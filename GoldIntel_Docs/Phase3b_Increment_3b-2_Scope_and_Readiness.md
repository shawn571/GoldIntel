# GoldIntel Phase 3b, increment 3b-2: Scope and Readiness Package

DOC VERSION: 1.0.0  |  DATE: 2026-10-18  |  AUTHOR: Claude (S-043)  |  STATUS: PROPOSED, for the user's review. **This is NOT authorization to implement.** No 3b-2 code exists or will be written until the user approves a scope in a new decision (D-051, D-067, D-077).

Evidence is cited as E-numbers (`Compatibility_Notes.md`). Precedence: Requirements > Decisions > Architecture; Contracts wins on data shapes. Already approved and NOT reopened here: D-065 (1.0 s window), D-067 (ledgers only), D-069 (schema 2, window mode, event allow-list), D-070 (AH sale split), D-071 (disenchant recorded), D-072 (validation rules: OTHER reported by value first, Diag lab off, 0 copper), D-073 (replay corpus).

## 1. Summary and recommendation

**What 3b-2 is:** the first increment that writes money records. It turns the 3b-1 signals (contexts, loot/quest/mail/trade/vendor/auction-post events) into **expectations**, reconciles every `P_MONEY` delta against them, and stores the result as a **cash ledger** with source, confidence, location stamp and activity stamp. It does not touch items (lots, bag diff, valuation are 3b-3).

**Readiness:** the signals are ready and every timing is measured inside the 1.0 s window (loot up to 0.509 s, trade 0.394, first loot money 0.378, mail 0.365, AH deposit after the post event 0.358, mail take 0.233 to 0.267, quest 0.041 before). The collector infrastructure behaves correctly in the real client (E-41..E-45, 3b-1 closed). Seven items need your decision first (section 12). The most important one: **Q-1, whether the AH, COD-out and postage sources join 3b-2 or stay for 3b-4.**

**Recommendation:** approve 3b-2 as the narrow scope in section 2 (option A of Q-1), built in four internal milestones (section 11) and validated with two live sessions (section 9). Expected new tests: about 280 (790 to about 1,070).

## 2. Scope

### 2.1 In scope for 3b-2

| # | Item |
|---|---|
| S1 | `Collect/Expectations.lua`: registry, exact and window matching, lifetime, priority |
| S2 | `Collect/Reconciler.lua`: `P_MONEY` delta to entries that sum to the delta, 1.0 s wait, `OTHER` remainder, gap handling, `Stats()` |
| S3 | `Collect/Sources.lua`: the only place that knows what each 3b-1 event means for money; subscribes to `P_*` events and registers expectations |
| S4 | `Ledger/Cash.lua`: `CashEntry` store (per character), totals, retention fold, `LEDGER_CASH` bus event |
| S5 | `Collect/Stamps.lua`: location stamp (`loc`, `locConf`), activity stamp (`act`, `actConf`), `creditable` flag. Pure functions, no engine |
| S6 | Schema 2 migration (1 to 2) with backup and a test on a REAL saved database |
| S7 | Commands: `/gi ledger status|last [n]|mark|check|off|on` and `/gi diag` (OTHER share by value first) |
| S8 | Tests, replay of the corpus through the Reconciler, mutation checks, live validation |

### 2.2 Money sources in 3b-2 (as built in 3b-1, evidence in brackets)

| Source | Signal (3b-1 as built) | Mode | Amount | `src`, `conf` | Place credit | Settle |
|---|---|---|---|---|---|---|
| Loot coin | `P_LOOT_MONEY` (one per coin slot, read at open) | exact | coin slot amount (E-18) | `loot`, high | yes (Creature/GameObject, D-044) | no |
| Quest reward | `P_QUEST_DONE` | exact | money argument (E-22) | `quest`, high | no | no |
| Mail money (player mail) | inbox diff after `MAIL_INBOX_UPDATE` (a mail left or its money went to 0) | exact | header money read BEFORE the take (E-29, E-39) | `mailMoney`, high | no | yes |
| COD received | same diff, COD-payment subject (E-40; English client only) | exact | header money, no fee (E-40) | `codIn`, high | no | yes |
| AH sale mail | same diff, mail with invoice (E-34) | exact, 3 components | price / cut / deposit refund from the invoice (51 / -2 / +100 = 149) | `ahSale` (settle), `ahCut` (expense), `ahDepositRefund` (not income), high | no | yes (price) |
| Vendor sale | `P_VENDOR` context (merchant open + linger) | window, sign + | delta | `vendor`, med | no | no |
| Vendor spend (buy or repair) | same context, sign - | window, sign - | delta | `purchase`, med (repair vs purchase is not told apart until 3b-3 bag diff) | no | no |
| Trade | `P_TRADE_OPEN/CLOSE` context | window, sign +/- | delta | `trade`, med | no | no |
| Unexplained | none | none | remainder after 1.0 s | `other`, low | no | no |

