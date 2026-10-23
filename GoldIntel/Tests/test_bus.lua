--[[
Tests / test_bus.lua                                           (Phase 2: Core/Bus.lua)
]]

local T = require('testlib')
local Loader = require('loader')

local FILES = { 'Platform/Platform.lua', 'Platform/Clock.lua', 'Core/Core.lua', 'Core/Bus.lua' }
local function boot()
  local W, P, ns = Loader.boot({}, { only = FILES })
  return W, P, ns.Bus, ns
end

T.describe('Bus declarations', function()
  T.it('declares the Contracts F3 events and the Phase 2 events', function()
    local _, _, Bus = boot()
    for _, name in ipairs({ 'DIAG', 'COMPAT_CHANGED', 'CAPABILITY_STAGE_CHANGED', 'CORE_READY', 'CORE_STOPPING',
                            'MODULE_STATE', 'STORE_OPENED', 'STORE_MIGRATED', 'STORE_DEGRADED', 'CONFIG_CHANGED' }) do
      T.truthy(Bus.Info(name), name .. ' must be declared')
      T.falsy(Bus.Info(name).reserved, name .. ' is active in Phase 2')
    end
  end)

  T.it('keeps the four money pipeline stages as separate reserved events (D-035)', function()
    local _, _, Bus = boot()
    for _, name in ipairs({ 'BALANCE_OBSERVED', 'TRANSACTION_DETECTED', 'ATTRIBUTION_ASSIGNED', 'RECONCILIATION_COMPLETE' }) do
      T.truthy(Bus.Info(name), name)
      T.truthy(Bus.Info(name).reserved, name .. ' is reserved for Phase 3')
    end
  end)

  T.it('reserves the later-phase events from Contracts F3', function()
    local _, _, Bus = boot()
    for _, name in ipairs({ 'LEDGER_CASH', 'LEDGER_LOT', 'ACTIVITY_CHANGED', 'SEGMENT_OPENED', 'SEGMENT_CLOSED',
                            'SESSION_STARTED', 'SESSION_STOPPED', 'PRICES_UPDATED', 'HEAT_UPDATED' }) do
      T.truthy(Bus.Info(name) and Bus.Info(name).reserved, name)
    end
  end)

  T.it('Define adds events, rejects duplicates and malformed specs', function()
    local _, _, Bus = boot()
    T.truthy(Bus.Define('MY_EVENT', { a = 'number', b = 'string?' }))
    T.isnil((Bus.Define('MY_EVENT', {})))
    T.isnil((Bus.Define('', {})))
    T.isnil((Bus.Define('BAD', 'x')))
    T.isnil((Bus.Define('BAD2', { a = 'number!' })))
    T.isnil((Bus.Define('BAD3', { a = 5 })))
  end)

  T.it('Names is sorted and includes defined events', function()
    local _, _, Bus = boot()
    Bus.Define('ZZZ_EVENT', {})
    local names = Bus.Names()
    for i = 2, #names do T.truthy(names[i - 1] <= names[i]) end
    local found = false
    for _, n in ipairs(names) do if n == 'ZZZ_EVENT' then found = true end end
    T.truthy(found)
  end)

  T.it('is registered as the bus service', function()
    local _, _, Bus, ns = boot()
    T.truthy(ns.Core.GetService('bus') == Bus)
  end)
end)

