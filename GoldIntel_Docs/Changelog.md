# GoldIntel Changelog

Append-only. Newest entry first. Format: `VERSION | DATE | AI/session | summary`, then bullet changes with decision/requirement references.

---

## 0.5.5-passive (retention stopgap R-1, R-2, R-3) | 2026-11-07 | Claude (session S-060)
- D-098: cash keeps 6,000 raw entries per character before folding (was 2,000); open lots cap 4,000 (was 1,500) and lots merge only within the same zone, subzone and activity; `trace.keep` keeps one unexplained line per item id per interval (gear swaps no longer push evidence out).
- Contains 0.5.4 (M4 measurement build). Contract 1.13.0. Tests: 1,316 passing (6 new). All addon Lua files parse under Lua 5.1.
- `/reload` is enough over 0.5.4; FULL restart when coming from 0.5.3 (0.5.4 added a file).
- New document (proposal, no code): Phase4_Live_Aggregation_Proposal.md.

## 0.5.4-passive (3b-3 M4 measurement build) | 2026-11-07 | Claude (session S-060)
- D-097: M4 authorized. New read-only `Platform/Perf.lua`: GoldIntel's CPU metrics (every metric of Enum.AddOnProfilerMetric through C_AddOnProfiler.GetAddOnMetric) and memory (GetAddOnMemoryUsage), sampled at interval begin, every 10 minutes and at the end into `GoldIntelCharDB.perf.samples` (cap 500), `EVT perf` trace lines, `/gi perf`, probe capability `perf.profiler`. No ledger, lot or classification change.
- Interim M4 report: Phase3b_3b-3_M4_Report.md (sizes measured; retention options R-1..R-4 for the user).
- Contract 1.12.0 (additive, F21). Tests: 1,310 passing (9 new). All addon Lua files parse under Lua 5.1.
- FULL CLIENT RESTART required (new TOC file).

## 0.5.3-passive (roll-won items, split shares) | 2026-11-06 | Claude (session S-059)
- D-095: an item roll you win ("[Loot]: You won: [item]") is now loot (value created, activity LOOT). The live line starts with a loot-history link, which the old pattern missed. Live evidence: Birchwood Maul and Ancestral Tunic (2026-11-05) had been "unexplained".
- D-096: a group share line of N claims the 2 or 3 pending money changes that add up to exactly N (several corpses looted at once by different players are paid separately but printed as one line). Ambiguous sets, single matches and already-written OTHER entries are left alone. Live evidence: 5 cases on 2026-11-05.
- Contract 1.11.0 (additive, F20). Tests: 1,300 passing (22 new incl. 6 mutation checks). All addon Lua files parse under Lua 5.1.
- `/reload` is enough (no new file, no new event: CHAT_MSG_LOOT and CHAT_MSG_MONEY were already registered).

## 0.5.2-passive (skinning, trainer fees, logout check, quest line) | 2026-11-05 | Claude (session S-058)
- D-091: a creature loot window opening at most 1.0 s after the player's own skin cast is skinning (GATHER) even when it is the corpse's first window (corpses left by other players). Live evidence 2026-11-04: 7 of 7 such windows had been booked GRIND.
- D-093: new trainer source. Platform/Trainer.lua (new file in the TOC), collector group G9 (TRAINER_SHOW, TRAINER_CLOSED), context `trainer`, money out inside the window = src `trainer`, activity TRAINER. Probe capability `trainer.events`. The two events are not yet verified in the Forever client; the first trainer visit is the check.
- D-092: the final check at a real logout uses the last seen balance (GetMoney() reads 0 then, E-46): no more false `MISMATCH` at logout; the line ends with ` logout`.
- D-094: `EVT quest done id=.. copper=..` trace line (evidence only).
- Pre-launch review items fixed on the way: `EVT check` floors the seconds (R-3), the Trace.lua header comment shows CAP 3000 (R-8).
- Contract 1.10.0 (additive, F19). Tests: 1,278 passing (23 new incl. 6 mutation checks; count updates for 18 collector events). All addon Lua files parse under Lua 5.1.
- FULL CLIENT RESTART required (new TOC file, two new events).

## DOC-ONLY | 2026-11-03 | Claude (session S-057)
- Document catch-up and pre-launch review; no code change (code stays a21e071, 0.5.1-passive, 1,255 tests).
- Decisions D-087 (evidence route: Remote Control link to the `_forever_` folder, attach GoldIntel.lua as fallback; replaces the chat-session wording of D-086), status notes, open items OI-14..OI-17.
- Contracts doc 1.9.1: header now matches contract 1.9.0; new F18 documents the 0.5.0/0.5.1 additions; trace cap and `/gi lots sales` caught up.
- README, TODO, Project_Bible header, Compatibility_Notes header updated. New PreLaunch_Review_2026-11-03.md.
- User decisions recorded: D-088 (item recording ON by default, supersedes the AC-19 default; closes OI-14), D-089 (beta data kept; closes OI-15). OI-16 deferred, OI-17 open.
- D-090 (user rule: every stage ends with a ready-to-install package block) added to the handoff working rules; launch checklist step 1 (TOC re-copy) removed after the user verified it.
- Entry order: the 0.4.1, 0.4.7, 0.5.0 and 0.5.1 entries were appended at the bottom of this file; they are moved here unchanged (newest first, as the header says), with their dates and sessions added to the headings. Session_Handoff.md sections S-054 update to S-056 likewise moved to the top.

## 0.5.1-passive (context events and periodic check) | 2026-10-31 | Claude (session S-055)
- Trace: one-line context events `EVT group <old> -> <new>` (group state polled every 2 s, logged only on change), `EVT zone`, vendor/mail/trade/auction open and close, level, profs changed.
- Trace: `EVT check` line (difference, moved, entries, pending, unseen) every 600 s and at interval end; a nonzero difference is flagged MISMATCH. `EVT group` and `EVT check` are also copied to `trace.keep`.
- Evidence only: no cash, lot or decision logic changed. Tests: 1,255 passing. `/reload` is enough.

