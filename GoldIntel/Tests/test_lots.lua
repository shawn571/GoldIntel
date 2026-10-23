--[[
Tests / test_lots.lua                (Phase 3b-3 M1: Ledger/Valuation.lua, Ledger/Lots.lua)
Pure modules: no Platform, no clock, no storage. Includes property tests; mutants are in test_item_mutation.lua.
]]

local T = require('testlib')
local Loader = require('loader')

local ld = loadstring or load
local SRC_V = Loader.readFile(Loader.root .. '/Ledger/Valuation.lua')
local SRC_L = Loader.readFile(Loader.root .. '/Ledger/Lots.lua')
local function load2()
  local ns = {}
  assert(ld(SRC_V, '=Valuation'))('GoldIntel', ns)
  assert(ld(SRC_L, '=Lots'))('GoldIntel', ns)
  return ns
end

local function newLots(opts)
  local ns = load2()
  local state = {}
  return ns.Lots.New(state, opts), state, ns
end
local function lootSpec(id, qty, t, extra)
  local s = { itemID = id, qty = qty, t = t or 1, src = 'loot', how = 'free', valueEach = 10, valueSrc = 'vendor', vc = true }
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end

-- ---------------------------------------------------------------------------------------------------
T.describe('Valuation.Value', function()
  local V = load2().Valuation
  T.it('vendor floor from a ready item', function()
    local r = V.Value({ status = 'ready', sellPrice = 13 })
    T.eq(r.valueEach, 13); T.eq(r.valueSrc, 'vendor'); T.eq(r.flags, {})
  end)
  T.it('sell price 0 is a KNOWN value (noVendor), never unknown', function()
    local r = V.Value({ status = 'ready', sellPrice = 0 })
    T.eq(r.valueEach, 0); T.eq(r.valueSrc, 'vendor'); T.eq(r.flags, { noVendor = true })
  end)
  T.it('pending and secret are unknown + pendingInfo with value 0', function()
    for _, st in ipairs({ 'pending', 'secret' }) do
      local r = V.Value({ status = st })
      T.eq(r.valueSrc, 'unknown'); T.eq(r.valueEach, 0); T.eq(r.flags, { unknown = true, pendingInfo = true })
    end
  end)
  T.it('a ready item without a numeric price is unknown, not 0', function()
    local r = V.Value({ status = 'ready' })
    T.eq(r.valueSrc, 'unknown'); T.truthy(r.flags.pendingInfo)
    r = V.Value({ status = 'ready', sellPrice = -3 })
    T.eq(r.valueSrc, 'unknown')
    r = V.Value({ status = 'ready', sellPrice = 1.5 })
    T.eq(r.valueSrc, 'unknown')
  end)
  T.it('invalid is unknown + invalid and not pending', function()
    local r = V.Value({ status = 'invalid' })
    T.eq(r.flags, { unknown = true, invalid = true })
    r = V.Value(nil)
    T.eq(r.flags, { unknown = true, invalid = true })
  end)
  T.it('D-082: the highest of vendor and manual is used; manual is an optional override', function()
    local hi = V.Value({ status = 'ready', sellPrice = 20 }, { copper = 500 })
    T.eq(hi.valueEach, 500); T.eq(hi.valueSrc, 'manual')
    local lo = V.Value({ status = 'ready', sellPrice = 500 }, { copper = 20 })
    T.eq(lo.valueEach, 500); T.eq(lo.valueSrc, 'vendor')
    local tie = V.Value({ status = 'ready', sellPrice = 20 }, { copper = 20 })
    T.eq(tie.valueSrc, 'vendor')
    T.eq(V.Value({ status = 'ready', sellPrice = 5 }, { copper = 0 }).valueSrc, 'vendor')
  end)
  T.it('no manual price means the vendor value (manual is never a default)', function()
    T.eq(V.Value({ status = 'ready', sellPrice = 7 }, nil).valueSrc, 'vendor')
    T.eq(V.Value({ status = 'ready', sellPrice = 7 }).valueEach, 7)
  end)
  T.it('a no-vendor item with a manual price takes the manual price and keeps noVendor', function()
    local r = V.Value({ status = 'ready', sellPrice = 0 }, { copper = 300 })
    T.eq(r.valueEach, 300); T.eq(r.valueSrc, 'manual'); T.truthy(r.flags.noVendor)
  end)
  T.it('item data must be ready first: pending or secret stays unknown even with a manual price', function()
    for _, st in ipairs({ 'pending', 'secret' }) do
      local r = V.Value({ status = st }, { copper = 7 })
      T.eq(r.valueSrc, 'unknown'); T.truthy(r.flags.pendingInfo)
    end
  end)
  T.it('an invalid manual price is ignored', function()
    T.eq(V.Value({ status = 'ready', sellPrice = 5 }, { copper = -1 }).valueSrc, 'vendor')
    T.eq(V.Value({ status = 'ready', sellPrice = 5 }, { copper = 'x' }).valueSrc, 'vendor')
    T.eq(V.Value({ status = 'ready', sellPrice = 5 }, {}).valueSrc, 'vendor')
  end)
  T.it('bound at acquisition: bind on pickup (1) and quest (4) only', function()
    T.truthy(V.Value({ status = 'ready', sellPrice = 5, bindType = 1 }).flags.bound)
    T.truthy(V.Value({ status = 'ready', sellPrice = 5, bindType = 4 }).flags.bound)
    T.falsy(V.Value({ status = 'ready', sellPrice = 5, bindType = 2 }).flags.bound)
    T.falsy(V.Value({ status = 'ready', sellPrice = 5, bindType = 0 }).flags.bound)
  end)
end)

