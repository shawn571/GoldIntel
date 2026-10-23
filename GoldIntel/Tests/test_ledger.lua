--[[
Tests / test_ledger.lua                       (Phase 3b-2 M3: Ledger/Ledger.lua, AC-9, AC-13, R-3b2-1)

Intervals, lastMoney, login gap, logout, mark/check, commands, and persistence across sessions
(every session ends in svsim.dump/parse, so only what the client could save carries over).
]]

local T = require('testlib')
local Fake = require('fake_wow')
local World = require('collectworld')
local Loader = require('loader')
local sim = require('svsim')

--- One play session over saved data. opts.money = balance at login; opts.override = replacement addon sources.
local function session(saved, opts)
  opts = opts or {}
  local W = Fake.new()
  World.extend(W)
  W.env.GoldIntelDB = saved and saved.account or nil
  W.env.GoldIntelCharDB = saved and saved.char or nil
  W.state.money = opts.money or (saved and saved.money) or 0
  Loader.override = opts.override
  local P, ns = Loader.load(W.env)
  Loader.override = nil
  W:login()
  local function run(text)
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL(text)
    return W:printedText()
  end
  return W, P, ns, run
end

local function save(W, logout)
  if logout ~= false then W:fire('PLAYER_LOGOUT') end
  return { account = sim.parse(sim.dump(W.env.GoldIntelDB)), char = sim.parse(sim.dump(W.env.GoldIntelCharDB)),
           money = W.state.money }
end

local function pay(W, delta) W.state.money = W.state.money + delta; W:fire('PLAYER_MONEY') end

local function charTable(ns) return ns.Store.Char() end

T.describe('ledger interval follows collect', function()
  T.it('is off after login; collect on begins it, collect off ends it', function()
    local W, _, ns, run = session(nil, { money = 5000 })
    T.falsy(ns.Ledger.IsOn())
    local out = run('collect on')
    T.truthy(out:find('ledger: interval started', 1, true), out)
    T.truthy(ns.Ledger.IsOn())
    pay(W, 100); W:advance(2)
    T.eq(ns.Cash.Count(), 1)
    run('collect off')
    T.falsy(ns.Ledger.IsOn())
    pay(W, 300); W:advance(2)
    T.eq(ns.Cash.Count(), 1, 'money while OFF is not recorded')
  end)

  T.it('a single-group collect does not start the ledger', function()
    local W, _, ns, run = session(nil, { money = 5000 })
    local out = run('collect on G1')
    T.falsy(ns.Ledger.IsOn())
    T.truthy(out:find('ledger: not started', 1, true), out)
    pay(W, 100); W:advance(2)
    T.eq(ns.Cash.Count(), 0)
  end)

  T.it('collect off turns pending money into OTHER immediately and counts the interval', function()
    local W, _, ns, run = session(nil, { money = 5000 })
    run('collect on')
    pay(W, 70)                                 -- still pending (no 1.0 s elapsed)
    T.eq(ns.Cash.Count(), 0)
    run('collect off')
    local e = ns.Cash.Last(1)[1]
    T.eq(e.src, 'other'); T.eq(e.copper, 70)
    local st = ns.Cash.Stats()
    T.eq(st.intervals, 1)
    T.eq(ns.Cash.Cumulative(), 70)
  end)

  T.it('ledger off keeps collect on but stops the interval; ledger on resumes', function()
    local W, _, ns, run = session(nil, { money = 5000 })
    run('collect on')
    run('ledger off')
    T.falsy(ns.Ledger.IsOn()); T.falsy(ns.Ledger.Switch())
    pay(W, 10); W:advance(2)
    T.eq(ns.Cash.Count(), 0)
    local out = run('ledger on')
    T.truthy(out:find('ledger: on', 1, true), out)
    T.truthy(ns.Ledger.IsOn())
    pay(W, 20); W:advance(2)
    T.eq(ns.Cash.Count(), 1)
    T.eq(ns.Cash.Cumulative(), 20)
  end)

  T.it('ledger on without collect only sets the switch', function()
    local _, _, ns, run = session(nil, { money = 5000 })
    local out = run('ledger on')
    T.truthy(out:find('starts with /gi collect on', 1, true), out)
    T.falsy(ns.Ledger.IsOn())
  end)

  T.it('collect stays OFF after a reload (new session)', function()
    local W, _, ns, run = session(nil, { money = 5000 })
    run('collect on'); pay(W, 5); W:advance(2)
    local saved = save(W)
    local W2, _, ns2 = session(saved)
    T.falsy(ns2.Ledger.IsOn())
    T.falsy(ns2.Collector.IsEnabled())
  end)
end)

