# GoldIntel Phase 3b, increment 3b-3: Scope and Readiness Package

DOC VERSION: 1.0.0  |  DATE: 2026-10-19  |  AUTHOR: Claude (S-054)  |  STATUS: PROPOSED, for the user's review. **This is NOT authorization to implement.** 3b-3 planning is approved (user, 2026-10-19); 3b-3 implementation is not. No 3b-3 code exists or will be written until the user approves a scope in a new decision (D-080, same procedure as D-051, D-067, D-077).

Evidence is cited as E-numbers (`Compatibility_Notes.md`). Precedence: Requirements > Decisions > Architecture; Contracts wins on data shapes. Already approved and NOT reopened here: D-043 (value booked once, at acquisition), D-044/D-064 (only creature or object loot is location-eligible; quest, mail, trade, vendor never), D-045 (vendor floor), D-046 (late item data stays visible as unknown), D-063 (a historical value is never overwritten), D-067 (ledgers only), D-069 (Lot flags), D-071 (disenchant recorded, not revalued), D-072 (validation rules), D-073 (replay corpus is permanent), D-079 (3b-2 closed; post-closure bug-fix policy).

## 1. Summary and recommendation

**What 3b-3 is:** the first increment that writes item records. It turns the item side of the signals 3b-1 already delivers (loot windows, quest turn-in, vendor, mail, trade, bag settle, item data) into **lots**: one record per acquisition, valued once, consumed once, with sales, purchases and disenchants as conversions (FR-LED-2, FR-LED-3). It never writes a cash entry and never changes one that exists. The 3b-2 invariant (sum of deltas = sum of entries + pending, 0 copper difference) cannot be affected by construction; section 10 makes that a tested property.

**Readiness:** the item signals are verified (loot window slots E-19/E-24, disenchant E-25/E-26, bag settle timing and quest-reward diff E-32, cold item cache E-30, vendor close E-33, mail E-28/E-29). The adapters `Platform/Bags.lua` (`Snapshot`, `P_BAGS_SETTLED`) and `Platform/Items.lua` (`Items.Get`, `P_ITEM_INFO`) already exist from 3b-1 and have not yet been used to produce records. Three facts are NOT verified and are the reason I propose an **evidence gate inside 3b-3** (section 11, M2): which bag indexes exist on Forever (E-32 read bags 0 to 5; the adapter reads 0 to 4), what a bag diff looks like for equip/unequip, bank and group-roll items, and whether the repair cost is readable before the click. This is the same pattern that made 3b-2 safe: evidence first (M5), rule second.

**Recommendation:** approve 3b-3 as the narrow scope in section 2, in four milestones with a review gate after M2 (trace only, nothing stored), schema 2 unchanged (additive), and the decisions in section 12. Expected new tests: about 290 (1,036 to about 1,330).

## 2. Scope

### 2.1 In scope for 3b-3

| # | Item |
|---|---|
| S1 | `Collect/BagDiff.lua`: pure function (snapshot, snapshot) to a diff aggregated per item id; incomplete-snapshot refusal; idempotence key |
| S2 | `Platform/Bags.lua` additions: carried-inventory snapshot (bags, plus equipped gear if Q-5 approved), `P_BAG_DIFF` emission after each settle |
| S3 | `Collect/ItemSources.lua`: the only place that knows what an item addition or removal means (loot, quest, mail, vendor, trade, disenchant, unexplained). Mirrors `Sources.lua` for money |
| S4 | `Ledger/Lots.lua`: lot store per character, FIFO consumption, conversions, retention, `LEDGER_LOT`, inventory reconciliation (`Lots:Check`) |
| S5 | `Ledger/Valuation.lua`: tiers 1 and 2 (vendor floor, manual price), flags `unknown`, `pendingInfo`, `noVendor`, `bound`; first valuation of a pending lot |
| S6 | Item data lifecycle: `pendingInfo` window, retry on `P_ITEM_INFO`, retry at login, visible unknown count (D-046, R-37) |
| S7 | Opening lots (first enable per character) and item gap lots at login (the item twin of the cash gap) |
| S8 | Commands: `/gi lots status|check|last [n]|unknown|off|on`, `/gi price set|list|clear` (manual prices), `/gi lots reset confirm` (see Q-12) |
| S9 | Trace lines for bag diffs and lot decisions (reuse `Ledger/Trace.lua`), `Stats().lots` counters |
| S10 | Tests, replay of the corpus, mutation checks, one evidence session, one validation session |

### 2.2 Item sources in 3b-3 (evidence in brackets)

