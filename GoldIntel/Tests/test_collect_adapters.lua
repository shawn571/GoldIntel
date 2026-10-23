--[[
Tests / test_collect_adapters.lua                   (Phase 3b-1: the Platform adapters, end to end)

Each test boots the whole addon, switches the collector on and fires raw client events at the fake.
Adapters must emit only normalized P_* events, read payloads safely, and never register by themselves.
]]

local T = require('testlib')
local World = require('collectworld')

local function boot()
  local W, P, ns = World.boot()
  local r = ns.Collector.On({})
  T.eq(#r.failed, 0, 'collector events registered')
  return W, P, ns
end

---------------------------------------------------------------------------
T.describe('adapters register nothing by themselves', function()
  T.it('only the 12 Phase 1 events are registered until collect is switched on', function()
    local W = World.boot()
    local set = {}
    for _, e in ipairs(W.registerCalls) do set[e] = true end
    local n = 0
    for _ in pairs(set) do n = n + 1 end
    T.eq(n, 12)
    T.falsy(set.LOOT_OPENED); T.falsy(set.UNIT_SPELLCAST_SUCCEEDED); T.falsy(set.MAIL_INBOX_UPDATE)
  end)

  T.it('every adapter declares handlers only for allow-listed events', function()
    local _, P = World.boot()
    T.truthy(#P.CollectAdapters >= 9)
    for _, a in ipairs(P.CollectAdapters) do
      for event in pairs(a.handlers) do T.truthy(P.IsCollectorEvent(event), a.name .. ' ' .. event) end
    end
  end)

  T.it('every allow-listed event except PLAYER_MONEY has exactly one adapter handler', function()
    local _, P = World.boot()
    local count = {}
    for _, a in ipairs(P.CollectAdapters) do
      for event in pairs(a.handlers) do count[event] = (count[event] or 0) + 1 end
    end
    for event in pairs(P.COLLECTOR_EVENTS) do
      if event ~= 'PLAYER_MONEY' then T.eq(count[event], 1, event) end
    end
  end)
end)

---------------------------------------------------------------------------
T.describe('Loot adapter', function()
  local function coinWindow(W, amount, guid)
    W.state.loot = { guid = guid or 'Creature-0-4621-0-1-95-AAAA', slots = { { type = 2, amount = amount } } }
  end

  T.it('emits P_LOOT_OPEN with the source type and the coin as a hint', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_OPEN', 'P_LOOT_MONEY', 'P_LOOT_ITEM')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED', false, false)
    T.eq(seen[1].name, 'P_LOOT_OPEN'); T.eq(seen[1].payload.sourceType, 'creature')
    T.eq(seen[2].name, 'P_LOOT_MONEY'); T.eq(seen[2].payload.copper, 8)
  end)

  T.it('reads item slots: item id from the link, quantity from the slot', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_ITEM')
    W.state.loot = { guid = 'Creature-0-1-0-1-95-A', slots = {
      { type = 1, link = '|cnIQ1:|Hitem:2589::::::::7:1487:::::::::|h[Linen Cloth]|h|r', qty = 2 } } }
    W:fire('LOOT_OPENED')
    T.eq(seen[1].payload.itemID, 2589); T.eq(seen[1].payload.qty, 2)
  end)

  T.it('classifies GameObject, Item and unknown sources', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_OPEN')
    for _, guid in ipairs({ 'GameObject-0-6782-0-4-1731-X', 'Item-4618-0-400000008C56C916', 'Weird-1' }) do
      W.state.loot = { guid = guid, slots = { { type = 2, amount = 1 } } }
      W:fire('LOOT_OPENED')
    end
    T.eq(seen[1].payload.sourceType, 'object')
    T.eq(seen[2].payload.sourceType, 'item')
    T.eq(seen[3].payload.sourceType, 'unknown')
  end)

  T.it('a secret source GUID gives sourceType unknown and no error', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_OPEN')
    W.state.loot = { slots = { { type = 2, amount = 5, guid = World.SECRET } } }
    W:fire('LOOT_OPENED')
    T.eq(seen[1].payload.sourceType, 'unknown')
    T.eq(P.Events.Counters('LOOT_OPENED').errors, 0)
  end)

  T.it('an empty window still opens a context and offers nothing', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_OPEN', 'P_LOOT_MONEY', 'P_LOOT_ITEM')
    W.state.loot = { slots = {} }
    W:fire('LOOT_OPENED')
    T.eq(#seen, 1)
  end)

  T.it('a zero or secret coin amount is not offered', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_MONEY')
    W.state.loot = { slots = { { type = 2, amount = 0 }, { type = 2, amount = World.SECRET } } }
    W:fire('LOOT_OPENED')
    T.eq(#seen, 0)
  end)

  T.it('closes when LootFrame hides (by = frame), within the 0.1 s poll', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED')
    W:advance(2.0); T.eq(#seen, 0)
    W.state.lootShown = false
    W:advance(0.25)
    T.eq(#seen, 1); T.eq(seen[1].payload.by, 'frame')
    T.eq(P.LootModule.stats.closedFrame, 1); T.eq(P.LootModule.stats.closedTimeout, 0)
  end)

  T.it('E-42: a slow loot (25 s) keeps the window open the whole time', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED')
    W:advance(24.8); W:fire('LOOT_SLOT_CLEARED', 1)
    T.eq(#seen, 0); T.truthy(P.LootModule.IsOpen())
    W.state.lootShown = false; W:advance(0.2)
    T.eq(#seen, 1); T.eq(seen[1].payload.by, 'frame')
    T.truthy(P.LootModule.stats.maxOpenSec > 24 and P.LootModule.stats.maxOpenSec < 26)
  end)

  T.it('E-42: slot clears are information only and never close the window', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    W.state.loot = { slots = { { type = 2, amount = 1 }, { type = 2, amount = 2 }, { type = 1, link = 'item:2589' } } }
    W:fire('LOOT_OPENED')
    W:fire('LOOT_SLOT_CLEARED', 1); W:advance(1.5); W:fire('LOOT_SLOT_CLEARED', 2)
    W:advance(5)
    T.eq(#seen, 0); T.truthy(P.LootModule.IsOpen())
    T.eq(P.LootModule.stats.clears, 2)
  end)

  T.it('E-42: Escape or walking away (no clear at all) closes by frame', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED'); W:advance(21.9)
    W.state.lootShown = false; W:advance(0.2)
    T.eq(#seen, 1); T.eq(seen[1].payload.by, 'frame'); T.eq(P.LootModule.stats.clears, 0)
  end)

  T.it('E-42: an empty corpse opens and closes cleanly (no clear ever comes)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_OPEN', 'P_LOOT_CLOSE')
    W.state.loot = { slots = {} }
    W:fire('LOOT_OPENED'); W:advance(1.37)
    W.state.lootShown = false; W:advance(0.2)
    T.eq(#seen, 2); T.eq(seen[2].payload.by, 'frame')
  end)

  T.it('E-42: close and reopen within 1.3 s gives two separate windows', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_OPEN', 'P_LOOT_CLOSE')
    W.state.loot = { slots = { { type = 2, amount = 1 } } }
    W:fire('LOOT_OPENED'); W:advance(0.217)
    W.state.lootShown = false; W:advance(0.2)
    W:advance(1.0)
    W:fire('LOOT_OPENED'); W:advance(1)
    W.state.lootShown = false; W:advance(0.2)
    T.eq(World.count(seen, 'P_LOOT_OPEN'), 2); T.eq(World.count(seen, 'P_LOOT_CLOSE'), 2)
    T.eq(P.LootModule.stats.closedFrame, 2); T.eq(P.LootModule.stats.closedReplaced, 0)
  end)

  T.it('the poll runs only while a window is open (no timers when idle)', function()
    local W, P = boot()
    local before = W:activeTimers()
    coinWindow(W, 8)
    W:fire('LOOT_OPENED'); T.truthy(W:activeTimers() > before)
    W.state.lootShown = false; W:advance(0.3)
    T.eq(W:activeTimers(), before)
  end)

  T.it('the 300 s backstop closes a window whose close was never seen (by = timeout)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED')
    W:advance(299); T.eq(#seen, 0)
    W:advance(2)
    T.eq(#seen, 1); T.eq(seen[1].payload.by, 'timeout')
    T.eq(P.LootModule.stats.closedTimeout, 1); T.eq(P.LootModule.stats.legacyWindows, 0)
  end)

  T.it('the 10 s legacy timeout is NOT used when the frame is readable (E-41 regression)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED'); W:advance(60)
    T.eq(#seen, 0)
  end)

  for _, mode in ipairs({ 'missing', 'error', 'secret', 'hidden-at-open' }) do
    T.it('unreadable frame (' .. mode .. '): legacy rule, counted as frameUnreadable', function()
      local W, P = boot()
      local seen = World.capture(P, 'P_LOOT_CLOSE')
      W.state.lootFrame = mode
      coinWindow(W, 8)
      W:fire('LOOT_OPENED')
      T.eq(P.LootModule.stats.frameUnreadable, 1); T.eq(P.LootModule.stats.legacyWindows, 1)
      W:advance(9.5); T.eq(#seen, 0)
      W:advance(1.0)
      T.eq(#seen, 1); T.eq(seen[1].payload.by, 'timeout')
    end)
  end

  T.it('unreadable frame: after a slot clear the legacy rule closes 1.0 s later', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    W.state.lootFrame = 'error'
    coinWindow(W, 8)
    W:fire('LOOT_OPENED'); W:advance(2); W:fire('LOOT_SLOT_CLEARED', 1)
    W:advance(0.75); T.eq(#seen, 0)
    W:advance(0.5); T.eq(#seen, 1)
  end)

  T.it('the frame becoming unreadable mid-window switches that window to the legacy rule', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED'); W:advance(1)
    W.state.lootFrame = 'error'; W:advance(0.2)
    T.eq(P.LootModule.stats.legacyWindows, 1)
    W:advance(11); T.eq(#seen, 1); T.eq(seen[1].payload.by, 'timeout')
  end)

  T.it('the same slot cleared twice in one window is counted once (E-20)', function()
    local W, P = boot()
    coinWindow(W, 8)
    W:fire('LOOT_OPENED')
    W:fire('LOOT_SLOT_CLEARED', 1); W:fire('LOOT_SLOT_CLEARED', 1)
    local c = P.Events.Counters('LOOT_SLOT_CLEARED')
    T.eq(c.kept, 1); T.eq(c.dropped, 1)
    T.eq(P.LootModule.stats.dupClears, 1)
  end)

  T.it('a new window while one is open closes the old one as replaced', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE', 'P_LOOT_OPEN')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED'); W:fire('LOOT_OPENED')
    T.eq(seen[2].name, 'P_LOOT_CLOSE'); T.eq(seen[2].payload.by, 'replaced')
    T.eq(P.LootModule.stats.closedReplaced, 1)
  end)

  T.it('the same slot index in a NEW window is not a duplicate', function()
    local W, P = boot()
    coinWindow(W, 8)
    W:fire('LOOT_OPENED'); W:fire('LOOT_SLOT_CLEARED', 1)
    W:advance(2.0)
    W:fire('LOOT_OPENED'); W:fire('LOOT_SLOT_CLEARED', 1)
    T.eq(P.LootModule.stats.dupClears, 0)
    T.eq(P.Events.Counters('LOOT_SLOT_CLEARED').kept, 2)
  end)

  T.it('a clear with no open window is a late clear and is dropped', function()
    local W, P = boot()
    W:fire('LOOT_SLOT_CLEARED', 1)
    T.eq(P.LootModule.stats.lateClears, 1)
    T.eq(P.Events.Counters('LOOT_SLOT_CLEARED').dropped, 1)
  end)

  T.it('a secret slot number is dropped', function()
    local W, P = boot()
    coinWindow(W, 8)
    W:fire('LOOT_OPENED')
    W:fire('LOOT_SLOT_CLEARED', World.SECRET)
    T.eq(P.Events.Counters('LOOT_SLOT_CLEARED').dropped, 1)
  end)

  T.it('collect off stops the timers and nothing closes afterwards', function()
    local W, P, ns = boot()
    local seen = World.capture(P, 'P_LOOT_CLOSE')
    coinWindow(W, 8)
    W:fire('LOOT_OPENED')
    ns.Collector.Off()
    W:advance(30)
    T.eq(#seen, 0)
    T.falsy(P.LootModule.IsOpen())
  end)

  T.it('unreadable slot types are counted', function()
    local W, P = boot()
    W.state.loot = { slots = { { type = 9 } } }
    W:fire('LOOT_OPENED')
    T.eq(P.LootModule.stats.unreadable, 1)
  end)

  T.it('a window larger than MAX_SLOTS is read only up to the cap', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_LOOT_MONEY')
    local slots = {}
    for i = 1, 60 do slots[i] = { type = 2, amount = 1 } end
    W.state.loot = { slots = slots }
    W:fire('LOOT_OPENED')
    T.eq(#seen, P.LootModule.MAX_SLOTS)
  end)
end)

---------------------------------------------------------------------------
T.describe('Merchant adapter', function()
  T.it('open and close emit once each', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_VENDOR_OPEN', 'P_VENDOR_CLOSE')
    W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_CLOSED')
    T.eq(#seen, 2)
    T.eq(seen[1].name, 'P_VENDOR_OPEN'); T.eq(seen[2].name, 'P_VENDOR_CLOSE')
  end)

  T.it('a duplicate close (walking away, E-33) is idempotent', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_VENDOR_CLOSE')
    W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_CLOSED'); W:fire('MERCHANT_CLOSED')
    T.eq(#seen, 1)
    T.eq(P.MerchantModule.stats.duplicateCloses, 1)
    T.eq(P.Events.Counters('MERCHANT_CLOSED').dropped, 1)
  end)

  T.it('a duplicate open is dropped', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_VENDOR_OPEN')
    W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_SHOW')
    T.eq(#seen, 1)
    T.eq(P.MerchantModule.stats.duplicateOpens, 1)
  end)

  T.it('a close with no open (collect switched on while the window was open) is dropped', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_VENDOR_CLOSE')
    W:fire('MERCHANT_CLOSED')
    T.eq(#seen, 0)
  end)

  T.it('can reopen after a close', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_VENDOR_OPEN')
    W:fire('MERCHANT_SHOW'); W:fire('MERCHANT_CLOSED'); W:fire('MERCHANT_SHOW')
    T.eq(#seen, 2)
  end)
end)

---------------------------------------------------------------------------
T.describe('Quest adapter', function()
  T.it('turns QUEST_TURNED_IN into P_QUEST_DONE with the money argument (E-22)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_QUEST_DONE')
    W:fire('QUEST_TURNED_IN', 818, 625, 175)
    T.eq(seen[1].payload, { questID = 818, copper = 175 })
  end)

  T.it('zero copper is a valid turn-in', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_QUEST_DONE')
    W:fire('QUEST_TURNED_IN', 5, 100, 0)
    T.eq(seen[1].payload.copper, 0)
  end)

  T.it('secret, missing or negative arguments are dropped and counted', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_QUEST_DONE')
    W:fire('QUEST_TURNED_IN', World.SECRET, 1, 1)
    W:fire('QUEST_TURNED_IN', 5, 1, World.SECRET)
    W:fire('QUEST_TURNED_IN', 5, 1, nil)
    W:fire('QUEST_TURNED_IN', 5, 1, -3)
    T.eq(#seen, 0)
    T.eq(P.QuestModule.stats.unreadable, 4)
    T.eq(P.Events.Counters('QUEST_TURNED_IN').dropped, 4)
  end)
end)

---------------------------------------------------------------------------
T.describe('Trade adapter', function()
  T.it('open, first close emits, second close (E-31) is dropped', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_TRADE_OPEN', 'P_TRADE_CLOSE')
    W:fire('TRADE_SHOW'); W:fire('TRADE_CLOSED'); W:fire('TRADE_CLOSED')
    T.eq(#seen, 2)
    T.eq(P.TradeModule.stats.duplicateCloses, 1)
  end)

  T.it('a cancelled trade (open then close, no money events) still opens and closes cleanly', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_TRADE_OPEN', 'P_TRADE_CLOSE')
    W:fire('TRADE_SHOW'); W:fire('TRADE_ACCEPT_UPDATE', 1, 0); W:fire('TRADE_CLOSED')
    T.eq(#seen, 2)
    T.falsy(P.TradeModule.State().moneyChanged)
  end)

  T.it('money change and accept updates are remembered, not emitted', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_TRADE_OPEN', 'P_TRADE_CLOSE')
    W:fire('TRADE_SHOW')
    W:fire('TRADE_MONEY_CHANGED'); W:fire('TRADE_ACCEPT_UPDATE', 1, 0); W:fire('TRADE_ACCEPT_UPDATE', 1, 1)
    local st = P.TradeModule.State()
    T.truthy(st.moneyChanged); T.eq(st.acceptUpdates, 2)
    T.eq(#seen, 1)
  end)

  T.it('events outside a window are dropped', function()
    local W, P = boot()
    W:fire('TRADE_MONEY_CHANGED'); W:fire('TRADE_ACCEPT_UPDATE', 1, 1)
    T.eq(P.Events.Counters('TRADE_MONEY_CHANGED').dropped, 1)
    T.eq(P.Events.Counters('TRADE_ACCEPT_UPDATE').dropped, 1)
  end)

  T.it('a new window resets the flags', function()
    local W, P = boot()
    W:fire('TRADE_SHOW'); W:fire('TRADE_MONEY_CHANGED'); W:fire('TRADE_CLOSED')
    W:fire('TRADE_SHOW')
    T.falsy(P.TradeModule.State().moneyChanged)
  end)

  T.it('a duplicate open is dropped', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_TRADE_OPEN')
    W:fire('TRADE_SHOW'); W:fire('TRADE_SHOW')
    T.eq(#seen, 1)
  end)
end)

---------------------------------------------------------------------------
T.describe('Mail adapter', function()
  local function addMail(W, m)
    W.state.inbox[#W.state.inbox + 1] = { header = World.header(m), invoice = m.invoice }
  end

  T.it('window state comes from polling MailFrame (no MAIL_CLOSED needed, E-34)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_MAIL_OPEN', 'P_MAIL_CLOSE')
    W:advance(1.0); T.eq(#seen, 0)
    W.state.mailShown = true; W:advance(0.6)
    T.eq(#seen, 1); T.eq(seen[1].name, 'P_MAIL_OPEN')
    W:advance(2.0); T.eq(#seen, 1)
    W.state.mailShown = false; W:advance(0.6)
    T.eq(#seen, 2); T.eq(seen[2].name, 'P_MAIL_CLOSE')
  end)

  T.it('a MAIL_INBOX_UPDATE with the box shown reads a snapshot and emits P_MAIL_UPDATE', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_MAIL_UPDATE', 'P_MAIL_OPEN')
    addMail(W, { sender = 'Rehgar Deadeye', subject = 'copper only', money = 50 })
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    T.eq(seen[1].name, 'P_MAIL_OPEN')                 -- the event itself reveals the open box
    T.eq(seen[2].payload.count, 1)
    local snap = P.MailModule.Snapshot()
    T.eq(snap.mails[1].sender, 'Rehgar Deadeye'); T.eq(snap.mails[1].money, 50)
  end)

  T.it('an update with the box closed is a stale cached view and is dropped (E-29)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_MAIL_UPDATE')
    addMail(W, { sender = 'X', subject = 'y', money = 1 })
    W:fire('MAIL_INBOX_UPDATE')
    T.eq(#seen, 0)
    T.isnil(P.MailModule.Snapshot())
    T.eq(P.MailModule.stats.staleUpdates, 1)
    T.eq(P.Events.Counters('MAIL_INBOX_UPDATE').dropped, 1)
  end)

  T.it('keeps the previous snapshot so the state before a take is readable', function()
    local W, P = boot()
    addMail(W, { sender = 'A', subject = 'one', money = 30 })
    addMail(W, { sender = 'B', subject = 'two', money = 0, itemCount = 1, firstQty = 1,
                 firstLink = '|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r' })
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    table.remove(W.state.inbox, 1)                    -- the money mail was taken and deleted (E-34/E-39)
    W:fire('MAIL_INBOX_UPDATE')
    T.eq(P.MailModule.Previous().count, 2)
    T.eq(P.MailModule.Previous().mails[1].money, 30)
    T.eq(P.MailModule.Snapshot().count, 1)
  end)

  T.it('reads the COD amount from the header before paying (E-39)', function()
    local W, P = boot()
    addMail(W, { sender = 'Rehgar Deadeye', subject = 'Spider Ichor (4)', money = 0, cod = 100, itemCount = 1,
                 firstQty = 4, firstLink = '|cnIQ1:|Hitem:3174::::::::7:1487:::::::::|h[Spider Ichor]|h|r' })
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    local m = P.MailModule.Snapshot().mails[1]
    T.eq(m.cod, 100); T.eq(m.money, 0); T.eq(m.firstItemID, 3174); T.eq(m.firstQty, 4)
  end)

  T.it('reads the auction sale invoice: price, deposit refund, house cut (E-34)', function()
    local W, P = boot()
    addMail(W, { sender = 'Horde Auction House', subject = 'Auction successful: x', money = 149, canReply = false,
                 textCreated = true, invoice = { 'seller', 'Shadowgem', '', 51, 1, 100, 2 } })
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    local m = P.MailModule.Snapshot().mails[1]
    T.eq(m.kind, 'auction')
    T.eq(m.invoice, { kind = 'seller', item = 'Shadowgem', player = '', price = 51, deposit = 100, cut = 2 })
    T.eq(m.invoice.price + m.invoice.deposit - m.invoice.cut, m.money)
  end)

  T.it('an auction mail without an invoice (cancelled) is still kind auction (E-29)', function()
    local W, P = boot()
    addMail(W, { sender = 'Horde Auction House', subject = 'Auction canceled: Chunk of Boar Meat', canReply = false,
                 textCreated = true, itemCount = 1 })
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    T.eq(P.MailModule.Snapshot().mails[1].kind, 'auction')
    T.isnil(P.MailModule.Snapshot().mails[1].invoice)
  end)

  T.it('player mail is kind player and has a fingerprint', function()
    local W, P = boot()
    addMail(W, { sender = 'Rehgar Deadeye', subject = 'Item only', itemCount = 1, firstQty = 1,
                 firstLink = '|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r' })
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    local m = P.MailModule.Snapshot().mails[1]
    T.eq(m.kind, 'player')
    T.eq(m.fingerprint, 'Rehgar Deadeye|Item only|0|0|1|1210|1')
  end)

  T.it('two identical mails have identical fingerprints and different indexes', function()
    local W, P = boot()
    addMail(W, { sender = 'A', subject = 's', money = 5 })
    addMail(W, { sender = 'A', subject = 's', money = 5 })
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    local mails = P.MailModule.Snapshot().mails
    T.eq(mails[1].fingerprint, mails[2].fingerprint)
    T.neq(mails[1].index, mails[2].index)
  end)

  T.it('secret header values are not trusted', function()
    local W, P = boot()
    addMail(W, { sender = World.SECRET, subject = 's', money = World.SECRET })
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    local m = P.MailModule.Snapshot().mails[1]
    T.eq(m.sender, ''); T.eq(m.money, 0)
  end)

  T.it('an empty inbox gives an empty snapshot', function()
    local W, P = boot()
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    T.eq(P.MailModule.Snapshot().count, 0)
    T.eq(#P.MailModule.Snapshot().mails, 0)
  end)

  T.it('at most MAX_MAILS headers are read', function()
    local W, P = boot()
    for i = 1, 60 do addMail(W, { sender = 'A', subject = tostring(i) }) end
    W.state.mailShown = true
    W:fire('MAIL_INBOX_UPDATE')
    local snap = P.MailModule.Snapshot()
    T.eq(snap.count, 60); T.eq(#snap.mails, P.MailModule.MAX_MAILS)
  end)

  T.it('polling stops when collect is switched off', function()
    local W, P, ns = boot()
    local seen = World.capture(P, 'P_MAIL_OPEN')
    ns.Collector.Off()
    W.state.mailShown = true; W:advance(3.0)
    T.eq(#seen, 0)
  end)

  T.it('without MailFrame the poll does nothing and does not raise', function()
    local W, P = boot()
    W.env.MailFrame = nil
    W:advance(2.0)
    T.falsy(P.MailModule.IsOpen())
  end)
end)

---------------------------------------------------------------------------
T.describe('Auction adapter', function()
  T.it('window state comes from polling AuctionHouseFrame (E-35)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_AH_OPEN', 'P_AH_CLOSE')
    W.state.ahShown = true; W:advance(0.6)
    W.state.ahShown = false; W:advance(0.6)
    T.eq(#seen, 2); T.eq(seen[1].name, 'P_AH_OPEN'); T.eq(seen[2].name, 'P_AH_CLOSE')
  end)

  T.it('a reopen within one poll interval is simply not seen (no phantom events)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_AH_OPEN', 'P_AH_CLOSE')
    W.state.ahShown = true; W.state.ahShown = false; W:advance(1.0)
    T.eq(#seen, 0)
  end)

  T.it('AUCTION_HOUSE_AUCTION_CREATED emits P_AH_POSTED once per event (E-36)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_AH_POSTED')
    W:fire('AUCTION_HOUSE_AUCTION_CREATED', { auctionID = 1 })
    T.eq(#seen, 1)
    T.eq(P.AuctionModule.stats.posted, 1)
  end)

  T.it('the payload of the posting event is never read (a secret payload is harmless)', function()
    local W, P = boot()
    W:fire('AUCTION_HOUSE_AUCTION_CREATED', World.SECRET)
    T.eq(P.Events.Counters('AUCTION_HOUSE_AUCTION_CREATED').errors, 0)
    T.eq(P.AuctionModule.stats.posted, 1)
  end)

  T.it('without AuctionHouseFrame the poll does nothing', function()
    local W, P = boot()
    W.env.AuctionHouseFrame = nil
    W:advance(2.0)
    T.falsy(P.AuctionModule.IsOpen())
  end)
end)

---------------------------------------------------------------------------
T.describe('Items adapter', function()
  local function addItem(W, id, sell, bind, cached)
    W.state.items[id] = { 'Name' .. id, 'link', 1, 5, 0, 'Misc', 'Junk', 20, '', 12345, sell, 15, 0, bind, 1, nil, false }
    W.state.cached[id] = cached ~= false
  end

  T.it('a cached item returns sell price and bind type (positions 11 and 14, E-30)', function()
    local W, P = boot()
    addItem(W, 2770, 5, 0)
    local r = P.ItemsModule.Get(2770)
    T.eq(r.status, 'ready'); T.eq(r.sellPrice, 5); T.eq(r.bindType, 0); T.eq(r.name, 'Name2770')
  end)

  T.it('a sell price of 0 is a real value, not unknown', function()
    local W, P = boot()
    addItem(W, 6948, 0, 1)
    T.eq(P.ItemsModule.Get(6948).sellPrice, 0)
  end)

  T.it('an uncached item is pending (never price 0) and a load is requested', function()
    local W, P = boot()
    addItem(W, 19019, 255355, 1, false)
    local r = P.ItemsModule.Get(19019)
    T.eq(r.status, 'pending'); T.isnil(r.sellPrice)
    T.eq(W.state.loadRequests, { 19019 })
  end)

  T.it('an unknown id is pending too (the failure arrives as an event)', function()
    local _, P = boot()
    T.eq(P.ItemsModule.Get(999999).status, 'pending')
  end)

  T.it('a secret field makes the answer secret', function()
    local W, P = boot()
    addItem(W, 5, World.SECRET, 0)
    T.eq(P.ItemsModule.Get(5).status, 'secret')
  end)

  T.it('invalid ids are rejected without a lookup', function()
    local _, P = boot()
    T.eq(P.ItemsModule.Get(0).status, 'invalid')
    T.eq(P.ItemsModule.Get('x').status, 'invalid')
    T.eq(P.ItemsModule.Get(World.SECRET).status, 'invalid')
    T.eq(P.ItemsModule.stats.lookups, 0)
  end)

  T.it('falls back to the legacy GetItemInfo global when C_Item is missing', function()
    local W, P = boot()
    W.env.C_Item = nil
    W.env.GetItemInfo = function(id) if id == 7 then return 'Seven', 'l', 1, 1, 0, 'a', 'b', 1, '', 1, 33, 1, 0, 0 end end
    T.eq(P.ItemsModule.Get(7).sellPrice, 33)
    T.eq(P.ItemsModule.Get(8).status, 'pending')
  end)

  T.it('GET_ITEM_INFO_RECEIVED emits P_ITEM_INFO with the success flag (E-30)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_ITEM_INFO')
    W:fire('GET_ITEM_INFO_RECEIVED', 2770, true)
    W:fire('GET_ITEM_INFO_RECEIVED', 999999, false)
    T.eq(seen[1].payload, { itemID = 2770, ready = true })
    T.eq(seen[2].payload, { itemID = 999999, ready = false })
    T.eq(P.ItemsModule.stats.failed, 1)
  end)

  T.it('secret or malformed info events are dropped', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_ITEM_INFO')
    W:fire('GET_ITEM_INFO_RECEIVED', World.SECRET, true)
    W:fire('GET_ITEM_INFO_RECEIVED', 'x', true)
    W:fire('GET_ITEM_INFO_RECEIVED', 5, World.SECRET)
    T.eq(#seen, 0)
    T.eq(P.Events.Counters('GET_ITEM_INFO_RECEIVED').dropped, 3)
  end)
end)

---------------------------------------------------------------------------
T.describe('Bags adapter', function()
  T.it('BAG_UPDATE_DELAYED emits P_BAGS_SETTLED', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_BAGS_SETTLED')
    W:fire('BAG_UPDATE_DELAYED'); W:fire('BAG_UPDATE_DELAYED')
    T.eq(#seen, 2)
    T.eq(P.BagsModule.stats.settled, 2)
  end)

  T.it('Snapshot aggregates quantities per item id over bags 0 to 4', function()
    local W, P = boot()
    W.state.bags = {
      [0] = { size = 4, { 2589, 20 }, { 2589, 5 }, [4] = { 2770, 3 } },
      [1] = { size = 2, { 117, 1 } },
      [4] = { size = 1, { 2589, 1 } },
    }
    local snap = P.BagsModule.Snapshot()
    T.eq(snap.items[2589], 26); T.eq(snap.items[2770], 3); T.eq(snap.items[117], 1)
    T.eq(snap.slots, 5)
  end)

  T.it('an empty bag set gives an empty snapshot', function()
    local _, P = boot()
    local snap = P.BagsModule.Snapshot()
    T.eq(next(snap.items), nil); T.eq(snap.slots, 0)
  end)

  T.it('a missing C_Container gives nil and a reason', function()
    local W, P = boot()
    W.env.C_Container = nil
    local snap, why = P.BagsModule.Snapshot()
    T.isnil(snap); T.truthy(why:find('unavailable', 1, true))
  end)

  T.it('secret item ids are skipped and counted', function()
    local W, P = boot()
    W.state.bags = { [0] = { size = 2, { World.SECRET, 1 }, { 5, 1 } } }
    local snap = P.BagsModule.Snapshot()
    T.eq(snap.items[5], 1); T.eq(snap.slots, 1)
    T.eq(P.BagsModule.stats.unreadable, 1)
  end)

  T.it('a secret stack count is read as 1', function()
    local W, P = boot()
    W.state.bags = { [0] = { size = 1, { 5, World.SECRET } } }
    T.eq(P.BagsModule.Snapshot().items[5], 1)
  end)

  T.it('Snapshot reads nothing outside bags 0 to 5', function()
    local W, P = boot()
    local asked = {}
    local orig = W.env.C_Container.GetContainerNumSlots
    W.env.C_Container.GetContainerNumSlots = function(b) asked[#asked + 1] = b; return orig(b) end
    P.BagsModule.Snapshot()
    T.eq(asked, { 0, 1, 2, 3, 4, 5 })
  end)
end)

---------------------------------------------------------------------------
T.describe('Cast adapter (UNIT_SPELLCAST_SUCCEEDED)', function()
  T.it('player casts are emitted with the verified gathering kinds (E-23)', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_CAST')
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'Cast-3-1-2-3-2366-X', 2366)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 2575)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8617)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 7731)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 133)
    local kinds = {}
    for i, e in ipairs(seen) do kinds[i] = e.payload.kind end
    T.eq(kinds, { 'herb', 'mine', 'skin', 'fish', 'other' })
  end)

  T.it('other units are dropped at the first line, before any payload is touched', function()
    local W, P = boot()
    local seen = World.capture(P, 'P_CAST')
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'target', World.SECRET, World.SECRET)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'nameplate1', World.SECRET, World.SECRET)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'targettarget', 'c', 100)
    T.eq(#seen, 0)
    local c = P.Events.Counters('UNIT_SPELLCAST_SUCCEEDED')
    T.eq(c.dropped, 3); T.eq(c.kept, 0); T.eq(c.errors, 0)
  end)

  T.it('a player cast with a secret spell id is dropped and counted', function()
    local W, P = boot()
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', World.SECRET, World.SECRET)
    T.eq(P.Unit.castStats.secret, 1)
    T.eq(P.Events.Counters('UNIT_SPELLCAST_SUCCEEDED').dropped, 1)
  end)

  T.it('a player cast without a spell id is dropped', function()
    local W, P = boot()
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', nil)
    T.eq(P.Events.Counters('UNIT_SPELLCAST_SUCCEEDED').dropped, 1)
  end)

end)

T.describe('Cast kinds by spell name (all skill ranks)', function()
  local NAMES = { [2366] = 'Herbalism', [2368] = 'Herbalism', [2575] = 'Mining', [2576] = 'Mining', [8617] = 'Skinning', [8613] = 'Skinning',
                  [7731] = 'Fishing', [7732] = 'Fishing', [133] = 'Fireball' }
  local function bootNames(map)
    local W, P = boot()
    W.env.C_Spell = { GetSpellName = function(id) return (map or NAMES)[id] end }
    P.Unit.ResetNames()
    return W, P
  end
  T.it('any rank of a verified profession spell gets its kind; other spells stay other', function()
    local W, P = bootNames()
    local seen = World.capture(P, 'P_CAST')
    for _, id in ipairs({ 8613, 2368, 2576, 7732, 133, 999 }) do W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', id) end
    local kinds = {}
    for i, e in ipairs(seen) do kinds[i] = e.payload.kind end
    T.eq(kinds, { 'skin', 'herb', 'mine', 'fish', 'other', 'other' })
    T.truthy(P.LastCast('skin'))
  end)

  T.it('without a readable spell API the verified ids still work and nothing raises', function()
    local W, P = boot()
    W.env.C_Spell = nil
    P.Unit.ResetNames()
    local seen = World.capture(P, 'P_CAST')
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8617)
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8613)
    T.eq({ seen[1].payload.kind, seen[2].payload.kind }, { 'skin', 'other' })
  end)

  T.it('a secret or non-string name is ignored', function()
    local W, P = bootNames({ [8617] = 'Skinning' })
    W.env.C_Spell.GetSpellName = function(id) if id == 8613 then return World.SECRET end return id == 8617 and 'Skinning' or nil end
    P.Unit.ResetNames()
    local seen = World.capture(P, 'P_CAST')
    W:fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'c', 8613)
    T.eq(seen[1].payload.kind, 'other')
  end)
end)
