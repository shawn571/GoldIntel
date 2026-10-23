-- GoldIntel / Collect / Expectations.lua                          (Phase 3b-2 M1, Architecture AC-10, AC-11)
--
-- PURPOSE
--  A registry of "money we expect to see": exact expectations (known amount, possibly split in components)
--  and window expectations (unknown amount, backed by an open context such as a merchant or trade window).
--  This module knows NOTHING about WoW, loot, mail or trade. Sources.lua (M2) is the only translator.
--  It is pure: no Platform calls, no clock. Every function that needs time takes it as an argument (gt).
--
--      local X = GI.Expectations.New()
--      X:Add{ src, mode='exact'|'window', copper=n (magnitude), sign=1|-1, t0, ttl>=1.0,
--             ctx?, ref?, settle?, comp?, comps?, hold? }          -> id | nil, err
--          hold (exact only): no expiry until Close(id, gt) -- used while the context that explains it is open (AC-11)
--          comps = { {src, copper (SIGNED), comp?, settle?}, ... } must sum to sign*copper (AH sale split, D-070)
--      X:Close(id, gt)      window or held exact: the context ended; stays active for ttl (the linger) after gt
--      X:Extend(id, gt)     exact: keeps it alive at least until gt (context still active, AC-11)
--      X:Consume(id)        exact: matched, removed
--      X:Active(gt, sign?, mode?) -> array sorted by priority, then t0, then id
--      X:Expire(gt)         removes everything no longer active; exact ones count as `unmatched`
--      X:Subscribe(fn)      fn(kind, exp) on 'add' and 'close' (the Reconciler retries pending deltas)
--      X:Stats()            { added, consumed, unmatched, windowsClosed, active }
--
-- Boundary rule: an expectation is active while  gt <= expireGT  (inclusive).  expireGT = t0 + ttl for exact,
-- nil (open) then closedGT + ttl for window.
--
-- Priority (D-065): trade, mail, vendor, quest, loot, AH.

local ADDON, GI = ...
GI = GI or {}

local X = {}
GI.Expectations = X

X.MIN_TTL = 1.0

X.PRIORITY = {
  trade = 1,
  mailMoney = 2, codIn = 2, codOut = 2, ahSale = 2, ahCut = 2, ahDepositRefund = 2,
  vendor = 3, purchase = 3, repair = 3, buyback = 3,
  quest = 4,
  loot = 5,
  ahDeposit = 6, ahPurchase = 6,
}
X.PRIORITY_DEFAULT = 9

function X.PrioOf(src) return X.PRIORITY[src] or X.PRIORITY_DEFAULT end

local Store = {}
Store.__index = Store

--- Diagnostic tap (Ledger/Trace.lua): fn(event, expectation, gt). Never changes behaviour; its errors are swallowed.
local function tapped(self, ev, e, gt)
  if self.tap then pcall(self.tap, ev, e, gt) end
end

function X.New()
  return setmetatable({ list = {}, nextId = 0, subs = {},
    st = { added = 0, consumed = 0, unmatched = 0, windowsClosed = 0 } }, Store)
end

local function sgn(n) if n > 0 then return 1 elseif n < 0 then return -1 end return 0 end

