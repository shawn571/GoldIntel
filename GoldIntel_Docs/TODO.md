# GoldIntel TODO

DOC VERSION: 1.4.1  |  UPDATED: 2026-11-14 (session S-070)

```
CURRENT PHASE:            Phase 3b: 3b-0..3b-3 CLOSED (3b-3 by D-101, 2026-11-08); 3b-4 NOT started (priorities: later decision). Phase 4: P4-M1 MERGED (PR #7, modules not loaded); P4-M2 built as 0.6.0-passive (PR #9), NOT approved, not merged, not installed; P4-M3 NOT started. Build on main: 0.5.6-passive (installed on all characters).
IMPLEMENTATION APPROVED:  Phases 1 and 2, Phase 3a (closed), Phase 3b scope D-067 (3b-0..3b-3 closed incl. M4 by D-097; 3b-4 NOT started); 0.5.6 (D-100, merged by D-109); Phase 4 P4-M1 (D-099, merged by D-109) and P4-M2 BUILD ONLY (D-102; PR #9 not approved). Docs-only merges as in D-105 and D-108; approved merges with the REST command (D-106). Everything else is NOT approved.
PHASE 0:                  COMPLETE
OPEN BLOCKERS:            None. Waiting on the user: review and approval of the 0.6.0 build (PR #9). Accountant cross-check done and price plan placed in Phase 6 as plan only (D-111). OI-14, OI-15 decided (D-088, D-089); OI-16 deferred (repo private); OI-8 closing wording, OI-5, OI-13, OI-17 unchanged.
```
Note (2026-11-08, S-065): D-099..D-102 are recorded on the PR branches (#7, #8, #9) and reach main with those merges.

Note (2026-11-03, S-057): the per-phase checklists for Phases 1 to 3a below are kept as a historical record. Some boxes stay unticked for work that was later finished or waived; the authoritative status is the closure decisions (D-056 Phase 2, D-066 Phase 3a, D-076 3b-1, D-079 3b-2) and the CURRENT PHASE block above.

Rules: work only on the current phase. Do not start the next phase without explicit approval. Mark tasks `[x]` with date and session when done. Each phase has an exit test; a phase is complete only when its exit test passes.

---

## Phase 0: Documentation baseline: COMPLETE (S-001, 2026-10-09)

- [x] Project_Bible.md
- [x] Requirements_v1.md
- [x] Decisions.md
- [x] Changelog.md
- [x] TODO.md
- [x] Session_Handoff.md
- [x] Architecture.md
- [x] Contracts.md

## Phase 1: Platform and Probe (REQ: FR-PLT-1, FR-PLT-2, FR-PLT-3)

- [x] 1.1 GoldIntel.toc and load order (S-002; revised in S-003: Interface 16001, forward slashes, minimal TOC, D-023/D-024). embeds.xml DEFERRED to Phase 2: no libraries are bundled in Phase 1 (D-021, D-022).
- [x] 1.2 `Platform/Platform.lua` capability registry and `Platform.Has` (S-002; also diagnostics, ready/fatal lifecycle)
- [x] 1.3 `Platform/Probe.lua` and `/gi probe` output formatted for pasting (S-002; temporary /gi handler, remove in Phase 2)
- [x] 1.4 Platform adapters: Events, Clock, Scheduler, Unit, Map, Money (S-002)
- [x] 1.5 Static test: no WoW globals outside `Platform/` (S-002; stricter: none even inside Platform/ except through P.env; also Lua 5.1 lint)
- Exit test (three parts):
  - [x] Automated, fake client: full TOC load without errors or leaked globals; `/gi probe` prints the capability table; a money change produces a normalized `P_MONEY`; one-hour soak with no diagnostics and no memory growth (Tests/test_integration.lua).
  - [ ] **PENDING, needs the user:** load in the real Forever beta client with no Lua errors; run `/gi probe`; confirm a gold change prints `[evt] P_MONEY` after `/gi debug on`.
  - [ ] **PENDING, needs the user:** paste the `/gi probe` output (answers OI-1) so the interface number and adapters can be finalized.
- **Real-client test #3 (2026-10-10, user report plus SavedVariables evidence): PASSED for the formal exit test.**
  - [x] Zip extracted; GoldIntel, GIMin, GoldIntelDiag loaded; `operational: yes`, `diag=0` (E-02, E-08).
  - [x] No Lua error / no popup (reported; X1 asks for explicit confirmation).
  - [x] `/gi probe` report written and delivered (answers OI-1, E-01).
  - [x] Money: vendor sale = positive `P_MONEY`, buyback = negative (reported, E-12).
  - [x] `/gidiag all` transcript delivered (E-04 to E-11).
  - [ ] GIMin `/gimin` output not delivered (no longer needed: forward-slash TOC proven by GoldIntel loading).
- **Phase 1 exceptions (non-blocking for Phase 2; see review section 8):**
  - [ ] E1 Registration verification in `Events.Bind` via `IsEventRegistered` (small patch + tests). Hard gate for Phase 3.
  - [ ] E2 Live observation of `P_ZONE`, `P_TICK`, `P_LEVEL`, `P_PROFS`, `P_COMBAT` and of `Player()` / `Where()` / professions. Diagnostics-only extension of GoldIntelDiag `run`, or a manual `/gi debug on` run.
  - [ ] E3 Remove dead legacy adapters (decision D-027).
  - [x] E4 Contracts.md caught up with the code (Contracts 1.2, S-005).
  - [ ] E5 TOC interface policy (D-028, OI-10).
  - [ ] E6 Unit/Map/Money behavior in combat, an instance, with secret values (during E2).
  - [ ] E7 Soak and CPU measurement with `C_AddOnProfiler` (Phase 2 or 9).
- **Conditions before approving Phase 2 (user):**
  - [ ] X1 Confirm: no popup and no Lua error in the latest session.
  - [ ] X2 Confirm or change D-022, D-024, D-025, D-026.
  - [ ] X3 Decide D-027 (legacy removal: now / Phase 2 housekeeping / never) and D-028.
  - [ ] X4 (should) E2 done before Phase 2 ends.
  - [ ] X5 (should) E1 done before Phase 2 ends.
- Earlier tests: #2 (S-004) found the ADDON_ACTION_FORBIDDEN popup, fixed in v0.1.2 (D-025). #1 (S-003) 'Error loading': folder structure from loose-file delivery (D-026).
- Real-client test #1 (S-003): FAILED, root cause = folder structure from loose-file delivery (RESOLVED, D-026). Interface 16001 loads the TOC; all 8 Platform files report 'Error loading' in FrameXML.log; a trivial addon loads. Patch v0.1.1 and diagnostics delivered (see Phase1_Compat_Analysis.md).
  - [x] (closed) Resolved by packaging, confirmed by live compile 8/8.
- Phase 1 closure is your decision; Phase 2 requires a separate approval (D-020 covers Phase 1 only).
- Carry-over items for Phase 2 (from D-022): move `/gi` handling from Probe.lua to Core/Slash.lua and delete `Probe.Slash`; Store must preserve `GoldIntelDB.compat` and treat a DB with `compat` but no `schema` as new schema 1; add embeds.xml when libraries are bundled.

## Phase 2: Core and Store (REQ: NFR-4, DR-4)  [APPROVED D-033; code complete; live validation pending]

- [x] 2.1 Core: module registry and lifecycle, service registry, typed bus, config framework, `/gi` commands moved from Probe (2026-10-10, S-007)
- [x] 2.2 Store: SavedVariables access via Platform adapter, schema 1, staged migrations, compat guarantee, read-only and degraded modes, per-character data, pruner (plans only) (S-007)
- [x] 2.3 `Future/CommunityDataEngine.lua` and `Future/RouteEngine.lua` placeholder stubs (FR-FUT-1, D-015) (S-007)
- [x] 2.4 Test harness extended: fake client forbidden-event trap, `svsim` saved-variables simulator, real Phase 1 database fixture; 476 tests (S-007)
- [x] 2.5 Capability stage model (valid, registered, delivered, payloadUsable) with Platform support and E1 registration verification (D-034, external finding ER-RELAY-001) (S-007)
- [x] 2.6 Money pipeline vocabulary reserved on the bus (D-035, ER-RELAY-002) (S-007)
- [x] 2.7 Documents: Architecture section 18, Contracts 1.3, Decisions D-033 to D-039, Risk Register, External Review Log, Phase2_Runtime_Validation_Plan (S-007)
- [x] 2.8 **LIVE validation** (user) CLOSED 2026-10-17 with exceptions PX-1..PX-8 (D-056) (2026-10-17 afternoon: V3, V5, V7, V8 run PASSED except ZONE_CHANGED_INDOORS and the `/gidiag copy` window; E-15; ready for the user's Phase 2 closure decision): V1, V2 (registered case), V4 migration and V6 PASSED on 2026-10-15 (E-13); V4 second session, combat delivery and libraries-off PASSED on 2026-10-17 (E-14). **Remaining (updated):** V3 sell/buy for PLAYER_MONEY, cross a subzone, level-up if possible; V5 `/gi config set idleSec 240` then `/reload` then `/gi config`; V8 `/gidiag run` and `/gidiag copy`; type `/gi debug on` BEFORE `/gi debug ticks`. Superseded list follows: V3 actions (sell something, cross a subzone, enter and leave combat, level-up if possible), V4 second session (`state=ok`, `opens=2`), V5 settings across `/reload`, V7 libraries off, V8 `/gidiag compile` and `run`. Send `GoldIntel.lua` (it now also contains the command output in `runtime.output`) (OI-12)
- [x] 2.9 (S-008) Output recording into the saved data (D-040), clearer `/gi caps` wording, stale contract constant fixed (Contracts 1.4)
- Exit test: automated part DONE (Phase 2 integration tests: Phase 1 database upgrade, reload round-trip, compat preserved, no Phase 3 leakage, nothing assumed delivered, bounded persistence, library matrix). Live part PENDING (2.8).
- Still open from the Phase 1 exceptions: E2 live observation of zone/tick/level/profession readouts (partly produced by validation step V3), E3 legacy adapter removal (D-027, undecided), E5 TOC interface policy (D-028, undecided), E7 CPU measurement.
- Phase 2 CLOSED WITH EXCEPTIONS on 2026-10-17 (D-056). Exceptions PX-1..PX-8 stay tracked in Phase2_Closure_Recommendation.md. **Recommendation delivered 2026-10-17:** COMPLETE WITH EXCEPTIONS PX-1..PX-8 (Phase2_Closure_Recommendation.md). The user stated Phase 2 is "substantially validated"; formal closure awaits the user's answers in that document.
- [x] 2.9 Preserve current + previous runtime session records, history ring and pin (D-041; S-012, rebuild 4; 17 new tests; bounded; diagnostic evidence only).
- [x] 2.10 Phase 3 planning package delivered (Phase3_Planning_Package.md); planning only (D-042). Awaiting the user's decisions on D-043..D-050 and Q-AFK-1..3.

## Phase 3a: Signal verification (diagnostics only)  [APPROVED D-051; protocol: Phase3a_Verification_Protocol.md]

- [x] 3a.1 Build `/gidiag lab` in GoldIntelDiag (read-only experiments, bounded `GoldIntelDiagDB.lab`, secret-safe payload capture, fake-client tests, zip delivery)
- [x] 3a.2 Session 1 (APIs only) run 2026-10-17 (E-17): P0, I1, I2, A1, T2, T1a, H1 done; S1 instance, T1a landing and H2 (screenshot) still open
- [ ] 3a.3 Event sessions, one event per session. DONE: L1 (E-18), L3 and P2 (E-19), L2 and node loot (E-20), M1 show (E-21), Q1 (E-22). REMAINING sessions (one event each, /reload between): C1 (gathering, skinning, fishing); LOOT_OPENED again with a skin of the same mob (repeat-GUID rule); MERCHANT_CLOSED; I1b (run `lab api I1` before and after registering GET_ITEM_INFO_RECEIVED); X1 mail; R1 trade. No registration needed: S1 instance (enter any dungeon), then, Q1, I1b, C1, X1, R1; T1b optional (taxi flag verified); C2 not needed (L1 passed). Also P2 and S1 instance, one event per session: L1, L2 (+L3), M1, Q1; then R1, X1; then C1 (D-029)
- [ ] 3a.4 Taxi and position-jump experiments T1a, T1b, T4; overlay host check H2
- [ ] 3a.5 Record results in Compatibility_Notes (E-17...), evidence files, fill the signal matrix, reopen any decision the evidence contradicts
- Exit: planning package signal matrix fully resolved; the user reviews and then decides on Phase 3b.

## Phase 3: Collect: ledgers (REQ: FR-LED-1..5, FR-SRC-1..8)  [NO-GO until OI-8; see D-029, D-030]

- [ ] 3.1 Context state (merchant, mail, trade, quest, loot)
- [ ] 3.2 Expectations and Reconciler (cash ledger, invariant tests)
- [ ] 3.3 Lots (asset ledger, FIFO conversions)
- [ ] 3.4 Collector handlers for loot, vendor, quest, mail (AH proceeds, COD), trade
- [ ] 3.5 Fixture-driven tests: mixed event streams; edge cases (simultaneous events, zero delta, negative balance moves, rapid sales)
- Exit test: invariants 1 and 2 (Architecture section 3) pass on fixtures; low-confidence share reported by `/gi diag`.

## Phase 4: Sessions, activity, metrics (REQ: FR-SES-1..4, FR-MET-1..5)

- Proposal answered 2026-11-07 (D-099). [x] P4-M1 pure modules built (Aggregate/Clock.lua, Aggregate/Aggregator.lua; not loaded), 2026-11-07 S-061. [x] P4-M2 approved to build (D-102) and built as 0.6.0-passive, 2026-11-08 S-063 (not installed, not merged). [ ] User: at least 3 hours on 0.5.6 in at least 3 sessions (one of 60 minutes or more, at least 18 CPU samples; a group or dungeon session if possible) as the Q-7 baseline; then says whether 0.5.6 works live (merge PR #8, then #7); then approves the 0.6.0 build. [ ] P4-M3 live validation and Phase 4 closure.

- [ ] 4.1 ActivityEngine (v1 activities: grind, gather, fish, vendor, quest, AH, trade, mail/COD, other; manual override; idle)
- [ ] 4.2 SessionEngine and segment rotation
- [ ] 4.3 Metrics: Cash, Wealth, Net GPH, normalization (experimental); explain-breakdown data
- [ ] 4.4 Tests for all of the above, including idle and rotation edge cases
- Exit test: 30-minute simulated session matches manual GPH within 1 percent; Cash GPH always present in outputs.

## Phase 5: Rankings and aggregates (REQ: FR-RNK-1..4)

- [ ] 5.1 Aggregation tables and rollup in Pruner
- [ ] 5.2 Zone, subzone, and activity rankings with confidence and minimum time
- [ ] 5.3 Tests on fixtures including locale-tagged subzone keys
- Exit test: rankings reproduce hand-computed values.

## Phase 6: Pricing and auction profitability (REQ: FR-AH-1..3)

- [ ] 6.1 PriceProvider interface and Native provider (manual prices; scan if capability exists)
- [ ] 6.1a PLAN ONLY (D-111; Phase 6 NOT authorized): optional providers for Auctionator's and TSM's public interfaces (both installed on the user's client), fixed order, Native always the fallback; market price stored with source and age as a separate figure, never changing an acquisition value (D-063); a missing or secret answer is no price, never 0 (D-045). Before any build: verify both licences and the interface calls on Forever (D-110).
- [ ] 6.2 PricingEngine valuation (conservative, staleness)
- [ ] 6.3 AHMath: cut, deposit, failure risk, expected net; tests
- [ ] 6.4 Own list/sold/expired history for sell-through estimates
- Exit test: AHMath matches hand calculations; addon works with no price source.

## Phase 7: Heatmap (REQ: FR-HEA-1..4)

- [ ] 7.1 HeatMapEngine: bins (32x32), time-in-bin, location-attributable credit rule, smoothing, queries; tests
- [ ] 7.2 MapOverlay: texture pool, tooltip, activity filter, metric selector
- Exit test: acceptance criterion 4; map open does not drop frame rate noticeably (measure and record).

## Phase 8: UI (REQ: FR-MET-2, FR-MET-5, FR-PLT-2)

- [ ] 8.1 Dashboard (Cash GPH always visible), SessionList, RankingsPanel, AHProfitPanel, Settings, Minimap
- [ ] 8.2 Explain-breakdown view for every metric
- [ ] 8.3 Capability-degradation messages
- Exit test: manual walkthrough checklist recorded in the handoff.

## Phase 9: Hardening and release

- [ ] 9.1 Performance measurement against NFR-3; record results
- [ ] 9.2 Acceptance criteria 1-7 checklist
- [ ] 9.3 Release notes and Changelog; tag version 1.0.0

---

## Deferred (do NOT start; see Requirements section 1)

CommunityDataEngine behavior; RouteEngine behavior; community sync; guild sharing; route detection and optimization; ML recommendations; world heatmap; craft profitability ranking; auto-detection of dungeon / rare / boost / service / disenchant / arbitrage activities; provenance back-attribution of AH sales.

## Open questions awaiting the user

OI-1 probe output; OI-2 metric definitions; OI-3 Ace3 policy; OI-4 scope deferrals. Details in Decisions.md.

- 3a.x (added 2026-10-17): Session 7 on the enchanter character too (disenchant one green or blue while UNIT_SPELLCAST_SUCCEEDED is registered); a later session with LOOT_OPENED to see the disenchant loot window and source. D-062 (Proposed) awaits user approval.

- 2026-10-17 18:48: C1 done (E-23). D-063 recorded (value views). Still open for Phase 3a: enchanter disenchant cast + loot (D1), repeat-GUID skin proof, MERCHANT_CLOSED, I1b, X1, R1, S1 instance, quest item reward bag diff.

- 2026-10-17 19:07: D-064/AM-13 recorded (economic vs location attribution). Session 8 steps are in GoldIntelDiag/README.txt.

- 2026-10-17 19:20: E-24 recorded (Session 8). Repeat-GUID rule resolved. Missing: enchanter disenchant (cast + loot window). Remaining Phase 3a: D1 enchanter, MERCHANT_CLOSED, I1b, X1, R1, S1 instance, quest item reward bag diff.

- 2026-10-17 19:35: E-25 recorded (disenchant loot window, Item source GUID). Open: disenchant CAST (one session, enchanter, UNIT_SPELLCAST_SUCCEEDED), MERCHANT_CLOSED, I1b, X1, R1, S1 instance, quest item bag diff.

- 2026-10-17 19:38: E-26 recorded (disenchant cast 13262). D-062 evidence complete. Remaining Phase 3a: MERCHANT_CLOSED, I1b, X1, R1, S1 instance, quest item bag diff, optional cast-to-loot timing.

- 2026-10-17 19:45: Session 11 (S1 instance run) steps written in GoldIntelDiag/README.txt; user to run.

- 2026-10-17 19:48: E-27 recorded (S1 instance verified). Remaining Phase 3a: MERCHANT_CLOSED, I1b, X1, R1, quest item bag diff, an instance run WITH loot/kills (optional, run value check), outdoor dungeon entrance (optional).

- 2026-10-17 19:52: Session 12 (X1 mail, MAIL_INBOX_UPDATE) steps written in GoldIntelDiag/README.txt; user to run.

- 2026-10-17 20:50: E-28 recorded (mail). Open: MAIL_CLOSED/MERCHANT_CLOSED, mail header readability (sender/subject, for AH proceeds) needs a read-only lab probe (proposed X2, a small Phase 3a code change, awaiting user go-ahead), AH mail, I1b, R1 trade, quest item bag diff.

- 2026-10-17 20:55: GoldIntelDiag 1.6 built with read-only probe X2 (mailbox headers and auction invoice); 546 tests pass; Session 13 steps in README.txt; user to install 1.6 and run.

- 2026-10-18 09:2x: E-29 recorded (X2 mailbox headers readable; cancelled-auction mail distinguishable from player mail). Open: sold-auction invoice fields (needs a sold auction, cancel gives no invoice), MAIL_CLOSED/MERCHANT_CLOSED (or frame-visibility polls), I1b, R1 trade, quest item bag diff, H2 click-through check (the square itself was reviewed from the user's screenshot: drawn, scales with the map, placed as expected; whether pins can be clicked through it is not checked), optional instance run with loot.

- 2026-10-18 09:3x: User priority (09:18): sold-auction invoice test is wanted eventually but ranks BELOW trade (R1) and item-data loading (I1b). X2 is accepted as sufficient to separate Auction House mail, alt transfer, player gift, generic mail for now. Session 14 (I1b) and Session 15 (R1) steps written in GoldIntelDiag/README.txt.

- 2026-10-18 09:4x: E-30 recorded (I1b item data loading verified). Remaining Phase 3a: R1 trade (user to choose option; no helper available), MAIL_CLOSED/MERCHANT_CLOSED, quest item bag diff, sold-auction invoice (lower priority), H2 click-through, optional instance run with loot.

- 2026-10-18 09:4x: User priority for remaining Phase 3a (09:28): 1 R1 trade, 2 quest reward item bag diff, 3 MERCHANT_CLOSED, 4 MAIL_CLOSED. Sold-auction invoice test is OPTIONAL for Phase 3a closure unless a specific collector design later depends on it. E-30 accepted by the user as sufficient for the item data lifecycle (valuation, unknown handling, vendor pricing). Session 15 (R1, one helper, 4 short rounds, one event per round) rewritten in GoldIntelDiag/README.txt.

- 2026-10-18 09:5x: R1 first attempt produced NO trade data: the user's file shows the transcript 'ROUND/EVENT/NAME/R1 is not in the Phase 3a catalog', so no trade event was ever registered (my README Session 15 used the placeholder EVENT; my wording error). Trades were done unregistered, so nothing was captured. Session 15 rewritten with literal commands per round (TRADE_CLOSED, TRADE_SHOW, TRADE_ACCEPT_UPDATE, TRADE_MONEY_CHANGED). R1 remains open. Possible small lab improvement (not built): list the valid event names when a name is not in the catalog.

- 2026-10-18 10:3x: E-31 recorded (trade verified). Findings: TRADE_CLOSED fires twice, PLAYER_MONEY follows the close by 0.394 s, cancelled trades give zero-delta PLAYER_MONEY, helper accept not visible through TRADE_ACCEPT_UPDATE. PROPOSAL awaiting the user: money-matching window and context lifetime must exceed 0.25 s (observed lags 0.37 to 0.51 s) before Phase 3b; Decisions money-matching rule and Architecture Expectations text would then be amended. Remaining Phase 3a (user order): 2 quest reward item bag diff, 3 MERCHANT_CLOSED, 4 MAIL_CLOSED; optional: sold-auction invoice, H2 click-through, trade item side / GetPlayerTradeMoney probe.

- 2026-10-18 10:2x: D-065 approved by the user (reconciliation window 1.0 s, both directions, ttl at least 1.0 s). Recorded in Decisions.md (D-004 amended, D-065 added), Architecture.md (Reconciler section, edge cases), Phase3_Planning_Package.md. Phase 3b tests must cover the cases in D-065 point 6. No code exists for the Reconciler yet, so no code change.

- 2026-10-18 10:4x: User approved D-065 and agreed trade results are sufficient. GoldIntelDiag 1.7 built: new lab experiment Q2 (quest reward item bag snapshot diff, `/gidiag lab api Q2 before|after`, plus BAG_UPDATE_DELAYED registrable); 551 tests pass (5 new). Session 16 steps in GoldIntelDiag/README.txt. User plan: Q2, then MERCHANT_CLOSED and MAIL_CLOSED lifecycle tests, then a formal Phase 3a Closure Recommendation for review BEFORE any Phase 3b discussion.

- 2026-10-18 10:5x: E-32 recorded (Q2 quest reward bag diff verified: Hezrul's Head removed, Bounty Hunter's Ring added, +800 copper; BAG_UPDATE_DELAYED fires 0.15 s before and 0.289 s after PLAYER_MONEY). Remaining Phase 3a (user plan): MERCHANT_CLOSED, MAIL_CLOSED lifecycle tests, then the formal Phase 3a Closure Recommendation. Optional/deferred: sold-auction invoice, H2 click-through, trade item side, choice-reward quest, stack-merge and full-bag cases.

- 2026-10-18 10:5x: Sessions 17 (MERCHANT_CLOSED) and 18 (MAIL_CLOSED) steps written in GoldIntelDiag/README.txt (no code change). After them: formal Phase 3a Closure Recommendation.

- 2026-10-18 11:0x: E-33 recorded (MERCHANT_CLOSED verified, both close routes, duplicate delivery on walk-away). User offered to include a sold-auction mail in Session 18: Session 18 now = MAIL_CLOSED registration plus `/gidiag lab api X2` on the mailbox containing the AH sale mail (verifies the invoice fields, so the optional invoice test is folded in). Remaining Phase 3a: Session 18, then the formal Phase 3a Closure Recommendation.
- 2026-10-18 11:1x: E-34 recorded (MAIL_CLOSED never delivered in two closes; sold-auction invoice readable: price 51, deposit 100, cut 2, money 149; deposit is a refund; mail deleted after take). All priority-list tests done. `Phase3a_Closure_Recommendation.md` written for the user's review. Phase 3b NOT started and NOT authorized.
- 2026-10-18 11:2x: User approved closing Phase 3a with X-A..X-H (D-066): XP kill proxy dropped, boat/zeppelin not a gate, D-065 stays. Phase 3b scope and readiness assessment written for review (`Phase3b_Scope_and_Readiness.md`). NOT authorization to implement.
- 2026-10-18 11:4x: User approved P3B-1..P3B-10 (D-067..D-072; D-027 and D-028 approved). 3b-0 built: D-027 patch, collector event allow-list, lab replay helper, version 0.2.1-phase3b0, contract 1.6, 565 tests. Lab 1.8 built for the AH/COD/outgoing-mail addendum (README Sessions 19-22). Next: user runs Sessions 19-22 and reviews 3b-0.
- 2026-10-18 11:1x: User APPROVED increment 3b-0 (D-027 removal, event allow-list, replay harness, OTHER reporting by entries and value). Approving 3b-0 does not start 3b-1; 3b-1 needs a separate go-ahead (D-067). Profiling plan and Sessions 19-22 instructions re-sent as files.
- 2026-10-18 11:2x: User approved 3b-0 and asked for a permanent replay regression suite (D-073): corpus E-22, E-28, E-31, E-34 in Tests/fixtures/replay, missing file fails the suite, 567 tests. OTHER share by VALUE is the headline figure (D-072 clarified). Accounting model for AH confirmed in the reply; cancel/expire treatment to be MEASURED in Session 19.
- 2026-10-18 11:2x: User gave expected AH mechanics (deposit forfeited on cancel/expiry, returned on sale; cut 5% faction, 15% neutral). Recorded under D-070 as [reported] expectations, not evidence. Measured Session 19-22 results win; differences get documented. The neutral-house 15% cut is not covered by Sessions 19-22 (optional later check at a neutral house).
- 2026-10-18 11:4x: E-35 recorded (Session 19). Deposit -100 exact; cancel changes money by 0 (deposit forfeited, user-expected mechanic MEASURED for cancel); buyout 13 + bid 101 = -113 (1 copper unexplained, middle snapshot missing); all AH and send-mail event names valid; bidding exists; owned auctions not readable without a query. Proposed Session 23 (one AH event plus repeat of buyout and bid) before 3b-4.
- 2026-10-18 12:xx: E-36 recorded (Session 23). AUCTION_HOUSE_AUCTION_CREATED fires 0.358 s BEFORE the deposit money (usable posting signal, 1 sample). Deposit -100 exact; cancel 0 (confirmed twice). Buyout was 4 copper (user corrected note), measured -4 exact; Session 19's 1 copper is most likely the same kind of note error. Bid untested. Remaining addendum: Sessions 20, 21, 22; optional clean buyout repeat and bid test with a second character posting a bid-able item.
- 2026-10-18 12:2x: E-37 recorded: bid of 300 copper charged -300 exactly and immediately, nothing later. Session 23 complete. Remaining addendum: Sessions 20, 21, 22 (outgoing mail, COD, auction mails incl. outbid/winning mail if available).
- 2026-10-18 12:3x: E-38 recorded (Session 20): postage 30 copper per mail; item mail -30; money mail -60 (amount typed to be confirmed by user); COD mail -30 (sender pays postage only); GetSendMailMoney/COD read 0 before sending. Next: Session 21 (Divine Slaps pays COD), Session 22.
- 2026-10-18 12:4x: E-39 recorded (Session 21): COD paid -100 exact, readable in header before paying; money ref 0.106 s after MAIL_INBOX_UPDATE; mail money +30 exact; buyer invoice shows 12 copper (explains the E-35 1 copper). Only Session 22 remains (Rehgar Deadeye collects the COD payment and auction mails).
- 2026-10-18 12:5x: E-40 recorded (Session 22): COD proceeds +100 exact, no fee, ref 0.267 s after MAIL_INBOX_UPDATE. Verification addendum (D-068) COMPLETE: Sessions 19-23 done. Uncovered (optional/deferred): expiry, outbid/bid-won mail, neutral-house 15% cut, multi-attachment mails. 3b-1 still needs the user's separate go-ahead.
- 2026-10-18 13:0x: User reviewed E-35..E-40, accepted the economic flow matrix as complete for Phase 3b scope and the four untested cases as optional. Asked for the 3b-1 plan: Phase3b_Increment_3b-1_Plan.md (D-074 Proposed). Awaiting approval A-1..A-5; no code written.
- [x] 2026-10-18 (S-042) RISK R-3b1-CHAR DOWNGRADED to low (E-44): per-character files live in `...\70\<First-Last>\SavedVariables`, so different surnames do not collide. Remaining unknown: what `70` encodes and whether the same full name on two realms is separated. Optional hedge for a later increment: stamp {guid, name, realm} in GoldIntelCharDB at login and detect a mismatch (user decision; not built).
- [x] 2026-10-18 (S-042) 3b-1 round 2 part 2 (= round 3, E-45): mail with snapshot CPU, trade, quest, auction posting validated live.
- [ ] 2026-10-18 (S-051) Run the 0.3.5 evidence session (solo + grouped); answer the 7 questions; then propose the final loot-share rule (D-078 stays unbuilt until approved). 3b-2 closure and 3b-3 NOT approved.
- [ ] 2026-10-18 (S-051) User decision needed on D-078 Addendum 2 (chat-signal rule). Not built.
- [x] 2026-10-18 (S-052) D-078 chat-signal rule built (0.3.6).
- [ ] 2026-10-18 (S-052) Run the 0.3.6 grouped validation; report OTHER share, unmatched, gaps, chat counters, limitations; then 3b-2 closure recommendation (user decides). 3b-3 NOT started.
- [ ] 2026-10-18 (S-052) Decide which unsourced money sinks (taxi, trainer, respec, barber, guild bank, repairs) to add to the 3b-4 scope; each needs a live signal check. Source of the idea: Reference_AccountantClassic.md.
- [ ] 2026-10-18 (S-052) Auctionator reference (for 3b-4 AH and Phase 6): need Source\Manifest.xml, Source_Forever folder, Source_Classic\Manifest.xml, Imports_LegacyAH\Manifest.xml, Source_LegacyAH\Manifest.xml, then the posting, purchase and deposit files they list. Known so far: TOC lists Interface 16001; Forever game type tag is `camelot`; Forever-only file holds just Durations 2/8/24 hours. Our E-36 event AUCTION_HOUSE_AUCTION_CREATED is a modern-AH event, so Forever probably uses the modern AH API (to confirm).
- [ ] 2026-10-18 (S-052) 3b-4 design inputs from Auctionator: deposit readable before posting (CalculateItemDeposit/CalculateCommodityDeposit); commodity buy total known at COMMODITY_PRICE_UPDATED, succeeds on COMMODITY_PURCHASE_SUCCEEDED; GetCancelCost readable before cancel; resolve duration code vs hours (2/8/24) live. See Reference_Auctionator.md.
- [ ] 2026-10-18 (S-052) Auctionator review complete; 3b-4 design inputs written in Reference_Auctionator.md (7 points). Live checks needed before any build.
- [ ] 2026-10-19 (S-053) 3b-2 closure recommendation written (Phase3b_3b-2_Closure_Recommendation.md); user decides. Grouped validation waived by the user; live issues are bug fixes.
- [x] 2026-10-19 (S-054) User closed 3b-2 (D-079).
- [x] 2026-10-19 (S-054) 3b-3 package approved (D-080), M1 authorized.
- [x] 2026-10-19 (S-054) 3b-3 M1 built: BagDiff, Valuation, Lots (pure), 1152 tests.
- [ ] 2026-10-19 (S-054) User reviews M1 (Phase3b_3b-3_M1_Report.md); then M2 (Platform/Bags extension, P_BAG_DIFF, ItemSources trace-only, CHAT_MSG_LOOT recorder, repair-cost probe) needs its own go-ahead. M2 evidence must answer: bag index range, equip/unequip, repair-cost API, bank movement, roll-awarded items.

### 3b-2 post-closure bug-fix backlog (tracked, not blocking; D-079)
- [ ] Chat-signal loot rule has not run in the live client (tests and replays only); optional 5-minute solo smoke test of 0.3.8.
- [ ] Groups of 3 or more, out-of-range members, one player looting several corpses.
- [ ] Silver/gold chat wording (`Your share of the loot is 22 Silver, 66 Copper.`), user-reported, not measurable on the level-30 beta.
- [ ] Real logout/login with the final lastMoney logic; trade, buyer COD payment, AH sale mail, full-bag coin, empty loot window shape (E-47).
- [ ] Unresolved Auctionator duration-code mapping (3b-4 input).
- [ ] 2026-10-19 (S-054) Session E probe additions: record reported sell price + classID for an enchanting mat, a quest item and a normal item; check whether a no-vendor item can ever be part of a vendor sale (candidate evidence rule); decide the equal-per-unit fallback (options in chat: keep + counter, group total, remove).
- [ ] 2026-10-19 (S-054) Phase 6 note: disenchant-value estimates need a drop-chance source; ask for a reference addon then. Bound state must be read live, not from the lot.
- [x] 2026-10-19 (S-054) D-081: option B approved (acquisition/conversion accounting); the Session E additions below for cursor, bag slots, bank and in-flight items are DROPPED. Keep: buyback signal, no-vendor sell price/class, repair-cost API, roll items, bag index range, CHAT_MSG_LOOT.
- [ ] 2026-10-19 (S-054) (superseded by D-081) Session E additions (user policy: changes while monitoring is off are accepted risk, gap lots are bookkeeping not alarms): (a) is the cursor item readable (GetCursorInfo) so held items count as carried; (b) items placed in trade/mail/AH slots and then cancelled: what does the diff show; (c) equip a bag: include bag slots (inventory slots for bags, ammo) in carried scope; (d) vendor buyback signal (purchase vs buyback).
- [x] 2026-10-19 (S-054) Scope review answered by the user (D-082). Recorded as AM-14..AM-16.
- [x] 2026-10-19 (S-054) D-082 addendum: dynamic heat map (repricing), value created per hour, no repairs/consumables in any GPH, Net GPH removed; repair-cost probe and Q-5 (repair vs purchase) DROPPED. Aggregates must store item counts for repricing (Phase 4/5 design item).
- [x] 2026-10-19 (S-054) Manual price resolved (optional override, highest value wins), M1 Valuation updated, 1174 tests.
- [ ] 2026-10-19 (S-054) (superseded in part) D-082 pending confirmations: (a) heat metric when no AH data, (b) manual price meaning (max(vendor, manual x (1 - cut))), (c) heat excludes repairs/consumables. Until answered, M1 Valuation is unchanged.
- [ ] 2026-10-19 (S-054) M2 must include: skin cast => GATHER for creature loot (Stamps GATHER map lacks 'skin'); tests for the skinning window (second LOOT_OPENED same GUID, E-24).
- [ ] 2026-10-19 (S-054) Phase 4 design item: segments carrying several activities (grind + skin) without rotating at each skin; hover shows the activity list.
- [x] 2026-10-19 (S-054) Money-sink classification for heat is not needed (repairs, consumables, taxi, trainer, respec, barber are excluded from heat); the earlier TODO about adding unsourced sinks to 3b-4 is resolved. Q-9 repair-cost probe is now only for the personal Net view (low priority).

- [x] 3b-3 M2 build (trace only). [ ] Session E live evidence — awaiting user. [ ] M2 evidence review/approval before any lot persistence (M3). M3/M4 NOT authorized.
- [x] Session E (reduced) done. [ ] User approval of M2 evidence. Open: roll-awarded items (needs group). M3 relabels `unexplained` per D-083.
- [x] 3b-3 M3 build (lot book, price command, rollback check). [ ] Session V live validation (user). [ ] M3 review and approval. M4 (measurements, closure recommendation) NOT authorized.
- [x] gathering casts of other ranks: fixed by name matching in 0.4.6 (verified for skinning; herbalism, mining, fishing at other ranks await a CAST trace line from a character with those professions).
- [x] Session V (M3) passed 2026-10-21. [x] User review/approval of M3 (D-086, 2026-10-31). [ ] M4 (measurements, closure recommendation) NOT authorized. Open: roll-won items, herb/mine/fish names at other ranks, empty loot windows.

### Live launch and passive play (2026-11-03, S-057)
- [x] 2026-10-31 (S-055) 0.5.0-passive and 0.5.1-passive built (D-086 and addendum); 1,255 tests.
- [x] 2026-11-03 (S-057) Handoff verified against the repo (last code commit a21e071; 1,255 tests pass; all 52 addon Lua files parse under Lua 5.1).
- [x] 2026-11-03 (S-057) Evidence route recorded (D-087). Remote Control link not available yet (laptop does not offer the folder to cloud sessions); fallback: user attaches GoldIntel.lua after play.
- [x] 2026-11-03 (S-057) Document catch-up (Contracts F18, README, TODO, Decisions status notes, entry order of Changelog and Session_Handoff, Bible and Compatibility_Notes headers) and pre-launch review (PreLaunch_Review_2026-11-03.md).
- [x] 2026-11-03 User re-copied `GoldIntel/GoldIntel.toc` from main and verified it (reported). Still confirm at launch that AddOns holds GoldIntel and GIMin only.
- [x] 2026-11-03 (S-057) Rule D-090: every stage ends with a ready-to-install package block (handoff section 8).
- [ ] User: update the Claude desktop app on the laptop, then retry the folder link (D-087).
- [ ] Launch day: `/gi caps` and `/gi version`; compare game version, build and Interface with 1.60.1 / 16001; if the client calls the addon out of date, update `## Interface:` (D-028, OI-10, OI-11). Confirm the client folder is still `_forever_`.
- [ ] First live login is a validation event for 0.5.x: one "recording started automatically" line about 3 s after login; `/gi ledger check` difference 0 copper; any "UNEXPECTED item condition" line is a bug report.
- [x] 2026-11-03 (S-057) User decisions: OI-14 item recording ON by default (D-088); OI-15 beta data kept, revisit with Account Best (D-089).
- [ ] Open: OI-16 privacy scrub (deferred, repo stays private); OI-17 status of D-029..D-031.
- [ ] Phase 7 design item: beta characters and Account Best (D-089).
- [ ] After each play session ("logged out, check"): read SavedVariables per D-087 and report.
- [x] M4 (lot size, CPU, memory, 3b-3 closure recommendation): authorized 2026-11-07 (D-097), done 2026-11-08; 3b-3 closed (D-101).

### 0.5.2 (2026-11-05, S-058)
- [x] User approved fixes after the first live sessions: D-091 skinning first window, D-092 logout check, D-093 trainer source, D-094 quest evidence line. Built as 0.5.2-passive on a branch with tests and a PR.
- [ ] User: install 0.5.2 (FULL restart) after approving the build. Live checks: first trainer visit (`EVIDENCE trainerRegistered=true`, `EVT trainer open`, fee booked as trainer); next skin of a corpse someone else left (GATHER); next logout shows `EVT check final ... logout` with difference 0.
- [ ] Open evidence: lag case (chat line before late money, fix 1 held); quest reward without quest context (watch `EVT quest done` timing); herbalism and fishing casts; roll-won items.
- [x] 2026-11-06 Live checks of 0.5.2 passed: trainer events registered and fees booked on both characters, first-window skinning 3 of 3 GATHER, every logout check 0 (MISMATCH only on old 0.5.1 lines). Persistence across 46 loads and 31 intervals: ledger ids without a hole, lots carried over.
- [x] 2026-11-06 (S-059) User approved D-095 (roll-won items) and D-096 (split shares); built 0.5.3-passive, PR opened.
- [ ] User: install 0.5.3 (`/reload` is enough) after approving the build.
- [ ] Remaining evidence before M4: coin in silver or gold (wording of the share and loot lines); optional herbalism/fishing cast, money taken from mail, money in a trade.
- [ ] Phase 7 design note: inside an instance the map id is nil and only the zone name is known (Ragefire Chasm, 2026-11-05); D-060 places instance runs at the entrance.
- [x] 2026-11-07 (S-060) User merged PR #4 (0.5.3) and authorized M4 (D-097). Silver wording verified live; roll wins and split shares verified live; client patch 70862 kept 1.60.1 / Interface 16001.
- [x] 2026-11-07 (S-060) M4 sizes measured (Phase3b_3b-3_M4_Report.md). Built 0.5.4-passive measurement build (Perf samples), PR opened.
- [x] 2026-11-07 (S-060) User approved R-1, R-2, R-3 as a stopgap (D-098). Built 0.5.5-passive (contains 0.5.4).
- [x] 2026-11-08 (S-062) 0.5.5 hour-of-play data received: CPU 0.04-0.06 ms per frame, lasting memory growth about 0.06 MB per hour (PASS); the memory reading caused one 100-400 ms frame per sample, removed in 0.5.6 (D-100, approved).
- [x] 2026-11-08 (S-062) Phase3b_3b-3_Closure_Recommendation.md written. [x] User decided the 3b-3 closure (D-101).
- [x] 2026-11-08 (S-062) Phase4_P4-M2_Plan.md written (plan only). [x] User confirmed section 0 (D-107) and decided P4-M2 (build only, D-102).
- [x] User: install 0.5.6 after approving the build (`/reload` over 0.5.5). (Installed on all characters, D-107.)
- [x] User: install 0.5.5 (FULL restart from 0.5.3), play normally including one session of an hour or more, upload. Then CPU and memory against NFR-3, then the 3b-3 closure recommendation. (Done: S-062 read the files; D-100, D-101.)
- [x] User: review Phase4_Live_Aggregation_Proposal.md (proposal only; Phase 4 NOT authorized). (Done: answers Q-1..Q-7, D-099.)
- [ ] Still OTHER by design until 3b-4: taxi, respec, barber, guild bank, repairs (repairs at a vendor are already vendor purchases).
- [x] 2026-11-08 (S-065) D-104 (chat-only items recorded with the user's words) and D-105 (session rules, first-report exception, docs-only merge approval); stale documents fixed (TODO, Bible, README, CODE_SESSION_OPENING_PROMPT marked replaced).
- [ ] User: play 0.5.6 at least 3 hours in at least 3 sessions (one of 60 minutes or more; group or dungeon if possible), attach the files in the session that analyzes them, and say whether 0.5.6 works live (D-102).
- [x] User: confirm or correct the quotes in Phase4_P4-M2_Plan.md section 0. (Confirmed correct, D-107.)
- [x] User: decide the TOC `## Notes:` change. (Next approved build, D-107.)
- [ ] Next approved build: update the TOC `## Notes:` line (it still says "Phase 2: core and store") (D-107).
- [x] 2026-11-08 (S-066..S-068) D-106 (merges through the PR, REST command while `gh pr merge` is refused), D-107 (answers recorded), D-108 (standing approval covers TODO.md and Changelog.md). PRs #11, #12, #13 merged.
- [x] 2026-11-14 (S-069) 0.5.6 baseline PASSED (D-109): 39.9 h, 224 periodic samples, 0.017 ms per frame, every 0.5.6 check 0. PR #8 and PR #7 merged.
- [x] User: attach Accountant Classic's SavedVariables file (same WTF folder) for the income and spending cross-check with GoldIntel, especially the OTHER share (D-110). (Done 2026-11-14: nets equal to the copper, D-111.)
- [x] User: decide the price plan (Baseline_0.5.6_Report.md section 6): optional Auctionator / TSM source with GoldIntel's own fallback. Plan only; Phase 6 territory, NOT authorized. (Added to Phase 6 as plan only, item 6.1a, D-111.)
- [ ] Before using any other add-on as a source or reference: verify its licence (D-110); THIRD_PARTY.md with the first copied item.
- [ ] PR #9 (0.6.0) is behind main since PR #7 and #8 merged: bring main into it (documents will conflict) when the user reviews it.
- [ ] Note for Phase 4/7: /reload load frames cost 100-178 ms charged to GoldIntel (cause not measured; the 1.9 MB account SavedVariables file is a candidate, unverified). Track with the 0.6.0 measurements.

