# 3b-3 M3 Report — stored lots (build 0.4.7-phase3b3m3)

Status: built, 1,230 tests passing. **Awaiting Session V (live) and your review. M4 not authorized.**

## What it does (economic ledger, D-081/D-084)
- Creates lots from: loot and quest rewards (value created), vendor purchases (cost kept, not created), disenchant materials (conversion, not created).
- Consumes lots on: vendor sales (copper split exactly), quest turn-ins, disenchant sources, trade-outs (0 copper).
- Only counts: mail/trade arrivals, "other additions (moves, returns, unknown)", inventory-only removals (destroy, equip, move).
- Items without data yet become unknown lots and are valued when the data arrives or at the next start; invalid ids stay unknown (listed).
- Unexpected conditions (sale at an item with no sell price, price unknown at sale, equal split, coerced value-created) are counted, shown once per kind with "please report it as a bug", and written to the trace.
- Manual price: `/gi price set|list|clear`, optional, used only when higher than vendor, never changes past lots.
- Location and activity stamps from the loot window are stored on each loot lot for Phase 4/5.

## Safety
- AC-15: the lot book never references Cash, Reconciler, Expectations or Sources (tested on the source text).
- Cash isolation: cash entries identical with lots on/off (test); all existing cash replays unchanged with the item pipeline active.
- Rollback verified: the 0.3.8 (3b-2 M8) build starts on data containing lots[charKey] and prices.manual, store ok and writable, cash intact.
- Read-only store: no lots created, no error.

## Not in M3 (by decision)
Opening/gap lots, equipped-gear scope, mirrored inventory, mail/trade lots (return with 3b-4), AH item flows.

## Next
Session V (Phase3b_3b-3_M3_Session_V.md). M4: measurements (lot size, CPU, memory), closure recommendation — needs your approval.

## Session V results (user, 2026-10-21, builds 0.4.3 to 0.4.7)
| Check | Result |
|---|---|
| `/gi ledger check` | 0 copper difference (OK), over several intervals incl. a final one with mark (+12c moved, +12c entries) |
| Lots created from loot, quests, purchases (buybacks) | correct counts; purchases not value created; quest items 0c |
| Vendor sales vs cash entries | exact match per sale (+6c, +1s10c, +2c, +45c = lots 6c, 1s10c, 2c, 45c); stack split exact (7c per unit) |
| Quick multi-sale burst (5 sales in 0.3 s in the M2 trace) | caught a double-count in the first M3 design (every decision saw all 156c); fixed by pairing each money event with its nearest bag settle (D-085), tested |
| Persistence | lots, conversions and totals identical after /logout and login |
| Reagent bag | bag 5 read; loot into the reagent bag attributed like any other loot |
| Skinning at apprentice rank | found not detected (only spell 8617 known); fixed by spell-name matching (0.4.6); live: `skinning=true act=GATHER/high` |
| Anomalies | none; errors 0 |
| Crash | none after the first /reload crash on M2 (cause unknown, not reproduced) |

## Fixes found during Session V
D-085 money pairing; spell-name gathering recognition (verified for skinning only); CAST trace line; `/gi lots sales`; conversion totals in status; activity and "no vendor value" in `lots last`.

## Still open
Roll-awarded items won by the player (not observed); herbalism/mining/fishing spell names at other ranks (expected to match, unverified); the unexplained empty loot windows (src=unknown, 0 items) and the first /reload crash on M2; M4 (measurements: lot size, CPU, memory; closure recommendation) awaits your approval.
