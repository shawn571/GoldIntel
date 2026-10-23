# 3b-1 live validation, round 2 (addon 0.3.1-phase3b1)

Restart needed: YES (full client restart). Move GoldIntelDiag and GIProbeLoot out of Interface\AddOns first.
Use the character that has items, a mailbox with several mails, and a second character or helper for trading if possible.
Keep a paper tally: kills, loot windows opened, vendor opens, mails taken, trades, quests, posts.

1. Close the game. Extract GoldIntel_Phase2_AddOns.zip into Interface\AddOns (replace GoldIntel and GIMin). GoldIntelDiag and GIProbeLoot must NOT be in AddOns.
2. Start the game, log in. Type: /gi collect status   (expect: off, 0 registered, quarantined: none)
3. Type: /gi collect on   (expect: 14 registered now, 0 failed, 0 skipped by quarantine, no popup)
4. LOOT. Auto-loot OFF. Do all of these: (a) loot a corpse taking everything; (b) open a loot window, wait 20 s, then take the item; (c) open a window and press Escape without taking anything; (d) open a window and walk away; (e) take only the coin from a corpse that has an item and leave the item; (f) open an empty corpse. Tally each.
5. VENDOR. Open a vendor, sell 2 items, close once with Escape and once by walking away.
6. MAIL. Go to a mailbox holding several mails (the more the better, ideally 5 or more). Open it, take one mail with money or an item, close it. Open it a second time and close it without taking anything.
7. QUEST. Turn in one quest if you have one ready.
8. TRADE. With a helper: one completed trade (gold or an item each way) and one trade you cancel.
9. AUCTION. At the auction house post one item, then close the window.
10. CAST. Cast one gathering spell or fishing once.
11. Type: /gi collect stats   and copy all lines.
12. Type: /gi collect off   then   /gi collect status   (expect 0 registered). Open and close a vendor window while off, then /gi collect stats again: vendor counts must NOT change.
13. Type: /gi collect on   then open and close one vendor window, then /gi collect stats: vendor counts rise by exactly one open and one close.
14. Type: /reload   then   /gi collect status   (expect off, 0 registered).
15. Log out normally. Send me: all copied outputs, any popup text word for word, your tally, and both GoldIntel.lua SavedVariables files (account file in WTF\Account\<account>\SavedVariables, character file in WTF\Account\<account>\<realm>\<character>\SavedVariables).

What I will check: all 14 registered, no popup; loot windows closed by frame (timeout must be 0 in normal play); slot clears and duplicates; longest open time; mail snapshot CPU (MAIL_INBOX_UPDATE cpu column) and snapshot count; trade, quest and auction counters against your tally; no errors; clean off/on with nothing counted while off.
