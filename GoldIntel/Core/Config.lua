-- GoldIntel / Core / Config.lua                                         (Phase 2)
--
-- PURPOSE
--   The configuration framework. Every setting is DEFINED once with a type, a default and
--   limits; values live in the persisted profile (GoldIntelDB.profile, dotted keys map to
--   nested tables, e.g. 'prune.days' -> profile.prune.days) and are always validated.
--
--   Config.Define(key, spec)        declare a setting (modules declare their own later)
--   Config.Get(key)                 -> value (the default when unset or invalid)
--   Config.Set(key, value, source)  -> true, persisted | nil, err
--   Config.Parse(key, text)         -> typed value | nil, err   (used by /gi config set)
--   Config.Reset(key) / ResetAll()
--   Config.Load()                   validates persisted values at startup
--   Config.List()                   -> sorted array of setting descriptions
--
--   spec: { type = 'number'|'boolean'|'string'|'enum', default = ..., min, max, integer,
--           values (enum), maxLength (string), readonly, help }
--
-- BEHAVIOR
--   * Invalid persisted values are ignored (the default applies) and reported at Load.
--   * Unknown keys already in the profile are preserved untouched (forward compatibility).
--   * Writes go to the live profile table. If the Store is read-only or degraded, the value
--     is kept for this session only and Set reports persisted = false.
--   * Every change fires CONFIG_CHANGED on the Bus.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Core/Config.lua')

local Config = {}
GI.Config = Config

local specs = {}
local order = {}

local function validKey(key)
  if type(key) ~= 'string' or key == '' then return false end
  for part in (key .. '.'):gmatch('([^%.]*)%.') do
    if not part:match('^[%a_][%w_]*$') then return false end
  end
  return true
end

local function checkValue(spec, value)
  local t = spec.type
  if t == 'number' then
    if type(value) ~= 'number' or value ~= value or value == math.huge or value == -math.huge then
      return false, 'must be a number'
    end
    if spec.integer and value ~= math.floor(value) then return false, 'must be a whole number' end
    if spec.minValue and value < spec.minValue then return false, 'must be at least ' .. tostring(spec.minValue) end
    if spec.maxValue and value > spec.maxValue then return false, 'must be at most ' .. tostring(spec.maxValue) end
    return true
  elseif t == 'boolean' then
    if type(value) ~= 'boolean' then return false, 'must be true or false' end
    return true
  elseif t == 'string' then
    if type(value) ~= 'string' then return false, 'must be text' end
    if #value > (spec.maxLength or 200) then return false, 'is too long' end
    return true
  elseif t == 'enum' then
    for i = 1, #spec.values do
      if spec.values[i] == value then return true end
    end
    return false, 'must be one of: ' .. table.concat(spec.values, ', ')
  end
  return false, 'unknown type'
end

