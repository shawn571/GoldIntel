-- GoldIntel / Platform / Perf.lua                                       (0.5.4, 3b-3 M4, D-097)
--
-- PURPOSE
--  Reads GoldIntel's own CPU and memory figures from the client for the M4 measurements (NFR-3: average CPU under
--  0.5 ms per frame, memory growth under 2 MB per hour). Read-only; never changes a setting.
--      Perf.Functions()  -> sorted names of the functions in C_AddOnProfiler (evidence; nil when the namespace is absent)
--      Perf.Metrics()    -> sorted names of Enum.AddOnProfilerMetric (nil when absent)
--      Perf.Sample()     -> { t, metrics = { [metricName] = number }, memKB = number|nil, luaKB = number,
--                             profilerEnabled = boolean|nil, why = string|nil }
-- Compatibility_Notes lists C_AddOnProfiler as present but its function names were never recorded (F1), so nothing
-- is assumed: every metric the enum offers is read for this addon with GetAddOnMetric, each call protected.
-- Memory: UpdateAddOnMemoryUsage + GetAddOnMemoryUsage(addon) in KB when both exist; luaKB is collectgarbage('count'),
-- the whole UI Lua heap (all addons), recorded only as context.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Perf.lua')

local Perf = {}
P.PerfModule = Perf
P.Register('Perf', Perf)

Perf.ADDON = 'GoldIntel'

local function sortedKeys(t, onlyFunctions)
  local out = {}
  for k, v in pairs(t) do
    if type(k) == 'string' and (not onlyFunctions or type(v) == 'function') then out[#out + 1] = k end
  end
  table.sort(out)
  return out
end

function Perf.Functions()
  local ns = P.env.C_AddOnProfiler
  if type(ns) ~= 'table' then return nil end
  return sortedKeys(ns, true)
end

local function metricEnum()
  local enum = P.env.Enum
  local m = type(enum) == 'table' and enum.AddOnProfilerMetric or nil
  return type(m) == 'table' and m or nil
end

function Perf.Metrics()
  local m = metricEnum()
  if not m then return nil end
  return sortedKeys(m, false)
end

function Perf.Sample()
  local _, gt = P.Now()
  local out = { t = gt, metrics = {} }
  local ns = P.env.C_AddOnProfiler
  if type(ns) ~= 'table' then
    out.why = 'C_AddOnProfiler missing'
  else
    if type(ns.IsEnabled) == 'function' then
      local ok, v = pcall(ns.IsEnabled)
      if ok then out.profilerEnabled = v and true or false end
    end
    local enum = metricEnum()
    if type(ns.GetAddOnMetric) ~= 'function' then
      out.why = 'GetAddOnMetric missing'
    elseif not enum then
      out.why = 'Enum.AddOnProfilerMetric missing'
    else
      for name, value in pairs(enum) do
        if type(name) == 'string' then
          local ok, v = pcall(ns.GetAddOnMetric, Perf.ADDON, value)
          if ok and type(v) == 'number' and not P.IsSecret(v) then out.metrics[name] = v end
        end
      end
    end
  end
  local env = P.env
  if type(env.UpdateAddOnMemoryUsage) == 'function' and type(env.GetAddOnMemoryUsage) == 'function' then
    pcall(env.UpdateAddOnMemoryUsage)
    local ok, kb = pcall(env.GetAddOnMemoryUsage, Perf.ADDON)
    if ok and type(kb) == 'number' then out.memKB = kb end
  end
  local okL, lua = pcall(collectgarbage, 'count')
  if okL and type(lua) == 'number' then out.luaKB = lua end
  return out
end

--- One-line text of a sample (trace and /gi perf). Metric values are printed with 4 decimals.
function Perf.Text(s)
  local parts = {}
  local names = sortedKeys(s.metrics or {}, false)
  for _, k in ipairs(names) do parts[#parts + 1] = string.format('%s=%.4f', k, s.metrics[k]) end
  local mem = s.memKB and string.format('memKB=%.0f', s.memKB) or 'memKB=n/a'
  local lua = s.luaKB and string.format('uiLuaKB=%.0f', s.luaKB) or ''
  local en = s.profilerEnabled == nil and '' or (' profiler=' .. tostring(s.profilerEnabled))
  local why = s.why and (' (' .. s.why .. ')') or ''
  return (#parts > 0 and table.concat(parts, ' ') or 'metrics=none') .. ' ' .. mem .. ' ' .. lua .. en .. why
end
