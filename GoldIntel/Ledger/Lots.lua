-- GoldIntel / Ledger / Lots.lua                                   (Phase 3b-3 M1, Architecture AC-15..AC-18, Requirements FR-LED-2/3)
--
-- PURPOSE
--  The asset ledger: one lot per acquisition of one item id, FIFO consumption, conversions, retention.
--  Pure: no Platform, no clock, no storage, and NO dependency on Cash / Reconciler / Expectations (AC-15, I-6):
--  a lot bug can never touch the cash ledger. `state` is the table the caller persists (M3: lots[charKey]).
--
--      local L = GI.Lots.New(state?, { capOpen = 4000, capClosed = 300, emit = fn(kind, record) })
--      L:Add{ itemID, qty, t, src, how, valueEach?, valueSrc?, vc?, flags?, origin?, locConf?, ctx?, ref?, vt?, cost? } -> lot | nil, err
--            cost = copper paid for a purchase lot (M3); informational, never part of value created
--      L:Convert(removed, copper, { t, via, ref?, priceOf? }) -> conversions, short, unallocated
--            removed = { [itemID] = qty }; FIFO per item id; `copper` is divided over the removed units (Q-8, exact sum);
--            short[id] = quantity that no open lot could cover (never invented away); unallocated = copper no lot received
--      L:Complete(itemID, info, manual, now) -> number of lots that received their FIRST valuation
--      L:ExpirePending(now) -> number
--      L:Compact() -> number of merges             open cap: equal-valued lots of one item merge, oldest first
--      opts.alert(kind, record) is called for every anomaly (see Lots.ANOMALY_TEXT, Lots.Describe); never hidden.
--      L:Check(carried) -> ok, diffs               OPTIONAL diagnostic only (D-081): open qty per item id vs a carried map; not an invariant
--      L:OpenQty() -> { [itemID] = qty }           L:InventoryValue() -> copper          L:Stats() -> table
--      GI.Lots.AllocateCopper(total, weights) -> shares summing EXACTLY to total
--
-- Invariants (tested): I-2 a lot is created once and consumed once (qtyLeft never rises, never below 0);
-- I-3 is now an optional diagnostic (D-081); I-5 `vc` (counts as value created) only for src loot or quest, free lots, none of the flags
-- transfer / conversion / opening / gap / unattributed / unexplained (otherwise coerced to false and counted).

local ADDON, GI = ...
GI = GI or {}

local Lots = {}
GI.Lots = Lots

Lots.CAP_OPEN = 4000         -- R-2 (D-098, user 2026-11-07, stopgap until Phase 4 aggregates): was 1500 (3b-3 Q-11)
Lots.CAP_CLOSED = 300

local SRC = { loot = true, quest = true, vendor = true, mail = true, trade = true, disenchant = true, unknown = true }
local HOW = { free = true, purchase = true }
local VSRC = { market = true, vendor = true, manual = true, unknown = true }
local VIA = { vendor = true, consume = true, trade = true, ah = true, mail = true, purchase = true }
local NO_VC_FLAGS = { transfer = true, conversion = true, opening = true, gap = true, unattributed = true, unexplained = true }

local function isInt(n, lo) return type(n) == "number" and n == math.floor(n) and n >= lo and n < 2 ^ 40 end

--- Splits `total` over `weights` (non-negative numbers) proportionally; the shares always sum to `total`.
-- The remainder goes to the largest weight (first on ties). All-zero weights share equally.
function Lots.AllocateCopper(total, weights)
  local n = #weights
  local shares = {}
  if n == 0 then return shares end
  local sum = 0
  for i = 1, n do sum = sum + weights[i] end
  local w = weights
  if sum <= 0 then
    w = {}
    for i = 1, n do w[i] = 1 end
    sum = n
  end
  local given, big = 0, 1
  for i = 1, n do
    local a = total * w[i]
    local q = (a - math.fmod(a, sum)) / sum
    shares[i] = q
    given = given + q
    if w[i] > w[big] then big = i end
  end
  shares[big] = shares[big] + (total - given)
  return shares
