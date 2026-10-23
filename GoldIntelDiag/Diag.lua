-- GoldIntelDiag: read-only diagnostics for the GoldIntel Phase 1 compatibility investigation.
-- Nothing here changes character data. Commands: /gidiag help
-- Written for Lua 5.1 and tested for syntax on 5.3; uses only ASCII and line comments.
local name, ns = ...
ns = type(ns) == "table" and ns or {}
ns.sources = ns.sources or {}

local TAG = "|cff33ccffGIDiag|r "
local transcript = {}
local compileChunk = loadstring or load

local function emit(text)
  text = tostring(text)
  transcript[#transcript + 1] = text
  print(TAG .. text)
end

local function fmt(...)
  local parts = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if type(v) == "table" then
      local inner = {}
      for k, x in pairs(v) do
        inner[#inner + 1] = tostring(k) .. "=" .. tostring(x)
        if #inner >= 12 then inner[#inner + 1] = "..."; break end
      end
      table.sort(inner)
      parts[#parts + 1] = "{" .. table.concat(inner, ", ") .. "}"
    else
      parts[#parts + 1] = tostring(v)
    end
  end
  return table.concat(parts, " | ")
end

local function try(label, fn, ...)
  local res = { pcall(fn, ...) }
  local ok = table.remove(res, 1)
  if ok then
    emit(label .. " -> " .. fmt((unpack or table.unpack)(res)))
  else
    emit(label .. " -> ERROR: " .. tostring(res[1]))
  end
  return ok
end

local function adler32(s)
  local a, b = 1, 0
  for i = 1, #s do
    a = (a + s:byte(i)) % 65521
    b = (b + a) % 65521
  end
  return string.format("%08x", b * 65536 + a)
end

local function sortedKeys(t, limit)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  if limit and #keys > limit then
    local n = #keys
    for i = n, limit + 1, -1 do keys[i] = nil end
    keys[#keys + 1] = "... (" .. n .. " total)"
  end
  return keys
end

local sections = {}

---------------------------------------------------------------------------
-- LUA: language and runtime characteristics
---------------------------------------------------------------------------
sections.lua = function()
  emit("== LUA language/runtime ==")
  emit("_VERSION = " .. tostring(_VERSION) .. "   jit = " .. type(jit))
  emit("types: loadstring=" .. type(loadstring) .. " load=" .. type(load) .. " setfenv=" .. type(setfenv)
    .. " getfenv=" .. type(getfenv) .. " unpack=" .. type(unpack) .. " table.unpack=" .. type(table.unpack)
    .. " bit=" .. type(bit) .. " math.pow=" .. type(math.pow) .. " string.pack=" .. type(string.pack))
  local cases = {
    { "integer division //", "return 7//2", "error" },
    { "goto / label", "goto a ::a::", "error" },
    { "break before more statements", "for i=1,2 do break print(i) end", "error" },
    { "nested [[ inside a long string", "x=[[a[[b]]c]]", "error" },
    { "bitwise &", "return 1 & 2", "error" },
    { "ambiguous call across lines", "local f,g=print,print\nf()\n(g)()", "error" },
    { "attribute <const>", "local a <const> = 1", "error" },
  }
  local like51 = 0
  for _, c in ipairs(cases) do
    local f, err = compileChunk(c[2])
    local result = f and "compiles" or ("error: " .. tostring(err))
    local isErr = not f
    if (c[3] == "error") == isErr then like51 = like51 + 1 end
    emit(string.format("grammar: %-34s -> %s", c[1], result))
  end
  local f = compileChunk('return #"\\xff"')
  local len = f and f() or "?"
  emit('string escape "\\xff" length = ' .. tostring(len) .. "  (5.1 gives 3, 5.2+ gives 1)")
  if len == 3 then like51 = like51 + 1 end
  local verdict = (like51 == #cases + 1) and "BEHAVES LIKE LUA 5.1 (WoW standard)" or "NOT pure 5.1 grammar"
  emit("verdict: " .. verdict .. " (" .. like51 .. "/" .. (#cases + 1) .. " checks match 5.1)")
  local main = compileChunk("return select('#', ...), ...")
  if main then emit("vararg main chunk: " .. fmt(main("a", "b"))) end
end

---------------------------------------------------------------------------
-- ADDON: loading environment and TOC compatibility
---------------------------------------------------------------------------
sections.addon = function()
  emit("== ADDON loading / TOC ==")
  try("GetBuildInfo()", GetBuildInfo)
  try("interface (TOC) number", function() return (select(4, GetBuildInfo())) end)
  try("GetLocale()", GetLocale)
  emit("type(C_AddOns) = " .. type(C_AddOns) .. "   type(GetAddOnInfo) = " .. type(GetAddOnInfo))
  local info = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
  local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  for _, addon in ipairs({ "GoldIntel", "GoldIntelDiag", "GIMin" }) do
    emit("-- addon: " .. addon)
    if info then try("GetAddOnInfo(" .. addon .. ")", info, addon) end
    if loaded then try("IsAddOnLoaded(" .. addon .. ")", loaded, addon) end
    if meta then
      try("metadata Interface", meta, addon, "Interface")
      try("metadata Version", meta, addon, "Version")
      try("metadata SavedVariables", meta, addon, "SavedVariables")
    end
  end
  local count = (C_AddOns and C_AddOns.GetNumAddOns) or GetNumAddOns
  if count and info then
    local n = count()
    emit("installed addons: " .. tostring(n) .. " (names starting with Gold/GI shown)")
    for i = 1, n do
      local ok, r1 = pcall(info, i)
      local addonName = ok and (type(r1) == "table" and r1.name or r1) or nil
      if type(addonName) == "string" and (addonName:find("^Gold") or addonName:find("^GI")) then
        emit("  [" .. i .. "] " .. fmt(select(2, pcall(info, i))))
      end
    end
  end
  emit("hint: 'reason' of GetAddOnInfo = nil is healthy; INTERFACE_VERSION = incompatible number; CORRUPT/MISSING = TOC or file problem.")
  emit("SavedVariables and file errors: see Logs/FrameXML.log and run '/console scriptErrors 1' then '/reload'.")
end

---------------------------------------------------------------------------
-- API: namespaces and Classic-era globals
---------------------------------------------------------------------------
sections.api = function()
  emit("== API namespaces ==")
  local names = { "C_Map", "C_AuctionHouse", "C_Timer", "C_TradeSkillUI", "C_AddOns", "C_Container",
                  "C_CVar", "C_Item", "C_Spell", "C_UnitAuras", "C_Secrets", "C_ChatInfo", "C_CurrencyInfo" }
  local line = {}
  for _, n in ipairs(names) do line[#line + 1] = n .. "=" .. type(_G[n]) end
  emit(table.concat(line, " "))
  local all = {}
  for k, v in pairs(_G) do
    if type(k) == "string" and k:find("^C_") and type(v) == "table" then all[#all + 1] = k end
  end
  table.sort(all)
  emit("all C_ namespaces (" .. #all .. "): " .. table.concat(all, " "))
  for _, ns2 in ipairs({ "C_Map", "C_AuctionHouse", "C_Timer" }) do
    if type(_G[ns2]) == "table" then
      emit(ns2 .. " functions: " .. table.concat(sortedKeys(_G[ns2], 70), " "))
    end
  end
  emit("== Classic-era globals GoldIntel adapters look for (function = present) ==")
  local legacy = { "GetNumSkillLines", "GetSkillLineInfo", "ExpandSkillHeader", "GetProfessions", "GetProfessionInfo",
    "QueryAuctionItems", "GetAuctionItemInfo", "CalculateAuctionDeposit", "GetTradeSkillInfo", "GetTradeSkillReagentInfo",
    "GetInboxItem", "GetInboxHeaderInfo", "TakeInboxMoney", "GetPlayerTradeMoney", "GetTargetTradeMoney",
    "GetLootSlotInfo", "IsInInstance", "GetInstanceInfo", "IsLoggedIn", "issecretvalue", "SlashCmdList", "LibStub",
    "WorldMapFrame", "AuctionHouseFrame" }
  line = {}
  for _, n in ipairs(legacy) do line[#line + 1] = n .. "=" .. type(_G[n]) end
  emit(table.concat(line, " "))
end

---------------------------------------------------------------------------
-- UNIT: identity, money, time (all read-only)
---------------------------------------------------------------------------
sections.unit = function()
  emit("== UNIT / identity / money / time ==")
  try("UnitGUID('player')", UnitGUID, "player")
  local guid = UnitGUID and UnitGUID("player")
  if type(guid) == "string" then
    emit("GUID parts (type-server-id): " .. fmt(guid:match("^(%a+)%-(%d+)%-(%x+)$")))
  end
  emit("issecretvalue(guid) = " .. tostring(issecretvalue and issecretvalue(guid)))
  try("UnitName", UnitName, "player")
  try("UnitClass (localized, token)", UnitClass, "player")
  try("UnitLevel", UnitLevel, "player")
  try("UnitFactionGroup", UnitFactionGroup, "player")
  try("GetRealmName", GetRealmName)
  try("GetNormalizedRealmName", GetNormalizedRealmName)
  try("GetMoney (copper)", GetMoney)
  emit("issecretvalue(GetMoney()) = " .. tostring(issecretvalue and GetMoney and issecretvalue(GetMoney())))
  try("time(), GetTime()", function() return time(), GetTime() end)
end

---------------------------------------------------------------------------
-- MAP
---------------------------------------------------------------------------
sections.map = function()
  emit("== MAP / zones ==")
  if type(C_Map) ~= "table" then emit("C_Map is " .. type(C_Map) .. " (GoldIntel falls back to zone text, heatmap disabled)") end
  if type(C_Map) == "table" then
    try("C_Map.GetBestMapForUnit('player')", C_Map.GetBestMapForUnit, "player")
    local id = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if id and C_Map.GetPlayerMapPosition then
      try("GetPlayerMapPosition x,y", function()
        local p = C_Map.GetPlayerMapPosition(id, "player")
        if p and p.GetXY then return p:GetXY() end
        return "no position object", type(p)
      end)
    end
    if id and C_Map.GetMapInfo then try("C_Map.GetMapInfo(id)", C_Map.GetMapInfo, id) end
  end
  try("GetZoneText / GetSubZoneText", function() return GetZoneText(), GetSubZoneText() end)
  emit("WorldMapFrame=" .. type(WorldMapFrame) .. " ScrollContainer=" .. type(WorldMapFrame and WorldMapFrame.ScrollContainer))
end

---------------------------------------------------------------------------
-- EVENTS
---------------------------------------------------------------------------
local EVENT_GROUPS = {
  lifecycle = { "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "PLAYER_LOGOUT", "ADDON_LOADED" },
  money = { "PLAYER_MONEY" },
  combat = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "COMBAT_LOG_EVENT_UNFILTERED", "UNIT_SPELLCAST_SUCCEEDED" },
  zone = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" },
  character = { "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED" },
  loot = { "LOOT_OPENED", "LOOT_SLOT_CLEARED", "CHAT_MSG_MONEY" },
  vendor = { "MERCHANT_SHOW", "MERCHANT_CLOSED", "QUEST_TURNED_IN" },
  mail = { "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE" },
  trade = { "TRADE_SHOW", "TRADE_CLOSED", "TRADE_MONEY_CHANGED", "TRADE_ACCEPT_UPDATE" },
  auction = { "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" },
}
sections.events = function()
  emit("== EVENT names (C_EventUtils.IsEventValid). NOTHING is registered here. ==")
  local utils = C_EventUtils
  if type(utils) ~= "table" or type(utils.IsEventValid) ~= "function" then
    emit("C_EventUtils.IsEventValid is unavailable: names cannot be checked without registering them.")
    emit("Use '/gidiag reg EVENT_NAME' for one event at a time (see its warning).")
    return
  end
  for _, g in ipairs(sortedKeys(EVENT_GROUPS)) do
    local ok, bad = 0, {}
    for _, e in ipairs(EVENT_GROUPS[g]) do
      local good, valid = pcall(utils.IsEventValid, e)
      if good and valid then ok = ok + 1 else bad[#bad + 1] = e end
    end
    emit(g .. ": valid=" .. ok .. (#bad > 0 and ("  NOT VALID: " .. table.concat(bad, ", ")) or "  all valid"))
  end
  local good, valid = pcall(utils.IsEventValid, "GIDIAG_NOT_A_REAL_EVENT")
  emit("sanity: IsEventValid('GIDIAG_NOT_A_REAL_EVENT') = " .. tostring(good and valid) .. " (expect false)")
  emit("A VALID NAME does not prove registration is ALLOWED. COMBAT_LOG_EVENT_UNFILTERED is restricted for addons in some clients.")
  emit("To test whether one event may be registered: /gidiag reg EVENT_NAME")
end

---------------------------------------------------------------------------
-- REG: opt-in test of registering ONE event (may show a blocked-action popup)
---------------------------------------------------------------------------
local function regTest(eventName)
  if not eventName or eventName == "" then
    emit("usage: /gidiag reg EVENT_NAME   (example: /gidiag reg PLAYER_MONEY)")
    return
  end
  emit("WARNING: about to call RegisterEvent(\"" .. eventName .. "\"). If an ADDON_ACTION_FORBIDDEN / blocked-action popup appears")
  emit("right now, that event is RESTRICTED for addons. Report the name. Nothing is changed on your character.")
  local watcher = CreateFrame("Frame")
  local watching = pcall(watcher.RegisterEvent, watcher, "ADDON_ACTION_FORBIDDEN")
  watcher:SetScript("OnEvent", function(_, event, addon, func)
    emit("ADDON_ACTION_FORBIDDEN fired: addon=" .. tostring(addon) .. " function=" .. tostring(func))
  end)
  local f = CreateFrame("Frame")
  local ok, err = pcall(f.RegisterEvent, f, eventName)
  emit("watching for ADDON_ACTION_FORBIDDEN: " .. tostring(watching))
  emit("RegisterEvent call: " .. (ok and "returned normally" or ("raised an error: " .. tostring(err))))
  local registered = f.IsEventRegistered and f:IsEventRegistered(eventName)
  emit("IsEventRegistered afterwards: " .. tostring(registered) .. "  (false after a 'normal' return means the client blocked it)")
  pcall(f.UnregisterEvent, f, eventName)
  pcall(watcher.UnregisterEvent, watcher, "ADDON_ACTION_FORBIDDEN")
end

---------------------------------------------------------------------------
-- TIMER
---------------------------------------------------------------------------
sections.timer = function()
  emit("== TIMER ==")
  if type(C_Timer) ~= "table" then emit("C_Timer is " .. type(C_Timer) .. " (GoldIntel uses its OnUpdate fallback)"); return end
  emit("NewTicker=" .. type(C_Timer.NewTicker) .. " NewTimer=" .. type(C_Timer.NewTimer) .. " After=" .. type(C_Timer.After))
  local t0 = GetTime()
  C_Timer.After(1, function() emit(string.format("C_Timer.After fired after %.2f s (asked 1.00)", GetTime() - t0)) end)
  local n, ticker = 0, nil
  ticker = C_Timer.NewTicker(0.5, function()
    n = n + 1
    emit(string.format("ticker tick %d at %.2f s", n, GetTime() - t0))
    if n == 3 then ticker:Cancel(); emit("ticker cancelled; no further ticks expected") end
  end)
  emit("scheduled: expect 3 ticks (0.5 s apart) and one After (1 s); results print below.")
end

---------------------------------------------------------------------------
-- SLASH
---------------------------------------------------------------------------
sections.slash = function()
  emit("== SLASH commands ==")
  emit("SlashCmdList=" .. type(SlashCmdList) .. "  /gidiag registered=" .. tostring(SlashCmdList and SlashCmdList.GIDIAG ~= nil))
  SLASH_GIDIAGTEST1 = "/gidiagtest"
  SlashCmdList.GIDIAGTEST = function(msg) emit("/gidiagtest works (runtime registration). argument: " .. tostring(msg)) end
  emit("registered /gidiagtest at runtime: now type  /gidiagtest hello  (expect a line saying it works)")
  emit("/gi registered by GoldIntel: " .. tostring(SlashCmdList and SlashCmdList.GOLDINTEL ~= nil))
end

---------------------------------------------------------------------------
-- SV: saved variables
---------------------------------------------------------------------------
sections.sv = function()
  emit("== SAVED VARIABLES ==")
  local db = GoldIntelDiagDB
  emit("GoldIntelDiagDB type = " .. type(db) .. "   loads (persisted across /reload) = " .. tostring(db and db.loads))
  emit("GoldIntelDB (GoldIntel) = " .. type(GoldIntelDB) .. "   GoldIntelCharDB = " .. type(GoldIntelCharDB))
  emit("to prove persistence: '/reload' and run '/gidiag sv' again; loads must increase by 1.")
end

---------------------------------------------------------------------------
-- COMPILE: let the real client compile the embedded GoldIntel sources
---------------------------------------------------------------------------
sections.compile = function()
  emit("== COMPILE embedded GoldIntel sources with the client's own Lua compiler ==")
  emit("compiler function in use: " .. (loadstring and "loadstring" or "load"))
  local control, cerr = compileChunk("return 1")
  emit("control chunk 'return 1' -> " .. (control and "ok" or tostring(cerr)))
  local anyFail = false
  for _, set in ipairs({ "current" }) do
    local files = ns.sources[set]
    if not files then
      emit(set .. ": sources not loaded (SrcCurrent.lua missing?)")
    else
      emit("-- GoldIntel " .. tostring(ns.sources.version) .. " (all files, TOC order)")
      for _, file in ipairs(files) do
        local f, err = compileChunk(file.src, "=" .. file.path)
        if f then
          emit(string.format("  OK    %-24s %6d bytes  adler32 %s", file.path, #file.src, adler32(file.src)))
        else
          anyFail = true
          emit(string.format("  FAIL  %-24s %6d bytes  adler32 %s", file.path, #file.src, adler32(file.src)))
          emit("        " .. tostring(err))
        end
      end
    end
  end
  emit(anyFail and "RESULT: at least one source FAILED to compile in this client (message above is the real cause)."
    or "RESULT: every embedded source compiles in this client. A load failure of the same files on disk is then NOT a syntax problem: check paths, folder layout, file integrity (compare size/adler32 with MANIFEST.txt) and TOC.")
end

---------------------------------------------------------------------------
-- RUN: execute the current GoldIntel sources in a sandbox and print its own report
---------------------------------------------------------------------------
sections.run = function()
  emit("== RUN GoldIntel " .. tostring(ns.sources.version) .. " inside a sandbox (private globals; your real saved data and /gi are not touched) ==")
  local files = ns.sources.current
  if not files then emit("sources missing"); return end
  -- Private copies of every global the addon writes: saved variables and slash commands.
  local sandbox = setmetatable({}, { __index = _G })
  sandbox._G = sandbox
  sandbox.GoldIntelDB = {}
  sandbox.GoldIntelCharDB = {}
  sandbox.SlashCmdList = {}
  local shared = { Platform = { env = sandbox } }
  for _, file in ipairs(files) do
    local f, err = compileChunk(file.src, "=" .. file.path)
    if not f then emit("compile FAIL " .. file.path .. ": " .. tostring(err)); return end
    local ok, runErr = xpcall(function() return f("GoldIntel", shared) end, function(e) return tostring(e) .. "\n" .. (debugstack and debugstack(2, 6, 0) or "") end)
    if not ok then emit("RUNTIME ERROR in " .. file.path .. ": " .. tostring(runErr)); return end
  end
  emit("ran " .. #files .. " files")
  local P = shared.Platform
  if P and P.ProbeModule then
    emit("platform: operational = " .. tostring(P.operational) .. "   ready = " .. tostring(P.IsReady and P.IsReady()))
    for _, line in ipairs(P.ProbeModule.Report()) do emit(line) end
  end
  local Core, Store, Caps = shared.Core, shared.Store, shared.Capabilities
  if Core then
    local d = Core.Describe()
    emit("core: state=" .. d.state .. " modules=" .. d.total .. " enabled=" .. d.enabled .. " failed=" .. d.failed .. " stubs=" .. d.stub)
  end
  if Store and Store.IsOpen() then
    local s = Store.Status()
    emit("store: state=" .. s.state .. " schema=" .. tostring(s.schema) .. " writable=" .. tostring(s.writable)
      .. " size~" .. tostring(Store.EstimateBytes(Store.Get())) .. " bytes")
  end
  if Caps then
    local sum = Caps.Summary()
    local parts = {}
    for level, n in pairs(sum.event) do parts[#parts + 1] = level .. "=" .. n end
    table.sort(parts)
    emit("event capability levels: " .. table.concat(parts, " "))
    for _, name in ipairs(Caps.Names("event")) do
      local rec = Caps.Get(name)
      emit("  " .. name .. " [" .. rec.level .. "] valid=" .. tostring(rec.stages.valid) .. " registered=" .. tostring(rec.stages.registered)
        .. " delivered=" .. tostring(rec.stages.delivered) .. " payloadUsable=" .. tostring(rec.stages.payloadUsable))
    end
  end
  local diag = P and P.GetDiag and P.GetDiag() or {}
  emit("GoldIntel diagnostics: " .. #diag)
  for _, d in ipairs(diag) do emit("  " .. d.level .. " [" .. d.module .. "] " .. d.msg) end
end

---------------------------------------------------------------------------
-- Copy window and command dispatch
---------------------------------------------------------------------------
local window
local function showWindow()
  local text = table.concat(transcript, "\n")
  local ok, err = pcall(function()
    if not window then
      window = CreateFrame("Frame", "GoldIntelDiagWindow", UIParent, "BasicFrameTemplateWithInset")
      window:SetSize(660, 440)
      window:SetPoint("CENTER")
      window:SetFrameStrata("DIALOG")
      window:EnableMouse(true)
      window:SetMovable(true)
      window:RegisterForDrag("LeftButton")
      window:SetScript("OnDragStart", window.StartMoving)
      window:SetScript("OnDragStop", window.StopMovingOrSizing)
      local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
      scroll:SetPoint("TOPLEFT", 12, -32)
      scroll:SetPoint("BOTTOMRIGHT", -32, 12)
      local edit = CreateFrame("EditBox", nil, scroll)
      edit:SetMultiLine(true)
      edit:SetFontObject(ChatFontNormal)
      edit:SetWidth(600)
      edit:SetAutoFocus(false)
      edit:SetScript("OnEscapePressed", function() window:Hide() end)
      scroll:SetScrollChild(edit)
      window.edit = edit
    end
    window.edit:SetText(text)
    window:Show()
    window.edit:HighlightText()
    window.edit:SetFocus()
  end)
  if not ok then emit("copy window unavailable: " .. tostring(err) .. "  (use the SavedVariables file instead)") end
end

local ORDER = { "lua", "addon", "api", "unit", "map", "events", "timer", "slash", "sv", "compile" }
local function runSection(key)
  local ok, err = pcall(sections[key])
  if not ok then emit("section '" .. key .. "' crashed: " .. tostring(err)) end
end

local function save()
  GoldIntelDiagDB = GoldIntelDiagDB or { loads = 0 }
  GoldIntelDiagDB.transcript = table.concat(transcript, "\n")
end

ns.emit = emit

SLASH_GIDIAG1 = "/gidiag"
SlashCmdList.GIDIAG = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)") or ""
  if cmd == "lab" then
    local rest = (msg or ""):match("^%S+%s*(.*)$") or ""
    if ns.Lab and ns.Lab.Command then
      local ok, err = pcall(ns.Lab.Command, rest)
      if not ok then emit("lab crashed: " .. tostring(err)) end
    else
      emit("lab is not loaded (Lab.lua missing from the TOC)")
    end
    save()
    return
  end
  if cmd == "reg" then
    regTest((msg or ""):match("^%S+%s+(%S+)"))
    save()
    return
  end
  if cmd == "all" then
    for _, key in ipairs(ORDER) do runSection(key) end
  elseif cmd == "copy" then
    showWindow()
    return
  elseif cmd == "clear" then
    transcript = {}
    emit("transcript cleared")
  elseif sections[cmd] then
    runSection(cmd)
  else
    emit("commands: /gidiag all | lua | addon | api | unit | map | events | timer | slash | sv | compile | run | reg EVENT | lab ... | copy | clear")
    emit("Phase 3a lab: /gidiag lab help")
    emit("start with:  /gidiag compile   then   /gidiag all   then   /gidiag copy  (ctrl+A, ctrl+C to copy the results)")
  end
  save()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, addon)
  if addon ~= name then return end
  GoldIntelDiagDB = GoldIntelDiagDB or { loads = 0 }
  GoldIntelDiagDB.loads = (GoldIntelDiagDB.loads or 0) + 1
  GoldIntelDiagDB.lastLoad = time()
  frame:UnregisterEvent("ADDON_LOADED")
  emit("loaded. Type /gidiag for commands. (load count " .. GoldIntelDiagDB.loads .. ")")
end)
