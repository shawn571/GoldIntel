--[[
Tests / test_unit.lua                                       (task 1.4: Unit.lua)

Identity fallbacks, class token, both profession adapters, collapsed skill headers,
locale handling, debounced P_PROFS and P_LEVEL events.
]]

local T = require('testlib')
local Loader = require('loader')

local FILES = {
  'Platform/Platform.lua', 'Platform/Clock.lua', 'Platform/Events.lua',
  'Platform/Scheduler.lua', 'Platform/Unit.lua',
}

local function boot(fakeOpts)
  return Loader.boot(fakeOpts or {}, { only = FILES })
end

T.describe('Platform.Player identity', function()
  T.it('returns GUID-keyed identity with class token and level', function()
    local W, P = boot()
    local p = P.Player()
    T.eq(p.guid, W.state.guid)
    T.eq(p.key, W.state.guid)
    T.eq(p.keyKind, 'guid')
    T.eq(p.name, 'Tester')
    T.eq(p.class, 'MAGE')
    T.eq(p.level, 12)
    T.eq(p.faction, 'Alliance')
    T.eq(type(p.profs), 'table')
  end)

  T.it('falls back to a name-based key when the GUID is unavailable', function()
    local W, P = boot()
    W.state.guid = nil
    local p = P.Player()
    T.isnil(p.guid)
    T.eq(p.keyKind, 'name')
    T.eq(p.key, 'name:Tester:Alliance')
  end)

  T.it('name fallback tolerates a missing faction', function()
    local W, P = boot()
    W.state.guid, W.state.faction = nil, nil
    T.eq(P.Player().key, 'name:Tester:?')
  end)

  T.it('returns nil plus a reason when neither GUID nor name exist', function()
    local W, P = boot()
    W.state.guid, W.state.name = nil, nil
    local p, err = P.Player()
    T.isnil(p)
    T.truthy(err)
  end)

  T.it('treats empty strings as missing', function()
    local W, P = boot()
    W.state.guid = ''
    T.eq(P.Player().keyKind, 'name')
  end)

  T.it('survives API functions that raise errors', function()
    local W, P = boot()
    W.env.UnitLevel = function() error('nope') end
    local p = P.Player()
    T.isnil(p.level)
    T.eq(p.name, 'Tester')
  end)

  T.it('missing Unit APIs yield nil fields, not crashes', function()
    local _, P = boot({ without = { 'UnitClass', 'UnitLevel', 'UnitFactionGroup' } })
    local p = P.Player()
    T.truthy(p)
    T.isnil(p.class)
    T.isnil(p.level)
    T.isnil(p.faction)
  end)

  T.it('every call returns a fresh table', function()
    local _, P = boot()
    local a, b = P.Player(), P.Player()
    T.truthy(a ~= b)
    a.profs.Cheating = 999
    T.isnil(P.Player().profs.Cheating)
  end)
end)

T.describe('professions: modern API only (D-027)', function()
  local PROFS = function() return { { 'Mining', 75 }, { 'Herbalism', 40 }, { 'Fishing', 10 } } end

  T.it('reads the professions through GetProfessions', function()
    local _, P = boot({ retailProfessions = PROFS() })
    T.eq(P.Unit.ReadProfessions(), { Mining = 75, Herbalism = 40, Fishing = 10 })
    T.truthy(P.Has('prof.getprofessions'))
  end)

  T.it('classic skill-line APIs are ignored: without GetProfessions the set is empty', function()
    local _, P = boot()
    T.eq(P.Unit.ReadProfessions(), {})
    T.falsy(P.Has('prof.getprofessions'))
    T.isnil(P.Has('prof.skilllines') and true or nil)
  end)

  T.it('the removed adapter pieces are gone', function()
    local _, P = boot()
    T.isnil(P.Unit.SetProfessionHeaders)
  end)

  T.it('no profession API at all: empty professions', function()
    local _, P = boot({ without = { 'GetProfessions', 'GetProfessionInfo' } })
    T.eq(P.Unit.ReadProfessions(), {})
    T.falsy(P.Has('prof.getprofessions'))
  end)

  T.it('a character with no professions reads an empty set', function()
    local _, P = boot({ retailProfessions = {} })
    T.eq(P.Unit.ReadProfessions(), {})
  end)
end)

T.describe('professions via GetProfessions', function()
  T.it('prefers the retail-style API when present', function()
    local _, P = boot({ retailProfessions = { { 'Alchemy', 225 }, { 'Herbalism', 200 } } })
    T.eq(P.Unit.ReadProfessions(), { Alchemy = 225, Herbalism = 200 })
    T.truthy(P.Has('prof.getprofessions'))
  end)

  T.it('GetProfessions raising an error yields an empty set (no fallback, D-027)', function()
    local W, P = boot({ retailProfessions = { { 'Alchemy', 225 } } })
    W.env.GetProfessions = function() error('api broke') end
    T.eq(P.Unit.ReadProfessions(), {})
    T.falsy(P.Has('prof.getprofessions'))
  end)

  T.it('malformed profession info is skipped', function()
    local _, P = boot({ retailProfessions = { { 'Alchemy', 'high' }, { 'Mining', 100 } } })
    T.eq(P.Unit.ReadProfessions(), { Mining = 100 })
  end)
end)

