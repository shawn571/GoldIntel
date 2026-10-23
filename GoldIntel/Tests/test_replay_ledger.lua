--[[
Tests / test_replay_ledger.lua                  (Phase 3b-2 M2, D-073: the permanent replay corpus through the Reconciler)

Each case replays the REAL event timing of a recorded GoldIntelDiag lab file (pinned: the test first checks the
fixture still holds the event or money reference at that game time) through the real adapters, Context, Sources,
Reconciler and Stamps, and asserts the exact source classification, component split and confidence.

What comes from the recordings: event order and every lag. What comes from the evidence notes (Compatibility_Notes):
amounts that the lab files cannot give (the recordings keep PLAYER_MONEY balances only at sampled moments and
splice several lab sessions, so a delta between two samples of different sessions is meaningless; each case uses
only deltas from consecutive samples of the same session, or the amount written in the evidence note). Mailbox
contents are rebuilt from the evidence notes (E-29, E-34, E-39, E-40). Where a lag is not in the recording (E-34
mail to money) the case says so and uses a measured band (0.233 to 0.367 s, E-28/E-39/E-40).
A missing fixture FAILS the suite.
]]

local T = require('testlib')
local World = require('collectworld')
local R = require('labreplay')
local Loader = require('loader')
local L = require('ledgerworld')

local dir = Loader.root .. '/Tests/fixtures/replay/'

local function lab(file)
  local l, err = R.load(dir .. file)
  T.truthy(l, 'replay corpus file missing or unreadable (never skipped): ' .. file .. ' ' .. tostring(err))
  return l
end

--- Pins: times in the cases are seconds from the first money / quest / mail / trade / merchant record of the file
-- (the same origin the corpus MANIFEST uses); the pin checks the fixture holds that sample at that relative time.
local pins, origins = {}, {}
local function timeline(file)
  if not pins[file] then
    pins[file] = R.timeline(lab(file))
    for _, r in ipairs(pins[file]) do
      if r.kind == 'money' or r.name == 'QUEST_TURNED_IN' or r.name:find('MAIL_INBOX') or r.name:find('TRADE')
        or r.name:find('MERCHANT') then origins[file] = r.gt; break end
    end
  end
  return pins[file], origins[file]
end
local function pinEvent(file, name, gt)
  local tl, o = timeline(file)
  for _, r in ipairs(tl) do
    if r.kind == 'event' and r.name == name and math.abs(r.gt - o - gt) < 0.0006 then return true end
  end
  T.truthy(false, string.format('fixture %s has no %s at %.3f', file, name, gt))
end
local function pinMoney(file, gt, balance)
  local tl, o = timeline(file)
  for _, r in ipairs(tl) do
    if r.kind == 'money' and math.abs(r.gt - o - gt) < 0.0006 and r.balance == balance then return true end
  end
  T.truthy(false, string.format('fixture %s has no money reference %d at %.3f', file, balance, gt))
end

--- Runs a script of { gt, fn(W, P, ns) } steps (real game times). Starts at `startMoney`, ticks for a location first.
local function run(steps, startMoney)
  local W, P, ns = World.boot()
  ns.Collector.On({}); ns.Ledger.End()      -- collect on starts the ledger interval; these tests start Sources by hand
  W.state.money = startMoney or 100000; W:fire('PLAYER_MONEY')
  W:advance(1.0)
  ns.Sources.Begin(); W:advance(0.6)
  table.sort(steps, function(a, b) return a.gt < b.gt end)
  local last = steps[1].gt
  for _, s in ipairs(steps) do
    local gap = s.gt - last
    if gap > 12 then gap = 12 end
    if gap > 0 then W:advance(gap) end
    last = s.gt
    s.fn(W, P, ns)
  end
  W:advance(4.0)                                   -- past WAIT (2.0 s) and the loot linger so nothing stays pending
  return W, P, ns
end

local unpack_ = table.unpack or unpack
local function fire(name, ...) local a = { ... }; return function(W) W:fire(name, unpack_(a)) end end
local function pay(d) return function(W) L.pay(W, d) end end
local function entries(ns) return ns.Sources.Entries() end

