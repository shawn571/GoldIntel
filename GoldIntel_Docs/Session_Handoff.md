# GoldIntel Session Handoff

Append newest section at the TOP. The newest section wins over older ones. Format is mandatory.

---

## S-059 | 2026-11-05 to 2026-11-06 | Claude (Claude Code cloud session)
- Read the user's files of 2026-11-05 (two upload sets, two characters, a Ragefire Chasm group run with up to 3000 ms lag). 0.5.2 verified live: trainer events and fees, first-window skinning, logout checks. Persistence across reloads and restarts confirmed (46 loads, ledger ids continuous, lots carried over). Trade item path works (mage water). Two gaps found: roll-won items unexplained; group shares paid in two pieces become OTHER.
- User: lag is not a reason to change code; no area loot in this version; several corpses looted at once is the likely cause of split shares. Approved D-095 and D-096. Built 0.5.3-passive (1,300 tests), PR opened. Not installed; `/reload` is enough.

OPEN ISSUES: silver/gold coin wording unseen; lag case (fix held); one unknown -99 copper sink; OI-16 deferred; OI-17 open.
BLOCKERS: none.
NEXT RECOMMENDED TASK: user approves and installs 0.5.3; next check verifies roll wins and share sums; then the user decides on M4 (needs a measurement command for CPU and memory).

