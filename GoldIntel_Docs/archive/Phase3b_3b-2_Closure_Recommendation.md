# 3b-2 closure recommendation

**STATUS: APPROVED by the user 2026-10-19. 3b-2 CLOSED (D-079).**

Date 2026-10-19. Build: 0.3.8-phase3b2m8 (zip GoldIntel_3b2_M8_AddOns.zip). Tests: 1036 passed, 0 failed. The user waived the grouped live validation (2026-10-19): any grouped-play issue found on the live server is treated as a bug fix.

## Recommendation
Close 3b-2, with the accepted risks listed in section 4. One cheap condition I recommend (the user may waive it): a 5-minute solo smoke test of 0.3.8 in the live client, because the code that turns the chat line into an expectation and the 2.0 s hold have only run against the test world and replays of real traces, never live. Steps: install the zip, `/reload`, `/gi collect on`, loot 3 mobs, `/gi ledger check`, `/gi ledger status`. Expected: difference 0 copper, OTHER share 0, unmatched 0, no Lua error.

## 1. What 3b-2 delivered (D-077)
Expectations, Reconciler, Sources (loot, quest, mail, vendor, trade), Stamps, Cash ledger (schema 2, cap 2000, fold 500), commands (`ledger check/mark/status/last/trace`), login gap check, accounting invariant (sum of deltas = sum of entries + pending), the diagnostic trace, the lastMoney fix, and the coin chat-signal loot rule with the range-based split match. AH deposit/buyout/bid, COD paid and postage stay OTHER until 3b-4 (D-077 Q-1).

## 2. Live evidence (quality indicators)
| Evidence | Build | Result |
|---|---|---|
| E-46 M4, Role 1 (28 entries) | 0.3.3 | OTHER 6.5% by value (110c of 1680c), 7.1% by entries, largest OTHER 80c, unmatched 0, gaps 0, checks 0 copper |
| E-46 M4, Role 2 (2 entries) | 0.3.3 | OTHER 39% (32c of 82c, only the deferred COD payment), unmatched 0, gaps 0, checks 0 copper |
| E-46 M4, Role 3 auto-loot in a group | 0.3.3 | OTHER 75.9% by value, 18 unmatched; cause found: group coin split. Check 0 copper |
| E-47 solo auto-loot | 0.3.4b | 16 of 16 coins matched exactly |
| E-48 solo, chat evidence | 0.3.5 | 10 of 10 loots matched, chat line 0.52-1.00 s after the money change, unmatched 0, check 0 copper |
| E-49 grouped (before the rule) | 0.3.5 | 14 coin changes (49c) all OTHER by design; 6 of 7 loot windows unmatched; chat line present on 14 of 14, 7 of them with no local window; check 0 copper |
| Replay of E-49 under the rule | 0.3.8 (tests) | 14 of 14 loot, OTHER 0 by value and entries, largest OTHER 0, unmatched 0, gaps 0, sum exact |
| Replay of E-48 under the rule | 0.3.8 (tests) | 10 of 10 loot, no doubles, unmatched 0 |
Non-zero ledger differences found anywhere: none.

## 3. Defects found and fixed during 3b-2
lastMoney stored 0 at a real logout (E-46); group coin split misread as OTHER (E-46/E-49); lastMoney followed the live balance so money pending at a crash was lost (found by the new crash test); partner-looted coin was activity OTHER (now LOOT, medium).

## 4. Accepted risks and what was NOT verified live
- The chat-signal rule and the 2.0 s hold have not run in the live client (only in tests and replays of real traces).
- Groups of 3 or more, a member out of range, one player looting several corpses: tested only against the user's confirmed rules (coin is split among members in range, or everyone in an instance).
- Silver and gold chat wording: user-reported, not measured (beta is level-capped). Unreadable text falls back to OTHER.
- A real logout and login with the final lastMoney logic: tested in the test world, not repeated live after the change.
- Never verified live: trade, buyer's COD payment arriving, AH sale mail, looting with full bags (coin), an empty loot window (E-47 saw one, 0.2 s, no coin lost).
- Partner-looted coin carries activity LOOT (medium) and the player's stamped location, not credited to heat bins.
- Coin split among a different number of sharers than expected leaves a loot window unmatched; the money is still recorded as loot.
Policy: any of these found wrong on the live server is handled as a bug fix.

## 5. Not part of 3b-2
AH posting/buying/cancel, COD paid, postage (3b-4); other sinks (taxi, trainer, respec, barber, guild bank) are 3b-4 scope candidates; lots, loot rules, item ownership (3b-3, not started).

## Decision needed
Approve closing 3b-2 (with or without the solo smoke test), then say when to start 3b-3 or 3b-4 planning. Nothing starts before that.
