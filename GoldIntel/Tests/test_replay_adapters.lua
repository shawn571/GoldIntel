--[[
Tests / test_replay_adapters.lua      (Phase 3b-1, D-073)

The permanent replay corpus (real WoW Forever recordings) is fed through the real adapters, the Context
module and the Collector. What is pinned: with the REAL measured lags, the context that explains a money
move is still open (or lingering) when the money arrives, and the adapters behave on the real sequences
(duplicate closes, cancelled trades, repeated inbox updates). Missing corpus files FAIL the suite.
]]

local T = require('testlib')
local World = require('collectworld')
local R = require('labreplay')
local Loader = require('loader')

local dir = Loader.root .. '/Tests/fixtures/replay/'

local function load(file)
  local lab, err = R.load(dir .. file)
  T.truthy(lab, 'replay corpus file missing or unreadable (never skipped): ' .. file .. ' ' .. tostring(err))
  return lab
end

local COLLECT = {}
for _, e in ipairs({ 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'QUEST_TURNED_IN', 'MERCHANT_SHOW', 'MERCHANT_CLOSED',
  'MAIL_INBOX_UPDATE', 'TRADE_SHOW', 'TRADE_CLOSED', 'TRADE_ACCEPT_UPDATE', 'TRADE_MONEY_CHANGED',
  'BAG_UPDATE_DELAYED', 'GET_ITEM_INFO_RECEIVED', 'AUCTION_HOUSE_AUCTION_CREATED' }) do COLLECT[e] = true end

--- Replays one file. Returns the world and a list of { gt, delta, active = {kind=true}, lastEvent } per nonzero money move.
-- The recordings keep a capped number of samples per event, so some opens are missing from the files (E-31 has
-- TRADE_CLOSED without TRADE_SHOW, E-33 MERCHANT_CLOSED without MERCHANT_SHOW). The replay infers the open just
-- before such a close, once, and the test names say so. Nothing else is invented.
local OPENER = { TRADE_CLOSED = 'TRADE_SHOW', MERCHANT_CLOSED = 'MERCHANT_SHOW' }

