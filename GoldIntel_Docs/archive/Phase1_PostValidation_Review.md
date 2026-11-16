# Phase 1 Post-Validation Review

DOC VERSION: 1.0.0  |  DATE: 2026-10-10  |  Session S-005  |  Scope: review, runtime analysis, governance updates. **No code was changed. Phase 2 not started.**

Primary evidence: `evidence/2026-10-10_GoldIntel_SavedVariables.lua` and `evidence/2026-10-10_GoldIntelDiag_SavedVariables.lua` (WoW Forever 1.60.1, build 70338, Interface 16001). Claims below are tagged **[file]** (visible in the attached files), **[reported]** (stated by the user, not in the files), **[inferred]** (my deduction) or **[assumed]** (not verified).

## 0. Verdict

| Question | Recommendation |
|---|---|
| Phase 1 | **COMPLETE WITH EXCEPTIONS.** The formal Phase 1 exit test (TODO.md) is satisfied by your report; five non-blocking exceptions (section 9) should be tracked. |
| OI-1 (WoW Forever API discovery) | **CLOSE as scoped** (platform capabilities discovered and recorded). The part that is NOT discovered (restricted events, restriction model, Phase 3 signals) moves to new OI-8. |
| Phase 2 (Core + Store) | **CONDITIONAL GO.** Phase 2 touches almost none of the unverified client surface. Conditions in section 13. |
| Phase 3 (Collector) | **NO-GO** until OI-8 (restriction model, per-event registration tests, a combat-log-free activity signal) is resolved. |
| Architecture confidence | About **70%**, up from about 50-55% before validation (my judgment; section 11). |

## 1. What the evidence proves, and what it does not

**Proven [file]:** build 1.60.1 / 70338, Interface 16001, enUS, WOW_PROJECT_ID 18; all 8 Platform sources compile in the live client and the addon ran (`operational: yes`, scheduler `ctimer`); probe result of 40 entries: 35 ok, 4 missing, 1 unknown; 12 event registrations returned normally and none failed; `GoldIntelDB.compat` was written by `Probe.Persist` and survived (SavedVariables work); `GoldIntelDiagDB.loads = 3` (persistence across sessions); Lua 5.1 grammar (8 of 8 checks); the API namespace inventory (272 `C_` namespaces); read-only unit, map, money and time values in Orgrimmar.

**Reported by you, not contained in the files [reported]:** vendor sale produced a positive `P_MONEY`, buyback a negative one; the `/gi status` values (ready, inWorld, diag=0); no popup or Lua error in the latest session. I treat these as true but they are not independently checkable from the attachments. Please keep the `[evt] P_MONEY` chat lines if you can.

**Not evidenced anywhere:**
- `P_ZONE`, `P_TICK`, `P_LEVEL`, `P_PROFS`, `P_COMBAT` delivered in the live client.
- Output of GoldIntel's **own** `Platform.Player()`, `Platform.Where()` and profession reading. The Diag transcript reads the WoW APIs directly, and `/gidiag run` (the sandbox run of GoldIntel's code) is not in the transcript because `/gidiag all` does not include it.
- Any profession data at all (no value printed), so `GetProfessions()` semantics for Forever are unconfirmed.
- Behavior in combat, instances, at an auction house, a mailbox or a trade window.
- Performance (CPU, memory) and the GIMin results.

**Context limits:** one build, one character, standing in a city, not in combat. Every `issecretvalue(...) = false` reading comes from that idle context.

## 2. Actual client behavior versus original assumptions

