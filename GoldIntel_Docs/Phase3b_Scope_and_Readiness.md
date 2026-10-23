# GoldIntel Phase 3b Scope and Readiness Assessment

DOC VERSION: 1.0.0  |  DATE: 2026-10-18  |  AUTHOR: Claude (S-038)  |  STATUS: PROPOSED, for the user's review. **This is NOT authorization to implement.** No Phase 3b code exists or will be written until the user approves a scope in a new decision (D-051, D-042, D-066).

Evidence is cited as E-numbers (`Compatibility_Notes.md`). Documents that win in a conflict: Requirements > Decisions > Architecture; Contracts wins on data shapes.

## 1. Summary

**Recommendation:** approve a deliberately narrow Phase 3b: **the cash ledger and the asset ledger only** (TODO "Phase 3: Collect"), built in four gated increments, each ending with automated tests and one short live validation session. Activity engine, sessions, metrics, pricing, heat bins and UI stay in Phases 4 to 7.

**Readiness:** the SIGNALS are ready (every source the ledgers need has a verified signal and timing). The PROCESS is not yet ready: five items need your decision first (section 8). One real coverage gap was found by this assessment (Auction House listing, COD and outgoing mail were never run in the lab, section 7, finding F-1). It does not break the ledger invariant, but it would leave those sources as `OTHER`.

## 2. Proposed scope

### 2.1 In scope for Phase 3b

| # | Item | Requirement |
|---|---|---|
| S1 | Platform adapters for the verified signals (loot, merchant, quest, mail, trade, item data, bags) | FR-PLT-1..3 |
| S2 | Context state: which window is open (loot, merchant, quest, mail, trade) and for how long | FR-LED-1 |
| S3 | Expectations and Reconciler: every `PLAYER_MONEY` delta becomes cash entries that sum to the delta | FR-LED-1, FR-LED-5 |
| S4 | Cash ledger (`CashEntry`) with source, confidence, location stamp, settlement flag | FR-LED-1, FR-LED-4 |
| S5 | Lots (asset ledger): free and purchased lots, FIFO conversions (vendor sale, consume, mail) | FR-LED-2, FR-LED-3 |
| S6 | Valuation tiers 1 and 2 only: vendor floor and manual prices; `unknown` and `pendingInfo` flags (D-045, D-046) | FR-AH-1 (partial) |
| S7 | Source-derived activity tag (a pure function source to `act` + `actConf`; no engine, no idle, no override) | FR-SES-2 (stamp only) |
| S8 | Position stamp (`loc`, `locConf`) from the last good sample; location credit eligibility flag (D-044, D-064); NO heat bins | FR-HEA (stamp only) |
| S9 | Text commands for checking: `/gi ledger`, `/gi lots`, `/gi diag` low-confidence share, `/gi collect on|off` | FR-LED-5 |
| S10 | Storage: schema 2, per-character ledger, retention and pruning of raw entries | DR-1..4 |

### 2.2 Explicitly out of scope (stays where the TODO already puts it)

- ActivityEngine rules, idle detection, manual override, `/gi pause|afk` behaviour: Phase 4 (D-049, D-055).
- Sessions, segments, Cash/Wealth/Net GPH, explain data: Phase 4.
- Rankings and aggregates: Phase 5. Pricing providers beyond tier 2, AH scanning, AHMath, disenchant revaluation (D-062), Current Market Value and Account Best views (D-063): Phase 6 and later.
- Heat bins, smoothing, overlay, hotspot list, travel model (D-052..D-061): Phase 7.
- Any graphical UI (D-053). Only text commands.
- Combat log (never, D-030), XP kill proxy (dropped, D-066).

Note on wording: in the earlier hand-offs I listed "activity/session engine, heat bins, pricing provider, UI" among the things not yet approved. This proposal narrows Phase 3b so those are NOT part of it. Please confirm (P3B-1).

### 2.3 Increments (each needs your approval to start and to close)

