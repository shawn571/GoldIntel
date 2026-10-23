
GoldIntelDiagDB = {
["lab"] = {
["report"] = {
"Phase 3a lab report  1.60.1 build 70450  at 1792341039",
"P0 [review, suggested] Presence of every candidate API and event name",
"   api runs: 1",
"I1 [review, suggested] Item data: sell price, bind type, async behaviour",
"   api runs: 3",
"I2 [review, suggested] Bags: readable item fields and scan cost",
"   api runs: 1",
"A1 [review, suggested] AFK flag and related state",
"   api runs: 2",
"S1 [review, suggested] Map position in the open world and in an instance",
"   api runs: 5",
"   note: Rehgar Deadeye: Ragefire Chasm, entered and left once.",
"T2 [review, suggested] Movement speed, mounted, flying, swimming, taxi flags (single snapshot)",
"   api runs: 1",
"T1a [review, suggested] Taxi flag and position jumps over time (also covers T2, T3, T4)",
"   track: 75 samples, maxSpeed 7, taxi 0, maxJump 0.006, mapChanges 3",
"P1 [review, suggested] Function names inside the C_* tables found by P0 (names only, nothing is called)",
"   api runs: 1",
"P2 [review, suggested] Restriction and state getters found by P1 (no-argument getters and the restriction enum)",
"   api runs: 2",
"I1b [pass, suggested] Item data load completion event (async item info)",
"   GET_ITEM_INFO_RECEIVED: delivered 4, samples 4, IsEventRegistered true",
"   note: Dottie Slaps: fresh login, item data test",
"H1 [review, suggested] Place names for map coordinates",
"   api runs: 1",
"H2 [review, suggested] Map overlay host: a test square on the world map",
"   square: shown",
"   note: part of a red square around Sentinel Hill, not completely filled in. I will upload a screenshot of it.",
"L3 [review, suggested] Loot window slot data and source GUID",
"   api runs: 9",
"L1 [pass, suggested] LOOT_OPENED payload and order versus PLAYER_MONEY",
"   LOOT_OPENED: delivered 13, samples 13, IsEventRegistered true",
"   note: Rehgar Deadeye: fishing",
"   note: Sunder Slaps: mining",
"   note: Sunder Slaps: mining",
"   note: Grizzly Slaps: herb",
"   note: Divine Slaps: enchanter",
"L2 [pass, suggested] LOOT_SLOT_CLEARED per slot",
"   LOOT_SLOT_CLEARED: delivered 9, samples 9, IsEventRegistered true",
"M1 [pass, suggested] Merchant open/close, sale and purchase order versus money",
"   MERCHANT_SHOW: delivered 2, samples 2, IsEventRegistered true",
"   MERCHANT_CLOSED: delivered 3, samples 3, IsEventRegistered true",
"   note: Divine Slaps: MERCHANT_CLOSED, vendor Barkeep Morag",
"Q1 [pass, suggested] Quest turn-in payload",
"   QUEST_TURNED_IN: delivered 1, samples 1, IsEventRegistered true",
"X1 [pass, suggested] Mail events",
"   MAIL_CLOSED: delivered 0, samples 0, IsEventRegistered true",
"   MAIL_INBOX_UPDATE: delivered 20, samples 20, IsEventRegistered true",
"   note: Divine Slaps: mail receiver, 1 mail with money and a small stack of an item",
"   note: Divine Slaps: MAIL_CLOSED, mailbox holds an auction sale mail",
"X2 [review, suggested] Mailbox header metadata: sender, subject, money, items, auction invoice",
"   api runs: 12",
"   note: Divine Slaps: mailbox with 1. auction cancelled mail, 2. copper only mail, 3. item only mail, 4. item and copper mail",
"Q2 [pass, suggested] Quest reward item: bag snapshot diff and BAG_UPDATE_DELAYED",
"   BAG_UPDATE_DELAYED: delivered 2, samples 2, IsEventRegistered true",
"   api runs: 2",
"   note: Rehgar Deadeye: quest Hezrul Bloodmark, reward Bounty Hunter's Ring, fixed",
"AHS [review, suggested] Auction house state: money, window, own auctions (listing, cancel, buyout)",
"   api runs: 15",
"   note: Divine Slaps: auction house, listing, cancel, buyout, bid",
"   note: deposit shown 100 copper",
"   note: cancel window said will lose your initial deposit by canceling this auction",
"   note: buyout price shown 13 copper",
"   note: bid shown 101 copper",
"   note: bid price shown 300 copper, buyout 400 copper",
"AH1 [pass, suggested] Auction house events (one per session)",
"   AUCTION_HOUSE_AUCTION_CREATED: delivered 1, samples 1, IsEventRegistered true",
"   note: Chilly Slaps: session 23, post, cancel, buyout, bid, one snapshot after each",
"   note: deposit shown 100 copper",
"MS1 [inconclusive, suggested] Outgoing mail: postage and money sent",
"   api runs: 7",
"   note: Rehgar Deadeye: outgoing mail to my other character Divine Slaps, item, money, COD",
"   note: postage shown 30 copper",
"CO1 [inconclusive, suggested] COD mail: paying and receiving (uses X2 and MAIL_INBOX_UPDATE)",
"   note: Divine Slaps: paying a COD of 1 silver",
"   note: Rehgar Deadeye: COD payment mail and any other mails",
"R1 [pass, suggested] Trade events",
"   TRADE_ACCEPT_UPDATE: delivered 6, samples 6, IsEventRegistered true",
"   TRADE_MONEY_CHANGED: delivered 1, samples 1, IsEventRegistered true",
"   TRADE_SHOW: delivered 1, samples 1, IsEventRegistered true",
"   TRADE_CLOSED: delivered 4, samples 4, IsEventRegistered true",
"   note: Rehgar Deadeye: helper Blurr Technicolor",
"   note: round 1 TRADE_CLOSED, helper Blurr Technicolor",
"   note: round 2 TRADE_SHOW, helper Blurr Technicolor",
"   note: roudn 3 TRADE_ACCEPT_UPDATE, helper Blurr Technicolor",
"   note: round 3 try 2 TRADE_ACCEPT_UPDATE, helper Blurr Technicolor",
"   note: round 4 TRADE_MONEY_CHANGED, helper Blurr Technicolor",
"T1b [not run] Taxi and control events",
"C1 [fail, suggested] UNIT_SPELLCAST_SUCCEEDED (highest suspicion of the old popup)",
"   UNIT_SPELLCAST_SUCCEEDED: delivered 39, samples 39, IsEventRegistered true",
"   note: Chilly Slaps: skinning",
"   note: Grizzly Slaps: herb",
"   note: Sunder Slaps: mining",
"   note: Rehgar Deadeye: fishing",
"   note: Divine Slaps: enchanter cast",
"C2 [not run] CHAT_MSG_MONEY (only if L1 fails)",
},
["version"] = 1,
["lastRegisterAttempt"] = "MAIL_INBOX_UPDATE",
["runs"] = {
["T2"] = {
["title"] = "Movement speed, mounted, flying, swimming, taxi flags (single snapshot)",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "GetUnitSpeed(player)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 4.722221851348877,
["type"] = "number",
},
},
},
{
["fn"] = "IsMounted()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsFlying()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsSwimming()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsFalling()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitOnTaxi(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "T2",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["X2"] = {
["title"] = "Mailbox header metadata: sender, subject, money, items, auction invoice",
["notes"] = {
"Divine Slaps: mailbox with 1. auction cancelled mail, 2. copper only mail, 3. item only mail, 4. item and copper mail",
},
["events"] = {
},
["api"] = {
{
["gt"] = 1408.913,
["label"] = "mailbox",
["t"] = 1792328737,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "false",
},
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 3,
["type"] = "number",
},
{
["value"] = 3,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "copper only",
["type"] = "string",
["len"] = 11,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99967575073242,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99954795837402,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99934005737305,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 1494.454,
["label"] = "mailbox",
["t"] = 1792328822,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "false",
},
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 3,
["type"] = "number",
},
{
["value"] = 3,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "copper only",
["type"] = "string",
["len"] = 11,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99967575073242,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99954795837402,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99934005737305,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 1658.927,
["label"] = "mailbox",
["t"] = 1792328987,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 4,
["type"] = "number",
},
{
["value"] = 4,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Chunk of Boar Meat",
["type"] = "string",
["len"] = 36,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.99980354309082,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Chunk of Boar Meat",
["type"] = "string",
["len"] = 18,
},
{
["value"] = 769,
["type"] = "number",
},
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "copper only",
["type"] = "string",
["len"] = 11,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99549674987793,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99537086486816,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(4)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99516296386719,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(4)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(4)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 1723.068,
["label"] = "after-take",
["t"] = 1792329051,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 3,
["type"] = "number",
},
{
["value"] = 3,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Chunk of Boar Meat",
["type"] = "string",
["len"] = 36,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.99980354309082,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Chunk of Boar Meat",
["type"] = "string",
["len"] = 18,
},
{
["value"] = 769,
["type"] = "number",
},
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99537086486816,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99516296386719,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 7483.425,
["label"] = "sale",
["t"] = 1792334811,
["restr"] = 0,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 4,
["type"] = "number",
},
{
["value"] = 4,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction successful: Strange Dust",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 149,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.99638938903809,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "seller",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Strange Dust",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "",
["type"] = "string",
["len"] = 0,
},
{
["value"] = 51,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 100,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Chunk of Boar Meat",
["type"] = "string",
["len"] = 36,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.9322452545166,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Chunk of Boar Meat",
["type"] = "string",
["len"] = 18,
},
{
["value"] = 769,
["type"] = "number",
},
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.92781257629395,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(4)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.92760467529297,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(4)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(4)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
},
{
["gt"] = 7508.357,
["label"] = "after-take",
["t"] = 1792334836,
["restr"] = 0,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 3,
["type"] = "number",
},
{
["value"] = 3,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Chunk of Boar Meat",
["type"] = "string",
["len"] = 36,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.9322452545166,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Chunk of Boar Meat",
["type"] = "string",
["len"] = 18,
},
{
["value"] = 769,
["type"] = "number",
},
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.92781257629395,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.92760467529297,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
},
{
["gt"] = 13375.019,
["label"] = "cod",
["t"] = 1792340703,
["restr"] = 0,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["summary"] = {
["copper"] = "160",
},
["fn"] = "money",
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 4,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 8,
["type"] = "number",
},
{
["value"] = 8,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134437,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Spider Ichor (4)",
["type"] = "string",
["len"] = 16,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 100,
["type"] = "number",
},
{
["value"] = 2.996412038803101,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 4,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:3174::::::::7:1487:::::::::|h[Spider Ichor]|h|r",
["type"] = "string",
["len"] = 61,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Spider Ichor",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 3174,
["type"] = "number",
},
{
["value"] = 134437,
["type"] = "number",
},
{
["value"] = 4,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:3174::::::::7:1487:::::::::|h[Spider Ichor]|h|r",
["type"] = "string",
["len"] = 61,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "30 copper",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 30,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99549674987793,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 132815,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Ice Cold Milk",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99485015869141,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:1179::::::::7:1487:::::::::|h[Ice Cold Milk]|h|r",
["type"] = "string",
["len"] = 62,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Ice Cold Milk",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 1179,
["type"] = "number",
},
{
["value"] = 132815,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:1179::::::::7:1487:::::::::|h[Ice Cold Milk]|h|r",
["type"] = "string",
["len"] = 62,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(4)",
["present"] = true,
["returns"] = {
{
["value"] = 134106,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction won: Malachite",
["type"] = "string",
["len"] = 22,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.95676994323731,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:774::::::::7:1487:::::::::|h[Malachite]|h|r",
["type"] = "string",
["len"] = 57,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(4)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(4)",
["present"] = true,
["returns"] = {
{
["value"] = "buyer",
["type"] = "string",
["len"] = 5,
},
{
["value"] = "Malachite",
["type"] = "string",
["len"] = 9,
},
{
["value"] = "先吃 再救人",
["type"] = "string",
["len"] = 16,
},
{
["value"] = 12,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItem(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Malachite",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 774,
["type"] = "number",
},
{
["value"] = 134106,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:774::::::::7:1487:::::::::|h[Malachite]|h|r",
["type"] = "string",
["len"] = 57,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(5)",
["present"] = true,
["returns"] = {
{
["value"] = 132179,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Small Furry Paw",
["type"] = "string",
["len"] = 33,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.95596122741699,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:5134::::::::7:1487:::::::::|h[Small Furry Paw]|h|r",
["type"] = "string",
["len"] = 64,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(5)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(5)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(5,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Small Furry Paw",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 5134,
["type"] = "number",
},
{
["value"] = 132179,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(5,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:5134::::::::7:1487:::::::::|h[Small Furry Paw]|h|r",
["type"] = "string",
["len"] = 64,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(6)",
["present"] = true,
["returns"] = {
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Chunk of Boar Meat",
["type"] = "string",
["len"] = 36,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.86406326293945,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(6)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(6)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(6,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Chunk of Boar Meat",
["type"] = "string",
["len"] = 18,
},
{
["value"] = 769,
["type"] = "number",
},
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(6,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(7)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.85962867736816,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(7)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(7)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(7,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(7,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(8)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.85942077636719,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(8)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(8)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(8,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(8,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
},
{
["gt"] = 13404.432,
["label"] = "cod-paid",
["t"] = 1792340732,
["restr"] = 0,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["summary"] = {
["copper"] = "60",
},
["fn"] = "money",
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "30 copper",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 30,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99549674987793,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 132815,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Ice Cold Milk",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99485015869141,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:1179::::::::7:1487:::::::::|h[Ice Cold Milk]|h|r",
["type"] = "string",
["len"] = 62,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Ice Cold Milk",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 1179,
["type"] = "number",
},
{
["value"] = 132815,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:1179::::::::7:1487:::::::::|h[Ice Cold Milk]|h|r",
["type"] = "string",
["len"] = 62,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 134106,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction won: Malachite",
["type"] = "string",
["len"] = 22,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.95676994323731,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:774::::::::7:1487:::::::::|h[Malachite]|h|r",
["type"] = "string",
["len"] = 57,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = "buyer",
["type"] = "string",
["len"] = 5,
},
{
["value"] = "Malachite",
["type"] = "string",
["len"] = 9,
},
{
["value"] = "先吃 再救人",
["type"] = "string",
["len"] = 16,
},
{
["value"] = 12,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Malachite",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 774,
["type"] = "number",
},
{
["value"] = 134106,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:774::::::::7:1487:::::::::|h[Malachite]|h|r",
["type"] = "string",
["len"] = 57,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(4)",
["present"] = true,
["returns"] = {
{
["value"] = 132179,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Small Furry Paw",
["type"] = "string",
["len"] = 33,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.95596122741699,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:5134::::::::7:1487:::::::::|h[Small Furry Paw]|h|r",
["type"] = "string",
["len"] = 64,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(4)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(4)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Small Furry Paw",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 5134,
["type"] = "number",
},
{
["value"] = 132179,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:5134::::::::7:1487:::::::::|h[Small Furry Paw]|h|r",
["type"] = "string",
["len"] = 64,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(5)",
["present"] = true,
["returns"] = {
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Chunk of Boar Meat",
["type"] = "string",
["len"] = 36,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.86406326293945,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(5)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(5)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(5,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Chunk of Boar Meat",
["type"] = "string",
["len"] = 18,
},
{
["value"] = 769,
["type"] = "number",
},
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(5,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(6)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.85962867736816,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(6)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(6)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(6,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(6,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(7)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.85942077636719,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(7)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(7)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(7,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(7,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
},
{
["gt"] = 13419.296,
["label"] = "taken",
["t"] = 1792340747,
["restr"] = 0,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["summary"] = {
["copper"] = "90",
},
["fn"] = "money",
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 6,
["type"] = "number",
},
{
["value"] = 6,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 132815,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Ice Cold Milk",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99485015869141,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:1179::::::::7:1487:::::::::|h[Ice Cold Milk]|h|r",
["type"] = "string",
["len"] = 62,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Ice Cold Milk",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 1179,
["type"] = "number",
},
{
["value"] = 132815,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:1179::::::::7:1487:::::::::|h[Ice Cold Milk]|h|r",
["type"] = "string",
["len"] = 62,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 134106,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction won: Malachite",
["type"] = "string",
["len"] = 22,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.95676994323731,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:774::::::::7:1487:::::::::|h[Malachite]|h|r",
["type"] = "string",
["len"] = 57,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = "buyer",
["type"] = "string",
["len"] = 5,
},
{
["value"] = "Malachite",
["type"] = "string",
["len"] = 9,
},
{
["value"] = "先吃 再救人",
["type"] = "string",
["len"] = 16,
},
{
["value"] = 12,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Malachite",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 774,
["type"] = "number",
},
{
["value"] = 134106,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:774::::::::7:1487:::::::::|h[Malachite]|h|r",
["type"] = "string",
["len"] = 57,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 132179,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Small Furry Paw",
["type"] = "string",
["len"] = 33,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.95596122741699,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:5134::::::::7:1487:::::::::|h[Small Furry Paw]|h|r",
["type"] = "string",
["len"] = 64,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Small Furry Paw",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 5134,
["type"] = "number",
},
{
["value"] = 132179,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:5134::::::::7:1487:::::::::|h[Small Furry Paw]|h|r",
["type"] = "string",
["len"] = 64,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(4)",
["present"] = true,
["returns"] = {
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Chunk of Boar Meat",
["type"] = "string",
["len"] = 36,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.86406326293945,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(4)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(4)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Chunk of Boar Meat",
["type"] = "string",
["len"] = 18,
},
{
["value"] = 769,
["type"] = "number",
},
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(5)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.85962867736816,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(5)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(5)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(5,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(5,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(6)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.85942077636719,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(6)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(6)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(6,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(6,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
},
{
["gt"] = 13429.339,
["label"] = "taken",
["t"] = 1792340757,
["restr"] = 0,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["summary"] = {
["copper"] = "90",
},
["fn"] = "money",
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134106,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction won: Malachite",
["type"] = "string",
["len"] = 22,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.95676994323731,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:774::::::::7:1487:::::::::|h[Malachite]|h|r",
["type"] = "string",
["len"] = 57,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "buyer",
["type"] = "string",
["len"] = 5,
},
{
["value"] = "Malachite",
["type"] = "string",
["len"] = 9,
},
{
["value"] = "先吃 再救人",
["type"] = "string",
["len"] = 16,
},
{
["value"] = 12,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Malachite",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 774,
["type"] = "number",
},
{
["value"] = 134106,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:774::::::::7:1487:::::::::|h[Malachite]|h|r",
["type"] = "string",
["len"] = 57,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 132179,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Small Furry Paw",
["type"] = "string",
["len"] = 33,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.95596122741699,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:5134::::::::7:1487:::::::::|h[Small Furry Paw]|h|r",
["type"] = "string",
["len"] = 64,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(2)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(2)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Small Furry Paw",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 5134,
["type"] = "number",
},
{
["value"] = 132179,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(2,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:5134::::::::7:1487:::::::::|h[Small Furry Paw]|h|r",
["type"] = "string",
["len"] = 64,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(3)",
["present"] = true,
["returns"] = {
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 134939,
["type"] = "number",
},
{
["value"] = "Horde Auction House",
["type"] = "string",
["len"] = 19,
},
{
["value"] = "Auction canceled: Chunk of Boar Meat",
["type"] = "string",
["len"] = 36,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 29.86406326293945,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(3)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(3)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Chunk of Boar Meat",
["type"] = "string",
["len"] = 18,
},
{
["value"] = 769,
["type"] = "number",
},
{
["value"] = 133970,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(3,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:769::::::::7:1487:::::::::|h[Chunk of Boar Meat]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(4)",
["present"] = true,
["returns"] = {
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item only",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.85962867736816,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(4)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(4)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Shadowgem",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1210,
["type"] = "number",
},
{
["value"] = 134074,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(4,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:1210::::::::7:1487:::::::::|h[Shadowgem]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["fn"] = "GetInboxHeaderInfo(5)",
["present"] = true,
["returns"] = {
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Rehgar Deadeye",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "Item and copper",
["type"] = "string",
["len"] = 15,
},
{
["value"] = 50,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.85942077636719,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(5)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(5)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(5,1)",
["present"] = true,
["returns"] = {
{
["value"] = "Light Leather Quiver",
["type"] = "string",
["len"] = 20,
},
{
["value"] = 7278,
["type"] = "number",
},
{
["value"] = 134401,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxItemLink(5,1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:7278::::::::7:1487:::::::::|h[Light Leather Quiver]|h|r",
["type"] = "string",
["len"] = 69,
},
},
},
},
},
{
["gt"] = 13645.476,
["label"] = "all-mail",
["t"] = 1792340973,
["restr"] = 0,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["summary"] = {
["copper"] = "6038",
},
["fn"] = "money",
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 15,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxHeaderInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["value"] = 134327,
["type"] = "number",
},
{
["value"] = "Divine Slaps",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "COD Payment: Spider Ichor (4)",
["type"] = "string",
["len"] = 29,
},
{
["value"] = 100,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 30.99709510803223,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney(1)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetInboxInvoiceInfo(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxItem(1,1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetInboxItemLink(1,1)",
["present"] = true,
["returns"] = {
},
},
},
},
{
["gt"] = 13704.713,
["label"] = "cod-money",
["t"] = 1792341032,
["restr"] = 0,
["results"] = {
{
["fn"] = "MailFrame:IsShown()",
["present"] = true,
["summary"] = {
["shown"] = "true",
},
},
{
["summary"] = {
["copper"] = "6138",
},
["fn"] = "money",
},
{
["fn"] = "C_Mail.CanCheckInbox()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "GetInboxNumItems()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
},
},
},
["id"] = "X2",
["startedAt"] = 1792328737,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["X1"] = {
["events"] = {
["MAIL_CLOSED"] = {
["registerCall"] = "returned normally",
["delivered"] = 0,
["samples"] = {
},
["attemptedAt"] = 1792334773,
["isEventRegistered"] = true,
},
["MAIL_INBOX_UPDATE"] = {
["registerCall"] = "returned normally",
["delivered"] = 20,
["samples"] = {
{
["gt"] = 513801.98,
["args"] = {
},
["money"] = 317,
["t"] = 1792284467,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 513806.156,
["args"] = {
},
["money"] = 317,
["t"] = 1792284472,
["restr"] = 0,
["n"] = 0,
},
{
["restr"] = 0,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.365,
},
},
["args"] = {
},
["money"] = 317,
["t"] = 1792284473,
["gt"] = 513807.454,
["n"] = 0,
},
{
["gt"] = 513810.884,
["args"] = {
},
["money"] = 367,
["t"] = 1792284476,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 513810.999,
["args"] = {
},
["money"] = 367,
["t"] = 1792284476,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 13364.04,
["args"] = {
},
["money"] = 160,
["t"] = 1792340692,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 13383.573,
["args"] = {
},
["money"] = 160,
["t"] = 1792340711,
["restr"] = 0,
["n"] = 0,
},
{
["restr"] = 0,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.269,
},
},
["args"] = {
},
["money"] = 160,
["t"] = 1792340722,
["gt"] = 13394.252,
["n"] = 0,
},
{
["restr"] = 0,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.106,
},
},
["args"] = {
},
["money"] = 160,
["t"] = 1792340722,
["gt"] = 13394.415,
["n"] = 0,
},
{
["gt"] = 13409.718,
["args"] = {
},
["money"] = 60,
["t"] = 1792340737,
["restr"] = 0,
["n"] = 0,
},
{
["restr"] = 0,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.233,
},
},
["args"] = {
},
["money"] = 60,
["t"] = 1792340741,
["gt"] = 13412.863,
["n"] = 0,
},
{
["before"] = {
["event"] = "PLAYER_MONEY",
["dt"] = 0,
},
["gt"] = 13413.096,
["args"] = {
},
["money"] = 90,
["t"] = 1792340741,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 13422.297,
["args"] = {
},
["money"] = 90,
["t"] = 1792340750,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 13424.262,
["args"] = {
},
["money"] = 90,
["t"] = 1792340752,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 13424.469,
["args"] = {
},
["money"] = 90,
["t"] = 1792340752,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 13628.987,
["args"] = {
},
["money"] = 6038,
["t"] = 1792340957,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 13628.987,
["args"] = {
},
["money"] = 6038,
["t"] = 1792340957,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 13645.01,
["args"] = {
},
["money"] = 6038,
["t"] = 1792340973,
["restr"] = 0,
["n"] = 0,
},
{
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.434,
},
},
["gt"] = 13690.409,
["args"] = {
},
["money"] = 6038,
["t"] = 1792341018,
["restr"] = 0,
["n"] = 0,
},
{
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.267,
},
},
["gt"] = 13690.576,
["args"] = {
},
["money"] = 6038,
["t"] = 1792341018,
["restr"] = 0,
["n"] = 0,
},
},
["attemptedAt"] = 1792340930,
["isEventRegistered"] = true,
},
},
["notes"] = {
"Divine Slaps: mail receiver, 1 mail with money and a small stack of an item",
"Divine Slaps: MAIL_CLOSED, mailbox holds an auction sale mail",
},
["title"] = "Mail events",
["api"] = {
},
["id"] = "X1",
["status"] = "open",
["startedAt"] = 1792284413,
["build"] = "1.60.1 build 70450",
},
["A1"] = {
["title"] = "AFK flag and related state",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "UnitIsAFK(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitIsDND(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsResting()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitIsDeadOrGhost(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_FLAGS_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_UPDATE_RESTING)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
{
["label"] = "afk",
["t"] = 1792269343,
["gt"] = 498677.407,
["results"] = {
{
["fn"] = "UnitIsAFK(player)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitIsDND(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsResting()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitIsDeadOrGhost(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_FLAGS_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_UPDATE_RESTING)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "A1",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["CO1"] = {
["events"] = {
},
["notes"] = {
"Divine Slaps: paying a COD of 1 silver",
"Rehgar Deadeye: COD payment mail and any other mails",
},
["title"] = "COD mail: paying and receiving (uses X2 and MAIL_INBOX_UPDATE)",
["api"] = {
},
["id"] = "CO1",
["status"] = "open",
["startedAt"] = 1792340689,
["build"] = "1.60.1 build 70450",
},
["Q1"] = {
["events"] = {
["QUEST_TURNED_IN"] = {
["registerCall"] = "returned normally",
["delivered"] = 1,
["samples"] = {
{
["restr"] = 0,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.041,
},
},
["args"] = {
{
["value"] = 818,
["type"] = "number",
},
{
["value"] = 625,
["type"] = "number",
},
{
["value"] = 175,
["type"] = "number",
},
},
["money"] = 148,
["t"] = 1792275755,
["gt"] = 505089.307,
["n"] = 3,
},
},
["attemptedAt"] = 1792275733,
["isEventRegistered"] = true,
},
},
["notes"] = {
},
["title"] = "Quest turn-in payload",
["api"] = {
},
["id"] = "Q1",
["status"] = "open",
["startedAt"] = 1792275733,
["build"] = "1.60.1 build 70450",
},
["C1"] = {
["events"] = {
["UNIT_SPELLCAST_SUCCEEDED"] = {
["registerCall"] = "returned normally",
["delivered"] = 39,
["samples"] = {
{
["gt"] = 506048.554,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-DCE63559D1",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["type"] = "nil",
},
},
["money"] = 18039,
["t"] = 1792276714,
["restr"] = 0,
["n"] = 4,
},
{
["gt"] = 506051.373,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-A9EFE9CCE7",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-23D20BAF474EA765",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276717,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506051.373,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-837-A9EFE9CCE7",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-4D386B1D321D4EEF",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276717,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506053.009,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-7C4A8FAD64",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-7AF98CF2E7AF8D5A",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276719,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506053.009,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-837-7C4A8FAD64",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-F63345FFFA511490",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276719,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506054.627,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-6713AAD092",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-1BE2BF994B8E0B82",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276720,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506054.627,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-837-6713AAD092",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-AA8BA180FD16387",
["type"] = "string",
["len"] = 23,
},
},
["money"] = 18039,
["t"] = 1792276720,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506054.821,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-122-6AF399AFA0",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 122,
["type"] = "number",
},
{
["type"] = "nil",
},
},
["money"] = 18039,
["t"] = 1792276720,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506054.821,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-122-6AF399AFA0",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 122,
["type"] = "number",
},
{
["type"] = "nil",
},
},
["money"] = 18039,
["t"] = 1792276720,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506059.053,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-4311B420CA",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-A264EA6FC6091D1D",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276725,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506060.774,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-AC17C301C7",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-1CAA0A8B70DA52D0",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276726,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506060.774,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-837-AC17C301C7",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-35D4836FB6E61B9E",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276726,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506062.401,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-BE76F4AFB3",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-1929478980CCE53C",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276728,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506062.401,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-837-BE76F4AFB3",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-F456522DC7A71EBC",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276728,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506065.046,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-82AFA3FCB1",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-6C518B6D029C5C04",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276731,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506065.046,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-837-82AFA3FCB1",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-116199494421A54C",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276731,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506067.413,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-7CD70EBD20",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-B1AD3BD74C289C0D",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276733,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506067.413,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-837-7CD70EBD20",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-4F8B81177CBFC199",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276733,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506067.517,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-2136-82C95182B3",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 2136,
["type"] = "number",
},
{
["type"] = "nil",
},
},
["money"] = 18039,
["t"] = 1792276733,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506067.517,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-2136-82C95182B3",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 2136,
["type"] = "number",
},
{
["type"] = "nil",
},
},
["money"] = 18039,
["t"] = 1792276733,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506071.412,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-837-CEFED25A41",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-F9A03B263940CCC",
["type"] = "string",
["len"] = 23,
},
},
["money"] = 18039,
["t"] = 1792276737,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506071.412,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-4621-0-10-837-CEFED25A41",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 837,
["type"] = "number",
},
{
["value"] = "CastBar-5500D675DD586938",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276737,
["restr"] = 2,
["n"] = 4,
},
{
["gt"] = 506085.028,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-0-10-8617-7BF53BDB8B",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 8617,
["type"] = "number",
},
{
["value"] = "CastBar-556182AC27574722",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 18039,
["t"] = 1792276751,
["restr"] = 0,
["n"] = 4,
},
{
["gt"] = 506222.989,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-1-12-5176-00B1680863",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-F6A2E1765411A549",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276889,
["n"] = 4,
["restr"] = 0,
},
{
["gt"] = 506223.208,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-1-12-8921-A4D7F8DF1D",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 8921,
["type"] = "number",
},
{
["type"] = "nil",
},
},
["money"] = 145,
["t"] = 1792276889,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506227.949,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-1-12-5176-14CA6632F6",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-C3C160A449ABCD77",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276894,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506227.949,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-6782-1-12-5176-14CA6632F6",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-DCC02BB1A59D5A22",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276894,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506231.268,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-1-12-5176-5AC981814C",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-E32DE7E66D74638A",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276897,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506231.268,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-6782-1-12-5176-5AC981814C",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-647A7797FF319E94",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276897,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506234.569,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-1-12-5176-FF92977B59",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-E3DB01527C99F27C",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276900,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506234.569,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-6782-1-12-5176-FF92977B59",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-26825EBB70F9C1D8",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276900,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506236.154,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-1-12-5176-34E041C9D5",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-2BA2A13B633E8A2A",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276902,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506236.154,
["args"] = {
{
["value"] = "targettarget",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "Cast-3-6782-1-12-5176-34E041C9D5",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 5176,
["type"] = "number",
},
{
["value"] = "CastBar-DE78AFF9188D7A07",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276902,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506238.697,
["args"] = {
{
["value"] = "nameplate1",
["type"] = "string",
["len"] = 10,
},
{
["type"] = "secret",
["secret"] = true,
},
{
["type"] = "secret",
["secret"] = true,
},
{
["value"] = "CastBar-6045BB7F03A599A",
["type"] = "string",
["len"] = 23,
},
},
["money"] = 145,
["t"] = 1792276904,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506238.697,
["args"] = {
{
["value"] = "target",
["type"] = "string",
["len"] = 6,
},
{
["type"] = "secret",
["secret"] = true,
},
{
["type"] = "secret",
["secret"] = true,
},
{
["value"] = "CastBar-7101CE6DE1CF7C31",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276904,
["n"] = 4,
["restr"] = 2,
},
{
["gt"] = 506249.729,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-1-12-2366-F5BB028063",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 2366,
["type"] = "number",
},
{
["value"] = "CastBar-7D777DE91D28690A",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 145,
["t"] = 1792276915,
["n"] = 4,
["restr"] = 0,
},
{
["gt"] = 506349.969,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-0-8-2575-702B996D5E",
["type"] = "string",
["len"] = 31,
},
{
["value"] = 2575,
["type"] = "number",
},
{
["value"] = "CastBar-21DC55F43AADEF61",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 190,
["t"] = 1792277016,
["restr"] = 0,
["n"] = 4,
},
{
["gt"] = 506532.76,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-4621-1-15-7731-ADA051081C",
["type"] = "string",
["len"] = 32,
},
{
["value"] = 7731,
["type"] = "number",
},
{
["type"] = "nil",
},
},
["money"] = 6686,
["t"] = 1792277198,
["n"] = 4,
["restr"] = 0,
},
{
["gt"] = 509603.468,
["args"] = {
{
["value"] = "player",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "Cast-3-6782-1-22-13262-727451BD77",
["type"] = "string",
["len"] = 33,
},
{
["value"] = 13262,
["type"] = "number",
},
{
["value"] = "CastBar-66E6EAD72836F703",
["type"] = "string",
["len"] = 24,
},
},
["money"] = 317,
["t"] = 1792280269,
["n"] = 4,
["restr"] = 0,
},
},
["attemptedAt"] = 1792280229,
["isEventRegistered"] = true,
},
},
["notes"] = {
"Chilly Slaps: skinning",
"Grizzly Slaps: herb",
"Sunder Slaps: mining",
"Rehgar Deadeye: fishing",
"Divine Slaps: enchanter cast",
},
["title"] = "UNIT_SPELLCAST_SUCCEEDED (highest suspicion of the old popup)",
["api"] = {
},
["id"] = "C1",
["status"] = "open",
["startedAt"] = 1792276702,
["build"] = "1.60.1 build 70450",
},
["Q2"] = {
["events"] = {
["BAG_UPDATE_DELAYED"] = {
["registerCall"] = "returned normally",
["delivered"] = 2,
["samples"] = {
{
["restr"] = 0,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.15,
},
},
["args"] = {
},
["money"] = 5358,
["t"] = 1792334214,
["gt"] = 6886.526,
["n"] = 0,
},
{
["before"] = {
["event"] = "PLAYER_MONEY",
["dt"] = 0.289,
},
["gt"] = 6886.965,
["args"] = {
},
["money"] = 6158,
["t"] = 1792334215,
["restr"] = 0,
["n"] = 0,
},
},
["attemptedAt"] = 1792334106,
["isEventRegistered"] = true,
},
},
["notes"] = {
"Rehgar Deadeye: quest Hezrul Bloodmark, reward Bounty Hunter's Ring, fixed",
},
["title"] = "Quest reward item: bag snapshot diff and BAG_UPDATE_DELAYED",
["api"] = {
{
["gt"] = 6881.203,
["label"] = "before",
["t"] = 1792334209,
["restr"] = 0,
["results"] = {
{
["fn"] = "bag snapshot",
["present"] = true,
["summary"] = {
["stacks"] = 47,
["secretResults"] = 0,
["label"] = "before",
["money"] = "5358",
["slots"] = 52,
},
},
{
["summary"] = {
["note"] = "snapshot kept in memory; now turn in the quest, then run: /gidiag lab api Q2 after",
},
["fn"] = "stored",
},
},
},
{
["gt"] = 6897.282,
["label"] = "after",
["t"] = 1792334225,
["restr"] = 0,
["results"] = {
{
["fn"] = "bag snapshot",
["present"] = true,
["summary"] = {
["stacks"] = 47,
["secretResults"] = 0,
["label"] = "after",
["money"] = "6158",
["slots"] = 52,
},
},
{
["summary"] = {
["before"] = 1,
["itemID"] = 5025,
["link"] = "|cnIQ1:|Hitem:5025::::::::20:1489:::::::::|h[Hezrul's Head]|h|r",
["delta"] = -1,
["after"] = 0,
},
["fn"] = "removed item 5025",
},
{
["summary"] = {
["before"] = 0,
["itemID"] = 5351,
["link"] = "|cnIQ2:|Hitem:5351::::::::20:1489::11:::::::|h[Bounty Hunter's Ring]|h|r",
["delta"] = 1,
["after"] = 1,
},
["fn"] = "added item 5351",
},
{
["summary"] = {
["changedItems"] = 2,
["moneyDelta"] = "800",
["shown"] = 2,
},
["fn"] = "diff total",
},
},
},
},
["id"] = "Q2",
["status"] = "open",
["startedAt"] = 1792334106,
["build"] = "1.60.1 build 70450",
},
["AH1"] = {
["title"] = "Auction house events (one per session)",
["notes"] = {
"Chilly Slaps: session 23, post, cancel, buyout, bid, one snapshot after each",
"deposit shown 100 copper",
},
["events"] = {
["AUCTION_HOUSE_AUCTION_CREATED"] = {
["registerCall"] = "returned normally",
["delivered"] = 1,
["samples"] = {
{
["n"] = 1,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.358,
},
},
["args"] = {
{
["value"] = 66684760,
["type"] = "number",
},
},
["money"] = 18039,
["t"] = 1792338077,
["gt"] = 10749.372,
["restr"] = 0,
},
},
["attemptedAt"] = 1792337969,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "AH1",
["startedAt"] = 1792337969,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["T1a"] = {
["track"] = {
["stoppedBecause"] = "stopped by user",
["seconds"] = 300,
["startedAt"] = 1792280763,
["analysis"] = {
["maxJump"] = 0.006,
["maxSpeed"] = 7,
["mountedSamples"] = 0,
["taxiSamples"] = 0,
["samples"] = 75,
["mapChanges"] = 3,
["maxGap"] = 2.34,
},
["samples"] = {
{
["mounted"] = false,
["gt"] = 510098.944,
["taxi"] = false,
["t"] = 1792280764,
["run"] = 7,
["swimming"] = false,
["y"] = 0.51,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.506,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510099.945,
["taxi"] = false,
["t"] = 1792280765,
["run"] = 7,
["swimming"] = false,
["y"] = 0.51,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.506,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510100.949,
["taxi"] = false,
["t"] = 1792280766,
["run"] = 7,
["swimming"] = false,
["y"] = 0.509,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1454,
["x"] = 0.508,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510101.965,
["taxi"] = false,
["t"] = 1792280767,
["run"] = 7,
["swimming"] = false,
["y"] = 0.504,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1454,
["x"] = 0.512,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510102.98,
["taxi"] = false,
["t"] = 1792280769,
["run"] = 7,
["swimming"] = false,
["y"] = 0.5,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1454,
["x"] = 0.516,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510103.991,
["taxi"] = false,
["t"] = 1792280770,
["run"] = 7,
["swimming"] = false,
["y"] = 0.496,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1454,
["x"] = 0.52,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510104.992,
["taxi"] = false,
["t"] = 1792280771,
["run"] = 7,
["swimming"] = false,
["y"] = 0.493,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1454,
["x"] = 0.525,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510106.005,
["taxi"] = false,
["t"] = 1792280772,
["run"] = 7,
["swimming"] = false,
["y"] = 0.49,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1454,
["x"] = 0.529,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510107.005,
["taxi"] = false,
["t"] = 1792280773,
["run"] = 7,
["swimming"] = false,
["y"] = 0.487,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1454,
["x"] = 0.534,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510108.019,
["taxi"] = false,
["t"] = 1792280774,
["run"] = 7,
["swimming"] = false,
["y"] = 0.485,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.536,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510109.027,
["taxi"] = false,
["t"] = 1792280775,
["run"] = 0,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510110.052,
["taxi"] = false,
["t"] = 1792280776,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510111.06,
["taxi"] = false,
["t"] = 1792280777,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510112.068,
["taxi"] = false,
["t"] = 1792280778,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510113.068,
["taxi"] = false,
["t"] = 1792280779,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510114.069,
["taxi"] = false,
["t"] = 1792280780,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510115.069,
["taxi"] = false,
["t"] = 1792280781,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510116.07,
["taxi"] = false,
["t"] = 1792280782,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510117.07,
["taxi"] = false,
["t"] = 1792280783,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510118.07,
["taxi"] = false,
["t"] = 1792280784,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510119.071,
["taxi"] = false,
["t"] = 1792280785,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510120.071,
["taxi"] = false,
["t"] = 1792280786,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510121.072,
["taxi"] = false,
["t"] = 1792280787,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510122.072,
["taxi"] = false,
["t"] = 1792280788,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510123.072,
["taxi"] = false,
["t"] = 1792280789,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510124.073,
["taxi"] = false,
["t"] = 1792280790,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510125.073,
["taxi"] = false,
["t"] = 1792280791,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510126.073,
["taxi"] = false,
["t"] = 1792280792,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510127.074,
["taxi"] = false,
["t"] = 1792280793,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510128.074,
["taxi"] = false,
["t"] = 1792280794,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510129.075,
["taxi"] = false,
["t"] = 1792280795,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510130.075,
["taxi"] = false,
["t"] = 1792280796,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510131.075,
["taxi"] = false,
["t"] = 1792280797,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510132.085,
["taxi"] = false,
["t"] = 1792280798,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510133.085,
["taxi"] = false,
["t"] = 1792280799,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510134.085,
["taxi"] = false,
["t"] = 1792280800,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510135.086,
["taxi"] = false,
["t"] = 1792280801,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510136.086,
["taxi"] = false,
["t"] = 1792280802,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510137.086,
["taxi"] = false,
["t"] = 1792280803,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510138.087,
["taxi"] = false,
["t"] = 1792280804,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510139.087,
["taxi"] = false,
["t"] = 1792280805,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510140.088,
["taxi"] = false,
["t"] = 1792280806,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510141.088,
["taxi"] = false,
["t"] = 1792280807,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510142.088,
["taxi"] = false,
["t"] = 1792280808,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510143.089,
["taxi"] = false,
["t"] = 1792280809,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510144.089,
["taxi"] = false,
["t"] = 1792280810,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510145.089,
["taxi"] = false,
["t"] = 1792280811,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510146.09,
["taxi"] = false,
["t"] = 1792280812,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510147.09,
["taxi"] = false,
["t"] = 1792280813,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510148.091,
["taxi"] = false,
["t"] = 1792280814,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510149.091,
["taxi"] = false,
["t"] = 1792280815,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510150.091,
["taxi"] = false,
["t"] = 1792280816,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510151.092,
["taxi"] = false,
["t"] = 1792280817,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510152.092,
["taxi"] = false,
["t"] = 1792280818,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510153.093,
["taxi"] = false,
["t"] = 1792280819,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 7,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510154.093,
["taxi"] = false,
["t"] = 1792280820,
["run"] = 7,
["swimming"] = false,
["flying"] = false,
["inst"] = true,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510156.433,
["taxi"] = false,
["t"] = 1792280822,
["run"] = 0,
["swimming"] = false,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510157.433,
["taxi"] = false,
["t"] = 1792280823,
["run"] = 7,
["swimming"] = false,
["y"] = 0.448,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1414,
["x"] = 0.584,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510158.457,
["taxi"] = false,
["t"] = 1792280824,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510159.47,
["taxi"] = false,
["t"] = 1792280825,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510160.472,
["taxi"] = false,
["t"] = 1792280826,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510161.482,
["taxi"] = false,
["t"] = 1792280827,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510162.498,
["taxi"] = false,
["t"] = 1792280828,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510163.512,
["taxi"] = false,
["t"] = 1792280829,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510164.519,
["taxi"] = false,
["t"] = 1792280830,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510165.54,
["taxi"] = false,
["t"] = 1792280831,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510166.544,
["taxi"] = false,
["t"] = 1792280832,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510167.551,
["taxi"] = false,
["t"] = 1792280833,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510168.556,
["taxi"] = false,
["t"] = 1792280834,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510169.561,
["taxi"] = false,
["t"] = 1792280835,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510170.561,
["taxi"] = false,
["t"] = 1792280836,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510171.571,
["taxi"] = false,
["t"] = 1792280837,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510172.582,
["taxi"] = false,
["t"] = 1792280838,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510173.594,
["taxi"] = false,
["t"] = 1792280839,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
{
["mounted"] = false,
["gt"] = 510174.602,
["taxi"] = false,
["t"] = 1792280840,
["run"] = 7,
["swimming"] = false,
["y"] = 0.494,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1454,
["x"] = 0.521,
["restr"] = 0,
},
},
},
["notes"] = {
},
["api"] = {
},
["id"] = "T1a",
["startedAt"] = 1792269451,
["status"] = "open",
["events"] = {
},
["title"] = "Taxi flag and position jumps over time (also covers T2, T3, T4)",
["build"] = "1.60.1 build 70450",
},
["S1"] = {
["title"] = "Map position in the open world and in an instance",
["notes"] = {
"Rehgar Deadeye: Ragefire Chasm, entered and left once.",
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "C_Map.GetBestMapForUnit(player)",
["present"] = true,
["returns"] = {
{
["value"] = 1436,
["type"] = "number",
},
},
},
{
["summary"] = {
["map"] = "1436",
["x"] = "0.52837765216827",
["y"] = "0.53540968894958",
},
["fn"] = "player position",
},
{
["fn"] = "C_Map.GetMapInfo(map)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapWorldSize(map)",
["present"] = true,
["returns"] = {
{
["value"] = 3499.999755859375,
["type"] = "number",
},
{
["value"] = 2333.3330078125,
["type"] = "number",
},
},
},
{
["fn"] = "IsInInstance()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = "none",
["type"] = "string",
["len"] = 4,
},
},
},
{
["fn"] = "GetZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
},
},
{
["fn"] = "GetSubZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Sentinel Hill",
["type"] = "string",
["len"] = 13,
},
},
},
},
},
{
["gt"] = 510089.055,
["label"] = "outside-before",
["t"] = 1792280755,
["results"] = {
{
["fn"] = "C_Map.GetBestMapForUnit(player)",
["present"] = true,
["returns"] = {
{
["value"] = 1454,
["type"] = "number",
},
},
},
{
["summary"] = {
["map"] = "1454",
["x"] = "0.50612139701843",
["y"] = "0.50991857051849",
},
["fn"] = "player position",
},
{
["fn"] = "C_Map.GetMapInfo(map)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1454,
["type"] = "number",
},
["name"] = {
["value"] = "Orgrimmar",
["type"] = "string",
["len"] = 9,
},
["parentMapID"] = {
["value"] = 1414,
["type"] = "number",
},
["flags"] = {
["value"] = 0,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapWorldSize(map)",
["present"] = true,
["returns"] = {
{
["value"] = 1402.6044921875,
["type"] = "number",
},
{
["value"] = 935.4166259765625,
["type"] = "number",
},
},
},
{
["fn"] = "IsInInstance()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = "none",
["type"] = "string",
["len"] = 4,
},
},
},
{
["fn"] = "GetInstanceInfo()",
["present"] = true,
["returns"] = {
{
["value"] = "Kalimdor",
["type"] = "string",
["len"] = 8,
},
{
["value"] = "none",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "",
["type"] = "string",
["len"] = 0,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Orgrimmar",
["type"] = "string",
["len"] = 9,
},
},
},
{
["fn"] = "GetSubZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Cleft of Shadow",
["type"] = "string",
["len"] = 15,
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 510125.406,
["label"] = "inside-start",
["t"] = 1792280791,
["results"] = {
{
["fn"] = "C_Map.GetBestMapForUnit(player)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
},
},
{
["summary"] = {
["map"] = "nil",
["x"] = "nil",
["y"] = "nil",
},
["fn"] = "player position",
},
{
["fn"] = "IsInInstance()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = "party",
["type"] = "string",
["len"] = 5,
},
},
},
{
["fn"] = "GetInstanceInfo()",
["present"] = true,
["returns"] = {
{
["value"] = "Ragefire Chasm",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "party",
["type"] = "string",
["len"] = 5,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Normal",
["type"] = "string",
["len"] = 6,
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 389,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Ragefire Chasm",
["type"] = "string",
["len"] = 14,
},
},
},
{
["fn"] = "GetSubZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "",
["type"] = "string",
["len"] = 0,
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 510146.44,
["label"] = "inside-later",
["t"] = 1792280812,
["results"] = {
{
["fn"] = "C_Map.GetBestMapForUnit(player)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
},
},
{
["summary"] = {
["map"] = "nil",
["x"] = "nil",
["y"] = "nil",
},
["fn"] = "player position",
},
{
["fn"] = "IsInInstance()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = "party",
["type"] = "string",
["len"] = 5,
},
},
},
{
["fn"] = "GetInstanceInfo()",
["present"] = true,
["returns"] = {
{
["value"] = "Ragefire Chasm",
["type"] = "string",
["len"] = 14,
},
{
["value"] = "party",
["type"] = "string",
["len"] = 5,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Normal",
["type"] = "string",
["len"] = 6,
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 389,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Ragefire Chasm",
["type"] = "string",
["len"] = 14,
},
},
},
{
["fn"] = "GetSubZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "",
["type"] = "string",
["len"] = 0,
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 510170.463,
["label"] = "outside-after",
["t"] = 1792280836,
["results"] = {
{
["fn"] = "C_Map.GetBestMapForUnit(player)",
["present"] = true,
["returns"] = {
{
["value"] = 1454,
["type"] = "number",
},
},
},
{
["summary"] = {
["map"] = "1454",
["x"] = "0.52130800485611",
["y"] = "0.49419391155243",
},
["fn"] = "player position",
},
{
["fn"] = "C_Map.GetMapInfo(map)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1454,
["type"] = "number",
},
["name"] = {
["value"] = "Orgrimmar",
["type"] = "string",
["len"] = 9,
},
["parentMapID"] = {
["value"] = 1414,
["type"] = "number",
},
["flags"] = {
["value"] = 0,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapWorldSize(map)",
["present"] = true,
["returns"] = {
{
["value"] = 1402.6044921875,
["type"] = "number",
},
{
["value"] = 935.4166259765625,
["type"] = "number",
},
},
},
{
["fn"] = "IsInInstance()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = "none",
["type"] = "string",
["len"] = 4,
},
},
},
{
["fn"] = "GetInstanceInfo()",
["present"] = true,
["returns"] = {
{
["value"] = "Kalimdor",
["type"] = "string",
["len"] = 8,
},
{
["value"] = "none",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "",
["type"] = "string",
["len"] = 0,
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Orgrimmar",
["type"] = "string",
["len"] = 9,
},
},
},
{
["fn"] = "GetSubZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Cleft of Shadow",
["type"] = "string",
["len"] = 15,
},
},
},
},
["restr"] = 0,
},
},
["id"] = "S1",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["AHS"] = {
["events"] = {
},
["notes"] = {
"Divine Slaps: auction house, listing, cancel, buyout, bid",
"deposit shown 100 copper",
"cancel window said will lose your initial deposit by canceling this auction",
"buyout price shown 13 copper",
"bid shown 101 copper",
"bid price shown 300 copper, buyout 400 copper",
},
["title"] = "Auction house state: money, window, own auctions (listing, cancel, buyout)",
["api"] = {
{
["gt"] = 9414.800000000001,
["label"] = "names",
["t"] = 1792336742,
["restr"] = 0,
["results"] = {
{
["summary"] = {
["money"] = "373",
["ahShown"] = "true",
["label"] = "names",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_SHOW)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_AUCTION_CREATED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_CANCELED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_PURCHASE_COMPLETED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(COMMODITY_PURCHASE_SUCCEEDED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(COMMODITY_PURCHASE_FAILED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(OWNED_AUCTIONS_UPDATED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(BID_ADDED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_MULTISELL_START)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_MULTISELL_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_POST_ERROR)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_POST_WARNING)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_SEND_SUCCESS)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_SEND_INFO_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_FAILED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_SUCCESS)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(SEND_MAIL_COD_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(SEND_MAIL_MONEY_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
{
["gt"] = 9427.134,
["label"] = "open",
["t"] = 1792336755,
["restr"] = 0,
["results"] = {
{
["summary"] = {
["money"] = "373",
["ahShown"] = "true",
["label"] = "open",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
},
{
["gt"] = 9509.482,
["label"] = "listed",
["t"] = 1792336837,
["restr"] = 0,
["results"] = {
{
["summary"] = {
["money"] = "273",
["ahShown"] = "true",
["label"] = "listed",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
},
{
["gt"] = 9576.295,
["label"] = "cancelled",
["t"] = 1792336904,
["restr"] = 0,
["results"] = {
{
["summary"] = {
["money"] = "273",
["ahShown"] = "true",
["label"] = "cancelled",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
},
{
["gt"] = 10140.801,
["label"] = "bid",
["t"] = 1792337468,
["results"] = {
{
["summary"] = {
["money"] = "160",
["ahShown"] = "true",
["label"] = "bid",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 10160.803,
["label"] = "closed",
["t"] = 1792337488,
["results"] = {
{
["summary"] = {
["money"] = "160",
["ahShown"] = "false",
["label"] = "closed",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 10702.695,
["label"] = "s23-open",
["t"] = 1792338030,
["results"] = {
{
["summary"] = {
["money"] = "18039",
["ahShown"] = "true",
["label"] = "s23-open",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 10756.582,
["label"] = "s23-listed",
["t"] = 1792338084,
["results"] = {
{
["summary"] = {
["money"] = "17939",
["ahShown"] = "true",
["label"] = "s23-listed",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 10779.379,
["label"] = "s23-cancelled",
["t"] = 1792338107,
["results"] = {
{
["summary"] = {
["money"] = "17939",
["ahShown"] = "true",
["label"] = "s23-cancelled",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 10827.793,
["label"] = "s23-bought",
["t"] = 1792338155,
["results"] = {
{
["summary"] = {
["money"] = "17935",
["ahShown"] = "true",
["label"] = "s23-bought",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 11481.478,
["label"] = "s23-closed",
["t"] = 1792338809,
["results"] = {
{
["summary"] = {
["money"] = "17935",
["ahShown"] = "false",
["label"] = "s23-closed",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 12565.187,
["label"] = "bid-before",
["t"] = 1792339893,
["results"] = {
{
["summary"] = {
["money"] = "17935",
["ahShown"] = "true",
["label"] = "bid-before",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 12622.218,
["label"] = "bid-after",
["t"] = 1792339950,
["results"] = {
{
["summary"] = {
["money"] = "17635",
["ahShown"] = "true",
["label"] = "bid-after",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 12646.241,
["label"] = "bid-later",
["t"] = 1792339974,
["results"] = {
{
["summary"] = {
["money"] = "17635",
["ahShown"] = "true",
["label"] = "bid-later",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
{
["gt"] = 12656.968,
["label"] = "bid-closed",
["t"] = 1792339985,
["results"] = {
{
["summary"] = {
["money"] = "17635",
["ahShown"] = "false",
["label"] = "bid-closed",
},
["fn"] = "state",
},
{
["summary"] = {
["present"] = "C_AuctionHouse.GetNumOwnedAuctions C_AuctionHouse.GetOwnedAuctions C_AuctionHouse.HasFullOwnedAuctionResults C_AuctionHouse.IsThrottledMessageSystemReady C_AuctionHouse.CancelAuction C_AuctionHouse.CanCancelAuction C_AuctionHouse.PostItem C_AuctionHouse.PostCommodity C_AuctionHouse.PlaceBid C_AuctionHouse.ConfirmCommoditiesPurchase C_AuctionHouse.CalculateItemDeposit C_AuctionHouse.CalculateCommodityDeposit C_AuctionHouse.GetCancelCost C_AuctionHouse.GetBidInfo C_AuctionHouse.GetNumBidTypes C_AuctionHouse.QueryOwnedAuctions",
["absent"] = "",
},
["fn"] = "AH functions",
},
{
["fn"] = "C_AuctionHouse.GetNumOwnedAuctions()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_AuctionHouse.HasFullOwnedAuctionResults()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_AuctionHouse.IsThrottledMessageSystemReady()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetOwnedAuctions()",
["present"] = true,
["summary"] = {
["count"] = 0,
},
},
},
["restr"] = 0,
},
},
["id"] = "AHS",
["status"] = "open",
["startedAt"] = 1792336725,
["build"] = "1.60.1 build 70450",
},
["L3"] = {
["title"] = "Loot window slot data and source GUID",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "default",
["t"] = 1792270407,
["gt"] = 499741.037,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133788,
["type"] = "number",
},
{
["value"] = "8 Copper",
["type"] = "string",
["len"] = 8,
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-4621-0-1-95-4B8D905020",
["type"] = "string",
["len"] = 33,
},
{
["value"] = 8,
["type"] = "number",
},
},
},
},
},
{
["label"] = "default",
["t"] = 1792271257,
["gt"] = 500591.072,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133722,
["type"] = "number",
},
{
["value"] = "Broken Boar Tusk",
["type"] = "string",
["len"] = 16,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ0:|Hitem:3171::::::::14:1482:::::::::|h[Broken Boar Tusk]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-6783-0-1-157-38184B766D",
["type"] = "string",
["len"] = 34,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
},
{
["label"] = "default",
["t"] = 1792271315,
["gt"] = 500649.599,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134252,
["type"] = "number",
},
{
["value"] = "Light Leather",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2318::::::::14:1482:::::::::|h[Light Leather]|h|r",
["type"] = "string",
["len"] = 63,
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-6783-0-1-157-22EE329824",
["type"] = "string",
["len"] = 34,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
},
{
["gt"] = 502895.59,
["label"] = "default",
["t"] = 1792273561,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "2",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134187,
["type"] = "number",
},
{
["value"] = "Earthroot",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 2,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2449::::::::7:1484:::::::::|h[Earthroot]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-4615-1-2-1619-C8E1A08EAE",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 133963,
["type"] = "number",
},
{
["value"] = "Frilled Lichen",
["type"] = "string",
["len"] = 14,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(2)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(2)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:249399::::::::7:1484:::::::::|h[Frilled Lichen]|h|r",
["type"] = "string",
["len"] = 65,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-4615-1-2-1619-C8E1A08EAE",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 502973.152,
["label"] = "default",
["t"] = 1792273639,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "2",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133788,
["type"] = "number",
},
{
["value"] = "9 Copper",
["type"] = "string",
["len"] = 8,
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-4615-1-2-2950-696F1CD830",
["type"] = "string",
["len"] = 35,
},
{
["value"] = 9,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = "Linen Cloth",
["type"] = "string",
["len"] = 11,
},
{
["value"] = 2,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(2)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(2)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2589::::::::7:1484:::::::::|h[Linen Cloth]|h|r",
["type"] = "string",
["len"] = 60,
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-4615-1-2-2950-696F1CD830",
["type"] = "string",
["len"] = 35,
},
{
["value"] = 2,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 502992.548,
["label"] = "herb",
["t"] = 1792273658,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134187,
["type"] = "number",
},
{
["value"] = "Earthroot",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2449::::::::7:1484:::::::::|h[Earthroot]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-4615-1-2-1619-155E443212",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
["restr"] = 2,
},
{
["gt"] = 503022.737,
["label"] = "default",
["t"] = 1792273688,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133788,
["type"] = "number",
},
{
["value"] = "3 Copper",
["type"] = "string",
["len"] = 8,
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-4615-1-2-2950-E454079710",
["type"] = "string",
["len"] = 35,
},
{
["value"] = 3,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 503131.044,
["label"] = "herb",
["t"] = 1792273797,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134190,
["type"] = "number",
},
{
["value"] = "Silverleaf",
["type"] = "string",
["len"] = 10,
},
{
["value"] = 3,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:765::::::::7:1484:::::::::|h[Silverleaf]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-4615-1-2-1617-FCB7D79ACB",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 3,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 503291.341,
["label"] = "mining",
["t"] = 1792273957,
["restr"] = 0,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134566,
["type"] = "number",
},
{
["value"] = "Copper Ore",
["type"] = "string",
["len"] = 10,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2770::::::::8:1491:::::::::|h[Copper Ore]|h|r",
["type"] = "string",
["len"] = 59,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-6782-0-4-1731-048BFFB770",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
},
},
["id"] = "L3",
["startedAt"] = 1792270407,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["MS1"] = {
["title"] = "Outgoing mail: postage and money sent",
["notes"] = {
"Rehgar Deadeye: outgoing mail to my other character Divine Slaps, item, money, COD",
"postage shown 30 copper",
},
["events"] = {
},
["api"] = {
{
["gt"] = 12886.745,
["label"] = "names",
["t"] = 1792340214,
["results"] = {
{
["summary"] = {
["money"] = "6158",
["sendShown"] = "true",
["label"] = "names",
["mailShown"] = "true",
},
["fn"] = "state",
},
{
["fn"] = "GetSendMailPrice()",
["present"] = true,
["returns"] = {
{
["value"] = 30,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailPrice()",
},
{
["fn"] = "GetSendMailMoney()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailMoney()",
},
{
["fn"] = "GetSendMailCOD()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailCOD()",
},
{
["fn"] = "GetSendMailItem(1)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_SHOW)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_AUCTION_CREATED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_CANCELED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_PURCHASE_COMPLETED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(COMMODITY_PURCHASE_SUCCEEDED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(COMMODITY_PURCHASE_FAILED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(OWNED_AUCTIONS_UPDATED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(BID_ADDED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_MULTISELL_START)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_MULTISELL_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_POST_ERROR)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(AUCTION_HOUSE_POST_WARNING)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_SEND_SUCCESS)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_SEND_INFO_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_FAILED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_SUCCESS)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(SEND_MAIL_COD_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(SEND_MAIL_MONEY_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 12915.176,
["label"] = "ready-item",
["t"] = 1792340243,
["results"] = {
{
["summary"] = {
["money"] = "6158",
["sendShown"] = "true",
["label"] = "ready-item",
["mailShown"] = "true",
},
["fn"] = "state",
},
{
["fn"] = "GetSendMailPrice()",
["present"] = true,
["returns"] = {
{
["value"] = 30,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailPrice()",
},
{
["fn"] = "GetSendMailMoney()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailMoney()",
},
{
["fn"] = "GetSendMailCOD()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailCOD()",
},
{
["fn"] = "GetSendMailItem(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Ice Cold Milk",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 1179,
["type"] = "number",
},
{
["value"] = 132815,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 12935.214,
["label"] = "sent-item",
["t"] = 1792340263,
["results"] = {
{
["summary"] = {
["money"] = "6128",
["sendShown"] = "true",
["label"] = "sent-item",
["mailShown"] = "true",
},
["fn"] = "state",
},
{
["fn"] = "GetSendMailPrice()",
["present"] = true,
["returns"] = {
{
["value"] = 30,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailPrice()",
},
{
["fn"] = "GetSendMailMoney()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailMoney()",
},
{
["fn"] = "GetSendMailCOD()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailCOD()",
},
{
["fn"] = "GetSendMailItem(1)",
["present"] = true,
["returns"] = {
},
},
},
["restr"] = 0,
},
{
["gt"] = 12973.097,
["label"] = "ready-money",
["t"] = 1792340301,
["results"] = {
{
["summary"] = {
["money"] = "6128",
["sendShown"] = "true",
["label"] = "ready-money",
["mailShown"] = "true",
},
["fn"] = "state",
},
{
["fn"] = "GetSendMailPrice()",
["present"] = true,
["returns"] = {
{
["value"] = 30,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailPrice()",
},
{
["fn"] = "GetSendMailMoney()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailMoney()",
},
{
["fn"] = "GetSendMailCOD()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailCOD()",
},
{
["fn"] = "GetSendMailItem(1)",
["present"] = true,
["returns"] = {
},
},
},
["restr"] = 0,
},
{
["gt"] = 12985.992,
["label"] = "sent-money",
["t"] = 1792340314,
["results"] = {
{
["summary"] = {
["money"] = "6068",
["sendShown"] = "true",
["label"] = "sent-money",
["mailShown"] = "true",
},
["fn"] = "state",
},
{
["fn"] = "GetSendMailPrice()",
["present"] = true,
["returns"] = {
{
["value"] = 30,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailPrice()",
},
{
["fn"] = "GetSendMailMoney()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailMoney()",
},
{
["fn"] = "GetSendMailCOD()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailCOD()",
},
{
["fn"] = "GetSendMailItem(1)",
["present"] = true,
["returns"] = {
},
},
},
["restr"] = 0,
},
{
["gt"] = 13048.709,
["label"] = "ready-cod",
["t"] = 1792340376,
["results"] = {
{
["summary"] = {
["money"] = "6068",
["sendShown"] = "true",
["label"] = "ready-cod",
["mailShown"] = "true",
},
["fn"] = "state",
},
{
["fn"] = "GetSendMailPrice()",
["present"] = true,
["returns"] = {
{
["value"] = 30,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailPrice()",
},
{
["fn"] = "GetSendMailMoney()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailMoney()",
},
{
["fn"] = "GetSendMailCOD()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailCOD()",
},
{
["fn"] = "GetSendMailItem(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Spider Ichor",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 3174,
["type"] = "number",
},
{
["value"] = 134437,
["type"] = "number",
},
{
["value"] = 4,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 13067.191,
["label"] = "sent-cod",
["t"] = 1792340395,
["results"] = {
{
["summary"] = {
["money"] = "6038",
["sendShown"] = "true",
["label"] = "sent-cod",
["mailShown"] = "true",
},
["fn"] = "state",
},
{
["fn"] = "GetSendMailPrice()",
["present"] = true,
["returns"] = {
{
["value"] = 30,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailPrice()",
},
{
["fn"] = "GetSendMailMoney()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailMoney()",
},
{
["fn"] = "GetSendMailCOD()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["present"] = false,
["fn"] = "C_Mail.GetSendMailCOD()",
},
{
["fn"] = "GetSendMailItem(1)",
["present"] = true,
["returns"] = {
},
},
},
["restr"] = 0,
},
},
["id"] = "MS1",
["startedAt"] = 1792340176,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["H2"] = {
["notes"] = {
"part of a red square around Sentinel Hill, not completely filled in. I will upload a screenshot of it.",
},
["api"] = {
},
["id"] = "H2",
["startedAt"] = 1792269616,
["square"] = {
["mouseEnabled"] = false,
["parentLevel"] = 3,
["parentStrata"] = "MEDIUM",
["t"] = 1792270041,
["squareLevel"] = 4,
["parent"] = "canvas (unnamed)",
},
["status"] = "open",
["title"] = "Map overlay host: a test square on the world map",
["events"] = {
},
["build"] = "1.60.1 build 70450",
},
["I2"] = {
["title"] = "Bags: readable item fields and scan cost",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "bag scan",
["present"] = true,
["summary"] = {
["items"] = 26,
["secretResults"] = 0,
["errors"] = 0,
["elapsed"] = "0.74 debugprofilestop ms",
["slots"] = 44,
},
},
{
["fn"] = "GetContainerItemInfo(0,1)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["itemName"] = {
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
["hasLoot"] = {
["value"] = false,
["type"] = "boolean",
},
["hyperlink"] = {
["value"] = "|cnIQ1:|Hitem:6948::::::::14:1482::75:::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 63,
},
["iconFileID"] = {
["value"] = 134414,
["type"] = "number",
},
["hasNoValue"] = {
["value"] = true,
["type"] = "boolean",
},
["isLocked"] = {
["value"] = false,
["type"] = "boolean",
},
["itemID"] = {
["value"] = 6948,
["type"] = "number",
},
["isBound"] = {
["value"] = true,
["type"] = "boolean",
},
["stackCount"] = {
["value"] = 1,
["type"] = "number",
},
["isFiltered"] = {
["value"] = false,
["type"] = "boolean",
},
["isReadable"] = {
["value"] = false,
["type"] = "boolean",
},
["quality"] = {
["value"] = 1,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "GetContainerItemInfo(0,2)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["itemName"] = {
["value"] = "Elixir of Minor Spirit",
["type"] = "string",
["len"] = 22,
},
["hasLoot"] = {
["value"] = false,
["type"] = "boolean",
},
["hyperlink"] = {
["value"] = "|cnIQ1:|Hitem:250344::::::::14:1482:::::::::|h[Elixir of Minor Spirit]|h|r",
["type"] = "string",
["len"] = 74,
},
["iconFileID"] = {
["value"] = 134736,
["type"] = "number",
},
["hasNoValue"] = {
["value"] = false,
["type"] = "boolean",
},
["isLocked"] = {
["value"] = false,
["type"] = "boolean",
},
["itemID"] = {
["value"] = 250344,
["type"] = "number",
},
["isBound"] = {
["value"] = false,
["type"] = "boolean",
},
["stackCount"] = {
["value"] = 5,
["type"] = "number",
},
["isFiltered"] = {
["value"] = false,
["type"] = "boolean",
},
["isReadable"] = {
["value"] = false,
["type"] = "boolean",
},
["quality"] = {
["value"] = 1,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "GetContainerItemInfo(0,3)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["itemName"] = {
["value"] = "Brilliant Smallfish",
["type"] = "string",
["len"] = 19,
},
["hasLoot"] = {
["value"] = false,
["type"] = "boolean",
},
["hyperlink"] = {
["value"] = "|cnIQ1:|Hitem:6290::::::::14:1482:::::::::|h[Brilliant Smallfish]|h|r",
["type"] = "string",
["len"] = 69,
},
["iconFileID"] = {
["value"] = 133893,
["type"] = "number",
},
["hasNoValue"] = {
["value"] = false,
["type"] = "boolean",
},
["isLocked"] = {
["value"] = false,
["type"] = "boolean",
},
["itemID"] = {
["value"] = 6290,
["type"] = "number",
},
["isBound"] = {
["value"] = false,
["type"] = "boolean",
},
["stackCount"] = {
["value"] = 10,
["type"] = "number",
},
["isFiltered"] = {
["value"] = false,
["type"] = "boolean",
},
["isReadable"] = {
["value"] = false,
["type"] = "boolean",
},
["quality"] = {
["value"] = 1,
["type"] = "number",
},
},
},
},
},
},
},
},
["id"] = "I2",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["I1"] = {
["title"] = "Item data: sell price, bind type, async behaviour",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "C_Item.GetItemInfo(6948)",
["present"] = true,
["returns"] = {
{
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:6948::::::::14:1482:::::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 61,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(6948)",
["present"] = true,
["returns"] = {
{
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:6948::::::::14:1482:::::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 61,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(6948)",
["present"] = true,
["returns"] = {
{
["value"] = 6948,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(2589)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(2589)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(2589)",
["present"] = true,
["returns"] = {
{
["value"] = 2589,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Cloth",
["type"] = "string",
["len"] = 5,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(2770)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(2770)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(2770)",
["present"] = true,
["returns"] = {
{
["value"] = 2770,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Metal & Stone",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134566,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(117)",
["present"] = true,
["returns"] = {
{
["value"] = "Tough Jerky",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:117::::::::14:1482:::::::::|h[Tough Jerky]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(117)",
["present"] = true,
["returns"] = {
{
["value"] = "Tough Jerky",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:117::::::::14:1482:::::::::|h[Tough Jerky]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(117)",
["present"] = true,
["returns"] = {
{
["value"] = 117,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(19019)",
["present"] = true,
["returns"] = {
{
["value"] = 19019,
["type"] = "number",
},
{
["value"] = "Weapon",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "One-Handed Swords",
["type"] = "string",
["len"] = 17,
},
{
["value"] = "INVTYPE_WEAPON",
["type"] = "string",
["len"] = 14,
},
{
["value"] = 135349,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "IsEventValid(ITEM_DATA_LOAD_RESULT)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(GET_ITEM_INFO_RECEIVED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
{
["gt"] = 2421.123,
["label"] = "default",
["t"] = 1792329749,
["results"] = {
{
["fn"] = "C_Item.GetItemInfo(6948)",
["present"] = true,
["returns"] = {
{
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:6948::::::::6:1490:::::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(6948)",
["present"] = true,
["returns"] = {
{
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:6948::::::::6:1490:::::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(6948)",
["present"] = true,
["returns"] = {
{
["value"] = 6948,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(2589)",
["present"] = true,
["returns"] = {
{
["value"] = "Linen Cloth",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:2589::::::::6:1490:::::::::|h[Linen Cloth]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Cloth",
["type"] = "string",
["len"] = 5,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = 13,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(2589)",
["present"] = true,
["returns"] = {
{
["value"] = "Linen Cloth",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:2589::::::::6:1490:::::::::|h[Linen Cloth]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Cloth",
["type"] = "string",
["len"] = 5,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = 13,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(2589)",
["present"] = true,
["returns"] = {
{
["value"] = 2589,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Cloth",
["type"] = "string",
["len"] = 5,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(2770)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(2770)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(2770)",
["present"] = true,
["returns"] = {
{
["value"] = 2770,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Metal & Stone",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134566,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(117)",
["present"] = true,
["returns"] = {
{
["value"] = "Tough Jerky",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:117::::::::6:1490:::::::::|h[Tough Jerky]|h|r",
["type"] = "string",
["len"] = 59,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(117)",
["present"] = true,
["returns"] = {
{
["value"] = "Tough Jerky",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:117::::::::6:1490:::::::::|h[Tough Jerky]|h|r",
["type"] = "string",
["len"] = 59,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(117)",
["present"] = true,
["returns"] = {
{
["value"] = 117,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(19019)",
["present"] = true,
["returns"] = {
{
["value"] = 19019,
["type"] = "number",
},
{
["value"] = "Weapon",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "One-Handed Swords",
["type"] = "string",
["len"] = 17,
},
{
["value"] = "INVTYPE_WEAPON",
["type"] = "string",
["len"] = 14,
},
{
["value"] = 135349,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(2589)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(2770)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "IsEventValid(ITEM_DATA_LOAD_RESULT)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(GET_ITEM_INFO_RECEIVED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 2434.797,
["label"] = "default",
["t"] = 1792329762,
["results"] = {
{
["fn"] = "C_Item.GetItemInfo(6948)",
["present"] = true,
["returns"] = {
{
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:6948::::::::6:1490:::::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(6948)",
["present"] = true,
["returns"] = {
{
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:6948::::::::6:1490:::::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(6948)",
["present"] = true,
["returns"] = {
{
["value"] = 6948,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(2589)",
["present"] = true,
["returns"] = {
{
["value"] = "Linen Cloth",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:2589::::::::6:1490:::::::::|h[Linen Cloth]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Cloth",
["type"] = "string",
["len"] = 5,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = 13,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(2589)",
["present"] = true,
["returns"] = {
{
["value"] = "Linen Cloth",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:2589::::::::6:1490:::::::::|h[Linen Cloth]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Cloth",
["type"] = "string",
["len"] = 5,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = 13,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(2589)",
["present"] = true,
["returns"] = {
{
["value"] = 2589,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Cloth",
["type"] = "string",
["len"] = 5,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(2770)",
["present"] = true,
["returns"] = {
{
["value"] = "Copper Ore",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "|cnIQ1:|Hitem:2770::::::::6:1490:::::::::|h[Copper Ore]|h|r",
["type"] = "string",
["len"] = 59,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 10,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Metal & Stone",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134566,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(2770)",
["present"] = true,
["returns"] = {
{
["value"] = "Copper Ore",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "|cnIQ1:|Hitem:2770::::::::6:1490:::::::::|h[Copper Ore]|h|r",
["type"] = "string",
["len"] = 59,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 10,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Metal & Stone",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134566,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(2770)",
["present"] = true,
["returns"] = {
{
["value"] = 2770,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Metal & Stone",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134566,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(117)",
["present"] = true,
["returns"] = {
{
["value"] = "Tough Jerky",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:117::::::::6:1490:::::::::|h[Tough Jerky]|h|r",
["type"] = "string",
["len"] = 59,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(117)",
["present"] = true,
["returns"] = {
{
["value"] = "Tough Jerky",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:117::::::::6:1490:::::::::|h[Tough Jerky]|h|r",
["type"] = "string",
["len"] = 59,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(117)",
["present"] = true,
["returns"] = {
{
["value"] = 117,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(19019)",
["present"] = true,
["returns"] = {
{
["value"] = "Thunderfury, Blessed Blade of the Windseeker",
["type"] = "string",
["len"] = 44,
},
{
["value"] = "|cnIQ5:|Hitem:19019::::::::6:1490:::::::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r",
["type"] = "string",
["len"] = 94,
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 80,
["type"] = "number",
},
{
["value"] = 60,
["type"] = "number",
},
{
["value"] = "Weapon",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "One-Handed Swords",
["type"] = "string",
["len"] = 17,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_WEAPON",
["type"] = "string",
["len"] = 14,
},
{
["value"] = 135349,
["type"] = "number",
},
{
["value"] = 255355,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(19019)",
["present"] = true,
["returns"] = {
{
["value"] = "Thunderfury, Blessed Blade of the Windseeker",
["type"] = "string",
["len"] = 44,
},
{
["value"] = "|cnIQ5:|Hitem:19019::::::::6:1490:::::::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r",
["type"] = "string",
["len"] = 94,
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 80,
["type"] = "number",
},
{
["value"] = 60,
["type"] = "number",
},
{
["value"] = "Weapon",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "One-Handed Swords",
["type"] = "string",
["len"] = 17,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_WEAPON",
["type"] = "string",
["len"] = 14,
},
{
["value"] = 135349,
["type"] = "number",
},
{
["value"] = 255355,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(19019)",
["present"] = true,
["returns"] = {
{
["value"] = 19019,
["type"] = "number",
},
{
["value"] = "Weapon",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "One-Handed Swords",
["type"] = "string",
["len"] = 17,
},
{
["value"] = "INVTYPE_WEAPON",
["type"] = "string",
["len"] = 14,
},
{
["value"] = 135349,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(2589)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(2770)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "IsEventValid(ITEM_DATA_LOAD_RESULT)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(GET_ITEM_INFO_RECEIVED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
["restr"] = 0,
},
},
["id"] = "I1",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["H1"] = {
["title"] = "Place names for map coordinates",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.528, 0.535)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.578, 0.535)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.478, 0.535)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.528, 0.585)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.528, 0.485)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapHighlightInfoAtPosition(center)",
["present"] = true,
["returns"] = {
},
},
},
},
},
["id"] = "H1",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["L2"] = {
["title"] = "LOOT_SLOT_CLEARED per slot",
["notes"] = {
},
["events"] = {
["LOOT_SLOT_CLEARED"] = {
["registerCall"] = "returned normally",
["delivered"] = 9,
["samples"] = {
{
["gt"] = 502902.209,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273568,
["n"] = 1,
["restr"] = 0,
},
{
["gt"] = 502902.209,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273568,
["n"] = 1,
["restr"] = 0,
},
{
["gt"] = 502902.959,
["args"] = {
{
["value"] = 2,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273569,
["n"] = 1,
["restr"] = 0,
},
{
["n"] = 1,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.417,
},
},
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273641,
["gt"] = 502975.72,
["restr"] = 0,
},
{
["n"] = 1,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.417,
},
},
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273641,
["gt"] = 502975.72,
["restr"] = 0,
},
{
["before"] = {
["event"] = "PLAYER_MONEY",
["dt"] = 0.133,
},
["gt"] = 502976.27,
["args"] = {
{
["value"] = 2,
["type"] = "number",
},
},
["money"] = 142,
["t"] = 1792273642,
["n"] = 1,
["restr"] = 0,
},
{
["gt"] = 502995.133,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 142,
["t"] = 1792273661,
["n"] = 1,
["restr"] = 2,
},
{
["n"] = 1,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0,
},
},
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 142,
["t"] = 1792273690,
["gt"] = 503024.321,
["restr"] = 0,
},
{
["gt"] = 503133.337,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 145,
["t"] = 1792273799,
["n"] = 1,
["restr"] = 0,
},
},
["attemptedAt"] = 1792273515,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "L2",
["startedAt"] = 1792273515,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["I1b"] = {
["title"] = "Item data load completion event (async item info)",
["notes"] = {
"Dottie Slaps: fresh login, item data test",
},
["events"] = {
["GET_ITEM_INFO_RECEIVED"] = {
["registerCall"] = "returned normally",
["delivered"] = 4,
["samples"] = {
{
["gt"] = 2421.123,
["args"] = {
{
["value"] = 2770,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
},
["money"] = 7,
["t"] = 1792329749,
["n"] = 2,
["restr"] = 0,
},
{
["gt"] = 2421.123,
["args"] = {
{
["value"] = 19019,
["type"] = "number",
},
{
["value"] = true,
["type"] = "boolean",
},
},
["money"] = 7,
["t"] = 1792329749,
["n"] = 2,
["restr"] = 0,
},
{
["gt"] = 2421.406,
["args"] = {
{
["value"] = 999999,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 7,
["t"] = 1792329749,
["n"] = 2,
["restr"] = 0,
},
{
["gt"] = 2435.047,
["args"] = {
{
["value"] = 999999,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 7,
["t"] = 1792329763,
["n"] = 2,
["restr"] = 0,
},
},
["attemptedAt"] = 1792329721,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "I1b",
["startedAt"] = 1792329721,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["M1"] = {
["title"] = "Merchant open/close, sale and purchase order versus money",
["notes"] = {
"Divine Slaps: MERCHANT_CLOSED, vendor Barkeep Morag",
},
["events"] = {
["MERCHANT_SHOW"] = {
["registerCall"] = "returned normally",
["delivered"] = 2,
["samples"] = {
{
["gt"] = 503757.602,
["args"] = {
},
["money"] = 18236,
["t"] = 1792274423,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 503828.546,
["args"] = {
},
["money"] = 18232,
["t"] = 1792274494,
["n"] = 0,
["restr"] = 0,
},
},
["attemptedAt"] = 1792274417,
["isEventRegistered"] = true,
},
["MERCHANT_CLOSED"] = {
["registerCall"] = "returned normally",
["delivered"] = 3,
["samples"] = {
{
["gt"] = 7256.263,
["args"] = {
},
["money"] = 224,
["t"] = 1792334584,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 7265.965,
["args"] = {
},
["money"] = 224,
["t"] = 1792334594,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 7265.965,
["args"] = {
},
["money"] = 224,
["t"] = 1792334594,
["restr"] = 0,
["n"] = 0,
},
},
["attemptedAt"] = 1792334503,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "M1",
["startedAt"] = 1792274417,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["L1"] = {
["title"] = "LOOT_OPENED payload and order versus PLAYER_MONEY",
["notes"] = {
"Rehgar Deadeye: fishing",
"Sunder Slaps: mining",
"Sunder Slaps: mining",
"Grizzly Slaps: herb",
"Divine Slaps: enchanter",
},
["events"] = {
["LOOT_OPENED"] = {
["registerCall"] = "returned normally",
["delivered"] = 13,
["samples"] = {
{
["gt"] = 499731.509,
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18548,
["t"] = 1792270397,
["n"] = 2,
},
{
["gt"] = 499788.318,
["args"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18556,
["t"] = 1792270454,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.509,
},
},
["n"] = 2,
},
{
["gt"] = 499823.517,
["args"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18566,
["t"] = 1792270489,
["n"] = 2,
},
{
["gt"] = 499858.37,
["args"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18566,
["t"] = 1792270524,
["n"] = 2,
},
{
["gt"] = 499882.235,
["args"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18566,
["t"] = 1792270548,
["n"] = 2,
},
{
["restr"] = 0,
["loot"] = {
["slots"] = 1,
["list"] = {
{
["guidType"] = "GameObject",
["type"] = 1,
["slot"] = 1,
["sourceId"] = 35591,
["qty"] = 1,
["guid"] = "GameObject-0-4621-1-15-35591-BDA09E7366",
["itemId"] = 6289,
},
},
},
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 6686,
["t"] = 1792278568,
["gt"] = 507902.161,
["n"] = 2,
},
{
["n"] = 2,
["loot"] = {
["slots"] = 1,
["list"] = {
{
["guidType"] = "GameObject",
["type"] = 1,
["slot"] = 1,
["itemId"] = 2770,
["qty"] = 1,
["guid"] = "GameObject-0-6782-0-8-1731-B61E572647",
["sourceId"] = 1731,
},
},
},
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 190,
["t"] = 1792278746,
["gt"] = 508079.992,
["restr"] = 0,
},
{
["n"] = 2,
["loot"] = {
["slots"] = 1,
["list"] = {
{
["guidType"] = "GameObject",
["type"] = 1,
["slot"] = 1,
["itemId"] = 2770,
["qty"] = 1,
["guid"] = "GameObject-0-6782-0-8-1731-B61E572647",
["sourceId"] = 1731,
},
},
},
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 190,
["t"] = 1792278760,
["gt"] = 508094.942,
["restr"] = 0,
},
{
["n"] = 2,
["loot"] = {
["slots"] = 1,
["list"] = {
{
["guidType"] = "GameObject",
["type"] = 1,
["slot"] = 1,
["itemId"] = 2770,
["qty"] = 1,
["guid"] = "GameObject-0-6782-0-8-1731-B61E572647",
["sourceId"] = 1731,
},
},
},
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 190,
["t"] = 1792278766,
["gt"] = 508100.363,
["restr"] = 0,
},
{
["restr"] = 0,
["loot"] = {
["slots"] = 1,
["list"] = {
{
["guidType"] = "GameObject",
["type"] = 1,
["slot"] = 1,
["sourceId"] = 1617,
["qty"] = 1,
["guid"] = "GameObject-0-6782-1-17-1617-4273096CC3",
["itemId"] = 765,
},
},
},
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 145,
["t"] = 1792278873,
["gt"] = 508207.607,
["n"] = 2,
},
{
["n"] = 2,
["loot"] = {
["slots"] = 1,
["list"] = {
{
["guidType"] = "Creature",
["type"] = 1,
["slot"] = 1,
["itemId"] = 3299,
["qty"] = 1,
["guid"] = "Creature-0-4621-0-19-833-A2FDE5D262",
["sourceId"] = 833,
},
},
},
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18039,
["t"] = 1792279121,
["gt"] = 508455.329,
["restr"] = 0,
},
{
["n"] = 2,
["loot"] = {
["slots"] = 1,
["list"] = {
{
["guidType"] = "Creature",
["type"] = 1,
["slot"] = 1,
["itemId"] = 783,
["qty"] = 1,
["guid"] = "Creature-0-4621-0-19-833-A2FDE5D262",
["sourceId"] = 833,
},
},
},
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18039,
["t"] = 1792279126,
["gt"] = 508460.63,
["restr"] = 0,
},
{
["restr"] = 0,
["loot"] = {
["slots"] = 1,
["list"] = {
{
["guidType"] = "Item",
["type"] = 1,
["slot"] = 1,
["qty"] = 1,
["guid"] = "Item-4618-0-400000008C56C916",
["itemId"] = 10940,
},
},
},
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 417,
["t"] = 1792280056,
["gt"] = 509390.733,
["n"] = 2,
},
},
["attemptedAt"] = 1792280005,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "L1",
["startedAt"] = 1792270366,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["P2"] = {
["title"] = "Restriction and state getters found by P1 (no-argument getters and the restriction enum)",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "default",
["t"] = 1792271162,
["gt"] = 500496.699,
["results"] = {
{
["fn"] = "C_Secrets.HasSecretRestrictions()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_CombatLog.IsCombatLogRestricted()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Loot.IsLegacyLootModeEnabled()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney()",
["present"] = true,
["error"] = "bad argument #1 to '?' (Usage: local inboxItemHasMoneyAttached = C_Mail.HasInboxMoney(inboxIndex))",
},
{
["fn"] = "C_MerchantFrame.GetNumJunkItems()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_MerchantFrame.IsSellAllJunkEnabled()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["summary"] = {
["count"] = 6,
["values"] = "Combat=0 Encounter=1 ChallengeMode=2 PvPMatch=3 Map=4 Chat=5",
},
["fn"] = "Enum.AddOnRestrictionType",
},
{
["fn"] = "GetAddOnRestrictionState(Combat)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Combat)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Encounter)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Encounter)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(ChallengeMode)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(ChallengeMode)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(PvPMatch)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(PvPMatch)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Map)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Map)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Chat)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Chat)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
},
},
{
["label"] = "default",
["t"] = 1792271225,
["gt"] = 500559.765,
["results"] = {
{
["fn"] = "C_Secrets.HasSecretRestrictions()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_CombatLog.IsCombatLogRestricted()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Loot.IsLegacyLootModeEnabled()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney()",
["present"] = true,
["error"] = "bad argument #1 to '?' (Usage: local inboxItemHasMoneyAttached = C_Mail.HasInboxMoney(inboxIndex))",
},
{
["fn"] = "C_MerchantFrame.GetNumJunkItems()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_MerchantFrame.IsSellAllJunkEnabled()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["summary"] = {
["count"] = 6,
["values"] = "Combat=0 Encounter=1 ChallengeMode=2 PvPMatch=3 Map=4 Chat=5",
},
["fn"] = "Enum.AddOnRestrictionType",
},
{
["fn"] = "GetAddOnRestrictionState(Combat)",
["present"] = true,
["returns"] = {
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Combat)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Encounter)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Encounter)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(ChallengeMode)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(ChallengeMode)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(PvPMatch)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(PvPMatch)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Map)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Map)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Chat)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Chat)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "P2",
["startedAt"] = 1792271162,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["R1"] = {
["title"] = "Trade events",
["notes"] = {
"Rehgar Deadeye: helper Blurr Technicolor",
"round 1 TRADE_CLOSED, helper Blurr Technicolor",
"round 2 TRADE_SHOW, helper Blurr Technicolor",
"roudn 3 TRADE_ACCEPT_UPDATE, helper Blurr Technicolor",
"round 3 try 2 TRADE_ACCEPT_UPDATE, helper Blurr Technicolor",
"round 4 TRADE_MONEY_CHANGED, helper Blurr Technicolor",
},
["events"] = {
["TRADE_ACCEPT_UPDATE"] = {
["registerCall"] = "returned normally",
["delivered"] = 6,
["samples"] = {
{
["gt"] = 4738.411,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
["money"] = 5287,
["t"] = 1792332066,
["n"] = 2,
["restr"] = 0,
},
{
["gt"] = 4740.412,
["args"] = {
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
["money"] = 5287,
["t"] = 1792332068,
["n"] = 2,
["restr"] = 0,
},
{
["gt"] = 4747.954,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
["money"] = 5287,
["t"] = 1792332076,
["n"] = 2,
["restr"] = 0,
},
{
["gt"] = 4900.027,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
["money"] = 5287,
["t"] = 1792332228,
["n"] = 2,
["restr"] = 0,
},
{
["gt"] = 4902.296,
["args"] = {
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
["money"] = 5287,
["t"] = 1792332230,
["n"] = 2,
["restr"] = 0,
},
{
["gt"] = 4909.151,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
["money"] = 5287,
["t"] = 1792332237,
["n"] = 2,
["restr"] = 0,
},
},
["attemptedAt"] = 1792331956,
["isEventRegistered"] = true,
},
["TRADE_MONEY_CHANGED"] = {
["registerCall"] = "returned normally",
["delivered"] = 1,
["samples"] = {
{
["gt"] = 5074.54,
["args"] = {
},
["money"] = 5292,
["t"] = 1792332402,
["restr"] = 0,
["n"] = 0,
},
},
["attemptedAt"] = 1792332275,
["isEventRegistered"] = true,
},
["TRADE_SHOW"] = {
["registerCall"] = "returned normally",
["delivered"] = 1,
["samples"] = {
{
["gt"] = 4578.302,
["args"] = {
},
["money"] = 5297,
["t"] = 1792331906,
["restr"] = 0,
["n"] = 0,
},
},
["attemptedAt"] = 1792331829,
["isEventRegistered"] = true,
},
["TRADE_CLOSED"] = {
["registerCall"] = "returned normally",
["delivered"] = 4,
["samples"] = {
{
["before"] = {
["event"] = "PLAYER_MONEY",
["dt"] = 0,
},
["gt"] = 4386.401,
["args"] = {
},
["money"] = 5307,
["t"] = 1792331714,
["n"] = 0,
["restr"] = 0,
},
{
["before"] = {
["event"] = "PLAYER_MONEY",
["dt"] = 0,
},
["gt"] = 4386.401,
["args"] = {
},
["money"] = 5307,
["t"] = 1792331714,
["n"] = 0,
["restr"] = 0,
},
{
["n"] = 0,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.394,
},
},
["args"] = {
},
["money"] = 5307,
["t"] = 1792331801,
["gt"] = 4473.565000000001,
["restr"] = 0,
},
{
["n"] = 0,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.394,
},
},
["args"] = {
},
["money"] = 5307,
["t"] = 1792331801,
["gt"] = 4473.565000000001,
["restr"] = 0,
},
},
["attemptedAt"] = 1792331652,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "R1",
["startedAt"] = 1792331327,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["P0"] = {
["title"] = "Presence of every candidate API and event name",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["summary"] = {
["count"] = 53,
["list"] = "GetLootSourceInfo=function GetLootSlotInfo=function GetLootSlotType=function GetLootSlotLink=function GetNumLootItems=function LootFrame=table UnitOnTaxi=function GetUnitSpeed=function UnitIsAFK=function UnitIsDND=function IsMounted=function IsFlying=function IsSwimming=function IsFalling=function IsResting=function UnitIsDeadOrGhost=function GetItemInfo=function GetItemInfoInstant=function C_Item.GetItemInfo=function C_Item.GetItemInfoInstant=function C_Item.RequestLoadItemDataByID=function C_Item.GetItemCount=function C_Container.GetContainerNumSlots=function C_Container.GetContainerItemInfo=function C_Container.GetContainerItemLink=function C_Map.GetBestMapForUnit=function C_Map.GetPlayerMapPosition=function C_Map.GetMapInfoAtPosition=function C_Map.GetMapHighlightInfoAtPosition=function C_Map.GetMapWorldSize=function C_Map.GetWorldPosFromMapPos=function C_Map.GetMapRectOnMap=function C_EventUtils.IsEventValid=function issecretvalue=function C_Secrets=table C_RestrictedActions=table C_CombatLog=table C_DamageMeter=table C_LootHistory=table C_Loot=table C_MerchantFrame=table C_Mail=table C_TradeInfo=table C_QuestLog=table C_TaxiMap=table Settings=table C_SettingsUtil=table hooksecurefunc=function WorldMapFrame=table WorldMapFrame.ScrollContainer=table CreateVector2D=function debugprofilestop=function GetTimePreciseSec=function",
},
["fn"] = "present",
},
{
["summary"] = {
["count"] = 2,
["list"] = "GetContainerNumSlots GetContainerItemInfo",
},
["fn"] = "absent",
},
{
["fn"] = "IsEventValid(LOOT_OPENED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(LOOT_SLOT_CLEARED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(LOOT_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(CHAT_MSG_LOOT)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(CHAT_MSG_MONEY)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MERCHANT_SHOW)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MERCHANT_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(QUEST_TURNED_IN)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_SHOW)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_INBOX_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TRADE_SHOW)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TRADE_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TRADE_MONEY_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TRADE_ACCEPT_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(UNIT_SPELLCAST_SUCCEEDED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_CONTROL_LOST)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_CONTROL_GAINED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TAXIMAP_OPENED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TAXIMAP_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_FLAGS_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_UPDATE_RESTING)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_XP_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(BAG_UPDATE_DELAYED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(ITEM_DATA_LOAD_RESULT)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(GET_ITEM_INFO_RECEIVED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "P0",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["P1"] = {
["title"] = "Function names inside the C_* tables found by P0 (names only, nothing is called)",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "default",
["t"] = 1792270236,
["gt"] = 499569.901,
["results"] = {
{
["summary"] = {
["count"] = 27,
["names"] = "CanCompareUnitTokens GetPowerTypeSecrecy GetSpellAuraSecrecy GetSpellCastSecrecy GetSpellCooldownSecrecy HasSecretRestrictions ShouldActionCooldownBeSecret ShouldAurasBeSecret ShouldCooldownsBeSecret ShouldSpellAuraBeSecret ShouldSpellBookItemCooldownBeSecret ShouldSpellCooldownBeSecret ShouldTotemSlotBeSecret ShouldTotemSpellBeSecret ShouldUnitAuraIndexBeSecret ShouldUnitAuraInstanceBeSecret ShouldUnitAuraSlotBeSecret ShouldUnitComparisonBeSecret ShouldUnitHealthMaxBeSecret ShouldUnitIdentityBeSecret ShouldUnitPowerBeSecret ShouldUnitPowerMaxBeSecret ShouldUnitSpellCastBeSecret ShouldUnitSpellCastingBeSecret ShouldUnitStatsBeSecret ShouldUnitThreatStateBeSecret ShouldUnitThreatValuesBeSecret",
},
["fn"] = "C_Secrets",
},
{
["summary"] = {
["count"] = 3,
["names"] = "CheckAllowProtectedFunctions GetAddOnRestrictionState IsAddOnRestrictionActive",
},
["fn"] = "C_RestrictedActions",
},
{
["summary"] = {
["count"] = 5,
["names"] = "GetAllEncounterInfos GetInfoForEncounter GetLootHistoryTime GetSortedDropsForEncounter GetSortedInfoForDrop",
},
["fn"] = "C_LootHistory",
},
{
["summary"] = {
["count"] = 2,
["names"] = "GetLootRollDuration IsLegacyLootModeEnabled",
},
["fn"] = "C_Loot",
},
{
["summary"] = {
["count"] = 7,
["names"] = "GetBuybackItemID GetItemInfo GetMerchantCurrencies GetNumJunkItems IsMerchantItemRefundable IsSellAllJunkEnabled SellAllJunkItems",
},
["fn"] = "C_MerchantFrame",
},
{
["summary"] = {
["count"] = 5,
["names"] = "CanCheckInbox GetCraftingOrderMailInfo HasInboxMoney IsCommandPending SetOpeningAll",
},
["fn"] = "C_Mail",
},
{
["summary"] = {
["count"] = 4,
["names"] = "AddTradeMoney PickupTradeMoney SetTradeMoney ShouldShowTradeOfferWarning",
},
["fn"] = "C_TradeInfo",
},
{
["summary"] = {
["count"] = 3,
["names"] = "GetAllTaxiNodes GetTaxiNodesForMap ShouldMapShowTaxiNodes",
},
["fn"] = "C_TaxiMap",
},
{
["summary"] = {
["count"] = 11,
["names"] = "ApplyFilterSettings AreFilteredEventsEnabled ClearEntries DoesObjectMatchFilter GetEntryRetentionTime GetMessageLimit IsCombatLogRestricted RefilterEntries SetEntryRetentionTime SetFilteredEventsEnabled SetMessageLimit",
},
["fn"] = "C_CombatLog",
},
{
["summary"] = {
["count"] = 93,
["names"] = "AbandonQuest AddQuestWatch AddWorldQuestWatch CanAbandonQuest DoesQuestAwardReputationWithFaction GetAbandonQuest GetAbandonQuestItems GetActivePreyQuest GetActiveThreatMaps GetAllCompletedQuestIDs GetBountiesForMapID GetBountySetInfoForMapID GetDistanceSqToQuest GetHeaderIndexForQuest GetInfo GetLogIndexForQuestID GetMapForQuestPOIs GetMaxNumQuests GetMaxNumQuestsCanAccept GetNextWaypoint GetNextWaypointForMap GetNextWaypointText GetNumQuestLogEntries GetNumQuestObjectives GetNumQuestWatches GetNumWorldQuestWatches GetQuestAdditionalHighlights GetQuestDetailsTheme GetQuestDifficultyLevel GetQuestIDForLogIndex GetQuestIDForQuestWatchIndex GetQuestIDForWorldQuestWatchIndex GetQuestLogMajorFactionReputationRewards GetQuestLogPortraitGiver GetQuestObjectives GetQuestRewardCurrencies GetQuestRewardCurrencyInfo GetQuestTagInfo GetQuestTimers GetQuestType GetQuestWatchType GetQuestsOnMap GetRequiredMoney GetSelectedQuest GetSuggestedGroupSize GetTimeAllowed GetTitleForLogIndex GetTitleForQuestID GetTrivialRange GetZoneStoryInfo HasActiveThreats IsAccountQuest IsComplete IsEliteQuest IsFailed IsImportantQuest IsMetaQuest IsOnMap IsOnQuest IsPushableQuest IsQuestBounty IsQuestCalling IsQuestCriteriaForBounty IsQuestDisabledForSession IsQuestFlaggedCompleted IsQuestFlaggedCompletedOnAccount IsQuestFromContentPush IsQuestInvasion IsQuestReplayable IsQuestReplayedRecently IsQuestTask IsQuestTrivial IsRepeatableQuest IsThreatQuest IsUnitOnQuest IsWorldQuest QuestCanHaveWarModeBonus QuestContainsFirstTimeRepBonusForPlayer QuestHasQuestSessionBonus QuestHasWarModeBonus",
},
["fn"] = "C_QuestLog",
},
},
},
},
["id"] = "P1",
["startedAt"] = 1792270236,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
},
["refs"] = {
{
["gt"] = 499771.668,
["args"] = {
},
["money"] = 18556,
["t"] = 1792270437,
["n"] = 0,
},
{
["before"] = {
["event"] = "LOOT_OPENED",
["dt"] = 0.509,
},
["gt"] = 499788.827,
["args"] = {
},
["money"] = 18566,
["t"] = 1792270454,
["n"] = 0,
},
{
["gt"] = 499936.793,
["args"] = {
},
["money"] = 18456,
["t"] = 1792270602,
["n"] = 0,
},
{
["before"] = {
["event"] = "LOOT_SLOT_CLEARED",
["dt"] = 0.417,
},
["n"] = 0,
["after"] = {
{
["event"] = "LOOT_SLOT_CLEARED",
["dt"] = 0.133,
},
},
["args"] = {
},
["money"] = 142,
["t"] = 1792273642,
["gt"] = 502976.137,
["restr"] = 0,
},
{
["before"] = {
["event"] = "LOOT_SLOT_CLEARED",
["dt"] = 0,
},
["gt"] = 503024.321,
["args"] = {
},
["money"] = 145,
["t"] = 1792273690,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 503769.537,
["args"] = {
},
["money"] = 18242,
["t"] = 1792274435,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 503771.978,
["args"] = {
},
["money"] = 18232,
["t"] = 1792274438,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 503832.879,
["args"] = {
},
["money"] = 18149,
["t"] = 1792274498,
["n"] = 0,
["restr"] = 0,
},
{
["before"] = {
["event"] = "QUEST_TURNED_IN",
["dt"] = 0.041,
},
["gt"] = 505089.348,
["args"] = {
},
["money"] = 323,
["t"] = 1792275755,
["restr"] = 0,
["n"] = 0,
},
{
["before"] = {
["event"] = "MAIL_INBOX_UPDATE",
["dt"] = 0.365,
},
["gt"] = 513807.819,
["args"] = {
},
["money"] = 367,
["t"] = 1792284473,
["restr"] = 0,
["n"] = 0,
},
{
["n"] = 0,
["after"] = {
{
["event"] = "TRADE_CLOSED",
["dt"] = 0,
},
{
["event"] = "TRADE_CLOSED",
["dt"] = 0,
},
},
["args"] = {
},
["money"] = 5307,
["t"] = 1792331714,
["gt"] = 4386.401,
["restr"] = 0,
},
{
["before"] = {
["event"] = "TRADE_CLOSED",
["dt"] = 0.394,
},
["gt"] = 4473.959,
["args"] = {
},
["money"] = 5297,
["t"] = 1792331802,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 4593.83,
["args"] = {
},
["money"] = 5287,
["t"] = 1792331921,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 4915.043,
["args"] = {
},
["money"] = 5292,
["t"] = 1792332243,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 5079.93,
["args"] = {
},
["money"] = 5292,
["t"] = 1792332408,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 5116.491,
["args"] = {
},
["money"] = 5282,
["t"] = 1792332444,
["restr"] = 0,
["n"] = 0,
},
{
["before"] = {
["event"] = "BAG_UPDATE_DELAYED",
["dt"] = 0.15,
},
["restr"] = 0,
["after"] = {
{
["event"] = "BAG_UPDATE_DELAYED",
["dt"] = 0.289,
},
},
["args"] = {
},
["money"] = 6158,
["t"] = 1792334214,
["gt"] = 6886.676,
["n"] = 0,
},
{
["gt"] = 7251.595,
["args"] = {
},
["money"] = 224,
["t"] = 1792334579,
["restr"] = 0,
["n"] = 0,
},
{
["gt"] = 7495.31,
["args"] = {
},
["money"] = 373,
["t"] = 1792334823,
["restr"] = 0,
["n"] = 0,
},
{
["before"] = {
["event"] = "AUCTION_HOUSE_AUCTION_CREATED",
["dt"] = 0.358,
},
["gt"] = 10749.73,
["args"] = {
},
["money"] = 17939,
["t"] = 1792338077,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 10817.926,
["args"] = {
},
["money"] = 17935,
["t"] = 1792338146,
["n"] = 0,
["restr"] = 0,
},
{
["before"] = {
["event"] = "MAIL_INBOX_UPDATE",
["dt"] = 0.106,
},
["gt"] = 13394.521,
["args"] = {
},
["money"] = 60,
["t"] = 1792340722,
["restr"] = 0,
["n"] = 0,
},
{
["before"] = {
["event"] = "MAIL_INBOX_UPDATE",
["dt"] = 0.233,
},
["restr"] = 0,
["after"] = {
{
["event"] = "MAIL_INBOX_UPDATE",
["dt"] = 0,
},
},
["args"] = {
},
["money"] = 90,
["t"] = 1792340741,
["gt"] = 13413.096,
["n"] = 0,
},
{
["before"] = {
["event"] = "MAIL_INBOX_UPDATE",
["dt"] = 0.267,
},
["gt"] = 13690.843,
["args"] = {
},
["money"] = 6138,
["t"] = 1792341018,
["restr"] = 0,
["n"] = 0,
},
},
},
["loads"] = 73,
["transcript"] = "loaded. Type /gidiag for commands. (load count 73)\nWARNING: about to register MAIL_INBOX_UPDATE. If an ADDON_ACTION_FORBIDDEN popup appears, that event is RESTRICTED:\nreport the popup text. Nothing changes on your character. Type /reload afterwards before any further registration.\nMAIL_INBOX_UPDATE: registered (IsEventRegistered true). Now do this: One event per session: /gidiag lab reg MAIL_SHOW ; open the mailbox, take money, take an item\nCapturing the first 40 payloads. Then /gidiag lab watch, /gidiag lab report, /reload.\nnote added to CO1\n== X2 Mailbox header metadata: sender, subject, money, items, auction invoice  [all-mail] ==\n  MailFrame:IsShown(): shown=true\n  money: copper=6038\n  C_Mail.CanCheckInbox() -> false | 15\n  GetInboxNumItems() -> 1 | 1\n  GetInboxHeaderInfo(1) -> nil | 134327 | Divine Slaps | COD Payment: Spider Ichor (4) | 100 | 0 | 30.997095108032 | nil | true | false | false | true | false | nil | nil\n  C_Mail.HasInboxMoney(1) -> true\n  GetInboxInvoiceInfo(1) -> nil | nil | nil | 0 | 0 | 0 | 0\n  GetInboxItem(1,1) -> \n  GetInboxItemLink(1,1) -> \n== X2 Mailbox header metadata: sender, subject, money, items, auction invoice  [cod-money] ==\n  MailFrame:IsShown(): shown=true\n  money: copper=6138\n  C_Mail.CanCheckInbox() -> true | 0\n  GetInboxNumItems() -> 0 | 0\nPhase 3a lab report  1.60.1 build 70450  at 1792341039\nP0 [review, suggested] Presence of every candidate API and event name\n   api runs: 1\nI1 [review, suggested] Item data: sell price, bind type, async behaviour\n   api runs: 3\nI2 [review, suggested] Bags: readable item fields and scan cost\n   api runs: 1\nA1 [review, suggested] AFK flag and related state\n   api runs: 2\nS1 [review, suggested] Map position in the open world and in an instance\n   api runs: 5\n   note: Rehgar Deadeye: Ragefire Chasm, entered and left once.\nT2 [review, suggested] Movement speed, mounted, flying, swimming, taxi flags (single snapshot)\n   api runs: 1\nT1a [review, suggested] Taxi flag and position jumps over time (also covers T2, T3, T4)\n   track: 75 samples, maxSpeed 7, taxi 0, maxJump 0.006, mapChanges 3\nP1 [review, suggested] Function names inside the C_* tables found by P0 (names only, nothing is called)\n   api runs: 1\nP2 [review, suggested] Restriction and state getters found by P1 (no-argument getters and the restriction enum)\n   api runs: 2\nI1b [pass, suggested] Item data load completion event (async item info)\n   GET_ITEM_INFO_RECEIVED: delivered 4, samples 4, IsEventRegistered true\n   note: Dottie Slaps: fresh login, item data test\nH1 [review, suggested] Place names for map coordinates\n   api runs: 1\nH2 [review, suggested] Map overlay host: a test square on the world map\n   square: shown\n   note: part of a red square around Sentinel Hill, not completely filled in. I will upload a screenshot of it.\nL3 [review, suggested] Loot window slot data and source GUID\n   api runs: 9\nL1 [pass, suggested] LOOT_OPENED payload and order versus PLAYER_MONEY\n   LOOT_OPENED: delivered 13, samples 13, IsEventRegistered true\n   note: Rehgar Deadeye: fishing\n   note: Sunder Slaps: mining\n   note: Sunder Slaps: mining\n   note: Grizzly Slaps: herb\n   note: Divine Slaps: enchanter\nL2 [pass, suggested] LOOT_SLOT_CLEARED per slot\n   LOOT_SLOT_CLEARED: delivered 9, samples 9, IsEventRegistered true\nM1 [pass, suggested] Merchant open/close, sale and purchase order versus money\n   MERCHANT_SHOW: delivered 2, samples 2, IsEventRegistered true\n   MERCHANT_CLOSED: delivered 3, samples 3, IsEventRegistered true\n   note: Divine Slaps: MERCHANT_CLOSED, vendor Barkeep Morag\nQ1 [pass, suggested] Quest turn-in payload\n   QUEST_TURNED_IN: delivered 1, samples 1, IsEventRegistered true\nX1 [pass, suggested] Mail events\n   MAIL_CLOSED: delivered 0, samples 0, IsEventRegistered true\n   MAIL_INBOX_UPDATE: delivered 20, samples 20, IsEventRegistered true\n   note: Divine Slaps: mail receiver, 1 mail with money and a small stack of an item\n   note: Divine Slaps: MAIL_CLOSED, mailbox holds an auction sale mail\nX2 [review, suggested] Mailbox header metadata: sender, subject, money, items, auction invoice\n   api runs: 12\n   note: Divine Slaps: mailbox with 1. auction cancelled mail, 2. copper only mail, 3. item only mail, 4. item and copper mail\nQ2 [pass, suggested] Quest reward item: bag snapshot diff and BAG_UPDATE_DELAYED\n   BAG_UPDATE_DELAYED: delivered 2, samples 2, IsEventRegistered true\n   api runs: 2\n   note: Rehgar Deadeye: quest Hezrul Bloodmark, reward Bounty Hunter's Ring, fixed\nAHS [review, suggested] Auction house state: money, window, own auctions (listing, cancel, buyout)\n   api runs: 15\n   note: Divine Slaps: auction house, listing, cancel, buyout, bid\n   note: deposit shown 100 copper\n   note: cancel window said will lose your initial deposit by canceling this auction\n   note: buyout price shown 13 copper\n   note: bid shown 101 copper\n   note: bid price shown 300 copper, buyout 400 copper\nAH1 [pass, suggested] Auction house events (one per session)\n   AUCTION_HOUSE_AUCTION_CREATED: delivered 1, samples 1, IsEventRegistered true\n   note: Chilly Slaps: session 23, post, cancel, buyout, bid, one snapshot after each\n   note: deposit shown 100 copper\nMS1 [inconclusive, suggested] Outgoing mail: postage and money sent\n   api runs: 7\n   note: Rehgar Deadeye: outgoing mail to my other character Divine Slaps, item, money, COD\n   note: postage shown 30 copper\nCO1 [inconclusive, suggested] COD mail: paying and receiving (uses X2 and MAIL_INBOX_UPDATE)\n   note: Divine Slaps: paying a COD of 1 silver\n   note: Rehgar Deadeye: COD payment mail and any other mails\nR1 [pass, suggested] Trade events\n   TRADE_ACCEPT_UPDATE: delivered 6, samples 6, IsEventRegistered true\n   TRADE_MONEY_CHANGED: delivered 1, samples 1, IsEventRegistered true\n   TRADE_SHOW: delivered 1, samples 1, IsEventRegistered true\n   TRADE_CLOSED: delivered 4, samples 4, IsEventRegistered true\n   note: Rehgar Deadeye: helper Blurr Technicolor\n   note: round 1 TRADE_CLOSED, helper Blurr Technicolor\n   note: round 2 TRADE_SHOW, helper Blurr Technicolor\n   note: roudn 3 TRADE_ACCEPT_UPDATE, helper Blurr Technicolor\n   note: round 3 try 2 TRADE_ACCEPT_UPDATE, helper Blurr Technicolor\n   note: round 4 TRADE_MONEY_CHANGED, helper Blurr Technicolor\nT1b [not run] Taxi and control events\nC1 [fail, suggested] UNIT_SPELLCAST_SUCCEEDED (highest suspicion of the old popup)\n   UNIT_SPELLCAST_SUCCEEDED: delivered 39, samples 39, IsEventRegistered true\n   note: Chilly Slaps: skinning\n   note: Grizzly Slaps: herb\n   note: Sunder Slaps: mining\n   note: Rehgar Deadeye: fishing\n   note: Divine Slaps: enchanter cast\nC2 [not run] CHAT_MSG_MONEY (only if L1 fails)",
["lastLoad"] = 1792340911,
}