| Source | Item event | Lot created | Value created (vc) | Evidence |
|---|---|---|---|---|
| Creature or object loot (kill, node, fish, skin) | slots at `P_LOOT_OPEN`, confirmed by the diff after the last settle | free lot, src `loot`, act from Stamps (GRIND, GATHER, FISH, LOOT) | yes (D-043); location-eligible only as in D-044 | E-19, E-24, E-42 |
| Quest reward | addition inside the quest context | free lot, src `quest` | yes (economic), never location-eligible (D-064) | E-22, E-32 |
| Vendor purchase | addition inside the merchant context with a negative delta | purchase lot at cost | no (cash to asset conversion) | E-21, E-33 |
| Mail take | addition inside the mail context | lot, src `mail`, flag `transfer` | no (transfer in; the item existed before) | E-28, E-29 |
| Trade received | addition inside the trade context | lot, src `trade`, flag `transfer` | no | E-31 (items unprobed) |
| Disenchant | loot source type `Item` (E-25) plus the removal of the disenchanted item | materials as free lots, flag `conversion` | no (D-071) | E-25, E-26 |
| Anything else | addition with no matching expectation | lot, src `unknown`, flag `unattributed`, conf low | no | R-34 |
| Opening / gap | first enable; login difference | lot, flags `opening` / `gap` | no | new, Q-4 |

Removals: vendor sale (conversion `vendor`, copper from the cash entry), quest turn-in (`consume`, 0), disenchant (`consume`, 0), trade out (`trade`, 0, linked to the cash entry), listing on the Auction House (`ah`, 0, proceeds belong to 3b-4), anything else (`consume`, 0, flag `unexplained`).

### 2.3 Out of scope (explicit)

- Valuation tiers 3 and above (auction prices, any price provider) and revaluation of anything (Phase 6; D-062 stays Proposed).
- Bank, guild bank, void storage, other characters' bags (items leaving or entering bags without a context are unexplained; see R-3b3-2).
- Auction House item flows beyond the `ah` removal at posting (3b-4), outgoing mail items (3b-4, E-38), crafting and tradeskill results (no verified signal; they are unexplained additions).
- Aggregation into segments, wealth or GPH (Phase 4). Lots are stored and reported only through commands.
- Any heuristic classification (rejected by the user, see D-078).

## 3. Starting point (what 3b-1 and 3b-2 left)

- `Platform/Bags.lua`: `Snapshot()` returns `{ items = {[itemID]=qty}, slots }` for bags 0 to 4 (C_Container, E-17), refuses silently on secret values (counter `unreadable`); `P_BAGS_SETTLED` is emitted once per `BAG_UPDATE_DELAYED`. No diff, nothing stored.
- `Platform/Items.lua`: `Items.Get(itemID)` returns `status = ready|pending|secret|invalid`, sell price (11th return), bind type (14th). An empty GetItemInfo is never a price of 0. `P_ITEM_INFO { itemID, ready }`.
- `Collect/Context.lua` provides the loot, merchant, quest, mail and trade contexts that kept the money sources exact. The same contexts classify item changes.
- `Collect/Sources.lua` already holds `P_LOOT_OPEN` slots (itemID, qty) per window, which 3b-2 ignored for items.
- `Ledger/Cash.lua` is the pattern to copy for retention, `lmv`-style recovery and the diagnostic trace.
- Store: the `lots` section exists but is empty and its shape differs from Contracts F5b (section 7).
- 3b-2 deferred to this increment: repair versus purchase (Q-5 of 3b-2). It is Q-9 here.

## 4. Architecture changes (proposed amendments to Architecture 19; none applied)

| ID | Amendment |
|---|---|
| AC-14 | **Item pipeline mirrors the money pipeline.** Platform events -> `ItemSources` (item-aware translator) -> item expectations -> `BagDiff` confirmation -> `Lots`. The bag diff is the only thing that creates or consumes a lot; an expectation without a confirming diff creates nothing (R-34). |
| AC-15 | **Lots never write cash.** `Lots` has no dependency on `Cash`/`Reconciler` except reading the finalized cash entry for a conversion's copper (`ref`). The 3b-2 invariant is independent of every 3b-3 failure. All 3b-3 handlers run inside the same `guard()` as `Sources`: a Lua error is counted and swallowed. |
| AC-16 | **Carried inventory** is the unit the asset ledger accounts for: bags (and, if Q-5 is approved, equipped gear). Open lots per item id must equal the carried quantity after every settle (`Lots:Check`). Anything outside (bank etc.) is outside the ledger until a later increment. |
| AC-17 | **One valuation per lot.** Valuation happens at acquisition (D-043). A `pendingInfo` lot receives its FIRST valuation when item data arrives; that is completion, not revaluation, and is stored with its own time and basis. Nothing ever overwrites a valuation (D-063). |
| AC-18 | **Lot retention** is capped per character, closed lots fold into `closedSummary`, and equal-valued open lots of the same item may merge (section 7). Cap values are final only after measurement (D-072). |
| AC-19 | **Separate enable switch** `/gi lots on|off`, independent of `/gi ledger`; OFF after every login and `/reload` (same rule as Q-2 of 3b-2). While OFF the diff is not computed; the next ON reconciles through the gap rule (Q-4). |