**Not in 3b-2 (Q-1, option A, as already planned in D-067 for 3b-4):** AH listing deposit (`P_AH_POSTED`, E-36), AH buyout and bid (no registered signal; AH context only), COD paid (inbox diff of a disappearing COD mail, E-39), postage (E-38). In 3b-2 these money changes become `other`, low, and are visible in `/gi diag`. They are verified (E-35..E-40) and are additive registrations in `Sources.lua`, so nothing built in 3b-2 has to change for them. **Option B** pulls them into 3b-2: about +60 tests, +1 live session step, no architecture change; the cost is a larger review. I recommend A to keep 3b-2 reviewable; say B if you want AH numbers sooner.

### 2.3 Out of scope (unchanged)

Lots, bag diff, item valuation, conversions (3b-3); source polish, retention final, profiling closure (3b-4); activity engine, sessions, GPH, heat bins, rankings, UI (Phases 4 to 7); disenchant (3b-3, D-071); automatic enabling of the collector (Q-2).

## 3. Starting point (what 3b-1 delivered and what it left)

Built and live-validated: adapters (`Loot` with frame-poll close, `Merchant`, `Quest`, `Trade`, `Mail` with `Snapshot()` and `Previous()`, `Auction`, `Items`, `Bags`, `Cast`), `Context` (loot, vendor, mail, trade, ah, quest; 1.0 s linger; `CONTEXT_CHANGED`), `Collector` (journal, quarantine, `/gi collect`), `Money` (`P_MONEY` with `gap`), `Where()`, `Player().key`.

Differences between the approved text (Contracts F2c) and what was built, to be corrected in the contract (Q-8): `P_LOOT_OPEN {sourceType}` plus separate `P_LOOT_MONEY {copper, source}` and `P_LOOT_ITEM {itemID, qty, source}` (F2c planned one event with a slot list and a `ctx`); `P_LOOT_CLOSE {by = frame|timeout|replaced}`; `P_MAIL_UPDATE {count}` plus readers `Mail.Snapshot/Previous` instead of `{ headers }`; `P_TRADE_CLOSE`, `P_AH_POSTED` added; `P_BAG_DIFF` and `P_CAST` are not built (3b-3 and 3b-4). 3b-2 consumes the as-built events. It needs one small additive Platform change: `Unit.LastCast(kind)` (read-only accessor for the activity stamp).

## 4. Architecture changes (proposed amendments to Architecture 19, none applied)

| ID | Change |
|---|---|
| AC-9 | **Ledger intervals.** The Reconciler runs only while collect is ON. The invariant (ledger sum equals money delta) holds per ON interval. `collect on` takes the baseline (`Money()`), `collect off` flushes pending deltas (after the 1.0 s wait or immediately as `other`, see 6.4) and closes the interval. Money changes while collect is OFF are not recorded. |
| AC-10 | **Source translators.** `Collect/Sources.lua` is the only module that maps events to expectations. The Reconciler and Expectations know nothing about WoW, mail, loot or trade. Adding AH/COD-out/postage later is adding rules to `Sources.lua`. |
| AC-11 | **Expectation lifetime follows contexts.** An exact expectation lives while its context is active (open + 1.0 s linger) and at least `ttl` (default 1.0 s). A window expectation is the context itself (no copper). |
| AC-12 | **Entries are immutable and sum-preserving.** Pruning folds raw entries into per-source totals (`ledger[charKey].totals`), so cumulative sums stay exact after raw entries are dropped. |
| AC-13 | **Gap entries.** A `P_MONEY` with `gap = true`, and the baseline difference at login, become `other` entries flagged `comp = 'gap'` and counted separately, never attributed. |

Module and load order (TOC): Platform, Core, Store, Collect (`Context`, `Collector`, `Expectations`, `Sources`, `Stamps`, `Reconciler`), Ledger (`Cash`), Future, Boot last. Module dependencies: `Sources` needs `Context` and `Expectations`; `Reconciler` needs `Expectations`, `Stamps`, `Cash`; `Collector` start/stop calls `Reconciler.Begin/End`. Platform boundary rule unchanged: no WoW globals outside `Platform/`.