## 0.5.0-passive (passive-play mode, M3 approved) | 2026-10-31 | Claude (session S-055)
- Collector: automatic start 3 s after login (`collect.auto`, default on); announced once; never overrides a hand-made `collect off`.
- Ledger: every interval begins with a mark, so `/gi ledger check` needs no `/gi ledger mark`.
- Trace: CAP 3000 (was 1500); new `trace.keep` list (cap 400) for anomaly/unmatched/unexplained/cast/note lines.
- Tests: 1,250 passing (new: auto start, config switch, manual off, isolation under auto interval, keep list). Existing tests adjusted: config list order, session-records tail check, ledger "no mark" case.
- Restart: `/reload` is enough (no new files). No cash or lot logic changed.

## 0.4.7-phase3b3m3 (3b-3 M3: lots stored) | 2026-10-19 to 2026-10-21 | Claude (session S-054)
- New Ledger/LotBook.lua: lots created from loot, quest rewards, vendor purchases and disenchant materials; consumed by vendor sales, quest turn-ins, disenchant and trade-outs; stored per character in `lots[charKey]` (schema 2, additive). Mail/trade arrivals, other additions and inventory-only removals are only counted (D-081, D-083, D-084).
- `/gi lots` gains last, unknown, check, reset confirm; new `/gi price set|list|clear` (optional manual override, units required).
- Lots carry location and activity stamps from the loot window (for Phase 4/5). Purchase lots carry `cost`.
- Tests: 1,230 passing, including mutation checks for the lot book. Rollback check: the 0.3.8 build runs on data that contains lots and manual prices. Existing cash replays unchanged with the item pipeline active.
- 0.4.7-phase3b3m3: money events are paired with exactly one bag settle (nearest within 1.0 s), fixing double counting when several stacks are sold within a second (D-085). Tests 1,235 passing.
- 0.4.7-phase3b3m3: the trace records the player's casts (`CAST spell=<id> kind=<kind> name=<name>`) to collect gathering spell ids of other skill ranks. Found in the user's Session V: an Apprentice skinner (skill 49) was not detected as skinning because only spell 8617 is known (E-23: "ranks differ by skill").
- 0.4.7-phase3b3m3: `/gi lots sales [n]` lists what each lot received when it left; `/gi lots status` shows conversion totals (units and copper per via). Integer-safe money formatting.
- 0.4.7-phase3b3m3: gathering casts are recognized by spell NAME across all skill ranks (names read from the client from the verified ids 2366/2575/8617/7731). Evidence: apprentice skinning cast 8613 is named "Skinning" (user trace 2026-10-21 20:36). Verified live for skinning only; herb/mining/fishing rank names pending a cast at another rank (the CAST trace line shows them).
- 0.4.7-phase3b3m3: `/gi lots last` shows the activity (and skinning) and "no vendor value" for items without a vendor price; the CAST trace line logs unrecognized spells once per interval (gathering casts always). Verified live: skinning at apprentice rank now GATHER/high (user trace 2026-10-21 20:44).

## 0.4.1-phase3b3m2 (3b-3 M2, trace only) | 2026-10-19 | Claude (session S-054)
- New: Collect/ItemSources.lua (attribution of bag changes, trace only; stores nothing, touches no cash module), CHAT_MSG_LOOT evidence recorder (group G8), `/gi lots` (status, on, off, decisions, iteminfo; check/last/unknown/reset arrive with M3).
- Bags: bags 0..5 with completeness flag and Ranges(); Items.Get adds classID/subclassID; P_LOOT_OPEN carries guid; skinning detected as repeat loot window of the same guid after a skin cast; Contract 1.9.0; Trace cap 1500.
- Tests: 1,196 passing incl. cash isolation (cash entries identical with item pipeline on/off) and mutation checks.
- M2 live evidence collected 2026-10-19; see Phase3b_3b-3_M2_Report.md. No code change since 0.4.1-phase3b3m2.


## 0.4.0-phase3b3m1 (3b-3 M1: pure item modules) | 2026-10-19 | Claude (session S-054)
- D-082: manual price is an optional override; `Valuation.Value` uses the highest of vendor and manual (manual only when strictly higher, only with ready item data). Tests 1174 passed, 0 failed.
- D-081 (option B): the item side is acquisition and conversion accounting, not a mirrored inventory. Lots: converting items no tracked lot covers is normal (counted, not an alarm); `Check` is an optional diagnostic. Tests 1168 passed, 0 failed.
- D-080 approved; M1 only. New pure modules, loaded by the TOC but wired to nothing (no events, no storage, no commands): `Collect/BagDiff.lua` (per-item-id diff, incomplete-snapshot refusal, baseline advances only on Commit, idempotent), `Ledger/Valuation.lua` (vendor floor, manual price, noVendor, pendingInfo, first valuation, expiry), `Ledger/Lots.lua` (lots, FIFO conversions, exact copper allocation, retention caps, Check I-3, stats).
- AC-15 / I-6: none of the modules references Cash, Reconciler, Expectations or Platform (static test). Cash behavior is unchanged: every existing test passes untouched.
- Contract 1.9 and Architecture AC-14..AC-19 applied as text (Q-13).
- Anomaly register in Lots (user directive 2026-10-19): unexpected conditions are counted, kept in a ring, passed to an alert hook and described with a "please report it as a bug" text; the equal-per-unit fallback is no longer silent.
- Tests: 1168 passed, 0 failed (1036 + 21 BagDiff + 64 Lots/Valuation + 47 mutation/scenario incl. 43 mutants).

## DOC-ONLY | 2026-10-19 | Claude (session S-054)
- 3b-2 recorded as CLOSED (D-079). Added Phase3b_Increment_3b-3_Scope_and_Readiness.md (D-080 Proposed). No code or package change: build stays 0.3.8-phase3b2m8, 1036 tests.

## 0.3.8-phase3b2m8 (split divisor follows range) | 2026-10-19 | Claude (session S-053)
- User confirmed: coin is split among the members who qualify (in range in the open world; everyone in an instance), so the divisor is not the group size. The window match now accepts a share N when N is floor or ceil of window coin / k for some k from 2 to the group size.
- Tests: 1036 passed, 0 failed (2-way split in a group of 3, 3-way split, far-away solo loot, no-fit share, 3 mutants adapted).

