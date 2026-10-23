--[[
Tests / test_clock.lua                                      (task 1.4: Clock.lua)

Edge cases: monotonic clamp, NaN/garbage readings, missing time sources, Since().
]]

local T = require('testlib')
local Loader = require('loader')

local FILES = { 'Platform/Platform.lua', 'Platform/Clock.lua' }

local function boot(fakeOpts)
  local W, P = Loader.boot(fakeOpts or {}, { only = FILES })
  return W, P
end

T.describe('Clock.Now', function()
  T.it('returns integer wall time and fractional monotonic time', function()
    local W, P = boot()
    W.state.time = 1700000000.9
    W.state.gt = 12.345
    local t, gt = P.Now()
    T.eq(t, 1700000000)
    T.near(gt, 12.345)
  end)

  T.it('clamps a backwards monotonic reading and counts the regression', function()
    local W, P = boot()
    W.state.gt = 100
    local _, a = P.Now()
    W.state.gt = 99.5
    local _, b = P.Now()
    T.near(a, 100)
    T.near(b, 100)
    T.eq(P.Clock.regressions, 1)
    W.state.gt = 101
    local _, c = P.Now()
    T.near(c, 101)
  end)

  T.it('rejects NaN and non-number readings', function()
    local W, P = boot()
    W.state.gt = 0 / 0
    local t, gt = P.Now()
    T.eq(t, 1700000000)
    T.near(gt, 1700000000, 1e-6, 'falls back to wall time')
    T.falsy(P.Has('clock.gettime'))
    W.state.time = 'oops'
    local t2 = P.Now()
    T.eq(t2, 0)
    T.falsy(P.Has('clock.time'))
  end)

  T.it('degrades when GetTime is missing', function()
    local _, P = boot({ without = { 'GetTime' } })
    local t, gt = P.Now()
    T.eq(gt, t)
    T.falsy(P.Has('clock.gettime'))
    T.truthy(P.CapNote('clock.gettime'))
  end)

  T.it('degrades when time is missing', function()
    local _, P = boot({ without = { 'time' } })
    local t = P.Now()
    T.eq(t, 0)
    T.falsy(P.Has('clock.time'))
  end)

  T.it('survives API functions that raise errors', function()
    local W, P = boot()
    W.env.GetTime = function() error('client exploded') end
    local _, gt = P.Now()
    T.truthy(type(gt) == 'number')
  end)

  T.it('is usable by Diag before any other module exists', function()
    local _, P = boot()
    P.Diag('info', 'T', 'hello')
    T.eq(P.GetDiag()[1].t, 1700000000)
  end)
end)

T.describe('Clock.Since', function()
  T.it('measures elapsed seconds and never goes negative', function()
    local W, P = boot()
    W.state.gt = 50
    local _, start = P.Now()
    W.state.gt = 52.5
    T.near(P.Clock.Since(start), 2.5)
    T.near(P.Clock.Since(1e9), 0, 1e-9, 'a start in the future yields 0')
  end)

  T.it('Reset forgets the clamp baseline', function()
    local W, P = boot()
    W.state.gt = 500
    P.Now()
    P.Clock.Reset()
    W.state.gt = 10
    local _, gt = P.Now()
    T.near(gt, 10)
    T.eq(P.Clock.regressions, 0)
  end)
end)
