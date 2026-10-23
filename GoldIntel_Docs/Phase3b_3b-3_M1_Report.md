# 3b-3 M1 report: pure item modules (build 0.4.0-phase3b3m1)

Date 2026-10-19. Authorization: D-080, M1 only. Tests: 1168 passed, 0 failed (1036 existing, unchanged, plus 132 new). Updated for D-081 (option B): see the last section. Package GoldIntel_3b3_M1_AddOns.zip. **Nothing is wired**: no events, no storage, no commands, no Platform change. Installing it changes no behavior; `/reload` is enough if you do. Known-good rollback build: GoldIntel_3b2_M8_AddOns.zip.

## Delivered
| File | What |
|---|---|
| `Collect/BagDiff.lua` | per-item-id diff; only `complete == true` snapshots compared; baseline advances only on `Commit`; a diff can be committed once, a superseded diff never (I-4) |
| `Ledger/Valuation.lua` | vendor floor, manual price (beats vendor), `noVendor` (sell price 0 is known), `pendingInfo`/`unknown`/`invalid`, first valuation (`Complete`), `Expire` (30 s window, stays unknown and retryable), `bound` = bindType 1 or 4 |
| `Ledger/Lots.lua` | lots, FIFO `Convert` with exact copper allocation (Q-8), shortfall counting, closed summary and ring, open cap with merge of equal-valued lots, `Check` (I-3), `Stats` |
| Docs | D-080 approved; Contract 1.9 + F17; Architecture AC-14..AC-19 and item invariants; Changelog, TODO, Handoff |

## Evidence of correctness
- Property tests: random snapshot streams (shadow inventory reproduces carried inventory after every commit), random add/convert streams (I-2, I-3 after every step, quantities and copper exact), allocation always sums exactly (500 random cases up to 2e9 copper).
- 35 mutants (9 BagDiff, 8 Valuation, 18 Lots), each caught by at least one scenario. One survivor was found and closed during the build (transfer totals).
- Isolation (AC-15, I-6): static tests prove the three modules contain no reference to Cash, Reconciler, Expectations, Platform, GetTime or GetMoney, and that loading them adds only `Valuation` and `Lots` to the namespace. The runtime half of the requirement (every existing cash replay byte-identical with the item pipeline ACTIVE) can only be tested once the pipeline is wired, so it is a hard M2/M3 test, not claimed here.

## Choices I made inside the approved design (please veto any)
1. **`vc` is coerced, not rejected.** A lot requested with `vc = true` that violates I-5 is still created (so I-3 holds) with `vc = false`, and `Stats().vcCoerced` counts it. Rejecting would lose items from the ledger.
2. **Equal-per-unit fallback, now never silent.** If any item in a vendor sale has no known price, the sale copper is split equal per unit (`alloc = true`) so totals stay exact, AND the condition is raised as an anomaly. Same for a sale where an item with sell price 0 leaves the bags while money comes in (user directive 2026-10-19). See section Anomalies.
3. **Merge key** ignores the `merged` flag so merged lots keep merging; pending lots never merge; a merged lot keeps its earliest time and origin.
4. **Closed lots** enter `closedSummary` at the moment they close; the ring only keeps recent copies (no double count).
5. **A first valuation books value under the original lot** (created/transfer/unattributed totals), never at completion time.
6. `Convert` rejects an unknown `via`, negative or fractional copper, and malformed removal entries without consuming anything.

## Known gaps handed to M2 (not defects of M1)
- `Platform/Bags.lua` still returns `{items, slots}` for bags 0 to 4 and has no `complete` field. M2 must add completeness and the reported bag count (E-32 read bags 0 to 5).
- Equipped gear is not in any snapshot yet (Q-5); M2 evidence decides how.
- Shortfall handling is counted and visible; what the explain view shows is M3.

## Next
Your review of M1. Then M2 needs its own go-ahead: Platform/Bags extension, `P_BAG_DIFF`, ItemSources in trace-only mode, CHAT_MSG_LOOT recorder, repair-cost probe, and Session E (bag index range, equip/unequip, repair-cost API, bank movement, roll-awarded items). No lot is stored before you approve that evidence.

## Anomalies (added after your 13:36 directive)
`Lots` has an anomaly register: every unexpected condition is counted (`Stats().anomalies`), kept in a ring of 50 records (time, kind, detail), passed to an `alert(kind, record)` hook on EVERY occurrence, and has a text ending "This is not expected: please report it as a bug." Kinds: `sale-price-unknown`, `sale-no-sell-price` (money in at a vendor while a no-sell-price item leaves), `equal-split`, `shortfall`, `unallocated-copper`, `vc-coerced`. A clean sale of a known, sellable item raises nothing (tested), and an alert error cannot break the ledger. 9 more mutants cover it (flag missing, wrongly raised, hook never called, ring unbounded).
Not done yet (M3, needs your go-ahead): the visible chat line (one per kind per session so it cannot spam), the listing in `/gi lots status`, trace lines. M1 only provides the register and the hook.

## D-082 update (manual price)
`Valuation.Value` now uses the HIGHEST of vendor and manual price; manual wins only when strictly higher and only when item data is ready; with no manual price the vendor value stands (never a default). The typed price is taken as typed (no AH cut). Tests: 1174 passed, 0 failed, 3 new mutants.

## D-081 update (option B)
Converting items that no tracked lot covers is now normal: counted in `Stats().shortfall` / `unallocated`, never an anomaly (mutant added: an alarm there is caught). `Lots:Check` is an optional diagnostic. Anomalies that remain: sale-price-unknown, sale-no-sell-price, equal-split, vc-coerced. Withdrawn from the 3b-3 plan: opening/gap lots, equipped gear and bag slots in scope, the exact bag-match invariant. Tests: 1168 passed, 0 failed.