T.describe('P_LEVEL', function()
  T.it('uses the level argument of PLAYER_LEVEL_UP', function()
    local W, P = boot()
    local levels = {}
    P.On('P_LEVEL', function(p) levels[#levels + 1] = p.level end)
    W:fire('PLAYER_LEVEL_UP', 13)
    T.eq(levels, { 13 })
  end)

  T.it('falls back to UnitLevel when the argument is missing, and ignores garbage', function()
    local W, P = boot()
    local levels = {}
    P.On('P_LEVEL', function(p) levels[#levels + 1] = p.level end)
    W.state.level = 20
    W:fire('PLAYER_LEVEL_UP')
    T.eq(levels, { 20 })
    W.env.UnitLevel = function() return nil end
    W:fire('PLAYER_LEVEL_UP', 'abc')
    T.eq(levels, { 20 }, 'no event when no level can be determined')
  end)
end)

T.describe('P_PROFS (debounced, change-only)', function()
  local function profs()
    return { { 'Mining', 75 }, { 'Herbalism', 40 }, { 'Fishing', 10 } }
  end
  local function ready(extra)
    local t = profs()
    local opts = { retailProfessions = t }
    for k, v in pairs(extra or {}) do opts[k] = v end
    local W, P = boot(opts)
    W:login()
    return W, P, t
  end

  T.it('does not emit at login (cache is primed silently)', function()
    local W, P = boot({ retailProfessions = profs() })
    local n = 0
    P.On('P_PROFS', function() n = n + 1 end)
    W:login()
    W:advance(3)
    T.eq(n, 0)
  end)

  T.it('emits once after a rank change, debounced across a burst of events', function()
    local W, P, t = ready()
    local seen = {}
    P.On('P_PROFS', function(p) seen[#seen + 1] = p.profs.Mining end)
    t[1][2] = 76
    for _ = 1, 10 do W:fire('SKILL_LINES_CHANGED') end
    T.eq(#seen, 0, 'nothing before the debounce expires')
    W:advance(P.Unit.DEBOUNCE_SECONDS + 0.5)
    T.eq(seen, { 76 })
  end)

  T.it('does not emit when the event fired but professions did not change', function()
    local W, P = ready()
    local n = 0
    P.On('P_PROFS', function() n = n + 1 end)
    W:fire('SKILL_LINES_CHANGED')
    W:advance(2)
    T.eq(n, 0)
  end)

  T.it('emits when a profession is learned', function()
    local W, P, t = ready()
    local got
    P.On('P_PROFS', function(p) got = p.profs end)
    table.insert(t, { 'Skinning', 1 })
    W:fire('SKILL_LINES_CHANGED')
    W:advance(2)
    T.eq(got, { Mining = 75, Herbalism = 40, Skinning = 1, Fishing = 10 })
  end)

  T.it('a second burst after the first is handled again', function()
    local W, P, t = ready()
    local n = 0
    P.On('P_PROFS', function() n = n + 1 end)
    t[1][2] = 80
    W:fire('SKILL_LINES_CHANGED'); W:advance(2)
    t[1][2] = 85
    W:fire('SKILL_LINES_CHANGED'); W:advance(2)
    T.eq(n, 2)
  end)

  T.it('without any timer backend the refresh happens immediately', function()
    local W, P, t = ready({ without = { 'C_Timer' } })
    -- drop the frame-based backend too by emptying Init
    W.env.CreateFrame = nil
    P.Scheduler.Init()
    local n = 0
    P.On('P_PROFS', function() n = n + 1 end)
    t[1][2] = 99
    W:fire('SKILL_LINES_CHANGED')
    T.eq(n, 1)
  end)

  T.it('events before ready are ignored', function()
    local W, P = boot()
    local n = 0
    P.On('P_PROFS', function() n = n + 1 end)
    W:fire('SKILL_LINES_CHANGED')
    W:advance(3)
    T.eq(n, 0)
  end)
end)

T.describe('12.0 secret values (defensive, unverified in the real client)', function()
  T.it('secret identity values are treated as unavailable, not stored', function()
    local W, P = boot()
    W.env.issecretvalue = function(v) return v == W.state.guid end
    local p = P.Player()
    T.isnil(p.guid)
    T.eq(p.keyKind, 'name')
    T.eq(p.name, 'Tester')
  end)
end)