## 0.3.7-phase3b2m7 (partner-looted coin is LOOT, not OTHER) | 2026-10-18 | Claude (session S-052)
- New ActivityKey 'LOOT' (Contracts F0): chat-share coin with no known corpse or object gets act LOOT, actConf med, stamped location kept, not creditable. Creature-window shares stay GRIND (med). Never OTHER.
- Tests: 1035 passed, 0 failed (partner activity assertions, replay E-49 asserts no OTHER activity, 2 new mutants).

## 0.3.6-phase3b2m6 (chat-signal loot rule; user approval 2026-10-18) | 2026-10-18 | Claude (session S-052)
- Platform/Chat.lua emits P_LOOT_CHAT { copper, kind 'self'|'share', group } for the two received-coin lines (client GlobalStrings YOU_LOOT_MONEY / LOOT_MONEY_SPLIT with English fallback; the rest of the line must be money words only). New event in Events.SPEC.
- Collect/Sources.lua: onLootChat. Order: (1) an unclaimed loot entry of exactly N within 3 s claims the line; (2) an unclaimed OTHER of exactly N means too late: counted (chatLate), no edit; (3) a window expectation of exactly N covers it; (4) otherwise an exact loot expectation (ttl 1.0) is added, and a split share consumes its window expectation when N is floor/ceil of coin / group size (inherits the source type). New counters chatLines, chatClaimed, chatLate, chatCovered, chatSplit, chatExp in Stats().sources.
- Sources.WAIT = 2.0 (Reconciler opts.wait); Sources.LOOT_LINGER = 2.0. Expectations carry comp; the Reconciler passes it to the entry (comp 'split').
- Ledger.lua: lastMoney follows the ledger (previous + entry), so a delta still pending at a crash is recovered as a gap.
- Trace: CHATSIG lines. G7 renamed 'coin chat (loot signal)'. No TOC file change since 0.3.5.
- Tests: 1033 passed, 0 failed. New: test_chat_rule.lua (scenarios, parsing, 17 mutants), test_replay_chat.lua (E-48 solo and E-49 grouped, permanent corpus), crash-with-pending scenario and 2 mutants in test_ledger_mutation.lua; timing tests updated for WAIT 2.0.
- 3b-2 stays open; 3b-3 unstarted.

## 0.3.5-phase3b2m5 (EVIDENCE build; no classification change) | 2026-10-18 | Claude (session S-051)
- New Platform/Chat.lua: records CHAT_MSG_MONEY (text, game time, parsed copper). Emits nothing, classifies nothing. New collect group G7 'coin chat (evidence)'; CHAT_MSG_MONEY added to the collector allow-list as EVIDENCE ONLY (user approval 2026-10-18). `collect on` now registers 15 events.
- Ledger/Trace.lua: CHAT_MONEY lines, EVIDENCE chatMoneyRegistered line, `grp=members/inGroup/inRaid` on MONEY and LOOT_OPEN lines.
- Tests: new test_chat.lua (7); event-count tests updated. 1008 passed, 0 failed.
- D-078 (loot share rule) remains PROPOSED and NOT built. 3b-2 stays open; 3b-3 unstarted.
- Evidence Part A (solo, E-48): CHAT_MSG_MONEY reaches the addon, text 'You loot N Copper', 10/10 loots, exact amounts, arrives 0.52-1.00 s AFTER PLAYER_MONEY; solo group API = 0/false/false; ledger check 0 copper difference. Session script fixed (missing `/gi ledger mark` step added).
- Evidence Part B (grouped, E-49): 'Your share of the loot is N Copper.' on 14/14 deltas incl. 7 with no loot window; chat 0.5-1.0 s after PLAYER_MONEY; grp=2/true/false; ledger check 0 copper difference (+49c, all OTHER as designed for 0.3.5). Rule proposal in D-078 Addendum 2.

## 0.3.4-phase3b2m4b (M4 evidence build; replaces the unshipped-to-client 4a) | 2026-10-18 | Claude (session S-049)

- User approved (E-46 review): lastMoney fix (logout stores the accounted balance, marker lmv=2) and a diagnostic-only loot trace. New Ledger/Trace.lua, behaviour-neutral taps in Expectations/Sources/Loot, `/gi ledger trace`. 999 tests green. No classification change. Trace also records frameShown at window open and `/gi ledger trace note`; user correction: corpses are looted one at a time, auto-loot window is brief (AoE hypothesis withdrawn). Package GoldIntel_3b2_M4b_AddOns.zip (1000 tests). Reload: CLIENT RESTART required.

---

## fix after M4 evidence E-46 | 2026-10-18 | Claude (session S-048)

- Ledger: logout stores the accounted balance (the client reads 0 during a real logout); marker `lmv = 2`; marker-less lastMoney is re-baselined once without a gap. 988 tests green. Not packaged.

---

## 0.3.3-phase3b2m4 (3b-2 M4 build) | 2026-10-18 | Claude (session S-047)

- M3 approved. Retention cap changed 5000 -> 2000 raw entries per character (user decision), fold of 500 unchanged; tests adjusted (984 passed). Version bump only otherwise; package GoldIntel_3b2_M4_AddOns.zip. Live validation script: Phase3b_3b-2_M4_Validation_Plan.md.
- Reload: CLIENT RESTART required.

---

## 0.3.2-phase3b2m3 (3b-2 M3, ledger now live in the addon) | 2026-10-18 | Claude (session S-046)

- Schema 2: ledger section and migrationBackup (real E-43/E-45 files migrate; compat byte-identical); GoldIntelCharDB schema 2 with `lastMoney`. Rollback to 0.3.1 verified read-only with the real 0.3.1 Store.
- New `Ledger/Cash.lua` (compact records, interned places, fold at 5000/500 with totals, immutable entries, `LEDGER_CASH`) and `Ledger/Ledger.lua` (intervals, login gap, logout, mark/check, `/gi ledger`). `collect on` starts the ledger; collect stays OFF after login and /reload.
- `/gi diag` prints the ledger quality block first. Collector wiring: partial group does not start the ledger.
- Tests: 984 passed (new: test_schema2, test_cash, test_ledger, test_ledger_mutation with 24 mutants). No live validation yet (M4 needs separate go-ahead).
- Reload: CLIENT RESTART required (TOC changed).

