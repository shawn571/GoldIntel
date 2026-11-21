--[[
Tests / test_item_mutation.lua                (Phase 3b-3 M1): deliberate bugs in BagDiff, Valuation and Lots must be caught.
One compact scenario suite is run against the real source and against each mutant (source text replaced before loading).
The unmutated suite must report no failure; every mutant must report at least one.
]]

local T = require('testlib')
local Loader = require('loader')

local ld = loadstring or load
local FILES = { bag = 'Collect/BagDiff.lua', val = 'Ledger/Valuation.lua', lots = 'Ledger/Lots.lua' }
local SRC = {}
for k, p in pairs(FILES) do SRC[k] = Loader.readFile(Loader.root .. '/' .. p) end

local function load3(src)
  local ns = {}
  assert(ld(src.bag, '=BagDiff'))('GoldIntel', ns)
  assert(ld(src.val, '=Valuation'))('GoldIntel', ns)
  assert(ld(src.lots, '=Lots'))('GoldIntel', ns)
  return ns
end

local function eqv(a, b)
  if a == b then return true end
  if type(a) ~= 'table' or type(b) ~= 'table' then return false end
  for k, v in pairs(a) do if not eqv(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function spec(id, qty, t, extra)
  local s = { itemID = id, qty = qty, t = t or 1, src = 'loot', how = 'free', valueEach = 10, valueSrc = 'vendor', vc = true }
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end
local function snap(items, complete) return { items = items, complete = complete ~= false } end

local function scenarios(src)
  local ns = load3(src)
  local fails = {}
  local function check(name, ok) if not ok then fails[#fails + 1] = name end end
  local function ok(f) local s, r = pcall(f); return s and r end

  local B, V, Lots = ns.BagDiff, ns.Valuation, ns.Lots

  -- BagDiff -------------------------------------------------------------------------------------
  check('diff add/remove', ok(function()
    local d = B.Compute(snap({ [1] = 5, [2] = 2 }), snap({ [1] = 7, [3] = 1 }))
    return eqv(d.added, { [1] = 2, [3] = 1 }) and eqv(d.removed, { [2] = 2 }) and d.n == 3
  end))
  check('stack move nets zero', ok(function() return B.Compute(snap({ [1] = 20 }), snap({ [1] = 20 })).n == 0 end))
  check('incomplete refused', ok(function()
    return B.Compute(snap({}, false), snap({})) == nil and B.Compute(snap({}), snap({}, false)) == nil
      and B.Compute(snap({}), { items = {} }) == nil
  end))
  check('zero quantity refused', ok(function() return B.Compute(snap({}), snap({ [1] = 0 })) == nil end))
  check('fingerprint sees quantity', ok(function() return B.Fingerprint({ [1] = 2 }) ~= B.Fingerprint({ [1] = 3 }) end))
  check('baseline only on commit', ok(function()
    local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d = t:Settle(snap({ [1] = 3 }))
    local before = t:Baseline()[1]
    t:Commit(d.seq)
    return before == 1 and t:Baseline()[1] == 3
  end))
  check('commit once', ok(function()
    local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d = t:Settle(snap({ [1] = 3 }))
    return t:Commit(d.seq) == true and t:Commit(d.seq) == nil
  end))
  check('superseded diff cannot commit', ok(function()
    local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d1 = t:Settle(snap({ [1] = 3 }))
    local d2 = t:Settle(snap({ [1] = 4 }))
    return t:Commit(d1.seq) == nil and t:Commit(d2.seq) == true
  end))
  check('incomplete settle keeps baseline', ok(function()
    local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d, why = t:Settle(snap({ [1] = 9 }, false))
    return d == nil and why == 'incomplete' and t:Baseline()[1] == 1
  end))
  check('repeat settle after commit is empty', ok(function()
    local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    t:Commit(t:Settle(snap({ [1] = 3 })).seq)
    local d, why = t:Settle(snap({ [1] = 3 }))
    return d == nil and why == 'empty'
  end))

  -- Valuation -----------------------------------------------------------------------------------
  check('vendor value', ok(function() local r = V.Value({ status = 'ready', sellPrice = 13 }); return r.valueEach == 13 and r.valueSrc == 'vendor' end))
  check('sell price 0 known', ok(function() local r = V.Value({ status = 'ready', sellPrice = 0 }); return r.valueSrc == 'vendor' and r.flags.noVendor == true end))
  check('pending unknown', ok(function() local r = V.Value({ status = 'pending' }); return r.valueSrc == 'unknown' and r.flags.pendingInfo == true and r.valueEach == 0 end))
  check('invalid final', ok(function() local r = V.Value({ status = 'invalid' }); return r.flags.invalid == true and not r.flags.pendingInfo end))
  check('highest of manual and vendor', ok(function()
    local hi = V.Value({ status = 'ready', sellPrice = 20 }, { copper = 500 })
    local lo = V.Value({ status = 'ready', sellPrice = 500 }, { copper = 20 })
    local tie = V.Value({ status = 'ready', sellPrice = 20 }, { copper = 20 })
    local none = V.Value({ status = 'ready', sellPrice = 20 }, nil)
    return hi.valueEach == 500 and hi.valueSrc == 'manual' and lo.valueEach == 500 and lo.valueSrc == 'vendor'
      and tie.valueSrc == 'vendor' and none.valueSrc == 'vendor'
  end))
  check('manual needs ready item data', ok(function()
    local r = V.Value({ status = 'pending' }, { copper = 7 })
    return r.valueSrc == 'unknown' and r.flags.pendingInfo == true
  end))
  check('bound rules', ok(function()
    return V.Value({ status = 'ready', sellPrice = 1, bindType = 1 }).flags.bound == true
      and V.Value({ status = 'ready', sellPrice = 1, bindType = 4 }).flags.bound == true
      and not V.Value({ status = 'ready', sellPrice = 1, bindType = 2 }).flags.bound
  end))
  check('first valuation only', ok(function()
    local lot = { t = 100, qty = 2, vc = true, valueEach = 0, valueSrc = 'unknown', flags = { unknown = true, pendingInfo = true } }
    local a = V.Complete(lot, { status = 'ready', sellPrice = 9 }, nil, 130)
    local b = V.Complete(lot, { status = 'ready', sellPrice = 500 }, nil, 200)
    return a == true and b == false and lot.valueEach == 9 and lot.vt == 130
  end))
  check('completion keeps acquisition time', ok(function()
    local lot = { t = 100, qty = 2, vc = true, valueEach = 0, valueSrc = 'unknown', flags = { unknown = true, pendingInfo = true } }
    V.Complete(lot, { status = 'ready', sellPrice = 9 }, nil, 130)
    return lot.t == 100 and lot.qty == 2 and lot.vc == true
  end))
  check('invalid never completed', ok(function()
    local lot = { t = 1, valueEach = 0, valueSrc = 'unknown', flags = { unknown = true, invalid = true } }
    return V.Complete(lot, { status = 'ready', sellPrice = 9 }, nil, 5) == false
  end))
  check('expire honours window', ok(function()
    local lot = { t = 100, flags = { pendingInfo = true, unknown = true } }
    local early = V.Expire(lot, 100 + V.PENDING_WINDOW - 1)
    local late = V.Expire(lot, 100 + V.PENDING_WINDOW)
    return early == false and late == true and lot.flags.unknown == true
  end))

  -- Lots ------------------------------------------------------------------------------------------
  check('allocation exact', ok(function()
    local s = Lots.AllocateCopper(10, { 1, 1, 1 })
    return s[1] + s[2] + s[3] == 10 and s[1] == 4
  end))
  check('FIFO order', ok(function()
    local st = {}
    local L = Lots.New(st)
    L:Add(spec(5, 3, 1)); L:Add(spec(5, 4, 2))
    local convs = L:Convert({ [5] = 5 }, 0, { t = 9, via = 'consume' })
    return convs[1].lotID == 1 and convs[1].qty == 3 and convs[2].lotID == 2 and convs[2].qty == 2
  end))
  check('consumed once', ok(function()
    local st = {}
    local L = Lots.New(st)
    L:Add(spec(5, 3, 1))
    L:Convert({ [5] = 1 }, 0, { t = 9, via = 'consume' })
    return st.open[1].qtyLeft == 2
  end))
  check('shortfall counted', ok(function()
    local L = Lots.New({})
    L:Add(spec(5, 2, 1))
    local _, short = L:Convert({ [5] = 5 }, 0, { t = 9, via = 'consume' })
    return short[5] == 3 and L:Stats().shortfall == 3
  end))
  check('uncovered copper unallocated', ok(function()
    local L = Lots.New({})
    local convs, _, un = L:Convert({ [6] = 1 }, 40, { t = 9, via = 'vendor' })
    return #convs == 0 and un == 40 and L:Stats().unallocated == 40
  end))
  check('sale allocation by price', ok(function()
    local L = Lots.New({})
    L:Add(spec(1, 2, 1)); L:Add(spec(2, 1, 1))
    local convs = L:Convert({ [1] = 2, [2] = 1 }, 100, { t = 9, via = 'vendor', priceOf = function(id) return id == 1 and 10 or 60 end })
    local by = {}
    for _, c in ipairs(convs) do by[c.itemID] = (by[c.itemID] or 0) + c.copper end
    return by[1] == 25 and by[2] == 75 and convs[1].alloc == true
  end))
  check('sale copper exact across pieces', ok(function()
    local L = Lots.New({})
    L:Add(spec(1, 1, 1)); L:Add(spec(1, 2, 2))
    local convs = L:Convert({ [1] = 3 }, 10, { t = 9, via = 'vendor' })
    return #convs == 2 and convs[1].copper + convs[2].copper == 10
  end))
  check('closed summary', ok(function()
    local st = {}
    local L = Lots.New(st)
    L:Add(spec(5, 3, 1, { valueEach = 7 }))
    L:Convert({ [5] = 3 }, 21, { t = 9, via = 'vendor' })
    local s = st.closedSummary[5]
    return #st.open == 0 and s.qty == 3 and s.copperIn == 21 and s.copperOut == 21 and #st.closed == 1
  end))
  check('ids increase', ok(function()
    local L = Lots.New({})
    return L:Add(spec(1, 1)).id == 1 and L:Add(spec(1, 1)).id == 2
  end))
  check('vc rule', ok(function()
    local L = Lots.New({})
    return L:Add(spec(1, 1, 1)).vc == true and L:Add(spec(1, 1, 1, { src = 'quest' })).vc == true
      and L:Add(spec(1, 1, 1, { src = 'mail' })).vc == false
      and L:Add(spec(1, 1, 1, { flags = { transfer = true } })).vc == false
      and L:Add(spec(1, 1, 1, { how = 'purchase' })).vc == false
      and L:Add(spec(1, 1, 1, { flags = { opening = true } })).vc == false
  end))
  check('unknown forces zero', ok(function()
    local lot = Lots.New({}):Add(spec(9, 2, 1, { valueSrc = 'unknown', valueEach = 77 }))
    return lot.valueEach == 0 and lot.flags.unknown == true
  end))
  check('transfer and unattributed totals', ok(function()
    local L = Lots.New({})
    L:Add(spec(1, 2, 1, { src = 'mail', vc = false, flags = { transfer = true } }))
    L:Add(spec(2, 1, 1, { src = 'unknown', vc = false, flags = { unattributed = true } }))
    local s = L:Stats()
    return s.transfer.value == 20 and s.transfer.n == 1 and s.unattributed.value == 10 and s.created.value == 0
  end))
  check('anomalies are never hidden', ok(function()
    local seen = {}
    local st = {}
    local L = Lots.New(st, { alert = function(kind) seen[#seen + 1] = kind; error('swallowed') end })
    L:Add(spec(1, 2, 1)); L:Add(spec(2, 1, 1)); L:Add(spec(3, 1, 1))
    -- clean single-item sale with a known price: no anomaly
    L:Convert({ [1] = 1 }, 10, { t = 5, via = 'vendor', priceOf = function() return 10 end })
    if #seen ~= 0 then return false end
    -- money came in while an item with sell price 0 left the bags
    L:Convert({ [2] = 1 }, 7, { t = 6, via = 'vendor', priceOf = function() return 0 end })
    -- price unknown at sale time
    L:Convert({ [3] = 1 }, 7, { t = 7, via = 'vendor', priceOf = function() return nil end })
    local c = L:Stats().anomalies
    return seen[1] == 'sale-no-sell-price' and seen[2] == 'sale-price-unknown'
      and c['sale-no-sell-price'] == 1 and c['sale-price-unknown'] == 1 and #st.anomalies.recent == 2
  end))
  check('uncovered conversions are counted but not alarms; equal split and vc are flagged', ok(function()
    local seen = {}
    local L = Lots.New({}, { alert = function(k) seen[#seen + 1] = k end })
    L:Add(spec(1, 1, 1))
    L:Convert({ [1] = 3, [9] = 1 }, 30, { t = 5, via = 'vendor' })
    L:Add(spec(5, 1, 2, { src = 'mail' }))
    local s = L:Stats()
    local c = s.anomalies
    return s.shortfall == 3 and s.unallocated > 0 and c['shortfall'] == nil and c['unallocated-copper'] == nil
      and c['equal-split'] == 1 and c['vc-coerced'] == 1
  end))
  check('anomaly ring is bounded', ok(function()
    local st = {}
    local L = Lots.New(st)
    for i = 1, Lots.ANOMALY_RING + 20 do L:Add(spec(1, 1, i, { src = 'mail' })) end
    return #st.anomalies.recent == Lots.ANOMALY_RING and L:Stats().anomalies['vc-coerced'] == Lots.ANOMALY_RING + 20
  end))
  check('check detects both directions', ok(function()
    local L = Lots.New({})
    L:Add(spec(1, 3, 1))
    local good = L:Check({ [1] = 3 })
    local bad, d = L:Check({ [1] = 3, [2] = 4 })
    local bad2, d2 = L:Check({ [1] = 2 })
    return good == true and bad == false and d[2] == -4 and bad2 == false and d2[1] == 1
  end))
  check('completion books under the original lot', ok(function()
    local L = Lots.New({})
    L:Add(spec(5, 3, 100, { valueSrc = 'unknown', flags = { pendingInfo = true } }))
    L:Complete(5, { status = 'ready', sellPrice = 9 }, nil, 130)
    local s = L:Stats()
    return s.created.value == 27 and s.unknown.lots == 0
  end))
  check('merge needs equal value', ok(function()
    local st = {}
    local L = Lots.New(st, { capOpen = 2 })
    L:Add(spec(1, 1, 1, { valueEach = 1 })); L:Add(spec(1, 1, 2, { valueEach = 2 })); L:Add(spec(1, 1, 3, { valueEach = 3 }))
    return #st.open == 3 and L:Stats().merged == 0
  end))
  check('merge keeps value', ok(function()
    local st = {}
    local L = Lots.New(st, { capOpen = 3 })
    for i = 1, 5 do L:Add(spec(1, 2, i)) end
    return #st.open == 3 and L:InventoryValue() == 100 and L:Stats().openQty == 10
  end))
  check('byVia totals', ok(function()
    local st = {}
    local L = Lots.New(st)
    L:Add(spec(1, 5, 1))
    L:Convert({ [1] = 2 }, 8, { t = 5, via = 'vendor' })
    return st.totals.byVia.vendor.copper == 8 and st.totals.byVia.vendor.qty == 2
  end))
  check('bad via consumes nothing', ok(function()
    local st = {}
    local L = Lots.New(st)
    L:Add(spec(1, 2, 1))
    L:Convert({ [1] = 1 }, 0, { t = 5, via = 'bogus' })
    return st.open[1].qtyLeft == 2
  end))
  return fails
end

local MUTANTS = {
  -- BagDiff
  { 'bag', 'swap added/removed', 'if q > p then added[id] = q - p; n = n + 1\n    elseif q < p then removed[id] = p - q; n = n + 1 end',
    'if q > p then removed[id] = q - p; n = n + 1\n    elseif q < p then added[id] = p - q; n = n + 1 end' },
  { 'bag', 'vanished ids ignored', 'if now.items[id] == nil then removed[id] = p; n = n + 1 end', 'if false then end' },
  { 'bag', 'baseline advances at settle', 'st.diffs = st.diffs + 1\n  return diff', 'st.diffs = st.diffs + 1\n  self.base = copyItems(snap.items); self.fp = fp\n  return diff' },
  { 'bag', 'commit keeps pending (double apply)', 'self.pending = nil\n  self.st.committed', 'self.st.committed' },
  { 'bag', 'incomplete accepted', 'snap.complete ~= true', 'false' },
  { 'bag', 'zero quantity accepted', 'n > 0 and n == math.floor(n) and n < 2 ^ 31', 'n >= 0 and n == math.floor(n) and n < 2 ^ 31' },
  { 'bag', 'commit ignores seq', 'if not p or p.seq ~= seq then', 'if not p then' },
  { 'bag', 'fingerprint ignores quantity', 'h = (h * 31 + items[id]) % MODULUS', 'h = h' },
  { 'bag', 'commit wrong baseline', 'self.base = p.items\n  self.fp = p.fp', 'self.base = self.base\n  self.fp = p.fp' },
  -- Valuation
  { 'val', 'pending treated as invalid', "if status == 'pending' or status == 'secret' then", 'if false then' },
  { 'val', 'manual ignored', 'if mc and mc > info.sellPrice then', 'if false then' },
  { 'val', 'lower manual price wins', 'if mc and mc > info.sellPrice then', 'if mc then' },
  { 'val', 'manual wins a tie', 'if mc and mc > info.sellPrice then', 'if mc and mc >= info.sellPrice then' },
  { 'val', 'manual used while item data pending', "if status == 'pending' or status == 'secret' then\n    flags.unknown, flags.pendingInfo = true, true\n    return", "if mc then return { valueEach = mc, valueSrc = 'manual', flags = flags } end\n  if status == 'pending' or status == 'secret' then\n    flags.unknown, flags.pendingInfo = true, true\n    return" },
  { 'val', 'revaluation allowed', "lot.valueSrc ~= 'unknown' then return false end", 'false then return false end' },
  { 'val', 'sell price 0 is unknown', 'n >= 0 and n == math.floor(n) and n < 2 ^ 40', 'n > 0 and n == math.floor(n) and n < 2 ^ 40' },
  { 'val', 'pending window ignored', 'now - lot.t < V.PENDING_WINDOW then return false end', 'false then return false end' },
  { 'val', 'completion rewrites acquisition time', 'lot.valueEach, lot.valueSrc, lot.vt = r.valueEach, r.valueSrc, now', 'lot.valueEach, lot.valueSrc, lot.vt = r.valueEach, r.valueSrc, now; lot.t = now' },
  { 'val', 'invalid lot completed', "if type(f) == 'table' and f.invalid then return false end", '' },
  { 'val', 'wrong bound types', 'info.bindType == 1 or info.bindType == 4', 'info.bindType == 1 or info.bindType == 2' },
  -- Lots
  { 'lots', 'FIFO reversed', 'for _, lot in ipairs(self.s.open) do\n    if lot.itemID == itemID and lot.qtyLeft > 0 then',
    'for i = #self.s.open, 1, -1 do local lot = self.s.open[i]\n    if lot.itemID == itemID and lot.qtyLeft > 0 then' },
  { 'lots', 'consumption not recorded', 'lot.qtyLeft = lot.qtyLeft - p.n', 'lot.qtyLeft = lot.qtyLeft' },
  { 'lots', 'uncovered conversion raises an alarm', 'self.s.quality.shortfall = self.s.quality.shortfall + (want - taken)', 'self.s.quality.shortfall = self.s.quality.shortfall + (want - taken); note(self, \'shortfall\', opts.t, {})' },
  { 'lots', 'shortfall not counted', 'self.s.quality.shortfall = self.s.quality.shortfall + (want - taken)', '' },
  { 'lots', 'allocation remainder dropped', 'shares[big] = shares[big] + (total - given)', 'shares[big] = shares[big]' },
  { 'lots', 'vc not coerced', 'vc = false\n      self.s.quality.vcCoerced', 'self.s.quality.vcCoerced' },
  { 'lots', 'no-sell-price sale not flagged', 'elseif p == 0 then', 'elseif p == -1 then' },
  { 'lots', 'clean sale flagged', 'elseif p == 0 then', 'elseif p >= 0 then' },
  { 'lots', 'unknown price not flagged', "if not isInt(p, 0) then\n        note(self, 'sale-price-unknown'", "if false then\n        note(self, 'sale-price-unknown'" },
  { 'lots', 'alert never called', 'if self.alert then pcall(self.alert, kind, rec) end', '' },
  { 'lots', 'equal split not flagged', "note(self, 'equal-split', opts.t, { copper = copper, items = #ids })", '' },
  { 'lots', 'anomaly ring unbounded', 'while #a.recent > Lots.ANOMALY_RING do table.remove(a.recent, 1) end', '' },
  { 'lots', 'closed summary not updated', 'sum.qty = sum.qty + lot.qty', 'sum.qty = sum.qty' },
  { 'lots', 'merge ignores value', 'lot.itemID, lot.valueEach, lot.valueSrc', 'lot.itemID, 0, lot.valueSrc' },
  { 'lots', 'check misses carried-only items', 'if open[id] == nil and q ~= 0 then', 'if false then' },
  { 'lots', 'completion not booked', 'book(self, lot, lot.valueEach * lot.qty)\n        say(self, \'lot\', lot, \'complete\')\n      end\n    end\n  end\n  return n', 'say(self, \'lot\', lot, \'complete\')\n      end\n    end\n  end\n  return n' },
  { 'lots', 'price weights ignored', 'weights[i] = p * removed[id]', 'weights[i] = removed[id]' },
  { 'lots', 'unallocated copper lost', 'unalloc = unalloc + share', 'unalloc = unalloc' },
  { 'lots', 'emptied lots not closed', 'if lot.qtyLeft == 0 then closeLot(self, lot) else', 'if lot.qtyLeft == 0 then else' },
  { 'lots', 'ids reused', 's.nextId = s.nextId + 1\n  s.open', 's.open' },
  { 'lots', 'via totals not counted', 'bv.n, bv.qty, bv.copper = bv.n + 1, bv.qty + p.n, bv.copper + c', '' },
  { 'lots', 'unknown keeps value', "each = 0\n    flags.unknown = true", 'flags.unknown = true' },
  { 'lots', 'bad via accepted', 'if not VIA[via] then return convs, short, 0, \'bad via\' end', '' },
  { 'lots', 'partial piece copper not exact', 'local pc = share > 0 and Lots.AllocateCopper(share, pw) or {}', 'local pc = {}' },
  { 'lots', 'transfer totals wrong', 'elseif f.transfer or f.opening or f.gap then\n    t.transfer.value = t.transfer.value + copper', 'elseif false then\n    t.transfer.value = t.transfer.value + copper' },
}

T.describe('item pipeline M1: scenario suite and mutation checks', function()
  T.it('the unmutated modules pass every scenario', function()
    T.eq(scenarios(SRC), {})
  end)
  for _, m in ipairs(MUTANTS) do
    T.it('mutant caught: ' .. m[2], function()
      local src = {}
      for k, v in pairs(SRC) do src[k] = v end
      local s, e = src[m[1]]:find(m[3], 1, true)
      T.truthy(s, 'anchor not found: ' .. m[2])
      src[m[1]] = src[m[1]]:sub(1, s - 1) .. m[4] .. src[m[1]]:sub(e + 1)
      local ok, fails = pcall(scenarios, src)
      T.truthy((not ok) or #fails > 0, 'mutant survived: ' .. m[2])
    end)
  end
end)