T.describe('lastMoney', function()
  T.it('is written at begin, after each entry, at collect off and at logout', function()
    local W, _, ns, run = session(nil, { money = 5000 })
    T.eq(charTable(ns).lastMoney, 5000, 'first-run baseline')
    pay(W, 0)
    run('collect on')
    T.eq(charTable(ns).lastMoney, 5000)
    pay(W, 120); W:advance(2)
    T.eq(charTable(ns).lastMoney, 5120)
    run('collect off')
    pay(W, 40)                               -- off: not recorded, lastMoney stays at the last ledger knowledge
    T.eq(charTable(ns).lastMoney, 5120)
    W:fire('PLAYER_LOGOUT')
    T.eq(charTable(ns).lastMoney, 5160, 'logout stores the true balance')
  end)

  T.it('first run stores a baseline and creates no gap', function()
    local _, _, ns = session(nil, { money = 777 })
    T.eq(charTable(ns).lastMoney, 777)
    T.eq(ns.Cash.Count(), 0)
  end)
end)

T.describe('login gap (AC-13, R-3b2-1)', function()
  T.it('normal logout then login with the same balance: no gap', function()
    local W, _, ns, run = session(nil, { money = 1000 })
    run('collect on'); pay(W, 50); W:advance(2)
    local saved = save(W)
    local _, _, ns2 = session(saved)
    T.eq(ns2.Cash.Stats().gapCount, 0)
    T.eq(ns2.Cash.Count(), 1)
  end)

  T.it('money changed while collect was OFF in a saved session creates no gap and no entry', function()
    local W, _, ns, run = session(nil, { money = 1000 })
    run('collect on'); run('collect off')
    pay(W, 500); W:advance(2)
    local saved = save(W)
    local _, _, ns2 = session(saved)
    T.eq(ns2.Cash.Count(), 0); T.eq(ns2.Cash.Stats().gapCount, 0)
  end)

  T.it('a client crash (no logout) with a balance change creates one gap entry at the next login', function()
    local W, _, ns, run = session(nil, { money = 1000 })
    run('collect on'); pay(W, 50); W:advance(2)       -- entry written, lastMoney 1050
    W.state.money = 1300; W:fire('PLAYER_MONEY')      -- +250 never reaches an entry before the crash
    local saved = save(W, false)
    saved.money = 1300
    local W2, _, ns2 = session(saved)
    T.eq(ns2.Cash.Stats().gapCount, 1)
    local e = ns2.Cash.Last(1)[1]
    T.eq(e.src, 'other'); T.eq(e.comp, 'gap'); T.eq(e.copper, 250); T.eq(e.ctx, 'login')
    T.eq(ns2.Cash.Cumulative(), 300, 'cumulative is honest again: 50 + gap 250')
    T.eq(charTable(ns2).lastMoney, 1300)
  end)

  T.it('spending while the client was away produces a negative gap', function()
    local W, _, ns, run = session(nil, { money = 1000 })
    run('collect on'); pay(W, 10); W:advance(2)
    local saved = save(W, false)
    saved.money = 400
    local _, _, ns2 = session(saved)
    T.eq(ns2.Cash.Last(1)[1].copper, -610)
  end)

  T.it('a read-only store records no gap and writes nothing', function()
    local saved = { account = { schema = 99, meta = {}, ledger = {} }, char = { schema = 99, lastMoney = 1, lmv = 2 }, money = 50 }
    local before = sim.dump(saved.char)
    local _, _, ns2 = session(saved)
    T.falsy(ns2.Cash.Writable())
    T.eq(ns2.Cash.Count(), 0)
    T.eq(sim.dump(saved.char), before)
  end)
end)

T.describe('logout reads a zero balance (E-46)', function()
  T.it('stores the accounted balance, so the next login has no gap', function()
    local W, _, ns, run = session(nil, { money = 6293 })
    run('collect on'); pay(W, 40); W:advance(2)
    W.env.GetMoney = function() return 0 end          -- the real client during logout
    local saved = save(W)
    T.eq(saved.char.lastMoney, 6333); T.eq(saved.char.lmv, 2)
    saved.money = 6333
    local _, _, ns2 = session(saved)
    T.eq(ns2.Cash.Stats().gapCount, 0)
  end)

  T.it('a lastMoney written by 0.3.3 (no marker, value 0) re-baselines once without a gap', function()
    local saved = { account = nil, char = { schema = 2, lastMoney = 0 }, money = 6293 }
    local _, _, ns = session(saved)
    T.eq(ns.Cash.Stats().gapCount, 0); T.eq(ns.Cash.Count(), 0)
    T.eq(ns.Store.Char().lastMoney, 6293); T.eq(ns.Store.Char().lmv, 2)
  end)
end)