---

## 3b-2 M2 (unreleased, inert) | 2026-10-18 | Claude (session S-045)

- Added Collect/Sources.lua, Collect/Stamps.lua, Platform.LastCast, held (`hold`) exact expectations; Contract 1.8.0; AC-9..AC-13 text. Collector not wired; no behaviour change in the client.

---

## 3b-2 M1 (unreleased, inert) | 2026-10-18 | Claude (session S-044)

- Added Collect/Expectations.lua and Collect/Reconciler.lua (pure; not wired to events), tests in Tests/test_reconciler.lua. No behaviour change in the addon.

---

## Documentation only | 2026-10-18 | Claude (session S-043)

- 3b-1 closed (D-076). Added Phase3b_Increment_3b-2_Scope_and_Readiness.md (D-077 Proposed). No code change.

---

## 0.3.1-phase3b1 (increment 3b-1, revision) | 2026-10-18 | Claude (session S-042)

Loot-close revision after live evidence (E-41, E-42, D-075). Still 3b-1 scope: no ledger, Reconciler, expectations, lots, valuation, schema 2.
- `Platform/Loot.lua`: window close = `LootFrame:IsShown()` false (poll 0.1 s only while open) -> `P_LOOT_CLOSE{by='frame'}`; `LOOT_SLOT_CLEARED` informational only; 300 s backstop `timeout`; unreadable frame -> legacy rule for that window (`frameUnreadable`, `legacyWindows`); `maxOpenSec` statistic.
- `/gi collect stats` loot lines: `closed by frame / timeout / replaced; longest open`, and `slot clears (information only): seen, duplicates, late; unreadable: frame, slots`. `collect on` line now reads "skipped by quarantine".
- Contract 1.7.1, addon 0.3.1-phase3b1. No schema change.
- New permanent fixture `Tests/fixtures/probe/E-42_lootframe.lua` replayed through the real adapter (8 windows).
- Tests: 790 passed, 0 failed (was 771). Install: CLIENT RESTART (Loot.lua changed; no TOC file added, so /reload would load it, but a restart is requested for a clean run).
- Throwaway probe addon `GIProbeLoot` (not part of GoldIntel).

## 0.3.0-phase3b1 (increment 3b-1) | 2026-10-18 | Claude (session S-042)

Phase 3b increment 3b-1: collectors and contexts only. NO expectations, Reconciler, cash ledger, lots, bag diff, valuation, stamps or schema 2. Decision D-074 (A-1..A-5 approved).
- Platform: adapters Loot, Merchant, Quest, Trade, Mail, Auction, Items, Bags; Cast adapter in Unit.lua; `P.RegisterCollectAdapter`, `P.Call/CallIn/HasIn/IsAddonLoaded`; allow-list enforced in `Events.Bind`; per-event delivery counters; optional `RegisterUnitEvent` filter for casts with plain fallback.
- Collect: `Context.lua` (loot, vendor, mail, trade, ah, quest; 1.0 s linger; idempotent closes; CONTEXT_CHANGED), `Collector.lua` (`/gi collect status|on [G1-G6] [plain]|off|stats|reset|allow EVENT`; journal before each registration; quarantine of an interrupted event; collect is OFF after every login and /reload).
- Contract 1.7 (additive), addon 0.3.0-phase3b1. No schema change.
- Replay corpus: added E-33 (merchant), E-39, E-40 fixtures; all replayed through the real adapters.
- Tests: 771 passed, 0 failed (567 at the start of 3b-1; the plan estimated about 790). Install: CLIENT RESTART required (files added to the TOC).

## Documentation only | 2026-10-18 | Claude (session S-041)

- Recorded E-37..E-40 (bid, outgoing mail, COD paying and receiving); addendum D-068 complete. Earlier: E-36 (Session 23) in Compatibility_Notes, evidence copy 2026-10-18h, README row, TODO line. No code change.

## Documentation only | 2026-10-18 | Claude (session S-040)

Session 19 recorded as E-35 (AH deposit, cancel, buyout, bid). Session 23 added to the lab README. No code.

---

## 0.2.1-phase3b0 (increment 3b-0) | 2026-10-18 | Claude (session S-039)

Phase 3b increment 3b-0 (housekeeping only; NO collector, NO ledger, nothing new registered). Decisions D-067..D-072, D-027, D-028.
- D-027 executed: the classic skill-line profession adapter and its probes (`prof.skilllines`, `prof.expand`, `auction.legacy`, `tradeskill.legacy`) are removed; professions come from GetProfessions only (Forever has no skill-line API, E-05).
- `Platform.COLLECTOR_EVENTS` and `Platform.IsCollectorEvent` (Architecture 19 AC-1): the allow-list of verified events. Registers nothing, trusts nothing new.
- `Tests/helpers/labreplay.lua`: replays saved lab files as event streams; tests show the measured lags (trade 0.394 s, mail 0.365 s, quest 0.041 s) are inside the 1.0 s window.
- Contract version 1.6 (shapes approved in D-069, not yet implemented). Addon version 0.2.1-phase3b0.
- Docs: Architecture section 19, Contracts Phase 3b additions, Phase3b_Profiling_Plan.md.
- Tests: 565 passed, 0 failed (was 551). Install: /reload is enough (no file added or removed).

---

## GoldIntelDiag 1.8 | 2026-10-18 | Claude (session S-039)

Read-only lab additions for the verification addendum (D-068): AHS (auction house state: money, window, own auctions, event name validity), MS1 (outgoing mail: postage, money, COD fields), AH1 (auction events, one per session), CO1 (COD via X2), X2 now also records the money. README Sessions 19 to 22. No collector. Install: /reload is enough.

---

## Documentation only | 2026-10-18 | Claude (session S-038)

D-066 recorded (Phase 3a closed with exceptions). Phase3b_Scope_and_Readiness.md written for review. Kill proxy row marked DROPPED. No code.