| Inc. | Content | Live session |
|---|---|---|
| 3b-0 | Housekeeping before any collector: D-027 patch if approved, Platform event allow-list, contract and schema 2 amendments, evidence-replay test harness, profiling plan | none |
| 3b-1 | Platform adapters, Context, event registration of verified events, delivery counters, `/gi collect on|off`. No ledger yet | Register all collector events together once; check no popup, counts match |
| 3b-2 | Expectations, Reconciler, cash ledger, location/activity stamps; money sources: loot coin, quest, mail, vendor, trade, `OTHER` | Scripted play: loot, vendor sale, quest, mail take, trade; ledger sum equals `GetMoney` delta exactly |
| 3b-3 | Lots, bag diff, valuation tiers 1 and 2, conversions, item data lifecycle | Scripted: loot items, sell, buy, fresh-login item cache; unknown count visible |
| 3b-4 | Source classification polish (mail fingerprint and AH split, gather/fish/skin, disenchant recorded not revalued), retention, profiling, closure review | Profiling session (PX-7) plus one free-play hour; low-confidence share reported |

User time estimate: about 10 to 15 minutes per live session, five sessions. Tests and code are mine.

## 3. Architecture changes needed (none applied yet)

| ID | Change | Where |
|---|---|---|
| AC-1 | Event table marks the verified collector events; Platform registers only an allow-list of verified events, the Phase 2 test "exactly 12 events" becomes "exactly this list" | Architecture 5.1, `Platform/Events.lua`, tests |
| AC-2 | New Platform adapters: `Loot`, `Merchant`, `Quest`, `Mail`, `Trade`, `Items`, `Bags`. WoW globals stay inside `Platform/` (invariant 5) | Architecture 4, 12 |
| AC-3 | New directories `Collect/` (Context, Collector, Expectations, Reconciler) and `Ledger/` (Lots, Valuation). Load order after Store, before Future, Boot last | Architecture 12 |
| AC-4 | Expectation match modes: **exact** (copper known: loot coin, quest, mail) and **window** (copper unknown: vendor sale, trade). D-065 states exact copper; this adds window mode, with the same 1.0 s and priority rules | Architecture 6, D-065 |
| AC-5 | AH sale mail splits one money delta into components using the invoice (E-34): sale price, house cut, deposit refund. Components sum to the delta (invariant 1) | Architecture 6, 7.1 |
| AC-6 | Section 8 wording: bin field `c` is "value credited" (gold plus valued free items). Applied now because D-043/D-044 already require it | Architecture 8 |
| AC-7 | Section 7.4: GRIND rule uses creature loot source (G1) and combat state (G3); G2 removed (D-066) | Architecture 7.4 |
| AC-8 | Pending state (open expectations, open loot context) is not persisted across `/reload`; anything unmatched becomes `OTHER` with a diagnostic | Architecture 6, 18 |

## 4. Contract changes needed (none applied yet)

- `CashEntry`: add `locConf`, `actConf`, `ctx` (context key such as loot window id), `ref` (evidence or mail fingerprint), `comp` (component of a split delta). `src` gains `deposit`, `cut`, `repair`, `buyback`, `other`.
- `Lot`: add `flags` (`unknown`, `bound`, `pendingInfo`, `noVendor`), `locConf`, `ctx`.
- `Expectation`: `{ id, src, mode = 'exact'|'window', copper?, sign, t0, ttl >= 1.0, ctx }`.
- Bus: add `CONTEXT_CHANGED { kind, open }`. `LEDGER_CASH` and `LEDGER_LOT` already declared.
- SavedVariables **schema 2**: `GoldIntelDB.ledger = { [charKey] = { cash = {...}, nextId } }`, `GoldIntelDB.lots`, migration 1 to 2 with a real-database fixture test (the existing Phase 1 fixture is reused). `GoldIntelCharDB.lastMoney` is already declared and becomes the cross-session baseline.
- Contract tests added for each (Contracts F9).