T.describe('Bus delivery', function()
  T.it('delivers to handlers in order and returns the count', function()
    local _, _, Bus = boot()
    local seen = {}
    Bus.On('CORE_READY', function(p) seen[#seen + 1] = 'a' .. p.modules end)
    Bus.On('CORE_READY', function(p) seen[#seen + 1] = 'b' .. p.modules end)
    T.eq(Bus.Fire('CORE_READY', { modules = 3 }), 2)
    T.eq(seen, { 'a3', 'b3' })
  end)

  T.it('rejects unknown events and non-function handlers; idempotent subscription', function()
    local _, _, Bus = boot()
    T.isnil((Bus.On('NOPE', function() end)))
    T.isnil((Bus.On('CORE_READY', 'x')))
    local n = 0
    local fn = function() n = n + 1 end
    Bus.On('CORE_READY', fn); Bus.On('CORE_READY', fn)
    Bus.Fire('CORE_READY', { modules = 0 })
    T.eq(n, 1)
  end)

  T.it('firing an undeclared event is an error that returns 0', function()
    local _, P, Bus = boot()
    T.eq(Bus.Fire('TYPO_EVENT', {}), 0)
    T.eq(P.GetDiag()[1].level, 'error')
  end)

  T.it('a failing handler is reported and the next handler still runs', function()
    local _, P, Bus = boot()
    local ran = false
    Bus.On('CORE_READY', function() error('handler bug') end)
    Bus.On('CORE_READY', function() ran = true end)
    T.eq(Bus.Fire('CORE_READY', { modules = 1 }), 2)
    T.truthy(ran)
    T.truthy(P.GetDiag()[1].msg:find('handler bug', 1, true))
  end)

  T.it('handlers removed or added during delivery are handled safely', function()
    local _, _, Bus = boot()
    local calls = {}
    local second
    local first = function() calls[#calls + 1] = 'first'; Bus.Off('CORE_READY', second) end
    second = function() calls[#calls + 1] = 'second' end
    local third = function() calls[#calls + 1] = 'third' end
    Bus.On('CORE_READY', first); Bus.On('CORE_READY', second); Bus.On('CORE_READY', third)
    Bus.Fire('CORE_READY', { modules = 0 })
    T.eq(calls, { 'first', 'third' })
    T.eq(Bus.HandlerCount('CORE_READY'), 2)
    local late = function() calls[#calls + 1] = 'late' end
    Bus.On('CORE_STOPPING', function() Bus.On('CORE_STOPPING', late) end)
    calls = {}
    Bus.Fire('CORE_STOPPING', { reason = 'x' })
    T.eq(calls, {})
    Bus.Fire('CORE_STOPPING', { reason = 'x' })
    T.eq(calls, { 'late' })
  end)

  T.it('Off reports whether a handler existed', function()
    local _, _, Bus = boot()
    local fn = function() end
    Bus.On('CORE_READY', fn)
    T.truthy(Bus.Off('CORE_READY', fn))
    T.falsy(Bus.Off('CORE_READY', fn))
    T.falsy(Bus.Off('NEVER', fn))
  end)

  T.it('a nil payload becomes an empty table', function()
    local _, _, Bus = boot()
    local got
    Bus.Define('PLAIN_EVENT', {})
    Bus.On('PLAIN_EVENT', function(p) got = p end)
    Bus.Fire('PLAIN_EVENT')
    T.eq(got, {})
  end)
end)

T.describe('Bus payload validation', function()
  T.it('lenient mode reports a bad payload but delivers; strict mode drops it', function()
    local _, P, Bus = boot()
    local n = 0
    Bus.On('CORE_READY', function() n = n + 1 end)
    Bus.validate = true
    Bus.Fire('CORE_READY', { modules = 'many' })
    T.eq(n, 1)
    T.eq(P.GetDiag()[1].level, 'error')
    Bus.validate = 'strict'
    Bus.Fire('CORE_READY', { modules = 'many' })
    T.eq(n, 1)
  end)

  T.it('accepts valid payloads including optional fields and the any type', function()
    local _, P, Bus = boot()
    Bus.validate = 'strict'
    local n = 0
    Bus.On('CONFIG_CHANGED', function() n = n + 1 end)
    Bus.On('MODULE_STATE', function() n = n + 1 end)
    Bus.Fire('CONFIG_CHANGED', { key = 'a', value = 5, source = 'api' })
    Bus.Fire('CONFIG_CHANGED', { key = 'a', value = 'text', previous = false, source = 'api' })
    Bus.Fire('MODULE_STATE', { name = 'x', state = 'enabled' })
    T.eq(n, 3)
    T.eq(P.DiagCount(), 0)
  end)

  T.it('a missing required field is rejected', function()
    local _, P, Bus = boot()
    Bus.validate = 'strict'
    T.eq(Bus.Fire('STORE_OPENED', { state = 'ok' }), 0)
    T.truthy(P.GetDiag()[1].msg:find('missing field', 1, true))
  end)
end)