---

## Documentation only | 2026-10-18 | Claude (session S-037)

Session 18 recorded as E-34 (MAIL_CLOSED not delivered; sold-auction invoice readable). Formal Phase3a_Closure_Recommendation.md written for the user's review. No code.

---

## Documentation only | 2026-10-18 | Claude (session S-036)

Session 17 recorded as E-33 (MERCHANT_CLOSED). No code.

---

## Documentation only | 2026-10-18 | Claude (session S-035)

Session 16 recorded as E-32 (quest reward bag diff). No code.

---

## GoldIntelDiag 1.7 | 2026-10-18 | Claude (session S-034)

Added read-only lab experiment Q2 (quest reward item bag diff; BAG_UPDATE_DELAYED registrable) with 5 tests (551 pass). No collector, no Phase 3b.

---

## Documentation only | 2026-10-18 | Claude (session S-033)

D-065 approved and recorded: reconciliation window 0.25 s to 1.0 s (Decisions D-004 amended, Architecture Reconciler section, Planning Package). No code.

---

## Documentation only | 2026-10-18 | Claude (session S-032)

Session 15 recorded as E-31 (trade events). README Session 15 rewritten. No code.

---

## Documentation only | 2026-10-18 | Claude (session S-031)

Session 14 recorded as E-30 (item data loading, I1b). No code.

---

## Documentation only | 2026-10-18 | Claude (session S-030)

Session 13 recorded as E-29 (X2 mailbox metadata). No code.

---

## GoldIntelDiag 1.6 | 2026-10-17 | Claude (session S-029)

Added read-only lab probe X2 (mailbox metadata) with 3 tests (546 pass). D-064 point 6 recorded. No collector, no Phase 3b.

---

## Documentation only | 2026-10-17 | Claude (session S-028)

Session 12 recorded as E-28 (mail). No code.

---

## Documentation only | 2026-10-17 | Claude (session S-027)

Session 11 recorded as E-27 (instance run S1). No code.

---

## Documentation only | 2026-10-17 | Claude (session S-026)

Session 10 recorded as E-26 (disenchant cast). No code.

---

## Documentation only | 2026-10-17 | Claude (session S-025)

Session 9 recorded as E-25 (disenchant loot window). No code.

---

## Documentation only | 2026-10-17 | Claude (session S-024)

Session 8 recorded as E-24 (loot windows, repeat-GUID rule). No code.

---

## Documentation only | 2026-10-17 | Claude (session S-022)

Session 7 recorded as E-23 (C1). D-063 and AM-12 added (value views). No code.

---

## Documentation only | 2026-10-17 | Claude (session S-021)

Session 6 recorded as E-22 (Q1 quest turn-in verified). No code.

---

## Documentation only | 2026-10-17 | Claude (session S-020)

Session 5 recorded as E-21; D-060 and D-061 details confirmed by the user. No code.

---

## GoldIntelDiag 1.5 | 2026-10-17 | Claude (session S-019)

- Session 4 recorded as E-20; signal matrix updated. Lab: loot window snapshot stored with each `LOOT_OPENED` sample. Tests 543 pass. GoldIntel unchanged.

---

## Documentation only | 2026-10-17 | Claude (session S-018)

User approved D-060 (instance farms at entrances, default per-run stats, optional full-cycle) and D-061 (Account Best and Character views, default Character, Account Best optional). Requirements AM-10, AM-11 updated. No code.

---

## GoldIntelDiag 1.4 | 2026-10-17 | Claude (session S-017)

- Session 3 recorded as E-19; user direction recorded as D-060 and D-061 (AM-10, AM-11, planning addendum A.4). Lab: restriction state stored with every sample, `GetInstanceInfo()` in S1, more table names in P1. Tests 540 pass. GoldIntel unchanged.

---

## GoldIntelDiag 1.3 | 2026-10-17 | Claude (session S-016)

- Session 2 recorded as E-18; signal matrix updated (L1 pass). Lab: probe P2 (restriction and state getters). Tests 538 pass. GoldIntel unchanged.

---

## GoldIntelDiag 1.2 | 2026-10-17 | Claude (session S-015)

- Session 1 results recorded as E-17; signal matrix updated. Lab additions: probe P1 (function names of C_* tables, never called), experiment I1b (GET_ITEM_INFO_RECEIVED), I1 requests loads for 2589/2770. Tests 537 pass. GoldIntel unchanged.

---

## GoldIntelDiag 1.1 (Phase 3a lab) | 2026-10-17 | Claude (session S-014)

- New `GoldIntelDiag/Lab.lua` and `/gidiag lab` command family (D-051, protocol Phase3a_Verification_Protocol.md). Read-only; results in `GoldIntelDiagDB.lab`; one event registration per session; secret-safe, bounded capture. `Diag.lua` delegates `lab` and exports `ns.emit`; TOC lists Lab.lua; README has the Session 1 steps.
- Tests: `Tests/test_diag_lab.lua` (36); 535 pass. Packages rebuilt and verified. GoldIntel addon unchanged.

---

## Documentation only | 2026-10-17 | Claude (session S-013)

User decisions recorded, no code: travel model Option B (D-054), colour scale relative by default (D-057), ranked hotspot list in v1 (D-058), overlay commands (D-059). Requirements AM-7..AM-9; Travel_Model_Options and Phase3_Planning_Package updated; TODO.

---

## 0.2.0-phase2 rebuild 4 | 2026-10-17 | Claude (session S-012)

