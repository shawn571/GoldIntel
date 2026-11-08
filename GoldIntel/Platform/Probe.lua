-- GoldIntel / Platform / Probe.lua                                      (Phase 1, task 1.3)
--
-- PURPOSE
--  Discovers which WoW API features exist in the running client (Decisions D-016) and
--  produces a copy-pasteable report. This is how open item OI-1 gets answered: nobody
--  has published the WoW Forever addon API, so GoldIntel measures instead of assuming.
--
--  Platform.Probe() -> { [capability] = boolean }                       (Contracts.md F2)
--
-- WHAT IT DOES
--  1. Runs every probe in PROBES (function/table presence, event NAME validity, libraries).
--  2. Stores results in the capability registry (P.SetCap) and, at PLAYER_LOGIN, persists
--     build info + capabilities + report lines to GoldIntelDB.compat for later reading
--     from the SavedVariables file.
--  3. Evaluates the fatal capabilities (P.CheckFatal).
--  (The temporary /gi handler that lived here moved to Core/Slash.lua in Phase 2, D-022 item 5.)
--
-- PROBES NEVER REGISTER EVENTS (Decisions D-025). Event names are checked with
-- C_EventUtils.IsEventValid; restricted events are reported [unknown] and never touched.
-- A probe has no side effects beyond creating one throwaway frame.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Probe.lua')

local Probe = {}
P.ProbeModule = Probe
P.Register('Probe', Probe)

Probe.last = nil   -- result of the most recent Run()

---------------------------------------------------------------------------
-- Probe building blocks
---------------------------------------------------------------------------

