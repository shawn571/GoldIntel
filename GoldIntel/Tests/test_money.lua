--[[
Tests / test_money.lua                                      (task 1.4: Money.lua)

The central property (Money.lua header): the P_MONEY deltas, summed over any window,
equal the real change in GetMoney(). Also covers gaps, bad reads, fatal conditions.
]]

local T = require('testlib')
local Loader = require('loader')

local FILES = {
  'Platform/Platform.lua', 'Platform/Clock.lua', 'Platform/Events.lua', 'Platform/Money.lua',
}

local function boot(fakeOpts, money)
  local W, P = Loader.boot(fakeOpts or {}, { only = FILES })
  W.state.money = money or 10000
  local deltas, gaps = {}, {}
  P.On('P_MONEY', function(p)
    deltas[#deltas + 1] = p.copper
    if p.gap then gaps[#gaps + 1] = p.copper end
  end)
  return W, P, deltas, gaps
end

local function sum(list)
  local total = 0
  for _, v in ipairs(list) do total = total + v end
  return total
end

T.describe('Platform.Money', function()
  T.it('returns the current copper', function()
    local W, P = boot()
    W.state.money = 12345
    T.eq(P.Money(), 12345)
  end)

  T.it('returns nil plus a reason for unreadable values', function()
    local W, P = boot()
    W.state.money = 'lots'
    local v, err = P.Money()
    T.isnil(v)
    T.truthy(err)
    W.state.money = -5
    T.isnil((P.Money()))
    W.state.money = 0 / 0
    T.isnil((P.Money()))
  end)

  T.it('returns nil plus a reason when GetMoney raises', function()
    local W, P = boot()
    W.env.GetMoney = function() error('client error') end
    local v, err = P.Money()
    T.isnil(v)
    T.truthy(err:find('client error', 1, true))
  end)

  T.it('missing GetMoney is reported', function()
    local _, P = boot({ without = { 'GetMoney' } })
    local v, err = P.Money()
    T.isnil(v)
    T.eq(err, 'GetMoney unavailable')
    T.falsy(P.Has('money.get'))
  end)
end)

T.describe('12.0 secret values (defensive, unverified in the real client)', function()
  T.it('a secret GetMoney value is rejected without any arithmetic or comparison', function()
    local W, P = boot()
    W.env.issecretvalue = function(v) return v == 777 end
    W.state.money = 777
    local v, err = P.Money()
    T.isnil(v)
    T.truthy(err:find('secret', 1, true))
  end)

  T.it('PLAYER_MONEY with a secret balance emits nothing and recovers afterwards', function()
    local W, P, deltas = boot()
    W:login()
    W.env.issecretvalue = function(v) return v == 777 end
    W.state.money = 777
    W:fire('PLAYER_MONEY')
    T.eq(deltas, {})
    W.state.money = 10400
    W:fire('PLAYER_MONEY')
    T.eq(deltas, { 400 })
  end)
end)

T.describe('P_MONEY emission', function()
  T.it('emits the signed delta and a monotonic timestamp', function()
    local W, P = boot()
    local payloads = {}
    P.On('P_MONEY', function(p) payloads[#payloads + 1] = p end)
    W:login()
    W.state.money = 10500
    W.state.gt = 1234.5
    W:fire('PLAYER_MONEY')
    W.state.money = 10200
    W:fire('PLAYER_MONEY')
    T.eq(payloads[1].copper, 500)
    T.near(payloads[1].gt, 1234.5)
    T.eq(payloads[2].copper, -300)
    T.isnil(payloads[1].gap)
  end)

  T.it('does not emit zero deltas (duplicate PLAYER_MONEY events)', function()
    local W, _, deltas = boot()
    W:login()
    W.state.money = 10100
    W:fire('PLAYER_MONEY')
    W:fire('PLAYER_MONEY')
    W:fire('PLAYER_MONEY')
    T.eq(deltas, { 100 })
  end)

  T.it('computes the delta from the live balance, so coalesced events lose nothing', function()
    local W, _, deltas = boot()
    W:login()
    W.state.money = 10100
    W.state.money = 10350            -- two changes, only one event arrives
    W:fire('PLAYER_MONEY')
    T.eq(deltas, { 350 })
  end)

  T.it('PROPERTY: sum of deltas equals the real balance change over random sequences', function()
    local W, _, deltas = boot({}, 50000)
    W:login()
    local seed = 12345
    local function rand(n)           -- tiny LCG: deterministic across Lua versions
      seed = (seed * 1103515245 + 12345) % 2147483648
      return seed % n
    end
    local start = W.state.money
    for _ = 1, 500 do
      local change = rand(20001) - 10000
      if W.state.money + change < 0 then change = -W.state.money end
      W.state.money = W.state.money + change
      if rand(4) ~= 0 then W:fire('PLAYER_MONEY') end   -- 25% of events are "lost"
    end
    W:fire('PLAYER_MONEY')                               -- final event drains the remainder
    T.eq(sum(deltas), W.state.money - start)
  end)

  T.it('an unreadable balance emits nothing and keeps the baseline intact', function()
    local W, P, deltas = boot()
    W:login()
    W.state.money = 'garbage'
    W:fire('PLAYER_MONEY')
    T.eq(deltas, {})
    T.eq(P.MoneyModule.stats.badReads, 1)
    W.state.money = 10700
    W:fire('PLAYER_MONEY')
    T.eq(deltas, { 700 }, 'recovers with the correct delta')
  end)

  T.it('PLAYER_MONEY before the baseline adopts it silently with a warning', function()
    local W, P, deltas = boot()
    W.state.money = 777
    W:fire('PLAYER_MONEY')
    T.eq(deltas, {})
    T.eq(P.MoneyModule.Last(), 777)
    local warned = false
    for _, d in ipairs(P.GetDiag()) do
      if d.level == 'warn' and d.msg:find('before baseline', 1, true) then warned = true end
    end
    T.truthy(warned)
  end)

  T.it('statistics count events, zeros, and emissions', function()
    local W, P = boot()
    W:login()
    W.state.money = 10050
    W:fire('PLAYER_MONEY')
    W:fire('PLAYER_MONEY')
    local s = P.MoneyModule.stats
    T.eq(s.events, 2)
    T.eq(s.emitted, 1)
    T.eq(s.zero, 1)
  end)

  T.it('large copper values (thousands of gold) stay exact', function()
    local W, _, deltas = boot({}, 0)
    W:login()
    W.state.money = 250000 * 10000      -- 250,000 gold in copper
    W:fire('PLAYER_MONEY')
    T.eq(deltas, { 2500000000 })
  end)
end)

T.describe('gaps across loading screens', function()
  T.it('money that changed without a PLAYER_MONEY event is emitted once as a gap', function()
    local W, P, deltas, gaps = boot()
    W:login()
    W.state.money = 10400
    W:fire('PLAYER_ENTERING_WORLD')
    T.eq(deltas, { 400 })
    T.eq(gaps, { 400 })
    T.eq(P.MoneyModule.stats.gaps, 1)
    W:fire('PLAYER_MONEY')
    T.eq(deltas, { 400 }, 'no double count when the late event arrives')
  end)

  T.it('no gap is emitted when the balance did not change', function()
    local W, _, deltas = boot()
    W:login()
    W:fire('PLAYER_ENTERING_WORLD')
    T.eq(deltas, {})
  end)

  T.it('a normal delta arriving first prevents any gap', function()
    local W, _, deltas, gaps = boot()
    W:login()
    W.state.money = 10900
    W:fire('PLAYER_MONEY')
    W:fire('PLAYER_ENTERING_WORLD')
    T.eq(deltas, { 900 })
    T.eq(gaps, {})
  end)

  T.it('PROPERTY: gaps plus normal deltas still sum to the real change', function()
    local W, _, deltas = boot({}, 1000)
    W:login()
    local start = W.state.money
    W.state.money = 1500; W:fire('PLAYER_MONEY')
    W.state.money = 1200                      -- unseen change
    W:fire('PLAYER_ENTERING_WORLD')
    W.state.money = 5000; W:fire('PLAYER_MONEY')
    W.state.money = 4000                      -- unseen change
    W:fire('PLAYER_ENTERING_WORLD')
    T.eq(sum(deltas), W.state.money - start)
  end)

  T.it('Sync with an unreadable balance reports a diagnostic and returns nil', function()
    local W, P = boot()
    W.state.money = 'x'
    T.isnil((P.MoneyModule.Sync(false)))
    T.eq(P.GetDiag()[1].level, 'error')
  end)
end)

T.describe('capabilities and fatal conditions', function()
  T.it('normal client: both money capabilities are available', function()
    local _, P = boot()
    T.truthy(P.Has('money.get'))
    T.truthy(P.Has('money.event'))
  end)

  T.it('a client that rejects PLAYER_MONEY flags money.event as missing', function()
    local W = require('fake_wow').new()
    W.state.invalidEvents.PLAYER_MONEY = true
    local P = Loader.load(W.env, { only = FILES })
    T.falsy(P.Has('money.event'))
    P.SetCap('frame', true)
    T.falsy(P.CheckFatal())
    T.falsy(P.IsOperational())
    T.truthy(P.fatalReason:find('money.event', 1, true))
  end)

  T.it('after a fatal failure no P_MONEY is delivered', function()
    local W, P, deltas = boot()
    W:login()
    P.Fatal('money.get', 'test')
    W.state.money = 99999
    W:fire('PLAYER_MONEY')
    T.eq(deltas, {})
  end)

  T.it('ready sync sets the baseline without emitting', function()
    local W, P, deltas = boot()
    W.state.money = 4321
    W:fire('PLAYER_LOGIN')
    T.eq(P.MoneyModule.Last(), 4321)
    T.eq(deltas, {})
  end)
end)