## 5. Expectation model

```lua
Expectation = { id, src, mode = 'exact' | 'window', copper = number?, sign = 1 | -1,
                t0 = gt, ttl = number (>= 1.0), ctx = string?, comps = { {src, copper, comp, settle?}... }? }
```
- **exact:** copper known. `comps` splits one expectation into components that sum to `copper` (the AH sale mail). Matches only that exact total with the same sign.
- **window:** copper unknown. Backed by an active context (merchant, trade). Claims the remaining delta of its sign while the context is open or within 1.0 s after it closed.
- **Registration (Sources.lua):** `P_LOOT_MONEY` registers an exact `loot` expectation tied to the loot context; `P_QUEST_DONE` registers exact `quest` (ttl 1.0 s); `MAIL_INBOX_UPDATE` (via `Mail.Previous/Snapshot` diff) registers exact `mailMoney`/`codIn`/`ahSale` for each mail that left; `CONTEXT_CHANGED` for vendor and trade registers window expectations.
- **Lifetime:** consumed on match; expires at `t0 + ttl` or when its context's linger ends, whichever is later. An expired exact expectation is counted as `unmatched` (a diagnostic, never an entry: no money moved).
- **Priority (D-065):** trade, mail, vendor, quest, loot, AH.

## 6. Reconciler design

### 6.1 Stages (Architecture 19, four stages)
(1) observation: `P_MONEY(copper, gt, gap?)`; (2) detection: expectations from Sources; (3) attribution: source, confidence, stamps; (4) reconciliation: entries sum to the delta, remainder `other`.

### 6.2 Algorithm per `P_MONEY` delta `d` (non-zero; zero deltas never create an entry)
1. If `gap`: write one `other` entry (`comp = 'gap'`, conf low), done.
2. Try to explain `d` now:
   a. **Exact pass:** candidate exact expectations with the sign of `d`, in priority order; find the first combination (size 1 to 3, bounded) whose copper sums to `d` exactly. Matched expectations are consumed; each component becomes an entry (conf high).
   b. **Window pass** on the remainder `r` (if `r ~= 0`): the highest-priority active window context with sign agreeing takes `r` (conf med; conf low if two window contexts of different sources were both active).
   c. If `r` is still non-zero it is **pending**.
3. A pending remainder waits up to **1.0 s** (D-065) for a late expectation or context, re-running the passes on every new registration. At 1.0 s it becomes `other`, low.
4. Every entry gets `t`, `charKey`, `act/actConf`, `loc/locConf`, `creditable`, `settle`, `ctx`, `ref`, then `Cash.Add` and `LEDGER_CASH`.
5. `Stats()`: total entries and value, `other` share by entries AND by value (value first, D-072), largest `other`, gap count and value, unmatched expectation count, low-confidence share.

### 6.3 Invariants the design guarantees
Sum of entries in an interval equals the sum of non-zero deltas (the only copper source is `P_MONEY`; expectations never create copper). One expectation is consumed at most once. A delta is never split across two expectations unless their exact sum equals it.

### 6.4 Decisions inside the design (Q-3, Q-4)
- **Late money.** Matching runs at once and re-runs for up to 1.0 s; no measured case has money arriving before its signal, so a delay only ever applies to `other`.
- **Split deltas.** Partial matching of one exact expectation across two deltas is NOT supported. Both deltas become `other` and the expectation expires as `unmatched`. The invariant holds; this changes the edge-case list in Architecture 6 (proposed amendment).
- **`collect off` with pending deltas:** pending remainders become `other` immediately (the interval ends).
- **Same copper from two sources inside one window:** both exact expectations are consumed in priority order only if their sum equals the delta; a single delta equal to one of them takes the higher-priority one.

## 7. Cash ledger and schema 2

