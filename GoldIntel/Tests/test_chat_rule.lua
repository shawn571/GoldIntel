--[[
Tests / test_chat_rule.lua                    (Phase 3b-2 M5, D-078 Addendum 2, evidence E-48 / E-49)

The coin chat line is an EXACT loot expectation. Scenarios use the measured shapes: the chat line arrives 0.5-1.0 s
AFTER the money change; a group of 2 splits C into floor/ceil; partner-looted corpses have no window.
Then deliberate bugs in Sources.lua / Chat.lua must be caught.
]]

local T = require('testlib')
local L = require('ledgerworld')
local Loader = require('loader')

local SELF = 'You loot %s'
local function es(ns) return ns.Sources.Entries() end
local function coinLoot(W, amounts, guid)
  local slots = {}
  for i, a in ipairs(amounts) do slots[i] = { type = 2, amount = a } end
  W.state.loot = { guid = guid or 'Creature-0-4621-0-1-95-AAAA', slots = slots }
  W:fire('LOOT_OPENED')
end
local function chat(W, text) W:fire('CHAT_MSG_MONEY', text) end
local function share(n) return 'Your share of the loot is ' .. n .. ' Copper.' end
local function group(W, n) W.state.group = { n = n } end
local function inv(ns)
  local ok, sd, se, ps = ns.Sources.Reconciler():Check()
  return ok
end

