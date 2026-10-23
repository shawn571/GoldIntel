--[[
Tests / test_events.lua                                     (task 1.4: Events.lua)

Dispatcher semantics, payload validation, reentrancy, WoW event binding, lifecycle events.
]]

local T = require('testlib')
local Loader = require('loader')

local FILES = { 'Platform/Platform.lua', 'Platform/Clock.lua', 'Platform/Events.lua' }

local function boot(fakeOpts)
  return Loader.boot(fakeOpts or {}, { only = FILES })
end

T.describe('normalized event subscription', function()
  T.it('delivers payloads to handlers in subscription order', function()
    local _, P = boot()
    local seen = {}
    P.On('P_LEVEL', function(p) seen[#seen + 1] = 'a' .. p.level end)
    P.On('P_LEVEL', function(p) seen[#seen + 1] = 'b' .. p.level end)
    T.eq(P.Emit('P_LEVEL', { level = 7 }), 2)
    T.eq(seen, { 'a7', 'b7' })
  end)

  T.it('rejects unknown events and non-function handlers', function()
    local _, P = boot()
    local r1, e1 = P.On('P_NOPE', function() end)
    T.isnil(r1)
    T.truthy(e1)
    local r2, e2 = P.On('P_LEVEL', 'x')
    T.isnil(r2)
    T.truthy(e2)
    local r3 = P.On(42, function() end)
    T.isnil(r3)
  end)

  T.it('subscribing the same function twice delivers once', function()
    local _, P = boot()
    local n = 0
    local fn = function() n = n + 1 end
    P.On('P_LEVEL', fn)
    P.On('P_LEVEL', fn)
    P.Emit('P_LEVEL', { level = 1 })
    T.eq(n, 1)
  end)

  T.it('Off removes a handler and reports whether it existed', function()
    local _, P = boot()
    local n = 0
    local fn = function() n = n + 1 end
    P.On('P_LEVEL', fn)
    T.truthy(P.Off('P_LEVEL', fn))
    T.falsy(P.Off('P_LEVEL', fn))
    T.falsy(P.Off('P_ZONE', fn))
    P.Emit('P_LEVEL', { level = 1 })
    T.eq(n, 0)
  end)

  T.it('a failing handler is reported and does not block the next one', function()
    local _, P = boot()
    local ran = false
    P.On('P_LEVEL', function() error('handler bug') end)
    P.On('P_LEVEL', function() ran = true end)
    T.eq(P.Emit('P_LEVEL', { level = 1 }), 2)
    T.truthy(ran)
    T.truthy(P.GetDiag()[1].msg:find('handler bug', 1, true))
  end)

  T.it('handlers removed during dispatch are skipped without corrupting the list', function()
    local _, P = boot()
    local calls = {}
    local second
    local first = function() calls[#calls + 1] = 'first'; P.Off('P_LEVEL', second) end
    second = function() calls[#calls + 1] = 'second' end
    local third = function() calls[#calls + 1] = 'third' end
    P.On('P_LEVEL', first)
    P.On('P_LEVEL', second)
    P.On('P_LEVEL', third)
    P.Emit('P_LEVEL', { level = 1 })
    T.eq(calls, { 'first', 'third' })
    T.eq(P.Events.HandlerCount('P_LEVEL'), 2)
    calls = {}
    P.Emit('P_LEVEL', { level = 1 })
    T.eq(calls, { 'first', 'third' })
  end)

  T.it('handlers added during dispatch run from the next event on', function()
    local _, P = boot()
    local calls = {}
    local late = function() calls[#calls + 1] = 'late' end
    P.On('P_LEVEL', function() calls[#calls + 1] = 'early'; P.On('P_LEVEL', late) end)
    P.Emit('P_LEVEL', { level = 1 })
    T.eq(calls, { 'early' })
    P.Emit('P_LEVEL', { level = 1 })
    T.eq(calls, { 'early', 'early', 'late' })
  end)

  T.it('nested emits of the same event stay consistent', function()
    local _, P = boot()
    local depthSeen = 0
    local count = 0
    P.On('P_LEVEL', function(p)
      count = count + 1
      if p.level == 1 then P.Emit('P_LEVEL', { level = 2 }) end
      depthSeen = depthSeen + 1
    end)
    P.Emit('P_LEVEL', { level = 1 })
    T.eq(count, 2)
    T.eq(depthSeen, 2)
  end)

  T.it('emitting with no subscribers is a cheap no-op returning 0', function()
    local _, P = boot()
    T.eq(P.Emit('P_ZONE', { loc = {} }), 0)
  end)

  T.it('emitting an unknown event reports an error and returns 0', function()
    local _, P = boot()
    T.eq(P.Emit('P_BOGUS', {}), 0)
    T.eq(P.GetDiag()[1].level, 'error')
  end)

  T.it('a nil payload is delivered as an empty table', function()
    local _, P = boot()
    local got
    P.On('P_LOGOUT', function(p) got = p end)
    P.Emit('P_LOGOUT')
    T.eq(got, {})
  end)

  T.it('nothing is delivered after a fatal failure except P_LOGOUT', function()
    local _, P = boot()
    local n, out = 0, 0
    P.On('P_LEVEL', function() n = n + 1 end)
    P.On('P_LOGOUT', function() out = out + 1 end)
    P.Fatal('money.get', 'test')
    P.Emit('P_LEVEL', { level = 1 })
    P.Emit('P_LOGOUT', {})
    T.eq(n, 0)
    T.eq(out, 1)
  end)
end)

T.describe('payload validation', function()
  T.it('accepts valid payloads including optional fields', function()
    local _, P = boot()
    T.truthy(P.Events.Validate('P_MONEY', { copper = -5, gt = 1.5 }))
    T.truthy(P.Events.Validate('P_MONEY', { copper = 5, gt = 1.5, gap = true }))
    T.truthy(P.Events.Validate('P_TICK', { dt = 0.5 }))
    T.truthy(P.Events.Validate('P_LOGOUT', {}))
  end)

  T.it('rejects missing fields, wrong types, non-tables and unknown events', function()
    local _, P = boot()
    local ok, why = P.Events.Validate('P_MONEY', { copper = 5 })
    T.falsy(ok)
    T.truthy(why:find('gt', 1, true))
    ok, why = P.Events.Validate('P_MONEY', { copper = '5', gt = 1 })
    T.falsy(ok)
    T.truthy(why:find('copper', 1, true))
    T.falsy((P.Events.Validate('P_MONEY', 'x')))
    T.falsy((P.Events.Validate('P_NOPE', {})))
    T.falsy((P.Events.Validate('P_MONEY', { copper = 1, gt = 1, gap = 'yes' })))
  end)

  T.it('strict mode drops invalid payloads; lenient mode only reports', function()
    local _, P = boot()
    local n = 0
    P.On('P_LEVEL', function() n = n + 1 end)
    P.validate = true
    P.Emit('P_LEVEL', { level = 'high' })
    T.eq(n, 1, 'lenient: delivered but reported')
    T.eq(P.GetDiag()[1].level, 'error')
    P.validate = 'strict'
    P.Emit('P_LEVEL', { level = 'high' })
    T.eq(n, 1, 'strict: dropped')
  end)

  T.it('every declared event has a consistent spec', function()
    local _, P = boot()
    local names = P.Events.Names()
    T.truthy(#names >= 25)
    for _, name in ipairs(names) do
      for field, want in pairs(P.Events.SPEC[name]) do
        T.truthy(want:match('^%a+%??$'), name .. '.' .. field .. ' has a malformed type spec')
      end
    end
  end)
end)

T.describe('debug echo', function()
  T.it('prints normalized events, hides ticks unless enabled', function()
    local W, P = boot()
    P.SetDebug(true)
    P.Emit('P_LEVEL', { level = 9 })
    T.truthy(W:printedText():find('[evt] P_LEVEL level=9', 1, true))
    local before = #W.printed
    P.Emit('P_TICK', { dt = 0.5 })
    T.eq(#W.printed, before, 'ticks are silent')
    P.debugTicks = true
    P.Emit('P_TICK', { dt = 0.5 })
    T.eq(#W.printed, before + 1)
  end)
end)

T.describe('raw WoW event binding', function()
  T.it('creates one frame, registers each event once, routes arguments', function()
    local W, P = boot()
    local got = {}
    P.Events.Bind('LOOT_OPENED', function(ev, a, b) got[#got + 1] = { ev, a, b } end)
    P.Events.Bind('LOOT_OPENED', function() got[#got + 1] = 'second' end)
    W:fire('LOOT_OPENED', 1, 2)
    T.eq(got, { { 'LOOT_OPENED', 1, 2 }, 'second' })
    T.eq(#W.frames, 1, 'a single shared frame')
    T.truthy(P.Has('event.LOOT_OPENED'))
  end)

  T.it('binding the same function twice does not duplicate delivery', function()
    local W, P = boot()
    local n = 0
    local fn = function() n = n + 1 end
    P.Events.Bind('LOOT_SLOT_CLEARED', fn)
    P.Events.Bind('LOOT_SLOT_CLEARED', fn)
    W:fire('LOOT_SLOT_CLEARED')
    T.eq(n, 1)
  end)

  T.it('an event name the client reports invalid is skipped WITHOUT calling RegisterEvent', function()
    local W, P = boot()
    W.state.invalidEvents.QUEST_TURNED_IN = true
    local ok, err = P.Events.Bind('QUEST_TURNED_IN', function() end)
    T.falsy(ok)
    T.truthy(err:find('QUEST_TURNED_IN', 1, true))
    T.falsy(P.Has('event.QUEST_TURNED_IN'))
    T.truthy(P.CapNote('event.QUEST_TURNED_IN'))
    for _, e in ipairs(W.registerCalls) do T.neq(e, 'QUEST_TURNED_IN') end
  end)

  T.it('without C_EventUtils a rejected registration is still caught (error path)', function()
    local W, P = Loader.boot({ without = { 'C_EventUtils' } }, { only = FILES })
    W.state.invalidEvents.QUEST_TURNED_IN = true
    local ok, err = P.Events.Bind('QUEST_TURNED_IN', function() end)
    T.falsy(ok)
    T.truthy(err:find('QUEST_TURNED_IN', 1, true))
    T.falsy(P.Has('event.QUEST_TURNED_IN'))
  end)

  T.it('restricted events are refused and RegisterEvent is never called for them', function()
    local W, P = boot()
    W.state.forbiddenEvents.COMBAT_LOG_EVENT_UNFILTERED = true
    local ok, err = P.Events.Bind('COMBAT_LOG_EVENT_UNFILTERED', function() end)
    T.falsy(ok)
    T.truthy(err:find('restricted', 1, true))
    T.falsy(P.Has('event.COMBAT_LOG_EVENT_UNFILTERED'))
    T.eq(#W.forbidden, 0, 'the client must never see a forbidden registration')
    for _, e in ipairs(W.registerCalls) do T.neq(e, 'COMBAT_LOG_EVENT_UNFILTERED') end
  end)

  T.it('the restricted list can be extended at runtime', function()
    local W, P = boot()
    local before = #W.registerCalls
    P.RESTRICTED_EVENTS.SOME_NEW_EVENT = true
    T.falsy((P.Events.Bind('SOME_NEW_EVENT', function() end)))
    T.eq(#W.registerCalls, before)
  end)

  T.it('a failing raw handler does not stop the next handler', function()
    local W, P = boot()
    local ran = false
    P.Events.Bind('MERCHANT_SHOW', function() error('raw boom') end)
    P.Events.Bind('MERCHANT_SHOW', function() ran = true end)
    W:fire('MERCHANT_SHOW')
    T.truthy(ran)
  end)

  T.it('Bind validates its arguments', function()
    local _, P = boot()
    T.falsy((P.Events.Bind(42, function() end)))
    T.falsy((P.Events.Bind('X', nil)))
  end)

  T.it('Unbind removes the handler and unregisters the event when unused', function()
    local W, P = boot()
    local fn = function() end
    P.Events.Bind('MERCHANT_CLOSED', fn)
    T.truthy(W.frames[1].events.MERCHANT_CLOSED)
    T.truthy(P.Events.Unbind('MERCHANT_CLOSED', fn))
    T.isnil(W.frames[1].events.MERCHANT_CLOSED)
    T.falsy(P.Events.Unbind('MERCHANT_CLOSED', fn))
  end)

  T.it('without CreateFrame binding fails gracefully and flags the capability', function()
    local _, P = Loader.boot({ without = { 'CreateFrame' } }, { only = FILES })
    local ok, err = P.Events.Bind('X_EVENT', function() end)
    T.falsy(ok)
    T.truthy(err)
    T.falsy(P.Has('frame'))
  end)
end)

T.describe('lifecycle events', function()
  T.it('PLAYER_LOGIN marks the platform ready', function()
    local W, P = boot()
    T.falsy(P.IsReady())
    W:fire('PLAYER_LOGIN')
    T.truthy(P.IsReady())
  end)

  T.it('in-world flag follows ENTERING/LEAVING_WORLD', function()
    local W, P = boot()
    T.falsy(P.InWorld())
    W:fire('PLAYER_ENTERING_WORLD')
    T.truthy(P.InWorld())
    W:fire('PLAYER_LEAVING_WORLD')
    T.falsy(P.InWorld())
  end)

  T.it('REGEN events become P_COMBAT', function()
    local W, P = boot()
    local seen = {}
    P.On('P_COMBAT', function(p) seen[#seen + 1] = p.inCombat end)
    W:fire('PLAYER_REGEN_DISABLED')
    T.truthy(P.Events.inCombat)
    W:fire('PLAYER_REGEN_ENABLED')
    T.falsy(P.Events.inCombat)
    T.eq(seen, { true, false })
  end)

  T.it('PLAYER_LOGOUT becomes P_LOGOUT', function()
    local W, P = boot()
    local n = 0
    P.On('P_LOGOUT', function() n = n + 1 end)
    W:fire('PLAYER_LOGOUT')
    T.eq(n, 1)
  end)

  T.it('late load: CheckLateLoad marks ready when already logged in', function()
    local W, P = boot()
    W.state.loggedIn = true
    local ran = false
    P.OnReady(function() ran = true end)
    T.truthy(P.Events.CheckLateLoad())
    T.truthy(ran)
    T.truthy(P.InWorld())
    T.falsy(P.Events.CheckLateLoad(), 'second call is a no-op')
  end)

  T.it('late load: not logged in means no change', function()
    local _, P = boot()
    T.falsy(P.Events.CheckLateLoad())
    T.falsy(P.IsReady())
  end)

  T.it('late load: IsLoggedIn missing means no change and no error', function()
    local _, P = boot({ without = { 'IsLoggedIn' } })
    T.falsy(P.Events.CheckLateLoad())
  end)
end)