Layer and load order (AC-3): `Platform/Bags.lua` and `Items.lua` exist; new files `Collect/BagDiff.lua`, `Collect/ItemSources.lua`, `Ledger/Lots.lua`, `Ledger/Valuation.lua`, then the TOC order stays Platform, Core, Store, Collect, Ledger, Future, Boot. No bare WoW global outside `Platform/` (invariant 5, enforced by the boundary test).

## 5. Lot ownership model

**Definitions**
- A **lot** is one acquisition of one item id by one character: `id, itemID, qty, qtyLeft, t, valueEach, valueSrc, how, origin = {act, loc}, flags, locConf, ctx` (Contracts F1 and 1.6) plus the additive fields proposed in section 7 (`src`, `vc`, `vt`, `ref`).
- A lot belongs to the character that held the item when the diff was taken. It never moves between characters. A mailed item leaves one character's ledger as a consumption (`via = 'mail'` is NOT claimed; see below) and enters the other as a new transfer lot.
- **FIFO per item id**, oldest lot first, ties by lot id. Bag position and stack boundaries are irrelevant (the diff is aggregated per item id).

**Invariants (new numbering, tested)**
- I-2 (Architecture 7, existing): a lot is created once and consumed once; `qtyLeft` never increases and never goes below 0; selling is a conversion, not value created.
- I-3 (new): after every processed settle, for each item id, the sum of `qtyLeft` over open lots equals the carried quantity. `Lots:Check()` returns the differences; the live check requires 0 for every item.
- I-4 (new): a diff is applied at most once (idempotence key = sequence number of the settle plus the two snapshot fingerprints). A duplicate settle produces no lot and no conversion.
- I-5 (new): value created (`vc = true`) is booked only at the lot's creation, only for loot, quest and (later) gather or fish acquisitions. Conversions, transfers, opening, gap, unexplained and disenchant materials have `vc = false`.
- I-6 (new): lots never touch the cash ledger; the 3b-2 accounting invariant is unchanged (property test: random item streams do not change any cash output).

**Origins**
1. *Free* (loot, quest): `how = 'free'`, valued at the floor, `vc = true`.
2. *Purchased* (vendor): `how = 'purchase'`, `valueEach` = cost per unit from the cash entry (exact copper; the delta is allocated over the added units, remainder copper to the first unit so the sum is exact), `vc = false`.
3. *Transfers* (mail, trade, unexplained, opening, gap): `how = 'free'`, `flags.transfer` or `unattributed` or `opening` or `gap`, valued at the floor, `vc = false`. They are inventory, not income.
4. *Conversion products* (disenchant materials): free lots, `flags.conversion`, `vc = false` (D-071: no revaluation; the disenchanted item was valued once at its own acquisition).

**Consumption**
- Vendor sale: FIFO over the removed item ids; each `Conversion { t, lotID, qty, copper, via = 'vendor' }`. The cash entry's copper is allocated over the removed units in proportion to `sellPrice x qty` (units with unknown price share equally); the remainder goes to the largest allocation so the allocated sum equals the entry exactly (Q-8). The copper is stored for the explain view ("realized variance", Architecture 7); it is not added to anything.
- Quest turn-in, disenchant, use/loss: `via = 'consume'`, copper 0.
- Trade out: `via = 'trade'`, copper 0, `ref` = trade cash entry id (the gold is on the cash side; splitting it over items would be a guess).
- Auction listing: `via = 'ah'`, copper 0, `ref` = posting time. 3b-4 pairs it with proceeds, cancel or expiry.
- If a removal exceeds the open lots (the opening baseline was absent or a lot was merged away wrongly) the shortfall is counted (`Stats().lots.shortfall`), the cash side is untouched, and `Lots:Check` fails visibly. It is never invented away.

**Group loot, rolls, free-for-all, master loot** affect which items arrive, not what the ledger does: a lot exists only if the diff confirms the item reached this character's carried inventory. Items other players receive never appear. The open question is attribution of a roll-won item that arrives after the window closed; it is covered by the evidence step in Q-10 and until then is an unattributed lot (conf low, visible).

