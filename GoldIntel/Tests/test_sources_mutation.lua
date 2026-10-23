--[[
Tests / test_sources_mutation.lua           (Phase 3b-2 M2): deliberate bugs in Sources.lua must be caught.
The scenario suite below runs the real adapters; each mutant replaces Sources.lua source text via Loader.override.
]]

local T = require('testlib')
local World = require('collectworld')
local Loader = require('loader')
local L = require('ledgerworld')

local SRC = Loader.readFile(Loader.root .. '/Collect/Sources.lua')

local function scenarios()
  local fails = {}
  local function check(n, ok) if not ok then fails[#fails + 1] = n end end
  local function es(ns) return ns.Sources.Entries() end
  local function open(W) W.state.mailShown = true; W:advance(1.0) end

  do -- slow loot held 9 s
    local W, _, ns = L.boot()
    W.state.loot = { guid = 'Creature-0-4621-0-1-95-AAAA', slots = { { type = 2, amount = 11 } } }
    W:fire('LOOT_OPENED'); W:advance(9); L.pay(W, 11); W:advance(0.3)
    check('slow loot', es(ns)[1] and es(ns)[1].src == 'loot')
  end
  do -- quest
    local W, _, ns = L.boot()
    W:fire('QUEST_TURNED_IN', 1, 2, 175); W:advance(0.041); L.pay(W, 175); W:advance(0.2)
    check('quest', es(ns)[1] and es(ns)[1].src == 'quest' and es(ns)[1].settle ~= true)
  end
  do -- vendor sale and purchase, windows close
    local W, _, ns = L.boot()
    W:fire('MERCHANT_SHOW'); W:advance(1); L.pay(W, 60); L.pay(W, -10); W:advance(0.2); W:fire('MERCHANT_CLOSED')
    W:advance(1.6); L.pay(W, 5); W:advance(2.3)
    check('vendor', es(ns)[1] and es(ns)[1].src == 'vendor' and es(ns)[2] and es(ns)[2].src == 'purchase')
    check('vendor window closes', es(ns)[3] and es(ns)[3].src == 'other')
  end
  do -- trade
    local W, _, ns = L.boot()
    W:fire('TRADE_SHOW'); W:advance(1); W:fire('TRADE_CLOSED'); W:advance(0.394); L.pay(W, -10); W:advance(0.3)
    check('trade', es(ns)[1] and es(ns)[1].src == 'trade')
  end
  do -- mail money, baseline, settle
    local W, _, ns = L.boot()
    open(W); L.inbox(W, { L.moneyMail(44) }); W:advance(1)
    check('baseline creates nothing', ns.Sources.Stats().sources.mailExp == 0)
    L.inbox(W, {}); W:advance(0.365); L.pay(W, 44); W:advance(0.2)
    check('mail money', es(ns)[1] and es(ns)[1].src == 'mailMoney' and es(ns)[1].settle == true)
  end
  do -- COD payment mail
    local W, _, ns = L.boot()
    open(W); L.inbox(W, { L.moneyMail(100, 'COD Payment: X', 'Y') }); W:advance(1)
    L.inbox(W, {}); W:advance(0.267); L.pay(W, 100); W:advance(0.2)
    check('codIn', es(ns)[1] and es(ns)[1].src == 'codIn')
  end
  do -- sale split
    local W, _, ns = L.boot()
    open(W); L.inbox(W, { L.saleMail(51, 100, 2) }); W:advance(1)
    L.inbox(W, {}); W:advance(0.3); L.pay(W, 149); W:advance(0.2)
    local e = es(ns)
    check('split', #e == 3 and e[1].src == 'ahSale' and e[2].copper == -2 and e[3].copper == 100)
  end
  do -- reopening: the first update is a baseline even though a snapshot exists from before
    local W, _, ns = L.boot()
    open(W); L.inbox(W, { L.moneyMail(77) }); W:advance(1)
    W.state.mailShown = false; W:advance(1.0); open(W)
    L.inbox(W, {}); W:advance(2.0)
    check('reopen baseline', ns.Sources.Stats().sources.mailExp == 0)
  end
  do -- two identical mails taken in one update
    local W, _, ns = L.boot()
    open(W); L.inbox(W, { L.moneyMail(30), L.moneyMail(30) }); W:advance(1)
    L.inbox(W, {}); W:advance(0.2); L.pay(W, 60); W:advance(0.3)
    check('two mails', ns.Sources.Stats().sources.mailExp == 2 and #es(ns) == 2 and es(ns)[1].src == 'mailMoney')
  end
  do -- gap
    local W, P, ns = L.boot()
    W.state.money = W.state.money + 500; P.MoneyModule.Sync(true); W:advance(0.1)
    check('gap', es(ns)[1] and es(ns)[1].comp == 'gap')
  end
  do -- End flushes
    local W, _, ns = L.boot()
    L.pay(W, 12); ns.Sources.End()
    check('end flush', es(ns)[1] and es(ns)[1].src == 'other')
  end
  do -- unexplained becomes other via the ticker
    local W, _, ns = L.boot()
    L.pay(W, 9); W:advance(2.5)
    check('ticker', es(ns)[1] and es(ns)[1].src == 'other')
  end
  return fails
end

local function withMutation(a, b, fn)
  local i, j = SRC:find(a, 1, true)
  T.truthy(i, 'anchor missing: ' .. a)
  Loader.override = { ['Collect/Sources.lua'] = SRC:sub(1, i - 1) .. b .. SRC:sub(j + 1) }
  local ok, res = pcall(fn)
  Loader.override = nil
  return ok, res
end

T.describe('Sources scenario suite', function()
  T.it('passes on the real source', function() T.eq(scenarios(), {}) end)
end)

T.describe('Sources mutation checks', function()
  local MUT = {
    { 'loot not held', "ref = { sourceType = p.source }, hold = true })", "ref = { sourceType = p.source } })" },
    { 'held loot released while the window is active', "not GI.Context.IsActive('loot')", "GI.Context.IsActive('loot')" },
    { 'mail baseline ignored', "if needBaseline then", "if false then" },
    { 'COD payment prefix ignored', "(m.subject or ''):sub(1, #Sources.COD_PREFIX) == Sources.COD_PREFIX", "false" },
    { 'AH split never applied', "if inv and inv.price + inv.deposit - inv.cut == m.money then", "if false then" },
    { 'cut sign wrong', "copper = -inv.cut", "copper = inv.cut" },
    { 'mail money not settlement', "spec.src, spec.settle = 'mailMoney', true", "spec.src = 'mailMoney'" },
    { 'vendor window signs swapped', "{ src = 'vendor', sign = 1 }, { src = 'purchase', sign = -1 }", "{ src = 'vendor', sign = -1 }, { src = 'purchase', sign = 1 }" },
    { 'windows never closed', "for _, id in ipairs(windows[p.kind] or {}) do X:Close(id, gt) end", "" },
    { 'trade windows missing', "trade = { { src = 'trade', sign = 1 }, { src = 'trade', sign = -1 } },", "trade = {}," },
    { 'ticker not started', "cancelTick = P.Every(Sources.TICK, tick)", "" },
    { 'End does not end the Reconciler', "R:End(nowGT())", "" },
    { 'quest expectation dropped', "src = 'quest', mode = 'exact', copper = p.copper, sign = 1", "src = 'quest', mode = 'exact', copper = p.copper + 1, sign = 1" },
    { 'money feed dropped', "R:Money(p.copper, p.gt or nowGT(), p.gap == true)", "" },
    { 'gap flag dropped', "p.gap == true", "false" },
    { 'vanished mail counted once only', "for _ = 1, gone do", "for _ = 1, math.min(gone, 1) do" },
  }
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[1], function()
      local ok, fails = withMutation(m[2], m[3], scenarios)
      T.truthy((not ok) or #fails > 0, 'survived: ' .. m[1])
    end)
  end
end)
