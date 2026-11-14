--[[
Tests / test_store.lua                                         (Phase 2: Store/Store.lua)

The persistence layer: fresh install, upgrading the REAL Phase 1 database captured from the
WoW Forever client, the compat guarantee, read-only and degraded modes, atomic migrations,
meta data, the per-character table, size estimates.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local Loader = require('loader')
local sim = require('svsim')

local function fixture()
  return sim.loadFixture(Loader.root .. '/Tests/fixtures/forever_1.60.1_GoldIntelDB.lua', 'GoldIntelDB')
end

--- Boots the full addon over a given saved database WITHOUT logging in, so Probe has not run
-- and nothing has touched compat. The test calls ns.Store.Open() itself.
local function bootWith(db, charDb, fakeOpts, subset)
  local W = Fake.new(fakeOpts)
  W.env.GoldIntelDB = db
  W.env.GoldIntelCharDB = charDb
  local P, ns = Loader.load(W.env, subset and { only = subset } or nil)
  return W, P, ns, ns.Store
end

local function copy(t) return require('svsim').parse(sim.dump(t)) end

T.describe('Store: fresh install', function()
  T.it('builds a schema-2 database in the live table; never creates compat', function()
    local W, _, _, Store = bootWith(nil, nil)
    local st = Store.Open()
    T.eq(st.state, 'created')
    T.eq(st.schema, 2)
    T.truthy(st.writable)
    local live = W.env.GoldIntelDB
    T.eq(live.schema, 2)
    T.truthy(Store.Get() == live)
    T.eq(type(live.sessions), 'table')
    T.eq(type(live.lots.open), 'table')
    T.isnil(live.compat)
    T.eq(live.meta.opens, 1)
    T.truthy(live.meta.firstSeen)
  end)

  T.it('an existing but empty table is also treated as fresh', function()
    local W, _, _, Store = bootWith({})
    T.eq(Store.Open().state, 'created')
    T.eq(W.env.GoldIntelDB.schema, 2)
  end)

  T.it('Open is idempotent: the second call changes nothing', function()
    local W, _, _, Store = bootWith(nil)
    local first = Store.Open()
    local second = Store.Open()
    T.eq(first.state, second.state)
    T.eq(W.env.GoldIntelDB.meta.opens, 1)
  end)

  T.it('announces STORE_OPENED with state, schema and writability', function()
    local Fake2 = Fake.new()
    local P, ns = Loader.load(Fake2.env)
    local seen
    ns.Bus.On('STORE_OPENED', function(p) seen = p end)
    ns.Store.Open()
    T.eq(seen, { state = 'created', schema = 2, writable = true })
  end)
end)

T.describe('Store: upgrading the real Phase 1 database (the compat guarantee)', function()
  T.it('migrates schema 0 to 2 and leaves compat byte-for-byte untouched', function()
    local db = fixture()
    local compatRef = db.compat
    local compatBefore = require('svsim').parse(sim.dump(db.compat))
    local W, _, ns, Store = bootWith(db)
    local migrated
    ns.Bus.On('STORE_MIGRATED', function(p) migrated = p end)
    local st = Store.Open()
    T.eq(st.state, 'migrated')
    T.eq(st.schema, 2)
    T.eq(migrated, { from = 0, to = 2 })
    T.truthy(W.env.GoldIntelDB.compat == compatRef, 'compat keeps its identity')
    T.eq(W.env.GoldIntelDB.compat, compatBefore, 'compat content is unchanged')
    T.eq(db.schema, 2)
    T.eq(type(db.sessions), 'table')
    T.eq(db.meta.lastBuild, '70338')
    T.eq(db.meta.schemaHistory[1].from, 0)
    T.eq(db.meta.schemaHistory[1].to, 2)
    T.eq(db.meta.opens, 1)
  end)

  T.it('unknown top-level keys and unknown sections survive the migration', function()
    local db = fixture()
    db.mystery = { 1, 2, { deep = true } }
    local _, _, _, Store = bootWith(db)
    Store.Open()
    T.eq(db.mystery, { 1, 2, { deep = true } })
  end)

  T.it('the table the client gave us is the table that gets upgraded (identity kept)', function()
    local db = fixture()
    local W, _, _, Store = bootWith(db)
    Store.Open()
    T.truthy(W.env.GoldIntelDB == db)
    T.truthy(Store.Get() == db)
  end)

  T.it('a database holding only compat (the Phase 1 shape) upgrades the same way', function()
    local db = { compat = { build = '70338', caps = { frame = true } } }
    local ref = db.compat
    local _, _, _, Store = bootWith(db)
    T.eq(Store.Open().state, 'migrated')
    T.truthy(db.compat == ref)
  end)

  T.it('a non-numeric schema field is treated as schema 0 and adopted', function()
    local db = { schema = 'one', compat = { build = '1' } }
    local _, _, _, Store = bootWith(db)
    T.eq(Store.Open().state, 'migrated')
    T.eq(db.schema, 2)
  end)

  T.it('the next session finds schema 2 and does not migrate again', function()
    local db = fixture()
    local _, _, _, Store = bootWith(db)
    Store.Open()
    local saved = sim.parse(sim.dump(db))          -- logout, then login
    local _, _, ns2, Store2 = bootWith(saved)
    local migrations = 0
    ns2.Bus.On('STORE_MIGRATED', function() migrations = migrations + 1 end)
    local st = Store2.Open()
    T.eq(st.state, 'ok')
    T.eq(migrations, 0)
    T.eq(saved.meta.opens, 2)
    T.eq(#saved.meta.schemaHistory, 1)
  end)

  T.it('compat is preserved after a FULL addon session too (probe rewrites it, Store never does)', function()
    local db = fixture()
    local W, _, ns = bootWith(db)
    W:login()
    T.eq(db.schema, 2)
    T.eq(db.compat.build, '61000', 'Probe refreshed compat for the (fake) client: that is Probe, not Store')
    T.eq(ns.Store.Status().state, 'migrated')
    T.truthy(db.meta.schemaHistory[1])
  end)
end)

T.describe('Store: validation of a current-schema database', function()
  T.it('repairs wrong-typed sections, keeps everything valid, reports and warns', function()
    local keep = { s1 = { t0 = 5 } }
    local compat = { build = 'x' }
    local db = { schema = 2, compat = compat, sessions = keep, segments = 'oops', lots = 5, extra = 'stay' }
    local _, P, _, Store = bootWith(db)
    local st = Store.Open()
    T.eq(st.state, 'ok')
    T.eq(st.repaired, { 'lots', 'segments' })
    T.truthy(db.sessions == keep)
    T.truthy(db.compat == compat)
    T.eq(db.extra, 'stay')
    T.eq(db.segments, {})
    local warned = false
    for _, d in ipairs(P.GetDiag()) do
      if d.level == 'warn' and d.msg:find('repaired wrong-typed sections', 1, true) then warned = true end
    end
    T.truthy(warned)
  end)

  T.it('adds missing nested tables without touching existing ones', function()
    local db = { schema = 2, lots = { open = { a = 1 } }, agg = {} }
    local _, _, _, Store = bootWith(db)
    local st = Store.Open()
    T.eq(db.lots.open, { a = 1 })
    T.eq(db.lots.closedSummary, {})
    T.eq(db.agg.zone, {})
    T.truthy(#st.added > 0)
  end)
end)

T.describe('Store: read-only mode (newer saved data)', function()
  T.it('leaves the saved database untouched and works on a private copy', function()
    local db = { schema = 99, compat = { build = '1' }, sessions = { x = { t0 = 1 } }, futureThing = { y = 2 } }
    local snapshot = copy(db)
    local W, _, ns, Store = bootWith(db)
    local migrated = false
    ns.Bus.On('STORE_MIGRATED', function() migrated = true end)
    local st = Store.Open()
    T.eq(st.state, 'readonly')
    T.falsy(st.writable)
    T.falsy(Store.IsWritable())
    T.truthy(st.reason:find('newer than this addon', 1, true))
    T.truthy(Store.Get() ~= db)
    Store.Get().sessions.x.t0 = 999
    Store.Section('profile').changed = true
    Store.Checkpoint()
    T.eq(db, snapshot, 'the saved data is byte-for-byte unchanged')
    T.falsy(migrated)
    T.eq(W.env.GoldIntelDB.schema, 99)
  end)

  T.it('a read-only open does not update meta (no open count, no history)', function()
    local db = { schema = 99, meta = { opens = 4 } }
    local _, _, _, Store = bootWith(db)
    Store.Open()
    T.eq(db.meta.opens, 4)
  end)
end)

T.describe('Store: degraded mode (migration failed)', function()
  T.it('a failing migration step leaves the saved data untouched and runs in memory', function()
    local db = { schema = 1, compat = { build = '1' }, sessions = { a = { t0 = 1 } } }
    local snapshot = copy(db)
    local W, _, ns, Store = bootWith(db)
    ns.Migrations.Remove(1)
    ns.Migrations.Register(1, function() error('boom') end, 'broken step')
    local degraded
    ns.Bus.On('STORE_DEGRADED', function(p) degraded = p end)
    local st = Store.Open()
    T.eq(st.state, 'degraded')
    T.falsy(st.writable)
    T.truthy(degraded.reason:find('boom', 1, true))
    T.eq(db, snapshot, 'saved data untouched')
    local working = Store.Get()
    T.truthy(working ~= db)
    T.eq(type(working.sessions), 'table')
    T.eq(working.compat, snapshot.compat, 'compat is copied for reading')
    T.truthy(W:printedText():find('left untouched', 1, true) == nil and W:printedText():find('untouched', 1, true))
  end)

  T.it('a migration that alters compat is rejected', function()
    local db = { schema = 1, compat = { build = 'original' } }
    local _, _, ns, Store = bootWith(db)
    ns.Migrations.Remove(1)
    ns.Migrations.Register(1, function(d) d.compat.build = 'tampered' end)
    local st = Store.Open()
    T.eq(st.state, 'degraded')
    T.truthy(st.reason:find('compat', 1, true))
    T.eq(db.compat.build, 'original')
    T.eq(db.schema, 1)
  end)

  T.it('migrations are atomic: a failure late in the chain leaves no early changes behind', function()
    local db = { schema = 1, compat = { build = '1' } }
    local snapshot = copy(db)
    local _, _, ns, Store = bootWith(db)
    ns.Migrations.Remove(1)
    ns.Migrations.Register(1, function(d) d.addedByStepOne = true end)
    ns.Migrations.Register(2, function() error('late failure') end)
    T.eq(Store.Open().state, 'degraded')
    T.eq(db, snapshot)
    T.isnil(db.addedByStepOne)
  end)

  T.it('SavedVariables unavailable: runs in memory, not writable', function()
    local W, _, _, Store = bootWith(nil, nil, nil,
      { 'Platform/Platform.lua', 'Platform/Clock.lua', 'Core/Core.lua', 'Store/Migrations.lua', 'Store/Store.lua' })
    local st = Store.Open()
    T.eq(st.state, 'degraded')
    T.truthy(st.reason:find('SavedVariables', 1, true))
    T.falsy(Store.IsWritable())
    T.eq(type(Store.Get().sessions), 'table')
    T.isnil(W.env.GoldIntelDB)
  end)
end)

T.describe('Store: successful multi-step migrations', function()
  T.it('applies the chain, keeps compat identity, unknown data and table identity, records history', function()
    local compat = { build = 'b' }
    local sessions = { a = { t0 = 1 } }
    local db = { schema = 1, compat = compat, sessions = sessions, unknown = 'stay' }
    local W, _, ns, Store = bootWith(db)
    ns.Migrations.Remove(1)
    ns.Migrations.Register(1, function(d) d.v2field = 7 end, 'to v2')
    ns.Migrations.Register(2, function(d) d.v2field = d.v2field + 1; d.sessions.a.migrated = true end, 'to v3')
    local st = Store.Open()
    T.eq(st.state, 'migrated')
    T.eq(st.schema, 3)
    T.eq(db.schema, 3)
    T.eq(db.v2field, 8)
    T.truthy(db.compat == compat)
    T.truthy(W.env.GoldIntelDB == db)
    T.eq(db.sessions.a, { t0 = 1, migrated = true })
    T.eq(db.unknown, 'stay')
    T.eq(db.meta.schemaHistory[1].from, 1)
    T.eq(db.meta.schemaHistory[1].to, 3)
    T.eq(st.migrated.applied, { 'to v2', 'to v3' })
  end)

  T.it('the schema history is capped', function()
    local db = { schema = 1, meta = { schemaHistory = {} } }
    for i = 1, 30 do db.meta.schemaHistory[i] = { from = i, to = i + 1 } end
    local _, _, ns, Store = bootWith(db)
    ns.Migrations.Remove(1)
    ns.Migrations.Register(1, function() end)
    Store.Open()
    T.eq(#db.meta.schemaHistory, Store.HISTORY_LIMIT)
    T.eq(db.meta.schemaHistory[Store.HISTORY_LIMIT].to, 2)
  end)
end)

T.describe('Store: meta, sections and access', function()
  T.it('meta keeps firstSeen, counts opens, records version and last build', function()
    local db = { compat = { build = '70338' } }
    local _, _, _, Store = bootWith(db)
    Store.Open()
    local first = db.meta.firstSeen
    local saved = sim.parse(sim.dump(db))
    local W2, _, _, Store2 = bootWith(saved)
    W2.state.time = W2.state.time + 1000
    Store2.Open()
    T.eq(saved.meta.firstSeen, first)
    T.eq(saved.meta.opens, 2)
    T.truthy(saved.meta.lastOpened >= first)
    T.eq(saved.meta.addonVersion, '0.5.6-passive')
    T.eq(saved.meta.lastBuild, '70338')
  end)

  T.it('Section returns the table, creates missing ones, rejects reserved or invalid names', function()
    local _, _, _, Store = bootWith(nil)
    Store.Open()
    T.eq(type(Store.Section('profile')), 'table')
    local fresh = Store.Section('brandnew')
    T.eq(fresh, {})
    fresh.x = 1
    T.eq(Store.Section('brandnew').x, 1)
    T.isnil(Store.Section('schema'))
    T.isnil(Store.Section('compat'))
    T.isnil(Store.Section(''))
    T.isnil(Store.Section(5))
  end)

  T.it('Get opens the store lazily', function()
    local _, _, _, Store = bootWith(nil)
    T.falsy(Store.IsOpen())
    T.eq(type(Store.Get()), 'table')
    T.truthy(Store.IsOpen())
  end)

  T.it('Status returns copies', function()
    local _, _, _, Store = bootWith(nil)
    Store.Open()
    local s = Store.Status()
    s.state = 'hacked'
    s.repaired[1] = 'x'
    T.eq(Store.Status().state, 'created')
    T.eq(#Store.Status().repaired, 0)
  end)
end)

T.describe('Store: per-character table', function()
  T.it('creates the defaults and is stable across calls', function()
    local W, _, _, Store = bootWith(nil, nil)
    local c = Store.Char()
    T.eq(c.schema, 2)
    T.eq(c.pending, {})
    T.truthy(Store.Char() == c)
    T.truthy(W.env.GoldIntelCharDB == c)
  end)

  T.it('keeps existing character data and repairs a broken pending table', function()
    local charDb = { schema = 1, activeSessionID = 12, lastMoney = 5000, pending = 'oops' }
    local _, _, _, Store = bootWith(nil, charDb)
    local c = Store.Char()
    T.eq(c.activeSessionID, 12)
    T.eq(c.lastMoney, 5000)
    T.eq(c.pending, {})
  end)

  T.it('a corrupt non-table value is replaced', function()
    local W, _, _, Store = bootWith(nil, 'junk')
    T.eq(type(Store.Char()), 'table')
    T.eq(type(W.env.GoldIntelCharDB), 'table')
  end)

  T.it('newer character data is used as a private copy and left untouched', function()
    local charDb = { schema = 5, activeSessionID = 3 }
    local snapshot = copy(charDb)
    local _, _, _, Store = bootWith(nil, charDb)
    local c = Store.Char()
    c.activeSessionID = 99
    T.truthy(c ~= charDb)
    T.eq(charDb, snapshot)
  end)
end)

T.describe('Store: size estimates and checkpoint', function()
  T.it('EstimateBytes grows with content and counts strings by length', function()
    local _, _, _, Store = bootWith(nil)
    local small = Store.EstimateBytes({ a = 1 })
    local big = Store.EstimateBytes({ a = 1, b = string.rep('x', 1000), c = { 1, 2, 3, 4, 5 } })
    T.truthy(big > small + 1000)
    T.truthy(Store.EstimateBytes('hello') > Store.EstimateBytes(''))
    T.eq(Store.EstimateBytes(nil), 0)
  end)

  T.it('EstimateBytes is cycle-safe and honors the node limit', function()
    local _, _, _, Store = bootWith(nil)
    local a = {}
    a.self = a
    local bytes, truncated = Store.EstimateBytes(a)
    T.truthy(bytes > 0)
    T.falsy(truncated)
    local wide = {}
    for i = 1, 500 do wide[i] = { i } end
    local _, cut = Store.EstimateBytes(wide, 50)
    T.truthy(cut)
  end)

  T.it('Checkpoint reports size and writability and stamps meta when writable', function()
    local db = {}
    local _, _, _, Store = bootWith(db)
    Store.Open()
    local r = Store.Checkpoint()
    T.truthy(r.bytes > 100)
    T.truthy(r.writable)
    T.truthy(r.note:find('logout', 1, true))
    T.truthy(db.meta.lastCheckpoint)
  end)

  T.it('the whole database stays plain, serializable data (no functions, no cycles)', function()
    local db = fixture()
    local W, _, ns = bootWith(db)
    W:login()
    W.state.money = 500; W:fire('PLAYER_MONEY')
    ns.Config.Set('idleSec', 300)
    ns.Capabilities.Persist()
    ns.Core.Stop('logout')
    local text = sim.dump(W.env.GoldIntelDB)
    local back = sim.parse(text)
    T.eq(back.profile.idleSec, 300)
    T.eq(back.runtime.capabilities['event.PLAYER_MONEY'].level, 'payloadUsable')
    sim.dump(W.env.GoldIntelCharDB)
  end)
end)
