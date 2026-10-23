--[[
Tests / test_schema2.lua                        (Phase 3b-2 M3: schema 1 -> 2 migration, backup, rollback)

Inputs are REAL files: the user's GoldIntelDB / GoldIntelCharDB written by addon 0.3.1 in the WoW Forever client
(E-43, E-44, E-45; fixtures/migration/MANIFEST.md) and the Phase 1 database (schema 0). The rollback tests load the
Store of the released 0.3.1 package (fixtures/rollback) to show what going back does to schema 2 data.
A missing fixture FAILS the suite.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local Loader = require('loader')
local sim = require('svsim')

local FX = Loader.root .. '/Tests/fixtures/'
local ACCOUNT = { 'E-43_GoldIntelDB_round2_schema1.lua', 'E-45_GoldIntelDB_round3_schema1.lua' }
local CHAR = { 'E-44_GoldIntelCharDB_schema1.lua', 'E-45_GoldIntelCharDB_round3_schema1.lua' }

local function fixture(file, name)
  local f = io.open(FX .. 'migration/' .. file, 'rb')
  T.truthy(f, 'migration fixture missing (never skipped): ' .. file)
  f:close()
  return sim.loadFixture(FX .. 'migration/' .. file, name)
end

local function copy(t) return sim.parse(sim.dump(t)) end

--- Boots the addon over saved data. Without `login` the Store is opened by hand and Probe has not run (so compat is
-- exactly what the file held); with login the full startup runs (Probe then refreshes compat by design).
-- override = { path = source } replaces addon files (the rollback tests).
local function open(account, character, override, login)
  local W = Fake.new()
  if account then W.env.GoldIntelDB = account end
  if character then W.env.GoldIntelCharDB = character end
  Loader.override = override
  local P, ns = Loader.load(W.env)
  Loader.override = nil
  if login then W:login() else ns.Store.Open(); ns.Store.Char() end
  return W, ns, P
end

local function oldSources()
  return {
    ['Store/Store.lua'] = Loader.readFile(FX .. 'rollback/store_0.3.1.lua'),
    ['Store/Migrations.lua'] = Loader.readFile(FX .. 'rollback/migrations_0.3.1.lua'),
  }
end

local SKIP = { compat = true, runtime = true }

for _, file in ipairs(ACCOUNT) do
  T.describe('schema 2 migration of the real file ' .. file, function()
    T.it('migrates 1 -> 2: ledger created empty, compat byte-for-byte identical, nothing else lost', function()
      local live = fixture(file, 'GoldIntelDB')
      T.eq(live.schema, 1)
      local before = copy(live)
      local compatDump = sim.dump(live.compat)
      local W, ns = open(live)
      local st = ns.Store.Status()
      T.eq(st.state, 'migrated'); T.eq(st.schema, 2); T.truthy(st.writable)
      T.eq(sim.dump(live.compat), compatDump, 'compat is byte-for-byte unchanged')
      T.eq(live.schema, 2)
      T.eq(type(live.ledger), 'table')
      -- every schema 1 key other than the volatile ones is still there with the same content (meta gets its normal update)
      for key, value in pairs(before) do
        if not SKIP[key] and key ~= 'meta' and key ~= 'schema' then T.eq(live[key], value, 'key ' .. key .. ' changed') end
      end
      T.eq(live.meta.schemaHistory[#live.meta.schemaHistory].from, 1)
      T.eq(live.meta.schemaHistory[#live.meta.schemaHistory].to, 2)
    end)

    T.it('migrationBackup holds an exact copy of the schema 1 data (everything except compat and runtime)', function()
      local live = fixture(file, 'GoldIntelDB')
      local before = copy(live)
      open(live)
      local b = live.migrationBackup
      T.truthy(b); T.eq(b.from, 1); T.eq(type(b.t), 'number')
      local expectKeys = {}
      for key in pairs(before) do if not SKIP[key] then expectKeys[#expectKeys + 1] = key end end
      table.sort(expectKeys)
      T.eq(b.keys, expectKeys)
      for _, key in ipairs(b.keys) do T.eq(b.data[key], before[key], 'backup of ' .. key) end
      T.isnil(b.data.compat); T.isnil(b.data.runtime); T.isnil(b.data.migrationBackup)
    end)

    T.it('the migrated file survives a save and load, and the next session does not migrate again', function()
      local live = fixture(file, 'GoldIntelDB')
      open(live)
      local opens = live.meta.opens
      local saved = sim.parse(sim.dump(live))            -- would fail on anything the client cannot save
      local backup = copy(saved.migrationBackup)
      local W2, ns2 = open(saved)
      T.eq(ns2.Store.Status().state, 'ok')
      T.eq(saved.migrationBackup, backup, 'the backup is written once and left alone')
      T.eq(saved.meta.opens, opens + 1)
    end)

    T.it('rollback: the released 0.3.1 Store opens the schema 2 file READ-ONLY and changes nothing', function()
      local live = fixture(file, 'GoldIntelDB')
      open(live)
      local schema2 = sim.parse(sim.dump(live))
      local snapshot = copy(schema2)
      local W2, ns2 = open(schema2, nil, oldSources())
      local st = ns2.Store.Status()
      T.eq(st.state, 'readonly'); T.falsy(st.writable); T.eq(st.schema, 2)
      T.truthy(st.reason:find('newer than this addon', 1, true))
      T.eq(schema2, snapshot, 'opening left the schema 2 file untouched')
      -- a full session of the old addon: Probe refreshes compat (it owns it); nothing else in the file changes
      local schema2b = copy(snapshot)
      local W3 = open(schema2b, nil, oldSources(), true)
      W3:advance(5); W3:fire('PLAYER_LOGOUT')
      for key, value in pairs(snapshot) do
        if key ~= 'compat' then T.eq(schema2b[key], value, 'old addon changed ' .. key) end
      end
    end)

    T.it('manual recovery: backup + compat rebuild a schema 1 file that the 0.3.1 Store opens normally', function()
      local live = fixture(file, 'GoldIntelDB')
      local before = copy(live)
      open(live)
      local schema2 = sim.parse(sim.dump(live))
      local rebuilt = { schema = 1, compat = schema2.compat }
      for _, key in ipairs(schema2.migrationBackup.keys) do rebuilt[key] = schema2.migrationBackup.data[key] end
      for key, value in pairs(before) do
        if not SKIP[key] then T.eq(rebuilt[key], value, 'rebuilt ' .. key) end
      end
      local W2, ns2 = open(rebuilt, nil, oldSources())
      T.eq(ns2.Store.Status().state, 'ok'); T.eq(ns2.Store.Status().schema, 1); T.truthy(ns2.Store.Status().writable)
    end)

    T.it('size of the backup (reported, not limited here)', function()
      local live = fixture(file, 'GoldIntelDB')
      open(live)
      local bytes = #sim.dump(live.migrationBackup)
      T.truthy(bytes > 0)
      T.truthy(bytes < 20000, 'backup is ' .. bytes .. ' bytes')
    end)
  end)
end

T.describe('schema 2 migration of the Phase 1 file (schema 0 -> 2)', function()
  T.it('goes 0 -> 2 in one open with compat untouched and a backup of the adopted schema 1 data', function()
    local live = sim.loadFixture(FX .. 'forever_1.60.1_GoldIntelDB.lua', 'GoldIntelDB')
    local compatDump = sim.dump(live.compat)
    local W, ns = open(live)
    T.eq(ns.Store.Status().state, 'migrated'); T.eq(live.schema, 2)
    T.eq(sim.dump(live.compat), compatDump)
    T.eq(live.migrationBackup.from, 1)
    T.eq(type(live.ledger), 'table')
  end)
end)

for _, file in ipairs(CHAR) do
  T.describe('character data of the real file ' .. file, function()
    T.it('upgrades to schema 2 in place; the collect journal and counters are kept; lastMoney is absent until saved', function()
      local char = fixture(file, 'GoldIntelCharDB')
      T.eq(char.schema, 1)
      local before = copy(char)
      local W, ns = open(nil, char)
      T.eq(ns.Store.Char().schema, 2)
      T.eq(char.collect, before.collect)
      T.eq(char.pending, before.pending)
      T.isnil(char.lastMoney)
    end)
    T.it('rollback: the 0.3.1 Store treats schema 2 character data as newer and uses a private copy', function()
      local char = fixture(file, 'GoldIntelCharDB')
      open(nil, char)
      local schema2 = sim.parse(sim.dump(char))
      local snapshot = copy(schema2)
      local W2, ns2 = open(nil, schema2, oldSources())
      local c = ns2.Store.Char()
      c.scratch = 1
      T.truthy(c ~= schema2)
      T.eq(schema2, snapshot)
    end)
  end)
end

T.describe('schema 2 specifics', function()
  T.it('a fresh install is created at schema 2 with an empty ledger and no backup', function()
    local W, ns = open()
    T.eq(ns.Store.Status().state, 'created')
    local db = W.env.GoldIntelDB
    T.eq(db.schema, 2); T.eq(db.ledger, {}); T.isnil(db.migrationBackup)
  end)
  T.it('unknown keys and the lots section survive the migration unchanged', function()
    local live = fixture(ACCOUNT[1], 'GoldIntelDB')
    live.futureThing = { a = 1 }
    local lots = copy(live.lots)
    open(live)
    T.eq(live.futureThing, { a = 1 })
    T.eq(live.lots, lots)
  end)
end)
