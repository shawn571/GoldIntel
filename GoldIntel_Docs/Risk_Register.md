# GoldIntel Risk Register

DOC VERSION: 1.1.0  |  DATE: 2026-10-10 (updated for Phase 2)  |  Likelihood and impact are my judgment: L/M/H.

| ID | Risk | L | I | Evidence | Mitigation | Owner phase | Status |
|---|---|---|---|---|---|---|---|
| R-01 | Events Phase 3 needs (loot, merchant, mail, trade, quest, auction, chat money) turn out to be restricted for addons | M | H | The earlier popup came from probing 29 events; the culprit is one of the 17 not registered by v0.1.2, which are exactly the events Phase 3 needs; none has been tested individually | Test each with `/gidiag reg NAME` before design (D-029); registration verification (E1) | Pre-Phase 3 | Open (OI-8) |
| R-02 | No usable combat log, so grind detection and some activity logic must be redesigned | H | M | Combat-log event never registered; restriction suspected, unproven | Choose another signal (D-030); inspect C_CombatLog / C_DamageMeter (F1) | Pre-Phase 3 | Open (OI-8) |
| R-03 | Secret values appear in combat, encounters or instances and break comparisons or arithmetic | M | H | issecretvalue and C_Secrets exist; readings were idle-city only | IsSecret guards in Money/Unit/Map (done); extend to Phase 3 payloads; observe in combat and an instance (F3) | Phase 1 E6, Phase 3 | Open |
| R-04 | Interface number changes with every client VERSION change; TOC shows out of date | M | L | Interface 16001 = encoded version 1.60.1. Observed 2026-10-15: a hotfix build (70338 to 70374) kept version 1.60.1 and Interface 16001, so only version changes matter | Policy D-028 (still Proposed); release checklist; verify TOC multi-value support | Before Phase 3 | Open (OI-10) |
| R-05 | Modern auction house complexity (commodity vs item deposit, throttling, replicate availability, unknown cut and deposit values) | M | M | 85 functions; two deposit functions; AuctionHouseFrame nil until opened | Redesign Platform.Auction contract in Phase 6; behavior probe at an auction house first | Phase 6 | Open |
| R-06 | Modern trade-skill data may be far larger than planned (craft ranking) | L | M | C_TradeSkillUI present, legacy absent, no recipe data seen | Keep deferred (A-1); probe real recipe data before planning | Post-v1 | Accepted |
| R-07 | Single-sample evidence: one build, one character, idle city | M | M | All evidence comes from one session | Re-verification protocol; more contexts (combat, instance, AH, mail, trade) per phase | All | Open |
| R-08 | Beta-to-launch drift (realm model, API, interface, build) | H | M | Beta realm 'Classic Beta PvE'; launch 2026-11-04 | Re-probe at launch (OI-11); keys never depend on realm | Launch | Open (OI-11) |
| R-09 | Registration success unverified; a silently blocked event looks registered | M | M | Events.Bind trusted 'did not raise' | IsEventRegistered check implemented in Phase 2 (D-034) with tests; fail-safe for the 12 live-proven events. Residual risk is R-26 | Phase 2 | **Mitigated in code; live check pending (OI-12)** |
| R-10 | Optional libraries present only through other addons; users may lack them | M | L | Probe found all six; 62 addons installed | No required dependency (D-021); default plan uses none | Phase 2 | Mitigated by design |
| R-11 | Test runtime (5.3) differs from the real runtime (5.1) | L | L | 8/8 compile and run live | Keep 5.1 lint rules; run suite on 5.1/LuaJIT when available | All | Accepted |
| R-12 | Namespace presence mistaken for feature support | M | M | C_Housing present in a Classic-era game; weak probes for auction/tradeskill | Behavior probes in the phase that needs a feature | All | Open |
| R-13 | WOW_PROJECT_ID 18 breaks libraries or code that branch on known IDs | L | L | Value 18 observed | Never gate on project ID | All | Mitigated |
| R-14 | Process repeat: unverified assumptions, loose-file delivery, contract drift | M | M | Three failures traced to process in S-002 to S-004 | D-026 packages; D-031 evidence tiers and contracts-with-code; one verified step at a time | All | Mitigated |
| R-15 | Unattributed login delay (29 s between Diag load and GoldIntel login probe in a 62-addon environment) | L | L | Timestamps in the evidence | Measure GoldIntel CPU with C_AddOnProfiler before concluding anything | Phase 2 or 9 | Open |
| R-16 | `UnitName('player')` second return unexplained; may signal a Forever-specific attribute | L | L | Returned 'Deadeye' | Investigate when Unit is next touched | Phase 2+ | Open |
| R-17 | Legacy dead code (skill-lines adapter, legacy probes) adds maintenance and test surface | H | L | Legacy APIs absent | Remove (D-027) | Phase 2 housekeeping | Proposed |
| R-18 | GoldIntelDB currently holds only `compat`; Store may overwrite it | L | M | Evidence file shows only `compat` | Implemented (D-036): staged migration, compat deep-equality check, identity kept; tested on the real captured database and by mutation | Phase 2 | **Mitigated in code and tests; live check pending (OI-12)** |
| R-19 | A migration copies the whole database once at login; cost grows with saved sessions | L | M | Staged migration deep-copies the database (D-036). Today about 5 KB | Step migrations stay small; Phase 5 roll-up and the size budget bound growth; measure with C_AddOnProfiler before the first big migration | Phase 5 | Open |
| R-20 | `/gi` collides with another addon's slash command | L | L | Single registration of `/gi` | Make the alias configurable if a collision is ever reported | Phase 8 | Accepted |
| R-21 | The client writes SavedVariables only at logout or reload; a crash loses the session's unsaved data | M | M | Platform limit (D-007); runtime snapshots are only evidence, not protection | `/gi checkpoint` reminds; nothing can force a write; keep data small | All | Accepted |
| R-22 | Read-only or degraded database confuses users (settings not saved) | L | M | New modes (D-036) | Explicit messages in `/gi config set`, `/gi db`, chat on degrade | Phase 2 | Mitigated |
| R-23 | Capability level 'registered' or 'delivered' is mistaken for 'safe to depend on' | M | M | Stage model (D-034) | `Usable()` is true only for payloadUsable or present; D-029 gate for Phase 3 | Phase 3 | Open |
| R-24 | Settings exist for features not built yet (idleSec, minSegSec, ...) and mislead users | L | L | Config defines the Contracts F6 keys | Help text names the phase that uses each; review before Phase 8 | Phase 8 | Accepted |
| R-27 | (Proposed, Phase 3 planning) Item data arrives late or never; valuations silently zero | M | M | Not yet built | `pendingInfo` window and visible `unknown` count (D-046) | Phase 3 | Proposed |
| R-28 | (Proposed) One lucky drop paints a false hot spot | M | M | Not yet built | Top-single-drop disclosure, optional cap (D-047) | Phase 7 | Proposed |
| R-29 | (Proposed) Idle heuristics mislabel legitimate waiting (respawn waits) | M | L | Not yet built | Manual pause; per-activity exemption if needed (D-049) | Phase 4 | Proposed |
| R-30 | (Proposed) Inventory diff misattributes items (loot, purchase, mail) | M | M | Not yet built | Context stamping; diff only at defined boundaries | Phase 3 | Proposed |
| R-31 | (Proposed) Account-best heat: a single outlier in a thin bin becomes the account best | M | M | Not yet built | Shared confidence floor and minimum active seconds in both scopes (D-061); show date and sample count in the tooltip |
| R-32 | (Proposed) Account-best heat goes stale after price or patch changes | M | L | Not yet built | Show date and valuation basis; optional recency window setting |
| R-33 | (Proposed) Instance accounting depends on signals not yet verified (entrance position, run boundaries) | M | M | Not yet built | Phase 3a S1 instance run and the P1 name lists; fall back to last open-world position before the loading screen |
| R-25 | Core, Store and the stage model have not been fully validated in the real client | M | M | **Further validated 2026-10-17 (build 70450)**: second session `store=ok opens=4`, combat events delivered, libraries-off run operational, installed files verified identical. **Partly validated 2026-10-15**: Store migrated the real database, Core started cleanly with `diag` empty, snapshot and checkpoint were saved at logout. Not yet validated: money/zone/level delivery, config persistence, sandbox run, blocked-event case. 482 fake-client tests | Phase2_Runtime_Validation_Plan.md (V0 to V10) | Phase 2 closure | Open (OI-12) |
| R-26 | `IsEventRegistered` behaves differently in the real client than modeled (the check could wrongly report 'blocked') | L | H | **Positive case CONFIRMED live (2026-10-15): returned true for all 12 registered events, no warning.** The blocked case is still unobserved. Fake client models the described blocked-registration behavior | `P.TRUSTED_EVENTS` fail-safe so the 12 proven events cannot be disabled by the check; strict only for unproven events; validation step V2 reads the result for all 12 | Phase 2 closure | **Mostly resolved for registered events; blocked case untested (Phase 3 events)** |
| R-27 | The external review documents were not seen; findings beyond the six relayed are unevaluated | M | L | Only six findings relayed | Provide the documents (OI-13) | Next review | Open |

## Retired / closed

| ID | Risk | Closed because |
|---|---|---|
| R-X1 | Source files may not compile in the live client | Compiled 8 of 8 in the live client (E-10) |
| R-X2 | Lua version may not be 5.1 | Confirmed 5.1 (E-04) |
| R-X3 | SavedVariables may not persist | Persistence proven (E-11) |
| R-X4 | Capability probe may itself break the client | Fixed in 0.1.2; no popup reported (E-02, E-12) |
| R-X5 | Original load failure unexplained | Packaging, confirmed by user and by live compile |
| R-X6 | Phase 2 scope creep into Phase 3 | Tests assert no reserved Bus event is fired, only the two placeholder modules exist, no new raw events are registered, and the Store holds no collected data |
