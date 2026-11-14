--[[
Tests / test_integration.lua                                (Phase 1 exit test)

Loads the complete addon exactly as listed in GoldIntel.toc and plays a short session:
  login -> zone event -> ticks -> money changes -> level-up -> logout.
Also a one-hour soak test for leaks and error-free operation.
]]

local T = require('testlib')
local Loader = require('loader')

T.describe('Phase 1 exit test: full addon load', function()
  T.it('loads every TOC file without error and without leaking globals', function()
    local W, P = Loader.boot()
    T.truthy(P.VERSION)
    for _, name in ipairs({ 'Platform', 'Clock', 'Events', 'Scheduler', 'Unit', 'Map', 'Money', 'Probe' }) do
      T.truthy(P.modules[name], 'module not registered: ' .. name)
    end
    T.eq(P.CONTRACT_VERSION, '1.17.0')
    T.truthy(W.env.SlashCmdList.GOLDINTEL)
  end)

  T.it('plays a session and produces the normalized event stream in order', function()
    local W, P = Loader.boot()
    local log = {}
    local function record(name)
      P.On(name, function(p)
        if name == 'P_MONEY' then log[#log + 1] = name .. ':' .. p.copper
        elseif name == 'P_LEVEL' then log[#log + 1] = name .. ':' .. p.level
        elseif name == 'P_ZONE' then log[#log + 1] = name .. ':' .. tostring(p.loc.sub)
        elseif name == 'P_COMBAT' then log[#log + 1] = name .. ':' .. tostring(p.inCombat)
        else log[#log + 1] = name end
      end)
    end
    for _, name in ipairs({ 'P_MONEY', 'P_LEVEL', 'P_ZONE', 'P_COMBAT', 'P_LOGOUT' }) do record(name) end

    W.state.money = 100000
    W:login()
    W:advance(1.0)

    W.state.money = 100250
    W:fire('PLAYER_MONEY')                          -- loot
    W:fire('PLAYER_REGEN_DISABLED')
    W:fire('PLAYER_REGEN_ENABLED')
    W.state.sub = 'Razor Hill'
    W:fire('ZONE_CHANGED')
    W.state.money = 99900
    W:fire('PLAYER_MONEY')                          -- repair bill
    W:fire('PLAYER_LEVEL_UP', 13)
    W:fire('PLAYER_LOGOUT')

    T.eq(log, {
      'P_ZONE:Valley of Trials',
      'P_MONEY:250',
      'P_COMBAT:true',
      'P_COMBAT:false',
      'P_ZONE:Razor Hill',
      'P_MONEY:-350',
      'P_LEVEL:13',
      'P_LOGOUT',
    })
    T.truthy(P.IsOperational())
    T.eq(P.DiagCount(), 0, 'a clean session produces no diagnostics')
  end)

  T.it('persists the probe results at login', function()
    local W = Loader.boot()
    W:login()
    local compat = W.env.GoldIntelDB.compat
    T.truthy(compat.caps['money.event'])
    T.eq(compat.operational, true)
  end)

  T.it('two independent loads do not interfere', function()
    local W1, P1 = Loader.boot()
    local W2, P2 = Loader.boot()
    local n1, n2 = 0, 0
    P1.On('P_MONEY', function() n1 = n1 + 1 end)
    P2.On('P_MONEY', function() n2 = n2 + 1 end)
    W1:login(); W2:login()
    W1.state.money = 500
    W1:fire('PLAYER_MONEY')
    T.eq(n1, 1)
    T.eq(n2, 0)
  end)

  T.it('the money delta stream matches the ledger invariant across a full session with lost events', function()
    local W, P = Loader.boot()
    W.state.money = 5000
    W:login()
    local total = 0
    P.On('P_MONEY', function(p) total = total + p.copper end)
    local start = W.state.money
    for i = 1, 200 do
      W.state.money = W.state.money + ((i % 7) * 13) - ((i % 5) * 11)
      if i % 3 ~= 0 then W:fire('PLAYER_MONEY') end
      W:advance(0.25)
    end
    W:fire('PLAYER_ENTERING_WORLD')              -- drains anything the lost events left over
    T.eq(total, W.state.money - start)
  end)
end)

T.describe('event registration policy (D-025, rule C-6)', function()
  T.it('Phase 1 registers exactly the allowlisted events during a full session and a probe', function()
    local W, P = Loader.boot()
    W:login()
    W.env.SlashCmdList.GOLDINTEL('probe')
    P.Probe()
    local seen, list = {}, {}
    for _, e in ipairs(W.registerCalls) do
      if not seen[e] then seen[e] = true; list[#list + 1] = e end
    end
    table.sort(list)
    T.eq(list, { 'PLAYER_ENTERING_WORLD', 'PLAYER_LEAVING_WORLD', 'PLAYER_LEVEL_UP', 'PLAYER_LOGIN',
                 'PLAYER_LOGOUT', 'PLAYER_MONEY', 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED',
                 'SKILL_LINES_CHANGED', 'ZONE_CHANGED', 'ZONE_CHANGED_INDOORS', 'ZONE_CHANGED_NEW_AREA' })
  end)

  T.it('events that do not exist in the client (e.g. Classic-only ones) are skipped quietly', function()
    local W = require('fake_wow').new()
    W.state.invalidEvents.SKILL_LINES_CHANGED = true
    local P = Loader.load(W.env)
    W:login()
    T.truthy(P.IsOperational())
    T.falsy(P.Has('event.SKILL_LINES_CHANGED'))
    for _, e in ipairs(W.registerCalls) do T.neq(e, 'SKILL_LINES_CHANGED') end
  end)
end)

T.describe('soak: one simulated hour', function()
  T.it('runs 14,400 frames with ticks, no diagnostics, and no memory growth', function()
    local W, P = Loader.boot()
    local zones, ticks, tickTime = 0, 0, 0
    P.On('P_ZONE', function() zones = zones + 1 end)
    P.On('P_TICK', function(p) ticks = ticks + 1; tickTime = tickTime + p.dt end)
    W:login()

    collectgarbage('collect')
    local before = collectgarbage('count')

    for i = 1, 14400 do
      W:advance(0.25)
      if i % 400 == 0 then
        W.state.money = W.state.money + 137
        W:fire('PLAYER_MONEY')
      end
    end

    collectgarbage('collect')
    local after = collectgarbage('count')

    T.eq(ticks, 7200, 'a tick every 0.5 s for an hour')
    T.near(tickTime, 3600, 1e-3, 'tick dt sums to elapsed time')
    T.eq(zones, 1)
    T.eq(P.DiagCount(), 0)
    T.truthy(after - before < 200, 'retained memory grew by ' .. (after - before) .. ' KB')
  end)
end)
