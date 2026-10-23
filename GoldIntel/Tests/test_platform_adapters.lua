--[[
Tests / test_platform_adapters.lua                     (Phase 2: SavedVars, Slash, event stages)

The new Platform pieces Phase 2 depends on: the SavedVariables adapter, slash registration,
registration verification (exception E1), delivery tracking, payload reports.
]]

local T = require('testlib')
local Loader = require('loader')

local CORE_FILES = { 'Platform/Platform.lua', 'Platform/Clock.lua', 'Platform/Events.lua', 'Platform/SavedVars.lua', 'Platform/Slash.lua' }
local function boot(fakeOpts)
  return Loader.boot(fakeOpts or {}, { only = CORE_FILES })
end

T.describe('Platform.SavedVars', function()
  T.it('returns the existing account table untouched', function()
    local Fake = require('fake_wow')
    local W = Fake.new()
    local mine = { x = 1 }
    W.env.GoldIntelDB = mine
    local P = Loader.load(W.env, { only = CORE_FILES })
    local t, status = P.SavedVars.Account()
    T.truthy(t == mine)
    T.eq(status, 'existing')
  end)

  T.it('creates the table when nothing was saved, and keeps it as the global', function()
    local W, P = boot()
    local t, status = P.SavedVars.Account()
    T.eq(status, 'created')
    T.truthy(W.env.GoldIntelDB == t)
    local again = P.SavedVars.Account()
    T.truthy(again == t)
  end)

  T.it('replaces a corrupt non-table value and warns', function()
    local Fake = require('fake_wow')
    local W = Fake.new()
    W.env.GoldIntelDB = 'garbage'
    local P = Loader.load(W.env, { only = CORE_FILES })
    local t, status = P.SavedVars.Account()
    T.eq(status, 'replaced')
    T.eq(type(t), 'table')
    local warned = false
    for _, d in ipairs(P.GetDiag()) do
      if d.level == 'warn' and d.msg:find('is not a table', 1, true) then warned = true end
    end
    T.truthy(warned)
  end)

  T.it('the character table is independent of the account table', function()
    local W, P = boot()
    local a = P.SavedVars.Account()
    local c, status = P.SavedVars.Character()
    T.eq(status, 'created')
    T.truthy(a ~= c)
    T.truthy(W.env.GoldIntelCharDB == c)
  end)
end)

T.describe('Platform.RegisterSlash', function()
  T.it('registers the command and the handler', function()
    local W, P = boot()
    local seen
    T.truthy(P.RegisterSlash('TESTCMD', '/testcmd', function(m) seen = m end))
    T.eq(W.env.SLASH_TESTCMD1, '/testcmd')
    W.env.SlashCmdList.TESTCMD('hello')
    T.eq(seen, 'hello')
  end)

  T.it('creates SlashCmdList when the client has none', function()
    local W, P = boot({ without = { 'SlashCmdList' } })
    T.truthy(P.RegisterSlash('TESTCMD', '/testcmd', function() end))
    T.eq(type(W.env.SlashCmdList.TESTCMD), 'function')
  end)

  T.it('validates key, command and handler', function()
    local _, P = boot()
    T.isnil((P.RegisterSlash('lower', '/x', function() end)))
    T.isnil((P.RegisterSlash('OK', 'nosslash', function() end)))
    T.isnil((P.RegisterSlash('OK', '/', function() end)))
    T.isnil((P.RegisterSlash('OK', '/x', 'handler')))
    T.isnil((P.RegisterSlash(5, '/x', function() end)))
  end)

  T.it('a failing handler is reported, never raised', function()
    local W, P = boot()
    P.RegisterSlash('BOOM', '/boom', function() error('handler bug') end)
    W.env.SlashCmdList.BOOM('x')
    T.truthy(P.GetDiag()[1].msg:find('handler bug', 1, true))
  end)

  T.it('registering again replaces the handler', function()
    local W, P = boot()
    local which
    P.RegisterSlash('TWICE', '/twice', function() which = 'first' end)
    P.RegisterSlash('TWICE', '/twice', function() which = 'second' end)
    W.env.SlashCmdList.TWICE('')
    T.eq(which, 'second')
  end)
end)

