-- GoldIntel / Store / Store.lua                                         (Phase 2)
--
-- PURPOSE
--   The persistence layer: opens GoldIntelDB (through Platform.SavedVars), brings it to the
--   current schema, and gives the rest of the addon safe access to its sections.
--
--   Store.Open()            -> status (idempotent; never throws)
--   Store.Get()             -> root table of the working database
--   Store.Section(name)     -> the named section (created if missing)
--   Store.Char()            -> per-character table (GoldIntelCharDB)
--   Store.Status() / IsOpen() / IsWritable()
--   Store.Checkpoint(opts)  -> { bytes, truncated, writable, note }
--   Store.EstimateBytes(table, nodeLimit) -> bytes, truncated
--
-- OPEN OUTCOMES (status.state)
--   created   no database existed: a fresh schema-N database was built
--   ok        schema is current; sections validated (and repaired if needed)
--   migrated  an older database (schema 0 = Phase 1, only 'compat') was upgraded
--   readonly  the database is NEWER than this addon understands: it is left untouched and
--             a private working copy is used; nothing is written back
--   degraded  migration or validation failed: the database is left untouched and an
--             in-memory database is used; nothing is written back
--
-- THE compat GUARANTEE (Decisions D-022 item 6, external review finding 3)
--   GoldIntelDB.compat belongs to Platform/Probe. Store never creates, rewrites or removes
--   it, in any state, during initialization or any migration. Migrations run on a copy and
--   the copy's compat must equal the original before anything is committed; the live compat
--   table keeps its identity. Tests assert this with the real database shape captured from
--   the WoW Forever client.
--
-- DURABILITY
--   SavedVariables are written by the client at logout or reload; addons cannot force a
--   write. The live table IS the database, so changes are durable only once the client saves.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Store/Store.lua')

local Store = {}
GI.Store = Store

local status = nil      -- set by Open
local root = nil        -- working root (the live table, or a private copy)
local charRoot = nil
Store.HISTORY_LIMIT = 20
Store.CHAR_SCHEMA = 2         -- GoldIntelCharDB.schema this addon writes (2 adds lastMoney, increment 3b-2)

local function fire(name, payload)
  if GI.Bus then GI.Bus.Fire(name, payload) end
end

---------------------------------------------------------------------------
-- Size estimation (cheap, bounded)
---------------------------------------------------------------------------

