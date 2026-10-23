-- GoldIntel / Platform / Map.lua                                        (Phase 1, task 1.4)
--
-- PURPOSE
--  Player location and the events built on it.
--      Platform.Where() -> Loc | nil
--        Loc = { mapID?, zone?, sub?, locale?, x?, y? }      (Contracts.md F1, v1.1)
--  Emits P_ZONE when (mapID, zone, subzone) changes and P_TICK every TICK_SECONDS.
--
-- DEGRADATION (Architecture section 11.3)
--  * No C_Map            -> mapID/x/y are nil; zone and subzone text still identify the place
--                           (rankings keep working, heatmap cannot).
--  * No map position     -> x/y are nil (typical inside instances). A reading of exactly
--                           (0, 0) is treated as "unavailable" because older APIs return it
--                           instead of nil.
--  * No zone text either -> Where() returns nil, 'no location data'.
--
-- SUBZONE IDENTITY (Decisions D-008)
--  `sub` is the localized subzone text and `locale` records the client language so
--  rankings never merge across locales.
--
-- HereBeDragons is not used here; world coordinates arrive with the (deferred) world
-- heatmap and will be guarded by Has('lib.hbd') (Decisions D-021).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Map.lua')

local Map = {}
P.Map = Map
P.Register('Map', Map)

local TICK_SECONDS = 0.5
local MAX_TICK_DT = 5          -- clamp: a stalled client must not credit minutes to one cell
Map.TICK_SECONDS = TICK_SECONDS
Map.MAX_TICK_DT = MAX_TICK_DT

local lastSignature = nil
local lastTickGT = nil
local cancelTicker = nil

local function text(name)
  local f = P.fn(name)
  if not f then return nil end
  local ok, v = pcall(f)
  if ok and not P.IsSecret(v) and type(v) == 'string' and v ~= '' then return v end
  return nil
end

local function readMapID()
  local cm = P.env.C_Map
  if type(cm) ~= 'table' or type(cm.GetBestMapForUnit) ~= 'function' then return nil end
  local ok, id = pcall(cm.GetBestMapForUnit, 'player')
  if ok and not P.IsSecret(id) and type(id) == 'number' then return id end
  return nil
end

local function readPosition(mapID)
  local cm = P.env.C_Map
  if not mapID or type(cm) ~= 'table' or type(cm.GetPlayerMapPosition) ~= 'function' then
    return nil, nil
  end
  local ok, pos = pcall(cm.GetPlayerMapPosition, mapID, 'player')
  if not ok or pos == nil then return nil, nil end
  local x, y
  if type(pos) == 'table' and type(pos.GetXY) == 'function' then
    local okXY, px, py = pcall(pos.GetXY, pos)
    if okXY then x, y = px, py end
  end
  if P.IsSecret(x) or P.IsSecret(y) then return nil, nil end
  if type(x) ~= 'number' or type(y) ~= 'number' then return nil, nil end
  if x ~= x or y ~= y then return nil, nil end                -- NaN
  if x < 0 or x > 1 or y < 0 or y > 1 then return nil, nil end
  if x == 0 and y == 0 then return nil, nil end
  return x, y
end

--- Platform.Where(). Returns a Loc table, or nil plus a reason.
function Map.Where()
  local mapID = readMapID()
  local x, y = readPosition(mapID)
  local zone = text('GetZoneText')
  local sub = text('GetSubZoneText')
  if not mapID and not zone then return nil, 'no location data' end
  return {
    mapID = mapID,
    zone = zone,
    sub = sub,
    locale = text('GetLocale'),
    x = x,
    y = y,
  }
end

local function signature(loc)
  return tostring(loc.mapID) .. '|' .. tostring(loc.zone) .. '|' .. tostring(loc.sub)
end

--- Emits P_ZONE if the place changed since the last check. Returns the Loc (or nil).
function Map.Check()
  if not P.InWorld() then return nil end
  local loc = Map.Where()
  if not loc then return nil end
  local sig = signature(loc)
  if sig ~= lastSignature then
    lastSignature = sig
    P.Events.Emit('P_ZONE', { loc = loc })
  end
  return loc
end

--- One 0.5 s step: detect zone changes and emit P_TICK. Exposed for tests.
function Map.OnTick()
  if not P.InWorld() then
    lastTickGT = nil               -- do not credit time spent in loading screens
    return
  end
  local _, gt = P.Now()
  local dt = TICK_SECONDS
  if lastTickGT then
    dt = gt - lastTickGT
    if dt < 0 then dt = 0 end
    if dt > MAX_TICK_DT then dt = MAX_TICK_DT end
  end
  lastTickGT = gt
  local loc = Map.Check()
  P.Events.Emit('P_TICK', { loc = loc, dt = dt })
end

local function onZoneEvent()
  Map.Check()
end

P.Events.Bind('ZONE_CHANGED', onZoneEvent)
P.Events.Bind('ZONE_CHANGED_INDOORS', onZoneEvent)
P.Events.Bind('ZONE_CHANGED_NEW_AREA', onZoneEvent)
P.Events.Bind('PLAYER_ENTERING_WORLD', function()
  lastTickGT = nil
  onZoneEvent()
end)

P.OnReady(function()
  local cancel, err = P.Every(TICK_SECONDS, Map.OnTick)
  if cancel then
    cancelTicker = cancel
  else
    P.Diag('error', 'Map', 'cannot start tick: ' .. tostring(err))
  end
end)

--- Stops the ticker and forgets state (tests, reloads).
function Map.Reset()
  if cancelTicker then cancelTicker() end
  cancelTicker = nil
  lastSignature = nil
  lastTickGT = nil
end

P.Where = Map.Where