Phase 2 closed with exceptions (D-056). Maintenance feature approved by the user: bounded session records (D-041). No Phase 3 functionality.
- Added: `runtime.previous`, `runtime.history` (10 rows), `runtime.pinned`; `Capabilities.Persist(reason)`, `Pin()`, `Unpin()`, `Records()`; `/gi caps previous|pinned|history`, `/gi checkpoint pin|unpin`, a session-records line in `/gi db`. Evidence only, bounded (previous/pinned output trimmed to 12000 bytes, history capped), never touches compat, profile or meta; read-only and degraded databases get no rotation.
- Contract 1.5 (`P.CONTRACT_VERSION`). Tests: `Tests/test_session_records.lua` (17), one growth test now covers 24 sessions with a bounded ring; 499 pass; removing the rotation fails 8 tests. Packages rebuilt and verified from the extracted dev zip.
- Documents: Requirements 1.1.0 (amendments AM-1..AM-6), Decisions D-041 (implemented), D-043..D-050 accepted, D-051 (Phase 3a), D-052 (location-level heat, overlay toggle), D-053 (graphical config), D-054 (travel direction), D-055 (AFK, manual commands), D-056 (Phase 2 closure), D-034..D-040 confirmed; `Travel_Model_Options.md`, `Phase3a_Verification_Protocol.md`; Phase3_Planning_Package Addendum A; TODO (Phase 3a); Contracts 1.5.

---

## Documentation only (planning) | 2026-10-17 | Claude (session S-011)

User: Phase 2 substantially validated; keep previous session records (principle); Phase 3 PLANNING ONLY. No code changed; no Phase 3 implementation.
- Added: `Phase2_Closure_Recommendation.md`, `Runtime_Session_Records_Proposal.md`, `Phase3_Planning_Package.md`.
- Decisions: D-041 (principle approved, design proposed), D-042 (planning-only authorization, approved), D-043..D-050 (Proposed). Risk_Register R-27..R-30 (proposed). TODO 2.9, 2.10. Project_Bible inventory.
- Identified a wording gap in Architecture 8 ("copper credited" should be value credited); recorded as a proposed amendment, not applied.

---

## Documentation only | 2026-10-17 | Claude (session S-010)

Third live session recorded (E-15): money, level-up, zone and combat delivery confirmed, settings persistence confirmed, sandbox run clean. No code change. Noted: `/reload` overwrites the previous session's `runtime` snapshot (proposal: keep `runtime.previous`; not implemented, awaits the user).

---

## 0.2.0-phase2 rebuild 3 | 2026-10-17 | Claude (session S-009)

Second live Phase 2 session (build 70450) interpreted; one small usability fix. Same version string; scope unchanged (Core + Store).
- Evidence: raw `GoldIntel.lua` and `GoldIntelDiag.lua` stored in `evidence/` (E-14). Installed files match the package; store ok, opens=4; combat events delivered; libraries absent yet operational.
- Fixed: `/gi debug ticks` now says that nothing is echoed until `/gi debug on` is also set (the user saw "tick echo on" and no echo). 1 new test; 483 pass.
- Documents: Compatibility_Notes (E-14, E-15 pending), Phase2_Runtime_Validation_Plan (results table), Risk_Register (R-25), TODO (2.8), Session_Handoff S-009, evidence/README.

---

## 0.2.0-phase2 rebuild 2 | 2026-10-15 | Claude (session S-008)

Follow-up after the first live Phase 2 session (build 70374). Same version string; scope unchanged (Core + Store).
- Evidence: `evidence/2026-10-15_Phase2_first_live_session_EXTRACT.md` (an extract; the raw file was pasted, not attached). Store migrated the real database 0 to 1, 12 verified registrations, clean startup, snapshot and checkpoint saved at logout, capabilities identical across the 70338 to 70374 hotfix.
- Fixed: `P.CONTRACT_VERSION` was stale (reported 1.1); now 1.4 and tested.
- Changed: `/gi caps` prints `yes` / `NO` / `not-seen-yet` / `unknown` instead of `true` / `false` / `nil` (a `nil` meant 'not observed yet' and looked like an error).
- Added [D-040]: `Platform.Print` records every line (200-line ring); `GoldIntelDB.runtime.output` stores the last 100 lines and `outputTotal`; every `/gi` command schedules a snapshot (`Capabilities.Touch`); logout writes the final one. The user can send the saved file instead of copying chat text. 6 new tests; 482 pass.
- Documents: Compatibility_Notes 1.2 (live facts), Risk_Register (R-26 positive case confirmed, R-25 partly validated, R-04 refined), Decisions D-040 and status notes, Contracts 1.4, Phase2_Runtime_Validation_Plan 1.1 (results so far, how to get output back), TODO, Session_Handoff S-008.

---

## 0.2.0-phase2 | 2026-10-10 | Claude (session S-007)

Phase 2 implementation: Core + Store (authorized by D-033). No collector, no Phase 3 functionality.

Added (GoldIntel/):
- `Platform/SavedVars.lua` (only access to the saved variables), `Platform/Slash.lua` (only slash registration) [D-037]
- `Core/Core.lua` (module and service registry, lifecycle, startup orchestration, minimal mode), `Core/Bus.lua` (typed internal bus, reserved events incl. the four money pipeline stages), `Core/Capabilities.lua` (stage model, snapshot to `runtime`), `Core/Config.lua` (typed validated settings), `Core/Slash.lua` (`/gi` command set), `Core/Boot.lua` (last file) [D-034, D-035, D-038]
- `Store/Migrations.lua`, `Store/Store.lua`, `Store/Pruner.lua` (plans only) [D-036]
- `Future/CommunityDataEngine.lua`, `Future/RouteEngine.lua` placeholders [D-015]
- Tests: 11 new test files plus `svsim` helper and the real Phase 1 database fixture. 476 tests pass (was 245). Mutation checks: 7 deliberate breakages of Phase 2 guarantees (compat wipe, read-only, delivered-from-registration, bus isolation, dependency order, invalid settings, compat check) were each caught.
- Tools/diagnostics: `tools/build_package.py` embeds all current files (`GoldIntelDiag/SrcCurrent.lua`); `/gidiag run` now sandboxes the whole addon with private saved variables and slash commands; packages renamed `GoldIntel_Phase2_AddOns.zip` and `GoldIntel_Phase2_Dev.zip`.

