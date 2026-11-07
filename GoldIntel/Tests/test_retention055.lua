--[[
Tests / test_retention055.lua                (0.5.5: retention stopgap R-1, R-2, R-3, D-098, user 2026-11-07)

R-1 cash keeps 6000 raw entries per character before folding (was 2000).
R-2 open lots: cap 4000 (was 1500); lots merge only when they also share zone, subzone and activity.
R-3 trace.keep holds at most one "-> unexplained" line per item id per interval (the rolling trace keeps every line).
]]

local T = require('testlib')
local Loader = require('loader')
local Fake = require('fake_wow')
local World = require('collectworld')

local ld = loadstring or load
local function lotsModule(src)
  local ns = {}
  assert(ld(Loader.readFile(Loader.root .. '/Ledger/Valuation.lua'), '=Valuation'))('GoldIntel', ns)
  assert(ld(src or Loader.readFile(Loader.root .. '/Ledger/Lots.lua'), '=Lots'))('GoldIntel', ns)
  return ns
end
local function spec(id, t, zone, sub, act)
  return { itemID = id, qty = 1, t = t, src = 'loot', how = 'free', valueEach = 10, valueSrc = 'vendor', vc = true,
           origin = { zone = zone, sub = sub, act = act, x = 0.1 * t, y = 0.2 } }
end

T.describe('R-1 and R-2 limits (D-098)', function()
  T.it('the shipped caps are 6000 cash entries and 4000 open lots', function()
    local W = Fake.new(); World.extend(W)
    local _, ns = Loader.load(W.env)
    T.eq(ns.Cash.CAP, 6000); T.eq(ns.Cash.FOLD, 500)
    T.eq(lotsModule().Lots.CAP_OPEN, 4000)
  end)
end)

local function mergeScenario(src)
  local ns = lotsModule(src)
  local state = {}
  local L = ns.Lots.New(state, { capOpen = 3 })
  L:Add(spec(1, 1, 'Durotar', 'Razor Hill', 'GRIND'))
  L:Add(spec(1, 2, 'The Barrens', 'The Crossroads', 'GRIND'))
  L:Add(spec(1, 3, 'Durotar', 'Razor Hill', 'GATHER'))
  L:Add(spec(1, 4, 'Durotar', 'Razor Hill', 'GRIND'))     -- same place and activity as lot 1: may merge
  L:Add(spec(1, 5, 'Durotar', 'Razor Hill', 'GRIND'))
  return state, L
end

T.describe('R-2 lots merge only within one place and activity (D-098)', function()
  T.it('lots of the same item from different places or activities are never merged', function()
    local state, L = mergeScenario()
    T.eq(#state.open, 3)
    local places = {}
    for _, lot in ipairs(state.open) do places[#places + 1] = lot.origin.zone .. '/' .. lot.origin.sub .. '/' .. lot.origin.act end
    table.sort(places)
    T.eq(places, { 'Durotar/Razor Hill/GATHER', 'Durotar/Razor Hill/GRIND', 'The Barrens/The Crossroads/GRIND' })
    local qty = 0 for _, lot in ipairs(state.open) do qty = qty + lot.qtyLeft end
    T.eq(qty, 5)
    T.eq(L:Stats().merged, 2)
  end)

  T.it('without a shared place nothing merges even above the cap', function()
    local ns = lotsModule()
    local state = {}
    local L = ns.Lots.New(state, { capOpen = 1 })
    L:Add(spec(1, 1, 'A', 'a', 'GRIND')); L:Add(spec(1, 2, 'B', 'b', 'GRIND')); L:Add(spec(1, 3, 'C', 'c', 'GRIND'))
    T.eq(#state.open, 3); T.eq(L:Stats().merged, 0)
  end)

  T.it('mutation is caught: dropping the place from the merge key', function()
    local src = Loader.readFile(Loader.root .. '/Ledger/Lots.lua')
    local a = ", flagKey(lot.flags), placeKey(lot) }, '|')"
    T.truthy(src:find(a, 1, true), 'anchor')
    local mutated = src:gsub(a:gsub('%p', '%%%0'), ", flagKey(lot.flags) }, '|')")
    local state = mergeScenario(mutated)
    local zones = {}
    for _, lot in ipairs(state.open) do zones[lot.origin.zone .. lot.origin.act] = true end
    T.falsy(zones['The BarrensGRIND'] and zones['DurotarGATHER'] and zones['DurotarGRIND'], 'the mutant kept all three places')
  end)
end)

T.describe('R-3 one unexplained line per item id per interval in trace.keep (D-098)', function()
  local function boot()
    local W = Fake.new(); World.extend(W)
    W.state.money = 1000
    local P, ns = Loader.load(W.env)
    W:login()
    W.env.SlashCmdList.GOLDINTEL('collect on'); W:advance(1)
    return W, P, ns
  end
  local function count(list, text) local n = 0 for _, l in ipairs(list or {}) do if l:find(text, 1, true) then n = n + 1 end end return n end

  T.it('repeated unexplained adds of one item keep one line; every line stays in the rolling trace', function()
    local W, _, ns = boot()
    for _ = 1, 4 do ns.Trace.Line('ITEM add item=4570 qty=1 -> unexplained reason="no matching signal (none)"') end
    ns.Trace.Line('ITEM add item=3292 qty=1 -> unexplained reason="no matching signal (none)"')
    local tr = W.env.GoldIntelCharDB.trace
    T.eq(count(tr.keep, 'item=4570'), 1); T.eq(count(tr.keep, 'item=3292'), 1)
    T.eq(count(tr.lines, 'item=4570'), 4)
  end)

  T.it('a new interval keeps the first line of each item again; other kept kinds are not limited', function()
    local W, _, ns = boot()
    ns.Trace.Line('ITEM add item=4570 qty=1 -> unexplained reason="x"')
    W.env.SlashCmdList.GOLDINTEL('collect off'); W.env.SlashCmdList.GOLDINTEL('collect on'); W:advance(1)
    ns.Trace.Line('ITEM add item=4570 qty=1 -> unexplained reason="x"')
    ns.Trace.Line('NOTE one'); ns.Trace.Line('NOTE one')
    local tr = W.env.GoldIntelCharDB.trace
    T.eq(count(tr.keep, 'item=4570'), 2)
    T.eq(count(tr.keep, 'NOTE one'), 2)
  end)
end)