local function missingFunctions(names)
  local missing = {}
  for i = 1, #names do
    if P.fn(names[i]) == nil then missing[#missing + 1] = names[i] end
  end
  return missing
end

local function missingMembers(tableName, names)
  local t = P.env[tableName]
  if type(t) ~= 'table' then return { tableName .. ' (table missing)' } end
  local missing = {}
  for i = 1, #names do
    if type(t[names[i]]) ~= 'function' then missing[#missing + 1] = tableName .. '.' .. names[i] end
  end
  return missing
end

local function noteFor(missing)
  if #missing == 0 then return nil end
  return 'missing: ' .. table.concat(missing, ', ')
end

local function fnProbe(names)
  return function()
    local m = missingFunctions(names)
    return #m == 0, noteFor(m)
  end
end

local function memberProbe(tableName, names)
  return function()
    local m = missingMembers(tableName, names)
    return #m == 0, noteFor(m)
  end
end

-- Event NAMES are checked without registering them (Decisions D-025). Registering a
-- restricted event is blocked by the client (ADDON_ACTION_FORBIDDEN popup) and pcall cannot
-- suppress that, so probing by registration is not allowed. Returns true, false, or nil
-- (nil = cannot tell: restricted event, or the client has no C_EventUtils.IsEventValid).
local function eventProbe(events)
  return function()
    local invalid, restricted, unknown = {}, {}, 0
    for i = 1, #events do
      local ev = events[i]
      if P.RESTRICTED_EVENTS[ev] then
        restricted[#restricted + 1] = ev
      else
        local valid = P.EventNameValid(ev)
        if valid == nil then
          unknown = unknown + 1
        elseif valid == false then
          invalid[#invalid + 1] = ev
        end
      end
    end
    if #invalid > 0 then return false, 'invalid event names: ' .. table.concat(invalid, ', ') end
    if #restricted > 0 then
      return nil, 'restricted, never registered by GoldIntel: ' .. table.concat(restricted, ', ')
    end
    if unknown > 0 then
      return nil, 'not verified (C_EventUtils.IsEventValid unavailable); nothing was registered'
    end
    return true
  end
end

local function libProbe(libName)
  return function()
    local libstub = P.env.LibStub
    if type(libstub) ~= 'table' and type(libstub) ~= 'function' then return false, 'LibStub not present' end
    local ok, lib = pcall(function() return libstub(libName, true) end)
    if ok and lib then return true end
    return false, libName .. ' not loaded'
  end
end

---------------------------------------------------------------------------
-- Probe table (Architecture section 11.3)
---------------------------------------------------------------------------

local PROBES = {
  -- Frames and timers
  { cap = 'frame',                fn = function(ctx) return ctx.frame ~= nil, ctx.frameErr end },
  { cap = 'timer.ctimer',         fn = memberProbe('C_Timer', { 'NewTicker', 'After' }) },
  -- Identity
  { cap = 'identity.guid',        fn = function()
      local f = P.fn('UnitGUID')
      if not f then return false, 'UnitGUID missing' end
      local ok, v = pcall(f, 'player')
      return ok and type(v) == 'string' and v ~= '', 'UnitGUID("player") returned ' .. tostring(v)
    end },
  { cap = 'identity.name',        fn = fnProbe({ 'UnitName', 'UnitClass', 'UnitLevel', 'UnitFactionGroup' }) },
  -- Money (fatal group). 'money.event' is set by Money.lua from its real registration.
  { cap = 'money.get',            fn = function()
      local f = P.fn('GetMoney')
      if not f then return false, 'GetMoney missing' end
      local ok, v = pcall(f)
      return ok and type(v) == 'number', 'GetMoney returned ' .. tostring(v)
    end },
  -- Lifecycle / combat / levels
  { cap = 'lifecycle.events',     fn = eventProbe({ 'PLAYER_LOGIN', 'PLAYER_ENTERING_WORLD', 'PLAYER_LEAVING_WORLD', 'PLAYER_LOGOUT' }) },
  { cap = 'combat.events',        fn = eventProbe({ 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED' }) },
  { cap = 'level.events',         fn = eventProbe({ 'PLAYER_LEVEL_UP', 'SKILL_LINES_CHANGED' }) },
  { cap = 'spell.events',         fn = eventProbe({ 'UNIT_SPELLCAST_SUCCEEDED' }) },
  { cap = 'combatlog.event',      fn = eventProbe({ 'COMBAT_LOG_EVENT_UNFILTERED' }) },
  -- Professions
  { cap = 'prof.getprofessions',  fn = fnProbe({ 'GetProfessions', 'GetProfessionInfo' }) },
  -- Map and zones
  { cap = 'map.cmap',             fn = memberProbe('C_Map', { 'GetBestMapForUnit', 'GetPlayerMapPosition', 'GetMapInfo' }) },
  { cap = 'map.worldframe',       fn = function()
      return type(P.env.WorldMapFrame) == 'table', 'WorldMapFrame is ' .. type(P.env.WorldMapFrame)
    end },
  { cap = 'zone.text',            fn = fnProbe({ 'GetZoneText', 'GetSubZoneText' }) },
  { cap = 'zone.events',          fn = eventProbe({ 'ZONE_CHANGED', 'ZONE_CHANGED_INDOORS', 'ZONE_CHANGED_NEW_AREA' }) },
  { cap = 'instance.api',         fn = fnProbe({ 'IsInInstance', 'GetInstanceInfo' }) },
  -- Loot, vendor, quest
  { cap = 'loot.events',          fn = eventProbe({ 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'CHAT_MSG_MONEY' }) },
  { cap = 'loot.slotinfo',        fn = fnProbe({ 'GetLootSlotInfo' }) },
  { cap = 'merchant.events',      fn = eventProbe({ 'MERCHANT_SHOW', 'MERCHANT_CLOSED' }) },
  { cap = 'quest.event',          fn = eventProbe({ 'QUEST_TURNED_IN' }) },
  { cap = 'map.worldsize',        fn = memberProbe('C_Map', { 'GetMapWorldSize' }) },   -- 0.6.0 (P4-M2): soft-travel distance
  { cap = 'perf.profiler',        fn = memberProbe('C_AddOnProfiler', { 'GetAddOnMetric' }) },   -- 0.5.4 (M4, D-097)
  { cap = 'trainer.events',       fn = eventProbe({ 'TRAINER_SHOW', 'TRAINER_CLOSED' }) },   -- 0.5.2 (D-093)
  -- Mail and trade
  { cap = 'mail.events',          fn = eventProbe({ 'MAIL_SHOW', 'MAIL_CLOSED', 'MAIL_INBOX_UPDATE' }) },
  { cap = 'mail.api',             fn = fnProbe({ 'GetInboxItem', 'GetInboxHeaderInfo', 'TakeInboxMoney' }) },
  { cap = 'trade.events',         fn = eventProbe({ 'TRADE_SHOW', 'TRADE_CLOSED', 'TRADE_MONEY_CHANGED', 'TRADE_ACCEPT_UPDATE' }) },
  { cap = 'trade.api',            fn = fnProbe({ 'GetPlayerTradeMoney', 'GetTargetTradeMoney' }) },
  -- Auction house
  { cap = 'auction.events',       fn = eventProbe({ 'AUCTION_HOUSE_SHOW', 'AUCTION_HOUSE_CLOSED' }) },
  { cap = 'auction.modern',       fn = function()
      return type(P.env.C_AuctionHouse) == 'table', 'C_AuctionHouse is ' .. type(P.env.C_AuctionHouse)
    end },
  -- Trade skills
  { cap = 'tradeskill.modern',    fn = function()
      return type(P.env.C_TradeSkillUI) == 'table', 'C_TradeSkillUI is ' .. type(P.env.C_TradeSkillUI)
    end },
  -- Slash commands and optional libraries (Decisions D-021)
  { cap = 'slash',                fn = function()
      return type(P.env.SlashCmdList) == 'table', 'SlashCmdList is ' .. type(P.env.SlashCmdList)
    end },
  { cap = 'lib.libstub',          fn = function()
      local l = P.env.LibStub
      return type(l) == 'table' or type(l) == 'function', 'LibStub is ' .. type(l)
    end },
  { cap = 'lib.hbd',              fn = libProbe('HereBeDragons-2.0') },
  { cap = 'lib.aceaddon',         fn = libProbe('AceAddon-3.0') },
  { cap = 'lib.acedb',            fn = libProbe('AceDB-3.0') },
  { cap = 'lib.aceconfig',        fn = libProbe('AceConfig-3.0') },
  { cap = 'lib.acegui',           fn = libProbe('AceGUI-3.0') },
}
Probe.PROBES = PROBES

---------------------------------------------------------------------------
-- Run / report / persist
---------------------------------------------------------------------------

local function buildInfo()
  local info = { locale = nil, gameVersion = nil, build = nil, buildDate = nil, interface = nil, projectID = nil }
  local f = P.fn('GetBuildInfo')
  if f then
    local ok, version, build, buildDate, toc = pcall(f)
    if ok then
      info.gameVersion, info.build, info.buildDate, info.interface = version, build, buildDate, toc
    end
  end
  local loc = P.fn('GetLocale')
  if loc then
    local ok, v = pcall(loc)
    if ok then info.locale = v end
  end
  info.projectID = P.env.WOW_PROJECT_ID
  return info
end

--- Runs all probes. Returns { [cap] = boolean } (a copy). Safe to call repeatedly.
function Probe.Run()
  local ctx = {}
  local create = P.fn('CreateFrame')
  if create then
    local ok, f = pcall(create, 'Frame')
    if ok and f then ctx.frame = f else ctx.frameErr = 'CreateFrame failed: ' .. tostring(f) end
  else
    ctx.frameErr = 'CreateFrame missing'
  end

  local notes, status = {}, {}
  for i = 1, #PROBES do
    local probe = PROBES[i]
    local ok, result, note = pcall(probe.fn, ctx)
    if not ok then
      P.SetCap(probe.cap, false, 'probe error: ' .. tostring(result))
      notes[probe.cap] = 'probe error: ' .. tostring(result)
      status[probe.cap] = 'missing'
    elseif result == nil then
      -- unknown: cannot be determined safely; the capability stays unset (Has = false)
      notes[probe.cap] = note
      status[probe.cap] = 'unknown'
    else
      P.SetCap(probe.cap, result and true or false, note)
      status[probe.cap] = result and 'ok' or 'missing'
      if not result then notes[probe.cap] = note end
    end
  end

  Probe.last = { info = buildInfo(), caps = P.Capabilities(), notes = notes, status = status }
  return P.Capabilities()
end

--- Builds the pasteable report (array of plain-ASCII lines) from the last run.
function Probe.Report()
  if not Probe.last then Probe.Run() end
  local info = Probe.last.info
  local lines = {}
  local function add(s) lines[#lines + 1] = s end

  add('GoldIntel probe report  (addon ' .. P.VERSION .. ', contract ' .. P.CONTRACT_VERSION .. ')')
  add('game version: ' .. tostring(info.gameVersion) .. '  build: ' .. tostring(info.build)
      .. '  date: ' .. tostring(info.buildDate))
  add('interface (toc): ' .. tostring(info.interface) .. '  locale: ' .. tostring(info.locale)
      .. '  WOW_PROJECT_ID: ' .. tostring(info.projectID))
  add('operational: ' .. (P.operational and 'yes' or ('NO - ' .. tostring(P.fatalReason))))
  add('scheduler backend: ' .. tostring(P.Scheduler and P.Scheduler.Backend() or 'none'))

  local caps = Probe.last.caps
  local names, seen = {}, {}
  for cap in pairs(caps) do
    if cap:sub(1, 6) ~= 'event.' then names[#names + 1] = cap; seen[cap] = true end
  end
  for cap in pairs(Probe.last.status) do
    if not seen[cap] then names[#names + 1] = cap end
  end
  table.sort(names)
  local failedEvents = {}
  for _, cap in ipairs(P.Util.sortedKeys(caps)) do
    if cap:sub(1, 6) == 'event.' and not caps[cap] then failedEvents[#failedEvents + 1] = cap:sub(7) end
  end
  add('--- capabilities ([unknown] = could not be checked safely) ---')
  for _, cap in ipairs(names) do
    local st = Probe.last.status[cap] or (caps[cap] and 'ok' or 'missing')
    local tag = (st == 'ok' and '[ok]      ') or (st == 'unknown' and '[unknown] ') or '[MISSING] '
    local note = Probe.last.notes[cap]
    add(tag .. cap .. ((st ~= 'ok' and note) and ('   ' .. note) or ''))
  end
  add('--- events GoldIntel tried to register and could not ---')
  add(#failedEvents == 0 and '(none)' or table.concat(failedEvents, ', '))
  return lines
end

--- Writes build info, capabilities and the report into GoldIntelDB.compat.
-- Store (Phase 2) must preserve this table (Decisions D-022 item 6).
function Probe.Persist()
  if not Probe.last then return nil, 'no probe result' end
  local db = P.env.GoldIntelDB
  if db == nil then
    db = {}
    P.env.GoldIntelDB = db
  elseif type(db) ~= 'table' then
    P.Diag('warn', 'Probe', 'GoldIntelDB is not a table; replacing it')
    db = {}
    P.env.GoldIntelDB = db
  end
  local info = Probe.last.info
  local t = P.Now()
  db.compat = {
    build = info.build,
    gameVersion = info.gameVersion,
    interface = info.interface,
    locale = info.locale,
    projectID = info.projectID,
    addonVersion = P.VERSION,
    probedAt = t,
    operational = P.operational,
    caps = P.Util.shallowCopy(Probe.last.caps),
    status = P.Util.shallowCopy(Probe.last.status),
    report = Probe.Report(),
  }
  return true
end

-- Contract: Platform.Probe() -> { [cap] = boolean }
P.Probe = function() return Probe.Run() end

---------------------------------------------------------------------------
-- Startup: runs last, after every module registered its OnReady listener
---------------------------------------------------------------------------

P.OnReady(function()
  local db = P.env.GoldIntelDB
  local previousBuild = type(db) == 'table' and type(db.compat) == 'table' and db.compat.build or nil
  Probe.Run()
  P.CheckFatal()
  Probe.Persist()
  if P.operational and previousBuild ~= Probe.last.info.build then
    P.Print('platform probe saved for client build ' .. tostring(Probe.last.info.build)
      .. '. Type /gi probe to view the report.')
  end
end)

P.Events.CheckLateLoad()
