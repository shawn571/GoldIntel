--[[
GoldIntel / Tests / helpers / svsim.lua

Simulates how the client persists SavedVariables: the live table is written to a text file at
logout or reload and read back in the next session. dump() REFUSES values the real client
cannot save (functions, userdata, cycles, non-string/number keys), so a test that dumps the
database proves it holds plain serializable data only.

    local text = svsim.dump(env.GoldIntelDB)       -- logout
    env2.GoldIntelDB = svsim.parse(text)            -- next session
    local t = svsim.loadFixture('path/to/file.lua', 'GoldIntelDB')
]]

local Sim = {}

local function dumpValue(v, out, seen, path)
  local t = type(v)
  if t == 'number' then
    if v ~= v or v == math.huge or v == -math.huge then error('cannot save ' .. tostring(v) .. ' at ' .. path, 0) end
    out[#out + 1] = string.format('%.17g', v)
  elseif t == 'string' then
    out[#out + 1] = string.format('%q', v)
  elseif t == 'boolean' then
    out[#out + 1] = tostring(v)
  elseif t == 'table' then
    if seen[v] then error('cycle or shared table at ' .. path, 0) end
    seen[v] = true
    out[#out + 1] = '{'
    for k, x in pairs(v) do
      if type(k) == 'string' then
        out[#out + 1] = '[' .. string.format('%q', k) .. ']='
      elseif type(k) == 'number' then
        out[#out + 1] = '[' .. string.format('%.17g', k) .. ']='
      else
        error('cannot save a ' .. type(k) .. ' key at ' .. path, 0)
      end
      dumpValue(x, out, seen, path .. '.' .. tostring(k))
      out[#out + 1] = ','
    end
    out[#out + 1] = '}'
    seen[v] = nil
  else
    error('cannot save a ' .. t .. ' at ' .. path, 0)
  end
end

--- Serializes one value. Raises an error naming the path when something is not saveable.
function Sim.dump(value)
  local out = {}
  dumpValue(value, out, {}, 'root')
  return table.concat(out)
end

local function evaluate(text, env)
  local chunk
  if setfenv then
    chunk = assert(loadstring(text))
    setfenv(chunk, env)
  else
    chunk = assert(load(text, 'saved', 't', env))
  end
  return chunk()
end

--- Reads back what dump() wrote.
function Sim.parse(text)
  return evaluate('return ' .. text, {})
end

--- Loads a SavedVariables-style file (`Name = { ... }`) and returns the named global.
function Sim.loadFixture(path, name)
  local f = assert(io.open(path, 'rb'))
  local text = f:read('*a')
  f:close()
  local env = {}
  evaluate(text, env)
  return env[name]
end

return Sim
