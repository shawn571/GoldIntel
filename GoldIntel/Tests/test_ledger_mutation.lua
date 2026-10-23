--[[
Tests / test_ledger_mutation.lua            (Phase 3b-2 M3): deliberate bugs in Cash.lua and Ledger.lua must be caught.
One scenario suite over real sessions (including save/load); each mutant replaces a piece of source via Loader.override.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local World = require('collectworld')
local Loader = require('loader')
local sim = require('svsim')

local SRC = {
  ['Ledger/Cash.lua'] = Loader.readFile(Loader.root .. '/Ledger/Cash.lua'),
  ['Ledger/Ledger.lua'] = Loader.readFile(Loader.root .. '/Ledger/Ledger.lua'),
}

local function session(saved, money)
  local W = Fake.new()
  World.extend(W)
  W.env.GoldIntelDB = saved and saved.account or nil
  W.env.GoldIntelCharDB = saved and saved.char or nil
  W.state.money = money or (saved and saved.money) or 0
  local P, ns = Loader.load(W.env)
  W:login()
  local function run(text) W.printed = {}; W.env.SlashCmdList.GOLDINTEL(text); return W:printedText() end
  return W, P, ns, run
end
local function save(W, logout)
  if logout ~= false then W:fire('PLAYER_LOGOUT') end
  return { account = sim.parse(sim.dump(W.env.GoldIntelDB)), char = sim.parse(sim.dump(W.env.GoldIntelCharDB)), money = W.state.money }
end
local function pay(W, d) W.state.money = W.state.money + d; W:fire('PLAYER_MONEY') end
local function entry(W, c, extra)
  local e = { t = W.state.gt, copper = c, src = 'loot', conf = 'high', act = 'GRIND', actConf = 'medium', locConf = 'high' }
  for k, v in pairs(extra or {}) do e[k] = v end
  return e
end

local function scenarios()
  local fails = {}
  local function check(n, ok) if not ok then fails[#fails + 1] = n end end

  do -- ids, zero, immutability, interning, time
    local W, P, ns = session(nil, 100)
    ns.Ledger.OnCollectOff()
    local C = ns.Cash
    check('id1', C.Add(entry(W, 5, { loc = { mapID = 1, zone = 'Z' } })) == 1)
    check('id2', C.Add(entry(W, 6, { loc = { mapID = 1, zone = 'Z' } })) == 2)
    check('zero rejected', C.Add(entry(W, 0)) == nil)
    check('one place', #C.Ledger().locs == 1)
    local last = C.Last(1)[1]
    check('expanded', last and last.copper == 6 and last.loc and last.loc.zone == 'Z')
    local ut, gt = P.Now()
    C.Add(entry(W, 7, { t = gt - 30 }))
    check('time', C.Ledger().cash[3].t == math.floor(ut - 30 + 0.5))
    C.AddGap(-9, 'login')
    check('gap flag', C.Last(1)[1].comp == 'gap' and C.Stats().gapCount == 1)
  end

  do -- fold keeps everything
    local W, _, ns = session(nil, 100)
    ns.Ledger.OnCollectOff()
    local C = ns.Cash
    C.CAP, C.FOLD = 10, 4
    local sum = 0
    C.Add(entry(W, -4000, { src = 'other', comp = 'gap' })); sum = sum - 4000
    for i = 1, 30 do C.Add(entry(W, i, { src = i % 2 == 0 and 'other' or 'loot' })); sum = sum + i end
    check('cumulative kept', C.Cumulative() == sum)
    check('raw bounded', #C.Ledger().cash <= 10)
    local st = C.Stats()
    check('total count', st.total == 31)
    check('gap total kept', st.gapCount == 1 and st.gapValue == 4000)
    check('largest other kept', st.largestOther == 4000)
    check('share by value', math.abs(st.otherShareValue - (4000 + 240) / (4000 + 465)) < 1e-9)
  end

  do -- intervals, lastMoney, logout
    local W, _, ns, run = session(nil, 1000)
    run('collect on'); pay(W, 50); W:advance(2)
    check('lastMoney at entry', ns.Store.Char().lastMoney == 1050)
    pay(W, 8)                                         -- pending at logout
    local saved = save(W)
    local led = saved.account.ledger[next(saved.account.ledger)]
    check('logout flush', led and led.cash[2] and led.cash[2].c == 8)
    check('interval counted', led and led.quality.intervals == 1)
    check('lastMoney at logout', saved.char.lastMoney == 1058)
  end

  do -- collect off ends; money off not recorded; partial group
    local W, _, ns, run = session(nil, 1000)
    run('collect on'); pay(W, 5); run('collect off')
    check('off flush', ns.Cash.Count() == 1)
    pay(W, 300); W:advance(2)
    check('off not recorded', ns.Cash.Count() == 1)
    run('collect on G1')
    check('partial not started', not ns.Ledger.IsOn())
    local saved = save(W)                              -- money moved while OFF: logout stores the true balance
    check('logout lastMoney', saved.char.lastMoney == 1305)
    local _, _, ns2 = session(saved)
    check('no gap after an off period', ns2.Cash.Count() == 1)
  end

  do -- gaps: sign, first run, repeat after crash, off period
    local W, _, ns, run = session(nil, 1000)
    check('first run no gap', ns.Cash.Count() == 0)
    run('collect on'); pay(W, 10); W:advance(2)
    local saved = save(W, false); saved.money = 1500
    local W2, _, ns2 = session(saved)
    check('gap value', ns2.Cash.Count() == 2 and ns2.Cash.Last(1)[1].copper == 490)
    local saved2 = save(W2, false)                      -- crash again straight after the login gap
    local _, _, ns3 = session(saved2)
    check('no duplicate gap', ns3.Cash.Count() == 2)
  end

  do -- the client reads 0 during logout (E-46); a marker-less lastMoney is not trusted
    local W, _, ns, run = session(nil, 6293)
    run('collect on'); pay(W, 40); W:advance(2)
    W.env.GetMoney = function() return 0 end
    local saved = save(W)
    check('zero at logout', saved.char.lastMoney == 6333)
    saved.money = 6333
    local _, _, ns2 = session(saved)
    check('no gap after zero read', ns2.Cash.Stats().gapCount == 0)
    local old = { char = { schema = 2, lastMoney = 0 }, money = 500 }
    local _, _, ns3 = session(old)
    check('0.3.3 value re-baselined', ns3.Cash.Count() == 0 and ns3.Store.Char().lastMoney == 500)
  end

  do -- unmatched persisted
    local W, _, ns, run = session(nil, 100)
    run('collect on'); W:fire('QUEST_TURNED_IN', 5, 100, 40); W:advance(3); run('collect off')
    local saved = save(W)
    check('unmatched stored', saved.account.ledger[next(saved.account.ledger)].quality.unmatched == 1)
  end

  do -- read-only: no gap, no writes
    local saved = { account = { schema = 99, meta = {}, ledger = {} }, char = { schema = 99, lastMoney = 1, lmv = 2 }, money = 50 }
    local before = sim.dump(saved.char)
    local _, _, ns = session(saved)
    check('readonly untouched', sim.dump(saved.char) == before and ns.Cash.Count() == 0)
  end

  do -- check: pending and mismatch
    local W, _, ns, run = session(nil, 10000)
    run('collect on'); run('ledger mark')
    pay(W, 11); W:advance(2); pay(W, -4)
    local c = ns.Ledger.Check()
    check('check ok with pending', c and c.difference == 0 and c.pending == -4)
    W.state.money = W.state.money + 42
    c = ns.Ledger.Check()
    check('check mismatch', c and c.difference == 42)
  end
  do -- crash while a delta is still pending (M5: WAIT 2.0 s): lastMoney follows the ledger, the next login recovers it
    local W, _, ns, run = session(nil, 100000)
    run('collect on'); pay(W, 50); W:advance(1.0); pay(W, 30); W:advance(1.2)
    local saved = save(W, false)
    local _, _, ns2 = session(saved)
    check('crash pending recovered', ns2.Cash.Cumulative() == 80)
  end

  return fails
end

local function mutate(file, a, b, fn)
  local src = SRC[file]
  local i, j = src:find(a, 1, true)
  T.truthy(i, 'anchor missing: ' .. a)
  Loader.override = { [file] = src:sub(1, i - 1) .. b .. src:sub(j + 1) }
  local ok, res = pcall(fn)
  Loader.override = nil
  return ok, res
end

T.describe('Cash and Ledger scenario suite', function()
  T.it('passes on the real sources', function() T.eq(scenarios(), {}) end)
end)

T.describe('Cash and Ledger mutation checks', function()
  local C, L = 'Ledger/Cash.lua', 'Ledger/Ledger.lua'
  local MUT = {
    { C, 'fold drops copper totals', "s.n = s.n + 1; s.copper = s.copper + r.c;", "s.n = s.n + 1;" },
    { C, 'fold drops value totals', "s.val = s.val + mag(r.c)\n    if r.cp", "\n    if r.cp" },
    { C, 'fold forgets gap totals', "totals.gap.n = totals.gap.n + 1;", "" },
    { C, 'fold keeps records', "led.cash = kept", "" },
    { C, 'cumulative ignores totals', "for _, s in pairs(led.totals.src) do sum = sum + s.copper end", "" },
    { C, 'largest other not tracked', "if rec.src == 'other' and mag(rec.c) > led.largestOther then led.largestOther = mag(rec.c) end", "" },
    { C, 'id not advanced', "led.nextId = led.nextId + 1", "" },
    { C, 'zero accepted', "e.copper == 0 or ", "" },
    { C, 'time not converted', "ut - (gt - (e.t or gt))", "ut" },
    { C, 'gap flag lost', "comp = 'gap', ctx = ctx", "ctx = ctx" },
    { C, 'places not interned', "local i = idx[k]", "local i = nil" },
    { C, 'Last hands out stored records', "out[#out + 1] = Cash.Expand(led.cash[i], led, key)", "out[#out + 1] = led.cash[i]" },
    { L, 'lastMoney not refreshed per entry', "if id and c and c.lmv == 2 and type(c.lastMoney) == 'number' then setLastMoney(c.lastMoney + entry.copper)", "if false then" },
    { L, 'lastMoney follows the live balance (pending lost)', "setLastMoney(c.lastMoney + entry.copper)", "setLastMoney(P.MoneyModule.Last())" },
    { L, 'logout does not end the interval', "if GI.Sources.IsActive() then Ledger.End() end\n  if GI.Store.IsWritable() then", "if GI.Store.IsWritable() then" },
    { L, 'logout stores the live (zero) balance', "local v = P.MoneyModule.Last()\n    if not v then\n      local live = balance()\n      if live and live > 0 then v = live end\n    end", "local v = balance()" },
    { L, 'untrusted lastMoney creates a gap', "if c.lmv ~= 2 then setLastMoney(now); return 0 end", "" },
    { L, 'logout lastMoney missing', "if v then setLastMoney(v) end", "" },
    { L, 'gap sign flipped', "GI.Cash.AddGap(now - saved, 'login')", "GI.Cash.AddGap(saved - now, 'login')" },
    { L, 'first run creates a gap', "setLastMoney(now); return 0 end", "setLastMoney(now); GI.Cash.AddGap(now, 'login'); return 0 end" },
    { L, 'gap leaves lastMoney stale', "    setLastMoney(now)\n    return now - saved", "    return now - saved" },
    { L, 'gap written to a read-only store', "if not GI.Store.IsWritable() then return nil, 'store not writable' end", "" },
    { L, 'check ignores pending', "local pending = pendingSum() - mark.pending", "local pending = 0" },
    { L, 'check difference ignores pending', "difference = moved - entries - pending", "difference = moved - entries" },
    { L, 'unmatched not stored', "led.quality.unmatched = led.quality.unmatched + (s and s.unmatched or 0)", "" },
    { L, 'intervals not counted', "led.quality.intervals = led.quality.intervals + 1", "" },
    { L, 'partial collect starts the ledger', "if partial then", "if false then" },
    { L, 'collect off keeps the interval', "function Ledger.OnCollectOff()\n  if GI.Sources.IsActive() then Ledger.End() end", "function Ledger.OnCollectOff()" },
  }
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[2], function()
      local ok, fails = mutate(m[1], m[3], m[4], scenarios)
      T.truthy((not ok) or #fails > 0, 'survived: ' .. m[2])
    end)
  end
end)