| # | Original assumption | Source | Actual (evidence) | Verdict |
|---|---|---|---|---|
| 1 | Interface number 11508 (Classic Era) | S-001/S-002 | GetBuildInfo reports 1.60.1 and Interface 16001 [file]. 16001 = 1x10000 + 60x100 + 1 [inferred], so the number tracks the client version | Wrong; fixed (D-023). Will change every patch (R-04) |
| 2 | Classic-era API surface | Architecture 11 | Modern retail-engine API: 272 `C_` namespaces including 12.x-style ones (C_Housing, C_Secrets, C_RestrictedActions, C_DamageMeter, C_EncounterTimeline, C_CooldownViewer, C_AssistedCombat) [file]. Content is Classic Era: map IDs 1454 Orgrimmar / 1414 Kalimdor, subzone 'Valley of Strength' [file] | Wrong. 'Classic+ content on a modern engine' |
| 3 | Lua version uncertain (5.1 or newer?) | S-003 hedging | Lua 5.1, all 8 grammar checks match 5.1; `loadstring`, `setfenv`, `getfenv`, `unpack`, `bit`, `math.pow` exist; `load`, `table.unpack`, `string.pack` are nil [file] | Confirmed 5.1. The hedging was unnecessary |
| 4 | Realmless | Press coverage | `GetRealmName` = 'Classic Beta PvE', normalized 'ClassicBetaPvE'; GUID `Player-4618-0083E4B2` has server field 4618 [file] | Partly wrong for the beta. Launch model unknown. GUID key (D-006) still right |
| 5 | WOW_PROJECT_ID (my fake client used 2) | Test fixture | 18 [file] | Unknown constant: never gate on WOW_PROJECT_ID |
| 6 | Professions via skill-lines API | Unit.lua adapter 2 | `GetNumSkillLines`, `GetSkillLineInfo`, `ExpandSkillHeader` absent; `GetProfessions`/`GetProfessionInfo` present [file] | Wrong adapter; modern-first order was already right |
| 7 | SKILL_LINES_CHANGED might not exist | Unit tests | Valid and registered (`event.SKILL_LINES_CHANGED = true`) [file] | Wrong: the event exists although the skill-line functions do not |
| 8 | Legacy auction API (`QueryAuctionItems`) | Architecture 9 | Absent. `C_AuctionHouse` has 85 functions, including `CalculateCommodityDeposit`, `CalculateItemDeposit`, `GetNumReplicateItems`, `GetReplicateItemInfo`, `IsThrottledMessageSystemReady` [file] | Wrong. Design needs the commodity/item split |
| 9 | Legacy trade-skill API | Architecture | Absent; `C_TradeSkillUI` present [file] | Wrong (craft ranking is deferred anyway) |
| 10 | C_Timer available | Likely | Present; `NewTicker`, `NewTimer`, `After`, `NewTimedSignalMap`; scheduler chose `ctimer` [file] | Confirmed |
| 11 | C_Map and map position | Likely | `GetBestMapForUnit` -> 1454; `GetPlayerMapPosition` returns an object whose `:GetXY()` gives 0.5457, 0.6802; `GetMapInfo` returns mapType 3 (city), parent 1414 [file]. Native `GetWorldPosFromMapPos` / `GetMapPosFromWorldPos` exist [file] | Confirmed; HereBeDragons not needed for world coordinates |
| 12 | Mail, trade, loot functions as globals | Probe design | `GetInboxItem`, `GetInboxHeaderInfo`, `TakeInboxMoney`, `GetPlayerTradeMoney`, `GetTargetTradeMoney`, `GetLootSlotInfo` exist [file], alongside `C_Mail`, `C_TradeInfo`, `C_Loot` | Confirmed; mixed API era, each family needs its own check |
| 13 | Kill detection via the combat log event | Architecture 7.4 | Never registered by v0.1.2 [file]. Restriction itself was NOT observed; it is inferred from the earlier popup | Design must not depend on it (D-030). Restriction unproven |
| 14 | pcall makes RegisterEvent a safe probe | Probe.lua v0.1.0-0.1.1 | The client blocks restricted events with a popup that pcall cannot suppress [reported] | Wrong; fixed (D-025) |
| 15 | `C_EventUtils.IsEventValid` exists | D-025 | Present; sanity check on a fake name returned false; all tested real names valid [file] | Confirmed; the D-025 policy works |
| 16 | Secret values may exist | Risk | `issecretvalue` and `C_Secrets` exist; GUID and money are not secret in an idle city [file] | Exists; contextual behavior unknown |
| 17 | Ace3 / HereBeDragons may be absent | D-021 | All six library probes ok [file] (62 addons installed; they come from other addons) [inferred] | Present here, not guaranteed for other users |
| 18 | SavedVariables persistence | Phase 1 design | `GoldIntelDB.compat` written; Diag `loads = 3` [file] | Confirmed |
| 19 | `GetAddOnMetadata` returns Interface | Diagnostics B5 | Interface and SavedVariables metadata come back blank; Version works [file] | Wrong (diagnostics only) |
| 20 | `GetAddOnInfo` global | Diagnostics | Global is nil; `C_AddOns.GetAddOnInfo` returns 6 values, `loadable = true`, no reason [file] | Confirmed modern |
| 21 | `UnitName('player')` returns (name, realm) | Assumed | Returned 'Rehgar' and 'Deadeye'; the second value is not a realm [file] | Unexplained; Unit.lua uses only the first value |
| 22 | Event registration success = no pcall error | Events.Bind | A silently blocked registration also returns normally [inferred], so `event.X = true` does not prove delivery | Gap (Phase 1 exception E1) |
| 23 | Tests on Lua 5.3 predict 5.1 behavior | D-022 item 8 | 8 of 8 sources compile and run in real 5.1 [file] | No divergence observed; still run tests on 5.1 when possible |

