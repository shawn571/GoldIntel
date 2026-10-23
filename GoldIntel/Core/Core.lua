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
