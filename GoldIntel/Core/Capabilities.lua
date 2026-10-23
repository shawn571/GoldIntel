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
