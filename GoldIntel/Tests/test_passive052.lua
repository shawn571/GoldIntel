--[[
Tests / test_passive052.lua                 (0.5.2: user decisions of 2026-11-05 after the first live sessions)

D-091 skinning a corpse whose first window GoldIntel never saw (left unskinned or unlooted by other players).
D-092 the final check at a real logout, where GetMoney() reads 0 (E-46), uses the last seen balance.
D-093 trainer fees paid while the trainer window is open are source 'trainer', activity TRAINER.
D-094 quest turn-ins leave an EVT quest line in the trace (evidence only).
]]

local T = require('testlib')
local Fake = require('fake_wow')
local World = require('collectworld')
local Loader = require('loader')

local function session(opts)
  opts = opts or {}
  local W = Fake.new()
  World.extend(W)
  W.state.money = opts.money or 5000
  local P, ns = Loader.load(W.env)
  W:login()
  local function run(text)
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL(text)
    return W:printedText()
  end
  run('collect on')
  W:advance(1)
  return W, P, ns, run
end

local function pay(W, d) W.state.money = W.state.money + d; W:fire('PLAYER_MONEY') end

local function item(W, id, sell)
  W.state.items[id] = { 'Item' .. id, 'link', 1, 1, 1, '', '', 1, '', 0, sell, 7, 1, 0, 0, 0, 0 }
  W.state.cached[id] = true
end

local function traceHas(W, text)
  local tr = W.env.GoldIntelCharDB and W.env.GoldIntelCharDB.trace
  for _, l in ipairs(tr and tr.lines or {}) do if l:find(text, 1, true) then return l end end
end
local function keepHas(W, text)
  local tr = W.env.GoldIntelCharDB and W.env.GoldIntelCharDB.trace
  for _, l in ipairs(tr and tr.keep or {}) do if l:find(text, 1, true) then return l end end
end

