--[[
Tests / test_phase3b_foundation.lua                 (Phase 3b-0, Decisions D-066..D-072)

1. The collector event allow-list (Architecture 19 AC-1, Contracts F9b).
2. The lab replay helper, and what the real evidence says about the 1.0 s reconciliation window
   (D-065): every measured lag between an explaining signal and the money move is inside it.
Evidence-based tests skip silently when the evidence folder is not next to the package.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local Loader = require('loader')
local R = require('labreplay')

local function boot()
  local W = Fake.new()
  local P = Loader.load(W.env)
  return W, P
end

T.describe('collector event allow-list (AC-1)', function()
  local EXPECTED = {
    'AUCTION_HOUSE_AUCTION_CREATED', 'BAG_UPDATE_DELAYED', 'CHAT_MSG_LOOT', 'CHAT_MSG_MONEY', 'GET_ITEM_INFO_RECEIVED', 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'MAIL_INBOX_UPDATE',
    'MERCHANT_CLOSED', 'MERCHANT_SHOW', 'PLAYER_MONEY', 'QUEST_TURNED_IN', 'TRADE_ACCEPT_UPDATE',
    'TRADE_CLOSED', 'TRADE_MONEY_CHANGED', 'TRADE_SHOW', 'TRAINER_CLOSED', 'TRAINER_SHOW', 'UNIT_SPELLCAST_SUCCEEDED',
  }

  T.it('contains exactly the verified events', function()
    local _, P = boot()
    local got = {}
    for name in pairs(P.COLLECTOR_EVENTS) do got[#got + 1] = name end
    table.sort(got)
    T.eq(got, EXPECTED)
  end)

  T.it('never contains a restricted event, MAIL_CLOSED or MAIL_SHOW', function()
    local _, P = boot()
    for name in pairs(P.RESTRICTED_EVENTS) do T.falsy(P.COLLECTOR_EVENTS[name], name) end
    T.falsy(P.COLLECTOR_EVENTS.MAIL_CLOSED)
    T.falsy(P.COLLECTOR_EVENTS.MAIL_SHOW)
    T.falsy(P.COLLECTOR_EVENTS.COMBAT_LOG_EVENT_UNFILTERED)
  end)

  T.it('IsCollectorEvent answers per name', function()
    local _, P = boot()
    T.truthy(P.IsCollectorEvent('LOOT_OPENED'))
    T.falsy(P.IsCollectorEvent('MAIL_CLOSED'))
    T.falsy(P.IsCollectorEvent('COMBAT_LOG_EVENT_UNFILTERED'))
    T.falsy(P.IsCollectorEvent(nil))
  end)

  T.it('having an allow-list registers nothing and trusts nothing new', function()
    local W, P = boot()
    W:login()
    T.falsy(P.TRUSTED_EVENTS.LOOT_OPENED)
    local n = 0
    for _ in pairs(P.TRUSTED_EVENTS) do n = n + 1 end
    T.eq(n, 12)
  end)
end)

T.describe('lab replay helper', function()
  T.it('builds a sorted timeline with money deltas from references', function()
    local lab = {
      runs = { R1 = { events = { TRADE_CLOSED = { samples = { { gt = 10.0, n = 0 } } } } } },
      refs = { { gt = 5.0, money = 100 }, { gt = 10.394, money = 150 }, { gt = 20.0, money = 150 } },
    }
    local tl = R.timeline(lab)
    T.eq(#tl, 4)
    T.eq(tl[1].kind, 'money'); T.isnil(tl[1].delta)
    T.eq(tl[2].kind, 'event')
    T.eq(tl[3].delta, 50)
    T.eq(tl[4].delta, 0)
    local lags = R.lag(tl, 'TRADE_CLOSED', 1.0)
    T.eq(#lags, 1)
    T.truthy(math.abs(lags[1] - 0.394) < 0.0001)
  end)

  T.it('a zero money move is not counted (cancelled trade)', function()
    local lab = {
      runs = { R1 = { events = { TRADE_CLOSED = { samples = { { gt = 10.0, n = 0 } } } } } },
      refs = { { gt = 5.0, money = 100 }, { gt = 10.3, money = 100 } },
    }
    T.eq(R.lag(R.timeline(lab), 'TRADE_CLOSED', 1.0), {})
  end)

  T.it('load reports a missing file', function()
    local lab, err = R.load('/no/such/file.lua')
    T.isnil(lab)
    T.truthy(err)
  end)
end)

T.describe('replay corpus: permanent regression suite (D-073)', function()
  local dir = Loader.root .. '/Tests/fixtures/replay/'
  local function load(file)
    local lab, err = R.load(dir .. file)
    T.truthy(lab, 'replay corpus file missing or unreadable (never skipped): ' .. file .. ' ' .. tostring(err))
    return lab
  end
  local function lags(file, event)
    return R.lag(R.timeline(load(file)), event, 1.0, 0.5)
  end
  local function near(a, b) return math.abs(a - b) < 0.005 end

  T.it('E-31 trade: money follows TRADE_CLOSED by 0.394 s, inside the window', function()
    local l = lags('E-31_trade.lua', 'TRADE_CLOSED')
    T.truthy(#l >= 1, 'at least one trade with a money move')
    for _, x in ipairs(l) do T.truthy(near(x, 0.394), 'lag ' .. x) end
  end)

  T.it('E-28 mail: money follows MAIL_INBOX_UPDATE by 0.365 s', function()
    local l = lags('E-28_mail_update.lua', 'MAIL_INBOX_UPDATE')
    T.eq(#l, 1)
    T.truthy(near(l[1], 0.365), 'lag ' .. l[1])
  end)

  T.it('E-22 quest: the turn-in event comes 0.041 s before the money', function()
    local l = lags('E-22_quest_turnin.lua', 'QUEST_TURNED_IN')
    T.eq(#l, 1)
    T.truthy(near(l[1], 0.041), 'lag ' .. l[1])
  end)

  T.it('E-31 trade: a cancelled trade leaves a zero money move that is never counted', function()
    local tl = R.timeline(load('E-31_trade.lua'))
    local zero = 0
    for _, r in ipairs(tl) do if r.kind == 'money' and r.delta == 0 then zero = zero + 1 end end
    T.truthy(zero >= 1, 'the corpus contains a zero-delta money reference')
    for _, x in ipairs(R.lag(tl, 'TRADE_CLOSED', 1.0, 0.5)) do T.truthy(x >= -0.5 and x <= 1.0) end
  end)

  T.it('E-34 AH sale mail: header money equals price + deposit refund - cut', function()
    local lab = load('E-34_ah_sale_mail.lua')
    local sale
    for _, a in ipairs(lab.runs.X2.api) do if a.label == 'sale' then sale = a end end
    T.truthy(sale, 'the sale snapshot exists')
    local header, invoice
    for _, r in ipairs(sale.results) do
      if r.fn == 'GetInboxHeaderInfo(1)' then header = r.returns end
      if r.fn == 'GetInboxInvoiceInfo(1)' then invoice = r.returns end
    end
    T.eq(header[3].value, 'Horde Auction House')
    T.eq(invoice[1].value, 'seller')
    local money = header[5].value
    local price, deposit, cut = invoice[4].value, invoice[6].value, invoice[7].value
    T.eq(money, 149)
    T.eq(price + deposit - cut, money)
    T.eq(price - cut, 49, 'sale income after the cut')
    T.eq(deposit, 100, 'deposit refund, not income')
  end)
end)