local function split(key)
  local parts = {}
  for part in key:gmatch('[^%.]+') do parts[#parts + 1] = part end
  return parts
end

local function profile()
  local store = GI.Store
  if store then return store.Section('profile') end
  return nil
end

local function getPath(root, key)
  local node = root
  for _, part in ipairs(split(key)) do
    if type(node) ~= 'table' then return nil end
    node = node[part]
  end
  return node
end

local function setPath(root, key, value)
  local parts = split(key)
  local node = root
  for i = 1, #parts - 1 do
    if type(node[parts[i]]) ~= 'table' then node[parts[i]] = {} end
    node = node[parts[i]]
  end
  node[parts[#parts]] = value
end

local function prune(root, key)
  -- remove the leaf and any parent tables that became empty
  local parts = split(key)
  local chain = { root }
  for i = 1, #parts - 1 do
    local nextNode = chain[#chain][parts[i]]
    if type(nextNode) ~= 'table' then return end
    chain[#chain + 1] = nextNode
  end
  chain[#chain][parts[#parts]] = nil
  for i = #chain, 2, -1 do
    if next(chain[i]) == nil then chain[i - 1][parts[i - 1]] = nil else break end
  end
end

---------------------------------------------------------------------------
-- Definitions
---------------------------------------------------------------------------

function Config.Define(key, spec)
  if not validKey(key) then return nil, 'invalid key ' .. tostring(key) end
  if specs[key] then return nil, 'setting already defined: ' .. key end
  if type(spec) ~= 'table' then return nil, 'spec must be a table' end
  local t = spec.type
  if t ~= 'number' and t ~= 'boolean' and t ~= 'string' and t ~= 'enum' then return nil, 'unknown type ' .. tostring(t) end
  if t == 'enum' and (type(spec.values) ~= 'table' or #spec.values == 0) then return nil, 'enum needs a list of values' end
  local ok, why = checkValue(spec, spec.default)
  if not ok then return nil, 'default ' .. why end
  for other in pairs(specs) do
    if other:sub(1, #key + 1) == key .. '.' or key:sub(1, #other + 1) == other .. '.' then
      return nil, 'key conflicts with ' .. other
    end
  end
  local copy = P.Util.shallowCopy(spec)
  specs[key] = copy
  order[#order + 1] = key
  return true
end

function Config.Spec(key)
  local spec = specs[key]
  if not spec then return nil end
  return P.Util.shallowCopy(spec)
end

---------------------------------------------------------------------------
-- Values
---------------------------------------------------------------------------

function Config.Get(key)
  local spec = specs[key]
  if not spec then return nil, 'unknown setting ' .. tostring(key) end
  local root = profile()
  if root then
    local stored = getPath(root, key)
    if stored ~= nil and checkValue(spec, stored) then return stored end
  end
  return spec.default
end

local function fire(key, value, previous, source)
  if GI.Bus then
    GI.Bus.Fire('CONFIG_CHANGED', { key = key, value = value, previous = previous, source = source or 'api' })
  end
end

local function persistedNow()
  return GI.Store ~= nil and GI.Store.IsWritable()
end

function Config.Set(key, value, source)
  local spec = specs[key]
  if not spec then return nil, 'unknown setting ' .. tostring(key) end
  if spec.readonly then return nil, key .. ' is read-only' end
  local ok, why = checkValue(spec, value)
  if not ok then return nil, key .. ' ' .. why end
  local root = profile()
  if not root then return nil, 'store is not available' end
  local previous = Config.Get(key)
  setPath(root, key, value)
  if previous ~= value then fire(key, value, previous, source) end
  return true, persistedNow()
end

function Config.Reset(key, source)
  local spec = specs[key]
  if not spec then return nil, 'unknown setting ' .. tostring(key) end
  if spec.readonly then return nil, key .. ' is read-only' end
  local root = profile()
  if not root then return nil, 'store is not available' end
  local previous = Config.Get(key)
  prune(root, key)
  if previous ~= spec.default then fire(key, spec.default, previous, source or 'reset') end
  return true
end

function Config.ResetAll(source)
  local n = 0
  for _, key in ipairs(order) do
    if not specs[key].readonly then
      local root = profile()
      if root and getPath(root, key) ~= nil then n = n + 1 end
      Config.Reset(key, source or 'reset')
    end
  end
  return n
end

--- Converts text (from a command line) into a typed value for the setting.
function Config.Parse(key, text)
  local spec = specs[key]
  if not spec then return nil, 'unknown setting ' .. tostring(key) end
  text = tostring(text or '')
  if spec.type == 'number' then
    local n = tonumber(text)
    if not n then return nil, key .. ' needs a number' end
    return n
  elseif spec.type == 'boolean' then
    local v = text:lower()
    if v == 'true' or v == 'on' or v == 'yes' or v == '1' then return true end
    if v == 'false' or v == 'off' or v == 'no' or v == '0' then return false end
    return nil, key .. ' needs on or off'
  end
  return text
end

--- Validates persisted values. Invalid ones stay in the table but are ignored (the default
-- applies); they are returned so the caller can report them. Returns { invalid = { key = reason } }.
function Config.Load()
  local report = { invalid = {} }
  local root = profile()
  if not root then return report end
  for _, key in ipairs(order) do
    local stored = getPath(root, key)
    if stored ~= nil then
      local ok, why = checkValue(specs[key], stored)
      if not ok then
        report.invalid[key] = why
        P.Diag('warn', 'Config', 'ignoring invalid saved value for ' .. key .. ' (' .. why .. '); using the default')
      end
    end
  end
  return report
end

--- Sorted descriptions: { key, value, default, isDefault, type, minValue, maxValue, values, readonly, help }.
function Config.List()
  local keys = {}
  for i = 1, #order do keys[i] = order[i] end
  table.sort(keys)
  local out = {}
  for _, key in ipairs(keys) do
    local spec = specs[key]
    local value = Config.Get(key)
    out[#out + 1] = {
      key = key, value = value, default = spec.default, isDefault = (value == spec.default),
      type = spec.type, minValue = spec.minValue, maxValue = spec.maxValue, values = spec.values,
      readonly = spec.readonly and true or false, help = spec.help,
    }
  end
  return out
end

---------------------------------------------------------------------------
-- Built-in settings (Contracts F6)
---------------------------------------------------------------------------

local BUILTIN = {
  { 'idleSec', { type = 'number', default = 120, minValue = 10, maxValue = 3600, integer = true,
                 help = 'Seconds without activity before the session clock pauses (used from Phase 4)' } },
  { 'minSegSec', { type = 'number', default = 600, minValue = 30, maxValue = 7200, integer = true,
                   help = 'Segments shorter than this are merged into the previous one (Phase 4)' } },
  { 'minBinSec', { type = 'number', default = 60, minValue = 1, maxValue = 3600, integer = true,
                   help = 'Minimum seconds in a heatmap cell before it is shown (Phase 7)' } },
  { 'heatGrid', { type = 'number', default = 32, minValue = 32, maxValue = 32, integer = true, readonly = true,
                  help = 'Heatmap grid size per axis (fixed in v1, Decisions D-011)' } },
  { 'valuation', { type = 'enum', default = 'conservative', values = { 'conservative' },
                   help = 'How items are valued (Phase 6)' } },
  { 'defaultSellThrough', { type = 'number', default = 0.6, minValue = 0, maxValue = 1,
                            help = 'Assumed chance an auction sells when there is no history (Phase 6)' } },
  { 'prune.days', { type = 'number', default = 90, minValue = 1, maxValue = 3650, integer = true,
                    help = 'Raw session data older than this is eligible for roll-up (Phase 5)' } },
  { 'prune.maxBytes', { type = 'number', default = 2000000, minValue = 100000, maxValue = 20000000, integer = true,
                        help = 'Approximate size budget of the saved database' } },
  { 'collect.auto', { type = 'boolean', default = true,
                      help = 'Start collecting (cash and item ledger) automatically a few seconds after login; /gi collect off still stops it' } },
  { 'normalization.minHours', { type = 'number', default = 5, minValue = 0, maxValue = 1000,
                                help = 'Hours needed in a level bracket before normalized GPH is shown (experimental)' } },
  { 'normalization.bracketSize', { type = 'number', default = 5, minValue = 1, maxValue = 60, integer = true,
                                   help = 'Levels per normalization bracket (experimental)' } },
}
for i = 1, #BUILTIN do
  local ok, err = Config.Define(BUILTIN[i][1], BUILTIN[i][2])
  if not ok then error('built-in setting ' .. BUILTIN[i][1] .. ': ' .. tostring(err)) end
end

if GI.Core then GI.Core.Service('config', Config) end