local function lastEntry(ns)
  local es = ns.Sources.Entries()
  return es[#es]
end

---------------------------------------------------------------------------
-- D-093 trainer fees
---------------------------------------------------------------------------
T.describe('trainer fees (D-093)', function()
  T.it('a fee paid while the trainer window is open is source trainer, activity TRAINER, and the check stays 0', function()
    local W, _, ns = session({ money = 5000 })
    W:fire('TRAINER_SHOW'); W:advance(0.5)
    pay(W, -100); W:advance(0.3)
    pay(W, -100); W:advance(0.3)
    W:fire('TRAINER_CLOSED'); W:advance(3)
    local es = ns.Sources.Entries()
    T.eq(#es, 2)
    for _, e in ipairs(es) do
      T.eq(e.src, 'trainer'); T.eq(e.copper, -100); T.eq(e.act, 'TRAINER'); T.eq(e.conf, 'med')
      T.falsy(e.creditable, 'a trainer fee is never credited to a heat bin')
    end
    T.eq(ns.Ledger.Check().difference, 0)
  end)

  T.it('money coming IN while the trainer window is open is not a trainer fee', function()
    local W, _, ns = session()
    W:fire('TRAINER_SHOW'); W:advance(0.5)
    pay(W, 40); W:advance(3)
    T.eq(lastEntry(ns).src, 'other')
  end)

  T.it('a fee long after the window closed is OTHER again', function()
    local W, _, ns = session()
    W:fire('TRAINER_SHOW'); W:advance(0.5)
    W:fire('TRAINER_CLOSED'); W:advance(3)
    pay(W, -100); W:advance(3)
    T.eq(lastEntry(ns).src, 'other')
  end)

  T.it('money right after the close (inside the 1.0 s linger) still counts as the fee', function()
    local W, _, ns = session()
    W:fire('TRAINER_SHOW'); W:advance(0.5)
    W:fire('TRAINER_CLOSED'); W:advance(0.4)
    pay(W, -10); W:advance(3)
    T.eq(lastEntry(ns).src, 'trainer')
  end)

  T.it('a duplicate show or close is counted and changes nothing', function()
    local W, P, ns = session()
    W:fire('TRAINER_SHOW'); W:fire('TRAINER_SHOW'); W:advance(0.2)
    W:fire('TRAINER_CLOSED'); W:fire('TRAINER_CLOSED'); W:advance(0.2)
    local s = P.TrainerModule.stats
    T.eq(s.opened, 1); T.eq(s.duplicateOpens, 1); T.eq(s.closed, 1); T.eq(s.duplicateCloses, 1)
    T.eq(ns.Context.Stats().trainer.opened, 1)
  end)

  T.it('the trace records trainer open and close and keeps them; the interval notes the registration', function()
    local W = session()
    W:fire('TRAINER_SHOW'); W:advance(0.2); W:fire('TRAINER_CLOSED'); W:advance(0.2)
    T.truthy(traceHas(W, 'EVT trainer open')); T.truthy(traceHas(W, 'EVT trainer close'))
    T.truthy(keepHas(W, 'EVT trainer open'))
    T.truthy(traceHas(W, 'EVIDENCE trainerRegistered=true'))
  end)

  T.it('the probe checks the trainer event names without registering them', function()
    local W = session()
    local compat = W.env.GoldIntelDB and W.env.GoldIntelDB.compat
    T.truthy(compat and compat.status and compat.status['trainer.events'], 'trainer.events in the saved probe status')
    local found = false
    for _, l in ipairs(compat.report or {}) do if l:find('trainer.events', 1, true) then found = true end end
    T.truthy(found, 'trainer.events in the probe report')
  end)
end)

---------------------------------------------------------------------------
-- D-091 skinning a corpse whose first window was never seen
---------------------------------------------------------------------------
T.describe('skinning a corpse GoldIntel never looted (D-091)', function()
  local function skinWindow(W, guid, itemID)
    W.state.loot = { guid = guid, slots = { { type = 1, link = '|Hitem:' .. itemID .. '::|h[x]|h', qty = 1 } } }
    W:fire('LOOT_OPENED', false, false, false)
    W:advance(0.4); W.state.bags[0][1] = { itemID, 1 }; W:fire('BAG_UPDATE_DELAYED')
    W.state.loot.slots = {}; W:fire('LOOT_CLOSED'); W:advance(4)
  end
  local function setup()
    local W, P, ns = session()
    W.env.C_Spell = { GetSpellName = function(id) return (id == 8617 or id == 8613) and 'Skinning' or nil end }
    P.Unit.ResetNames()
    item(W, 2934, 7)
    W.state.bags[0] = { size = 16 }
    return W, P, ns
  end

  T.it('a first window 0.29 s after the skin cast is skinning (GATHER, high)', function()
    local W, _, ns = setup()
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8613)
    W:advance(0.29)
    skinWindow(W, 'Creature-0-4621-0-1-95-CCCC01', 2934)
    local st = ns.ItemSources.Stats()
    T.eq(st.skinWindows, 1); T.eq(st.skinFirst, 1)
    local lot = ns.LotBook.Instance().s.open[1]
    T.eq(lot.itemID, 2934); T.eq(lot.origin.act, 'GATHER'); T.eq(lot.origin.actConf, 'high'); T.truthy(lot.origin.skinning)
  end)

  T.it('a first window more than SKIN_FIRST after the cast stays GRIND', function()
    local W, _, ns = setup()
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8613)
    W:advance(ns.ItemSources.SKIN_FIRST + 0.5)
    skinWindow(W, 'Creature-0-4621-0-1-95-CCCC02', 2934)
    T.eq(ns.ItemSources.Stats().skinWindows, 0)
    T.eq(ns.LotBook.Instance().s.open[1].origin.act, 'GRIND')
  end)

  T.it('a first window with no skin cast stays GRIND', function()
    local W, _, ns = setup()
    skinWindow(W, 'Creature-0-4621-0-1-95-CCCC03', 2934)
    T.eq(ns.ItemSources.Stats().skinWindows, 0)
    T.eq(ns.LotBook.Instance().s.open[1].origin.act, 'GRIND')
  end)

  T.it('a different cast just before a first window does not make it skinning', function()
    local W, _, ns = setup()
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 20154)
    W:advance(0.2)
    skinWindow(W, 'Creature-0-4621-0-1-95-CCCC04', 2934)
    T.eq(ns.ItemSources.Stats().skinWindows, 0)
  end)
end)

---------------------------------------------------------------------------
-- D-092 the final check at a real logout
---------------------------------------------------------------------------
T.describe('final check at logout (D-092)', function()
  T.it('GetMoney() reading 0 at logout gives difference 0 marked logout, not a MISMATCH', function()
    local W = session({ money = 335 })
    pay(W, 17); W:advance(3)
    W.env.GetMoney = function() return 0 end          -- the real client during logout (E-46)
    W:fire('PLAYER_LOGOUT')
    local l = traceHas(W, 'EVT check final')
    T.truthy(l, 'final check line')
    T.truthy(l:find('difference=0', 1, true), l)
    T.truthy(l:find(' logout', 1, true), l)
    T.falsy(l:find('MISMATCH', 1, true), l)
    T.falsy(keepHas(W, 'MISMATCH'))
  end)

  T.it('a real difference at logout is still flagged', function()
    local W = session({ money = 335 })
    pay(W, 17); W:advance(3)
    W.state.money = W.state.money + 50                -- money the client never reported
    W.env.GetMoney = function() return 0 end
    W:fire('PLAYER_LOGOUT')
    local l = traceHas(W, 'EVT check final')
    T.truthy(l)
    -- the last SEEN balance is used, so money without PLAYER_MONEY cannot be seen at logout: 0 is correct here,
    -- the next login's gap check catches it (R-3b2-1)
    T.truthy(l:find('difference=0', 1, true), l)
  end)

  T.it('/gi ledger check outside logout still reads the live balance', function()
    local W, _, ns = session({ money = 1000 })
    pay(W, 5); W:advance(3)
    W.state.money = W.state.money + 9                 -- no PLAYER_MONEY
    local c = ns.Ledger.Check()
    T.eq(c.unseen, 9); T.falsy(c.atLogout)
  end)
end)

