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

T.describe('trace keep list (0.5.0)', function()
  T.it('evidence lines survive when routine lines roll out of the window', function()
    local W, _, ns = boot()
    ns.Trace.CAP = 20
    ns.Trace.Line('ANOMALY test -- NOT EXPECTED')
    ns.Trace.Line('CAST spell=2575 kind=mine name=Mining')
    ns.Trace.Line('ITEM add item=1 qty=1 -> unexplained reason="x"')
    for i = 1, 60 do pay(W, 1); W:advance(0.05) end
    local all = ns.Trace.Lines(400)
    T.falsy(has(all, 'ANOMALY test'))                       -- rolled out of the window ...
    local keep = W.env.GoldIntelCharDB.trace.keep
    local function k(text) for _, l in ipairs(keep) do if l:find(text, 1, true) then return true end end end
    T.truthy(k('ANOMALY test'))                             -- ... but kept
    T.truthy(k('kind=mine'))
    T.truthy(k('-> unexplained'))
    T.falsy(k('MONEY'))                                     -- routine lines are not kept
    ns.Trace.CAP = 3000
  end)

  T.it('the keep list is bounded', function()
    local W, _, ns = boot()
    ns.Trace.KEEP_CAP = 10
    for i = 1, 50 do ns.Trace.Line('NOTE n' .. i) end
    T.eq(#W.env.GoldIntelCharDB.trace.keep, 10)
    ns.Trace.KEEP_CAP = 400
  end)
end)

T.describe('context events and periodic check (0.5.1)', function()
  local function keepHas(W, text)
    for _, l in ipairs(W.env.GoldIntelCharDB.trace.keep or {}) do if l:find(text, 1, true) then return l end end
  end

  T.it('a group change is logged and kept', function()
    local W, _, ns = boot()
    W:advance(3)
    W.state.group = { n = 3 }
    W:advance(3)
    local l = has(lines(ns), 'EVT group')
    T.truthy(l, 'no EVT group line')
    T.truthy(l:find('->', 1, true))
    T.truthy(keepHas(W, 'EVT group'))
    local n = 0
    for _, x in ipairs(lines(ns)) do if x:find('EVT group', 1, true) then n = n + 1 end end
    W:advance(5)
    local m = 0
    for _, x in ipairs(lines(ns)) do if x:find('EVT group', 1, true) then m = m + 1 end end
    T.eq(m, n)                                              -- no line without a change
  end)

  T.it('the periodic check records difference 0 and flags a mismatch', function()
    local W, _, ns = boot()
    ns.Trace.CHECK_EVERY = 5
    W:advance(6)
    local l = has(lines(ns), 'EVT check periodic')
    T.truthy(l and l:find('difference=0', 1, true), tostring(l))
    T.falsy(l:find('MISMATCH', 1, true))
    W.state.money = W.state.money + 77                      -- money moves without PLAYER_MONEY: the check must show it
    W:advance(6)
    local found
    for _, x in ipairs(lines(ns)) do if x:find('MISMATCH', 1, true) then found = x end end
    T.truthy(found)
    T.truthy(keepHas(W, 'MISMATCH'))
    ns.Trace.CHECK_EVERY = 600
  end)

  T.it('a final check is written when the interval ends', function()
    local W, _, ns = boot()
    ns.Collector.Off()
    local lastCheck
    for _, x in ipairs(W.env.GoldIntelCharDB.trace.lines) do if x:find('EVT check final', 1, true) then lastCheck = x end end
    T.truthy(lastCheck and lastCheck:find('difference=0', 1, true), tostring(lastCheck))
  end)

  T.it('vendor, mail, trade and auction windows leave one line each', function()
    local W, P, ns = boot()
    for _, e in ipairs({ 'P_VENDOR_OPEN', 'P_VENDOR_CLOSE', 'P_MAIL_OPEN', 'P_MAIL_CLOSE', 'P_AH_OPEN', 'P_AH_CLOSE', 'P_TRADE_OPEN', 'P_TRADE_CLOSE' }) do
      P.Events.Emit(e, {})
    end
    for _, w in ipairs({ 'vendor open', 'vendor close', 'mail open', 'mail close', 'ah open', 'ah close', 'trade open', 'trade close' }) do
      T.truthy(has(lines(ns), 'EVT ' .. w), w)
    end
  end)

  T.it('nothing is recorded without an interval', function()
    local W, P, ns = World.boot()
    ns.Config.Set('collect.auto', false)
    P.Events.Emit('P_VENDOR_OPEN', {})
    W:advance(5)
    T.falsy(W.env.GoldIntelCharDB and W.env.GoldIntelCharDB.trace and #(W.env.GoldIntelCharDB.trace.lines or {}) > 0)
  end)
end)
