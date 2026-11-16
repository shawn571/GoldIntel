# GoldIntel Phase 3a Closure Recommendation

DOC VERSION: 1.0.0  |  DATE: 2026-10-18  |  AUTHOR: Claude (S-037)  |  STATUS: PROPOSED, awaiting the user's review. Closing Phase 3a does NOT authorize Phase 3b (D-051, D-042).

Evidence is cited as E-numbers in `Compatibility_Notes.md`; raw files are in `evidence/`.

## 1. Recommendation

**Phase 3a (diagnostics, experiments, signal verification) is COMPLETE WITH EXCEPTIONS, listed in section 4.**

Every signal the Phase 3b design depends on has been observed in the live client (WoW Forever 1.60.1, build 70450), registered with no popup, and its behaviour, payload and timing are recorded. The 18 lab sessions recorded 34 evidence items (E-17..E-34). Where a signal did not behave as hoped (`MAIL_CLOSED`, subzone names from `C_Map`, map position inside instances), a working fallback is named. Two matrix rows have no result and need your call (section 4, X-A and X-B).

## 2. Review gate (Phase3a_Verification_Protocol section 8) versus evidence

| Gate | Status |
|---|---|
| 1. Every signal-matrix row has pass, fail with fallback, or explicitly dropped | MET except two rows that need your decision (X-A kill proxy, X-B boat/zeppelin) |
| 2. Results recorded in Compatibility_Notes (E-17..) with raw files in `evidence/` | MET (E-17..E-34; session files 2026-10-17 and 2026-10-18a..f) |
| 3. Matrix and planning package updated; any contradicted decision D-043..D-054 reopened | MET. No decision D-043..D-054 is contradicted. D-004 was amended by D-065 (1.0 s window). One design note (section 5, mail deposit) for Phase 3b |
| 4. User reviews and decides on Phase 3b | THIS DOCUMENT; your decision is section 6 |

## 3. What is verified

| Area | Result | Evidence |
|---|---|---|
| Money | `PLAYER_MONEY` plus `GetMoney`. Zero-delta events occur (cancelled trade) and are ignored | E-31 |
| Loot | `LOOT_OPENED`, `LOOT_SLOT_CLEARED` non-secret, before the money; slot and source GUID readable (creature, game object; skinning reports the corpse); slot-cleared can repeat; money lag up to 0.509 s | E-18..E-20, E-24, E-25 |
| Gather, fish, cast | `UNIT_SPELLCAST_SUCCEEDED` for the player: no popup, readable even in combat; spell ids for herb, mining, skinning, fishing, disenchant seen | E-23, E-26 |
| Vendor | `MERCHANT_SHOW` and `MERCHANT_CLOSED` (button/Esc and walk-away; duplicates possible); sale positive, purchase and repair negative, inside the open window | E-21, E-33 |
| Quest | `QUEST_TURNED_IN` (id, xp, money; money equals the money delta exactly, arrives 0.041 s before it). Item rewards by bag diff; `BAG_UPDATE_DELAYED` fires before and after the money | E-22, E-32 |
| Mail | `MAIL_INBOX_UPDATE` (no payload, 0.365 s before the money). Headers readable with the mailbox open: AH cancel, AH sale, player gift, alt transfer separable. Sold-auction invoice readable before the take. `MAIL_CLOSED` NOT delivered | E-28, E-29, E-34 |
| Trade | `TRADE_SHOW`, `TRADE_CLOSED` (twice per close), `TRADE_ACCEPT_UPDATE`, `TRADE_MONEY_CHANGED`; money 0.394 s after the close | E-31 |
| Item data | Sell price and bind type for cached items; async load by `C_Item.RequestLoadItemDataByID` and `GET_ITEM_INFO_RECEIVED(itemID, success)`; unknown stays unknown until it arrives | E-17, E-30 |
| Bags | `C_Container.GetContainerItemInfo` non-secret, 0.74 ms for 44 slots | E-17, E-32 |
| Position and travel | `C_Map` in the open world and cities; nil map inside instances by design, entry and exit verified; `UnitOnTaxi` polled works; hearth jump pattern; AFK flag polled | E-17, E-18, E-27 |
| Restrictions | No popup from any registered event. `COMBAT_LOG_EVENT_UNFILTERED` never registered (D-030) | E-17..E-34 |

Test suite at the end of Phase 3a: 551 passed, 0 failed.

