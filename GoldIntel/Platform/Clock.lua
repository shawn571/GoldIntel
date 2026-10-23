-- GoldIntel / Platform / Clock.lua                                      (Phase 1, task 1.4)
--
-- PURPOSE
--  Single source of time for the addon.
--    t   = wall clock, Unix seconds (integer)      -> persisted in records
--    gt  = monotonic seconds with fractions        -> durations, tick deltas
--
--  GetTime() never goes backwards in a healthy client, but this module clamps it
--  anyway so a bad reading can never produce a negative duration downstream.
--
-- CONTRACT: Platform.Now() -> t, gt          (Contracts.md F2)

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Clock.lua')

local Clock = {}
P.Clock = Clock
P.Register('Clock', Clock)

local lastGT = nil
local warnedNoGetTime, warnedNoTime = false, false

--- Number of times the raw monotonic reading went backwards (diagnostics/tests).
Clock.regressions = 0

local function readNumber(name)
  local f = P.env[name]
  if type(f) ~= 'function' then return nil end
  local ok, v = pcall(f)
  if ok and type(v) == 'number' and v == v then return v end   -- v == v rejects NaN
  return nil
end

--- Returns t (Unix seconds, integer) and gt (monotonic seconds, fractional).
function Clock.Now()
  local t = readNumber('time')
  local gt = readNumber('GetTime')

  if t == nil then
    if not warnedNoTime then
      warnedNoTime = true
      P.SetCap('clock.time', false, 'time() unavailable; wall clock reported as 0')
    end
    t = 0
  end
  t = math.floor(t)

  if gt == nil then
    if not warnedNoGetTime then
      warnedNoGetTime = true
      P.SetCap('clock.gettime', false, 'GetTime() unavailable; monotonic clock degraded to wall clock')
    end
    gt = t
  end

  if lastGT ~= nil and gt < lastGT then
    Clock.regressions = Clock.regressions + 1
    gt = lastGT
  end
  lastGT = gt
  return t, gt
end

--- Seconds elapsed since an earlier gt reading (never negative).
function Clock.Since(earlierGT)
  local _, gt = Clock.Now()
  local d = gt - (earlierGT or gt)
  if d < 0 then d = 0 end
  return d
end

--- Test helper: forget the clamp baseline.
function Clock.Reset()
  lastGT = nil
  Clock.regressions = 0
  warnedNoGetTime, warnedNoTime = false, false
end

P.Now = Clock.Now
