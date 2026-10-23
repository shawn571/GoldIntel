--[[
Tests / test_item_sources.lua          (Phase 3b-3 M2: Collect/ItemSources.lua, trace only)

Pure attribution rules, mutation checks, live wiring through the fake client, and the cash-isolation
requirement (AC-15): the cash entries are byte-identical with the item pipeline on and off.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local World = require('collectworld')
local Loader = require('loader')

local function boot()
  local W = Fake.new()
  World.extend(W)
  local P, ns = Loader.load(W.env)
  W:login()
  return W, P, ns
end

local function IS()
  local _, _, ns = boot()
  return ns.ItemSources
end

local function slot(id, left, extra)
  local t = { itemID = id, left = left, sourceType = 'creature' }
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end

local function find(list, dir, id)
  for _, d in ipairs(list) do if d.dir == dir and d.itemID == id then return d end end
end

T.describe('ItemSources.Attribute', function()
  T.it('loot window slots explain additions and consume their quantity', function()
    local S = IS()
    local facts = { loot = { slot(10, 2, { act = 'GRIND', actConf = 'med' }) } }
    local r = S.Attribute({ added = { [10] = 3 }, removed = {} }, facts)
    T.eq(#r, 2)
    T.eq(r[1].how, 'loot'); T.eq(r[1].qty, 2); T.eq(r[1].act, 'GRIND')
    T.eq(r[2].how, 'unexplained'); T.eq(r[2].qty, 1)
    T.eq(facts.loot[1].left, 0)
  end)

  T.it('item-source window gives disenchant materials', function()
    local S = IS()
    local r = S.Attribute({ added = { [7] = 1 }, removed = {} }, { loot = { slot(7, 1, { sourceType = 'item' }) } })
    T.eq(r[1].how, 'disenchantMat')
  end)

  T.it('additions without a loot slot: quest, vendor buy, mail, trade, unexplained', function()
    local S = IS()
    local function how(facts) return S.Attribute({ added = { [1] = 1 }, removed = {} }, facts)[1].how end
    T.eq(how({ quest = true }), 'quest')
    T.eq(how({ merchant = true, moneyNeg = 50 }), 'vendorBuy')
    T.eq(how({ merchant = true, moneyNeg = 0 }), 'unexplained')
    T.eq(how({ mail = true }), 'mail')
    T.eq(how({ trade = true }), 'trade')
    T.eq(how({}), 'unexplained')
  end)

  T.it('removals: vendor sale needs money in; quest; disenchant; trade; otherwise ignored', function()
    local S = IS()
    local function how(facts) return S.Attribute({ added = {}, removed = { [1] = 1 } }, facts)[1].how end
    T.eq(how({ merchant = true, moneyPos = 10 }), 'vendorSale')
    T.eq(how({ merchant = true, moneyPos = 0 }), 'ignored')
    T.eq(how({ quest = true }), 'questConsume')
    T.eq(how({ disenchant = true, loot = { slot(2, 1, { sourceType = 'item' }) } }), 'disenchantSrc')
    T.eq(how({ disenchant = true }), 'ignored')
    T.eq(how({ trade = true }), 'tradeOut')
    T.eq(how({}), 'ignored')
  end)

  T.it('is deterministic by item id and handles nil facts', function()
    local S = IS()
    local r = S.Attribute({ added = { [5] = 1, [3] = 1 }, removed = { [9] = 1, [2] = 1 } })
    T.eq({ r[1].itemID, r[2].itemID, r[3].itemID, r[4].itemID }, { 3, 5, 2, 9 })
  end)
end)

T.describe('ItemSources mutation checks', function()
  local f = io.open('../Collect/ItemSources.lua', 'r')
  local SRC = f:read('*a'); f:close()
  local MUT = {
    { 'loot qty not consumed', 'e.left = e.left - n', '' },
    { 'sale without money', "facts.merchant and (facts.moneyPos or 0) > 0", 'facts.merchant' },
    { 'buy without money', "facts.merchant and (facts.moneyNeg or 0) > 0", 'facts.merchant' },
    { 'disenchant without window', "facts.disenchant and hasItemWindow", 'facts.disenchant' },
    { 'quest after trade', "if facts.quest then how, reason = 'quest'", "if facts.trade then how, reason = 'quest'" },
    { 'item window is loot', "e.sourceType == 'item' and 'disenchantMat' or 'loot'", "'loot'" },
    { 'unexplained hidden', "how, reason = 'unexplained'", "how, reason = 'ignored'" },
  }
  local function scenarios(S)
    local fails = 0
    local function chk(c) if not c then fails = fails + 1 end end
    local facts = { loot = { slot(10, 1) } }
    local r = S.Attribute({ added = { [10] = 2 }, removed = {} }, facts)
    chk(#r == 2 and r[1].qty == 1 and r[2].how == 'unexplained')
    r = S.Attribute({ added = {}, removed = { [1] = 1 } }, { merchant = true, moneyPos = 0 })
    chk(r[1].how == 'ignored')
    r = S.Attribute({ added = {}, removed = { [1] = 1 } }, { merchant = true, moneyPos = 5 })
    chk(r[1].how == 'vendorSale')
    r = S.Attribute({ added = { [1] = 1 }, removed = {} }, { merchant = true, moneyNeg = 0 })
    chk(r[1].how == 'unexplained')
    r = S.Attribute({ added = {}, removed = { [1] = 1 } }, { disenchant = true })
    chk(r[1].how == 'ignored')
    r = S.Attribute({ added = { [1] = 1 }, removed = {} }, { quest = true, trade = true })
    chk(r[1].how == 'quest')
    r = S.Attribute({ added = { [1] = 1 }, removed = {} }, { loot = { slot(1, 1, { sourceType = 'item' }) } })
    chk(r[1].how == 'disenchantMat')
    return fails == 0
  end
  local function loadWith(src)
    local chunk = assert(load(src, '=ItemSources', 't'))
    local ns = { Platform = {}, Context = {} }
    local ok, S = pcall(chunk, 'GoldIntel', ns)
    return ns.ItemSources or S
  end
  T.it('baseline scenarios pass on the real source', function()
    T.truthy(scenarios(IS()))
  end)
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[1], function()
      local i, j = SRC:find(m[2], 1, true)
      T.truthy(i, 'anchor missing: ' .. m[1])
      local S = loadWith(SRC:sub(1, i - 1) .. m[3] .. SRC:sub(j + 1))
      local ok, res = pcall(scenarios, S)
      T.truthy((not ok) or res == false, 'survived: ' .. m[1])
    end)
  end
end)

T.describe('ItemSources isolation (AC-15)', function()
  T.it('source references no cash, reconciler, expectation or source modules', function()
    local f = io.open('../Collect/ItemSources.lua', 'r')
    local src = f:read('*a'); f:close()
    src = src:gsub('%-%-[^\n]*', '')
    for _, bad in ipairs({ 'GI.Cash', 'GI.Reconciler', 'GI.Expectations', 'GI.Sources', 'Cash%.', 'Reconciler' }) do
      T.falsy(src:find(bad), bad)
    end
  end)
end)

-- A scripted evening: loot with coin, an item, a vendor sale, a quest and a purchase.
local function evening(lotsOn)
  local W, P, ns = boot()
  W.state.money = 1000
  W.state.bags[0] = { size = 16 }
  W.state.items[100] = { 'Linen', 'link', 1, 1, 1, '', '', 1, '', 0, 13, 7, 1, 1, 0, 0, 0 }
  W.state.cached[100] = true
  local run = function(t) W.printed = {}; W.env.SlashCmdList.GOLDINTEL(t); return W:printedText() end
  if not lotsOn then run('lots off') end
  run('collect on')
  W:advance(1)
  -- loot a creature: coin + item
  W.state.loot = { guid = 'Creature-0-4621-0-1-95-AAAA', slots = { { type = 2, amount = 30 }, { type = 1, link = '|Hitem:100::|h[Linen]|h', qty = 2 } } }
  W:fire('LOOT_OPENED', false, false, false)
  W.state.money = W.state.money + 30; W:fire('PLAYER_MONEY')
  W.state.bags[0][1] = { 100, 2 }
  W:fire('BAG_UPDATE_DELAYED')
  W.state.loot.slots = {}
  W:fire('LOOT_CLOSED')
  W:advance(3)
  -- vendor sale
  W:fire('MERCHANT_SHOW'); W:advance(0.3)
  W.state.bags[0][1] = nil
  W:fire('BAG_UPDATE_DELAYED')
  W.state.money = W.state.money + 8; W:fire('PLAYER_MONEY')
  W:advance(0.3)
  W:fire('MERCHANT_CLOSED'); W:advance(4)
  -- unexplained money
  W.state.money = W.state.money + 55; W:fire('PLAYER_MONEY'); W:advance(3)
  local entries = ns.Cash.Last(100)
  local parts = {}
  for _, e in ipairs(entries) do
    local keys = {}
    for k in pairs(e) do if type(e[k]) ~= 'table' then keys[#keys + 1] = k end end
    table.sort(keys)
    local row = {}
    for _, k in ipairs(keys) do row[#row + 1] = k .. '=' .. tostring(e[k]) end
    parts[#parts + 1] = table.concat(row, ',')
  end
  local check = run('ledger check')
  return table.concat(parts, '\n'), check, ns
end

T.describe('cash isolation with the item pipeline active', function()
  T.it('cash entries are byte-identical with lots on and off', function()
    local on, checkOn, nsOn = evening(true)
    local off, checkOff = evening(false)
    T.truthy(#on > 0)
    T.eq(on, off)
    T.eq(checkOn, checkOff)
    local st = nsOn.ItemSources.Stats()
    T.truthy(st.settles >= 1, 'item pipeline did observe the bags')
  end)

  T.it('lots on records item decisions', function()
    local _, _, ns = evening(true)
    local st = ns.ItemSources.Stats()
    T.eq(st.how.loot, 2)
    T.eq(st.how.vendorSale, 2)
  end)

  T.it('lots off leaves the pipeline inactive and the lots command answers', function()
    local W, _, ns = boot()
    W.env.SlashCmdList.GOLDINTEL('lots off')
    W.env.SlashCmdList.GOLDINTEL('collect on')
    T.falsy(ns.ItemSources.IsActive())
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('lots check')
    T.truthy(W:printedText():find('lots check', 1, true))
  end)
end)

T.describe('M2 evidence recorders', function()
  T.it('ClassifyLoot reads item id and quantity and never fails on odd input', function()
    local _, P = boot()
    local C = P.ChatModule
    local k, id, q = C.ClassifyLoot('You receive loot: |cffffffff|Hitem:2589::::|h[Linen Cloth]|h|rx3.')
    T.eq(id, 2589); T.eq(q, 3); T.truthy(k)
    T.eq(select(2, C.ClassifyLoot('You receive loot: |Hitem:2589::|h[X]|h.')), 2589)
    T.eq((C.ClassifyLoot(nil)), 'unknown')
    T.eq((C.ClassifyLoot(42)), 'unknown')
  end)

  T.it('CHAT_MSG_LOOT is recorded but emits no cash-relevant event', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_CHAT_MONEY')
    W:fire('CHAT_MSG_LOOT', 'You receive loot: |Hitem:2589::|h[Linen Cloth]|h.')
    T.eq(#seen, 0)
  end)

  T.it('Bags.Snapshot covers bags 0 to 5, reports ranges and completeness', function()
    local W, P = boot()
    W.state.bags[5] = { size = 4, [1] = { 77, 2 } }
    local s = P.BagsModule.Snapshot()
    T.eq(s.items[77], 2); T.truthy(s.complete)
    T.eq(s.bags[5], 4)
    T.truthy(P.BagsModule.Ranges().slots)
  end)

  T.it('Items.Get ready result carries classID and subclassID', function()
    local W, P = boot()
    W.state.items[100] = { 'Linen', 'link', 1, 1, 1, '', '', 1, '', 0, 13, 7, 1, 1, 0, 0, 0 }
    W.state.cached[100] = true
    local r = P.ItemsModule.Get(100)
    T.eq(r.status, 'ready'); T.eq(r.sellPrice, 13)
    T.truthy(r.classID ~= nil)
  end)
end)
