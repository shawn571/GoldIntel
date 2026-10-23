-- GoldIntel / Platform / Money.lua                                      (Phase 1, task 1.4)
--
-- PURPOSE
--  The money signal that feeds the cash ledger (Requirements FR-LED-1).
--      Platform.Money() -> copper
--  Emits P_MONEY { copper = signed delta, gt = monotonic time, gap = true? }.
--
-- THE ONE RULE
--  The deltas emitted here, summed over any window, equal the real change of GetMoney()
--  over that window. Nothing is dropped and nothing is invented. The Reconciler (Phase 3)
--  relies on this to guarantee invariant 1 (Architecture section 3).
--
-- HOW
--  last = money at the previous emission. On PLAYER_MONEY: delta = GetMoney() - last.
--  Zero deltas are not emitted. The delta is computed from the live value, not from
--  event arguments, so coalesced or duplicated PLAYER_MONEY events cannot cause drift.
--
-- GAPS
--  If money changed while no PLAYER_MONEY event was seen (detected at
--  PLAYER_ENTERING_WORLD), the difference is emitted once with gap = true so downstream
--  code can tag it low-confidence instead of silently absorbing it into the next delta.
--
-- FATAL CONDITIONS (Decisions D-016)
--  GetMoney missing or PLAYER_MONEY not registrable disables the addon (capabilities
--  'money.get' and 'money.event').

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Money.lua')

local Money = {}
P.MoneyModule = Money
P.Register('Money', Money)

local last = nil
Money.stats = { events = 0, emitted = 0, zero = 0, gaps = 0, badReads = 0 }

--- Current copper, or nil plus a reason.
function Money.Get()
  local f = P.fn('GetMoney')
  if not f then return nil, 'GetMoney unavailable' end
  local ok, v = pcall(f)
  if not ok then return nil, 'GetMoney failed: ' .. tostring(v) end
  if P.IsSecret(v) then return nil, 'GetMoney returned a secret value' end
  if type(v) ~= 'number' or v ~= v or v < 0 then return nil, 'GetMoney returned an invalid value' end
  return math.floor(v)
end

--- Last balance this module has accounted for (nil before the baseline exists).
function Money.Last() return last end

local function emit(delta, isGap)
  local _, gt = P.Now()
  local payload = { copper = delta, gt = gt }
  if isGap then
    payload.gap = true
    Money.stats.gaps = Money.stats.gaps + 1
  end
  Money.stats.emitted = Money.stats.emitted + 1
  P.Events.Emit('P_MONEY', payload)
end

--- Sets the baseline. With emitGap, a difference to the previous balance is emitted as a gap.
function Money.Sync(emitGap)
  local now, err = Money.Get()
  if not now then
    Money.stats.badReads = Money.stats.badReads + 1
    P.Diag('error', 'Money', 'sync failed: ' .. tostring(err))
    return nil
  end
  if emitGap and last ~= nil and now ~= last then
    local delta = now - last
    last = now
    P.Diag('warn', 'Money', 'money changed without PLAYER_MONEY (gap of ' .. delta .. ' copper)')
    emit(delta, true)
  else
    last = now
  end
  return now
end

local function onMoney()
  Money.stats.events = Money.stats.events + 1
  local now, err = Money.Get()
  P.Events.ReportPayload('PLAYER_MONEY', now ~= nil, err)
  if not now then
    Money.stats.badReads = Money.stats.badReads + 1
    P.Diag('error', 'Money', 'PLAYER_MONEY with unreadable balance: ' .. tostring(err))
    return
  end
  if last == nil then
    -- Baseline missing (event before ready): adopt it; nothing can be attributed yet.
    last = now
    P.Diag('warn', 'Money', 'PLAYER_MONEY before baseline; baseline set to ' .. now)
    return
  end
  local delta = now - last
  if delta == 0 then
    Money.stats.zero = Money.stats.zero + 1
    return
  end
  last = now
  emit(delta, false)
end

Money.OnMoney = onMoney     -- exposed for tests

---------------------------------------------------------------------------
-- Wiring and capabilities
---------------------------------------------------------------------------

P.SetCap('money.get', P.fn('GetMoney') ~= nil, 'GetMoney')

local bound, bindErr = P.Events.Bind('PLAYER_MONEY', onMoney)
P.SetCap('money.event', bound, bound and 'PLAYER_MONEY' or bindErr)

P.Events.Bind('PLAYER_ENTERING_WORLD', function()
  Money.Sync(true)
end)

P.OnReady(function()
  Money.Sync(false)
end)

--- Test helper.
function Money.Reset()
  last = nil
  Money.stats = { events = 0, emitted = 0, zero = 0, gaps = 0, badReads = 0 }
end

-- Contract: Platform.Money() -> copper
P.Money = function() return Money.Get() end