## 3. Incorrect assumptions discovered (mine)

1. **Classic-era API surface and Interface 11508.** I built Phase 1 and Architecture section 11 around Classic Era names. The real client is a modern engine (D-023).
1. **`pcall` as a probe for protected calls.** Cost one real-client failure (D-025).
1. **My own delivery was the cause of the first failure.** Loose file cards instead of a package; three GIMin files and two Diag files never delivered (D-026). My S-003 analysis called the cause unproven and shipped a defensive patch instead of checking my own delivery first.
1. **Combat-log-based kill detection** in the Activity design. Cannot be relied upon.
1. **'Realmless'** taken from press coverage. The beta has a named realm.
1. **Legacy adapters** (skill lines, `QueryAuctionItems`, legacy trade skills) were built or planned although the target client has none of them.
1. **Diagnostics B5** expected `GetAddOnMetadata('Interface')` to return 16001; it is blank.
1. **Unit test comment** that SKILL_LINES_CHANGED may be missing; it exists.
1. **Contracts drift:** I shipped v0.1.2 code (`EventNameValid`, `IsSecret`, `RESTRICTED_EVENTS`, three-state probe, `compat.status`) without updating Contracts.md. That violates the governance rule that Contracts is the source of truth. Corrected in this session (Contracts 1.2).

## 4. The specific findings you asked about

**Lua behaves as 5.1 despite modern APIs.** Not actually surprising: retail WoW has always run Lua 5.1; modernization happened in the API, not the language. The result closes the biggest worry of S-003 (that my 5.3 tests proved nothing about syntax). Practical notes: `load` is nil here, so any code or tool that assumes `load` fails (use `loadstring`, and GoldIntel uses neither); `table.unpack` is nil, so the lint rule against it was right; `math.pow`, `setfenv`, `getfenv` exist but must not be used. Rules C-1 to C-6 stay as cheap hygiene, but they were not what caused the first failure.

**C_Secrets and issecretvalue() are available.** Confirms the 12.x restriction system exists. The probe readings (`false` for GUID and money) come from an idle city, so they say nothing about combat, encounters or instances. `C_RestrictedActions` existing suggests restrictions are stateful [inferred]. Consequence: the guards added to Money, Unit and Map stay mandatory, and must be extended to every Phase 3 payload reader (chat text, loot, mail, trade). It also vindicates the Money design: it reads the live balance and never parses chat text or combat events, so it has the least exposure to restricted data.

