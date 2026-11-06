-- GoldIntel / Collect / Reconciler.lua                            (Phase 3b-2 M1, Architecture 19, AC-9, AC-13)
--
-- PURPOSE
--  Turns money deltas into ledger entries that sum EXACTLY to the deltas. Source-agnostic (AC-10): it only
--  sees an Expectations store and delta numbers. Pure: no Platform calls, no clock, no storage; time is an
--  argument. The sink receives finished entries; stamps (act, loc, creditable) are added by opts.decorate.
--
--      local R = GI.Reconciler.New{ exp = store, sink = function(entry) end, decorate = function(entry) end? }
--      R:Begin(gt)          starts an interval (collect on). Deltas outside an interval are ignored (AC-9).
--      R:Money(copper, gt, gap?)   one P_MONEY delta
--      R:Tick(gt)           retries pending deltas, turns the ones older than WAIT into OTHER, expires expectations
--      R:End(gt)            collect off: pending deltas become OTHER at once, expectations are cleared
--      R:Stats()            see below ; R:Check() -> ok, sumDeltas, sumEntries, pendingSum
--
-- ALGORITHM for a delta d (never 0; zero is ignored):
--   gap          -> one OTHER entry, comp='gap' (AC-13)
--   exact pass   -> first combination (size 1..3 of the 8 highest-priority exact expectations with the sign
--                   of d) whose signed amounts sum to exactly d. Each component becomes an entry, conf high.
--   window pass  -> the highest-priority active window with the sign of d takes all of d, conf med, or low
--                   when another active window with that sign has a different src (competing windows)
--   else         -> pending. Pending deltas are retried whenever an expectation is added or a window closes,
--                   and at Tick. After WAIT (1.0 s, D-065; opts.wait may lengthen it, 3b-2 M5: the coin chat line
--                   arrives up to 1.0 s after the money change) a pending delta becomes OTHER, conf low.
-- No expectation is ever matched across two deltas (Q-4): an unmatched expectation just expires.
-- ONE narrow exception, called by Sources only (D-096, 0.5.3): R:ClaimPendingSum(n, spec) books 2 or 3 PENDING deltas
-- whose sum is exactly n as entries of `spec`, when exactly one such set exists and no single pending delta equals n.

local ADDON, GI = ...
GI = GI or {}

local R = {}
GI.Reconciler = R

R.WAIT = 1.0
R.MAX_CANDIDATES = 8
R.MAX_COMBO = 3

local Rec = {}
Rec.__index = Rec

function R.New(opts)
  opts = opts or {}
  assert(opts.exp, 'Reconciler.New needs an Expectations store')
  local self = setmetatable({
    exp = opts.exp, sink = opts.sink or function() end, decorate = opts.decorate,
    wait = (type(opts.wait) == 'number' and opts.wait >= R.WAIT) and opts.wait or R.WAIT,
    active = false, pending = {},
    sumDeltas = 0, sumEntries = 0, ignored = 0,
    n = 0, value = 0, otherN = 0, otherValue = 0, lowN = 0, largestOther = 0,
    gapN = 0, gapValue = 0, bySrc = {},
  }, Rec)
  opts.exp:Subscribe(function() if self.active then self:_retry(self.lastGT or 0) end end)
  return self
end

local function mag(n) return n < 0 and -n or n end

function Rec:_emit(e)
  if self.decorate then self.decorate(e) end
  self.n = self.n + 1
  self.value = self.value + mag(e.copper)
  self.sumEntries = self.sumEntries + e.copper
  local s = self.bySrc[e.src]
  if not s then s = { n = 0, copper = 0 }; self.bySrc[e.src] = s end
  s.n = s.n + 1; s.copper = s.copper + e.copper
  if e.conf == 'low' then self.lowN = self.lowN + 1 end
  if e.src == 'other' then
    self.otherN = self.otherN + 1
    self.otherValue = self.otherValue + mag(e.copper)
    if mag(e.copper) > self.largestOther then self.largestOther = mag(e.copper) end
  end
  if e.comp == 'gap' then self.gapN = self.gapN + 1; self.gapValue = self.gapValue + mag(e.copper) end
  self.sink(e)
end

function Rec:_other(p, gt, comp)
  self:_emit({ t = p.t, copper = p.copper, src = 'other', conf = 'low', comp = comp })
end

-- exact pass: search combinations of size 1..MAX_COMBO over the highest-priority candidates
local function findCombo(cands, d)
  local n = #cands
  for i = 1, n do
    if cands[i].sign * cands[i].copper == d then return { cands[i] } end
  end
  if R.MAX_COMBO >= 2 then
    for i = 1, n do for j = i + 1, n do
      if cands[i].sign * cands[i].copper + cands[j].sign * cands[j].copper == d then return { cands[i], cands[j] } end
    end end
  end
  if R.MAX_COMBO >= 3 then
    for i = 1, n do for j = i + 1, n do for k = j + 1, n do
      if cands[i].sign * cands[i].copper + cands[j].sign * cands[j].copper + cands[k].sign * cands[k].copper == d then
        return { cands[i], cands[j], cands[k] }
      end
    end end end
  end
end