## 5. Collector design (per source, from the verified evidence)

Common rules: handlers only enqueue (Architecture 5.3); the 0.25 s drain processes the queue; close handlers are idempotent; secret values are never compared (R-03); money amounts come only from `PLAYER_MONEY` deltas, never from chat; classification hints never create copper.

| Source | Opens context | Expectation | Amount source | Lot effect | Place credit eligible? | Evidence |
|---|---|---|---|---|---|---|
| Loot coin | `LOOT_OPENED`; slot data read at open | exact | coin slot amount (`GetLootSourceInfo` second value, E-18); key (source GUID, window time) | none | Yes: Creature and GameObject sources (D-044) | E-18..E-20, E-24 |
| Loot item (kill, node, fish, skin) | same | none (no copper) | slots from the window, confirmed by bag diff after the last `BAG_UPDATE_DELAYED` | free lot at acquisition value, once | Yes (same rule) | E-19, E-24, E-32 |
| Disenchant | `LOOT_OPENED` with source GUID type `Item` | none | materials from the window; the destroyed item from the bag diff | consume the item, add materials as free lots, flag `conversion`; NO revaluation (D-062 Proposed) | No until D-062 is approved | E-25, E-26 |
| Vendor sale or buy or repair | `MERCHANT_SHOW`, closed by `MERCHANT_CLOSED` (idempotent) | window, by sign | `PLAYER_MONEY` delta; positive = sale, negative = purchase or repair | sale: FIFO conversion; purchase: lot at cost | No | E-21, E-33 |
| Quest turn-in | `QUEST_TURNED_IN` (id, xp, money) | exact | money argument equals the delta (E-22) | reward items by bag diff as free lots; quest items consumed are not sales | No (D-064) | E-22, E-32 |
| Mail take | `MAIL_INBOX_UPDATE`, mailbox state by `MailFrame:IsShown()` polling | exact from header money (read while open, before the take) | header money; sale mails split by invoice into price, cut, deposit refund | mail items by bag diff; free lot only for non-purchase origin | No; `settle = true` for AH proceeds (D-064) | E-28, E-29, E-34 |
| Trade | `TRADE_SHOW`, `TRADE_CLOSED` (twice per close); context kept at least 1.0 s after the close | window, by sign | `PLAYER_MONEY` delta | trade items not read (item side unprobed): bag diff only | No | E-31 |
| Unexplained | none | none | remainder after 1.0 s | none | No | D-065 |

Timing fixed by evidence: trade money 0.394 s after close, mail 0.365 s after the update, loot up to 0.509 s, quest event 0.041 s before money, bag event 0.15 s before and 0.289 s after money. All inside the 1.0 s window.

Location stamp: the last good `C_Map` sample no older than 5 s (setting); an older stamp gets `locConf = 'stale'` and earns no credit (planning package 5.1). Instances: no position by design (E-27); the entry carries the instance id and no coordinates.

Activity stamp (S7): Creature loot to `GRIND` (actConf medium), GameObject loot to `GATHER`/`FISH` using the verified player cast spell ids (2366, 2575, 8617, 7731; data, not code), merchant `VENDOR`, quest `QUEST`, mail `MAIL`, trade `TRADE`, otherwise `OTHER`.

## 6. Evidence reuse for tests

The saved lab runs in `evidence/` are real event sequences with timings. A converter (3b-0) turns each into a normalized event stream, so the tests replay what the client actually did: loot lag 0.509 s, trade E-31 rounds including the cancelled zero-delta trade, mail E-28 and E-34, quest E-32. Tests assert the resulting ledger entries.

## 7. Risks and findings

### 7.1 Findings from this assessment

