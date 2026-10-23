--[[
GoldIntel / Tests / helpers / testlib.lua

A deliberately tiny test framework so the suite runs on any plain Lua 5.1+ interpreter
without dependencies. Tests execute immediately (no deferred hooks): do your setup
inside the `it` body or in a local helper function.

    local T = require('testlib')          -- via package.path set by Tests/run.lua
    T.describe('Money', function()
      T.it('emits deltas', function()
        T.eq(1 + 1, 2)
      end)
    end)
]]

local T = { passed = 0, failed = 0, failures = {} }
local path = {}

local function serialize(v, seen, depth)
  depth = depth or 0
  if type(v) == 'string' then return string.format('%q', v) end
  if type(v) ~= 'table' then return tostring(v) end
  seen = seen or {}
  if seen[v] then return '<cycle>' end
  if depth > 4 then return '{...}' end
  seen[v] = true
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    if type(a) == type(b) and (type(a) == 'number' or type(a) == 'string') then return a < b end
    return tostring(a) < tostring(b)
  end)
  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = tostring(k) .. '=' .. serialize(v[k], seen, depth + 1)
  end
  seen[v] = nil
  return '{' .. table.concat(parts, ', ') .. '}'
end
T.serialize = serialize

local function deepEqual(a, b)
  if a == b then return true end
  if type(a) ~= 'table' or type(b) ~= 'table' then return false end
  for k, v in pairs(a) do
    if not deepEqual(v, b[k]) then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

local function fail(msg, level)
  error(msg, (level or 1) + 1)
end

function T.eq(actual, expected, msg)
  if not deepEqual(actual, expected) then
    fail((msg and (msg .. ': ') or '') .. 'expected ' .. serialize(expected) .. ' but got ' .. serialize(actual), 2)
  end
end

function T.neq(actual, unexpected, msg)
  if deepEqual(actual, unexpected) then
    fail((msg and (msg .. ': ') or '') .. 'did not expect ' .. serialize(actual), 2)
  end
end

function T.truthy(v, msg)
  if not v then fail((msg or 'expected a truthy value') .. ' (got ' .. serialize(v) .. ')', 2) end
end

function T.falsy(v, msg)
  if v then fail((msg or 'expected a falsy value') .. ' (got ' .. serialize(v) .. ')', 2) end
end

function T.isnil(v, msg)
  if v ~= nil then fail((msg or 'expected nil') .. ' (got ' .. serialize(v) .. ')', 2) end
end

function T.near(actual, expected, eps, msg)
  eps = eps or 1e-9
  if type(actual) ~= 'number' or math.abs(actual - expected) > eps then
    fail((msg and (msg .. ': ') or '') .. 'expected ~' .. tostring(expected) .. ' but got ' .. tostring(actual), 2)
  end
end

--- Expects fn() to raise an error whose message contains `pattern` (plain find).
function T.raises(fn, pattern, msg)
  local ok, err = pcall(fn)
  if ok then fail((msg or 'expected an error') .. ' but none was raised', 2) end
  if pattern and not tostring(err):find(pattern, 1, true) then
    fail((msg or 'error mismatch') .. ': expected "' .. pattern .. '" in "' .. tostring(err) .. '"', 2)
  end
end

function T.describe(name, fn)
  path[#path + 1] = name
  local ok, err = xpcall(fn, function(e) return debug.traceback(tostring(e), 2) end)
  if not ok then
    T.failed = T.failed + 1
    T.failures[#T.failures + 1] = { name = table.concat(path, ' > ') .. ' (describe body)', err = err }
  end
  path[#path] = nil
end

function T.it(name, fn)
  local full = table.concat(path, ' > ') .. ' > ' .. name
  local ok, err = xpcall(fn, function(e) return debug.traceback(tostring(e), 2) end)
  if ok then
    T.passed = T.passed + 1
  else
    T.failed = T.failed + 1
    T.failures[#T.failures + 1] = { name = full, err = err }
  end
end

function T.summary()
  for _, f in ipairs(T.failures) do
    print('FAIL  ' .. f.name)
    print('      ' .. tostring(f.err):gsub('\n', '\n      '))
  end
  print(string.format('%d passed, %d failed', T.passed, T.failed))
  return T.failed == 0
end

return T
