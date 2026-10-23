-- GoldIntelDiag / Lab.lua
-- Phase 3a signal verification lab (Decision D-051; protocol: GoldIntel_Docs/Phase3a_Verification_Protocol.md).
--
-- READ-ONLY EXPERIMENTS. This file contains NO collector, ledger, valuation, activity or session
-- logic. It never reads or writes GoldIntelDB. Results go to GoldIntelDiagDB.lab and stay bounded.
-- Safety rules (protocol section 2): one NEW event registration per game session; registration only
-- through this opt-in path with an ADDON_ACTION_FORBIDDEN watcher; COMBAT_LOG_EVENT_UNFILTERED is
-- never registered; every payload value is checked with issecretvalue BEFORE it is read.
-- Lua 5.1 safe, ASCII only, line comments only.

local name, ns = ...
ns = type(ns) == "table" and ns or {}
local Lab = {}
ns.Lab = Lab

Lab.MAX_SAMPLES_PER_EVENT = 40
Lab.MAX_TOTAL_SAMPLES = 400
Lab.MAX_STRING = 120
Lab.MAX_ARGS = 12
Lab.MAX_API_ENTRIES = 20
Lab.MAX_FIELDS = 24
Lab.MAX_REFS = 60
Lab.TRACK_DEFAULT = 60
Lab.TRACK_MAX = 300
Lab.REFERENCE_EVENT = "PLAYER_MONEY"     -- proven safe; used only to order other events against money
Lab.NEAR_WINDOW = 1.0
Lab.NEVER = { COMBAT_LOG_EVENT_UNFILTERED = true }

local function emit(text)
  if ns.emit then ns.emit(text) else print(tostring(text)) end
end

