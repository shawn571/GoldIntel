# 3b-3 closure recommendation

**STATUS: APPROVED by the user 2026-11-08. 3b-3 CLOSED with the accepted risks of section 4 (D-101).** Written 2026-11-08 (S-062).

Date 2026-11-08. Builds in live use: 0.5.0-passive to 0.5.5-passive (live servers since 2026-11-04); 0.5.6-passive delivered with this document. Tests: 1,319 passed, 0 failed. Scope: Phase3b_Increment_3b-3_Scope_and_Readiness.md as amended by D-081 (acquisition and conversion accounting, not an inventory mirror), D-082, D-083, D-084, D-085.

## Recommendation

Close 3b-3, with the accepted risks in section 4. No condition: the live evidence of 2026-11-04 to 2026-11-08 covers every item source in scope, and the M4 measurements pass NFR-3.

## 1. What 3b-3 delivered

- **M1:** pure modules BagDiff, Valuation, Lots (D-080).
- **M2:** item attribution as trace only, the CHAT_MSG_LOOT recorder (D-081, D-083).
- **M3:** the lot book, persisted per character. Lots are created by loot, quest rewards, vendor purchases and disenchant materials. They are consumed by vendor sales, quest turn-ins, disenchants and trade-outs. Commands `/gi lots` and `/gi price` (D-084); money pairing (D-085).
- **Passive play (D-086):** auto start, marked intervals, context and check lines.
- **Fixes from live play:**
  - first-window skinning (D-091);
  - logout check (D-092);
  - trainer source (D-093);
  - quest evidence line (D-094);
  - roll wins as loot (D-095);
  - split shares (D-096).
- **M4:** measurements (D-097), retention stopgap (D-098), and CPU-only samples (D-100).

## 2. Exit criteria (scope section 15) and evidence

| Criterion | Result |
|---|---|
| All tests green; invariants I-2, I-4..I-6 on replays and random streams; mutation set caught; no bare WoW global outside Platform/ | 1,319 passing; mutation checks for every live fix; boundary and Lua 5.1 checks pass. I-3 is an optional diagnostic since D-081 |
| Cash isolation (lots never write cash, AC-15) | Tested in M1 to M3 and again in the 0.5.2 to 0.5.5 tests; cash entries identical with the item pipeline on or off |
| No popup, no Lua error, no quarantine | None in any upload 2026-11-04 to 2026-11-08; no event failed to register; client patch 70862 changed nothing |
| `/gi ledger check` 0 copper | Every periodic and final check on 0.5.2 and later reads 0. The only MISMATCH lines are the 0.5.1 logout false alarm, fixed by D-092 |
| `/gi lots check` 0 quantity difference | WITHDRAWN as a hard rule by D-081; stays an optional diagnostic |
| Every source classified as in scope section 2.2 | Live: loot windows (creature, object, skinning including first windows, mining), quest rewards, vendor purchases and sales, disenchant (14 casts, materials booked), trade (item add), roll wins, chat-pushed quest items. Mail and trade items create no lot by design (D-084 part 2) |
| Unattributed share reported by value first, then by count | See the metrics table (section 3) |
| Unknown items back to 0 except invalid ids | Open lots with unknown value: 0 on all characters |
| Lot size, CPU and memory within NFR-3 or reported | CPU 0.04 to 0.06 ms per frame (target under 0.5); lasting memory growth about 0.06 MB per hour (target under 2); one measurement artefact found and removed (D-100). Sizes and caps in the M4 report |

## 3. Metrics (live servers 2026-11-04 to 2026-11-08)

| Character | Cash entries | OTHER by value | OTHER by count | Largest OTHER | Login gaps | Lots created (value) | Anomalies |
|---|---|---|---|---|---|---|---|
| Main | 1,835 | income 0.64% (1,106 of 172,080 c); spending 25.7% (37,318 of 145,035 c) | 124 (6.8%) | 8,000 c (an AH bag, user) | 2 (+36, +44 c) | 1,772 (151,600 c) | none |
| Alt | 134 | income 20% (385 of 1,921 c); spending 62.5% (1,141 of 1,825 c) | 14 (10.4%) | 385 c | 1 (−356 c) | 132 (662 c) | none |

What the OTHER spending is (main character): auction-house buyouts (24,000 c, three bags, user-confirmed), flight fares (330 to 550 c each), postage and other small sinks. All of these are 3b-4 sources or candidates, so they are OTHER by design until 3b-4. OTHER income on the main character is under the 2% starting target.

Item side (main character): 282 vendor sales allocated exactly (43,525 c); 351 quest consumptions; 204 units sold that no lot covered, and 13,490 c allocated to no lot. Both are NORMAL under D-081: starting gear and items that were held before tracking began.

## 4. Accepted risks and what is not verified

- **Lag case:** a coin chat line before a late money change, 2026-11-04. The fix is held at the user's choice. Lag up to 3,000 ms was seen in Ragefire Chasm.
- **One quest reward arrived without quest context** (Rugged Mail Vest). The `EVT quest done` line (D-094) is collecting evidence; there has been no repeat with the line in place.
- **Roll wins through a loot window you have open** count as value created with activity OTHER (low), not LOOT.
- **Soft spots of D-081:**
  - gear swaps appear as "other additions";
  - crafting (smelting) is unexplained by design.
- **Never seen live:** herbalism, fishing, money in a trade, money taken from mail, a sold-auction mail, COD. The AH and COD flows are 3b-4.
- **Item 279912 never becomes ready** (beta) and has not reappeared.
- **Retention** is a stopgap (D-098) until Phase 4 aggregates exist. Merged lots keep the place only at subzone level.
- **A client crash loses everything since the last save.** The money comes back as a login gap (R-21).

Policy (as in D-079): anything found wrong later in 3b-3 functionality is a bug fix and does not reopen the increment.

## 5. Not part of 3b-3

- **3b-4:** auction-house deposit, buyout, bid and sale, COD paid, outgoing mail and postage, other sinks such as flight fares if approved, and mail and trade item lots.
- **Phase 4 and later:** aggregates, sessions, gold per hour, rankings, heat map, prices.

## Decision needed

Approve closing 3b-3 (D-101 would record it), or name what must happen first. Closing 3b-3 does not start 3b-4 or P4-M2: each needs its own go-ahead.
