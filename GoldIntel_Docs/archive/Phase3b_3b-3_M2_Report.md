# 3b-3 M2 Report — trace-only item pipeline (build 0.4.1-phase3b3m2)

Status: built, 1,196 tests passing, live evidence collected 2026-10-19. **Awaiting user approval of the evidence. M3/M4 not authorized.**

## Built
Collect/ItemSources.lua (trace only; touches no Sources/Reconciler/Cash), CHAT_MSG_LOOT evidence recorder (group G8), bags 0..5 with completeness and Ranges(), Items classID/subclassID, P_LOOT_OPEN.guid, skinning detection, `/gi lots` (status, on, off, decisions, iteminfo), Contract 1.9.0.

## Evidence answers
| Question | Answer |
|---|---|
| Bag index range | 0..5; 5 = reagent bag (6 slots when equipped, 0 otherwise); 6..8 read 0 |
| Roll-awarded items | NOT observed (needs a group). Open, low risk |
| CHAT_MSG_LOOT shapes | self loot and multi observed; id/qty parsed correctly |
| Loot item timing | bag diff 0.1-0.25 s after window close; decision at 2.0 s covers money |
| No-vendor items | decided by sell price 0 only; five shapes + enchanting-mat nominal 1c recorded in Compatibility_Notes |
| Vendor buyback | no separate signal; appears as vendorBuy at the sale price |
| Reagent bag | user: items never enter it directly, only by manual move; a move nets to zero (observed) |
| Cash isolation | live ledger check 0 copper; test: cash entries identical with item pipeline on/off |

## Findings
- Cursor pick-up/put-back produces `ignored` then `unexplained` (D-083: relabel only in M3).
- Item-info events arrive in bursts for items never requested (nearby vendor wares); noise.
- Item 279912 never becomes ready; handled as unknown/invalid.
- Destroying an item = `ignored` (D-081).

## Open (low risk)
Roll-awarded items; item arriving directly in a reagent bag (user says it does not happen).

## Next (needs approval)
M3: lot persistence, per D-080/D-081/D-082.