local function scenarios()
  local fails = {}
  local function check(n, ok) if not ok then fails[#fails + 1] = n end end

  do -- solo, window offers exactly the coin: the delta matches the window, the chat line is claimed, nothing doubles
    local W, _, ns = L.boot()
    coinLoot(W, { 2 }); W:advance(0.4); L.pay(W, 2); W:advance(0.2)
    W.state.lootShown = false; W:advance(0.5)
    chat(W, 'You loot 2 Copper'); W:advance(3.0)
    local e, st = es(ns), ns.Sources.Stats()
    check('solo one entry', #e == 1 and e[1].src == 'loot' and e[1].conf == 'high' and e[1].copper == 2)
    check('solo claimed', st.sources.chatClaimed == 1 and st.sources.chatExp == 0)
    check('solo unmatched 0', st.unmatched == 0)
    check('solo invariant', inv(ns))
    -- the chat line must not leave a ghost that later explains an unrelated 2 copper
    L.pay(W, 2); W:advance(2.5)
    check('no ghost', es(ns)[2] and es(ns)[2].src == 'other')
  end

  do -- group of 2, looter: window 11, share 6 (money first, chat 0.9 s later)
    local W, _, ns = L.boot()
    group(W, 2)
    coinLoot(W, { 11 }); W:advance(0.45); L.pay(W, 6); W:advance(0.03)
    W.state.lootShown = false; W:advance(0.87)
    chat(W, share(6)); W:advance(3.0)
    local e, st = es(ns), ns.Sources.Stats()
    check('split one entry', #e == 1 and e[1].src == 'loot' and e[1].conf == 'high' and e[1].copper == 6)
    check('split comp', e[1] and e[1].comp == 'split')
    check('split keeps creature stamp', e[1] and e[1].act == 'GRIND' and e[1].actConf == 'med')
    check('split window consumed', st.unmatched == 0 and st.sources.chatSplit == 1)
    check('split otherShare 0', st.otherShareValue == 0)
    check('split invariant', inv(ns) and st.sumDeltas == 6 and st.sumEntries == 6)
  end

  do -- partner-looted corpse: no window here at all
    local W, _, ns = L.boot()
    group(W, 2)
    L.pay(W, 4); W:advance(0.8)
    check('partner still pending', #es(ns) == 0 and ns.Sources.Reconciler():PendingSum() == 4)
    chat(W, share(4)); W:advance(0.3)
    local e = es(ns)[1]
    check('partner loot', e and e.src == 'loot' and e.conf == 'high' and e.copper == 4 and e.comp == 'split')
    check('partner activity', e and e.act == 'LOOT' and e.actConf == 'med' and e.creditable == false)
    check('partner unmatched 0', ns.Sources.Stats().unmatched == 0)
  end

  do -- group of 2, 1 copper is not split: window matches, the share line is claimed
    local W, _, ns = L.boot()
    group(W, 2)
    coinLoot(W, { 1 }); W:advance(0.5); L.pay(W, 1); W:advance(0.5); chat(W, share(1)); W:advance(3.0)
    local e = es(ns)
    check('1c one entry', #e == 1 and e[1].src == 'loot' and e[1].comp == nil)
    check('1c claimed', ns.Sources.Stats().sources.chatClaimed == 1)
  end

  do -- the chat line arrives later than the OTHER fallback: stays OTHER, counted, no edit, nothing left behind
    local W, _, ns = L.boot()
    group(W, 2)
    L.pay(W, 5); W:advance(2.3)
    check('written as other', es(ns)[1] and es(ns)[1].src == 'other')
    chat(W, share(5)); W:advance(0.3)
    local st = ns.Sources.Stats()
    check('late counted', st.sources.chatLate == 1 and st.sources.chatExp == 0)
    check('late unchanged', #es(ns) == 1 and es(ns)[1].src == 'other')
    L.pay(W, 5); W:advance(2.5)
    check('late no ghost', es(ns)[2] and es(ns)[2].src == 'other')
  end

  do -- text that is not "coin I received" creates nothing
    local W, P, ns = L.boot()
    group(W, 2)
    chat(W, 'Bob loots 5 Copper.')
    chat(W, 'You loot 5 Copper (3 Copper deposited to guild bank)')
    chat(W, 'You loot nothing')
    chat(W, { __secret = true })
    chat(W, 12)
    L.pay(W, 5); W:advance(2.6)
    check('ignored lines', ns.Sources.Stats().sources.chatLines == 0)
    check('ignored -> other', es(ns)[1] and es(ns)[1].src == 'other')
  end

  do -- the share fits no split of the window coin: still loot (the chat is exact), but the window is NOT consumed
    local W, _, ns = L.boot()
    group(W, 3)
    coinLoot(W, { 11 }); W:advance(0.5); L.pay(W, 9); W:advance(0.4); chat(W, share(9)); W:advance(0.1)
    W.state.lootShown = false; W:advance(3.0)
    local e, st = es(ns), ns.Sources.Stats()
    check('mismatch loot', #e == 1 and e[1].src == 'loot' and e[1].copper == 9)
    check('mismatch window unmatched', st.unmatched == 1 and st.sources.chatSplit == 0)
  end

  do -- chat before money (reverse order) still works
    local W, _, ns = L.boot()
    group(W, 2)
    chat(W, share(7)); W:advance(0.3); L.pay(W, 7); W:advance(0.3)
    check('reverse order', es(ns)[1] and es(ns)[1].src == 'loot' and es(ns)[1].copper == 7)
  end

  do -- an unmatched chat line expires after one second; it never explains a later delta
    local W, _, ns = L.boot()
    group(W, 2)
    chat(W, share(6)); W:advance(1.6); L.pay(W, 6); W:advance(2.6)
    check('chat ttl', es(ns)[1] and es(ns)[1].src == 'other')
    check('chat unmatched counted', ns.Sources.Stats().unmatched == 1)
  end

  do -- two coin lines, one coalesced money event
    local W, _, ns = L.boot()
    L.pay(W, 7); W:advance(0.6); chat(W, 'You loot 3 Copper'); W:advance(0.2); chat(W, 'You loot 4 Copper'); W:advance(0.3)
    local e = es(ns)
    check('combo', #e == 2 and e[1].src == 'loot' and e[2].src == 'loot' and e[1].copper + e[2].copper == 7)
  end

  do -- no signal, no classification: a plain positive delta in a group stays OTHER (no heuristics)
    local W, _, ns = L.boot()
    group(W, 2)
    L.pay(W, 4); W:advance(2.6)
    check('no heuristic', es(ns)[1] and es(ns)[1].src == 'other' and es(ns)[1].conf == 'low')
  end

  do -- the OTHER fallback waits 2.0 s: not before
    local W, _, ns = L.boot()
    L.pay(W, 4); W:advance(1.7)
    check('wait holds', #es(ns) == 0)
    W:advance(0.6)
    check('wait ends', #es(ns) == 1)
  end
  do -- group of 3 but one member is out of range: the coin is split two ways (user-confirmed), window still matched
    local W, _, ns = L.boot()
    group(W, 3)
    coinLoot(W, { 11 }); W:advance(0.5); L.pay(W, 6); W:advance(0.4); chat(W, share(6)); W:advance(0.1)
    W.state.lootShown = false; W:advance(3.0)
    local e, st = es(ns), ns.Sources.Stats()
    check('range 2-way', #e == 1 and e[1].src == 'loot' and e[1].act == 'GRIND' and e[1].comp == 'split')
    check('range 2-way window', st.unmatched == 0 and st.sources.chatSplit == 1)
  end

  do -- group of 3, all in range: a 3-way split of 11 is 3 or 4
    local W, _, ns = L.boot()
    group(W, 3)
    coinLoot(W, { 11 }); W:advance(0.5); L.pay(W, 4); W:advance(0.4); chat(W, share(4)); W:advance(0.1)
    W.state.lootShown = false; W:advance(3.0)
    check('range 3-way', es(ns)[1] and es(ns)[1].act == 'GRIND' and ns.Sources.Stats().unmatched == 0)
  end

  do -- one member far away looting alone gets the whole coin as a plain "You loot" line
    local W, _, ns = L.boot()
    group(W, 3)
    coinLoot(W, { 11 }); W:advance(0.5); L.pay(W, 11); W:advance(0.4); chat(W, 'You loot 11 Copper'); W:advance(3.0)
    check('far solo', #es(ns) == 1 and es(ns)[1].src == 'loot' and es(ns)[1].copper == 11 and ns.Sources.Stats().sources.chatClaimed == 1)
  end

  do -- chat before the money, window offers exactly that coin: the window matches, no second expectation
    local W, _, ns = L.boot()
    group(W, 2)
    coinLoot(W, { 1 }); W:advance(0.3); chat(W, share(1)); W:advance(0.2); L.pay(W, 1); W:advance(3.0)
    local st = ns.Sources.Stats()
    check('covered one entry', #es(ns) == 1 and es(ns)[1].src == 'loot')
    check('covered counted', st.sources.chatCovered == 1 and st.unmatched == 0)
  end

  do -- group size unreadable: the share is still loot (exact), the window is left alone
    local W, _, ns = L.boot()
    W.state.group = 'absent'
    coinLoot(W, { 11 }); W:advance(0.5); L.pay(W, 6); W:advance(0.4); chat(W, share(6)); W:advance(0.1)
    W.state.lootShown = false; W:advance(3.0)
    local st = ns.Sources.Stats()
    check('nogroup loot', #es(ns) == 1 and es(ns)[1].src == 'loot' and es(ns)[1].copper == 6)
    check('nogroup window kept', st.unmatched == 1 and st.sources.chatSplit == 0 and st.sources.handlerErrors == 0)
  end

  do -- an unclaimed loot entry of another amount is never claimed by a chat line
    local W, _, ns = L.boot()
    group(W, 2)
    coinLoot(W, { 2 }); W:advance(0.4); L.pay(W, 2); W:advance(0.3)
    W.state.lootShown = false; W:advance(0.3)
    L.pay(W, 4); W:advance(0.5); chat(W, share(4)); W:advance(3.0)
    local e = es(ns)
    check('other amount', #e == 2 and e[1].copper == 2 and e[2].src == 'loot' and e[2].copper == 4 and e[2].comp == 'split')
  end

  return fails
end

T.describe('chat-signal rule', function()
  T.it('all scenarios pass on the real sources', function() T.eq(scenarios(), {}) end)
end)

T.describe('coin chat parsing', function()
  local function P_()
    local _, P = L.boot()
    return P.ChatModule
  end
  T.it('classifies the two received-coin lines, English fallback', function()
    local C = P_()
    T.eq({ C.Classify('You loot 2 Copper') }, { 'self', 2 })
    T.eq({ C.Classify('Your share of the loot is 6 Copper.') }, { 'share', 6 })
    T.eq({ C.Classify('Your share of the loot is 1 Silver 5 Copper.') }, { 'share', 105 })
    T.eq({ C.Classify('You loot 2 Gold, 3 Silver, 4 Copper') }, { 'self', 20304 })
    -- wording reported by the user (not measured by us): comma separated, final period
    T.eq({ C.Classify('Your share of the loot is 22 Silver, 66 Copper.') }, { 'share', 2266 })
    T.eq({ C.Classify('Your share of the loot is 4 Gold, 22 Silver, 66 Copper.') }, { 'share', 42266 })
    T.eq({ C.Classify('Your share of the loot is 4 Gold.') }, { 'share', 40000 })
  end)
  T.it('refuses everything else', function()
    local C = P_()
    T.falsy(C.Classify('Bob loots 5 Copper.'))
    T.falsy(C.Classify('You loot 5 Copper (3 Copper deposited to guild bank)'))
    T.falsy(C.Classify('You loot nothing'))
    T.falsy(C.Classify('Your share of the loot is 6 Copper'))        -- no final period: not the client line
    T.falsy(C.Classify('Your share of the loot is 0 Copper.'))
    T.falsy(C.Classify(nil)); T.falsy(C.Classify(5))
  end)
  T.it('uses the client GlobalStrings when present', function()
    local W, P = L.boot()
    W.env.YOU_LOOT_MONEY = 'Vous recevez %s'
    W.env.LOOT_MONEY_SPLIT = 'Votre part du butin est de %s.'
    W.env.COPPER_AMOUNT = '%d cuivre'
    W.env.SILVER_AMOUNT = '%d argent'
    W.env.GOLD_AMOUNT = '%d or'
    T.eq({ P.ChatModule.Classify('Votre part du butin est de 3 argent 4 cuivre.') }, { 'share', 304 })
    T.eq({ P.ChatModule.Classify('Vous recevez 9 cuivre') }, { 'self', 9 })
    T.falsy(P.ChatModule.Classify('You loot 2 Copper'))
  end)
  T.it('emits P_LOOT_CHAT with the group size, nothing for other text', function()
    local W, P = L.boot()
    W.state.group = { n = 2 }
    local World = require('collectworld')
    local seen = World.capture(P, 'P_LOOT_CHAT')
    W:fire('CHAT_MSG_MONEY', 'Your share of the loot is 6 Copper.')
    W:fire('CHAT_MSG_MONEY', 'Bob loots 5 Copper.')
    T.eq(#seen, 1)
    T.eq(seen[1].payload, { copper = 6, kind = 'share', group = 2 })
  end)
end)

-- mutation checks ------------------------------------------------------------------------------------------------
local SRC = {
  ['Collect/Sources.lua'] = Loader.readFile(Loader.root .. '/Collect/Sources.lua'),
  ['Platform/Chat.lua'] = Loader.readFile(Loader.root .. '/Platform/Chat.lua'),
  ['Collect/Reconciler.lua'] = Loader.readFile(Loader.root .. '/Collect/Reconciler.lua'),
  ['Collect/Stamps.lua'] = Loader.readFile(Loader.root .. '/Collect/Stamps.lua'),
}
local function mutate(file, a, b)
  local src = SRC[file]
  local i, j = src:find(a, 1, true)
  T.truthy(i, 'anchor missing: ' .. a)
  Loader.override = { [file] = src:sub(1, i - 1) .. b .. src:sub(j + 1) }
  local ok, res = pcall(scenarios)
  Loader.override = nil
  return ok, res
end

T.describe('chat-signal rule mutation checks', function()
  local S, C = 'Collect/Sources.lua', 'Platform/Chat.lua'
  local MUT = {
    { S, 'chat handler not wired', "  P.On('P_LOOT_CHAT', guard(onLootChat))\n", "" },
    { S, 'claim disabled', "if r.e.src == 'loot' then\n        r.claimed = true", "if false then\n        r.claimed = true" },
    { S, 'late check disabled', "and r.e.src == 'other' and r.e.copper == n then", "and false then" },
    { S, 'covered check disabled', "  if covered then", "  if false then" },
    { S, 'split fit not checked', "if fits and (not best", "if (not best" },
    { S, 'floor only', "n == math.floor(e.copper / k) or n == math.ceil(e.copper / k)", "n == math.floor(e.copper / k)" },
    { S, 'only the full group size', "for k = 2, p.group do", "for k = p.group, p.group do" },
    { S, 'window consumed without a group size', "if p.kind == 'share' and type(p.group) == 'number' and p.group >= 2 and e.copper > n then", "if e.copper > n then" },
    { S, 'split comp dropped', "comp = p.kind == 'share' and 'split' or nil", "comp = nil" },
    { S, 'chat exp lives too long', "ttl = Sources.LINGER, ctx = 'loot',\n    ref = ref", "ttl = 5, ctx = 'loot',\n    ref = ref" },
    { S, 'split loses the creature stamp', "ref.sourceType = best.ref and best.ref.sourceType;", "" },
    { 'Collect/Stamps.lua', 'chat share not LOOT', "if not st and e.ref and e.ref.chat then return 'LOOT', 'med' end", "" },
    { 'Collect/Stamps.lua', 'chat share LOOT high', "return 'LOOT', 'med' end", "return 'LOOT', 'high' end" },
    { S, 'wait back to 1.0', "Sources.WAIT = 2.0", "Sources.WAIT = 1.0" },
    { S, 'wait not passed to the reconciler', "exp = X, wait = Sources.WAIT,", "exp = X," },
    { S, 'claim ignores the amount', "not r.claimed and r.e.copper == n then\n      if r.e.src == 'loot'", "not r.claimed then\n      if r.e.src == 'loot'" },
    { C, 'guild text accepted', "if left:find('[%w]') then return nil end", "" },
    { C, 'any text classified', "local kind, copper = Chat.Classify(rec.text)", "local kind, copper = 'self', Chat.ParseMoney(rec.text)" },
    { C, 'group size not sent', "group = groupSize() }", "group = nil }" },
    { 'Collect/Reconciler.lua', 'comp not carried to the entry', "ref = e.ref, settle = e.settle, comp = e.comp, exp = e.id })", "ref = e.ref, settle = e.settle, exp = e.id })" },
  }
  for _, m in ipairs(MUT) do
    local file, name, a, b = m[1], m[2], m[3], m[4]
    if file ~= S and file ~= C then name, a, b = m[2], m[3], m[4] end
    T.it('mutation is caught: ' .. name, function()
      local ok, fails = mutate(file, a, b)
      T.truthy((not ok) or #fails > 0, 'survived: ' .. name)
    end)
  end
end)