## 4. Exceptions carried out of Phase 3a

| ID | Exception | Why it does not block closure | Needs |
|---|---|---|---|
| X-A | **Kill proxy** (XP event or creature loot source as a grind signal) never tested (G1, G2) | Creature loot source GUID is verified, and D-044 only credits heat on acquisition, so a kill count is not needed for heat. The proxy only improves the GRIND label | **Your decision:** drop the XP kill proxy (recommended) or test it |
| X-B | Boat/zeppelin travel jump (T4) not tested; T1b (taxi control events) not run | Taxi flag polling and the hearth pattern are verified; any loading gap is already treated as a break | Your decision: test later in play or drop |
| X-C | `MAIL_CLOSED` not delivered | Not needed: money is attributed from `MAIL_INBOX_UPDATE`; mailbox open state is polled with `MailFrame:IsShown()` | None. Caveat: closes were not independently time-stamped (E-34) |
| X-D | Trade item side and `GetPlayerTradeMoney/GetTargetTradeMoney` not probed; helper accept not visible | Trade gold is attributed from money delta plus trade context kept at least 1.0 s after the close (D-065). Items traded are an item-ledger matter | Optional probe in Phase 3b |
| X-E | Choice-reward quests, stack merges and full-bag cases, outdoor dungeon entrance, instance run with loot not tested | Fixed reward, bag diff and instance entry/exit are proven; the rest are edge cases | Collect during Phase 3b testing |
| X-F | H2 map overlay: drawing, scaling, translucency seen; click-through of pins not checked | UI is Phase 3b; no data effect | One check when the overlay is built |
| X-G | Subzone names from `C_Map` FAILED (zone only) | `GetSubZoneText()` at the player's position works (E-17); decision A-4 stays your call | A-4 |
| X-H | Lab constraint: one new event registration per game session | Lab only; Phase 3b registers all verified events at load, on the trusted list | None |

## 5. What Phase 3b depends on (rules the evidence now fixes)

1. Reconciliation window 1.0 s, both directions (D-065); the context signal outlives the close by at least 1 s.
2. Close handlers are idempotent (`TRADE_CLOSED`, `MERCHANT_CLOSED`, `LOOT_SLOT_CLEARED` can repeat). Loot is keyed by (source GUID, window time), never by GUID alone.
3. Bag diff is taken after the last `BAG_UPDATE_DELAYED` of a burst. Quest items consumed at turn-in are not sales.
4. Unknown item value stays unknown until `GET_ITEM_INFO_RECEIVED`; value is booked once at acquisition (D-043, D-045, D-046).
5. Mail: read headers and invoice before the take; mail index is unstable, so identity needs a fingerprint; headers are trustworthy only with the mailbox open. Mail never affects heat maps (D-064).
6. **New design note (mail deposit):** an Auction House sale mail pays price + deposit - cut (51 + 100 - 2 = 149). The deposit was already paid at listing, so only price minus cut (49) is sale income; the deposit is a refund. Phase 3b needs a rule for this in the ledger. I propose to settle it in the Phase 3b design review, not now.
7. Before the first collector ships: CPU and memory soak with `C_AddOnProfiler` (PX-7).

## 6. What you are asked to do

1. Decide whether Phase 3a is closed (recommended: yes, with X-A..X-H).
2. Decide X-A (drop the XP kill proxy: recommended yes) and X-B (drop or test boat/zeppelin: recommended leave for play, not a gate).
3. Say whether D-065 and the E-33/E-34 findings need any change.
4. Only then, and only if you choose, ask for the Phase 3b scope discussion. Nothing in Phase 3b has been started.

## 7. Governance items still open (unchanged by Phase 3a)

OI-5 (merge older documents), OI-8 (restriction model: now largely answered by evidence, closure wording needs your approval), OI-11 (re-probe after client patches), OI-13 (missing reviewer documents), X-2 (D-027, D-028), PX-1..PX-8 from Phase 2, A-4, label details of D-062 and D-063, and the Architecture section 8 wording amendment (not applied).

## 8. Confidence

- Signals and timing: high. Each signal was seen in at least one clean live run; the most timing-sensitive ones (loot, trade, mail, quest) have several samples.
- Mail invoice meaning: medium. One sale only; the arithmetic matches but one field is unexplained.
- `MAIL_CLOSED` absence: medium-high (two closes, zero events, registration confirmed), not independently time-stamped.
- Kill proxy: no data.