Changed:
- `Platform/Events.lua`: `Bind` verifies registration with `IsEventRegistered` (exception E1), delivery counters, `WatchStage`, `ReportPayload`, `Stats`, `BoundEvents`; `Money.lua` and `Unit.lua` report payload usability (two call sites) [D-034]
- `Platform/Platform.lua`: `TRUSTED_EVENTS` fail-safe (the 12 live-proven events), `Util.deepCopy/deepEqual`; version 0.2.0-phase2
- `Platform/Probe.lua`: the temporary `/gi` handler removed (moved to Core) [D-022 item 5]
- `GoldIntel.toc`: 21 files, Version 0.2.0-phase2, Interface unchanged (16001)

Bugs found by the new tests and fixed during the work: `Capabilities.Stage` returned nil for a false value; a bulk rename had turned `spec.maxLength` into `spec.maxValueLength`; the per-character table was not created at startup.

Documents: Architecture 18 and file tree, Contracts 1.3, Decisions D-033 to D-039, Risk_Register (R-09 and R-18 mitigated in code; R-19 to R-27 added), `reviews/External_Review_Log.md` (six relayed findings, all accepted, one partially applied), `Phase2_Runtime_Validation_Plan.md`, Compatibility_Notes, TODO, Session_Handoff S-007.

NOT verified: anything in the real client (Core, Store, stage model, `IsEventRegistered` behavior: R-25, R-26, OI-12). Tests ran on Lua 5.3.

---

## 0.1.2 (governance only) | 2026-10-10 | Claude (session S-006)

Governance update from the user; no code, architecture or requirement change. Added `Project_Bible.md` section 2.1 (roles, review model, external review intake rules, conflict-table row) and Decisions D-032. Session_Handoff S-006.

---

## 0.1.2 (documentation only) | 2026-10-10 | Claude (session S-005)

Phase 1 post-validation review. NO CODE CHANGED; the shipped packages are unchanged (still 0.1.2-phase1-runtime). Phase 2 not started.

Added: `Phase1_PostValidation_Review.md`; `Compatibility_Notes.md` (verified client profile, evidence ledger E-01..E-12, re-verification protocol); `Risk_Register.md` (R-01..R-18, closed risks); `evidence/` (the two SavedVariables files from the real client plus README).
Changed: `Decisions.md` (D-027 to D-031 proposed; status notes on D-022/D-024/D-025/D-026; OI-1 closed as scoped, OI-7 merged into new OI-8, new OI-9..OI-11, X-1, X-2); `Contracts.md` 1.1 to 1.2 (documents `EventNameValid`, `IsSecret`, `RESTRICTED_EVENTS`, three-state Probe, full `compat` shape; corrects drift introduced in code 0.1.2); `Architecture.md` (7.4 GRIND rule marked REDESIGN REQUIRED; 11.1 pointer); `TODO.md` (Phase 1 live-validated, exceptions E1-E7, conditions X1-X5); `Project_Bible.md` (inventory); `Session_Handoff.md` (S-005).
Process note: Contracts.md was behind the code after 0.1.2 (my error); fixed here and prevented going forward by D-031.

---

## 0.1.2-phase1-runtime | 2026-10-09 | Claude (session S-004)

Phase 1 runtime compatibility patch after real-client test #2. No new functionality; no Phase 2 work.

Findings: (a) the original "Error loading" was folder structure, caused by loose-file delivery; (b) `GIMin/Sub/*.lua` and `GoldIntelDiag/SrcV*.lua` were never delivered; (c) with files loading, `Probe.lua` raised `ADDON_ACTION_FORBIDDEN` on `Frame:RegisterEvent()` because it probed 29 event names by registering them (39 was the number of capability probes, not events) (restricted events are blocked with a popup pcall cannot hide).

Changed (GoldIntel):
- `Platform.lua`: `RESTRICTED_EVENTS` (COMBAT_LOG_EVENT_UNFILTERED), `EventNameValid()` (C_EventUtils.IsEventValid, never registers), `IsSecret()`; version 0.1.2-phase1-runtime [D-025]
- `Events.lua`: `Bind` refuses restricted events and names the client reports invalid, without calling RegisterEvent; records `Events.lastRegisterAttempt` before registering
- `Probe.lua`: no event is registered any more; event families checked by name only; three-state report (`[ok]`, `[MISSING]`, `[unknown]`); money.event probe removed (Money.lua sets it from its real registration); `status` persisted; `/gi status` shows `lastRegister`
- `Money.lua`, `Unit.lua`, `Map.lua`: secret-value guards (defensive, unverified in the real client)
- `GoldIntel.toc`: version 0.1.2-phase1-runtime
- Tests: fake client gained a forbidden-event trap that mirrors the real client, `C_EventUtils`, `IsEventRegistered`; new tests: Probe never registers (even when the client forbids many events), full session registers exactly the 12-event allowlist, restricted list enforced, names-only probe states, secret-value guards, rule C-6 (only Events.lua may call RegisterEvent). 245 tests pass (was 227). Re-introducing the bug (Probe registering the combat-log event) makes 6 tests fail.

Changed (diagnostics): `GoldIntelDiag` events section checks names only; new opt-in `/gidiag reg NAME` with an ADDON_ACTION_FORBIDDEN watcher; embeds only v0.1.2 sources (`SrcV012.lua`); `Phase1_Client_Diagnostics.md` 1.1.0: every event command now checks names only (I6 is the single opt-in registration test), 51 commands, all at most 255 characters and syntax-checked.

Added: `tools/build_package.py` (verifies every TOC-listed file exists, builds `GoldIntel_Phase1_AddOns.zip` and `GoldIntel_Phase1_Dev.zip`, regenerates SrcV012.lua and MANIFEST.txt) [D-026]. Both zips were extracted and verified: tests pass from the extracted dev zip; Diag and GIMin load from the extracted AddOns zip in the fake client.

Documents: Decisions.md (D-025, D-026; OI-6 resolved; OI-7 opened), Phase1_Compat_Analysis.md (addendum with corrections), TODO.md, Session_Handoff.md (S-004).

NOT verified: behavior in the real client after this patch. Which event was actually forbidden is unknown (OI-7).

---

## 0.1.1-phase1-compat | 2026-10-09 | Claude (session S-003)

Phase 1 compatibility fix after real-client test #1. No new functionality; no Phase 2 work.

Trigger: client rejected Interface 11508; with 16001 the TOC loads but all 8 Platform files log "Error loading" (no detail). A trivial addon loads.

