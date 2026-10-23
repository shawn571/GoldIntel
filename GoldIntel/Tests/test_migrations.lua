--[[
Tests / test_migrations.lua                                (Phase 2: Store/Migrations.lua)
]]

local T = require('testlib')
local Loader = require('loader')

local FILES = { 'Platform/Platform.lua', 'Platform/Clock.lua', 'Core/Core.lua', 'Store/Migrations.lua' }
local function boot()
  local _, P, ns = Loader.boot({}, { only = FILES })
  return P, ns.Migrations
end

T.describe('Migrations registry', function()
  T.it('the built-in chain ends at schema 2 (D-014, D-077)', function()
    local _, M = boot()
    T.eq(M.Latest(), 2)
    local plan = M.Plan(0, 2)
    T.eq(#plan, 2)
  end)

  T.it('registering the next step moves the target; gaps do not count', function()
    local _, M = boot()
    T.truthy(M.Register(2, function() end))
    T.eq(M.Latest(), 3)
    T.truthy(M.Register(4, function() end))
    T.eq(M.Latest(), 3, 'step 3 is missing, so the contiguous chain still ends at 3')
    local plan, err = M.Plan(0, 5)
    T.isnil(plan)
    T.truthy(err:find('no migration from schema 3', 1, true))
  end)

  T.it('Register validates its arguments and rejects duplicates', function()
    local _, M = boot()
    T.isnil((M.Register(-1, function() end)))
    T.isnil((M.Register(1.5, function() end)))
    T.isnil((M.Register('1', function() end)))
    T.isnil((M.Register(1, 'fn')))
    T.isnil((M.Register(0, function() end)))
  end)

  T.it('Plan refuses to go backwards and validates numbers', function()
    local _, M = boot()
    T.isnil((M.Plan(2, 1)))
    T.isnil((M.Plan('a', 1)))
    T.eq(M.Plan(1, 1), {})
  end)

  T.it('Reset empties the registry', function()
    local _, M = boot()
    M.Reset()
    T.eq(M.Latest(), 0)
  end)
end)

T.describe('Migrations.Run', function()
  T.it('applies each step in order and stamps the schema after each', function()
    local _, M = boot()
    M.Remove(1)                       -- pin the old chain: this test is about the runner, not the built-in steps
    local log = {}
    M.Register(1, function(db) log[#log + 1] = 'v1:' .. tostring(db.schema); db.addedInV2 = true end, 'second')
    M.Register(2, function(db) log[#log + 1] = 'v2:' .. tostring(db.schema) end, 'third')
    local db = { schema = 0 }
    local r = M.Run(db, 0, 3)
    T.truthy(r.ok)
    T.eq(r.applied, { 'adopt Phase 1 database into schema 1', 'second', 'third' })
    T.eq(log, { 'v1:1', 'v2:2' })
    T.eq(db.schema, 3)
    T.truthy(db.addedInV2)
  end)

  T.it('a failing step stops the chain and reports where', function()
    local _, M = boot()
    M.Remove(1)
    M.Register(1, function() error('step bug') end)
    M.Register(2, function() error('never runs') end)
    local db = {}
    local r = M.Run(db, 0, 3)
    T.falsy(r.ok)
    T.eq(r.failedAt, 1)
    T.truthy(r.err:find('step bug', 1, true))
    T.eq(db.schema, 1, 'steps before the failure were applied to the copy')
  end)

  T.it('a missing step is reported without running anything', function()
    local _, M = boot()
    local db = {}
    local r = M.Run(db, 0, 5)
    T.falsy(r.ok)
    T.truthy(r.err:find('no migration', 1, true))
    T.isnil(db.schema)
  end)

  T.it('the adopt step preserves unknown keys and the compat table', function()
    local _, M = boot()
    local compat = { build = '70338' }
    local db = { compat = compat, mystery = { 1, 2, 3 } }
    M.Run(db, 0, 1)
    T.truthy(db.compat == compat)
    T.eq(db.mystery, { 1, 2, 3 })
    T.eq(db.schema, 1)
    T.eq(type(db.sessions), 'table')
  end)
end)

T.describe('Database shape', function()
  T.it('Sections returns fresh tables every call, with the Contracts F5 nesting', function()
    local _, M = boot()
    local a, b = M.Sections(), M.Sections()
    T.truthy(a.sessions ~= b.sessions)
    T.truthy(a.lots.open and a.lots.closedSummary)
    T.truthy(a.agg.zone and a.agg.sub and a.agg.act and a.agg.bracket)
    T.truthy(a.prices.snapshots)
    for _, name in ipairs({ 'meta', 'profile', 'chars', 'sessions', 'segments', 'heat', 'auctions', 'runtime' }) do
      T.eq(type(a[name]), 'table', name)
    end
    T.isnil(a.compat)
    T.isnil(a.schema)
  end)

  T.it('Check lists missing and wrong-typed sections without changing anything', function()
    local _, M = boot()
    local db = { sessions = 'oops', lots = { open = {}, closedSummary = 5 } }
    local problems = M.Check(db)
    T.truthy(#problems.missing > 5)
    T.eq(problems.wrongType, { 'lots.closedSummary', 'sessions' })
    T.eq(db.sessions, 'oops')
  end)

  T.it('EnsureShape adds, repairs and preserves', function()
    local _, M = boot()
    local keep = { id1 = { t0 = 1 } }
    local db = { sessions = keep, segments = 'oops', lots = { open = { x = 1 } }, unknownKey = 'stay' }
    local r = M.EnsureShape(db)
    T.truthy(db.sessions == keep)
    T.eq(db.segments, {})
    T.eq(db.lots.open, { x = 1 })
    T.eq(db.lots.closedSummary, {})
    T.eq(db.unknownKey, 'stay')
    T.eq(r.repaired, { 'segments' })
    T.truthy(#r.added > 0)
    T.eq(#M.Check(db).missing + #M.Check(db).wrongType, 0)
  end)

  T.it('DefineSection lets later phases add sections that Check and EnsureShape then honor', function()
    local _, M = boot()
    T.truthy(M.DefineSection('routes', function() return { list = {} } end, { 'list' }))
    T.isnil((M.DefineSection('routes', function() return {} end)))
    T.isnil((M.DefineSection('compat', function() return {} end)))
    T.isnil((M.DefineSection('schema', function() return {} end)))
    T.isnil((M.DefineSection('x', 'factory')))
    local db = {}
    M.EnsureShape(db)
    T.eq(db.routes, { list = {} })
    T.eq(M.Sections().routes, { list = {} })
  end)
end)