local function assertClean(ns, n)
  local s = ns.Sources.Stats()
  T.truthy(ns.Sources.Reconciler():Check(), 'sumDeltas = sumEntries + pending')
  T.eq(s.pending, 0)
  T.eq(s.sumDeltas, s.sumEntries)
  if n then T.eq(#entries(ns), n) end
  return s
end

---------------------------------------------------------------------------
T.describe('replay ledger: E-22 quest', function()
  T.it('E-22: QUEST_TURNED_IN then money 0.041 s later is ONE quest entry, high, QUEST', function()
    pinEvent('E-22_quest_turnin.lua', 'QUEST_TURNED_IN', 5317.639)
    pinMoney('E-22_quest_turnin.lua', 5317.680, 323)
    local _, _, ns = run({
      { gt = 5317.639, fn = fire('QUEST_TURNED_IN', 818, 625, 175) },       -- args from the E-22 note
      { gt = 5317.680, fn = pay(175) },                                    -- 148 -> 323 (E-22 note)
    }, 148)
    local s = assertClean(ns, 1)
    local e = entries(ns)[1]
    T.eq({ e.src, e.copper, e.conf, e.act, e.creditable }, { 'quest', 175, 'high', 'QUEST', false })
    T.eq(s.otherShareValue, 0); T.eq(s.unmatched, 0); T.eq(s.gapCount, 0)
  end)
end)

T.describe('replay ledger: E-28 mail money', function()
  T.it('E-28: the 44 copper money mail (update 0.365 s before the money) is ONE mailMoney entry, settle', function()
    local f = 'E-28_mail_update.lua'
    pinEvent(f, 'MAIL_INBOX_UPDATE', 14030.312); pinEvent(f, 'MAIL_INBOX_UPDATE', 14034.488)
    pinEvent(f, 'MAIL_INBOX_UPDATE', 14035.786); pinMoney(f, 14036.151, 367)
    pinEvent(f, 'MAIL_INBOX_UPDATE', 14039.216); pinEvent(f, 'MAIL_INBOX_UPDATE', 14039.331)
    local itemOnly = { header = World.header({ icon = 1, sender = 'Rehgar Deadeye', subject = 'an item', itemCount = 1, firstQty = 1 }) }
    local both = { L.moneyMail(44), itemOnly }
    local _, _, ns = run({
      { gt = 14030.0, fn = function(W) W.state.mailShown = true end },
      { gt = 14030.312, fn = function(W) L.inbox(W, both) end },           -- opening load: baseline
      { gt = 14034.488, fn = function(W) L.inbox(W, both) end },
      { gt = 14035.786, fn = function(W) L.inbox(W, { itemOnly }) end },   -- the money mail is taken
      { gt = 14036.151, fn = pay(44) },                                    -- 323 -> 367 (recorded balance 367)
      { gt = 14039.216, fn = function(W) L.inbox(W, { itemOnly }) end },
      { gt = 14039.331, fn = function(W) L.inbox(W, { itemOnly }) end },
    }, 323)
    local s = assertClean(ns, 1)
    local e = entries(ns)[1]
    T.eq({ e.src, e.copper, e.conf, e.act, e.settle }, { 'mailMoney', 44, 'high', 'MAIL', true })
    T.eq(s.unmatched, 0); T.eq(s.otherShareValue, 0)
  end)
end)

T.describe('replay ledger: E-31 trade', function()
  T.it('E-31: doubled TRADE_CLOSED, money -10 0.394 s later is ONE trade entry (med); the cancelled trade gives none', function()
    local f = 'E-31_trade.lua'
    pinEvent(f, 'TRADE_CLOSED', 87.164); pinMoney(f, 87.558, 5297)
    pinEvent(f, 'TRADE_MONEY_CHANGED', 688.139); pinMoney(f, 693.529, 5292)
    local _, _, ns = run({
      { gt = 80.0, fn = fire('TRADE_SHOW') },                              -- the open is not in the capped samples (inferred)
      { gt = 87.164, fn = function(W) W:fire('TRADE_CLOSED'); W:fire('TRADE_CLOSED') end },
      { gt = 87.558, fn = pay(-10) },                                      -- 5307 -> 5297
      { gt = 683.0, fn = fire('TRADE_SHOW') },
      { gt = 688.139, fn = fire('TRADE_MONEY_CHANGED') },
      { gt = 693.529, fn = pay(0) },                                       -- a zero move (cancelled trade)
      { gt = 694.0, fn = fire('TRADE_CLOSED') },
    }, 5307)
    local s = assertClean(ns, 1)
    local e = entries(ns)[1]
    T.eq({ e.src, e.copper, e.conf, e.act }, { 'trade', -10, 'med', 'TRADE' })
    T.eq(s.otherShareValue, 0)
  end)
end)

T.describe('replay ledger: E-33 vendor window', function()
  T.it('E-33 session: sale +18097, then -10 and -83 inside the vendor window are vendor med and purchase med', function()
    local f = 'E-33_merchant_close.lua'
    pinEvent(f, 'MERCHANT_SHOW', 499371.201); pinMoney(f, 499383.136, 18242)
    pinMoney(f, 499385.577, 18232); pinEvent(f, 'MERCHANT_SHOW', 499442.145); pinMoney(f, 499446.478, 18149)
    pinEvent(f, 'MERCHANT_CLOSED', 2879.564)
    local _, P, ns = run({
      { gt = 499371.201, fn = fire('MERCHANT_SHOW') },
      { gt = 499383.136, fn = pay(18097) },                                -- 145 -> 18242
      { gt = 499385.577, fn = pay(-10) },                                  -- 18242 -> 18232
      { gt = 499442.145, fn = fire('MERCHANT_SHOW') },                     -- duplicate open of the same window
      { gt = 499446.478, fn = pay(-83) },                                  -- 18232 -> 18149
      { gt = 499451.146, fn = function(W) W:fire('MERCHANT_CLOSED'); W:fire('MERCHANT_CLOSED') end },   -- E-33: doubled close, 4.668 s after the last sale
    }, 145)
    local s = assertClean(ns, 3)
    local a, b, c = entries(ns)[1], entries(ns)[2], entries(ns)[3]
    T.eq({ a.src, a.copper, a.conf, a.act }, { 'vendor', 18097, 'med', 'VENDOR' })
    T.eq({ b.src, b.copper, b.conf }, { 'purchase', -10, 'med' })
    T.eq({ c.src, c.copper, c.conf }, { 'purchase', -83, 'med' })
    T.eq(s.otherShareValue, 0)
    T.truthy(P.MerchantModule.stats.duplicateCloses >= 1)
  end)
end)

T.describe('replay ledger: E-34 AH sale mail', function()
  local f = 'E-34_ah_sale_mail.lua'
  local function sale(lag)
    pinMoney(f, 3108.909, 373)                    -- 224 -> 373 = +149 (consecutive samples of the same session)
    local both = { L.saleMail(51, 100, 2) }
    return run({
      { gt = 3100.0, fn = function(W) W.state.mailShown = true end },
      { gt = 3101.0, fn = function(W) L.inbox(W, both) end },              -- baseline
      { gt = 3108.909 - lag, fn = function(W) L.inbox(W, {}) end },        -- mail taken (lag not in the recording)
      { gt = 3108.909, fn = pay(149) },
    }, 224)
  end

  T.it('E-34: +149 = ahSale 51 (settle) + ahCut -2 + ahDepositRefund 100, all high, summing to the delta', function()
    local _, _, ns = sale(0.3)
    local s = assertClean(ns, 3)
    local e = entries(ns)
    T.eq({ e[1].src, e[1].copper, e[1].settle, e[1].conf }, { 'ahSale', 51, true, 'high' })
    T.eq({ e[2].src, e[2].copper, e[2].conf }, { 'ahCut', -2, 'high' })
    T.eq({ e[3].src, e[3].copper, e[3].comp, e[3].conf }, { 'ahDepositRefund', 100, 'deposit', 'high' })
    T.eq(e[1].copper + e[2].copper + e[3].copper, 149)
    T.eq(s.otherShareValue, 0); T.eq(s.unmatched, 0)
  end)

  T.it('E-34 boundary: money exactly 1.0 s after the mail update still matches', function()
    local _, _, ns = sale(1.0)
    assertClean(ns, 3)
    T.eq(entries(ns)[1].src, 'ahSale')
  end)

  T.it('E-34 boundary: money 1.2 s after the update is OTHER 149, the expectation is counted unmatched', function()
    local _, _, ns = sale(1.2)
    local s = assertClean(ns, 1)
    T.eq(entries(ns)[1].src, 'other'); T.eq(entries(ns)[1].copper, 149)
    T.eq(s.unmatched, 1); T.eq(s.otherShareValue, 1)
  end)
end)

T.describe('replay ledger: E-39 COD paid and money mail', function()
  T.it('E-39: COD paid -100 stays OTHER (option A); the +30 money mail (0.233 s after the update) is mailMoney', function()
    local f = 'E-39_cod_paid.lua'
    for _, g in ipairs({ 8977.639, 8997.172, 9007.851, 9008.014, 9023.317, 9026.462, 9035.896, 9037.861, 9038.068 }) do
      pinEvent(f, 'MAIL_INBOX_UPDATE', g)
    end
    pinMoney(f, 9008.120, 60); pinMoney(f, 9026.695, 90)
    local cod, money30 = L.codMail(100), L.moneyMail(30, 'postage refund')
    local both = { cod, money30 }
    local _, _, ns = run({
      { gt = 8977.0, fn = function(W) W.state.mailShown = true end },
      { gt = 8977.639, fn = function(W) L.inbox(W, both) end },
      { gt = 8997.172, fn = function(W) L.inbox(W, both) end },
      { gt = 9007.851, fn = function(W) L.inbox(W, both) end },
      { gt = 9008.014, fn = function(W) L.inbox(W, { money30 }) end },     -- COD mail paid and gone
      { gt = 9008.120, fn = pay(-100) },                                   -- 0.106 s later (E-39)
      { gt = 9023.317, fn = function(W) L.inbox(W, { money30 }) end },
      { gt = 9026.462, fn = function(W) L.inbox(W, {}) end },              -- the money mail is taken
      { gt = 9026.695, fn = pay(30) },                                     -- 60 -> 90, 0.233 s later
      { gt = 9035.896, fn = function(W) L.inbox(W, {}) end },
      { gt = 9037.861, fn = function(W) L.inbox(W, {}) end },
      { gt = 9038.068, fn = function(W) L.inbox(W, {}) end },
    }, 160)
    local s = assertClean(ns, 2)
    local a, b = entries(ns)[1], entries(ns)[2]
    T.eq({ a.src, a.copper, a.conf }, { 'other', -100, 'low' })
    T.eq({ b.src, b.copper, b.conf, b.settle }, { 'mailMoney', 30, 'high', true })
    T.eq(s.unmatched, 0)
    T.near(s.otherShareValue, 100 / 130, 1e-9)                              -- reported by value (D-072)
    T.near(s.otherShareEntries, 0.5, 1e-9)
    T.eq(s.largestOther, 100)
  end)
end)

T.describe('replay ledger: E-40 COD payment mail', function()
  T.it('E-40: "COD Payment" mail +100 exact 0.267 s after the update is codIn, high, settle', function()
    local f = 'E-40_cod_payment_mail.lua'
    for _, g in ipairs({ 9242.586, 9258.609, 9304.008, 9304.175 }) do pinEvent(f, 'MAIL_INBOX_UPDATE', g) end
    pinMoney(f, 9304.442, 6138)
    local pay100 = L.moneyMail(100, 'COD Payment: Spider Ichor (4)', 'Divine Slaps')
    local _, _, ns = run({
      { gt = 9242.0, fn = function(W) W.state.mailShown = true end },
      { gt = 9242.586, fn = function(W) L.inbox(W, { pay100 }) end },
      { gt = 9258.609, fn = function(W) L.inbox(W, { pay100 }) end },
      { gt = 9304.008, fn = function(W) L.inbox(W, { pay100 }) end },
      { gt = 9304.175, fn = function(W) L.inbox(W, {}) end },
      { gt = 9304.442, fn = pay(100) },                                    -- 6038 -> 6138
    }, 6038)
    local s = assertClean(ns, 1)
    local e = entries(ns)[1]
    T.eq({ e.src, e.copper, e.conf, e.settle, e.act }, { 'codIn', 100, 'high', true, 'MAIL' })
    T.eq(s.otherShareValue, 0); T.eq(s.unmatched, 0)
  end)
end)

T.describe('replay ledger: E-42 loot windows', function()
  local function records()
    local f = io.open(Loader.root .. '/Tests/fixtures/probe/E-42_lootframe.lua', 'rb')
    T.truthy(f, 'E-42 probe fixture missing (never skipped)')
    local src = f:read('*a'); f:close()
    local env = {}
    local chunk
    if setfenv then chunk = loadstring(src); setfenv(chunk, env) else chunk = load(src, 'e42', 't', env) end
    chunk()
    local out = {}
    for _, line in ipairs(env.GIProbeLootDB.log) do
      local gt, rest = line:match('^([%d%.]+) (.*)$')
      gt = tonumber(gt)
      if rest:find('^EVENT LOOT_OPENED') then out[#out + 1] = { gt = gt, kind = 'open', slots = tonumber(rest:match('slots=(%d+)')) }
      elseif rest:find('^EVENT LOOT_SLOT_CLEARED') then out[#out + 1] = { gt = gt, kind = 'clear', slot = tonumber(rest:match('slot=(%d+)')) }
      elseif rest:find('^POLL LootFrame shown=false') and not rest:find('was nil') then out[#out + 1] = { gt = gt, kind = 'hide' } end
    end
    return out
  end

  T.it('E-42: every looted coin (1 copper per slot, money 0.378 s after the clear) is a loot entry; unlooted slots expire unmatched', function()
    local steps, seen, totalSlots, looted = {}, {}, 0, 0
    for _, r in ipairs(records()) do
      if r.kind == 'open' then
        seen = {}; totalSlots = totalSlots + r.slots
        local n = r.slots
        steps[#steps + 1] = { gt = r.gt, fn = function(W)
          local slots = {}
          for i = 1, n do slots[i] = { type = 2, amount = 1 } end
          W.state.loot = { guid = 'Creature-0-4621-0-1-95-AAAA', slots = slots }; W:fire('LOOT_OPENED')
        end }
      elseif r.kind == 'clear' then
        local slot = r.slot
        steps[#steps + 1] = { gt = r.gt, fn = function(W) W:fire('LOOT_SLOT_CLEARED', slot) end }
        if not seen[slot] then
          seen[slot] = true; looted = looted + 1
          steps[#steps + 1] = { gt = r.gt + 0.378, fn = pay(1) }
        end
      elseif r.kind == 'hide' then
        steps[#steps + 1] = { gt = r.gt, fn = function(W) W.state.lootShown = false end }
      end
    end
    local _, _, ns = run(steps)
    local s = assertClean(ns)
    T.eq(looted, 5)
    T.eq(#entries(ns), 5)
    for _, e in ipairs(entries(ns)) do T.eq({ e.src, e.conf, e.copper, e.act }, { 'loot', 'high', 1, 'GRIND' }) end
    T.eq(s.otherShareValue, 0)
    T.eq(s.unmatched, totalSlots - looted)
  end)
end)

T.describe('replay ledger: the whole corpus is deterministic', function()
  T.it('running a case twice gives identical entries', function()
    local function once()
      local _, _, ns = run({
        { gt = 10, fn = fire('QUEST_TURNED_IN', 1, 1, 40) }, { gt = 10.041, fn = pay(40) },
        { gt = 20, fn = pay(-3) },
      })
      local out = {}
      for _, e in ipairs(entries(ns)) do out[#out + 1] = e.src .. ':' .. e.copper .. ':' .. e.conf end
      return table.concat(out, ',')
    end
    T.eq(once(), once())
  end)
end)