Changed:
- `GoldIntel.toc`: Interface 16001 [D-023]; forward slashes; all `#` comment lines removed; OptionalDeps and custom X- field removed; minimal 6 fields [D-024 C-4]
- `Platform/*.lua` (all 8): leading `--[[ ... ]]` header blocks converted to `--` line comments; no long brackets remain [D-024 C-2]. Logic untouched.
- `Platform/Platform.lua`: `P.VERSION` = `0.1.1-phase1-compat`
- `Tests/test_platform_boundary.lua`: new rules C-1..C-5 (ASCII/LF/BOM/trailing newline, no long brackets, minimal TOC with forward slashes and Interface 16001, namespace line first). 227 tests pass (was 224). Each rule verified to fail when violated.

Added (outside the addon):
- `GoldIntelDiag/` read-only diagnostic addon: `/gidiag compile` lets the client compile embedded v0.1.0 and v0.1.1 sources and print real errors; `/gidiag all|lua|addon|api|unit|map|events|timer|slash|sv|run|copy`; MANIFEST.txt with size/adler32/SHA-256
- `GIMin/` smallest test addon (loading, namespace passing, TOC path styles, block-comment header, SavedVariables, slash, events)
- `GoldIntel_Docs/Phase1_Compat_Analysis.md` (root-cause analysis, ranked causes, audit)
- `GoldIntel_Docs/Phase1_Client_Diagnostics.md` (45 copy/paste commands, each at most 255 characters and syntax-checked)

Documents: Decisions.md (D-023, D-024; OI-1 partially answered; OI-6 opened), TODO.md, Architecture.md section 11.1 note, Project_Bible.md known facts, Session_Handoff.md (S-003).

Verification: `texlua Tests/run.lua` gives 227 passed, 0 failed (Lua 5.3). GoldIntelDiag and GIMin smoke-tested in the fake client; every diagnostic one-liner compiles. NOT verified: any behavior in the real client. Root cause of the load failure remains unproven (OI-6).

---

## 0.1.0-phase1 | 2026-10-09 | Claude (session S-002)

Phase 1 implementation (authorized by D-020: Phase 1 only). First code in the project.

Added (addon folder `GoldIntel/`):
- `GoldIntel.toc` (placeholder interface 11508; OptionalDeps Ace3, HereBeDragons-2.0) [D-021, D-022]
- `Platform/Platform.lua`: environment injection (`P.env`), capability registry, diagnostics ring (200), ready/fatal lifecycle, utilities [D-001, D-016]
- `Platform/Clock.lua`: `Platform.Now()` wall + monotonic time with regression clamp
- `Platform/Events.lua`: normalized event dispatcher with payload validation for all 26 contract events, WoW event binding with registrability probing, lifecycle events (login, in-world, combat, logout), late-load check
- `Platform/Scheduler.lua`: `Every` / `After` on C_Timer or OnUpdate backends, error isolation (cancel after 5 consecutive failures), stall handling
- `Platform/Unit.lua`: `Platform.Player()` (GUID identity, class token), professions via two adapters incl. collapsed skill headers, `P_LEVEL`, debounced change-only `P_PROFS` [D-006]
- `Platform/Map.lua`: `Platform.Where()` with degradation paths, `P_ZONE` (deduplicated), `P_TICK` (0.5 s, dt clamped) [D-008]
- `Platform/Money.lua`: `Platform.Money()`, `P_MONEY` deltas computed from the live balance (sum of deltas equals real change), gap detection at loading screens [FR-LED-1 groundwork]
- `Platform/Probe.lua`: 39 capability probes, pasteable report, persistence to `GoldIntelDB.compat`, TEMPORARY `/gi probe|status|diag|debug` [D-016, D-022]
- Tests (`Tests/`, 10 files, 224 tests): fake WoW client, plain-Lua runner, boundary/lint test, per-module suites, integration and one-hour soak test

Changed (documents):
- Decisions.md: added D-020, D-021, D-022; D-012 and D-013 confirmed; D-019 superseded; OI-2, OI-3, OI-4 resolved; OI-1 and OI-5 remain open
- Requirements_v1.md section 9: assumption statuses updated (A-1, A-2, A-3, A-5, A-6 confirmed; A-4 open)
- Contracts.md 1.0.0 to 1.1.0 (CONTRACT VERSION 1.1, additive): see its change log
- TODO.md: Phase 1 tasks 1.1-1.5 done; exit test split into automated (done) and in-client (pending)

Verification: `texlua Tests/run.lua` gives 224 passed, 0 failed (Lua 5.3; Lua 5.1 interpreter not available in the authoring environment). Five deliberate code mutations (sign error, stall catch-up, bare global, (0,0) position, missing handler isolation) were each caught by the suite.

NOT verified: behavior in a real WoW Forever client (no access). All WoW API usage follows Classic-era conventions and is unconfirmed for Forever (OI-1).

---

## 0.0.1-planning | 2026-10-09 | Claude (session S-001)

Documentation baseline. No code exists; nothing was implemented.

- Created Project_Bible.md 1.0.0 (governance, precedence, resume procedure) [D-018]
- Created Requirements_v1.md 1.0.0 (frozen scope from charter; metric definitions; assumptions A-1..A-6)
- Created Decisions.md 1.0.0 (D-001..D-019; open items OI-1..OI-4)
- Created Architecture.md 1.0.0: consolidated v1 architecture from design spec Part 1 + Part 2 review, re-scoped to the charter [D-013]
- Created Contracts.md 1.0.0: records, Platform API, bus events, module interfaces, SavedVariables schema, placeholder stubs [D-014, D-015]
- Created TODO.md and Session_Handoff.md (section S-001)
- Reconciled drift between earlier drafts and charter: scope (D-013), schema numbering (D-014), metric definitions (D-012, pending confirmation), added Future/ placeholders (D-015)

Documents superseded by this baseline: design spec "GoldIntel: WoW Forever Addon Design" Part 1 (v0 draft) and Part 2 (review). Those remain as historical input; where they differ from these documents, these documents win.