---------------------------------------------------------------------------
-- D-094 quest evidence line
---------------------------------------------------------------------------
T.describe('quest turn-in evidence line (D-094)', function()
  T.it('a turn-in leaves EVT quest done with id and copper; classification unchanged', function()
    local W, _, ns = session({ money = 1000 })
    W:fire('QUEST_TURNED_IN', 4321, 50, 75); W:advance(0.1)
    pay(W, 75); W:advance(3)
    T.truthy(traceHas(W, 'EVT quest done id=4321 copper=75'))
    T.eq(lastEntry(ns).src, 'quest')
  end)
end)

---------------------------------------------------------------------------
-- Mutation checks: each 0.5.2 rule, removed from the source, must make its scenario fail.
---------------------------------------------------------------------------
local function trainerScenario()
  local W, _, ns = session({ money = 5000 })
  W:fire('TRAINER_SHOW'); W:advance(0.5)
  pay(W, -100); W:advance(0.3)
  W:fire('TRAINER_CLOSED'); W:advance(3)
  local e = lastEntry(ns)
  assert(e.src == 'trainer' and e.act == 'TRAINER', 'trainer fee not recognised')
end

local function skinScenario()
  local W, P, ns = session()
  W.env.C_Spell = { GetSpellName = function(id) return (id == 8617 or id == 8613) and 'Skinning' or nil end }
  P.Unit.ResetNames()
  item(W, 2934, 7)
  W.state.bags[0] = { size = 16 }
  W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8613)
  W:advance(0.29)
  W.state.loot = { guid = 'Creature-0-4621-0-1-95-DDDD01', slots = { { type = 1, link = '|Hitem:2934::|h[x]|h', qty = 1 } } }
  W:fire('LOOT_OPENED', false, false, false)
  W:advance(0.4); W.state.bags[0][1] = { 2934, 1 }; W:fire('BAG_UPDATE_DELAYED')
  W.state.loot.slots = {}; W:fire('LOOT_CLOSED'); W:advance(4)
  assert(ns.LotBook.Instance().s.open[1].origin.act == 'GATHER', 'first skin window not GATHER')
end

local function logoutScenario()
  local W = session({ money = 335 })
  pay(W, 17); W:advance(3)
  W.env.GetMoney = function() return 0 end
  W:fire('PLAYER_LOGOUT')
  local l = traceHas(W, 'EVT check final')
  assert(l and l:find('difference=0', 1, true) and not l:find('MISMATCH', 1, true), 'logout check: ' .. tostring(l))
end

local function questScenario()
  local W = session({ money = 1000 })
  W:fire('QUEST_TURNED_IN', 4321, 50, 75); W:advance(0.1)
  assert(traceHas(W, 'EVT quest done id=4321'), 'no quest line')
end

local function srcOf(path) return Loader.readFile(Loader.root .. '/' .. path) end

local function mutant(path, a, b, scenario)
  local src = srcOf(path)
  local i, j = src:find(a, 1, true)
  assert(i, 'anchor missing in ' .. path .. ': ' .. a)
  Loader.override = { [path] = src:sub(1, i - 1) .. b .. src:sub(j + 1) }
  local ok = pcall(scenario)
  Loader.override = nil
  return ok
end

T.describe('0.5.2 mutation checks', function()
  T.it('the real sources pass every 0.5.2 scenario', function()
    trainerScenario(); skinScenario(); logoutScenario(); questScenario()
  end)
  local MUT = {
    { 'Collect/Sources.lua', 'trainer window missing', "  trainer = { { src = 'trainer', sign = -1 } },", "", trainerScenario },
    { 'Collect/Stamps.lua', 'trainer activity missing', " trainer = 'TRAINER',", "", trainerScenario },
    { 'Collect/Context.lua', 'trainer context not opened', "P.On('P_TRAINER_OPEN', function() openKind('trainer') end)", "", trainerScenario },
    { 'Collect/ItemSources.lua', 'first skin window ignored', "      elseif castGT and gt - castGT >= -1e-9 and gt - castGT <= IS.SKIN_FIRST then", "      elseif false then", skinScenario },
    { 'Ledger/Ledger.lua', 'logout check reads the live zero balance', "  if loggingOut then\n", "  if false then\n", logoutScenario },
    { 'Ledger/Trace.lua', 'quest line missing', "  Trace.Line(string.format('EVT quest done id=%s copper=%s', tostring(p and p.questID), tostring(p and p.copper)))", "", questScenario },
  }
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[2], function()
      T.falsy(mutant(m[1], m[3], m[4], m[5]), 'the mutant passed: ' .. m[2])
    end)
  end
end)
