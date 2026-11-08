--[[
Tests / test_p4m1.lua               (Phase 4 P4-M1: Aggregate/Clock.lua and Aggregate/Aggregator.lua; D-099)

Pure modules, NOT listed in the TOC (no live change). Checked here: the time classes of D-054 / D-055 / AM-3 with the
user's Q-3 split by current activity, the aggregate cells, every visited heat bin (Q-2), heat credit only for
GRIND / GATHER / FISH (D-005, D-044), exact sums (the live check), back-fill without time (Q-4), segments, purity,
and deliberate bugs that the scenarios must catch.
]]

local T = require('testlib')
local Loader = require('loader')

local ld = loadstring or load
local SRC = {
  clock = Loader.readFile(Loader.root .. '/Aggregate/Clock.lua'),
  agg = Loader.readFile(Loader.root .. '/Aggregate/Aggregator.lua'),
}

-- a sandbox with the Lua standard library only: a module that touches any client global fails here
local function sandbox()
  return { math = math, table = table, string = string, tostring = tostring, tonumber = tonumber, type = type,
           pairs = pairs, ipairs = ipairs, setmetatable = setmetatable, pcall = pcall, error = error, next = next }
end
local function loadMods(src)
  src = src or SRC
  local ns, env = {}, sandbox()
  local f1 = load and (pcall(load, src.clock, '=Clock', 't', env)) and load(src.clock, '=Clock', 't', env) or assert(ld(src.clock, '=Clock'))
  local f2 = load and (pcall(load, src.agg, '=Aggregator', 't', env)) and load(src.agg, '=Aggregator', 't', env) or assert(ld(src.agg, '=Aggregator'))
  f1('GoldIntel', ns); f2('GoldIntel', ns)
  return ns, env
end

local function loc(x, y, mapID, sub, zone) return { mapID = mapID or 1411, zone = zone or 'Durotar', sub = sub or 'Razor Hill', x = x, y = y } end
local function yards(a, b)            -- test distance: 1.0 map unit = 1000 yards, same map only
  if a.mapID ~= b.mapID or not a.x or not b.x then return nil end
  return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) * 1000
end

