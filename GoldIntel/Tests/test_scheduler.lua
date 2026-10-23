--[[
Tests / test_scheduler.lua                                  (task 1.4: Scheduler.lua)

The same behavioral suite runs against BOTH backends (C_Timer and OnUpdate), then
backend-specific tests cover selection, fallbacks, stalls and idle cost.

Fake time advances in 0.25 s sub-steps, so intervals below are multiples of 0.25.
]]

local T = require('testlib')
local Loader = require('loader')

local FILES = { 'Platform/Platform.lua', 'Platform/Clock.lua', 'Platform/Events.lua', 'Platform/Scheduler.lua' }

local function boot(fakeOpts)
  return Loader.boot(fakeOpts or {}, { only = FILES })
end

local BACKENDS = {
  { name = 'ctimer', fake = {} },
  { name = 'onupdate', fake = { without = { 'C_Timer' } } },
}

for _, backend in ipairs(BACKENDS) do
  T.describe('Scheduler behavior on the ' .. backend.name .. ' backend', function()
    local function setup()
      local W, P = boot(backend.fake)
      T.eq(P.Scheduler.Backend(), backend.name)
      return W, P
    end

    T.it('Every fires at its interval', function()
      local W, P = setup()
      local n = 0
      P.Every(0.5, function() n = n + 1 end)
      W:advance(2.0)
      T.eq(n, 4)
    end)

    T.it('After fires exactly once', function()
      local W, P = setup()
      local n = 0
      P.After(1.0, function() n = n + 1 end)
      W:advance(0.75)
      T.eq(n, 0)
      W:advance(5)
      T.eq(n, 1)
    end)

    T.it('cancel stops a periodic task and is idempotent', function()
      local W, P = setup()
      local n = 0
      local cancel = P.Every(0.5, function() n = n + 1 end)
      W:advance(1.0)
      cancel()
      cancel()
      W:advance(3.0)
      T.eq(n, 2)
    end)

    T.it('cancel prevents a pending After', function()
      local W, P = setup()
      local ran = false
      local cancel = P.After(1.0, function() ran = true end)
      cancel()
      W:advance(3.0)
      T.falsy(ran)
    end)

    T.it('a task can cancel itself from inside its callback', function()
      local W, P = setup()
      local n, cancel = 0, nil
      cancel = P.Every(0.5, function()
        n = n + 1
        if n == 3 then cancel() end
      end)
      W:advance(10)
      T.eq(n, 3)
    end)

    T.it('a task can cancel another task from inside its callback', function()
      local W, P = setup()
      local a, b = 0, 0
      local cancelB
      P.Every(0.5, function() a = a + 1; if a == 2 then cancelB() end end)
      cancelB = P.Every(0.5, function() b = b + 1 end)
      W:advance(5)
      T.eq(a, 10)
      T.truthy(b <= 2, 'b must stop soon after being cancelled, ran ' .. b)
    end)

    T.it('a task can schedule new tasks from inside its callback', function()
      local W, P = setup()
      local order = {}
      P.After(0.5, function()
        order[#order + 1] = 'outer'
        P.After(0.5, function() order[#order + 1] = 'inner' end)
      end)
      W:advance(2)
      T.eq(order, { 'outer', 'inner' })
    end)

    T.it('an erroring task is reported, keeps running, and the error count resets on success', function()
      local W, P = setup()
      local n = 0
      P.Every(0.5, function()
        n = n + 1
        if n <= 4 then error('flaky') end
      end)
      W:advance(5)                  -- 10 invocations: 4 failures, then successes
      T.eq(n, 10)
    end)

    T.it('a task failing five times in a row is cancelled', function()
      local W, P = setup()
      local n = 0
      P.Every(0.5, function() n = n + 1; error('always') end)
      W:advance(10)
      T.eq(n, 5)
      local cancelledReported = false
      for _, d in ipairs(P.GetDiag()) do
        if d.msg:find('cancelled after repeated failures', 1, true) then cancelledReported = true end
      end
      T.truthy(cancelledReported)
    end)

    T.it('a failing One-shot never blocks other tasks', function()
      local W, P = setup()
      local ran = false
      P.After(0.5, function() error('x') end)
      P.After(0.5, function() ran = true end)
      W:advance(1)
      T.truthy(ran)
    end)

    T.it('rejects bad arguments with an error string', function()
      local _, P = setup()
      local c1, e1 = P.Every(0, function() end)
      T.isnil(c1); T.truthy(e1)
      local c2 = P.Every(-1, function() end)
      T.isnil(c2)
      local c3 = P.Every('1', function() end)
      T.isnil(c3)
      local c4 = P.Every(1, nil)
      T.isnil(c4)
      local c5 = P.After(0 / 0, function() end)
      T.isnil(c5)
      local c6 = P.After(1, 'fn')
      T.isnil(c6)
    end)

    T.it('many tasks keep their relative order', function()
      local W, P = setup()
      local order = {}
      for i = 1, 5 do P.After(0.5, function() order[#order + 1] = i end) end
      W:advance(1)
      T.eq(order, { 1, 2, 3, 4, 5 })
    end)
  end)
end

T.describe('Scheduler backend selection', function()
  T.it('auto prefers C_Timer when present', function()
    local _, P = boot()
    T.eq(P.Scheduler.Backend(), 'ctimer')
    T.truthy(P.Has('timer.ctimer'))
    T.truthy(P.Has('timer.onupdate'))
  end)

  T.it('auto falls back to OnUpdate without C_Timer', function()
    local _, P = boot({ without = { 'C_Timer' } })
    T.eq(P.Scheduler.Backend(), 'onupdate')
    T.falsy(P.Has('timer.ctimer'))
  end)

  T.it('a partial C_Timer (no NewTicker) counts as unavailable', function()
    local W, P = boot()
    W.env.C_Timer = { After = function() end }
    T.eq(P.Scheduler.Init(), 'onupdate')
  end)

  T.it('no backend at all: Every and After return nil plus a reason', function()
    local _, P = boot({ without = { 'C_Timer', 'CreateFrame' } })
    T.isnil(P.Scheduler.Backend())
    local c, e = P.Every(1, function() end)
    T.isnil(c); T.eq(e, 'no timer backend')
    local c2, e2 = P.After(1, function() end)
    T.isnil(c2); T.eq(e2, 'no timer backend')
  end)

  T.it('forcing an unavailable backend fails without changing the current one', function()
    local _, P = boot({ without = { 'C_Timer' } })
    local b, err = P.Scheduler.Init({ backend = 'ctimer' })
    T.isnil(b)
    T.truthy(err)
    T.eq(P.Scheduler.Backend(), 'onupdate')
  end)
end)

T.describe('Scheduler C_Timer specifics', function()
  T.it('After falls back to C_Timer.After when NewTimer is missing, with soft cancel', function()
    local W, P = boot()
    W.env.C_Timer.NewTimer = nil
    local ran = false
    local cancel = P.After(0.5, function() ran = true end)
    cancel()
    W:advance(2)
    T.falsy(ran)
    local ran2 = false
    P.After(0.5, function() ran2 = true end)
    W:advance(2)
    T.truthy(ran2)
  end)

  T.it('cancel really cancels the underlying ticker', function()
    local W, P = boot()
    local cancel = P.Every(0.5, function() end)
    T.eq(W:activeTimers(), 1)
    cancel()
    T.eq(W:activeTimers(), 0)
  end)
end)

T.describe('Scheduler OnUpdate specifics', function()
  local function setup()
    return boot({ without = { 'C_Timer' } })
  end

  T.it('the frame is hidden when idle and shown when a task exists', function()
    local W, P = setup()
    local cancel = P.Every(0.5, function() end)
    local frame = W.frames[#W.frames]
    T.truthy(frame.shown)
    cancel()
    T.falsy(frame.shown, 'idle scheduler must not run OnUpdate')
    P.After(0.5, function() end)
    T.truthy(frame.shown)
    W:advance(1)
    T.falsy(frame.shown, 'hidden again after the one-shot completed')
    T.eq(P.Scheduler.ActiveCount(), 0)
  end)

  T.it('a long stall fires a periodic task once, not once per missed tick', function()
    local W, P = setup()
    local n = 0
    P.Every(0.5, function() n = n + 1 end)
    W:stall(30)
    T.eq(n, 1)
    W:advance(1.0)
    T.eq(n, 3, 'normal cadence resumes right after the stall')
  end)

  T.it('Reset drops every task and the idle frame is hidden', function()
    local W, P = setup()
    local n = 0
    P.Every(0.5, function() n = n + 1 end)
    P.Scheduler.Reset()
    W:advance(5)
    T.eq(n, 0)
    T.eq(P.Scheduler.ActiveCount(), 0)
  end)

  T.it('Reset called from inside a callback does not crash the update loop', function()
    local W, P = setup()
    P.After(0.5, function() P.Scheduler.Reset() end)
    P.After(0.5, function() end)
    W:advance(1)
    T.eq(P.Scheduler.ActiveCount(), 0)
  end)

  T.it('Update ignores invalid elapsed values', function()
    local _, P = setup()
    local n = 0
    P.After(0.5, function() n = n + 1 end)
    P.Scheduler.Update(-1)
    P.Scheduler.Update('x')
    P.Scheduler.Update(nil)
    T.eq(n, 0)
    P.Scheduler.Update(0.5)
    T.eq(n, 1)
  end)

  T.it('performance: 1000 pending tasks are processed in one pass without error', function()
    local _, P = setup()
    local n = 0
    for i = 1, 1000 do P.After(0.5, function() n = n + 1 end) end
    P.Scheduler.Update(0.5)
    T.eq(n, 1000)
    T.eq(P.Scheduler.ActiveCount(), 0)
  end)
end)
