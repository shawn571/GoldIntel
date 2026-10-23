--[[
Tests / test_map.lua                                        (task 1.4: Map.lua)

Location reading and degradation, zone-change dedupe, tick cadence and dt clamping.
]]

local T = require('testlib')
local Loader = require('loader')

local FILES = {
  'Platform/Platform.lua', 'Platform/Clock.lua', 'Platform/Events.lua',
  'Platform/Scheduler.lua', 'Platform/Map.lua',
}

local function boot(fakeOpts)
  return Loader.boot(fakeOpts or {}, { only = FILES })
end

--- Boots, logs in, and returns collectors for P_ZONE and P_TICK.
local function bootInWorld(fakeOpts)
  local W, P = boot(fakeOpts)
  local zones, ticks = {}, {}
  P.On('P_ZONE', function(p) zones[#zones + 1] = p.loc end)
  P.On('P_TICK', function(p) ticks[#ticks + 1] = p end)
  W:login()
  return W, P, zones, ticks
end

T.describe('Platform.Where', function()
  T.it('returns mapID, normalized position, zone, subzone and locale', function()
    local W, P = boot()
    W.state.pos = { 0.25, 0.75 }
    T.eq(P.Where(), { mapID = 1411, zone = 'Durotar', sub = 'Valley of Trials',
      locale = 'enUS', x = 0.25, y = 0.75 })
  end)

  T.it('empty subzone text becomes nil', function()
    local W, P = boot()
    W.state.sub = ''
    T.isnil(P.Where().sub)
  end)

  T.it('position unavailable (instances) keeps the zone but drops x/y', function()
    local W, P = boot()
    W.state.pos = nil
    local loc = P.Where()
    T.eq(loc.mapID, 1411)
    T.isnil(loc.x)
    T.isnil(loc.y)
  end)

  T.it('a (0,0) position is treated as unavailable', function()
    local W, P = boot()
    W.state.pos = { 0, 0 }
    local loc = P.Where()
    T.isnil(loc.x)
    T.isnil(loc.y)
  end)

  T.it('out-of-range and NaN positions are rejected', function()
    local W, P = boot()
    W.state.pos = { 1.5, 0.5 }
    T.isnil(P.Where().x)
    W.state.pos = { 0.5, -0.1 }
    T.isnil(P.Where().x)
    W.state.pos = { 0 / 0, 0.5 }
    T.isnil(P.Where().x)
  end)

  T.it('a position object without GetXY is tolerated', function()
    local W, P = boot()
    W.env.C_Map.GetPlayerMapPosition = function() return {} end
    T.isnil(P.Where().x)
  end)

  T.it('without C_Map: no mapID or position, zone text still identifies the place', function()
    local _, P = boot({ without = { 'C_Map' } })
    local loc = P.Where()
    T.isnil(loc.mapID)
    T.isnil(loc.x)
    T.eq(loc.zone, 'Durotar')
    T.eq(loc.sub, 'Valley of Trials')
  end)

  T.it('without C_Map and zone text: nil plus a reason', function()
    local _, P = boot({ without = { 'C_Map', 'GetZoneText', 'GetSubZoneText' } })
    local loc, err = P.Where()
    T.isnil(loc)
    T.eq(err, 'no location data')
  end)

  T.it('API errors are swallowed', function()
    local W, P = boot()
    W.env.C_Map.GetBestMapForUnit = function() error('map broke') end
    W.env.GetZoneText = function() error('zone broke') end
    local loc, err = P.Where()
    T.isnil(loc)
    T.truthy(err)
  end)
end)

T.describe('P_ZONE', function()
  T.it('fires once on entering the world with the initial location', function()
    local _, _, zones = bootInWorld()
    T.eq(#zones, 1)
    T.eq(zones[1].zone, 'Durotar')
  end)

  T.it('fires on a subzone change, not on repeated identical checks', function()
    local W, _, zones = bootInWorld()
    W:fire('ZONE_CHANGED')
    T.eq(#zones, 1, 'same place: no event')
    W.state.sub = 'Razor Hill'
    W:fire('ZONE_CHANGED')
    W:fire('ZONE_CHANGED')
    T.eq(#zones, 2)
    T.eq(zones[2].sub, 'Razor Hill')
  end)

  T.it('fires on a map change and on indoors/new-area events', function()
    local W, _, zones = bootInWorld()
    W.state.mapID, W.state.zone, W.state.sub = 1412, 'Mulgore', 'Bloodhoof Village'
    W:fire('ZONE_CHANGED_NEW_AREA')
    W.state.sub = 'The Rolling Plains'
    W:fire('ZONE_CHANGED_INDOORS')
    T.eq(#zones, 3)
  end)

  T.it('position changes inside the same subzone do not fire', function()
    local W, _, zones = bootInWorld()
    W.state.pos = { 0.9, 0.9 }
    W:fire('ZONE_CHANGED')
    T.eq(#zones, 1)
  end)

  T.it('is not emitted while out of world', function()
    local W, P = boot()
    local n = 0
    P.On('P_ZONE', function() n = n + 1 end)
    W:fire('ZONE_CHANGED')
    T.eq(n, 0)
  end)

  T.it('is not emitted when no location data exists', function()
    local W, _, zones = bootInWorld({ without = { 'C_Map', 'GetZoneText', 'GetSubZoneText' } })
    W:fire('ZONE_CHANGED')
    T.eq(#zones, 0)
  end)
end)

T.describe('P_TICK', function()
  T.it('ticks every 0.5 s with the actual elapsed time', function()
    local W, _, _, ticks = bootInWorld()
    W:advance(2.0)
    T.eq(#ticks, 4)
    for _, tk in ipairs(ticks) do T.near(tk.dt, 0.5, 1e-6) end
    T.eq(ticks[1].loc.zone, 'Durotar')
  end)

  T.it('clamps dt after a long stall', function()
    local W, P, _, ticks = bootInWorld()
    W:advance(1.0)
    local before = #ticks
    W:stall(120)
    T.eq(#ticks, before + 1)
    T.near(ticks[#ticks].dt, P.Map.MAX_TICK_DT)
  end)

  T.it('does not tick (or credit time) while in a loading screen', function()
    local W, _, _, ticks = bootInWorld()
    W:advance(1.0)
    local n = #ticks
    W:fire('PLAYER_LEAVING_WORLD')
    W:advance(5.0)
    T.eq(#ticks, n)
    W:fire('PLAYER_ENTERING_WORLD')
    W:advance(0.5)
    T.eq(#ticks, n + 1)
    T.near(ticks[#ticks].dt, 0.5, 1e-6, 'first tick after a loading screen is a fresh interval')
  end)

  T.it('ticks carry loc = nil when location is unavailable (and still tick)', function()
    local W, _, _, ticks = bootInWorld({ without = { 'C_Map', 'GetZoneText', 'GetSubZoneText' } })
    W:advance(1.0)
    T.eq(#ticks, 2)
    T.isnil(ticks[1].loc)
  end)

  T.it('a negative clock jump yields dt = 0, never negative', function()
    local W, P, _, ticks = bootInWorld()
    W:advance(0.5)
    W.state.gt = W.state.gt - 50
    P.Clock.Reset()
    P.Map.OnTick()
    T.truthy(ticks[#ticks].dt >= 0)
  end)

  T.it('Reset stops the ticker', function()
    local W, P, _, ticks = bootInWorld()
    W:advance(1.0)
    P.Map.Reset()
    local n = #ticks
    W:advance(3.0)
    T.eq(#ticks, n)
  end)

  T.it('no timer backend: a diagnostic explains why ticks are missing', function()
    local W, P = boot({ without = { 'C_Timer', 'CreateFrame' } })
    -- Platform cannot even bind events without a frame; Map must not raise during OnReady.
    P.MarkReady()
    T.truthy(P.DiagCount() >= 1)
    T.isnil(W.frames[1])
  end)
end)

T.describe('12.0 secret values (defensive, unverified in the real client)', function()
  T.it('a secret map id and position are dropped; readable zone text still identifies the place', function()
    local W, P = boot()
    W.env.issecretvalue = function(v) return v == 1411 or v == 0.25 end
    W.state.pos = { 0.25, 0.75 }
    local loc = P.Where()
    T.isnil(loc.mapID)
    T.isnil(loc.x)
    T.eq(loc.zone, 'Durotar')
    T.eq(loc.sub, 'Valley of Trials')
  end)

  T.it('when every location value is secret there is no location, and nothing raises', function()
    local W, P = boot()
    W.env.issecretvalue = function() return true end
    local loc, err = P.Where()
    T.isnil(loc)
    T.eq(err, 'no location data')
  end)
end)
