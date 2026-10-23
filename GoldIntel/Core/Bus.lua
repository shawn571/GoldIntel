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