## 6. Bag diff design

**Snapshot.** `Bags.Snapshot()` is extended to return per-item quantities plus a fingerprint and the number of slots read versus the number of slots the client reports. A snapshot with any unreadable (secret) slot is `incomplete`.

**Settle handling** (per `P_BAGS_SETTLED`, driven by `BAG_UPDATE_DELAYED`, E-32: fires once per change, 0.15 s before and 0.289 s after the money event):
1. Take a snapshot now. If incomplete, count `diffSkipped`, keep the previous baseline unchanged, and let the next complete snapshot absorb the change (nothing is guessed from a partial read).
2. `BagDiff.Compute(prev, now)` returns `added = {[id]=qty}`, `removed = {[id]=qty}` (per item id, so a stack split or merge nets to zero, R-34), `seq`, fingerprints. An empty diff (events with no net change) emits nothing.
3. The baseline advances only after the diff has been processed.
4. `P_BAG_DIFF { seq, added, removed, t, ctx? }` is emitted; `ItemSources` consumes it.

**Attribution** (`ItemSources`, per added or removed item id, in this order, each step consumes only what it is entitled to):
- *Loot expectation* from the open or recently closed loot window (slots known from `P_LOOT_OPEN`, cleared slots from `P_LOOT_SLOT_CLEARED`): expected `{itemID, qty}` pairs; an addition of that id up to the expected quantity is the loot lot. The window context lingers for the same hold as the money side (3b-2 learned the confirming events can lag; Q-10 will measure item lag).
- *Quest context* (inside the window around `QUEST_TURNED_IN`): every addition is a reward, every removal a consumed quest item (E-32: Hezrul's Head removed, Bounty Hunter's Ring added).
- *Merchant context*: with a negative money delta in the window, additions are purchases and removals are impossible to be the same transaction unless money is positive; with a positive delta, removals are sales. Both signs in one settle (sell and buy within the hold) are resolved by sign of each cash entry in the window, never by guessing: if the cash entries do not fit exactly, all item changes in the window become `unexplained`.
- *Mail context*: additions are transfers.
- *Trade context*: additions are transfers; removals are trade-outs.
- *Disenchant*: loot source type `Item` (E-25) marks the materials; the removed item is the one removal in the same settle that matches the disenchant cast context (`P_CAST`, spell 13262, E-26). If more than one candidate removal exists, nothing is chosen; all removals are `unexplained` and the materials are unattributed.
- *Everything else*: unexplained (additions: `unattributed` lot, removals: `consume` with flag `unexplained`).

**Repair versus purchase (carried from 3b-2 Q-5).** A negative merchant delta with no item added in the settle looks like a repair, but absence of a settle is not evidence (an equipment-only change might not raise a bag event). I therefore do NOT propose to infer it. Proposal: record in the evidence session whether `GetRepairAllCost()` (or the equivalent on Forever) returns the exact copper before the click. If yes, a repair becomes an exact expectation (like quest money) and the entry is classified `repair`/high going forward. If no, the 3b-2 behaviour (`purchase`, med) stays and the item side is the only thing that changes. No entry is ever edited afterwards (D-078 policy).

**Timing.** Items are confirmed by the diff of the last settle in the burst. The item hold (how long a window stays open for late settles) is measured in M2, not assumed. Money windows are untouched.

**Equipment and carried scope.** Equipping moves an item out of the bags (a removal) and unequipping moves it back (an addition). Accounting bags only would book gear swaps as use and unexplained additions. Q-5 proposes that the snapshot also includes equipped slots 1 to 19 (`GetInventoryItemID`), so equip/unequip nets to zero. Whether a bag event fires on equip, and whether the equipped id is readable in combat, is part of M2's evidence list.

**Cost.** One snapshot per settle (about 50 C calls). Profiling uses `Phase3b_Profiling_Plan.md`; the target stays NFR-3 (under 0.5 ms average per frame, under 2 MB growth per hour). Tables are reused between snapshots. If a settle storm is measured, snapshots coalesce to at most one per 0.25 s (the diff is per net change, so coalescing loses nothing).

## 7. Schema impacts