--- Approximate serialized size in bytes. Stops after nodeLimit nodes (default 200000) and
-- reports truncated = true. Cycle-safe.
function Store.EstimateBytes(value, nodeLimit)
  nodeLimit = nodeLimit or 200000
  local bytes, nodes = 0, 0
  local seen = {}
  local stack = { value }
  while #stack > 0 do
    local v = table.remove(stack)
    nodes = nodes + 1
    if nodes > nodeLimit then return bytes, true end
    local t = type(v)
    if t == 'string' then
      bytes = bytes + #v + 2
    elseif t == 'number' then
      bytes = bytes + 8
    elseif t == 'boolean' then
      bytes = bytes + 5
    elseif t == 'table' then
      if not seen[v] then
        seen[v] = true
        bytes = bytes + 4
        for k, x in pairs(v) do
          stack[#stack + 1] = k
          stack[#stack + 1] = x
        end
      end
    end
  end
  return bytes, false
end

---------------------------------------------------------------------------
-- Open
---------------------------------------------------------------------------

local function newStatus(target)
  return { state = 'ok', schema = 0, target = target, writable = true, repaired = {}, added = {},
           migrated = nil, reason = nil, svStatus = nil }
end

local function updateMeta(db, st)
  local t = P.Now()
  local meta = db.meta
  if type(meta) ~= 'table' then meta = {}; db.meta = meta end
  if not meta.firstSeen then meta.firstSeen = t end
  meta.lastOpened = t
  meta.opens = (tonumber(meta.opens) or 0) + 1
  meta.addonVersion = P.VERSION
  if type(db.compat) == 'table' and db.compat.build ~= nil then meta.lastBuild = db.compat.build end
  if st.migrated then
    local history = meta.schemaHistory
    if type(history) ~= 'table' then history = {}; meta.schemaHistory = history end
    history[#history + 1] = { from = st.migrated.from, to = st.migrated.to, t = t, addonVersion = P.VERSION }
    while #history > Store.HISTORY_LIMIT do table.remove(history, 1) end
  end
end

local function degrade(live, st, reason)
  st.state = 'degraded'
  st.writable = false
  st.reason = reason
  -- A private in-memory database; the live table is not touched. compat is copied for reading.
  local working = GI.Migrations.Sections()
  working.schema = st.target
  if live and type(live.compat) == 'table' then working.compat = P.Util.deepCopy(live.compat) end
  root = working
  P.Diag('error', 'Store', 'database degraded: ' .. tostring(reason))
  P.Print('saved data could not be upgraded (' .. tostring(reason) .. '). GoldIntel keeps your file untouched and runs without saving.')
  fire('STORE_DEGRADED', { reason = tostring(reason) })
end

local function migrate(live, from, target, st)
  local Util = P.Util
  local staged = Util.deepCopy(live)
  local compatBefore = Util.deepCopy(live.compat)
  local report = GI.Migrations.Run(staged, from, target)
  if not report.ok then return false, 'migration failed' .. (report.failedAt and (' at schema ' .. report.failedAt) or '') .. ': ' .. tostring(report.err) end
  local shape = GI.Migrations.EnsureShape(staged)
  for _, name in ipairs(shape.added) do st.added[#st.added + 1] = name end
  for _, name in ipairs(shape.repaired) do st.repaired[#st.repaired + 1] = name end
  if not Util.deepEqual(staged.compat, compatBefore) then return false, 'migration changed compat, which Store must preserve' end
  local problems = GI.Migrations.Check(staged)
  if #problems.missing > 0 or #problems.wrongType > 0 then return false, 'database invalid after migration' end
  -- Commit: replace everything except the live compat table (its identity is preserved).
  for key in pairs(live) do
    if key ~= 'compat' then live[key] = nil end
  end
  for key, value in pairs(staged) do
    if key ~= 'compat' then live[key] = value end
  end
  st.migrated = { from = from, to = target, applied = report.applied }
  return true
end

--- Opens the database. Idempotent: later calls return the same status.
function Store.Open()
  if status then return Store.Status() end
  local Mig = GI.Migrations
  local target = Mig.Latest()
  local st = newStatus(target)
  status = st

  local sv = P.SavedVars
  local live, svStatus
  if sv then live, svStatus = sv.Account() end
  st.svStatus = svStatus

  if type(live) ~= 'table' then
    degrade(nil, st, 'SavedVariables are not available')
  elseif svStatus ~= 'existing' or next(live) == nil then
    -- nothing was saved: build a fresh database in place
    local fresh = Mig.Sections()
    for key, value in pairs(fresh) do live[key] = value end
    live.schema = target
    st.state = 'created'
    st.schema = target
    root = live
  else
    local schema = live.schema
    local from = type(schema) == 'number' and schema or 0
    if type(schema) == 'number' and schema > target then
      st.state = 'readonly'
      st.writable = false
      st.schema = schema
      st.reason = 'saved data is schema ' .. schema .. ', newer than this addon (' .. target .. '); left untouched'
      root = P.Util.deepCopy(live)
      P.Diag('warn', 'Store', st.reason)
    elseif from < target then
      local ok, err = migrate(live, from, target, st)
      if ok then
        st.state = 'migrated'
        st.schema = target
        root = live
      else
        st.schema = from
        degrade(live, st, err)
      end
    else
      local shape = Mig.EnsureShape(live)
      for _, name in ipairs(shape.added) do st.added[#st.added + 1] = name end
      for _, name in ipairs(shape.repaired) do st.repaired[#st.repaired + 1] = name end
      if #shape.repaired > 0 then
        P.Diag('warn', 'Store', 'repaired wrong-typed sections: ' .. table.concat(shape.repaired, ', '))
      end
      st.schema = target
      root = live
    end
  end

  if st.writable and root then updateMeta(root, st) end
  fire('STORE_OPENED', { state = st.state, schema = st.schema, writable = st.writable })
  if st.migrated then fire('STORE_MIGRATED', { from = st.migrated.from, to = st.migrated.to }) end
  return Store.Status()
end

---------------------------------------------------------------------------
-- Access
---------------------------------------------------------------------------

function Store.IsOpen() return status ~= nil end

function Store.IsWritable()
  return status ~= nil and status.writable == true
end

--- Copy of the status table.
function Store.Status()
  if not status then return nil end
  local out = P.Util.shallowCopy(status)
  out.repaired = P.Util.shallowCopy(status.repaired)
  out.added = P.Util.shallowCopy(status.added)
  return out
end

function Store.Get()
  if not status then Store.Open() end
  return root
end

--- The named section; created when missing. Returns nil when the name is invalid.
function Store.Section(name)
  if type(name) ~= 'string' or name == '' or name == 'schema' or name == 'compat' then return nil end
  local db = Store.Get()
  if type(db[name]) ~= 'table' then db[name] = {} end
  return db[name]
end

--- The per-character table (GoldIntelCharDB): { schema, pending = {}, ... }.
function Store.Char()
  if charRoot then return charRoot end
  local live
  if P.SavedVars then live = P.SavedVars.Character() end
  if type(live) ~= 'table' then live = {} end
  if type(live.schema) == 'number' and live.schema > Store.CHAR_SCHEMA then
    P.Diag('warn', 'Store', 'character data is schema ' .. live.schema .. ', newer than this addon; using a private copy')
    live = P.Util.deepCopy(live)
  end
  if live.schema == nil or live.schema < Store.CHAR_SCHEMA then live.schema = Store.CHAR_SCHEMA end    -- 1 -> 2 is additive (lastMoney)
  if type(live.pending) ~= 'table' then live.pending = {} end
  charRoot = live
  return live
end

--- Marks a checkpoint and returns the approximate size. Saving to disk still happens at
-- logout or /reload (addons cannot force it).
function Store.Checkpoint(opts)
  local db = Store.Get()
  local bytes, truncated = Store.EstimateBytes(db)
  if status.writable and type(db.meta) == 'table' then db.meta.lastCheckpoint = (P.Now()) end
  return {
    bytes = bytes, truncated = truncated, writable = status.writable,
    note = 'The client writes saved data at logout or /reload.',
  }
end

--- Test helper: forget the open database (does not touch saved variables).
function Store.Reset()
  status, root, charRoot = nil, nil, nil
end

if GI.Core then GI.Core.Service('store', Store) end
