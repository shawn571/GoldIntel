--[[
Tests / test_events_collect.lua                     (Phase 3b-1: allow-list enforcement, counters, unit filter)
]]

local T = require('testlib')
local World = require('collectworld')

local ALL = { 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'QUEST_TURNED_IN', 'MERCHANT_SHOW', 'MERCHANT_CLOSED',
  'MAIL_INBOX_UPDATE', 'TRADE_SHOW', 'TRADE_CLOSED', 'TRADE_ACCEPT_UPDATE', 'TRADE_MONEY_CHANGED',
  'BAG_UPDATE_DELAYED', 'GET_ITEM_INFO_RECEIVED', 'UNIT_SPELLCAST_SUCCEEDED', 'AUCTION_HOUSE_AUCTION_CREATED', 'CHAT_MSG_MONEY' }

T.describe('allow-list enforcement in Events.Bind (AC-1)', function()
  T.it('refuses an event that is not on the allow-list and registers nothing', function()
    local W, P = World.boot()
    local before = #W.registerCalls
    local ok, err = P.Events.Bind('CHAT_MSG_SAY', function() end)
    T.falsy(ok)
    T.truthy(err:find('allow-list', 1, true))
    T.eq(#W.registerCalls, before)
    T.falsy(P.Has('event.CHAT_MSG_MONEY'))
  end)

  T.it('refuses MAIL_CLOSED and MAIL_SHOW (never delivered / unverified)', function()
    local W, P = World.boot()
    T.falsy((P.Events.Bind('MAIL_CLOSED', function() end)))
    T.falsy((P.Events.Bind('MAIL_SHOW', function() end)))
    for _, e in ipairs(W.registerCalls) do T.neq(e, 'MAIL_CLOSED'); T.neq(e, 'MAIL_SHOW') end
  end)

  T.it('still refuses a restricted event first', function()
    local _, P = World.boot()
    local ok, err = P.Events.Bind('COMBAT_LOG_EVENT_UNFILTERED', function() end)
    T.falsy(ok)
    T.truthy(err:find('restricted', 1, true))
  end)

  T.it('accepts every one of the 15 collector events', function()
    local W, P = World.boot()
    for _, e in ipairs(ALL) do
      T.truthy((P.Events.Bind(e, function() end)), e)
    end
    T.eq(#P.Events.BoundEvents(), 12 + 15)
  end)

  T.it('an invalid event name in this client is still skipped without a registration call', function()
    local W, P = World.boot()
    W.state.invalidEvents.TRADE_SHOW = true
    local before = #W.registerCalls
    local ok = P.Events.Bind('TRADE_SHOW', function() end)
    T.falsy(ok)
    T.eq(#W.registerCalls, before)
  end)
end)

T.describe('delivery counters', function()
  T.it('count received and kept for a normal handler', function()
    local W, P = World.boot()
    P.Events.Bind('MERCHANT_SHOW', function() end)
    W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_SHOW')
    local c = P.Events.Counters('MERCHANT_SHOW')
    T.eq(c.received, 2); T.eq(c.kept, 2); T.eq(c.dropped, 0); T.eq(c.errors, 0)
  end)

  T.it("a handler returning 'dropped' is counted as dropped, not kept", function()
    local W, P = World.boot()
    P.Events.Bind('MERCHANT_SHOW', function() return 'dropped' end)
    W:fire('MERCHANT_SHOW')
    local c = P.Events.Counters('MERCHANT_SHOW')
    T.eq(c.dropped, 1); T.eq(c.kept, 0)
  end)

  T.it('a failing handler is counted as an error and does not stop delivery', function()
    local W, P = World.boot()
    local ran = false
    P.Events.Bind('MERCHANT_SHOW', function() error('boom') end)
    P.Events.Bind('MERCHANT_SHOW', function() ran = true end)
    W:fire('MERCHANT_SHOW')
    T.truthy(ran)
    local c = P.Events.Counters('MERCHANT_SHOW')
    T.eq(c.errors, 1); T.eq(c.kept, 1); T.eq(c.received, 1)
  end)

  T.it('firstGT, lastGT and maxPerSec follow the game clock', function()
    local W, P = World.boot()
    P.Events.Bind('MERCHANT_SHOW', function() end)
    W.state.gt = 2000.1; W:fire('MERCHANT_SHOW')
    W.state.gt = 2000.4; W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_SHOW')
    W.state.gt = 2005.0; W:fire('MERCHANT_SHOW')
    local c = P.Events.Counters('MERCHANT_SHOW')
    T.near(c.firstGT, 2000.1, 1e-6)
    T.near(c.lastGT, 2005.0, 1e-6)
    T.eq(c.maxPerSec, 3)
    T.eq(c.received, 4)
  end)

  T.it('cpu time is recorded when debugprofilestop exists', function()
    local W, P = World.boot()
    local t = 0
    W.env.debugprofilestop = function() t = t + 2.5; return t end
    P.Events.Bind('MERCHANT_SHOW', function() end)
    W:fire('MERCHANT_SHOW')
    local c = P.Events.Counters('MERCHANT_SHOW')
    T.near(c.cpuTotalMs, 2.5, 1e-9)
    T.near(c.cpuMaxMs, 2.5, 1e-9)
  end)

  T.it('cpu fields stay zero without debugprofilestop', function()
    local W, P = World.boot()
    P.Events.Bind('MERCHANT_SHOW', function() end)
    W:fire('MERCHANT_SHOW')
    T.eq(P.Events.Counters('MERCHANT_SHOW').cpuTotalMs, 0)
  end)

  T.it('Counters returns a copy and nil for an event never delivered', function()
    local W, P = World.boot()
    T.isnil(P.Events.Counters('MERCHANT_SHOW'))
    P.Events.Bind('MERCHANT_SHOW', function() end)
    W:fire('MERCHANT_SHOW')
    local c = P.Events.Counters('MERCHANT_SHOW')
    c.received = 99
    T.eq(P.Events.Counters('MERCHANT_SHOW').received, 1)
  end)

  T.it('ResetCounters zeroes the counters and keeps the registration', function()
    local W, P = World.boot()
    P.Events.Bind('MERCHANT_SHOW', function() end)
    W:fire('MERCHANT_SHOW')
    P.Events.ResetCounters()
    T.isnil(P.Events.Counters('MERCHANT_SHOW'))
    T.eq(P.Events.Stats('MERCHANT_SHOW').registered, true)
    W:fire('MERCHANT_SHOW')
    T.eq(P.Events.Counters('MERCHANT_SHOW').received, 1)
  end)

  T.it('CounterNames is sorted', function()
    local W, P = World.boot()
    P.Events.Bind('TRADE_SHOW', function() end)
    P.Events.Bind('MERCHANT_SHOW', function() end)
    W:fire('TRADE_SHOW'); W:fire('MERCHANT_SHOW')
    local names = P.Events.CounterNames()
    local sorted = {}
    for i, n in ipairs(names) do sorted[i] = n end
    table.sort(sorted)
    T.eq(names, sorted)
  end)
end)

T.describe('unit-filtered registration (F-5)', function()
  local function withUnitEvent(W, behaviour)
    W.state.unitCalls = {}
    for _, f in ipairs(W.frames) do
      function f:RegisterUnitEvent(e, unit)
        W.state.unitCalls[#W.state.unitCalls + 1] = e .. ':' .. unit
        if behaviour == 'works' then self.events[e] = true end
        if behaviour == 'error' then error('unit registration failed') end
      end
    end
  end

  T.it('uses RegisterUnitEvent for the player when asked and the client has it', function()
    local W, P = World.boot({ login = false })
    withUnitEvent(W, 'works')
    P.Events.Bind('UNIT_SPELLCAST_SUCCEEDED', function() end, { unit = 'player' })
    T.eq(W.state.unitCalls, { 'UNIT_SPELLCAST_SUCCEEDED:player' })
    T.eq(P.Events.RegisteredVia('UNIT_SPELLCAST_SUCCEEDED'), 'unit-filter')
    T.eq(P.Events.Stats('UNIT_SPELLCAST_SUCCEEDED').registered, true)
  end)

  T.it('falls back to a plain registration when the unit registration is not in effect', function()
    local W, P = World.boot({ login = false })
    withUnitEvent(W, 'noeffect')
    local ok = P.Events.Bind('UNIT_SPELLCAST_SUCCEEDED', function() end, { unit = 'player' })
    T.truthy(ok)
    T.eq(P.Events.RegisteredVia('UNIT_SPELLCAST_SUCCEEDED'), 'plain')
    T.eq(P.Events.Stats('UNIT_SPELLCAST_SUCCEEDED').registered, true)
  end)

  T.it('falls back to a plain registration when the unit registration raises', function()
    local W, P = World.boot({ login = false })
    withUnitEvent(W, 'error')
    T.truthy((P.Events.Bind('UNIT_SPELLCAST_SUCCEEDED', function() end, { unit = 'player' })))
    T.eq(P.Events.RegisteredVia('UNIT_SPELLCAST_SUCCEEDED'), 'plain')
  end)

  T.it('uses the plain registration when the client has no RegisterUnitEvent', function()
    local W, P = World.boot({ login = false })
    P.Events.Bind('UNIT_SPELLCAST_SUCCEEDED', function() end, { unit = 'player' })
    T.eq(P.Events.RegisteredVia('UNIT_SPELLCAST_SUCCEEDED'), 'plain')
  end)

  T.it('without the unit option the plain registration is used even when RegisterUnitEvent exists', function()
    local W, P = World.boot({ login = false })
    withUnitEvent(W, 'works')
    P.Events.Bind('UNIT_SPELLCAST_SUCCEEDED', function() end)
    T.eq(W.state.unitCalls, {})
    T.eq(P.Events.RegisteredVia('UNIT_SPELLCAST_SUCCEEDED'), 'plain')
  end)

  T.it('Unbind clears the registration route', function()
    local W, P = World.boot({ login = false })
    local fn = function() end
    P.Events.Bind('UNIT_SPELLCAST_SUCCEEDED', fn, { unit = 'player' })
    P.Events.Unbind('UNIT_SPELLCAST_SUCCEEDED', fn)
    T.isnil(P.Events.RegisteredVia('UNIT_SPELLCAST_SUCCEEDED'))
  end)
end)

T.describe('Platform call helpers', function()
  T.it('P.Call returns packed results, keeps nil holes and reports missing functions', function()
    local W, P = World.boot()
    W.env.Three = function() return 1, nil, 3 end
    local r = P.Call('Three')
    T.eq(r.n, 3); T.eq(r[1], 1); T.isnil(r[2]); T.eq(r[3], 3)
    local none, why = P.Call('NoSuchFunction')
    T.isnil(none); T.truthy(why:find('missing', 1, true))
  end)

  T.it('P.Call never raises', function()
    local W, P = World.boot()
    W.env.Bad = function() error('client error') end
    local r, why = P.Call('Bad')
    T.isnil(r); T.truthy(why:find('client error', 1, true))
  end)

  T.it('P.CallIn and P.HasIn work on tables of functions', function()
    local W, P = World.boot()
    T.truthy(P.HasIn('C_Container', 'GetContainerNumSlots'))
    T.falsy(P.HasIn('C_Container', 'Nope'))
    T.falsy(P.HasIn('NoTable', 'Nope'))
    T.eq(P.CallIn('C_Container', 'GetContainerNumSlots', 0)[1], 0)
    T.isnil((P.CallIn('NoTable', 'x')))
  end)

  T.it('P.IsAddonLoaded reads C_AddOns or the legacy global and is false when unknown', function()
    local W, P = World.boot()
    T.falsy(P.IsAddonLoaded('GoldIntelDiag'))
    W.env.C_AddOns = { IsAddOnLoaded = function(n) return n == 'GoldIntelDiag' end }
    T.truthy(P.IsAddonLoaded('GoldIntelDiag'))
    T.falsy(P.IsAddonLoaded('Other'))
    W.env.C_AddOns = nil
    W.env.IsAddOnLoaded = function(n) return n == 'X' end
    T.truthy(P.IsAddonLoaded('X'))
  end)
end)
