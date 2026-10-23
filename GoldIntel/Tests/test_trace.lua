--[[
Tests / test_trace.lua                         (Phase 3b-2 after E-46: Ledger/Trace.lua, diagnostic only)

The trace must (a) record the facts listed in its header, (b) never change a classification, (c) survive its own
failures, (d) be bounded and persisted with the character.
]]

local T = require('testlib')
local World = require('collectworld')
local sim = require('svsim')

local function boot()
  local W, P, ns = World.boot()
  W.state.money = 100000; W:fire('PLAYER_MONEY')
  ns.Collector.On({})                           -- starts the ledger interval and the trace
  W:advance(1.0)
  return W, P, ns
end

local function coinWindow(W, coins, guid)
  local slots = {}
  for i, a in ipairs(coins) do slots[i] = { type = 2, amount = a, guid = guid } end
  W.state.loot = { guid = guid or 'Creature-0-4621-0-1-95-AAAA', slots = slots }
  W:fire('LOOT_OPENED')
end

local function pay(W, d) W.state.money = W.state.money + d; W:fire('PLAYER_MONEY') end

local function lines(ns) return ns.Trace.Lines(400) end
local function has(list, text)
  for _, l in ipairs(list) do if l:find(text, 1, true) then return l end end
end

-- one scripted auto-loot-like burst, returns the entries as comparable text
local function burst(W, ns)
  coinWindow(W, { 5 }, 'Creature-0-4621-0-1-95-AAAA11'); W:advance(0.05)
  pay(W, 5); W:advance(0.05)
  W.state.lootShown = false; W:advance(0.2)
  coinWindow(W, { 3, 4 }, 'Creature-0-4621-0-1-95-BBBB22'); W:advance(0.05)
  pay(W, 7); W:advance(0.05)                    -- one delta for two slots
  pay(W, 9); W:advance(0.05)                    -- money nobody offered
  W.state.lootShown = false; W:advance(3)
  local out = {}
  for _, e in ipairs(ns.Sources.Entries()) do out[#out + 1] = string.format('%s %d %s', e.src, e.copper, e.conf) end
  return out
end

T.describe('trace records the facts', function()
  T.it('window, expectations, money, entries and their timing', function()
    local W, _, ns = boot()
    coinWindow(W, { 5, 3 }); W:advance(0.05)
    pay(W, 5); W:advance(0.05)
    W.state.lootShown = false; W:advance(3)
    local L = lines(ns)
    T.truthy(has(L, 'INTERVAL begin'), 'begin')
    local open = has(L, 'LOOT_OPEN')
    T.truthy(open and open:find('frameShown=true', 1, true), open)
    T.truthy(open and open:find('src=creature', 1, true) and open:find('coins=[5,3]', 1, true), open)
    T.truthy(open:find('numLootItems=2', 1, true) and open:find('s1:t2:a5:g', 1, true) and open:find('s2:t2:a3:g', 1, true), open)
    T.truthy(has(L, 'EXP add #1 loot 5c hold') and has(L, 'EXP add #2 loot 3c hold'))
    local money = has(L, 'MONEY +5')
    T.truthy(money and money:find('#1 loot 5c hold', 1, true) and money:find('#2 loot 3c hold', 1, true), money)
    T.truthy(has(L, 'EXP matched #1'))
    local entry = has(L, 'ENTRY +5 loot high exp=#1')
    T.truthy(entry and entry:find('waited=', 1, true), entry)
    T.truthy(has(L, 'LOOT_CLOSE by=frame'))
    T.truthy(has(L, 'EXP expired UNMATCHED #2 loot 3c'), 'the unmatched slot is visible')
  end)

  T.it('a delta nobody explains is shown with the (empty) active list and the wait before it became OTHER', function()
    local W, _, ns = boot()
    pay(W, 9); W:advance(2.6)
    local L = lines(ns)
    T.truthy(has(L, 'MONEY +9 exact=[] windows=[]'), table.concat(L, '\n'))
    local e = has(L, 'ENTRY +9 other low')
    T.truthy(e and e:find('waited=2.', 1, true), e)
  end)

  T.it('lines carry seconds since the interval and since the previous line', function()
    local W, _, ns = boot()
    pay(W, 2); W:advance(2)
    for _, l in ipairs(lines(ns)) do T.truthy(l:match('^%s*%d+%.%d%d%d %+%d+%.%d%d%d '), l) end
  end)

  T.it('slot clears are recorded', function()
    local W, _, ns = boot()
    coinWindow(W, { 5 }); W:fire('LOOT_SLOT_CLEARED', 1); W:advance(0.1)
    T.truthy(has(lines(ns), 'LOOT_CLEAR slot=1'))
  end)
end)

T.describe('trace is diagnostic only', function()
  T.it('the same burst gives identical entries with the trace on, off, and failing', function()
    local W1, _, ns1 = boot()
    local withTrace = burst(W1, ns1)
    local W2, _, ns2 = boot()
    ns2.Trace.Switch(false)
    local without = burst(W2, ns2)
    local W3, _, ns3 = boot()
    ns3.Sources.tap = function() error('broken tap') end
    ns3.LootModule = nil
    local broken = burst(W3, ns3)
    T.truthy(#withTrace >= 3)
    T.eq(without, withTrace); T.eq(broken, withTrace)
    T.eq(ns3.Sources.Stats().sumDeltas, ns3.Sources.Stats().sumEntries)
  end)

  T.it('a failing loot tap does not stop the window', function()
    local W, P, ns = boot()
    P.LootModule.tap = function() error('broken') end
    coinWindow(W, { 5 }); W:advance(0.05); pay(W, 5); W:advance(0.2)
    T.eq(ns.Sources.Entries()[1].src, 'loot')
  end)
end)

T.describe('trace storage and command', function()
  T.it('is bounded to CAP lines and keeps the newest', function()
    local W, _, ns = boot()
    ns.Trace.CAP = 30
    for i = 1, 60 do pay(W, 1); W:advance(0.05) end
    local L = lines(ns)
    T.truthy(#L <= 30)
    ns.Trace.CAP = 400
  end)

  T.it('is saved with the character and readable after a reload', function()
    local W, P, ns = boot()
    coinWindow(W, { 5 }); W:advance(0.05); pay(W, 5); W:advance(0.2)
    W:fire('PLAYER_LOGOUT')
    local saved = sim.parse(sim.dump(W.env.GoldIntelCharDB))
    T.truthy(saved.trace and #saved.trace.lines > 5)
    T.truthy(has(saved.trace.lines, 'INTERVAL end'))
  end)

  T.it('/gi ledger trace prints, clears and switches', function()
    local W, _, ns = boot()
    local function run(t) W.printed = {}; W.env.SlashCmdList.GOLDINTEL(t); return W:printedText() end
    coinWindow(W, { 5 }); W:advance(0.05); pay(W, 5); W:advance(0.2)
    local out = run('ledger trace 10')
    T.truthy(out:find('ENTRY +5 loot high', 1, true), out)
    T.truthy(run('ledger trace off'):find('trace: off', 1, true))
    pay(W, 1); W:advance(2)
    T.falsy(has(lines(ns), 'MONEY +1'))
    T.truthy(run('ledger trace on'):find('trace: on', 1, true))
    T.truthy(run('ledger trace clear'):find('cleared', 1, true))
    T.truthy(run('ledger trace'):find('no lines', 1, true))
  end)

  T.it('/gi ledger trace note adds a marker line', function()
    local W, _, ns = boot()
    local function run(t) W.printed = {}; W.env.SlashCmdList.GOLDINTEL(t); return W:printedText() end
    T.truthy(run('ledger trace note part 2 group pulls'):find('note added', 1, true))
    T.truthy(has(lines(ns), 'NOTE part 2 group pulls'))
    T.truthy(run('ledger trace note'):find('usage', 1, true))
    W.env.SlashCmdList.GOLDINTEL('collect off')
    T.truthy(run('ledger trace note x'):find('no interval', 1, true))
  end)

  T.it('nothing is recorded outside an interval', function()
    local W, _, ns = boot()
    W.env.SlashCmdList.GOLDINTEL('collect off')
    ns.Trace.Clear()
    pay(W, 5); W:advance(2)
    T.eq(#lines(ns), 0)
  end)
end)