function Store:Add(spec)
  if type(spec) ~= 'table' then return nil, 'spec' end
  if spec.mode ~= 'exact' and spec.mode ~= 'window' then return nil, 'mode' end
  if spec.sign ~= 1 and spec.sign ~= -1 then return nil, 'sign' end
  if type(spec.t0) ~= 'number' then return nil, 't0' end
  if type(spec.ttl) ~= 'number' or spec.ttl < X.MIN_TTL then return nil, 'ttl' end
  if type(spec.src) ~= 'string' then return nil, 'src' end
  local e = { src = spec.src, mode = spec.mode, sign = spec.sign, t0 = spec.t0, ttl = spec.ttl,
    ctx = spec.ctx, ref = spec.ref, settle = spec.settle, comp = spec.comp, prio = X.PrioOf(spec.src) }
  if spec.mode == 'exact' then
    if type(spec.copper) ~= 'number' or spec.copper <= 0 or spec.copper ~= math.floor(spec.copper) then
      return nil, 'copper'
    end
    e.copper = spec.copper
    if spec.comps then
      local sum = 0
      for _, c in ipairs(spec.comps) do
        if type(c.copper) ~= 'number' or c.copper == 0 or c.copper ~= math.floor(c.copper) then return nil, 'comp' end
        sum = sum + c.copper
      end
      if #spec.comps == 0 or sum ~= spec.sign * spec.copper then return nil, 'comps' end
      e.comps = {}
      for i, c in ipairs(spec.comps) do
        e.comps[i] = { src = c.src, copper = c.copper, comp = c.comp, settle = c.settle }
      end
    end
    e.expireGT = spec.t0 + spec.ttl
    if spec.hold then e.hold = true; e.expireGT = nil end
  else
    if spec.copper ~= nil or spec.comps ~= nil then return nil, 'window has no amount' end
    e.expireGT = nil
  end
  self.nextId = self.nextId + 1
  e.id = self.nextId
  self.list[#self.list + 1] = e
  self.st.added = self.st.added + 1
  tapped(self, 'add', e)
  for _, fn in ipairs(self.subs) do fn('add', e) end
  return e.id
end

function Store:Get(id)
  for _, e in ipairs(self.list) do if e.id == id then return e end end
end

function Store:Close(id, gt)
  local e = self:Get(id)
  if not e or e.closedGT or not (e.mode == 'window' or e.hold) then return false end
  e.closedGT = gt
  local base = e.mode == 'exact' and (e.t0 + e.ttl) or 0
  e.expireGT = math.max(gt + e.ttl, base)
  self.st.windowsClosed = self.st.windowsClosed + 1
  tapped(self, 'close', e, gt)
  for _, fn in ipairs(self.subs) do fn('close', e) end
  return true
end

function Store:Extend(id, gt)
  local e = self:Get(id)
  if not e or e.mode ~= 'exact' then return false end
  if gt > e.expireGT then e.expireGT = gt end
  return true
end

function Store:Consume(id)
  for i, e in ipairs(self.list) do
    if e.id == id then
      if e.mode ~= 'exact' then return false end
      table.remove(self.list, i)
      self.st.consumed = self.st.consumed + 1
      tapped(self, 'consume', e)
      return true
    end
  end
  return false
end

local function isActive(e, gt)
  if e.expireGT == nil then return true end       -- open window
  return gt <= e.expireGT
end

local function before(a, b)
  if a.prio ~= b.prio then return a.prio < b.prio end
  if a.t0 ~= b.t0 then return a.t0 < b.t0 end
  return a.id < b.id
end

function Store:Active(gt, sign, mode)
  local out = {}
  for _, e in ipairs(self.list) do
    if isActive(e, gt) and (sign == nil or e.sign == sign) and (mode == nil or e.mode == mode) then
      out[#out + 1] = e
    end
  end
  table.sort(out, before)
  return out
end

function Store:Expire(gt)
  local kept, gone = {}, {}
  for _, e in ipairs(self.list) do
    if isActive(e, gt) then kept[#kept + 1] = e
    else
      gone[#gone + 1] = e
      if e.mode == 'exact' then self.st.unmatched = self.st.unmatched + 1; tapped(self, 'expire', e, gt) end
    end
  end
  self.list = kept
  return gone
end

--- Ends an interval (collect off): every remaining exact expectation is unmatched, windows are dropped.
function Store:Clear()
  for _, e in ipairs(self.list) do
    if e.mode == 'exact' then self.st.unmatched = self.st.unmatched + 1; tapped(self, 'clear', e) end
  end
  self.list = {}
end

function Store:Subscribe(fn) self.subs[#self.subs + 1] = fn end

function Store:Stats()
  return { added = self.st.added, consumed = self.st.consumed, unmatched = self.st.unmatched,
    windowsClosed = self.st.windowsClosed, active = #self.list }
end

X.sign = sgn
