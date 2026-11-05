--[[
Tests / test_collector.lua            (Phase 3b-1: Collect/Collector.lua, journal, quarantine, /gi collect)
]]

local T = require('testlib')
local World = require('collectworld')

local ALL14 = 18                 -- 16 + TRAINER_SHOW, TRAINER_CLOSED (0.5.2, D-093)

local function run(W, ns, text)
  local from = #W.printed
  ns.Commands.Run(text)
  local lines = {}
  for i = from + 1, #W.printed do lines[#lines + 1] = W.printed[i] end
  return table.concat(lines, '\n')
end

local function seeded(char)
  -- boots a client whose saved character data already exists (a /reload or a new login)
  local W, P, ns = World.boot({ login = false })
  W.env.GoldIntelCharDB = char
  W:login()
  return W, P, ns
end

T.describe('collect is off by default and never persisted (A-3)', function()
  T.it('nothing is registered after login', function()
    local W, _, ns = World.boot()
    T.falsy(ns.Collector.IsEnabled())
    T.eq(#ns.Collector.Registered(), 0)
    local set = {}
    for _, e in ipairs(W.registerCalls) do set[e] = true end
    T.falsy(set.LOOT_OPENED)
  end)

  T.it('a character that was collecting before starts with collect off', function()
    local W, _, ns = seeded({ schema = 1, pending = {}, collect = { quarantine = {}, enabled = true } })
    T.falsy(ns.Collector.IsEnabled())
    local set = {}
    for _, e in ipairs(W.registerCalls) do set[e] = true end
    T.falsy(set.MERCHANT_SHOW)
  end)

  T.it('turning collect on writes no enabled flag into the saved data', function()
    local _, _, ns = World.boot()
    ns.Collector.On({})
    T.isnil(ns.Collector.Journal().enabled)
  end)
end)

T.describe('Collector.On', function()
  T.it('registers all 18 events in group order and reports them', function()
    local W, _, ns = World.boot()
    local r = ns.Collector.On({})
    T.eq(r.registered, ALL14); T.eq(#r.failed, 0); T.eq(#r.skipped, 0)
    T.truthy(ns.Collector.IsEnabled())
    local order = {}
    for _, e in ipairs(W.registerCalls) do order[#order + 1] = e end
    local tail = {}
    for i = #order - 17, #order do tail[#tail + 1] = order[i] end
    T.eq(tail, { 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'QUEST_TURNED_IN', 'MERCHANT_SHOW', 'MERCHANT_CLOSED',
                 'MAIL_INBOX_UPDATE', 'TRADE_SHOW', 'TRADE_CLOSED', 'TRADE_ACCEPT_UPDATE', 'TRADE_MONEY_CHANGED',
                 'BAG_UPDATE_DELAYED', 'GET_ITEM_INFO_RECEIVED', 'UNIT_SPELLCAST_SUCCEEDED',
                 'AUCTION_HOUSE_AUCTION_CREATED', 'CHAT_MSG_MONEY', 'CHAT_MSG_LOOT', 'TRAINER_SHOW', 'TRAINER_CLOSED' })
  end)

  T.it('the riskiest event is registered last among the original 13, in its own group', function()
    local _, _, ns = World.boot()
    local g = ns.Collector.GROUPS
    T.eq(g[5].events, { 'UNIT_SPELLCAST_SUCCEEDED' })
    T.eq(g[6].events, { 'AUCTION_HOUSE_AUCTION_CREATED' })
  end)

  T.it('after collect on there are 12 + 18 = 30 raw events registered with the frame', function()
    local _, P, ns = World.boot()
    ns.Collector.On({})
    T.eq(#P.Events.BoundEvents(), 30)
  end)

  T.it('can register one group alone', function()
    local W, _, ns = World.boot()
    local r = ns.Collector.On({ group = 'G2' })
    T.eq(r.registered, 2)
    T.eq(ns.Collector.Registered(), { 'MERCHANT_CLOSED', 'MERCHANT_SHOW' })
    local set = {}
    for _, e in ipairs(W.registerCalls) do set[e] = true end
    T.falsy(set.LOOT_OPENED)
  end)

  T.it('an unknown group is refused', function()
    local _, _, ns = World.boot()
    local r, err = ns.Collector.On({ group = 'G10' })
    T.isnil(r); T.truthy(err:find('G10', 1, true))
  end)

  T.it('calling On twice is a no-op the second time', function()
    local W, _, ns = World.boot()
    ns.Collector.On({})
    local calls = #W.registerCalls
    local r = ns.Collector.On({})
    T.eq(r.registered, 0); T.eq(r.already, ALL14)
    T.eq(#W.registerCalls, calls)
  end)

  T.it('every registration is verified; a blocked one is reported as failed and the others still work', function()
    local W, _, ns = World.boot()
    W.state.forbiddenEvents.TRADE_CLOSED = true            -- the client blocks it silently (popup in the real client)
    local r = ns.Collector.On({})
    T.eq(r.registered, ALL14 - 1)
    T.eq(#r.failed, 1)
    T.truthy(r.failed[1]:find('TRADE_CLOSED', 1, true))
    W:fire('MERCHANT_SHOW')
    T.eq(ns.Context.Stats().vendor.opened, 1)
  end)

  T.it('an event invalid in this client is reported as failed without a registration call', function()
    local W, _, ns = World.boot()
    W.state.invalidEvents.AUCTION_HOUSE_AUCTION_CREATED = true
    local r = ns.Collector.On({})
    T.eq(#r.failed, 1)
    for _, e in ipairs(W.registerCalls) do T.neq(e, 'AUCTION_HOUSE_AUCTION_CREATED') end
  end)

  T.it('the plain option skips the unit filter for casts', function()
    local W, _, ns = World.boot()
    for _, f in ipairs(W.frames) do
      function f:RegisterUnitEvent(e) self.events[e] = true; W.state.unitUsed = true end
    end
    ns.Collector.On({ plain = true })
    T.falsy(W.state.unitUsed)
  end)

  T.it('without the plain option the cast event uses the unit filter when available', function()
    local W, P, ns = World.boot()
    for _, f in ipairs(W.frames) do
      function f:RegisterUnitEvent(e) self.events[e] = true; W.state.unitUsed = e end
    end
    ns.Collector.On({})
    T.eq(W.state.unitUsed, 'UNIT_SPELLCAST_SUCCEEDED')
    T.eq(P.Events.RegisteredVia('UNIT_SPELLCAST_SUCCEEDED'), 'unit-filter')
  end)

  T.it('starts the polling adapters (mail and auction house)', function()
    local W, P, ns = World.boot()
    local seen = World.capture(P, 'P_MAIL_OPEN', 'P_AH_OPEN')
    W.state.mailShown = true; W.state.ahShown = true
    W:advance(1.0); T.eq(#seen, 0)
    ns.Collector.On({})
    W:advance(1.0); T.eq(#seen, 2)
  end)
end)

T.describe('Collector.Off', function()
  T.it('unregisters every collector event and keeps the Phase 1 events', function()
    local W, P, ns = World.boot()
    ns.Collector.On({})
    local n = ns.Collector.Off()
    T.eq(n, ALL14)
    T.eq(#P.Events.BoundEvents(), 12)
    T.falsy(ns.Collector.IsEnabled())
    local money = false
    for _, f in ipairs(W.frames) do T.falsy(f.events.LOOT_OPENED); if f.events.PLAYER_MONEY then money = true end end
    T.truthy(money)
  end)

  T.it('events after off are not delivered or counted', function()
    local W, P, ns = World.boot()
    ns.Collector.On({})
    W:fire('MERCHANT_SHOW'); ns.Collector.Off()
    W:fire('MERCHANT_SHOW')
    T.eq(P.Events.Counters('MERCHANT_SHOW').received, 1)
  end)

  T.it('off then on again re-registers cleanly with no duplicate delivery', function()
    local W, P, ns = World.boot()
    ns.Collector.On({}); ns.Collector.Off(); ns.Collector.On({})
    P.Events.ResetCounters()
    W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_CLOSED')
    T.eq(P.Events.Counters('MERCHANT_SHOW').received, 1)
    T.eq(P.MerchantModule.stats.opened >= 1, true)
    local c = P.Events.Counters('MERCHANT_SHOW')
    T.eq(c.kept, 1)
  end)

  T.it('off when already off does nothing', function()
    local _, _, ns = World.boot()
    T.eq(ns.Collector.Off(), 0)
  end)

  T.it('off stops the polling adapters', function()
    local W, P, ns = World.boot()
    ns.Collector.On({}); ns.Collector.Off()
    local seen = World.capture(P, 'P_MAIL_OPEN')
    W.state.mailShown = true; W:advance(3.0)
    T.eq(#seen, 0)
  end)

  T.it('leaves no timers running after off', function()
    local W, _, ns = World.boot()
    local before = W:activeTimers()
    ns.Collector.On({}); ns.Collector.Off()
    T.eq(W:activeTimers(), before)
  end)
end)

T.describe('registration journal and quarantine (D-074)', function()
  T.it('writes the event name BEFORE the registration call and clears it afterwards', function()
    local W, P, ns = World.boot()
    local seenPending = {}
    for _, f in ipairs(W.frames) do
      local orig = f.RegisterEvent
      function f:RegisterEvent(e)
        seenPending[e] = ns.Collector.Journal().pending
        return orig(self, e)
      end
    end
    ns.Collector.On({})
    T.eq(seenPending.LOOT_OPENED, 'LOOT_OPENED')
    T.eq(seenPending.UNIT_SPELLCAST_SUCCEEDED, 'UNIT_SPELLCAST_SUCCEEDED')
    T.isnil(ns.Collector.Journal().pending)
  end)

  T.it('an interrupted registration quarantines exactly that event at the next load', function()
    local _, _, ns = seeded({ schema = 1, pending = {}, collect = { pending = 'UNIT_SPELLCAST_SUCCEEDED', quarantine = {} } })
    T.eq(ns.Collector.Quarantined(), { 'UNIT_SPELLCAST_SUCCEEDED' })
    T.eq(ns.Collector.recovered, 'UNIT_SPELLCAST_SUCCEEDED')
    T.isnil(ns.Collector.Journal().pending)
  end)

  T.it('a quarantined event is skipped and every other event still registers', function()
    local W, _, ns = seeded({ schema = 1, pending = {}, collect = { quarantine = { UNIT_SPELLCAST_SUCCEEDED = true } } })
    local r = ns.Collector.On({})
    T.eq(r.registered, ALL14 - 1)
    T.eq(r.skipped, { 'UNIT_SPELLCAST_SUCCEEDED' })
    for _, e in ipairs(W.registerCalls) do T.neq(e, 'UNIT_SPELLCAST_SUCCEEDED') end
    T.truthy(ns.Collector.IsEnabled())
  end)

  T.it('the collector stack as a whole is not disabled by one quarantined event', function()
    local W, _, ns = seeded({ schema = 1, pending = {}, collect = { quarantine = { MAIL_INBOX_UPDATE = true } } })
    ns.Collector.On({})
    W:fire('LOOT_OPENED'); W:fire('MERCHANT_SHOW'); W:fire('TRADE_SHOW')
    T.eq(ns.Context.Stats().vendor.opened, 1)
    T.eq(ns.Context.Stats().trade.opened, 1)
  end)

  T.it('Allow lifts the quarantine and the event registers again', function()
    local W, _, ns = seeded({ schema = 1, pending = {}, collect = { quarantine = { BAG_UPDATE_DELAYED = true } } })
    T.truthy(ns.Collector.Allow('BAG_UPDATE_DELAYED'))
    T.eq(ns.Collector.Quarantined(), {})
    local r = ns.Collector.On({})
    T.eq(r.registered, ALL14)
  end)

  T.it('Allow on an event that is not quarantined says so', function()
    local _, _, ns = World.boot()
    T.falsy(ns.Collector.Allow('LOOT_OPENED'))
  end)

  T.it('the quarantine survives the next reload through the saved data', function()
    local W1, _, ns1 = seeded({ schema = 1, pending = {}, collect = { pending = 'TRADE_SHOW', quarantine = {} } })
    local saved = W1.env.GoldIntelCharDB
    local _, _, ns2 = seeded(saved)
    T.eq(ns2.Collector.Quarantined(), { 'TRADE_SHOW' })
  end)

  T.it('a clean registration leaves no pending marker in the saved data', function()
    local W, _, ns = World.boot()
    ns.Collector.On({})
    T.isnil(W.env.GoldIntelCharDB.collect.pending)
  end)

  T.it('simulated popup: the blocked event stays quarantined after reload and is never retried', function()
    -- session 1: the client blocks a registration; the journal marker is what survives a crash/reload
    local W1, _, ns1 = World.boot()
    W1.state.forbiddenEvents.TRADE_ACCEPT_UPDATE = true
    ns1.Collector.On({})
    -- the real popup interrupts before the marker is cleared: simulate by restoring it
    W1.env.GoldIntelCharDB.collect.pending = 'TRADE_ACCEPT_UPDATE'
    local W2, _, ns2 = seeded(W1.env.GoldIntelCharDB)
    local r = ns2.Collector.On({})
    T.eq(r.skipped, { 'TRADE_ACCEPT_UPDATE' })
    for _, e in ipairs(W2.registerCalls) do T.neq(e, 'TRADE_ACCEPT_UPDATE') end
    T.eq(r.registered, ALL14 - 1)
  end)

  T.it('works without a Store (memory journal)', function()
    local _, _, ns = World.boot()
    local saved = ns.Store
    ns.Store = nil
    T.truthy(ns.Collector.Journal())
    ns.Store = saved
  end)
end)

T.describe('Collector statistics', function()
  T.it('Stats lists one row per collector event in group order with totals', function()
    local W, _, ns = World.boot()
    ns.Collector.On({})
    W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_CLOSED'); W:fire('MERCHANT_CLOSED')
    local s = ns.Collector.Stats()
    T.eq(#s.rows, ALL14)
    T.eq(s.rows[1].event, 'LOOT_OPENED'); T.eq(s.rows[14].event, 'AUCTION_HOUSE_AUCTION_CREATED'); T.eq(s.rows[15].event, 'CHAT_MSG_MONEY'); T.eq(s.rows[16].event, 'CHAT_MSG_LOOT'); T.eq(s.rows[17].event, 'TRAINER_SHOW'); T.eq(s.rows[18].event, 'TRAINER_CLOSED')
    local closed
    for _, r in ipairs(s.rows) do if r.event == 'MERCHANT_CLOSED' then closed = r end end
    T.eq(closed.received, 2); T.eq(closed.kept, 1); T.eq(closed.dropped, 1); T.truthy(closed.registered)
    T.eq(s.total.received, 3); T.eq(s.total.dropped, 1)
  end)

  T.it('rows for events that never fired show zeros', function()
    local _, _, ns = World.boot()
    ns.Collector.On({})
    for _, r in ipairs(ns.Collector.Stats().rows) do T.eq(r.received, 0) end
  end)

  T.it('Details report the loot close paths separately (frame, timeout, replaced)', function()
    local W, _, ns = World.boot()
    ns.Collector.On({})
    W.state.loot = { slots = { { type = 2, amount = 5 } } }
    W:fire('LOOT_OPENED'); W:advance(20); W:fire('LOOT_SLOT_CLEARED', 1); W.state.lootShown = false; W:advance(0.3)
    W:fire('LOOT_OPENED'); W:advance(301)
    W:fire('LOOT_OPENED'); W:fire('LOOT_OPENED')
    local d = ns.Collector.Details()
    T.eq(d.loot.opened, 4); T.eq(d.loot.closedFrame, 1); T.eq(d.loot.closedTimeout, 1); T.eq(d.loot.closedReplaced, 1)
    T.eq(d.loot.clears, 1)
  end)

  T.it('Reset zeroes counters, adapter statistics and contexts', function()
    local W, P, ns = World.boot()
    ns.Collector.On({})
    W:fire('MERCHANT_SHOW'); W:fire('TRADE_SHOW')
    ns.Collector.Reset()
    T.eq(ns.Collector.Stats().total.received, 0)
    T.eq(P.MerchantModule.stats.opened, 0)
    T.eq(ns.Context.Stats().vendor.opened, 0)
    T.eq(P.Unit.castStats.player, 0)
  end)

  T.it('the logout summary holds counts only and is small', function()
    local W, _, ns = World.boot()
    ns.Collector.On({})
    W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_CLOSED')
    ns.Collector.OnLogout()
    local saved = ns.Collector.Journal().lastStats
    T.eq(saved.events.MERCHANT_SHOW, { 1, 1, 0, 0, 1 })
    T.truthy(saved.loot)
    T.truthy(ns.Store.EstimateBytes(saved) < 2048)
  end)

  T.it('the summary is written by Core.Stop(logout)', function()
    local W, _, ns = World.boot()
    ns.Collector.On({})
    W:fire('MERCHANT_SHOW')
    W:fire('PLAYER_LOGOUT')
    ns.Core.Stop('logout')
    T.truthy(W.env.GoldIntelCharDB.collect.lastStats)
  end)
end)

T.describe('/gi collect', function()
  T.it('status with collect off', function()
    local W, _, ns = World.boot()
    local out = run(W, ns, 'collect status')
    T.truthy(out:find('collect: off, 0 events registered', 1, true))
    T.truthy(out:find('quarantined: none', 1, true))
    T.truthy(out:find('G5 (casts): 0/1', 1, true))
  end)

  T.it('a bare /gi collect shows the status', function()
    local W, _, ns = World.boot()
    T.truthy(run(W, ns, 'collect'):find('collect: off', 1, true))
  end)

  T.it('on registers everything and prints the counts', function()
    local W, _, ns = World.boot()
    local out = run(W, ns, 'collect on')
    T.truthy(out:find('collect: on, 18 registered now, 0 already, 0 failed, 0 skipped', 1, true))
    T.truthy(run(W, ns, 'collect status'):find('collect: ON, 18 events registered', 1, true))
  end)

  T.it('on G3 registers one group', function()
    local W, _, ns = World.boot()
    local out = run(W, ns, 'collect on G3')
    T.truthy(out:find('5 registered now', 1, true))
    T.truthy(run(W, ns, 'collect status'):find('G3 (mail and trade): 5/5', 1, true))
    T.truthy(run(W, ns, 'collect status'):find('G1 (loot and quest): 0/3', 1, true))
  end)

  T.it('group names are case-insensitive', function()
    local W, _, ns = World.boot()
    T.truthy(run(W, ns, 'collect on g2'):find('2 registered now', 1, true))
  end)

  T.it('on with an unknown option says so and registers nothing', function()
    local W, _, ns = World.boot()
    T.truthy(run(W, ns, 'collect on banana'):find('unknown option banana', 1, true))
    T.eq(#ns.Collector.Registered(), 0)
  end)

  T.it('on plain is accepted', function()
    local W, _, ns = World.boot()
    T.truthy(run(W, ns, 'collect on plain'):find('18 registered now', 1, true))
  end)

  T.it('failed and skipped events are listed', function()
    local W, _, ns = seeded({ schema = 1, pending = {}, collect = { quarantine = { MAIL_INBOX_UPDATE = true } } })
    W.state.forbiddenEvents.TRADE_SHOW = true
    local out = run(W, ns, 'collect on')
    T.truthy(out:find('failed: TRADE_SHOW', 1, true))
    T.truthy(out:find('skipped: MAIL_INBOX_UPDATE', 1, true))
  end)

  T.it('off reports how many events were unregistered', function()
    local W, _, ns = World.boot()
    run(W, ns, 'collect on')
    T.truthy(run(W, ns, 'collect off'):find('collect: off, 18 events unregistered', 1, true))
  end)

  T.it('stats prints a header, one line per event, totals and the loot close paths', function()
    local W, _, ns = World.boot()
    run(W, ns, 'collect on')
    W:fire('MERCHANT_SHOW')
    local out = run(W, ns, 'collect stats')
    T.truthy(out:find('event ', 1, true))
    T.truthy(out:find('LOOT_OPENED', 1, true))
    T.truthy(out:find('UNIT_SPELLCAST_SUCCEEDED', 1, true))
    T.truthy(out:find('total: received 1, kept 1, dropped 0, errors 0', 1, true))
    T.truthy(out:find('closed by frame 0, by timeout 0', 1, true))
    T.truthy(out:find('context vendor', 1, true))
  end)

  T.it('stats marks events that are not registered', function()
    local W, _, ns = World.boot()
    run(W, ns, 'collect on G1')
    T.truthy(run(W, ns, 'collect stats'):find('(not registered)', 1, true))
  end)

  T.it('reset clears the counters', function()
    local W, _, ns = World.boot()
    run(W, ns, 'collect on'); W:fire('MERCHANT_SHOW')
    T.truthy(run(W, ns, 'collect reset'):find('counters reset', 1, true))
    T.truthy(run(W, ns, 'collect stats'):find('total: received 0', 1, true))
  end)

  T.it('allow releases a quarantined event (case-insensitive)', function()
    local W, _, ns = seeded({ schema = 1, pending = {}, collect = { quarantine = { TRADE_SHOW = true } } })
    T.truthy(run(W, ns, 'collect allow trade_show'):find('released from quarantine', 1, true))
    T.truthy(run(W, ns, 'collect allow trade_show'):find('was not quarantined', 1, true))
    T.truthy(run(W, ns, 'collect allow'):find('usage', 1, true))
  end)

  T.it('status names an event quarantined at startup', function()
    local W, _, ns = seeded({ schema = 1, pending = {}, collect = { pending = 'BAG_UPDATE_DELAYED', quarantine = {} } })
    local out = run(W, ns, 'collect status')
    T.truthy(out:find('quarantined: BAG_UPDATE_DELAYED', 1, true))
    T.truthy(out:find('was quarantined at startup', 1, true))
  end)

  T.it('status warns when GoldIntelDiag is loaded (D-072)', function()
    local W, _, ns = World.boot()
    W.env.C_AddOns = { IsAddOnLoaded = function(n) return n == 'GoldIntelDiag' end }
    T.truthy(run(W, ns, 'collect status'):find('GoldIntelDiag is loaded', 1, true))
  end)

  T.it('an unknown subcommand prints the usage', function()
    local W, _, ns = World.boot()
    T.truthy(run(W, ns, 'collect banana'):find('usage: /gi collect', 1, true))
  end)

  T.it('the command is listed in help', function()
    local W, _, ns = World.boot()
    T.truthy(run(W, ns, 'help'):find('collect', 1, true))
  end)
end)

T.describe('collector module lifecycle', function()
  T.it('Context and Collector are enabled modules', function()
    local _, _, ns = World.boot()
    T.eq(ns.Core.ModuleState('Context'), 'enabled')
    T.eq(ns.Core.ModuleState('Collector'), 'enabled')
  end)

  T.it('the Phase 2 rule still holds: the 12 Phase 1 events only, until collect is switched on', function()
    local _, P = World.boot()
    T.eq(#P.Events.BoundEvents(), 12)
  end)

  T.it('PLAYER_MONEY keeps working while the collector runs (the money signal is untouched)', function()
    local W, P, ns = World.boot()
    local deltas = {}
    P.On('P_MONEY', function(p) deltas[#deltas + 1] = p.copper end)
    ns.Collector.On({})
    W.state.money = W.state.money + 8; W:fire('PLAYER_MONEY')
    T.eq(deltas, { 8 })
  end)
end)

T.describe('passive mode: auto start after login (0.5.0)', function()
  T.it('starts the interval by itself after the delay and says so once', function()
    local W, _, ns = World.boot()
    T.falsy(ns.Collector.IsEnabled())                     -- nothing before the delay
    W:advance(ns.Collector.AUTO_DELAY + 1)
    T.truthy(ns.Collector.IsEnabled())
    T.truthy(ns.Sources.IsActive())
    local n = 0
    for _, l in ipairs(W.printed) do if l:find('recording started automatically', 1, true) then n = n + 1 end end
    T.eq(n, 1)
  end)

  T.it('collect.auto false keeps collect off', function()
    local W, _, ns = World.boot()
    ns.Config.Set('collect.auto', false)
    W:advance(ns.Collector.AUTO_DELAY + 1)
    T.falsy(ns.Collector.IsEnabled())
  end)

  T.it('a hand-made collect off before the delay is not undone', function()
    local W, _, ns = World.boot()
    run(W, ns, 'collect on'); run(W, ns, 'collect off')
    W:advance(ns.Collector.AUTO_DELAY + 1)
    T.falsy(ns.Collector.IsEnabled())
  end)

  T.it('a collect already on is left alone and not announced twice', function()
    local W, _, ns = World.boot()
    run(W, ns, 'collect on')
    W:advance(ns.Collector.AUTO_DELAY + 1)
    T.truthy(ns.Collector.IsEnabled())
    for _, l in ipairs(W.printed) do T.falsy(l:find('recording started automatically', 1, true)) end
  end)

  T.it('an auto interval keeps cash and lots isolated (cash difference stays 0)', function()
    local W, _, ns = World.boot()
    W.state.money = 100000; W:fire('PLAYER_MONEY')
    W:advance(ns.Collector.AUTO_DELAY + 1)
    W.state.money = W.state.money + 25; W:fire('PLAYER_MONEY'); W:advance(5)
    local out = run(W, ns, 'ledger check')
    T.truthy(out:find('0 copper', 1, true) or out:find('OK', 1, true), out)
  end)
end)