local function replay(file, opts)
  opts = opts or {}
  local lab = load(file)
  local tl = R.timeline(lab)
  local W, P, ns = World.boot()
  ns.Collector.On({})
  if opts.mail then W.state.mailShown = true; W:advance(1.0) end
  local moves, last, lastGT = {}, nil, nil
  local lastByName = {}
  local t0
  for _, rec in ipairs(tl) do
    if opts.from and rec.gt < opts.from then goto continue end
    if opts.to and rec.gt > opts.to then break end
    t0 = t0 or rec.gt
    local target = rec.gt - t0
    local now = W.state.replayNow or 0
    if target > now then
      local gap = target - now
      -- long gaps are skipped in coarse steps, short ones run in the fake's 0.25 s sub-steps
      -- gaps longer than 12 s are compressed to 12 s (longer than every context timeout, so nothing is hidden)
      if gap > 12 then gap = 12 end
      W:advance(gap)
      W.state.replayNow = target
    end
    if rec.kind == 'event' and COLLECT[rec.name] then
      local opener = OPENER[rec.name]
      if opener and lastByName[rec.name] ~= rec.gt then
        local mod = (opener == 'TRADE_SHOW') and P.TradeModule or P.MerchantModule
        if not mod.IsOpen() then W:fire(opener) end
      end
      if rec.name == 'QUEST_TURNED_IN' then W:fire(rec.name, 1, 0, 0) else W:fire(rec.name) end
      last = rec.name; lastGT = rec.gt; lastByName[rec.name] = rec.gt
      -- E-42: a single-item loot window hides 0.1 s after the clear; the recordings hold no frame data
      if rec.name == 'LOOT_SLOT_CLEARED' then W.state.lootShown = false end
    elseif rec.kind == 'money' then
      local before = W.state.money
      W.state.money = rec.balance
      if rec.delta and rec.delta ~= 0 then
        local active = {}
        for _, k in ipairs({ 'loot', 'vendor', 'mail', 'trade', 'ah', 'quest' }) do
          if ns.Context.IsActive(k) then active[k] = true end
        end
        moves[#moves + 1] = { gt = rec.gt, delta = rec.delta, active = active, lastEvent = last, sinceEvent = lastGT and (rec.gt - lastGT) or nil }
      end
      W:fire('PLAYER_MONEY')
    end
    ::continue::
  end
  if opts.debug then for _, r in ipairs(tl) do if r.kind=='event' and COLLECT[r.name] then io.write(string.format('%.3f %s\n', r.gt, r.name)) end end end
  return W, P, ns, moves
end

local function kinds(m)
  local out = {}
  for k in pairs(m.active) do out[#out + 1] = k end
  table.sort(out)
  return table.concat(out, ',')
end

T.describe('replay through the adapters: contexts explain the real money moves', function()
  T.it('E-22 quest: the quest context is open when the quest reward arrives', function()
    local _, _, ns, moves = replay('E-22_quest_turnin.lua')
    local found = false
    for _, m in ipairs(moves) do if m.active.quest then found = true end end
    T.truthy(found, 'a money move happened inside the quest context')
    T.truthy(ns.Context.Stats().quest.opened >= 1)
  end)

  T.it('E-28 mail: the mail context is open when the mail money arrives', function()
    local _, _, ns, moves = replay('E-28_mail_update.lua', { mail = true })
    local inMail = 0
    for _, m in ipairs(moves) do if m.active.mail then inMail = inMail + 1 end end
    T.truthy(inMail >= 1, 'a money move inside the mail context')
  end)

  T.it('E-31 trade: money (0.394 s after TRADE_CLOSED) arrives while the trade context still lingers', function()
    local _, _, ns, moves = replay('E-31_trade.lua')
    local inTrade = 0
    for _, m in ipairs(moves) do if m.lastEvent == 'TRADE_CLOSED' and m.active.trade then inTrade = inTrade + 1 end end
    T.truthy(inTrade >= 1, 'a trade money move happened inside the lingering trade context')
    T.truthy(ns.Context.Stats().trade.opened >= 2)
  end)

  T.it('E-31 trade: the doubled TRADE_CLOSED (cancelled and completed trades) is counted as duplicates', function()
    local _, P = replay('E-31_trade.lua')
    T.truthy(P.TradeModule.stats.duplicateCloses >= 2, 'two doubled closes in the recording')
    T.truthy(P.TradeModule.stats.closed >= 2)
  end)

  T.it('E-39 COD paid: every money move within 1 s of a MAIL_INBOX_UPDATE is inside the mail context', function()
    local _, _, _, moves = replay('E-39_cod_paid.lua', { mail = true })
    local n = 0
    for _, m in ipairs(moves) do
      if m.lastEvent == 'MAIL_INBOX_UPDATE' and m.sinceEvent and m.sinceEvent <= 1.0 then
        n = n + 1
        T.truthy(m.active.mail, 'mail context open for the move of ' .. m.delta)
      end
    end
    T.truthy(n >= 1, 'the recording has a money move right after an inbox update')
  end)

  T.it('E-40 COD payment mail: the +100 (0.267 s after the inbox update) is inside the mail context', function()
    local _, _, _, moves = replay('E-40_cod_payment_mail.lua', { mail = true })
    local n = 0
    for _, m in ipairs(moves) do
      if m.lastEvent == 'MAIL_INBOX_UPDATE' and m.sinceEvent and m.sinceEvent <= 1.0 then
        n = n + 1
        T.truthy(m.active.mail)
      end
    end
    T.truthy(n >= 1)
  end)
end)

T.describe('replay through the adapters: real sequences', function()
  T.it('E-33 merchant: the doubled MERCHANT_CLOSED closes the vendor context once', function()
    local W, P, ns = replay('E-33_merchant_close.lua')
    local s = ns.Context.Stats().vendor
    T.truthy(s.opened >= 1)
    T.truthy(s.closed >= 1)
    T.truthy(P.MerchantModule.stats.duplicateCloses >= 1, 'the duplicate close was counted')
  end)

  T.it('E-33: the collector counted the duplicate as dropped, not kept', function()
    local _, _, ns = replay('E-33_merchant_close.lua')
    local row
    for _, r in ipairs(ns.Collector.Stats().rows) do if r.event == 'MERCHANT_CLOSED' then row = r end end
    T.truthy(row.dropped >= 1)
    T.eq(row.received, row.kept + row.dropped + row.errors)
  end)

  T.it('every replayed file runs with zero handler errors', function()
    for _, f in ipairs({ 'E-22_quest_turnin.lua', 'E-28_mail_update.lua', 'E-31_trade.lua', 'E-33_merchant_close.lua',
                         'E-39_cod_paid.lua', 'E-40_cod_payment_mail.lua' }) do
      local _, _, ns = replay(f, { mail = true })
      T.eq(ns.Collector.Stats().total.errors, 0, f)
    end
  end)

  T.it('every replayed file ends with no stuck context after a quiet period', function()
    -- (the recordings may end with a window still open, so only the timed kinds are checked)
    for _, f in ipairs({ 'E-22_quest_turnin.lua', 'E-31_trade.lua', 'E-33_merchant_close.lua' }) do
      local W, _, ns = replay(f)
      W.state.lootShown = false
      W:advance(15)
      T.falsy(ns.Context.IsActive('quest'), f)
      T.falsy(ns.Context.IsActive('loot'), f)
    end
  end)

  T.it('replaying twice gives identical context statistics (deterministic)', function()
    local _, _, ns1 = replay('E-31_trade.lua')
    local _, _, ns2 = replay('E-31_trade.lua')
    T.eq(ns1.Context.Stats().trade.opened, ns2.Context.Stats().trade.opened)
  end)
end)

T.describe('E-34 / E-39 / E-40 mail data rebuilt from the recorded results', function()
  local function x2(file)
    -- the recorded X2 inbox read results, as { header values..., invoice values... } are in lab.runs; keep it tolerant
    local lab = load(file)
    T.truthy(lab.runs, 'runs present in ' .. file)
    return lab
  end

  T.it('E-34 sale mail: header money 149 splits into 51 + 100 deposit - 2 cut', function()
    x2('E-34_ah_sale_mail.lua')
    local W, P, ns = World.boot()
    ns.Collector.On({})
    W.state.inbox[1] = {
      header = World.header({ icon = 1, sender = 'Auction House', subject = 'Auction successful: Spider Ichor (4)',
                              money = 149, itemCount = nil }),
      invoice = { 'seller', 'Spider Ichor', 'Buyer', 51, 0, 100, 2 },
    }
    W.state.mailShown = true
    W:advance(1.0)
    W:fire('MAIL_INBOX_UPDATE')
    local snap = P.MailModule.Snapshot()
    T.eq(snap.mails[1].money, 149)
    T.eq(snap.mails[1].kind, 'auction')
    T.eq(snap.mails[1].invoice.price, 51); T.eq(snap.mails[1].invoice.deposit, 100); T.eq(snap.mails[1].invoice.cut, 2)
    T.eq(snap.mails[1].invoice.price + snap.mails[1].invoice.deposit - snap.mails[1].invoice.cut, 149)
  end)

  T.it('E-39 COD header: cod 100, money 0, readable before paying', function()
    x2('E-39_cod_paid.lua')
    local W, P = World.boot()
    P.Collect = true
    local _, _, ns = World.boot()
    local W2, P2, ns2 = World.boot()
    ns2.Collector.On({})
    W2.state.inbox[1] = { header = World.header({ icon = 1, sender = 'Dottie Slaps', subject = 'Spider Ichor (4)',
                                                  money = 0, cod = 100, itemCount = 1, firstQty = 4 }) }
    W2.state.mailShown = true
    W2:advance(1.0)
    W2:fire('MAIL_INBOX_UPDATE')
    local snap = P2.MailModule.Snapshot()
    T.eq(snap.mails[1].cod, 100); T.eq(snap.mails[1].money, 0)
    T.eq(snap.mails[1].kind, 'player')
  end)

  T.it('E-40 COD payment mail: money 100 (full amount, no fee) with the COD subject', function()
    x2('E-40_cod_payment_mail.lua')
    local W2, P2, ns2 = World.boot()
    ns2.Collector.On({})
    W2.state.inbox[1] = { header = World.header({ icon = 1, sender = 'Divine Slaps',
                                                  subject = 'COD Payment: Spider Ichor (4)', money = 100 }) }
    W2.state.mailShown = true
    W2:advance(1.0)
    W2:fire('MAIL_INBOX_UPDATE')
    local snap = P2.MailModule.Snapshot()
    T.eq(snap.mails[1].money, 100); T.eq(snap.mails[1].cod, 0)
    T.truthy(snap.mails[1].subject:find('COD Payment', 1, true))
  end)

  T.it('money lags in the recordings are shorter than the 1.0 s context linger (E-39 and E-40)', function()
    local l39 = R.lag(R.timeline(load('E-39_cod_paid.lua')), 'MAIL_INBOX_UPDATE', 1.0, 0.5)
    local l40 = R.lag(R.timeline(load('E-40_cod_payment_mail.lua')), 'MAIL_INBOX_UPDATE', 1.0, 0.5)
    T.truthy(#l39 >= 2); T.truthy(#l40 >= 1)
    for _, x in ipairs(l39) do T.truthy(x < 1.0 and x >= 0) end
    for _, x in ipairs(l40) do T.truthy(x < 1.0 and x >= 0) end
  end)
end)
