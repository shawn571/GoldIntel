-- Generated embedded copy of every GoldIntel Lua file in TOC order (do not edit; see tools/build_package.py).
local _, ns = ...
ns.sources = ns.sources or {}
ns.sources.version = "0.4.7-phase3b3m3"
ns.sources.current = {
{ path = "Platform/Platform.lua", src = [=====[
-- GoldIntel / Platform / Platform.lua                                   (Phase 1, task 1.2)
--
-- PURPOSE
--  Core of the Platform layer, the ONLY layer allowed to touch the WoW API
--  (Requirements FR-PLT-1, Decisions D-001). This file provides:
--    * the environment indirection  (P.env, defaults to _G; tests inject a fake)
--    * the capability registry      (P.SetCap / P.Has / P.Capabilities)
--    * diagnostics                  (P.Diag ring buffer + optional sink)
--    * lifecycle                    (P.OnReady / P.MarkReady / P.Fatal / P.IsOperational)
--    * small helpers                (P.Util)
--
-- RULES FOR EVERY FILE IN Platform/
--  * Never reference a WoW global directly. Read it through P.env at CALL time:
--        local f = P.env.GetMoney
--    The boundary test (Tests/test_platform_boundary.lua) enforces this.
--  * Write Lua 5.1 compatible code (WoW). No goto, no integer division, no table.unpack.
--  * Never throw across the module boundary; return nil, errString or use P.Diag.
--
-- CONTRACT: Contracts.md F2 (contract version 1.1).

local ADDON, GI = ...
GI = GI or {}   -- real clients always pass the addon table; plain-Lua tests pass one too

local P = GI.Platform or {}
GI.Platform = P

P.VERSION = '0.4.7-phase3b3m3'
P.CONTRACT_VERSION = '1.9.0'
P.env = P.env or _G
P.debug = P.debug or false
P.modules = P.modules or {}

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------

local Util = {}
P.Util = Util

--- Shallow copy of a table (nil-safe).
function Util.shallowCopy(t)
  local out = {}
  if type(t) == 'table' then
    for k, v in pairs(t) do out[k] = v end
  end
  return out
end

--- Returns the keys of t sorted (numbers before strings, then natural order).
function Util.sortedKeys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    return a < b
  end)
  return keys
end

--- True when both tables have identical keys and identical (==) values.
function Util.shallowEqual(a, b)
  if a == b then return true end
  if type(a) ~= 'table' or type(b) ~= 'table' then return false end
  for k, v in pairs(a) do
    if b[k] ~= v then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

--- Deep copy of plain data (tables, strings, numbers, booleans). Cycle-safe; functions and
-- userdata are copied by reference. Metatables are not copied.
function Util.deepCopy(value, seen)
  if type(value) ~= 'table' then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local out = {}
  seen[value] = out
  for k, v in pairs(value) do
    out[Util.deepCopy(k, seen)] = Util.deepCopy(v, seen)
  end
  return out
end

--- Structural equality of plain data. Cycle-safe for the compared shapes.
function Util.deepEqual(a, b, seen)
  if a == b then return true end
  if type(a) ~= 'table' or type(b) ~= 'table' then return false end
  seen = seen or {}
  if seen[a] == b then return true end
  seen[a] = b
  for k, v in pairs(a) do
    if not Util.deepEqual(v, b[k], seen) then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

local function packResult(ok, ...)
  if not ok then return nil, tostring((...)) end
  return { n = select('#', ...), ... }
end

--- Calls the global function `name` under pcall. Returns the results as a table { n = count, ... }
-- or nil plus a reason (function missing or it raised an error). Never raises.
function P.Call(name, ...)
  local f = P.env[name]
  if type(f) ~= 'function' then return nil, 'missing ' .. tostring(name) end
  return packResult(pcall(f, ...))
end

--- Same for env[tableName][fnName](...) (for example C_Container.GetContainerNumSlots).
function P.CallIn(tableName, fnName, ...)
  local t = P.env[tableName]
  if type(t) ~= 'table' or type(t[fnName]) ~= 'function' then return nil, 'missing ' .. tableName .. '.' .. fnName end
  return packResult(pcall(t[fnName], ...))
end

--- True when env[tableName][fnName] is a function.
function P.HasIn(tableName, fnName)
  local t = P.env[tableName]
  return type(t) == 'table' and type(t[fnName]) == 'function'
end

--- Returns env[name] when it is a function, otherwise nil.
function P.fn(name)
  local f = P.env[name]
  if type(f) == 'function' then return f end
  return nil
end

---------------------------------------------------------------------------
-- Event safety (Decisions D-025)
---------------------------------------------------------------------------

-- Events GoldIntel must NEVER register. The client blocks insecure registration of
-- restricted events with ADDON_ACTION_FORBIDDEN (a popup), and pcall cannot suppress it.
-- Extend this list when the diagnostics show another restricted event.
P.RESTRICTED_EVENTS = P.RESTRICTED_EVENTS or { COMBAT_LOG_EVENT_UNFILTERED = true }

-- The 12 events Phase 1 registers. They are PROVEN in the live client (evidence E-02: registered
-- without a popup; PLAYER_MONEY delivery observed), so if the registration check
-- (IsEventRegistered) ever disagrees for one of them it is treated as a check problem, not a
-- block. Every other event is verified strictly (Decisions D-034). Only extend this list with
-- events whose delivery was observed in the real client.
P.TRUSTED_EVENTS = P.TRUSTED_EVENTS or {
  PLAYER_LOGIN = true, PLAYER_ENTERING_WORLD = true, PLAYER_LEAVING_WORLD = true, PLAYER_LOGOUT = true,
  PLAYER_MONEY = true, PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, PLAYER_LEVEL_UP = true,
  SKILL_LINES_CHANGED = true, ZONE_CHANGED = true, ZONE_CHANGED_INDOORS = true, ZONE_CHANGED_NEW_AREA = true,
}

-- Events the Phase 3b collectors are ALLOWED to register (Architecture 19 AC-1, D-069). Every entry
-- was registered in the real client without a popup and delivered (lab E-17..E-34). This list does
-- NOT register anything and does not make an event trusted; Events.Bind still verifies each one.
-- MAIL_CLOSED (never delivered, E-34) and MAIL_SHOW (unverified) are deliberately absent.
P.COLLECTOR_EVENTS = P.COLLECTOR_EVENTS or {
  PLAYER_MONEY = true, LOOT_OPENED = true, LOOT_SLOT_CLEARED = true,
  MERCHANT_SHOW = true, MERCHANT_CLOSED = true, QUEST_TURNED_IN = true,
  MAIL_INBOX_UPDATE = true,
  TRADE_SHOW = true, TRADE_CLOSED = true, TRADE_ACCEPT_UPDATE = true, TRADE_MONEY_CHANGED = true,
  BAG_UPDATE_DELAYED = true, GET_ITEM_INFO_RECEIVED = true, UNIT_SPELLCAST_SUCCEEDED = true,
  AUCTION_HOUSE_AUCTION_CREATED = true,      -- E-36, approved A-1 (D-074)
  CHAT_MSG_MONEY = true,                     -- loot coin signal (E-48/E-49, user approval 2026-10-18); read by Platform/Chat.lua
  CHAT_MSG_LOOT = true,                      -- item loot lines: EVIDENCE RECORDER ONLY (D-080 Q-10, user 2026-10-19); read by Platform/Chat.lua
}

-- Phase 3b-1 collector adapters register themselves here: { name, handlers = { WOW_EVENT = fn },
-- start = fn?, stop = fn?, unitFilter = { WOW_EVENT = 'player' }? }. The Collector (Collect/) decides
-- WHEN to bind them; adapters never register anything by themselves.
P.CollectAdapters = P.CollectAdapters or {}
function P.RegisterCollectAdapter(def)
  P.CollectAdapters[#P.CollectAdapters + 1] = def
  return def
end

--- Is the addon `name` loaded? false when the client cannot tell.
function P.IsAddonLoaded(name)
  local c = P.env.C_AddOns
  local f = (type(c) == 'table' and c.IsAddOnLoaded) or P.env.IsAddOnLoaded
  if type(f) ~= 'function' then return false end
  local ok, loaded = pcall(f, name)
  return ok and loaded and true or false
end

--- True when the Phase 3b collectors may register `name`.
function P.IsCollectorEvent(name)
  return P.COLLECTOR_EVENTS[name] == true and not P.RESTRICTED_EVENTS[name]
end

--- Is `name` a valid event name in this client? Returns true, false, or nil when the
-- client cannot tell (no C_EventUtils.IsEventValid). Never registers anything.
function P.EventNameValid(name)
  local utils = P.env.C_EventUtils
  if type(utils) ~= 'table' or type(utils.IsEventValid) ~= 'function' then return nil end
  local ok, valid = pcall(utils.IsEventValid, name)
  if not ok then return nil end
  return valid and true or false
end

--- True when v is a 12.0 "secret value" (arithmetic/comparison on it would raise errors).
-- False when the client has no issecretvalue.
function P.IsSecret(v)
  local f = P.env.issecretvalue
  if type(f) ~= 'function' then return false end
  local ok, secret = pcall(f, v)
  return ok and secret == true
end

---------------------------------------------------------------------------
-- Module registry
---------------------------------------------------------------------------

--- Registers a Platform module for introspection (/gi status, tests).
function P.Register(name, module)
  P.modules[name] = module
  return module
end

---------------------------------------------------------------------------
-- Diagnostics
---------------------------------------------------------------------------

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }
local DIAG_MAX = 200
local ring, ringTotal = {}, 0
local sink = nil
local printedErrors = {}

-- Everything GoldIntel tells the user is also kept in a small ring buffer, so it can be saved with
-- the data (GoldIntelDB.runtime.output) and sent back without copying text out of the chat window.
local OUTPUT_MAX = 200
local output, outputTotal = {}, 0

--- Chat output. Safe when print is unavailable. The line is also recorded in the output ring.
function P.Print(msg)
  local line = tostring(msg)
  outputTotal = outputTotal + 1
  local t = 0
  if P.Now then t = (P.Now()) end
  output[((outputTotal - 1) % OUTPUT_MAX) + 1] = tostring(t) .. ' ' .. line
  local f = P.fn('print')
  if f then f('GoldIntel: ' .. line) end
end

--- The last n recorded output lines, oldest first ('<unix time> <text>').
function P.GetOutput(n)
  local count = math.min(outputTotal, OUTPUT_MAX)
  n = math.min(n or count, count)
  local out = {}
  local first = outputTotal - n
  for i = 1, n do
    out[i] = output[((first + i - 1) % OUTPUT_MAX) + 1]
  end
  return out
end

--- Number of lines ever printed (not capped by the ring size).
function P.OutputCount() return outputTotal end

function P.ClearOutput()
  output, outputTotal = {}, 0
end

--- Records a diagnostic entry. level: debug | info | warn | error.
-- Errors are printed once per unique message; everything is printed in debug mode.
function P.Diag(level, module, msg)
  if not LEVELS[level] then level = 'info' end
  local t = 0
  if P.Now then t = (P.Now()) end
  local entry = { level = level, module = module or '?', msg = tostring(msg), t = t }
  ringTotal = ringTotal + 1
  ring[((ringTotal - 1) % DIAG_MAX) + 1] = entry
  if sink then pcall(sink, entry) end
  if level == 'error' then
    if not printedErrors[entry.msg] then
      printedErrors[entry.msg] = true
      P.Print('error [' .. entry.module .. ']: ' .. entry.msg)
    end
  elseif P.debug then
    P.Print(level .. ' [' .. entry.module .. ']: ' .. entry.msg)
  end
end

--- Returns diagnostics oldest to newest (copy).
function P.GetDiag()
  local out = {}
  local n = math.min(ringTotal, DIAG_MAX)
  local first = ringTotal - n
  for i = 1, n do
    out[i] = ring[((first + i - 1) % DIAG_MAX) + 1]
  end
  return out
end

--- Number of diagnostics ever recorded (not capped by the ring size).
function P.DiagCount() return ringTotal end

--- Installs a function(entry) called for every diagnostic. Core uses this to forward to the bus.
function P.SetDiagSink(fn)
  if fn ~= nil and type(fn) ~= 'function' then return nil, 'sink must be a function' end
  sink = fn
  return true
end

function P.ClearDiag()
  ring, ringTotal, printedErrors = {}, 0, {}
end

--- Turns verbose diagnostics and normalized-event echo on or off.
function P.SetDebug(on)
  P.debug = on and true or false
  return P.debug
end

---------------------------------------------------------------------------
-- Capability registry
---------------------------------------------------------------------------

local caps, capNotes, capWatchers = {}, {}, {}
P.caps = caps   -- read-only by convention; mutate only through P.SetCap

--- Records whether a capability is available. Notifies watchers on change.
function P.SetCap(cap, value, note)
  value = value and true or false
  local previous = caps[cap]
  caps[cap] = value
  if note ~= nil then capNotes[cap] = note end
  if previous ~= value then
    for i = 1, #capWatchers do
      local ok, err = pcall(capWatchers[i], cap, value, previous)
      if not ok then P.Diag('error', 'Platform', 'capability watcher failed: ' .. tostring(err)) end
    end
  end
  return value
end

--- True only when the capability was probed and is available.
function P.Has(cap)
  return caps[cap] == true
end

function P.CapNote(cap) return capNotes[cap] end

--- Copy of the whole capability table.
function P.Capabilities() return Util.shallowCopy(caps) end

--- Registers function(cap, value, previous). Core forwards this as COMPAT_CHANGED.
function P.WatchCaps(fn)
  if type(fn) ~= 'function' then return nil, 'watcher must be a function' end
  capWatchers[#capWatchers + 1] = fn
  return true
end

---------------------------------------------------------------------------
-- Lifecycle: ready state and fatal conditions
---------------------------------------------------------------------------

local ready = false
local readyListeners = {}
local fatalListeners = {}

P.operational = true
P.fatalReason = nil
P.fatalCap = nil
P.FATAL_CAPS = { 'frame', 'money.get', 'money.event' }

--- Runs fn once the player is logged in (PLAYER_LOGIN). Runs immediately if already ready.
-- Listeners run in registration order; a failing listener never blocks the others.
function P.OnReady(fn)
  if type(fn) ~= 'function' then return nil, 'listener must be a function' end
  if ready then
    local ok, err = pcall(fn)
    if not ok then P.Diag('error', 'Platform', 'ready listener failed: ' .. tostring(err)) end
  else
    readyListeners[#readyListeners + 1] = fn
  end
  return true
end

function P.IsReady() return ready end

--- Called by Events on PLAYER_LOGIN (or by the late-load check). Idempotent.
function P.MarkReady()
  if ready then return false end
  ready = true
  local list = readyListeners
  readyListeners = {}
  for i = 1, #list do
    local ok, err = pcall(list[i])
    if not ok then P.Diag('error', 'Platform', 'ready listener failed: ' .. tostring(err)) end
  end
  return true
end

--- Registers function(reason, cap) called once if the platform becomes non-operational.
function P.OnFatal(fn)
  if type(fn) ~= 'function' then return nil, 'listener must be a function' end
  fatalListeners[#fatalListeners + 1] = fn
  return true
end

--- Marks the platform unusable (first fatal wins). Events.Emit stops delivering after this.
function P.Fatal(cap, reason)
  if not P.operational then return false end
  P.operational = false
  P.fatalCap = cap
  P.fatalReason = tostring(reason)
  P.Diag('error', 'Platform', 'FATAL: ' .. P.fatalReason)
  for i = 1, #fatalListeners do
    pcall(fatalListeners[i], P.fatalReason, cap)
  end
  return true
end

function P.IsOperational() return P.operational end

--- Evaluates the fatal capabilities. Called after probing. Returns true when still operational.
function P.CheckFatal()
  for i = 1, #P.FATAL_CAPS do
    local cap = P.FATAL_CAPS[i]
    if caps[cap] ~= true then
      P.Fatal(cap, 'required capability missing: ' .. cap .. '. GoldIntel is disabled. Run /gi probe and report the output.')
      break
    end
  end
  return P.operational
end

--- pcall wrapper that records failures as diagnostics. Returns ok, result1.
function P.SafeCall(module, fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    P.Diag('error', module, tostring(result))
    return false, result
  end
  return true, result
end

P.Register('Platform', P)
]=====] },
{ path = "Platform/Clock.lua", src = [=====[
-- GoldIntel / Platform / Clock.lua                                      (Phase 1, task 1.4)
--
-- PURPOSE
--  Single source of time for the addon.
--    t   = wall clock, Unix seconds (integer)      -> persisted in records
--    gt  = monotonic seconds with fractions        -> durations, tick deltas
--
--  GetTime() never goes backwards in a healthy client, but this module clamps it
--  anyway so a bad reading can never produce a negative duration downstream.
--
-- CONTRACT: Platform.Now() -> t, gt          (Contracts.md F2)

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Clock.lua')

local Clock = {}
P.Clock = Clock
P.Register('Clock', Clock)

local lastGT = nil
local warnedNoGetTime, warnedNoTime = false, false

--- Number of times the raw monotonic reading went backwards (diagnostics/tests).
Clock.regressions = 0

local function readNumber(name)
  local f = P.env[name]
  if type(f) ~= 'function' then return nil end
  local ok, v = pcall(f)
  if ok and type(v) == 'number' and v == v then return v end   -- v == v rejects NaN
  return nil
end

--- Returns t (Unix seconds, integer) and gt (monotonic seconds, fractional).
function Clock.Now()
  local t = readNumber('time')
  local gt = readNumber('GetTime')

  if t == nil then
    if not warnedNoTime then
      warnedNoTime = true
      P.SetCap('clock.time', false, 'time() unavailable; wall clock reported as 0')
    end
    t = 0
  end
  t = math.floor(t)

  if gt == nil then
    if not warnedNoGetTime then
      warnedNoGetTime = true
      P.SetCap('clock.gettime', false, 'GetTime() unavailable; monotonic clock degraded to wall clock')
    end
    gt = t
  end

  if lastGT ~= nil and gt < lastGT then
    Clock.regressions = Clock.regressions + 1
    gt = lastGT
  end
  lastGT = gt
  return t, gt
end

--- Seconds elapsed since an earlier gt reading (never negative).
function Clock.Since(earlierGT)
  local _, gt = Clock.Now()
  local d = gt - (earlierGT or gt)
  if d < 0 then d = 0 end
  return d
end

--- Test helper: forget the clamp baseline.
function Clock.Reset()
  lastGT = nil
  Clock.regressions = 0
  warnedNoGetTime, warnedNoTime = false, false
end

P.Now = Clock.Now
]=====] },
{ path = "Platform/Events.lua", src = [=====[
-- GoldIntel / Platform / Events.lua                                     (Phase 1, task 1.4)
--
-- PURPOSE
--  1. A tiny pure-Lua dispatcher for NORMALIZED Platform events (P_MONEY, P_ZONE, ...).
--     Contract: Platform.On(eventName, handler(payload)), payload is always a table.
--  2. The only place a WoW event frame is created for event routing.
--     Other Platform modules call Events.Bind(wowEvent, fn) to receive raw WoW events.
--  3. Lifecycle: PLAYER_LOGIN -> ready, PLAYER_ENTERING/LEAVING_WORLD -> in-world flag,
--     PLAYER_REGEN_* -> P_COMBAT, PLAYER_LOGOUT -> P_LOGOUT.
--
-- DESIGN NOTES
--  * Handlers are isolated with pcall: one failing handler never blocks the others.
--  * Removing/adding handlers while an event is being dispatched is safe.
--  * This is the ONLY file allowed to call RegisterEvent (enforced by a test).
--  * Restricted events (P.RESTRICTED_EVENTS) are refused without calling RegisterEvent, and
--    names the client reports invalid (C_EventUtils.IsEventValid) are skipped the same way:
--    a blocked registration shows an ADDON_ACTION_FORBIDDEN popup that pcall cannot hide.
--  * The registration result is recorded as capability 'event.<NAME>'.
--  * After a fatal capability failure (P.Fatal) nothing is emitted except P_LOGOUT.
--
-- CONTRACT: Contracts.md F2 (event table).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Events.lua')

local Events = {}
P.Events = Events
P.Register('Events', Events)

---------------------------------------------------------------------------
-- Event specification (payload shapes). Suffix '?' = optional field.
---------------------------------------------------------------------------

local SPEC = {
  P_MONEY         = { copper = 'number', gt = 'number', gap = 'boolean?' },
  P_LOOT_MONEY    = { copper = 'number', source = 'string?' },
  P_LOOT_CHAT     = { copper = 'number', kind = 'string', group = 'number?' },
  P_LOOT_ITEM     = { itemID = 'number', qty = 'number', source = 'string?' },
  P_VENDOR_OPEN   = {},
  P_VENDOR_CLOSE  = {},
  P_VENDOR_SOLD   = { itemID = 'number', qty = 'number', copper = 'number' },
  P_VENDOR_BOUGHT = { itemID = 'number', qty = 'number', copper = 'number' },
  P_QUEST_DONE    = { questID = 'number', copper = 'number', items = 'table?' },
  P_MAIL_OPEN     = {},
  P_MAIL_CLOSE    = {},
  P_MAIL_TAKE     = { kind = 'string', sender = 'string?', subject = 'string?',
                      copper = 'number', cod = 'number?', items = 'table?' },
  P_TRADE_OPEN    = { partner = 'string?' },
  P_TRADE_DONE    = { gave = 'number', got = 'number', partner = 'string?' },
  P_AH_OPEN       = {},
  P_AH_CLOSE      = {},
  P_AH_LISTED     = { itemID = 'number', qty = 'number', price = 'number',
                      deposit = 'number?', duration = 'number?' },
  P_AH_SOLD       = { itemID = 'number', qty = 'number', price = 'number?' },
  P_AH_EXPIRED    = { itemID = 'number', qty = 'number' },
  P_CAST          = { spellID = 'number', kind = 'string', target = 'string?' },
  P_KILL          = { guid = 'string', classification = 'string?' },
  P_ZONE          = { loc = 'table' },
  P_LEVEL         = { level = 'number' },
  P_PROFS         = { profs = 'table' },
  P_COMBAT        = { inCombat = 'boolean' },
  P_TICK          = { loc = 'table?', dt = 'number' },
  P_LOGOUT        = {},
  -- Phase 3b-1 additive entries (Contracts 1.7, D-074 A-2 and consequences)
  P_LOOT_OPEN     = { sourceType = 'string', guid = 'string?' },   -- creature | object | item | unknown; guid of the first slot's source (M2)
  P_LOOT_CLOSE    = { by = 'string' },                  -- frame | timeout | replaced (D-075)
  P_BAGS_SETTLED  = {},
  P_ITEM_INFO     = { itemID = 'number', ready = 'boolean' },
  P_AH_POSTED     = {},                                 -- AUCTION_HOUSE_AUCTION_CREATED (E-36)
  P_MAIL_UPDATE   = { count = 'number' },               -- MAIL_INBOX_UPDATE with a fresh snapshot
  P_TRADE_CLOSE   = {},                                 -- first TRADE_CLOSED of a window (E-31)
}
Events.SPEC = SPEC

--- Sorted list of every normalized event name.
function Events.Names()
  return P.Util.sortedKeys(SPEC)
end

--- Validates a payload against SPEC. Returns true, or false plus a reason.
function Events.Validate(name, payload)
  local spec = SPEC[name]
  if not spec then return false, 'unknown event ' .. tostring(name) end
  if type(payload) ~= 'table' then return false, 'payload must be a table' end
  for field, want in pairs(spec) do
    local optional = want:sub(-1) == '?'
    local typeName = optional and want:sub(1, -2) or want
    local v = payload[field]
    if v == nil then
      if not optional then return false, 'missing field ' .. field end
    elseif type(v) ~= typeName then
      return false, 'field ' .. field .. ' must be ' .. typeName .. ', got ' .. type(v)
    end
  end
  return true
end

---------------------------------------------------------------------------
-- Normalized event dispatcher
---------------------------------------------------------------------------

local handlers = {}        -- name -> array of fn (false marks a slot removed mid-dispatch)
local depth = {}           -- name -> dispatch nesting level
local dirty = {}           -- name -> true when a compaction is pending

--- Subscribes handler(payload) to a normalized event. Idempotent per (name, fn).
-- Returns fn, or nil plus an error string.
function Events.On(name, fn)
  if type(name) ~= 'string' or not SPEC[name] then
    return nil, 'unknown event ' .. tostring(name)
  end
  if type(fn) ~= 'function' then return nil, 'handler must be a function' end
  local list = handlers[name]
  if not list then
    list = {}
    handlers[name] = list
  end
  for i = 1, #list do
    if list[i] == fn then return fn end
  end
  list[#list + 1] = fn
  return fn
end

--- Unsubscribes. Returns true if a handler was removed.
function Events.Off(name, fn)
  local list = handlers[name]
  if not list then return false end
  for i = 1, #list do
    if list[i] == fn then
      if (depth[name] or 0) > 0 then
        list[i] = false
        dirty[name] = true
      else
        table.remove(list, i)
      end
      return true
    end
  end
  return false
end

--- Number of live handlers for an event (tests/diagnostics).
function Events.HandlerCount(name)
  local list = handlers[name]
  if not list then return 0 end
  local n = 0
  for i = 1, #list do
    if list[i] then n = n + 1 end
  end
  return n
end

local function describe(value)
  if type(value) == 'table' then return '{...}' end
  return tostring(value)
end

local function debugEcho(name, payload)
  if name == 'P_TICK' and not P.debugTicks then return end
  local parts = {}
  for _, k in ipairs(P.Util.sortedKeys(payload)) do
    parts[#parts + 1] = tostring(k) .. '=' .. describe(payload[k])
  end
  P.Print('[evt] ' .. name .. ' ' .. table.concat(parts, ' '))
end

--- Delivers a normalized event to subscribers. Returns the number of handlers invoked.
-- Platform modules call this; other layers must not.
function Events.Emit(name, payload)
  if not SPEC[name] then
    P.Diag('error', 'Events', 'emit of unknown event ' .. tostring(name))
    return 0
  end
  if not P.operational and name ~= 'P_LOGOUT' then return 0 end
  if payload == nil then payload = {} end
  if P.debug or P.validate then
    local ok, why = Events.Validate(name, payload)
    if not ok then
      P.Diag('error', 'Events', 'invalid payload for ' .. name .. ': ' .. tostring(why))
      if P.validate == 'strict' then return 0 end
    end
  end
  if P.debug then debugEcho(name, payload) end

  local list = handlers[name]
  if not list then return 0 end

  depth[name] = (depth[name] or 0) + 1
  local n = #list          -- handlers added during dispatch run on the next event
  local invoked = 0
  for i = 1, n do
    local fn = list[i]
    if fn then
      invoked = invoked + 1
      local ok, err = pcall(fn, payload)
      if not ok then
        P.Diag('error', 'Events', 'handler for ' .. name .. ' failed: ' .. tostring(err))
      end
    end
  end
  depth[name] = depth[name] - 1

  if depth[name] == 0 and dirty[name] then
    dirty[name] = nil
    for i = #list, 1, -1 do
      if not list[i] then table.remove(list, i) end
    end
  end
  return invoked
end

---------------------------------------------------------------------------
-- Raw WoW event routing
---------------------------------------------------------------------------

local frame = nil
local wowHandlers = {}   -- wowEvent -> array of fn(event, ...)

-- Capability stages per raw WoW event (Phase 2, D-034). Core's capability registry subscribes
-- through Events.WatchStage; Platform itself knows nothing about Core.
--   registered : true (verified with IsEventRegistered), false (blocked), nil (cannot verify)
--   delivered  : first observation of the event reaching the frame (never set to false)
--   payload    : true/false, reported by the module that reads the event's data
local registration = {}   -- wowEvent -> true | false | nil
local deliveries = {}     -- wowEvent -> { count, firstGT, lastGT }
local payloads = {}       -- wowEvent -> { usable = boolean, note = string|nil }
local stageWatchers = {}

local function notifyStage(event, stage, value, note)
  for i = 1, #stageWatchers do
    local ok, err = pcall(stageWatchers[i], event, stage, value, note)
    if not ok then P.Diag('error', 'Events', 'stage watcher failed: ' .. tostring(err)) end
  end
end

--- Registers function(wowEvent, stage, value, note) called when a stage is first observed or
-- changes. stage: 'registered' | 'delivered' | 'payloadUsable'.
function Events.WatchStage(fn)
  if type(fn) ~= 'function' then return nil, 'watcher must be a function' end
  stageWatchers[#stageWatchers + 1] = fn
  return true
end

--- Reported by the module that consumes an event's payload (or the value derived from it).
-- Notifies watchers only when the usable flag changes.
function Events.ReportPayload(wowEvent, usable, note)
  usable = usable and true or false
  local previous = payloads[wowEvent]
  if previous and previous.usable == usable then return false end
  payloads[wowEvent] = { usable = usable, note = note }
  notifyStage(wowEvent, 'payloadUsable', usable, note)
  return true
end

--- Stage data for one raw event: { registered, delivered (count), firstGT, lastGT, payloadUsable }.
function Events.Stats(wowEvent)
  local d = deliveries[wowEvent]
  local p = payloads[wowEvent]
  return {
    registered = registration[wowEvent],
    delivered = d and d.count or 0,
    firstGT = d and d.firstGT or nil,
    lastGT = d and d.lastGT or nil,
    payloadUsable = p and p.usable or nil,
  }
end

--- Names of every raw event GoldIntel has bound (sorted).
function Events.BoundEvents()
  local out = {}
  for name in pairs(wowHandlers) do out[#out + 1] = name end
  table.sort(out)
  return out
end

-- Delivery counters (Phase 3b-1, profiling plan PX-7). One record per raw event.
--   received : frame delivered the event          kept   : handler enqueued/used it
--   dropped  : handler filtered it at once        errors : handler raised an error
--   maxPerSec: highest count inside one second    cpu*   : handler time in ms (debugprofilestop)
local counters = {}

local function counterFor(event, gt)
  local c = counters[event]
  if not c then
    c = { received = 0, kept = 0, dropped = 0, errors = 0, firstGT = gt, lastGT = gt,
          sec = -1, secCount = 0, maxPerSec = 0, cpuTotalMs = 0, cpuMaxMs = 0, via = nil }
    counters[event] = c
  end
  return c
end

local function dispatchWow(event, ...)
  local list = wowHandlers[event]
  if not list then return end
  local _, gt = P.Now()
  local d = deliveries[event]
  if not d then
    d = { count = 0, firstGT = gt }
    deliveries[event] = d
    d.count = 1
    d.lastGT = gt
    notifyStage(event, 'delivered', true, 'first delivery observed')
  else
    d.count = d.count + 1
    d.lastGT = gt
  end
  local c = counterFor(event, gt)
  c.received = c.received + 1
  c.lastGT = gt
  local sec = math.floor(gt)
  if sec ~= c.sec then c.sec = sec; c.secCount = 0 end
  c.secCount = c.secCount + 1
  if c.secCount > c.maxPerSec then c.maxPerSec = c.secCount end
  local prof = P.fn('debugprofilestop')
  for i = 1, #list do
    local t0 = prof and prof() or nil
    local ok, res = pcall(list[i], event, ...)
    if t0 then
      local dt = (prof() or t0) - t0
      c.cpuTotalMs = c.cpuTotalMs + dt
      if dt > c.cpuMaxMs then c.cpuMaxMs = dt end
    end
    if not ok then
      c.errors = c.errors + 1
      P.Diag('error', 'Events', 'WoW handler for ' .. tostring(event) .. ' failed: ' .. tostring(res))
    elseif res == 'dropped' then
      c.dropped = c.dropped + 1
    else
      c.kept = c.kept + 1
    end
  end
end

--- Counters for one raw event (copy), or nil when it was never delivered.
function Events.Counters(wowEvent)
  local c = counters[wowEvent]
  if not c then return nil end
  local out = {}
  for k, v in pairs(c) do out[k] = v end
  return out
end

--- Sorted names of every raw event that has counters.
function Events.CounterNames()
  local out = {}
  for name in pairs(counters) do out[#out + 1] = name end
  table.sort(out)
  return out
end

--- Zeroes all delivery counters (the registration state is untouched).
function Events.ResetCounters()
  counters = {}
end

--- Records how an event was registered ('unit-filter' | 'plain').
function Events.RegisteredVia(wowEvent) return Events.via and Events.via[wowEvent] or nil end
Events.via = {}

--- Entry point used by the frame script (also callable from tests).
Events.DispatchWow = dispatchWow

local function ensureFrame()
  if frame then return frame end
  local create = P.fn('CreateFrame')
  if not create then
    P.SetCap('frame', false, 'CreateFrame unavailable')
    return nil
  end
  local ok, f = pcall(create, 'Frame')
  if not ok or not f then
    P.SetCap('frame', false, 'CreateFrame failed: ' .. tostring(f))
    return nil
  end
  frame = f
  f:SetScript('OnEvent', function(_, event, ...) dispatchWow(event, ...) end)
  P.SetCap('frame', true)
  return f
end

--- Subscribes fn(wowEvent, ...) to a raw WoW event.
-- Returns true, or false plus a reason (unknown event, no frame support).
function Events.Bind(wowEvent, fn, opts)
  if type(wowEvent) ~= 'string' or type(fn) ~= 'function' then
    return false, 'Bind needs an event name and a function'
  end
  if P.RESTRICTED_EVENTS[wowEvent] then
    P.SetCap('event.' .. wowEvent, false, 'restricted event, never registered')
    return false, 'restricted event (never registered): ' .. wowEvent
  end
  -- AC-1 (D-069): only events on the allow-list are ever registered.
  if not (P.TRUSTED_EVENTS[wowEvent] or P.IsCollectorEvent(wowEvent)) then
    P.SetCap('event.' .. wowEvent, false, 'event is not on the allow-list (AC-1)')
    return false, 'event not on the allow-list (AC-1): ' .. wowEvent
  end
  if P.EventNameValid(wowEvent) == false then
    P.SetCap('event.' .. wowEvent, false, 'event name not valid in this client')
    return false, 'event name not valid in this client: ' .. wowEvent
  end
  local f = ensureFrame()
  if not f then return false, 'no frame support' end

  local list = wowHandlers[wowEvent]
  if not list then
    -- Recorded BEFORE the call: if the client ever shows a blocked-action popup, /gi status
    -- names the event that caused it (the popup itself does not).
    Events.lastRegisterAttempt = wowEvent
    local ok, err
    local via = 'plain'
    if opts and opts.unit and type(f.RegisterUnitEvent) == 'function' then
      -- Unit-filtered registration (F-5): the client only delivers the named unit's casts.
      ok, err = pcall(function() f:RegisterUnitEvent(wowEvent, opts.unit) end)
      via = 'unit-filter'
      local okCheck, isReg = pcall(function() return f:IsEventRegistered(wowEvent) end)
      if not ok or (okCheck and isReg == false) then
        -- not in effect: fall back to the plain registration of the verified event
        pcall(function() f:UnregisterEvent(wowEvent) end)
        P.Diag('warn', 'Events', wowEvent .. ': unit-filtered registration not in effect, using plain RegisterEvent')
        ok, err = pcall(function() f:RegisterEvent(wowEvent) end)
        via = 'plain'
      end
    else
      ok, err = pcall(function() f:RegisterEvent(wowEvent) end)
    end
    Events.via[wowEvent] = via
    if not ok then
      P.SetCap('event.' .. wowEvent, false, tostring(err))
      registration[wowEvent] = false
      notifyStage(wowEvent, 'registered', false, tostring(err))
      return false, tostring(err)
    end
    -- A blocked registration returns normally. Verify that it actually took effect (E1).
    local verified = nil
    local okCheck, isRegistered = pcall(function() return f:IsEventRegistered(wowEvent) end)
    if okCheck and type(isRegistered) == 'boolean' then verified = isRegistered end
    if verified == false and P.TRUSTED_EVENTS[wowEvent] then
      -- proven in the live client: do not let an unproven check disable a working event
      P.Diag('warn', 'Events', wowEvent .. ': IsEventRegistered is false but this event is proven in the live client; treating it as registered (unverified)')
      verified = nil
    end
    if verified == false then
      local why = 'RegisterEvent returned normally but IsEventRegistered is false (blocked?)'
      P.SetCap('event.' .. wowEvent, false, why)
      P.Diag('error', 'Events', wowEvent .. ': ' .. why)
      registration[wowEvent] = false
      notifyStage(wowEvent, 'registered', false, why)
      return false, 'registration not in effect: ' .. wowEvent
    end
    P.SetCap('event.' .. wowEvent, true, verified and 'registered (verified)' or 'registered (could not verify)')
    registration[wowEvent] = verified      -- true, or nil when IsEventRegistered is unavailable
    notifyStage(wowEvent, 'registered', verified, verified and 'verified with IsEventRegistered' or 'cannot verify')
    list = {}
    wowHandlers[wowEvent] = list
  end
  for i = 1, #list do
    if list[i] == fn then return true end
  end
  list[#list + 1] = fn
  return true
end

--- Removes a raw subscription; unregisters the event when nobody listens any more.
function Events.Unbind(wowEvent, fn)
  local list = wowHandlers[wowEvent]
  if not list then return false end
  for i = 1, #list do
    if list[i] == fn then
      table.remove(list, i)
      if #list == 0 then
        wowHandlers[wowEvent] = nil
        registration[wowEvent] = nil
        Events.via[wowEvent] = nil
        if frame then pcall(function() frame:UnregisterEvent(wowEvent) end) end
      end
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Lifecycle state
---------------------------------------------------------------------------

local inWorld = false
Events.inCombat = false

--- True between PLAYER_ENTERING_WORLD and PLAYER_LEAVING_WORLD.
function P.InWorld() return inWorld end

Events.Bind('PLAYER_LOGIN', function()
  P.MarkReady()
end)

Events.Bind('PLAYER_ENTERING_WORLD', function()
  inWorld = true
end)

-- PLAYER_LEAVING_WORLD is optional: if the client lacks it, in-world simply stays true.
Events.Bind('PLAYER_LEAVING_WORLD', function()
  inWorld = false
end)

Events.Bind('PLAYER_REGEN_DISABLED', function()
  Events.inCombat = true
  Events.Emit('P_COMBAT', { inCombat = true })
end)

Events.Bind('PLAYER_REGEN_ENABLED', function()
  Events.inCombat = false
  Events.Emit('P_COMBAT', { inCombat = false })
end)

Events.Bind('PLAYER_LOGOUT', function()
  Events.Emit('P_LOGOUT', {})
end)

--- Addon loaded after login (load-on-demand, /reload quirks): PLAYER_LOGIN will not fire.
-- Probe.lua calls this last, after every module has registered its OnReady listener.
function Events.CheckLateLoad()
  local isLoggedIn = P.fn('IsLoggedIn')
  if isLoggedIn and not P.IsReady() then
    local ok, logged = pcall(isLoggedIn)
    if ok and logged then
      inWorld = true
      P.MarkReady()
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Public Platform API (Contracts.md F2)
---------------------------------------------------------------------------

P.On = Events.On
P.Off = Events.Off
P.Emit = Events.Emit
]=====] },
{ path = "Platform/Scheduler.lua", src = [=====[
-- GoldIntel / Platform / Scheduler.lua                                  (Phase 1, task 1.4)
--
-- PURPOSE
--  Throttled periodic and delayed work (Architecture section 13):
--      Platform.Every(seconds, fn) -> cancel      periodic task
--      Platform.After(seconds, fn) -> cancel      one-shot task
--
--  Two interchangeable backends, chosen once by Scheduler.Init:
--      'ctimer'   : C_Timer.NewTicker / NewTimer / After   (preferred)
--      'onupdate' : one hidden frame with an OnUpdate script (fallback, fully deterministic)
--
-- DESIGN NOTES
--  * Callbacks run under pcall. A task failing MAX_ERRORS times in a row is cancelled
--    and reported, so a bug can never spam the chat or burn CPU forever.
--  * Periodic tasks never "catch up" after a long stall (loading screen, lag spike):
--    missed ticks are skipped, not replayed. Callers measure real elapsed time themselves.
--  * Cancelling a task from inside any callback is safe.
--  * The OnUpdate backend hides its frame when idle, so an empty scheduler costs nothing.
--
-- LIMITS
--  A single Lua callback is not preemptible. Heavy work must be sliced by the caller.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Scheduler.lua')

local Sched = {}
P.Scheduler = Sched
P.Register('Scheduler', Sched)

local MIN_INTERVAL = 0.01
local MAX_ERRORS = 5

Sched.MIN_INTERVAL = MIN_INTERVAL
Sched.MAX_ERRORS = MAX_ERRORS

local backend = nil          -- 'ctimer' | 'onupdate' | nil
local tasks = {}             -- onupdate backend: array of task tables
local frame = nil
local clockSec = 0           -- onupdate backend: accumulated elapsed seconds
local updating = false
local compactPending = false

---------------------------------------------------------------------------
-- Shared helpers
---------------------------------------------------------------------------

--- Runs one callback invocation with error accounting. Returns false if the task must stop.
local function runTask(task)
  local ok, err = pcall(task.fn)
  if ok then
    task.errors = 0
    return true
  end
  task.errors = task.errors + 1
  P.Diag('error', 'Scheduler', 'task failed (' .. task.errors .. '/' .. MAX_ERRORS .. '): ' .. tostring(err))
  if task.errors >= MAX_ERRORS then
    P.Diag('error', 'Scheduler', 'task cancelled after repeated failures')
    return false
  end
  return true
end

local function validate(seconds, fn)
  if type(seconds) ~= 'number' or seconds ~= seconds or seconds < MIN_INTERVAL then
    return false, 'seconds must be a number >= ' .. MIN_INTERVAL
  end
  if type(fn) ~= 'function' then return false, 'fn must be a function' end
  return true
end

---------------------------------------------------------------------------
-- OnUpdate backend
---------------------------------------------------------------------------

local function setFrameVisible(show)
  if not frame then return end
  if show then
    if frame.Show then frame:Show() end
  else
    if frame.Hide then frame:Hide() end
  end
end

local function compact()
  for i = #tasks, 1, -1 do
    if not tasks[i].active then table.remove(tasks, i) end
  end
  compactPending = false
  if #tasks == 0 then setFrameVisible(false) end
end

--- Advances the OnUpdate backend by `elapsed` seconds. Called by the frame script;
-- tests call it directly for deterministic time control.
function Sched.Update(elapsed)
  if type(elapsed) ~= 'number' or elapsed < 0 then return end
  clockSec = clockSec + elapsed
  updating = true
  local n = #tasks                      -- tasks added during this pass wait for the next one
  for i = 1, n do
    local task = tasks[i]      -- may be nil if a callback called Sched.Reset()
    if task and task.active and task.due <= clockSec then
      if task.interval then
        local late = clockSec - task.due
        if late >= task.interval then
          task.due = clockSec + task.interval      -- stalled: skip missed ticks
        else
          task.due = task.due + task.interval
        end
        if not runTask(task) then task.active = false end
      else
        task.active = false                        -- one-shot: deactivate before running
        runTask(task)
      end
      if not task.active then compactPending = true end
    end
  end
  updating = false
  if compactPending then compact() end
end

local function onUpdateAdd(delay, interval, fn)
  if not frame then
    local create = P.fn('CreateFrame')
    if not create then return nil, 'no frame support' end
    local ok, f = pcall(create, 'Frame')
    if not ok or not f then return nil, 'CreateFrame failed' end
    frame = f
    frame:SetScript('OnUpdate', function(_, elapsed) Sched.Update(elapsed) end)
  end
  local task = { fn = fn, interval = interval, due = clockSec + delay, active = true, errors = 0 }
  tasks[#tasks + 1] = task
  setFrameVisible(true)
  return function()
    if task.active then
      task.active = false
      if updating then
        compactPending = true
      else
        compact()
      end
    end
  end
end

---------------------------------------------------------------------------
-- C_Timer backend
---------------------------------------------------------------------------

local function ctimerEvery(seconds, fn)
  local ct = P.env.C_Timer
  local task = { fn = fn, active = true, errors = 0 }
  local ticker
  local function cancel()
    task.active = false
    if ticker and ticker.Cancel then ticker:Cancel() end
  end
  ticker = ct.NewTicker(seconds, function()
    if not task.active then return end
    if not runTask(task) then cancel() end
  end)
  return cancel
end

local function ctimerAfter(seconds, fn)
  local ct = P.env.C_Timer
  local task = { fn = fn, active = true, errors = 0 }
  if type(ct.NewTimer) == 'function' then
    local timer = ct.NewTimer(seconds, function()
      if not task.active then return end
      task.active = false
      runTask(task)
    end)
    return function()
      task.active = false
      if timer and timer.Cancel then timer:Cancel() end
    end
  end
  ct.After(seconds, function()
    if not task.active then return end
    task.active = false
    runTask(task)
  end)
  return function() task.active = false end
end

---------------------------------------------------------------------------
-- Backend selection and public API
---------------------------------------------------------------------------

local function ctimerAvailable()
  local ct = P.env.C_Timer
  return type(ct) == 'table' and type(ct.NewTicker) == 'function' and type(ct.After) == 'function'
end

--- Selects the backend. opts.backend: 'auto' (default) | 'ctimer' | 'onupdate'.
-- Returns the backend name or nil plus a reason. Safe to call again (tests).
function Sched.Init(opts)
  local want = (opts and opts.backend) or 'auto'
  local hasCT = ctimerAvailable()
  local hasFrame = P.fn('CreateFrame') ~= nil
  P.SetCap('timer.ctimer', hasCT)
  P.SetCap('timer.onupdate', hasFrame)

  if want == 'ctimer' and not hasCT then return nil, 'C_Timer unavailable' end
  if want == 'onupdate' and not hasFrame then return nil, 'no frame support' end

  if want == 'ctimer' or (want == 'auto' and hasCT) then
    backend = 'ctimer'
  elseif hasFrame then
    backend = 'onupdate'
  else
    backend = nil
    return nil, 'no timer backend available'
  end
  return backend
end

--- Cancels every OnUpdate task and resets the internal clock. C_Timer tasks are not
-- tracked here; their cancel functions remain valid. Intended for tests and reloads.
function Sched.Reset()
  tasks = {}
  clockSec = 0
  updating = false
  compactPending = false
  setFrameVisible(false)
end

function Sched.Backend() return backend end

--- Number of live tasks on the OnUpdate backend (tests/diagnostics).
function Sched.ActiveCount()
  local n = 0
  for i = 1, #tasks do
    if tasks[i].active then n = n + 1 end
  end
  return n
end

--- Runs fn every `seconds`. Returns a cancel function, or nil plus an error string.
function Sched.Every(seconds, fn)
  local ok, why = validate(seconds, fn)
  if not ok then return nil, why end
  if not backend then return nil, 'no timer backend' end
  if backend == 'ctimer' then return ctimerEvery(seconds, fn) end
  return onUpdateAdd(seconds, seconds, fn)
end

--- Runs fn once after `seconds`. Returns a cancel function, or nil plus an error string.
function Sched.After(seconds, fn)
  local ok, why = validate(seconds, fn)
  if not ok then return nil, why end
  if not backend then return nil, 'no timer backend' end
  if backend == 'ctimer' then return ctimerAfter(seconds, fn) end
  return onUpdateAdd(seconds, nil, fn)
end

P.Every = Sched.Every
P.After = Sched.After

Sched.Init()
]=====] },
{ path = "Platform/Unit.lua", src = [=====[
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
]=====] },
{ path = "Platform/Loot.lua", src = [=====[
-- GoldIntel / Platform / Loot.lua                                       (Phase 3b-1)
--
-- PURPOSE
--  Loot window adapter. Raw LOOT_OPENED and LOOT_SLOT_CLEARED become:
--      P_LOOT_OPEN  { sourceType }      once per window ('creature' | 'object' | 'item' | 'unknown')
--      P_LOOT_MONEY { copper, source }  one per coin slot offered (a HINT, never the ledger amount)
--      P_LOOT_ITEM  { itemID, qty, source } one per item slot offered
--      P_LOOT_CLOSE { by }              'frame' | 'timeout' | 'replaced'
--
-- EVIDENCE
--  E-18/E-19: coin slot type 2, amount = 2nd return of GetLootSourceInfo; item slot type 1, item id
--  from the link; all readable, also in combat. E-20: LOOT_SLOT_CLEARED can arrive twice for one slot
--  (de-duplicated here). E-24: one GUID can open several windows (never key by GUID alone).
--  E-41: the first rule (close 1.0 s after the last clear, 10 s timeout) was FALSIFIED live: 6 of 6
--  windows closed by timeout, because the player keeps the window open for 20-30 s.
--  E-42 (D-075): LootFrame:IsShown() tracks the window exactly (8 windows, empty corpses, Escape,
--  walk-away, partial loot, close and reopen). So:
--     open  = LOOT_OPENED (LootFrame shown at the same instant)
--     close = LootFrame:IsShown() false, polled every 0.1 s only while a window is open  -> by 'frame'
--     slot clears are INFORMATION ONLY (counted, de-duplicated, never close anything)
--     a 300 s timer is a RECOVERY backstop, not a normal path                            -> by 'timeout'
--     if LootFrame cannot be read the old rule is used for that window (counted as
--     frameUnreadable and legacyWindows; its closes are reported as 'timeout').
--  The 1.0 s linger after a close lives in Collect/Context.lua (money arrives about 0.05 s after the
--  frame hides, E-42).
--
-- This module reads no bags, prices nothing and writes nothing.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Loot.lua')

local Loot = {}
P.LootModule = Loot
P.Register('Loot', Loot)

Loot.POLL = 0.1            -- seconds between LootFrame checks while a window is open (E-42)
Loot.BACKSTOP = 300.0      -- recovery only; the longest observed window was 30.7 s (E-42)
Loot.AFTER_CLEAR = 1.0     -- legacy rule, used only when LootFrame cannot be read
Loot.FALLBACK = 10.0       -- legacy rule, used only when LootFrame cannot be read
Loot.MAX_SLOTS = 40

local SLOT_ITEM, SLOT_MONEY = 1, 2     -- GetLootSlotType (E-18/E-19)

local function tapped(...)           -- diagnostic tap (Ledger/Trace.lua); never changes behaviour
  if Loot.tap then pcall(Loot.tap, ...) end
end

local state = { open = false, id = 0, cleared = {}, legacy = false,
               cancelClose = nil, cancelFallback = nil, cancelPoll = nil }
local function freshStats()
  return { opened = 0, closedFrame = 0, closedTimeout = 0, closedReplaced = 0, clears = 0, lateClears = 0,
           dupClears = 0, unreadable = 0, frameUnreadable = 0, legacyWindows = 0, maxOpenSec = 0 }
end
Loot.stats = freshStats()

local function typeOf(guid)
  if type(guid) ~= 'string' or P.IsSecret(guid) then return 'unknown' end
  local t = guid:match('^(%a+)%-')
  if t == 'Creature' or t == 'Vehicle' then return 'creature' end
  if t == 'GameObject' then return 'object' end
  if t == 'Item' then return 'item' end
  return 'unknown'
end

local function cancelTimers()
  if state.cancelClose then state.cancelClose(); state.cancelClose = nil end
  if state.cancelFallback then state.cancelFallback(); state.cancelFallback = nil end
  if state.cancelPoll then state.cancelPoll(); state.cancelPoll = nil end
end

local function close(by)
  if not state.open then return end
  cancelTimers()
  state.open = false
  if state.openedAt then
    local dur = P.Clock.Since(state.openedAt)
    if dur > Loot.stats.maxOpenSec then Loot.stats.maxOpenSec = dur end
  end
  if by == 'frame' then Loot.stats.closedFrame = Loot.stats.closedFrame + 1
  elseif by == 'timeout' then Loot.stats.closedTimeout = Loot.stats.closedTimeout + 1
  else Loot.stats.closedReplaced = Loot.stats.closedReplaced + 1 end
  tapped('close', by, state.openedAt and P.Clock.Since(state.openedAt) or 0)
  P.Events.Emit('P_LOOT_CLOSE', { by = by })
end

--- True when LootFrame is shown, false when hidden, nil when it cannot be read.
function Loot.FrameShown()
  local frame = P.env.LootFrame
  if type(frame) ~= 'table' or type(frame.IsShown) ~= 'function' then return nil end
  local ok, shown = pcall(frame.IsShown, frame)
  if not ok or P.IsSecret(shown) then return nil end
  return shown and true or false
end

local function num(v)
  if type(v) ~= 'number' or P.IsSecret(v) or v ~= v then return nil end
  return v
end

--- Reads the slots of the open loot window. Returns { sourceType, coins = {...}, items = {...} }.
function Loot.ReadWindow()
  local out = { sourceType = 'unknown', coins = {}, items = {}, detail = {} }
  local n = P.Call('GetNumLootItems')
  local count = n and num(n[1]) or 0
  out.raw = count
  if count > Loot.MAX_SLOTS then count = Loot.MAX_SLOTS end
  local first = true
  for i = 1, count do
    local kind = P.Call('GetLootSlotType', i)
    local slotType = kind and num(kind[1]) or nil
    local src = P.Call('GetLootSourceInfo', i)
    do
      local g = src and src[1]
      local tail = (type(g) == 'string' and not P.IsSecret(g)) and g:sub(-6) or '?'
      out.detail[#out.detail + 1] = string.format('s%d:t%s:a%s:g%s', i, tostring(slotType), tostring(src and num(src[2]) or '?'), tail)
    end
    if first and src then
      out.sourceType = typeOf(src[1]); first = false
      if type(src[1]) == 'string' and not P.IsSecret(src[1]) then out.guid = src[1] end      -- the corpse/object identity (skinning = a repeat window of the same guid, E-24)
    end
    if slotType == SLOT_MONEY then
      local amount = src and num(src[2]) or nil
      if amount and amount > 0 then out.coins[#out.coins + 1] = math.floor(amount) end
    elseif slotType == SLOT_ITEM then
      local link = P.Call('GetLootSlotLink', i)
      local text = link and link[1]
      local id = (type(text) == 'string' and not P.IsSecret(text)) and tonumber(text:match('item:(%d+)')) or nil
      local info = P.Call('GetLootSlotInfo', i)
      local qty = info and num(info[3]) or nil
      if id then out.items[#out.items + 1] = { itemID = id, qty = qty and math.max(1, math.floor(qty)) or 1 } end
    else
      Loot.stats.unreadable = Loot.stats.unreadable + 1
    end
  end
  out.slots = count
  return out
end

--- The old rule, kept only for a window whose frame cannot be read (counted separately).
local function enterLegacy(id)
  if state.cancelPoll then state.cancelPoll(); state.cancelPoll = nil end
  if state.cancelFallback then state.cancelFallback(); state.cancelFallback = nil end
  if state.cancelClose then state.cancelClose(); state.cancelClose = nil end
  state.legacy = true
  Loot.stats.frameUnreadable = Loot.stats.frameUnreadable + 1
  Loot.stats.legacyWindows = Loot.stats.legacyWindows + 1
  if next(state.cleared) ~= nil then
    state.cancelClose = P.After(Loot.AFTER_CLEAR, function()
      state.cancelClose = nil
      if state.open and state.id == id then close('timeout') end
    end)
  else
    state.cancelFallback = P.After(Loot.FALLBACK, function()
      state.cancelFallback = nil
      if state.open and state.id == id and next(state.cleared) == nil then close('timeout') end
    end)
  end
end

--- One check of the loot frame (called every Loot.POLL seconds while a window is open).
function Loot.Tick(id)
  if not state.open or state.legacy or (id and id ~= state.id) then return end
  local shown = Loot.FrameShown()
  if shown == false then
    close('frame')
  elseif shown == nil then
    enterLegacy(state.id)       -- the frame became unreadable mid-window
  end
end

local function onOpened()
  if state.open then close('replaced') end
  state.id = state.id + 1
  state.open = true
  state.cleared = {}
  Loot.stats.opened = Loot.stats.opened + 1
  local id = state.id
  local w = Loot.ReadWindow()
  w.frame = Loot.FrameShown()
  tapped('open', w)
  P.Events.Emit('P_LOOT_OPEN', { sourceType = w.sourceType, guid = w.guid })
  for _, copper in ipairs(w.coins) do P.Events.Emit('P_LOOT_MONEY', { copper = copper, source = w.sourceType }) end
  for _, it in ipairs(w.items) do
    P.Events.Emit('P_LOOT_ITEM', { itemID = it.itemID, qty = it.qty, source = w.sourceType })
  end
  local _, gt = P.Now()
  state.openedAt = gt
  state.legacy = false
  if Loot.FrameShown() == true then
    state.cancelPoll = P.Every(Loot.POLL, function() Loot.Tick(id) end)
    state.cancelFallback = P.After(Loot.BACKSTOP, function()
      state.cancelFallback = nil
      if state.open and state.id == id then close('timeout') end
    end)
  else
    enterLegacy(id)           -- LootFrame missing, unreadable, or not shown when the event arrived
  end
end

local function onCleared(_, slot)
  slot = num(slot)
  if not slot then return 'dropped' end
  if not state.open then
    Loot.stats.lateClears = Loot.stats.lateClears + 1
    return 'dropped'
  end
  if state.cleared[slot] then
    Loot.stats.dupClears = Loot.stats.dupClears + 1       -- E-20: the client sends a slot twice
    return 'dropped'
  end
  state.cleared[slot] = true
  tapped('clear', slot)
  Loot.stats.clears = Loot.stats.clears + 1          -- information only (D-075)
  if state.legacy then
    if state.cancelFallback then state.cancelFallback(); state.cancelFallback = nil end
    if state.cancelClose then state.cancelClose() end
    local id = state.id
    state.cancelClose = P.After(Loot.AFTER_CLEAR, function()
      state.cancelClose = nil
      if state.open and state.id == id then close('timeout') end
    end)
  end
end

--- True while a loot window is considered open.
function Loot.IsOpen() return state.open end

function Loot.Stop()
  cancelTimers()
  state.open = false
  state.cleared = {}
end

function Loot.Reset()
  Loot.Stop()
  state.id = 0
  Loot.stats = freshStats()
end

Loot.OnOpened = function() onOpened() end
Loot.OnCleared = onCleared

P.RegisterCollectAdapter({
  name = 'Loot',
  handlers = { LOOT_OPENED = function(_, ...) return Loot.OnOpened(...) end, LOOT_SLOT_CLEARED = onCleared },
  stop = Loot.Stop,
})
]=====] },
{ path = "Platform/Merchant.lua", src = [=====[
-- GoldIntel / Platform / Merchant.lua                                   (Phase 3b-1)
--
-- Vendor window adapter: MERCHANT_SHOW -> P_VENDOR_OPEN, MERCHANT_CLOSED -> P_VENDOR_CLOSE.
-- E-33: the close event fires for both close routes and arrives TWICE in the same frame when the
-- window closes by walking away, so the close is idempotent (the duplicate is counted as dropped).
-- No amounts are read here: vendor money is matched by sign inside the window (AC-4 window mode).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Merchant.lua')

local Merchant = {}
P.MerchantModule = Merchant
P.Register('Merchant', Merchant)

local open = false
Merchant.stats = { opened = 0, closed = 0, duplicateCloses = 0, closeWithoutOpen = 0, duplicateOpens = 0 }

local function onShow()
  if open then
    Merchant.stats.duplicateOpens = Merchant.stats.duplicateOpens + 1
    return 'dropped'
  end
  open = true
  Merchant.stats.opened = Merchant.stats.opened + 1
  P.Events.Emit('P_VENDOR_OPEN', {})
end

local function onClosed()
  if not open then
    Merchant.stats.duplicateCloses = Merchant.stats.duplicateCloses + 1
    return 'dropped'
  end
  open = false
  Merchant.stats.closed = Merchant.stats.closed + 1
  P.Events.Emit('P_VENDOR_CLOSE', {})
end

function Merchant.IsOpen() return open end
function Merchant.Stop() open = false end
function Merchant.Reset()
  open = false
  Merchant.stats = { opened = 0, closed = 0, duplicateCloses = 0, closeWithoutOpen = 0, duplicateOpens = 0 }
end

Merchant.OnShow = onShow
Merchant.OnClosed = onClosed

P.RegisterCollectAdapter({
  name = 'Merchant',
  handlers = { MERCHANT_SHOW = function() return onShow() end, MERCHANT_CLOSED = function() return onClosed() end },
  stop = Merchant.Stop,
})
]=====] },
{ path = "Platform/Quest.lua", src = [=====[
-- GoldIntel / Platform / Quest.lua                                      (Phase 3b-1)
--
-- Quest turn-in adapter: QUEST_TURNED_IN(questID, xp, money) -> P_QUEST_DONE { questID, copper }.
-- E-22: all three arguments are non-secret numbers; the money argument equals the following
-- PLAYER_MONEY delta exactly (0.041 s later). The argument is an EXPECTATION for the ledger, never
-- a ledger amount (principle 1). Secret or non-numeric arguments are dropped and counted.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Quest.lua')

local Quest = {}
P.QuestModule = Quest
P.Register('Quest', Quest)

Quest.stats = { turnedIn = 0, unreadable = 0 }

local function onTurnedIn(_, questID, _xp, money)
  local function ok(v) return type(v) == 'number' and not P.IsSecret(v) and v == v end
  if not ok(questID) or not ok(money) or money < 0 then
    Quest.stats.unreadable = Quest.stats.unreadable + 1
    return 'dropped'
  end
  Quest.stats.turnedIn = Quest.stats.turnedIn + 1
  P.Events.Emit('P_QUEST_DONE', { questID = math.floor(questID), copper = math.floor(money) })
end

Quest.OnTurnedIn = onTurnedIn
function Quest.Reset() Quest.stats = { turnedIn = 0, unreadable = 0 } end

P.RegisterCollectAdapter({ name = 'Quest', handlers = { QUEST_TURNED_IN = onTurnedIn } })
]=====] },
{ path = "Platform/Trade.lua", src = [=====[
-- GoldIntel / Platform / Trade.lua                                      (Phase 3b-1)
--
-- Trade window adapter. TRADE_SHOW -> P_TRADE_OPEN, the FIRST TRADE_CLOSED of a window ->
-- P_TRADE_CLOSE. E-31: TRADE_CLOSED arrives twice per close (the second is dropped); the trade money
-- lands 0.394 s after the close; a cancelled trade changes no money. TRADE_ACCEPT_UPDATE and
-- TRADE_MONEY_CHANGED are counted and remembered (flags readable through Trade.State()) but emit
-- nothing; the item side of a trade is not read (never probed).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Trade.lua')

local Trade = {}
P.TradeModule = Trade
P.Register('Trade', Trade)

local open = false
local flags = { moneyChanged = false, acceptUpdates = 0 }
Trade.stats = { opened = 0, closed = 0, duplicateCloses = 0, duplicateOpens = 0 }

local function onShow()
  if open then
    Trade.stats.duplicateOpens = Trade.stats.duplicateOpens + 1
    return 'dropped'
  end
  open = true
  flags = { moneyChanged = false, acceptUpdates = 0 }
  Trade.stats.opened = Trade.stats.opened + 1
  P.Events.Emit('P_TRADE_OPEN', {})
end

local function onClosed()
  if not open then
    Trade.stats.duplicateCloses = Trade.stats.duplicateCloses + 1
    return 'dropped'
  end
  open = false
  Trade.stats.closed = Trade.stats.closed + 1
  P.Events.Emit('P_TRADE_CLOSE', {})
end

local function onAccept()
  if not open then return 'dropped' end
  flags.acceptUpdates = flags.acceptUpdates + 1
end

local function onMoney()
  if not open then return 'dropped' end
  flags.moneyChanged = true
end

function Trade.IsOpen() return open end
--- { moneyChanged, acceptUpdates } of the current or last window.
function Trade.State() return { moneyChanged = flags.moneyChanged, acceptUpdates = flags.acceptUpdates } end
function Trade.Stop() open = false end
function Trade.Reset()
  open = false
  flags = { moneyChanged = false, acceptUpdates = 0 }
  Trade.stats = { opened = 0, closed = 0, duplicateCloses = 0, duplicateOpens = 0 }
end

Trade.OnShow, Trade.OnClosed, Trade.OnAccept, Trade.OnMoney = onShow, onClosed, onAccept, onMoney

P.RegisterCollectAdapter({
  name = 'Trade',
  handlers = {
    TRADE_SHOW = function() return onShow() end, TRADE_CLOSED = function() return onClosed() end,
    TRADE_ACCEPT_UPDATE = function() return onAccept() end, TRADE_MONEY_CHANGED = function() return onMoney() end,
  },
  stop = Trade.Stop,
})
]=====] },
{ path = "Platform/Chat.lua", src = [=====[
-- GoldIntel / Platform / Chat.lua                       (Phase 3b-2, 0.3.5 evidence, 0.3.6 chat-signal rule)
--
-- PURPOSE
--  The client prints a chat line for money: when you loot coin, and (in Classic) when a group
--  splits coin ("Your share of the loot is ..."). If CHAT_MSG_MONEY reaches the addon with readable text, it may
--  give an exact signal for group shares, also for members who get no loot window. This module records the raw
--  text and when it arrived; it emits nothing and classifies nothing. Ledger/Trace.lua prints the facts.
--
-- QUESTIONS THIS ANSWERS (user list, 2026-10-18): does the event exist and reach the addon; exact English text;
--  does it fire for the looter; for non-looters; does it hold the exact amount; before or after PLAYER_MONEY.
--
-- 3b-2 M5 (user approval 2026-10-18, evidence E-48/E-49): the module now also EMITS P_LOOT_CHAT { copper, kind, group }
-- for the two lines that report coin the local player received from a corpse or object:
--   kind 'self'   YOU_LOOT_MONEY        "You loot 2 Copper"
--   kind 'share'  LOOT_MONEY_SPLIT      "Your share of the loot is 6 Copper."
-- It uses the client's own GlobalStrings when present (English fallback). The amount must be the WHOLE rest of the
-- line (money words only); anything else (guild-bank text, other players' loot, unreadable text) emits nothing.
-- Sources.lua turns the event into an exact expectation. This module classifies nothing.
--
-- Chat.ParseMoney(text) -> copper | nil reads "1 Gold 3 Silver 5 Copper" style amounts (the client's own
-- GOLD_AMOUNT / SILVER_AMOUNT / COPPER_AMOUNT strings when present, English words otherwise). Evidence only.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Chat.lua')

local Chat = {}
P.ChatModule = Chat
P.Register('Chat', Chat)

Chat.stats = { seen = 0, text = 0, secret = 0, nonString = 0, emitted = 0, ignored = 0 }
Chat.RING = 20
local recent = {}

local function formatToPattern(fmt, fallback)
  if type(fmt) ~= 'string' or fmt == '' then return fallback end
  local pat = fmt:gsub('([%^%$%(%)%.%[%]%*%+%-%?])', '%%%1')
  pat = pat:gsub('%%%%d', '(%%d+)'):gsub('%%d', '(%%d+)'):gsub('%%1%$d', '(%%d+)')
  if not pat:find('(%d+)', 1, true) then return fallback end
  return pat
end

--- Copper in a message, or nil. Evidence helper, never used for the ledger.
function Chat.ParseMoney(text)
  if type(text) ~= 'string' then return nil end
  local env = P.env or {}
  local gold = formatToPattern(env.GOLD_AMOUNT, '(%d+) Gold')
  local silver = formatToPattern(env.SILVER_AMOUNT, '(%d+) Silver')
  local copper = formatToPattern(env.COPPER_AMOUNT, '(%d+) Copper')
  local g, s, c = tonumber(text:match(gold)), tonumber(text:match(silver)), tonumber(text:match(copper))
  if not (g or s or c) then return nil end
  return (g or 0) * 10000 + (s or 0) * 100 + (c or 0)
end

local function fmtToAnchored(fmt, fallback)
  if type(fmt) ~= 'string' or not fmt:find('%s', 1, true) then return fallback end
  local a, b = fmt:match('^(.-)%%s(.*)$')
  if not a or b:find('%', 1, true) then return fallback end          -- more than one argument: not the plain shape
  local function esc(x) return (x:gsub('([%^%$%(%)%.%[%]%*%+%-%?%%])', '%%%1')) end
  return '^' .. esc(a) .. '(.-)' .. esc(b) .. '$'
end

--- The copper in a string that holds NOTHING but money words, else nil. (Guild-bank and other text is refused.)
function Chat.ParseExact(rest)
  if type(rest) ~= 'string' then return nil end
  local copper = Chat.ParseMoney(rest)
  if not copper or copper <= 0 then return nil end
  local env = P.env or {}
  local left = rest
  for _, pat in ipairs({ formatToPattern(env.GOLD_AMOUNT, '(%d+) Gold'), formatToPattern(env.SILVER_AMOUNT, '(%d+) Silver'),
                         formatToPattern(env.COPPER_AMOUNT, '(%d+) Copper') }) do
    left = left:gsub(pat, '')
  end
  if left:find('[%w]') then return nil end
  return copper
end

--- 'self' | 'share', copper  for a coin chat line the player received, else nil.
function Chat.Classify(text)
  if type(text) ~= 'string' then return nil end
  local env = P.env or {}
  local selfPat = fmtToAnchored(env.YOU_LOOT_MONEY, '^You loot (.-)$')
  local sharePat = fmtToAnchored(env.LOOT_MONEY_SPLIT, '^Your share of the loot is (.-)%.$')
  local rest = text:match(sharePat)
  if rest then local c = Chat.ParseExact(rest); if c then return 'share', c end return nil end
  rest = text:match(selfPat)
  if rest then local c = Chat.ParseExact(rest); if c then return 'self', c end end
  return nil
end

local function groupSize()
  local ok, r = pcall(P.Call, 'GetNumGroupMembers')
  local n = ok and r and r[1]
  if type(n) == 'number' and not P.IsSecret(n) then return n end
end

local function onMoney(_, text)
  Chat.stats.seen = Chat.stats.seen + 1
  local rec = { gt = select(2, P.Now()) }
  if P.IsSecret(text) then
    Chat.stats.secret = Chat.stats.secret + 1
    rec.secret = true
  elseif type(text) ~= 'string' then
    Chat.stats.nonString = Chat.stats.nonString + 1
    rec.nonString = type(text)
  else
    Chat.stats.text = Chat.stats.text + 1
    rec.text = text
    rec.copper = Chat.ParseMoney(text)
  end
  recent[#recent + 1] = rec
  if #recent > Chat.RING then table.remove(recent, 1) end
  if Chat.tap then pcall(Chat.tap, rec) end          -- diagnostic tap (Ledger/Trace.lua)
  if rec.text then
    local kind, copper = Chat.Classify(rec.text)
    if kind then
      Chat.stats.emitted = (Chat.stats.emitted or 0) + 1
      pcall(P.Events.Emit, 'P_LOOT_CHAT', { copper = copper, kind = kind, group = groupSize() })
    else
      Chat.stats.ignored = (Chat.stats.ignored or 0) + 1
    end
  end
end

function Chat.Recent() return recent end
function Chat.Stop() end
function Chat.Reset()
  Chat.stats = { seen = 0, text = 0, secret = 0, nonString = 0, emitted = 0, ignored = 0 }
  recent = {}
  if Chat.ResetLoot then Chat.ResetLoot() end
end

Chat.OnMoney = onMoney

---------------------------------------------------------------------------
-- CHAT_MSG_LOOT: EVIDENCE RECORDER ONLY (D-080 Q-10, user 2026-10-19). Nothing is emitted and no rule uses it.
-- It answers: does the event reach the addon with readable text, what do the lines look like for items you loot,
-- items pushed to you (quest rewards, mail), group rolls and items other players receive, and how long after the
-- bag settle they arrive. Ledger/Trace.lua prints the facts (CHAT_LOOT lines). A rule needs a separate approval.
---------------------------------------------------------------------------
Chat.LOOT_RING = 40
Chat.lootStats = { seen = 0, text = 0, secret = 0, nonString = 0, self = 0, other = 0 }
local lootRecent = {}

--- kind, itemID, qty for an item chat line. kind: 'loot' | 'lootMulti' | 'pushed' | 'created' | 'won' | 'otherLoot' |
-- 'roll' | 'unknown'. English patterns (the client's own GlobalStrings are recorded raw by the trace, not trusted).
function Chat.ClassifyLoot(text)
  if type(text) ~= 'string' then return 'unknown' end
  local id = tonumber(text:match('item:(%d+)'))
  local qty = tonumber(text:match('x(%d+)%.?$')) or (id and 1 or nil)
  local kind = 'unknown'
  if text:find('^You receive loot:') then kind = text:find('x%d+%.?$') and 'lootMulti' or 'loot'
  elseif text:find('^You receive item:') then kind = 'pushed'
  elseif text:find('^You create:') then kind = 'created'
  elseif text:find('^You won:') then kind = 'won'
  elseif text:find(' receives loot:') or text:find(' receives item:') then kind = 'otherLoot'
  elseif text:find(' won: ') or text:find('Roll') or text:find(' rolled ') or text:find(' passed') then kind = 'roll' end
  return kind, id, qty
end

local function onLoot(_, text)
  local st = Chat.lootStats
  st.seen = st.seen + 1
  local rec = { gt = select(2, P.Now()) }
  if P.IsSecret(text) then
    st.secret = st.secret + 1
    rec.secret = true
  elseif type(text) ~= 'string' then
    st.nonString = st.nonString + 1
    rec.nonString = type(text)
  else
    st.text = st.text + 1
    rec.text = text
    rec.kind, rec.itemID, rec.qty = Chat.ClassifyLoot(text)
    if rec.kind == 'loot' or rec.kind == 'lootMulti' or rec.kind == 'pushed' or rec.kind == 'created' or rec.kind == 'won' then
      st.self = st.self + 1
    else
      st.other = st.other + 1
    end
  end
  lootRecent[#lootRecent + 1] = rec
  if #lootRecent > Chat.LOOT_RING then table.remove(lootRecent, 1) end
  if Chat.lootTap then pcall(Chat.lootTap, rec) end
end

function Chat.LootRecent() return lootRecent end
function Chat.ResetLoot()
  Chat.lootStats = { seen = 0, text = 0, secret = 0, nonString = 0, self = 0, other = 0 }
  lootRecent = {}
end
Chat.OnLoot = onLoot

P.RegisterCollectAdapter({ name = 'ChatLoot', handlers = { CHAT_MSG_LOOT = onLoot } })

P.RegisterCollectAdapter({
  name = 'Chat',
  handlers = { CHAT_MSG_MONEY = onMoney },
  stop = Chat.Stop,
})
]=====] },
{ path = "Platform/Mail.lua", src = [=====[
-- GoldIntel / Platform / Mail.lua                                       (Phase 3b-1)
--
-- Mailbox adapter.
--   * Window state by polling MailFrame:IsShown() every 0.5 s while collecting (MAIL_CLOSED is NEVER
--     delivered, E-34; MAIL_SHOW is unverified and not used): P_MAIL_OPEN / P_MAIL_CLOSE.
--   * MAIL_INBOX_UPDATE -> a fresh header snapshot (only while the mailbox is shown; headers read with
--     the box closed are a stale cache, E-29) and P_MAIL_UPDATE { count }.
--   * Mail.Snapshot() / Mail.Previous(): the newest snapshot and the one BEFORE it, so 3b-2 can read
--     what a mail carried before it was taken (the mail disappears on take, E-34/E-39).
--
-- HEADER FIELDS (E-29, E-39): GetInboxHeaderInfo(i) = package icon, stationery, sender, subject, money,
-- COD amount, days left, item count (nil when none), was read, was returned, text created, can reply,
-- is GM, first item quantity, first item link. GetInboxInvoiceInfo(i) = type ('seller' | 'buyer' | nil),
-- item name, player, price, ?, deposit, house cut (E-34: 51 | 1 | 100 | 2 for a sale of 51).
-- Index 1 is the newest mail, so the index is not an identity: a fingerprint is stored instead.
--
-- Nothing here takes, deletes or marks mail; it only reads.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Mail.lua')

local Mail = {}
P.MailModule = Mail
P.Register('Mail', Mail)

Mail.POLL = 0.5
Mail.MAX_MAILS = 50

local open = false
local snapshot, previous = nil, nil
local cancelPoll = nil
Mail.stats = { opened = 0, closed = 0, updates = 0, staleUpdates = 0, snapshots = 0, unreadable = 0 }

local function clean(v)
  if P.IsSecret(v) then return nil end
  return v
end

local function str(v)
  v = clean(v)
  if type(v) == 'string' then return v end
  return nil
end

local function num(v)
  v = clean(v)
  if type(v) == 'number' and v == v then return v end
  return nil
end

--- True when MailFrame is shown; nil when the frame does not exist.
function Mail.FrameShown()
  local frame = P.env.MailFrame
  if type(frame) ~= 'table' or type(frame.IsShown) ~= 'function' then return nil end
  local ok, shown = pcall(frame.IsShown, frame)
  if not ok then return nil end
  return shown and true or false
end

local function readOne(i)
  local h = P.Call('GetInboxHeaderInfo', i)
  if not h then return nil end
  local entry = {
    index = i,
    sender = str(h[3]) or '', subject = str(h[4]) or '',
    money = num(h[5]) or 0, cod = num(h[6]) or 0,
    daysLeft = num(h[7]),
    itemCount = num(h[8]) or 0,
    textCreated = clean(h[11]) == true, canReply = clean(h[12]) == true,
    firstQty = num(h[14]), firstLink = str(h[15]),
  }
  entry.firstItemID = entry.firstLink and tonumber(entry.firstLink:match('item:(%d+)')) or nil
  local inv = P.Call('GetInboxInvoiceInfo', i)
  if inv and str(inv[1]) then
    entry.invoice = { kind = str(inv[1]), item = str(inv[2]), player = str(inv[3]),
                      price = num(inv[4]) or 0, deposit = num(inv[6]) or 0, cut = num(inv[7]) or 0 }
  end
  -- Auction House mail: separable from player mail by an invoice or by canReply=false with a text (E-29)
  entry.kind = (entry.invoice or (not entry.canReply and entry.textCreated)) and 'auction' or 'player'
  entry.fingerprint = table.concat({ entry.sender, entry.subject, entry.money, entry.cod, entry.itemCount,
                                     entry.firstItemID or 0, entry.firstQty or 0 }, '|')
  return entry
end

--- Reads every header (up to MAX_MAILS). Returns { count, mails = {...}, gt } or nil plus a reason.
function Mail.Read()
  local n = P.Call('GetInboxNumItems')
  local count = n and num(n[1]) or nil
  if not count then return nil, 'GetInboxNumItems unavailable' end
  local mails = {}
  for i = 1, math.min(count, Mail.MAX_MAILS) do
    local entry = readOne(i)
    if entry then mails[#mails + 1] = entry else Mail.stats.unreadable = Mail.stats.unreadable + 1 end
  end
  local _, gt = P.Now()
  return { count = count, mails = mails, gt = gt }
end

function Mail.Snapshot() return snapshot end
function Mail.Previous() return previous end
function Mail.IsOpen() return open end

local function setOpen(now)
  if now == open then return end
  open = now
  if now then
    Mail.stats.opened = Mail.stats.opened + 1
    P.Events.Emit('P_MAIL_OPEN', {})
  else
    Mail.stats.closed = Mail.stats.closed + 1
    P.Events.Emit('P_MAIL_CLOSE', {})
  end
end

--- One poll step (also called by tests).
function Mail.Tick()
  local shown = Mail.FrameShown()
  if shown == nil then return end
  setOpen(shown)
end

local function onUpdate()
  Mail.stats.updates = Mail.stats.updates + 1
  if Mail.FrameShown() ~= true then
    Mail.stats.staleUpdates = Mail.stats.staleUpdates + 1      -- cached view, not trusted (E-29)
    return 'dropped'
  end
  setOpen(true)
  local snap, err = Mail.Read()
  if not snap then
    P.Diag('warn', 'Mail', 'inbox unreadable: ' .. tostring(err))
    return 'dropped'
  end
  previous = snapshot
  snapshot = snap
  Mail.stats.snapshots = Mail.stats.snapshots + 1
  P.Events.Emit('P_MAIL_UPDATE', { count = snap.count })
end

function Mail.Start()
  if cancelPoll then cancelPoll() end
  cancelPoll = P.Every(Mail.POLL, Mail.Tick)
end

function Mail.Stop()
  if cancelPoll then cancelPoll(); cancelPoll = nil end
  open = false
end

function Mail.Reset()
  Mail.Stop()
  snapshot, previous = nil, nil
  Mail.stats = { opened = 0, closed = 0, updates = 0, staleUpdates = 0, snapshots = 0, unreadable = 0 }
end

Mail.OnUpdate = onUpdate

P.RegisterCollectAdapter({
  name = 'Mail',
  handlers = { MAIL_INBOX_UPDATE = function() return onUpdate() end },
  start = Mail.Start, stop = Mail.Stop,
})
]=====] },
{ path = "Platform/Auction.lua", src = [=====[
-- GoldIntel / Platform / Auction.lua                                    (Phase 3b-1)
--
-- Auction House adapter (context only).
--   * Window state by polling AuctionHouseFrame:IsShown() every 0.5 s while collecting (E-35): P_AH_OPEN
--     and P_AH_CLOSE.
--   * AUCTION_HOUSE_AUCTION_CREATED (approved D-074 A-1) -> P_AH_POSTED. E-36: it fires once per
--     posting, 0.358 s BEFORE the deposit leaves the balance. Its payload is not read.
-- Owned auctions are not readable passively (E-35) and nothing is queried here.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Auction.lua')

local Auction = {}
P.AuctionModule = Auction
P.Register('Auction', Auction)

Auction.POLL = 0.5
local open = false
local cancelPoll = nil
Auction.stats = { opened = 0, closed = 0, posted = 0 }

function Auction.FrameShown()
  local frame = P.env.AuctionHouseFrame
  if type(frame) ~= 'table' or type(frame.IsShown) ~= 'function' then return nil end
  local ok, shown = pcall(frame.IsShown, frame)
  if not ok then return nil end
  return shown and true or false
end

function Auction.IsOpen() return open end

function Auction.Tick()
  local shown = Auction.FrameShown()
  if shown == nil or shown == open then return end
  open = shown
  if shown then
    Auction.stats.opened = Auction.stats.opened + 1
    P.Events.Emit('P_AH_OPEN', {})
  else
    Auction.stats.closed = Auction.stats.closed + 1
    P.Events.Emit('P_AH_CLOSE', {})
  end
end

local function onCreated()
  Auction.stats.posted = Auction.stats.posted + 1
  P.Events.Emit('P_AH_POSTED', {})
end

function Auction.Start()
  if cancelPoll then cancelPoll() end
  cancelPoll = P.Every(Auction.POLL, Auction.Tick)
end

function Auction.Stop()
  if cancelPoll then cancelPoll(); cancelPoll = nil end
  open = false
end

function Auction.Reset()
  Auction.Stop()
  Auction.stats = { opened = 0, closed = 0, posted = 0 }
end

Auction.OnCreated = onCreated

P.RegisterCollectAdapter({
  name = 'Auction',
  handlers = { AUCTION_HOUSE_AUCTION_CREATED = function() return onCreated() end },
  start = Auction.Start, stop = Auction.Stop,
})
]=====] },
{ path = "Platform/Items.lua", src = [=====[
-- GoldIntel / Platform / Items.lua                                      (Phase 3b-1)
--
-- Item data adapter (E-17, E-30).
--   Items.Get(itemID) -> { status = 'ready' | 'pending' | 'secret' | 'invalid', name?, quality?,
--                          sellPrice?, classID?, subclassID?, bindType? }   (classID/subclassID: M2 evidence, 12th/13th returns)
--   An empty GetItemInfo is NEVER a price of 0 (D-045/D-046): the status says 'pending' and a load is
--   requested. GET_ITEM_INFO_RECEIVED(itemID, success) -> P_ITEM_INFO { itemID, ready }.
--   Items already cached produce no event, so callers check Items.Get first.
-- GetItemInfo order (E-30): name, link, quality, ilvl, minLevel, type, subtype, stack, equipLoc, icon,
-- SELL PRICE (11), classID, subclassID, BIND TYPE (14).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Items.lua')

local Items = {}
P.ItemsModule = Items
P.Register('Items', Items)

Items.stats = { lookups = 0, pending = 0, received = 0, failed = 0, secret = 0 }

function Items.Get(itemID)
  if type(itemID) ~= 'number' or itemID <= 0 or P.IsSecret(itemID) then return { status = 'invalid' } end
  Items.stats.lookups = Items.stats.lookups + 1
  local r
  if P.HasIn('C_Item', 'GetItemInfo') then r = P.CallIn('C_Item', 'GetItemInfo', itemID)
  else r = P.Call('GetItemInfo', itemID) end
  if not r or r[1] == nil then
    Items.stats.pending = Items.stats.pending + 1
    if P.HasIn('C_Item', 'RequestLoadItemDataByID') then P.CallIn('C_Item', 'RequestLoadItemDataByID', itemID) end
    return { status = 'pending' }
  end
  for i = 1, r.n do
    if P.IsSecret(r[i]) then
      Items.stats.secret = Items.stats.secret + 1
      return { status = 'secret' }
    end
  end
  return { status = 'ready', name = r[1], quality = r[3], sellPrice = r[11], classID = r[12], subclassID = r[13], bindType = r[14] }
end

local function onInfo(_, itemID, success)
  if type(itemID) ~= 'number' or P.IsSecret(itemID) or P.IsSecret(success) then return 'dropped' end
  Items.stats.received = Items.stats.received + 1
  if success ~= true then Items.stats.failed = Items.stats.failed + 1 end
  P.Events.Emit('P_ITEM_INFO', { itemID = itemID, ready = success == true })
end

Items.OnInfo = onInfo
function Items.Reset() Items.stats = { lookups = 0, pending = 0, received = 0, failed = 0, secret = 0 } end

P.RegisterCollectAdapter({ name = 'Items', handlers = { GET_ITEM_INFO_RECEIVED = onInfo } })
]=====] },
{ path = "Platform/Bags.lua", src = [=====[
-- GoldIntel / Platform / Bags.lua                                       (Phase 3b-1)
--
-- Bag adapter: BAG_UPDATE_DELAYED -> P_BAGS_SETTLED (E-32: it fires once after a change settles, 0.15 s
-- before and 0.289 s after the money event). Bags.Snapshot() is a read-only aggregate item id -> quantity
-- (C_Container.GetContainerItemInfo, E-17: the legacy globals do not exist). The diff logic that turns
-- two snapshots into lots belongs to 3b-3 (Collect/BagDiff.lua, Collect/ItemSources.lua); nothing here is stored.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Bags.lua')

local Bags = {}
P.BagsModule = Bags
P.Register('Bags', Bags)

Bags.FIRST_BAG, Bags.LAST_BAG = 0, 5     -- E-32 read bags 0 to 5 (52 slots); a bag index that does not exist reports 0 slots
Bags.RANGE_MAX = 8                       -- evidence only: Bags.Ranges() asks bag indexes 0..8 what they hold
Bags.stats = { settled = 0, snapshots = 0, unreadable = 0, incomplete = 0 }

--- Returns { items = { [itemID] = quantity }, slots = number read, complete = boolean, bags = { [bag] = slotCount } }
-- or nil plus a reason. complete == false when ANY slot or count could not be read (secret value): a quantity that is
-- not exactly known never counts as complete (BagDiff refuses incomplete snapshots, D-080 AC-14).
function Bags.Snapshot()
  if not P.HasIn('C_Container', 'GetContainerNumSlots') or not P.HasIn('C_Container', 'GetContainerItemInfo') then
    return nil, 'C_Container unavailable'
  end
  local items, read, bad, bags = {}, 0, 0, {}
  for bag = Bags.FIRST_BAG, Bags.LAST_BAG do
    local n = P.CallIn('C_Container', 'GetContainerNumSlots', bag)
    local slots = 0
    if n and type(n[1]) == 'number' and not P.IsSecret(n[1]) then slots = n[1]
    elseif n and n[1] ~= nil then bad = bad + 1 end
    bags[bag] = slots
    for slot = 1, slots do
      local r = P.CallIn('C_Container', 'GetContainerItemInfo', bag, slot)
      local info = r and r[1]
      if type(info) == 'table' then
        local id, count = info.itemID, info.stackCount
        if type(id) == 'number' and not P.IsSecret(id) then
          if type(count) ~= 'number' or P.IsSecret(count) then count = 1; bad = bad + 1 end
          items[id] = (items[id] or 0) + count
          read = read + 1
        else
          bad = bad + 1
        end
      end
    end
  end
  Bags.stats.snapshots = Bags.stats.snapshots + 1
  Bags.stats.unreadable = Bags.stats.unreadable + bad
  if bad > 0 then Bags.stats.incomplete = Bags.stats.incomplete + 1 end
  return { items = items, slots = read, complete = bad == 0, bags = bags }
end

--- Evidence (D-080 M2): the slot count of bag indexes 0..RANGE_MAX, plus the client constants that describe them.
function Bags.Ranges()
  local out = { slots = {}, constants = {} }
  for bag = 0, Bags.RANGE_MAX do
    local r = P.HasIn('C_Container', 'GetContainerNumSlots') and P.CallIn('C_Container', 'GetContainerNumSlots', bag) or nil
    local n = r and r[1]
    out.slots[bag] = (type(n) == 'number' and not P.IsSecret(n)) and n or nil
  end
  local env = P.env or {}
  for _, k in ipairs({ 'NUM_BAG_SLOTS', 'NUM_TOTAL_EQUIPPED_BAG_SLOTS', 'NUM_REAGENTBAG_SLOTS' }) do
    local v = env[k]
    if type(v) == 'number' then out.constants[k] = v end
  end
  return out
end

local function onSettled()
  Bags.stats.settled = Bags.stats.settled + 1
  P.Events.Emit('P_BAGS_SETTLED', {})
end

Bags.OnSettled = onSettled
function Bags.Reset() Bags.stats = { settled = 0, snapshots = 0, unreadable = 0, incomplete = 0 } end

P.RegisterCollectAdapter({ name = 'Bags', handlers = { BAG_UPDATE_DELAYED = function() return onSettled() end } })
]=====] },
{ path = "Platform/Map.lua", src = [=====[
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
]=====] },
{ path = "Platform/Money.lua", src = [=====[
-- GoldIntel / Platform / Money.lua                                      (Phase 1, task 1.4)
--
-- PURPOSE
--  The money signal that feeds the cash ledger (Requirements FR-LED-1).
--      Platform.Money() -> copper
--  Emits P_MONEY { copper = signed delta, gt = monotonic time, gap = true? }.
--
-- THE ONE RULE
--  The deltas emitted here, summed over any window, equal the real change of GetMoney()
--  over that window. Nothing is dropped and nothing is invented. The Reconciler (Phase 3)
--  relies on this to guarantee invariant 1 (Architecture section 3).
--
-- HOW
--  last = money at the previous emission. On PLAYER_MONEY: delta = GetMoney() - last.
--  Zero deltas are not emitted. The delta is computed from the live value, not from
--  event arguments, so coalesced or duplicated PLAYER_MONEY events cannot cause drift.
--
-- GAPS
--  If money changed while no PLAYER_MONEY event was seen (detected at
--  PLAYER_ENTERING_WORLD), the difference is emitted once with gap = true so downstream
--  code can tag it low-confidence instead of silently absorbing it into the next delta.
--
-- FATAL CONDITIONS (Decisions D-016)
--  GetMoney missing or PLAYER_MONEY not registrable disables the addon (capabilities
--  'money.get' and 'money.event').

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Money.lua')

local Money = {}
P.MoneyModule = Money
P.Register('Money', Money)

local last = nil
Money.stats = { events = 0, emitted = 0, zero = 0, gaps = 0, badReads = 0 }

--- Current copper, or nil plus a reason.
function Money.Get()
  local f = P.fn('GetMoney')
  if not f then return nil, 'GetMoney unavailable' end
  local ok, v = pcall(f)
  if not ok then return nil, 'GetMoney failed: ' .. tostring(v) end
  if P.IsSecret(v) then return nil, 'GetMoney returned a secret value' end
  if type(v) ~= 'number' or v ~= v or v < 0 then return nil, 'GetMoney returned an invalid value' end
  return math.floor(v)
end

--- Last balance this module has accounted for (nil before the baseline exists).
function Money.Last() return last end

local function emit(delta, isGap)
  local _, gt = P.Now()
  local payload = { copper = delta, gt = gt }
  if isGap then
    payload.gap = true
    Money.stats.gaps = Money.stats.gaps + 1
  end
  Money.stats.emitted = Money.stats.emitted + 1
  P.Events.Emit('P_MONEY', payload)
end

--- Sets the baseline. With emitGap, a difference to the previous balance is emitted as a gap.
function Money.Sync(emitGap)
  local now, err = Money.Get()
  if not now then
    Money.stats.badReads = Money.stats.badReads + 1
    P.Diag('error', 'Money', 'sync failed: ' .. tostring(err))
    return nil
  end
  if emitGap and last ~= nil and now ~= last then
    local delta = now - last
    last = now
    P.Diag('warn', 'Money', 'money changed without PLAYER_MONEY (gap of ' .. delta .. ' copper)')
    emit(delta, true)
  else
    last = now
  end
  return now
end

local function onMoney()
  Money.stats.events = Money.stats.events + 1
  local now, err = Money.Get()
  P.Events.ReportPayload('PLAYER_MONEY', now ~= nil, err)
  if not now then
    Money.stats.badReads = Money.stats.badReads + 1
    P.Diag('error', 'Money', 'PLAYER_MONEY with unreadable balance: ' .. tostring(err))
    return
  end
  if last == nil then
    -- Baseline missing (event before ready): adopt it; nothing can be attributed yet.
    last = now
    P.Diag('warn', 'Money', 'PLAYER_MONEY before baseline; baseline set to ' .. now)
    return
  end
  local delta = now - last
  if delta == 0 then
    Money.stats.zero = Money.stats.zero + 1
    return
  end
  last = now
  emit(delta, false)
end

Money.OnMoney = onMoney     -- exposed for tests

---------------------------------------------------------------------------
-- Wiring and capabilities
---------------------------------------------------------------------------

P.SetCap('money.get', P.fn('GetMoney') ~= nil, 'GetMoney')

local bound, bindErr = P.Events.Bind('PLAYER_MONEY', onMoney)
P.SetCap('money.event', bound, bound and 'PLAYER_MONEY' or bindErr)

P.Events.Bind('PLAYER_ENTERING_WORLD', function()
  Money.Sync(true)
end)

P.OnReady(function()
  Money.Sync(false)
end)

--- Test helper.
function Money.Reset()
  last = nil
  Money.stats = { events = 0, emitted = 0, zero = 0, gaps = 0, badReads = 0 }
end

-- Contract: Platform.Money() -> copper
P.Money = function() return Money.Get() end
]=====] },
{ path = "Platform/SavedVars.lua", src = [=====[
-- GoldIntel / Platform / SavedVars.lua                                  (Phase 2)
--
-- PURPOSE
--   The only access path to the SavedVariables globals (GoldIntelDB, GoldIntelCharDB).
--   Store and every other module above Platform/ must use this adapter, because WoW
--   globals may not be touched outside Platform/ (Requirements FR-PLT-1).
--
--   Platform.SavedVars.Account()   -> table, status
--   Platform.SavedVars.Character() -> table, status
--     status: 'existing' (the client restored a table), 'created' (nothing was there),
--             'replaced' (something that was not a table was there and was replaced).
--
-- TIMING
--   The client restores SavedVariables after an addon's files run and before ADDON_LOADED,
--   so these functions are safe from PLAYER_LOGIN onward (never at file-load time).
--
-- The table returned is the live global table. The client writes it to disk at logout or
-- reload; addons cannot force a write.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/SavedVars.lua')

local SV = {}
P.SavedVars = SV
P.Register('SavedVars', SV)

SV.NAMES = { account = 'GoldIntelDB', character = 'GoldIntelCharDB' }

local function ensure(kind)
  local name = SV.NAMES[kind]
  local value = P.env[name]
  if type(value) == 'table' then return value, 'existing' end
  local status = 'created'
  if value ~= nil then
    status = 'replaced'
    P.Diag('warn', 'SavedVars', name .. ' is not a table (was ' .. type(value) .. '); replaced by an empty table')
  end
  value = {}
  P.env[name] = value
  return value, status
end

--- The account-wide SavedVariables table (GoldIntelDB).
function SV.Account() return ensure('account') end

--- The per-character SavedVariables table (GoldIntelCharDB).
function SV.Character() return ensure('character') end
]=====] },
{ path = "Platform/Slash.lua", src = [=====[
-- GoldIntel / Platform / Slash.lua                                      (Phase 2)
--
-- PURPOSE
--   The only place that registers slash commands with the client (SlashCmdList and the
--   SLASH_<KEY>1 global). Core/Slash.lua builds the /gi command set on top of this.
--
--   Platform.RegisterSlash(key, command, handler) -> true | nil, err
--     key     : uppercase identifier, e.g. 'GOLDINTEL'
--     command : the typed command, e.g. '/gi'
--     handler : function(message)  (errors are caught and reported as diagnostics)
--
-- Re-registering the same key replaces the handler (used by tests and /reload-safe boot).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Slash.lua')

local Slash = {}
P.Slash = Slash
P.Register('Slash', Slash)

function Slash.Register(key, command, handler)
  if type(key) ~= 'string' or not key:match('^[A-Z0-9_]+$') then
    return nil, 'key must be an uppercase identifier'
  end
  if type(command) ~= 'string' or command:sub(1, 1) ~= '/' or #command < 2 then
    return nil, 'command must start with /'
  end
  if type(handler) ~= 'function' then return nil, 'handler must be a function' end
  local list = P.env.SlashCmdList
  if type(list) ~= 'table' then
    list = {}
    P.env.SlashCmdList = list
  end
  P.env['SLASH_' .. key .. '1'] = command
  list[key] = function(message)
    local ok, err = pcall(handler, message)
    if not ok then P.Diag('error', 'Slash', command .. ' handler failed: ' .. tostring(err)) end
  end
  return true
end

P.RegisterSlash = Slash.Register
]=====] },
{ path = "Platform/Probe.lua", src = [=====[
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
]=====] },
{ path = "Core/Core.lua", src = [=====[
-- GoldIntel / Core / Core.lua                                           (Phase 2)
--
-- PURPOSE
--   The application core above the Platform layer:
--     * module registry and lifecycle   (Core.Module, Core.Start, Core.Stop)
--     * service registry                (Core.Service, Core.GetService)
--     * startup orchestration           (Store -> Config -> Capabilities -> commands -> modules)
--
--   Core never calls a WoW API. Everything it needs comes through Platform/.
--
-- MODULES
--   Core.Module(name, def) registers a module and returns def (the module's own table).
--   def fields (all optional):
--     deps         : array of module or service names that must be available first
--     OnInitialize : function(def)  called once, in dependency order
--     OnEnable     : function(def)  called after every module initialized, dependency order
--     OnDisable    : function(def)  called by Core.Stop in reverse order
--     OnLogout     : function(def)  called by Core.Stop('logout') in reverse order
--     stub         : true for placeholder modules that implement nothing (Future/)
--   States: registered, initialized, enabled, failed, disabled (a dependency did not enable).
--   A failing module never prevents other modules from starting.
--
-- ORDER OF STARTUP (Core.Start)
--   1. Store.Open     (SavedVariables, schema, migrations; never throws) and Store.Char
--   2. Config.Load    (validates persisted settings)
--   3. Capabilities   (import Platform capabilities, subscribe to changes)
--   4. Bridges        (Platform diagnostics and capability changes onto the Bus)
--   5. /gi commands
--   6. Modules        (initialize all, then enable all)
--   7. CORE_READY
--   The platform may be non-operational (a fatal capability is missing): Core then installs
--   only the minimal command set and starts nothing else.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Core/Core.lua')

local Core = {}
GI.Core = Core
Core.VERSION = P.VERSION
Core.state = 'loaded'          -- loaded | starting | ready | stopped | platform-failed

local modules = {}             -- name -> record
local order = {}               -- registration order
local services = {}

---------------------------------------------------------------------------
-- Services
---------------------------------------------------------------------------

--- Registers a named service (any value). Services satisfy module dependencies immediately.
function Core.Service(name, impl)
  if type(name) ~= 'string' or name == '' then return nil, 'service name must be a non-empty string' end
  if services[name] ~= nil then return nil, 'duplicate service ' .. name end
  if impl == nil then return nil, 'service ' .. name .. ' has no implementation' end
  services[name] = impl
  return impl
end

function Core.GetService(name) return services[name] end

---------------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------------

local function setState(rec, state, reason)
  rec.state = state
  rec.reason = reason
  if GI.Bus then
    GI.Bus.Fire('MODULE_STATE', { name = rec.name, state = state, reason = reason })
  end
end

--- Registers a module. Returns the module table (def, or a new table), or nil plus an error.
function Core.Module(name, def)
  if type(name) ~= 'string' or name == '' then return nil, 'module name must be a non-empty string' end
  if modules[name] then return nil, 'duplicate module ' .. name end
  if def ~= nil and type(def) ~= 'table' then return nil, 'module definition must be a table' end
  def = def or {}
  if def.deps ~= nil and type(def.deps) ~= 'table' then return nil, 'deps must be an array of names' end
  if Core.state ~= 'loaded' then
    P.Diag('warn', 'Core', 'module ' .. name .. ' registered after Core.Start; it will not be started')
  end
  local rec = { name = name, def = def, state = 'registered', index = #order + 1 }
  modules[name] = rec
  order[#order + 1] = name
  return def
end

function Core.GetModule(name)
  local rec = modules[name]
  return rec and rec.def or nil
end

function Core.ModuleState(name)
  local rec = modules[name]
  if not rec then return nil end
  return rec.state, rec.reason
end

--- List of { name, state, reason, stub } in registration order.
function Core.Modules()
  local out = {}
  for i = 1, #order do
    local rec = modules[order[i]]
    out[#out + 1] = { name = rec.name, state = rec.state, reason = rec.reason, stub = rec.def.stub and true or false }
  end
  return out
end

-- Dependency order (Kahn). Returns the ordered names and a table of names that are in a cycle.
local function plan()
  local indegree, dependents = {}, {}
  for i = 1, #order do
    local name = order[i]
    indegree[name] = 0
    dependents[name] = {}
  end
  for i = 1, #order do
    local name = order[i]
    local deps = modules[name].def.deps or {}
    for j = 1, #deps do
      local dep = deps[j]
      if modules[dep] then
        indegree[name] = indegree[name] + 1
        dependents[dep][#dependents[dep] + 1] = name
      end
    end
  end
  local queue, sorted = {}, {}
  for i = 1, #order do
    if indegree[order[i]] == 0 then queue[#queue + 1] = order[i] end
  end
  local head = 1
  while head <= #queue do
    local name = queue[head]
    head = head + 1
    sorted[#sorted + 1] = name
    local list = dependents[name]
    for i = 1, #list do
      local dependent = list[i]
      indegree[dependent] = indegree[dependent] - 1
      if indegree[dependent] == 0 then queue[#queue + 1] = dependent end
    end
  end
  local cyclic = {}
  if #sorted < #order then
    local done = {}
    for i = 1, #sorted do done[sorted[i]] = true end
    for i = 1, #order do
      if not done[order[i]] then cyclic[order[i]] = true end
    end
  end
  return sorted, cyclic
end

local function call(rec, hook)
  local fn = rec.def[hook]
  if type(fn) ~= 'function' then return true end
  local ok, err = pcall(fn, rec.def)
  if not ok then
    P.Diag('error', 'Core', 'module ' .. rec.name .. ' ' .. hook .. ' failed: ' .. tostring(err))
    return false, tostring(err)
  end
  return true
end

local function dependencyProblem(rec, wantState)
  local deps = rec.def.deps or {}
  for i = 1, #deps do
    local dep = deps[i]
    local other = modules[dep]
    if other then
      if other.state ~= wantState and other.state ~= 'enabled' then
        return dep .. ' is ' .. other.state
      end
    elseif services[dep] == nil then
      return 'missing dependency ' .. dep
    end
  end
  return nil
end

local function startModules()
  local sorted, cyclic = plan()
  for i = 1, #order do
    local rec = modules[order[i]]
    if cyclic[rec.name] then setState(rec, 'failed', 'dependency cycle') end
  end
  -- pass 1: initialize
  for i = 1, #sorted do
    local rec = modules[sorted[i]]
    local problem = dependencyProblem(rec, 'initialized')
    if problem then
      setState(rec, 'disabled', problem)
    else
      local ok, err = call(rec, 'OnInitialize')
      if ok then setState(rec, 'initialized') else setState(rec, 'failed', 'OnInitialize: ' .. tostring(err)) end
    end
  end
  -- pass 2: enable
  for i = 1, #sorted do
    local rec = modules[sorted[i]]
    if rec.state == 'initialized' then
      local problem = dependencyProblem(rec, 'enabled')
      if problem then
        setState(rec, 'disabled', problem)
      else
        local ok, err = call(rec, 'OnEnable')
        if ok then setState(rec, 'enabled') else setState(rec, 'failed', 'OnEnable: ' .. tostring(err)) end
      end
    end
  end
  return sorted
end

local function onLogout()
  Core.Stop('logout')
end

---------------------------------------------------------------------------
-- Start and stop
---------------------------------------------------------------------------

--- Runs the startup sequence. Returns true, or false plus a reason. Safe to call once.
function Core.Start()
  if Core.state == 'starting' or Core.state == 'ready' then return false, 'already ' .. Core.state end
  Core.state = 'starting'

  if not P.IsOperational() then
    Core.state = 'platform-failed'
    if GI.Commands then GI.Commands.Install(true) end
    P.Diag('error', 'Core', 'platform is not operational; Core started in minimal mode')
    return false, 'platform not operational'
  end

  local store = GI.Store
  if store then
    store.Open()
    store.Char()          -- create/validate the per-character table so the file has its structure from day one
  end
  if GI.Config then GI.Config.Load() end
  if GI.Capabilities then GI.Capabilities.Attach() end

  -- Bridges: Platform diagnostics and capability changes become Bus events (Contracts F3).
  local bus = GI.Bus
  if bus then
    local inSink = false
    P.SetDiagSink(function(entry)
      if inSink then return end          -- a failing DIAG handler must not recurse
      inSink = true
      bus.Fire('DIAG', entry)
      inSink = false
    end)
    P.WatchCaps(function(cap, value, previous)
      bus.Fire('COMPAT_CHANGED', { cap = cap, available = value, previous = previous })
    end)
  end

  P.On('P_LOGOUT', onLogout)
  if GI.Commands then GI.Commands.Install(false) end

  startModules()
  Core.state = 'ready'
  if bus then bus.Fire('CORE_READY', { modules = #order }) end
  return true
end

--- Stops modules in reverse order. reason 'logout' calls OnLogout, anything else OnDisable.
-- Idempotent. SavedVariables are written by the client; Core only makes sure the in-memory
-- tables are up to date (runtime snapshot, checkpoint marker).
function Core.Stop(reason)
  if Core.state ~= 'ready' then return false, 'not running' end
  reason = reason or 'stop'
  if GI.Bus then GI.Bus.Fire('CORE_STOPPING', { reason = reason }) end
  local hook = (reason == 'logout') and 'OnLogout' or 'OnDisable'
  for i = #order, 1, -1 do
    local rec = modules[order[i]]
    if rec.state == 'enabled' then
      call(rec, hook)
      if hook == 'OnDisable' then setState(rec, 'disabled', reason) end
    end
  end
  if GI.Capabilities then GI.Capabilities.Persist(reason) end
  if GI.Store then GI.Store.Checkpoint({ silent = true }) end
  Core.state = 'stopped'
  return true
end

--- Summary for /gi status and diagnostics.
function Core.Describe()
  local counts = { total = #order, enabled = 0, failed = 0, disabled = 0, stub = 0 }
  for i = 1, #order do
    local rec = modules[order[i]]
    if rec.state == 'enabled' then counts.enabled = counts.enabled + 1 end
    if rec.state == 'failed' then counts.failed = counts.failed + 1 end
    if rec.state == 'disabled' then counts.disabled = counts.disabled + 1 end
    if rec.def.stub then counts.stub = counts.stub + 1 end
  end
  counts.state = Core.state
  return counts
end

P.Register('Core', Core)
]=====] },
{ path = "Core/Bus.lua", src = [=====[
-- GoldIntel / Core / Bus.lua                                            (Phase 2)
--
-- PURPOSE
--   The internal event bus (Contracts F3). Modules talk through the bus and through
--   published interfaces, never by reaching into each other's tables.
--
--   Bus.On(event, fn) -> fn | nil, err        subscribe (idempotent per event+fn)
--   Bus.Off(event, fn) -> boolean
--   Bus.Fire(event, payload) -> number        handlers invoked
--   Bus.Define(event, spec, opts)             declare an event (modules add their own)
--   Bus.Info(event) -> { reserved, spec }
--
-- SAFETY
--   * Handlers run under pcall; one failing handler never blocks the others.
--   * Adding or removing handlers while an event is firing is safe.
--   * Payloads are validated against the declared spec when Bus.validate is true (debug).
--   * Firing an undeclared event is an error (returns 0), so typos cannot go unnoticed.
--
-- RESERVED EVENTS
--   Events for later phases are declared now so the vocabulary is stable, but no Phase 2
--   code fires them. Their payload shapes are provisional until their phase (Contracts F3).
--   The money pipeline keeps four separate stages (Decisions D-035):
--     BALANCE_OBSERVED -> TRANSACTION_DETECTED -> ATTRIBUTION_ASSIGNED -> RECONCILIATION_COMPLETE

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Core/Bus.lua')

local Bus = {}
GI.Bus = Bus
Bus.validate = false

local events = {}      -- name -> { spec, reserved }
local handlers = {}
local depth = {}
local dirty = {}

local function validatePayload(spec, payload)
  if type(payload) ~= 'table' then return false, 'payload must be a table' end
  for field, want in pairs(spec) do
    local optional = want:sub(-1) == '?'
    local typeName = optional and want:sub(1, -2) or want
    local v = payload[field]
    if v == nil then
      if not optional then return false, 'missing field ' .. field end
    elseif typeName ~= 'any' and type(v) ~= typeName then
      return false, 'field ' .. field .. ' must be ' .. typeName .. ', got ' .. type(v)
    end
  end
  return true
end

--- Declares an event. opts.reserved marks a placeholder for a later phase.
function Bus.Define(name, spec, opts)
  if type(name) ~= 'string' or name == '' then return nil, 'event name must be a non-empty string' end
  if events[name] then return nil, 'event already defined: ' .. name end
  if type(spec) ~= 'table' then return nil, 'spec must be a table' end
  for field, want in pairs(spec) do
    if type(field) ~= 'string' or type(want) ~= 'string' or not want:match('^%a+%??$') then
      return nil, 'malformed spec entry ' .. tostring(field)
    end
  end
  events[name] = { spec = spec, reserved = (opts and opts.reserved) and true or false }
  return true
end

function Bus.Info(name)
  local e = events[name]
  if not e then return nil end
  return { reserved = e.reserved, spec = e.spec }
end

--- Sorted names of every declared event.
function Bus.Names()
  local out = {}
  for name in pairs(events) do out[#out + 1] = name end
  table.sort(out)
  return out
end

function Bus.On(name, fn)
  if type(name) ~= 'string' or not events[name] then return nil, 'unknown event ' .. tostring(name) end
  if type(fn) ~= 'function' then return nil, 'handler must be a function' end
  local list = handlers[name]
  if not list then
    list = {}
    handlers[name] = list
  end
  for i = 1, #list do
    if list[i] == fn then return fn end
  end
  list[#list + 1] = fn
  return fn
end

function Bus.Off(name, fn)
  local list = handlers[name]
  if not list then return false end
  for i = 1, #list do
    if list[i] == fn then
      if (depth[name] or 0) > 0 then
        list[i] = false
        dirty[name] = true
      else
        table.remove(list, i)
      end
      return true
    end
  end
  return false
end

function Bus.HandlerCount(name)
  local list = handlers[name]
  if not list then return 0 end
  local n = 0
  for i = 1, #list do
    if list[i] then n = n + 1 end
  end
  return n
end

function Bus.Fire(name, payload)
  local e = events[name]
  if not e then
    P.Diag('error', 'Bus', 'fire of undeclared event ' .. tostring(name))
    return 0
  end
  if payload == nil then payload = {} end
  if Bus.validate then
    local ok, why = validatePayload(e.spec, payload)
    if not ok then
      P.Diag('error', 'Bus', 'invalid payload for ' .. name .. ': ' .. tostring(why))
      if Bus.validate == 'strict' then return 0 end
    end
  end
  local list = handlers[name]
  if not list then return 0 end

  depth[name] = (depth[name] or 0) + 1
  local n = #list
  local invoked = 0
  for i = 1, n do
    local fn = list[i]
    if fn then
      invoked = invoked + 1
      local ok, err = pcall(fn, payload)
      if not ok then
        -- Reporting a DIAG handler failure as a diagnostic would loop; Core guards the sink.
        P.Diag('error', 'Bus', 'handler for ' .. name .. ' failed: ' .. tostring(err))
      end
    end
  end
  depth[name] = depth[name] - 1
  if depth[name] == 0 and dirty[name] then
    dirty[name] = nil
    for i = #list, 1, -1 do
      if not list[i] then table.remove(list, i) end
    end
  end
  return invoked
end

---------------------------------------------------------------------------
-- Declared events (Contracts F3)
---------------------------------------------------------------------------

local ACTIVE = {
  DIAG                     = { level = 'string', module = 'string', msg = 'string', t = 'number' },
  COMPAT_CHANGED           = { cap = 'string', available = 'boolean', previous = 'boolean?' },
  CAPABILITY_STAGE_CHANGED = { cap = 'string', stage = 'string', value = 'boolean?', previous = 'boolean?',
                               note = 'string?', level = 'string' },
  CORE_READY               = { modules = 'number' },
  CORE_STOPPING            = { reason = 'string' },
  MODULE_STATE             = { name = 'string', state = 'string', reason = 'string?' },
  STORE_OPENED             = { state = 'string', schema = 'number', writable = 'boolean' },
  STORE_MIGRATED           = { from = 'number', to = 'number' },
  STORE_DEGRADED           = { reason = 'string' },
  CONFIG_CHANGED           = { key = 'string', value = 'any?', previous = 'any?', source = 'string' },
  CONTEXT_CHANGED          = { kind = 'string', open = 'boolean', id = 'number?' },   -- Contracts F3b
}
for name, spec in pairs(ACTIVE) do Bus.Define(name, spec) end

-- Reserved for later phases. Provisional shapes: nothing is enforced yet.
local RESERVED = {
  'BALANCE_OBSERVED', 'TRANSACTION_DETECTED', 'ATTRIBUTION_ASSIGNED', 'RECONCILIATION_COMPLETE',
  'LEDGER_CASH', 'LEDGER_LOT', 'ACTIVITY_CHANGED', 'SEGMENT_OPENED', 'SEGMENT_CLOSED',
  'SESSION_STARTED', 'SESSION_STOPPED', 'PRICES_UPDATED', 'HEAT_UPDATED',
}
for i = 1, #RESERVED do Bus.Define(RESERVED[i], {}, { reserved = true }) end

if GI.Core then GI.Core.Service('bus', Bus) end
]=====] },
{ path = "Core/Capabilities.lua", src = [=====[
-- GoldIntel / Core / Capabilities.lua                                   (Phase 2)
--
-- PURPOSE
--   The capability STAGE model (Decisions D-034, external review finding 1). The Platform
--   registry answers 'is this API there?' with one boolean. For events that is not enough:
--   a valid name is not a registered event, a registered event is not a delivered event,
--   and a delivered event does not guarantee a usable payload.
--
--   EVENT capabilities (name 'event.<WOW_EVENT>') have four stages, each true / false / nil:
--     valid          the client reports the event name valid (C_EventUtils.IsEventValid)
--     registered     RegisterEvent took effect (verified with IsEventRegistered); nil = could not verify;
--                    false = refused or blocked
--     delivered      the event was observed reaching GoldIntel at least once.
--                    Only ever true or nil: 'not seen yet' is NOT 'not delivered'
--     payloadUsable  the module that reads the payload (or the value derived from it) found it
--                    readable and of the expected type (not a secret value); true or false
--   API capabilities (every other name) have one stage: present (true / false / nil = unknown).
--
--   Level(name) returns the highest PROVEN level:
--     events: invalid | blocked | payloadUnusable | payloadUsable | delivered | registered | valid | unknown
--     api   : present | absent | unknown
--   Only 'payloadUsable' means a design may depend on the event. Phase 2 makes no such
--   decision; the model exists so Phase 3 cannot assume delivery (review finding 6).
--
-- DATA FLOW
--   Platform.SetCap / Platform.Events.WatchStage / Events.ReportPayload  ->  Capabilities.Set
--   Set fires CAPABILITY_STAGE_CHANGED on the Bus and schedules a throttled snapshot into
--   GoldIntelDB.runtime so the SavedVariables file carries live evidence (capability stages,
--   event statistics and the last 100 lines GoldIntel printed, so output never has to be copied
--   out of the chat window).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Core/Capabilities.lua')

local Caps = {}
GI.Capabilities = Caps

local STAGES = {
  event = { 'valid', 'registered', 'delivered', 'payloadUsable' },
  api = { 'present' },
}
Caps.STAGES = STAGES

local records = {}
local attached = false
local persistScheduled = false
Caps.PERSIST_DELAY = 5
Caps.OUTPUT_LINES = 100
Caps.HISTORY_ROWS = 10             -- one-line summaries of earlier sessions (D-041)
Caps.RECORD_MAX_BYTES = 12000      -- cap for runtime.previous and runtime.pinned (output lines are trimmed oldest first)

local function kindOf(name)
  if name:sub(1, 6) == 'event.' then return 'event' end
  return 'api'
end

local function stageAllowed(kind, stage)
  local list = STAGES[kind]
  for i = 1, #list do
    if list[i] == stage then return true end
  end
  return false
end

local function bare(name) return name:sub(7) end

---------------------------------------------------------------------------
-- Levels
---------------------------------------------------------------------------

function Caps.Level(name)
  local rec = records[name]
  if not rec then return 'unknown' end
  local s = rec.stages
  if rec.kind == 'api' then
    if s.present == true then return 'present' end
    if s.present == false then return 'absent' end
    return 'unknown'
  end
  if s.valid == false then return 'invalid' end
  if s.registered == false and s.delivered ~= true then return 'blocked' end   -- delivery proves it works
  if s.payloadUsable == false then return 'payloadUnusable' end
  if s.payloadUsable == true and s.delivered == true then return 'payloadUsable' end
  if s.delivered == true then return 'delivered' end
  if s.registered == true then return 'registered' end
  if s.valid == true then return 'valid' end
  return 'unknown'
end

--- True only when a design may depend on the capability (events: payloadUsable).
function Caps.Usable(name)
  local level = Caps.Level(name)
  return level == 'payloadUsable' or level == 'present'
end

---------------------------------------------------------------------------
-- Setting stages
---------------------------------------------------------------------------

local function schedulePersist()
  if persistScheduled then return end
  if not P.After then return end
  local cancel = P.After(Caps.PERSIST_DELAY, function()
    persistScheduled = false
    Caps.Persist()
  end)
  if cancel then persistScheduled = true end
end

--- Records one stage. value: true, false or nil. Returns true when something changed.
function Caps.Set(name, stage, value, note)
  if type(name) ~= 'string' or name == '' then return nil, 'capability name must be a non-empty string' end
  local kind = kindOf(name)
  if not stageAllowed(kind, stage) then return nil, 'stage ' .. tostring(stage) .. ' is not valid for a ' .. kind .. ' capability' end
  if value ~= nil and type(value) ~= 'boolean' then return nil, 'value must be true, false or nil' end
  if kind == 'event' and stage == 'delivered' and value == false then
    return nil, 'delivered is never false: not observed yet is not the same as not delivered'
  end
  local rec = records[name]
  if not rec then
    rec = { kind = kind, stages = {}, notes = {} }
    records[name] = rec
  end
  local previous = rec.stages[stage]
  local noteChanged = note ~= nil and rec.notes[stage] ~= note
  if note ~= nil then rec.notes[stage] = note end
  if previous == value then return false end
  rec.stages[stage] = value
  if GI.Bus then
    GI.Bus.Fire('CAPABILITY_STAGE_CHANGED', {
      cap = name, stage = stage, value = value, previous = previous, note = note, level = Caps.Level(name),
    })
  end
  schedulePersist()
  return true
end

function Caps.Stage(name, stage)
  local rec = records[name]
  if not rec then return nil end
  return rec.stages[stage]      -- may legitimately be false
end

--- Copy of one capability: { kind, level, stages = {...}, notes = {...} } or nil.
function Caps.Get(name)
  local rec = records[name]
  if not rec then return nil end
  return { kind = rec.kind, level = Caps.Level(name), stages = P.Util.shallowCopy(rec.stages),
           notes = P.Util.shallowCopy(rec.notes) }
end

--- Sorted capability names, optionally only 'event' or 'api'.
function Caps.Names(kind)
  local out = {}
  for name, rec in pairs(records) do
    if not kind or rec.kind == kind then out[#out + 1] = name end
  end
  table.sort(out)
  return out
end

--- Counts per level, per kind.
function Caps.Summary()
  local out = { event = {}, api = {} }
  for name, rec in pairs(records) do
    local level = Caps.Level(name)
    out[rec.kind][level] = (out[rec.kind][level] or 0) + 1
  end
  return out
end

---------------------------------------------------------------------------
-- Integration with the Platform
---------------------------------------------------------------------------

local function syncEvent(event)
  local name = 'event.' .. event
  Caps.Set(name, 'valid', P.EventNameValid(event))
  local stats = P.Events.Stats(event)
  if P.RESTRICTED_EVENTS[event] then
    Caps.Set(name, 'registered', false, 'restricted event, never registered')
  elseif stats.registered ~= nil then
    Caps.Set(name, 'registered', stats.registered)
  end
  if stats.delivered > 0 then Caps.Set(name, 'delivered', true) end
  if stats.payloadUsable ~= nil then Caps.Set(name, 'payloadUsable', stats.payloadUsable) end
end

--- Imports everything the Platform knows now. Safe to call again.
function Caps.Import()
  local platformCaps = P.Capabilities()
  for cap, value in pairs(platformCaps) do
    if cap:sub(1, 6) == 'event.' then
      syncEvent(bare(cap))
      local note = P.CapNote(cap)
      if value == false and note and records[cap] and records[cap].stages.registered == nil then
        Caps.Set(cap, 'registered', false, note)
      end
    else
      Caps.Set(cap, 'present', value, P.CapNote(cap))
    end
  end
  for _, event in ipairs(P.Events.BoundEvents()) do syncEvent(event) end
  local probe = P.ProbeModule and P.ProbeModule.last
  if probe and probe.status then
    for cap, status in pairs(probe.status) do
      if status == 'unknown' then Caps.Set(cap, 'present', nil, probe.notes[cap]) end
    end
  end
end

--- Imports the current state and subscribes to Platform changes. Idempotent.
function Caps.Attach()
  Caps.Import()
  if attached then return false end
  attached = true
  P.WatchCaps(function(cap, value)
    if cap:sub(1, 6) == 'event.' then
      syncEvent(bare(cap))
    else
      Caps.Set(cap, 'present', value, P.CapNote(cap))
    end
  end)
  P.Events.WatchStage(function(event, stage, value, note)
    Caps.Set('event.' .. event, stage, value, note)
  end)
  return true
end

---------------------------------------------------------------------------
-- Snapshot and persistence (evidence for the SavedVariables file)
---------------------------------------------------------------------------

--- Plain-data snapshot: { [name] = { level = ..., <stage> = bool, ... } } (unknown stages omitted).
function Caps.Snapshot()
  local out = {}
  for name, rec in pairs(records) do
    local entry = { level = Caps.Level(name) }
    for stage, value in pairs(rec.stages) do entry[stage] = value end
    out[name] = entry
  end
  return out
end

---------------------------------------------------------------------------
-- Session records (D-041). Diagnostic evidence ONLY: bounded, never raw game events.
--   runtime            = the CURRENT session (written by Persist)
--   runtime.previous   = the record that was current when this session opened (compacted)
--   runtime.history    = at most HISTORY_ROWS one-line summaries of earlier sessions
--   runtime.pinned     = a record the user asked to keep (/gi checkpoint pin)
---------------------------------------------------------------------------

local rotated = false

-- "name=level;name=level" in sorted order: the full capability tables are not kept for old sessions.
local function digest(capabilities)
  if type(capabilities) ~= 'table' then return nil end
  local names = {}
  for name in pairs(capabilities) do names[#names + 1] = name end
  table.sort(names)
  local parts = {}
  for _, name in ipairs(names) do
    local entry = capabilities[name]
    parts[#parts + 1] = name .. '=' .. tostring(type(entry) == 'table' and entry.level or '?')
  end
  return table.concat(parts, ';')
end

local function outputBytes(lines)
  local n = 0
  for i = 1, #lines do n = n + #tostring(lines[i]) + 4 end
  return n
end

-- Compact copy of a runtime record. Never aliases the source tables.
local function compact(rec, build)
  local out = {
    sessionStart = rec.sessionStart,
    generatedAt = rec.generatedAt,
    generatedGT = rec.generatedGT,
    addonVersion = rec.addonVersion,
    build = build,
    eventStats = P.Util.deepCopy(rec.eventStats or {}),
    outputTotal = rec.outputTotal,
    capDigest = digest(rec.capabilities) or rec.capDigest,
    endedBy = rec.endedBy or 'unknown',
  }
  if type(rec.generatedAt) == 'number' and type(rec.sessionStart) == 'number' then
    out.durationSec = math.max(0, rec.generatedAt - rec.sessionStart)
  end
  local lines = {}
  if type(rec.output) == 'table' then
    for i = 1, #rec.output do lines[#lines + 1] = tostring(rec.output[i]) end
  end
  while #lines > 0 and outputBytes(lines) > Caps.RECORD_MAX_BYTES do table.remove(lines, 1) end
  out.output = lines
  return out
end

local function summaryRow(rec)
  local delivered = {}
  for event, s in pairs(rec.eventStats or {}) do
    if type(s) == 'table' and (s.delivered or 0) > 0 then delivered[event] = s.delivered end
  end
  return {
    sessionStart = rec.sessionStart,
    durationSec = rec.durationSec,
    build = rec.build,
    addonVersion = rec.addonVersion,
    endedBy = rec.endedBy,
    lines = rec.outputTotal,
    delivered = delivered,
  }
end

local function currentBuild()
  local store = GI.Store
  local compat = store and store.Section and store.Section('compat')
  return type(compat) == 'table' and compat.build or nil
end

-- Runs once per open, before the first overwrite of the loaded record. A failure is reported
-- and never raises; it costs only the previous session's record (runtime is evidence, not data).
local function rotate(runtime)
  if rotated then return end
  local now = (P.Now())
  rotated = true
  if type(runtime.generatedAt) == 'number' then
    local ok, err = pcall(function()
      local prev = compact(runtime, runtime.build or currentBuild())
      local history = type(runtime.history) == 'table' and runtime.history or {}
      history[#history + 1] = summaryRow(prev)
      while #history > Caps.HISTORY_ROWS do table.remove(history, 1) end
      runtime.previous = prev          -- assigned last: nothing above has touched runtime
      runtime.history = history
    end)
    if not ok then
      P.Diag('warn', 'Capabilities', 'session record rotation failed (the previous session record is lost; nothing else is affected): ' .. tostring(err))
    end
  end
  runtime.sessionStart = now
  runtime.endedBy = nil
end

--- Writes the snapshot, event statistics and a timestamp into GoldIntelDB.runtime.
--- reason 'logout' marks the record as ended by a logout or reload (a crash writes nothing).
function Caps.Persist(reason)
  local store = GI.Store
  if not store or not store.IsOpen() then return false end
  local runtime = store.Section('runtime')
  if not runtime then return false end
  local t, gt = P.Now()
  rotate(runtime)
  runtime.capabilities = Caps.Snapshot()
  local stats = {}
  for _, event in ipairs(P.Events.BoundEvents()) do
    local s = P.Events.Stats(event)
    stats[event] = { delivered = s.delivered, firstGT = s.firstGT, lastGT = s.lastGT }
  end
  runtime.eventStats = stats
  runtime.generatedAt = t
  runtime.generatedGT = gt
  runtime.addonVersion = P.VERSION
  runtime.build = currentBuild()
  runtime.endedBy = (reason == 'logout') and 'logout-or-reload' or nil
  runtime.output = P.GetOutput(Caps.OUTPUT_LINES)     -- what GoldIntel told the user (chat lines)
  runtime.outputTotal = P.OutputCount()
  return true
end

--- Keeps a copy of the current record until it is replaced or cleared. Returns true or nil, reason.
function Caps.Pin()
  local store = GI.Store
  if not store or not store.IsOpen() or not store.IsWritable() then return nil, 'the saved database is not writable' end
  if not Caps.Persist() then return nil, 'nothing to pin' end
  local runtime = store.Section('runtime')
  local rec = compact(runtime, runtime.build)
  rec.pinnedAt = (P.Now())
  runtime.pinned = rec
  return true
end

--- Removes the pinned record. Returns true when there was one.
function Caps.Unpin()
  local store = GI.Store
  if not store or not store.IsOpen() or not store.IsWritable() then return nil, 'the saved database is not writable' end
  local runtime = store.Section('runtime')
  if not runtime or runtime.pinned == nil then return false end
  runtime.pinned = nil
  return true
end

--- Read-only view of the kept records: { previous = table|nil, pinned = table|nil, history = list }.
function Caps.Records()
  local store = GI.Store
  local runtime = store and store.IsOpen() and store.Section('runtime') or nil
  if not runtime then return { history = {} } end
  if store.IsWritable() then rotate(runtime) end     -- a read right after login must already see 'previous'
  return { previous = runtime.previous, pinned = runtime.pinned, history = runtime.history or {} }
end

--- Schedules a throttled snapshot (used after every command so its output reaches the saved data).
function Caps.Touch()
  schedulePersist()
end

--- Test helper: forget everything and detach.
function Caps.Reset()
  records = {}
  attached = false
  persistScheduled = false
  rotated = false
end

if GI.Core then GI.Core.Service('capabilities', Caps) end
]=====] },
{ path = "Core/Config.lua", src = [=====[
-- GoldIntel / Core / Config.lua                                         (Phase 2)
--
-- PURPOSE
--   The configuration framework. Every setting is DEFINED once with a type, a default and
--   limits; values live in the persisted profile (GoldIntelDB.profile, dotted keys map to
--   nested tables, e.g. 'prune.days' -> profile.prune.days) and are always validated.
--
--   Config.Define(key, spec)        declare a setting (modules declare their own later)
--   Config.Get(key)                 -> value (the default when unset or invalid)
--   Config.Set(key, value, source)  -> true, persisted | nil, err
--   Config.Parse(key, text)         -> typed value | nil, err   (used by /gi config set)
--   Config.Reset(key) / ResetAll()
--   Config.Load()                   validates persisted values at startup
--   Config.List()                   -> sorted array of setting descriptions
--
--   spec: { type = 'number'|'boolean'|'string'|'enum', default = ..., min, max, integer,
--           values (enum), maxLength (string), readonly, help }
--
-- BEHAVIOR
--   * Invalid persisted values are ignored (the default applies) and reported at Load.
--   * Unknown keys already in the profile are preserved untouched (forward compatibility).
--   * Writes go to the live profile table. If the Store is read-only or degraded, the value
--     is kept for this session only and Set reports persisted = false.
--   * Every change fires CONFIG_CHANGED on the Bus.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Core/Config.lua')

local Config = {}
GI.Config = Config

local specs = {}
local order = {}

local function validKey(key)
  if type(key) ~= 'string' or key == '' then return false end
  for part in (key .. '.'):gmatch('([^%.]*)%.') do
    if not part:match('^[%a_][%w_]*$') then return false end
  end
  return true
end

local function checkValue(spec, value)
  local t = spec.type
  if t == 'number' then
    if type(value) ~= 'number' or value ~= value or value == math.huge or value == -math.huge then
      return false, 'must be a number'
    end
    if spec.integer and value ~= math.floor(value) then return false, 'must be a whole number' end
    if spec.minValue and value < spec.minValue then return false, 'must be at least ' .. tostring(spec.minValue) end
    if spec.maxValue and value > spec.maxValue then return false, 'must be at most ' .. tostring(spec.maxValue) end
    return true
  elseif t == 'boolean' then
    if type(value) ~= 'boolean' then return false, 'must be true or false' end
    return true
  elseif t == 'string' then
    if type(value) ~= 'string' then return false, 'must be text' end
    if #value > (spec.maxLength or 200) then return false, 'is too long' end
    return true
  elseif t == 'enum' then
    for i = 1, #spec.values do
      if spec.values[i] == value then return true end
    end
    return false, 'must be one of: ' .. table.concat(spec.values, ', ')
  end
  return false, 'unknown type'
end

local function split(key)
  local parts = {}
  for part in key:gmatch('[^%.]+') do parts[#parts + 1] = part end
  return parts
end

local function profile()
  local store = GI.Store
  if store then return store.Section('profile') end
  return nil
end

local function getPath(root, key)
  local node = root
  for _, part in ipairs(split(key)) do
    if type(node) ~= 'table' then return nil end
    node = node[part]
  end
  return node
end

local function setPath(root, key, value)
  local parts = split(key)
  local node = root
  for i = 1, #parts - 1 do
    if type(node[parts[i]]) ~= 'table' then node[parts[i]] = {} end
    node = node[parts[i]]
  end
  node[parts[#parts]] = value
end

local function prune(root, key)
  -- remove the leaf and any parent tables that became empty
  local parts = split(key)
  local chain = { root }
  for i = 1, #parts - 1 do
    local nextNode = chain[#chain][parts[i]]
    if type(nextNode) ~= 'table' then return end
    chain[#chain + 1] = nextNode
  end
  chain[#chain][parts[#parts]] = nil
  for i = #chain, 2, -1 do
    if next(chain[i]) == nil then chain[i - 1][parts[i - 1]] = nil else break end
  end
end

---------------------------------------------------------------------------
-- Definitions
---------------------------------------------------------------------------

function Config.Define(key, spec)
  if not validKey(key) then return nil, 'invalid key ' .. tostring(key) end
  if specs[key] then return nil, 'setting already defined: ' .. key end
  if type(spec) ~= 'table' then return nil, 'spec must be a table' end
  local t = spec.type
  if t ~= 'number' and t ~= 'boolean' and t ~= 'string' and t ~= 'enum' then return nil, 'unknown type ' .. tostring(t) end
  if t == 'enum' and (type(spec.values) ~= 'table' or #spec.values == 0) then return nil, 'enum needs a list of values' end
  local ok, why = checkValue(spec, spec.default)
  if not ok then return nil, 'default ' .. why end
  for other in pairs(specs) do
    if other:sub(1, #key + 1) == key .. '.' or key:sub(1, #other + 1) == other .. '.' then
      return nil, 'key conflicts with ' .. other
    end
  end
  local copy = P.Util.shallowCopy(spec)
  specs[key] = copy
  order[#order + 1] = key
  return true
end

function Config.Spec(key)
  local spec = specs[key]
  if not spec then return nil end
  return P.Util.shallowCopy(spec)
end

---------------------------------------------------------------------------
-- Values
---------------------------------------------------------------------------

function Config.Get(key)
  local spec = specs[key]
  if not spec then return nil, 'unknown setting ' .. tostring(key) end
  local root = profile()
  if root then
    local stored = getPath(root, key)
    if stored ~= nil and checkValue(spec, stored) then return stored end
  end
  return spec.default
end

local function fire(key, value, previous, source)
  if GI.Bus then
    GI.Bus.Fire('CONFIG_CHANGED', { key = key, value = value, previous = previous, source = source or 'api' })
  end
end

local function persistedNow()
  return GI.Store ~= nil and GI.Store.IsWritable()
end

function Config.Set(key, value, source)
  local spec = specs[key]
  if not spec then return nil, 'unknown setting ' .. tostring(key) end
  if spec.readonly then return nil, key .. ' is read-only' end
  local ok, why = checkValue(spec, value)
  if not ok then return nil, key .. ' ' .. why end
  local root = profile()
  if not root then return nil, 'store is not available' end
  local previous = Config.Get(key)
  setPath(root, key, value)
  if previous ~= value then fire(key, value, previous, source) end
  return true, persistedNow()
end

function Config.Reset(key, source)
  local spec = specs[key]
  if not spec then return nil, 'unknown setting ' .. tostring(key) end
  if spec.readonly then return nil, key .. ' is read-only' end
  local root = profile()
  if not root then return nil, 'store is not available' end
  local previous = Config.Get(key)
  prune(root, key)
  if previous ~= spec.default then fire(key, spec.default, previous, source or 'reset') end
  return true
end

function Config.ResetAll(source)
  local n = 0
  for _, key in ipairs(order) do
    if not specs[key].readonly then
      local root = profile()
      if root and getPath(root, key) ~= nil then n = n + 1 end
      Config.Reset(key, source or 'reset')
    end
  end
  return n
end

--- Converts text (from a command line) into a typed value for the setting.
function Config.Parse(key, text)
  local spec = specs[key]
  if not spec then return nil, 'unknown setting ' .. tostring(key) end
  text = tostring(text or '')
  if spec.type == 'number' then
    local n = tonumber(text)
    if not n then return nil, key .. ' needs a number' end
    return n
  elseif spec.type == 'boolean' then
    local v = text:lower()
    if v == 'true' or v == 'on' or v == 'yes' or v == '1' then return true end
    if v == 'false' or v == 'off' or v == 'no' or v == '0' then return false end
    return nil, key .. ' needs on or off'
  end
  return text
end

--- Validates persisted values. Invalid ones stay in the table but are ignored (the default
-- applies); they are returned so the caller can report them. Returns { invalid = { key = reason } }.
function Config.Load()
  local report = { invalid = {} }
  local root = profile()
  if not root then return report end
  for _, key in ipairs(order) do
    local stored = getPath(root, key)
    if stored ~= nil then
      local ok, why = checkValue(specs[key], stored)
      if not ok then
        report.invalid[key] = why
        P.Diag('warn', 'Config', 'ignoring invalid saved value for ' .. key .. ' (' .. why .. '); using the default')
      end
    end
  end
  return report
end

--- Sorted descriptions: { key, value, default, isDefault, type, minValue, maxValue, values, readonly, help }.
function Config.List()
  local keys = {}
  for i = 1, #order do keys[i] = order[i] end
  table.sort(keys)
  local out = {}
  for _, key in ipairs(keys) do
    local spec = specs[key]
    local value = Config.Get(key)
    out[#out + 1] = {
      key = key, value = value, default = spec.default, isDefault = (value == spec.default),
      type = spec.type, minValue = spec.minValue, maxValue = spec.maxValue, values = spec.values,
      readonly = spec.readonly and true or false, help = spec.help,
    }
  end
  return out
end

---------------------------------------------------------------------------
-- Built-in settings (Contracts F6)
---------------------------------------------------------------------------

local BUILTIN = {
  { 'idleSec', { type = 'number', default = 120, minValue = 10, maxValue = 3600, integer = true,
                 help = 'Seconds without activity before the session clock pauses (used from Phase 4)' } },
  { 'minSegSec', { type = 'number', default = 600, minValue = 30, maxValue = 7200, integer = true,
                   help = 'Segments shorter than this are merged into the previous one (Phase 4)' } },
  { 'minBinSec', { type = 'number', default = 60, minValue = 1, maxValue = 3600, integer = true,
                   help = 'Minimum seconds in a heatmap cell before it is shown (Phase 7)' } },
  { 'heatGrid', { type = 'number', default = 32, minValue = 32, maxValue = 32, integer = true, readonly = true,
                  help = 'Heatmap grid size per axis (fixed in v1, Decisions D-011)' } },
  { 'valuation', { type = 'enum', default = 'conservative', values = { 'conservative' },
                   help = 'How items are valued (Phase 6)' } },
  { 'defaultSellThrough', { type = 'number', default = 0.6, minValue = 0, maxValue = 1,
                            help = 'Assumed chance an auction sells when there is no history (Phase 6)' } },
  { 'prune.days', { type = 'number', default = 90, minValue = 1, maxValue = 3650, integer = true,
                    help = 'Raw session data older than this is eligible for roll-up (Phase 5)' } },
  { 'prune.maxBytes', { type = 'number', default = 2000000, minValue = 100000, maxValue = 20000000, integer = true,
                        help = 'Approximate size budget of the saved database' } },
  { 'normalization.minHours', { type = 'number', default = 5, minValue = 0, maxValue = 1000,
                                help = 'Hours needed in a level bracket before normalized GPH is shown (experimental)' } },
  { 'normalization.bracketSize', { type = 'number', default = 5, minValue = 1, maxValue = 60, integer = true,
                                   help = 'Levels per normalization bracket (experimental)' } },
}
for i = 1, #BUILTIN do
  local ok, err = Config.Define(BUILTIN[i][1], BUILTIN[i][2])
  if not ok then error('built-in setting ' .. BUILTIN[i][1] .. ': ' .. tostring(err)) end
end

if GI.Core then GI.Core.Service('config', Config) end
]=====] },
{ path = "Store/Migrations.lua", src = [=====[
-- GoldIntel / Store / Migrations.lua                                    (Phase 2)
--
-- PURPOSE
--   The schema migration framework and the database shape.
--
--   Migrations.Register(from, fn, name)   fn(db) upgrades a database from schema `from` to from+1
--   Migrations.Latest()                   the schema this addon writes (highest registered step + 1)
--   Migrations.Plan(from, to)             -> array of steps | nil, err (a gap means no path)
--   Migrations.Run(db, from, to)          -> { ok, applied = {names}, failedAt, err }
--   Migrations.Sections()                 -> fresh default sections (new tables every call)
--   Migrations.Check(db) / EnsureShape(db)  detect / repair wrong or missing sections
--
-- RULES (Decisions D-036)
--   * A migration only mutates the table it is given. Store runs it on a COPY and commits
--     only when the whole chain succeeded and validation passed, so a failing migration can
--     never damage saved data.
--   * A migration must never alter db.compat (owned by Platform/Probe). Store verifies this.
--   * Steps are contiguous: 0->1, 1->2, ... Schema 0 means 'a database that has no schema field'
--     (everything written before Phase 2: only GoldIntelDB.compat).
--   * Unknown keys are preserved by every migration.
--   * The first released schema is 1 (Decisions D-014). Schema 2 (increment 3b-2, D-077) adds `ledger` and keeps
--     a backup of the schema 1 data in `migrationBackup` (see the step at the end of this file).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Store/Migrations.lua')

local Mig = {}
GI.Migrations = Mig

local steps = {}      -- from -> { fn = function, name = string }

---------------------------------------------------------------------------
-- Database shape (Contracts F5)
---------------------------------------------------------------------------

local FACTORIES = {
  meta = function() return {} end,
  profile = function() return {} end,
  chars = function() return {} end,
  sessions = function() return {} end,
  segments = function() return {} end,
  lots = function() return { open = {}, closedSummary = {} } end,
  agg = function() return { zone = {}, sub = {}, act = {}, bracket = {} } end,
  heat = function() return {} end,
  prices = function() return { snapshots = {} } end,
  auctions = function() return {} end,
  runtime = function() return {} end,
  ledger = function() return {} end,          -- schema 2 (Contracts F5b): ledger[charKey] = { nextId, cash, totals, locs, quality }
}
local NESTED = {
  lots = { 'open', 'closedSummary' },
  agg = { 'zone', 'sub', 'act', 'bracket' },
  prices = { 'snapshots' },
}
Mig.SECTION_NAMES = {}
for name in pairs(FACTORIES) do Mig.SECTION_NAMES[#Mig.SECTION_NAMES + 1] = name end
table.sort(Mig.SECTION_NAMES)

--- Registers a section factory so later phases can add sections (Store validates it too).
function Mig.DefineSection(name, factory, nested)
  if type(name) ~= 'string' or name == '' or name == 'compat' or name == 'schema' then
    return nil, 'invalid section name'
  end
  if FACTORIES[name] then return nil, 'section already defined: ' .. name end
  if type(factory) ~= 'function' then return nil, 'factory must be a function' end
  FACTORIES[name] = factory
  NESTED[name] = nested
  Mig.SECTION_NAMES[#Mig.SECTION_NAMES + 1] = name
  table.sort(Mig.SECTION_NAMES)
  return true
end

--- Fresh default sections (every table is new).
function Mig.Sections()
  local out = {}
  for name, factory in pairs(FACTORIES) do out[name] = factory() end
  return out
end

--- Lists problems without changing anything: { missing = {...}, wrongType = {...} }.
function Mig.Check(db)
  local problems = { missing = {}, wrongType = {} }
  for _, name in ipairs(Mig.SECTION_NAMES) do
    local section = db[name]
    if section == nil then
      problems.missing[#problems.missing + 1] = name
    elseif type(section) ~= 'table' then
      problems.wrongType[#problems.wrongType + 1] = name
    else
      local nested = NESTED[name]
      if nested then
        for _, inner in ipairs(nested) do
          if section[inner] == nil then
            problems.missing[#problems.missing + 1] = name .. '.' .. inner
          elseif type(section[inner]) ~= 'table' then
            problems.wrongType[#problems.wrongType + 1] = name .. '.' .. inner
          end
        end
      end
    end
  end
  return problems
end

--- Adds missing sections and replaces wrong-typed ones. Returns { added = {...}, repaired = {...} }.
-- Existing valid content and unknown keys are never touched.
function Mig.EnsureShape(db)
  local report = { added = {}, repaired = {} }
  for _, name in ipairs(Mig.SECTION_NAMES) do
    local section = db[name]
    if section == nil then
      db[name] = FACTORIES[name]()
      report.added[#report.added + 1] = name
    elseif type(section) ~= 'table' then
      db[name] = FACTORIES[name]()
      report.repaired[#report.repaired + 1] = name
    else
      local nested = NESTED[name]
      if nested then
        for _, inner in ipairs(nested) do
          if section[inner] == nil then
            section[inner] = {}
            report.added[#report.added + 1] = name .. '.' .. inner
          elseif type(section[inner]) ~= 'table' then
            section[inner] = {}
            report.repaired[#report.repaired + 1] = name .. '.' .. inner
          end
        end
      end
    end
  end
  return report
end

---------------------------------------------------------------------------
-- Registry and runner
---------------------------------------------------------------------------

function Mig.Register(from, fn, name)
  if type(from) ~= 'number' or from < 0 or from ~= math.floor(from) then return nil, 'from must be a whole number >= 0' end
  if type(fn) ~= 'function' then return nil, 'migration must be a function' end
  if steps[from] then return nil, 'a migration from ' .. from .. ' is already registered' end
  steps[from] = { fn = fn, name = name or ('v' .. from .. '->v' .. (from + 1)) }
  return true
end

--- The schema this addon writes: the end of the contiguous chain that starts at 0.
function Mig.Latest()
  local v = 0
  while steps[v] do v = v + 1 end
  return v
end

function Mig.Plan(from, to)
  if type(from) ~= 'number' or type(to) ~= 'number' then return nil, 'from and to must be numbers' end
  if from > to then return nil, 'cannot migrate backwards from ' .. from .. ' to ' .. to end
  local plan = {}
  for v = from, to - 1 do
    if not steps[v] then return nil, 'no migration from schema ' .. v end
    plan[#plan + 1] = { from = v, name = steps[v].name }
  end
  return plan
end

--- Runs the chain on `db` (mutating it). Never throws.
function Mig.Run(db, from, to)
  local report = { ok = true, applied = {} }
  local plan, err = Mig.Plan(from, to)
  if not plan then
    report.ok = false
    report.err = err
    return report
  end
  for _, step in ipairs(plan) do
    local ok, stepErr = pcall(steps[step.from].fn, db)
    if not ok then
      report.ok = false
      report.failedAt = step.from
      report.err = tostring(stepErr)
      return report
    end
    db.schema = step.from + 1
    report.applied[#report.applied + 1] = step.name
  end
  return report
end

--- Test helper: remove every step (then Latest() is 0).
function Mig.Reset() steps = {} end

--- Test helper: remove one step (lets a framework test pin an older chain).
function Mig.Remove(from) steps[from] = nil end

---------------------------------------------------------------------------
-- Built-in migration: schema 0 (Phase 1 database, only 'compat') -> schema 1
---------------------------------------------------------------------------

Mig.Register(0, function(db)
  Mig.EnsureShape(db)
end, 'adopt Phase 1 database into schema 1')

---------------------------------------------------------------------------
-- Built-in migration: schema 1 -> schema 2 (increment 3b-2, D-077 Q-7)
--   * creates the empty `ledger` section;
--   * keeps `migrationBackup = { from = 1, t, keys = { name, ... }, data = { ... } }`: a deep copy of every schema 1
--     key except `compat` (owned by Platform/Probe, preserved by Store anyway), `runtime` (rewritten each session)
--     and the backup itself. The addon never reads it back automatically; it exists so a person can recover the
--     schema 1 data by hand. An older addon (0.3.1) opens a schema 2 file read-only and does not touch it.
--   * nothing else changes; unknown keys are preserved. Lots are untouched (3b-3 owns them).
---------------------------------------------------------------------------

Mig.BACKUP_SKIP = { compat = true, runtime = true, migrationBackup = true }

Mig.Register(1, function(db)
  local backup = { from = 1, t = P.Now(), keys = {}, data = {} }
  for key, value in pairs(db) do
    if not Mig.BACKUP_SKIP[key] then
      backup.keys[#backup.keys + 1] = key
      backup.data[key] = P.Util.deepCopy(value)
    end
  end
  table.sort(backup.keys)
  if type(db.ledger) ~= 'table' then db.ledger = {} end
  db.migrationBackup = backup
end, 'schema 2: ledger section and migrationBackup')

if GI.Core then GI.Core.Service('migrations', Mig) end
]=====] },
{ path = "Store/Store.lua", src = [=====[
-- GoldIntel / Store / Store.lua                                         (Phase 2)
--
-- PURPOSE
--   The persistence layer: opens GoldIntelDB (through Platform.SavedVars), brings it to the
--   current schema, and gives the rest of the addon safe access to its sections.
--
--   Store.Open()            -> status (idempotent; never throws)
--   Store.Get()             -> root table of the working database
--   Store.Section(name)     -> the named section (created if missing)
--   Store.Char()            -> per-character table (GoldIntelCharDB)
--   Store.Status() / IsOpen() / IsWritable()
--   Store.Checkpoint(opts)  -> { bytes, truncated, writable, note }
--   Store.EstimateBytes(table, nodeLimit) -> bytes, truncated
--
-- OPEN OUTCOMES (status.state)
--   created   no database existed: a fresh schema-N database was built
--   ok        schema is current; sections validated (and repaired if needed)
--   migrated  an older database (schema 0 = Phase 1, only 'compat') was upgraded
--   readonly  the database is NEWER than this addon understands: it is left untouched and
--             a private working copy is used; nothing is written back
--   degraded  migration or validation failed: the database is left untouched and an
--             in-memory database is used; nothing is written back
--
-- THE compat GUARANTEE (Decisions D-022 item 6, external review finding 3)
--   GoldIntelDB.compat belongs to Platform/Probe. Store never creates, rewrites or removes
--   it, in any state, during initialization or any migration. Migrations run on a copy and
--   the copy's compat must equal the original before anything is committed; the live compat
--   table keeps its identity. Tests assert this with the real database shape captured from
--   the WoW Forever client.
--
-- DURABILITY
--   SavedVariables are written by the client at logout or reload; addons cannot force a
--   write. The live table IS the database, so changes are durable only once the client saves.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Store/Store.lua')

local Store = {}
GI.Store = Store

local status = nil      -- set by Open
local root = nil        -- working root (the live table, or a private copy)
local charRoot = nil
Store.HISTORY_LIMIT = 20
Store.CHAR_SCHEMA = 2         -- GoldIntelCharDB.schema this addon writes (2 adds lastMoney, increment 3b-2)

local function fire(name, payload)
  if GI.Bus then GI.Bus.Fire(name, payload) end
end

---------------------------------------------------------------------------
-- Size estimation (cheap, bounded)
---------------------------------------------------------------------------

--- Approximate serialized size in bytes. Stops after nodeLimit nodes (default 200000) and
-- reports truncated = true. Cycle-safe.
function Store.EstimateBytes(value, nodeLimit)
  nodeLimit = nodeLimit or 200000
  local bytes, nodes = 0, 0
  local seen = {}
  local stack = { value }
  while #stack > 0 do
    local v = table.remove(stack)
    nodes = nodes + 1
    if nodes > nodeLimit then return bytes, true end
    local t = type(v)
    if t == 'string' then
      bytes = bytes + #v + 2
    elseif t == 'number' then
      bytes = bytes + 8
    elseif t == 'boolean' then
      bytes = bytes + 5
    elseif t == 'table' then
      if not seen[v] then
        seen[v] = true
        bytes = bytes + 4
        for k, x in pairs(v) do
          stack[#stack + 1] = k
          stack[#stack + 1] = x
        end
      end
    end
  end
  return bytes, false
end

---------------------------------------------------------------------------
-- Open
---------------------------------------------------------------------------

local function newStatus(target)
  return { state = 'ok', schema = 0, target = target, writable = true, repaired = {}, added = {},
           migrated = nil, reason = nil, svStatus = nil }
end

local function updateMeta(db, st)
  local t = P.Now()
  local meta = db.meta
  if type(meta) ~= 'table' then meta = {}; db.meta = meta end
  if not meta.firstSeen then meta.firstSeen = t end
  meta.lastOpened = t
  meta.opens = (tonumber(meta.opens) or 0) + 1
  meta.addonVersion = P.VERSION
  if type(db.compat) == 'table' and db.compat.build ~= nil then meta.lastBuild = db.compat.build end
  if st.migrated then
    local history = meta.schemaHistory
    if type(history) ~= 'table' then history = {}; meta.schemaHistory = history end
    history[#history + 1] = { from = st.migrated.from, to = st.migrated.to, t = t, addonVersion = P.VERSION }
    while #history > Store.HISTORY_LIMIT do table.remove(history, 1) end
  end
end

local function degrade(live, st, reason)
  st.state = 'degraded'
  st.writable = false
  st.reason = reason
  -- A private in-memory database; the live table is not touched. compat is copied for reading.
  local working = GI.Migrations.Sections()
  working.schema = st.target
  if live and type(live.compat) == 'table' then working.compat = P.Util.deepCopy(live.compat) end
  root = working
  P.Diag('error', 'Store', 'database degraded: ' .. tostring(reason))
  P.Print('saved data could not be upgraded (' .. tostring(reason) .. '). GoldIntel keeps your file untouched and runs without saving.')
  fire('STORE_DEGRADED', { reason = tostring(reason) })
end

local function migrate(live, from, target, st)
  local Util = P.Util
  local staged = Util.deepCopy(live)
  local compatBefore = Util.deepCopy(live.compat)
  local report = GI.Migrations.Run(staged, from, target)
  if not report.ok then return false, 'migration failed' .. (report.failedAt and (' at schema ' .. report.failedAt) or '') .. ': ' .. tostring(report.err) end
  local shape = GI.Migrations.EnsureShape(staged)
  for _, name in ipairs(shape.added) do st.added[#st.added + 1] = name end
  for _, name in ipairs(shape.repaired) do st.repaired[#st.repaired + 1] = name end
  if not Util.deepEqual(staged.compat, compatBefore) then return false, 'migration changed compat, which Store must preserve' end
  local problems = GI.Migrations.Check(staged)
  if #problems.missing > 0 or #problems.wrongType > 0 then return false, 'database invalid after migration' end
  -- Commit: replace everything except the live compat table (its identity is preserved).
  for key in pairs(live) do
    if key ~= 'compat' then live[key] = nil end
  end
  for key, value in pairs(staged) do
    if key ~= 'compat' then live[key] = value end
  end
  st.migrated = { from = from, to = target, applied = report.applied }
  return true
end

--- Opens the database. Idempotent: later calls return the same status.
function Store.Open()
  if status then return Store.Status() end
  local Mig = GI.Migrations
  local target = Mig.Latest()
  local st = newStatus(target)
  status = st

  local sv = P.SavedVars
  local live, svStatus
  if sv then live, svStatus = sv.Account() end
  st.svStatus = svStatus

  if type(live) ~= 'table' then
    degrade(nil, st, 'SavedVariables are not available')
  elseif svStatus ~= 'existing' or next(live) == nil then
    -- nothing was saved: build a fresh database in place
    local fresh = Mig.Sections()
    for key, value in pairs(fresh) do live[key] = value end
    live.schema = target
    st.state = 'created'
    st.schema = target
    root = live
  else
    local schema = live.schema
    local from = type(schema) == 'number' and schema or 0
    if type(schema) == 'number' and schema > target then
      st.state = 'readonly'
      st.writable = false
      st.schema = schema
      st.reason = 'saved data is schema ' .. schema .. ', newer than this addon (' .. target .. '); left untouched'
      root = P.Util.deepCopy(live)
      P.Diag('warn', 'Store', st.reason)
    elseif from < target then
      local ok, err = migrate(live, from, target, st)
      if ok then
        st.state = 'migrated'
        st.schema = target
        root = live
      else
        st.schema = from
        degrade(live, st, err)
      end
    else
      local shape = Mig.EnsureShape(live)
      for _, name in ipairs(shape.added) do st.added[#st.added + 1] = name end
      for _, name in ipairs(shape.repaired) do st.repaired[#st.repaired + 1] = name end
      if #shape.repaired > 0 then
        P.Diag('warn', 'Store', 'repaired wrong-typed sections: ' .. table.concat(shape.repaired, ', '))
      end
      st.schema = target
      root = live
    end
  end

  if st.writable and root then updateMeta(root, st) end
  fire('STORE_OPENED', { state = st.state, schema = st.schema, writable = st.writable })
  if st.migrated then fire('STORE_MIGRATED', { from = st.migrated.from, to = st.migrated.to }) end
  return Store.Status()
end

---------------------------------------------------------------------------
-- Access
---------------------------------------------------------------------------

function Store.IsOpen() return status ~= nil end

function Store.IsWritable()
  return status ~= nil and status.writable == true
end

--- Copy of the status table.
function Store.Status()
  if not status then return nil end
  local out = P.Util.shallowCopy(status)
  out.repaired = P.Util.shallowCopy(status.repaired)
  out.added = P.Util.shallowCopy(status.added)
  return out
end

function Store.Get()
  if not status then Store.Open() end
  return root
end

--- The named section; created when missing. Returns nil when the name is invalid.
function Store.Section(name)
  if type(name) ~= 'string' or name == '' or name == 'schema' or name == 'compat' then return nil end
  local db = Store.Get()
  if type(db[name]) ~= 'table' then db[name] = {} end
  return db[name]
end

--- The per-character table (GoldIntelCharDB): { schema, pending = {}, ... }.
function Store.Char()
  if charRoot then return charRoot end
  local live
  if P.SavedVars then live = P.SavedVars.Character() end
  if type(live) ~= 'table' then live = {} end
  if type(live.schema) == 'number' and live.schema > Store.CHAR_SCHEMA then
    P.Diag('warn', 'Store', 'character data is schema ' .. live.schema .. ', newer than this addon; using a private copy')
    live = P.Util.deepCopy(live)
  end
  if live.schema == nil or live.schema < Store.CHAR_SCHEMA then live.schema = Store.CHAR_SCHEMA end    -- 1 -> 2 is additive (lastMoney)
  if type(live.pending) ~= 'table' then live.pending = {} end
  charRoot = live
  return live
end

--- Marks a checkpoint and returns the approximate size. Saving to disk still happens at
-- logout or /reload (addons cannot force it).
function Store.Checkpoint(opts)
  local db = Store.Get()
  local bytes, truncated = Store.EstimateBytes(db)
  if status.writable and type(db.meta) == 'table' then db.meta.lastCheckpoint = (P.Now()) end
  return {
    bytes = bytes, truncated = truncated, writable = status.writable,
    note = 'The client writes saved data at logout or /reload.',
  }
end

--- Test helper: forget the open database (does not touch saved variables).
function Store.Reset()
  status, root, charRoot = nil, nil, nil
end

if GI.Core then GI.Core.Service('store', Store) end
]=====] },
{ path = "Store/Pruner.lua", src = [=====[
-- GoldIntel / Store / Pruner.lua                                        (Phase 2: stub)
--
-- PURPOSE
--   Plans data retention. In Phase 2 it only PLANS: it reports what would be pruned and
--   whether the database is over its size budget. It never deletes, because removing raw
--   sessions before they are rolled up into the aggregates (Phase 5) would lose data.
--
--   Pruner.Plan(db, policy, now) -> { cutoff, sessions = {ids}, segments = {ids}, bytes, maxBytes, overBudget }
--   Pruner.Run(policy)           -> { ok, dryRun = true, planned, removed = 0, overBudget, note }
--
--   policy: { days, maxBytes }  (defaults from Config prune.days / prune.maxBytes)
--
-- A session is eligible when its end time (t1, else its start t0) is older than `days`.
-- Segments are eligible when their session is, or when they are orphans older than the cutoff.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Store/Pruner.lua')

local Pruner = {}
GI.Pruner = Pruner

local DAY = 86400

local function sortedKeys(t)
  local out = {}
  for k in pairs(t) do out[#out + 1] = k end
  table.sort(out, function(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    return a < b
  end)
  return out
end

function Pruner.Plan(db, policy, now)
  policy = policy or {}
  local days = policy.days or 90
  local maxBytes = policy.maxBytes or 2000000
  now = now or (P.Now())
  local cutoff = now - days * DAY
  local plan = { cutoff = cutoff, sessions = {}, segments = {}, maxBytes = maxBytes }

  local oldSession = {}
  if type(db.sessions) == 'table' then
    for _, id in ipairs(sortedKeys(db.sessions)) do
      local s = db.sessions[id]
      if type(s) == 'table' then
        local ended = tonumber(s.t1) or tonumber(s.t0)
        if ended and ended < cutoff then
          plan.sessions[#plan.sessions + 1] = id
          oldSession[id] = true
        end
      end
    end
  end
  if type(db.segments) == 'table' then
    for _, id in ipairs(sortedKeys(db.segments)) do
      local seg = db.segments[id]
      if type(seg) == 'table' then
        local started = tonumber(seg.t0)
        local orphan = seg.sessionID == nil or (type(db.sessions) == 'table' and db.sessions[seg.sessionID] == nil)
        if oldSession[seg.sessionID] or (orphan and started and started < cutoff) then
          plan.segments[#plan.segments + 1] = id
        end
      end
    end
  end
  local bytes, truncated = GI.Store.EstimateBytes(db)
  plan.bytes = bytes
  plan.truncated = truncated
  plan.overBudget = bytes > maxBytes
  return plan
end

function Pruner.Run(policy)
  policy = policy or {}
  if policy.days == nil and GI.Config then policy.days = GI.Config.Get('prune.days') end
  if policy.maxBytes == nil and GI.Config then policy.maxBytes = GI.Config.Get('prune.maxBytes') end
  local plan = Pruner.Plan(GI.Store.Get(), policy)
  return {
    ok = true, dryRun = true, removed = 0,
    planned = { sessions = #plan.sessions, segments = #plan.segments },
    bytes = plan.bytes, maxBytes = plan.maxBytes, overBudget = plan.overBudget,
    note = 'Phase 2 plans only; roll-up and deletion arrive with the aggregation tables (Phase 5).',
  }
end

if GI.Core then GI.Core.Service('pruner', Pruner) end
]=====] },
{ path = "Core/Slash.lua", src = [=====[
-- GoldIntel / Core / Slash.lua                                          (Phase 2)
--
-- PURPOSE
--   The /gi command set. The commands moved here from Platform/Probe.lua (Decisions D-022
--   item 5) and grew with Core and Store. Registration with the client goes through
--   Platform.RegisterSlash; this file never touches a WoW API.
--
--   Commands.Register(name, spec)   spec = { help = '...', usage = '...', fn = function(args, rest) }
--   Commands.Run(text, minimal)     parse and dispatch one command line
--   Commands.Install(minimal)       register /gi with the client
--
--   /gi                      summary of the whole addon
--   /gi help                 this list
--   /gi status               platform line (as in Phase 1) plus Core and Store state
--   /gi version              addon, client and interface
--   /gi probe                run the capability probe and print the report
--   /gi diag                 last diagnostics
--   /gi debug [on|off|ticks] echo normalized platform events to chat
--   /gi caps [events|api|all|text]   capability stages (valid/registered/delivered/payloadUsable)
--   /gi config [list|get K|set K V|reset K|all]   settings (persisted)
--   /gi db                   saved database: state, schema, sizes, history
--   /gi modules              module states
--   /gi checkpoint           size estimate and a reminder how saving works
--
--   When the platform is not operational only help, status, version, probe, diag and debug exist.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Core/Slash.lua')

local Commands = {}
GI.Commands = Commands

local registry = {}
local order = {}
local MINIMAL = { help = true, status = true, version = true, probe = true, diag = true, debug = true }

local function say(line) P.Print(line) end

function Commands.Register(name, spec)
  if type(name) ~= 'string' or not name:match('^[a-z][a-z0-9]*$') then return nil, 'command names are lowercase words' end
  if registry[name] then return nil, 'command already registered: ' .. name end
  if type(spec) ~= 'table' or type(spec.fn) ~= 'function' then return nil, 'spec needs a function' end
  registry[name] = spec
  order[#order + 1] = name
  return true
end

function Commands.Names()
  local out = {}
  for i = 1, #order do out[i] = order[i] end
  table.sort(out)
  return out
end

local function parse(text)
  text = tostring(text or '')
  local cmd, rest = text:match('^%s*(%S*)%s*(.-)%s*$')
  local args = {}
  for word in (rest or ''):gmatch('%S+') do args[#args + 1] = word end
  return (cmd or ''):lower(), args, rest or ''
end

local function kb(bytes)
  return string.format('%.1f KB', bytes / 1024)
end

---------------------------------------------------------------------------
-- Built-in commands
---------------------------------------------------------------------------

local function statusLine()
  local lastRegister = P.Events and P.Events.lastRegisterAttempt
  return 'operational=' .. tostring(P.operational) .. ' ready=' .. tostring(P.IsReady())
    .. ' inWorld=' .. tostring(P.InWorld()) .. ' scheduler=' .. tostring(P.Scheduler.Backend())
    .. ' money=' .. tostring(P.MoneyModule.Last()) .. ' diag=' .. P.DiagCount()
    .. ' lastRegister=' .. tostring(lastRegister)
end

local function coreLines()
  local lines = {}
  if GI.Core then
    local d = GI.Core.Describe()
    lines[#lines + 1] = 'core=' .. d.state .. ' modules=' .. d.total .. ' enabled=' .. d.enabled
      .. ' failed=' .. d.failed .. ' disabled=' .. d.disabled .. ' stubs=' .. d.stub
  end
  if GI.Store and GI.Store.IsOpen() then
    local s = GI.Store.Status()
    local bytes = GI.Store.EstimateBytes(GI.Store.Get())
    lines[#lines + 1] = 'store=' .. s.state .. ' schema=' .. tostring(s.schema) .. ' writable=' .. tostring(s.writable)
      .. ' size~' .. kb(bytes)
    if s.reason then lines[#lines + 1] = 'store note: ' .. s.reason end
  end
  return lines
end

Commands.Register('status', { help = 'platform, core and store state', fn = function()
  say(statusLine())
  for _, line in ipairs(coreLines()) do say(line) end
end })

Commands.Register('help', { help = 'list commands', fn = function()
  say('GoldIntel ' .. P.VERSION .. ' commands (/gi <command>):')
  for _, name in ipairs(Commands.Names()) do
    if not Commands.minimal or MINIMAL[name] then
      local spec = registry[name]
      say('  ' .. (spec.usage or name) .. '  -  ' .. (spec.help or ''))
    end
  end
end })

Commands.Register('version', { help = 'addon, client and interface versions', fn = function()
  local info = P.ProbeModule and P.ProbeModule.last and P.ProbeModule.last.info or {}
  say('GoldIntel ' .. P.VERSION .. '  (contract ' .. P.CONTRACT_VERSION .. ')')
  say('client ' .. tostring(info.gameVersion) .. ' build ' .. tostring(info.build) .. '  interface ' .. tostring(info.interface)
    .. '  locale ' .. tostring(info.locale))
end })

Commands.Register('probe', { help = 'run the capability probe and print the report', fn = function()
  P.ProbeModule.Run()
  P.CheckFatal()
  P.ProbeModule.Persist()
  if GI.Capabilities then GI.Capabilities.Import() end
  for _, line in ipairs(P.ProbeModule.Report()) do say(line) end
  say('Report saved to SavedVariables after /reload or logout (GoldIntelDB.compat.report).')
end })

Commands.Register('diag', { help = 'last diagnostics', fn = function()
  local list = P.GetDiag()
  if GI.Ledger then for _, l in ipairs(GI.Ledger.DiagLines()) do say(l) end end
  if #list == 0 then say('no diagnostics') end
  for i = math.max(1, #list - 9), #list do
    say(list[i].level .. ' [' .. list[i].module .. '] ' .. list[i].msg)
  end
end })

Commands.Register('debug', { help = 'echo platform events: on | off | ticks', usage = 'debug [on|off|ticks]', fn = function(args)
  local arg = (args[1] or ''):lower()
  if arg == 'ticks' then
    P.debugTicks = not P.debugTicks
    local note = ''
    if P.debugTicks and not P.debug then
      note = ' (nothing is echoed until you also type /gi debug on)'
    end
    say('tick echo ' .. (P.debugTicks and 'on' or 'off') .. note)
  else
    P.SetDebug(arg ~= 'off')
    say('debug ' .. (P.debug and 'on' or 'off') .. ' (normalized events are echoed to chat)')
  end
end })

-- yes = proven, NO = failed, anything else = not observed yet (NOT a failure)
local function stageWord(stage, value)
  if value == true then return 'yes' end
  if value == false then return 'NO' end
  if stage == 'delivered' then return 'not-seen-yet' end
  return 'unknown'
end

local function stageText(rec)
  local parts = {}
  for _, stage in ipairs(GI.Capabilities.STAGES[rec.kind]) do
    parts[#parts + 1] = stage .. '=' .. stageWord(stage, rec.stages[stage])
  end
  return table.concat(parts, ' ')
end

-- Read-only view of a kept session record (D-041): previous or pinned.
local function showRecord(which, rec)
  if type(rec) ~= 'table' then say('no ' .. which .. ' session record'); return end
  local now = P.Now()
  local age = (type(rec.generatedAt) == 'number') and math.floor((now - rec.generatedAt) / 60) or nil
  say(which .. ' session: ' .. (rec.durationSec and (math.floor(rec.durationSec / 60) .. ' min') or 'length unknown')
    .. ', addon ' .. tostring(rec.addonVersion) .. ', build ' .. tostring(rec.build)
    .. ', ended by ' .. tostring(rec.endedBy) .. (age and (', saved ' .. age .. ' min ago') or ''))
  local names = {}
  for event in pairs(rec.eventStats or {}) do names[#names + 1] = event end
  table.sort(names)
  for _, event in ipairs(names) do
    local d = rec.eventStats[event].delivered or 0
    say('  ' .. event .. ': delivered ' .. d .. (d == 0 and '  (not seen)' or ''))
  end
  say('  ' .. #(rec.output or {}) .. ' output lines are kept in the saved file (GoldIntel.lua, runtime.' .. which .. '.output)')
end

Commands.Register('caps', { help = 'capability stages', usage = 'caps [events|api|all|text|history|events previous|events pinned]', fn = function(args)
  local C = GI.Capabilities
  if not C then say('capabilities are not available'); return end
  local filter = (args[1] or ''):lower()
  local second = (args[2] or ''):lower()
  if filter == 'history' then
    local rows = C.Records().history
    if #rows == 0 then say('no earlier sessions are recorded') end
    for i = #rows, 1, -1 do
      local r = rows[i]
      say('session at ' .. tostring(r.sessionStart) .. ': ' .. (r.durationSec and (math.floor(r.durationSec / 60) .. ' min') or '? min')
        .. ', build ' .. tostring(r.build) .. ', ended by ' .. tostring(r.endedBy))
    end
    return
  end
  if filter == 'previous' or filter == 'pinned' or (filter == 'events' and (second == 'previous' or second == 'pinned')) then
    local which = (filter == 'events') and second or filter
    showRecord(which, C.Records()[which])
    return
  end
  local summary = C.Summary()
  local function line(kind)
    local parts = {}
    local levels = {}
    for level in pairs(summary[kind]) do levels[#levels + 1] = level end
    table.sort(levels)
    for _, level in ipairs(levels) do parts[#parts + 1] = level .. '=' .. summary[kind][level] end
    return table.concat(parts, ' ')
  end
  say('events: ' .. (line('event') ~= '' and line('event') or 'none'))
  say('api:    ' .. (line('api') ~= '' and line('api') or 'none'))
  local kind = nil
  if filter == 'events' then kind = 'event' elseif filter == 'api' then kind = 'api' end
  local showAll = filter == 'all'
  for _, name in ipairs(C.Names(kind)) do
    local rec = C.Get(name)
    local match = (filter == '' and rec.kind == 'event') or showAll or kind ~= nil
    if not match and filter ~= '' and name:lower():find(filter, 1, true) then match = true end
    if match then
      if rec.kind == 'event' then
        say(name .. '  [' .. rec.level .. ']  ' .. stageText(rec))
      else
        say(name .. '  [' .. rec.level .. ']' .. ((rec.notes.present and rec.level ~= 'present') and ('  ' .. rec.notes.present) or ''))
      end
    end
  end
  say('yes = proven, NO = failed, not-seen-yet / unknown = not observed yet (not a failure). Only payloadUsable (events) or present (api) means a design may depend on a capability.')
end })

Commands.Register('config', { help = 'settings', usage = 'config [list|get K|set K V|reset K|all]', fn = function(args)
  local Config = GI.Config
  if not Config then say('config is not available'); return end
  local sub = (args[1] or 'list'):lower()
  if sub == 'list' then
    for _, e in ipairs(Config.List()) do
      say(e.key .. ' = ' .. tostring(e.value) .. (e.isDefault and '' or ('   (default ' .. tostring(e.default) .. ')'))
        .. (e.readonly and '  [read-only]' or ''))
    end
  elseif sub == 'get' then
    if not args[2] then say('usage: /gi config get <key>'); return end
    local value, err = Config.Get(args[2])
    if value == nil then say(tostring(err)) else say(args[2] .. ' = ' .. tostring(value)) end
  elseif sub == 'set' then
    if not args[2] or args[3] == nil then say('usage: /gi config set <key> <value>'); return end
    local value, perr = Config.Parse(args[2], args[3])
    if value == nil then say(tostring(perr)); return end
    local ok, result = Config.Set(args[2], value, 'command')
    if not ok then say(tostring(result)); return end
    say(args[2] .. ' = ' .. tostring(value) .. (result and '' or '   (this session only: the saved database is not writable)'))
  elseif sub == 'reset' then
    if not args[2] then say('usage: /gi config reset <key|all>'); return end
    if args[2]:lower() == 'all' then
      say('reset ' .. Config.ResetAll('command') .. ' setting(s) to defaults')
    else
      local ok, err = Config.Reset(args[2], 'command')
      if not ok then say(tostring(err)) else say(args[2] .. ' reset to ' .. tostring(Config.Get(args[2]))) end
    end
  else
    say('usage: /gi config [list|get <key>|set <key> <value>|reset <key|all>]')
  end
end })

Commands.Register('db', { help = 'saved database state, schema, sizes, history', fn = function()
  local Store = GI.Store
  if not Store or not Store.IsOpen() then say('store is not open'); return end
  local s = Store.Status()
  say('state=' .. s.state .. ' schema=' .. tostring(s.schema) .. ' target=' .. tostring(s.target) .. ' writable=' .. tostring(s.writable))
  if s.reason then say('note: ' .. s.reason) end
  if #s.added > 0 then say('added sections: ' .. table.concat(s.added, ', ')) end
  if #s.repaired > 0 then say('repaired sections: ' .. table.concat(s.repaired, ', ')) end
  local db = Store.Get()
  for _, name in ipairs(GI.Migrations.SECTION_NAMES) do
    local section = db[name]
    if type(section) == 'table' then
      local n = 0
      for _ in pairs(section) do n = n + 1 end
      local bytes = Store.EstimateBytes(section)
      say('  ' .. name .. ': ' .. n .. ' entries, ~' .. kb(bytes))
    end
  end
  say('  compat: ' .. (type(db.compat) == 'table' and 'present (preserved untouched)' or 'absent'))
  local c = Store.Char()
  say('  character data: schema ' .. tostring(c.schema) .. ', pending ' .. (next(c.pending) == nil and 'none' or 'yes') .. (c.activeSessionID and (', activeSessionID ' .. tostring(c.activeSessionID)) or ''))
  if GI.Capabilities and GI.Capabilities.Records then
    local r = GI.Capabilities.Records()
    say('  session records: current + previous ' .. (r.previous and 'kept' or 'none yet') .. ', history ' .. #r.history .. ' row(s), pinned ' .. (r.pinned and 'yes' or 'no'))
  end
  local meta = db.meta
  if type(meta) == 'table' then
    say('opens=' .. tostring(meta.opens) .. ' lastBuild=' .. tostring(meta.lastBuild) .. ' addonVersion=' .. tostring(meta.addonVersion))
    local history = meta.schemaHistory
    if type(history) == 'table' then
      for i = math.max(1, #history - 4), #history do
        say('  migration: schema ' .. tostring(history[i].from) .. ' -> ' .. tostring(history[i].to) .. ' by ' .. tostring(history[i].addonVersion))
      end
    end
  end
end })

Commands.Register('modules', { help = 'module states', fn = function()
  if not GI.Core then say('core is not available'); return end
  local list = GI.Core.Modules()
  if #list == 0 then say('no modules registered') end
  for _, m in ipairs(list) do
    say(m.name .. ': ' .. m.state .. (m.reason and (' (' .. m.reason .. ')') or '') .. (m.stub and '  [placeholder]' or ''))
  end
end })

Commands.Register('checkpoint', { help = 'size estimate; how saving works; pin | unpin keeps this session record', usage = 'checkpoint [pin|unpin]', fn = function(args)
  local Store = GI.Store
  if not Store or not Store.IsOpen() then say('store is not open'); return end
  local sub = ((args and args[1]) or ''):lower()
  if sub == 'pin' or sub == 'unpin' then
    local C = GI.Capabilities
    if not C then say('capabilities are not available'); return end
    if sub == 'pin' then
      local ok, why = C.Pin()
      say(ok and 'pinned: this session record is kept until you unpin or pin another (/reload to save it now)' or ('not pinned: ' .. tostring(why)))
    else
      local had, why = C.Unpin()
      if had == nil then say('not changed: ' .. tostring(why)) else say(had and 'unpinned' or 'nothing was pinned') end
    end
    return
  end
  if GI.Capabilities then GI.Capabilities.Persist() end
  local r = Store.Checkpoint()
  say('database ~' .. kb(r.bytes) .. (r.truncated and ' (estimate truncated)' or '') .. '  writable=' .. tostring(r.writable))
  say(r.note .. ' Use /reload to save now.')
end })

---------------------------------------------------------------------------
-- Dispatch and installation
---------------------------------------------------------------------------

local function summary()
  local info = P.ProbeModule and P.ProbeModule.last and P.ProbeModule.last.info or {}
  say('GoldIntel ' .. P.VERSION .. '  -  gold analytics for WoW Forever (client ' .. tostring(info.gameVersion) .. ')')
  say(statusLine())
  for _, line in ipairs(coreLines()) do say(line) end
  if GI.Capabilities then
    local s = GI.Capabilities.Summary()
    local function n(kind, level) return s[kind][level] or 0 end
    say('events: registered=' .. n('event', 'registered') .. ' delivered=' .. n('event', 'delivered')
      .. ' payloadUsable=' .. n('event', 'payloadUsable') .. ' blocked=' .. n('event', 'blocked')
      .. '   api: present=' .. n('api', 'present') .. ' absent=' .. n('api', 'absent') .. ' unknown=' .. n('api', 'unknown'))
  end
  say('Type /gi help for commands. Collection of gold data starts in a later version.')
end

--- Dispatches one command line.
function Commands.Run(text, minimal)
  local cmd, args, rest = parse(text)
  if minimal == nil then minimal = Commands.minimal end
  if cmd == '' then
    if minimal then registry.status.fn({}, '') else summary() end
    return
  end
  local spec = registry[cmd]
  if not spec or (minimal and not MINIMAL[cmd]) then
    say('unknown command "' .. cmd .. '". Type /gi help.')
    return
  end
  local ok, err = pcall(spec.fn, args, rest)
  if not ok then P.Diag('error', 'Slash', 'command ' .. cmd .. ' failed: ' .. tostring(err)) ; say('command failed: ' .. tostring(err)) end
  if GI.Capabilities then GI.Capabilities.Touch() end      -- save this command's output with the data soon
end

--- Registers /gi with the client. minimal = only the platform commands.
function Commands.Install(minimal)
  Commands.minimal = minimal and true or false
  return P.RegisterSlash('GOLDINTEL', '/gi', function(text) Commands.Run(text) end)
end

if GI.Core then GI.Core.Service('commands', Commands) end
]=====] },
{ path = "Collect/Context.lua", src = [=====[
-- GoldIntel / Collect / Context.lua                                     (Phase 3b-1, Architecture AC-3)
--
-- PURPOSE
--  Knows which game windows are open (loot, vendor, mail, trade, auction house) and for how long, from the
--  normalized events the Platform adapters emit. Nothing here touches the client.
--      Context.Active()   -> array of { kind, id, open, openedGT, closedGT, by }   open or inside the linger
--      Context.Stats()    -> per kind { opened, closed, byCounts, duplicateOpens, strayCloses }
--      Context.Clear()    -> drops every context (collect off, reload; AC-8)
--  A context that closed stays "active" for LINGER seconds (1.0, D-065) so money that lands after the
--  window closed can still be matched (trade money 0.394 s, E-31). Closing is idempotent (E-31, E-33).
--  The quest turn-in has no window: it opens and closes in the same instant and lingers like the others.
--  CONTEXT_CHANGED { kind, open, id } is fired on the Bus on every open and close (Contracts F3b).
--
-- Nothing is stored. After /reload every context is gone and unmatched money becomes OTHER (AC-8).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
local Core = GI.Core
assert(P and Core, 'Platform and Core must be loaded before Collect/Context.lua')

local Context = Core.Module('Context', {})
GI.Context = Context

Context.LINGER = 1.0
Context.KINDS = { 'loot', 'vendor', 'mail', 'trade', 'ah', 'quest' }

local records = {}      -- kind -> { id, open, openedGT, closedGT, by }
local stats = {}
local nextId = 0

local function freshStats()
  stats = {}
  for _, kind in ipairs(Context.KINDS) do
    stats[kind] = { opened = 0, closed = 0, byCounts = {}, duplicateOpens = 0, strayCloses = 0 }
  end
end
freshStats()

local function nowGT()
  local _, gt = P.Now()
  return gt
end

local function fire(kind, open, id)
  if GI.Bus then GI.Bus.Fire('CONTEXT_CHANGED', { kind = kind, open = open, id = id }) end
end

local function openKind(kind)
  local r = records[kind]
  local s = stats[kind]
  if r and r.open then
    s.duplicateOpens = s.duplicateOpens + 1
    return false
  end
  nextId = nextId + 1
  records[kind] = { id = nextId, open = true, openedGT = nowGT() }
  s.opened = s.opened + 1
  fire(kind, true, nextId)
  return true
end

local function closeKind(kind, by)
  local r = records[kind]
  local s = stats[kind]
  if not r or not r.open then
    s.strayCloses = s.strayCloses + 1
    return false
  end
  r.open = false
  r.closedGT = nowGT()
  r.by = by or 'close'
  s.closed = s.closed + 1
  s.byCounts[r.by] = (s.byCounts[r.by] or 0) + 1
  fire(kind, false, r.id)
  return true
end

Context.Open, Context.Close = openKind, closeKind

--- Contexts that are open or closed less than LINGER seconds ago, oldest first.
function Context.Active()
  local gt = nowGT()
  local out = {}
  for _, kind in ipairs(Context.KINDS) do
    local r = records[kind]
    if r and (r.open or (r.closedGT and gt - r.closedGT <= Context.LINGER)) then
      out[#out + 1] = { kind = kind, id = r.id, open = r.open, openedGT = r.openedGT, closedGT = r.closedGT, by = r.by }
    end
  end
  table.sort(out, function(a, b) return a.openedGT < b.openedGT end)
  return out
end

--- True when `kind` is open or inside its linger.
function Context.IsActive(kind)
  local r = records[kind]
  if not r then return false end
  if r.open then return true end
  return r.closedGT ~= nil and nowGT() - r.closedGT <= Context.LINGER
end

function Context.Stats()
  local out = {}
  for kind, s in pairs(stats) do
    local copy = { opened = s.opened, closed = s.closed, duplicateOpens = s.duplicateOpens,
                   strayCloses = s.strayCloses, byCounts = {} }
    for k, v in pairs(s.byCounts) do copy.byCounts[k] = v end
    out[kind] = copy
  end
  return out
end

--- Drops every context without firing events (collect off, reload).
function Context.Clear()
  records = {}
end

function Context.Reset()
  records = {}
  nextId = 0
  freshStats()
end

---------------------------------------------------------------------------
-- Wiring: the Platform adapters emit these; they emit nothing while collect is off.
---------------------------------------------------------------------------

P.On('P_LOOT_OPEN', function() openKind('loot') end)
P.On('P_LOOT_CLOSE', function(p) closeKind('loot', p.by) end)
P.On('P_VENDOR_OPEN', function() openKind('vendor') end)
P.On('P_VENDOR_CLOSE', function() closeKind('vendor', 'close') end)
P.On('P_MAIL_OPEN', function() openKind('mail') end)
P.On('P_MAIL_CLOSE', function() closeKind('mail', 'close') end)
P.On('P_TRADE_OPEN', function() openKind('trade') end)
P.On('P_TRADE_CLOSE', function() closeKind('trade', 'close') end)
P.On('P_AH_OPEN', function() openKind('ah') end)
P.On('P_AH_CLOSE', function() closeKind('ah', 'close') end)
P.On('P_QUEST_DONE', function()
  if openKind('quest') then closeKind('quest', 'instant') end
end)
]=====] },
{ path = "Collect/Collector.lua", src = [=====[
-- GoldIntel / Collect / Collector.lua                                   (Phase 3b-1, D-074)
--
-- PURPOSE
--  Switches the collector events on and off, in groups, with fault containment, and reports delivery
--  counters. It builds NO ledger and no expectations (3b-2). It registers only events on the allow-list
--  (Platform.COLLECTOR_EVENTS, AC-1) and only through Platform.Events.Bind.
--
--  /gi collect status | on [G1..G8] [plain] | off | stats | reset | allow EVENT
--
-- RULES
--  * Collect is OFF after every login and /reload. The state is never persisted in 3b-1 (A-3).
--  * Fault containment (D-074): before each registration the event name is written to
--    char.collect.pending. If the client ever shows a blocked-action popup, the next load finds `pending`
--    still set, quarantines THAT event (char.collect.quarantine) and skips it from then on; every other
--    event keeps working. `/gi collect allow EVENT` lifts the quarantine.
--  * Groups register in a fixed order, the riskiest event (UNIT_SPELLCAST_SUCCEEDED, G5) last.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
local Core = GI.Core
assert(P and Core, 'Platform and Core must be loaded before Collect/Collector.lua')

local Collector = Core.Module('Collector', { deps = { 'Context' } })
GI.Collector = Collector

Collector.GROUPS = {
  { name = 'G1', label = 'loot and quest', events = { 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'QUEST_TURNED_IN' } },
  { name = 'G2', label = 'vendor', events = { 'MERCHANT_SHOW', 'MERCHANT_CLOSED' } },
  { name = 'G3', label = 'mail and trade', events = { 'MAIL_INBOX_UPDATE', 'TRADE_SHOW', 'TRADE_CLOSED',
                                                     'TRADE_ACCEPT_UPDATE', 'TRADE_MONEY_CHANGED' } },
  { name = 'G4', label = 'items and bags', events = { 'BAG_UPDATE_DELAYED', 'GET_ITEM_INFO_RECEIVED' } },
  { name = 'G5', label = 'casts', events = { 'UNIT_SPELLCAST_SUCCEEDED' } },
  { name = 'G6', label = 'auction posting', events = { 'AUCTION_HOUSE_AUCTION_CREATED' } },
  { name = 'G7', label = 'coin chat (loot signal)', events = { 'CHAT_MSG_MONEY' } },
  { name = 'G8', label = 'item chat (evidence only)', events = { 'CHAT_MSG_LOOT' } },
}

local enabled = false
local registered = {}          -- event -> handler
local memoryJournal = nil      -- used when the Store is not available
Collector.recovered = nil      -- event quarantined at startup because `pending` was still set
Collector.lastResult = nil

---------------------------------------------------------------------------
-- Journal (char.collect = { pending = EVENT?, quarantine = { EVENT = true }, lastStats = {...} })
---------------------------------------------------------------------------

local function journal()
  local store = GI.Store
  if store and store.Char then
    local ok, char = pcall(store.Char)
    if ok and type(char) == 'table' then
      if type(char.collect) ~= 'table' then char.collect = {} end
      if type(char.collect.quarantine) ~= 'table' then char.collect.quarantine = {} end
      return char.collect
    end
  end
  memoryJournal = memoryJournal or { quarantine = {} }
  return memoryJournal
end

function Collector.Journal() return journal() end

--- Names of quarantined events (sorted).
function Collector.Quarantined()
  local out = {}
  for name, v in pairs(journal().quarantine) do
    if v then out[#out + 1] = name end
  end
  table.sort(out)
  return out
end

--- Startup check: an unfinished registration means the previous session ended inside RegisterEvent.
function Collector.Recover()
  local j = journal()
  if type(j.pending) == 'string' and j.pending ~= '' then
    local event = j.pending
    j.quarantine[event] = true
    Collector.recovered = event
    P.Diag('warn', 'Collector', event .. ' was being registered when the last session ended: quarantined')
    j.pending = nil
    return event
  end
  return nil
end

function Collector.Allow(event)
  local j = journal()
  if not j.quarantine[event] then return false end
  j.quarantine[event] = nil
  if Collector.recovered == event then Collector.recovered = nil end
  return true
end

---------------------------------------------------------------------------
-- Adapter lookup
---------------------------------------------------------------------------

local function adapterFor(event)
  for _, a in ipairs(P.CollectAdapters) do
    if a.handlers and a.handlers[event] then return a, a.handlers[event] end
  end
  return nil
end

function Collector.IsEnabled() return enabled end

--- Sorted list of the raw events currently registered by the collector.
function Collector.Registered()
  local out = {}
  for name in pairs(registered) do out[#out + 1] = name end
  table.sort(out)
  return out
end

---------------------------------------------------------------------------
-- On / Off
---------------------------------------------------------------------------

local function groupByName(name)
  for _, g in ipairs(Collector.GROUPS) do
    if g.name == name then return g end
  end
  return nil
end

--- Registers one or all groups. opts.group = 'G3' (nil = all), opts.plain = true skips unit filtering.
-- Returns { registered = n, failed = {...}, skipped = {...} } or nil plus a reason.
function Collector.On(opts)
  opts = opts or {}
  local groups = Collector.GROUPS
  if opts.group then
    local g = groupByName(opts.group)
    if not g then return nil, 'unknown group ' .. tostring(opts.group) end
    groups = { g }
  end
  local j = journal()
  local result = { registered = 0, failed = {}, skipped = {}, already = 0 }
  for _, g in ipairs(groups) do
    for _, event in ipairs(g.events) do
      if registered[event] then
        result.already = result.already + 1
      elseif j.quarantine[event] then
        result.skipped[#result.skipped + 1] = event
      else
        local adapter, handler = adapterFor(event)
        if not adapter then
          result.failed[#result.failed + 1] = event .. ' (no adapter)'
        else
          j.pending = event                                   -- written BEFORE the call (fault containment)
          local bindOpts = nil
          if not opts.plain and adapter.unitFilter and adapter.unitFilter[event] then
            bindOpts = { unit = adapter.unitFilter[event] }
          end
          local ok, err = P.Events.Bind(event, handler, bindOpts)
          local stat = P.Events.Stats(event)
          if ok and stat.registered ~= false then
            registered[event] = handler
            result.registered = result.registered + 1
          else
            result.failed[#result.failed + 1] = event .. ' (' .. tostring(err or 'not in effect') .. ')'
          end
          j.pending = nil                                     -- cleared only after the call returned
        end
      end
    end
  end
  for _, a in ipairs(P.CollectAdapters) do
    if a.start then
      local ok, err = pcall(a.start)
      if not ok then P.Diag('error', 'Collector', 'adapter ' .. tostring(a.name) .. ' failed to start: ' .. tostring(err)) end
    end
  end
  enabled = next(registered) ~= nil
  Collector.lastResult = result
  if enabled and GI.Ledger then
    local ok, why = GI.Ledger.OnCollectOn(opts.group ~= nil)
    result.ledger = ok and 'interval started' or ('not started: ' .. tostring(why))
  end
  return result
end

--- Unregisters every collector event, stops the adapters and drops all contexts.
function Collector.Off()
  local n = 0
  if GI.Ledger then GI.Ledger.OnCollectOff() end      -- ends the ledger interval while contexts still exist (AC-9)
  for event, handler in pairs(registered) do
    P.Events.Unbind(event, handler)
    registered[event] = nil
    n = n + 1
  end
  for _, a in ipairs(P.CollectAdapters) do
    if a.stop then pcall(a.stop) end
  end
  if GI.Context then GI.Context.Clear() end
  enabled = false
  return n
end

---------------------------------------------------------------------------
-- Statistics
---------------------------------------------------------------------------

--- Rows for every collector event (registered or not), in group order, plus totals.
function Collector.Stats()
  local rows = {}
  local total = { received = 0, kept = 0, dropped = 0, errors = 0 }
  for _, g in ipairs(Collector.GROUPS) do
    for _, event in ipairs(g.events) do
      local c = P.Events.Counters(event) or { received = 0, kept = 0, dropped = 0, errors = 0, maxPerSec = 0,
                                              cpuTotalMs = 0, cpuMaxMs = 0 }
      rows[#rows + 1] = { group = g.name, event = event, registered = registered[event] ~= nil,
                          via = P.Events.RegisteredVia(event), received = c.received, kept = c.kept,
                          dropped = c.dropped, errors = c.errors, maxPerSec = c.maxPerSec,
                          cpuTotalMs = c.cpuTotalMs, cpuMaxMs = c.cpuMaxMs }
      total.received = total.received + c.received
      total.kept = total.kept + c.kept
      total.dropped = total.dropped + c.dropped
      total.errors = total.errors + c.errors
    end
  end
  return { rows = rows, total = total }
end

--- Adapter and context statistics the validation report needs (loot closes by clear or timeout, ...).
function Collector.Details()
  local d = {}
  if P.LootModule then d.loot = P.LootModule.stats end
  if P.MerchantModule then d.vendor = P.MerchantModule.stats end
  if P.TradeModule then d.trade = P.TradeModule.stats end
  if P.MailModule then d.mail = P.MailModule.stats end
  if P.AuctionModule then d.ah = P.AuctionModule.stats end
  if P.QuestModule then d.quest = P.QuestModule.stats end
  if P.ItemsModule then d.items = P.ItemsModule.stats end
  if P.BagsModule then d.bags = P.BagsModule.stats end
  if P.Unit then d.cast = P.Unit.castStats end
  d.context = GI.Context and GI.Context.Stats() or {}
  return d
end

function Collector.Reset()
  P.Events.ResetCounters()
  for _, mod in ipairs({ P.LootModule, P.MerchantModule, P.TradeModule, P.MailModule, P.AuctionModule,
                         P.QuestModule, P.ItemsModule, P.BagsModule }) do
    if mod and mod.stats then
      for k in pairs(mod.stats) do mod.stats[k] = 0 end
    end
  end
  if P.Unit then P.Unit.castStats = { player = 0, secret = 0 } end
  if GI.Context then GI.Context.Reset() end
end

--- Compact counts-only summary kept in the character data (about 1.5 KB).
local function summaryForSave()
  local s = Collector.Stats()
  local out = { events = {}, total = s.total }
  for _, r in ipairs(s.rows) do
    if r.received > 0 then
      out.events[r.event] = { r.received, r.kept, r.dropped, r.errors, r.maxPerSec }
    end
  end
  local d = Collector.Details()
  if d.loot then
    out.loot = { opened = d.loot.opened, frame = d.loot.closedFrame, timeout = d.loot.closedTimeout,
                 replaced = d.loot.closedReplaced, clears = d.loot.clears, late = d.loot.lateClears,
                 dup = d.loot.dupClears, slotUnreadable = d.loot.unreadable, frameUnreadable = d.loot.frameUnreadable,
                 legacy = d.loot.legacyWindows, maxOpenSec = d.loot.maxOpenSec }
  end
  return out
end

Collector.SummaryForSave = summaryForSave

function Collector.OnInitialize()
  Collector.Recover()
end

function Collector.OnLogout()
  local ok, err = pcall(function() journal().lastStats = summaryForSave() end)
  if not ok then P.Diag('warn', 'Collector', 'could not save the counter summary: ' .. tostring(err)) end
end

---------------------------------------------------------------------------
-- /gi collect
---------------------------------------------------------------------------

local function say(line) P.Print(line) end

local function statusLines()
  local lines = {}
  lines[#lines + 1] = 'collect: ' .. (enabled and 'ON' or 'off') .. ', ' .. #Collector.Registered() .. ' events registered'
  for _, g in ipairs(Collector.GROUPS) do
    local n = 0
    for _, e in ipairs(g.events) do if registered[e] then n = n + 1 end end
    lines[#lines + 1] = '  ' .. g.name .. ' (' .. g.label .. '): ' .. n .. '/' .. #g.events
  end
  local q = Collector.Quarantined()
  lines[#lines + 1] = 'quarantined: ' .. (#q > 0 and table.concat(q, ', ') or 'none')
  if Collector.recovered then
    lines[#lines + 1] = 'NOTE: ' .. Collector.recovered .. ' was quarantined at startup (an earlier registration did not finish)'
  end
  if P.IsAddonLoaded('GoldIntelDiag') then
    lines[#lines + 1] = 'WARNING: GoldIntelDiag is loaded; disable it for validation sessions (D-072)'
  end
  return lines
end

Collector.StatusLines = statusLines

local function fmt(n) return string.format('%.1f', n or 0) end

local function statsLines()
  local lines = {}
  local s = Collector.Stats()
  lines[#lines + 1] = 'event                            recv  kept  drop  err  max/s  cpu ms (total/max)  via'
  for _, r in ipairs(s.rows) do
    lines[#lines + 1] = string.format('%-32s %5d %5d %5d %4d %6d  %s/%s  %s%s', r.event, r.received, r.kept, r.dropped,
      r.errors, r.maxPerSec, fmt(r.cpuTotalMs), fmt(r.cpuMaxMs), r.via or '-', r.registered and '' or '  (not registered)')
  end
  lines[#lines + 1] = string.format('total: received %d, kept %d, dropped %d, errors %d', s.total.received, s.total.kept,
    s.total.dropped, s.total.errors)
  local d = Collector.Details()
  local l = d.loot or {}
  lines[#lines + 1] = string.format('loot windows: opened %d, closed by frame %d, by timeout %d, replaced %d; longest open %.1f s',
    l.opened or 0, l.closedFrame or 0, l.closedTimeout or 0, l.closedReplaced or 0, l.maxOpenSec or 0)
  lines[#lines + 1] = string.format('loot slot clears (information only): seen %d, duplicates %d, late %d; unreadable: frame %d (legacy rule windows %d), slots %d',
    l.clears or 0, l.dupClears or 0, l.lateClears or 0, l.frameUnreadable or 0, l.legacyWindows or 0, l.unreadable or 0)
  for _, kind in ipairs(GI.Context and GI.Context.KINDS or {}) do
    local c = d.context[kind]
    if c and (c.opened > 0 or c.strayCloses > 0) then
      lines[#lines + 1] = string.format('context %-6s opened %d, closed %d, duplicate opens %d, stray closes %d',
        kind, c.opened, c.closed, c.duplicateOpens, c.strayCloses)
    end
  end
  local m = d.mail or {}
  lines[#lines + 1] = string.format('mail: updates %d, stale (box closed) %d, snapshots %d; vendor duplicate closes %d; trade duplicate closes %d; casts kept %d, secret %d',
    m.updates or 0, m.staleUpdates or 0, m.snapshots or 0, (d.vendor or {}).duplicateCloses or 0,
    (d.trade or {}).duplicateCloses or 0, (d.cast or {}).player or 0, (d.cast or {}).secret or 0)
  return lines
end

Collector.StatsLines = statsLines

if GI.Commands then
  GI.Commands.Register('collect', {
    help = 'collector events: status | on [G1..G8] [plain] | off | stats | reset | allow EVENT',
    usage = 'collect [status|on [G1-G8] [plain]|off|stats|reset|allow EVENT]',
    fn = function(args)
      local sub = args[1] or 'status'
      if sub == 'status' then
        for _, line in ipairs(statusLines()) do say(line) end
      elseif sub == 'on' then
        local opts = {}
        for i = 2, #args do
          local a = args[i]
          if a == 'plain' then opts.plain = true
          elseif a:match('^[Gg]%d$') then opts.group = a:upper()
          else say('collect on: unknown option ' .. a); return end
        end
        local r, err = Collector.On(opts)
        if not r then say('collect on failed: ' .. tostring(err)); return end
        say(string.format('collect: %s, %d registered now, %d already, %d failed, %d skipped by quarantine',
          enabled and 'on' or 'off', r.registered, r.already, #r.failed, #r.skipped))
        for _, f in ipairs(r.failed) do say('  failed: ' .. f) end
        for _, f in ipairs(r.skipped) do say('  skipped: ' .. f) end
        if r.ledger then say('  ledger: ' .. r.ledger) end
      elseif sub == 'off' then
        say('collect: off, ' .. Collector.Off() .. ' events unregistered')
      elseif sub == 'stats' then
        for _, line in ipairs(statsLines()) do say(line) end
      elseif sub == 'reset' then
        Collector.Reset()
        say('collect: counters reset')
      elseif sub == 'allow' then
        local event = args[2] and args[2]:upper() or nil
        if not event then say('usage: /gi collect allow EVENT'); return end
        say(Collector.Allow(event) and ('collect: ' .. event .. ' released from quarantine') or ('collect: ' .. event .. ' was not quarantined'))
      else
        say('usage: /gi collect [status|on [G1-G8] [plain]|off|stats|reset|allow EVENT]')
      end
    end,
  })
end
]=====] },
{ path = "Collect/Expectations.lua", src = [=====[
-- GoldIntel / Collect / Expectations.lua                          (Phase 3b-2 M1, Architecture AC-10, AC-11)
--
-- PURPOSE
--  A registry of "money we expect to see": exact expectations (known amount, possibly split in components)
--  and window expectations (unknown amount, backed by an open context such as a merchant or trade window).
--  This module knows NOTHING about WoW, loot, mail or trade. Sources.lua (M2) is the only translator.
--  It is pure: no Platform calls, no clock. Every function that needs time takes it as an argument (gt).
--
--      local X = GI.Expectations.New()
--      X:Add{ src, mode='exact'|'window', copper=n (magnitude), sign=1|-1, t0, ttl>=1.0,
--             ctx?, ref?, settle?, comp?, comps?, hold? }          -> id | nil, err
--          hold (exact only): no expiry until Close(id, gt) -- used while the context that explains it is open (AC-11)
--          comps = { {src, copper (SIGNED), comp?, settle?}, ... } must sum to sign*copper (AH sale split, D-070)
--      X:Close(id, gt)      window or held exact: the context ended; stays active for ttl (the linger) after gt
--      X:Extend(id, gt)     exact: keeps it alive at least until gt (context still active, AC-11)
--      X:Consume(id)        exact: matched, removed
--      X:Active(gt, sign?, mode?) -> array sorted by priority, then t0, then id
--      X:Expire(gt)         removes everything no longer active; exact ones count as `unmatched`
--      X:Subscribe(fn)      fn(kind, exp) on 'add' and 'close' (the Reconciler retries pending deltas)
--      X:Stats()            { added, consumed, unmatched, windowsClosed, active }
--
-- Boundary rule: an expectation is active while  gt <= expireGT  (inclusive).  expireGT = t0 + ttl for exact,
-- nil (open) then closedGT + ttl for window.
--
-- Priority (D-065): trade, mail, vendor, quest, loot, AH.

local ADDON, GI = ...
GI = GI or {}

local X = {}
GI.Expectations = X

X.MIN_TTL = 1.0

X.PRIORITY = {
  trade = 1,
  mailMoney = 2, codIn = 2, codOut = 2, ahSale = 2, ahCut = 2, ahDepositRefund = 2,
  vendor = 3, purchase = 3, repair = 3, buyback = 3,
  quest = 4,
  loot = 5,
  ahDeposit = 6, ahPurchase = 6,
}
X.PRIORITY_DEFAULT = 9

function X.PrioOf(src) return X.PRIORITY[src] or X.PRIORITY_DEFAULT end

local Store = {}
Store.__index = Store

--- Diagnostic tap (Ledger/Trace.lua): fn(event, expectation, gt). Never changes behaviour; its errors are swallowed.
local function tapped(self, ev, e, gt)
  if self.tap then pcall(self.tap, ev, e, gt) end
end

function X.New()
  return setmetatable({ list = {}, nextId = 0, subs = {},
    st = { added = 0, consumed = 0, unmatched = 0, windowsClosed = 0 } }, Store)
end

local function sgn(n) if n > 0 then return 1 elseif n < 0 then return -1 end return 0 end

function Store:Add(spec)
  if type(spec) ~= 'table' then return nil, 'spec' end
  if spec.mode ~= 'exact' and spec.mode ~= 'window' then return nil, 'mode' end
  if spec.sign ~= 1 and spec.sign ~= -1 then return nil, 'sign' end
  if type(spec.t0) ~= 'number' then return nil, 't0' end
  if type(spec.ttl) ~= 'number' or spec.ttl < X.MIN_TTL then return nil, 'ttl' end
  if type(spec.src) ~= 'string' then return nil, 'src' end
  local e = { src = spec.src, mode = spec.mode, sign = spec.sign, t0 = spec.t0, ttl = spec.ttl,
    ctx = spec.ctx, ref = spec.ref, settle = spec.settle, comp = spec.comp, prio = X.PrioOf(spec.src) }
  if spec.mode == 'exact' then
    if type(spec.copper) ~= 'number' or spec.copper <= 0 or spec.copper ~= math.floor(spec.copper) then
      return nil, 'copper'
    end
    e.copper = spec.copper
    if spec.comps then
      local sum = 0
      for _, c in ipairs(spec.comps) do
        if type(c.copper) ~= 'number' or c.copper == 0 or c.copper ~= math.floor(c.copper) then return nil, 'comp' end
        sum = sum + c.copper
      end
      if #spec.comps == 0 or sum ~= spec.sign * spec.copper then return nil, 'comps' end
      e.comps = {}
      for i, c in ipairs(spec.comps) do
        e.comps[i] = { src = c.src, copper = c.copper, comp = c.comp, settle = c.settle }
      end
    end
    e.expireGT = spec.t0 + spec.ttl
    if spec.hold then e.hold = true; e.expireGT = nil end
  else
    if spec.copper ~= nil or spec.comps ~= nil then return nil, 'window has no amount' end
    e.expireGT = nil
  end
  self.nextId = self.nextId + 1
  e.id = self.nextId
  self.list[#self.list + 1] = e
  self.st.added = self.st.added + 1
  tapped(self, 'add', e)
  for _, fn in ipairs(self.subs) do fn('add', e) end
  return e.id
end

function Store:Get(id)
  for _, e in ipairs(self.list) do if e.id == id then return e end end
end

function Store:Close(id, gt)
  local e = self:Get(id)
  if not e or e.closedGT or not (e.mode == 'window' or e.hold) then return false end
  e.closedGT = gt
  local base = e.mode == 'exact' and (e.t0 + e.ttl) or 0
  e.expireGT = math.max(gt + e.ttl, base)
  self.st.windowsClosed = self.st.windowsClosed + 1
  tapped(self, 'close', e, gt)
  for _, fn in ipairs(self.subs) do fn('close', e) end
  return true
end

function Store:Extend(id, gt)
  local e = self:Get(id)
  if not e or e.mode ~= 'exact' then return false end
  if gt > e.expireGT then e.expireGT = gt end
  return true
end

function Store:Consume(id)
  for i, e in ipairs(self.list) do
    if e.id == id then
      if e.mode ~= 'exact' then return false end
      table.remove(self.list, i)
      self.st.consumed = self.st.consumed + 1
      tapped(self, 'consume', e)
      return true
    end
  end
  return false
end

local function isActive(e, gt)
  if e.expireGT == nil then return true end       -- open window
  return gt <= e.expireGT
end

local function before(a, b)
  if a.prio ~= b.prio then return a.prio < b.prio end
  if a.t0 ~= b.t0 then return a.t0 < b.t0 end
  return a.id < b.id
end

function Store:Active(gt, sign, mode)
  local out = {}
  for _, e in ipairs(self.list) do
    if isActive(e, gt) and (sign == nil or e.sign == sign) and (mode == nil or e.mode == mode) then
      out[#out + 1] = e
    end
  end
  table.sort(out, before)
  return out
end

function Store:Expire(gt)
  local kept, gone = {}, {}
  for _, e in ipairs(self.list) do
    if isActive(e, gt) then kept[#kept + 1] = e
    else
      gone[#gone + 1] = e
      if e.mode == 'exact' then self.st.unmatched = self.st.unmatched + 1; tapped(self, 'expire', e, gt) end
    end
  end
  self.list = kept
  return gone
end

--- Ends an interval (collect off): every remaining exact expectation is unmatched, windows are dropped.
function Store:Clear()
  for _, e in ipairs(self.list) do
    if e.mode == 'exact' then self.st.unmatched = self.st.unmatched + 1; tapped(self, 'clear', e) end
  end
  self.list = {}
end

function Store:Subscribe(fn) self.subs[#self.subs + 1] = fn end

function Store:Stats()
  return { added = self.st.added, consumed = self.st.consumed, unmatched = self.st.unmatched,
    windowsClosed = self.st.windowsClosed, active = #self.list }
end

X.sign = sgn
]=====] },
{ path = "Collect/Stamps.lua", src = [=====[
-- GoldIntel / Collect / Stamps.lua                                 (Phase 3b-2 M2, Architecture AC-10)
--
-- PURPOSE
--  Adds the location stamp (loc, locConf), the activity stamp (act, actConf) and `creditable` to a finished
--  ledger entry. No engine (Phase 4): activity is a pure function of the source, plus the last gathering cast
--  for game-object loot. Pure: no Platform calls; times and the cast lookup are injected.
--
--      local S = GI.Stamps.New{ lastCast = function(kind) -> gt, spellID | nil end }
--      S:NoteLoc(loc, gt)         the last good Where() (from P_TICK / P_ZONE)
--      S:Apply(entry)             fills entry.act, actConf, loc, locConf, creditable (entry.t is the delta time)
--
-- Location: fresh when the last good Where() is at most 5 s old, stale when older, none when never seen.
-- Creditable (D-044, D-064): only creature or game-object loot coin AND a fresh location. Never quest, mail,
-- trade, vendor, other.
--
-- Activity (judgment calls made in M2, listed in the M2 report): creature loot GRIND (med); game-object loot
-- GATHER (herb or mine cast within 30 s) or FISH (fish cast within 30 s) with high confidence, otherwise OTHER
-- (low); coin from a chat share with no known corpse or object LOOT (med, never credited to a place);
-- vendor and purchase VENDOR; quest QUEST; trade TRADE; every mail-paid source MAIL; unknown OTHER.

local ADDON, GI = ...
GI = GI or {}

local S = {}
GI.Stamps = S

S.FRESH = 5.0
S.CAST_WINDOW = 30.0

S.BY_SOURCE = {
  vendor = 'VENDOR', purchase = 'VENDOR', repair = 'VENDOR', buyback = 'VENDOR',
  quest = 'QUEST', trade = 'TRADE',
  mailMoney = 'MAIL', codIn = 'MAIL', codOut = 'MAIL', ahSale = 'MAIL', ahCut = 'MAIL', ahDepositRefund = 'MAIL',
}

local Obj = {}
Obj.__index = Obj

function S.New(opts)
  opts = opts or {}
  return setmetatable({ lastCast = opts.lastCast, loc = nil, locGT = nil }, Obj)
end

function Obj:NoteLoc(loc, gt)
  if type(loc) ~= 'table' or type(gt) ~= 'number' then return end
  self.loc = { mapID = loc.mapID, zone = loc.zone, sub = loc.sub, x = loc.x, y = loc.y }
  self.locGT = gt
end

function Obj:Clear() self.loc, self.locGT = nil, nil end

--- Returns loc (a copy) or nil, plus 'fresh' | 'stale' | 'none'.
function Obj:Loc(t)
  if not self.loc then return nil, 'none' end
  local age = t - self.locGT
  local copy = { mapID = self.loc.mapID, zone = self.loc.zone, sub = self.loc.sub, x = self.loc.x, y = self.loc.y }
  if age <= S.FRESH then return copy, 'fresh' end
  return copy, 'stale'
end

local GATHER = { herb = 'GATHER', mine = 'GATHER', fish = 'FISH' }

function Obj:Activity(e)
  local fixed = S.BY_SOURCE[e.src]
  if fixed then return fixed, e.conf or 'high' end
  if e.src == 'loot' then
    local st = e.ref and e.ref.sourceType
    if st == 'creature' then return 'GRIND', 'med' end
    if not st and e.ref and e.ref.chat then return 'LOOT', 'med' end      -- coin chat share, source unknown (D-078, user 2026-10-18)
    if st == 'object' then
      local act = self:ObjectActivity(e.t)
      if act then return act, 'high' end
    end
  end
  return 'OTHER', 'low'
end

--- GATHER or FISH when a herb, mine or fish cast happened within CAST_WINDOW before `t`, else nil.
function Obj:ObjectActivity(t)
  if not self.lastCast then return nil end
  local bestAct, bestGT
  for kind, act in pairs(GATHER) do
    local gt = self.lastCast(kind)
    if gt and t - gt >= 0 - 1e-9 and t - gt <= S.CAST_WINDOW and (not bestGT or gt > bestGT) then
      bestAct, bestGT = act, gt
    end
  end
  return bestAct
end

--- Activity of an ITEM loot window (3b-3 M2; D-082: skinning is GATHER, user 2026-10-19).
--   w = { sourceType = 'creature'|'object'|'item'|..., skinning = boolean, t = gt }
-- 'skinning' is decided by ItemSources (a repeat window of the same corpse after a skin cast, E-24), never here.
-- Creature window: GATHER (high) when skinning, otherwise GRIND (med). Object window: as for coin. Item window
-- (disenchant) and anything else: OTHER (low).
function Obj:ItemActivity(w)
  if w.sourceType == 'creature' then
    if w.skinning then return 'GATHER', 'high' end
    return 'GRIND', 'med'
  end
  if w.sourceType == 'object' then
    local act = self:ObjectActivity(w.t)
    if act then return act, 'high' end
  end
  return 'OTHER', 'low'
end

function Obj:Apply(e)
  e.act, e.actConf = self:Activity(e)
  e.loc, e.locConf = self:Loc(e.t)
  local st = e.ref and e.ref.sourceType
  e.creditable = (e.src == 'loot' and (st == 'creature' or st == 'object') and e.locConf == 'fresh') or false
  return e
end
]=====] },
{ path = "Collect/Reconciler.lua", src = [=====[
-- GoldIntel / Collect / Reconciler.lua                            (Phase 3b-2 M1, Architecture 19, AC-9, AC-13)
--
-- PURPOSE
--  Turns money deltas into ledger entries that sum EXACTLY to the deltas. Source-agnostic (AC-10): it only
--  sees an Expectations store and delta numbers. Pure: no Platform calls, no clock, no storage; time is an
--  argument. The sink receives finished entries; stamps (act, loc, creditable) are added by opts.decorate.
--
--      local R = GI.Reconciler.New{ exp = store, sink = function(entry) end, decorate = function(entry) end? }
--      R:Begin(gt)          starts an interval (collect on). Deltas outside an interval are ignored (AC-9).
--      R:Money(copper, gt, gap?)   one P_MONEY delta
--      R:Tick(gt)           retries pending deltas, turns the ones older than WAIT into OTHER, expires expectations
--      R:End(gt)            collect off: pending deltas become OTHER at once, expectations are cleared
--      R:Stats()            see below ; R:Check() -> ok, sumDeltas, sumEntries, pendingSum
--
-- ALGORITHM for a delta d (never 0; zero is ignored):
--   gap          -> one OTHER entry, comp='gap' (AC-13)
--   exact pass   -> first combination (size 1..3 of the 8 highest-priority exact expectations with the sign
--                   of d) whose signed amounts sum to exactly d. Each component becomes an entry, conf high.
--   window pass  -> the highest-priority active window with the sign of d takes all of d, conf med, or low
--                   when another active window with that sign has a different src (competing windows)
--   else         -> pending. Pending deltas are retried whenever an expectation is added or a window closes,
--                   and at Tick. After WAIT (1.0 s, D-065; opts.wait may lengthen it, 3b-2 M5: the coin chat line
--                   arrives up to 1.0 s after the money change) a pending delta becomes OTHER, conf low.
-- No expectation is ever matched across two deltas (Q-4): an unmatched expectation just expires.

local ADDON, GI = ...
GI = GI or {}

local R = {}
GI.Reconciler = R

R.WAIT = 1.0
R.MAX_CANDIDATES = 8
R.MAX_COMBO = 3

local Rec = {}
Rec.__index = Rec

function R.New(opts)
  opts = opts or {}
  assert(opts.exp, 'Reconciler.New needs an Expectations store')
  local self = setmetatable({
    exp = opts.exp, sink = opts.sink or function() end, decorate = opts.decorate,
    wait = (type(opts.wait) == 'number' and opts.wait >= R.WAIT) and opts.wait or R.WAIT,
    active = false, pending = {},
    sumDeltas = 0, sumEntries = 0, ignored = 0,
    n = 0, value = 0, otherN = 0, otherValue = 0, lowN = 0, largestOther = 0,
    gapN = 0, gapValue = 0, bySrc = {},
  }, Rec)
  opts.exp:Subscribe(function() if self.active then self:_retry(self.lastGT or 0) end end)
  return self
end

local function mag(n) return n < 0 and -n or n end

function Rec:_emit(e)
  if self.decorate then self.decorate(e) end
  self.n = self.n + 1
  self.value = self.value + mag(e.copper)
  self.sumEntries = self.sumEntries + e.copper
  local s = self.bySrc[e.src]
  if not s then s = { n = 0, copper = 0 }; self.bySrc[e.src] = s end
  s.n = s.n + 1; s.copper = s.copper + e.copper
  if e.conf == 'low' then self.lowN = self.lowN + 1 end
  if e.src == 'other' then
    self.otherN = self.otherN + 1
    self.otherValue = self.otherValue + mag(e.copper)
    if mag(e.copper) > self.largestOther then self.largestOther = mag(e.copper) end
  end
  if e.comp == 'gap' then self.gapN = self.gapN + 1; self.gapValue = self.gapValue + mag(e.copper) end
  self.sink(e)
end

function Rec:_other(p, gt, comp)
  self:_emit({ t = p.t, copper = p.copper, src = 'other', conf = 'low', comp = comp })
end

-- exact pass: search combinations of size 1..MAX_COMBO over the highest-priority candidates
local function findCombo(cands, d)
  local n = #cands
  for i = 1, n do
    if cands[i].sign * cands[i].copper == d then return { cands[i] } end
  end
  if R.MAX_COMBO >= 2 then
    for i = 1, n do for j = i + 1, n do
      if cands[i].sign * cands[i].copper + cands[j].sign * cands[j].copper == d then return { cands[i], cands[j] } end
    end end
  end
  if R.MAX_COMBO >= 3 then
    for i = 1, n do for j = i + 1, n do for k = j + 1, n do
      if cands[i].sign * cands[i].copper + cands[j].sign * cands[j].copper + cands[k].sign * cands[k].copper == d then
        return { cands[i], cands[j], cands[k] }
      end
    end end end
  end
end

-- tries to explain pending delta p now; true when entries were emitted
function Rec:_resolve(p, gt)
  local d = p.copper
  local sign = d > 0 and 1 or -1
  local all = self.exp:Active(gt, sign, 'exact')
  local cands = {}
  for i = 1, math.min(#all, R.MAX_CANDIDATES) do cands[i] = all[i] end
  local combo = findCombo(cands, d)
  if combo then
    for _, e in ipairs(combo) do
      self.exp:Consume(e.id)
      if e.comps then
        for _, c in ipairs(e.comps) do
          self:_emit({ t = p.t, copper = c.copper, src = c.src, conf = 'high', comp = c.comp, ctx = e.ctx,
            ref = e.ref, settle = c.settle, exp = e.id })
        end
      else
        self:_emit({ t = p.t, copper = e.sign * e.copper, src = e.src, conf = 'high', ctx = e.ctx,
          ref = e.ref, settle = e.settle, comp = e.comp, exp = e.id })
      end
    end
    return true
  end
  local wins = self.exp:Active(gt, sign, 'window')
  if #wins > 0 then
    local w = wins[1]
    local conf = 'med'
    for i = 2, #wins do if wins[i].src ~= w.src then conf = 'low'; break end end
    self:_emit({ t = p.t, copper = d, src = w.src, conf = conf, ctx = w.ctx, ref = w.ref, settle = w.settle, exp = w.id })
    return true
  end
  return false
end

function Rec:_retry(gt)
  local keep = {}
  for _, p in ipairs(self.pending) do
    if not self:_resolve(p, gt) then keep[#keep + 1] = p end
  end
  self.pending = keep
end

function Rec:Begin(gt)
  self.active = true
  self.lastGT = gt
end

function Rec:Money(copper, gt, gap)
  if not self.active then self.ignored = self.ignored + 1; return end
  self.lastGT = gt
  if type(copper) ~= 'number' or copper == 0 then return end
  self.sumDeltas = self.sumDeltas + copper
  local p = { copper = copper, t = gt }
  if gap then self:_other(p, gt, 'gap'); return end
  if not self:_resolve(p, gt) then self.pending[#self.pending + 1] = p end
end

function Rec:Tick(gt)
  if not self.active then return end
  self.lastGT = gt
  self:_retry(gt)
  local keep = {}
  for _, p in ipairs(self.pending) do
    if gt - p.t >= self.wait then self:_other(p, gt) else keep[#keep + 1] = p end
  end
  self.pending = keep
  self.exp:Expire(gt)
end

function Rec:End(gt)
  if not self.active then return end
  self.lastGT = gt
  self:_retry(gt)
  for _, p in ipairs(self.pending) do self:_other(p, gt) end
  self.pending = {}
  self.exp:Clear()
  self.active = false
end

function Rec:PendingSum()
  local s = 0
  for _, p in ipairs(self.pending) do s = s + p.copper end
  return s
end

function Rec:Check()
  local ps = self:PendingSum()
  return self.sumDeltas == self.sumEntries + ps, self.sumDeltas, self.sumEntries, ps
end

function Rec:Stats()
  local xs = self.exp:Stats()
  local function share(a, b) if b == 0 then return 0 end return a / b end
  local by = {}
  for k, v in pairs(self.bySrc) do by[k] = { n = v.n, copper = v.copper } end
  return {
    total = self.n, totalValue = self.value,
    lowConfShare = share(self.lowN, self.n),
    otherShareValue = share(self.otherValue, self.value),     -- the headline (D-072)
    otherShareEntries = share(self.otherN, self.n),
    largestOther = self.largestOther,
    gapCount = self.gapN, gapValue = self.gapValue,
    unmatched = xs.unmatched, pending = #self.pending, ignored = self.ignored,
    sumDeltas = self.sumDeltas, sumEntries = self.sumEntries, bySource = by,
  }
end
]=====] },
{ path = "Collect/BagDiff.lua", src = [=====[
-- GoldIntel / Collect / BagDiff.lua                               (Phase 3b-3 M1, Architecture AC-14, AC-16)
--
-- PURPOSE
--  Turns two carried-inventory snapshots into a diff aggregated PER ITEM ID (R-34: a stack split or merge nets
--  to zero). Pure: no Platform calls, no clock, no storage. The caller (M2) supplies snapshots.
--
--  Snapshot = { items = { [itemID] = quantity }, complete = true }
--      Only `complete == true` snapshots are ever compared. A snapshot with any unreadable (secret) slot is
--      incomplete and is REFUSED; the baseline stays where it was and the next complete snapshot absorbs the change.
--
--      BagDiff.Compute(prev, now)  -> { added = {[id]=qty}, removed = {[id]=qty}, n = changed ids } | nil, reason
--      BagDiff.Fingerprint(items)  -> number (order independent checksum)
--      local T = BagDiff.New()
--      T:Settle(snap)  -> diff | nil, reason       reasons: 'incomplete' | 'baseline' | 'empty'
--                         diff = { seq, from, to, added, removed, n }; becomes PENDING (not applied)
--      T:Commit(seq)   -> true | nil, err          the baseline advances ONLY here, after the caller processed the diff
--      T:Baseline()    -> copy of the committed baseline items | nil
--      T:Stats()       -> { settles, skipped, empty, diffs, committed, baselines, rejected }
--
-- Invariant I-4 (applied at most once): a diff can be committed once; a second Commit of the same seq, a Commit
-- of a superseded diff, and a repeated identical settle all change nothing.

local ADDON, GI = ...
GI = GI or {}

local B = {}
GI.BagDiff = B

local MODULUS = 2147483629

local function isCount(n) return type(n) == 'number' and n > 0 and n == math.floor(n) and n < 2 ^ 31 end

--- True when `snap` is a usable snapshot: complete == true and every entry a positive integer id and quantity.
local function usable(snap)
  if type(snap) ~= 'table' or snap.complete ~= true or type(snap.items) ~= 'table' then return false end
  for id, qty in pairs(snap.items) do
    if not isCount(id) or not isCount(qty) then return false end
  end
  return true
end
B.Usable = usable

function B.Fingerprint(items)
  local ids = {}
  for id in pairs(items) do ids[#ids + 1] = id end
  table.sort(ids)
  local h = 7
  for _, id in ipairs(ids) do
    h = (h * 31 + id) % MODULUS
    h = (h * 31 + items[id]) % MODULUS
  end
  return h
end

local function copyItems(items)
  local c = {}
  for id, q in pairs(items) do c[id] = q end
  return c
end

function B.Compute(prev, now)
  if not usable(prev) then return nil, 'previous snapshot unusable' end
  if not usable(now) then return nil, 'snapshot unusable' end
  local added, removed, n = {}, {}, 0
  for id, q in pairs(now.items) do
    local p = prev.items[id] or 0
    if q > p then added[id] = q - p; n = n + 1
    elseif q < p then removed[id] = p - q; n = n + 1 end
  end
  for id, p in pairs(prev.items) do
    if now.items[id] == nil then removed[id] = p; n = n + 1 end
  end
  return { added = added, removed = removed, n = n }
end

local Tracker = {}
Tracker.__index = Tracker

function B.New()
  return setmetatable({ base = nil, fp = nil, seq = 0, pending = nil,
    st = { settles = 0, skipped = 0, empty = 0, diffs = 0, committed = 0, baselines = 0, rejected = 0 } }, Tracker)
end

function Tracker:Settle(snap)
  local st = self.st
  st.settles = st.settles + 1
  if not usable(snap) then
    st.skipped = st.skipped + 1
    return nil, 'incomplete'
  end
  local fp = B.Fingerprint(snap.items)
  if not self.base then
    self.base = copyItems(snap.items)
    self.fp = fp
    self.pending = nil
    st.baselines = st.baselines + 1
    return nil, 'baseline'
  end
  if fp == self.fp then
    self.pending = nil
    st.empty = st.empty + 1
    return nil, 'empty'
  end
  local diff = B.Compute({ items = self.base, complete = true }, snap)
  if not diff or diff.n == 0 then
    self.pending = nil
    st.empty = st.empty + 1
    return nil, 'empty'
  end
  self.seq = self.seq + 1
  diff.seq, diff.from, diff.to = self.seq, self.fp, fp
  self.pending = { seq = self.seq, items = copyItems(snap.items), fp = fp }
  st.diffs = st.diffs + 1
  return diff
end

function Tracker:Commit(seq)
  local p = self.pending
  if not p or p.seq ~= seq then
    self.st.rejected = self.st.rejected + 1
    return nil, 'no such pending diff'
  end
  self.base = p.items
  self.fp = p.fp
  self.pending = nil
  self.st.committed = self.st.committed + 1
  return true
end

function Tracker:Baseline()
  if not self.base then return nil end
  return copyItems(self.base)
end

function Tracker:Stats()
  local s = {}
  for k, v in pairs(self.st) do s[k] = v end
  return s
end
]=====] },
{ path = "Collect/Sources.lua", src = [=====[
-- GoldIntel / Collect / Sources.lua                                (Phase 3b-2 M2, Architecture AC-10)
--
-- PURPOSE
--  The ONLY module that knows what a normalized Platform event means for money. It turns P_* events and
--  context changes into expectations (Expectations.lua) and feeds P_MONEY deltas to the Reconciler.
--  Expectations, Reconciler and Stamps stay source-agnostic.
--
--      Sources.Begin()      starts an interval (collect on): creates the store, Reconciler, Stamps; subscribes
--      Sources.End()        ends it: pending deltas become OTHER, expectations are cleared, ticker stopped
--      Sources.IsActive()   Sources.Stats()   Sources.Entries()   Sources.SetSink(fn)
--
-- Sources in 3b-2 (option A, D-077 Q-1):
--   loot coin   P_LOOT_MONEY      exact, held while the loot context is open, then LOOT_LINGER (2.0 s)   src loot
--   coin chat   P_LOOT_CHAT       (M5, E-48/E-49) the client's own "You loot N" / "Your share of the loot is N" line
--                                 is an EXACT loot expectation of N, whether or not a loot window was opened here.
--                                 It arrives 0.5-1.0 s AFTER the money change, so pending deltas wait WAIT (2.0 s).
--                                 Already explained by an earlier entry -> claimed, nothing added. Already written
--                                 as OTHER -> counted as late, nothing added (no retroactive edits).
--                                 A split share also consumes the loot window expectation it came from, only when
--                                 N is floor or ceil of window coin / k for some k from 2 to the group size
--                                 (the coin is split among the members in range; exact, no guessing).
--   quest       P_QUEST_DONE      exact, ttl 1.0 s                                           src quest
--   mail money  P_MAIL_UPDATE     exact, one per money mail that left the inbox (diff of Mail.Previous/Snapshot)
--                                 COD payment mail -> codIn; seller invoice that adds up -> ahSale/ahCut/
--                                 ahDepositRefund components; any other money mail -> mailMoney
--   vendor      vendor context    window: + -> vendor, - -> purchase
--   trade       trade context     window: + and - -> trade
--  NOT sources yet (stay OTHER until 3b-4): AH deposit, AH buyout and bid, COD paid, postage.
--
-- Mail diff (E-28, E-34, E-39, E-40): the first update after the mailbox opened is only a baseline. After that, a
-- money mail (key sender|subject|money|cod) that is in the previous snapshot but not in the current one means its
-- money was taken (or it was deleted, returned or expired: that expectation simply expires unmatched, R-3b2-5).
-- Taking only the items of a mail that also holds money keeps its key, so it creates nothing. COD mails
-- (cod > 0) create nothing: COD paid is out of scope.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P and GI.Expectations and GI.Reconciler and GI.Stamps, 'Expectations, Reconciler and Stamps must be loaded first')

local Sources = {}
GI.Sources = Sources

Sources.TICK = 0.25
Sources.LINGER = 1.0
Sources.LOOT_LINGER = 2.0    -- a loot window expectation outlives the window by this long (the chat line arrives late)
Sources.WAIT = 2.0           -- pending money waits this long for the chat line before it becomes OTHER
Sources.CHAT_LOOK = 3.0      -- a chat line looks this far back for an entry that already explains it
Sources.ENTRY_CAP = 500
Sources.COD_PREFIX = 'COD Payment:'      -- English client only (R-3b2-4); other locales fall back to mailMoney

local X, R, S                -- the live instances (nil when no interval)
local active = false
local cancelTick
local held = {}              -- loot expectations held open while the loot context is open
local windows = {}           -- context kind -> { ids }
local needBaseline = true    -- the next mail update after the mailbox opened is a baseline only
local entries = {}
local sink
local c

local function freshCounters()
  c = { chatLines = 0, chatClaimed = 0, chatLate = 0, chatCovered = 0, chatSplit = 0, chatExp = 0, lootExp = 0, questExp = 0, mailExp = 0, mailVanished = 0, mailBaselines = 0, mailSkippedCod = 0,
        windowsOpened = 0, ticks = 0, handlerErrors = 0 }
end
freshCounters()

local function nowGT()
  local _, gt = P.Now()
  return gt
end

--- Diagnostic tap (Ledger/Trace.lua): Sources.tap(kind, ...) with kind 'money' | 'entry' | 'exp'. Never changes behaviour.
local function tapped(...)
  if Sources.tap then pcall(Sources.tap, ...) end
end

local recent = {}        -- recent loot/other entries a chat line may already be explained by: { gt, e, claimed }

local function record(e)                  -- the recent-entries ring (diagnostics, tests); the sink gets every entry too
  tapped('entry', e)
  if e.src == 'loot' or (e.src == 'other' and e.comp ~= 'gap') then
    recent[#recent + 1] = { gt = nowGT(), e = e, claimed = (e.ref and e.ref.chat) == true }
    if #recent > 40 then table.remove(recent, 1) end
  end
  entries[#entries + 1] = e
  if #entries > Sources.ENTRY_CAP then table.remove(entries, 1) end
end

--- Optional second consumer of finished entries (Ledger.lua: the Cash store). nil removes it.
function Sources.SetSink(fn) sink = fn end
function Sources.Entries() return entries end
function Sources.IsActive() return active end
function Sources.Reconciler() return R end
function Sources.Expectations() return X end
function Sources.Stamps() return S end

local function add(spec)
  local id, err = X:Add(spec)
  if not id then P.Diag('warn', 'Sources', 'expectation refused: ' .. tostring(err)) end
  return id
end

---------------------------------------------------------------------------
-- Translators
---------------------------------------------------------------------------

local function onLootMoney(p)
  if not active or type(p.copper) ~= 'number' or p.copper <= 0 then return end
  local id = add({ src = 'loot', mode = 'exact', copper = p.copper, sign = 1, t0 = nowGT(), ttl = Sources.LOOT_LINGER,
    ctx = 'loot', ref = { sourceType = p.source }, hold = true })
  if id then held[#held + 1] = id; c.lootExp = c.lootExp + 1 end
end

--- The coin chat line (P_LOOT_CHAT). See the header. Pure decisions on exact amounts; no guessing.
local function onLootChat(p)
  if not active or type(p.copper) ~= 'number' or p.copper <= 0 then return end
  local n, gt = p.copper, nowGT()
  c.chatLines = c.chatLines + 1
  for i = #recent, 1, -1 do                                  -- 1) an entry already explains this coin
    local r = recent[i]
    if gt - r.gt <= Sources.CHAT_LOOK and not r.claimed and r.e.copper == n then
      if r.e.src == 'loot' then
        r.claimed = true; c.chatClaimed = c.chatClaimed + 1
        tapped('chat', 'claimed', p, r.e)
        return
      end
    end
  end
  for i = #recent, 1, -1 do                                  -- 2) it was already written as OTHER: too late, no edits
    local r = recent[i]
    if gt - r.gt <= Sources.CHAT_LOOK and not r.claimed and r.e.src == 'other' and r.e.copper == n then
      r.claimed = true; c.chatLate = c.chatLate + 1
      tapped('chat', 'late', p, r.e)
      return
    end
  end
  local best, covered                                        -- 3) look at the loot window expectations
  for _, e in ipairs(X:Active(gt, 1, 'exact')) do
    if e.src == 'loot' and not (e.ref and e.ref.chat) then
      if e.copper == n then covered = e end
      if p.kind == 'share' and type(p.group) == 'number' and p.group >= 2 and e.copper > n then
        -- the coin is split among the members who qualify (in range, or everyone in an instance): any count from
        -- 2 up to the group size is possible, so N must be floor or ceil of coin / k for some k in that range
        local fits = false
        for k = 2, p.group do
          if n == math.floor(e.copper / k) or n == math.ceil(e.copper / k) then fits = true; break end
        end
        if fits and (not best or e.copper < best.copper) then best = e end
      end
    end
  end
  if covered then                                            -- the window itself offers exactly N: it will match
    c.chatCovered = c.chatCovered + 1
    tapped('chat', 'covered', p, covered)
    return
  end
  local ref = { chat = true }
  if best then ref.sourceType = best.ref and best.ref.sourceType; X:Consume(best.id); c.chatSplit = c.chatSplit + 1 end
  local id = add({ src = 'loot', mode = 'exact', copper = n, sign = 1, t0 = gt, ttl = Sources.LINGER, ctx = 'loot',
    ref = ref, comp = p.kind == 'share' and 'split' or nil })
  if id then c.chatExp = c.chatExp + 1 end
  tapped('chat', best and 'split' or 'expect', p, best, id)
end

local function releaseHeld(gt)
  for _, id in ipairs(held) do X:Close(id, gt) end
  held = {}
end

local function onQuest(p)
  if not active or type(p.copper) ~= 'number' or p.copper <= 0 then return end
  if add({ src = 'quest', mode = 'exact', copper = p.copper, sign = 1, t0 = nowGT(), ttl = Sources.LINGER, ctx = 'quest' }) then
    c.questExp = c.questExp + 1
  end
end

local WINDOWS = {
  vendor = { { src = 'vendor', sign = 1 }, { src = 'purchase', sign = -1 } },
  trade = { { src = 'trade', sign = 1 }, { src = 'trade', sign = -1 } },
}

local function onContext(p)
  if not active then return end
  local gt = nowGT()
  if p.kind == 'loot' then
    if not p.open then releaseHeld(gt) end
    return
  end
  local w = WINDOWS[p.kind]
  if not w then return end
  if p.open then
    local ids = {}
    for _, def in ipairs(w) do
      ids[#ids + 1] = add({ src = def.src, mode = 'window', sign = def.sign, t0 = gt, ttl = Sources.LINGER, ctx = p.kind })
    end
    windows[p.kind] = ids
    c.windowsOpened = c.windowsOpened + 1
  else
    for _, id in ipairs(windows[p.kind] or {}) do X:Close(id, gt) end
    windows[p.kind] = nil
  end
end

-- mail --------------------------------------------------------------------

local function key(m) return table.concat({ m.sender or '', m.subject or '', m.money or 0, m.cod or 0 }, '|') end

local function count(snap)
  local t, rep = {}, {}
  for _, m in ipairs(snap and snap.mails or {}) do
    local k = key(m)
    t[k] = (t[k] or 0) + 1
    rep[k] = rep[k] or m
  end
  return t, rep
end

--- Builds the expectation spec for one vanished money mail (pure, exposed for tests).
function Sources.MailSpec(m, t0)
  if (m.cod or 0) > 0 or (m.money or 0) <= 0 then return nil end
  local spec = { mode = 'exact', copper = m.money, sign = 1, t0 = t0, ttl = Sources.LINGER, ctx = 'mail' }
  local inv = m.invoice
  if inv and inv.price + inv.deposit - inv.cut == m.money then
    local comps = {}
    if inv.price ~= 0 then comps[#comps + 1] = { src = 'ahSale', copper = inv.price, settle = true } end
    if inv.cut ~= 0 then comps[#comps + 1] = { src = 'ahCut', copper = -inv.cut } end
    if inv.deposit ~= 0 then comps[#comps + 1] = { src = 'ahDepositRefund', copper = inv.deposit, comp = 'deposit' } end
    if #comps > 0 then
      spec.src, spec.comps = 'ahSale', comps
      return spec
    end
  end
  if (m.subject or ''):sub(1, #Sources.COD_PREFIX) == Sources.COD_PREFIX then
    spec.src, spec.settle = 'codIn', true
  else
    spec.src, spec.settle = 'mailMoney', true
  end
  return spec
end

local function onMailOpen() needBaseline = true end

local function onMailUpdate()
  if not active then return end
  local Mail = P.MailModule
  if not Mail then return end
  if needBaseline then
    needBaseline = false
    c.mailBaselines = c.mailBaselines + 1
    return
  end
  local prevN, prevRep = count(Mail.Previous())
  local curN = count(Mail.Snapshot())
  local gt = nowGT()
  for k, n in pairs(prevN) do
    local gone = n - (curN[k] or 0)
    for _ = 1, gone do
      c.mailVanished = c.mailVanished + 1
      local spec = Sources.MailSpec(prevRep[k], gt)
      if spec then
        if add(spec) then c.mailExp = c.mailExp + 1 end
      else
        c.mailSkippedCod = c.mailSkippedCod + 1
      end
    end
  end
end

---------------------------------------------------------------------------
-- Stamps feed, money feed, ticker
---------------------------------------------------------------------------

local function onTick(p)
  if active and S and p.loc then S:NoteLoc(p.loc, nowGT()) end
end

local function onMoney(p)
  if not active then return end
  tapped('money', p)
  R:Money(p.copper, p.gt or nowGT(), p.gap == true)
end

local function tick()
  if not active then return end
  c.ticks = c.ticks + 1
  local gt = nowGT()
  -- safety net: a held loot expectation whose loot context is gone is released now
  if #held > 0 and GI.Context and not GI.Context.IsActive('loot') then releaseHeld(gt) end
  R:Tick(gt)
end

local function guard(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then
      c.handlerErrors = c.handlerErrors + 1
      P.Diag('error', 'Sources', tostring(err))
    end
  end
end

local wired = false
local function wire()
  if wired then return end
  wired = true
  P.On('P_LOOT_MONEY', guard(onLootMoney))
  P.On('P_LOOT_CHAT', guard(onLootChat))
  P.On('P_QUEST_DONE', guard(onQuest))
  P.On('P_MAIL_OPEN', guard(onMailOpen))
  P.On('P_MAIL_UPDATE', guard(onMailUpdate))
  P.On('P_MONEY', guard(onMoney))
  P.On('P_TICK', guard(onTick))
  P.On('P_ZONE', guard(function(p) if active and S and p.loc then S:NoteLoc(p.loc, nowGT()) end end))
  if GI.Bus then GI.Bus.On('CONTEXT_CHANGED', guard(onContext)) end
end

function Sources.Begin()
  wire()
  if active then return false end
  X = GI.Expectations.New()
  X.tap = function(ev, e, gt) tapped('exp', ev, e, gt) end
  S = GI.Stamps.New{ lastCast = P.LastCast }
  recent = {}
  R = GI.Reconciler.New{ exp = X, wait = Sources.WAIT, sink = function(e) record(e); if sink then sink(e) end end, decorate = function(e) S:Apply(e) end }
  held, windows = {}, {}
  needBaseline = true
  freshCounters()
  entries = {}
  local gt = nowGT()
  active = true
  R:Begin(gt)
  -- contexts that are already open when the interval starts get their windows (collect on inside a window)
  if GI.Context then
    for _, k in ipairs(GI.Context.Active()) do
      if k.open then onContext({ kind = k.kind, open = true }) end
    end
  end
  cancelTick = P.Every(Sources.TICK, tick)
  return true
end

function Sources.End()
  if not active then return false end
  if cancelTick then cancelTick(); cancelTick = nil end
  R:End(nowGT())
  active = false
  held, windows = {}, {}
  return true
end

--- Reconciler statistics plus this module's counters. Nil when no interval has run.
function Sources.Stats()
  if not R then return nil end
  local s = R:Stats()
  s.sources = {}
  for k, v in pairs(c) do s.sources[k] = v end
  s.active = active
  return s
end
]=====] },
{ path = "Collect/ItemSources.lua", src = [=====[
-- GoldIntel / Collect / ItemSources.lua                       (Phase 3b-3 M2, TRACE-ONLY; D-080, D-081, D-082)
--
-- PURPOSE
--  The ONLY module that knows what an item addition or removal in the bags means. M2 runs it in TRACE-ONLY mode:
--  it decides and records what it WOULD do (trace lines, counters, a ring of recent decisions), but it creates no
--  lot, stores nothing and never touches Sources, Reconciler or Cash (AC-15, I-6). M3 will feed the same decisions
--  to Ledger/Lots.lua after the user has reviewed the Session E evidence (D-080 gate).
--
--      ItemSources.Begin()    starts with the ledger interval: baseline bag snapshot, subscriptions live
--      ItemSources.End()      stops; pending decisions are dropped (nothing is stored)
--      ItemSources.IsActive() ItemSources.Stats() ItemSources.Recent(n) ItemSources.Anomalies()
--      ItemSources.Attribute(diff, facts) -> decisions      PURE: the attribution rules (tested without a client)
--
-- Scope (D-081, option B): acquisitions and conversions only. Additions are loot, quest reward, vendor purchase,
-- mail, trade, disenchant materials; removals that matter are vendor sale, quest consumption, disenchant source,
-- trade out. Every other removal is IGNORED (equip, cursor, moves, use, destroy, bank are not our business) and
-- every other addition is UNEXPLAINED (counted, visible, no value created).
--
-- Rules, in this order (no heuristics: each rests on a verified signal; unknowns stay unexplained):
--   add:    loot window slot (id and quantity from the window; disenchant window = materials) -> quest context ->
--           vendor context with money OUT -> mail context -> trade context -> unexplained
--   remove: vendor context with money IN -> quest context -> disenchant (cast 13262 + an item-source window) ->
--           trade context -> ignored
-- Decisions wait WAIT seconds after the bag settle because the money delta can arrive after it (E-32) and the
-- measured lags are what Session E records.
--
-- Skinning (D-082): a loot window of a creature already looted in this interval, after a skin cast made since that
-- first window, is skinning = GATHER (E-24: the skinning window is a second LOOT_OPENED of the same guid).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P and GI.BagDiff and GI.Stamps, 'Platform, BagDiff and Stamps must be loaded before Collect/ItemSources.lua')

local IS = {}
GI.ItemSources = IS

IS.WAIT = 2.0                 -- a decision waits this long after the settle (money may land after the bag event, E-32)
IS.LOOT_KEEP = 6.0            -- a loot item expectation outlives its window by this long
IS.MONEY_PAIR = 1.0           -- a money event can belong to a bag settle at most this far away (before or after)
IS.SEEN_KEEP = 600            -- how long a looted creature guid is remembered (for the skinning rule)
IS.RING = 50
IS.DISENCHANT_SPELL = 13262   -- E-26
IS.CAST_BEFORE = 8.0          -- a disenchant cast this long before the settle explains the removal

---------------------------------------------------------------------------
-- Pure attribution
---------------------------------------------------------------------------

local function sortedIds(map)
  local ids = {}
  for id in pairs(map or {}) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

local function contextsText(f)
  local t = {}
  for _, k in ipairs({ 'quest', 'merchant', 'mail', 'trade' }) do if f[k] then t[#t + 1] = k end end
  if (f.moneyPos or 0) > 0 then t[#t + 1] = 'money+' end
  if (f.moneyNeg or 0) > 0 then t[#t + 1] = 'money-' end
  return #t > 0 and table.concat(t, ',') or 'none'
end

--- Pure. diff = { added = {[id]=qty}, removed = {[id]=qty} }.
-- facts = { loot = { {itemID,left,sourceType,skinning,act,actConf,windowId}... } (left is CONSUMED),
--           quest, merchant, mail, trade, disenchant = boolean, moneyPos, moneyNeg = number (magnitudes) }.
-- Returns decisions { dir = 'add'|'remove', itemID, qty, how, reason, act?, actConf?, window?, skinning? }.
--- Pure. Each money event belongs to exactly ONE bag settle: the nearest one within `pair` seconds (ties: the earlier
-- settle). A vendor sells one stack per click and money lands with its own bag event (E-21, M2 trace 2026-10-21: five sales
-- within 0.3 s), so a shared window would book the same copper several times.
-- events = { {gt, copper}... }, settles = { gt... } (all known settles), mine = this entry's settle time.
-- Returns moneyPos, moneyNeg (magnitudes) owned by `mine`.
function IS.PairMoney(events, settles, mine, pair)
  local pos, neg = 0, 0
  for _, m in ipairs(events) do
    if math.abs(m.gt - mine) <= pair + 1e-9 then
      local best, bestD = nil, nil
      for _, s in ipairs(settles) do
        local d = math.abs(m.gt - s)
        if d <= pair + 1e-9 and (bestD == nil or d < bestD - 1e-9 or (math.abs(d - bestD) <= 1e-9 and s < best)) then best, bestD = s, d end
      end
      if best == mine then
        if m.copper > 0 then pos = pos + m.copper else neg = neg - m.copper end
      end
    end
  end
  return pos, neg
end

function IS.Attribute(diff, facts)
  facts = facts or {}
  local out = {}
  local hasItemWindow = false
  for _, e in ipairs(facts.loot or {}) do if e.sourceType == 'item' then hasItemWindow = true end end
  for _, id in ipairs(sortedIds(diff.added)) do
    local left = diff.added[id]
    for _, e in ipairs(facts.loot or {}) do
      if left <= 0 then break end
      if e.itemID == id and e.left > 0 then
        local n = math.min(left, e.left)
        e.left = e.left - n
        left = left - n
        out[#out + 1] = { dir = 'add', itemID = id, qty = n, how = e.sourceType == 'item' and 'disenchantMat' or 'loot',
          reason = 'loot window slot', act = e.act, actConf = e.actConf, window = e.windowId, skinning = e.skinning,
          loc = e.loc, locConf = e.locConf }
      end
    end
    if left > 0 then
      local how, reason
      if facts.quest then how, reason = 'quest', 'quest turn-in context'
      elseif facts.merchant and (facts.moneyNeg or 0) > 0 then how, reason = 'vendorBuy', 'vendor open and money out'
      elseif facts.mail then how, reason = 'mail', 'mailbox open'
      elseif facts.trade then how, reason = 'trade', 'trade window'
      else how, reason = 'unexplained', 'no matching signal (' .. contextsText(facts) .. ')' end
      out[#out + 1] = { dir = 'add', itemID = id, qty = left, how = how, reason = reason }
    end
  end
  for _, id in ipairs(sortedIds(diff.removed)) do
    local qty = diff.removed[id]
    local how, reason
    if facts.merchant and (facts.moneyPos or 0) > 0 then how, reason = 'vendorSale', 'vendor open and money in'
    elseif facts.quest then how, reason = 'questConsume', 'quest turn-in context'
    elseif facts.disenchant and hasItemWindow then how, reason = 'disenchantSrc', 'disenchant cast and item-source window'
    elseif facts.trade then how, reason = 'tradeOut', 'trade window'
    else how, reason = 'ignored', 'inventory-only change (D-081)' end
    out[#out + 1] = { dir = 'remove', itemID = id, qty = qty, how = how, reason = reason }
  end
  return out
end

---------------------------------------------------------------------------
-- Live wiring
---------------------------------------------------------------------------

local active = false
local tracker, stamps
local lootExp, win, seen, nextWin
local moneyRing, lastDE, settleLog
local pendingQ
local ring
local seenInfo
local anomalies
local c

local function freshCounters()
  c = { settles = 0, baselines = 0, empty = 0, skipped = 0, snapFail = 0, diffs = 0, decisions = 0, handlerErrors = 0,
        windows = 0, lootSlots = 0, skinWindows = 0, noGuid = 0, how = {}, itemInfoEvents = 0 }
end
freshCounters()

local function nowGT() local _, gt = P.Now(); return gt end

local function tapped(...)
  if IS.tap then pcall(IS.tap, ...) end
end

local function guard(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then
      c.handlerErrors = c.handlerErrors + 1
      P.Diag('error', 'ItemSources', tostring(err))
    end
  end
end

local function reset()
  tracker = GI.BagDiff.New()
  stamps = GI.Stamps.New{ lastCast = P.LastCast }
  lootExp, win, seen, nextWin = {}, nil, {}, 0
  moneyRing, lastDE, settleLog = {}, nil, {}
  pendingQ, ring, seenInfo, anomalies = {}, {}, {}, { counts = {}, recent = {} }
  freshCounters()
end

local function prune(gt)
  local keep = {}
  for _, e in ipairs(lootExp) do
    local expired = e.closeGT and gt - e.closeGT > IS.LOOT_KEEP + IS.WAIT
    if not expired then keep[#keep + 1] = e end
  end
  lootExp = keep
  for guid, t in pairs(seen) do if gt - t > IS.SEEN_KEEP then seen[guid] = nil end end
  local m = {}
  for _, r in ipairs(moneyRing) do if gt - r.gt <= 20 then m[#m + 1] = r end end
  moneyRing = m
  local sl = {}
  for _, g in ipairs(settleLog) do if gt - g <= 20 then sl[#sl + 1] = g end end
  settleLog = sl
end

local function onLootOpen(p)
  local gt = nowGT()
  prune(gt)
  nextWin = nextWin + 1
  local skinning = false
  if p.sourceType == 'creature' then
    if type(p.guid) == 'string' then
      local prev = seen[p.guid]
      if prev then
        local castGT = P.LastCast and P.LastCast('skin')
        if castGT and castGT >= prev and castGT <= gt + 1e-9 then skinning = true end
      end
      seen[p.guid] = gt
    else
      c.noGuid = c.noGuid + 1
    end
  end
  if skinning then c.skinWindows = c.skinWindows + 1 end
  local act, actConf = stamps:ItemActivity{ sourceType = p.sourceType, skinning = skinning, t = gt }
  local loc, locConf = stamps:Loc(gt)
  win = { id = nextWin, sourceType = p.sourceType, skinning = skinning, openGT = gt, act = act, actConf = actConf, loc = loc, locConf = locConf,
          guid = type(p.guid) == 'string' and p.guid:sub(-6) or '?' }
  c.windows = c.windows + 1
  tapped('window', win)
end

local function onLootItem(p)
  local gt = nowGT()
  local w = win
  c.lootSlots = c.lootSlots + 1
  local e = { itemID = p.itemID, left = p.qty, qty = p.qty, sourceType = (w and w.sourceType) or p.source or 'unknown',
              skinning = w and w.skinning or false, act = w and w.act, actConf = w and w.actConf, windowId = w and w.id,
              loc = w and w.loc, locConf = w and w.locConf,
              openGT = gt }
  lootExp[#lootExp + 1] = e
  tapped('slot', e)
end

local function onLootClose(p)
  local gt = nowGT()
  for _, e in ipairs(lootExp) do
    if win and e.windowId == win.id and not e.closeGT then e.closeGT = gt end
  end
  tapped('windowClose', win, p.by)
  win = nil
end

local function onMoney(p)
  moneyRing[#moneyRing + 1] = { gt = nowGT(), copper = p.copper }
end

local function onCast(p)
  if p.spellID == IS.DISENCHANT_SPELL then lastDE = nowGT() end
end

local function note(kind, detail)
  anomalies.counts[kind] = (anomalies.counts[kind] or 0) + 1
  anomalies.recent[#anomalies.recent + 1] = { gt = nowGT(), kind = kind, detail = detail }
  while #anomalies.recent > IS.RING do table.remove(anomalies.recent, 1) end
  tapped('anomaly', kind, detail)
end

local function infoOnce(id)
  if seenInfo[id] then return end
  seenInfo[id] = true
  local info = GI.Platform.ItemsModule and GI.Platform.ItemsModule.Get(id) or nil
  tapped('iteminfo', id, info)
end

local function decide(entry)
  if not active then return end
  local gt = nowGT()
  prune(gt)
  local moneyPos, moneyNeg = IS.PairMoney(moneyRing, settleLog, entry.gt, IS.MONEY_PAIR)
  local f = entry.facts
  f.moneyPos, f.moneyNeg = moneyPos, moneyNeg
  f.disenchant = lastDE ~= nil and lastDE >= entry.gt - IS.CAST_BEFORE and lastDE <= entry.gt + 1.0
  f.loot = lootExp
  local decisions = IS.Attribute(entry.diff, f)
  for _, d in ipairs(decisions) do
    c.decisions = c.decisions + 1
    c.how[d.how] = (c.how[d.how] or 0) + d.qty
    ring[#ring + 1] = { gt = gt, settleGT = entry.gt, d = d }
    while #ring > IS.RING do table.remove(ring, 1) end
    if d.how == 'vendorSale' and not IS.sink then      -- with a sink (M3) the lot book raises these anomalies itself
      local info = P.ItemsModule and P.ItemsModule.Get(d.itemID) or nil
      if info and info.status == 'ready' and info.sellPrice == 0 then
        note('sale-no-sell-price', { itemID = d.itemID, qty = d.qty, moneyIn = moneyPos })
      elseif not info or info.status ~= 'ready' then
        note('sale-price-unknown', { itemID = d.itemID, qty = d.qty, moneyIn = moneyPos })
      end
    end
    tapped('decision', d, entry, f)
  end
  -- M3: the lot book receives the whole entry's decisions at once (a vendor sale of several items shares one money total)
  if IS.sink and #decisions > 0 then
    local ok, err = pcall(IS.sink, decisions, { gt = entry.gt, unix = (P.Now()), moneyPos = moneyPos, moneyNeg = moneyNeg })
    if not ok then c.handlerErrors = c.handlerErrors + 1; P.Diag('error', 'ItemSources', 'sink: ' .. tostring(err)) end
  end
end

local function settle(origin)
  local gt = nowGT()
  c.settles = c.settles + 1
  if not P.BagsModule then c.snapFail = c.snapFail + 1; return end
  local snap, why = P.BagsModule.Snapshot()
  if not snap then
    c.snapFail = c.snapFail + 1
    tapped('snapFail', why)
    return
  end
  local diff, reason = tracker:Settle(snap)
  if not diff then
    if reason == 'baseline' then c.baselines = c.baselines + 1; tapped('baseline', snap, origin)
    elseif reason == 'empty' then c.empty = c.empty + 1; tapped('empty')
    else c.skipped = c.skipped + 1; tapped('skipped', snap) end
    return
  end
  tracker:Commit(diff.seq)
  c.diffs = c.diffs + 1
  settleLog[#settleLog + 1] = gt
  for id in pairs(diff.added) do infoOnce(id) end
  for id in pairs(diff.removed) do infoOnce(id) end
  local Ctx = GI.Context
  local function on(kind) return Ctx and Ctx.IsActive(kind) or false end
  local entry = { gt = gt, diff = diff, snap = snap, facts = { quest = on('quest'), merchant = on('vendor'), mail = on('mail'), trade = on('trade') } }
  tapped('diff', diff, entry)
  pendingQ[#pendingQ + 1] = entry
  P.After(IS.WAIT, function()
    for i, e in ipairs(pendingQ) do if e == entry then table.remove(pendingQ, i); break end end
    guard(decide)(entry)
  end)
end

local wired = false
local function wire()
  if wired then return end
  wired = true
  P.On('P_LOOT_OPEN', guard(function(p) if active then onLootOpen(p) end end))
  P.On('P_LOOT_ITEM', guard(function(p) if active then onLootItem(p) end end))
  P.On('P_LOOT_CLOSE', guard(function(p) if active then onLootClose(p) end end))
  P.On('P_MONEY', guard(function(p) if active then onMoney(p) end end))
  P.On('P_CAST', guard(function(p) if active then onCast(p) end end))
  P.On('P_TICK', guard(function(p) if active and stamps and p.loc then stamps:NoteLoc(p.loc, nowGT()) end end))
  P.On('P_ZONE', guard(function(p) if active and stamps and p.loc then stamps:NoteLoc(p.loc, nowGT()) end end))
  P.On('P_BAGS_SETTLED', guard(function() if active then settle('settle') end end))
  P.On('P_ITEM_INFO', guard(function(p) if active then c.itemInfoEvents = c.itemInfoEvents + 1; tapped('infoEvent', p) end end))
end

function IS.Begin()
  wire()
  if active then return false end
  reset()
  active = true
  if P.BagsModule and P.BagsModule.Ranges then tapped('ranges', P.BagsModule.Ranges()) end
  settle('begin')
  return true
end

function IS.End()
  if not active then return false end
  active = false
  pendingQ = {}
  return true
end

function IS.IsActive() return active end
function IS.Recent(n)
  n = math.max(1, math.min(tonumber(n) or 10, IS.RING))
  local out = {}
  for i = math.max(1, #ring - n + 1), #ring do out[#out + 1] = ring[i] end
  return out
end
function IS.Anomalies() return anomalies end

--- Counters. Nil before the first interval.
function IS.Stats()
  if not c then return nil end
  local s = { active = active, how = {} }
  for k, v in pairs(c) do if k ~= 'how' then s[k] = v end end
  for k, v in pairs(c.how) do s.how[k] = v end
  s.tracker = tracker and tracker:Stats() or nil
  s.anomalies = {}
  if anomalies then for k, v in pairs(anomalies.counts) do s.anomalies[k] = v end end
  return s
end

--- Test helper.
function IS.Reset() active = false; reset() end
]=====] },
{ path = "Ledger/Valuation.lua", src = [=====[
-- GoldIntel / Ledger / Valuation.lua                              (Phase 3b-3 M1, Architecture AC-17; D-043..D-046, D-063)
--
-- PURPOSE
--  Valuation tiers 1 and 2 for a lot, as pure functions. Tier 1 = vendor floor, tier 2 = manual price.
--  No Platform, no clock, no storage. `info` is an Items.Get result, `manual` is { copper = n } or nil.
--
--      Valuation.Value(info, manual) -> { valueEach, valueSrc, flags }
--          info.status 'ready' + sellPrice >= 0    -> valueSrc 'vendor'; sellPrice 0 is KNOWN: flags.noVendor
--          optional manual price (D-082): the HIGHEST of vendor and manual is used; manual wins only when strictly higher
--          (valueSrc 'manual'); it is an override set by slash command, never a default; item data must be ready first
--          'ready' without a price, 'pending', 'secret' -> valueSrc 'unknown', valueEach 0, flags unknown + pendingInfo
--          'invalid' or anything else              -> valueSrc 'unknown', flags unknown + invalid (final)
--          flags.bound when bindType is 1 (on pickup) or 4 (quest): bound AT ACQUISITION
--      Valuation.Complete(lot, info, manual, now) -> true | false
--          The FIRST valuation of a lot that has none (valueSrc 'unknown', not invalid). Completion, not revaluation:
--          acquisition time, origin, vc and quantity never change. A lot that already has a basis is never touched (D-063).
--      Valuation.Expire(lot, now) -> true | false   ends the pendingInfo window (flag cleared, `unknown` stays, retryable)
--
-- An empty item answer is NEVER a price of 0 (D-045, D-046).

local ADDON, GI = ...
GI = GI or {}

local V = {}
GI.Valuation = V

V.PENDING_WINDOW = 30.0

local function isCopper(n) return type(n) == 'number' and n >= 0 and n == math.floor(n) and n < 2 ^ 40 end

local function boundAtPickup(info)
  return type(info) == 'table' and (info.bindType == 1 or info.bindType == 4)
end

function V.Value(info, manual)
  local flags = {}
  if boundAtPickup(info) then flags.bound = true end
  local mc = type(manual) == 'table' and isCopper(manual.copper) and manual.copper or nil
  local status = type(info) == 'table' and info.status or nil
  if status == 'ready' then
    if isCopper(info.sellPrice) then
      if info.sellPrice == 0 then flags.noVendor = true end
      -- D-082 / user 2026-10-19: the HIGHEST value is used. A manual price is an optional override
      -- (slash command), taken as typed (no AH cut); on a tie the vendor value stands.
      if mc and mc > info.sellPrice then
        return { valueEach = mc, valueSrc = 'manual', flags = flags }
      end
      return { valueEach = info.sellPrice, valueSrc = 'vendor', flags = flags }
    end
    flags.unknown, flags.pendingInfo = true, true
    return { valueEach = 0, valueSrc = 'unknown', flags = flags }
  end
  if status == 'pending' or status == 'secret' then
    flags.unknown, flags.pendingInfo = true, true
    return { valueEach = 0, valueSrc = 'unknown', flags = flags }
  end
  flags.unknown, flags.invalid = true, true
  return { valueEach = 0, valueSrc = 'unknown', flags = flags }
end

function V.Complete(lot, info, manual, now)
  if type(lot) ~= 'table' or lot.valueSrc ~= 'unknown' then return false end
  local f = lot.flags
  if type(f) == 'table' and f.invalid then return false end
  local r = V.Value(info, manual)
  if r.valueSrc == 'unknown' then return false end
  lot.valueEach, lot.valueSrc, lot.vt = r.valueEach, r.valueSrc, now
  lot.flags = lot.flags or {}
  lot.flags.unknown, lot.flags.pendingInfo = nil, nil
  if r.flags.noVendor then lot.flags.noVendor = true end
  if r.flags.bound then lot.flags.bound = true end
  return true
end

function V.Expire(lot, now)
  if type(lot) ~= 'table' or type(lot.flags) ~= 'table' or not lot.flags.pendingInfo then return false end
  if type(now) ~= 'number' or type(lot.t) ~= 'number' or now - lot.t < V.PENDING_WINDOW then return false end
  lot.flags.pendingInfo = nil
  return true
end
]=====] },
{ path = "Ledger/Lots.lua", src = [=====[
-- GoldIntel / Ledger / Lots.lua                                   (Phase 3b-3 M1, Architecture AC-15..AC-18, Requirements FR-LED-2/3)
--
-- PURPOSE
--  The asset ledger: one lot per acquisition of one item id, FIFO consumption, conversions, retention.
--  Pure: no Platform, no clock, no storage, and NO dependency on Cash / Reconciler / Expectations (AC-15, I-6):
--  a lot bug can never touch the cash ledger. `state` is the table the caller persists (M3: lots[charKey]).
--
--      local L = GI.Lots.New(state?, { capOpen = 1500, capClosed = 300, emit = fn(kind, record) })
--      L:Add{ itemID, qty, t, src, how, valueEach?, valueSrc?, vc?, flags?, origin?, locConf?, ctx?, ref?, vt?, cost? } -> lot | nil, err
--            cost = copper paid for a purchase lot (M3); informational, never part of value created
--      L:Convert(removed, copper, { t, via, ref?, priceOf? }) -> conversions, short, unallocated
--            removed = { [itemID] = qty }; FIFO per item id; `copper` is divided over the removed units (Q-8, exact sum);
--            short[id] = quantity that no open lot could cover (never invented away); unallocated = copper no lot received
--      L:Complete(itemID, info, manual, now) -> number of lots that received their FIRST valuation
--      L:ExpirePending(now) -> number
--      L:Compact() -> number of merges             open cap: equal-valued lots of one item merge, oldest first
--      opts.alert(kind, record) is called for every anomaly (see Lots.ANOMALY_TEXT, Lots.Describe); never hidden.
--      L:Check(carried) -> ok, diffs               OPTIONAL diagnostic only (D-081): open qty per item id vs a carried map; not an invariant
--      L:OpenQty() -> { [itemID] = qty }           L:InventoryValue() -> copper          L:Stats() -> table
--      GI.Lots.AllocateCopper(total, weights) -> shares summing EXACTLY to total
--
-- Invariants (tested): I-2 a lot is created once and consumed once (qtyLeft never rises, never below 0);
-- I-3 is now an optional diagnostic (D-081); I-5 `vc` (counts as value created) only for src loot or quest, free lots, none of the flags
-- transfer / conversion / opening / gap / unattributed / unexplained (otherwise coerced to false and counted).

local ADDON, GI = ...
GI = GI or {}

local Lots = {}
GI.Lots = Lots

Lots.CAP_OPEN = 1500
Lots.CAP_CLOSED = 300

local SRC = { loot = true, quest = true, vendor = true, mail = true, trade = true, disenchant = true, unknown = true }
local HOW = { free = true, purchase = true }
local VSRC = { market = true, vendor = true, manual = true, unknown = true }
local VIA = { vendor = true, consume = true, trade = true, ah = true, mail = true, purchase = true }
local NO_VC_FLAGS = { transfer = true, conversion = true, opening = true, gap = true, unattributed = true, unexplained = true }

local function isInt(n, lo) return type(n) == "number" and n == math.floor(n) and n >= lo and n < 2 ^ 40 end

--- Splits `total` over `weights` (non-negative numbers) proportionally; the shares always sum to `total`.
-- The remainder goes to the largest weight (first on ties). All-zero weights share equally.
function Lots.AllocateCopper(total, weights)
  local n = #weights
  local shares = {}
  if n == 0 then return shares end
  local sum = 0
  for i = 1, n do sum = sum + weights[i] end
  local w = weights
  if sum <= 0 then
    w = {}
    for i = 1, n do w[i] = 1 end
    sum = n
  end
  local given, big = 0, 1
  for i = 1, n do
    local a = total * w[i]
    local q = (a - math.fmod(a, sum)) / sum
    shares[i] = q
    given = given + q
    if w[i] > w[big] then big = i end
  end
  shares[big] = shares[big] + (total - given)
  return shares
end

local function copyFlags(f)
  local c = {}
  if type(f) == 'table' then for k, v in pairs(f) do if v then c[k] = true end end end
  return c
end

local function flagKey(f)
  local names = {}
  for k in pairs(f) do if k ~= 'merged' then names[#names + 1] = k end end
  table.sort(names)
  return table.concat(names, ',')
end

local Ledger = {}
Ledger.__index = Ledger

function Lots.New(state, opts)
  opts = opts or {}
  state = state or {}
  if type(state.nextId) ~= 'number' then state.nextId = 1 end
  if type(state.open) ~= 'table' then state.open = {} end
  if type(state.closed) ~= 'table' then state.closed = {} end
  if type(state.closedSummary) ~= 'table' then state.closedSummary = {} end
  if type(state.conv) ~= 'table' then state.conv = {} end
  local t = state.totals
  if type(t) ~= 'table' then t = {}; state.totals = t end
  t.created = t.created or { n = 0, value = 0 }
  t.transfer = t.transfer or { n = 0, value = 0 }
  t.unattributed = t.unattributed or { n = 0, qty = 0, value = 0 }
  t.byVia = t.byVia or {}
  local q = state.quality
  if type(q) ~= 'table' then q = {}; state.quality = q end
  q.shortfall = q.shortfall or 0
  q.merged = q.merged or 0
  q.unallocated = q.unallocated or 0
  q.vcCoerced = q.vcCoerced or 0
  if type(state.anomalies) ~= 'table' then state.anomalies = {} end
  state.anomalies.counts = state.anomalies.counts or {}
  state.anomalies.recent = state.anomalies.recent or {}
  return setmetatable({ s = state, capOpen = opts.capOpen or Lots.CAP_OPEN, capClosed = opts.capClosed or Lots.CAP_CLOSED,
    emit = opts.emit, alert = opts.alert }, Ledger)
end

-- Scope (user decision 2026-10-19, D-081): the asset side tracks ACQUISITIONS and CONVERSIONS only. Inventory is an
-- approximation ("acquired and not known disposed"). Converting items that no tracked lot covers (acquired before
-- tracking, from the bank, ...) is NORMAL: it is counted (Stats().shortfall / unallocated) but is not an anomaly.
-- Anomalies: conditions that must never be hidden or treated as normal (user directive 2026-10-19). Each one is counted,
-- kept in a ring, passed to opts.alert(kind, record) EVERY time (the caller decides how to show it; M3 prints one
-- "please report this as a bug" line per kind per session) and listed in Stats().anomalies.
Lots.ANOMALY_TEXT = {
  ['sale-price-unknown'] = 'a vendor sale included an item whose vendor price was not known',
  ['sale-no-sell-price'] = 'money came in at a vendor while an item with no sell price left the bags',
  ['equal-split'] = 'a vendor sale had to be split equally per unit because a price was missing',
  ['vc-coerced'] = 'a lot asked to count as value created but broke the rule and was recorded as not created',
}
Lots.ANOMALY_RING = 50

function Lots.Describe(kind)
  return (Lots.ANOMALY_TEXT[kind] or ('unexpected condition ' .. tostring(kind))) .. '. This is not expected: please report it as a bug.'
end

local function note(self, kind, t, detail)
  local a = self.s.anomalies
  a.counts[kind] = (a.counts[kind] or 0) + 1
  local rec = { t = t, kind = kind, detail = detail }
  a.recent[#a.recent + 1] = rec
  while #a.recent > Lots.ANOMALY_RING do table.remove(a.recent, 1) end
  if self.alert then pcall(self.alert, kind, rec) end
end

local function say(self, kind, rec)
  if self.emit then pcall(self.emit, kind, rec) end
end

-- value bookkeeping: totals follow the lot's value so a later first valuation is attributed to the original lot
local function book(self, lot, copper)
  local t = self.s.totals
  local f = lot.flags
  if lot.vc then
    t.created.value = t.created.value + copper
  elseif f.unattributed then
    t.unattributed.value = t.unattributed.value + copper
  elseif f.transfer or f.opening or f.gap then
    t.transfer.value = t.transfer.value + copper
  end
end

function Ledger:Add(spec)
  if type(spec) ~= 'table' then return nil, 'spec required' end
  if not isInt(spec.itemID, 1) then return nil, 'bad itemID' end
  if not isInt(spec.qty, 1) then return nil, 'bad qty' end
  if type(spec.t) ~= 'number' then return nil, 'bad time' end
  if not SRC[spec.src] then return nil, 'bad src' end
  local how = spec.how or 'free'
  if not HOW[how] then return nil, 'bad how' end
  local vsrc = spec.valueSrc or 'unknown'
  if not VSRC[vsrc] then return nil, 'bad valueSrc' end
  local each = spec.valueEach or 0
  if not isInt(each, 0) then return nil, 'bad valueEach' end
  local flags = copyFlags(spec.flags)
  if vsrc == 'unknown' then
    each = 0
    flags.unknown = true
  end
  local vc = spec.vc == true
  if vc then
    local ok = (spec.src == 'loot' or spec.src == 'quest') and how == 'free'
    if ok then for k in pairs(flags) do if NO_VC_FLAGS[k] then ok = false end end end
    if not ok then
      vc = false
      self.s.quality.vcCoerced = self.s.quality.vcCoerced + 1
      note(self, 'vc-coerced', spec.t, { itemID = spec.itemID, src = spec.src })
    end
  end
  if spec.cost ~= nil and not isInt(spec.cost, 0) then return nil, 'bad cost' end
  local s = self.s
  local lot = {
    id = s.nextId, itemID = spec.itemID, qty = spec.qty, qtyLeft = spec.qty, t = spec.t,
    valueEach = each, valueSrc = vsrc, how = how, src = spec.src, vc = vc, flags = flags,
    origin = spec.origin, locConf = spec.locConf, ctx = spec.ctx, ref = spec.ref, vt = spec.vt or spec.t, out = 0, cost = spec.cost,
  }
  s.nextId = s.nextId + 1
  s.open[#s.open + 1] = lot
  local tot = s.totals
  if vc then tot.created.n = tot.created.n + 1
  elseif flags.unattributed then tot.unattributed.n = tot.unattributed.n + 1; tot.unattributed.qty = tot.unattributed.qty + lot.qty
  elseif flags.transfer or flags.opening or flags.gap then tot.transfer.n = tot.transfer.n + 1 end
  book(self, lot, each * lot.qty)
  say(self, 'lot', lot)
  if #s.open > self.capOpen then self:Compact() end
  return lot
end

local function closeLot(self, lot)
  local s = self.s
  local sum = s.closedSummary[lot.itemID]
  if not sum then sum = { qty = 0, copperIn = 0, copperOut = 0 }; s.closedSummary[lot.itemID] = sum end
  sum.qty = sum.qty + lot.qty
  sum.copperIn = sum.copperIn + lot.valueEach * lot.qty
  sum.copperOut = sum.copperOut + lot.out
  s.closed[#s.closed + 1] = lot
  while #s.closed > self.capClosed do table.remove(s.closed, 1) end
end

-- takes up to `qty` of one item id, oldest lot first. Returns pieces { {lot, n} }, taken
local function take(self, itemID, qty)
  local pieces, taken = {}, 0
  for _, lot in ipairs(self.s.open) do
    if lot.itemID == itemID and lot.qtyLeft > 0 then
      local n = lot.qtyLeft
      if n > qty - taken then n = qty - taken end
      pieces[#pieces + 1] = { lot = lot, n = n }
      taken = taken + n
      if taken >= qty then break end
    end
  end
  return pieces, taken
end

function Ledger:Convert(removed, copper, opts)
  opts = opts or {}
  local convs, short, unalloc = {}, {}, 0
  if type(removed) ~= 'table' then return convs, short, 0 end
  local via = opts.via
  if not VIA[via] then return convs, short, 0, 'bad via' end
  copper = copper or 0
  if not isInt(copper, 0) then return convs, short, 0, 'bad copper' end
  local ids = {}
  for id, q in pairs(removed) do
    if isInt(id, 1) and isInt(q, 1) then ids[#ids + 1] = id end
  end
  table.sort(ids)
  -- weights across items: sellPrice x qty when every price is known, otherwise equal per unit
  local weights, byPrice = {}, type(opts.priceOf) == 'function'
  if byPrice then
    for i, id in ipairs(ids) do
      local p = opts.priceOf(id)
      if not isInt(p, 0) then byPrice = false; break end
      weights[i] = p * removed[id]
    end
  end
  if via == 'vendor' and copper > 0 and type(opts.priceOf) == 'function' then
    for _, id in ipairs(ids) do
      local p = opts.priceOf(id)
      if not isInt(p, 0) then
        note(self, 'sale-price-unknown', opts.t, { itemID = id, copper = copper })
      elseif p == 0 then
        note(self, 'sale-no-sell-price', opts.t, { itemID = id, copper = copper })
      end
    end
  end
  if not byPrice then
    if copper > 0 and #ids > 1 then note(self, 'equal-split', opts.t, { copper = copper, items = #ids }) end
    for i, id in ipairs(ids) do weights[i] = removed[id] end
  end
  local itemCopper = copper > 0 and Lots.AllocateCopper(copper, weights) or {}
  local divided = false
  for i, id in ipairs(ids) do
    local want = removed[id]
    local pieces, taken = take(self, id, want)
    local share = itemCopper[i] or 0
    if taken < want then
      short[id] = want - taken
      self.s.quality.shortfall = self.s.quality.shortfall + (want - taken)
    end
    if #pieces == 0 then
      unalloc = unalloc + share
    else
      local pw = {}
      for k, p in ipairs(pieces) do pw[k] = p.n end
      local pc = share > 0 and Lots.AllocateCopper(share, pw) or {}
      for k, p in ipairs(pieces) do
        local c = pc[k] or 0
        local lot = p.lot
        lot.qtyLeft = lot.qtyLeft - p.n
        lot.out = lot.out + c
        local cv = { t = opts.t, lotID = lot.id, itemID = id, qty = p.n, copper = c, via = via, ref = opts.ref }
        convs[#convs + 1] = cv
        local conv = self.s.conv
        conv[#conv + 1] = cv
        while #conv > self.capClosed do table.remove(conv, 1) end
        local bv = self.s.totals.byVia[via]
        if not bv then bv = { n = 0, qty = 0, copper = 0 }; self.s.totals.byVia[via] = bv end
        bv.n, bv.qty, bv.copper = bv.n + 1, bv.qty + p.n, bv.copper + c
      end
    end
  end
  if copper > 0 and #convs > 1 then
    for _, cv in ipairs(convs) do cv.alloc = true end
    divided = true
  end
  self.s.quality.unallocated = self.s.quality.unallocated + unalloc
  -- retire emptied lots after the loop (no index shifting while iterating)
  local open, keep = self.s.open, {}
  for _, lot in ipairs(open) do
    if lot.qtyLeft == 0 then closeLot(self, lot) else keep[#keep + 1] = lot end
  end
  self.s.open = keep
  for _, cv in ipairs(convs) do say(self, 'conversion', cv) end
  return convs, short, unalloc, nil, divided
end

function Ledger:Complete(itemID, info, manual, now)
  local V = GI.Valuation
  local n = 0
  for _, lot in ipairs(self.s.open) do
    if lot.itemID == itemID and lot.valueSrc == 'unknown' then
      if V.Complete(lot, info, manual, now) then
        n = n + 1
        book(self, lot, lot.valueEach * lot.qty)
        say(self, 'lot', lot)
      end
    end
  end
  return n
end

function Ledger:ExpirePending(now)
  local V = GI.Valuation
  local n = 0
  for _, lot in ipairs(self.s.open) do
    if V.Expire(lot, now) then n = n + 1 end
  end
  return n
end

function Ledger:Compact()
  local open = self.s.open
  if #open <= self.capOpen then return 0 end
  local first, drop, merges = {}, {}, 0
  local excess = #open - self.capOpen
  for i, lot in ipairs(open) do
    if excess > 0 and not lot.flags.pendingInfo then
      local key = table.concat({ lot.itemID, lot.valueEach, lot.valueSrc, lot.how, tostring(lot.vc), flagKey(lot.flags) }, '|')
      local head = first[key]
      if not head then
        first[key] = lot
      else
        head.qty = head.qty + lot.qty
        head.qtyLeft = head.qtyLeft + lot.qtyLeft
        head.out = head.out + lot.out
        head.flags.merged = true
        drop[i] = true
        merges = merges + 1
        excess = excess - 1
      end
    elseif not lot.flags.pendingInfo then
      local key = table.concat({ lot.itemID, lot.valueEach, lot.valueSrc, lot.how, tostring(lot.vc), flagKey(lot.flags) }, '|')
      first[key] = first[key] or lot
    end
  end
  if merges > 0 then
    local keep = {}
    for i, lot in ipairs(open) do if not drop[i] then keep[#keep + 1] = lot end end
    self.s.open = keep
    self.s.quality.merged = self.s.quality.merged + merges
  end
  return merges
end

function Ledger:OpenQty()
  local m = {}
  for _, lot in ipairs(self.s.open) do
    m[lot.itemID] = (m[lot.itemID] or 0) + lot.qtyLeft
  end
  return m
end

function Ledger:Check(carried)
  local open = self:OpenQty()
  local diffs, ok = {}, true
  carried = carried or {}
  for id, q in pairs(open) do
    local d = q - (carried[id] or 0)
    if d ~= 0 then diffs[id] = d; ok = false end
  end
  for id, q in pairs(carried) do
    if open[id] == nil and q ~= 0 then diffs[id] = -q; ok = false end
  end
  return ok, diffs
end

function Ledger:InventoryValue()
  local v = 0
  for _, lot in ipairs(self.s.open) do v = v + lot.qtyLeft * lot.valueEach end
  return v
end

function Ledger:Stats()
  local s = self.s
  local unknownLots, unknownQty, items = 0, 0, {}
  local qtyOpen = 0
  for _, lot in ipairs(s.open) do
    qtyOpen = qtyOpen + lot.qtyLeft
    if lot.valueSrc == 'unknown' then
      unknownLots = unknownLots + 1
      unknownQty = unknownQty + lot.qtyLeft
      items[lot.itemID] = true
    end
  end
  local ui = 0
  for _ in pairs(items) do ui = ui + 1 end
  return {
    openLots = #s.open, openQty = qtyOpen, closedRing = #s.closed, inventoryValue = self:InventoryValue(),
    created = { n = s.totals.created.n, value = s.totals.created.value },
    transfer = { n = s.totals.transfer.n, value = s.totals.transfer.value },
    unattributed = { n = s.totals.unattributed.n, qty = s.totals.unattributed.qty, value = s.totals.unattributed.value },
    unknown = { lots = unknownLots, qty = unknownQty, items = ui },
    shortfall = s.quality.shortfall, merged = s.quality.merged, unallocated = s.quality.unallocated,
    vcCoerced = s.quality.vcCoerced,
    anomalies = (function() local c = {} for k, v in pairs(s.anomalies.counts) do c[k] = v end return c end)(),
  }
end
]=====] },
{ path = "Ledger/Cash.lua", src = [=====[
-- GoldIntel / Ledger / Cash.lua                                    (Phase 3b-2 M3, Architecture AC-12)
--
-- PURPOSE
--  The persistent cash ledger: one compact record per finished entry, per character, in
--  GoldIntelDB.ledger[charKey]. The Reconciler (through Ledger/Ledger.lua) is the only producer.
--
--      Cash.Add(entry)            -> id | nil, reason     entry = what the Reconciler emits (Contracts F14.4)
--      Cash.AddGap(copper, ctx)   -> id | nil, reason     an OTHER entry flagged comp = 'gap' (AC-13)
--      Cash.Last(n)               -> array of expanded entry COPIES, newest last
--      Cash.Cumulative()          -> signed copper of every entry ever added (raw + folded)
--      Cash.Stats()               -> persistent indicators (see below)
--      Cash.Writable()            -> true when the Store saves what is added
--
-- STORAGE (Contracts F5b / F15)
--  ledger[charKey] = {
--    nextId = n,
--    cash   = { rec, ... },                 raw records, oldest first
--    totals = { src = { [src] = { n, copper, val } }, gap = { n, copper, val }, folded = n },
--    locs   = { { mapID, zone, sub }, ... } interned places; a record points at one with `l` (long zone names are
--                                           stored once, not on every entry)
--    quality = { intervals, unmatched },    summed over finished intervals (Ledger.lua)
--    largestOther = n,                      largest |OTHER| ever added (survives folding)
--  }
--  rec = { id, t (unix s), c (signed copper), src, conf, act, ac (actConf), lc (locConf), l?, x?, y?, cr? (true),
--          st? (true), ctx?, r? (loot source type), cp? (comp) }
--
-- RETENTION (D-077 Q-6, interim): when more than CAP (2000) raw records exist, the oldest FOLD (500) are folded into
-- `totals` and removed. Folding never changes Cumulative(): sum(raw) + sum(totals) is constant (AC-12). Final values
-- come from the measured entry size.
--
-- IMMUTABILITY: Add stores a fresh record; nothing hands out a stored table (Last/Expand return copies); there is no
-- update or delete function. A fold only removes whole old records after adding them to the totals.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Ledger/Cash.lua')

local Cash = {}
GI.Cash = Cash

Cash.CAP = 2000
Cash.FOLD = 500
Cash.stats = { added = 0, rejected = 0, folds = 0, gaps = 0 }

local locIndex = {}          -- [ledger table] -> { [key] = index }, rebuilt lazily after a load

local function bus(name, payload)
  if GI.Bus then GI.Bus.Fire(name, payload) end
end

local function charKey()
  local pl = P.Player and P.Player()
  return pl and pl.key or nil
end

local function ledgerTable(create)
  local key = charKey()
  if not key then return nil, 'no character identity' end
  local store = GI.Store
  if not store then return nil, 'no store' end
  local section = store.Section('ledger')
  if not section then return nil, 'no ledger section' end
  local led = section[key]
  if type(led) ~= 'table' then
    if not create then return nil, 'empty' end
    led = {}
    section[key] = led
  end
  if type(led.nextId) ~= 'number' then led.nextId = 1 end
  if type(led.cash) ~= 'table' then led.cash = {} end
  if type(led.totals) ~= 'table' then led.totals = {} end
  if type(led.totals.src) ~= 'table' then led.totals.src = {} end
  if type(led.totals.gap) ~= 'table' then led.totals.gap = { n = 0, copper = 0, val = 0 } end
  if type(led.totals.folded) ~= 'number' then led.totals.folded = 0 end
  if type(led.locs) ~= 'table' then led.locs = {} end
  if type(led.quality) ~= 'table' then led.quality = { intervals = 0, unmatched = 0 } end
  if type(led.largestOther) ~= 'number' then led.largestOther = 0 end
  return led, key
end

function Cash.Writable() return GI.Store ~= nil and GI.Store.IsWritable() end

function Cash.Ledger() return (ledgerTable(true)) end          -- the live table (for Ledger.lua's counters; not for callers)

local function mag(n) return n < 0 and -n or n end
local function round4(v) return math.floor(v * 10000 + 0.5) / 10000 end

local function internLoc(led, loc)
  local idx = locIndex[led]
  if not idx then
    idx = {}
    for i, l in ipairs(led.locs) do idx[tostring(l.mapID) .. '|' .. tostring(l.zone) .. '|' .. tostring(l.sub)] = i end
    locIndex[led] = idx
  end
  local k = tostring(loc.mapID) .. '|' .. tostring(loc.zone) .. '|' .. tostring(loc.sub)
  local i = idx[k]
  if not i then
    i = #led.locs + 1
    led.locs[i] = { mapID = loc.mapID, zone = loc.zone, sub = loc.sub }
    idx[k] = i
  end
  return i
end

local function fold(led)
  local cash, totals = led.cash, led.totals
  local n = math.min(Cash.FOLD, #cash)
  for i = 1, n do
    local r = cash[i]
    local s = totals.src[r.src]
    if not s then s = { n = 0, copper = 0, val = 0 }; totals.src[r.src] = s end
    s.n = s.n + 1; s.copper = s.copper + r.c; s.val = s.val + mag(r.c)
    if r.cp == 'gap' then
      totals.gap.n = totals.gap.n + 1; totals.gap.copper = totals.gap.copper + r.c; totals.gap.val = totals.gap.val + mag(r.c)
    end
  end
  local kept = {}
  for i = n + 1, #cash do kept[#kept + 1] = cash[i] end
  led.cash = kept
  totals.folded = totals.folded + n
  Cash.stats.folds = Cash.stats.folds + 1
end

--- Expands a stored record into the Contracts entry shape (a new table every call).
function Cash.Expand(rec, led, key)
  local e = { id = rec.id, t = rec.t, copper = rec.c, src = rec.src, conf = rec.conf, act = rec.act, actConf = rec.ac,
    locConf = rec.lc, creditable = rec.cr == true, settle = rec.st == true, ctx = rec.ctx, comp = rec.cp, charKey = key }
  if rec.r then e.ref = rec.r end
  if rec.l and led and led.locs[rec.l] then
    local l = led.locs[rec.l]
    e.loc = { mapID = l.mapID, zone = l.zone, sub = l.sub, x = rec.x, y = rec.y }
  end
  return e
end

local function build(e, led)
  local ut, gt = P.Now()
  local rec = {
    id = led.nextId, t = math.floor(ut - (gt - (e.t or gt)) + 0.5), c = e.copper, src = e.src, conf = e.conf or 'low',
    act = e.act or 'OTHER', ac = e.actConf or 'low', lc = e.locConf or 'none',
  }
  if e.loc then
    rec.l = internLoc(led, e.loc)
    if type(e.loc.x) == 'number' then rec.x = round4(e.loc.x) end
    if type(e.loc.y) == 'number' then rec.y = round4(e.loc.y) end
  end
  if e.creditable then rec.cr = true end
  if e.settle then rec.st = true end
  if e.ctx then rec.ctx = e.ctx end
  if e.comp then rec.cp = e.comp end
  local st = e.ref and (type(e.ref) == 'table' and e.ref.sourceType or (type(e.ref) == 'string' and e.ref))
  if st then rec.r = st end
  return rec
end

function Cash.Add(e)
  if type(e) ~= 'table' or type(e.copper) ~= 'number' or e.copper == 0 or e.copper ~= math.floor(e.copper) or type(e.src) ~= 'string' then
    Cash.stats.rejected = Cash.stats.rejected + 1
    return nil, 'invalid entry'
  end
  local led, key = ledgerTable(true)
  if not led then
    Cash.stats.rejected = Cash.stats.rejected + 1
    return nil, key
  end
  local rec = build(e, led)
  led.nextId = led.nextId + 1
  led.cash[#led.cash + 1] = rec
  if rec.src == 'other' and mag(rec.c) > led.largestOther then led.largestOther = mag(rec.c) end
  Cash.stats.added = Cash.stats.added + 1
  if rec.cp == 'gap' then Cash.stats.gaps = Cash.stats.gaps + 1 end
  if #led.cash > Cash.CAP then fold(led) end
  bus('LEDGER_CASH', Cash.Expand(rec, led, key))
  return rec.id
end

function Cash.AddGap(copper, ctx)
  local _, gt = P.Now()
  return Cash.Add({ t = gt, copper = copper, src = 'other', conf = 'low', comp = 'gap', ctx = ctx or 'login',
    act = 'OTHER', actConf = 'low', locConf = 'none', creditable = false })
end

function Cash.Count()
  local led = ledgerTable(false)
  return led and #led.cash or 0
end

function Cash.Last(n)
  local led, key = ledgerTable(false)
  local out = {}
  if not led then return out end
  n = math.max(1, math.min(tonumber(n) or 10, 200))
  for i = math.max(1, #led.cash - n + 1), #led.cash do out[#out + 1] = Cash.Expand(led.cash[i], led, key) end
  return out
end

function Cash.Cumulative()
  local led = ledgerTable(false)
  if not led then return 0 end
  local sum = 0
  for _, r in ipairs(led.cash) do sum = sum + r.c end
  for _, s in pairs(led.totals.src) do sum = sum + s.copper end
  return sum
end

--- Persistent indicators over raw records and folded totals. Shares use absolute copper; value is the headline (D-072).
function Cash.Stats()
  local led = ledgerTable(false)
  local out = { raw = 0, folded = 0, total = 0, cumulative = 0, totalValue = 0, otherN = 0, otherValue = 0,
    otherShareValue = 0, otherShareEntries = 0, largestOther = 0, gapCount = 0, gapValue = 0, unmatched = 0, intervals = 0,
    bySource = {}, writable = Cash.Writable() }
  if not led then return out end
  local by = out.bySource
  local function acc(src, n, copper, av)
    local s = by[src]
    if not s then s = { n = 0, copper = 0, val = 0 }; by[src] = s end
    s.n = s.n + n; s.copper = s.copper + copper; s.val = s.val + av
  end
  for _, r in ipairs(led.cash) do
    acc(r.src, 1, r.c, mag(r.c))
    if r.cp == 'gap' then out.gapCount = out.gapCount + 1; out.gapValue = out.gapValue + mag(r.c) end
  end
  for src, s in pairs(led.totals.src) do acc(src, s.n, s.copper, s.val) end
  out.gapCount = out.gapCount + led.totals.gap.n
  out.gapValue = out.gapValue + led.totals.gap.val
  out.raw, out.folded = #led.cash, led.totals.folded
  for _, s in pairs(by) do
    out.total = out.total + s.n; out.cumulative = out.cumulative + s.copper; out.totalValue = out.totalValue + s.val
  end
  if by.other then out.otherN, out.otherValue = by.other.n, by.other.val end
  if out.total > 0 then out.otherShareEntries = out.otherN / out.total end
  if out.totalValue > 0 then out.otherShareValue = out.otherValue / out.totalValue end
  out.largestOther = led.largestOther
  out.unmatched = led.quality.unmatched
  out.intervals = led.quality.intervals
  return out
end

--- Test helper: forget cached lookups (the saved tables stay).
function Cash.Reset()
  locIndex = {}
  Cash.stats = { added = 0, rejected = 0, folds = 0, gaps = 0 }
end
]=====] },
{ path = "Ledger/Trace.lua", src = [=====[
-- GoldIntel / Ledger / Trace.lua                          (Phase 3b-2, diagnostic build after E-46)
--
-- PURPOSE
--  Evidence only. While a ledger interval is on, writes one text line per fact needed to explain why money was
--  (not) attributed to a loot window:
--      LOOT_OPEN   slot count, every slot (type, amount, source id tail), coin amounts, item count
--      LOOT_CLEAR  slot cleared
--      LOOT_CLOSE  how the window closed and how long it was open
--      EXP         expectation added / closed / consumed (matched) / expired (UNMATCHED) / cleared
--      MONEY       every money delta with the expectations active at that moment
--      ENTRY       every finished ledger entry, its source, expectation id and how long the delta waited
--  Each line starts with seconds since the interval began and seconds since the previous line.
--  It changes no classification: all hooks are optional taps whose errors are swallowed.
--
-- STORAGE   GoldIntelCharDB.trace = { lines = { "...", ... } }, newest last, at most Trace.CAP (1500) lines.
-- COMMAND   /gi ledger trace [n] | clear | on | off

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Ledger/Trace.lua')

local Trace = {}
GI.Trace = Trace
Trace.CAP = 1500
Trace.stats = { lines = 0, errors = 0 }

local on = true
local t0, prev

local function nowGT() local _, gt = P.Now(); return gt end

local function char()
  local ok, c = pcall(GI.Store.Char)
  if ok and type(c) == 'table' then return c end
end

function Trace.IsOn() return on end
function Trace.IsRunning() return t0 ~= nil end

function Trace.Line(text)
  if not on or not t0 then return end
  local c = char()
  if not c then return end
  local gt = nowGT()
  if type(c.trace) ~= 'table' or type(c.trace.lines) ~= 'table' then c.trace = { lines = {} } end
  local L = c.trace.lines
  L[#L + 1] = string.format('%8.3f +%.3f %s', gt - t0, gt - (prev or gt), text)
  prev = gt
  if #L > Trace.CAP then table.remove(L, 1) end
  Trace.stats.lines = Trace.stats.lines + 1
end

local function safe(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then Trace.stats.errors = Trace.stats.errors + 1 end
  end
end

local function expText(e)
  return string.format('#%d %s %s%dc%s', e.id, e.src, e.sign < 0 and '-' or '', e.copper or 0, e.hold and ' hold' or '')
end

--- Group facts (evidence): which group functions exist and what they report.
local function groupText()
  local n, g, r = P.Call('GetNumGroupMembers'), P.Call('IsInGroup'), P.Call('IsInRaid')
  if not n and not g and not r then return 'grp=unavailable' end
  return string.format('grp=%s/%s/%s', n and tostring(n[1]) or 'nofn', g and tostring(g[1]) or 'nofn', r and tostring(r[1]) or 'nofn')
end

local function clean(text)
  return (tostring(text):gsub('|', '<pipe>'):gsub('[%c]', '?'))
end

local function activeText(gt)
  local X = GI.Sources.Expectations()
  if not X then return '[]', '[]' end
  local ex, wi = {}, {}
  for _, e in ipairs(X:Active(gt, nil, 'exact')) do ex[#ex + 1] = expText(e) end
  for _, e in ipairs(X:Active(gt, nil, 'window')) do wi[#wi + 1] = '#' .. e.id .. ' ' .. e.src end
  return '[' .. table.concat(ex, ', ') .. ']', '[' .. table.concat(wi, ', ') .. ']'
end

local function onSources(kind, a, b, c)
  if kind == 'money' then
    local gt = a.gt or nowGT()
    local ex, wi = activeText(gt)
    Trace.Line(string.format('MONEY %+d%s exact=%s windows=%s %s', a.copper, a.gap and ' GAP' or '', ex, wi, groupText()))
  elseif kind == 'entry' then
    local waited = nowGT() - (a.t or nowGT())
    Trace.Line(string.format('ENTRY %+d %s %s%s%s waited=%.3f', a.copper, a.src, a.conf or '?',
      a.exp and (' exp=#' .. a.exp) or '', a.comp and (' ' .. a.comp) or '', waited))
  elseif kind == 'chat' then
    local how, p, win, id = a, b, c, nil
    Trace.Line(string.format('CHATSIG %s %s %dc group=%s%s', how, tostring(p.kind), p.copper, tostring(p.group),
      win and (' window=#' .. win.id) or ''))
  elseif kind == 'exp' then
    local ev, e = a, b
    if ev == 'add' then Trace.Line('EXP add ' .. expText(e))
    elseif ev == 'close' then Trace.Line('EXP close ' .. expText(e))
    elseif ev == 'consume' then Trace.Line('EXP matched ' .. expText(e))
    elseif ev == 'expire' then Trace.Line('EXP expired UNMATCHED ' .. expText(e))
    elseif ev == 'clear' then Trace.Line('EXP interval end UNMATCHED ' .. expText(e)) end
  end
end

local function onLoot(kind, a, b)
  if kind == 'open' then
    Trace.Line(string.format('LOOT_OPEN src=%s frameShown=%s %s numLootItems=%s read=%d coins=[%s] items=%d slots: %s', a.sourceType,
      tostring(a.frame), groupText(), tostring(a.raw), a.slots or 0, table.concat(a.coins, ','), #a.items, table.concat(a.detail or {}, ' ')))
  elseif kind == 'clear' then Trace.Line('LOOT_CLEAR slot=' .. tostring(a))
  elseif kind == 'close' then Trace.Line(string.format('LOOT_CLOSE by=%s open=%.3fs', tostring(a), b or 0)) end
end

local function onChat(rec)
  if rec.secret then Trace.Line('CHAT_MONEY text=<secret value> ' .. groupText())
  elseif rec.nonString then Trace.Line('CHAT_MONEY text=<' .. rec.nonString .. '> ' .. groupText())
  else
    Trace.Line(string.format('CHAT_MONEY parsed=%s %s text="%s"', tostring(rec.copper), groupText(), clean(rec.text)))
  end
end


local function idList(map)
  local ids = {}
  for id in pairs(map or {}) do ids[#ids + 1] = id end
  table.sort(ids)
  local out = {}
  for _, id in ipairs(ids) do out[#out + 1] = id .. 'x' .. map[id] end
  return table.concat(out, ' ')
end

--- Item pipeline facts (3b-3 M2, trace-only): ItemSources.tap(kind, a, b, c)
local function onItems(kind, a, b, cc)
  if kind == 'window' then
    Trace.Line(string.format('ITEM_WIN #%d src=%s skinning=%s act=%s/%s guid=%s', a.id, tostring(a.sourceType), tostring(a.skinning), tostring(a.act), tostring(a.actConf), tostring(a.guid)))
  elseif kind == 'slot' then
    Trace.Line(string.format('ITEM_SLOT win=#%s item=%d qty=%d', tostring(a.windowId), a.itemID, a.qty))
  elseif kind == 'windowClose' then
    Trace.Line(string.format('ITEM_WIN_CLOSE #%s by=%s', a and tostring(a.id) or '?', tostring(b)))
  elseif kind == 'ranges' then
    local t = {}
    for bag = 0, P.BagsModule and P.BagsModule.RANGE_MAX or 8 do t[#t + 1] = bag .. ':' .. tostring(a.slots[bag]) end
    local k = {}
    for name, v in pairs(a.constants) do k[#k + 1] = name .. '=' .. v end
    table.sort(k)
    Trace.Line('BAGRANGE slots ' .. table.concat(t, ' ') .. ' constants ' .. (#k > 0 and table.concat(k, ' ') or 'none'))
  elseif kind == 'baseline' then
    local n = 0
    for _ in pairs(a.items) do n = n + 1 end
    local t = {}
    for bag = 0, P.BagsModule and P.BagsModule.LAST_BAG or 5 do t[#t + 1] = bag .. ':' .. tostring(a.bags and a.bags[bag]) end
    Trace.Line(string.format('BAGS baseline origin=%s distinctItems=%d slotsRead=%d complete=%s bags %s', tostring(b), n, a.slots or 0, tostring(a.complete), table.concat(t, ' ')))
  elseif kind == 'diff' then
    local f = b.facts
    Trace.Line(string.format('BAGS diff seq=%d +[%s] -[%s] slotsRead=%d ctx quest=%s vendor=%s mail=%s trade=%s', a.seq, idList(a.added), idList(a.removed),
      b.snap.slots or 0, tostring(f.quest), tostring(f.merchant), tostring(f.mail), tostring(f.trade)))
  elseif kind == 'skipped' then
    Trace.Line('BAGS settle skipped: incomplete snapshot (slots read ' .. tostring(a and a.slots) .. ')')
  elseif kind == 'snapFail' then
    Trace.Line('BAGS settle: no snapshot (' .. tostring(a) .. ')')
  elseif kind == 'empty' then
    Trace.Line('BAGS settle: no net change')
  elseif kind == 'decision' then
    local d, e, f = a, b, cc
    Trace.Line(string.format('ITEM %s item=%d qty=%d -> %s%s%s reason="%s" waited=%.3f money+%d money-%d', d.dir, d.itemID, d.qty, d.how,
      d.act and (' act=' .. d.act .. '/' .. tostring(d.actConf)) or '', d.skinning and ' SKINNING' or '', clean(d.reason), nowGT() - e.gt,
      f.moneyPos or 0, f.moneyNeg or 0))
  elseif kind == 'iteminfo' then
    if a and b and b.status == 'ready' then
      Trace.Line(string.format('ITEMINFO id=%d name="%s" quality=%s class=%s/%s sell=%s bind=%s', a, clean(b.name), tostring(b.quality), tostring(b.classID), tostring(b.subclassID), tostring(b.sellPrice), tostring(b.bindType)))
    else
      Trace.Line(string.format('ITEMINFO id=%s status=%s', tostring(a), b and tostring(b.status) or 'noModule'))
    end
  elseif kind == 'infoEvent' then
    Trace.Line(string.format('ITEM_INFO_EVENT id=%s ready=%s', tostring(a.itemID), tostring(a.ready)))
  elseif kind == 'anomaly' then
    local t = {}
    for k, v in pairs(b or {}) do t[#t + 1] = k .. '=' .. tostring(v) end
    table.sort(t)
    Trace.Line('ANOMALY ' .. tostring(a) .. ' ' .. table.concat(t, ' ') .. '  -- NOT EXPECTED: please report this as a bug')
  end
end

local function onChatLoot(rec)
  if rec.secret then Trace.Line('CHAT_LOOT text=<secret value>')
  elseif rec.nonString then Trace.Line('CHAT_LOOT text=<' .. rec.nonString .. '>')
  else
    Trace.Line(string.format('CHAT_LOOT kind=%s item=%s qty=%s text="%s"', tostring(rec.kind), tostring(rec.itemID), tostring(rec.qty), clean(rec.text)))
  end
end

--- Evidence recorder (user-found gap 2026-10-21): the player's own casts, with the spell name, so gathering spell ids of other
--- skill ranks can be added from evidence (E-23 listed only one rank per profession). Nothing else reads this.
local function spellName(id) return P.Unit and P.Unit.SpellName and P.Unit.SpellName(id) or nil end

local castSeen = {}
P.On('P_CAST', function(p)
  if not t0 then return end
  if p.kind == 'other' then                    -- unrecognized casts: once per spell id per interval (combat spells would flood the trace)
    if castSeen[p.spellID] then return end
    castSeen[p.spellID] = true
  end
  local ok, err = pcall(function()
    Trace.Line(string.format('CAST spell=%s kind=%s name=%s', tostring(p.spellID), tostring(p.kind), tostring(spellName(p.spellID))))
  end)
  if not ok then Trace.stats.errors = (Trace.stats.errors or 0) + 1 end
end)

--- Starts a trace for a ledger interval (called by Ledger.Begin after Sources.Begin).
function Trace.Begin()
  t0, prev = nowGT(), nil
  castSeen = {}
  GI.Sources.tap = safe(onSources)
  if P.LootModule then P.LootModule.tap = safe(onLoot) end
  if P.ChatModule then P.ChatModule.tap = safe(onChat); P.ChatModule.lootTap = safe(onChatLoot) end
  if GI.ItemSources then GI.ItemSources.tap = safe(onItems) end
  local ut = P.Now()
  Trace.Line(string.format('INTERVAL begin unix=%d version=%s', ut, tostring(P.VERSION)))
  local okS, st = pcall(function() return P.Events.Stats('CHAT_MSG_MONEY') end)
  Trace.Line(string.format('EVIDENCE chatMoneyRegistered=%s %s', tostring(okS and st and st.registered), groupText()))
  local okL, stl = pcall(function() return P.Events.Stats('CHAT_MSG_LOOT') end)
  Trace.Line(string.format('EVIDENCE chatLootRegistered=%s', tostring(okL and stl and stl.registered)))
end

function Trace.End()
  if not t0 then return end
  Trace.Line('INTERVAL end')
  t0, prev = nil, nil
  GI.Sources.tap = nil
  if P.LootModule then P.LootModule.tap = nil end
  if P.ChatModule then P.ChatModule.tap = nil; P.ChatModule.lootTap = nil end
  if GI.ItemSources then GI.ItemSources.tap = nil end
end

function Trace.Lines(n)
  local c = char()
  local L = c and c.trace and c.trace.lines or {}
  n = math.max(1, math.min(tonumber(n) or 40, Trace.CAP))
  local out = {}
  for i = math.max(1, #L - n + 1), #L do out[#out + 1] = L[i] end
  return out
end

--- A free-text marker from the player (what the next lines are about).
function Trace.Note(text)
  if not t0 then return false end
  Trace.Line('NOTE ' .. tostring(text):sub(1, 120))
  return true
end

function Trace.Clear()
  local c = char()
  if c then c.trace = { lines = {} } end
end

function Trace.Switch(v)
  on = v and true or false
end
]=====] },
{ path = "Ledger/LotBook.lua", src = [=====[
-- GoldIntel / Ledger / LotBook.lua                                  (Phase 3b-3 M3, D-080, D-081, D-082, D-083)
--
-- PURPOSE
--  Turns the item decisions of Collect/ItemSources.lua into stored lots (Ledger/Lots.lua) for the current character.
--  The item side is an ECONOMIC ledger, not an inventory mirror (D-081): lots are created only by known acquisitions
--  and consumed only by known conversions; everything else is counted and nothing more.
--
--    CREATED   loot (value created), quest reward (value created), vendor purchase (cost recorded, not created),
--              disenchant materials (conversion, not created)
--    CONSUMED  vendor sale (copper allocated exactly), quest turn-in, disenchant source, trade out (copper 0)
--    COUNTED   mail and trade arrivals, "other additions" (moves, returns, unknown: D-083), inventory-only removals
--
--  AC-15: this module never touches Cash, Reconciler, Expectations or Sources. It reads item decisions only.
--  Storage: GoldIntelDB.lots[charKey] (additive inside schema 2, lazily created; the legacy empty keys stay untouched)
--           GoldIntelDB.prices.manual[itemID] = { copper, t }   (optional override, only by /gi price, D-082)
--  Nothing is written when the store is read-only.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P and GI.Lots and GI.Valuation, 'Platform, Lots and Valuation must be loaded before Ledger/LotBook.lua')

local LB = {}
GI.LotBook = LB

local active, readonly = false, false
local L, state, charKeyNow
local told = {}                              -- anomaly kinds already announced this session
local c

local function fresh()
  c = { batches = 0, lotsCreated = 0, conversions = 0, purchases = 0, ignoredRemovals = 0, ignoredAdds = 0,
        arrivals = 0, otherAdds = 0, errors = 0 }
end
fresh()

local function charKey()
  local pl = P.Player and P.Player()
  return pl and pl.key or nil
end

local function section(name)
  local st = GI.Store
  if not st then return nil end
  local ok, s = pcall(st.Section, name)
  if ok and type(s) == 'table' then return s end
  return nil
end

local function unixNow() return (P.Now()) end

---------------------------------------------------------------------------
-- Manual prices (optional override, D-082): account-wide, only by /gi price
---------------------------------------------------------------------------

local function manualTable(create)
  local s = section('prices')
  if not s then return nil end
  if type(s.manual) ~= 'table' then
    if not create then return nil end
    s.manual = {}
  end
  return s.manual
end

function LB.ManualFor(itemID)
  local m = manualTable(false)
  return m and m[itemID] or nil
end

--- "1g20s5c", "20s", "500c" (units required; a bare number is refused because it is ambiguous). -> copper | nil, err
function LB.ParseMoney(text)
  if type(text) ~= 'string' then return nil, 'a price like 1g20s5c is required' end
  local t = text:lower():gsub('%s+', '')
  if t == '' then return nil, 'a price like 1g20s5c is required' end
  local total
  local rest = t
  local gg, r1 = rest:match('^(%d+)g(.*)$')
  if gg then total = (total or 0) + tonumber(gg) * 10000; rest = r1 end
  local ss, r2 = rest:match('^(%d+)s(.*)$')
  if ss then if tonumber(ss) > 99 and gg then return nil, 'silver must be 0 to 99 when gold is given' end total = (total or 0) + tonumber(ss) * 100; rest = r2 end
  local c1, r3 = rest:match('^(%d+)c(.*)$')
  if c1 then if tonumber(c1) > 99 and (gg or ss) then return nil, 'copper must be 0 to 99 when gold or silver is given' end total = (total or 0) + tonumber(c1); rest = r3 end
  if rest ~= '' or total == nil then return nil, 'could not read "' .. text .. '"; use units, for example 1g20s5c' end
  if total > 2 ^ 40 then return nil, 'price too large' end
  return total
end

function LB.PriceSet(itemID, copper)
  if not GI.Store or not GI.Store.IsWritable() then return false, 'the store is read-only' end
  if type(itemID) ~= 'number' or itemID <= 0 or itemID ~= math.floor(itemID) then return false, 'bad item id' end
  if type(copper) ~= 'number' or copper < 0 then return false, 'bad price' end
  local m = manualTable(true)
  if not m then return false, 'no prices section' end
  m[itemID] = { copper = copper, t = unixNow() }
  return true
end

function LB.PriceClear(itemID)
  local m = manualTable(false)
  if not m or not m[itemID] then return false end
  m[itemID] = nil
  return true
end

function LB.PriceList()
  local m = manualTable(false)
  local out = {}
  if m then for id, v in pairs(m) do out[#out + 1] = { itemID = id, copper = v.copper, t = v.t } end end
  table.sort(out, function(a, b) return a.itemID < b.itemID end)
  return out
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local function lotsState(create)
  local key = charKey()
  if not key then return nil, 'no character identity' end
  local sec = section('lots')
  if not sec then return nil, 'no lots section' end
  local s = sec[key]
  if type(s) ~= 'table' then
    if not create then return nil, 'empty' end
    s = {}
    sec[key] = s
  end
  return s, key
end

local function alert(kind, rec)
  if GI.Trace and GI.Trace.IsRunning and GI.Trace.IsRunning() then
    GI.Trace.Line('ANOMALY ' .. kind .. ' -- NOT EXPECTED: please report this as a bug')
  end
  if not told[kind] then
    told[kind] = true
    P.Print('GoldIntel: UNEXPECTED item condition: ' .. GI.Lots.Describe(kind))
  end
end

local function emit(kind, rec)
  if GI.Trace and GI.Trace.IsRunning and GI.Trace.IsRunning() and kind == 'conversion' then
    GI.Trace.Line(string.format('LOT conversion lot=%s item=%s qty=%s copper=%s via=%s', tostring(rec.lotID), tostring(rec.itemID), tostring(rec.qty), tostring(rec.copper), tostring(rec.via)))
  elseif GI.Trace and GI.Trace.IsRunning and GI.Trace.IsRunning() and kind == 'lot' then
    GI.Trace.Line(string.format('LOT lot=%s item=%s qty=%s each=%s src=%s how=%s valueSrc=%s vc=%s', tostring(rec.id), tostring(rec.itemID), tostring(rec.qty), tostring(rec.valueEach), tostring(rec.src), tostring(rec.how), tostring(rec.valueSrc), tostring(rec.vc)))
  end
end

---------------------------------------------------------------------------
-- Decisions -> lots
---------------------------------------------------------------------------

local function priceOf(id)
  local info = P.ItemsModule and P.ItemsModule.Get(id)
  if info and info.status == 'ready' and type(info.sellPrice) == 'number' then return info.sellPrice end
  return nil
end

local function origin(d)
  local o = { act = d.act, actConf = d.actConf }
  if d.loc then o.mapID, o.zone, o.sub, o.x, o.y = d.loc.mapID, d.loc.zone, d.loc.sub, d.loc.x, d.loc.y end
  if d.skinning then o.skinning = true end
  return o
end

local function addLot(d, now, src, how, vc, extraFlags, cost)
  local info = P.ItemsModule and P.ItemsModule.Get(d.itemID) or { status = 'invalid' }
  local r = GI.Valuation.Value(info, LB.ManualFor(d.itemID))
  local flags = {}
  for k in pairs(r.flags) do flags[k] = true end
  for k in pairs(extraFlags or {}) do flags[k] = true end
  local lot, err = L:Add{ itemID = d.itemID, qty = d.qty, t = now, src = src, how = how, valueEach = r.valueEach,
    valueSrc = r.valueSrc, vc = vc, flags = flags, origin = origin(d), locConf = d.locConf, cost = cost }
  if not lot then c.errors = c.errors + 1; P.Diag('error', 'LotBook', 'Add refused: ' .. tostring(err)); return end
  c.lotsCreated = c.lotsCreated + 1
end

--- decisions from ItemSources, info = { gt, unix, moneyPos, moneyNeg }
function LB.OnDecisions(decisions, info)
  if not active or not L then return end
  local now = info.unix or unixNow()
  c.batches = c.batches + 1
  local sales, consume, trade = {}, {}, {}
  local anySales, anyConsume, anyTrade = false, false, false
  for _, d in ipairs(decisions) do
    if d.dir == 'remove' then
      if d.how == 'vendorSale' then sales[d.itemID] = (sales[d.itemID] or 0) + d.qty; anySales = true
      elseif d.how == 'questConsume' or d.how == 'disenchantSrc' then consume[d.itemID] = (consume[d.itemID] or 0) + d.qty; anyConsume = true
      elseif d.how == 'tradeOut' then trade[d.itemID] = (trade[d.itemID] or 0) + d.qty; anyTrade = true
      else c.ignoredRemovals = c.ignoredRemovals + 1 end
    end
  end
  if anySales then
    local convs = L:Convert(sales, info.moneyPos or 0, { t = now, via = 'vendor', priceOf = priceOf })
    c.conversions = c.conversions + #convs
  end
  if anyConsume then c.conversions = c.conversions + #L:Convert(consume, 0, { t = now, via = 'consume' }) end
  if anyTrade then c.conversions = c.conversions + #L:Convert(trade, 0, { t = now, via = 'trade' }) end
  -- purchases share the money that left the character in this entry, per unit
  local buys, weights = {}, {}
  for _, d in ipairs(decisions) do
    if d.dir == 'add' and d.how == 'vendorBuy' then buys[#buys + 1] = d; weights[#weights + 1] = d.qty end
  end
  local costs = (#buys > 0) and GI.Lots.AllocateCopper(info.moneyNeg or 0, weights) or {}
  local bi = 0
  for _, d in ipairs(decisions) do
    if d.dir == 'add' then
      if d.how == 'loot' then addLot(d, now, 'loot', 'free', true)
      elseif d.how == 'quest' then addLot(d, now, 'quest', 'free', true)
      elseif d.how == 'disenchantMat' then addLot(d, now, 'disenchant', 'free', false, { conversion = true })
      elseif d.how == 'vendorBuy' then
        bi = bi + 1
        c.purchases = c.purchases + 1
        addLot(d, now, 'vendor', 'purchase', false, nil, costs[bi] or 0)
      elseif d.how == 'mail' or d.how == 'trade' then c.arrivals = c.arrivals + 1
      else c.otherAdds = c.otherAdds + 1 end
    end
  end
  L:ExpirePending(now)
  L:Compact()
end

local function onItemInfo(p)
  if not active or not L or not p.ready then return end
  local info = P.ItemsModule.Get(p.itemID)
  if info.status == 'ready' then L:Complete(p.itemID, info, LB.ManualFor(p.itemID), unixNow()) end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------

local wired = false

--- Called by Ledger.Begin after ItemSources.Begin. Returns true when lots are being stored.
function LB.Begin()
  if active then return true end
  fresh()
  told = {}
  readonly = false
  if not (GI.Store and GI.Store.IsWritable()) then readonly = true; return false end
  local s, key = lotsState(true)
  if not s then readonly = true; return false end
  state, charKeyNow = s, key
  L = GI.Lots.New(s, { alert = alert, emit = emit })
  active = true
  if not wired then
    wired = true
    P.On('P_ITEM_INFO', function(p) local ok, err = pcall(onItemInfo, p); if not ok then c.errors = c.errors + 1; P.Diag('error', 'LotBook', tostring(err)) end end)
  end
  if GI.ItemSources then GI.ItemSources.sink = LB.OnDecisions end
  -- lots still waiting for item data (a previous session, a cold cache): ask again and complete what is ready now
  local seen, now = {}, unixNow()
  for _, lot in ipairs(s.open) do
    if lot.valueSrc == 'unknown' and not (lot.flags and lot.flags.invalid) and not seen[lot.itemID] then
      seen[lot.itemID] = true
      local info = P.ItemsModule.Get(lot.itemID)
      if info.status == 'ready' then L:Complete(lot.itemID, info, LB.ManualFor(lot.itemID), now) end
    end
  end
  return true
end

function LB.End()
  if GI.ItemSources and GI.ItemSources.sink == LB.OnDecisions then GI.ItemSources.sink = nil end
  active = false
end

function LB.IsActive() return active end
function LB.ReadOnly() return readonly end
function LB.Instance() return L end

--- Test helper.
function LB.Reset() active, readonly, L, state = false, false, nil, nil; told = {}; fresh() end

---------------------------------------------------------------------------
-- Reports (lines of text; the commands print them)
---------------------------------------------------------------------------

local function fmt(cop)
  cop = cop or 0
  local g, s, cc = math.floor(cop / 10000), math.floor(cop / 100) % 100, math.floor(cop % 100)
  local parts = {}
  if g > 0 then parts[#parts + 1] = string.format('%dg', g) end
  if s > 0 then parts[#parts + 1] = string.format('%ds', s) end
  if cc > 0 or #parts == 0 then parts[#parts + 1] = string.format('%dc', cc) end
  return table.concat(parts, ' ')
end
LB.Format = fmt

local function nameOf(id)
  local info = P.ItemsModule and P.ItemsModule.Get(id)
  if info and info.status == 'ready' and info.name then return info.name end
  return 'item ' .. tostring(id)
end

--- The stored state even when the interval is off.
local function view()
  if L then return L end
  local s = lotsState(false)
  if not s then return nil end
  return GI.Lots.New(s, {}), s
end

function LB.Status()
  local lines = {}
  local v = view()
  if not v then
    lines[1] = 'lots stored: none yet for this character'
    return lines
  end
  local st = v:Stats()
  lines[#lines + 1] = string.format('lots stored: %d open (%d units), %d recent closed; inventory value (acquired, not known disposed) %s',
    st.openLots, st.openQty, st.closedRing, fmt(st.inventoryValue))
  lines[#lines + 1] = string.format('value created by loot and quests: %s in %d lots; unknown value: %d lots / %d items',
    fmt(st.created.value), st.created.n, st.unknown.lots, st.unknown.items)
  lines[#lines + 1] = string.format('conversions not covered by a lot (normal, D-081): %d units, %s unallocated; merged lots %d',
    st.shortfall, fmt(st.unallocated), st.merged)
  lines[#lines + 1] = string.format('this interval: batches %d, lots created %d (purchases %d), conversions %d, ignored removals %d, mail/trade arrivals %d, other additions (moves, returns, unknown) %d, errors %d',
    c.batches, c.lotsCreated, c.purchases, c.conversions, c.ignoredRemovals, c.arrivals, c.otherAdds, c.errors)
  local bv = (view() and select(2, view())) or state
  local via = bv and bv.totals and bv.totals.byVia
  if via then
    local order = {}
    for k in pairs(via) do order[#order + 1] = k end
    table.sort(order)
    local parts = {}
    for _, k in ipairs(order) do parts[#parts + 1] = string.format('%s %d units for %s', k, via[k].qty, fmt(via[k].copper)) end
    if #parts > 0 then lines[#lines + 1] = 'conversions so far: ' .. table.concat(parts, '; ') end
  end
  local an = {}
  for k, n in pairs(st.anomalies) do an[#an + 1] = k .. ' ' .. n end
  table.sort(an)
  if #an > 0 then lines[#lines + 1] = 'ANOMALIES (not expected, please report as a bug): ' .. table.concat(an, ', ') end
  if readonly then lines[#lines + 1] = 'the store is read-only: nothing is being saved' end
  return lines
end

function LB.Last(n)
  n = math.max(1, math.min(tonumber(n) or 10, 30))
  local v, s = view()
  local lines = {}
  if not v then return { 'lots: none yet for this character' } end
  s = s or state
  local all = {}
  for _, lot in ipairs(s.closed) do all[#all + 1] = lot end
  for _, lot in ipairs(s.open) do all[#all + 1] = lot end
  table.sort(all, function(a, b) return a.id < b.id end)
  for i = math.max(1, #all - n + 1), #all do
    local lot = all[i]
    local worth = (lot.flags and lot.flags.noVendor and lot.valueSrc == 'vendor') and 'no vendor value'
      or (fmt(lot.valueEach) .. ' each [' .. lot.valueSrc .. ']')
    local act = lot.origin and lot.origin.act
    lines[#lines + 1] = string.format('#%d %s x%d (%d left) %s %s/%s%s%s%s', lot.id, nameOf(lot.itemID), lot.qty, lot.qtyLeft,
      worth, lot.src, lot.how, act and (' ' .. act .. (lot.origin.skinning and ' (skinning)' or '')) or '', lot.vc and ' value-created' or '',
      (lot.flags and lot.flags.unknown) and (lot.flags.invalid and ' UNKNOWN(invalid item)' or ' UNKNOWN(waiting for item data)') or '')
  end
  if #lines == 0 then lines[1] = 'lots: none yet for this character' end
  return lines
end

--- The most recent conversions (what each lot received when it left), newest last.
function LB.Sales(n)
  n = math.max(1, math.min(tonumber(n) or 15, 40))
  local _, s = view()
  s = s or state
  if not s or #s.conv == 0 then return { 'lots: no conversions yet' } end
  local lines = {}
  for i = math.max(1, #s.conv - n + 1), #s.conv do
    local cv = s.conv[i]
    lines[#lines + 1] = string.format('lot #%d %s x%d -> %s via %s%s', cv.lotID, nameOf(cv.itemID), cv.qty, fmt(cv.copper), cv.via, cv.alloc and ' (split)' or '')
  end
  return lines
end

function LB.Unknown()
  local _, s = view()
  s = s or state
  local lines, byItem, order = {}, {}, {}
  if s then
    for _, lot in ipairs(s.open) do
      if lot.valueSrc == 'unknown' then
        local e = byItem[lot.itemID]
        if not e then e = { qty = 0, invalid = false }; byItem[lot.itemID] = e; order[#order + 1] = lot.itemID end
        e.qty = e.qty + lot.qtyLeft
        if lot.flags and lot.flags.invalid then e.invalid = true end
      end
    end
  end
  table.sort(order)
  for _, id in ipairs(order) do
    local e = byItem[id]
    lines[#lines + 1] = string.format('item %d %s x%d: %s', id, nameOf(id), e.qty, e.invalid and 'invalid item id (stays unknown)' or 'waiting for item data (retried at login and when the data arrives)')
  end
  if #lines == 0 then lines[1] = 'lots: no unknown values' end
  return lines
end

--- Optional diagnostic (D-081): stored open quantities against what is in the bags now. Differences are expected
--- (items used, destroyed, moved to the bank or acquired before tracking); this is not an invariant.
function LB.Check()
  local v = view()
  if not v then return { 'lots check: no lots stored for this character' } end
  local snap = P.BagsModule and P.BagsModule.Snapshot()
  if not snap then return { 'lots check: the bags could not be read now' } end
  local ok, diffs = v:Check(snap.items)
  local ids = {}
  for id in pairs(diffs) do ids[#ids + 1] = id end
  table.sort(ids)
  local lines = { string.format('lots check (diagnostic only): %d item ids differ from the bags%s', #ids, snap.complete and '' or ' (bag read incomplete)') }
  for i = 1, math.min(#ids, 10) do
    local id, d = ids[i], diffs[ids[i]]
    lines[#lines + 1] = string.format('  %s: %s%d (%s)', nameOf(id), d > 0 and '+' or '', d, d > 0 and 'lots hold more than the bags' or 'bags hold more than the lots')
  end
  if #ids > 10 then lines[#lines + 1] = string.format('  ... and %d more', #ids - 10) end
  return lines
end

--- Deletes the current character's lots only. The caller has already checked for the word "confirm".
function LB.ResetCurrent()
  if not (GI.Store and GI.Store.IsWritable()) then return false, 'the store is read-only' end
  local key = charKey()
  local sec = section('lots')
  if not key or not sec then return false, 'no character identity' end
  sec[key] = nil
  if active then
    local s = lotsState(true)
    state = s
    L = GI.Lots.New(s, { alert = alert, emit = emit })
  else
    L = nil
  end
  told = {}
  return true
end

---------------------------------------------------------------------------
-- /gi price  (optional manual override, never used unless set; D-082)
---------------------------------------------------------------------------

if GI.Commands then
  local function say(line) P.Print(line) end
  GI.Commands.Register('price', {
    help = 'optional manual item price (override): set <item id or link> <1g20s5c> | list | clear <item id or link>',
    usage = 'price set <item> <price> | list | clear <item>',
    fn = function(args)
      local sub = args[1]
      local function itemId()
        local rest = table.concat(args, ' ', 2)
        return tonumber(rest:match('item:(%d+)')) or tonumber(args[2])
      end
      if sub == 'list' or sub == nil then
        local list = LB.PriceList()
        if #list == 0 then say('prices: no manual prices set (the vendor value is used)'); return end
        for _, e in ipairs(list) do say(string.format('manual price: %s (item %d) = %s', nameOf(e.itemID), e.itemID, fmt(e.copper))) end
      elseif sub == 'set' then
        local id = itemId()
        if not id then say('usage: /gi price set <item id or link> <price such as 1g20s5c>'); return end
        local copper, err = LB.ParseMoney(args[#args])
        if #args < 3 or not copper then say('prices: ' .. tostring(err or 'a price like 1g20s5c is required')); return end
        local ok, why = LB.PriceSet(id, copper)
        if ok then
          say(string.format('prices: item %d (%s) manual price %s. It is used only when higher than the vendor value, for new lots and current views; past values are not changed.', id, nameOf(id), fmt(copper)))
        else
          say('prices: ' .. tostring(why))
        end
      elseif sub == 'clear' then
        local id = itemId()
        if not id then say('usage: /gi price clear <item id or link>'); return end
        say(LB.PriceClear(id) and ('prices: manual price for item ' .. id .. ' removed') or ('prices: no manual price for item ' .. id))
      else
        say('usage: /gi price set <item> <price> | list | clear <item>')
      end
    end,
  })
end
]=====] },
{ path = "Ledger/Ledger.lua", src = [=====[
-- GoldIntel / Ledger / Ledger.lua                                  (Phase 3b-2 M3, Architecture AC-9, AC-13)
--
-- PURPOSE
--  Runs the ledger intervals and ties Sources -> Reconciler -> Cash together:
--    * `collect on` (all groups) begins an interval, `collect off` ends it (Collector calls OnCollectOn / OnCollectOff);
--    * every finished entry goes to Cash and `lastMoney` (GoldIntelCharDB) follows the balance;
--    * at login a difference between the saved `lastMoney` and the balance is one OTHER entry flagged gap (AC-13,
--      R-3b2-1: a client crash loses the whole session, the next login still keeps the cumulative sum honest);
--    * at logout / reload the interval is ended first, so pending deltas are written before the client saves.
--    * /gi ledger status | last [n] | mark | check | on | off     and the quality block of /gi diag.
--
-- AC-9: money that moves while collect is OFF is not recorded (only the baseline `lastMoney` is refreshed).
-- Nothing here is persisted except what Cash and CharDB.lastMoney hold; the switch, the mark and the interval are
-- session memory (OFF after every login and reload, D-077 Q-2).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
local Core = GI.Core
assert(P and Core, 'Platform and Core must be loaded before Ledger/Ledger.lua')
assert(GI.Cash and GI.Sources, 'Ledger/Cash.lua and Collect/Sources.lua must be loaded first')

local Ledger = Core.Module('Ledger', { deps = { 'Collector' } })
GI.Ledger = Ledger

local switch = true            -- /gi ledger off switches the Reconciler off while collect stays on
local intervalStart            -- gt
local mark                     -- { balance, cumulative, pending, gt, t }
local last = { reason = 'not started' }

local function nowGT() local _, gt = P.Now(); return gt end

local function char()
  local ok, c = pcall(GI.Store.Char)
  if ok and type(c) == 'table' then return c end
  return nil
end

local function balance()
  local v = P.MoneyModule.Get()
  return v
end

local function setLastMoney(v)
  local c = char()
  if c and type(v) == 'number' then c.lastMoney = v; c.lmv = 2 end
end

local function sink(entry)
  local id, err = GI.Cash.Add(entry)
  if not id then P.Diag('error', 'Ledger', 'entry refused: ' .. tostring(err)) end
  -- lastMoney follows the LEDGER (previous lastMoney + this entry), not the live balance: money still pending
  -- (waiting for its chat line, WAIT 2.0 s) must be recovered as a gap after a crash, never skipped or counted twice
  local c = char()
  if id and c and c.lmv == 2 and type(c.lastMoney) == 'number' then setLastMoney(c.lastMoney + entry.copper)
  elseif id then setLastMoney(P.MoneyModule.Last()) end
end

local lotsSwitch = true          -- /gi lots on|off (AC-19): independent of the ledger switch; nothing runs without an interval
function Ledger.LotsSwitch() return lotsSwitch end

function Ledger.IsOn() return GI.Sources.IsActive() end
function Ledger.Switch() return switch end

--- Begins an interval (AC-9). Returns true, or false plus a reason.
function Ledger.Begin()
  if GI.Sources.IsActive() then return false, 'already on' end
  if not switch then return false, 'switched off (/gi ledger on)' end
  if not P.MoneyModule.Last() then P.MoneyModule.Sync(false) end
  GI.Sources.SetSink(sink)
  GI.Sources.Begin()
  if GI.Trace then GI.Trace.Begin() end
  if lotsSwitch and GI.ItemSources then
    GI.ItemSources.Begin()
    if GI.LotBook then GI.LotBook.Begin() end                               -- 3b-3 M3: stores lots (never cash)
  end
  intervalStart = nowGT()
  setLastMoney(P.MoneyModule.Last())
  last = { reason = 'on' }
  return true
end

--- Ends the interval: pending deltas become OTHER at once, quality counters are added to the ledger.
function Ledger.End()
  if not GI.Sources.IsActive() then return false, 'not on' end
  GI.Sources.End()
  if GI.LotBook then GI.LotBook.End() end
  if GI.ItemSources then GI.ItemSources.End() end
  if GI.Trace then GI.Trace.End() end
  GI.Sources.SetSink(nil)
  local s = GI.Sources.Stats()
  local led = GI.Cash.Ledger()
  if led then
    led.quality.intervals = led.quality.intervals + 1
    led.quality.unmatched = led.quality.unmatched + (s and s.unmatched or 0)
  end
  setLastMoney(P.MoneyModule.Last() or balance())
  mark = nil
  intervalStart = nil
  last = { reason = 'ended', stats = s }
  return true
end

---------------------------------------------------------------------------
-- Collector hooks
---------------------------------------------------------------------------

--- Called by Collector.On. `partial` = a single group was requested.
function Ledger.OnCollectOn(partial)
  if partial then last = { reason = 'not started: partial collection (use /gi collect on)' }; return false, last.reason end
  local ok, why = Ledger.Begin()
  if not ok then last = { reason = why }; return false, why end
  return true
end

function Ledger.OnCollectOff()
  if GI.Sources.IsActive() then Ledger.End() end
end

---------------------------------------------------------------------------
-- Login gap check and logout (AC-13, R-3b2-1)
---------------------------------------------------------------------------

function Ledger.CheckLoginGap()
  if not GI.Store.IsWritable() then return nil, 'store not writable' end
  local c = char()
  if not c then return nil, 'no character table' end
  local now = balance()
  if not now then return nil, 'balance unreadable' end
  local saved = c.lastMoney
  if type(saved) ~= 'number' then setLastMoney(now); return 0 end          -- first run: baseline only
  -- E-46: 0.3.3 stored lastMoney = 0 at a real logout (GetMoney reads 0 while the client logs out). A value without the
  -- lmv = 2 marker is not trusted: it becomes the new baseline once, with no gap entry.
  if c.lmv ~= 2 then setLastMoney(now); return 0 end
  if now ~= saved then
    GI.Cash.AddGap(now - saved, 'login')
    setLastMoney(now)
    return now - saved
  end
  return 0
end

function Ledger.OnEnable()
  local ok, res = pcall(Ledger.CheckLoginGap)
  if not ok then P.Diag('error', 'Ledger', 'login check failed: ' .. tostring(res)) end
  last.gap = ok and res or nil
end

function Ledger.OnLogout()
  if GI.Sources.IsActive() then Ledger.End() end
  if GI.Store.IsWritable() then
    -- E-46: GetMoney() returns 0 during a real logout, so the balance this module has accounted for is stored instead
    -- (Money tracks every PLAYER_MONEY, also while collect is off). The live read is only a fallback when it is positive.
    local v = P.MoneyModule.Last()
    if not v then
      local live = balance()
      if live and live > 0 then v = live end
    end
    if v then setLastMoney(v) end
  end
end

---------------------------------------------------------------------------
-- Mark / check (live validation, D-072: the ledger difference must be 0 copper)
---------------------------------------------------------------------------

local function pendingSum()
  local R = GI.Sources.Reconciler()
  return R and R:PendingSum() or 0
end

function Ledger.Mark()
  if not GI.Sources.IsActive() then return nil, 'ledger interval is not on (use /gi collect on)' end
  local bal = balance()
  if not bal then return nil, 'balance unreadable' end
  mark = { balance = bal, cumulative = GI.Cash.Cumulative(), pending = pendingSum(), gt = nowGT() }
  return mark
end

--- Compares the live balance change since the mark with what the ledger holds. difference must be 0.
function Ledger.Check()
  if not mark then return nil, 'no mark (use /gi ledger mark first)' end
  local bal = balance()
  if not bal then return nil, 'balance unreadable' end
  local moved = bal - mark.balance
  local entries = GI.Cash.Cumulative() - mark.cumulative
  local pending = pendingSum() - mark.pending
  local seen = P.MoneyModule.Last()
  return {
    moved = moved, entries = entries, pending = pending,
    unseen = seen and (bal - seen) or 0,                       -- money that moved but PLAYER_MONEY has not been processed yet
    difference = moved - entries - pending,
    seconds = nowGT() - mark.gt,
  }
end

---------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------

local function money(c)
  local sign = c < 0 and '-' or '+'
  c = c < 0 and -c or c
  local g, s, cc = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = g .. 'g' end
  if s > 0 then parts[#parts + 1] = s .. 's' end
  if cc > 0 or #parts == 0 then parts[#parts + 1] = cc .. 'c' end
  return sign .. table.concat(parts, ' ')
end
Ledger.Money = money

local function pct(x) return string.format('%.1f%%', x * 100) end

--- The review indicators, one block (used by /gi ledger status and /gi diag).
function Ledger.QualityLines()
  local stored = GI.Cash.Stats()
  local lines = {}
  local s = GI.Sources.Stats()
  if s then
    lines[#lines + 1] = string.format('this interval: OTHER %s by value (%s by entries), largest OTHER %s, gaps %d (%s), unmatched %d, pending %d',
      pct(s.otherShareValue), pct(s.otherShareEntries), money(s.largestOther), s.gapCount, money(s.gapValue), s.unmatched, s.pending)
  end
  if stored.total > 0 or stored.gapCount > 0 then
    lines[#lines + 1] = string.format('stored: OTHER %s by value (%s by entries), largest OTHER %s, gaps %d (%s), unmatched %d over %d interval(s)',
      pct(stored.otherShareValue), pct(stored.otherShareEntries), money(stored.largestOther), stored.gapCount, money(stored.gapValue),
      stored.unmatched, stored.intervals)
  end
  return lines
end

function Ledger.StatusLines()
  local lines = {}
  local on = GI.Sources.IsActive()
  local s = GI.Sources.Stats()
  lines[#lines + 1] = string.format('ledger: %s (switch %s)%s', on and 'ON' or 'off', switch and 'on' or 'OFF',
    on and intervalStart and string.format(', interval %.0f s', nowGT() - intervalStart) or '')
  if not on and last.reason and last.reason ~= 'on' then lines[#lines + 1] = '  ' .. tostring(last.reason) end
  if s then
    local ok = GI.Sources.Reconciler():Check()
    lines[#lines + 1] = string.format('interval: %d entries, money deltas %s, entries %s, pending %s -> sum check %s',
      s.total, money(s.sumDeltas), money(s.sumEntries), money(pendingSum()), ok and 'OK' or 'MISMATCH')
  end
  for _, l in ipairs(Ledger.QualityLines()) do lines[#lines + 1] = l end
  local st = GI.Cash.Stats()
  lines[#lines + 1] = string.format('stored: %d raw entries + %d folded, cumulative %s, saving %s, refused %d',
    st.raw, st.folded, money(st.cumulative), st.writable and 'yes' or 'NO (read-only or unavailable store)', GI.Cash.stats.rejected)
  local order = {}
  for src in pairs(st.bySource) do order[#order + 1] = src end
  table.sort(order)
  local parts = {}
  for _, src in ipairs(order) do parts[#parts + 1] = string.format('%s %d (%s)', src, st.bySource[src].n, money(st.bySource[src].copper)) end
  if #parts > 0 then lines[#lines + 1] = 'by source: ' .. table.concat(parts, ', ') end
  return lines
end

function Ledger.DiagLines()
  local lines = Ledger.QualityLines()
  if #lines > 0 then table.insert(lines, 1, 'ledger quality (OTHER share by value is the headline):') end
  return lines
end

local function say(line) P.Print(line) end

if GI.Commands then
  GI.Commands.Register('ledger', {
    help = 'cash ledger: status | last [n] | mark | check | on | off | trace [n|clear|on|off|note text]',
    usage = 'ledger [status|last [n]|mark|check|on|off|trace [n|clear|on|off|note text]]',
    fn = function(args)
      local sub = args[1] or 'status'
      if sub == 'status' then
        for _, l in ipairs(Ledger.StatusLines()) do say(l) end
      elseif sub == 'last' then
        local list = GI.Cash.Last(tonumber(args[2]) or 10)
        if #list == 0 then say('ledger: no entries'); return end
        for _, e in ipairs(list) do
          say(string.format('#%d %s %s %s act=%s/%s loc=%s%s%s%s', e.id, money(e.copper), e.src, e.conf, e.act, e.actConf, e.locConf,
            e.loc and e.loc.zone and (' ' .. e.loc.zone) or '', e.creditable and ' creditable' or '', (e.settle and ' settle' or '') .. (e.comp and (' ' .. e.comp) or '')))
        end
      elseif sub == 'mark' then
        local m, err = Ledger.Mark()
        if not m then say('ledger mark: ' .. tostring(err)); return end
        say(string.format('ledger mark set: balance %s, ledger %s, pending %s', money(m.balance):sub(2), money(m.cumulative), money(m.pending)))
      elseif sub == 'check' then
        local r, err = Ledger.Check()
        if not r then say('ledger check: ' .. tostring(err)); return end
        say(string.format('ledger check over %.0f s: money moved %s, entries %s, pending %s, unseen %s -> DIFFERENCE %d copper %s',
          r.seconds, money(r.moved), money(r.entries), money(r.pending), money(r.unseen), r.difference, r.difference == 0 and '(OK)' or '(MISMATCH)'))
      elseif sub == 'trace' then
        local T = GI.Trace
        local a2 = args[2]
        if a2 == 'clear' then T.Clear(); say('ledger trace: cleared')
        elseif a2 == 'note' then
          local text = table.concat(args, ' ', 3)
          if text == '' then say('usage: /gi ledger trace note <text>')
          elseif T.Note(text) then say('ledger trace: note added')
          else say('ledger trace: no interval is on (use /gi collect on first)') end
        elseif a2 == 'on' then T.Switch(true); say('ledger trace: on (records while a ledger interval is on)')
        elseif a2 == 'off' then T.Switch(false); say('ledger trace: off')
        else
          local list = T.Lines(tonumber(a2) or 40)
          if #list == 0 then say('ledger trace: no lines (trace is ' .. (T.IsOn() and 'on' or 'off') .. ')'); return end
          for _, l in ipairs(list) do say(l) end
        end
      elseif sub == 'on' then
        switch = true
        local c = GI.Collector and GI.Collector.IsEnabled and GI.Collector.IsEnabled()
        if not c then say('ledger: switch on; the interval starts with /gi collect on'); return end
        local ok, why = Ledger.Begin()
        say(ok and 'ledger: on' or ('ledger: ' .. tostring(why)))
      elseif sub == 'off' then
        switch = false
        if GI.Sources.IsActive() then Ledger.End() end
        say('ledger: off (collect keeps counting events)')
      else
        say('usage: /gi ledger [status|last [n]|mark|check|on|off|trace [n|clear|on|off]]')
      end
    end,
  })

  -- 3b-3: item lots (M2 trace of decisions, M3 stored lots). Lots never write cash (AC-15).
  local function lotsStatus()
    local IS, Ch = GI.ItemSources, P.ChatModule
    say(string.format('lots: %s (switch %s)', IS and IS.IsActive() and 'ON' or 'off', lotsSwitch and 'on' or 'OFF'))
    if GI.LotBook then for _, l in ipairs(GI.LotBook.Status()) do say(l) end end
    local s = IS and IS.Stats()
    if s then
      say(string.format('bag settles %d: baselines %d, diffs %d, empty %d, skipped (incomplete) %d, no snapshot %d; decisions %d, errors %d',
        s.settles, s.baselines, s.diffs, s.empty, s.skipped, s.snapFail, s.decisions, s.handlerErrors))
      local order = {}
      for how in pairs(s.how) do order[#order + 1] = how end
      table.sort(order)
      local parts = {}
      for _, how in ipairs(order) do parts[#parts + 1] = how .. ' ' .. s.how[how] end
      say('decided (item quantity): ' .. (#parts > 0 and table.concat(parts, ', ') or 'none yet'))
      say(string.format('loot windows %d (skinning windows %d, without guid %d), loot slots %d, item-info events %d',
        s.windows, s.skinWindows, s.noGuid, s.lootSlots, s.itemInfoEvents))
      local an = {}
      for k, v in pairs(s.anomalies) do an[#an + 1] = k .. ' ' .. v end
      table.sort(an)
      if #an > 0 then say('ANOMALIES (not expected, please report as a bug): ' .. table.concat(an, ', ')) else say('anomalies: none') end
    else
      say('lots: no interval has run (use /gi collect on)')
    end
    if Ch then
      local l = Ch.lootStats
      say(string.format('item chat lines (evidence): seen %d, text %d, secret %d, self %d, other %d', l.seen, l.text, l.secret, l.self, l.other))
    end
  end

  GI.Commands.Register('lots', {
    help = 'item lots: status | last [n] | sales [n] | unknown | check | on | off | reset confirm | decisions [n] | iteminfo <id or link>',
    usage = 'lots [status|last [n]|sales [n]|unknown|check|on|off|reset confirm|decisions [n]|iteminfo <id|link>]',
    fn = function(args)
      local sub = args[1] or 'status'
      if sub == 'status' then lotsStatus()
      elseif sub == 'on' then
        lotsSwitch = true
        if GI.Sources.IsActive() and GI.ItemSources and not GI.ItemSources.IsActive() then
          GI.ItemSources.Begin()
          if GI.LotBook then GI.LotBook.Begin() end
        end
        say('lots: on' .. (GI.Sources.IsActive() and '' or ' (the interval starts with /gi collect on)'))
      elseif sub == 'off' then
        lotsSwitch = false
        if GI.LotBook then GI.LotBook.End() end
        if GI.ItemSources then GI.ItemSources.End() end
        say('lots: off (the cash ledger keeps running)')
      elseif sub == 'decisions' then
        local list = GI.ItemSources and GI.ItemSources.Recent(tonumber(args[2]) or 10) or {}
        if #list == 0 then say('lots: no decisions yet'); return end
        for _, r in ipairs(list) do
          local d = r.d
          say(string.format('%s item %d x%d -> %s%s (%s)', d.dir, d.itemID, d.qty, d.how, d.act and (' ' .. d.act) or '', d.reason))
        end
      elseif sub == 'iteminfo' then
        local arg = args[2]
        local id = arg and (tonumber(arg:match('item:(%d+)')) or tonumber(arg))
        if not id then say('usage: /gi lots iteminfo <itemID or item link>'); return end
        local info = P.ItemsModule.Get(id)
        local text
        if info.status == 'ready' then
          text = string.format('item %d "%s": quality %s, class %s/%s, sell price %s copper, bind type %s', id, tostring(info.name), tostring(info.quality),
            tostring(info.classID), tostring(info.subclassID), tostring(info.sellPrice), tostring(info.bindType))
        else
          text = string.format('item %d: data %s (a load was requested; ask again in a moment)', id, tostring(info.status))
        end
        say(text)
        if GI.Trace and GI.Trace.IsRunning() then GI.Trace.Line('ITEMINFO_CMD ' .. text) end
      elseif sub == 'last' or sub == 'unknown' or sub == 'check' or sub == 'sales' then
        local LB = GI.LotBook
        local lines = sub == 'last' and LB.Last(tonumber(args[2])) or sub == 'sales' and LB.Sales(tonumber(args[2])) or sub == 'unknown' and LB.Unknown() or LB.Check()
        for _, l in ipairs(lines) do say(l) end
      elseif sub == 'reset' then
        if args[2] ~= 'confirm' then
          say('lots reset deletes the stored lots of THIS character only (cash ledger and prices untouched). Type /gi lots reset confirm to do it.')
        else
          local ok, err = GI.LotBook.ResetCurrent()
          say(ok and 'lots reset: this character\'s lots were deleted' or ('lots reset: ' .. tostring(err)))
        end
      else
        say('usage: /gi lots [status|last [n]|sales [n]|unknown|check|on|off|reset confirm|decisions [n]|iteminfo <id|link>]')
      end
    end,
  })
end

--- Test helper.
function Ledger.Reset()
  lotsSwitch = true; switch = true; intervalStart = nil; mark = nil; last = { reason = 'not started' }
end
]=====] },
{ path = "Future/CommunityDataEngine.lua", src = [=====[
-- GoldIntel / Future / CommunityDataEngine.lua                          (PLACEHOLDER, Decisions D-015)
--
-- Architecture placeholder only. Nothing here is implemented, persisted or shown.
-- Every function returns { ok = false, err = 'NOT_IMPLEMENTED' }. Implementing it needs an
-- explicit user instruction and a new decision. Out of scope until after v1.

local ADDON, GI = ...
GI = GI or {}
local Core = GI.Core
assert(Core, 'Core/Core.lua must be loaded before Future/CommunityDataEngine.lua')

local function notImplemented() return { ok = false, err = 'NOT_IMPLEMENTED' } end

local Engine = Core.Module('CommunityDataEngine', { stub = true })
Engine.Import = notImplemented
Engine.Export = notImplemented
Engine.Merge = notImplemented
Engine.GuildSync = notImplemented
Engine.ChannelSync = notImplemented
]=====] },
{ path = "Future/RouteEngine.lua", src = [=====[
-- GoldIntel / Future / RouteEngine.lua                                  (PLACEHOLDER, Decisions D-015)
--
-- Architecture placeholder only. Nothing here is implemented, persisted or shown.
-- Every function returns { ok = false, err = 'NOT_IMPLEMENTED' }. Implementing it needs an
-- explicit user instruction and a new decision. Out of scope until after v1.

local ADDON, GI = ...
GI = GI or {}
local Core = GI.Core
assert(Core, 'Core/Core.lua must be loaded before Future/RouteEngine.lua')

local function notImplemented() return { ok = false, err = 'NOT_IMPLEMENTED' } end

local Engine = Core.Module('RouteEngine', { stub = true })
Engine.Record = notImplemented
Engine.Analyze = notImplemented
Engine.Discover = notImplemented
Engine.Rank = notImplemented
]=====] },
{ path = "Core/Boot.lua", src = [=====[
-- GoldIntel / Core / Boot.lua                                           (Phase 2)
--
-- The LAST file in the TOC. It schedules Core.Start for PLAYER_LOGIN (or runs it at once when
-- the addon was loaded after login), so every module and service is registered before
-- anything starts and Platform/Probe has already persisted its capability data.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
local Core = GI.Core
assert(P and Core, 'Platform and Core must be loaded before Core/Boot.lua')

-- /gi works from the moment the files load (minimal command set), so it is available even if
-- the login event were never delivered. Core.Start installs the full command set.
if GI.Commands then GI.Commands.Install(true) end

P.OnReady(function()
  Core.Start()
end)
]=====] },
}