| Item | Proposal |
|---|---|
| Version | **Stay at schema 2, additive** (Q-3). No migration step. `GoldIntelDB.lots[charKey]` is created lazily exactly like `ledger[charKey]`. |
| Existing `lots` section | Today the factory creates `lots = { open = {}, closedSummary = {} }` at section level, which differs from Contracts F5b (`lots[charKey] = { open, closedSummary }`). Both are empty in every real file. Proposal: keep the legacy empty keys untouched and unused (documented), and store under `lots[charKey]`. The alternative (schema 3 with a clean migration and a backup) is Q-3 option B; it costs the rollback property below. |
| `lots[charKey]` | `{ nextId, open = { Lot... }, closed = { ring of recent closed lots }, closedSummary = { [itemID] = { qty, copperIn, copperOut } }, conv = { recent Conversion ring }, totals = { created, transfer, unattributed (n, qty, value) }, opening = boolean, snap = { fingerprint, items }, quality = { settles, skipped, shortfall, unknown } }` |
| `prices.manual` | account-wide `GoldIntelDB.prices.manual = { [itemID] = { copper, t, note? } }`; written only by `/gi price set`. The `prices` section already exists. |
| Lot (additive, Contracts 1.9) | `src` (SourceKey-like: `loot|quest|vendor|mail|trade|disenchant|unknown`), `vc` (boolean: counts toward value created), `vt` (valuation time), `ref` (cash entry id or posting time), flags add `transfer`, `unattributed`, `opening`, `gap`, `unexplained`, `merged` (existing: `unknown`, `bound`, `pendingInfo`, `noVendor`, `conversion`). `origin.act` gains no new key. |
| Conversion (additive) | `ref`, `alloc` (boolean: copper was allocated across items) |
| Retention (interim, final from measurement) | open lots cap 1,500 per character; when exceeded, the oldest open lots of the same item id with equal `valueEach`, `valueSrc`, `how`, `vc` and flags merge (qty summed, earliest `t` and origin kept, flag `merged`; value stays exact because `valueEach` is equal). Closed lots fold into `closedSummary` as soon as they close except a ring of the last 300. Estimated 100 to 140 bytes per lot; measured at the end of 3b-3 (D-072). |
| Rollback property | 3b-2's M8 build, installed over 3b-3, still passes its own Store validation with the extra keys (tested before M3 is accepted: the real M8 Store code is run against a database that contains `lots[charKey]` and `prices.manual`). If that test fails, the schema bump (option B) becomes mandatory and I will say so before building. |

Contract version 1.9 (additive, text only until approved): Lot fields above, `P_BAG_DIFF`, `LEDGER_LOT`, `Lots:*` and `Valuation:*` interfaces, `Stats().lots`, `Platform.Bags.Snapshot` extension, `Items` unchanged.

## 8. Valuation model

**Tiers**
- Tier 1, vendor floor: `Items.Get(id).sellPrice` per unit when `status = ready`. A real sell price of 0 is a known value (`flags.noVendor`, value 0, not unknown).
- Tier 2, manual price: `GoldIntelDB.prices.manual[id]`. When one exists at acquisition it is the basis (`valueSrc = 'manual'`, with the price date). Q-6 asks whether manual always beats vendor (my recommendation: yes, the user entered it deliberately; the vendor value stays visible in the explain view).
- `valueSrc` already allows `market|vendor|manual|unknown`; `market` stays unused until Phase 6.

**Item data lifecycle** (D-046, R-27, R-37; E-30)
1. Lot created. If the item is `ready`, valuation happens now (`vt = t`).
2. If `pending` or `secret`: the lot is created with `valueSrc = 'unknown'`, `valueEach = 0`, flags `unknown` and `pendingInfo`; a load is requested once (`C_Item.RequestLoadItemDataByID`, E-30: the event comes in the same frame or about 0.28 s later).
3. `P_ITEM_INFO ready` completes the first valuation of every `pendingInfo` lot of that id: `valueEach`, `valueSrc = 'vendor'`, `vt` = completion time, flags cleared. The lot's acquisition time, place and `vc` do not change; the value is attributed to the original acquisition (D-043, D-064), never to where the information arrived.
4. After the pending window (default 30 s, measured in M2) the lot stays `unknown` and remains retryable: on a later `P_ITEM_INFO` or at the next login the same completion rule applies. An `invalid` item id (event success false, E-30) is final: `unknown` stays, with `flags.invalid`.
5. The unknown count (lots, quantity, items) is part of `/gi lots status` and `/gi diag`. It is never silently valued at 0 in a total without being shown.

**Never done:** guessing a price, using a price from another item, using Auction House data (tier 3), writing a later price over an earlier valuation, valuing at a higher figure than recorded because the market moved (that is the "Current Market Value" of D-063, a separate computed figure).

**Bound items** (`bindType` from the 14th GetItemInfo return) are flagged `bound`; they are valued at the vendor floor and a manual price is allowed but labelled. The flag exists so Phase 6 tiers can skip them.