-- tries to explain pending delta p now; true when entries were emitted
function Rec:_resolve(p, gt)
  local d = p.copper
  local sign = d > 0 and 1 or -1
  local all = self.exp:Active(gt, sign, 'exact')
  local cands = {}
  for i = 1, math.min(#all, R.MAX_CANDIDATES) do cands[i] = all[i] end
  local combo = findCombo(cands, d)
  if combo then
    for _, e in ipairs(combo) do
      self.exp:Consume(e.id)
      if e.comps then
        for _, c in ipairs(e.comps) do
          self:_emit({ t = p.t, copper = c.copper, src = c.src, conf = 'high', comp = c.comp, ctx = e.ctx,
            ref = e.ref, settle = c.settle, exp = e.id })
        end
      else
        self:_emit({ t = p.t, copper = e.sign * e.copper, src = e.src, conf = 'high', ctx = e.ctx,
          ref = e.ref, settle = e.settle, comp = e.comp, exp = e.id })
      end
    end
    return true
  end
  local wins = self.exp:Active(gt, sign, 'window')
  if #wins > 0 then
    local w = wins[1]
    local conf = 'med'
    for i = 2, #wins do if wins[i].src ~= w.src then conf = 'low'; break end end
    self:_emit({ t = p.t, copper = d, src = w.src, conf = conf, ctx = w.ctx, ref = w.ref, settle = w.settle, exp = w.id })
    return true
  end
  return false
end

function Rec:_retry(gt)
  local keep = {}
  for _, p in ipairs(self.pending) do
    if not self:_resolve(p, gt) then keep[#keep + 1] = p end
  end
  self.pending = keep
end

function Rec:Begin(gt)
  self.active = true
  self.lastGT = gt
end

function Rec:Money(copper, gt, gap)
  if not self.active then self.ignored = self.ignored + 1; return end
  self.lastGT = gt
  if type(copper) ~= 'number' or copper == 0 then return end
  self.sumDeltas = self.sumDeltas + copper
  local p = { copper = copper, t = gt }
  if gap then self:_other(p, gt, 'gap'); return end
  if not self:_resolve(p, gt) then self.pending[#self.pending + 1] = p end
end

function Rec:Tick(gt)
  if not self.active then return end
  self.lastGT = gt
  self:_retry(gt)
  local keep = {}
  for _, p in ipairs(self.pending) do
    if gt - p.t >= self.wait then self:_other(p, gt) else keep[#keep + 1] = p end
  end
  self.pending = keep
  self.exp:Expire(gt)
end

function Rec:End(gt)
  if not self.active then return end
  self.lastGT = gt
  self:_retry(gt)
  for _, p in ipairs(self.pending) do self:_other(p, gt) end
  self.pending = {}
  self.exp:Clear()
  self.active = false
end

--- D-096: books 2..3 pending deltas of n's sign that sum to exactly n, one entry per delta built from spec
-- { src, ctx?, ref?, comp? } (conf high). Refuses (false, reason) when a single pending delta equals n (the normal
-- exact match handles it), when no set sums to n, or when more than one set does (ambiguous: no guessing).
function Rec:ClaimPendingSum(n, spec)
  if not self.active or type(n) ~= 'number' or n == 0 then return false, 'inactive' end
  local sign = n > 0 and 1 or -1
  local idx = {}
  for i, p in ipairs(self.pending) do
    if p.copper == n then return false, 'single' end
    if (p.copper > 0 and 1 or -1) == sign then idx[#idx + 1] = i end
  end
  local found = {}
  for a = 1, #idx do for b = a + 1, #idx do
    local pa, pb = self.pending[idx[a]], self.pending[idx[b]]
    if pa.copper + pb.copper == n then found[#found + 1] = { idx[a], idx[b] } end
    for c = b + 1, #idx do
      if pa.copper + pb.copper + self.pending[idx[c]].copper == n then found[#found + 1] = { idx[a], idx[b], idx[c] } end
    end
  end end
  if #found == 0 then return false, 'nosum' end
  if #found > 1 then return false, 'ambiguous' end
  local take = {}
  for _, i in ipairs(found[1]) do take[i] = true end
  local keep = {}
  for i, p in ipairs(self.pending) do
    if take[i] then
      self:_emit({ t = p.t, copper = p.copper, src = spec.src, conf = 'high', ctx = spec.ctx, ref = spec.ref, comp = spec.comp })
    else
      keep[#keep + 1] = p
    end
  end
  self.pending = keep
  return true, #found[1]
end

function Rec:PendingSum()
  local s = 0
  for _, p in ipairs(self.pending) do s = s + p.copper end
  return s
end

function Rec:Check()
  local ps = self:PendingSum()
  return self.sumDeltas == self.sumEntries + ps, self.sumDeltas, self.sumEntries, ps
end

function Rec:Stats()
  local xs = self.exp:Stats()
  local function share(a, b) if b == 0 then return 0 end return a / b end
  local by = {}
  for k, v in pairs(self.bySrc) do by[k] = { n = v.n, copper = v.copper } end
  return {
    total = self.n, totalValue = self.value,
    lowConfShare = share(self.lowN, self.n),
    otherShareValue = share(self.otherValue, self.value),     -- the headline (D-072)
    otherShareEntries = share(self.otherN, self.n),
    largestOther = self.largestOther,
    gapCount = self.gapN, gapValue = self.gapValue,
    unmatched = xs.unmatched, pending = #self.pending, ignored = self.ignored,
    sumDeltas = self.sumDeltas, sumEntries = self.sumEntries, bySource = by,
  }
end
