--[[
Tests / test_passive053.lua                 (0.5.3: user decisions of 2026-11-06 after the Ragefire Chasm run)

D-095 an item roll the player WON ("[Loot]: You won: [item]") is loot: value created, activity LOOT.
D-096 a group share line of N claims the 2..3 pending money changes that sum to exactly N (several corpses looted at
      once by different players are paid separately but printed as ONE share line).
Shapes are the live ones of 2026-11-05: the won line starts with a loot-history link and the item lands ~1.4 s later;
the share pieces arrive 0.1-0.9 s apart and the share line 0.1-0.5 s after the last piece.
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
  W.env.SlashCmdList.GOLDINTEL('collect on')
  W:advance(1)
  return W, P, ns
end

local function pay(W, d) W.state.money = W.state.money + d; W:fire('PLAYER_MONEY') end
local function item(W, id, sell)
  W.state.items[id] = { 'Item' .. id, 'link', 2, 1, 1, '', '', 1, '', 0, sell, 2, 5, 2, 0, 0, 0 }
  W.state.cached[id] = true
end
local function wonLine(id) return '|HlootHistory:228224258|h[Loot]|h: You won: |cnIQ2:|Hitem:' .. id .. '::::::::14:1486::1:1:12919:1:28:5244:::::|h[Birchwood Maul]|h|r' end
local function otherWonLine(id) return '|HlootHistory:1301235201|h[Loot]|h: Urazz Brightbone won: |cnIQ2:|Hitem:' .. id .. '::::::::11:1486:::::::::|h[Tigerseye]|h|r' end
local function share(n) return 'Your share of the loot is ' .. n .. ' Copper.' end
local function keepHas(W, text)
  local tr = W.env.GoldIntelCharDB and W.env.GoldIntelCharDB.trace
  for _, l in ipairs(tr and tr.keep or {}) do if l:find(text, 1, true) then return l end end
end
local function addToBag(W, id, slot)
  W.state.bags[0] = W.state.bags[0] or { size = 16 }
  W.state.bags[0][slot or 1] = { id, 1 }
  W:fire('BAG_UPDATE_DELAYED')
end
local function lastLot(ns) local o = ns.LotBook.Instance().s.open; return o[#o] end

---------------------------------------------------------------------------
-- D-095
---------------------------------------------------------------------------
T.describe('roll-won items are loot (D-095)', function()
  T.it('the live line shape is classified as won, another player\'s win as roll', function()
    local _, P = session()
    local C = P.ChatModule
    local kind, id = C.ClassifyLoot(wonLine(4570))
    T.eq(kind, 'won'); T.eq(id, 4570)
    T.eq((C.ClassifyLoot(otherWonLine(818))), 'roll')
    T.eq((C.ClassifyLoot('You won: |Hitem:4570::|h[x]|h')), 'won')
  end)

  T.it('the item that arrives 1.4 s after the line becomes a value-created loot lot, activity LOOT', function()
    local W, _, ns = session()
    item(W, 4570, 922)
    W.state.bags[0] = { size = 16 }; W:fire('BAG_UPDATE_DELAYED'); W:advance(3)     -- baseline
    W:fire('CHAT_MSG_LOOT', wonLine(4570)); W:advance(1.4)
    addToBag(W, 4570); W:advance(4)
    local lot = lastLot(ns)
    T.truthy(lot, 'a lot was created')
    T.eq(lot.itemID, 4570); T.eq(lot.src, 'loot'); T.truthy(lot.vc); T.eq(lot.valueEach, 922)
    T.eq(lot.origin.act, 'LOOT')
    T.eq(ns.ItemSources.Stats().rollWon, 1)
    T.eq(ns.ItemSources.Stats().how.loot, 1)
    T.truthy(keepHas(W, 'ITEM_WON item=4570'))
    T.truthy(keepHas(W, 'reason="roll won"'))
  end)

  T.it('another player\'s win does not make the next add loot', function()
    local W, _, ns = session()
    item(W, 818, 100)
    W.state.bags[0] = { size = 16 }; W:fire('BAG_UPDATE_DELAYED'); W:advance(3)
    W:fire('CHAT_MSG_LOOT', otherWonLine(818)); W:advance(1)
    addToBag(W, 818); W:advance(4)
    T.eq(ns.ItemSources.Stats().rollWon, 0)
    T.eq(ns.ItemSources.Stats().how.unexplained, 1)
  end)

  T.it('a different item arriving after a won line stays unexplained', function()
    local W, _, ns = session()
    item(W, 4570, 922); item(W, 3292, 203)
    W.state.bags[0] = { size = 16 }; W:fire('BAG_UPDATE_DELAYED'); W:advance(3)
    W:fire('CHAT_MSG_LOOT', wonLine(4570)); W:advance(1)
    addToBag(W, 3292); W:advance(4)
    T.eq(ns.ItemSources.Stats().how.unexplained, 1)
    T.falsy(ns.ItemSources.Stats().how.loot)
  end)

  T.it('the expectation is used once: the same item returning later (an equip swap) is unexplained', function()
    local W, _, ns = session()
    item(W, 4570, 922)
    W.state.bags[0] = { size = 16 }; W:fire('BAG_UPDATE_DELAYED'); W:advance(3)
    W:fire('CHAT_MSG_LOOT', wonLine(4570)); W:advance(1.4)
    addToBag(W, 4570); W:advance(4)
    W.state.bags[0][1] = nil; W:fire('BAG_UPDATE_DELAYED'); W:advance(3)        -- equipped
    addToBag(W, 4570, 2); W:advance(4)                                            -- back in the bags
    local st = ns.ItemSources.Stats()
    T.eq(st.how.loot, 1); T.eq(st.how.unexplained, 1)
  end)

  T.it('an item arriving long after the line is unexplained (the expectation expired)', function()
    local W, _, ns = session()
    item(W, 4570, 922)
    W.state.bags[0] = { size = 16 }; W:fire('BAG_UPDATE_DELAYED'); W:advance(3)
    W:fire('CHAT_MSG_LOOT', wonLine(4570)); W:advance(ns.ItemSources.LOOT_KEEP + ns.ItemSources.WAIT + 2)
    addToBag(W, 4570); W:advance(4)
    T.eq(ns.ItemSources.Stats().how.unexplained, 1)
  end)

  T.it('the cash ledger is untouched by a won item (AC-15)', function()
    local W, _, ns = session()
    item(W, 4570, 922)
    W.state.bags[0] = { size = 16 }; W:fire('BAG_UPDATE_DELAYED'); W:advance(3)
    W:fire('CHAT_MSG_LOOT', wonLine(4570)); W:advance(1.4)
    addToBag(W, 4570); W:advance(4)
    T.eq(#ns.Sources.Entries(), 0)
    T.eq(ns.Ledger.Check().difference, 0)
  end)
end)

---------------------------------------------------------------------------
-- D-096
---------------------------------------------------------------------------
T.describe('a share line claims the pieces that sum to it (D-096)', function()
  local function grouped(n) local W, P, ns = session(); W.state.group = { n = n }; W:advance(0.1); return W, P, ns end

  T.it('12 + 5 then "share 17": two loot entries, comp split, no OTHER, check 0', function()
    local W, _, ns = grouped(5)
    pay(W, 12); W:advance(0.74)
    pay(W, 5); W:advance(0.22)
    W:fire('CHAT_MSG_MONEY', share(17)); W:advance(3)
    local es = ns.Sources.Entries()
    T.eq(#es, 2)
    for _, e in ipairs(es) do T.eq(e.src, 'loot'); T.eq(e.conf, 'high'); T.eq(e.comp, 'split') end
    T.eq(es[1].copper + es[2].copper, 17)
    T.eq(ns.Sources.Stats().sources.chatSum, 1)
    T.eq(ns.Ledger.Check().difference, 0)
  end)

  T.it('three pieces (7 + 9 + 7 = 23) are claimed too', function()
    local W, _, ns = grouped(5)
    pay(W, 7); W:advance(0.3); pay(W, 9); W:advance(0.3); pay(W, 7); W:advance(0.3)
    W:fire('CHAT_MSG_MONEY', share(23)); W:advance(3)
    for _, e in ipairs(ns.Sources.Entries()) do T.eq(e.src, 'loot') end
    T.eq(#ns.Sources.Entries(), 3)
  end)

  T.it('a single delta equal to N uses the normal match (one entry)', function()
    local W, _, ns = grouped(3)
    pay(W, 17); W:advance(0.5)
    W:fire('CHAT_MSG_MONEY', share(17)); W:advance(3)
    local es = ns.Sources.Entries()
    T.eq(#es, 1); T.eq(es[1].src, 'loot'); T.eq(ns.Sources.Stats().sources.chatSum, 0)
  end)

  T.it('two different sets summing to N: ambiguous, nothing is claimed', function()
    local W, _, ns = grouped(5)
    pay(W, 5); W:advance(0.2); pay(W, 12); W:advance(0.2); pay(W, 12); W:advance(0.2)
    W:fire('CHAT_MSG_MONEY', share(17)); W:advance(3)
    local other = 0
    for _, e in ipairs(ns.Sources.Entries()) do if e.src == 'other' then other = other + 1 end end
    T.eq(other, 3); T.eq(ns.Sources.Stats().sources.chatSum, 0)
  end)

  T.it('pieces that do not sum to N stay OTHER', function()
    local W, _, ns = grouped(5)
    pay(W, 12); W:advance(0.3); pay(W, 4); W:advance(0.3)
    W:fire('CHAT_MSG_MONEY', share(17)); W:advance(3)
    for _, e in ipairs(ns.Sources.Entries()) do T.eq(e.src, 'other') end
  end)

  T.it('a solo "You loot N" line never claims several deltas (shares only)', function()
    local W, _, ns = session()
    pay(W, 12); W:advance(0.3); pay(W, 5); W:advance(0.3)
    W:fire('CHAT_MSG_MONEY', 'You loot 17 Copper'); W:advance(3)
    for _, e in ipairs(ns.Sources.Entries()) do T.eq(e.src, 'other') end
  end)

  T.it('pieces older than the wait are already OTHER and are not edited (no retroactive change)', function()
    local W, _, ns = grouped(5)
    pay(W, 12); W:advance(0.2); pay(W, 5); W:advance(ns.Sources.WAIT + 0.5)
    W:fire('CHAT_MSG_MONEY', share(17)); W:advance(3)
    for _, e in ipairs(ns.Sources.Entries()) do T.eq(e.src, 'other') end
  end)

  T.it('the pure Reconciler rule: refuses single, none and ambiguous; books one set exactly', function()
    local _, _, ns = session()
    local X = ns.Expectations.New()
    local got = {}
    local R = ns.Reconciler.New{ exp = X, sink = function(e) got[#got + 1] = e end }
    R:Begin(0)
    R:Money(12, 0.1); R:Money(5, 0.2)
    T.eq(select(2, R:ClaimPendingSum(17, { src = 'loot' })), 2)
    T.eq(#got, 2); T.eq(got[1].copper + got[2].copper, 17); T.eq(#R.pending, 0)
    R:Money(17, 0.3)
    T.eq(select(2, R:ClaimPendingSum(17, { src = 'loot' })), 'single')
    R:Tick(5)
    R:Money(3, 5.1)
    T.eq(select(2, R:ClaimPendingSum(9, { src = 'loot' })), 'nosum')
    local ok = R:Check()
    T.truthy(ok, 'entries still sum to the deltas')
  end)
end)

---------------------------------------------------------------------------
-- Mutation checks
---------------------------------------------------------------------------
local function rollScenario()
  local W, _, ns = session()
  item(W, 4570, 922)
  W.state.bags[0] = { size = 16 }; W:fire('BAG_UPDATE_DELAYED'); W:advance(3)
  W:fire('CHAT_MSG_LOOT', wonLine(4570)); W:advance(1.4)
  addToBag(W, 4570); W:advance(4)
  local lot = lastLot(ns)
  assert(lot and lot.itemID == 4570 and lot.src == 'loot' and lot.vc, 'won item not loot')
end

local function splitScenario()
  local W, _, ns = session(); W.state.group = { n = 5 }; W:advance(0.1)
  pay(W, 12); W:advance(0.74); pay(W, 5); W:advance(0.22)
  W:fire('CHAT_MSG_MONEY', share(17)); W:advance(3)
  for _, e in ipairs(ns.Sources.Entries()) do assert(e.src == 'loot', 'piece not claimed') end
end

local function ambiguityScenario()
  local W, _, ns = session(); W.state.group = { n = 5 }; W:advance(0.1)
  pay(W, 5); W:advance(0.2); pay(W, 12); W:advance(0.2); pay(W, 12); W:advance(0.2)
  W:fire('CHAT_MSG_MONEY', share(17)); W:advance(3)
  for _, e in ipairs(ns.Sources.Entries()) do assert(e.src == 'other', 'ambiguous set was claimed') end
end

local function mutant(path, a, b, scenario)
  local src = Loader.readFile(Loader.root .. '/' .. path)
  local i, j = src:find(a, 1, true)
  assert(i, 'anchor missing in ' .. path .. ': ' .. a)
  Loader.override = { [path] = src:sub(1, i - 1) .. b .. src:sub(j + 1) }
  local ok = pcall(scenario)
  Loader.override = nil
  return ok
end

T.describe('0.5.3 mutation checks', function()
  T.it('the real sources pass every 0.5.3 scenario', function()
    rollScenario(); splitScenario(); ambiguityScenario()
  end)
  local MUT = {
    { 'Platform/Chat.lua', 'live won line not recognised', " or text:find(': You won: ', 1, true)", "", rollScenario },
    { 'Platform/Chat.lua', 'won line not emitted', "    pcall(P.Events.Emit, 'P_LOOT_WON', { itemID = rec.itemID, qty = rec.qty or 1 })", "", rollScenario },
    { 'Collect/ItemSources.lua', 'won expectation not wired', "  P.On('P_LOOT_WON', guard(function(p) if active then onLootWon(p) end end))", "", rollScenario },
    { 'Collect/Sources.lua', 'share line does not claim pieces', "    local ok = R:ClaimPendingSum(n, { src = 'loot', ctx = 'loot', ref = ref, comp = 'split' })", "    local ok = false", splitScenario },
    { 'Collect/Reconciler.lua', 'ambiguity not refused', "  if #found > 1 then return false, 'ambiguous' end", "", ambiguityScenario },
    { 'Collect/Reconciler.lua', 'two-piece sets not searched', "    if pa.copper + pb.copper == n then found[#found + 1] = { idx[a], idx[b] } end", "", splitScenario },
  }
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[2], function()
      T.falsy(mutant(m[1], m[3], m[4], m[5]), 'the mutant passed: ' .. m[2])
    end)
  end
end)
