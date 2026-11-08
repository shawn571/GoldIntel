--[[
Tests / test_perf054.lua                     (0.5.4, 3b-3 M4 measurement build, D-097)

Platform/Perf.lua reads GoldIntel's CPU and memory figures. The C_AddOnProfiler function names in Forever were never
recorded, so the module must read whatever the enum offers, survive a missing namespace or a failing call, change
nothing in the client, and store samples apart from the trace (begin, every CHECK_EVERY seconds, end).
]]

local T = require('testlib')
local Fake = require('fake_wow')
local World = require('collectworld')
local Loader = require('loader')

local function profiler(W, opts)
  opts = opts or {}
  local calls = {}
  W.env.Enum = W.env.Enum or {}
  W.env.Enum.AddOnProfilerMetric = { SessionAverageTime = 0, RecentAverageTime = 1, PeakTime = 3, CountTimeOver1Ms = 6 }
  W.env.C_AddOnProfiler = {
    IsEnabled = function() calls[#calls + 1] = 'IsEnabled'; return true end,
    GetAddOnMetric = function(name, metric)
      calls[#calls + 1] = 'GetAddOnMetric'
      assert(name == 'GoldIntel', 'asked for another addon: ' .. tostring(name))
      if opts.failMetric == metric then error('boom') end
      return ({ [0] = 0.0123, [1] = 0.0456, [3] = 1.75, [6] = 2 })[metric]
    end,
  }
  if opts.memory ~= false then
    W.env.UpdateAddOnMemoryUsage = function() calls[#calls + 1] = 'UpdateAddOnMemoryUsage' end
    W.env.GetAddOnMemoryUsage = function(name) calls[#calls + 1] = 'GetAddOnMemoryUsage'; return name == 'GoldIntel' and 2048.5 or 0 end
  end
  return calls
end

local function session(setup)
  local W = Fake.new()
  World.extend(W)
  W.state.money = 1000
  local calls = setup and setup(W) or nil
  local P, ns = Loader.load(W.env)
  W:login()
  local function run(text) W.printed = {}; W.env.SlashCmdList.GOLDINTEL(text); return W:printedText() end
  return W, P, ns, run, calls
end

local function samples(W)
  local c = W.env.GoldIntelCharDB
  return c and c.perf and c.perf.samples or {}
end
local function traceHas(W, text)
  local tr = W.env.GoldIntelCharDB and W.env.GoldIntelCharDB.trace
  for _, l in ipairs(tr and tr.lines or {}) do if l:find(text, 1, true) then return l end end
end

T.describe('Perf.Sample (0.5.4, M4)', function()
  T.it('reads every metric of the enum for GoldIntel and the addon memory', function()
    local _, P = session(function(W) return profiler(W) end)
    local s = P.PerfModule.Sample({ memory = true })
    T.eq(s.metrics.RecentAverageTime, 0.0456); T.eq(s.metrics.SessionAverageTime, 0.0123)
    T.eq(s.metrics.PeakTime, 1.75); T.eq(s.metrics.CountTimeOver1Ms, 2)
    T.eq(s.memKB, 2048.5); T.truthy(s.profilerEnabled); T.isnil(s.why)
    T.truthy(type(s.luaKB) == 'number')
    local text = P.PerfModule.Text(s)
    T.truthy(text:find('RecentAverageTime=0.0456', 1, true), text)
    T.truthy(text:find('memKB=2048', 1, true) or text:find('memKB=2049', 1, true), text)
    T.eq(P.PerfModule.Functions(), { 'GetAddOnMetric', 'IsEnabled' })
    T.eq(P.PerfModule.Metrics(), { 'CountTimeOver1Ms', 'PeakTime', 'RecentAverageTime', 'SessionAverageTime' })
  end)

  T.it('a missing profiler namespace is reported, nothing fails', function()
    local _, P = session(function(W) W.env.C_AddOnProfiler = nil end)
    local s = P.PerfModule.Sample()
    T.eq(s.why, 'C_AddOnProfiler missing'); T.isnil(next(s.metrics))
    T.isnil(P.PerfModule.Functions())
    T.truthy(P.PerfModule.Text(s):find('metrics=none', 1, true))
  end)

  T.it('one failing metric does not stop the others; no memory API means memKB n/a', function()
    local _, P = session(function(W) return profiler(W, { failMetric = 3, memory = false }) end)
    local s = P.PerfModule.Sample({ memory = true })
    T.isnil(s.metrics.PeakTime); T.eq(s.metrics.RecentAverageTime, 0.0456)
    T.isnil(s.memKB)
    T.truthy(P.PerfModule.Text(s):find('memKB=n/a', 1, true))
  end)

  T.it('is read-only: only query functions are called', function()
    local _, P, _, _, calls = session(function(W) return profiler(W) end)
    P.PerfModule.Sample()
    for _, c in ipairs(calls) do
      T.truthy(c == 'IsEnabled' or c == 'GetAddOnMetric' or c == 'UpdateAddOnMemoryUsage' or c == 'GetAddOnMemoryUsage', c)
    end
  end)
end)

T.describe('perf samples while recording (0.5.4, M4)', function()
  T.it('a sample at begin, every CHECK_EVERY seconds and at the end, stored apart from the trace', function()
    local W, _, ns, run = session(function(W) return profiler(W) end)
    ns.Trace.CHECK_EVERY = 5
    run('collect on'); W:advance(1)
    T.eq(#samples(W), 1); T.eq(samples(W)[1].why, 'begin')
    W:advance(11)
    T.eq(#samples(W), 3); T.eq(samples(W)[3].why, 'periodic')
    run('collect off')
    local S = samples(W)
    T.eq(S[#S].why, 'final'); T.eq(S[#S].m.RecentAverageTime, 0.0456); T.isnil(S[#S].memKB)   -- 0.5.6: CPU only
    local pl = traceHas(W, 'EVT perf periodic')
    T.truthy(pl and pl:find('RecentAverageTime=0.0456', 1, true), tostring(pl))
    T.truthy(traceHas(W, 'EVIDENCE profilerFunctions=GetAddOnMetric,IsEnabled'))
    T.truthy(traceHas(W, 'EVIDENCE profilerMetrics=CountTimeOver1Ms,PeakTime,RecentAverageTime,SessionAverageTime'))
    ns.Trace.CHECK_EVERY = 600
  end)

  T.it('the stored samples are capped at PERF_CAP (oldest dropped)', function()
    local W, _, ns, run = session(function(W) return profiler(W) end)
    ns.Trace.PERF_CAP = 4; ns.Trace.CHECK_EVERY = 1
    run('collect on'); W:advance(10)
    T.eq(#samples(W), 4); T.eq(samples(W)[4].why, 'periodic')
    ns.Trace.PERF_CAP = 500; ns.Trace.CHECK_EVERY = 600
  end)

  T.it('samples survive a save and reload of the character data', function()
    local sim = require('svsim')
    local W, _, _, run = session(function(W) return profiler(W) end)
    run('collect on'); W:advance(1)
    W:fire('PLAYER_LOGOUT')
    local char = sim.parse(sim.dump(W.env.GoldIntelCharDB))
    T.truthy(#char.perf.samples >= 2, 'begin and final samples persisted')
    T.eq(char.perf.samples[1].m.PeakTime, 1.75)
  end)

  T.it('/gi perf prints functions, metrics, the current sample and the stored count', function()
    local W, _, _, run = session(function(W) return profiler(W) end)
    run('collect on'); W:advance(1)
    local out = run('perf')
    T.truthy(out:find('profiler functions GetAddOnMetric, IsEnabled', 1, true), out)
    T.truthy(out:find('perf: now', 1, true) and out:find('RecentAverageTime=0.0456', 1, true), out)
    T.truthy(out:find('1 samples stored', 1, true), out)
  end)

  T.it('the cash ledger is identical with and without the profiler (evidence only)', function()
    local function play(withProfiler)
      local W, _, ns, run = session(withProfiler and function(W) return profiler(W) end or nil)
      ns.Trace.CHECK_EVERY = 2
      run('collect on'); W:advance(1)
      W.state.money = W.state.money + 25; W:fire('PLAYER_MONEY'); W:advance(5)
      ns.Trace.CHECK_EVERY = 600
      local out = {}
      for _, e in ipairs(ns.Sources.Entries()) do out[#out + 1] = e.src .. ' ' .. e.copper end
      return out
    end
    T.eq(play(true), play(false))
  end)
end)

T.describe('0.5.6: memory only on request (D-100)', function()
  local function count(calls, name) local n = 0 for _, c in ipairs(calls) do if c == name then n = n + 1 end end return n end

  T.it('an automatic sample reads CPU but never calls UpdateAddOnMemoryUsage', function()
    local _, P, _, _, calls = session(function(W) return profiler(W) end)
    local s = P.PerfModule.Sample()
    T.eq(s.metrics.RecentAverageTime, 0.0456); T.isnil(s.memKB); T.truthy(s.memSkipped)
    T.eq(count(calls, 'UpdateAddOnMemoryUsage'), 0)
    T.truthy(P.PerfModule.Text(s):find('memKB=skipped', 1, true))
  end)

  T.it('a whole recording (begin, periodic, final) never calls the memory functions; /gi perf calls them once', function()
    local W, _, ns, run, calls = session(function(W) return profiler(W) end)
    ns.Trace.CHECK_EVERY = 5
    run('collect on'); W:advance(21); run('collect off')
    ns.Trace.CHECK_EVERY = 600
    T.truthy(#samples(W) >= 5)
    T.eq(count(calls, 'UpdateAddOnMemoryUsage'), 0); T.eq(count(calls, 'GetAddOnMemoryUsage'), 0)
    local out = run('perf')
    T.eq(count(calls, 'UpdateAddOnMemoryUsage'), 1)
    T.truthy(out:find('memKB=2048', 1, true) or out:find('memKB=2049', 1, true), out)
  end)

  T.it('mutation is caught: reading memory in automatic samples again', function()
    local src = Loader.readFile(Loader.root .. '/Platform/Perf.lua')
    local a = "  if opts.memory and type(env.UpdateAddOnMemoryUsage) == 'function'"
    T.truthy(src:find(a, 1, true), 'anchor')
    Loader.override = { ['Platform/Perf.lua'] = (src:gsub(a:gsub('%p', '%%%0'), "  if type(env.UpdateAddOnMemoryUsage) == 'function'")) }
    local ok = pcall(function()
      local _, P, _, _, calls = session(function(W) return profiler(W) end)
      P.PerfModule.Sample()
      assert(count(calls, 'UpdateAddOnMemoryUsage') == 0, 'memory read in an automatic sample')
    end)
    Loader.override = nil
    T.falsy(ok, 'the mutant passed')
  end)
end)

