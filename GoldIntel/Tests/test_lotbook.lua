--[[
Tests / test_lotbook.lua              (Phase 3b-3 M3: Ledger/LotBook.lua)

Lots created from item decisions, persistence through a save/load cycle, valuation lifecycle, manual prices,
anomalies, commands, read-only store, cash isolation (AC-15).
]]

local T = require('testlib')
local Fake = require('fake_wow')
local World = require('collectworld')
local Loader = require('loader')
local sim = require('svsim')

local function session(saved, opts)
  opts = opts or {}
  local W = Fake.new()
  World.extend(W)
  W.env.GoldIntelDB = saved and saved.account or nil
  W.env.GoldIntelCharDB = saved and saved.char or nil
  W.state.money = opts.money or (saved and saved.money) or 5000
  local P, ns = Loader.load(W.env)
  W:login()
  local function run(text)
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL(text)
    return W:printedText()
  end
  return W, P, ns, run
end

local function save(W)
  W:fire('PLAYER_LOGOUT')
  return { account = sim.parse(sim.dump(W.env.GoldIntelDB)), char = sim.parse(sim.dump(W.env.GoldIntelCharDB)), money = W.state.money }
end

local function item(W, id, sell, bind, name)
  W.state.items[id] = { name or ('Item' .. id), 'link', 1, 1, 1, '', '', 1, '', 0, sell, 7, 1, bind or 0, 0, 0, 0 }
  W.state.cached[id] = true
end

local function dec(t) t.dir = t.dir or 'add'; t.qty = t.qty or 1; return t end

local function boot(opts)
  local W, P, ns, run = session(nil, opts)
  run('collect on')
  W:advance(1)
  return W, P, ns, run
end