**Disenchant:** materials valued at their own floor, `vc = false`, flag `conversion`. The consumed item's lot is closed with `via = 'consume'`. No difference is booked anywhere (D-071).

## 9. Validation strategy

### 9.1 Automated (about 290 new tests, estimate)

| Area | Tests |
|---|---|
| BagDiff (aggregation per id, stack split/merge, incomplete snapshot, idempotence, duplicate settle, equip/unequip) | ~45 |
| Lots (create, FIFO, partial consume, shortfall, merge, fold, retention, invariants I-2..I-6, property tests with random streams) | ~80 |
| Valuation (tiers, noVendor, pending, completion, invalid, late, manual price, no overwrite, bound) | ~45 |
| ItemSources (each source in 2.2, combined sell and buy, quest, mail, trade, disenchant ambiguity, unexplained, loot expectation versus left-behind items, full bag) | ~55 |
| Store, schema and rollback property (lazy creation, round trip, M8 Store tolerance, reset) | ~20 |
| Commands and stats | ~20 |
| Replay corpus through the item pipeline (E-32 quest reward diff, E-25 disenchant, E-30 cold cache sequence, E-24 repeat loot windows, E-33 vendor, new fixtures from the M2 evidence session) | ~25 |

All 1,036 existing tests must still pass, unchanged. **Cash isolation test (I-6):** every existing cash replay is re-run with the item pipeline enabled and with item events injected; cash outputs must be byte-identical.

**Mutation checks** on BagDiff, Lots and ItemSources (D-073 style): sign error, consume twice, FIFO reversed, aggregate per slot instead of per id, apply a diff twice, advance the baseline on an incomplete snapshot, count an expectation without the diff, overwrite a valuation, treat pending as 0, give transfers `vc = true`, skip the shortfall counter, allocation remainder dropped. Each must fail at least one test.

### 9.2 Live (two sessions, collect ON, Diag lab OFF, GIProbeLoot out of AddOns)

- **Session E (evidence, after M2; nothing stored).** Scripted with exact commands, same style as Part A/B: loot items alone and with coin; auto-loot; a left-behind item; a full bag (leave one item); quest with reward; vendor sell of 1 item, then of 3 different items; vendor purchase; repair (note the repair-cost API result); equip and unequip a piece of gear; open the bank, deposit and withdraw one item (observation only); mail take with an item; trade one item each way if a helper is available; disenchant if an enchanter is available; one loot in combat; group roll (need/greed) if a partner is available (optional, waived like the grouped validation if not). Output: the trace file; I record E-numbers and set the final attribution rules.
- **Session V (validation, after M3).** Same scripted set against the finished pipeline, plus the fresh-login item cache (log out and in, loot a never-seen item, watch the unknown count rise and fall) and a crash-style test (`/reload` with pending item data). Checks: `/gi ledger check` = **0 copper** (unchanged requirement); `/gi lots check` = **0 quantity difference for every item id** (I-3); every scripted source classified as in 2.2; the unattributed share reported by value first and by entries (the D-072 rule applied to items); unknown count visible and returns to 0 except invalid ids; no Lua error, popup or quarantine.

Rules from D-072 continue: failures are recorded as evidence before any fix; a surviving mutant is a defect in the test.

## 10. Rollback plan

1. **Package rollback:** keep `GoldIntel_3b2_M8_AddOns.zip` (0.3.8) as the known-good build; install it over 3b-3. Same procedure as the earlier rollbacks.
2. **Data safety:** with schema 2 unchanged the older addon runs fully (cash ledger included), ignoring `lots[charKey]` and `prices.manual`. This is verified by a test (section 7) before M3 can be accepted. No `migrationBackup` is needed because no migration runs. If Q-3 option B is chosen instead, the older addon would run read-only on schema 3, and a backup copy is kept as in 3b-2.
3. **Kill switches:** `/gi lots off` stops the diff and all item handlers immediately (cash ledger keeps running). `/gi lots reset confirm` deletes the current character's `lots[charKey]` only (Q-12); lots are derived from the bag diff, so a reset starts a fresh opening baseline at the next ON. `/gi collect off` ends the interval. Nothing runs at login or `/reload`.
4. **Fault isolation:** item handlers run under `guard()`; an error is counted in `Stats().lots.errors`, the item pipeline disables itself after 5 errors in a session (reported in `/gi lots status`), and the cash path is unaffected (I-6, tested).
5. **Validation failure policy** (unchanged): any non-zero copper difference, quantity difference, popup, Lua error or quarantined event stops the session; the finding is recorded as E-number evidence before a fix.
6. **Post-closure policy** (D-079 applies): once 3b-3 is closed, edge cases (bank, rolls, wording, large groups) are bug fixes against 3b-3, not blockers.

