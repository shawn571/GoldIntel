-- GoldIntel / Platform / Unit.lua                                       (Phase 1, task 1.4)
--
-- PURPOSE
--  Player identity and character attributes.
--      Platform.Player() -> { guid, key, keyKind, name, class, level, faction, profs }
--  Emits normalized events P_LEVEL and P_PROFS.
--
-- IDENTITY (Decisions D-006)
--  The game is realmless, so the character key is the GUID. If the GUID is not
--  available yet, a degraded key 'name:<Name>:<Faction>' is used and keyKind says so.
--
-- CLASS
--  `class` is the non-localized class TOKEN (e.g. 'MAGE'), not the display name,
--  so aggregated data never splits by client language.
--
-- PROFESSIONS (one adapter, D-027)
--  GetProfessions()/GetProfessionInfo()  (modern API; the only one the Forever client has, E-05).
--  The classic skill-line adapter was removed under D-027 (approved 2026-10-18): GetNumSkillLines,
--  GetSkillLineInfo and ExpandSkillHeader do not exist in the target client.
--
--  SKILL_LINES_CHANGED fires very often (every weapon skill-up); it is debounced and
--  P_PROFS is emitted only when the profession set or a rank actually changed.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Unit.lua')

local Unit = {}
P.Unit = Unit
P.Register('Unit', Unit)

local DEBOUNCE_SECONDS = 1.0
Unit.DEBOUNCE_SECONDS = DEBOUNCE_SECONDS

local cachedProfs = nil
local debouncePending = false

---------------------------------------------------------------------------
-- Professions
---------------------------------------------------------------------------

local function readViaGetProfessions()
  local getProfs, getInfo = P.fn('GetProfessions'), P.fn('GetProfessionInfo')
  if not getProfs or not getInfo then return nil end
  local ok, a, b, c, d, e = pcall(getProfs)
  if not ok then return nil end
  local profs = {}
  local indices = { a, b, c, d, e }
  for i = 1, 5 do
    local idx = indices[i]
    if idx then
      local okInfo, name, _, rank = pcall(getInfo, idx)
      if okInfo and type(name) == 'string' and type(rank) == 'number' then
        profs[name] = rank
      end
    end
  end
  return profs
end

--- Reads professions now. Returns a { [name] = rank } table (possibly empty).
function Unit.ReadProfessions()
  local profs = readViaGetProfessions()
  if profs then
    P.SetCap('prof.getprofessions', true)
    return profs
  end
  P.SetCap('prof.getprofessions', false)
  return {}
end

--- Cached professions (reads once). Returns a copy.
function Unit.Professions()
  if not cachedProfs then cachedProfs = Unit.ReadProfessions() end
  return P.Util.shallowCopy(cachedProfs)
end

---------------------------------------------------------------------------
-- Player snapshot
---------------------------------------------------------------------------

local function call(name, ...)
  local f = P.fn(name)
  if not f then return nil end
  local ok, a, b = pcall(f, ...)
  if not ok then return nil end
  if P.IsSecret(a) then a = nil end        -- 12.0 secret values cannot be compared or stored
  if P.IsSecret(b) then b = nil end
  return a, b
end

--- 0.6.0 (P4-M2): true when the player is on a flight path (UnitOnTaxi, verified in Phase 3a), false, or nil when unreadable.
function Unit.OnTaxi()
  local v = call('UnitOnTaxi', 'player')
  if type(v) == 'boolean' then return v end
  return nil
end
P.OnTaxi = Unit.OnTaxi

--- Platform.Player(). Returns the snapshot table, or nil plus a reason when the
-- character cannot be identified yet (too early in login).
function Unit.Player()
  local guid = call('UnitGUID', 'player')
  local name = call('UnitName', 'player')
  local _, classToken = call('UnitClass', 'player')
  local level = call('UnitLevel', 'player')
  local faction = call('UnitFactionGroup', 'player')

  if type(guid) ~= 'string' or guid == '' then guid = nil end
  if type(name) ~= 'string' or name == '' then name = nil end
  if not guid and not name then return nil, 'player identity unavailable' end

  local key, keyKind
  if guid then
    key, keyKind = guid, 'guid'
  else
    key, keyKind = 'name:' .. name .. ':' .. tostring(faction or '?'), 'name'
  end

  return {
    guid = guid,
    key = key,
    keyKind = keyKind,
    name = name,
    class = type(classToken) == 'string' and classToken or nil,
    level = type(level) == 'number' and level or nil,
    faction = type(faction) == 'string' and faction or nil,
    profs = Unit.Professions(),
  }
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local function refreshProfessions(emit)
  local fresh = Unit.ReadProfessions()
  local changed = not P.Util.shallowEqual(cachedProfs or {}, fresh)
  local first = cachedProfs == nil
  cachedProfs = fresh
  if changed and emit and not first then
    P.Events.Emit('P_PROFS', { profs = P.Util.shallowCopy(fresh) })
  end
  return changed
