--[[
Tests / test_stamps.lua                 (Phase 3b-2 M2: Collect/Stamps.lua, Platform/Unit.lua LastCast, hold expectations)
]]

local T = require('testlib')
local Loader = require('loader')
local World = require('collectworld')

local SRC = Loader.readFile(Loader.root .. '/Collect/Stamps.lua')

local function loadStamps(src)
  local ns = {}
  local ld = loadstring or load
  assert(ld(src or SRC, '=Stamps'))('GoldIntel', ns)
  return ns.Stamps
end

local LOC = { mapID = 1411, zone = 'Durotar', sub = 'Valley of Trials', x = 0.5, y = 0.4, locale = 'enUS' }

local function stamps(casts)
  local S = loadStamps()
  return S, S.New{ lastCast = function(kind) return casts and casts[kind] end }
end

local function entry(src, t, sourceType, conf)
  return { t = t, copper = 10, src = src, conf = conf or 'high', ref = sourceType and { sourceType = sourceType } or nil }
end

local function scenarios(S)
  local fails = {}
  local function check(n, ok) if not ok then fails[#fails + 1] = n end end
  local function mk(casts) return S.New{ lastCast = function(k) return casts and casts[k] end } end
  do
    local o = mk(); o:NoteLoc(LOC, 100)
    local e = o:Apply(entry('loot', 105, 'creature'))
    check('fresh at 5.0 s', e.locConf == 'fresh' and e.loc.zone == 'Durotar' and e.creditable == true)
    local e2 = o:Apply(entry('loot', 105.01, 'creature'))
    check('stale after 5.0 s', e2.locConf == 'stale' and e2.creditable == false and e2.loc ~= nil)
  end
  do
    local o = mk()
    local e = o:Apply(entry('loot', 5, 'creature'))
    check('none', e.locConf == 'none' and e.loc == nil and e.creditable == false)
  end
  do
    local o = mk(); o:NoteLoc(LOC, 100)
    local e = o:Apply(entry('loot', 101, 'creature'))
    check('grind', e.act == 'GRIND' and e.actConf == 'med')
    local g = o:Apply(entry('loot', 101, 'object'))
    check('object without cast', g.act == 'OTHER' and g.actConf == 'low' and g.creditable == true)
    local u = o:Apply(entry('loot', 101, 'unknown'))
    check('unknown loot', u.act == 'OTHER' and u.creditable == false)
    local i = o:Apply(entry('loot', 101, 'item'))
    check('item loot', i.creditable == false)
  end
  do
    local o = mk{ herb = 90 }; o:NoteLoc(LOC, 100)
    local e = o:Apply(entry('loot', 110, 'object'))
    check('gather', e.act == 'GATHER' and e.actConf == 'high')
    local o2 = mk{ herb = 80 }; o2:NoteLoc(LOC, 100)
    local e2 = o2:Apply(entry('loot', 110.01, 'object'))
    check('cast window 30 s', e2.act == 'OTHER')
    local o3 = mk{ fish = 95, mine = 90 }; o3:NoteLoc(LOC, 100)
    check('latest cast wins', o3:Apply(entry('loot', 100, 'object')).act == 'FISH')
    local o4 = mk{ herb = 99 }; o4:NoteLoc(LOC, 100)
    check('cast must not be after the entry', o4:Apply(entry('loot', 90, 'object')).act == 'OTHER')
  end
  do
    local o = mk(); o:NoteLoc(LOC, 100)
    for src, act in pairs({ vendor = 'VENDOR', purchase = 'VENDOR', quest = 'QUEST', trade = 'TRADE', mailMoney = 'MAIL',
      codIn = 'MAIL', ahSale = 'MAIL', ahCut = 'MAIL', ahDepositRefund = 'MAIL' }) do
      local e = o:Apply(entry(src, 100, nil, 'med'))
      check('act ' .. src, e.act == act and e.actConf == 'med' and e.creditable == false)
    end
    local e = o:Apply(entry('other', 100, nil, 'low'))
    check('other', e.act == 'OTHER' and e.actConf == 'low' and e.creditable == false)
  end
  do
    local o = mk(); o:NoteLoc(LOC, 100)
    local e = o:Apply(entry('loot', 100, 'creature')); e.loc.zone = 'X'
    local e2 = o:Apply(entry('loot', 100, 'creature'))
    check('loc copied', e2.loc.zone == 'Durotar')
    o:NoteLoc({ zone = 'Z' }, 'bad'); o:NoteLoc('bad', 5)
    check('bad NoteLoc ignored', o:Apply(entry('loot', 100, 'creature')).loc.zone == 'Durotar')
  end
  return fails
end

T.describe('Stamps', function()
  T.it('all scenarios pass on the real source', function() T.eq(scenarios(loadStamps()), {}) end)

  T.it('Clear forgets the location', function()
    local _, o = stamps(); o:NoteLoc(LOC, 1); o:Clear()
    local _, conf = o:Loc(2); T.eq(conf, 'none')
  end)

  local MUT = {
    { 'fresh window too short', "S.FRESH = 5.0", "S.FRESH = 1.0" },
    { 'fresh window exclusive', "if age <= S.FRESH", "if age < S.FRESH" },
    { 'cast window too long', "S.CAST_WINDOW = 30.0", "S.CAST_WINDOW = 300.0" },
    { 'creditable ignores freshness', "and e.locConf == 'fresh') or false", ") or false" },
    { 'creditable for item loot', "(st == 'creature' or st == 'object')", "(st ~= nil)" },
    { 'gathering without cast', "  return bestAct\nend", "  return 'GATHER'\nend" },
    { 'mail is not MAIL', "ahSale = 'MAIL',", "ahSale = 'OTHER'," },
    { 'loc not copied', "local copy = { mapID = self.loc.mapID, zone = self.loc.zone, sub = self.loc.sub, x = self.loc.x, y = self.loc.y }",
      "local copy = self.loc" },
    { 'oldest cast wins', "(not bestGT or gt > bestGT)", "(not bestGT or gt < bestGT)" },
  }
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[1], function()
      local i, j = SRC:find(m[2], 1, true)
      T.truthy(i, 'anchor missing: ' .. m[1])
      local S = loadStamps(SRC:sub(1, i - 1) .. m[3] .. SRC:sub(j + 1))
      local ok, fails = pcall(scenarios, S)
      T.truthy((not ok) or #fails > 0, 'survived: ' .. m[1])
    end)
  end
end)

T.describe('Unit.LastCast', function()
  T.it('remembers the last cast per kind with its game time and spell id', function()
    local W, P = World.boot()
    P.Unit.ResetCasts()
    local E = P.Events
    T.isnil(P.LastCast('herb'))
    W:advance(1)
    P.Unit.OnCast(nil, 'player', 'g', 2366)
    local gt, id = P.LastCast('herb')
    T.truthy(gt); T.eq(id, 2366)
    W:advance(2)
    P.Unit.OnCast(nil, 'player', 'g', 7731)
    local gt2 = P.LastCast('fish')
    T.truthy(gt2 > gt)
    T.eq((P.LastCast('herb')), gt)
  end)
  T.it('other units and unknown spells: other units never recorded; unknown spells recorded as other', function()
    local _, P = World.boot()
    P.Unit.ResetCasts()
    P.Unit.OnCast(nil, 'target', 'g', 2366)
    T.isnil(P.LastCast('herb'))
    P.Unit.OnCast(nil, 'player', 'g', 12345)
    T.truthy(P.LastCast('other'))
  end)
  T.it('a secret spell id is dropped and not recorded', function()
    local _, P = World.boot()
    P.Unit.ResetCasts()
    T.eq(P.Unit.OnCast(nil, 'player', 'g', World.SECRET), 'dropped')
    T.isnil(P.LastCast('herb')); T.isnil(P.LastCast('other'))
  end)
end)

T.describe('Held exact expectations (loot window)', function()
  local function store()
    local ns = {}
    local ld = loadstring or load
    assert(ld(Loader.readFile(Loader.root .. '/Collect/Expectations.lua'), '=X'))('GoldIntel', ns)
    return ns.Expectations.New()
  end
  T.it('a held exact expectation does not expire until Close, then lingers ttl', function()
    local X = store()
    local id = assert(X:Add{ src = 'loot', mode = 'exact', copper = 5, sign = 1, t0 = 0, ttl = 1.0, hold = true })
    T.eq(#X:Active(500), 1)
    T.eq(#X:Expire(500), 0)
    T.truthy(X:Close(id, 10))
    T.eq(#X:Active(11.0), 1)
    T.eq(#X:Active(11.01), 0)
  end)
  T.it('Close on a plain exact expectation is refused and Close twice is refused', function()
    local X = store()
    local a = X:Add{ src = 'loot', mode = 'exact', copper = 5, sign = 1, t0 = 0, ttl = 1.0 }
    T.falsy(X:Close(a, 1))
    local h = X:Add{ src = 'loot', mode = 'exact', copper = 5, sign = 1, t0 = 0, ttl = 1.0, hold = true }
    T.truthy(X:Close(h, 1)); T.falsy(X:Close(h, 2))
  end)
  T.it('a held expectation closed at once still lives its normal ttl', function()
    local X = store()
    local h = X:Add{ src = 'loot', mode = 'exact', copper = 5, sign = 1, t0 = 10, ttl = 1.0, hold = true }
    X:Close(h, 10)
    T.eq(#X:Active(11.0), 1)
  end)
end)
