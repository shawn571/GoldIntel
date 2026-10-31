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

P.VERSION = '0.5.1-passive'
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
