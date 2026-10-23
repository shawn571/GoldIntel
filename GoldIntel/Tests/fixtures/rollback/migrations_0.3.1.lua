-- GoldIntel / Store / Migrations.lua                                    (Phase 2)
--
-- PURPOSE
--   The schema migration framework and the database shape.
--
--   Migrations.Register(from, fn, name)   fn(db) upgrades a database from schema `from` to from+1
--   Migrations.Latest()                   the schema this addon writes (highest registered step + 1)
--   Migrations.Plan(from, to)             -> array of steps | nil, err (a gap means no path)
--   Migrations.Run(db, from, to)          -> { ok, applied = {names}, failedAt, err }
--   Migrations.Sections()                 -> fresh default sections (new tables every call)
--   Migrations.Check(db) / EnsureShape(db)  detect / repair wrong or missing sections
--
-- RULES (Decisions D-036)
--   * A migration only mutates the table it is given. Store runs it on a COPY and commits
--     only when the whole chain succeeded and validation passed, so a failing migration can
--     never damage saved data.
--   * A migration must never alter db.compat (owned by Platform/Probe). Store verifies this.
--   * Steps are contiguous: 0->1, 1->2, ... Schema 0 means 'a database that has no schema field'
--     (everything written before Phase 2: only GoldIntelDB.compat).
--   * Unknown keys are preserved by every migration.
--   * The first released schema is 1 (Decisions D-014).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Store/Migrations.lua')

local Mig = {}
GI.Migrations = Mig

local steps = {}      -- from -> { fn = function, name = string }

---------------------------------------------------------------------------
-- Database shape (Contracts F5)
---------------------------------------------------------------------------

local FACTORIES = {
  meta = function() return {} end,
  profile = function() return {} end,
  chars = function() return {} end,
  sessions = function() return {} end,
  segments = function() return {} end,
  lots = function() return { open = {}, closedSummary = {} } end,
  agg = function() return { zone = {}, sub = {}, act = {}, bracket = {} } end,
  heat = function() return {} end,
  prices = function() return { snapshots = {} } end,
  auctions = function() return {} end,
  runtime = function() return {} end,
}
local NESTED = {
  lots = { 'open', 'closedSummary' },
  agg = { 'zone', 'sub', 'act', 'bracket' },
  prices = { 'snapshots' },
}
Mig.SECTION_NAMES = {}
for name in pairs(FACTORIES) do Mig.SECTION_NAMES[#Mig.SECTION_NAMES + 1] = name end
table.sort(Mig.SECTION_NAMES)

--- Registers a section factory so later phases can add sections (Store validates it too).
function Mig.DefineSection(name, factory, nested)
  if type(name) ~= 'string' or name == '' or name == 'compat' or name == 'schema' then
    return nil, 'invalid section name'
  end
  if FACTORIES[name] then return nil, 'section already defined: ' .. name end
  if type(factory) ~= 'function' then return nil, 'factory must be a function' end
  FACTORIES[name] = factory
  NESTED[name] = nested
  Mig.SECTION_NAMES[#Mig.SECTION_NAMES + 1] = name
  table.sort(Mig.SECTION_NAMES)
  return true
end

--- Fresh default sections (every table is new).
function Mig.Sections()
  local out = {}
  for name, factory in pairs(FACTORIES) do out[name] = factory() end
  return out
end

--- Lists problems without changing anything: { missing = {...}, wrongType = {...} }.
function Mig.Check(db)
  local problems = { missing = {}, wrongType = {} }
  for _, name in ipairs(Mig.SECTION_NAMES) do
    local section = db[name]
    if section == nil then
      problems.missing[#problems.missing + 1] = name
    elseif type(section) ~= 'table' then
      problems.wrongType[#problems.wrongType + 1] = name
    else
      local nested = NESTED[name]
      if nested then
        for _, inner in ipairs(nested) do
          if section[inner] == nil then
            problems.missing[#problems.missing + 1] = name .. '.' .. inner
          elseif type(section[inner]) ~= 'table' then
            problems.wrongType[#problems.wrongType + 1] = name .. '.' .. inner
          end
        end
      end
    end
  end
  return problems
end

--- Adds missing sections and replaces wrong-typed ones. Returns { added = {...}, repaired = {...} }.
-- Existing valid content and unknown keys are never touched.
function Mig.EnsureShape(db)
  local report = { added = {}, repaired = {} }
  for _, name in ipairs(Mig.SECTION_NAMES) do
    local section = db[name]
    if section == nil then
      db[name] = FACTORIES[name]()
      report.added[#report.added + 1] = name
    elseif type(section) ~= 'table' then
      db[name] = FACTORIES[name]()
      report.repaired[#report.repaired + 1] = name
    else
      local nested = NESTED[name]
      if nested then
        for _, inner in ipairs(nested) do
          if section[inner] == nil then
            section[inner] = {}
            report.added[#report.added + 1] = name .. '.' .. inner
          elseif type(section[inner]) ~= 'table' then
            section[inner] = {}
            report.repaired[#report.repaired + 1] = name .. '.' .. inner
          end
        end
      end
    end
  end
  return report
end

---------------------------------------------------------------------------
-- Registry and runner
---------------------------------------------------------------------------

function Mig.Register(from, fn, name)
  if type(from) ~= 'number' or from < 0 or from ~= math.floor(from) then return nil, 'from must be a whole number >= 0' end
  if type(fn) ~= 'function' then return nil, 'migration must be a function' end
  if steps[from] then return nil, 'a migration from ' .. from .. ' is already registered' end
  steps[from] = { fn = fn, name = name or ('v' .. from .. '->v' .. (from + 1)) }
  return true
end

--- The schema this addon writes: the end of the contiguous chain that starts at 0.
function Mig.Latest()
  local v = 0
  while steps[v] do v = v + 1 end
  return v
end

function Mig.Plan(from, to)
  if type(from) ~= 'number' or type(to) ~= 'number' then return nil, 'from and to must be numbers' end
  if from > to then return nil, 'cannot migrate backwards from ' .. from .. ' to ' .. to end
  local plan = {}
  for v = from, to - 1 do
    if not steps[v] then return nil, 'no migration from schema ' .. v end
    plan[#plan + 1] = { from = v, name = steps[v].name }
  end
  return plan
end

--- Runs the chain on `db` (mutating it). Never throws.
function Mig.Run(db, from, to)
  local report = { ok = true, applied = {} }
  local plan, err = Mig.Plan(from, to)
  if not plan then
    report.ok = false
    report.err = err
    return report
  end
  for _, step in ipairs(plan) do
    local ok, stepErr = pcall(steps[step.from].fn, db)
    if not ok then
      report.ok = false
      report.failedAt = step.from
      report.err = tostring(stepErr)
      return report
    end
    db.schema = step.from + 1
    report.applied[#report.applied + 1] = step.name
  end
  return report
end

--- Test helper: remove every step (then Latest() is 0).
function Mig.Reset() steps = {} end

---------------------------------------------------------------------------
-- Built-in migration: schema 0 (Phase 1 database, only 'compat') -> schema 1
---------------------------------------------------------------------------

Mig.Register(0, function(db)
  Mig.EnsureShape(db)
end, 'adopt Phase 1 database into schema 1')

if GI.Core then GI.Core.Service('migrations', Mig) end