| ID | Finding | Impact | Proposed handling |
|---|---|---|---|
| F-1 | **Auction House events, listing deposits, bids and buyouts, cancel penalty, COD pay and receive, and sending mail (postage, money sent) were never run in the lab.** Only sale proceeds by mail are verified (E-34) | Those money changes become `OTHER` low confidence. Ledger sum stays correct. FR-SRC-5 and FR-SRC-7 would be only partly met, and AH profit is your main interest | P3B-3: a short verification addendum (about 3 lab sessions) before 3b-4 |
| F-2 | Loot coin amount is available but the window is a hint (principle 1). Vendor and trade amounts are not in any signal | Exact-copper matching cannot be universal | AC-4 window mode |
| F-3 | `MAIL_CLOSED` is not delivered (E-34); `MAIL_SHOW` was never verified | Mailbox open state needs polling | `MailFrame:IsShown()` on the existing 0.5 s tick |
| F-4 | The AH sale mail pays price + deposit - cut (51 + 100 - 2 = 149); the deposit was paid at listing | Treating 149 as income would overstate | AC-5 split; deposit refund is not income |
| F-5 | `UNIT_SPELLCAST_SUCCEEDED` fires for every unit; other units' casts are secret in combat (E-23) | Highest-volume handler; CPU risk | First line checks the unit token without touching payloads; try unit-filtered registration in 3b-1, else early return; measure in 3b-4 |
| F-6 | D-027 and D-028 are still Proposed (X-2); the GoldIntelDiag lab registers the same events | Process gate; double registration confuses live results | P3B-4; disable GoldIntelDiag during live validation sessions |

### 7.2 Risk register additions (proposed IDs)

| ID | Risk | Mitigation |
|---|---|---|
| R-31 | Registering all collector events together triggers the old popup (only single events were tested) | Staged enable in 3b-1 with `/gi collect off`; one live check before 3b-2 |
| R-32 | Ledger growth against the 2 MB budget (Architecture 13) | Compact entries, retention default to be set from a measured size per entry in 3b-2, raw entries pruned until Phase 4 rollups exist (P3B-8) |
| R-33 | Mail identity: index is unstable, two identical mails | Fingerprint (sender, subject, money, first item) plus count; ambiguity degrades confidence, not the sum |
| R-34 | Loot window items left behind, full bags, stack merges | Items count only when the bag diff confirms them; diff aggregated per item id |
| R-35 | Two sources with the same copper inside one 1.0 s window | Priority order (D-065); both consumed in order; leftovers `OTHER` |
| R-36 | `/reload` or crash mid-window loses pending state | AC-8; `OTHER` with a diagnostic; baseline from `lastMoney` so the sum still holds |
| R-37 | Item data late or secret, silent zero value | `pendingInfo` window and visible `unknown` count (D-046, R-27) |

Existing risks unchanged: R-01 (restricted events: now mitigated by evidence), R-03 (secret values), R-23, R-27..R-30.

## 8. Dependencies and gates (planning package section 13, status now)

| # | Gate | Status |
|---|---|---|
| 1 | User approves Phase 3b explicitly (new decision) | OPEN: this document |
| 2 | OI-8 restriction model; no UNVERIFIED matrix row a collector depends on | MET by evidence for the P3B scope; the AH/COD/mail-send sources are the exception (F-1). OI-8 closing wording needs your approval |
| 3 | X-2: D-027 (legacy adapter removal) and D-028 (interface policy) | OPEN. Recommendation: approve D-027 as the first small patch in 3b-0; D-028 as a release checklist item (no code) |
| 4 | PX-1..PX-8 triaged | PX-5 is gate 3; PX-7 (profiling) scheduled in 3b-4; PX-1 (subzone text) matters only when subzone keys are used (A-4, Phase 5); PX-6 confirmed by D-056; others are not blockers |
| 5 | D-043..D-050 accepted | MET (planning package A.1). D-062 and D-063 details stay Proposed and are not needed in 3b (record only) |
| 6 | CPU and memory measurement plan agreed | OPEN. Proposal: `C_AddOnProfiler` average ms per frame and memory growth per hour, before and after enabling collectors, targets from Architecture 13 (0.5 ms, 2 MB per hour); plus a fake-clock handler cost test |