## S-058 | 2026-11-04 to 2026-11-05 | Claude (Claude Code cloud session)
- Read the first live data (fallback route D-087, files attached): 0.5.1 auto start works; launch client 1.60.1 build 70790, Interface 16001 unchanged; every `EVT check` 0 copper except one false MISMATCH at logout; lots and anomalies clean.
- Findings: lag put 1 copper in OTHER (chat line before a 2.4 s late money change; fix held at the user's choice); skinning of corpses never looted here booked GRIND (7 of 7); trainer fees are most of OTHER (410 of 447 copper); one quest reward without quest context; one login gap +36 (probably a crash or disconnect, user not yet asked back); empty loot windows are brief false starts (2 of 2).
- User approved D-091..D-094. Built 0.5.2-passive on branch fix/0.5.2-skin-trainer (based on the open PR #2 branch), 1,278 tests, PR opened. Not installed. FULL restart needed.

OPEN ISSUES: TRAINER_SHOW/TRAINER_CLOSED unverified live (first trainer visit); OI-16 deferred; OI-17 open; lag fix held; login gap question to the user.
BLOCKERS: none.
NEXT RECOMMENDED TASK: user reviews the 0.5.2 PR and approves the build; install with a full restart; next "logged out, check" verifies the trainer source, first-window skinning and the logout line. M4, 3b-4 NOT authorized.

## S-057 | 2026-11-03 | Claude (Claude Code cloud session)
- Verified HANDOFF_Code_Session_2026-11-02.md against the repo: last code commit a21e071 (later commits docs only), 0.5.1-passive, contract 1.9.0, schema 2, 1,255 tests pass (Lua 5.4.6), all 52 addon Lua files parse under Lua 5.1. Disagreements reported to the user; corrections in the files below.
- User decisions: D-087 evidence route (Remote Control link to exactly `C:\Program Files (x86)\World of Warcraft\_forever_`, read-only on SavedVariables; fallback the user attaches GoldIntel.lua; trigger "logged out, check"; no timer). Document catch-up and pre-launch review approved.
- Folder link attempt: the folder is in the user's Remote Control list on the laptop but is not offered to cloud sessions (likely the Windows desktop app needs an update). Fallback in use.
- Done (docs only, branch docs/catch-up-2026-11-03, pull request): Decisions D-087, status notes, OI-14..OI-17; Contracts doc 1.9.1 with F18; README; TODO; Changelog and Session_Handoff entry order (moved unchanged, newest first); Project_Bible header, reviewer names, inventory rows; Compatibility_Notes header; Architecture AC-19 note; new PreLaunch_Review_2026-11-03.md. No code changed.

- Update: user decided OI-14 (item recording ON by default, D-088) and OI-15 (beta data kept, revisit with Account Best, D-089); OI-16 deferred (repo stays private), OI-17 open. PR merged.
- Update 2: user rule D-090 (every stage ends with a package block; added to the handoff working rules). User re-copied and verified the installed TOC; launch checklist step 1 removed. Package GoldIntel_0.5.1_passive_AddOns.zip built from 1e42dd8 (GoldIntel and GIMin identical to main) plus a 0.4.7 rollback zip from fa78ade.

OPEN ISSUES: OI-16 privacy scrub (deferred, repo private; D-073 fixtures); OI-17 status of D-029..D-031; installed TOC reads 0.5.0-passive (user to re-copy); OI-5, OI-8 wording, OI-10/OI-11 at launch, OI-13; D-062 Proposed; roll-won item label; money sinks in 3b-4 (only for the OTHER share).
BLOCKERS: none for live play. Remote Control link unavailable until the desktop app is updated.
NEXT RECOMMENDED TASK: user plays from 2026-11-04 (checklist in PreLaunch_Review_2026-11-03.md section 4); on "logged out, check" read the SavedVariables per D-087 and report. M4, 3b-4 and new features NOT authorized.

## S-056 | 2026-11-02 | Claude
- Wrote HANDOFF_Code_Session_2026-11-02.md and CODE_SESSION_OPENING_PROMPT.md for the move of GoldIntel development to a Claude Code cloud session. Docs only; no code changed. Read the handoff first: it lists what is approved, open decisions, known bugs, package state (0.5.1 zip matches main), pre-launch tasks, working rules, what exists only in chat or memory, and known document staleness. M4 NOT authorized.

## S-055 | 2026-10-31 | Claude
- User approved M3 (D-086) and linked the Forever folder (C:\Program Files (x86)\World of Warcraft\_forever_) to the session. Built 0.5.0-passive: auto start, marked intervals, bigger trace plus keep list. 1,250 tests pass. M4 NOT authorized.
- Next: user plays normally from 2026-11-04; after logout/`/reload` Claude reads GoldIntel.lua from WTF\Account\SHAWN313\... and reports: ledger check difference, anomalies, unexplained adds, new CAST names, roll-won items. Alert the user when a package is ready or a decision is needed. Open evidence: roll-won items, herb/mine/fish spell names, empty loot windows.
- S-055 update: built and installed 0.5.1-passive (EVT lines, periodic and final check lines). 1,255 tests pass. When reading data: look at `trace.keep` first (EVT group, EVT check, ANOMALY, unexplained, CAST).

## S-054 close (M3 validated)
Session V passed on builds up to 0.4.7-phase3b3m3: ledger check 0 copper, exact vendor allocation, persistence, reagent bag, skinning by name. Fixes: D-085 money pairing, spell-name gathering. Waiting for the user's M3 review; M4 not authorized. Package GoldIntel_3b3_M3_AddOns.zip is current (0.4.7).

## S-054 M3 (build 0.4.7-phase3b3m3)
M2 approved by the user; M3 built: LotBook, `/gi price`, `/gi lots last|unknown|check|reset confirm`. 1,230 tests pass; rollback to 0.3.8 verified on data with lots. Package GoldIntel_3b3_M3_AddOns.zip; script Phase3b_3b-3_M3_Session_V.md. Restart required (new file). Next: user runs Session V; then review. M4 not authorized.

## S-054 close (M2 evidence)
Evidence collected and reviewed with the user; report in Phase3b_3b-3_M2_Report.md. Waiting for the user to approve the evidence; M3 not authorized. D-083 recorded.

## S-054 update (M2)
M2 built (0.4.1-phase3b3m2): ItemSources trace-only, `/gi lots`, G8 chat evidence. Package GoldIntel_3b3_M2_AddOns.zip; script Phase3b_3b-3_M2_Session_E.md. Next: user runs Session E, we review evidence; no lot persistence until approved. Restart client required.

## S-054 | 2026-10-19 | Claude
- (update 2) User approved Q-1..Q-14 and D-080; 3b-3 authorized at M1 ONLY. Built 0.4.0-phase3b3m1: pure modules BagDiff, Valuation, Lots with 116 new tests and 35 mutants; 1152 passed, 0 failed. Nothing is wired: no events, no storage, no commands, so no client behavior changes. Package GoldIntel_3b3_M1_AddOns.zip (optional to install; `/reload` is enough if you do). M2 is NOT started and needs the M1 review first; M3/M4 not authorized; no lot persistence before the M2 evidence is approved.
- (update 1) User CLOSED 3b-2 (D-079). Wrote the 3b-3 scope and readiness package.

## S-053 | 2026-10-19 | Claude
- Built 0.3.8-phase3b2m8: split divisor follows range (user-confirmed facts). Supersedes 0.3.7. `/reload` is enough. Next: grouped validation per Phase3b_3b-2_M8_Validation_Session.md (adds the far-away-member case). 3b-2 open, 3b-3 unstarted.

## S-052 addendum | 2026-10-18 | Claude
- User decided partner-looted coin is activity LOOT (med), not OTHER. Built in 0.3.7-phase3b2m7 (supersedes the 0.3.6 zip). Validation script unchanged except the zip name. `/reload` is enough.

## S-052 | 2026-10-18 | Claude
- Built 0.3.6-phase3b2m6: chat-signal loot rule (D-078 accepted), WAIT 2.0 s, lastMoney follows the ledger. 1033 tests green. Only Lua files changed (no new files, no new events): `/reload` is enough after replacing the folder (a full restart is the safe choice).
- Next: grouped validation (script Phase3b_3b-2_M6_Validation_Session.md). Report: ledger check, OTHER share by value and entries, largest OTHER, unmatched, gap count/value, chatLate/chatCovered/chatSplit, any remaining grouped-play limitations (groups > 2, silver/gold wording, one player looting a pull). Then the 3b-2 closure recommendation for the user to review. 3b-2 open, 3b-3 unstarted.

## S-051 | 2026-10-18 | Claude
- Built 0.3.5-phase3b2m5 evidence build (CHAT_MSG_MONEY recorder + group info in trace). 1008 tests green. CLIENT RESTART required (new file in TOC, 15th collect event).
- Next: user runs the evidence session (solo, then grouped), returns the character GoldIntel.lua and chat. Then answer the 7 questions and propose the final rule (signal-based if CHAT_MSG_MONEY works). Do NOT build D-078 before that review. 3b-2 open, 3b-3 unstarted.

## S-050 | 2026-10-18 | Claude

- Done: E-47 (Chilly Slaps trace) reviewed: solo auto-loot 16/16 exact, lastMoney fix works (18136, lmv 2). User confirmed Role 3 (E-46) was partly grouped (2 players): coin split explains the failure (18 unmatched own shares + 11 partner shares = 29 OTHER). Wrote Phase3b_3b-2_M4_RootCause_and_Proposal.md (D-078 PROPOSED, nothing built).
- Next: user decides option A/B/C and whether to run the grouped confirmation trace (build 0.3.4b, no restart needed). 3b-2 closure not requested; 3b-3 not approved.
- Reload: none.

## S-049 | 2026-10-18 | Claude

- Done: user approved lastMoney fix and the diagnostic loot trace; user does NOT approve closing 3b-2; 3b-3 not approved. Built 0.3.4-phase3b2m4a (trace + fix), 999 tests green, package GoldIntel_3b2_M4b_AddOns.zip (user corrected: Classic loot rules, one corpse at a time, brief auto-loot window), script Phase3b_3b-2_M4a_AutoLoot_Session.md.
- Next: user runs the focused auto-loot session and returns the trace and SavedVariables; Claude presents a root-cause analysis and a proposed classification change for review. No classification change before that review.
- Reload: CLIENT RESTART required.

## S-048 | 2026-10-18 | Claude

- Done: M4 evidence received (E-46). Roles 1 and 2: all checks 0 copper. AUTO-LOOT failed (75.9% OTHER by value, 18 unmatched). Defect found: lastMoney stored 0 at real logout (false gap at next login); fixed in source with marker lmv=2 (988 tests green), NOT packaged. Report: Phase3b_3b-2_M4_Report.md.
- Next: user decides (1) lastMoney fix, (2) diagnostic loot trace build, (3) file/character mapping. No closure recommendation yet. 3b-3 NOT started.
- Reload: no new package delivered; next package needs a CLIENT RESTART.

## S-047 | 2026-10-18 | Claude

- Done: user APPROVED M3, set retention CAP to 2000 (FOLD 500), authorized M4. Built 0.3.3-phase3b2m4 (cap change only), package GoldIntel_3b2_M4_AddOns.zip, wrote Phase3b_3b-2_M4_Validation_Plan.md.
- Next: user runs the two live sessions; Claude records evidence (E-46...) and writes the M4 report (checks, OTHER share by value, largest OTHER, unmatched, gap count/value, AUTO-LOOT, non-zero differences, unexpected classifications) and, if 0 copper difference and no major classification errors, the 3b-2 closure recommendation. Do NOT begin 3b-3 before that review.
- Reload: CLIENT RESTART required.

## S-046 | 2026-10-18 | Claude

- Done: user APPROVED M2 and authorized M3. Built schema 2 (ledger, migrationBackup, CharDB lastMoney), Ledger/Cash.lua, Ledger/Ledger.lua, collector wiring, `/gi ledger`, `/gi diag` ledger block, Contract F15, addon 0.3.2-phase3b2m3. 984 tests green incl. real-file migration, rollback with the 0.3.1 Store, multi-session persistence property test, 24 Cash/Ledger mutants. Report: Phase3b_3b-2_M3_Report.md. Package GoldIntel_3b2_M3_AddOns.zip (rollback: GoldIntel_3b1_AddOns.zip).
- Next: user reviews the M1-M3 package. Do NOT start M4 (live validation: normal session + AUTO-LOOT session) before the separate go-ahead. Nothing in 3b-3/3b-4.
- Reload: CLIENT RESTART required (TOC changed). GoldIntelDiag and GIProbeLoot out of AddOns for validation.

## S-045 | 2026-10-18 | Claude

- Done: user APPROVED M1 and authorized M2. Built Collect/Sources.lua, Collect/Stamps.lua, Platform.LastCast, `hold` expectations, tests (test_stamps, test_sources, test_replay_ledger, test_sources_mutation, helpers/ledgerworld, Loader.override), Contracts 1.8.0 (F14), Architecture AC-9..AC-13 text. Suite 901/0. Sources.Begin is only called by tests (inert in game). Report: Phase3b_3b-2_M2_Report.md.
- Next: user reviews M2 (replay classifications, 7 judgment calls). Do NOT start M3 (Cash store, schema 2, commands, collector wiring) before approval. Live validation only after the M1-M3 package.
- Reload: none needed.

## S-044 | 2026-10-18 | Claude

- Done: D-077 APPROVED (all Q approved, option A). Built M1 only: Collect/Expectations.lua, Collect/Reconciler.lua (pure, injected time, source-agnostic), Tests/test_reconciler.lua (26 tests incl. 200+100 random-stream property tests and 18 mutation checks). Suite 818/0. Modules are in the TOC but nothing calls them (inert); Contract/Architecture text not yet amended (Contract 1.8 and AC-9..13 text arrive with M2/M3).
- Next: user reviews M1. Do NOT start M2 (Sources, Stamps, replay corpus) before approval.
- Reload: none needed; no user-visible change.

## S-043 | 2026-10-18 | Claude

- Done: user APPROVED CLOSURE of 3b-1 (D-076). Wrote Phase3b_Increment_3b-2_Scope_and_Readiness.md (D-077 Proposed): scope, as-built vs F2c differences, AC-9..AC-13, expectation model, Reconciler algorithm, cash ledger and schema 2, stamps, validation plan (about 280 tests, two live sessions with `/gi ledger mark|check`), rollback, exit criteria, risks, decisions Q-1..Q-10.
- Next: wait for the user's review. NO 3b-2 code. Package for rollback: GoldIntel_Phase2_AddOns.zip (0.3.1) must be kept as GoldIntel_3b1_AddOns.zip when 3b-2 ships.
- Key open question for the user: Q-1 (AH deposit/buy, COD-out and postage in 3b-2 or 3b-4).
- Reload: no addon change this session.

## S-042 | 2026-10-18 | Claude

- Done: increment 3b-1 built (D-074 approved A-1..A-5): Platform adapters, Collect/Context, Collect/Collector, `/gi collect`, contract 1.7, 771 tests green. Packages rebuilt (previous kept as GoldIntel_3b0_AddOns.zip).
- Reload: CLIENT RESTART required (TOC changed). Move GoldIntelDiag out of AddOns for the validation.
- Waiting for: the user's live validation (plan section 7) and review. Report must show loot closes by slot-clear vs timeout (A-4 condition).
- 2026-10-18 13:0x: User APPROVED 3b-1 for live validation and acknowledged P_AH_POSTED, P_MAIL_UPDATE, P_TRADE_CLOSE. Validation focus: 14 events no popup; RegisterUnitEvent behavior; loot closes (clear/replaced/timeout, review before 3b-2 if timeouts frequent); mail snapshot cost; quarantine/failures. 3b-2 waits for the evidence review.
- 2026-10-18 13:2x: live validation part 1 recorded as E-41: 14 events registered, no popup, unit-filter works, off/on clean. LOOT CLOSE ASSUMPTION FAILED (6/6 timeouts, 2 late clears; money arrived 0.150 s after a clear that came 24 s after open). Options sent to the user; no code changed. Mail, trade, quest, auction and mail CPU still unvalidated (other characters).
- 2026-10-18 13:4x: User chose Option 1 (poll LootFrame:IsShown(), long timeout only as backstop). Probe GIProbeLoot run: E-42 recorded. LootFrame:IsShown() verified (8 windows). Implementation NOT yet changed; proposal sent for approval (frame-close signal, linger kept, duplicate clears deduped, timeout backstop, stats by close path).
- 2026-10-18 13:5x: User APPROVED the E-42 change (D-075). Implemented 0.3.1-phase3b1 / contract 1.7.1: Loot close by LootFrame poll, clears informational, 300 s backstop, legacy fallback with separate stats. 790 tests green. Package rebuilt (3b-0 rollback kept). Waiting for the revised validation (loot, mail, trade, quest, auction, mail snapshot CPU).
- 2026-10-18 14:0x: Round 2 part 1 recorded as E-43: loot revision PASSED (7/7 closes by frame, 0 timeouts), vendor off/on clean incl. nothing counted while off, 14 registered, no popup, unit-filter OK. Still unvalidated live: mail (snapshot CPU), trade, quest, auction posting. Per-character file located by the user (E-44): `...\70\Rehgar-Deadeye\SavedVariables`; folders are named First-Last, so the surname-collision risk is low; optional identity stamp left as a user decision, not built.
- 2026-10-18 14:3x: Round 3 recorded as E-45: mail (7 updates, 7 snapshots, 1.1 ms total / 0.3 max), quest, trade x3 (TRADE_CLOSED 5 for 3 windows, TRADE_MONEY_CHANGED 0), auction post all PASSED with 0 errors. 3b-1 closure recommendation written (Phase3b_Increment_3b-1_Closure.md); awaiting the user's decision. 3b-2 NOT started.
- NOT started: 3b-2 (expectations, Reconciler, cash ledger). Do not discuss before the review is approved.
- Risks to review: three extra additive events; RegisterUnitEvent untested live (plain fallback); loot close is a rule; only 4 verified cast spell ids; mail snapshot cost; popup risk for 14 events (journal/quarantine); COD popups user-reported only.

## S-041 | 2026-10-18 | Claude

- Done: parsed Session 23, recorded E-36 (posting event 0.358 s before deposit money; deposit -100; cancel 0; buyout -4 exact (user corrected the price to 4; earlier 13 was a note error); bid untested).
- Update: Sessions 20-22 done (E-37..E-40); D-068 addendum COMPLETE. Old open list: Sessions 20, 21, 22; optional clean buyout repeat / bid test; 3b-1 needs separate go-ahead (not requested).
- Also: wrote Phase3b_Increment_3b-1_Plan.md (D-074 Proposed). 3b-1 code NOT started; waits for the user's A-1..A-5.
- Reload: no addon change this session.

## S-040 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntel 0.2.1-phase3b0, GoldIntelDiag 1.8). Documentation only.

DECISIONS: none new.

DONE: Session 19 recorded as E-35. Listing deposit -100 exact. Cancel: money change 0, deposit forfeited (measured). Buyout plus bid -113 against 114 expected (1 copper unexplained; the 'bought' snapshot was skipped). All AH and send-mail event names valid; bidding exists; owned auctions need a query to read. Session 23 (register AUCTION_HOUSE_AUCTION_CREATED, post, cancel, buyout, bid with money references) written in the lab README.

NOT DONE: Sessions 20, 21, 22, 23 (user). Increments 3b-1..3b-4 not started; 3b-1 needs the user's go-ahead.

USER NEXT: run Session 23 (recommended now, same character) and Sessions 20 to 22; send the file after each.

==================================================

---

## S-039 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: GoldIntel 0.2.1-phase3b0 (contract 1.6), GoldIntelDiag 1.8. Install: /reload is enough for both (no file added or removed).

DECISIONS: D-067 scope and increments, D-068 verification addendum, D-069 architecture and contract package (schema 2, window mode), D-070 AH sale split, D-071 disenchant recorded not revalued, D-072 validation rules (retention from measured size, GoldIntelDiag disabled in live validation, profiling plan, OTHER reported by entries AND value). D-027 and D-028 Approved. All user-approved 2026-10-18 10:58.

DONE: Decisions, Architecture section 19, Contracts Phase 3b additions recorded. Increment 3b-0 built: D-027 patch, collector event allow-list, lab replay helper and evidence-based lag tests, profiling plan. Lab 1.8 with AH, outgoing mail and COD experiments (README Sessions 19 to 22). 565 tests pass.

NOT DONE: lab Sessions 19 to 22 (user); the user's review of 3b-0; increments 3b-1..3b-4 (NOT authorized until reviewed, one at a time). schema 2 and window-mode expectations are approved designs only, no code. A conditional Session 23 (an AH event) is decided after Session 19.

USER NEXT: install both addons (/reload), run Sessions 19, 20, 21, 22 and send the file after each; review 3b-0.

==================================================

---

## S-038 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.7). Documentation only.

DECISIONS: D-066 Approved (Phase 3a closed with exceptions X-A..X-H; XP kill proxy dropped; boat/zeppelin not a gate; D-065 stays).

DONE: D-066 recorded. Phase3b_Scope_and_Readiness.md written (scope, increments, architecture and contract changes, collector design, risks, dependencies, exit criteria, decisions P3B-1..P3B-10).

NOT DONE: the user's review. No Phase 3b code, no Phase 3b implementation until the user explicitly authorizes it.

USER NEXT: review Phase3b_Scope_and_Readiness.md and answer section 9.

==================================================

---

## S-037 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.7). Documentation only.

DECISIONS: none new. Proposed for the user in the closure recommendation: close Phase 3a with listed exceptions.

DONE: Session 18 recorded as E-34. MAIL_CLOSED not delivered (use MailFrame:IsShown polling). Sold-auction invoice readable (price, deposit, cut); deposit is a refund, not income. Phase3a_Closure_Recommendation.md written.

NOT DONE: the user's review of the closure recommendation. No Phase 3b work, no Phase 3b discussion until the user decides.

USER NEXT: review Phase3a_Closure_Recommendation.md and answer its section 6.

==================================================

---

## S-036 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.7). Documentation only.

DECISIONS: none new.

DONE: Session 17 recorded as E-33 (MERCHANT_CLOSED fires on both close routes; duplicates possible).

NOT DONE: Session 18 (MAIL_CLOSED, with X2 on the mailbox holding an AH sale mail, which also covers the sold-auction invoice), then the formal Phase 3a Closure Recommendation. No Phase 3b.

USER NEXT: run Session 18 and send the file.

==================================================

---

## S-035 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.7). Documentation only.

DECISIONS: none new.

DONE: Session 16 recorded as E-32. Quest reward item is detectable by bag diff; quest item removal visible; BAG_UPDATE_DELAYED fires before and after the money event.

NOT DONE: MERCHANT_CLOSED and MAIL_CLOSED lifecycle tests (next), then the formal Phase 3a Closure Recommendation for the user's review. No Phase 3b. Optional: sold-auction invoice, H2 click-through, trade item side, choice reward, stack merge, full bag.

USER NEXT: ask for the MERCHANT_CLOSED and MAIL_CLOSED steps.

==================================================

---

## S-034 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: GoldIntelDiag 1.7 (new read-only experiment Q2: bag snapshot diff and BAG_UPDATE_DELAYED). GoldIntel 0.2.0-phase2 unchanged. 551 tests pass. Reload is enough (no file added).

DECISIONS: none new. D-065 already recorded.

DONE: Q2 built and packaged; Session 16 steps written. User agreed trade (E-31) is sufficient.

NOT DONE: running Q2 (user), MERCHANT_CLOSED, MAIL_CLOSED, formal Phase 3a Closure Recommendation (to be written after the lifecycle tests, for the user's review; no Phase 3b before that). Optional/deferred: sold-auction invoice, H2 click-through, trade item side.

USER NEXT: install 1.7, /reload, run Session 16 (Q2) with a quest that rewards an item, send the file.

==================================================

---

## S-033 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged. Documentation only.

DECISIONS: D-065 APPROVED (reconciliation window 1.0 s, amends D-004).

DONE: recorded in Decisions.md, Architecture.md, Phase3_Planning_Package.md, Compatibility_Notes E-31 wording. No Reconciler code exists, so nothing to change in code.

NOT DONE: quest reward item bag diff (next), MERCHANT_CLOSED, MAIL_CLOSED. No Phase 3b.

USER NEXT: ask for the quest bag-diff steps.

==================================================

---

## S-032 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.6). No code change. README Session 15 rewritten with literal commands after the first attempt captured nothing (my placeholder wording).

DECISIONS: none approved. PROPOSED (needs the user): lengthen the Reconciler match window and context lifetime beyond 0.25 s (trade 0.394 s, mail 0.365 s, loot up to 0.509 s lags after the context signal).

DONE: E-31 (trade). Planning matrix trade row verified.

NOT DONE: quest reward item bag diff (next, user priority 2), MERCHANT_CLOSED, MAIL_CLOSED. Optional: sold-auction invoice, H2 click-through, trade item side. No Phase 3b.

USER NEXT: answer whether the longer match window is approved, then run the quest bag-diff test when its steps are sent.

==================================================

---

## S-031 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.6, GoldIntel 0.2.0-phase2). No code change.

DECISIONS: none new.

DONE: Session 14 recorded as E-30. Item data loads asynchronously; GET_ITEM_INFO_RECEIVED(itemID, success) verified; cold-cache GetItemInfo returns nothing (unknown, not zero); sell price and bind type positions confirmed.

NOT DONE: R1 trade (waiting on the user's choice of option: stranger/guildmate trades, second account, or skip), MAIL_CLOSED / MERCHANT_CLOSED, quest item bag diff, sold-auction invoice (lower priority), H2 click-through. No Phase 3b.

USER NEXT: choose the trade test option; I then rewrite Session 15 as a one-character test.

==================================================

---

## S-030 | 2026-10-18 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.6, GoldIntel 0.2.0-phase2). No code change.

DECISIONS: none new. D-064 point 6 supported by E-29.

DONE: Session 13 file recorded as E-29 (evidence/2026-10-18a). Mail headers readable; auction mail separable from player mail; index not stable; closed-mailbox reads are cached; money-only mail vanishes on take.

NOT DONE: sold-auction invoice fields, MAIL_CLOSED / MERCHANT_CLOSED, I1b, R1, quest item bag diff, H2 click-through (screenshot already reviewed earlier: square drawn, scales with the map, correct place; the uneven fill is probably translucency over terrain). No Phase 3b.

USER NEXT: decide whether to run an auction sale test (list an item on an alt, buy it with another character or let it sell, open the mailbox, run X2) and optionally check whether map pins can be clicked through the H2 square.

==================================================

---

## S-029 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: GoldIntelDiag 1.6 (new read-only probe X2). GoldIntel 0.2.0-phase2 unchanged. 546 tests pass. Packages rebuilt.

DECISIONS: D-064 point 6 (mail metadata may matter for the ledger; mail never affects heat maps).

DONE: X2 built (mailbox header, money, invoice, attachment readers; max 8 mails; never calls GetInboxText). Session 13 steps written.

NOT DONE: running X2 (user), MAIL_CLOSED / MERCHANT_CLOSED, I1b, R1, quest item bag diff. No Phase 3b.

USER NEXT: install the 1.6 zip, put mail in a mailbox (alt transfer, auction mail), run /gidiag lab api X2 mailbox, report, /reload, send the file.

==================================================

---

## S-028 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.5). No code.

DONE: Session 12 recorded as E-28. MAIL_INBOX_UPDATE: payloadless, fires about 0.4 s before the PLAYER_MONEY of a money take, double update on the item take, no close signal.

PROPOSED (not started, needs user go-ahead): lab probe X2, read-only, to see whether inbox headers (sender, subject, money, item count) are readable; needed to tell AH proceeds from player mail.

NOT DONE: MAIL_CLOSED / MERCHANT_CLOSED, I1b, R1, quest item bag diff, AH mail. No Phase 3b.

==================================================

---

## S-027 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.5). No code.

DONE: Session 11 recorded as E-27. Instance run boundaries verified (IsInInstance, GetInstanceInfo 389), no position inside, exit matches entry within about 23 yards, post-loading position samples need a settle rule. D-060 evidence added.

NOT DONE: MERCHANT_CLOSED, I1b, X1, R1, quest item bag diff. No Phase 3b.

USER NEXT: choose the next one-event session (mail, trade, vendor close, item data load).

==================================================

---

## S-026 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.5). No code.

DONE: Session 10 recorded as E-26. Disenchant cast verified (spell 13262, readable, no item named). D-062 Phase 3a evidence complete.

NOT DONE: MERCHANT_CLOSED, I1b, X1, R1, S1 instance, quest item bag diff. No Phase 3b.

USER NEXT: choose the next one-event session (mail, trade, vendor close, item data load, or an instance run).

==================================================

---

## S-025 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.5). No code.

DONE: Session 9 recorded as E-25. Disenchant loot window: Item source GUID, item 10940. Mining third window left as an unexplained but harmless observation (user not certain); rule: credit on slot-cleared, bag diff or money, never on window open.

NOT DONE: disenchant cast (UNIT_SPELLCAST_SUCCEEDED on the enchanter), MERCHANT_CLOSED, I1b, X1, R1, S1 instance. No Phase 3b.

USER NEXT: Session 10 (enchanter cast) and the remaining one-event sessions.

==================================================

---

## S-024 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.5). No code.

DONE: Session 8 recorded as E-24. Repeat-GUID rule proven: a source GUID is not a once-only key (node: one window per harvest; corpse: corpse loot then skin loot, same GUID).

NOT DONE: enchanter (disenchant cast and loot window), skinner note missing from the file, mining shows 3 windows versus the user's 2 logged (unexplained), MERCHANT_CLOSED, I1b, X1, R1, S1. No Phase 3b.

USER NEXT: Session 9 (enchanter) then the remaining one-event sessions.

==================================================

---

## S-023 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.5). No code.

DECISIONS: D-064 / AM-13 (Economic Attribution vs Location Attribution; quest rewards in the ledger, out of heat maps) approved by the user.

DONE: Session 8 step-by-step instructions written (README.txt).

USER NEXT: Session 8 per character (reg LOOT_OPENED, one note, one action, report, /reload), then send the file.

NOT DONE: Phase 3a leftovers (MERCHANT_CLOSED, I1b, X1, R1, S1, disenchant cast). No Phase 3b.

==================================================

---

## S-022 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.5). No code.

DECISIONS: D-063 value views (Verified, Current Market, Account Best; never overwrite history) approved as principle by the user; D-062 updated to reference it. AM-12 added.

DONE: Session 7 recorded as E-23. C1 verified (no popup; player casts readable; others secret in combat; gather spell ids seen).

NOT DONE: disenchant cast (no enchanter data in the file), LOOT_OPENED timing vs gather cast, repeat-GUID skin proof, MERCHANT_CLOSED, I1b, X1, R1, S1. No Phase 3b.

USER NEXT: Session 8 = LOOT_OPENED on a gatherer/skinner: register it, skin the same mob twice (or gather), then on the enchanter disenchant one item (cast event + loot window) in a later session.

BLOCKERS: Phase 3b blocked until Phase 3a reviewed and authorized.

==================================================

---

## S-021 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntelDiag 1.5). No code change.

DONE: Session 6 analysed, recorded as E-22 (evidence/2026-10-17h_*). Q1 verified: QUEST_TURNED_IN args questID, xp, money; money arg equals the following PLAYER_MONEY delta; event first, money 0.041 s later.

NOT DONE: C1, X1, R1, I1b, MERCHANT_CLOSED, repeat-GUID skin proof, S1 instance, quest item reward via bag diff. No Phase 3b.

USER NEXT: Session 7 = C1 (register UNIT_SPELLCAST_SUCCEEDED, gather a herb, an ore, skin a mob, then report/reload/send).

BLOCKERS: Phase 3b blocked until Phase 3a reviewed and authorized.

==================================================

---

## S-020 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: unchanged (GoldIntel 0.2.0-phase2 rebuild 4, GoldIntelDiag 1.5). No code change, no new package.

DECISIONS: user confirmed D-060 and D-061 with details (instance hotspot model; per-run default; per-cycle secondary; Character View default; Account Best optional). Recorded.

DONE: Session 5 analysed, recorded as E-21 (evidence/2026-10-17g_*). M1 show event verified; sale, purchase and repair are separable from income by sign and window; purchase and repair indistinguishable by money alone (both spending).

NOT DONE: MERCHANT_CLOSED (not registered), Q1, C1, X1, R1, I1b, repeat-GUID skin proof, S1 instance. No collector, no Phase 3b.

USER NEXT: Session 6 = Q1 (`/gidiag lab reg QUEST_TURNED_IN`, turn in a quest that gives copper and an item, report, /reload, send file). Then C1, LOOT_OPENED plus skin, MERCHANT_CLOSED, I1b, X1, R1; instance S1 whenever convenient.

BLOCKERS: Phase 3b blocked until Phase 3a results are reviewed and authorized.

==================================================

---

## S-019 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: GoldIntel 0.2.0-phase2 rebuild 4 (unchanged). GoldIntelDiag 1.5 (every `LOOT_OPENED` sample now stores a loot window snapshot: slot type, item id, quantity, source GUID type and id; secret-safe). Tests 543 pass.

DONE: Session 4 analysed, recorded as E-20 (evidence/2026-10-17f_*). L2 verified; LOOT_SLOT_CLEARED can be delivered twice for one slot; herb and mining node loot give GameObject GUIDs; loot data stayed readable while the Combat restriction was active. Signal matrix updated (loot arrival and loot source verified).

DESIGN IMPLICATIONS (recorded only): de-duplicate slot-clear events per window and slot; value still comes from the money delta (D-043); node versus mob is decided by the GUID type; item id comes from the slot link.

NOT DONE: repeat-GUID skinning proof (needs one skin after looting the same mob with lab 1.5 registered on LOOT_OPENED); M1, Q1, I1b, C1, X1, R1; S1 instance. No collector, no Phase 3b.

USER NEXT: Session 5 (M1) per README: `lab reg MERCHANT_SHOW`, open a vendor, sell one item, buy one item, close; report; /reload; send file.

OPEN ISSUES: as before plus the experiments above.

BLOCKERS: Phase 3b blocked until Phase 3a results are reviewed and authorized.

==================================================

---

## S-017 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: GoldIntel 0.2.0-phase2 rebuild 4 (unchanged). GoldIntelDiag 1.4 (restriction state stored with every event sample, API entry and track sample; S1 also calls `GetInstanceInfo()`; P1 also lists `C_EncounterJournal` and `C_AreaPoiInfo`). Tests 540 pass.

DECISIONS RECORDED (user direction, details proposed): D-060 instances as whole runs located at the instance entrance; D-061 heat scope toggle account best versus this character. Requirements AM-10, AM-11; planning addendum A.4; risks R-31..R-33 proposed.

DONE: Session 3 analysed, recorded as E-19. P2: restriction enum Combat 0, Encounter 1, ChallengeMode 2, PvPMatch 3, Map 4, Chat 5; Combat state 0 out of combat and 2 in combat; `HasSecretRestrictions` true in both so it is not a combat indicator; combat log restricted (D-030 consistent). L3: item slot and skinning slot readable, links carry item ids, skinning reports the corpse GUID.

NOT DONE: `LOOT_SLOT_CLEARED` was not registered in Session 3 (L2 no data). S1 instance not run. No collector, no Phase 3b.

ANSWERED (user 17:41, S-018): D-060 and D-061 APPROVED. Defaults: per-run instance statistics and character heat maps. Optional: full-cycle statistics and account-best heat maps. No open questions.

USER NEXT: Session 4 per README: `lab reg LOOT_SLOT_CLEARED`, loot a few mobs slot by slot, `lab api L3` on a mining or herb node if available, report, /reload, send file. Optional: run `lab api S1 instance` after entering any dungeon.

OPEN ISSUES: event experiments L2, M1, Q1, I1b, C1, X1, R1; loot behaviour in combat (restriction state now recorded); OI-8 (largely informed by P2); X-2; PX-1..PX-8; OI-13; OI-9..OI-11; OI-5; A-4.

BLOCKERS: Phase 3b blocked until Phase 3a results are reviewed and authorized.

==================================================

---

## S-016 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: GoldIntel 0.2.0-phase2 rebuild 4 (unchanged). GoldIntelDiag 1.3 (adds probe P2: restriction and state getters). Tests 538 pass.

DONE: Session 2 analysed, recorded as E-18 (evidence/2026-10-17d_*). L1 PASS: LOOT_OPENED registered without popup, non-secret args, precedes PLAYER_MONEY. L3 coin slot and source GUID verified. Taxi landing verified. H2 host works (screenshot). P1 gave function names; `C_RestrictedActions.GetAddOnRestrictionState`, `C_Secrets.HasSecretRestrictions` and `C_CombatLog.IsCombatLogRestricted` exist, so P2 reads them (relevant to OI-8).

DESIGN IMPLICATIONS (recorded only): coin expectation comes from LOOT_OPENED (coin slot amount is the second return of `GetLootSourceInfo`, more robust than parsing "8 Copper"); money delta arrives 0.5 s to many seconds later (manual looting), so the expectation TTL must be generous; items-only loot opens the window with no money change.

NOT DONE: no collector, no Phase 3b.

USER NEXT: Session 3 per README: `lab api P2` (twice: out of combat and in combat), `lab reg LOOT_SLOT_CLEARED`, loot a mob that drops an item with the window open and run `lab api L3`, skin a mob and run `lab api L3` again, report, /reload, send file. Optional: inside an instance `lab api S1 instance`; check whether you can click map pins through the red square.

OPEN ISSUES: remaining event experiments (L2, M1, Q1, I1b, C1, X1, R1); S1 instance; OI-8; X-2; PX-1..PX-8; OI-13; OI-9..OI-11; OI-5; A-4.

BLOCKERS: Phase 3b blocked until Phase 3a results are reviewed and authorized.

==================================================

---

## S-015 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: GoldIntel 0.2.0-phase2 rebuild 4 (unchanged). GoldIntelDiag 1.2 (lab: new probe P1, new experiment I1b, I1 also requests loads for 2589 and 2770). Tests 537 pass.

DONE: Phase 3a Session 1 analysed and recorded as E-17 (evidence/2026-10-17c_*). Signal matrix updated (Phase3_Planning_Package 8.2). Verified: P0 presence, I1 item data (cached only), I2 bags, A1 AFK flag, T1a taxi flag and speed, hearth jump pattern, S1 open world. Failed: H1 subzone names from C_Map (zone only). Open: H2 (user's screenshot of the partly filled red square), S1 instance, taxi landing, I1b async item load, every event experiment.

DESIGN IMPLICATIONS (to carry into any Phase 3b proposal, none implemented): vendor-floor valuation must treat uncached items as unknown and request-load then retry (D-046 holds); never hardcode item ids; hotspot place names come from `GetSubZoneText()` recorded at credit time, not from C_Map; ignore position samples with nil map or a one-sample continent map around loading screens; poll `UnitOnTaxi` and `UnitIsAFK` (no events needed); bag snapshots are cheap.

NOT DONE: no collector, no Phase 3b work.

USER NEXT: Session 2 per GoldIntelDiag/README.txt (reg LOOT_OPENED, loot mobs, `lab api L3`, report, /reload, send GoldIntelDiag.lua) and the H2 screenshot.

OPEN ISSUES: Phase 3a event results; OI-8; X-2 (D-027, D-028); PX-1..PX-8; OI-13; OI-9..OI-11; OI-5; A-4.

BLOCKERS: Phase 3b blocked until Phase 3a results are reviewed and authorized.

==================================================

---

## S-014 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: GoldIntel 0.2.0-phase2 rebuild 4 (unchanged). GoldIntelDiag 1.1 adds `/gidiag lab` (new file `Lab.lua`, hooked from `Diag.lua`).

DONE: Phase 3a task 3a.1. Lab is read-only, writes only `GoldIntelDiagDB.lab`, never touches `GoldIntelDB`, registers at most ONE catalog event per session (plus PLAYER_MONEY as ordering reference), refuses COMBAT_LOG_EVENT_UNFILTERED, records secret payloads as `secret` without reading them, watches ADDON_ACTION_FORBIDDEN, caps 40 samples per event / 400 total / strings 120. Experiments P0 I1 I2 A1 S1 T2 T1a H1 H2 L3 (API) and L1 L2 M1 Q1 X1 R1 T1b C1 C2 (event). Tests: `Tests/test_diag_lab.lua` (36); full suite 535 pass. Packages rebuilt; TOC files verified in both zips; suite passes from the extracted dev zip.

NOT DONE: no collector, no Phase 3b work. GoldIntel addon unchanged.

USER NEXT: run Session 1 (see GoldIntelDiag/README.txt: `/gidiag lab api session1`, `/afk` check, `lab track 120`, `lab square on`, `lab report`, `/reload`), send GoldIntelDiag.lua. Then one event per session.

OPEN ISSUES: Phase 3a results; OI-8; X-2 (D-027, D-028); PX-1..PX-8; OI-13; OI-9..OI-11; OI-5; A-4. Lab behaviour in the real client is unverified (fake-client tests only).

NEXT RECOMMENDED TASK: analyse Session 1 results, record as E-17, then plan the first event session (L1 LOOT_OPENED).

BLOCKERS: Phase 3b blocked until Phase 3a results are reviewed and authorized.

==================================================

---

## S-013 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.2.0-phase2 rebuild 4 (unchanged; documentation only)

DECISIONS RECORDED (user): D-054 Option B (hard + soft travel; `travel.countInGph` false; `TRAVEL` activity; dry window 60 s; stay-near ~150 yd); D-057 relative colour scale default, fixed-threshold option later; D-058 ranked hotspot list in v1; D-059 `/gi overlay on|off|toggle`, settings window to mirror it. Requirements AM-7..AM-9.

NOT DONE: nothing implemented. The next authorized work is unchanged: build `/gidiag lab` (Phase 3a, task 3a.1). Planned setting keys are recorded only, not added to Config (avoids R-24).

OPEN ISSUES: Phase 3a results; OI-8; X-2 (D-027, D-028); PX-1..PX-8; OI-13; OI-9..OI-11; OI-5; A-4. No pending user choices for Phase 3a.

NEXT RECOMMENDED TASK: build the Phase 3a lab and deliver it; user runs session 1 (APIs only).

BLOCKERS: Phase 3b blocked until Phase 3a results are reviewed and authorized.

==================================================

---

## S-012 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.2.0-phase2 rebuild 4 (Contract 1.5; 499 tests pass)

USER DECISIONS RECORDED: Phase 2 CLOSED WITH EXCEPTIONS PX-1..PX-8 (D-056); D-034..D-040 confirmed; session-record design 3.1-3.4 and pin approved with the constraint that records are bounded diagnostic evidence only (D-041); D-043..D-050 accepted (D-049 clarified: idle excluded from all GPH and heat); AFK: waiting counts as idle, `/gi pause|resume|afk` approved (D-055); taxi time must not count and travel must not dilute hotspots, model to be proposed (D-054); heatmap is location-level density, not zone coloring, with an easy overlay toggle (D-052); graphical configuration is the long-term primary UI (D-053); Phase 3a (diagnostics, experiments, signal verification) APPROVED (D-051); Phase 3b NOT approved.

DONE: session records implemented (current, previous, ten-row history, pin), tests, contract 1.5, packages rebuilt; Requirements 1.1.0 amendments; Travel_Model_Options.md; Phase3a_Verification_Protocol.md; Planning package Addendum A (heat cloud design, overlay, GUI); TODO Phase 3a tasks; decisions D-051..D-056.

NOT DONE (next, authorized): build `/gidiag lab` per the protocol (task 3a.1). No collector or GoldIntel behaviour change.

OPEN ISSUES: travel model choice (A/B/C and thresholds); heat colour scale (relative recommended); hotspot list wanted?; overlay command name; Phase 3a results; OI-8, X-2 (D-027, D-028), PX-1..PX-8, OI-13, OI-9..OI-11, OI-5, A-4.

KNOWN RISKS: R-01, R-02, R-03, R-23 (Phase 3b gates), R-21, proposed R-27..R-30; new: overlay coexistence with other map addons is unverified (H2).

NEXT RECOMMENDED TASK: build the Phase 3a lab (diagnostics addon only), deliver the zip, then the user runs Session 1 (APIs only) of the protocol and sends GoldIntelDiag.lua.

BLOCKERS: Phase 3b blocked until Phase 3a results are reviewed and the user authorizes it.

==================================================

---

## S-011 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.2.0-phase2 (rebuild 3; NO code change; planning documents only)

AUTHORIZATION: Phase 2 "substantially validated" (user). Previous-session record principle approved (D-041). Phase 3 PLANNING ONLY approved (D-042). Phase 3 implementation NOT approved.

DELIVERED: Phase2_Closure_Recommendation.md (complete with exceptions PX-1..PX-8); Runtime_Session_Records_Proposal.md (current + previous + 10-row history, optional pin; no schema change); Phase3_Planning_Package.md (value attribution, loot valuation, location credit, activity detection, AFK handling, collector signal selection, verification plan, risks, work breakdown 3a/3b, gate checklist).

KEY POINTS: only money, zone, level, combat, lifecycle and skill events are proven; every other Phase 3 signal is UNVERIFIED, so signals are chosen by experiment (D-050). Value is booked once at acquisition and credited to places only for loot, gathered and fished value (D-043, D-044). Idle uses retroactive subtraction (D-049). Architecture 8 must say "value credited", not "copper credited" (proposed amendment, not applied).

FILES CREATED: the three documents above. FILES MODIFIED: Decisions (D-041..D-050), Risk_Register (R-27..R-30 proposed), TODO (2.9, 2.10), Changelog, Project_Bible inventory, Session_Handoff.

DECISIONS MADE: D-042 (user). Proposed: D-041 design, D-043..D-050.

OPEN ISSUES: Phase 2 closure answer; D-034..D-040 confirmation; session-record design approval and pin yes/no; D-043..D-050; Q-AFK-1..3; whether to authorize Phase 3a (verification-only diagnostics); OI-8, X-2 (D-027, D-028), OI-12 remainder (PX-1..PX-3), OI-13, OI-9..OI-11, OI-5, A-4.

KNOWN RISKS: R-01, R-02, R-03, R-23 (Phase 3 gates); R-21; proposed R-27..R-30.

NEXT RECOMMENDED TASK (user): answer the questions at the end of each document. If approved, implement the session-record change (small, Phase 2 maintenance). Do NOT start Phase 3 until separately authorized.

BLOCKERS: Phase 3 implementation blocked by OI-8, X-2 and the lack of approval.

==================================================

---

## S-010 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.2.0-phase2 (rebuild 3, unchanged; documentation only)

TRIGGER: the user ran the V3/V5/V8 test round and sent chat text plus both SavedVariables files, then asked how the map overlay, AFK handling and item valuation will work.

FINDINGS (E-15): PLAYER_MONEY, PLAYER_LEVEL_UP delivered with usable payloads; ZONE_CHANGED, ZONE_CHANGED_NEW_AREA, combat delivered; ZONE_CHANGED_INDOORS not seen; `idleSec = 240` persisted; `/gidiag run` clean. The saved files cover only the short post-`/reload` session because `runtime` is overwritten on every open (design weakness of D-040).

DESIGN QUESTIONS ANSWERED IN CHAT (no decision recorded; all already covered by Architecture 8, 9, 7.5 and FR-SES-3/4): heat bins credit value created at the loot location, idle excluded from seconds, manual pause plus automatic idle, vendor-price floor and pluggable auction price providers. Gap noted: Architecture 8 says bins credit "copper"; it must say value created (gold plus valued items). To be corrected when the user approves Phase 3 planning.

OPEN ISSUES: OI-12 (ZONE_CHANGED_INDOORS, `/gidiag copy`, blocked-event case), OI-13, OI-8 (blocks Phase 3), OI-9, OI-10, OI-11, OI-5, X-2, A-4; D-034..D-040 await confirmation.

NEXT RECOMMENDED TASK (user): decide Phase 2 closure; decide whether to keep the previous session's snapshot (`runtime.previous`); approve or defer Phase 3 planning. Phase 3 is NOT approved.

BLOCKERS: Phase 3 blocked by OI-8 and no approval.

==================================================

---

## S-009 | 2026-10-17 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.2.0-phase2 (rebuild 3; version string unchanged)

TRIGGER: the user ran the full test round on build 70450 and sent GoldIntel.lua and GoldIntelDiag.lua ("no errors").

WHAT THE EVIDENCE SHOWS (E-14, raw files in evidence/):
- The 21 installed files match the package; all compile in the live client; `store=ok schema=1 opens=4`; `diag=0`; command output was captured in `runtime.output` (D-040 works live).
- Delivered now: PLAYER_REGEN_DISABLED, PLAYER_REGEN_ENABLED (about 25 s of combat), SKILL_LINES_CHANGED x3, plus the lifecycle events. Not triggered: PLAYER_MONEY, ZONE_CHANGED*, PLAYER_LEVEL_UP (delivered=0 is "not seen yet", not a failure).
- LibStub was nil: all `lib.*` absent, addon still operational (D-039 holds).
- `profile` is empty, so settings persistence (V5) is still untested. `/gidiag` transcript holds only `compile`.
- Usability bug of mine: `/gi debug ticks` gave no echo without `/gi debug on`; message fixed.

FILES MODIFIED: Core/Slash.lua, Tests/test_commands.lua, packages rebuilt (483 tests pass), Compatibility_Notes, Phase2_Runtime_Validation_Plan, Risk_Register, TODO, Changelog, Session_Handoff, evidence/README. FILES CREATED: two evidence files.

DECISIONS MADE: none. No scope change; Phase 3 not started.

OPEN ISSUES: OI-12 (V3 money/zone/level, V5, V8 run, blocked case), OI-13, OI-8 (blocks Phase 3), OI-9, OI-10, OI-11, OI-5, X-2 (D-027, D-028), A-4; D-034..D-040 still await explicit confirmation.

KNOWN RISKS: R-26 blocked case unobserved; R-25 partly validated; R-21 saved data only at logout/reload; R-01/R-02 Phase 3 gates.

NEXT RECOMMENDED TASK (user): install the rebuilt zip; sell or buy one item; walk across a subzone border; `/gi debug on`; `/gi caps events`; `/gi config set idleSec 240`; `/reload`; `/gi config`; `/gidiag run`; log out; send GoldIntel.lua and GoldIntelDiag.lua. Then decide Phase 2 closure. Phase 3 requires OI-8 resolved and explicit approval.

BLOCKERS: none for validation; Phase 3 blocked by OI-8 and lack of approval.

==================================================

---

## S-008 | 2026-10-15 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.2.0-phase2 (rebuild 2; code changed slightly, version string unchanged)

TRIGGER: the user ran the Phase 2 build in the real client (build 70374), saw many `nil` in `/gi caps events`, `/gi diag` empty, logged out, and pasted GoldIntel.lua. They asked whether chat text can be copied or is logged.

WHAT THE EVIDENCE SHOWS (extract: evidence/2026-10-15_Phase2_first_live_session_EXTRACT.md):
- The Store works live: the real Phase 1 database migrated schema 0 to 1, history recorded, all sections created, compat present, opens=1, lastBuild=70374.
- Core started cleanly (no diagnostics). Snapshot and checkpoint were written at PLAYER_LOGOUT and reached the saved file: logout-time persistence works.
- `IsEventRegistered` returned true for all 12 registered events (positive case confirmed; blocked case untested). Delivery seen: PLAYER_LOGIN, PLAYER_ENTERING_WORLD, SKILL_LINES_CHANGED (fires at login), PLAYER_LEAVING_WORLD, PLAYER_LOGOUT. Not triggered: money, level-up, regen, zone events.
- The `nil` was correct behavior ('not seen yet') but a poor display. Build 70374 is a hotfix of 70338 with identical capabilities and the same Interface 16001.
- Bugs of mine found: stale `P.CONTRACT_VERSION` (probe printed 1.1); the `nil` display.

CHANGES: contract constant fixed (1.4); `/gi caps` wording; output recording into runtime.output (D-040); `Capabilities.Touch`; 6 tests (482 pass). Packages rebuilt and verified from the extracted zips.

COPY/PASTE ANSWER GIVEN: output is now saved automatically in the SavedVariables file; also `/gidiag copy` (untested live), screenshots, `/chatlog` (unsure whether addon print lines are logged).

FILES MODIFIED: Platform/Platform.lua, Core/Capabilities.lua, Core/Slash.lua, tests (platform, capabilities, commands, integration); Compatibility_Notes, Risk_Register, Decisions (D-040), Contracts (1.4), Phase2_Runtime_Validation_Plan, TODO, Changelog, Session_Handoff. FILES CREATED: evidence extract. Packages rebuilt.

DECISIONS MADE: D-040 (mine, pending confirmation). No scope change; Phase 3 not started.

OPEN ISSUES: OI-12 (remaining live steps V3, V4 second session, V5, V7, V8, blocked-event case), OI-13 review documents, OI-8 (blocks Phase 3), OI-9, OI-10, OI-11, OI-5, X-2 (D-027, D-028), A-4.

KNOWN RISKS: R-26 now only the blocked case; R-25 partly validated; R-21 saved data is written only at logout/reload (output lines can be lost on a crash); R-01/R-02 Phase 3 gates.

NEXT RECOMMENDED TASK (user): install the rebuilt zip; do the V3 actions (sell something, cross a subzone, enter and leave combat), then `/gi caps events`, `/gi config set idleSec 240`, `/reload`, `/gi config`, `/gi db`; then send GoldIntel.lua (it now includes `runtime.output`) and say whether `/gidiag copy` opened.

BLOCKERS: none to continue validation; Phase 3 blocked by OI-8 and approval.

==================================================

---

## S-007 | 2026-10-10 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.2.0-phase2

SCOPE: Phase 2 = Core + Store, authorized by the user (D-033). Phase 3 not started; no collector, auction scanner, attribution or activity detection exists.

WHAT WAS BUILT (all in GoldIntel/, contracts F2a, F3a, F10-F13):
- Core: module and service registry with dependency-ordered, failure-isolated lifecycle; startup orchestration; minimal mode when the platform is not operational; `/gi` installed in minimal mode at load and fully at Core.Start.
- Bus: typed internal bus; Phase 2 events plus reserved events for later phases, including the four SEPARATE money pipeline stages (observation, detection, attribution, reconciliation).
- Capabilities: stage model valid/registered/delivered/payloadUsable for events, present for APIs; only payloadUsable/present counts as dependable; throttled snapshot into GoldIntelDB.runtime.
- Config: typed, validated, persisted settings; `/gi config`.
- Store: SavedVariables via Platform adapter; schema 1; staged atomic migrations; compat guaranteed untouched (identity kept, deep-equality checked); read-only mode for newer data; degraded mode on failure; meta and history; per-character table; size estimates; Pruner plans only.
- Platform additions: SavedVars and Slash adapters; registration verification (E1) with delivery counters and payload reports; TRUSTED_EVENTS fail-safe.
- Commands: /gi, help, status, version, probe, diag, debug, caps, config, db, modules, checkpoint.
- Future placeholders (D-015). No library used anywhere above Platform/.

VERIFICATION: 476 automated tests pass (Lua 5.3); real captured Phase 1 database used as a fixture; 7 mutation checks of the Phase 2 guarantees all caught; Diag addon smoke-tested including sandbox isolation; zips rebuilt and verified (every TOC file present; tests pass from the extracted dev zip). NOT verified: anything in the real client.

EXTERNAL REVIEW FINDINGS (D-032): six relayed findings, all accepted (one scoped to events); see reviews/External_Review_Log.md. The review documents themselves were not provided (OI-13).

FILES CREATED: Platform/SavedVars.lua, Platform/Slash.lua; Core/{Core,Bus,Capabilities,Config,Slash,Boot}.lua; Store/{Migrations,Store,Pruner}.lua; Future/{CommunityDataEngine,RouteEngine}.lua; 11 test files, Tests/helpers/svsim.lua, Tests/fixtures/forever_1.60.1_GoldIntelDB.lua; GoldIntelDiag/SrcCurrent.lua; GoldIntel_Docs/Phase2_Runtime_Validation_Plan.md, reviews/{README.md,External_Review_Log.md}; GoldIntel_Phase2_AddOns.zip, GoldIntel_Phase2_Dev.zip
FILES MODIFIED: Platform/{Platform,Events,Money,Unit,Probe}.lua, GoldIntel.toc, test files touched by the moved `/gi` and registration verification, GoldIntelDiag/{Diag.lua,GoldIntelDiag.toc,README.txt,MANIFEST.txt}, tools/build_package.py; Architecture (12, 18), Contracts (1.3), Decisions (D-033..D-039), Risk_Register, Compatibility_Notes, Project_Bible (inventory), TODO, Changelog, Session_Handoff

DECISIONS MADE: D-033 (user, Approved). Approved-pending-confirm (mine): D-034 stage model + scoped Platform change, D-035 pipeline vocabulary, D-036 Store design, D-037 adapters and boot order, D-038 Config, D-039 no library dependency. Assumptions flagged in D-033: the authorization is read as accepting D-022/24/25/26; D-027 and D-028 stay Proposed and are untouched.

TODO ITEMS COMPLETED: 2.1 to 2.7. PENDING: 2.8 live validation.

OPEN ISSUES: OI-12 (live Phase 2 validation), OI-13 (review documents), OI-8 (blocks Phase 3), OI-9, OI-10, OI-11, OI-5, X-2 (D-027, D-028), A-4.

KNOWN RISKS (Risk_Register.md): R-26 `IsEventRegistered` behaves differently live (mitigated by TRUSTED_EVENTS but unproven), R-25 nothing of Phase 2 has run live, R-19 migration cost at login (small today), R-21 client writes saved data only at logout/reload, R-23 stage levels misread as dependable, R-01 17 unverified events behind the earlier popup (Phase 3 gate), R-02 no combat log.

NEXT RECOMMENDED TASK (user): run Phase2_Runtime_Validation_Plan.md steps V1 to V8 (V2 is the important new unknown) and send GoldIntel.lua and GoldIntelDiag.lua plus any popup text; add the ChatGPT and Gemini review documents to reviews/. Then decide Phase 2 closure. Before ANY Phase 3 work: resolve OI-8 (per-event `/gidiag reg` tests, restriction namespaces F1, secret values in combat F3), decide D-027 and D-028, and obtain explicit Phase 3 approval.

BLOCKERS: none for you to start validating. Phase 3 is blocked by OI-8 and by lack of approval.

NOTE FOR THE NEXT AI: Store must never touch GoldIntelDB.compat (D-036); only Platform/Events.lua may call RegisterEvent; never register COMBAT_LOG_EVENT_UNFILTERED; the four money pipeline stages stay separate (D-035); Contracts.md changes in the same change as code (D-031); do not start Phase 3 without explicit user approval; tests assume Lua 5.1 semantics (no long brackets, goto, //, table.unpack).

==================================================

---

## S-006 | 2026-10-10 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.1.2-phase1-runtime (governance documents only; no code, architecture or requirement change)

SCOPE: the user announced a multi-review model. No action was requested; I recorded it so future AIs and sessions inherit it (the project forbids relying on conversational memory).

GOVERNANCE NOW IN FORCE (D-032, Project_Bible.md section 2.1):
- User: sponsor, project manager, client tester, final decision authority.
- Claude: lead architect and lead developer; source of truth for requirements, architecture, contracts, code, changelogs, governance documents.
- ChatGPT: independent reviewer (risk, architecture, runtime evidence, phase gates). Gemini: platform and WoW Forever compatibility analyst, research and alternate-design reviewer. Neither implements; neither approves phase gates.
- Every external finding: accepted, rejected or partially accepted with technical justification; architecture is never changed solely because another AI suggested it; accepted changes follow the Decisions/migration rules and the user's approval.
- External review documents are stored unedited in `GoldIntel_Docs/reviews/` (not created yet; created with the first review); a finding log starts then.

FILES MODIFIED: Project_Bible.md, Decisions.md (D-032), Changelog.md, Session_Handoff.md. Dev zip rebuilt.
FILES CREATED: none.
DECISIONS MADE: D-032 (approved by the user).
TODO ITEMS COMPLETED: none. Phase status unchanged: Phase 1 live-validated, recommendation complete with exceptions; Phase 2 not approved; conditions X1-X5 and the open issues from S-005 are unchanged.
OPEN ISSUES: unchanged (OI-5, OI-8, OI-9, OI-10, OI-11, X-1, X-2, A-4).
KNOWN RISKS: unchanged (Risk_Register.md). New process note: conflicting reviewer inputs need an explicit recorded verdict, not silent adoption.
NEXT RECOMMENDED TASK: unchanged (user answers X1-X3, runs F1-F4, decides on Phase 2). When a ChatGPT or Gemini review arrives, store it in `reviews/`, answer each finding with a verdict and justification, and update Decisions/Risk Register only for accepted items.
BLOCKERS: none new.

==================================================

---

## S-005 | 2026-10-10 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.1.2-phase1-runtime (documentation updated; NO CODE CHANGE)

SCOPE: Phase 1 post-validation review using the user's real-client SavedVariables as primary evidence. The user said: do NOT start Phase 2.

CONCLUSIONS:
- Phase 1: COMPLETE WITH EXCEPTIONS (recommendation; closure is the user's decision). The formal exit test is met.
- OI-1: CLOSE as scoped. Residual unknowns moved to OI-8 (restriction model, Phase 3 signals), OI-9 (live Unit/Map event validation), OI-11 (beta to launch drift).
- Phase 2 (Core + Store): CONDITIONAL GO (conditions X1-X5 in TODO.md). Phase 3: NO-GO until OI-8.
- Architecture confidence: about 70% (was 50-55%), my judgment.
- Evidence tiers: files prove build 1.60.1/70338, Interface 16001, Lua 5.1, 272 namespaces, 35 ok / 4 missing / 1 unknown capabilities, 8/8 compile, SavedVariables persistence, 12 registrations returned normally. The user reported (not in files): money deltas, no popup. Not evidenced: P_ZONE/P_TICK/P_LEVEL/P_PROFS/P_COMBAT live, own Player()/Where()/profession output, combat/instance/AH/mail/trade behavior, performance.

KEY FINDINGS (details in Phase1_PostValidation_Review.md):
- Interface number tracks the client version (1.60.1 -> 16001): TOC churn each patch.
- Modern API, Classic Era content (map IDs 1454/1414), WOW_PROJECT_ID 18, named beta realm, Lua 5.1 (`load` is nil).
- Legacy professions/auction/trade-skill APIs absent; modern AH splits commodity and item deposits.
- The combat log is avoided by policy, NOT observed restricted. `Events.Bind` cannot detect a silently blocked registration (exception E1).
- Secret values exist; all readings were from an idle city.

FILES CREATED: GoldIntel_Docs/Phase1_PostValidation_Review.md, Compatibility_Notes.md, Risk_Register.md, evidence/ (2 SavedVariables files + README)
FILES MODIFIED: Decisions.md, Contracts.md (1.2), Architecture.md (pointers), TODO.md, Changelog.md, Project_Bible.md (inventory), Session_Handoff.md. GoldIntel_Phase1_Dev.zip rebuilt with the updated documents.

DECISIONS MADE: none approved. PROPOSED: D-027 (modern-API-only adapters, remove legacy), D-028 (interface number policy), D-029 (Phase 3 per-event gate), D-030 (no combat-log dependency), D-031 (evidence and documentation discipline). OI-1 closed as scoped; OI-7 merged into OI-8.

TODO ITEMS COMPLETED: Phase 1 formal exit test satisfied (per user report); E4 (contracts catch-up).

OPEN ISSUES: OI-5 (merge outside documents), OI-8, OI-9, OI-10, OI-11, X-1 (confirm D-022/24/25/26), X-2 (decide D-027/D-028), A-4.

KNOWN RISKS: see Risk_Register.md (R-01..R-18). Top: R-01 unverified Phase 3 events, R-02 no combat log, R-03 secret values in combat, R-08 beta to launch drift, R-09 unverified registration.

NEXT RECOMMENDED TASK (user): answer X1-X3 (confirm no popup/no error; confirm or change D-022/24/25/26; decide D-027 and D-028). Optionally authorize a small Phase 1 closing patch: E1 (IsEventRegistered check) and E2 (diagnostics-only live capture of Unit/Map events and Player()/Where()/professions). Run the follow-up diagnostics F1-F4 (review section 14), including F3 in combat and in an instance, and `/gidiag reg COMBAT_LOG_EVENT_UNFILTERED`. Then approve Phase 2 explicitly.

BLOCKERS: none for a Phase 2 approval once X1-X3 are answered. Phase 3 is blocked by OI-8.

NOTE FOR THE NEXT AI: do not start Phase 2 without explicit user approval. Do not add legacy adapters. Never register `COMBAT_LOG_EVENT_UNFILTERED`. Update Contracts.md in the same change as code (D-031). Treat Compatibility_Notes.md as the authority on client facts.

==================================================

---

## S-004 | 2026-10-09 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.1.2-phase1-runtime

SCOPE: Phase 1 runtime compatibility patch only. User instruction: do NOT start Phase 2.

REAL-CLIENT FINDINGS (from the user):
- The original "Error loading" was folder structure. It loads far enough to execute now.
- New blocker: ADDON_ACTION_FORBIDDEN, GoldIntel tried to call Frame:RegisterEvent(); stack points at Probe.lua event-capability probing. The event name was not reported.
- GIMin: "Error loading GIMin/Sub/Back.lua" and ".../Fwd.lua": those files were not in the delivered package.

AUDIT RESULTS:
1. Probe.lua: probed 29 event names by RegisterEvent on a throwaway frame, relying on pcall. Illegal pattern: restricted events are blocked with a popup that pcall cannot suppress. COMBAT_LOG_EVENT_UNFILTERED was in the list (prime suspect, not proven; I had even flagged it as possibly restricted in the diagnostics and still registered it).
2. Is probing RegisterEvent legal? Registering ordinary events is legal; probing availability by registering is not safe. Use C_EventUtils.IsEventValid (names) and never register restricted events.
3. GIMin TOC: correct. It lists Sub\Back.lua, Sub/Fwd.lua, Sub/Block.lua on purpose (path-style test). The files existed in my outputs but I never presented them.
4. Missing package files: GIMin/Sub/Back.lua, Fwd.lua, Block.lua; GoldIntelDiag/SrcV010.lua, SrcV011.lua were never delivered; the patched Platform files were not re-delivered in S-003 (only the TOC). Root cause of ALL load failures: my loose-file delivery. Fixed by D-026 (zip packages + TOC verification tool).

FILES CREATED: tools/build_package.py; GoldIntel_Phase1_AddOns.zip; GoldIntel_Phase1_Dev.zip; GoldIntelDiag/SrcV012.lua (replaces SrcV010/011)
FILES MODIFIED: GoldIntel/Platform/{Platform,Events,Probe,Money,Unit,Map}.lua; GoldIntel.toc (version); Tests (fake_wow, boundary, platform, events, probe, integration, money, unit, map); GoldIntelDiag/{Diag.lua,GoldIntelDiag.toc,README.txt,MANIFEST.txt}; GIMin/README.txt; Phase1_Client_Diagnostics.md (1.1.0); Phase1_Compat_Analysis.md (addendum); Decisions, TODO, Changelog, Session_Handoff

DECISIONS MADE: D-025 event registration/probing policy; D-026 delivery policy (both approved-pending-confirm); OI-6 resolved; OI-7 opened

TODO ITEMS COMPLETED: none new; Phase 1 stays open pending the real-client re-test

OPEN ISSUES:
- OI-7: which events are restricted for addons in WoW Forever. Unknown. v0.1.2 registers exactly 12 events (PLAYER_LOGIN, PLAYER_ENTERING_WORLD, PLAYER_LEAVING_WORLD, PLAYER_REGEN_DISABLED/ENABLED, PLAYER_LOGOUT, PLAYER_LEVEL_UP, SKILL_LINES_CHANGED, ZONE_CHANGED, ZONE_CHANGED_INDOORS, ZONE_CHANGED_NEW_AREA, PLAYER_MONEY); none confirmed non-restricted in the real client.
- OI-1 probe data; OI-5; confirmations of D-022, D-024, D-025, D-026; A-4.

KNOWN RISKS:
- If the popup recurs, one of the 12 registered events is restricted: send `/gi status` (shows lastRegister=) and run `/gidiag reg NAME`.
- Secret-value guards (D-025 item 5) are defensive and unverified.
- Phase 3 cannot use COMBAT_LOG_EVENT_UNFILTERED; kill/activity detection needs another signal; decide before Phase 3.
- Tests run on Lua 5.3 only; the fake client mirrors my assumptions (the forbidden-event trap is modeled on the described behavior, not observed).
- This is the third consecutive failure caused partly by unverified assumptions about the client. Prefer adding one verified step at a time.

NEXT RECOMMENDED TASK (user):
1. Delete old GoldIntel, GIMin, GoldIntelDiag folders. Extract GoldIntel_Phase1_AddOns.zip into the AddOns folder (verify layout: GoldIntel/Platform/*.lua, GIMin/Sub/*.lua, GoldIntelDiag/SrcV012.lua).
2. Log in. Expect no popup. Run `/gi status`, then `/gi probe` and send both outputs.
3. `/gi debug on`, change gold, expect `[evt] P_MONEY`; `/gi debug off`.
4. `/gimin` and `/gidiag all` (then `/gidiag copy`); send outputs.
5. Next AI: interpret; if clean, ask the user to confirm Phase 1 exit test; do not start Phase 2 without approval.

BLOCKERS: real-client re-test results; Phase 2 not approved.

==================================================

---

## S-003 | 2026-10-09 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.1.1-phase1-compat

SCOPE: Phase 1 compatibility fix only. The user said: do NOT begin Phase 2; no new functionality.

FINDINGS FROM THE FIRST REAL-CLIENT TEST (reported by the user):
- Interface 11508 was rejected; 16001 works (WoW Forever is a modern, 12.0-based client). Recorded as D-023.
- With 16001 the addon appears, but FrameXML.log reports "Error loading" for all 8 Platform files (TOC lines 18-25), no stack trace. A trivial addon loads.
- The log's TOC line numbers (18-25) do not match the delivered TOC (20-27): the deployed TOC was NOT byte-identical to the delivered one.

FILES CREATED:
- GoldIntelDiag/ (GoldIntelDiag.toc, Diag.lua, SrcV010.lua, SrcV011.lua, MANIFEST.txt, README.txt)
- GIMin/ (GIMin.toc, GIMin.lua, Sub/Back.lua, Sub/Fwd.lua, Sub/Block.lua, README.txt)
- GoldIntel_Docs/Phase1_Compat_Analysis.md
- GoldIntel_Docs/Phase1_Client_Diagnostics.md

FILES MODIFIED:
- GoldIntel/GoldIntel.toc; GoldIntel/Platform/{Platform,Clock,Events,Scheduler,Unit,Map,Money,Probe}.lua (comment style only; Platform.lua also P.VERSION)
- GoldIntel/Tests/test_platform_boundary.lua (rules C-1..C-5)
- Decisions.md, TODO.md, Changelog.md, Architecture.md (11.1 note), Project_Bible.md (known facts), Session_Handoff.md

DECISIONS MADE: D-023 (target client: Interface 16001, modern 12.0-based; approved by user evidence); D-024 (client compatibility rules C-1..C-5; AI decision, approved-pending-confirm)

TODO ITEMS COMPLETED: none new. Phase 1 stays open: real-client test #1 failed; fix unverified.

ROOT CAUSE: NOT PROVEN (OI-6). Static audit found no 5.1 or 12.0 incompatibility in the delivered code. Evidence points to a file-level cause (path/layout, altered or damaged files, TOC) over a syntax or API cause. Ranked causes with estimates and a decision tree are in Phase1_Compat_Analysis.md sections 5 and 8. Key reasoning: Platform.lua and Clock.lua execute no WoW API at load, so API incompatibility cannot explain "Error loading" for them.

OPEN ISSUES:
- OI-6: cause of "Error loading". Resolve with the steps below.
- OI-1: probe data (interface now known). `/gidiag all` or `/gi probe` output still needed.
- OI-5, D-022 and D-024 confirmations, A-4 (unchanged).

KNOWN RISKS:
- The patch (comment style, minimal TOC) may not fix the problem if the cause is deployment or file integrity.
- Tests run on Lua 5.3 only. The 5.1-only hazards (nested long brackets, break placement, ambiguous calls) were audited by script, not executed on 5.1.
- Unverified 12.0 behaviors that affect later phases: COMBAT_LOG_EVENT_UNFILTERED availability, secret values on GUID/money, whether registering an unknown event raises an error (Events.Bind and Probe assume it does), auction API shape.
- GoldIntelDiag `/gidiag run` executes GoldIntel inside a sandbox; it registers event frames until /reload but does not write the real GoldIntelDB.

NEXT RECOMMENDED TASK (user, in this order):
1. Install GoldIntelDiag; run `/gidiag compile`; send the output. If it prints FAIL lines, the message is the real cause.
2. Hash your deployed GoldIntel files against GoldIntelDiag/MANIFEST.txt (certutil -hashfile <file> SHA256) and compare the folder layout with Phase1_Compat_Analysis.md section 7. Delete the old GoldIntel folder, copy the v0.1.1 folder as a whole, `/reload`.
3. Install GIMin; run `/gimin`; send the output.
4. Run `/gidiag all` then `/gidiag copy`; send the output (answers OI-1).
5. Optional: `/console scriptErrors 1` then `/reload` for the real error popup (Phase1_Client_Diagnostics.md 0.1).
Then a next AI session: interpret results, fix remaining Phase 1 issues, and only after the in-client exit test passes and the user approves, consider Phase 2.

BLOCKERS: waiting on the in-client results above. Phase 2 is not approved.

NOTE FOR THE NEXT AI: do not re-add `--[[ ]]` comments, backslashes in the TOC, or TOC comment lines (D-024). The user's message ended mid-sentence ("Assume Forever is closer to"); the intended comparison was not received. I assumed the modern retail 12.0 client.

==================================================

---

## S-002 | 2026-10-09 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.1.0-phase1

FILES CREATED (addon folder GoldIntel/):
- GoldIntel.toc
- Platform/Platform.lua, Clock.lua, Events.lua, Scheduler.lua, Unit.lua, Map.lua, Money.lua, Probe.lua
- Tests/run.lua; Tests/helpers/testlib.lua, fake_wow.lua, loader.lua
- Tests/test_platform_boundary.lua, test_platform.lua, test_clock.lua, test_events.lua, test_scheduler.lua, test_unit.lua, test_map.lua, test_money.lua, test_probe.lua, test_integration.lua

FILES MODIFIED (GoldIntel_Docs/):
- Decisions.md (D-020, D-021, D-022 added; D-012, D-013 confirmed; D-019 superseded; open-items table)
- Requirements_v1.md (section 9 assumption statuses)
- Contracts.md (1.0.0 to 1.1.0, additive)
- TODO.md (Phase 1 status)
- Changelog.md (0.1.0-phase1 entry)
- Session_Handoff.md (this section)

DECISIONS MADE:
- D-020 Implementation approved for Phase 1 only (user)
- D-021 Ace3 / HereBeDragons optional, must degrade gracefully (user, OI-3)
- D-012 and D-013 confirmed by the user (OI-2, OI-4)
- D-022 Phase 1 implementation conventions (AI decision, Approved-pending-confirm): env injection, shared namespace, no bundled libs and no embeds.xml yet, placeholder interface number, temporary /gi in Probe.lua, Probe persists to GoldIntelDB.compat, additive contract changes (1.1), tests authored for Lua 5.1 and run on 5.3

TODO ITEMS COMPLETED: 1.1, 1.2, 1.3, 1.4, 1.5 (code and automated tests). Phase 1 exit test: automated part done; in-client part PENDING.

HOW TO RUN THE TESTS: `cd GoldIntel && lua Tests/run.lua` (any Lua 5.1+; authoring environment used `texlua Tests/run.lua`, which is Lua 5.3). Expected: `224 passed, 0 failed`. Optional filter: `lua Tests/run.lua money`.

OPEN ISSUES:
- OI-1 (kept open by user): no Forever probe data yet. The .toc interface number 11508 is a placeholder; the whole Platform has never run in a real client.
- OI-5: pre-existing documents from other AI sessions have not been merged.
- D-022 awaits the user's explicit confirmation (user may overrule any item).
- A-4 (subzone key = mapID + localized text + locale) still unconfirmed.

KNOWN RISKS (read before Phase 2):
- API names and return orders (GetSkillLineInfo, C_Map.GetPlayerMapPosition returning a Vector2D, PLAYER_LEAVING_WORLD, C_Timer.NewTicker, GetProfessions) follow Classic-era conventions and are UNVERIFIED for Forever. Every use is guarded (pcall, capability flags), so the failure mode is a disabled feature, but behavior is unproven.
- Professions via skill lines recognize only enUS header names ('Professions', 'Secondary Skills') unless `Platform.Unit.SetProfessionHeaders` is called; other locales get an empty set plus one warning.
- Skill-line reading temporarily expands collapsed headers and restores them (touches the player's skills pane state for a moment).
- `Loc.mapID` can be nil (no C_Map). Phase 3+ code must key places by zone text in that case.
- Money: a `P_MONEY` with `gap = true` means money changed without an event (seen at PLAYER_ENTERING_WORLD). The Reconciler (Phase 3) MUST tag it OTHER with low confidence, never attribute it to the active activity.
- Money relies on PLAYER_MONEY firing at all; if the Forever client uses a different event, `money.event` is false and the addon disables itself with a message (by design, D-016).
- Tests ran on Lua 5.3, not 5.1. The lint test forbids goto, table.unpack and `//`, but a real 5.1 run has not happened.
- The fake client mirrors my assumptions about the API; passing tests prove the logic, not the assumptions.

NEXT RECOMMENDED TASK (needs the user, in this order):
1. Install the `GoldIntel` folder in the Forever beta client's AddOns directory, enable "Load out of date AddOns", log in.
2. Run `/gi probe` and paste the output (this answers OI-1). Also report any Lua errors at login.
3. Run `/gi debug on`, change your gold (vendor something), confirm a line like `[evt] P_MONEY copper=... gt=...` appears; `/gi debug off`.
4. Then record approval for Phase 2 (Core and Store) in TODO.md. The next AI should first fix the interface number and any adapter order issues revealed by the probe.

BLOCKERS:
- None for code. Phase 1 cannot be declared complete without the in-client check (step 2 and 3 above).
- Phase 2 is not approved (D-020 covers Phase 1 only).

PHASE 2 CARRY-OVER (also in TODO.md): move `/gi` to Core/Slash.lua and delete `Probe.Slash` and its registration; Store must preserve `GoldIntelDB.compat` and treat a DB with `compat` but no `schema` as a fresh schema-1 DB; add embeds.xml only when libraries are bundled.

==================================================

---

## S-001 | 2026-10-09 | Claude

==================================================
SESSION HANDOFF
==================================================

VERSION: 0.0.1-planning (documents only; no code)

FILES CREATED:
- Project_Bible.md 1.0.0
- Requirements_v1.md 1.0.0
- Decisions.md 1.0.0
- Changelog.md
- TODO.md 1.0.0
- Session_Handoff.md (this file)
- Architecture.md 1.0.0
- Contracts.md 1.0.0

FILES MODIFIED: none (no prior project documents were provided; all of the above are new baselines)

DECISIONS MADE:
- D-001..D-011, D-014..D-018: recorded as Approved (blanket approval stated in the charter; originate from the Part 2 review of the design spec)
- D-012 (Cash / Wealth / Net GPH definitions): Approved-pending-confirm
- D-013 (v1 scope aligned to charter; items outside the charter's v1 list deferred): recorded; needs confirmation (OI-4)
- D-015 (CommunityDataEngine and RouteEngine stubs only)
- D-019 (planning phase; implementation not yet approved)

TODO ITEMS COMPLETED: Phase 0 (all 8 documents)

OPEN ISSUES:
- OI-1: No output from the Forever beta client yet (build, interface number, capability probes). Commands are in Architecture.md section 11.4. The beta runs through 2026-10-21 per press coverage, so this is time-sensitive.
- OI-2: Confirm metric definitions (D-012).
- OI-3: Allow Ace3 / HereBeDragons if they work in Forever, else pure-Lua fallbacks?
- OI-4: Confirm deferral of features that were in the earlier draft but not in the charter's v1 list (dungeon, rare, boosting, disenchant, arbitrage, crafting profit, services, craft ranking, world heatmap).
- OI-5: The charter lists documents (Project_Bible, Requirements, Decisions, Changelog, TODO, Handoff, Architecture, Contracts) that were not provided. This session created fresh baselines. If the user has existing versions elsewhere (ChatGPT or Copilot sessions), they must be merged; per precedence rules, the user's existing Requirements_v1.md would win over the Requirements here.

KNOWN RISKS:
- Forever's addon API is unconfirmed (no official docs found as of 2026-10-09). Any module that assumes an API beyond the money event and basic frame/event system may need a different adapter.
- Subzone identity depends on localized text (no stable ID known).
- SavedVariables flush only at logout/reload; crash loses the unsaved session (documented, D-007).
- Valuation quality depends on price data that may not exist at launch (AH scanning capability unknown).
- Normalization has no empirical baseline until real Forever data exists (experimental by design).

NEXT RECOMMENDED TASK: User answers OI-1..OI-5 and gives implementation approval; then start Phase 1 (Platform + Probe) per TODO.md.

BLOCKERS:
- Implementation approval not recorded (D-019).
- OI-1 is not a hard blocker for Phase 1.1-1.2 but is required to finalize the .toc interface number and adapter order.

RESUME CHECKLIST FOR THE NEXT AI:
1. Read documents in the order given in Project_Bible.md section 3.
2. Confirm the user's answers to OI-1..OI-5; record them in Decisions.md.
3. If implementation is approved, set TODO.md `IMPLEMENTATION APPROVED: YES (Phase 1)` and begin Phase 1 only.

==================================================