T.describe('logout', function()
  T.it('flushes a pending delta as OTHER and saves it with the interval counter', function()
    local W, _, ns, run = session(nil, { money = 100 })
    run('collect on'); pay(W, 33)
    local saved = save(W)
    local led = saved.account.ledger
    local key = next(led)
    T.eq(led[key].cash[1].c, 33); T.eq(led[key].cash[1].src, 'other')
    T.eq(led[key].quality.intervals, 1)
    T.eq(saved.char.lastMoney, 133)
  end)

  T.it('persists the unmatched counter of finished intervals', function()
    local W, _, ns, run = session(nil, { money = 100 })
    run('collect on')
    W:fire('QUEST_TURNED_IN', 5, 100, 40)            -- expectation that never gets money
    W:advance(3)
    run('collect off')
    local saved = save(W)
    local led = saved.account.ledger[next(saved.account.ledger)]
    T.eq(led.quality.unmatched, 1)
  end)
end)

T.describe('mark and check', function()
  T.it('difference is 0 over a mix of matched, window and pending money', function()
    local W, _, ns, run = session(nil, { money = 10000 })
    run('collect on')
    pay(W, 11); W:advance(2)
    local out = run('ledger mark')
    T.truthy(out:find('ledger mark set', 1, true), out)
    W:fire('MERCHANT_SHOW'); W:advance(1)
    pay(W, 60); W:advance(0.2); pay(W, -10); W:advance(0.2)
    W:fire('MERCHANT_CLOSED'); W:advance(0.3)
    pay(W, -777); W:advance(2)                         -- unexplained spending
    pay(W, 5)                                          -- still pending at check time
    local c = ns.Ledger.Check()
    T.eq(c.difference, 0, 'moved ' .. c.moved .. ' entries ' .. c.entries .. ' pending ' .. c.pending)
    T.eq(c.moved, 60 - 10 - 777 + 5)
    T.eq(c.pending, 5)
    out = run('ledger check')
    T.truthy(out:find('DIFFERENCE 0 copper (OK)', 1, true), out)
  end)

  T.it('detects a mismatch (balance moved but the event was not delivered)', function()
    local W, _, ns, run = session(nil, { money = 10000 })
    run('collect on'); run('ledger mark')
    W.state.money = W.state.money + 42                 -- no PLAYER_MONEY
    W:advance(2)
    local c = ns.Ledger.Check()
    T.eq(c.difference, 42); T.eq(c.unseen, 42)
    T.truthy(run('ledger check'):find('(MISMATCH)', 1, true))
  end)

  T.it('refuse without a mark or without an interval', function()
    local W, _, ns, run = session(nil, { money = 10 })
    T.truthy(run('ledger mark'):find('not on', 1, true))
    run('collect on')
    T.truthy(run('ledger check'):find('no mark', 1, true))
  end)
end)

T.describe('ledger commands', function()
  T.it('status, last and usage', function()
    local W, _, ns, run = session(nil, { money = 500 })
    local out = run('ledger')
    T.truthy(out:lower():find('ledger', 1, true), out)
    run('collect on'); pay(W, 25); W:advance(2)
    out = run('ledger last 5')
    T.truthy(out:find('#1', 1, true), out); T.truthy(out:find('other', 1, true), out)
    T.truthy(run('ledger bogus'):find('usage: /gi ledger', 1, true))
    T.truthy(run('ledger status'):find('OTHER', 1, true) or run('ledger status'):find('other', 1, true))
  end)

  T.it('/gi diag prints the ledger quality block first and still works without diagnostics', function()
    local W, _, ns, run = session(nil, { money = 500 })
    run('collect on'); pay(W, 25); W:advance(2)
    local out = run('diag')
    local a = out:lower():find('ledger', 1, true)
    T.truthy(a, out)
    T.truthy(out:find('gap', 1, true), out)
    T.truthy(out:lower():find('unmatched', 1, true), out)
  end)
end)

T.describe('runtime accounting invariant with real storage', function()
  T.it('saved cumulative equals the sum of every money delta across sessions (random run, small CAP/FOLD)', function()
    math.randomseed(77)
    local saved, expected = nil, 0
    local balance = 100000
    for s = 1, 6 do
      local W, _, ns, run = session(saved, { money = saved and saved.money or balance })
      ns.Cash.CAP, ns.Cash.FOLD = 25, 6
      run('collect on')
      for _ = 1, 60 do
        local d = math.random(-900, 900)
        if d ~= 0 then pay(W, d); expected = expected + d end
        W:advance(math.random() < 0.5 and 0.2 or 1.3)
      end
      if s == 3 then run('collect off'); pay(W, 1000); W:advance(2) end    -- off: neither recorded nor a gap
      saved = save(W, s ~= 4)                                              -- session 4 ends in a crash
      -- the crash loses the pending delta; the next login's gap entry brings the ledger back to the true figure
      local W2, _, ns2 = session(saved)
      T.eq(ns2.Cash.Cumulative(), expected, 'session ' .. s)
      saved = save(W2, true)
      saved.money = W2.state.money
      balance = W2.state.money
    end
  end)
end)