-- drives a clock for `secs` seconds in 0.5 s ticks; events = { [gt] = fn(C, gt) }; pos(gt) -> loc
local function drive(C, from, secs, pos, events, flags)
  local out = {}
  local gt = from
  while gt < from + secs - 1e-9 do
    gt = gt + 0.5
    local e = events and events[gt]
    if e then e(C, gt) end
    for _, s in ipairs(C:Tick(gt, 0.5, pos(gt), flags and flags(gt) or nil)) do out[#out + 1] = s end
  end
  return out, gt
end
local function sumBy(slices, key)
  local t = {}
  for _, s in ipairs(slices) do t[s[key]] = (t[s[key]] or 0) + s.dt end
  return t
end

---------------------------------------------------------------------------
T.describe('P4-M1 Clock (D-054, D-055, AM-3, Q-3)', function()
  T.it('grinding with a kill every 20 s is active GRIND after the first kill (OTHER before it; a slice takes the state at its end)', function()
    local ns = loadMods()
    local C = ns.Clock.New{ distance = yards }
    C:Life(0)
    local ev = {}
    for k = 10, 300, 20 do ev[k] = function(c, gt) c:Productive(gt, 'GRIND', loc(0.5 + gt * 0.0001, 0.5)) end end
    local out, last = drive(C, 0, 300, function(gt) return loc(0.5 + gt * 0.0001, 0.5) end, ev)
    for _, s in ipairs(C:Flush(last)) do out[#out + 1] = s end
    local by = sumBy(out, 'act')
    T.eq(by.OTHER, 9.5); T.eq(by.GRIND, 290.5)
    local st = C:Stats()
    T.eq(st.active, 300); T.eq(st.idle, 0); T.eq(st.pending, 0)
  end)

  T.it('standing still with no signal for 200 s is idle; a 60 s wait is not', function()
    local ns = loadMods()
    local C = ns.Clock.New{ distance = yards }
    C:Life(0)
    local here = function() return loc(0.5, 0.5) end
    local ev = { [60] = function(c, gt) c:Productive(gt, 'GRIND', here()) end,
                 [260] = function(c, gt) c:Productive(gt, 'GRIND', here()) end }
    drive(C, 0, 280, here, ev)
    C:Flush(280)
    local st = C:Stats()
    T.eq(st.idle, 200)            -- 60 .. 260 is a 200 s gap without life
    T.eq(st.active, 80)           -- 0 .. 60 (a 60 s gap) and 260 .. 280
  end)

  T.it('fishing casts are life: an hour of casts every 20 s is never idle (D-055)', function()
    local ns = loadMods()
    local C = ns.Clock.New{ distance = yards }
    C:Life(0)
    local ev = {}
    for k = 5, 3600, 20 do ev[k] = function(c, gt) c:Productive(gt, 'FISH', loc(0.4, 0.4)) end end
    drive(C, 0, 3600, function() return loc(0.4, 0.4) end, ev)
    C:Flush(3600)
    T.eq(C:Stats().idle, 0)
  end)

  T.it('a manual pause and a taxi are decided at once and never become active slices', function()
    local ns = loadMods()
    local C = ns.Clock.New{ distance = yards }
    C:Life(0)
    C:Manual('afk')
    local out = drive(C, 0, 30, function() return loc(0.5, 0.5) end)
    C:Manual(nil)
    local out2 = drive(C, 30, 30, function(gt) return loc(0.1 + gt * 0.001, 0.5) end, nil, function() return { taxi = true } end)
    T.eq(#out + #out2, 0)
    local st = C:Stats()
    T.eq(st.paused, 30); T.eq(st.travelHard, 30)
  end)

  T.it('soft travel: a fast run far from the last kill with no kill for 90 s is TRAVEL; camp-to-camp is not', function()
    local ns = loadMods()
    local C = ns.Clock.New{ distance = yards }
    C:Life(0)
    local pos = function(gt)
      if gt <= 30 then return loc(0.5, 0.5) end
      return loc(0.5 + (gt - 30) * 0.012, 0.5)       -- 12 yards per second after t = 30
    end
    local ev = { [30] = function(c, gt) c:Productive(gt, 'GRIND', pos(gt)) end,
                 [120] = function(c, gt) c:Productive(gt, 'GRIND', pos(gt)) end }
    drive(C, 0, 130, pos, ev)
    C:Flush(130)
    local st = C:Stats()
    -- between 30 and 120 (a 90 s dry gap) the slices more than 150 yards away (after about 42.5 s) are travel
    T.truthy(st.travelSoft >= 75 and st.travelSoft <= 78, 'travelSoft ' .. st.travelSoft)
    -- the same run with a kill every 40 s (camp to camp) has no travel
    local C2 = ns.Clock.New{ distance = yards }
    C2:Life(0)
    local ev2 = {}
    for k = 30, 130, 40 do ev2[k] = function(c, gt) c:Productive(gt, 'GRIND', pos(gt)) end end
    drive(C2, 0, 130, pos, ev2)
    C2:Flush(130)
    T.eq(C2:Stats().travelSoft, 0)
  end)

  T.it('without a distance function soft travel is not decided: the run counts as active and is counted as unknown', function()
    local ns = loadMods()
    local C = ns.Clock.New{}
    C:Life(0)
    local pos = function(gt) return loc(0.5 + gt * 0.012, 0.5) end
    drive(C, 0, 100, pos, { [1] = function(c, gt) c:Productive(gt, 'GRIND', pos(gt)) end })
    C:Flush(100)
    local st = C:Stats()
    T.eq(st.travelSoft, 0); T.truthy(st.travelUnknown > 0); T.eq(st.active, 100)
  end)

  T.it('Q-3: time is split by the current activity, and a manual override wins', function()
    local ns = loadMods()
    local C = ns.Clock.New{ distance = yards }
    C:Life(0)
    local here = function() return loc(0.5, 0.5) end
    local ev = { [10] = function(c, gt) c:Productive(gt, 'GRIND', here()) end,
                 [50] = function(c, gt) c:Productive(gt, 'GATHER', here()) end,
                 [90] = function(c, gt) c:Override('DUNGEON') end }
    local out = drive(C, 0, 100, here, ev)
    for _, s in ipairs(C:Flush(100)) do out[#out + 1] = s end
    local by = sumBy(out, 'act')
    T.eq(by.OTHER, 9.5); T.eq(by.GRIND, 40); T.eq(by.GATHER, 40); T.eq(by.DUNGEON, 10.5)
  end)

  T.it('every slice gets exactly one class: the classes sum to the logged-in time (random play)', function()
    local ns = loadMods()
    local seed = 7
    local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
    for _ = 1, 20 do
      local C = ns.Clock.New{ distance = yards }
      C:Life(0)
      local total, x, gt = 0, 0.5, 0
      for _ = 1, 1500 do
        gt = gt + 0.5
        local r = rnd()
        if r < 0.03 then C:Productive(gt, ({ 'GRIND', 'GATHER', 'FISH' })[1 + math.floor(rnd() * 3)], loc(x, 0.5)) end
        if r > 0.97 then C:Manual(C.manual and nil or 'pause') end
        if rnd() < 0.5 then x = x + (rnd() - 0.4) * 0.02 end
        C:Tick(gt, 0.5, loc(x, 0.5), { taxi = r > 0.995 })
        total = total + 0.5
      end
      C:Flush(gt)
      local st = C:Stats()
      T.eq(st.active + st.idle + st.travelHard + st.travelSoft + st.paused, total)
      T.eq(st.pending, 0)
    end
  end)
end)

---------------------------------------------------------------------------
T.describe('P4-M1 Aggregator (D-099 Q-1, Q-2, Q-4)', function()
  local function new()
    local ns = loadMods()
    local state, heat = {}, {}
    return ns.Aggregator.New(state, heat, { locale = 'enUS' }), state, heat, ns
  end

  T.it('keys: place mapID:locale:subzone, instance by name, cell activity|bracket, bin row*32+col', function()
    local _, _, _, ns = new()
    local AG = ns.Aggregator
    T.eq((AG.PlaceKey(loc(0.1, 0.2), 'enUS')), '1411:enUS:Razor Hill')
    T.eq((AG.PlaceKey({ zone = 'Ragefire Chasm' }, 'enUS')), 'i:Ragefire Chasm')
    T.isnil(AG.PlaceKey({}, 'enUS'))
    T.eq(AG.Bracket(1), '0'); T.eq(AG.Bracket(5), '0'); T.eq(AG.Bracket(6), '1'); T.eq(AG.Bracket(23), '4'); T.eq(AG.Bracket(nil), '?')
    T.eq(AG.BinIndex(0, 0), 0); T.eq(AG.BinIndex(0.999, 0.999), 1023); T.eq(AG.BinIndex(1.0, 1.0), 1023)
    T.eq(AG.BinIndex(0.5, 0.25), 8 * 32 + 16)
  end)

  T.it('cash: loot coin, cash in and out per cell; credit only creditable GRIND/GATHER/FISH coin', function()
    local A, state, heat = new()
    A:AddCash{ copper = 12, src = 'loot', act = 'GRIND', loc = loc(0.5, 0.5), level = 12, creditable = true }
    A:AddCash{ copper = 300, src = 'vendor', act = 'VENDOR', loc = loc(0.5, 0.5), level = 12 }
    A:AddCash{ copper = -100, src = 'trainer', act = 'TRAINER', loc = loc(0.5, 0.5), level = 12 }
    A:AddCash{ copper = 50, src = 'quest', act = 'QUEST', loc = loc(0.5, 0.5), level = 12, creditable = false }
    A:AddCash{ copper = 7, src = 'loot', act = 'GRIND', loc = loc(0.5, 0.5), level = 12, creditable = false }   -- stale position
    local p = state.places['1411:enUS:Razor Hill']
    T.eq(p.cells['GRIND|2'].coin, 19); T.eq(p.cells['GRIND|2'].cin, 19)
    T.eq(p.cells['VENDOR|2'].cin, 300); T.eq(p.cells['VENDOR|2'].coin, 0)
    T.eq(p.cells['TRAINER|2'].cout, 100)
    local b = heat[1411][ns_bin or (16 * 32 + 16)]
    T.eq(b.c, 12); T.eq(b.a.GRIND, 12); T.isnil(b.a.VENDOR)
    local tot = state.totals
    T.eq(tot.cin, 369); T.eq(tot.cout, 100); T.eq(tot.coin, 19)
  end)

  T.it('lots: value created and item counts per cell; only vc lots; heat credit for GRIND/GATHER/FISH only', function()
    local A, state, heat = new()
    A:AddLot{ itemID = 2589, qty = 2, valueEach = 13, vc = true, origin = { mapID = 1411, zone = 'Durotar', sub = 'Razor Hill', x = 0.5, y = 0.5, act = 'GRIND' }, level = 9 }
    A:AddLot{ itemID = 2589, qty = 1, valueEach = 13, vc = true, origin = { mapID = 1411, zone = 'Durotar', sub = 'Razor Hill', x = 0.5, y = 0.5, act = 'GRIND' }, level = 9 }
    A:AddLot{ itemID = 3277, qty = 1, valueEach = 30, vc = true, origin = { mapID = 1411, zone = 'Durotar', sub = 'Razor Hill', x = 0.5, y = 0.5, act = 'QUEST' }, level = 9 }
    A:AddLot{ itemID = 7005, qty = 1, valueEach = 2, vc = false, origin = { mapID = 1411, zone = 'Durotar', sub = 'Razor Hill', x = 0.5, y = 0.5, act = 'VENDOR' }, level = 9 }
    local c = state.places['1411:enUS:Razor Hill'].cells
    T.eq(c['GRIND|1'].vc, 39); T.eq(c['GRIND|1'].q[2589], 3)
    T.eq(c['QUEST|1'].vc, 30)
    T.isnil(c['VENDOR|1'])
    T.eq(state.totals.vc, 69)
    T.eq(heat[1411][16 * 32 + 16].c, 39)
  end)

  T.it('time: every ACTIVE slice adds seconds to its cell and to its heat bin, for every activity (Q-2)', function()
    local A, state, heat = new()
    A:AddTime{ dt = 0.5, loc = loc(0.5, 0.5), act = 'GRIND', level = 9 }
    A:AddTime{ dt = 0.5, loc = loc(0.51, 0.5), act = 'OTHER', level = 9 }
    A:AddTime{ dt = 0.5, loc = { zone = 'Ragefire Chasm' }, act = 'GRIND', level = 9 }
    T.eq(state.places['1411:enUS:Razor Hill'].cells['GRIND|1'].s, 0.5)
    T.eq(state.places['1411:enUS:Razor Hill'].cells['OTHER|1'].s, 0.5)
    T.eq(heat[1411][16 * 32 + 16].s, 1.0); T.eq(heat[1411][16 * 32 + 16].c, 0)
    T.eq(state.places['i:Ragefire Chasm'].cells['GRIND|1'].s, 0.5)
    T.eq(state.totals.s, 1.5)
  end)

  T.it('the live check is exact over a random stream (sum of cells = ledger net; value = created value)', function()
    local seed = 11
    local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
    for _ = 1, 10 do
      local A, state = new()
      local net, created = 0, 0
      for _ = 1, 400 do
        local r = rnd()
        local where = rnd() < 0.1 and nil or loc(rnd(), rnd(), 1411 + math.floor(rnd() * 3), 'S' .. math.floor(rnd() * 4))
        if r < 0.6 then
          local c = math.floor(rnd() * 200) - 60
          if c ~= 0 then A:Enqueue('cash', { copper = c, src = c > 0 and 'loot' or 'other', act = 'GRIND', loc = where, level = 10, creditable = true }); net = net + c end
        else
          local q, v = 1 + math.floor(rnd() * 4), math.floor(rnd() * 50)
          A:Enqueue('lot', { itemID = 100 + math.floor(rnd() * 20), qty = q, valueEach = v, vc = true, origin = where and { mapID = where.mapID, zone = where.zone, sub = where.sub, x = where.x, y = where.y, act = 'GRIND' } or nil, level = 10 })
          created = created + q * v
        end
        if rnd() < 0.3 then A:Drain() end
      end
      A:Drain()
      local chk = A:Check(net, created)
      T.eq(chk.cash, 0); T.eq(chk.vc, 0)
      -- the place cells add up to the totals except entries without a place (counted)
      local cin, cout = 0, 0
      for _, p in pairs(state.places) do for _, c in pairs(p.cells) do cin = cin + c.cin; cout = cout + c.cout end end
      T.truthy(cin <= state.totals.cin and cout <= state.totals.cout)
    end
  end)

  T.it('back-fill (Q-4): value and items of the saved raw records once, no time, marked; completeness recorded', function()
    local A, state, heat = new()
    local ledger = {
      locs = { { mapID = 1411, zone = 'Durotar', sub = 'Razor Hill' }, { zone = 'Ragefire Chasm' } },
      cash = { { c = 12, src = 'loot', act = 'GRIND', l = 1, x = 0.5, y = 0.5, cr = true, lc = 'fresh', t = 100 },
               { c = -330, src = 'other', act = 'OTHER', l = 1, t = 101 },
               { c = 9, src = 'loot', act = 'LOOT', l = 2, t = 102, cp = 'split' } },
      totals = { folded = 0 },
    }
    local lots = { open = { { itemID = 2589, qty = 2, valueEach = 13, vc = true, t = 100, locConf = 'fresh',
                              origin = { mapID = 1411, zone = 'Durotar', sub = 'Razor Hill', x = 0.5, y = 0.5, act = 'GRIND' } } },
                   closed = { { itemID = 818, qty = 1, valueEach = 100, vc = true, t = 90, origin = { zone = 'Ragefire Chasm', act = 'LOOT' } } },
                   totals = { created = { n = 5 } } }
    local ok, n = A:Backfill(ledger, lots)
    T.truthy(ok); T.eq(n, 5)
    local c = state.places['1411:enUS:Razor Hill'].cells['GRIND|?']
    T.eq(c.coin, 12); T.eq(c.vc, 26); T.eq(c.q[2589], 2); T.eq(c.s, 0); T.truthy(c.bf)
    T.eq(state.places['i:Ragefire Chasm'].cells['LOOT|?'].vc, 100)
    T.eq(state.totals.s, 0)
    T.eq(heat[1411][16 * 32 + 16].c, 12 + 26)
    T.eq(state.backfilled.lotsCreated, 5)
    T.eq((A:Backfill(ledger, lots)), false, 'only once')
  end)

  T.it('segments close on a change of place, activity or level and are capped', function()
    local A, state, _, ns = new()
    ns.Aggregator.SEG_CAP = 3
    for i = 1, 6 do A:AddTime{ dt = 1, loc = loc(0.5, 0.5, 1411, 'S' .. i), act = 'GRIND', level = 9, t = i } end
    T.eq(#state.segments, 3); T.eq(state.segments[3].place, '1411:enUS:S5')
    ns.Aggregator.SEG_CAP = 200
  end)

  T.it('the modules are pure: they load in a standard-library sandbox and create no globals', function()
    local _, env = loadMods()
    local extra = {}
    for k in pairs(env) do
      if not ({ math = 1, table = 1, string = 1, tostring = 1, tonumber = 1, type = 1, pairs = 1, ipairs = 1,
                setmetatable = 1, pcall = 1, error = 1, next = 1 })[k] then extra[#extra + 1] = k end
    end
    T.eq(extra, {})
  end)

  T.it('P4-M2 (0.6.0): the TOC loads the Aggregate files after the ledger, Clock and Aggregator before Live', function()
    local pos = {}
    for i, f in ipairs(Loader.tocFiles()) do pos[f] = i end
    T.truthy(pos['Aggregate/Clock.lua'] and pos['Aggregate/Aggregator.lua'] and pos['Aggregate/Live.lua'])
    T.truthy(pos['Ledger/Ledger.lua'] < pos['Aggregate/Clock.lua'])
    T.truthy(pos['Aggregate/Clock.lua'] < pos['Aggregate/Live.lua'] and pos['Aggregate/Aggregator.lua'] < pos['Aggregate/Live.lua'])
  end)
end)

---------------------------------------------------------------------------
-- deliberate bugs that the scenarios must catch
---------------------------------------------------------------------------
local function scenarioClock(ns)
  local C = ns.Clock.New{ distance = yards }
  C:Life(0)
  local here = function() return loc(0.5, 0.5) end
  drive(C, 0, 280, here, { [60] = function(c, gt) c:Productive(gt, 'GRIND', here()) end, [260] = function(c, gt) c:Productive(gt, 'GRIND', here()) end })
  C:Flush(280)
  assert(C:Stats().idle == 200, 'idle')
  local C2 = ns.Clock.New{ distance = yards }
  C2:Life(0)
  local pos = function(gt) if gt <= 30 then return loc(0.5, 0.5) end return loc(0.5 + (gt - 30) * 0.012, 0.5) end
  drive(C2, 0, 130, pos, { [30] = function(c, gt) c:Productive(gt, 'GRIND', pos(gt)) end, [120] = function(c, gt) c:Productive(gt, 'GRIND', pos(gt)) end })
  C2:Flush(130)
  assert(C2:Stats().travelSoft > 70, 'soft travel')
end
local function scenarioAgg(ns)
  local A, state, heat = ns.Aggregator.New({}, {}, { locale = 'enUS' }), nil, nil
  state, heat = A.s, A.h
  A:AddCash{ copper = 12, src = 'loot', act = 'GRIND', loc = loc(0.5, 0.5), level = 12, creditable = true }
  A:AddCash{ copper = 300, src = 'vendor', act = 'VENDOR', loc = loc(0.5, 0.5), level = 12, creditable = true }
  A:AddCash{ copper = -40, src = 'other', act = 'OTHER', loc = loc(0.5, 0.5), level = 12 }
  A:AddCash{ copper = 9, src = 'loot', act = 'LOOT', loc = loc(0.5, 0.5), level = 12, creditable = true }   -- LOOT is not a location activity
  A:AddTime{ dt = 0.5, loc = loc(0.5, 0.5), act = 'OTHER', level = 12 }
  local b = heat[1411][16 * 32 + 16]
  assert(b.c == 12 and b.s == 0.5, 'heat')
  assert(state.places['1411:enUS:Razor Hill'].cells['GRIND|2'].coin == 12, 'coin')
  assert(A:Check(281, 0).cash == 0, 'check')
end

local function mutant(key, a, b, scenario)
  local src = { clock = SRC.clock, agg = SRC.agg }
  local i, j = src[key]:find(a, 1, true)
  assert(i, 'anchor missing: ' .. a)
  src[key] = src[key]:sub(1, i - 1) .. b .. src[key]:sub(j + 1)
  return (pcall(function() scenario(loadMods(src)) end))
end

T.describe('P4-M1 mutation checks', function()
  T.it('the real modules pass the scenarios', function()
    scenarioClock(loadMods()); scenarioAgg(loadMods())
  end)
  local MUT = {
    { 'clock', 'idle needs no full gap', "  if nextv then return nextv - prev >= len - 1e-9 end", "  if nextv then return true end", scenarioClock },
    { 'clock', 'idle threshold ignored', "  local idle = inGap(self.lives, s.gt, self.idleSec, now)", "  local idle = false", scenarioClock },
    { 'clock', 'soft travel never decided', "    if tr then return 'travelSoft' end", "", scenarioClock },
    { 'agg', 'a non-location activity lights the map', "  if coin > 0 and e.creditable and AG.CREDIT[e.act] then", "  if coin > 0 and e.creditable then", scenarioAgg },
    { 'agg', 'time not put in the heat bin', "  if b then b.s = b.s + sl.dt end", "", scenarioAgg },
    { 'agg', 'spending added as income', "  if e.copper > 0 then T.cin = T.cin + e.copper else T.cout = T.cout - e.copper end", "  T.cin = T.cin + math.abs(e.copper)", scenarioAgg },
  }
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[2], function()
      T.falsy(mutant(m[1], m[3], m[4], m[5]), 'the mutant passed: ' .. m[2])
    end)
  end
end)
