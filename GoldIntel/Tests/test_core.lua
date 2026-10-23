--[[
Tests / test_core.lua                                          (Phase 2: Core/Core.lua)

Module registry, dependency ordering, failure isolation, lifecycle, services, startup
bridges, minimal mode when the platform is not operational, and the Future placeholders.
]]

local T = require('testlib')
local Loader = require('loader')

--- Boots the full addon but does not log in (so modules can be registered first).
local function boot(fakeOpts)
  local W, P, ns = Loader.boot(fakeOpts or {})
  return W, P, ns, ns.Core
end

T.describe('Core.Module registration', function()
  T.it('returns the module table and starts in the registered state', function()
    local _, _, _, Core = boot()
    local def = { marker = true }
    local m = Core.Module('alpha', def)
    T.truthy(m == def)
    T.eq(Core.ModuleState('alpha'), 'registered')
    T.truthy(Core.GetModule('alpha') == def)
  end)

  T.it('creates a table when no definition is given', function()
    local _, _, _, Core = boot()
    T.eq(type(Core.Module('beta')), 'table')
  end)

  T.it('rejects duplicates, bad names and bad definitions', function()
    local _, _, _, Core = boot()
    Core.Module('alpha', {})
    T.isnil((Core.Module('alpha', {})))
    T.isnil((Core.Module('', {})))
    T.isnil((Core.Module(5, {})))
    T.isnil((Core.Module('x', 'not a table')))
    T.isnil((Core.Module('y', { deps = 'store' })))
  end)

  T.it('a module registered after startup is flagged and never started', function()
    local W, P, _, Core = boot()
    W:login()
    local started = false
    Core.Module('late', { OnEnable = function() started = true end })
    T.eq(Core.ModuleState('late'), 'registered')
    T.falsy(started)
    local warned = false
    for _, d in ipairs(P.GetDiag()) do
      if d.msg:find('registered after', 1, true) then warned = true end
    end
    T.truthy(warned)
  end)

  T.it('Modules lists registration order with states', function()
    local _, _, _, Core = boot()
    Core.Module('one', {}); Core.Module('two', {})
    local names = {}
    for _, m in ipairs(Core.Modules()) do names[#names + 1] = m.name end
    T.eq(names[#names - 1], 'one')
    T.eq(names[#names], 'two')
  end)
end)

T.describe('Core services', function()
  T.it('registers and retrieves services; rejects duplicates and nil', function()
    local _, _, _, Core = boot()
    local impl = { x = 1 }
    T.truthy(Core.Service('mine', impl) == impl)
    T.truthy(Core.GetService('mine') == impl)
    T.isnil((Core.Service('mine', {})))
    T.isnil((Core.Service('nothing', nil)))
    T.isnil((Core.Service('', {})))
  end)

  T.it('the infrastructure registered itself as services', function()
    local _, _, ns, Core = boot()
    for _, name in ipairs({ 'bus', 'capabilities', 'config', 'migrations', 'store', 'pruner', 'commands' }) do
      T.truthy(Core.GetService(name), name)
    end
    T.truthy(Core.GetService('store') == ns.Store)
  end)
end)

T.describe('Core lifecycle', function()
  T.it('initializes and enables in dependency order', function()
    local W, _, _, Core = boot()
    local log = {}
    local function mod(name, deps)
      Core.Module(name, {
        deps = deps,
        OnInitialize = function() log[#log + 1] = 'init:' .. name end,
        OnEnable = function() log[#log + 1] = 'enable:' .. name end,
      })
    end
    mod('a', { 'b' }); mod('b', { 'c' }); mod('c', nil)
    W:login()
    T.eq(log, { 'init:c', 'init:b', 'init:a', 'enable:c', 'enable:b', 'enable:a' })
    T.eq(Core.ModuleState('a'), 'enabled')
  end)

  T.it('hooks receive the module table', function()
    local W, _, _, Core = boot()
    local got
    local def = Core.Module('hooked', { OnEnable = function(self) got = self end })
    W:login()
    T.truthy(got == def)
  end)

  T.it('services satisfy dependencies; a missing dependency disables the module', function()
    local W, _, _, Core = boot()
    Core.Module('needs_store', { deps = { 'store' } })
    Core.Module('needs_ghost', { deps = { 'ghost' } })
    W:login()
    T.eq(Core.ModuleState('needs_store'), 'enabled')
    local state, reason = Core.ModuleState('needs_ghost')
    T.eq(state, 'disabled')
    T.truthy(reason:find('missing dependency ghost', 1, true))
  end)

  T.it('a failing OnInitialize fails the module, disables dependents, spares others', function()
    local W, _, _, Core = boot()
    local independentRan = false
    Core.Module('bad', { OnInitialize = function() error('init bug') end })
    Core.Module('child', { deps = { 'bad' } })
    Core.Module('free', { OnEnable = function() independentRan = true end })
    W:login()
    local state, reason = Core.ModuleState('bad')
    T.eq(state, 'failed')
    T.truthy(reason:find('init bug', 1, true))
    local childState, childReason = Core.ModuleState('child')
    T.eq(childState, 'disabled')
    T.truthy(childReason:find('bad is failed', 1, true))
    T.truthy(independentRan)
    T.eq(Core.ModuleState('free'), 'enabled')
  end)

  T.it('a failing OnEnable fails the module and disables its dependents', function()
    local W, _, _, Core = boot()
    Core.Module('bad', { OnEnable = function() error('enable bug') end })
    Core.Module('child', { deps = { 'bad' } })
    W:login()
    T.eq(Core.ModuleState('bad'), 'failed')
    T.eq(Core.ModuleState('child'), 'disabled')
  end)

  T.it('dependency cycles fail the cycle members and nothing else', function()
    local W, _, _, Core = boot()
    Core.Module('x', { deps = { 'y' } })
    Core.Module('y', { deps = { 'x' } })
    Core.Module('fine', {})
    W:login()
    local _, rx = Core.ModuleState('x')
    T.eq(Core.ModuleState('x'), 'failed')
    T.eq(Core.ModuleState('y'), 'failed')
    T.eq(rx, 'dependency cycle')
    T.eq(Core.ModuleState('fine'), 'enabled')
  end)

  T.it('self-dependency counts as a cycle', function()
    local W, _, _, Core = boot()
    Core.Module('loop', { deps = { 'loop' } })
    W:login()
    T.eq(Core.ModuleState('loop'), 'failed')
  end)

  T.it('state changes are announced on the bus', function()
    local W, _, ns, Core = boot()
    local seen = {}
    ns.Bus.On('MODULE_STATE', function(p) seen[#seen + 1] = p.name .. ':' .. p.state end)
    Core.Module('watched', {})
    W:login()
    T.eq(seen, { 'Context:initialized', 'CommunityDataEngine:initialized', 'RouteEngine:initialized',
                 'watched:initialized', 'Collector:initialized', 'Ledger:initialized',
                 'Context:enabled', 'CommunityDataEngine:enabled', 'RouteEngine:enabled',
                 'watched:enabled', 'Collector:enabled', 'Ledger:enabled' })
  end)

  T.it('Start runs once; a second call reports it', function()
    local W, _, _, Core = boot()
    W:login()
    T.eq(Core.state, 'ready')
    local ok, why = Core.Start()
    T.falsy(ok)
    T.truthy(why:find('already', 1, true))
  end)

  T.it('CORE_READY fires after the modules are enabled, with the module count', function()
    local W, _, ns, Core = boot()
    local payload, stateAtFire
    ns.Bus.On('CORE_READY', function(p) payload = p; stateAtFire = Core.ModuleState('CommunityDataEngine') end)
    W:login()
    T.eq(payload.modules, 5)
    T.eq(stateAtFire, 'enabled')
  end)

  T.it('Describe summarizes module states', function()
    local W, _, _, Core = boot()
    Core.Module('bad', { OnInitialize = function() error('x') end })
    W:login()
    local d = Core.Describe()
    T.eq(d.state, 'ready')
    T.eq(d.total, 6)
    T.eq(d.failed, 1)
    T.eq(d.enabled, 5)
    T.eq(d.stub, 2)
  end)
end)

T.describe('Core.Stop', function()
  T.it('logout calls OnLogout in reverse order, only for enabled modules', function()
    local W, _, _, Core = boot()
    local log = {}
    Core.Module('first', { OnLogout = function() log[#log + 1] = 'first' end })
    Core.Module('second', { deps = { 'first' }, OnLogout = function() log[#log + 1] = 'second' end })
    Core.Module('broken', { OnInitialize = function() error('x') end, OnLogout = function() log[#log + 1] = 'broken' end })
    W:login()
    T.truthy(Core.Stop('logout'))
    T.eq(log, { 'second', 'first' })
    T.eq(Core.state, 'stopped')
  end)

  T.it('other reasons call OnDisable and mark modules disabled', function()
    local W, _, _, Core = boot()
    local disabled = 0
    Core.Module('m', { OnDisable = function() disabled = disabled + 1 end })
    W:login()
    Core.Stop('test')
    T.eq(disabled, 1)
    T.eq(Core.ModuleState('m'), 'disabled')
  end)

  T.it('is idempotent and refuses before start', function()
    local W, _, _, Core = boot()
    T.falsy((Core.Stop('x')))
    W:login()
    T.truthy(Core.Stop('x'))
    T.falsy((Core.Stop('x')))
  end)

  T.it('the logout event stops Core; a missing logout event is not required for correctness', function()
    local W, _, ns, Core = boot()
    local stopping
    ns.Bus.On('CORE_STOPPING', function(p) stopping = p.reason end)
    W:login()
    W:fire('PLAYER_LOGOUT')
    T.eq(stopping, 'logout')
    T.eq(Core.state, 'stopped')
    -- without the event the addon simply keeps running and the client saves the live tables
    local W2, _, _, Core2 = boot()
    W2:login()
    T.eq(Core2.state, 'ready')
  end)

  T.it('stopping persists the capability snapshot and a checkpoint marker', function()
    local W, _, ns, Core = boot()
    W:login()
    ns.Store.Section('runtime').capabilities = nil
    Core.Stop('logout')
    T.truthy(ns.Store.Section('runtime').capabilities)
    T.truthy(ns.Store.Get().meta.lastCheckpoint)
  end)
end)

T.describe('Core bridges to the Platform', function()
  T.it('diagnostics are forwarded as DIAG events', function()
    local W, P, ns = boot()
    W:login()
    local seen = {}
    ns.Bus.On('DIAG', function(e) seen[#seen + 1] = e.msg end)
    P.Diag('warn', 'Test', 'bridge check')
    T.eq(seen, { 'bridge check' })
  end)

  T.it('a failing DIAG handler cannot cause a diagnostic loop', function()
    local W, P, ns = boot()
    W:login()
    local calls = 0
    ns.Bus.On('DIAG', function() calls = calls + 1; error('diag handler bug') end)
    P.Diag('warn', 'Test', 'trigger')
    T.truthy(calls <= 2, 'DIAG handler ran ' .. calls .. ' times')
  end)

  T.it('capability changes become COMPAT_CHANGED events', function()
    local W, P, ns = boot()
    W:login()
    local seen = {}
    ns.Bus.On('COMPAT_CHANGED', function(p) seen[#seen + 1] = p.cap .. '=' .. tostring(p.available) end)
    P.SetCap('test.capability', true)
    P.SetCap('test.capability', false)
    T.eq(seen, { 'test.capability=true', 'test.capability=false' })
  end)
end)

T.describe('Core in minimal mode (platform not operational)', function()
  T.it('does not start modules or open the store, and offers only the platform commands', function()
    local W, P, ns, Core = boot({ without = { 'GetMoney' } })
    local started = false
    Core.Module('m', { OnEnable = function() started = true end })
    W:login()
    T.falsy(P.IsOperational())
    T.eq(Core.state, 'platform-failed')
    T.falsy(started)
    T.falsy(ns.Store.IsOpen())
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('config list')
    T.truthy(W:printedText():find('unknown command "config"', 1, true))
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('status')
    T.truthy(W:printedText():find('operational=false', 1, true))
  end)
end)

T.describe('Future placeholders (Decisions D-015)', function()
  T.it('are registered as enabled stub modules', function()
    local W, _, _, Core = boot()
    W:login()
    for _, name in ipairs({ 'CommunityDataEngine', 'RouteEngine' }) do
      T.eq(Core.ModuleState(name), 'enabled')
    end
    local stubs = 0
    for _, m in ipairs(Core.Modules()) do if m.stub then stubs = stubs + 1 end end
    T.eq(stubs, 2)
  end)

  T.it('every function returns NOT_IMPLEMENTED and persists nothing', function()
    local W, _, ns, Core = boot()
    W:login()
    local before = ns.Store.EstimateBytes(ns.Store.Get())
    local community = Core.GetModule('CommunityDataEngine')
    for _, fn in ipairs({ 'Import', 'Export', 'Merge', 'GuildSync', 'ChannelSync' }) do
      T.eq(community[fn](), { ok = false, err = 'NOT_IMPLEMENTED' }, fn)
    end
    local route = Core.GetModule('RouteEngine')
    for _, fn in ipairs({ 'Record', 'Analyze', 'Discover', 'Rank' }) do
      T.eq(route[fn](), { ok = false, err = 'NOT_IMPLEMENTED' }, fn)
    end
    T.eq(ns.Store.EstimateBytes(ns.Store.Get()), before)
  end)
end)