---------------------------------------------------------------------------
-- Catalog (protocol sections 5 and 6)
---------------------------------------------------------------------------
Lab.CATALOG = {
  { id = "P0", stage = "API", title = "Presence of every candidate API and event name",
    api = "presence", how = "/gidiag lab api P0", pass = "Reading the lists is the result." },
  { id = "I1", stage = "API", title = "Item data: sell price, bind type, async behaviour",
    api = "itemdata", how = "/gidiag lab api I1  (run it twice; the second run shows the cached state)",
    pass = "Sell price and bind type obtainable; the uncached case understood." },
  { id = "I2", stage = "API", title = "Bags: readable item fields and scan cost",
    api = "bags", how = "/gidiag lab api I2", pass = "Bag snapshot cheap and non-secret." },
  { id = "A1", stage = "API", title = "AFK flag and related state",
    api = "afk", how = "/gidiag lab api A1 normal ; then /afk ; then /gidiag lab api A1 afk ; /afk again",
    pass = "UnitIsAFK readable and it changes." },
  { id = "S1", stage = "API", title = "Map position in the open world and in an instance",
    api = "position", how = "/gidiag lab api S1 openworld ; later inside an instance /gidiag lab api S1 instance",
    pass = "Open world usable; instance behaviour documented." },
  { id = "T2", stage = "API", title = "Movement speed, mounted, flying, swimming, taxi flags (single snapshot)",
    api = "speed", how = "/gidiag lab api T2 walking ; mount up ; /gidiag lab api T2 mounted",
    pass = "Modes distinguishable." },
  { id = "T1a", stage = "API", title = "Taxi flag and position jumps over time (also covers T2, T3, T4)",
    api = "track", how = "/gidiag lab track 120 ; during it: walk, run, mount, take a flight path, hearth",
    pass = "Taxi flag accurate; jumps detectable." },
  { id = "P1", stage = "API", title = "Function names inside the C_* tables found by P0 (names only, nothing is called)",
    api = "tables", how = "/gidiag lab api P1", pass = "Reading the lists is the result." },
  { id = "P2", stage = "API", title = "Restriction and state getters found by P1 (no-argument getters and the restriction enum)",
    api = "restrictions", how = "/gidiag lab api P2 ; run it once out of combat and once in combat",
    pass = "Reading the values is the result." },
  { id = "I1b", stage = "A", title = "Item data load completion event (async item info)",
    events = { "GET_ITEM_INFO_RECEIVED" },
    how = "/gidiag lab reg GET_ITEM_INFO_RECEIVED ; /gidiag lab api I1 ; wait 5 s ; /gidiag lab api I1 again (compare)",
    pass = "Event delivered after RequestLoadItemDataByID; sell price appears afterwards." },
  { id = "H1", stage = "API", title = "Place names for map coordinates",
    api = "names", how = "/gidiag lab api H1 ; or /gidiag lab api H1 MAPID X Y  (X and Y in percent)",
    pass = "A readable place name is returned." },
  { id = "H2", stage = "API", title = "Map overlay host: a test square on the world map",
    api = "square", how = "/gidiag lab square on ; open the world map ; check pins and clicks ; /gidiag lab square off",
    pass = "Square visible, below pins, mouse-transparent, coexists with other map addons." },
  { id = "L3", stage = "A", title = "Loot window slot data and source GUID",
    api = "loot", how = "Open a loot window, then /gidiag lab api L3",
    pass = "Slot fields readable; source GUID classified (Creature or GameObject)." },
  { id = "L1", stage = "A", title = "LOOT_OPENED payload and order versus PLAYER_MONEY",
    events = { "LOOT_OPENED" }, how = "/gidiag lab reg LOOT_OPENED ; kill and loot a few mobs that drop coins",
    pass = "Delivered, args not secret, order versus money known." },
  { id = "L2", stage = "A", title = "LOOT_SLOT_CLEARED per slot",
    events = { "LOOT_SLOT_CLEARED" }, how = "/gidiag lab reg LOOT_SLOT_CLEARED ; take loot slot by slot",
    pass = "Delivered per slot." },
  { id = "M1", stage = "A", title = "Merchant open/close, sale and purchase order versus money",
    events = { "MERCHANT_SHOW", "MERCHANT_CLOSED" },
    how = "One event per session: /gidiag lab reg MERCHANT_SHOW ; open a vendor, sell one item, buy one, close",
    pass = "Delivered; context window known." },
  { id = "Q1", stage = "A", title = "Quest turn-in payload",
    events = { "QUEST_TURNED_IN" }, how = "/gidiag lab reg QUEST_TURNED_IN ; turn in a quest with a copper reward and an item",
    pass = "Args usable; money argument present." },
  { id = "X1", stage = "B", title = "Mail events",
    events = { "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE" },
    how = "One event per session: /gidiag lab reg MAIL_SHOW ; open the mailbox, take money, take an item",
    pass = "Delivered; money-take order versus money known." },
  { id = "X2", stage = "API", title = "Mailbox header metadata: sender, subject, money, items, auction invoice",
    api = "mail", how = "Open the mailbox, then /gidiag lab api X2 label  (reads the first mails; changes nothing)",
    pass = "Headers readable; an auction invoice separates auction proceeds from player mail." },
  { id = "Q2", stage = "B", title = "Quest reward item: bag snapshot diff and BAG_UPDATE_DELAYED",
    events = { "BAG_UPDATE_DELAYED" }, api = "bagdiff",
    how = "/gidiag lab reg BAG_UPDATE_DELAYED ; /gidiag lab api Q2 before ; turn in a quest with an item reward ; /gidiag lab api Q2 after",
    pass = "The reward item appears in the diff; the bag event and the money event order is known." },
  { id = "AHS", stage = "API", title = "Auction house state: money, window, own auctions (listing, cancel, buyout)",
    api = "ahstate", how = "Open the auction house, then /gidiag lab api AHS label  (read-only; each call records money, window state and your own auctions)",
    pass = "Money change of a listing deposit, a cancel and a buyout is known; own auctions are readable." },
  { id = "AH1", stage = "B", title = "Auction house events (one per session)",
    events = { "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "AUCTION_HOUSE_AUCTION_CREATED", "AUCTION_CANCELED", "COMMODITY_PURCHASE_SUCCEEDED" },
    how = "One event per session: /gidiag lab reg AUCTION_HOUSE_AUCTION_CREATED ; post an auction",
    pass = "Delivered; order versus the deposit money change known." },
  { id = "MS1", stage = "B", title = "Outgoing mail: postage and money sent",
    events = { "MAIL_SEND_SUCCESS", "MAIL_FAILED", "MAIL_SEND_INFO_UPDATE" }, api = "sendmail",
    how = "/gidiag lab api MS1 before ; send a mail ; /gidiag lab api MS1 after   (optionally with /gidiag lab reg MAIL_SEND_SUCCESS)",
    pass = "Postage and attached money show in the money change; the send event order is known." },
  { id = "CO1", stage = "API", title = "COD mail: paying and receiving (uses X2 and MAIL_INBOX_UPDATE)",
    api = "mail", events = {},
    how = "See README Session 21 and 22; /gidiag lab api X2 label on both characters, optionally /gidiag lab reg MAIL_INBOX_UPDATE",
    pass = "The COD amount, the payment money change and the COD payment mail are known." },
  { id = "R1", stage = "B", title = "Trade events",
    events = { "TRADE_SHOW", "TRADE_CLOSED", "TRADE_MONEY_CHANGED", "TRADE_ACCEPT_UPDATE" },
    how = "One event per session: /gidiag lab reg TRADE_SHOW ; trade a small amount of gold with a friend or alt",
    pass = "Delivered; gold fields usable." },
  { id = "T1b", stage = "B", title = "Taxi and control events",
    events = { "PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED", "TAXIMAP_OPENED", "TAXIMAP_CLOSED" },
    how = "One event per session: /gidiag lab reg PLAYER_CONTROL_LOST ; take a flight path",
    pass = "Timing matches the ride." },
  { id = "C1", stage = "C", title = "UNIT_SPELLCAST_SUCCEEDED (highest suspicion of the old popup)",
    events = { "UNIT_SPELLCAST_SUCCEEDED" }, how = "/gidiag lab reg UNIT_SPELLCAST_SUCCEEDED ; mine or herb, fish, skin, cast a spell",
    pass = "Delivered; unit token and spell id usable." },
  { id = "C2", stage = "C", title = "CHAT_MSG_MONEY (only if L1 fails)",
    events = { "CHAT_MSG_MONEY" }, how = "/gidiag lab reg CHAT_MSG_MONEY ; loot coins", pass = "Delivered." },
}

local byId, eventExp = {}, {}
for _, exp in ipairs(Lab.CATALOG) do
  byId[string.lower(exp.id)] = exp
  for _, e in ipairs(exp.events or {}) do eventExp[e] = exp end
end

function Lab.Find(id)
  if type(id) ~= "string" then return nil end
  return byId[string.lower(id)]
end

---------------------------------------------------------------------------
-- Safe value handling. A secret value is NEVER read, compared or stored.
---------------------------------------------------------------------------
local function isSecret(v)
  if type(issecretvalue) == "function" then
    local ok, r = pcall(issecretvalue, v)
    return ok and r == true
  end
  return false
end

local function clip(s)
  s = tostring(s)
  if #s > Lab.MAX_STRING then return string.sub(s, 1, Lab.MAX_STRING) .. "..." end
  return s
end

local function describe(v)
  if isSecret(v) then return { type = "secret", secret = true } end
  local t = type(v)
  if t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return { type = "number", value = tostring(v) } end
    return { type = "number", value = v }
  elseif t == "string" then
    return { type = "string", value = clip(v), len = #v }
  elseif t == "boolean" then
    return { type = "boolean", value = v }
  end
  return { type = t }
end

-- Plain value for compact time series; "S" stands for a secret.
local function plain(v)
  if isSecret(v) then return "S" end
  local t = type(v)
  if t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return tostring(v) end
    return v
  elseif t == "boolean" then
    return v
  elseif t == "string" then
    return clip(v)
  end
  return nil
end

local function pack(...) return { n = select("#", ...), ... } end

local function G(path)
  local cur = _G
  for part in string.gmatch(path, "[^%.]+") do
    if type(cur) ~= "table" then return nil end
    cur = cur[part]
    if cur == nil then return nil end
  end
  return cur
end

-- Calls fn(...) under pcall and describes every return value (one level of table fields).
local function callDescribe(label, fn, ...)
  if type(fn) ~= "function" then return { fn = label, present = false } end
  local r = pack(pcall(fn, ...))
  if not r[1] then return { fn = label, present = true, error = clip(r[2]) } end
  local out = { fn = label, present = true, returns = {} }
  for i = 2, math.min(r.n, 18) do
    local value = r[i]
    local d = describe(value)
    if d.type == "table" then
      local fields, count = {}, 0
      local okp = pcall(function()
        for k, x in pairs(value) do
          count = count + 1
          if count > Lab.MAX_FIELDS then break end
          fields[clip(k)] = describe(x)
        end
      end)
      if okp then d.fields = fields end
    end
    out.returns[i - 1] = d
  end
  return out
end

local function showDesc(d)
  if d.secret then return "<secret>" end
  if d.fields then
    local parts = {}
    for k, x in pairs(d.fields) do
      parts[#parts + 1] = k .. "=" .. (x.secret and "<secret>" or (x.value ~= nil and tostring(x.value) or x.type))
    end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
  end
  if d.value ~= nil then return tostring(d.value) end
  return d.type
end

local function resultLine(r)
  if r.summary then
    local parts = {}
    for k, v in pairs(r.summary) do parts[#parts + 1] = k .. "=" .. tostring(v) end
    table.sort(parts)
    return r.fn .. ": " .. table.concat(parts, " ")
  end
  if r.present == false then return r.fn .. ": ABSENT" end
  if r.error then return r.fn .. ": ERROR " .. r.error end
  local parts = {}
  for i, d in ipairs(r.returns or {}) do parts[i] = showDesc(d) end
  local line = r.fn .. " -> " .. table.concat(parts, " | ")
  if #line > 230 then line = string.sub(line, 1, 230) .. "..." end
  return line
end

---------------------------------------------------------------------------
-- Stored data (GoldIntelDiagDB.lab) and run records
---------------------------------------------------------------------------
local state = { registered = nil, frame = nil, watcher = nil, current = nil, recent = {}, events = {}, track = nil, square = nil }

local function store()
  if type(GoldIntelDiagDB) ~= "table" then GoldIntelDiagDB = { loads = 0 } end
  local lab = GoldIntelDiagDB.lab
  if type(lab) ~= "table" then
    lab = { version = 1 }
    GoldIntelDiagDB.lab = lab
  end
  lab.runs = lab.runs or {}
  lab.refs = lab.refs or {}
  lab.report = lab.report or {}
  return lab
end

local function buildString()
  if type(GetBuildInfo) ~= "function" then return nil end
  local ok, version, build = pcall(GetBuildInfo)
  if ok then return tostring(version) .. " build " .. tostring(build) end
  return nil
end

local function nowTime() return type(time) == "function" and time() or 0 end

-- Combat restriction state (0 = inactive, 2 = active in this client); nil when the API is missing.
local function restrictionState()
  local fn = G("C_RestrictedActions.GetAddOnRestrictionState")
  local enum = G("Enum.AddOnRestrictionType")
  if type(fn) ~= "function" or type(enum) ~= "table" or type(enum.Combat) ~= "number" then return nil end
  local ok, v = pcall(fn, enum.Combat)
  if ok then return plain(v) end
  return nil
end

local function runFor(id)
  local exp = Lab.Find(id)
  if not exp then return nil end
  local lab = store()
  local rec = lab.runs[exp.id]
  if not rec then
    rec = { id = exp.id, title = exp.title, build = buildString(), startedAt = nowTime(), status = "open",
            events = {}, api = {}, notes = {} }
    lab.runs[exp.id] = rec
  end
  state.current = exp.id
  return rec
end

local function totalSamples()
  local n = 0
  for _, rec in pairs(store().runs) do
    for _, ev in pairs(rec.events or {}) do n = n + #(ev.samples or {}) end
  end
  return n
end

local function trim()
  local total = totalSamples()
  while total > Lab.MAX_TOTAL_SAMPLES do
    local worst, worstN = nil, 0
    for _, rec in pairs(store().runs) do
      for _, ev in pairs(rec.events or {}) do
        if #(ev.samples or {}) > worstN then worst, worstN = ev, #ev.samples end
      end
    end
    if not worst then break end
    table.remove(worst.samples, 1)
    worst.trimmed = true
    total = total - 1
  end
end

local function round3(x) return math.floor(x * 1000 + 0.5) / 1000 end

---------------------------------------------------------------------------
-- Loot window snapshot, stored with each LOOT_OPENED sample (read-only getters, secret-safe)
---------------------------------------------------------------------------
local function lootSnapshot()
  local numFn = G("GetNumLootItems")
  if type(numFn) ~= "function" then return nil end
  local okn, n = pcall(numFn)
  n = okn and plain(n) or nil
  if type(n) ~= "number" then return { slots = n } end
  local snap = { slots = n, list = {} }
  local typeFn, linkFn, srcFn = G("GetLootSlotType"), G("GetLootSlotLink"), G("GetLootSourceInfo")
  for i = 1, math.min(n, 12) do
    local row = { slot = i }
    if type(typeFn) == "function" then
      local ok, t = pcall(typeFn, i)
      if ok then row.type = plain(t) end
    end
    if type(linkFn) == "function" then
      local ok, link = pcall(linkFn, i)
      local p = ok and plain(link) or nil
      if p == "S" then row.itemId = "S" elseif type(p) == "string" then row.itemId = tonumber(string.match(p, "item:(%d+)")) end
    end
    if type(srcFn) == "function" then
      local r = pack(pcall(srcFn, i))
      if r[1] then
        local guid, qty = plain(r[2]), plain(r[3])
        row.qty = qty
        if guid == "S" then row.guid = "S"
        elseif type(guid) == "string" then
          row.guid = guid
          row.guidType = string.match(guid, "^(%a+)%-")
          row.sourceId = tonumber(string.match(guid, "^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
        end
      end
    end
    snap.list[#snap.list + 1] = row
  end
  return snap
end

---------------------------------------------------------------------------
-- Event capture
---------------------------------------------------------------------------
local function onEvent(_, event, ...)
  local gt = GetTime()
  local n = select("#", ...)
  local sample = { t = nowTime(), gt = gt, n = n, args = {}, restr = restrictionState() }
  for i = 1, math.min(n, Lab.MAX_ARGS) do
    sample.args[i] = describe((select(i, ...)))
  end
  if event == "LOOT_OPENED" then
    local okl, snap = pcall(lootSnapshot)
    if okl then sample.loot = snap end
  end
  if type(GetMoney) == "function" then
    local ok, m = pcall(GetMoney)
    if ok then
      local p = plain(m)
      if type(p) == "number" then sample.money = p end
    end
  end

  -- order versus neighbouring events (within NEAR_WINDOW seconds)
  local kept, latest = {}, nil
  for _, r in ipairs(state.recent) do
    if gt - r.gt <= Lab.NEAR_WINDOW then
      kept[#kept + 1] = r
      if r.event ~= event then
        r.sample.after = r.sample.after or {}
        if #r.sample.after < 3 then r.sample.after[#r.sample.after + 1] = { event = event, dt = round3(gt - r.gt) } end
        latest = r
      end
    end
  end
  if latest then sample.before = { event = latest.event, dt = round3(gt - latest.gt) } end

  local exp = eventExp[event]
  if exp then
    local rec = runFor(exp.id)
    local ev = rec.events[event]
    if not ev then ev = { delivered = 0, samples = {} }; rec.events[event] = ev end
    ev.delivered = (ev.delivered or 0) + 1
    if #ev.samples < Lab.MAX_SAMPLES_PER_EVENT then
      ev.samples[#ev.samples + 1] = sample
      trim()
    else
      ev.capped = true
    end
  elseif event == Lab.REFERENCE_EVENT then
    local refs = store().refs
    refs[#refs + 1] = sample
    while #refs > Lab.MAX_REFS do table.remove(refs, 1) end
  end

  kept[#kept + 1] = { event = event, gt = gt, sample = sample }
  while #kept > 20 do table.remove(kept, 1) end
  state.recent = kept
end

local function guardedOnEvent(...)
  local ok, err = pcall(onEvent, ...)
  if not ok then
    local lab = store()
    lab.errors = lab.errors or {}
    if #lab.errors < 5 then lab.errors[#lab.errors + 1] = clip(err) end
  end
end

local function ensureFrames()
  if not state.frame then
    state.frame = CreateFrame("Frame")
    state.frame:SetScript("OnEvent", guardedOnEvent)
  end
  if not state.watcher then
    state.watcher = CreateFrame("Frame")
    pcall(state.watcher.RegisterEvent, state.watcher, "ADDON_ACTION_FORBIDDEN")
    state.watcher:SetScript("OnEvent", function(_, _, addon, func)
      local text = "ADDON_ACTION_FORBIDDEN addon=" .. clip(plain(addon) or "?") .. " function=" .. clip(plain(func) or "?")
      if state.regEv then state.regEv.popup = text; state.regEv.blocked = true end
      local lab = store()
      lab.popups = lab.popups or {}
      if #lab.popups < 10 then lab.popups[#lab.popups + 1] = text end
      emit(text)
    end)
  end
end

function Lab.Reg(eventName)
  eventName = string.upper(eventName or "")
  if eventName == "" then emit("usage: /gidiag lab reg EVENT_NAME   (see /gidiag lab list)"); return end
  if Lab.NEVER[eventName] then
    emit("refused: " .. eventName .. " is never registered by GoldIntel or this lab (D-030).")
    return
  end
  local exp = eventExp[eventName]
  if not exp then
    emit(eventName .. " is not in the Phase 3a catalog. See /gidiag lab list (ad hoc tests: /gidiag reg NAME).")
    return
  end
  if state.registered == eventName then emit(eventName .. " is already registered in this session."); return end
  if state.registered then
    emit("refused: " .. state.registered .. " was already registered in this session. One NEW event per session (safety rule 1).")
    emit("Type /reload, then /gidiag lab reg " .. eventName)
    return
  end
  local rec = runFor(exp.id)
  local ev = rec.events[eventName]
  if not ev then ev = { delivered = 0, samples = {} }; rec.events[eventName] = ev end
  if C_EventUtils and type(C_EventUtils.IsEventValid) == "function" then
    local ok, valid = pcall(C_EventUtils.IsEventValid, eventName)
    if ok and valid == false then
      ev.invalid = true
      rec.status = "fail"
      emit(eventName .. " is not a valid event name in this client (C_EventUtils.IsEventValid = false). Nothing registered.")
      return
    end
  end
  ensureFrames()
  emit("WARNING: about to register " .. eventName .. ". If an ADDON_ACTION_FORBIDDEN popup appears, that event is RESTRICTED:")
  emit("report the popup text. Nothing changes on your character. Type /reload afterwards before any further registration.")
  state.registered = eventName
  state.regEv = ev
  store().lastRegisterAttempt = eventName
  ev.attemptedAt = nowTime()
  local ok, err = pcall(state.frame.RegisterEvent, state.frame, eventName)
  ev.registerCall = ok and "returned normally" or ("error: " .. clip(err))
  local answer
  if type(state.frame.IsEventRegistered) == "function" then
    local okq, a = pcall(state.frame.IsEventRegistered, state.frame, eventName)
    if okq then answer = a end
  end
  ev.isEventRegistered = answer
  state.events[#state.events + 1] = eventName
  if not (ok and answer ~= false and not ev.popup) then
    rec.status = "blocked"
    ev.blocked = true
    pcall(state.frame.UnregisterEvent, state.frame, eventName)
    emit(eventName .. ": BLOCKED (call " .. ev.registerCall .. ", IsEventRegistered " .. tostring(answer) .. (ev.popup and ", popup seen" or "") .. ")")
    return
  end
  -- reference event for ordering against money (proven safe)
  local okr = pcall(state.frame.RegisterEvent, state.frame, Lab.REFERENCE_EVENT)
  if okr then state.events[#state.events + 1] = Lab.REFERENCE_EVENT end
  emit(eventName .. ": registered (IsEventRegistered " .. tostring(answer) .. "). Now do this: " .. exp.how)
  emit("Capturing the first " .. Lab.MAX_SAMPLES_PER_EVENT .. " payloads. Then /gidiag lab watch, /gidiag lab report, /reload.")
end

function Lab.Unreg()
  if not state.frame then emit("nothing registered"); return end
  for _, e in ipairs(state.events) do pcall(state.frame.UnregisterEvent, state.frame, e) end
  state.events = {}
  emit("capture stopped. The one-event-per-session rule still applies: /reload before registering another event.")
end

function Lab.Watch()
  if not state.registered then emit("no event is registered in this session"); return end
  local exp = eventExp[state.registered]
  local rec = store().runs[exp.id]
  emit("registered this session: " .. state.registered .. "  (experiment " .. exp.id .. ")")
  for e, ev in pairs(rec and rec.events or {}) do
    emit("  " .. e .. ": delivered " .. tostring(ev.delivered) .. ", samples " .. #(ev.samples or {})
      .. (ev.blocked and "  BLOCKED" or "") .. (ev.popup and ("  popup: " .. ev.popup) or ""))
  end
end

---------------------------------------------------------------------------
-- API probes (read-only)
---------------------------------------------------------------------------
local PRESENCE = {
  "GetLootSourceInfo", "GetLootSlotInfo", "GetLootSlotType", "GetLootSlotLink", "GetNumLootItems", "LootFrame",
  "UnitOnTaxi", "GetUnitSpeed", "UnitIsAFK", "UnitIsDND", "IsMounted", "IsFlying", "IsSwimming", "IsFalling",
  "IsResting", "UnitIsDeadOrGhost", "GetItemInfo", "GetItemInfoInstant", "C_Item.GetItemInfo",
  "C_Item.GetItemInfoInstant", "C_Item.RequestLoadItemDataByID", "C_Item.GetItemCount",
  "C_Container.GetContainerNumSlots", "C_Container.GetContainerItemInfo", "C_Container.GetContainerItemLink",
  "GetContainerNumSlots", "GetContainerItemInfo", "C_Map.GetBestMapForUnit", "C_Map.GetPlayerMapPosition",
  "C_Map.GetMapInfoAtPosition", "C_Map.GetMapHighlightInfoAtPosition", "C_Map.GetMapWorldSize",
  "C_Map.GetWorldPosFromMapPos", "C_Map.GetMapRectOnMap", "C_EventUtils.IsEventValid", "issecretvalue",
  "C_Secrets", "C_RestrictedActions", "C_CombatLog", "C_DamageMeter", "C_LootHistory", "C_Loot", "C_MerchantFrame",
  "C_Mail", "C_TradeInfo", "C_QuestLog", "C_TaxiMap", "Settings", "C_SettingsUtil", "hooksecurefunc",
  "GetInstanceInfo", "EJ_GetInstanceInfo", "C_EncounterJournal", "C_AreaPoiInfo", "C_Map.GetMapPosFromWorldPos",
  "WorldMapFrame", "WorldMapFrame.ScrollContainer", "CreateVector2D", "debugprofilestop", "GetTimePreciseSec",
}
local EVENT_NAMES = {
  "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_CLOSED", "CHAT_MSG_LOOT", "CHAT_MSG_MONEY", "MERCHANT_SHOW",
  "MERCHANT_CLOSED", "QUEST_TURNED_IN", "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE", "TRADE_SHOW",
  "TRADE_CLOSED", "TRADE_MONEY_CHANGED", "TRADE_ACCEPT_UPDATE", "UNIT_SPELLCAST_SUCCEEDED", "PLAYER_CONTROL_LOST",
  "PLAYER_CONTROL_GAINED", "TAXIMAP_OPENED", "TAXIMAP_CLOSED", "PLAYER_FLAGS_CHANGED", "PLAYER_UPDATE_RESTING",
  "PLAYER_XP_UPDATE", "BAG_UPDATE_DELAYED", "ITEM_DATA_LOAD_RESULT", "GET_ITEM_INFO_RECEIVED",
}

local function eventValidity(names)
  local out = {}
  for _, e in ipairs(names) do
    local d = { fn = "IsEventValid(" .. e .. ")" }
    if C_EventUtils and type(C_EventUtils.IsEventValid) == "function" then
      local ok, v = pcall(C_EventUtils.IsEventValid, e)
      d.present = true
      if ok then d.returns = { describe(v) } else d.error = clip(v) end
    else
      d.present = false
    end
    out[#out + 1] = d
  end
  return out
end

local function probePresence()
  local present, absent = {}, {}
  for _, path in ipairs(PRESENCE) do
    local v = G(path)
    if v ~= nil then present[#present + 1] = path .. "=" .. type(v) else absent[#absent + 1] = path end
  end
  local results = {
    { fn = "present", summary = { count = #present, list = table.concat(present, " ") } },
    { fn = "absent", summary = { count = #absent, list = table.concat(absent, " ") } },
  }
  for _, r in ipairs(eventValidity(EVENT_NAMES)) do results[#results + 1] = r end
  return results
end

local ITEM_IDS = { 6948, 2589, 2770, 117, 19019, 999999 }
local function probeItemData()
  local results = {}
  local req = G("C_Item.RequestLoadItemDataByID")
  for _, id in ipairs(ITEM_IDS) do
    results[#results + 1] = callDescribe("C_Item.GetItemInfo(" .. id .. ")", G("C_Item.GetItemInfo"), id)
    results[#results + 1] = callDescribe("GetItemInfo(" .. id .. ")", G("GetItemInfo"), id)
    results[#results + 1] = callDescribe("C_Item.GetItemInfoInstant(" .. id .. ")", G("C_Item.GetItemInfoInstant"), id)
  end
  for _, id in ipairs({ 2589, 2770, 19019, 999999 }) do
    results[#results + 1] = callDescribe("C_Item.RequestLoadItemDataByID(" .. id .. ")", req, id)
  end
  for _, r in ipairs(eventValidity({ "ITEM_DATA_LOAD_RESULT", "GET_ITEM_INFO_RECEIVED" })) do results[#results + 1] = r end
  return results
end

local function clock()
  if type(debugprofilestop) == "function" then return debugprofilestop(), "debugprofilestop ms" end
  return GetTime() * 1000, "GetTime ms"
end

local function probeBags()
  local numSlots = G("C_Container.GetContainerNumSlots") or G("GetContainerNumSlots")
  local getInfo = G("C_Container.GetContainerItemInfo") or G("GetContainerItemInfo")
  local results = {}
  if type(numSlots) ~= "function" or type(getInfo) ~= "function" then
    results[1] = { fn = "bag scan", present = false }
    return results
  end
  local t0, unit = clock()
  local slots, items, errors, secrets = 0, 0, 0, 0
  local firstItems = {}
  for bag = 0, 5 do
    local okn, count = pcall(numSlots, bag)
    if okn and type(count) == "number" and not isSecret(count) then
      for slot = 1, count do
        slots = slots + 1
        local ok, info = pcall(getInfo, bag, slot)
        if not ok then errors = errors + 1
        elseif info ~= nil then
          if isSecret(info) then secrets = secrets + 1 else
            items = items + 1
            if #firstItems < 3 then firstItems[#firstItems + 1] = { bag, slot } end
          end
        end
      end
    end
  end
  local t1 = clock()
  results[1] = { fn = "bag scan", present = true,
    summary = { slots = slots, items = items, errors = errors, secretResults = secrets,
                elapsed = string.format("%.2f", t1 - t0) .. " " .. unit } }
  for _, pos in ipairs(firstItems) do
    results[#results + 1] = callDescribe("GetContainerItemInfo(" .. pos[1] .. "," .. pos[2] .. ")", getInfo, pos[1], pos[2])
  end
  return results
end

local function probeAfk()
  local results = {
    callDescribe("UnitIsAFK(player)", G("UnitIsAFK"), "player"),
    callDescribe("UnitIsDND(player)", G("UnitIsDND"), "player"),
    callDescribe("IsResting()", G("IsResting")),
    callDescribe("UnitIsDeadOrGhost(player)", G("UnitIsDeadOrGhost"), "player"),
  }
  for _, r in ipairs(eventValidity({ "PLAYER_FLAGS_CHANGED", "PLAYER_UPDATE_RESTING" })) do results[#results + 1] = r end
  return results
end

local function currentMapPos()
  local map, x, y
  if type(C_Map) == "table" and type(C_Map.GetBestMapForUnit) == "function" then
    local ok, m = pcall(C_Map.GetBestMapForUnit, "player")
    if ok and not isSecret(m) then map = m end
    if map and type(C_Map.GetPlayerMapPosition) == "function" then
      local okp, pos = pcall(C_Map.GetPlayerMapPosition, map, "player")
      if okp and pos ~= nil and not isSecret(pos) and type(pos) == "table" and type(pos.GetXY) == "function" then
        local okx, px, py = pcall(pos.GetXY, pos)
        if okx and not isSecret(px) and not isSecret(py) then x, y = px, py end
      end
    end
  end
  return map, x, y
end

local function probePosition()
  local results = {}
  results[#results + 1] = callDescribe("C_Map.GetBestMapForUnit(player)", G("C_Map.GetBestMapForUnit"), "player")
  local map, x, y = currentMapPos()
  results[#results + 1] = { fn = "player position", summary = { map = tostring(map), x = tostring(x), y = tostring(y) } }
  if map then
    results[#results + 1] = callDescribe("C_Map.GetMapInfo(map)", G("C_Map.GetMapInfo"), map)
    results[#results + 1] = callDescribe("C_Map.GetMapWorldSize(map)", G("C_Map.GetMapWorldSize"), map)
  end
  results[#results + 1] = callDescribe("IsInInstance()", G("IsInInstance"))
  results[#results + 1] = callDescribe("GetInstanceInfo()", G("GetInstanceInfo"))
  results[#results + 1] = callDescribe("GetZoneText()", G("GetZoneText"))
  results[#results + 1] = callDescribe("GetSubZoneText()", G("GetSubZoneText"))
  return results
end

local function probeSpeed()
  return {
    callDescribe("GetUnitSpeed(player)", G("GetUnitSpeed"), "player"),
    callDescribe("IsMounted()", G("IsMounted")),
    callDescribe("IsFlying()", G("IsFlying")),
    callDescribe("IsSwimming()", G("IsSwimming")),
    callDescribe("IsFalling()", G("IsFalling")),
    callDescribe("UnitOnTaxi(player)", G("UnitOnTaxi"), "player"),
  }
end

local function probeNames(args)
  local results = {}
  local map, x, y = currentMapPos()
  local m, px, py = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
  if m and px and py then map, x, y = m, px / 100, py / 100 end
  if not (map and x and y) then
    results[1] = { fn = "H1", summary = { problem = "no map or position; give MAPID X Y (percent)" } }
    return results
  end
  local fn = G("C_Map.GetMapInfoAtPosition")
  local hl = G("C_Map.GetMapHighlightInfoAtPosition")
  local points = { { x, y }, { x + 0.05, y }, { x - 0.05, y }, { x, y + 0.05 }, { x, y - 0.05 } }
  for _, p in ipairs(points) do
    local qx, qy = math.max(0, math.min(1, p[1])), math.max(0, math.min(1, p[2]))
    local label = string.format("C_Map.GetMapInfoAtPosition(%s, %.3f, %.3f)", tostring(map), qx, qy)
    local r = callDescribe(label, fn, map, qx, qy)
    if r.error and type(CreateVector2D) == "function" then
      local r2 = callDescribe(label .. " [vector form]", fn, map, CreateVector2D(qx, qy))
      if not r2.error then r = r2 end
    end
    results[#results + 1] = r
  end
  results[#results + 1] = callDescribe("C_Map.GetMapHighlightInfoAtPosition(center)", hl, map, x, y)
  return results
end

local function probeLoot()
  local results = {}
  local nfn = G("GetNumLootItems")
  local okn, n = false, nil
  if type(nfn) == "function" then okn, n = pcall(nfn) end
  results[1] = { fn = "GetNumLootItems()", present = type(nfn) == "function",
                 summary = { count = tostring(okn and n or "?"), lootFrameShown = tostring(G("LootFrame") and G("LootFrame").IsShown and G("LootFrame"):IsShown()) } }
  if not (okn and type(n) == "number" and n > 0) then
    results[#results + 1] = { fn = "note", summary = { problem = "no loot window open: open one, then run this again" } }
    return results
  end
  for i = 1, math.min(n, 10) do
    results[#results + 1] = callDescribe("GetLootSlotInfo(" .. i .. ")", G("GetLootSlotInfo"), i)
    results[#results + 1] = callDescribe("GetLootSlotType(" .. i .. ")", G("GetLootSlotType"), i)
    results[#results + 1] = callDescribe("GetLootSlotLink(" .. i .. ")", G("GetLootSlotLink"), i)
    local src = callDescribe("GetLootSourceInfo(" .. i .. ")", G("GetLootSourceInfo"), i)
    local first = src.returns and src.returns[1]
    if first and first.type == "string" and first.value then
      src.guidType = string.match(first.value, "^(%a+)%-")
    end
    results[#results + 1] = src
  end
  return results
end

local TABLE_NAMES = { "C_Secrets", "C_RestrictedActions", "C_LootHistory", "C_Loot", "C_MerchantFrame", "C_Mail",
  "C_TradeInfo", "C_TaxiMap", "C_CombatLog", "C_QuestLog", "C_EncounterJournal", "C_AreaPoiInfo" }
local function probeTables()
  local results = {}
  for _, tname in ipairs(TABLE_NAMES) do
    local t = G(tname)
    local keys = {}
    if type(t) == "table" then
      pcall(function() for k in pairs(t) do keys[#keys + 1] = tostring(k) end end)
      table.sort(keys)
    end
    local total = #keys
    while #keys > 80 do table.remove(keys) end
    results[#results + 1] = { fn = tname, summary = { count = total, names = table.concat(keys, " ") } }
  end
  return results
end

local STATE_GETTERS = { "C_Secrets.HasSecretRestrictions", "C_CombatLog.IsCombatLogRestricted", "C_Loot.IsLegacyLootModeEnabled",
  "C_Mail.HasInboxMoney", "C_MerchantFrame.GetNumJunkItems", "C_MerchantFrame.IsSellAllJunkEnabled" }
local function probeRestrictions()
  local results = {}
  for _, path in ipairs(STATE_GETTERS) do results[#results + 1] = callDescribe(path .. "()", G(path)) end
  local enum = G("Enum.AddOnRestrictionType")
  local list = {}
  if type(enum) == "table" then
    pcall(function() for k, v in pairs(enum) do if type(v) == "number" then list[#list + 1] = { k, v } end end end)
    table.sort(list, function(a, b) return a[2] < b[2] end)
  end
  local names = {}
  for _, e in ipairs(list) do names[#names + 1] = e[1] .. "=" .. e[2] end
  results[#results + 1] = { fn = "Enum.AddOnRestrictionType", summary = { count = #list, values = table.concat(names, " ") } }
  for _, e in ipairs(list) do
    results[#results + 1] = callDescribe("GetAddOnRestrictionState(" .. e[1] .. ")", G("C_RestrictedActions.GetAddOnRestrictionState"), e[2])
    results[#results + 1] = callDescribe("IsAddOnRestrictionActive(" .. e[1] .. ")", G("C_RestrictedActions.IsAddOnRestrictionActive"), e[2])
  end
  return results
end

Lab.DIFF_MAX = 30

-- Q2: snapshot of the bags by item id. "before" stores a snapshot in memory (not saved);
-- any other label compares the bags now against it and records what was added, removed or changed.
local function bagSnapshot()
  local numSlots = G("C_Container.GetContainerNumSlots") or G("GetContainerNumSlots")
  local getInfo = G("C_Container.GetContainerItemInfo") or G("GetContainerItemInfo")
  if type(numSlots) ~= "function" or type(getInfo) ~= "function" then return nil end
  local snap = { items = {}, slots = 0, stacks = 0, secrets = 0 }
  for bag = 0, 5 do
    local okn, count = pcall(numSlots, bag)
    if okn and type(count) == "number" and not isSecret(count) then
      for slot = 1, count do
        snap.slots = snap.slots + 1
        local ok, info = pcall(getInfo, bag, slot)
        if ok and info ~= nil then
          if isSecret(info) then snap.secrets = snap.secrets + 1
          elseif type(info) == "table" then
            local id, n, link = info.itemID, info.stackCount, info.hyperlink
            if isSecret(id) or isSecret(n) then
              snap.secrets = snap.secrets + 1
            elseif type(id) == "number" then
              local e = snap.items[id]
              if not e then e = { count = 0, where = bag .. ":" .. slot }; snap.items[id] = e end
              e.count = e.count + (type(n) == "number" and n or 1)
              if type(link) == "string" and not isSecret(link) then e.link = clip(link) end
              snap.stacks = snap.stacks + 1
            end
          end
        end
      end
    end
  end
  return snap
end

local function probeBagDiff(extra)
  local results = {}
  local label = string.lower(tostring(extra and extra.label or "after"))
  local snap = bagSnapshot()
  local money
  local getMoney = G("GetMoney")
  if type(getMoney) == "function" then
    local okm, mv = pcall(getMoney)
    if okm and type(mv) == "number" and not isSecret(mv) then money = mv end
  end
  if not snap then
    results[1] = { fn = "bag snapshot", present = false }
    return results
  end
  results[1] = { fn = "bag snapshot", present = true,
    summary = { slots = snap.slots, stacks = snap.stacks, secretResults = snap.secrets, money = tostring(money), label = label } }
  if label == "before" then
    state.bagBefore = { snap = snap, money = money }
    results[#results + 1] = { fn = "stored", summary = { note = "snapshot kept in memory; now turn in the quest, then run: /gidiag lab api Q2 after" } }
    return results
  end
  local before = state.bagBefore
  if not before then
    results[#results + 1] = { fn = "diff", summary = { problem = "no 'before' snapshot this session: run /gidiag lab api Q2 before first" } }
    return results
  end
  local shown, changes = 0, 0
  local ids = {}
  for id in pairs(before.snap.items) do ids[id] = true end
  for id in pairs(snap.items) do ids[id] = true end
  local order = {}
  for id in pairs(ids) do order[#order + 1] = id end
  table.sort(order)
  for _, id in ipairs(order) do
    local b, a = before.snap.items[id], snap.items[id]
    local bc, ac = b and b.count or 0, a and a.count or 0
    if bc ~= ac then
      changes = changes + 1
      if shown < Lab.DIFF_MAX then
        shown = shown + 1
        local kind = (bc == 0 and "added") or (ac == 0 and "removed") or "changed"
        results[#results + 1] = { fn = kind .. " item " .. id,
          summary = { itemID = id, before = bc, after = ac, delta = ac - bc, link = (a and a.link) or (b and b.link) } }
      end
    end
  end
  local md
  if type(money) == "number" and type(before.money) == "number" then md = money - before.money end
  results[#results + 1] = { fn = "diff total", summary = { changedItems = changes, shown = shown, moneyDelta = tostring(md) } }
  return results
end

local function readMoney()
  local getMoney = G("GetMoney")
  if type(getMoney) ~= "function" then return nil end
  local ok, v = pcall(getMoney)
  if ok and type(v) == "number" and not isSecret(v) then return v end
  return nil
end

Lab.MAIL_MAX = 8

-- X2: read-only look at the open mailbox. GetInboxText is NOT called (it marks a mail as read).
local function probeMail()
  local results = {}
  local frame = G("MailFrame")
  local shown
  if type(frame) == "table" and type(frame.IsShown) == "function" then
    local ok, r = pcall(frame.IsShown, frame)
    if ok and not isSecret(r) then shown = r end
  end
  results[#results + 1] = { fn = "MailFrame:IsShown()", present = type(frame) == "table", summary = { shown = tostring(shown) } }
  results[#results + 1] = { fn = "money", summary = { copper = tostring(readMoney()) } }
  results[#results + 1] = callDescribe("C_Mail.CanCheckInbox()", G("C_Mail.CanCheckInbox"))
  results[#results + 1] = callDescribe("GetInboxNumItems()", G("GetInboxNumItems"))
  local count = 0
  local okn, n = pcall(function() return (G("GetInboxNumItems") or function() return 0 end)() end)
  if okn and type(n) == "number" and not isSecret(n) then count = n end
  if count > Lab.MAIL_MAX then count = Lab.MAIL_MAX end
  for i = 1, count do
    results[#results + 1] = callDescribe("GetInboxHeaderInfo(" .. i .. ")", G("GetInboxHeaderInfo"), i)
    results[#results + 1] = callDescribe("C_Mail.HasInboxMoney(" .. i .. ")", G("C_Mail.HasInboxMoney"), i)
    results[#results + 1] = callDescribe("GetInboxInvoiceInfo(" .. i .. ")", G("GetInboxInvoiceInfo"), i)
    results[#results + 1] = callDescribe("GetInboxItem(" .. i .. ",1)", G("GetInboxItem"), i, 1)
    results[#results + 1] = callDescribe("GetInboxItemLink(" .. i .. ",1)", G("GetInboxItemLink"), i, 1)
  end
  return results
end

---------------------------------------------------------------------------
-- Phase 3b verification addendum (D-068): auction house, outgoing mail, COD. Read-only.
---------------------------------------------------------------------------
Lab.AH_MAX = 8
local AH_EVENT_NAMES = {
  "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "AUCTION_HOUSE_AUCTION_CREATED", "AUCTION_CANCELED",
  "AUCTION_HOUSE_PURCHASE_COMPLETED", "COMMODITY_PURCHASE_SUCCEEDED", "COMMODITY_PURCHASE_FAILED",
  "OWNED_AUCTIONS_UPDATED", "BID_ADDED", "AUCTION_MULTISELL_START", "AUCTION_MULTISELL_UPDATE",
  "AUCTION_HOUSE_POST_ERROR", "AUCTION_HOUSE_POST_WARNING", "MAIL_SEND_SUCCESS", "MAIL_SEND_INFO_UPDATE",
  "MAIL_FAILED", "MAIL_SUCCESS", "SEND_MAIL_COD_CHANGED", "SEND_MAIL_MONEY_CHANGED",
}
local AH_FUNCS = {
  "C_AuctionHouse.GetNumOwnedAuctions", "C_AuctionHouse.GetOwnedAuctions", "C_AuctionHouse.HasFullOwnedAuctionResults",
  "C_AuctionHouse.IsThrottledMessageSystemReady", "C_AuctionHouse.CancelAuction", "C_AuctionHouse.CanCancelAuction",
  "C_AuctionHouse.PostItem", "C_AuctionHouse.PostCommodity", "C_AuctionHouse.PlaceBid", "C_AuctionHouse.ConfirmCommoditiesPurchase",
  "C_AuctionHouse.CalculateItemDeposit", "C_AuctionHouse.CalculateCommodityDeposit", "C_AuctionHouse.GetCancelCost",
  "C_AuctionHouse.GetBidInfo", "C_AuctionHouse.GetNumBidTypes", "C_AuctionHouse.QueryOwnedAuctions",
}

local function frameShown(path)
  local frame = G(path)
  if type(frame) ~= "table" or type(frame.IsShown) ~= "function" then return nil end
  local ok, r = pcall(frame.IsShown, frame)
  if ok and not isSecret(r) then return r end
  return nil
end

local function safeScalar(v)
  if isSecret(v) then return "S" end
  local t = type(v)
  if t == "number" or t == "boolean" then return tostring(v) end
  if t == "string" then return clip(v) end
  return t
end

local function probeAhState(extra)
  local label = string.lower(tostring(extra and extra.label or "default"))
  local results = {}
  results[1] = { fn = "state", summary = { label = label, money = tostring(readMoney()),
    ahShown = tostring(frameShown("AuctionHouseFrame")) } }
  local present, absent = {}, {}
  for _, path in ipairs(AH_FUNCS) do
    if type(G(path)) == "function" then present[#present + 1] = path else absent[#absent + 1] = path end
  end
  results[#results + 1] = { fn = "AH functions", summary = { present = table.concat(present, " "), absent = table.concat(absent, " ") } }
  results[#results + 1] = callDescribe("C_AuctionHouse.GetNumOwnedAuctions()", G("C_AuctionHouse.GetNumOwnedAuctions"))
  results[#results + 1] = callDescribe("C_AuctionHouse.HasFullOwnedAuctionResults()", G("C_AuctionHouse.HasFullOwnedAuctionResults"))
  results[#results + 1] = callDescribe("C_AuctionHouse.IsThrottledMessageSystemReady()", G("C_AuctionHouse.IsThrottledMessageSystemReady"))
  local getOwned = G("C_AuctionHouse.GetOwnedAuctions")
  if type(getOwned) == "function" then
    local ok, list = pcall(getOwned)
    if not ok then
      results[#results + 1] = { fn = "GetOwnedAuctions()", present = true, error = clip(list) }
    elseif type(list) ~= "table" or isSecret(list) then
      results[#results + 1] = { fn = "GetOwnedAuctions()", present = true, summary = { result = isSecret(list) and "S" or type(list) } }
    else
      local n = 0
      pcall(function() for _ in pairs(list) do n = n + 1 end end)
      results[#results + 1] = { fn = "GetOwnedAuctions()", present = true, summary = { count = n } }
      local shown = 0
      for i = 1, math.min(n, Lab.AH_MAX) do
        local a = list[i]
        if type(a) == "table" and not isSecret(a) then
          local parts = {}
          for _, k in ipairs({ "auctionID", "quantity", "bidAmount", "buyoutAmount", "timeLeftSeconds", "timeLeft", "status", "cancelled", "bidder" }) do
            local okf, v = pcall(function() return a[k] end)
            if okf and v ~= nil then parts[#parts + 1] = k .. "=" .. safeScalar(v) end
          end
          local okk, itemID = pcall(function() return a.itemKey and a.itemKey.itemID end)
          if okk and itemID ~= nil then parts[#parts + 1] = "itemID=" .. safeScalar(itemID) end
          shown = shown + 1
          results[#results + 1] = { fn = "owned auction " .. i, summary = { fields = table.concat(parts, " ") } }
        end
      end
    end
  else
    results[#results + 1] = { fn = "GetOwnedAuctions()", present = false }
  end
  if label == "names" then
    for _, r in ipairs(eventValidity(AH_EVENT_NAMES)) do results[#results + 1] = r end
  end
  return results
end

local function probeSendMail(extra)
  local label = string.lower(tostring(extra and extra.label or "default"))
  local results = {}
  results[1] = { fn = "state", summary = { label = label, money = tostring(readMoney()),
    mailShown = tostring(frameShown("MailFrame")), sendShown = tostring(frameShown("SendMailFrame")) } }
  for _, base in ipairs({ "GetSendMailPrice", "GetSendMailMoney", "GetSendMailCOD" }) do
    results[#results + 1] = callDescribe(base .. "()", G(base))
    results[#results + 1] = callDescribe("C_Mail." .. base .. "()", G("C_Mail." .. base))
  end
  results[#results + 1] = callDescribe("GetSendMailItem(1)", G("GetSendMailItem"), 1)
  if label == "names" then
    for _, r in ipairs(eventValidity(AH_EVENT_NAMES)) do results[#results + 1] = r end
  end
  return results
end

local PROBES = {
  restrictions = { id = "P2", fn = probeRestrictions }, p2 = { id = "P2", fn = probeRestrictions },
  tables = { id = "P1", fn = probeTables }, p1 = { id = "P1", fn = probeTables },
  presence = { id = "P0", fn = probePresence }, p0 = { id = "P0", fn = probePresence },
  itemdata = { id = "I1", fn = probeItemData }, i1 = { id = "I1", fn = probeItemData },
  bags = { id = "I2", fn = probeBags }, i2 = { id = "I2", fn = probeBags },
  afk = { id = "A1", fn = probeAfk }, a1 = { id = "A1", fn = probeAfk },
  position = { id = "S1", fn = probePosition }, s1 = { id = "S1", fn = probePosition },
  speed = { id = "T2", fn = probeSpeed }, t2 = { id = "T2", fn = probeSpeed },
  names = { id = "H1", fn = probeNames }, h1 = { id = "H1", fn = probeNames },
  loot = { id = "L3", fn = probeLoot }, l3 = { id = "L3", fn = probeLoot },
  mail = { id = "X2", fn = probeMail }, x2 = { id = "X2", fn = probeMail },
  bagdiff = { id = "Q2", fn = probeBagDiff }, q2 = { id = "Q2", fn = probeBagDiff },
  ahstate = { id = "AHS", fn = probeAhState }, ahs = { id = "AHS", fn = probeAhState },
  sendmail = { id = "MS1", fn = probeSendMail }, ms1 = { id = "MS1", fn = probeSendMail },
}

local SESSION1 = { "P0", "P1", "P2", "I1", "I2", "A1", "S1", "T2", "H1" }

local function runProbe(key, label, extra)
  local probe = PROBES[string.lower(key)]
  if not probe then emit("unknown API probe '" .. tostring(key) .. "'. See /gidiag lab list."); return false end
  local rec = runFor(probe.id)
  local ok, results = pcall(probe.fn, extra or {})
  if not ok then
    emit(probe.id .. " crashed: " .. tostring(results))
    results = { { fn = probe.id, error = clip(results), present = true } }
  end
  local entry = { label = label or "default", t = nowTime(), gt = GetTime(), results = results, restr = restrictionState() }
  rec.api[#rec.api + 1] = entry
  while #rec.api > Lab.MAX_API_ENTRIES do table.remove(rec.api, 1) end
  emit("== " .. probe.id .. " " .. rec.title .. "  [" .. entry.label .. "] ==")
  for _, r in ipairs(results) do emit("  " .. resultLine(r)) end
  return true
end

function Lab.Api(args)
  local key = args[1]
  if not key then emit("usage: /gidiag lab api NAME [label]   names: P0 I1 I2 A1 S1 T2 H1 L3 X2 Q2 AHS MS1 session1"); return end
  if string.lower(key) == "session1" then
    for _, id in ipairs(SESSION1) do runProbe(id, "session1", {}) end
    emit("Session 1 follow-ups: /gidiag lab api A1 afk (after /afk), /gidiag lab api S1 instance (inside an instance),")
    emit("/gidiag lab api T2 mounted (while mounted), /gidiag lab track 120 (walk, run, mount, flight path, hearth),")
    emit("/gidiag lab square on (look at the world map). Then /gidiag lab report and /reload, and send GoldIntelDiag.lua.")
    return
  end
  local rest = {}
  for i = 2, #args do rest[#rest + 1] = args[i] end
  local probe = PROBES[string.lower(key)]
  if probe and probe.id == "H1" then
    runProbe(key, "default", rest)
  elseif probe and probe.id == "Q2" then
    runProbe(key, rest[1] or "after", { label = rest[1] or "after" })
  elseif probe and (probe.id == "AHS" or probe.id == "MS1") then
    runProbe(key, rest[1] or "default", { label = rest[1] or "default" })
  else
    runProbe(key, rest[1], {})
  end
end

---------------------------------------------------------------------------
-- Time series: taxi flag, speed, position jumps (T1a, covers T2, T3, T4)
---------------------------------------------------------------------------
local function callPlain(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b = pcall(fn, ...)
  if not ok then return nil end
  return plain(a), plain(b)
end

local function trackSample()
  local map, x, y = currentMapPos()
  local speed, runSpeed = callPlain(G("GetUnitSpeed"), "player")
  local inst = callPlain(G("IsInInstance"))
  return {
    gt = round3(GetTime()), t = nowTime(), speed = speed, run = runSpeed,
    mounted = callPlain(G("IsMounted")), flying = callPlain(G("IsFlying")),
    swimming = callPlain(G("IsSwimming")), taxi = callPlain(G("UnitOnTaxi"), "player"),
    map = map, x = x and round3(x) or nil, y = y and round3(y) or nil, inst = inst, restr = restrictionState(),
  }
end

local function analyze(samples)
  local a = { samples = #samples, maxSpeed = 0, taxiSamples = 0, mountedSamples = 0, mapChanges = 0, maxJump = 0, maxGap = 0 }
  local prev
  for _, s in ipairs(samples) do
    if type(s.speed) == "number" and s.speed > a.maxSpeed then a.maxSpeed = s.speed end
    if s.taxi == true then a.taxiSamples = a.taxiSamples + 1 end
    if s.mounted == true then a.mountedSamples = a.mountedSamples + 1 end
    if prev then
      if type(s.gt) == "number" and type(prev.gt) == "number" and s.gt - prev.gt > a.maxGap then a.maxGap = round3(s.gt - prev.gt) end
      if s.map ~= prev.map then
        a.mapChanges = a.mapChanges + 1
      elseif s.x and s.y and prev.x and prev.y then
        local d = math.sqrt((s.x - prev.x) ^ 2 + (s.y - prev.y) ^ 2)
        if d > a.maxJump then a.maxJump = round3(d) end
      end
    end
    prev = s
  end
  return a
end

local function stopTrack(why)
  local tr = state.track
  if not tr then emit("no track is running"); return end
  if tr.ticker and tr.ticker.Cancel then pcall(tr.ticker.Cancel, tr.ticker) end
  if tr.frame then tr.frame:SetScript("OnUpdate", nil) end
  state.track = nil
  tr.rec.track.stoppedBecause = why
  tr.rec.track.analysis = analyze(tr.rec.track.samples)
  local a = tr.rec.track.analysis
  emit("track ended (" .. why .. "): " .. a.samples .. " samples, max speed " .. tostring(a.maxSpeed) .. ", taxi samples " .. a.taxiSamples
    .. ", mounted samples " .. a.mountedSamples .. ", map changes " .. a.mapChanges .. ", biggest position jump " .. a.maxJump
    .. " (map units), longest gap " .. a.maxGap .. " s")
end

function Lab.Track(arg)
  if arg == "stop" then stopTrack("stopped by user"); return end
  if state.track then emit("a track is already running; /gidiag lab track stop"); return end
  local secs = tonumber(arg) or Lab.TRACK_DEFAULT
  if secs < 5 then secs = 5 end
  if secs > Lab.TRACK_MAX then secs = Lab.TRACK_MAX end
  local rec = runFor("T1a")
  rec.track = { startedAt = nowTime(), seconds = secs, samples = {} }
  local tr = { rec = rec, count = 0 }
  state.track = tr
  local function tick()
    tr.count = tr.count + 1
    rec.track.samples[#rec.track.samples + 1] = trackSample()
    if tr.count >= secs then stopTrack("finished") end
  end
  if C_Timer and type(C_Timer.NewTicker) == "function" then
    tr.ticker = C_Timer.NewTicker(1, tick)
  else
    tr.frame = CreateFrame("Frame")
    local acc = 0
    tr.frame:SetScript("OnUpdate", function(_, dt) acc = acc + dt; if acc >= 1 then acc = acc - 1; tick() end end)
  end
  emit("tracking once per second for " .. secs .. " s. Now: walk, run, mount up, take a flight path, hearth or teleport if you can.")
  emit("Stop early with /gidiag lab track stop. Results are summarized when it ends.")
end

---------------------------------------------------------------------------
-- Overlay host test (H2): one translucent square on the world map canvas
---------------------------------------------------------------------------
function Lab.Square(arg)
  local rec = runFor("H2")
  if arg == "off" then
    if state.square then state.square:Hide() end
    emit("test square hidden")
    return
  end
  local info = { t = nowTime() }
  rec.square = info
  local wm = G("WorldMapFrame")
  if type(wm) ~= "table" then
    info.problem = "WorldMapFrame is absent"
    emit("H2: WorldMapFrame is absent")
    return
  end
  local ok, err = pcall(function()
    local canvas
    if type(wm.GetCanvas) == "function" then canvas = wm:GetCanvas() end
    if not canvas and wm.ScrollContainer then canvas = wm.ScrollContainer.Child or wm.ScrollContainer end
    local parent = canvas or wm
    info.parent = canvas and (canvas.GetName and canvas:GetName() or "canvas (unnamed)") or "WorldMapFrame"
    if parent.GetFrameLevel then info.parentLevel = parent:GetFrameLevel() end
    if parent.GetFrameStrata then info.parentStrata = parent:GetFrameStrata() end
    if not state.square then
      local sq = CreateFrame("Frame", nil, parent)
      sq:SetSize(80, 80)
      sq:SetPoint("CENTER", parent, "CENTER", 0, 0)
      if sq.EnableMouse then sq:EnableMouse(false) end
      if sq.SetFrameLevel and parent.GetFrameLevel then sq:SetFrameLevel(parent:GetFrameLevel() + 1) end
      local tex = sq:CreateTexture(nil, "ARTWORK")
      tex:SetAllPoints(sq)
      tex:SetColorTexture(1, 0, 0, 0.35)
      state.square = sq
    end
    state.square:Show()
    if state.square.GetFrameLevel then info.squareLevel = state.square:GetFrameLevel() end
    if state.square.IsMouseEnabled then info.mouseEnabled = state.square:IsMouseEnabled() end
  end)
  if not ok then info.problem = clip(err); emit("H2 failed: " .. info.problem); return end
  emit("H2: a translucent red square should now be in the middle of the world map (parent " .. tostring(info.parent) .. ").")
  emit("Open the map. Check: is it visible? can you still click pins and other map addons through it? is it below the pins?")
  emit("Then: /gidiag lab note H2 <what you saw>  and  /gidiag lab square off")
end

---------------------------------------------------------------------------
-- Notes, status, report
---------------------------------------------------------------------------
function Lab.Note(args)
  if #args == 0 then emit("usage: /gidiag lab note [ID] text"); return end
  local id, first = state.current, 1
  if Lab.Find(args[1]) then id, first = Lab.Find(args[1]).id, 2 end
  if not id then emit("no current experiment; start one or give an ID: /gidiag lab note ID text"); return end
  local parts = {}
  for i = first, #args do parts[#parts + 1] = args[i] end
  local rec = runFor(id)
  rec.notes[#rec.notes + 1] = clip(table.concat(parts, " "))
  while #rec.notes > 20 do table.remove(rec.notes, 1) end
  emit("note added to " .. id)
end

local STATUSES = { pass = true, fail = true, inconclusive = true, blocked = true }

function Lab.Done(args)
  local exp = Lab.Find(args[1])
  local status = args[2] and string.lower(args[2])
  if not exp or not status or not STATUSES[status] then
    emit("usage: /gidiag lab done ID pass|fail|inconclusive|blocked")
    return
  end
  local rec = runFor(exp.id)
  rec.status = status
  rec.decidedBy = "user"
  emit(exp.id .. " marked " .. status)
end

local function hasSecretSample(rec)
  for _, ev in pairs(rec.events or {}) do
    for _, s in ipairs(ev.samples or {}) do
      for _, a in ipairs(s.args or {}) do if a.secret then return true end end
    end
  end
  return false
end

-- Suggested status from the data; the user's word (lab done) wins.
function Lab.Suggest(rec)
  if rec.status == "blocked" then return "blocked" end
  local expected = Lab.Find(rec.id)
  if expected and expected.events then
    local any, anyDelivered = false, false
    for _, ev in pairs(rec.events or {}) do
      any = true
      if ev.blocked or ev.popup then return "blocked" end
      if ev.invalid then return "fail" end
      if (ev.delivered or 0) > 0 then anyDelivered = true end
    end
    if not any or not anyDelivered then return "inconclusive" end
    if hasSecretSample(rec) then return "fail" end
    return "pass"
  end
  if rec.track and rec.track.analysis then return "review" end
  if #(rec.api or {}) > 0 or rec.square then return "review" end
  return "inconclusive"
end

function Lab.Report()
  local lab = store()
  local lines = { "Phase 3a lab report  " .. (buildString() or "?") .. "  at " .. nowTime() }
  for _, exp in ipairs(Lab.CATALOG) do
    local rec = lab.runs[exp.id]
    if rec then
      local status = rec.decidedBy == "user" and rec.status or Lab.Suggest(rec)
      local parts = { exp.id .. " [" .. status .. (rec.decidedBy == "user" and ", set by you" or ", suggested") .. "] " .. exp.title }
      for e, ev in pairs(rec.events or {}) do
        parts[#parts + 1] = "   " .. e .. ": delivered " .. tostring(ev.delivered) .. ", samples " .. #(ev.samples or {})
          .. ", IsEventRegistered " .. tostring(ev.isEventRegistered)
          .. (ev.popup and (", POPUP " .. ev.popup) or "") .. (ev.blocked and ", BLOCKED" or "")
      end
      if #(rec.api or {}) > 0 then parts[#parts + 1] = "   api runs: " .. #rec.api end
      if rec.track and rec.track.analysis then
        local a = rec.track.analysis
        parts[#parts + 1] = "   track: " .. a.samples .. " samples, maxSpeed " .. tostring(a.maxSpeed) .. ", taxi " .. a.taxiSamples
          .. ", maxJump " .. a.maxJump .. ", mapChanges " .. a.mapChanges
      end
      if rec.square then parts[#parts + 1] = "   square: " .. tostring(rec.square.problem or "shown") end
      for _, note in ipairs(rec.notes or {}) do parts[#parts + 1] = "   note: " .. note end
      for _, p in ipairs(parts) do lines[#lines + 1] = p end
    else
      lines[#lines + 1] = exp.id .. " [not run] " .. exp.title
    end
  end
  lab.report = lines
  for _, l in ipairs(lines) do emit(l) end
end

function Lab.List()
  local lab = store()
  emit("Phase 3a experiments (A low risk, B medium, C highest suspicion; API = no event registration):")
  for _, exp in ipairs(Lab.CATALOG) do
    local rec = lab.runs[exp.id]
    local status = rec and (rec.decidedBy == "user" and rec.status or Lab.Suggest(rec)) or "not run"
    emit(string.format("  %-4s %-4s [%s] %s", exp.id, exp.stage, status, exp.title))
  end
  emit("details of one: /gidiag lab show ID")
end

function Lab.Show(id)
  local exp = Lab.Find(id)
  if not exp then emit("unknown experiment; see /gidiag lab list"); return end
  emit(exp.id .. "  " .. exp.title .. "  (stage " .. exp.stage .. ")")
  emit("  how:  " .. exp.how)
  emit("  pass: " .. exp.pass)
end

function Lab.Clear()
  if GoldIntelDiagDB then GoldIntelDiagDB.lab = nil end
  state.recent = {}
  emit("lab data cleared. (An event registered in this session stays registered until /reload.)")
end

function Lab.Help()
  emit("/gidiag lab list | show ID | api NAME [label] | api session1 | reg EVENT | unreg | watch")
  emit("/gidiag lab track [seconds|stop] | square on|off | note [ID] text | done ID status | report | clear")
  emit("Session 1 (no event registration): /gidiag lab api session1   then follow the printed steps.")
  emit("Safety: one NEW event per session; /reload before the next. Results are saved in GoldIntelDiag.lua (field lab).")
end

---------------------------------------------------------------------------
-- Command dispatch: rest = text after '/gidiag lab'
---------------------------------------------------------------------------
function Lab.Command(rest)
  local args = {}
  for token in string.gmatch(rest or "", "%S+") do args[#args + 1] = token end
  local cmd = string.lower(args[1] or "help")
  table.remove(args, 1)
  if cmd == "help" then Lab.Help()
  elseif cmd == "list" then Lab.List()
  elseif cmd == "show" then Lab.Show(args[1])
  elseif cmd == "api" then Lab.Api(args)
  elseif cmd == "reg" then Lab.Reg(args[1])
  elseif cmd == "unreg" then Lab.Unreg()
  elseif cmd == "watch" then Lab.Watch()
  elseif cmd == "track" then Lab.Track(args[1])
  elseif cmd == "square" then Lab.Square(args[1] and string.lower(args[1]) or "on")
  elseif cmd == "note" then Lab.Note(args)
  elseif cmd == "done" then Lab.Done(args)
  elseif cmd == "report" then Lab.Report()
  elseif cmd == "clear" then Lab.Clear()
  else emit("unknown lab command '" .. cmd .. "'"); Lab.Help() end
end