## 11. Build milestones inside 3b-3 (gated)

- **M1** Pure modules: `BagDiff`, `Lots`, `Valuation` with property and mutation tests. No WoW, no storage. Review report.
- **M2** `Platform/Bags.lua` extension, `P_BAG_DIFF`, `ItemSources` in **trace-only mode**: item decisions are written to the trace and counted, **no lot is stored**. Evidence session E. **Review gate:** you review the evidence and the attribution rules before M3.
- **M3** Lot store, retention, opening and gap lots, commands, manual prices, replay corpus, rollback test. Review report.
- **M4** Validation session V, measurements (lot size, CPU, memory), 3b-3 closure recommendation.

## 12. Decisions requested

| ID | Question | My recommendation |
|---|---|---|
| Q-1 | Scope as in 2.1 to 2.3: item sources loot, quest, vendor buy/sell, mail, trade, disenchant; AH items beyond the posting removal, bank, crafting, outgoing mail stay unexplained until later | Yes |
| Q-2 | Milestones with the evidence gate after M2 (trace only, nothing stored until you review) | Yes |
| Q-3 | Schema: (A) stay at 2, additive, lazy `lots[charKey]`; (B) schema 3 with a clean migration and backup | A |
| Q-4 | Opening lots at the first enable per character, and item gap lots at login/ON (the item twin of the cash gap); both `vc = false` | Yes |
| Q-5 | Carried scope: bags (including any extra bag index the evidence shows, E-32 read 0 to 5) plus equipped gear, so equip and unequip net to zero | Yes, subject to M2 evidence |
| Q-6 | Valuation: manual price beats vendor floor when set; sell price 0 is `noVendor` (known), pending/secret is `unknown`; pending window 30 s (measured in M2) then retry on later info and at login | Yes |
| Q-7 | Only loot and quest items create value (`vc = true`); purchase, transfer, opening, gap, unattributed and disenchant materials do not | Yes |
| Q-8 | Vendor sale copper allocated across items by `sellPrice x qty`, remainder to the largest, stored with `alloc = true`; explain-view only | Yes |
| Q-9 | Repair versus purchase: probe the repair-cost API in Session E and decide with the result; no inference from absence, no retroactive edit | Yes |
| Q-10 | Add a `CHAT_MSG_LOOT` evidence recorder in M2 (allow-list addition, collector group like the coin chat; recorder only, no rule) to learn whether `You receive loot: [item]x2.` style lines give an exact item signal for rolls and delayed items. A rule would need a separate approval after the evidence, as in D-078 | Yes |
| Q-11 | Interim retention: open cap 1,500, closed ring 300, merge rule in section 7; final from measured size | Yes |
| Q-12 | Commands as in S8 including `/gi lots reset confirm` (current character only) | Yes |
| Q-13 | Contract 1.9 (additive) and Architecture amendments AC-14 to AC-19, text only | Yes |
| Q-14 | Disenchant materials `vc = false` (reading of D-071: no revaluation, source item valued once). Confirm that this is what you intended | Yes |

## 13. Risks (new, proposed IDs; existing R-34 and R-37 tightened)

| ID | Risk | Mitigation |
|---|---|---|
| R-34 | Loot items left behind, full bags, stack merges | Items count only when the diff confirms; diff aggregated per item id; tested |
| R-37 | Late or secret item data | `pendingInfo`, visible unknown count, first-valuation rule, retry at login |
| R-3b3-1 | Bag index set differs from the adapter (E-32 read 0 to 5, adapter reads 0 to 4); a missing bag silently hides items | M2 reads the reported bag count; Session E checks; `incomplete` snapshots are refused |
| R-3b3-2 | Items moving without a verified signal (bank, guild bank, crafting, outgoing mail, group rolls) produce unexplained rows | Unexplained is a visible, counted category with `vc = false`; never silent; evidence in Session E |
| R-3b3-3 | Equip/unequip books false removals and additions | Q-5 equipped slots in the snapshot; evidence for the event behavior |
| R-3b3-4 | Sell and buy in the same merchant window confuse item and cash matching | Resolved by cash entry sign and exact fit, otherwise all `unexplained`; mutation-tested |
| R-3b3-5 | Lot growth in long grinds (hundreds of lots per hour) | Cap, merge, fold; size measured; D-072 rule |
| R-3b3-6 | Bag reads fail or are restricted in combat | Incomplete snapshot handling; one combat loot in Session E |
| R-3b3-7 | A first-enable baseline taken while a diff is in flight loses an item | Baseline only from a complete snapshot after a settle; the gap rule absorbs any difference |
| R-3b3-8 | Manual price typed wrongly (units) | `/gi price set` accepts `12g 5s 3c` or raw copper and echoes the parsed copper; prices carry a date; `price clear` |

