--[[
Tests / test_p4m2.lua                    (Phase 4 P4-M2, 0.6.0-passive: Aggregate/Live.lua; D-099, D-102)

The live aggregation in the fake client: the check against the ledger and the lot book is 0, time is classified
(idle, taxi, pause, override), back-fill runs once and survives save and load, login gaps are counted, late item values
follow, the reminder speaks once per hour outside combat only, cash isolation holds, a build without Live runs on the
same data, and deliberate bugs are caught.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local World = require('collectworld')
local Loader = require('loader')
local sim = require('svsim')

local function session(saved, opts)
  opts = opts or {}
  local W = Fake.new()
  World.extend(W)
  W.env.GoldIntelDB = saved and saved.account or nil
  W.env.GoldIntelCharDB = saved and saved.char or nil
  W.state.money = opts.money or (saved and saved.money) or 5000
  if opts.setup then opts.setup(W) end
  Loader.override = opts.override
  local P, ns = Loader.load(W.env)
  Loader.override = nil
  W:login()
  local function run(text) W.printed = {}; W.env.SlashCmdList.GOLDINTEL(text); return W:printedText() end
  if opts.collect ~= false then run('collect on'); W:advance(1) end
  return W, P, ns, run
end
local function save(W)
  W:fire('PLAYER_LOGOUT')
  return { account = sim.parse(sim.dump(W.env.GoldIntelDB)), char = sim.parse(sim.dump(W.env.GoldIntelCharDB)), money = W.state.money }
end
local function pay(W, d) W.state.money = W.state.money + d; W:fire('PLAYER_MONEY') end
local function item(W, id, sell, ready)
  W.state.items[id] = { 'Item' .. id, 'link', 1, 1, 1, '', '', 1, '', 0, sell, 7, 1, 0, 0, 0, 0 }
  W.state.cached[id] = ready ~= false
end
local function coinLoot(W, copper, guid)
  W.state.loot = { guid = guid or 'Creature-0-4621-0-1-95-AAAA', slots = { { type = 2, amount = copper } } }
  W:fire('LOOT_OPENED')
  W:advance(0.3); pay(W, copper); W:advance(0.1)
  W.state.lootShown = false; W:advance(2.5)
end
local function itemLoot(W, id, slot, guid)
  W.state.bags[0] = W.state.bags[0] or { size = 16 }
  W.state.loot = { guid = guid or 'Creature-0-4621-0-1-95-BBBB', slots = { { type = 1, link = '|Hitem:' .. id .. '::|h[x]|h', qty = 1 } } }
  W:fire('LOOT_OPENED', false, false, false)
  W:advance(0.4); W.state.bags[0][slot] = { id, 1 }; W:fire('BAG_UPDATE_DELAYED')
  W.state.loot.slots = {}; W:fire('LOOT_CLOSED'); W:advance(4)
end
local function aggState(W)
  local key = W.state.guid
  return W.env.GoldIntelDB.agg[key], W.env.GoldIntelDB.heat[key]
end

-- D-113: periodic EVT agg / EVT clock lines stay in the rolling trace; trace.keep gets the final pair and any MISMATCH.
local function keepScenario(override)
  local W, _, ns, run = session(nil, { override = override })
  coinLoot(W, 5)
  ns.AggLive.REPORT_EVERY = 5; W:advance(12); ns.AggLive.REPORT_EVERY = 600
  ns.Trace.Line('EVT agg periodic cash=7 vc=0 seconds=10 MISMATCH')
  run('collect off')
  local lines = table.concat(W.env.GoldIntelCharDB.trace.lines, '\n')
  local keep = table.concat(W.env.GoldIntelCharDB.trace.keep, '\n')
  assert(lines:find('EVT agg periodic cash=0', 1, true), 'periodic agg line missing from the rolling trace')
  assert(lines:find('EVT clock periodic active=', 1, true), 'periodic clock line missing from the rolling trace')
  assert(not keep:find('EVT agg periodic cash=0', 1, true), 'periodic agg line kept')
  assert(not keep:find('EVT clock periodic', 1, true), 'periodic clock line kept')
  assert(keep:find('EVT agg periodic cash=7 vc=0 seconds=10 MISMATCH', 1, true), 'MISMATCH line not kept')
  assert(keep:find('EVT agg final cash=0 vc=0', 1, true), 'final agg line not kept')
  assert(keep:find('EVT clock final active=', 1, true), 'final clock line not kept')
end

---------------------------------------------------------------------------
T.describe('P4-M2 live check (D-102)', function()
  T.it('coin, a vendor sale and a looted item: the aggregates equal the ledger and the lot book (0 / 0)', function()
    local W, _, ns, run = session(nil, { money = 5000 })
    item(W, 2589, 13)
    coinLoot(W, 12)
    itemLoot(W, 2589, 1)
    W:fire('MERCHANT_SHOW'); W:advance(0.5); pay(W, 40); W:advance(0.5); W:fire('MERCHANT_CLOSED'); W:advance(3)
    pay(W, -100); W:advance(3)                                   -- unexplained spending
    local r = ns.AggLive.Check()
    T.eq(r.cash, 0); T.eq(r.vc, 0)
    local out = run('agg check')
    T.truthy(out:find('cash difference 0 copper, value difference 0 copper (OK)', 1, true), out)
    local st = aggState(W)
    T.eq(st.totals.coin, 12); T.eq(st.totals.vc, 13)
  end)

  T.it('a login gap booked before the interval starts is counted (crash recovery)', function()
    local W = session(nil, { money = 1000 })
    pay(W, 30); W:advance(3)
    local saved = save(W)
    saved.money = 1500                                            -- +470 while nothing was saved
    local W2, _, ns2 = session(saved)
    T.eq(ns2.Cash.Stats().gapCount, 1)
    local r = ns2.AggLive.Check()
    T.eq(r.cash, 0)
  end)

  T.it('an item whose value arrives later is counted once in quantity and gets its value on completion', function()
    local W, _, ns = session()
    item(W, 777, 25, false)                                       -- not in the item cache yet
    itemLoot(W, 777, 1)
    local st = aggState(W)
    local chk = ns.AggLive.Check(); T.eq(chk.vc, 0)
    W.state.cached[777] = true
    W:fire('GET_ITEM_INFO_RECEIVED', 777, true); W:advance(3)
    chk = ns.AggLive.Check(); T.eq(chk.vc, 0)
    T.eq(st.totals.vc, 25)
    local qty = 0
    for _, pl in pairs(st.places) do for _, c in pairs(pl.cells) do qty = qty + (c.q[777] or 0) end end
    T.eq(qty, 1)
  end)
end)

---------------------------------------------------------------------------
T.describe('P4-M2 time (Clock wired; D-054, D-055, Q-3)', function()
  T.it('play with a kill every 30 s is active time; a 5-minute stand-still is idle; heat seconds are recorded', function()
    local W, _, ns = session()
    for _ = 1, 10 do coinLoot(W, 3); W:advance(27) end           -- about 5 minutes of play
    W:advance(300)                                               -- standing still, no signal
    coinLoot(W, 3); W:advance(5)
    W.env.SlashCmdList.GOLDINTEL('collect off')
    local st, heat = aggState(W)
    -- the 27 s walk after the last kill lies inside the 327 s gap without a signal, so it is idle too (D-054 idle rule)
    T.truthy(st.totals.s >= 260 and st.totals.s <= 300, 'active seconds ' .. st.totals.s)
    T.truthy(ns.AggLive.Stats().slices > 0)
    local binSeconds = 0
    for _, bins in pairs(heat) do for _, b in pairs(bins) do binSeconds = binSeconds + b.s end end
    T.eq(binSeconds, st.totals.s)
  end)

  T.it('time on a taxi and while paused is not counted; /gi activity puts the time under the chosen key', function()
    local W, _, ns, run = session()
    coinLoot(W, 3)
    W.env.UnitOnTaxi = function() return true end
    W:advance(60)
    W.env.UnitOnTaxi = function() return false end
    run('pause'); W:advance(60); run('resume')
    run('activity DUNGEON')
    for _ = 1, 4 do coinLoot(W, 2); W:advance(10) end
    run('collect off')
    local st = aggState(W)
    local dungeon = 0
    for _, pl in pairs(st.places) do for k, c in pairs(pl.cells) do if k:find('^DUNGEON|') then dungeon = dungeon + c.s end end end
    T.truthy(dungeon > 40, 'dungeon seconds ' .. dungeon)
    T.truthy(st.totals.s < 100, 'taxi and pause excluded: ' .. st.totals.s)
    T.truthy(run('activity clear'):find('detected automatically', 1, true))
  end)

  T.it('soft travel uses the map size when the client offers it; without it the run is counted as unknown', function()
    local W, P = session(nil, { setup = function(W) W.env.C_Map.GetMapWorldSize = function() return 1000, 1000 end end })
    T.truthy(P.Distance({ mapID = 1, x = 0.1, y = 0.1 }, { mapID = 1, x = 0.2, y = 0.1 }) - 100 < 1e-6)
    T.isnil(P.Distance({ mapID = 1, x = 0.1, y = 0.1 }, { mapID = 2, x = 0.2, y = 0.1 }))
    local W2, P2 = session(nil, { setup = function(W) W.env.C_Map.GetMapWorldSize = nil end })
    T.isnil(P2.Distance({ mapID = 1, x = 0.1, y = 0.1 }, { mapID = 1, x = 0.2, y = 0.1 }))
  end)
end)

---------------------------------------------------------------------------
T.describe('P4-M2 back-fill and persistence (Q-4)', function()
  T.it('the first start back-fills the saved records once (no time), the check stays 0, and a reload does not repeat it', function()
    -- a session on a build without Live writes ledger and lots
    local empty = { ['Aggregate/Live.lua'] = 'local ADDON, GI = ...\nGI.AggLive = nil\n' }
    local W = session(nil, { money = 2000, override = empty })
    item(W, 2589, 13)
    coinLoot(W, 20); itemLoot(W, 2589, 1)
    local saved = save(W)
    T.isnil(saved.account.agg[W.state.guid])
    -- first start with Live: back-fill
    local W2, _, ns2 = session(saved)
    local st = aggState(W2)
    T.truthy(st.backfilled, 'back-filled')
    T.eq(st.totals.coin, 20); T.eq(st.totals.vc, 13)
    T.eq(st.totals.s >= 0 and st.totals.s < 5, true)
    T.eq(ns2.AggLive.Check().cash, 0); T.eq(ns2.AggLive.Check().vc, 0)
    coinLoot(W2, 7)
    local saved2 = save(W2)
    -- next load: no second back-fill, totals carried over
    local W3, _, ns3 = session(saved2)
    local st3 = aggState(W3)
    T.eq(st3.totals.coin, 27)
    T.eq(ns3.AggLive.Check().cash, 0)
  end)

  T.it('rollback: a build without Live runs on a file that holds agg and heat, and leaves them untouched', function()
    local W = session(nil, { money = 3000 })
    coinLoot(W, 9)
    local saved = save(W)
    local beforeAgg, beforeHeat = saved.account.agg, saved.account.heat
    local empty = { ['Aggregate/Live.lua'] = 'local ADDON, GI = ...\nGI.AggLive = nil\n' }
    local W2, _, ns2 = session(saved, { override = empty })
    coinLoot(W2, 4)
    T.eq(ns2.Ledger.Check().difference, 0)
    local saved2 = save(W2)
    T.eq(saved2.account.agg, beforeAgg); T.eq(saved2.account.heat, beforeHeat)
  end)

  T.it('cash isolation: the ledger entries are identical with the aggregation on and off', function()
    local function play(override)
      local W, _, ns = session(nil, { money = 4000, override = override })
      coinLoot(W, 11); pay(W, -50); W:advance(3)
      W:fire('MERCHANT_SHOW'); pay(W, 22); W:advance(0.5); W:fire('MERCHANT_CLOSED'); W:advance(3)
      local out = {}
      for _, e in ipairs(ns.Sources.Entries()) do out[#out + 1] = e.src .. ' ' .. e.copper .. ' ' .. tostring(e.act) end
      return out
    end
    T.eq(play(nil), play({ ['Aggregate/Live.lua'] = 'local ADDON, GI = ...\nGI.AggLive = nil\n' }))
  end)
end)

---------------------------------------------------------------------------
T.describe('P4-M2 reminder (Q-6)', function()
  local function lines(W, text) local n = 0 for _, l in ipairs(W.printed) do if l:find(text, 1, true) then n = n + 1 end end return n end
  local TEXT = 'minutes since your data was last saved; /reload saves it'

  T.it('one line after 60 minutes, then once per 60 minutes', function()
    local W = session()
    W.printed = {}
    W:advance(59 * 60); T.eq(lines(W, TEXT), 0)
    W:advance(2 * 60); T.eq(lines(W, TEXT), 1)
    T.truthy(W:printedText():find('GoldIntel: 60 minutes since your data was last saved; /reload saves it', 1, true))
    W:advance(50 * 60); T.eq(lines(W, TEXT), 1)
    W:advance(11 * 60); T.eq(lines(W, TEXT), 2)
  end)

  T.it('never in combat: it waits until combat ends', function()
    local W = session()
    W.printed = {}
    W:advance(55 * 60)
    W:fire('PLAYER_REGEN_DISABLED')
    W:advance(10 * 60); T.eq(lines(W, TEXT), 0)
    W:fire('PLAYER_REGEN_ENABLED')
    W:advance(2 * 60); T.eq(lines(W, TEXT), 1)
  end)

  T.it('reminder.reloadMinutes 0 turns it off', function()
    local W, _, ns = session()
    ns.Config.Set('reminder.reloadMinutes', 0)
    W.printed = {}
    W:advance(130 * 60); T.eq(lines(W, TEXT), 0)
  end)
end)

---------------------------------------------------------------------------
T.describe('P4-M2 commands and trace', function()
  T.it('agg status and top answer; EVT agg and EVT clock lines are written and kept', function()
    local W, _, ns, run = session()
    for _ = 1, 6 do coinLoot(W, 5); W:advance(20) end
    T.truthy(run('agg status'):find('places', 1, true))
    local top = run('agg top 3')
    T.truthy(top:find('1 more with gold but under 10 minutes (not ranked)', 1, true), top)   -- 2 minutes: not ranked (D-115)
    ns.AggLive.REPORT_EVERY = 5; W:advance(6); ns.AggLive.REPORT_EVERY = 600
    local lines = table.concat(W.env.GoldIntelCharDB.trace.lines, '\n')
    T.truthy(lines:find('EVT agg periodic cash=0 vc=0', 1, true), lines:sub(-300))
    T.truthy(lines:find('EVT clock periodic active=', 1, true))
    T.truthy(run('agg status'):find('agg clock: active=', 1, true))
  end)

  T.it('trace.keep holds only final and MISMATCH EVT agg / EVT clock lines (D-113)', function()
    keepScenario()
  end)

  T.it('pause, afk, resume and activity answer, and an unknown activity key is refused', function()
    local _, _, _, run = session()
    T.truthy(run('pause'):find('time paused', 1, true))
    T.truthy(run('afk'):find('away', 1, true))
    T.truthy(run('resume'):find('counted again', 1, true))
    T.truthy(run('activity NONSENSE'):find('unknown key', 1, true))
  end)
end)

---------------------------------------------------------------------------
-- 0.6.1 (D-115)
---------------------------------------------------------------------------
-- Every second of an interval gets exactly one class: active, idle, travelHard (taxi, loading screen), travelSoft,
-- paused. Their total equals the session time (the live check of 2026-11-14 had 6,841 s over 5,664 s).
local function timeScenario(override)
  local W, _, ns, run = session(nil, { override = override })
  local begin = W.state.gt - 1                                    -- session() switches collect on, then advances 1 s
  coinLoot(W, 5)                                                  -- active
  W:advance(200)                                                  -- no signal: idle
  W.env.UnitOnTaxi = function() return true end; W:advance(60)   -- flight path
  W.env.UnitOnTaxi = function() return false end
  W:fire('PLAYER_LEAVING_WORLD'); W:advance(12); W:fire('PLAYER_ENTERING_WORLD')   -- a loading screen
  coinLoot(W, 3)
  run('pause'); W:advance(30); run('resume')
  W:stall(8)                                                      -- one frozen frame longer than the 5 s tick clamp
  coinLoot(W, 2); W:advance(0.3)
  run('collect off')
  local s = ns.AggLive.ClockStats()
  local session = W.state.gt - begin
  local classes = s.active + s.idle + s.travelHard + s.travelSoft + s.paused
  assert(math.abs(s.session - session) < 0.01, 'session ' .. s.session .. ' vs ' .. session)
  assert(math.abs(classes - session) < 0.01, string.format('classes %.3f vs session %.3f', classes, session))
  assert(s.pending == 0 and math.abs(s.total - classes) < 1e-9, 'total')
  assert(s.travelHard >= 71.9, 'taxi and loading screen are hard travel: ' .. s.travelHard)
  assert(s.paused >= 29.9 and s.paused <= 30.6, 'paused ' .. s.paused)
  local keep = table.concat(W.env.GoldIntelCharDB.trace.keep, '\n')
  local tot, ses = keep:match('EVT clock final .- total=(%d+) session=(%d+)')
  assert(tot and tot == ses, 'final line total= and session= : ' .. tostring(tot) .. ' / ' .. tostring(ses))
  assert(keep:find('EVT clock final .- noDistance=%d+'), 'noDistance after the classes')
end

-- /gi agg top ranks by gold per hour among cells with at least 10 minutes; back-filled cells are listed apart.
local function topScenario(override)
  local W, _, ns, run = session(nil, { override = override })
  for _ = 1, 16 do coinLoot(W, 50); W:advance(60) end            -- about 17 minutes of looting in Durotar: ranked
  local st = aggState(W)
  st.places['bf|Barrens'] = { zone = 'The Barrens', cells = { ['LOOT|?'] = { coin = 90000, vc = 0, s = 0, q = {} } } }
  st.places['short|Mulgore'] = { zone = 'Mulgore', cells = { ['GRIND|1-5'] = { coin = 500, vc = 0, s = 120, q = {} } } }
  local res = ns.AggLive.Top(5)
  assert(#res.ranked == 1 and res.ranked[1].name:find('Durotar') and res.ranked[1].rate > 0, 'ranked: ' .. #res.ranked)
  assert(#res.backfilled == 1 and res.backfilled[1].name == 'The Barrens', 'back-filled apart')
  assert(res.short == 1, 'short ' .. res.short)
  local out = run('agg top')
  assert(out:find('1. Durotar', 1, true) and out:find('per hour', 1, true), out)
  assert(out:find('back-filled before 0.6.0', 1, true) and out:find('The Barrens', 1, true), out)
  assert(out:find('1 more with gold but under 10 minutes', 1, true), out)
  assert(out:find('1. Durotar') < out:find('The Barrens'), 'the 90 g back-filled cell does not outrank the timed one')
end

-- The back-fill runs in steps; an entry stored while it runs is counted once; the check reads 0 when it is done.
local function backfillScenario(override)
  local empty = { ['Aggregate/Live.lua'] = 'local ADDON, GI = ...\nGI.AggLive = nil\n' }
  local W = session(nil, { money = 2000, override = empty })
  coinLoot(W, 20)
  local saved = save(W)
  local cash = saved.account.ledger[W.state.guid].cash
  local first = cash[1]
  for i = 2, 6000 do local r = {} for k, v in pairs(first) do r[k] = v end; r.id = 10000 + i; cash[#cash + 1] = r end
  local W2, _, ns2, run = session(saved, { override = override })
  local done, total = ns2.AggLive.Backfilling()
  assert(done and total >= 6000 and done < total, 'back-fill spread over ticks: ' .. tostring(done) .. '/' .. tostring(total))
  assert(run('agg check'):find('back-fill in progress', 1, true), 'check waits')
  pay(W2, 33); W2:advance(3)                                      -- stored while the back-fill runs (12 ticks in all)
  assert(ns2.AggLive.Backfilling(), 'the entry was stored during the back-fill')
  W2:advance(5)
  assert(ns2.AggLive.Backfilling() == nil, 'finished')
  local r = ns2.AggLive.Check()
  assert(r and r.cash == 0 and r.vc == 0, 'check ' .. tostring(r and r.cash) .. ' / ' .. tostring(r and r.vc))
  assert(aggState(W2).backfilled.n >= 6000, "all records")
  -- nothing is folded here, so the aggregates' net must equal the ledger's net exactly: offset 0 (a double count shows here)
  assert(aggState(W2).check.cash == 0, 'check offset ' .. tostring(aggState(W2).check.cash))
end

T.describe('0.6.1 fixes (D-115)', function()
  T.it('time classes never overlap and add up to the session time (taxi, loading screen, pause, idle, a frozen frame)', function() timeScenario() end)
  T.it('agg top: gold per hour with a 10-minute minimum; back-filled places listed separately', function() topScenario() end)
  T.it('the back-fill runs in steps of BACKFILL_STEP records, counts live entries once, and the check is 0 after it', function() backfillScenario() end)
  T.it('a back-fill still running at logout is finished before the save', function()
    local empty = { ['Aggregate/Live.lua'] = 'local ADDON, GI = ...\nGI.AggLive = nil\n' }
    local W = session(nil, { money = 2000, override = empty })
    coinLoot(W, 20)
    local saved = save(W)
    local cash = saved.account.ledger[W.state.guid].cash
    for i = 2, 3000 do local r = {} for k, v in pairs(cash[1]) do r[k] = v end; r.id = 20000 + i; cash[#cash + 1] = r end
    local W2, _, ns2 = session(saved)
    T.truthy(ns2.AggLive.Backfilling())
    local saved2 = save(W2)
    local st = saved2.account.agg[W2.state.guid]
    T.truthy(st.backfilled and st.backfilled.n >= 3000, 'complete in the saved file')
    local W3, _, ns3 = session(saved2)
    T.isnil(ns3.AggLive.Backfilling())
    T.eq(ns3.AggLive.Check().cash, 0)
  end)
end)

---------------------------------------------------------------------------
-- deliberate bugs
---------------------------------------------------------------------------
local LIVE = Loader.readFile(Loader.root .. '/Aggregate/Live.lua')
local function mutantLive(a, b)
  local i, j = LIVE:find(a, 1, true)
  assert(i, 'anchor missing: ' .. a)
  return { ['Aggregate/Live.lua'] = LIVE:sub(1, i - 1) .. b .. LIVE:sub(j + 1) }
end
local function checkScenario(override)
  local W, _, ns = session(nil, { money = 5000, override = override })
  item(W, 777, 25, false)
  coinLoot(W, 12); itemLoot(W, 777, 1)
  W.state.cached[777] = true; W:fire('GET_ITEM_INFO_RECEIVED', 777, true); W:advance(3)
  local r = ns.AggLive.Check()
  assert(r.cash == 0 and r.vc == 0, 'check ' .. r.cash .. ' / ' .. r.vc)
end
local function reminderScenario(override)
  local W = session(nil, { override = override })
  W.printed = {}
  W:advance(55 * 60); W:fire('PLAYER_REGEN_DISABLED'); W:advance(10 * 60)
  assert(not W:printedText():find('/reload saves it', 1, true), 'reminder in combat')
end
local function pauseScenario(override)
  local W, _, _, run = session(nil, { override = override })
  coinLoot(W, 3)
  run('pause')
  for _ = 1, 8 do coinLoot(W, 2); W:advance(20) end           -- signals of life: without the pause this time is active
  run('resume'); run('collect off')
  local st = aggState(W)
  assert(st.totals.s < 20, 'paused time counted: ' .. st.totals.s)
  assert(st.totals.coin == 19, 'coin is still recorded while paused')
end

T.describe('P4-M2 mutation checks', function()
  T.it('the real sources pass the scenarios', function() checkScenario(); reminderScenario(); pauseScenario(); keepScenario() end)
  local MUT = {
    { 'cash not fed', "    GI.Bus.On('LEDGER_CASH', guard(onCash))", "", checkScenario },
    { 'late value ignored', "    A:Enqueue('lotValue', rec); c.lotValues = c.lotValues + 1", "", checkScenario },
    { 'reminder in combat', "  if type(minutes) ~= 'number' or minutes <= 0 or inCombat or not loadGT then return end", "  if type(minutes) ~= 'number' or minutes <= 0 or not loadGT then return end", reminderScenario },
    { 'pause not applied', "  if C then C:Manual(mode) end", "", pauseScenario },
    { 'final clock line unmarked', "  trace(clockText(why))", "  trace(clockText())", keepScenario },
    { 'loading screens and frozen frames not booked (D-115)', "  if extra > 1e-6 then C:Unobserved(extra, (p and p.out) and 'loading' or 'stall') end", "", timeScenario },
    { 'back-filled cells ranked with the rest (D-115)', "        if ck:find('|%?$') then", "        if false then", topScenario },
    { 'no minimum time for the ranking (D-115)', "        elseif s >= Live.TOP_MIN_SECONDS then", "        elseif s >= 0 then", topScenario },
  }
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[1], function()
      T.falsy((pcall(m[4], mutantLive(m[2], m[3]))), 'the mutant passed: ' .. m[1])
    end)
  end
  local TRACE = Loader.readFile(Loader.root .. '/Ledger/Trace.lua')
  local function mutantTrace(a, b)
    local i, j = TRACE:find(a, 1, true)
    assert(i, 'anchor missing: ' .. a)
    return { ['Ledger/Trace.lua'] = TRACE:sub(1, i - 1) .. b .. TRACE:sub(j + 1) }
  end
  T.it('mutation is caught: periodic lines kept again (the 0.6.0 rule before D-113)', function()
    T.falsy((pcall(keepScenario, mutantTrace("text:find('^EVT agg final', 1)", "text:find('^EVT agg', 1)"))), 'the mutant passed')
  end)
  local AGGR = Loader.readFile(Loader.root .. '/Aggregate/Aggregator.lua')
  T.it('mutation is caught: back-fill reads the live list instead of a snapshot (D-115)', function()
    local a = "    for i, rec in ipairs(ledger.cash) do cash[i] = rec end"
    local i, j = AGGR:find(a, 1, true); assert(i, 'anchor missing')
    local m = { ['Aggregate/Aggregator.lua'] = AGGR:sub(1, i - 1) .. "    cash = ledger.cash" .. AGGR:sub(j + 1) }
    T.falsy((pcall(backfillScenario, m)), 'the mutant passed')
  end)
  T.it('mutation is caught: MISMATCH lines no longer kept', function()
    T.falsy((pcall(keepScenario, mutantTrace("(text:find('^EVT agg', 1) and text:find(' MISMATCH', 1, true))", "false"))), 'the mutant passed')
  end)
end)