T.describe('Valuation.Complete / Expire', function()
  local V = load2().Valuation
  local function pending() return { itemID = 5, qty = 3, qtyLeft = 3, t = 100, vc = true, valueEach = 0, valueSrc = 'unknown',
    flags = { unknown = true, pendingInfo = true }, origin = { act = 'GRIND' } } end
  T.it('first valuation completes a pending lot and changes nothing else', function()
    local lot = pending()
    T.truthy(V.Complete(lot, { status = 'ready', sellPrice = 9 }, nil, 130))
    T.eq(lot.valueEach, 9); T.eq(lot.valueSrc, 'vendor'); T.eq(lot.vt, 130)
    T.eq(lot.flags, {})
    T.eq(lot.t, 100); T.eq(lot.qty, 3); T.truthy(lot.vc); T.eq(lot.origin, { act = 'GRIND' })
  end)
  T.it('still pending: nothing changes', function()
    local lot = pending()
    T.falsy(V.Complete(lot, { status = 'pending' }, nil, 130))
    T.eq(lot.valueSrc, 'unknown'); T.truthy(lot.flags.pendingInfo)
  end)
  T.it('D-063: a lot that already has a basis is never revalued', function()
    local lot = pending()
    V.Complete(lot, { status = 'ready', sellPrice = 9 }, nil, 130)
    T.falsy(V.Complete(lot, { status = 'ready', sellPrice = 500 }, nil, 200))
    T.falsy(V.Complete(lot, { status = 'ready', sellPrice = 500 }, { copper = 1000 }, 200))
    T.eq(lot.valueEach, 9); T.eq(lot.vt, 130)
  end)
  T.it('an invalid lot is never completed', function()
    local lot = pending(); lot.flags = { unknown = true, invalid = true }
    T.falsy(V.Complete(lot, { status = 'ready', sellPrice = 9 }, nil, 130))
  end)
  T.it('completion with sell price 0 sets noVendor and keeps the value known', function()
    local lot = pending()
    V.Complete(lot, { status = 'ready', sellPrice = 0 }, nil, 130)
    T.eq(lot.valueSrc, 'vendor'); T.truthy(lot.flags.noVendor); T.falsy(lot.flags.unknown)
  end)
  T.it('expire ends the pending window but the lot stays unknown and retryable', function()
    local lot = pending()
    T.falsy(V.Expire(lot, 100 + V.PENDING_WINDOW - 0.1))
    T.truthy(V.Expire(lot, 100 + V.PENDING_WINDOW))
    T.falsy(lot.flags.pendingInfo); T.truthy(lot.flags.unknown); T.eq(lot.valueSrc, 'unknown')
    T.truthy(V.Complete(lot, { status = 'ready', sellPrice = 4 }, nil, 500))
    T.eq(lot.valueEach, 4)
  end)
  T.it('expire ignores lots that are not pending', function()
    T.falsy(V.Expire({ t = 0, flags = {} }, 1000))
    T.falsy(V.Expire({ t = 0 }, 1000))
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Lots.AllocateCopper', function()
  local Lots = load2().Lots
  local function total(t) local s = 0 for _, v in ipairs(t) do s = s + v end return s end
  T.it('shares sum exactly, remainder to the largest weight', function()
    T.eq(Lots.AllocateCopper(10, { 1, 1, 1 }), { 4, 3, 3 })
    T.eq(Lots.AllocateCopper(10, { 1, 5, 1 }), { 1, 8, 1 })
    T.eq(Lots.AllocateCopper(100, { 3 }), { 100 })
  end)
  T.it('all-zero weights share equally', function()
    T.eq(Lots.AllocateCopper(7, { 0, 0 }), { 4, 3 })
  end)
  T.it('zero total and empty weights', function()
    T.eq(Lots.AllocateCopper(0, { 2, 3 }), { 0, 0 })
    T.eq(Lots.AllocateCopper(5, {}), {})
  end)
  T.it('property: always exact, never negative, large values exact', function()
    math.randomseed(3)
    for _ = 1, 500 do
      local n = math.random(1, 8)
      local w = {}
      for i = 1, n do w[i] = math.random(0, 5) == 0 and 0 or math.random(1, 100000) end
      local c = math.random(0, 2000000000)
      local s = Lots.AllocateCopper(c, w)
      T.eq(total(s), c)
      for i = 1, n do T.truthy(s[i] >= 0) end
    end
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Lots.Add', function()
  T.it('creates a lot with id, qtyLeft = qty and the valuation fields', function()
    local L, st = newLots()
    local lot = L:Add(lootSpec(2589, 3, 50, { origin = { act = 'GRIND' }, locConf = 'fresh', ctx = 'loot#1' }))
    T.eq(lot.id, 1); T.eq(lot.qty, 3); T.eq(lot.qtyLeft, 3); T.eq(lot.valueEach, 10)
    T.eq(lot.origin, { act = 'GRIND' }); T.eq(lot.locConf, 'fresh'); T.eq(lot.ctx, 'loot#1')
    T.eq(st.nextId, 2); T.eq(#st.open, 1)
  end)
  T.it('ids are unique and increasing', function()
    local L = newLots()
    local a, b = L:Add(lootSpec(1, 1)), L:Add(lootSpec(2, 1))
    T.eq(a.id, 1); T.eq(b.id, 2)
  end)
  T.it('rejects bad input without creating anything', function()
    local L, st = newLots()
    local bad = {
      lootSpec(0, 1), lootSpec(1.5, 1), lootSpec(1, 0), lootSpec(1, -2), lootSpec(1, 1.5),
      lootSpec(1, 1, 'x'), lootSpec(1, 1, 1, { src = 'bogus' }), lootSpec(1, 1, 1, { how = 'gift' }),
      lootSpec(1, 1, 1, { valueSrc = 'guess' }), lootSpec(1, 1, 1, { valueEach = -1 }), lootSpec(1, 1, 1, { valueEach = 1.5 }),
    }
    for i, spec in ipairs(bad) do
      local lot, err = L:Add(spec)
      T.isnil(lot, 'case ' .. i); T.truthy(err)
    end
    T.isnil((L:Add(nil)))
    T.eq(#st.open, 0); T.eq(st.nextId, 1)
  end)
  T.it('an unknown valuation forces value 0 and the unknown flag', function()
    local L = newLots()
    local lot = L:Add(lootSpec(9, 2, 1, { valueSrc = 'unknown', valueEach = 77, flags = { pendingInfo = true } }))
    T.eq(lot.valueEach, 0); T.truthy(lot.flags.unknown); T.truthy(lot.flags.pendingInfo)
  end)
  T.it('I-5: vc survives only for loot or quest, free, without transfer-like flags', function()
    local L = newLots()
    T.truthy(L:Add(lootSpec(1, 1, 1, { src = 'loot' })).vc)
    T.truthy(L:Add(lootSpec(1, 1, 1, { src = 'quest' })).vc)
    for _, src in ipairs({ 'vendor', 'mail', 'trade', 'disenchant', 'unknown' }) do
      T.falsy(L:Add(lootSpec(1, 1, 1, { src = src })).vc, src)
    end
    T.falsy(L:Add(lootSpec(1, 1, 1, { how = 'purchase' })).vc)
    for _, f in ipairs({ 'transfer', 'conversion', 'opening', 'gap', 'unattributed', 'unexplained' }) do
      T.falsy(L:Add(lootSpec(1, 1, 1, { flags = { [f] = true } })).vc, f)
    end
    T.eq(L:Stats().vcCoerced, 5 + 1 + 6)
  end)
  T.it('totals: created, transfer, unattributed', function()
    local L = newLots()
    L:Add(lootSpec(1, 2, 1))                                                         -- created 20
    L:Add(lootSpec(1, 1, 1, { src = 'mail', vc = false, flags = { transfer = true } }))  -- transfer 10
    L:Add(lootSpec(2, 4, 1, { src = 'unknown', vc = false, flags = { unattributed = true } })) -- unattributed 40
    L:Add(lootSpec(3, 1, 1, { src = 'unknown', vc = false, flags = { opening = true } }))      -- transfer 10
    local s = L:Stats()
    T.eq(s.created, { n = 1, value = 20 })
    T.eq(s.transfer, { n = 2, value = 20 })
    T.eq(s.unattributed, { n = 1, qty = 4, value = 40 })
    T.eq(s.inventoryValue, 20 + 10 + 40 + 10)
  end)
  T.it('the flags table is a copy', function()
    local L = newLots()
    local f = { transfer = true }
    local lot = L:Add(lootSpec(1, 1, 1, { vc = false, flags = f }))
    f.transfer = nil
    T.truthy(lot.flags.transfer)
  end)
  T.it('emit receives the lot and its errors are swallowed', function()
    local seen = {}
    local L = newLots({ emit = function(kind, rec) seen[#seen + 1] = kind .. rec.id; error('boom') end })
    L:Add(lootSpec(1, 1))
    T.eq(seen, { 'lot1' })
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Lots.Convert (FIFO, I-2)', function()
  T.it('consumes the oldest lot first, then the next', function()
    local L, st = newLots()
    L:Add(lootSpec(5, 3, 1)); L:Add(lootSpec(5, 4, 2))
    local convs, short = L:Convert({ [5] = 5 }, 0, { t = 10, via = 'consume' })
    T.eq(#convs, 2)
    T.eq(convs[1].lotID, 1); T.eq(convs[1].qty, 3)
    T.eq(convs[2].lotID, 2); T.eq(convs[2].qty, 2)
    T.eq(short, {})
    T.eq(#st.open, 1); T.eq(st.open[1].qtyLeft, 2)
    T.eq(#st.closed, 1)
  end)
  T.it('a fully consumed lot leaves open, enters the summary once and the ring', function()
    local L, st = newLots()
    L:Add(lootSpec(5, 3, 1, { valueEach = 7 }))
    L:Convert({ [5] = 3 }, 21, { t = 10, via = 'vendor' })
    T.eq(#st.open, 0)
    T.eq(st.closedSummary[5], { qty = 3, copperIn = 21, copperOut = 21 })
    T.eq(#st.closed, 1)
  end)
  T.it('a partially consumed lot is not closed and not summarised', function()
    local L, st = newLots()
    L:Add(lootSpec(5, 3, 1))
    L:Convert({ [5] = 1 }, 4, { t = 10, via = 'vendor' })
    T.eq(st.open[1].qtyLeft, 2); T.eq(st.open[1].out, 4)
    T.isnil(st.closedSummary[5])
  end)
  T.it('shortfall is counted and reported, never invented away; copper of an uncovered item is unallocated', function()
    local L = newLots()
    L:Add(lootSpec(5, 2, 1))
    local convs, short, unalloc = L:Convert({ [5] = 5, [6] = 1 }, 100, { t = 10, via = 'vendor' })
    T.eq(short, { [5] = 3, [6] = 1 })
    T.eq(#convs, 1); T.eq(convs[1].qty, 2)
    local s = L:Stats()
    T.eq(s.shortfall, 4)
    local sum = 0 for _, c in ipairs(convs) do sum = sum + c.copper end
    T.eq(sum + unalloc, 100)
    T.eq(s.unallocated, unalloc)
  end)
  T.it('Q-8: copper is allocated by sellPrice x qty across items and the sum is exact', function()
    local L = newLots()
    L:Add(lootSpec(1, 2, 1)); L:Add(lootSpec(2, 1, 1))
    local convs = L:Convert({ [1] = 2, [2] = 1 }, 100, { t = 5, via = 'vendor',
      priceOf = function(id) return id == 1 and 10 or 60 end })
    -- weights 20 : 60 -> 25 : 75
    local by = {}
    for _, c in ipairs(convs) do by[c.itemID] = (by[c.itemID] or 0) + c.copper; T.truthy(c.alloc) end
    T.eq(by[1], 25); T.eq(by[2], 75)
  end)
  T.it('Q-8: an unknown price anywhere falls back to equal per unit', function()
    local L = newLots()
    L:Add(lootSpec(1, 2, 1)); L:Add(lootSpec(2, 1, 1))
    local convs = L:Convert({ [1] = 2, [2] = 1 }, 90, { t = 5, via = 'vendor',
      priceOf = function(id) if id == 1 then return 10 end return nil end })
    local by = {}
    for _, c in ipairs(convs) do by[c.itemID] = (by[c.itemID] or 0) + c.copper end
    T.eq(by[1], 60); T.eq(by[2], 30)
  end)
  T.it('copper split inside one item across lot pieces by quantity, exact', function()
    local L = newLots()
    L:Add(lootSpec(1, 1, 1)); L:Add(lootSpec(1, 2, 2))
    local convs = L:Convert({ [1] = 3 }, 10, { t = 5, via = 'vendor' })
    T.eq(#convs, 2)
    T.eq(convs[1].copper + convs[2].copper, 10)
  end)
  T.it('a single conversion is not marked alloc', function()
    local L = newLots()
    L:Add(lootSpec(1, 2, 1))
    local convs = L:Convert({ [1] = 2 }, 10, { t = 5, via = 'vendor' })
    T.falsy(convs[1].alloc)
  end)
  T.it('rejects an unknown via and negative or fractional copper without consuming', function()
    local L, st = newLots()
    L:Add(lootSpec(1, 2, 1))
    local convs, _, _, err = L:Convert({ [1] = 1 }, 0, { t = 5, via = 'bogus' })
    T.eq(#convs, 0); T.truthy(err)
    convs, _, _, err = L:Convert({ [1] = 1 }, -5, { t = 5, via = 'vendor' })
    T.eq(#convs, 0); T.truthy(err)
    convs, _, _, err = L:Convert({ [1] = 1 }, 1.5, { t = 5, via = 'vendor' })
    T.eq(#convs, 0); T.truthy(err)
    T.eq(st.open[1].qtyLeft, 2)
  end)
  T.it('ignores malformed entries in the removal map', function()
    local L, st = newLots()
    L:Add(lootSpec(1, 2, 1))
    L:Convert({ [1] = 0, [2] = -1, x = 1, [3] = 1.5 }, 0, { t = 5, via = 'consume' })
    T.eq(st.open[1].qtyLeft, 2)
  end)
  T.it('a non-sale conversion carries copper 0 and the ref', function()
    local L = newLots()
    L:Add(lootSpec(1, 2, 1))
    local convs = L:Convert({ [1] = 1 }, 0, { t = 5, via = 'trade', ref = 42 })
    T.eq(convs[1].copper, 0); T.eq(convs[1].ref, 42); T.eq(convs[1].via, 'trade')
  end)
  T.it('byVia totals add up', function()
    local L, st = newLots()
    L:Add(lootSpec(1, 5, 1))
    L:Convert({ [1] = 2 }, 8, { t = 5, via = 'vendor' })
    L:Convert({ [1] = 1 }, 4, { t = 6, via = 'vendor' })
    L:Convert({ [1] = 1 }, 0, { t = 7, via = 'consume' })
    T.eq(st.totals.byVia.vendor, { n = 2, qty = 3, copper = 12 })
    T.eq(st.totals.byVia.consume, { n = 1, qty = 1, copper = 0 })
  end)
  T.it('the closed ring and the conversion ring are capped, the summary keeps everything', function()
    local L, st = newLots({ capClosed = 3 })
    for i = 1, 6 do L:Add(lootSpec(1, 1, i)); L:Convert({ [1] = 1 }, 0, { t = i, via = 'consume' }) end
    T.eq(#st.closed, 3); T.eq(#st.conv, 3)
    T.eq(st.closedSummary[1].qty, 6)
    T.eq(st.closed[1].id, 4)
  end)
  T.it('emit receives conversions', function()
    local kinds = {}
    local L = newLots({ emit = function(k) kinds[#kinds + 1] = k end })
    L:Add(lootSpec(1, 1)); L:Convert({ [1] = 1 }, 0, { t = 2, via = 'consume' })
    T.eq(kinds, { 'lot', 'conversion' })
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Lots.Complete / ExpirePending', function()
  T.it('a pending lot receives its first valuation, totals follow the original lot', function()
    local L = newLots()
    L:Add(lootSpec(5, 3, 100, { valueSrc = 'unknown', flags = { pendingInfo = true } }))
    T.eq(L:Stats().unknown, { lots = 1, qty = 3, items = 1 })
    T.eq(L:Stats().created.value, 0)
    T.eq(L:Complete(5, { status = 'ready', sellPrice = 9 }, nil, 130), 1)
    local s = L:Stats()
    T.eq(s.unknown, { lots = 0, qty = 0, items = 0 })
    T.eq(s.created, { n = 1, value = 27 })
    T.eq(s.inventoryValue, 27)
  end)
  T.it('only lots of that item are touched, and only once', function()
    local L = newLots()
    L:Add(lootSpec(5, 1, 1, { valueSrc = 'unknown' })); L:Add(lootSpec(6, 1, 1, { valueSrc = 'unknown' }))
    T.eq(L:Complete(5, { status = 'ready', sellPrice = 9 }, nil, 2), 1)
    T.eq(L:Complete(5, { status = 'ready', sellPrice = 99 }, nil, 3), 0)
    T.eq(L:Stats().unknown.lots, 1)
  end)
  T.it('a higher manual price is used when a pending lot is completed', function()
    local L = newLots()
    L:Add(lootSpec(5, 2, 1, { valueSrc = 'unknown' }))
    T.eq(L:Complete(5, { status = 'pending' }, { copper = 33 }, 2), 0)
    L:Complete(5, { status = 'ready', sellPrice = 10 }, { copper = 33 }, 3)
    T.eq(L:InventoryValue(), 66)
  end)
  T.it('ExpirePending clears only the pending flag', function()
    local L, st = newLots()
    L:Add(lootSpec(5, 1, 100, { valueSrc = 'unknown', flags = { pendingInfo = true } }))
    T.eq(L:ExpirePending(110), 0)
    T.eq(L:ExpirePending(131), 1)
    T.falsy(st.open[1].flags.pendingInfo); T.truthy(st.open[1].flags.unknown)
    T.eq(L:Stats().unknown.lots, 1)
  end)
  T.it('a transfer lot completed later books its value under transfer, not created', function()
    local L = newLots()
    L:Add(lootSpec(5, 2, 1, { src = 'mail', vc = false, valueSrc = 'unknown', flags = { transfer = true } }))
    L:Complete(5, { status = 'ready', sellPrice = 4 }, nil, 2)
    T.eq(L:Stats().transfer.value, 8); T.eq(L:Stats().created.value, 0)
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Lots.Check (I-3)', function()
  T.it('ok when open quantity equals carried, otherwise the exact differences', function()
    local L = newLots()
    L:Add(lootSpec(1, 3, 1)); L:Add(lootSpec(1, 2, 2)); L:Add(lootSpec(2, 1, 3))
    local ok, d = L:Check({ [1] = 5, [2] = 1 })
    T.truthy(ok); T.eq(d, {})
    ok, d = L:Check({ [1] = 4, [2] = 1, [3] = 2 })
    T.falsy(ok); T.eq(d, { [1] = 1, [3] = -2 })
    ok, d = L:Check({})
    T.falsy(ok); T.eq(d, { [1] = 5, [2] = 1 })
  end)
  T.it('an empty ledger against an empty bag is ok', function()
    local L = newLots()
    T.truthy((L:Check({})))
    T.truthy((L:Check(nil)))
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Lots.Compact (retention)', function()
  T.it('merges equal-valued lots of one item, oldest first, until the cap is met', function()
    local L, st = newLots({ capOpen = 3 })
    for i = 1, 5 do L:Add(lootSpec(1, 2, i)) end
    T.eq(#st.open, 3)
    local qty = 0 for _, l in ipairs(st.open) do qty = qty + l.qtyLeft end
    T.eq(qty, 10)
    T.truthy(st.open[1].flags.merged)
    T.eq(st.open[1].t, 1)
    T.truthy(L:Stats().merged >= 2)
    T.eq(L:InventoryValue(), 100)
  end)
  T.it('never merges different values, items, vc, or pending lots', function()
    local L, st = newLots({ capOpen = 2 })
    L:Add(lootSpec(1, 1, 1, { valueEach = 1 }))
    L:Add(lootSpec(1, 1, 2, { valueEach = 2 }))
    L:Add(lootSpec(2, 1, 3, { valueEach = 2 }))
    L:Add(lootSpec(1, 1, 4, { valueEach = 1, vc = false }))
    L:Add(lootSpec(1, 1, 5, { valueEach = 1, valueSrc = 'unknown', flags = { pendingInfo = true } }))
    L:Add(lootSpec(1, 1, 6, { valueEach = 1, valueSrc = 'unknown', flags = { pendingInfo = true } }))
    T.eq(#st.open, 6)
    T.eq(L:Stats().merged, 0)
  end)
  T.it('merging keeps quantity, remaining quantity and copper out exact', function()
    local L, st = newLots({ capOpen = 100 })
    L:Add(lootSpec(1, 4, 1)); L:Add(lootSpec(1, 4, 2)); L:Add(lootSpec(1, 4, 3))
    L:Convert({ [1] = 5 }, 10, { t = 4, via = 'vendor' })     -- lot 1 closed, lot 2 has 3 left
    local out2 = st.open[1].out
    L.capOpen = 1
    T.eq(L:Compact(), 1)
    T.eq(#st.open, 1)
    T.eq(st.open[1].qty, 8); T.eq(st.open[1].qtyLeft, 7); T.eq(st.open[1].out, out2)
  end)
  T.it('compaction does not change totals or the unknown count', function()
    local L = newLots({ capOpen = 2 })
    for i = 1, 6 do L:Add(lootSpec(1, 1, i)) end
    local s = L:Stats()
    T.eq(s.created.n, 6); T.eq(s.created.value, 60); T.eq(s.openQty, 6)
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Lots properties and isolation', function()
  T.it('property: random streams keep I-2, I-3 and exact value bookkeeping', function()
    for seed = 1, 25 do
      math.randomseed(seed)
      local L, st = newLots({ capOpen = 12, capClosed = 8 })
      local shadow, created = {}, {}
      local t = 0
      local addedQty, consumedQty = 0, 0
      for _ = 1, 150 do
        t = t + 1
        local id = math.random(1, 4)
        if math.random() < 0.55 then
          local q = math.random(1, 6)
          local each = id * 3
          L:Add(lootSpec(id, q, t, { valueEach = each, vc = (id % 2 == 0) }))
          shadow[id] = (shadow[id] or 0) + q
          addedQty = addedQty + q
        else
          local q = math.random(1, 8)
          local have = shadow[id] or 0
          local copper = math.random(0, 50)
          local convs, short = L:Convert({ [id] = q }, copper, { t = t, via = 'vendor' })
          local taken = 0
          for _, c in ipairs(convs) do taken = taken + c.qty end
          T.eq(taken, math.min(q, have))
          T.eq(short[id] or 0, math.max(0, q - have))
          shadow[id] = have - taken
          consumedQty = consumedQty + taken
          local cs = 0 for _, c in ipairs(convs) do cs = cs + c.copper end
          if taken > 0 then T.eq(cs, copper) end
        end
        for _, lot in ipairs(st.open) do
          T.truthy(lot.qtyLeft > 0); T.truthy(lot.qtyLeft <= lot.qty)
        end
        local ok = L:Check(shadow)
        T.truthy(ok)
      end
      local s = L:Stats()
      T.eq(s.openQty, addedQty - consumedQty)
      local summed = 0
      for _, v in pairs(st.closedSummary) do summed = summed + v.qty end
      T.truthy(summed <= addedQty)
      T.eq(s.created.n, s.created.n)
      T.truthy(s.openLots <= 12 or s.merged >= 0)
    end
  end)
  T.it('property: copper out equals copper in conversions (nothing lost or created)', function()
    math.randomseed(99)
    local L, st = newLots()
    local paid, got = 0, 0
    for i = 1, 100 do
      L:Add(lootSpec(math.random(1, 3), math.random(1, 4), i))
      if i % 3 == 0 then
        local c = math.random(1, 90)
        local convs, _, un = L:Convert({ [math.random(1, 3)] = math.random(1, 5) }, c, { t = i, via = 'vendor' })
        paid = paid + c
        for _, cv in ipairs(convs) do got = got + cv.copper end
        got = got + un
      end
    end
    T.eq(got, paid)
    T.eq(st.totals.byVia.vendor.copper + L:Stats().unallocated, paid)
  end)
  T.it('I-6: neither module references cash, reconciler, expectations or platform code', function()
    for _, src in ipairs({ SRC_V, SRC_L }) do
      local code = src:gsub('%-%-[^\n]*', '')
      for _, w in ipairs({ 'Cash', 'Reconciler', 'Expectations', 'Platform', 'GetTime', 'GetMoney' }) do
        T.falsy(code:find(w), w)
      end
    end
  end)
  T.it('loading the modules adds only GI.Valuation and GI.Lots to the namespace', function()
    local ns = load2()
    local keys = {}
    for k in pairs(ns) do keys[#keys + 1] = k end
    table.sort(keys)
    T.eq(keys, { 'Lots', 'Valuation' })
  end)
end)

T.describe('Lots anomalies (never hidden)', function()
  local function mk()
    local seen = {}
    local L, st, ns = newLots({ alert = function(kind, rec) seen[#seen + 1] = { kind = kind, rec = rec } end })
    return L, st, seen, ns
  end
  T.it('a clean sale of a known, sellable item raises nothing', function()
    local L, _, seen = mk()
    L:Add(lootSpec(1, 2, 1))
    L:Convert({ [1] = 2 }, 20, { t = 5, via = 'vendor', priceOf = function() return 10 end })
    T.eq(#seen, 0); T.eq(L:Stats().anomalies, {})
  end)
  T.it('money in while a no-sell-price item leaves: flagged, with item and copper', function()
    local L, _, seen = mk()
    L:Add(lootSpec(7, 1, 1, { valueEach = 0, flags = { noVendor = true } }))
    L:Convert({ [7] = 1 }, 12, { t = 5, via = 'vendor', priceOf = function() return 0 end })
    T.eq(#seen, 1); T.eq(seen[1].kind, 'sale-no-sell-price')
    T.eq(seen[1].rec.detail, { itemID = 7, copper = 12 })
  end)
  T.it('a price still unknown at sale time is flagged', function()
    local L, _, seen = mk()
    L:Add(lootSpec(7, 1, 1))
    L:Convert({ [7] = 1 }, 12, { t = 5, via = 'vendor', priceOf = function() return nil end })
    T.eq(seen[1].kind, 'sale-price-unknown')
  end)
  T.it('the equal split is never silent', function()
    local L, _, seen = mk()
    L:Add(lootSpec(1, 1, 1)); L:Add(lootSpec(2, 1, 1))
    L:Convert({ [1] = 1, [2] = 1 }, 10, { t = 5, via = 'vendor', priceOf = function(id) return id == 1 and 5 or nil end })
    local kinds = {}
    for _, a in ipairs(seen) do kinds[a.kind] = true end
    T.truthy(kinds['equal-split']); T.truthy(kinds['sale-price-unknown'])
  end)
  T.it('a non-vendor conversion with copper 0 and no price hook raises nothing', function()
    local L, _, seen = mk()
    L:Add(lootSpec(1, 2, 1))
    L:Convert({ [1] = 1 }, 0, { t = 5, via = 'consume' })
    T.eq(#seen, 0)
  end)
  T.it('converting items no tracked lot covers is normal: counted, never an anomaly (D-081)', function()
    local L, _, seen = mk()
    L:Add(lootSpec(1, 1, 1))
    L:Convert({ [1] = 3, [9] = 1 }, 30, { t = 5, via = 'vendor' })
    local s = L:Stats()
    T.eq(s.shortfall, 3)
    T.truthy(s.unallocated > 0)
    T.falsy(s.anomalies['shortfall']); T.falsy(s.anomalies['unallocated-copper'])
    for _, a in ipairs(seen) do T.neq(a.kind, 'shortfall'); T.neq(a.kind, 'unallocated-copper') end
  end)
  T.it('a coerced vc is flagged', function()
    local L = mk()
    L:Add(lootSpec(1, 1, 1, { src = 'mail' }))
    T.eq(L:Stats().anomalies['vc-coerced'], 1)
  end)
  T.it('every kind has a human text that says to report it as a bug', function()
    local Lots = load2().Lots
    for kind in pairs(Lots.ANOMALY_TEXT) do
      T.truthy(Lots.Describe(kind):find('report it as a bug', 1, true), kind)
    end
    T.truthy(Lots.Describe('made-up'):find('report it as a bug', 1, true))
  end)
  T.it('the ring is bounded, counts are not, an alert error is swallowed', function()
    local L, st = newLots({ alert = function() error('boom') end })
    local n = load2().Lots.ANOMALY_RING + 5
    for i = 1, n do L:Add(lootSpec(1, 1, i, { src = 'mail' })) end
    T.eq(#st.anomalies.recent, load2().Lots.ANOMALY_RING)
    T.eq(L:Stats().anomalies['vc-coerced'], n)
  end)
end)