end

P.Events.Bind('PLAYER_LEVEL_UP', function(_, newLevel)
  local level = tonumber(newLevel)
  if not level then level = call('UnitLevel', 'player') end
  P.Events.ReportPayload('PLAYER_LEVEL_UP', type(level) == 'number', 'new level readable')
  if type(level) == 'number' then
    P.Events.Emit('P_LEVEL', { level = level })
  end
end)

P.Events.Bind('SKILL_LINES_CHANGED', function()
  if not P.IsReady() or debouncePending then return end
  local cancel = P.After(DEBOUNCE_SECONDS, function()
    debouncePending = false
    refreshProfessions(true)
  end)
  if cancel then
    debouncePending = true
  else
    refreshProfessions(true)        -- no timer backend: refresh immediately
  end
end)

P.OnReady(function()
  refreshProfessions(false)         -- prime the cache silently
end)

--- Test helper.
function Unit.Reset()
  cachedProfs = nil
  debouncePending = false
end

P.Player = Unit.Player

---------------------------------------------------------------------------
-- Casts (Phase 3b-1): UNIT_SPELLCAST_SUCCEEDED -> P_CAST
--
-- E-23: the event fires for the player and also target/targettarget/nameplate units; in combat the
-- castGUID and spellID of OTHER units are secret. The first thing the handler does is compare the unit
-- token; every other unit returns at once as 'dropped' without touching a payload. The client is asked
-- for the player's casts only (RegisterUnitEvent) where it supports that; otherwise the same filter is
-- the first line of the handler. Only the four verified gathering spell ids get a kind (E-23); other
-- player casts are 'other' (more ids are added from evidence, never guessed).
---------------------------------------------------------------------------

Unit.CAST_KINDS = { [2366] = 'herb', [2575] = 'mine', [8617] = 'skin', [7731] = 'fish' }
Unit.castStats = { player = 0, secret = 0 }

--- Spell name for an id, or nil (missing API, unknown id, secret value). Never raises.
function Unit.SpellName(id)
  local ok, name = pcall(function()
    local r
    if P.HasIn('C_Spell', 'GetSpellName') then r = P.CallIn('C_Spell', 'GetSpellName', id)
    elseif P.HasIn('C_Spell', 'GetSpellInfo') then
      r = P.CallIn('C_Spell', 'GetSpellInfo', id)
      if r and type(r[1]) == 'table' then return r[1].name end
    end
    return r and r[1] or nil
  end)
  if ok and type(name) == 'string' and not P.IsSecret(name) then return name end
  return nil
end

-- A gathering spell exists once per skill rank with a different id but the SAME name (user evidence 2026-10-21: the
-- apprentice skinning cast 8613 is named "Skinning", like 8617). So any cast whose name equals the name of a verified
-- id (E-23) has that kind. Names are read from the client, never typed in (locale independent).
local nameKind, castKind = nil, {}
local function resolveKind(spellID)
  if castKind[spellID] ~= nil then return castKind[spellID] or nil end
  if not nameKind then
    nameKind = {}
    for id, kind in pairs(Unit.CAST_KINDS) do
      local n = Unit.SpellName(id)
      if n then nameKind[n] = kind end
    end
    if next(nameKind) == nil then nameKind = nil end          -- nothing readable yet: ask again next time
  end
  local kind
  if nameKind then
    local n = Unit.SpellName(spellID)
    kind = n and nameKind[n] or nil
    castKind[spellID] = kind or false
  end
  return kind
end
function Unit.ResetNames() nameKind, castKind = nil, {} end
local lastCast = {}      -- kind -> { gt, spellID }; read-only through Unit.LastCast (activity stamp, 3b-2)

--- Game time and spell id of the player's most recent cast of `kind` ('herb'|'mine'|'skin'|'fish'|'other'), or nil.
function Unit.LastCast(kind)
  local c = lastCast[kind]
  if not c then return nil end
  return c.gt, c.spellID
end
function Unit.ResetCasts() lastCast = {} end
P.LastCast = Unit.LastCast

local function onCast(_, unit, _castGUID, spellID)
  if unit ~= 'player' then return 'dropped' end       -- the unit token is never secret; compared first
  if type(spellID) ~= 'number' or P.IsSecret(spellID) then
    Unit.castStats.secret = Unit.castStats.secret + 1
    return 'dropped'
  end
  Unit.castStats.player = Unit.castStats.player + 1
  local _, gt = P.Now()
  local kind = Unit.CAST_KINDS[spellID] or resolveKind(spellID) or 'other'
  lastCast[kind] = { gt = gt, spellID = spellID }
  P.Events.Emit('P_CAST', { spellID = spellID, kind = kind })
end

Unit.OnCast = onCast

P.RegisterCollectAdapter({
  name = 'Cast',
  handlers = { UNIT_SPELLCAST_SUCCEEDED = onCast },
  unitFilter = { UNIT_SPELLCAST_SUCCEEDED = 'player' },
})