- **Entry (compact):** `id, t, c (signed copper), src, conf, act, actConf, loc?, locConf, cr (creditable), st (settle), ctx?, ref?, comp?`. Estimated 90 to 130 bytes serialized; MEASURED at the end of 3b-2 (D-072, P3B-8).
- **Storage:** `GoldIntelDB.ledger[charKey] = { nextId, cash = {...}, totals = { [src] = { n, copper } } }`, `GoldIntelCharDB = { schema = 2, lastMoney, ... }`. `lastMoney` is written on every entry and at `collect off`/logout; it is the baseline for the next ON interval and for the login gap check.
- **Retention (interim, final from measurement):** raw cap 5,000 entries per character; the oldest 500 are folded into `totals` when the cap is exceeded (AC-12). Phase 4 rollups replace raw entries later.
- **Migration 1 to 2:** runs on a copy (existing Store rules), creates empty `ledger`, keeps `compat` byte-identical, maps `unknown` to `other`, stores `GoldIntelDB.migrationBackup = { from = 1, t, data }` (a copy of the schema 1 keys; they are small), and is tested on a REAL file (the user's own `GoldIntel.lua` from E-43 is the schema 1 fixture, never edited).
- **Crash risk (new, R-3b2-1):** the client writes SavedVariables only at logout or `/reload`. A client crash loses the whole session's entries. At the next login `Money()` minus the stored `lastMoney` is recorded as one `other`/`gap` entry flagged `comp = 'gap'`, so the cumulative sum stays correct while the detail is lost. Nothing in an addon can change this.

## 8. Stamps

- **Location:** last good `Where()` from the 0.5 s tick, no older than 5 s (`locConf = 'fresh'`), older `'stale'`, none `'none'`; instances carry the instance id and no coordinates (E-27). Stale and none earn no credit.
- **Activity (pure function of the source):** creature loot GRIND (med), game-object loot GATHER or FISH using `Unit.LastCast(kind)` within 30 s (med; high only with a verified spell id, otherwise OTHER), vendor VENDOR, quest QUEST, mail MAIL, trade TRADE, otherwise OTHER (low). No engine, no idle, no override (Phase 4).
- **`creditable`:** true only for creature or game-object loot coin (D-044, D-064); never for quest, mail, trade, vendor.

## 9. Validation plan

### 9.1 Automated (about 280 new tests, estimate)

| Area | Tests |
|---|---|
| Expectations (exact, window, ttl, priority, combos) | ~45 |
| Reconciler (algorithm, pending, gap, collect off, stats, mutation set) | ~90 |
| Sources (each source, inbox diff, COD, sale split) | ~50 |
| Cash and schema 2 (store, retention fold, migration, backup, round trip) | ~45 |
| Stamps and commands | ~30 |
| Replay corpus through the Reconciler (E-22 quest, E-28 mail, E-31 trade incl. cancelled, E-33 vendor, E-34 sale split 51/-2/+100, E-39, E-40, E-42 loot, E-45) | ~25 |
| Property tests (random streams: sum equals delta, each expectation once, split exactness) | ~10 |

Existing 790 tests must still pass. Mutation checks on Reconciler and Expectations (sign error, consume twice, skip priority, drop remainder, window over-claim, off-by-one on the 1.0 s window, gap ignored).

### 9.2 Live (two sessions, about 15 minutes each, collect ON, Diag lab OFF)

Session 1: `/gi ledger mark`; loot with coin (kill several, include one slow loot and one walk-away with coin left), vendor sale and a purchase, quest turn-in, take one money mail, one trade (gold given) and one trade (item for gold); `/gi ledger check` (compares the live `GetMoney` change since the mark with the sum of entries: **must be 0 copper**); `/gi ledger last 30`; `/gi diag`; `/reload` and re-check the saved ledger and `lastMoney`. Session 2: repeat with **auto-loot ON** (the loot frame may not show; the legacy close rule applies, never validated live), a gap check (log out and in), the AH items that stay `other` (post one auction, bid or buy once) so their `other` share is seen, and, if a sale mail with an invoice exists, take it to check the 3-component split live. Reported: entries by source, `other` share by value (headline) and by entries, largest `other`, gap entries, unmatched expectations, per-event CPU.

## 10. Rollback strategy

1. **Package rollback:** keep the 3b-1 package as `GoldIntel_3b1_AddOns.zip`; install it over 3b-2. Same procedure as the 3b-0 rollback used in 3b-1.
2. **Data safety:** the older addon sees schema 2 data it does not know and runs in the existing read-only mode for newer data (Store rule), without modifying it. The `migrationBackup` copy restores schema 1 (`/gi ledger restore` is NOT built; the file copy is kept for manual recovery and removed after three clean sessions only by your decision).
3. **Kill switches:** `/gi ledger off` stops the Reconciler (collector keeps counting), `/gi collect off` ends the interval. Nothing runs at login: collect and ledger are OFF after every login and `/reload` (Q-2).
4. **Validation failure policy:** any non-zero copper difference, popup, Lua error or quarantined event stops the session; the finding is recorded as E-number evidence before any fix.

## 11. Build milestones inside 3b-2 (reported in one review, or gated if you prefer)

- **M1** Expectations and Reconciler as pure modules with the property and mutation tests (no WoW, no storage).
- **M2** Sources and Stamps with the replay corpus.
- **M3** Cash store, retention fold, schema 2 migration, commands.
- **M4** Live session 1 and 2, closure recommendation.

## 12. Decisions requested

| ID | Question | My recommendation |
|---|---|---|
| Q-1 | Source scope: (A) the list in 2.2 and AH deposit/buy, COD-out and postage stay `other` until 3b-4; (B) pull them into 3b-2 | A |
| Q-2 | Collect and ledger stay manual (`/gi collect on`, OFF after every login and `/reload`) in 3b-2; automatic enabling is decided at 3b-4 closure | Yes |
| Q-3 | Window-mode confidence med (low when two window sources competed), exact matches high, `other` low; 1.0 s wait applies to unexplained remainders only | Yes |
| Q-4 | No partial matching of one expectation across two deltas (both become `other`, expectation `unmatched`); amend the Architecture 6 edge-case list | Yes |
| Q-5 | Negative vendor deltas are tagged `purchase` (med) until the 3b-3 bag diff can tell repair from purchase | Yes |
| Q-6 | Interim retention: raw cap 5,000 entries per character, oldest 500 folded into `totals`; final value from the measured entry size (D-072) | Yes |
| Q-7 | Schema 2 migration with `migrationBackup`, real-file fixture (your E-43 file) and read-only fallback for an older addon | Yes |
| Q-8 | Contract 1.8 (additive): as-built `P_*` events replace the F2c text; `LEDGER_CASH` payload, `Reconciler:Stats()`, `Unit.LastCast`, schema 2 specifics | Yes |
| Q-9 | Live sessions as in 9.2 including one auto-loot session; the AH sale mail check is optional (needs a sold auction) | Yes |
| Q-10 | Approve the architecture amendments AC-9 to AC-13 as one package (text only in Architecture 19) | Yes |

## 13. Risks (new, proposed IDs)

| ID | Risk | Mitigation |
|---|---|---|
| R-3b2-1 | Client crash loses the whole session's ledger (SavedVariables written only at logout or reload) | Gap entry at next login keeps the cumulative sum; documented; cannot be fixed from an addon |
| R-3b2-2 | Auto-loot may not show the loot frame; the legacy close rule has never run live | Session 2 covers it; legacy rule is correct for auto-loot by construction (all clears come at once) |
| R-3b2-3 | Two sources with equal copper in one window | Priority and sum rules (6.4); property test |
| R-3b2-4 | COD-payment mail detection uses the English subject (E-40) | Other locales fall back to `mailMoney` (still settle); locale list left to Phase 8 |
| R-3b2-5 | Mail diff misreads a mail that was deleted, returned or expired as a money take | The expectation simply expires `unmatched` (no entry); counted in Stats |
| R-3b2-6 | Entry size larger than estimated | Measured at the end of 3b-2; cap and fold are configurable |
| R-3b2-7 | `TRADE_MONEY_CHANGED` unreliable (0 of 2 when giving money, E-45) | Not used; trade is window mode |
| R-3b2-8 | Quest reward choice not visible | Quest copper is exact from the event; item side is 3b-3 |

Existing risks unchanged: R-03 (secret values), R-23, R-27..R-30; the optional character identity stamp stays a later hedge (not a blocker, 2026-10-18).

## 14. Exit criteria

**Automated:** all tests green (790 existing plus the new ones); invariant 1 holds for replayed and random streams; each replay case yields the expected entries (including E-34 51 / -2 / +100, cancelled trade, duplicate closes, loot lag 0.509 s, COD received +100); migration 1 to 2 on the real file with `compat` unchanged; mutation set caught; platform boundary and allow-list tests unchanged.

**Live:** no popup, no Lua error, no quarantine; `/gi ledger check` shows **0 copper difference** in both sessions; every scripted verified source is classified as in 2.2; every `other` is explained in the report (AH deposit/buy, postage, COD-out under option A); the `other` share by value is reported first and compared with the 2% starting target; ledger survives `/reload`; auto-loot session passes; CPU per event reported against the 3b-1 baseline.

**Closure:** a 3b-2 closure recommendation in the 3b-1 format. 3b-3 needs your separate approval.

If you approve, the next step is a written decision (D-077) and then M1 only. Nothing is built before that.