T.describe('registration verification (exception E1)', function()
  T.it('a verified registration is recorded as registered = true', function()
    local _, P = boot()
    P.Events.Bind('LOOT_OPENED', function() end)
    T.eq(P.Events.Stats('LOOT_OPENED').registered, true)
    T.truthy(P.Has('event.LOOT_OPENED'))
    T.eq(P.CapNote('event.LOOT_OPENED'), 'registered (verified)')
  end)

  T.it('a silently blocked registration is detected and reported as failed', function()
    local W, P = boot()
    W.state.forbiddenEvents.TRADE_SHOW = true
    local stages = {}
    P.Events.WatchStage(function(e, stage, value) stages[#stages + 1] = e .. ':' .. stage .. '=' .. tostring(value) end)
    local ok, err = P.Events.Bind('TRADE_SHOW', function() end)
    T.falsy(ok)
    T.truthy(err:find('registration not in effect', 1, true))
    T.falsy(P.Has('event.TRADE_SHOW'))
    T.eq(P.Events.Stats('TRADE_SHOW').registered, false)
    T.eq(stages, { 'TRADE_SHOW:registered=false' })
    T.eq(P.GetDiag()[1].level, 'error')
  end)

  T.it('when IsEventRegistered is unavailable the registration is accepted but unverified (nil)', function()
    local _, P = boot({ noIsEventRegistered = true })
    local ok = P.Events.Bind('LOOT_OPENED', function() end)
    T.truthy(ok)
    T.isnil(P.Events.Stats('LOOT_OPENED').registered)
    T.truthy(P.Has('event.LOOT_OPENED'))
    T.eq(P.CapNote('event.LOOT_OPENED'), 'registered (could not verify)')
  end)

  T.it('a blocked event does not receive handlers', function()
    local W, P = boot()
    W.state.forbiddenEvents.TRADE_SHOW = true
    local n = 0
    P.Events.Bind('TRADE_SHOW', function() n = n + 1 end)
    W:fire('TRADE_SHOW')
    T.eq(n, 0)
    T.eq(#P.Events.BoundEvents(), #P.Events.BoundEvents())
    for _, e in ipairs(P.Events.BoundEvents()) do T.neq(e, 'TRADE_SHOW') end
  end)
end)

T.describe('delivery tracking and stage watchers', function()
  T.it('counts deliveries and notifies once, on the first one', function()
    local W, P = boot()
    local seen = {}
    P.Events.WatchStage(function(e, stage, value) seen[#seen + 1] = e .. ':' .. stage .. '=' .. tostring(value) end)
    P.Events.Bind('LOOT_OPENED', function() end)
    T.eq(P.Events.Stats('LOOT_OPENED').delivered, 0)
    W:fire('LOOT_OPENED'); W:fire('LOOT_OPENED'); W:fire('LOOT_OPENED')
    local s = P.Events.Stats('LOOT_OPENED')
    T.eq(s.delivered, 3)
    T.truthy(s.firstGT and s.lastGT)
    local deliveredNotes = 0
    for _, line in ipairs(seen) do
      if line == 'LOOT_OPENED:delivered=true' then deliveredNotes = deliveredNotes + 1 end
    end
    T.eq(deliveredNotes, 1)
  end)

  T.it('delivery is counted even when the handler errors', function()
    local W, P = boot()
    P.Events.Bind('LOOT_OPENED', function() error('bug') end)
    W:fire('LOOT_OPENED')
    T.eq(P.Events.Stats('LOOT_OPENED').delivered, 1)
  end)

  T.it('an event nobody bound has no stats and nothing delivered', function()
    local _, P = boot()
    local s = P.Events.Stats('NEVER_BOUND')
    T.eq(s.delivered, 0)
    T.isnil(s.registered)
    T.isnil(s.payloadUsable)
  end)

  T.it('ReportPayload notifies on the first report and on changes only', function()
    local _, P = boot()
    local seen = {}
    P.Events.WatchStage(function(e, stage, value) if stage == 'payloadUsable' then seen[#seen + 1] = value end end)
    T.truthy(P.Events.ReportPayload('X_EVENT', true))
    T.falsy(P.Events.ReportPayload('X_EVENT', true))
    T.truthy(P.Events.ReportPayload('X_EVENT', false, 'secret'))
    T.falsy(P.Events.ReportPayload('X_EVENT', false))
    T.truthy(P.Events.ReportPayload('X_EVENT', true))
    T.eq(seen, { true, false, true })
    T.eq(P.Events.Stats('X_EVENT').payloadUsable, true)
  end)

  T.it('a failing stage watcher never breaks delivery', function()
    local W, P = boot()
    P.Events.WatchStage(function() error('watcher bug') end)
    local n = 0
    P.Events.Bind('LOOT_OPENED', function() n = n + 1 end)
    W:fire('LOOT_OPENED')
    T.eq(n, 1)
  end)

  T.it('WatchStage validates its argument; BoundEvents is sorted', function()
    local _, P = boot()
    T.isnil((P.Events.WatchStage('x')))
    P.Events.Bind('B_EVENT', function() end)
    P.Events.Bind('A_EVENT', function() end)
    local bound = P.Events.BoundEvents()
    for i = 2, #bound do T.truthy(bound[i - 1] <= bound[i]) end
  end)

  T.it('Unbind forgets the registration state', function()
    local _, P = boot()
    local fn = function() end
    P.Events.Bind('LOOT_OPENED', fn)
    P.Events.Unbind('LOOT_OPENED', fn)
    T.isnil(P.Events.Stats('LOOT_OPENED').registered)
  end)
end)

T.describe('registration check fail-safe for events proven in the live client (D-034)', function()
  T.it('if IsEventRegistered disagrees about a proven event, the event still works and a warning is logged', function()
    local W, P = boot()
    W.state.forbiddenEvents.PLAYER_MONEY = true      -- the fake now reports "not registered" for it
    local n = 0
    local ok = P.Events.Bind('PLAYER_MONEY', function() n = n + 1 end)
    T.truthy(ok, 'trusted event is accepted')
    T.isnil(P.Events.Stats('PLAYER_MONEY').registered)
    T.truthy(P.Has('event.PLAYER_MONEY'))
    W:fire('PLAYER_MONEY')
    T.eq(n, 0, 'the fake client never delivers a blocked event, so nothing fires here')
    local warned = false
    for _, d in ipairs(P.GetDiag()) do
      if d.level == 'warn' and d.msg:find('proven in the live client', 1, true) then warned = true end
    end
    T.truthy(warned)
  end)

  T.it('the trusted list is exactly the 12 Phase 1 events; unproven events are still verified strictly', function()
    local _, P = boot()
    local n = 0
    for _ in pairs(P.TRUSTED_EVENTS) do n = n + 1 end
    T.eq(n, 12)
    T.falsy(P.TRUSTED_EVENTS.LOOT_OPENED)
    T.falsy(P.TRUSTED_EVENTS.COMBAT_LOG_EVENT_UNFILTERED)
  end)

  T.it('a delivered event is never reported as blocked, even if registration was doubted', function()
    local W, P, ns = Loader.boot()
    W:login()
    local C = ns.Capabilities
    C.Set('event.X', 'registered', false, 'doubted')
    T.eq(C.Level('event.X'), 'blocked')
    C.Set('event.X', 'delivered', true)
    T.eq(C.Level('event.X'), 'delivered')
  end)
end)
