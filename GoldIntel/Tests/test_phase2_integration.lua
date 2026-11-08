--[[
Tests / test_phase2_integration.lua                              (Phase 2 exit tests)

End-to-end: a Phase 1 install upgrades, settings and evidence survive a reload, nothing from
Phase 3 leaked in, events are never assumed delivered, persistence stays bounded.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local Loader = require('loader')
local sim = require('svsim')

local function fixture()
  return sim.loadFixture(Loader.root .. '/Tests/fixtures/forever_1.60.1_GoldIntelDB.lua', 'GoldIntelDB')
end

--- One play session. `saved` = { account = text|nil, character = text|nil }.
-- Returns the new saved texts (what the client would write at logout) and the last W, ns.
local function session(saved, play, opts)
  local W = Fake.new(opts)
  if opts and opts.money then W.state.money = opts.money end
  if saved.account then W.env.GoldIntelDB = sim.parse(saved.account) end
  if saved.character then W.env.GoldIntelCharDB = sim.parse(saved.character) end
  local P, ns = Loader.load(W.env)
  W:login()
  if play then play(W, ns, P) end
  W:fire('PLAYER_LOGOUT')
  return { account = sim.dump(W.env.GoldIntelDB), character = sim.dump(W.env.GoldIntelCharDB) }, W, ns
end

T.describe('journey: Phase 1 install -> Phase 2 -> reload', function()
  local first, second

  T.it('session 1 upgrades the real Phase 1 database and records settings and evidence', function()
    local saved = { account = sim.dump(fixture()) }
    local out, W, ns = session(saved, function(W, ns)
      T.eq(ns.Store.Status().state, 'migrated')
      W.state.money = 7181 + 250
      W:fire('PLAYER_MONEY')
      W.env.SlashCmdList.GOLDINTEL('config set idleSec 240')
      W.env.SlashCmdList.GOLDINTEL('config set prune.days 45')
      W:advance(10)
    end)
    first = out
    local db = sim.parse(out.account)
    T.eq(db.schema, 2)
    T.eq(db.profile.idleSec, 240)
    T.eq(db.profile.prune.days, 45)
    T.truthy(db.compat, 'compat exists after the session')
    T.eq(db.meta.opens, 1)
    T.eq(db.meta.schemaHistory[1].from, 0)
    T.eq(db.runtime.capabilities['event.PLAYER_MONEY'].level, 'payloadUsable')
    T.eq(db.runtime.eventStats.PLAYER_MONEY.delivered, 1)
  end)

  T.it('session 2 finds everything: settings applied, no new migration, history intact', function()
    local out, W, ns = session(first, function(W, ns)
      T.eq(ns.Store.Status().state, 'ok')
      T.eq(ns.Config.Get('idleSec'), 240)
      T.eq(ns.Config.Get('prune.days'), 45)
      T.eq(ns.Core.state, 'ready')
      -- evidence from the previous session is still there until this one overwrites it
      T.truthy(ns.Store.Section('runtime').capabilities)
    end)
    second = sim.parse(out.account)
    T.eq(second.meta.opens, 2)
    T.eq(#second.meta.schemaHistory, 1)
    T.eq(second.profile.idleSec, 240)
  end)

  T.it('the per-character data persists too', function()
    local out = session({ account = first.account, character = first.character }, function(W, ns)
      ns.Store.Char().activeSessionID = 12345
    end)
    local out2, _, ns2 = session(out, function(W, ns) T.eq(ns.Store.Char().activeSessionID, 12345) end)
    T.truthy(out2.character)
  end)

  T.it('a session on a newer database changes nothing on disk', function()
    local newer = fixture()
    newer.schema = 7
    newer.profile = { idleSec = 999 }
    local text = sim.dump(newer)
    local out, W, ns = session({ account = text }, function(W, ns)
      T.eq(ns.Store.Status().state, 'readonly')
      T.eq(ns.Core.state, 'ready')
      ns.Config.Set('idleSec', 100)
      W.env.SlashCmdList.GOLDINTEL('config set minSegSec 700')
    end)
    local after = sim.parse(out.account)
    T.eq(after.schema, 7)
    T.eq(after.profile.idleSec, 999)
    T.isnil(after.profile.minSegSec)
  end)
end)

T.describe('scope: nothing from Phase 3 leaked in', function()
  T.it('only the two placeholder modules exist and nothing fires a reserved event', function()
    local W, _, ns = Loader.boot()
    local fired = {}
    for _, name in ipairs(ns.Bus.Names()) do
      if ns.Bus.Info(name).reserved then
        ns.Bus.On(name, function() fired[#fired + 1] = name end)
      end
    end
    W:login()
    W.state.money = 99; W:fire('PLAYER_MONEY')
    W:fire('PLAYER_LEVEL_UP', 5)
    W:fire('ZONE_CHANGED')
    W:advance(30)
    W:fire('PLAYER_LOGOUT')
    T.eq(fired, {}, 'reserved (Phase 3+) events must not be fired in Phase 2')
    local names = {}
    for _, m in ipairs(ns.Core.Modules()) do names[#names + 1] = m.name end
    T.eq(names, { 'Context', 'Collector', 'Ledger', 'CommunityDataEngine', 'RouteEngine' })   -- Phase 3b-1 added Context and Collector, 3b-2 Ledger
  end)

  T.it('Phase 2 registers no new raw events: still exactly the 12 Phase 1 events', function()
    local W = Loader.boot()
    W:login()
    W.env.SlashCmdList.GOLDINTEL('probe')
    local seen, list = {}, {}
    for _, e in ipairs(W.registerCalls) do
      if not seen[e] then seen[e] = true; list[#list + 1] = e end
    end
    table.sort(list)
    T.eq(list, { 'PLAYER_ENTERING_WORLD', 'PLAYER_LEAVING_WORLD', 'PLAYER_LEVEL_UP', 'PLAYER_LOGIN',
                 'PLAYER_LOGOUT', 'PLAYER_MONEY', 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED',
                 'SKILL_LINES_CHANGED', 'ZONE_CHANGED', 'ZONE_CHANGED_INDOORS', 'ZONE_CHANGED_NEW_AREA' })
    T.eq(W.forbidden, {})
  end)

  T.it('no module consumes money events: the Store holds no ledger, session or collection data', function()
    local W, _, ns = Loader.boot()
    W:login()
    for i = 1, 20 do W.state.money = W.state.money + i; W:fire('PLAYER_MONEY') end
    W:advance(60)
    local db = ns.Store.Get()
    T.eq(db.sessions, {}); T.eq(db.segments, {}); T.eq(db.lots.open, {}); T.eq(db.auctions, {})
    T.eq(db.agg.zone, {})
    -- 0.6.0 (P4-M2, D-102): the live aggregation keeps time per character in heat[charKey]; money with no loot credits nothing
    for _, maps in pairs(db.heat) do for _, bins in pairs(maps) do for _, b in pairs(bins) do T.eq(b.c, 0) end end end
  end)
end)

T.describe('events are never assumed delivered (review finding 6)', function()
  T.it('right after startup nothing but the login events counts as delivered', function()
    local W, _, ns = Loader.boot()
    W:login()
    local C = ns.Capabilities
    for _, event in ipairs({ 'PLAYER_MONEY', 'PLAYER_LEVEL_UP', 'ZONE_CHANGED', 'PLAYER_REGEN_DISABLED', 'SKILL_LINES_CHANGED', 'PLAYER_LOGOUT' }) do
      T.isnil(C.Stage('event.' .. event, 'delivered'), event)
      T.falsy(C.Usable('event.' .. event), event)
    end
  end)

  T.it('Core works when the logout event never arrives (the live tables are what gets saved)', function()
    local W, _, ns = Loader.boot()
    W:login()
    ns.Config.Set('idleSec', 321)
    W:advance(ns.Capabilities.PERSIST_DELAY + 1)
    local text = sim.dump(W.env.GoldIntelDB)       -- the client saves without any logout event
    local db = sim.parse(text)
    T.eq(db.profile.idleSec, 321)
    T.truthy(db.runtime.capabilities, 'evidence reached the saved data through the throttled snapshot')
  end)

  T.it('Core works when the login event never arrives but the addon loads after login', function()
    local W = Fake.new({ without = { 'IsLoggedIn' } })
    W.state.loggedIn = true
    local P, ns = Loader.load(W.env)
    T.eq(ns.Core.state, 'loaded', 'without IsLoggedIn the late-load path cannot start Core')
    W.env.SlashCmdList.GOLDINTEL('status')
    T.truthy(W:printedText():find('operational=', 1, true), 'but /gi still answers (minimal mode)')
    local W2 = Fake.new()
    W2.state.loggedIn = true
    local _, ns2 = Loader.load(W2.env)
    T.eq(ns2.Core.state, 'ready', 'late load with IsLoggedIn starts Core immediately')
  end)
end)

T.describe('bounded work and memory', function()
  T.it('an hour of play: snapshots are throttled, no diagnostics, no memory growth', function()
    local W, P, ns = Loader.boot()
    W:login()
    local persists = 0
    local original = ns.Capabilities.Persist
    ns.Capabilities.Persist = function() persists = persists + 1; return original() end
    collectgarbage('collect')
    local before = collectgarbage('count')
    for i = 1, 14400 do
      W:advance(0.25)
      if i % 400 == 0 then W.state.money = W.state.money + 137; W:fire('PLAYER_MONEY') end
      if i % 3000 == 0 then W:fire('PLAYER_LEVEL_UP', 10) end
    end
    collectgarbage('collect')
    local after = collectgarbage('count')
    T.eq(P.DiagCount(), 0)
    T.truthy(persists <= 6, 'snapshot persisted ' .. persists .. ' times in an hour')
    T.truthy(after - before < 250, 'retained memory grew by ' .. (after - before) .. ' KB')
    local bytes = ns.Store.EstimateBytes(ns.Store.Get())
    T.truthy(bytes < 20000, 'database is ' .. bytes .. ' bytes after an hour with no collection')
  end)

  T.it('the database does not grow across many sessions (records are bounded: current, previous, ten history rows)', function()
    local saved = { account = sim.dump(fixture()) }
    local sizes = {}
    for i = 1, 24 do
      saved = session(saved, function(W) W:fire('PLAYER_MONEY') end, { money = 5000 })
      sizes[i] = #saved.account
    end
    -- the ten-row history fills during the first dozen opens; after that nothing may grow
    T.truthy(sizes[24] - sizes[14] < 400, 'size drifted from ' .. sizes[14] .. ' to ' .. sizes[24])
    T.eq(sim.parse(saved.account).meta.opens, 24)
  end)
end)
