# GoldIntel Risk Register

DOC VERSION: 2.0.0  |  DATE: 2026-11-20 (R-35 updated, R-38 added, D-120; reviewed against live play 2026-11-16, D-119)  |  Likelihood
(L) and impact (I) are Claude's judgement: L/M/H. Evidence numbers (E-nn) are in Compatibility_Notes.md.

## Open and accepted risks

| ID | Risk | L | I | Evidence | Mitigation | Phase | Status |
|---|---|---|---|---|---|---|---|
| R-03 | Secret values appear in combat, encounters or instances and break comparisons or arithmetic | L | H | `issecretvalue` and C_Secrets exist; no secret value reached GoldIntel in live play since launch (0 collector errors, groups and dungeons included) | IsSecret guards in every Platform adapter | All | Open (watch) |
| R-04 | The Interface number changes with a client version change and the TOC shows out of date | M | L | 16001 = version 1.60.1; launch and two patches (70790, 70862, 70938) kept it | Re-probe after each client patch (Compatibility_Notes section 8); update `## Interface:` (D-028) | All | Open |
| R-05 | Modern auction house complexity (commodity vs item deposit, throttling, cut and deposit values) | M | M | Deposit and cancel measured (E-35..E-40); AH buyouts are plain money changes | Behaviour checks before 3b-4 (AH deposits) and Phase 6 | 3b-4, 6 | Open |
| R-06 | Modern trade-skill data may be far larger than planned (craft ranking) | L | M | C_TradeSkillUI present | Craft ranking deferred (A-1) | Post-v1 | Accepted |
| R-12 | Namespace presence mistaken for feature support | M | M | C_Housing exists in a Classic-era game | Behaviour probe in the phase that needs a feature | All | Open |
| R-16 | `UnitName('player')` second return is a Forever-specific secondary name | L | L | Returned 'Deadeye'; Accountant Classic reads it as a secondary name | Never used as identity (GUID is) | All | Accepted |
| R-19 | A migration deep-copies the whole database once at login; cost grows with the saved data | L | M | The account file is about 2 MB (2026-11-14) | Small step migrations; retention plan (R-35); measure before the next schema migration | 5 | Open |
| R-20 | `/gi` collides with another add-on's slash command | L | L | None reported | Configurable alias if ever needed | 8 | Accepted |
| R-21 | The client writes SavedVariables only at logout, /reload or disconnect; a crash loses the unsaved period | M | M | A disconnect does save (2026-11-07); a crash does not | Reload reminder popup with evidence-based bands (0.6.1, D-115); login gaps keep the money exact | All | Mitigated (0.6.x) |
| R-24 | Settings exist for features not built yet and mislead users | L | L | Config defines future keys | Help text names the phase; review before Phase 8 | 8 | Accepted |
| R-26 | `IsEventRegistered` reports wrongly in a blocked case | L | H | Positive case confirmed live; the blocked case was never seen | Fail-safe for the trusted events (D-034) | All | Open (low) |
| R-28 | One lucky drop paints a false hot spot | M | M | Not built yet | Top-single-drop disclosure, optional cap (D-047) | 7 | Open |
| R-29 | Idle rules mislabel legitimate waiting (respawn waits) | M | L | Phase 4 time classes in live validation | Manual pause and AFK; per-activity exemption if needed (D-049) | 4 | Open |
| R-31 | Account-best heat: one outlier in a thin bin becomes the account best | M | M | Not built yet | Confidence floor and minimum active seconds (D-061) | 7 | Open |
| R-32 | Account-best heat goes stale after price or patch changes | M | L | Not built yet | Show date and valuation basis; optional recency window | 7 | Open |
| R-33 | Instance accounting: inside an instance the map id is nil, only the zone name is known | M | M | Ragefire Chasm 2026-11-05 | Place instance runs at the entrance (D-060); design in Phase 7 | 7 | Open |
| R-35 | The saved data grows; load, /reload and logout get slower | H | M | Account file 2.0 MB (2026-11-14) -> 3.9 MB (2026-11-20): ledger 1.8 MB, lots 1.2 MB, agg 0.7 MB, heat 0.2 MB; Paladin 4,762 cash entries, 1,276 open lots; /reload frames 100-178 ms | Plan_Retention_and_Realm_Scope.md part B (7-day raw window plus daily summaries, stale-lot rule, segment cap, test-mode switch), plan only (D-120) | 4, 5 | Open |
| R-38 | Realm-dependent data mixes realms: the manual price (`/gi price`) is account-wide by item id; later market prices and account-wide views would mix realms whose prices differ | M | M | Four realms with separate GUID server numbers (6796, 6800, 6928, 6935); `GetRealmName()` returns "" since build 71037; `prices.manual` empty today | Key realm-dependent data by the GUID server number, never by realm name (Plan_Retention_and_Realm_Scope.md part A), plan only (D-120) | 5, 6 | Open |
| R-36 | A client patch changes an API or an event's behaviour | M | M | Three builds since launch, no change seen so far | Re-probe after each patch; `/gi probe` lists every capability | All | Open |