end

local function copyFlags(f)
  local c = {}
  if type(f) == 'table' then for k, v in pairs(f) do if v then c[k] = true end end end
  return c
end

-- R-2 (D-098): lots merge only when they also share zone, subzone and activity, so the place survives at subzone level.
local function placeKey(lot)
  local o = lot.origin or {}
  return table.concat({ tostring(o.zone or ''), tostring(o.sub or ''), tostring(o.act or '') }, '/')
end

local function flagKey(f)
  local names = {}
  for k in pairs(f) do if k ~= 'merged' then names[#names + 1] = k end end
  table.sort(names)
  return table.concat(names, ',')
end

local Ledger = {}
Ledger.__index = Ledger

function Lots.New(state, opts)
  opts = opts or {}
  state = state or {}
  if type(state.nextId) ~= 'number' then state.nextId = 1 end
  if type(state.open) ~= 'table' then state.open = {} end
  if type(state.closed) ~= 'table' then state.closed = {} end
  if type(state.closedSummary) ~= 'table' then state.closedSummary = {} end
  if type(state.conv) ~= 'table' then state.conv = {} end
  local t = state.totals
  if type(t) ~= 'table' then t = {}; state.totals = t end
  t.created = t.created or { n = 0, value = 0 }
  t.transfer = t.transfer or { n = 0, value = 0 }
  t.unattributed = t.unattributed or { n = 0, qty = 0, value = 0 }
  t.byVia = t.byVia or {}
  local q = state.quality
  if type(q) ~= 'table' then q = {}; state.quality = q end
  q.shortfall = q.shortfall or 0
  q.merged = q.merged or 0
  q.unallocated = q.unallocated or 0
  q.vcCoerced = q.vcCoerced or 0
  if type(state.anomalies) ~= 'table' then state.anomalies = {} end
  state.anomalies.counts = state.anomalies.counts or {}
  state.anomalies.recent = state.anomalies.recent or {}
  return setmetatable({ s = state, capOpen = opts.capOpen or Lots.CAP_OPEN, capClosed = opts.capClosed or Lots.CAP_CLOSED,
    emit = opts.emit, alert = opts.alert }, Ledger)
end

-- Scope (user decision 2026-10-19, D-081): the asset side tracks ACQUISITIONS and CONVERSIONS only. Inventory is an
-- approximation ("acquired and not known disposed"). Converting items that no tracked lot covers (acquired before
-- tracking, from the bank, ...) is NORMAL: it is counted (Stats().shortfall / unallocated) but is not an anomaly.
-- Anomalies: conditions that must never be hidden or treated as normal (user directive 2026-10-19). Each one is counted,
-- kept in a ring, passed to opts.alert(kind, record) EVERY time (the caller decides how to show it; M3 prints one
-- "please report this as a bug" line per kind per session) and listed in Stats().anomalies.
Lots.ANOMALY_TEXT = {
  ['sale-price-unknown'] = 'a vendor sale included an item whose vendor price was not known',
  ['sale-no-sell-price'] = 'money came in at a vendor while an item with no sell price left the bags',
  ['equal-split'] = 'a vendor sale had to be split equally per unit because a price was missing',
  ['vc-coerced'] = 'a lot asked to count as value created but broke the rule and was recorded as not created',
}
Lots.ANOMALY_RING = 50

function Lots.Describe(kind)
  return (Lots.ANOMALY_TEXT[kind] or ('unexpected condition ' .. tostring(kind))) .. '. This is not expected: please report it as a bug.'
end

local function note(self, kind, t, detail)
  local a = self.s.anomalies
  a.counts[kind] = (a.counts[kind] or 0) + 1
  local rec = { t = t, kind = kind, detail = detail }
  a.recent[#a.recent + 1] = rec
  while #a.recent > Lots.ANOMALY_RING do table.remove(a.recent, 1) end
  if self.alert then pcall(self.alert, kind, rec) end
end

local function say(self, kind, rec, phase)
  if self.emit then pcall(self.emit, kind, rec, phase) end   -- phase (0.6.0): 'add' | 'complete' for kind 'lot'
end

-- value bookkeeping: totals follow the lot's value so a later first valuation is attributed to the original lot
local function book(self, lot, copper)
  local t = self.s.totals
  local f = lot.flags
  if lot.vc then
    t.created.value = t.created.value + copper
  elseif f.unattributed then
    t.unattributed.value = t.unattributed.value + copper
  elseif f.transfer or f.opening or f.gap then
    t.transfer.value = t.transfer.value + copper
  end
end

function Ledger:Add(spec)
  if type(spec) ~= 'table' then return nil, 'spec required' end
  if not isInt(spec.itemID, 1) then return nil, 'bad itemID' end
  if not isInt(spec.qty, 1) then return nil, 'bad qty' end
  if type(spec.t) ~= 'number' then return nil, 'bad time' end
  if not SRC[spec.src] then return nil, 'bad src' end
  local how = spec.how or 'free'
  if not HOW[how] then return nil, 'bad how' end
  local vsrc = spec.valueSrc or 'unknown'
  if not VSRC[vsrc] then return nil, 'bad valueSrc' end
  local each = spec.valueEach or 0
  if not isInt(each, 0) then return nil, 'bad valueEach' end
  local flags = copyFlags(spec.flags)
  if vsrc == 'unknown' then
    each = 0
    flags.unknown = true
  end
  local vc = spec.vc == true
  if vc then
    local ok = (spec.src == 'loot' or spec.src == 'quest') and how == 'free'
    if ok then for k in pairs(flags) do if NO_VC_FLAGS[k] then ok = false end end end
    if not ok then
      vc = false
      self.s.quality.vcCoerced = self.s.quality.vcCoerced + 1
      note(self, 'vc-coerced', spec.t, { itemID = spec.itemID, src = spec.src })
    end
  end
  if spec.cost ~= nil and not isInt(spec.cost, 0) then return nil, 'bad cost' end
  local s = self.s
  local lot = {
    id = s.nextId, itemID = spec.itemID, qty = spec.qty, qtyLeft = spec.qty, t = spec.t,
    valueEach = each, valueSrc = vsrc, how = how, src = spec.src, vc = vc, flags = flags,
    origin = spec.origin, locConf = spec.locConf, ctx = spec.ctx, ref = spec.ref, vt = spec.vt or spec.t, out = 0, cost = spec.cost,
  }
  s.nextId = s.nextId + 1
  s.open[#s.open + 1] = lot
  local tot = s.totals
  if vc then tot.created.n = tot.created.n + 1
  elseif flags.unattributed then tot.unattributed.n = tot.unattributed.n + 1; tot.unattributed.qty = tot.unattributed.qty + lot.qty
  elseif flags.transfer or flags.opening or flags.gap then tot.transfer.n = tot.transfer.n + 1 end
  book(self, lot, each * lot.qty)
  say(self, 'lot', lot, 'add')
  if #s.open > self.capOpen then self:Compact() end
  return lot
end

local function closeLot(self, lot)
  local s = self.s
  local sum = s.closedSummary[lot.itemID]
  if not sum then sum = { qty = 0, copperIn = 0, copperOut = 0 }; s.closedSummary[lot.itemID] = sum end
  sum.qty = sum.qty + lot.qty
  sum.copperIn = sum.copperIn + lot.valueEach * lot.qty
  sum.copperOut = sum.copperOut + lot.out
  s.closed[#s.closed + 1] = lot
  while #s.closed > self.capClosed do table.remove(s.closed, 1) end
end

-- takes up to `qty` of one item id, oldest lot first. Returns pieces { {lot, n} }, taken
local function take(self, itemID, qty)
  local pieces, taken = {}, 0
  for _, lot in ipairs(self.s.open) do
    if lot.itemID == itemID and lot.qtyLeft > 0 then
      local n = lot.qtyLeft
      if n > qty - taken then n = qty - taken end
      pieces[#pieces + 1] = { lot = lot, n = n }
      taken = taken + n
      if taken >= qty then break end
    end
  end
  return pieces, taken
end

function Ledger:Convert(removed, copper, opts)
  opts = opts or {}
  local convs, short, unalloc = {}, {}, 0
  if type(removed) ~= 'table' then return convs, short, 0 end
  local via = opts.via
  if not VIA[via] then return convs, short, 0, 'bad via' end
  copper = copper or 0
  if not isInt(copper, 0) then return convs, short, 0, 'bad copper' end
  local ids = {}
  for id, q in pairs(removed) do
    if isInt(id, 1) and isInt(q, 1) then ids[#ids + 1] = id end
  end
  table.sort(ids)
  -- weights across items: sellPrice x qty when every price is known, otherwise equal per unit
  local weights, byPrice = {}, type(opts.priceOf) == 'function'
  if byPrice then
    for i, id in ipairs(ids) do
      local p = opts.priceOf(id)
      if not isInt(p, 0) then byPrice = false; break end
      weights[i] = p * removed[id]
    end
  end
  if via == 'vendor' and copper > 0 and type(opts.priceOf) == 'function' then
    for _, id in ipairs(ids) do
      local p = opts.priceOf(id)
      if not isInt(p, 0) then
        note(self, 'sale-price-unknown', opts.t, { itemID = id, copper = copper })
      elseif p == 0 then
        note(self, 'sale-no-sell-price', opts.t, { itemID = id, copper = copper })
      end
    end
  end
  if not byPrice then
    if copper > 0 and #ids > 1 then note(self, 'equal-split', opts.t, { copper = copper, items = #ids }) end
    for i, id in ipairs(ids) do weights[i] = removed[id] end
  end
  local itemCopper = copper > 0 and Lots.AllocateCopper(copper, weights) or {}
  local divided = false
  for i, id in ipairs(ids) do
    local want = removed[id]
    local pieces, taken = take(self, id, want)
    local share = itemCopper[i] or 0
    if taken < want then
      short[id] = want - taken
      self.s.quality.shortfall = self.s.quality.shortfall + (want - taken)
    end
    if #pieces == 0 then
      unalloc = unalloc + share
    else
      local pw = {}
      for k, p in ipairs(pieces) do pw[k] = p.n end
      local pc = share > 0 and Lots.AllocateCopper(share, pw) or {}
      for k, p in ipairs(pieces) do
        local c = pc[k] or 0
        local lot = p.lot
        lot.qtyLeft = lot.qtyLeft - p.n
        lot.out = lot.out + c
        local cv = { t = opts.t, lotID = lot.id, itemID = id, qty = p.n, copper = c, via = via, ref = opts.ref }
        convs[#convs + 1] = cv
        local conv = self.s.conv
        conv[#conv + 1] = cv
        while #conv > self.capClosed do table.remove(conv, 1) end
        local bv = self.s.totals.byVia[via]
        if not bv then bv = { n = 0, qty = 0, copper = 0 }; self.s.totals.byVia[via] = bv end
        bv.n, bv.qty, bv.copper = bv.n + 1, bv.qty + p.n, bv.copper + c
      end
    end
  end
  if copper > 0 and #convs > 1 then
    for _, cv in ipairs(convs) do cv.alloc = true end
    divided = true
  end
  self.s.quality.unallocated = self.s.quality.unallocated + unalloc
  -- retire emptied lots after the loop (no index shifting while iterating)
  local open, keep = self.s.open, {}
  for _, lot in ipairs(open) do
    if lot.qtyLeft == 0 then closeLot(self, lot) else keep[#keep + 1] = lot end
  end
  self.s.open = keep
  for _, cv in ipairs(convs) do say(self, 'conversion', cv) end
  return convs, short, unalloc, nil, divided
end

function Ledger:Complete(itemID, info, manual, now)
  local V = GI.Valuation
  local n = 0
  for _, lot in ipairs(self.s.open) do
    if lot.itemID == itemID and lot.valueSrc == 'unknown' then
      if V.Complete(lot, info, manual, now) then
        n = n + 1
        book(self, lot, lot.valueEach * lot.qty)
        say(self, 'lot', lot, 'complete')
      end
    end
  end
  return n
end

function Ledger:ExpirePending(now)
  local V = GI.Valuation
  local n = 0
  for _, lot in ipairs(self.s.open) do
    if V.Expire(lot, now) then n = n + 1 end
  end
  return n
end

function Ledger:Compact()
  local open = self.s.open
  if #open <= self.capOpen then return 0 end
  local first, drop, merges = {}, {}, 0
  local excess = #open - self.capOpen
  for i, lot in ipairs(open) do
    if excess > 0 and not lot.flags.pendingInfo then
      local key = table.concat({ lot.itemID, lot.valueEach, lot.valueSrc, lot.how, tostring(lot.vc), flagKey(lot.flags), placeKey(lot) }, '|')
      local head = first[key]
      if not head then
        first[key] = lot
      else
        head.qty = head.qty + lot.qty
        head.qtyLeft = head.qtyLeft + lot.qtyLeft
        head.out = head.out + lot.out
        head.flags.merged = true
        drop[i] = true
        merges = merges + 1
        excess = excess - 1
      end
    elseif not lot.flags.pendingInfo then
      local key = table.concat({ lot.itemID, lot.valueEach, lot.valueSrc, lot.how, tostring(lot.vc), flagKey(lot.flags), placeKey(lot) }, '|')
      first[key] = first[key] or lot
    end
  end
  if merges > 0 then
    local keep = {}
    for i, lot in ipairs(open) do if not drop[i] then keep[#keep + 1] = lot end end
    self.s.open = keep
    self.s.quality.merged = self.s.quality.merged + merges
  end
  return merges
end

function Ledger:OpenQty()
  local m = {}
  for _, lot in ipairs(self.s.open) do
    m[lot.itemID] = (m[lot.itemID] or 0) + lot.qtyLeft
  end
  return m
end

function Ledger:Check(carried)
  local open = self:OpenQty()
  local diffs, ok = {}, true
  carried = carried or {}
  for id, q in pairs(open) do
    local d = q - (carried[id] or 0)
    if d ~= 0 then diffs[id] = d; ok = false end
  end
  for id, q in pairs(carried) do
    if open[id] == nil and q ~= 0 then diffs[id] = -q; ok = false end
  end
  return ok, diffs
end

function Ledger:InventoryValue()
  local v = 0
  for _, lot in ipairs(self.s.open) do v = v + lot.qtyLeft * lot.valueEach end
  return v
end

function Ledger:Stats()
  local s = self.s
  local unknownLots, unknownQty, items = 0, 0, {}
  local qtyOpen = 0
  for _, lot in ipairs(s.open) do
    qtyOpen = qtyOpen + lot.qtyLeft
    if lot.valueSrc == 'unknown' then
      unknownLots = unknownLots + 1
      unknownQty = unknownQty + lot.qtyLeft
      items[lot.itemID] = true
    end
  end
  local ui = 0
  for _ in pairs(items) do ui = ui + 1 end
  return {
    openLots = #s.open, openQty = qtyOpen, closedRing = #s.closed, inventoryValue = self:InventoryValue(),
    created = { n = s.totals.created.n, value = s.totals.created.value },
    transfer = { n = s.totals.transfer.n, value = s.totals.transfer.value },
    unattributed = { n = s.totals.unattributed.n, qty = s.totals.unattributed.qty, value = s.totals.unattributed.value },
    unknown = { lots = unknownLots, qty = unknownQty, items = ui },
    shortfall = s.quality.shortfall, merged = s.quality.merged, unallocated = s.quality.unallocated,
    vcCoerced = s.quality.vcCoerced,
    anomalies = (function() local c = {} for k, v in pairs(s.anomalies.counts) do c[k] = v end return c end)(),
  }
end
