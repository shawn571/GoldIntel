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