## Mitigated by design or by the code (kept for reference)

| ID | Risk | How |
|---|---|---|
| R-02 | No usable combat log | Grind detection uses loot and money signals (D-030); the combat log is never registered |
| R-09 | A silently blocked event looks registered | IsEventRegistered check and stage model (D-034); live positive case confirmed |
| R-10 | Optional libraries only present through other add-ons | No required dependency (D-021) |
| R-11 | Test runtime (5.4) differs from the client (5.1) | Every addon file is parse-checked with Lua 5.1 before a build; 5.1 lint rules |
| R-13 | WOW_PROJECT_ID 18 breaks code that branches on known ids | Never gated on project id |
| R-14 | Process repeat: unverified assumptions, loose files, contract drift | Packages from clean checkouts (D-026), evidence tiers and contracts with code (D-031), standing orders |
| R-22 | Read-only or degraded database confuses users | Explicit messages (D-036) |
| R-23 | 'registered' or 'delivered' mistaken for 'safe to depend on' | Only verified events are used (AC-1, D-069) |
| R-27 | Item data arrives late or never; valuations silently zero | Pending window and visible unknown count (D-046); late values follow (0.6.0) |
| R-30 | The inventory diff misattributes items | Context stamping; unexplained items relabelled only (D-083) |
| R-34 | Other add-ons flood shared events (GET_ITEM_INFO_RECEIVED: 3,566 in a session, up to 1,999 in one second) and GoldIntel pays for each | Since 0.6.1 GoldIntel handles only item data it asked for (D-115); live check 2: no frame over 500 ms |
| R-37 | UI widgets and templates differ on Forever | 0.6.1 popup, reload from a button and the Settings window work live (D-117); every UI call is protected with a chat fallback |

## Retired / closed

| ID | Risk | Closed because |
|---|---|---|
| R-X1..R-X6 | Compile, Lua version, persistence, probe safety, first load failure, Phase 2 scope creep | Closed in Phases 1 and 2 (E-02..E-12) |
| R-01 | Events needed for the ledgers are restricted for add-ons | Every needed event was verified one by one (E-17..E-34) and has run in live play since launch |
| R-07 | Single-sample evidence (one build, one character, idle city) | Weeks of live play on several characters, groups, dungeons and three builds |
| R-08 | Beta-to-launch drift | Launch client re-probed 2026-11-04 (build 70790): every capability ok, Interface unchanged (OI-11) |
| R-15 | Unattributed login delay | GoldIntel's CPU is measured with the add-on profiler: 0.017 ms per frame on 0.5.6 (D-109) |
| R-17 | Legacy dead code | Removed (D-027, 3b-0) |
| R-18 | Store overwrites the probe data | Compat preserved live (D-036) |
| R-25 | Core, Store and the stage model not validated in the real client | Validated in Phase 2 and in live play since launch |
| R-27b | External review documents not seen (OI-13) | The multi-AI review model ended (D-119); reviews archived |