## 14. Reference addons (extend rather than rebuild; same request as before)

The user asked to be told what to reference. Names come from my training knowledge and may not exist on Forever; availability is yours to check. What I would look for:
1. **A bag/bank scanner** (for example the container module of Altoholic/DataStore, or Bagnon): how it enumerates bag indexes including any reagent bag, equipped slots, and bank events. Answers R-3b3-1, R-3b3-3 and the bank question.
2. **A loot-chat parser** (any addon that reads `CHAT_MSG_LOOT`, for example XLoot or a loot-history addon): the GlobalStrings it uses for item gains and roll results. Answers Q-10.
3. **A junk seller** (for example Scrap or a "sell grey items" addon) and Accountant Classic's repair path: which signal they use for sales and for repair cost. Answers Q-9.
4. **Auctionator** (already reviewed, `Reference_Auctionator.md`): its vendor-price cache is a design check for tier 1 and the unknown handling; no new files needed.
Provide the files in the same way as before (one or two at a time); I will extract only what the open questions need and record it in `Compatibility_Notes.md` as third-party, unverified until we measure it.

## 15. Exit criteria

**Automated:** all tests green (1,036 existing plus the new ones); invariants I-2..I-6 hold for replayed and random streams; each replay case yields the expected lots and conversions (E-32 ring added and head removed, E-25 materials created and item consumed, E-30 cold-cache sequence ending valued, vendor sale allocation sums exactly); cash isolation test byte-identical; M8-Store tolerance test passes; mutation set caught; no bare WoW global outside `Platform/`.

**Live (Session V):** no popup, no Lua error, no quarantine; `/gi ledger check` 0 copper; `/gi lots check` 0 quantity difference for every item id; every scripted source classified as in 2.2; unattributed share reported by value first and by count, each unattributed row explained in the report; unknown count visible and back to 0 except invalid ids; measured lot size, CPU and memory within NFR-3 or reported as a deviation with a proposal.

**Closure:** a 3b-3 closure recommendation in the 3b-2 format (metrics table, accepted risks). 3b-4 (Auction House deposit/buyout/bid, COD paid, postage, other sinks, AH item flows) needs your separate approval, as does every milestone gate above.

If you approve, the next step is a written decision (D-080) and then M1 only. Nothing is built before that.

## 16. Amendment D-081 (2026-10-19): acquisition and conversion accounting (supersedes parts of sections 4-9 as listed)
Approved by the user after the scope discussion. The item side answers: loot valuation, quest valuation, vendor conversion tracking, AH purchase/sale tracking, profit, no double counting. Inventory value is "acquired and not known disposed".
- **Withdrawn:** opening lots and item gap lots (Q-4), equipped gear and bag slots in the carried scope (Q-5), AC-16, invariant I-3 as a rule, R-3b3-3 (equip), cursor/in-flight/bank/buyback probing. `Lots:Check` is an optional diagnostic.
- **Lots are created by:** confirmed loot items, quest reward items, vendor/AH purchases, disenchant materials (conversion). **Consumed by:** vendor sale, AH sale (3b-4), trade, disenchant source item. All other additions and removals are ignored (at most counted in the trace).
- **Normal, not an anomaly:** converting items with no tracked lot. **Still anomalies:** sale at no sell price, sale price unknown, equal split, coerced vc.
- **Unchanged:** Q-1 scope, Q-2 evidence gate, Q-3 schema 2, Q-6 valuation, Q-7 value created, Q-8 allocation, Q-9 repair probe, Q-10 CHAT_MSG_LOOT evidence, Q-11 caps, Q-12 commands (`status|check|last|unknown|on|off|reset confirm`; `check` becomes the optional diagnostic), Q-13, Q-14, AC-14/15/17/18/19, I-2/I-4/I-5/I-6.
- **M2 evidence list (reduced):** bag index range; roll-awarded item arrival; repair-cost API; CHAT_MSG_LOOT lines; loot item timing; sell price and class of no-vendor items (enchanting mat, quest item); vendor buyback signal. Session E validation steps for equip/bank/cursor/in-flight are dropped.
- **Risk accepted by the user:** inventory value can run high (items destroyed, used or mailed away stay open as "not known disposed"); changes while monitoring is off are not tracked.