Also needed before 3b-0: approval of the Architecture and Contract changes in sections 3 and 4 (one package), and the reconciliation of OI-5 only if you want older documents merged (not a blocker).

## 9. Exit criteria

### 9.1 Automated (all must pass)

1. Invariant 1: for random and replayed event streams the sum of cash entries equals the money delta, exactly, in every window.
2. Invariant 2: a lot is created once and consumed once; selling is a conversion, not value created.
3. Invariants 4 and 6 hold for the stamps (only location-eligible sources are marked creditable; settlement entries are flagged).
4. Evidence replay: every case in section 6 produces the expected entries, including loot lag 0.509 s, cancelled trade (zero delta ignored), duplicate `TRADE_CLOSED`/`MERCHANT_CLOSED`/`LOOT_SLOT_CLEARED`, AH sale split 51/-2/+100, quest with item.
5. Edge cases from Architecture 6 (zero delta, split deltas, expiry, simultaneous sources, a delta that waits the full second).
6. Platform boundary test, registered-event allow-list test, schema migration 1 to 2 on the real Phase 1 database fixture, contract tests.
7. Mutation checks on the Reconciler and Lots (the earlier phases used 7).
8. Existing 551 tests still pass.

### 9.2 Live (per increment, and at closure)

1. No popup, no Lua error, every collector event `IsEventRegistered` true and delivered in the scripted session.
2. Ledger sum equals the real `GetMoney` change over the scripted session: **0 copper discrepancy**.
3. Every entry from the scripted verified sources is correctly classified; any `OTHER` is explained in the report.
4. Free-play hour: `OTHER` share reported by `/gi diag`; target proposed at 2% of entries or less for verified sources (a proposal, you set it).
5. Profiling (PX-7) within Architecture 13 targets, or the miss is reported with a plan.
6. `unknown` item count visible; a fresh-login test shows `pendingInfo` resolving through `GET_ITEM_INFO_RECEIVED`.

### 9.3 Closure

A Phase 3b Closure Recommendation in the same format as the Phase 2 and Phase 3a ones, for your decision. Phase 4 starts only after your explicit approval.

## 10. Decisions requested (none are made until you answer)

| ID | Question | My recommendation |
|---|---|---|
| P3B-1 | Is Phase 3b the narrow scope in 2.1 and 2.2 (ledgers only; activity engine, sessions, metrics, pricing, heat and UI stay in Phases 4 to 7)? | Yes |
| P3B-2 | Approve the four-increment plan with a gate after each (3b-0 to 3b-4 as in 2.3)? | Yes |
| P3B-3 | AH listing, bids, cancel penalty, COD and outgoing mail: (A) verify first with a short lab addendum, about 3 sessions, before 3b-4; (B) accept `OTHER` for now and verify in Phase 6; (C) never | A |
| P3B-4 | D-027: remove legacy adapters as the first patch of 3b-0? D-028: treat as release checklist? | Yes to both |
| P3B-5 | Approve the Architecture and Contract changes in sections 3 and 4, including schema 2 and window-mode expectations (AC-4)? | Yes, as one package |
| P3B-6 | AH sale mail split into price, cut and deposit refund (AC-5)? | Yes |
| P3B-7 | Disenchant in 3b is recorded (consume plus new lots) with no revaluation; D-062 stays Proposed until Phase 6? | Yes |
| P3B-8 | Raw ledger retention: set from the measured entry size at the end of 3b-2, within the 2 MB budget? | Yes |
| P3B-9 | Disable GoldIntelDiag during Phase 3b live validation sessions? | Yes |
| P3B-10 | Profiling plan in gate 6 and the proposed 2% `OTHER` target? | Yes, adjust the number if you prefer |

If you approve, the next step is a written decision (D-067 and following) and then 3b-0 only. Nothing is built before that.