T.describe('LotBook decisions', function()
  T.it('loot creates a value-created lot priced at the vendor value', function()
    local W, _, ns = boot()
    item(W, 100, 13)
    ns.LotBook.OnDecisions({ dec{ itemID = 100, qty = 2, how = 'loot', act = 'GRIND', actConf = 'med' } }, { moneyPos = 0, moneyNeg = 0 })
    local st = ns.LotBook.Instance():Stats()
    T.eq(st.openLots, 1); T.eq(st.openQty, 2); T.eq(st.created.value, 26); T.eq(st.created.n, 1)
    T.eq(st.inventoryValue, 26)
  end)

  T.it('quest rewards create value, disenchant materials and purchases do not', function()
    local W, _, ns = boot()
    item(W, 1, 10); item(W, 2, 5); item(W, 3, 7)
    ns.LotBook.OnDecisions({
      dec{ itemID = 1, how = 'quest' }, dec{ itemID = 2, how = 'disenchantMat', qty = 2 }, dec{ itemID = 3, how = 'vendorBuy' } },
      { moneyPos = 0, moneyNeg = 21 })
    local st = ns.LotBook.Instance():Stats()
    T.eq(st.created.value, 10); T.eq(st.created.n, 1)
    T.eq(st.openLots, 3)
    local lots = ns.LotBook.Instance().s.open
    T.eq(lots[3].how, 'purchase'); T.eq(lots[3].cost, 21); T.falsy(lots[3].vc)
    T.falsy(lots[2].vc); T.truthy(lots[2].flags.conversion)
  end)

  T.it('a vendor sale consumes lots oldest first and books the money exactly', function()
    local W, _, ns = boot()
    item(W, 100, 13)
    local LB = ns.LotBook
    LB.OnDecisions({ dec{ itemID = 100, qty = 2, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    LB.OnDecisions({ dec{ itemID = 100, qty = 2, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    LB.OnDecisions({ dec{ dir = 'remove', itemID = 100, qty = 3, how = 'vendorSale' } }, { moneyPos = 40, moneyNeg = 0 })
    local L = LB.Instance()
    local st = L:Stats()
    T.eq(st.openQty, 1)
    local out = 0
    for _, cv in ipairs(L.s.conv) do out = out + cv.copper end
    T.eq(out, 40)
  end)

  T.it('mail, trade and unexplained additions and inventory-only removals create nothing', function()
    local W, _, ns = boot()
    item(W, 5, 9)
    ns.LotBook.OnDecisions({ dec{ itemID = 5, how = 'mail' }, dec{ itemID = 5, how = 'trade' }, dec{ itemID = 5, how = 'unexplained' },
      dec{ dir = 'remove', itemID = 5, how = 'ignored' } }, { moneyPos = 0, moneyNeg = 0 })
    T.eq(ns.LotBook.Instance():Stats().openLots, 0)
  end)

  T.it('trade out and quest consumption close lots with 0 copper', function()
    local W, _, ns = boot()
    item(W, 6, 9)
    local LB = ns.LotBook
    LB.OnDecisions({ dec{ itemID = 6, qty = 4, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    LB.OnDecisions({ dec{ dir = 'remove', itemID = 6, qty = 1, how = 'tradeOut' }, dec{ dir = 'remove', itemID = 6, qty = 2, how = 'questConsume' } }, { moneyPos = 0, moneyNeg = 0 })
    T.eq(LB.Instance():Stats().openQty, 1)
  end)

  T.it('a sale of items no lot covers is counted, not an anomaly (D-081)', function()
    local W, _, ns = boot()
    item(W, 7, 9)
    ns.LotBook.OnDecisions({ dec{ dir = 'remove', itemID = 7, qty = 2, how = 'vendorSale' } }, { moneyPos = 18, moneyNeg = 0 })
    local st = ns.LotBook.Instance():Stats()
    T.eq(st.shortfall, 2)
    T.eq(next(st.anomalies), nil)
  end)
end)

T.describe('LotBook valuation lifecycle', function()
  T.it('item data not ready: unknown lot, then valued when the data arrives, value stays with the lot', function()
    local W, _, ns = boot()
    W.state.items[200] = { 'Late', 'link', 1, 1, 1, '', '', 1, '', 0, 30, 7, 1, 0, 0, 0, 0 }
    -- not cached yet
    ns.LotBook.OnDecisions({ dec{ itemID = 200, qty = 2, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    local L = ns.LotBook.Instance()
    T.eq(L:Stats().unknown.lots, 1); T.eq(L:Stats().created.value, 0)
    W.state.cached[200] = true
    W:fire('GET_ITEM_INFO_RECEIVED', 200, true)
    T.eq(L:Stats().unknown.lots, 0); T.eq(L:Stats().created.value, 60)
  end)

  T.it('an invalid item stays unknown and is listed', function()
    local W, _, ns, run = boot()
    ns.LotBook.OnDecisions({ dec{ itemID = 279912, qty = 1, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    W:fire('GET_ITEM_INFO_RECEIVED', 279912, false)
    local out = run('lots unknown')
    T.truthy(out:find('279912', 1, true), out)
  end)

  T.it('unknown lots are completed at the next start when the data is ready', function()
    local W, _, ns = boot()
    W.state.items[201] = { 'Slow', 'link', 1, 1, 1, '', '', 1, '', 0, 11, 7, 1, 0, 0, 0, 0 }
    ns.LotBook.OnDecisions({ dec{ itemID = 201, qty = 1, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    local saved = save(W)
    local W2, _, ns2, run2 = session(saved)
    W2.state.items[201] = W.state.items[201]; W2.state.cached[201] = true
    run2('collect on')
    T.eq(ns2.LotBook.Instance():Stats().unknown.lots, 0)
    T.eq(ns2.LotBook.Instance():Stats().created.value, 11)
  end)
end)

T.describe('LotBook persistence and isolation', function()
  T.it('lots survive logout and login for the same character', function()
    local W, _, ns = boot()
    item(W, 100, 13)
    ns.LotBook.OnDecisions({ dec{ itemID = 100, qty = 2, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    local saved = save(W)
    local _, _, ns2, run2 = session(saved)
    local out = run2('lots status')
    T.truthy(out:find('1 open', 1, true), out)
    run2('collect on')
    T.eq(ns2.LotBook.Instance():Stats().openQty, 2)
  end)

  T.it('lots off stores nothing; on resumes', function()
    local W, _, ns, run = session(nil)
    run('lots off'); run('collect on')
    T.falsy(ns.LotBook.IsActive())
    run('lots on')
    T.truthy(ns.LotBook.IsActive())
  end)

  T.it('a read-only store creates no lots and does not fail', function()
    local W, _, ns, run = session(nil)
    ns.Store.IsWritable = function() return false end
    run('collect on')
    T.falsy(ns.LotBook.IsActive()); T.truthy(ns.LotBook.ReadOnly())
  end)

  T.it('the lot book source never references cash, reconciler, expectations or sources', function()
    local f = io.open('../Ledger/LotBook.lua', 'r'); local src = f:read('*a'); f:close()
    src = src:gsub('%-%-[^\n]*', '')
    for _, bad in ipairs({ 'GI%.Cash', 'GI%.Reconciler', 'GI%.Expectations', 'GI%.Sources' }) do T.falsy(src:find(bad), bad) end
  end)

  T.it('live: loot, sale and buyback books lots and leaves the cash entries untouched', function()
    local W, _, ns, run = boot({ money = 1000 })
    item(W, 100, 13)
    W.state.bags[0] = { size = 16 }
    W.state.loot = { guid = 'Creature-0-4621-0-1-95-AAAA', slots = { { type = 1, link = '|Hitem:100::|h[Linen]|h', qty = 2 } } }
    W:fire('LOOT_OPENED', false, false, false)
    W.state.bags[0][1] = { 100, 2 }
    W:fire('BAG_UPDATE_DELAYED')
    W.state.loot.slots = {}
    W:fire('LOOT_CLOSE'); W:fire('LOOT_CLOSED')
    W:advance(3)
    T.eq(ns.LotBook.Instance():Stats().created.value, 26)
    W:fire('MERCHANT_SHOW'); W:advance(0.3)
    W.state.bags[0][1] = nil
    W:fire('BAG_UPDATE_DELAYED')
    W.state.money = W.state.money + 26; W:fire('PLAYER_MONEY')
    W:advance(0.3); W:fire('MERCHANT_CLOSED'); W:advance(4)
    local L = ns.LotBook.Instance()
    T.eq(L:Stats().openQty, 0)
    T.eq(L.s.totals.byVia.vendor.copper, 26)
    T.eq(ns.Cash.Cumulative(), 26)
  end)
end)

T.describe('LotBook anomalies', function()
  T.it('a sale at a vendor of an item with no sell price raises one visible bug message per kind', function()
    local W, _, ns, run = boot()
    item(W, 8, 0)
    W.printed = {}
    ns.LotBook.OnDecisions({ dec{ dir = 'remove', itemID = 8, how = 'vendorSale' } }, { moneyPos = 5, moneyNeg = 0 })
    ns.LotBook.OnDecisions({ dec{ dir = 'remove', itemID = 8, how = 'vendorSale' } }, { moneyPos = 5, moneyNeg = 0 })
    local out = W:printedText()
    local _, n = out:gsub('please report', '')
    T.eq(n, 1, out)
    T.truthy(run('lots status'):find('ANOMALIES', 1, true))
  end)
end)

T.describe('manual prices', function()
  T.it('ParseMoney accepts units and refuses bare numbers and junk', function()
    local LB = select(3, session(nil)).LotBook
    T.eq(LB.ParseMoney('1g20s5c'), 12005); T.eq(LB.ParseMoney('20s'), 2000); T.eq(LB.ParseMoney('500c'), 500)
    T.eq(LB.ParseMoney('2g'), 20000)
    T.isnil((LB.ParseMoney('500'))); T.isnil((LB.ParseMoney('abc'))); T.isnil((LB.ParseMoney('')))
    T.isnil((LB.ParseMoney('1g150s')))
  end)

  T.it('set, list and clear; a higher manual price is used for new lots, a lower one is not', function()
    local W, _, ns, run = boot()
    item(W, 100, 13)
    local out = run('price set 100 50c')
    T.truthy(out:find('manual price', 1, true), out)
    T.truthy(run('price list'):find('50c', 1, true))
    ns.LotBook.OnDecisions({ dec{ itemID = 100, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    T.eq(ns.LotBook.Instance().s.open[1].valueEach, 50)
    T.eq(ns.LotBook.Instance().s.open[1].valueSrc, 'manual')
    run('price set 100 5c')
    ns.LotBook.OnDecisions({ dec{ itemID = 100, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    T.eq(ns.LotBook.Instance().s.open[2].valueSrc, 'vendor')
    T.eq(ns.LotBook.Instance().s.open[1].valueEach, 50, 'past lots are not repriced')
    T.truthy(run('price clear 100'):find('removed', 1, true))
    T.truthy(run('price list'):find('no manual prices', 1, true))
  end)

  T.it('a bad price is refused with a message', function()
    local W, _, ns, run = boot()
    T.truthy(run('price set 100 500'):find('units', 1, true))
    T.truthy(run('price set'):find('usage', 1, true))
  end)
end)

T.describe('/gi lots commands', function()
  T.it('last, unknown, check and reset confirm', function()
    local W, _, ns, run = boot()
    item(W, 100, 13, 0, 'Linen Cloth')
    ns.LotBook.OnDecisions({ dec{ itemID = 100, qty = 2, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    T.truthy(run('lots last'):find('Linen Cloth', 1, true))
    T.truthy(run('lots unknown'):find('no unknown values', 1, true))
    T.truthy(run('lots check'):find('lots check', 1, true))
    T.truthy(run('lots reset'):find('Type /gi lots reset confirm', 1, true))
    T.eq(ns.LotBook.Instance():Stats().openLots, 1)
    T.truthy(run('lots reset confirm'):find('deleted', 1, true))
    T.eq(ns.LotBook.Instance():Stats().openLots, 0)
  end)
end)

T.describe('LotBook mutation checks', function()
  local f = io.open('../Ledger/LotBook.lua', 'r'); local SRC = f:read('*a'); f:close()
  local MUT = {
    { 'sale money not booked', "L:Convert(sales, info.moneyPos or 0,", "L:Convert(sales, 0," },
    { 'loot is not value created', "addLot(d, now, 'loot', 'free', true)", "addLot(d, now, 'loot', 'free', false)" },
    { 'quest is not value created', "addLot(d, now, 'quest', 'free', true)", "addLot(d, now, 'quest', 'free', false)" },
    { 'purchase counts as created', "addLot(d, now, 'vendor', 'purchase', false, nil, costs[bi] or 0)", "addLot(d, now, 'vendor', 'purchase', true, nil, costs[bi] or 0)" },
    { 'disenchant material counts as created', "addLot(d, now, 'disenchant', 'free', false, { conversion = true })", "addLot(d, now, 'disenchant', 'free', true, { conversion = true })" },
    { 'other additions create lots', "else c.otherAdds = c.otherAdds + 1 end", "else c.otherAdds = c.otherAdds + 1; addLot(d, now, 'loot', 'free', true) end" },
    { 'mail creates lots', "elseif d.how == 'mail' or d.how == 'trade' then c.arrivals = c.arrivals + 1", "elseif d.how == 'mail' or d.how == 'trade' then c.arrivals = c.arrivals + 1; addLot(d, now, 'loot', 'free', false)" },
    { 'item data never completes lots', "if info.status == 'ready' then L:Complete(p.itemID,", "if false then L:Complete(p.itemID," },
    { 'manual price ignored', "local r = GI.Valuation.Value(info, LB.ManualFor(d.itemID))", "local r = GI.Valuation.Value(info, nil)" },
    { 'quest turn-in does not consume', "if anyConsume then c.conversions", "if false then c.conversions" },
    { 'trade out does not consume', "if anyTrade then c.conversions", "if false then c.conversions" },
    { 'reset without confirm word is not needed', "sec[key] = nil", "sec[key] = sec[key]" },
    { 'purchase cost not recorded', "addLot(d, now, 'vendor', 'purchase', false, nil, costs[bi] or 0)", "addLot(d, now, 'vendor', 'purchase', false, nil, nil)" },
  }
  local function scenario(override)
    Loader.override = override and { ['Ledger/LotBook.lua'] = override } or nil
    local ok, res = pcall(function()
      local W, _, ns, run = session(nil)
      Loader.override = nil
      run('collect on'); W:advance(1)
      item(W, 1, 10); item(W, 2, 5); item(W, 3, 7); item(W, 4, 9)
      W.state.items[9] = { 'Late', 'l', 1, 1, 1, '', '', 1, '', 0, 30, 7, 1, 0, 0, 0, 0 }
      local LB = ns.LotBook
      local good = true
      local function chk(c) if not c then good = false end end
      LB.OnDecisions({ dec{ itemID = 1, qty = 2, how = 'loot' }, dec{ itemID = 4, how = 'quest' }, dec{ itemID = 2, how = 'disenchantMat' },
        dec{ itemID = 3, how = 'vendorBuy' }, dec{ itemID = 3, how = 'mail' }, dec{ itemID = 3, how = 'unexplained' } }, { moneyPos = 0, moneyNeg = 14 })
      local L = LB.Instance()
      local st = L:Stats()
      chk(st.openLots == 4)
      chk(st.created.value == 29 and st.created.n == 2)
      chk(next(st.anomalies) == nil)
      chk(L.s.open[4] and L.s.open[4].cost == 14)
      LB.OnDecisions({ dec{ dir = 'remove', itemID = 1, qty = 1, how = 'vendorSale' } }, { moneyPos = 10, moneyNeg = 0 })
      chk(L.s.totals.byVia.vendor and L.s.totals.byVia.vendor.copper == 10)
      LB.OnDecisions({ dec{ dir = 'remove', itemID = 4, how = 'questConsume' }, dec{ dir = 'remove', itemID = 1, how = 'tradeOut' } }, { moneyPos = 0, moneyNeg = 0 })
      chk(L:Stats().openQty == 2)
      LB.OnDecisions({ dec{ itemID = 9, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
      W.state.cached[9] = true
      W:fire('GET_ITEM_INFO_RECEIVED', 9, true)
      chk(L:Stats().unknown.lots == 0)
      run('price set 1 99c')
      LB.OnDecisions({ dec{ itemID = 1, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
      chk(L.s.open[#L.s.open].valueSrc == 'manual')
      run('lots reset confirm')
      chk(LB.Instance():Stats().openLots == 0)
      chk(next(st.anomalies) == nil)
      return good
    end)
    Loader.override = nil
    return ok and res
  end
  T.it('baseline scenario passes on the real source', function() T.truthy(scenario(nil)) end)
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[1], function()
      local i, j = SRC:find(m[2], 1, true)
      T.truthy(i, 'anchor missing: ' .. m[1])
      local ok = scenario(SRC:sub(1, i - 1) .. m[3] .. SRC:sub(j + 1))
      T.falsy(ok, 'survived: ' .. m[1])
    end)
  end
end)

T.describe('money pairing for quick vendor sales (M2 trace 2026-10-21: five sales within 0.3 s)', function()
  local IS = function() return select(3, session(nil)).ItemSources end
  T.it('PairMoney gives every money event to its nearest settle only', function()
    local S = IS()
    local settles = { 100.000, 100.035, 100.133, 100.198, 100.301 }
    local events = { { gt = 100.000, copper = 2 }, { gt = 100.035, copper = 4 }, { gt = 100.133, copper = 30 }, { gt = 100.198, copper = 55 }, { gt = 100.301, copper = 65 } }
    local total = 0
    for i, s in ipairs(settles) do
      local pos = S.PairMoney(events, settles, s, 1.0)
      T.eq(pos, events[i].copper)
      total = total + pos
    end
    T.eq(total, 156)
  end)

  T.it('money that arrives after its bag event still pairs (quest, 0.289 s) and money out is kept apart', function()
    local S = IS()
    local pos, neg = S.PairMoney({ { gt = 10.289, copper = 50 }, { gt = 10.4, copper = -20 } }, { 10.0 }, 10.0, 1.0)
    T.eq(pos, 50); T.eq(neg, 20)
  end)

  T.it('money farther than the pairing distance, or nearer to another settle, is not taken', function()
    local S = IS()
    T.eq((S.PairMoney({ { gt = 11.5, copper = 9 } }, { 10.0 }, 10.0, 1.0)), 0)
    T.eq((S.PairMoney({ { gt = 10.6, copper = 9 } }, { 10.0, 10.5 }, 10.0, 1.0)), 0)
    T.eq((S.PairMoney({ { gt = 10.25, copper = 9 } }, { 10.0, 10.5 }, 10.0, 1.0)), 9, 'tie goes to the earlier settle')
  end)

  T.it('mutation is caught: every settle takes all nearby money', function()
    local f = io.open('../Collect/ItemSources.lua', 'r'); local src = f:read('*a'); f:close()
    local i, j = src:find('if best == mine then', 1, true)
    T.truthy(i)
    local mutated = src:sub(1, i - 1) .. 'if true then' .. src:sub(j + 1)
    Loader.override = { ['Collect/ItemSources.lua'] = mutated }
    local S = select(3, session(nil)).ItemSources
    Loader.override = nil
    local settles = { 100.000, 100.035 }
    local events = { { gt = 100.000, copper = 2 }, { gt = 100.035, copper = 4 } }
    T.eq((S.PairMoney(events, settles, 100.000, 1.0)), 6, 'the mutant double counts')
    local real = IS()
    T.eq((real.PairMoney(events, settles, 100.000, 1.0)), 2)
  end)

  T.it('live: five quick vendor sales each get exactly their own copper and the total is booked once', function()
    local W, _, ns, run = boot({ money = 1000 })
    local ids = { 11, 12, 13, 14, 15 }
    local price = { 2, 4, 30, 55, 65 }
    W.state.bags[0] = { size = 16 }
    local LB = ns.LotBook
    for i, id in ipairs(ids) do
      item(W, id, price[i])
      LB.OnDecisions({ dec{ itemID = id, qty = 1, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
      W.state.bags[0][i] = { id, 1 }
    end
    W:fire('BAG_UPDATE_DELAYED'); W:advance(3)              -- baseline of what we hold now
    W:fire('MERCHANT_SHOW'); W:advance(0.3)
    for i = 1, 5 do
      W.state.bags[0][i] = nil
      W:fire('BAG_UPDATE_DELAYED')
      W.state.money = W.state.money + price[i]; W:fire('PLAYER_MONEY')
      W:advance(0.06)
    end
    W:advance(0.3); W:fire('MERCHANT_CLOSED'); W:advance(5)
    local L = LB.Instance()
    T.eq(L.s.totals.byVia.vendor.copper, 156, 'the sales total is booked exactly once')
    local sum = 0
    for _, cv in ipairs(L.s.conv) do
      T.eq(cv.copper, price[cv.itemID - 10])
      sum = sum + cv.copper
    end
    T.eq(sum, 156)
  end)
end)

T.describe('cast evidence in the trace', function()
  T.it('the trace records the player\'s casts with spell id and kind', function()
    local W, _, ns, run = boot()
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8613)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'target', 'c', 8617)
    local out = run('ledger trace 10')
    T.truthy(out:find('CAST spell=8613 kind=other', 1, true), out)
    T.falsy(out:find('spell=8617', 1, true), 'other units are not recorded')
  end)
end)

T.describe('sales report', function()
  T.it('lots sales and the status line show what each lot received', function()
    local W, _, ns, run = boot()
    item(W, 100, 13, 0, 'Linen Cloth')
    ns.LotBook.OnDecisions({ dec{ itemID = 100, qty = 2, how = 'loot' } }, { moneyPos = 0, moneyNeg = 0 })
    ns.LotBook.OnDecisions({ dec{ dir = 'remove', itemID = 100, qty = 2, how = 'vendorSale' } }, { moneyPos = 26, moneyNeg = 0 })
    local sl = run('lots sales')
    T.truthy(sl:find('Linen Cloth x2 -> 26c via vendor', 1, true), sl)
    local st = run('lots status')
    T.truthy(st:find('conversions so far: vendor 2 units for 26c', 1, true), st)
  end)
end)

T.describe('skinning at a lower rank (user evidence 2026-10-21)', function()
  T.it('an apprentice skin cast makes the second window of the same corpse GATHER', function()
    local W, P, ns, run = boot()
    W.env.C_Spell = { GetSpellName = function(id) return (id == 8617 or id == 8613) and 'Skinning' or nil end }
    P.Unit.ResetNames()
    item(W, 100, 13); item(W, 2934, 7)
    W.state.bags[0] = { size = 16 }
    local guid = 'Creature-0-4621-0-1-95-AAAA'
    W.state.loot = { guid = guid, slots = { { type = 1, link = '|Hitem:100::|h[x]|h', qty = 1 } } }
    W:fire('LOOT_OPENED', false, false, false)
    W:advance(0.4); W.state.bags[0][1] = { 100, 1 }; W:fire('BAG_UPDATE_DELAYED')
    W.state.loot.slots = {}; W:fire('LOOT_CLOSED'); W:advance(1)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8613)
    W:advance(0.2)
    W.state.loot = { guid = guid, slots = { { type = 1, link = '|Hitem:2934::|h[x]|h', qty = 1 } } }
    W:fire('LOOT_OPENED', false, false, false)
    W:advance(0.4); W.state.bags[0][2] = { 2934, 1 }; W:fire('BAG_UPDATE_DELAYED')
    W.state.loot.slots = {}; W:fire('LOOT_CLOSED'); W:advance(4)
    T.eq(ns.ItemSources.Stats().skinWindows, 1)
    local lot = ns.LotBook.Instance().s.open[2]
    T.eq(lot.itemID, 2934); T.eq(lot.origin.act, 'GATHER'); T.truthy(lot.origin.skinning)
  end)
end)

T.describe('lots last shows activity and no-vendor wording', function()
  T.it('activity, skinning and "no vendor value" are visible', function()
    local W, _, ns, run = boot()
    item(W, 100, 13, 0, 'Linen Cloth'); item(W, 101, 0, 4, 'Quest Thing')
    ns.LotBook.OnDecisions({ dec{ itemID = 100, how = 'loot', act = 'GATHER', skinning = true }, dec{ itemID = 101, how = 'loot', act = 'GRIND' } }, { moneyPos = 0, moneyNeg = 0 })
    local out = run('lots last 5')
    T.truthy(out:find('Linen Cloth x1 (1 left) 13c each [vendor] loot/free GATHER (skinning)', 1, true), out)
    T.truthy(out:find('Quest Thing x1 (1 left) no vendor value loot/free GRIND', 1, true), out)
  end)

  T.it('the cast trace logs an unrecognized spell once per interval and every gathering cast', function()
    local W = boot()
    for _ = 1, 3 do W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 133) end
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8617)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8617)
    W.printed = {}; W.env.SlashCmdList.GOLDINTEL('ledger trace 20')
    local out = W:printedText()
    local _, n133 = out:gsub('CAST spell=133', '')
    local _, n8617 = out:gsub('CAST spell=8617', '')
    T.eq(n133, 1); T.eq(n8617, 2)
  end)
end)