**272 C_ namespaces.** Shows how large the modern surface is, but namespace presence is weak evidence: `C_Housing` exists in a Classic-era game, so a namespace can be an unused stub. Treat every `ok` capability as 'API present', not 'feature works'. Two probes are particularly weak: `auction.modern` and `tradeskill.modern` only check that the namespace is a table. Several namespaces are directly useful: `C_AddOnProfiler` (measure GoldIntel's CPU for NFR-3), `C_EventUtils`, `C_Container` (bags for the asset ledger), `C_Mail`, `C_TradeInfo`, `C_Loot`, `C_MerchantFrame`, `C_Map` (native world position).

**COMBAT_LOG_EVENT_UNFILTERED restricted or avoided.** It is **avoided by policy**, not **observed as restricted**. The only evidence of restriction is the earlier popup, whose event name was never reported, and v0.1.0-0.1.1 probed 29 events. Twelve of them are the ones v0.1.2 registers without a reported popup, which leaves 17 candidates for the culprit: the combat-log event is one of them, together with every loot, merchant, mail, trade, quest, auction, chat-money and spell event Phase 3 needs. So the popup does not single out the combat log; it singles out the whole group. `IsEventValid` says the name is valid. Namespaces `C_CombatLog`, `C_DamageMeter`, `C_SwingTimer`, `C_EncounterEvents` exist and probably reflect Blizzard providing first-party combat data while limiting raw access [inferred]. Next step: `/gidiag reg COMBAT_LOG_EVENT_UNFILTERED` and the function listing F1 below. Until then, Phase 3 must assume no combat log.

**Modern C_AuctionHouse present, legacy absent.** The legacy adapter is dead code in Forever. Modern AH separates commodities and items with different deposit functions (`CalculateCommodityDeposit` by itemID, `CalculateItemDeposit` by item location), throttles queries (`IsThrottledMessageSystemReady`) and offers a replicate family. The design assumed one `Deposit(itemRef, duration)`; that contract must change in Phase 6. The auction cut rate, deposit values and whether Forever's AH is commodity-based in practice are unknown; `AuctionHouseFrame` is nil until an auction house is opened (load-on-demand). 'ok' here means only the API exists.

**Modern C_TradeSkillUI present, legacy absent.** Craft profitability stays deferred (A-1), and this makes it larger than assumed: modern recipe and reagent data (quality tiers, optional reagents) may or may not apply to a Classic-era ruleset. Do not plan it until a probe shows real recipe data.

**GetProfessions() exists, skill-line APIs do not.** Unit.lua already tried `GetProfessions` first, so the right path runs. But no profession value appears anywhere in the evidence, so the third return of `GetProfessionInfo` as the rank is unconfirmed, and the skill-line adapter (about 100 lines, plus its tests and probes) is now dead weight. Recommend removing it (D-027).

**Scheduler selected C_Timer.** As expected. The OnUpdate backend is never exercised live in Forever; it remains tested by unit tests only. Keep it as a cheap fallback, or remove it if you want less surface. `NewTimedSignalMap` is new and unused.

**All Platform files compiled in the live client.** Closes syntax, grammar and file-integrity doubts for good: 8 of 8, sizes match what I shipped, and `P.VERSION` reported 0.1.2 proves the installed code is the current build. Also proves the original failure was packaging, not content.

**No event registration failures.** True but weaker than it sounds. `Events.Bind` records `event.X = true` when `RegisterEvent` does not raise, and a silently blocked registration does not raise. So 'none failed' proves the 12 calls returned normally, not that each event is delivered. Only `PLAYER_MONEY` has proven delivery (it fed `P_MONEY`). The other 11 should be verified live (E1, E2).

**Money tracking validated in game.** The most valuable result, and the foundation of the architecture. Caveats: reported not attached; the gap path (`gap = true` at loading screens), the zero-delta path and large values are unobserved; and attribution (which source caused a delta) is Phase 3 and still unproven.

## 5. Other findings you may have missed

- **Interface tracks the client version.** 1.60.1 -> 16001 [inferred]. Every client patch changes the number and an exact `## Interface: 16001` TOC becomes 'out of date' (D-028, R-04).
- **WOW_PROJECT_ID is 18**, a value outside the known Classic/retail constants. Libraries that branch on project ID may misdetect this client.
- **Classic Era map IDs on a modern engine.** Orgrimmar 1454 and Kalimdor 1414 look like Classic Era numbering [assumed from memory]; retail uses different IDs. Heatmap keys by `mapID` are fine; no retail ID tables.
- **Native world-coordinate conversion exists** (`GetWorldPosFromMapPos`, `GetMapPosFromWorldPos`, `GetMapRectOnMap`, `GetMapWorldSize`), so HereBeDragons is probably unnecessary for the world heatmap.
- **A named beta realm exists** ('Classic Beta PvE'), and the GUID server field is 4618. The launch realm model is unknown (R-08).
- **`UnitName('player')` second return is 'Deadeye'**, not a realm. Unexplained; may be a Forever-specific attribute worth a look later.
- **Forever-specific systems may be visible**: `C_Seasons`, `C_Reincarnation`, `C_LevelLink`. They could matter for the Hardcore/season tagging promised in D-007. Not probed yet (F2).
- **Mixed API generations**: mail, trade and loot still expose legacy global functions next to modern namespaces. Never assume a whole family has moved.
- **Libraries are present here only because other addons provide them** (62 addons installed). Do not infer that users have them. Ace3 is not needed for Core at all (own bus).
- **The probe checks presence, not behavior** for most families. A future 'behavior probe' (open AH, mailbox, trade) belongs to the phase that needs it.
- **29 seconds** separate Diag's `ADDON_LOADED` (14:55:03 UTC) from GoldIntel's login probe (14:55:32 UTC). With 62 addons I cannot attribute that to GoldIntel; measure with `C_AddOnProfiler` before drawing any conclusion.
- **The money validation is the only live event proof.** Everything else listed as 'works' is an API-presence or return-value check.
- **`GoldIntelDB` currently contains only `compat`.** Phase 2 Store must preserve it (D-022 item 6). The report is about 3 KB, rewritten each login.

## 6. Architecture updates to document

Recorded in Decisions D-027 to D-031 (proposed) and Compatibility_Notes.md; Architecture.md section 11 and 7.4 now carry pointers.

- **Modern-API-only adapters** for auction, trade skills and professions; remove legacy paths (D-027).
- **Auction contract**: `Platform.Auction.Available()` returns only `'modern'`; deposit is split commodity/item; scanning must respect throttling. Detail in Phase 6.
- **Activity detection without the combat log** (D-030): candidate signals to verify, none decided: loot window with creature source GUIDs, experience-gain events, `C_CombatLog` / `C_DamageMeter` outputs, `LOOT_OPENED` context.
- **Reconciler must not depend on chat text** or any payload that can be secret; deltas from `GetMoney` stay the ground truth. Loot attribution uses context (loot window open) not text parsing.
- **Secret-value handling** generalized: every Platform reader of client data goes through `IsSecret` (Phase 3 extends it to events).
- **Heatmap**: native C_Map world conversion; zone maps from `GetBestMapForUnit`; instances give no position.
- **Identity**: GUID remains the key; realm text is an attribute at most; `serverID` could be stored but is not needed.
- **Interface-number policy** (D-028) and **per-event verification before Phase 3** (D-029).
- **Performance measurement** through `C_AddOnProfiler` (verify function names with F1).
- **Contracts 1.2** documents what shipped in 0.1.2 (done this session).

## 7. Compatibility decisions to revise

| Decision | Revision |
|---|---|
| D-021 Ace3/HereBeDragons optional | Keep 'optional, degrade gracefully'. Additionally: HereBeDragons is not needed (native C_Map conversion) and Ace3 is not needed for Core. Default plan: no library dependency at all. |
| D-023 Target client | Add: Interface number equals the encoded client version and changes per patch (D-028). Beta realm names exist. |
| D-016 degrade policy | Refined by D-025: three-state results; `unknown` never counts as available. No change needed beyond documentation. |
| D-006 GUID identity | Keep. Add note that realm strings exist in the beta. |
| D-008 subzone key | Keep. Classic Era subzone text works ('Valley of Strength'). |
| D-022 item 8 (tests on 5.3) | Real runtime is 5.1. Keep the rule 'tests assume 5.1 semantics'; run the suite on 5.1/LuaJIT whenever one is available. |
| D-024 hygiene rules | Keep as cheap hygiene. Note: not the cause of the original failure. |
| Architecture 7.4 GRIND rule | Replace 'kills > 0 in last 60 s' (needs the combat log) with a signal chosen in OI-8. |
| Requirements FR-SRC-1 | No text change needed (it says mob kills and their loot, not how to detect them); detection method changes only. |

## 8. Phase 1 bugs and weaknesses still remaining

| ID | Item | Severity | Fix |
|---|---|---|---|
| E1 | `Events.Bind` cannot detect a silently blocked registration; `event.X = true` only means 'did not raise' | Medium | After `RegisterEvent`, check `frame:IsEventRegistered(event)`; set the capability false and log on mismatch. Small patch plus tests (the fake client already supports it) |
| E2 | Live behavior of `P_ZONE`, `P_TICK`, `P_LEVEL`, `P_PROFS`, `P_COMBAT` and of `Platform.Player()` / `Where()` / profession reading has not been observed. No read-only command prints them (the namespace is private, `/dump` cannot reach it) | Medium | Diagnostics only: extend GoldIntelDiag `/gidiag run` to print Player/Where/Professions and capture 20 s of events in the sandbox. No GoldIntel code change. Or use `/gi debug on` + `/gi debug ticks` and walk, zone, fight, level |
| E3 | Legacy adapter code: skill-lines reader, `prof.skilllines`/`prof.expand`/`tradeskill.legacy`/`auction.legacy` probes | Low | Remove (D-027); or leave and document as deprecated |
| E4 | Contracts.md was behind the shipped code | Low (process) | Fixed in this session (Contracts 1.2) |
| E5 | `## Interface: 16001` will go stale at the next client patch | Low | Policy decision D-028 (TOC list or per-patch bump) |
| E6 | Unit/Map/Money paths never run in combat, instances or with secret values | Low-Medium | Exercise during E2; guards exist and are unit-tested |
| E7 | 1-hour soak (memory and CPU) never run in the real client | Low | Measure with `C_AddOnProfiler` during Phase 2 or 9 |

No functional bug in the delivered Phase 1 behavior was found in the evidence.

## 9. Phase 1 acceptance scorecard

| Criterion | Status | Evidence |
|---|---|---|
| Automated suite passes (245 tests) | PASS | Dev zip; run on Lua 5.3 (real 5.1 compile 8/8 [file]) |
| Real client: loads with no Lua error | PASS [reported] | `operational: yes`, `diag=0`; please confirm no popup |
| `/gi probe` prints the capability table | PASS [file] | `compat.report` written |
| Money change produces `P_MONEY` | PASS [reported] | Vendor sale and buyback |
| Probe output delivered (OI-1) | PASS [file] | GoldIntel.lua |
| FR-PLT-1 no WoW API outside Platform | PASS | Static test C-5/boundary |
| FR-PLT-2 probe at startup, degrade per feature | PASS [file] | 4 missing, 1 unknown, operational |
| FR-PLT-3 GUID key | PARTIAL | `identity.guid ok` and GUID read in Diag; `Platform.Player()` output not observed (E2) |
| Acceptance criterion 5 (one capability off, rest works) | PASS [file] | Legacy families absent and addon fully operational |
| Live delivery of non-money events | NOT SHOWN | E2 |
| Registration verification | GAP | E1 |

## 10. Open issues: what can close

| ID | Status after this review |
|---|---|
| OI-1 WoW Forever API discovery | **CLOSE as scoped.** Build, interface, capability inventory, Lua version, namespaces and Phase 1 events are all measured. Residual unknowns moved to OI-8 and OI-9. |
| OI-6 original load failure | Already resolved (packaging, D-026). Also confirmed by 8/8 compile in the live client. |
| OI-7 restricted events | **Re-scope** into OI-8. Evidence: the 12 registered events raised no failure and no popup is reported; the earlier popup's event is still unidentified. |
| OI-8 (new) Restriction model and Phase 3 signals | Open. Needs: per-event registration tests for every Phase 3 event, the restriction namespaces' contents, and a combat-log-free activity signal. |
| OI-9 (new) Live validation of Unit/Map events and readouts | Open (E2). |
| OI-10 (new) TOC interface policy across patches | Open (D-028). |
| OI-11 (new) Re-probe after each client patch and at launch | Open; protocol in Compatibility_Notes.md. |
| OI-5 merge outside documents | Still open; not addressed. |
| D-022, D-024, D-025, D-026 | Validated by operation in the live client; explicit confirmation still requested. |
| A-4 subzone key | Still unconfirmed by you; supported by evidence (Classic Era subzone text works). |

## 11. Confidence assessment

My judgment that each component will work as designed in the live client without redesign. Not a measurement.

| Component | Before | Now | Why |
|---|---|---|---|
| Platform layer / capability model | 60% | 90% | Loaded, probed, degraded correctly, compiled live |
| Money signal and ledger input | 60% | 90% | Live deltas; secret-safe design |
| Reconciler / source attribution | 55% | 65% | Signal proven; loot/vendor/quest context events unverified (OI-8) |
| Activity engine (grind) | 50% | 35% | Combat-log design invalid; new signal needed |
| Session / Metrics / Rankings (pure logic) | 85% | 90% | Independent of the client |
| Store / SavedVariables | 75% | 85% | Persistence proven; `compat` coexistence still to handle |
| Heatmap / Map | 60% | 75% | Positions, map info, native world conversion all work |
| Pricing / Auction | 50% | 55% | Modern API present, shape differs from the design, behavior untested |
| UI | 55% | 60% | Untested live (copy window result not reported) |
| Process (delivery, evidence, docs) | 40% | 75% | Packages, evidence folder, contracts corrected |
| **Overall architecture** | **50-55%** | **~70%** | Large unknowns removed; the main remaining risks are all in Phase 3 |

## 12. Lessons learned

- **Deliver packages, never loose files** (cost two sessions). Verify the TOC against the package before sending.
- **Never use error catching as a probe for protected calls.** `pcall` does not hide a taint popup.
- **Check your own side first.** The first hypothesis should have been 'my delivery', not a defensive code patch.
- **Run one real-client smoke test before building nine modules.** A 20-line probe addon would have revealed the interface number, modern API, and restrictions on day one.
- **Tag every claim with its evidence tier** (file, reported, inferred, assumed). This review does it; the Compatibility Notes keep an evidence ledger.
- **Contracts must change with the code**, in the same change. I broke this once (0.1.2).
- **Diagnostics must be as safe as production code.** My own Diag registered the restricted event too.
- **Namespace present does not mean feature works.** Behavior probes belong to the phase that needs the feature.
- **A different Lua version gives false assurance.** The live compile check closed what 245 tests on 5.3 could not.
- **Prefer measuring to parsing.** Money from the live balance survived every client surprise; anything based on chat or combat events would not have.
- **Don't assume press descriptions are API facts** ('realmless').

## 13. Recommendation and Phase 2 go/no-go

**Phase 1: complete with exceptions.** The formal exit test is met; the exceptions (E1-E7) are non-blocking for Phase 2 and are tracked.

**Phase 2 (Core + Store only): CONDITIONAL GO.** Phase 2 builds the module registry, bus, config, slash commands, SavedVariables store and migrations, the Future stubs and the test harness. It uses SavedVariables (proven) and no unverified client surface, so the remaining client risks do not threaten it.

Conditions before you approve Phase 2:

| # | Condition | Type |
|---|---|---|
| X1 | You explicitly confirm: no ADDON_ACTION_FORBIDDEN popup and no Lua error (BugGrabber / scriptErrors) in the latest session | Must |
| X2 | You accept or change D-022, D-024, D-025, D-026 (the AI-made decisions now validated in the live client) | Must |
| X3 | You decide D-027 (remove legacy adapters now, in Phase 2 housekeeping, or never) and D-028 (TOC interface policy) | Must (a decision, not work) |
| X4 | E2: live evidence of P_ZONE/P_TICK/P_LEVEL/P_COMBAT and of Player()/Where()/professions (small diagnostics-only change, or a 60-second manual run with `/gi debug on`) | Should, before Phase 2 ends |
| X5 | E1: registration verification via `IsEventRegistered` (small Phase 1 patch with tests) | Should, before Phase 2 ends; hard gate for Phase 3 |

**Phase 3 (Collector): NO-GO** until OI-8 is closed: every event Phase 3 needs tested one at a time (`/gidiag reg NAME`), the restriction namespaces inspected (F1), a combat-log-free grind signal chosen, and secret-value behavior observed in combat and an instance (F3).

## 14. Follow-up diagnostics (read-only; safe)

Run these in the client and attach the output when convenient. Each is at most 255 characters and syntax-checked.

**F1**: Contents of the restriction and event namespaces (answers how restrictions are expressed and which profiler functions exist)

```
/run for _,n in ipairs({"C_Secrets","C_RestrictedActions","C_CombatLog","C_EventUtils","C_AddOnProfiler"}) do local t={} for k in pairs(_G[n]) do t[#t+1]=k end table.sort(t) print(n,#t,table.concat(t," ")) end
```

**F2**: Forever-specific and loot/vendor namespaces

```
/run for _,n in ipairs({"C_Seasons","C_Reincarnation","C_LevelLink","C_SkillInfo","C_Loot","C_MerchantFrame"}) do local t={} for k in pairs(_G[n]) do t[#t+1]=k end table.sort(t) print(n,#t,table.concat(t," ")) end
```

**F3**: Secret-value behavior; run it again IN COMBAT and inside an instance and compare

```
/run print(issecretvalue(GetMoney()),issecretvalue(UnitGUID("player")),issecretvalue(UnitHealth("player")),issecretvalue(GetZoneText()))
```

**F4**: Profession readout (the one value never captured)

```
/run for i=1,5 do local x=select(i,GetProfessions()) if x then print(i,x,GetProfessionInfo(x)) end end
```

Also: `/gidiag reg COMBAT_LOG_EVENT_UNFILTERED` (opt-in; a blocked-action popup naming it proves restriction), then `/gi debug on`, walk across a subzone boundary, change zone, fight something, and send the chat lines (`/gi debug ticks` toggles tick echo).

