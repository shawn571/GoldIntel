# GoldIntel Decisions

DOC VERSION: 1.0.0  |  DATE: 2026-10-09  |  Append-only. Supersede a decision by adding a new one that references it; never delete.

Status values: **Approved** (by the user's charter dated 2026-10-09, which states architecture is approved), **Approved-pending-confirm** (name approved, details proposed by an AI and awaiting explicit user confirmation), **Open**, **Superseded**.

Provenance note: D-001 to D-011 originate from the Part 2 architecture review (design spec doc "GoldIntel: WoW Forever Addon Design", Part 2, items R1-R11, R14). The charter states the resulting architecture is approved; recorded here as blanket approval.

Entry template:

```
ID | Title | Status | Date
Why: ...   Affected modules: ...   Migration: ...   Supersedes: ...
```

---

## D-001 Platform abstraction layer | Approved | 2026-10-09
Why: the Forever addon API is unconfirmed; modules must be testable without the client.
Affected: all. Only `Platform/` touches WoW globals. Everything else consumes normalized events and plain tables.
Migration: none.

## D-002 Two-ledger wealth model | Approved | 2026-10-09
Why: earlier draft double-counted loot (valued as income, then again when sold).
Affected: Collect (Reconciler, Lots), SessionEngine, Metrics, PricingEngine.
Rule: cash ledger = copper changes; asset ledger = lots. Sales and purchases are conversions, not income.
Migration: none (pre-release).

## D-003 Settlement bucket for delayed (mailed) income | Approved | 2026-10-09
Why: AH proceeds and COD arrive hours later and distort session GPH.
Affected: Collect, SessionEngine, Metrics, UI. Settlement entries carry `settle = true`, are excluded from GPH windows by default, and shown as "Settled".
Deferred: back-attribution of AH sales to the producing activity (provenance matching) is a post-v1 item.

## D-004 Expectation-based reconciliation of money changes | Approved | 2026-10-09
Why: attribution by UI context alone is brittle; event ordering is not guaranteed.
Affected: Collect (Expectations, Reconciler), diagnostics.
Rule: sources register expected copper; money deltas are matched within a **1.0 s** window (amended by D-065; originally 0.25 s); remainder becomes OTHER, low confidence. Invariant: entries sum to the delta.

## D-005 Heatmap credits only location-attributable income | Approved | 2026-10-09
Why: vendor, mail, and AH income would otherwise make towns the hottest cells.
Affected: HeatMapEngine. Credited activities: grinding, gathering, fishing. Time-in-bin is tracked for all activities.

## D-006 Character identity is the GUID | Approved | 2026-10-09
Why: Forever is realmless; Name-Realm keys are invalid.
Affected: Store, Platform.Unit, all keys. Name and faction are attributes.

## D-007 Durability and size budget | Approved | 2026-10-09
Why: SavedVariables are written only at logout or reload; whole DB loads at login.
Affected: Store, Pruner, Slash. Raw segments capped (default 90 days / 2 MB) then rolled into aggregates. `/gi checkpoint` and optional reload prompt. Crash-loss is documented, not solved.

## D-008 Subzone key = mapID + localized text + locale | Approved | 2026-10-09
Why: no stable subzone ID is known. Rankings merge only within a locale. Coarse region-cell fallback if no subzone text.
Affected: Rankings, HeatMapEngine, Store.

## D-009 Normalization is experimental, percentile-based | Approved | 2026-10-09
Why: the earlier a*L^b baseline was invented, not measured. Charter lists normalization as experimental.
Affected: Metrics, Rankings, UI. Hidden until minimum hours in bracket. Labeled "experimental".

## D-010 Sell-through probability is a labeled estimate | Approved | 2026-10-09
Why: no reliable competition model exists. Source: own list/sold/expired history, else user default; show low-confidence badge.
Affected: AHMath, PricingEngine, UI.

## D-011 Heatmap grid 32x32 with pooled textures | Approved | 2026-10-09
Why: render cost. Only non-empty bins drawn; rebuild on map change or filter change only.
Affected: HeatMapEngine, MapOverlay.

## D-012 Metric definitions: Cash / Wealth / Net GPH | Approved (confirmed by user as OI-2, 2026-10-09) | 2026-10-09
Why: the charter names three metrics but does not define them, and earlier drafts used the names inconsistently (Part 2 described Wealth GPH as the primary ranking metric including cash and inventory change).
Decision (proposed): Cash GPH = real cash flow; Wealth GPH = gross value creation; Net GPH = value creation minus expenses. Full formulas in Requirements_v1.md section 5. Rankings default to **Net GPH**; Cash GPH is always shown (charter).
Affected: Metrics, Rankings, SessionEngine, UI, tests.
Supersedes: Part 2 R1 wording "Wealth GPH is the primary ranking metric".
Migration: none (pre-release). Confirmed: user answered OI-2 "Approved as written".

## D-013 v1 scope aligned to the charter | Approved | 2026-10-09
Why: charter's v1 list is narrower than Part 2's scope table. Requirements_v1.md wins.
Effect: deferred from Part 2's v1: dungeon, rare, boosting, disenchant, vendor arbitrage, crafting profit, service activities, craft profitability ranking, world heatmap. Activity keys remain reserved in the enum (D-014 schema stays stable). See Requirements A-1, A-2, A-5. Confirmed: user answered OI-4 "Deferrals approved as written".
Supersedes: Part 2 section C scope table.

## D-014 Schema numbering restarts at 1 for the first released schema | Approved | 2026-10-09
Why: Part 1 draft showed `schema = 3` and Part 2 showed `schema = 4`, but nothing shipped; the numbers carry no migration meaning.
Rule: the first persisted release uses `schema = 1`. Increment only when a persisted shape changes after release.
Affected: Store, Migrations, Contracts section F5.

## D-015 Future-system placeholders: CommunityDataEngine and RouteEngine | Approved | 2026-10-09
Why: charter requires architecture placeholders only.
Effect: stub modules under `Future/` that register with Core and return `{ ok = false, err = 'NOT_IMPLEMENTED' }`. No logic, no persisted data, no UI. Must not be implemented without an explicit user instruction.
Affected: Core registry, file tree, Contracts section 8.

## D-016 Capability probing and degrade-not-crash policy | Approved | 2026-10-09
Why: unknown Forever API surface.
Rule: `Platform/Probe.lua` records capabilities in `GoldIntelDB.compat`; each Platform family has multiple adapters tried in order; missing capability disables only its feature with a UI explanation. Money API and PLAYER_MONEY are fatal-if-missing.
Affected: Platform, Core, UI.

## D-017 Price provider interface | Approved | 2026-10-09
Why: no guarantee of an AH scan API or third-party price addons in Forever.
Rule: PricingEngine consumes ordered providers (`Native`, optional adapters). Valuation is conservative by default and flags staleness. Affected: PricingEngine, AHMath.

## D-018 Document hierarchy and precedence | Approved | 2026-10-09
Per charter. Order and conflict table in Project_Bible.md sections 3. Requirements > Decisions > Architecture; newest handoff wins.

## D-019 Current phase is planning; implementation is not yet approved | Superseded by D-020 | 2026-10-09
Why: the charter says "if this is a planning phase, generate documents only; if implementation approval has been granted, work only on the current phase in TODO.md." No TODO.md and no implementation approval existed in the provided material.
Effect: this session produced documents only. Implementation of Phase 1 begins when the user records approval in TODO.md (or says so) and answers OI-1.

---

## D-020 Implementation Approval | Approved | 2026-10-09
Why: the user approved the architecture package (Project_Bible, Requirements_v1, Decisions, Architecture, Contracts, TODO) and explicitly granted implementation approval.
Scope: **Phase 1 only** (Platform and Probe). Phases 2-9 remain NOT approved; each needs its own recorded approval.
Phase 1 deliverables authorized: GoldIntel.toc, Platform.lua, Probe.lua, Events.lua, Clock.lua, Scheduler.lua, Unit.lua, Map.lua, Money.lua, plus tests for them.
Affected: TODO.md (IMPLEMENTATION APPROVED: YES, Phase 1), Session_Handoff.md, Changelog.md.
Supersedes: D-019.
Resolved with this approval: OI-2 (D-012 confirmed), OI-3 (D-021), OI-4 (D-013 confirmed). OI-1 stays open by user instruction until Forever beta probe data exists.

## D-021 Optional libraries policy (Ace3, HereBeDragons) | Approved | 2026-10-09
Source: user answer to OI-3: "Ace3 and HereBeDragons approved if available. Must degrade gracefully if unavailable."
Rule: Ace3 components and HereBeDragons-2.0 may be used when present and verified working in the Forever client. No module may require them: every use is guarded by a capability check (`Platform.Has('lib.*')`) and has a pure-Lua fallback. Absence is never an error.
Affected: Platform (detection in Probe), Core, Store, UI, HeatMapEngine (future phases).
Migration: none.

## D-022 Phase 1 implementation conventions | Approved-pending-confirm | 2026-10-09
Status note: Live validation 2026-10-10: conventions worked in the real client (namespace, env injection, Probe persistence, temporary /gi). Item 4 (interface placeholder) is obsolete (D-023). Awaiting your explicit confirmation.
Why: details the architecture left open that Phase 1 code must settle. Made by the implementing AI within Phase 1 authority; the user may overrule.
1. **Dependency injection for testability:** every Platform module reads WoW APIs only through `Platform.env` (defaults to `_G`). Tests substitute a fake environment. Bare WoW globals are forbidden even inside `Platform/` (enforced by the boundary test).
2. **Shared namespace:** all files start with `local ADDON, GI = ...` (the addon's private table); modules attach to `GI.Platform`.
3. **Libraries are not bundled in Phase 1.** The .toc declares them as OptionalDeps and `embeds.xml` is deferred to Phase 2 (task 1.1 amended). Detection via LibStub in Probe.
4. **Interface number is a placeholder** (`11508`) until OI-1 supplies the real value. Replace it first when probe data arrives.
5. **Temporary `/gi` slash handler lives in `Platform/Probe.lua`** (subcommands: probe, status, debug) so the Phase 1 exit test is possible before Core exists. Core/Slash.lua (Phase 2) must take it over and remove it from Probe.lua.
6. **Probe persists to `GoldIntelDB.compat`** at PLAYER_LOGIN. Store (Phase 2) must treat a `GoldIntelDB` that has `compat` but no `schema` as a new schema-1 DB and preserve `compat`.
7. **Additive contract changes (CONTRACT VERSION 1 to 1.1):** `Platform.OnReady`, `Platform.Off`, `Platform.Diag`; `Platform.Player()` gains `key` and `keyKind`; `Loc` gains optional `zone` and `mapID` may be nil when the map capability is absent; `P_MONEY` gains optional `gap`; `P_TICK.loc` may be nil. See Contracts.md.
8. **Test runtime:** tests are written for Lua 5.1 semantics (WoW) and were executed under Lua 5.3 (texlua) in the authoring environment because no 5.1 interpreter was available. Re-run under Lua 5.1 or LuaJIT when possible.
Affected: all Platform files, Contracts.md, TODO.md (task 1.1 amended).

## D-023 Target client is WoW Forever, Interface 16001, modern 12.0-based | Approved | 2026-10-09
Source: user's first in-client test (S-003): the client marked `Interface: 11508` incompatible; `Interface: 16001` is what a working WoW Forever addon uses (evidence from the Forever addon development repository, per the user). The user states Forever is a modern, 12.0-based client.
Supersedes: the Classic-era assumption in Architecture section 11 and the placeholder interface 11508 (D-022 item 4).
Effect: TOC uses 16001. Adapter ORDER should prefer modern APIs (C_AuctionHouse, GetProfessions, C_Map) before legacy ones; Phase 1 code already tries modern-first for professions and detects both families in Probe. Combat-log availability and "secret values" must be verified (diagnostics I3, A8, G2, G5) before Phase 3 design.
Affected: GoldIntel.toc, Probe, Unit (order already modern-first), later Auction/TradeSkill/Collector adapters.
Migration: none (pre-release).

## D-024 Client compatibility rules for all addon files | Approved-pending-confirm | 2026-10-09
Status note: Live validation 2026-10-10: all 8 files compile and run in the real client; rules kept as hygiene. Awaiting your explicit confirmation.
Note (S-004): the original load failure turned out to be packaging (D-026), not these rules; they stay as inexpensive hygiene.
Why: the first real-client test rejected every Platform file with "Error loading" and no detail. Root cause unproven (see Phase1_Compat_Analysis.md); these rules remove every plausible code-side trigger at zero cost and are enforced by tests so they cannot regress.
Rules (tests C-1..C-5 in Tests/test_platform_boundary.lua):
1. C-1 Files are plain ASCII, LF line endings, no BOM, end with a newline.
2. C-2 No long brackets of any kind (`[[`, `[=[`): comments are `--` line comments, strings use quotes.
3. C-3 Every addon file begins with `local ADDON, GI = ...` before any other statement.
4. C-4 TOC is minimal: `## Interface: 16001`, Title, Notes, Version, SavedVariables, SavedVariablesPerCharacter, a blank line, then file paths with FORWARD slashes. No `#` comment lines, no custom fields.
5. C-5 Existing rules stay: no bare WoW globals, no goto, no table.unpack, no `//`.
Affected: every future addon file; test suite. Migration: none.

## D-025 Event registration and probing policy | Approved-pending-confirm | 2026-10-09
Status note: Live validation 2026-10-10: with no probing-by-registration the popup is gone [reported]; `C_EventUtils.IsEventValid` works (sanity check false); 12 registrations returned normally. Limit: registration success is not verified (exception E1). Awaiting your explicit confirmation.
Why: real-client test #2: `ADDON_ACTION_FORBIDDEN ... Frame:RegisterEvent()` from Probe.lua. Probing availability by registering events is unsafe: restricted events are blocked with a popup that pcall cannot suppress.
Rules (tests enforce them; rule C-6):
1. No code may probe by registering. Event NAMES are checked with `C_EventUtils.IsEventValid` (`Platform.EventNameValid`, true/false/nil).
2. `Platform.RESTRICTED_EVENTS` (initially `COMBAT_LOG_EVENT_UNFILTERED`) are never registered; `Events.Bind` refuses them. Extend the list when diagnostics (`/gidiag reg NAME`, `/gi status` lastRegister) identify more.
3. Only `Platform/Events.lua` may call `RegisterEvent`. Events are registered only when the feature that needs them is implemented (Phase 1: exactly 12 events, asserted by a test).
4. Probe reports three states: `[ok]`, `[MISSING]`, `[unknown]` (cannot be checked safely, e.g. restricted). Unknown never counts as available.
5. Defensive 12.0 handling: `Platform.IsSecret` guards Money, Unit and Map reads (unverified in the real client).
Consequence for later phases: kill/combat detection cannot rely on the combat log event; Phase 3 design must pick another signal before implementation.
Affected: Platform, Events, Probe, Money, Unit, Map, GoldIntelDiag, diagnostics doc. Migration: none.

## D-026 Delivery policy: packages, not loose files | Approved-pending-confirm | 2026-10-09
Status note: Live validation 2026-10-10: the zip install loaded GoldIntel, GIMin and GoldIntelDiag completely. Awaiting your explicit confirmation.
Why: the original "Error loading" (S-002/S-003) was a folder-structure problem caused by delivering files individually, and files never delivered (GIMin/Sub/*, GoldIntelDiag/SrcV*) caused further errors.
Rules: every multi-file addon is delivered as a zip that extracts to complete addon folders; `tools/build_package.py` verifies every file named in every TOC exists, is ASCII/LF, then zips; the AddOns zip excludes Tests; a Dev zip holds source, tests, docs and tools; MANIFEST.txt lists size and SHA-256 of every shipped file. Individual file cards may accompany a zip but never replace it.
Affected: delivery process only. Migration: none.

## D-032 Multi-review governance model | Approved | 2026-10-10
Source: user instruction 2026-10-10. Roles: user = sponsor, project manager, client tester, final decision authority; Claude = lead architect, lead developer, owner of requirements, architecture, contracts, code, changelogs and governance documents (source of truth); ChatGPT = independent reviewer (risk, architecture, runtime evidence, phase gates); Gemini = platform and WoW Forever compatibility analyst, research and alternate-design reviewer.
Rules: external reviews are peer-review inputs; each finding is accepted, rejected or partially accepted with technical justification; architecture is not changed solely because another AI suggested it; reviewers are not implementation owners and cannot approve phase gates. Full intake procedure in Project_Bible.md section 2.1.
Affected: governance only (Project_Bible.md, future `reviews/` folder and review log). Migration: none. No code or architecture change.

## D-027 Forever API profile: modern-only adapters | Approved (user, 2026-10-18, P3B-4) | 2026-10-10

APPROVED 2026-10-18: executed as the first patch of 3b-0.
Why: the live probe shows the legacy skill-line, auction and trade-skill APIs are absent (E-05, probe report). Maintaining legacy paths adds code and tests that can never run in the target client.
Proposal: treat Forever as modern-API-only. Remove `Unit` skill-line adapter, the legacy probes (`prof.skilllines`, `prof.expand`, `tradeskill.legacy`, `auction.legacy`) and their tests; keep detection of the modern families. `Platform.Auction.Available()` returns only `'modern'` (Contracts change in Phase 6).
Options: remove now (Phase 1 patch), in Phase 2 housekeeping (recommended), or never. Needs your decision (X3).
Affected: Unit, Probe, tests, later Auction adapter. Migration: none.

## D-028 Interface number policy | Approved as a release-checklist item (user, 2026-10-18, P3B-4) | 2026-10-10

APPROVED 2026-10-18 as a release-checklist item only (no code): every client patch needs a re-probe and a TOC Interface check.
Observation 2026-10-15: a hotfix build (70338 to 70374) kept version 1.60.1 and Interface 16001, which fits the 'interface = encoded version' hypothesis: only a version change requires a TOC update.
Why: Interface 16001 equals the encoded client version 1.60.1 (major x 10000 + minor x 100 + patch) [inferred]; every client patch changes it and an exact TOC value shows 'out of date'.
Proposal: add 'update `## Interface:` and re-probe' to the release checklist for every client patch; if the client accepts a comma-separated Interface list (to verify; OI-10), list the current and the next-announced versions.
Affected: GoldIntel.toc, release process. Migration: none.

## D-029 Phase 3 gate: verify every event before depending on it | Proposed | 2026-10-10
Why: names being valid does not prove registration is allowed (D-025). The earlier popup came from a probe of 29 events; 12 of them register fine in v0.1.2 [reported, X1 asks for confirmation], so the culprit is one of the other 17 (listed in Compatibility_Notes.md section 3) and was never identified.
Rule: before Phase 3 implements a source, its events are registered one at a time with `/gidiag reg NAME`, `Events.Bind` verifies registration with `IsEventRegistered` (exception E1), and the result is recorded in Compatibility_Notes.md. A source whose event is restricted needs a documented alternative before implementation.
Affected: Collector design, Events.Bind (small patch). Migration: none.

## D-030 Activity detection must not depend on the combat log | Proposed | 2026-10-10
Why: the combat-log event is never registered and is suspected restricted; Architecture 7.4 used it for GRIND.
Rule: no module may require `COMBAT_LOG_EVENT_UNFILTERED`. The GRIND signal is chosen under OI-8 from candidates that must first be verified live (loot window with creature source GUIDs, experience-gain events, outputs of `C_CombatLog` / `C_DamageMeter`); none is decided. Manual activity override stays.
Affected: ActivityEngine design, Architecture 7.4. Migration: none (not yet implemented).

## D-031 Evidence and documentation discipline | Proposed | 2026-10-10
Why: S-002 to S-004 failures traced to unverified assumptions, loose delivery and contract drift.
Rules: (1) runtime evidence files are stored in `GoldIntel_Docs/evidence/` with dated names and an entry in the Compatibility_Notes evidence ledger; (2) every client fact is tagged [file], [reported], [inferred] or [assumed]; (3) Contracts.md changes in the same change as the code that affects it; (4) 'Compatibility_Notes.md' wins over Architecture.md on client facts; (5) one verified step at a time: no phase starts before its predecessor's live exit test has real evidence.
Affected: all documentation. Migration: none.

## D-033 Phase 2 authorization: Core + Store | Approved | 2026-10-10
Source: user authorization 2026-10-10, based on the live validation, the runtime evidence and the independent ChatGPT and Gemini reviews.
Included: Core module registry, internal event bus, Store, persistence layer, schema versioning, migrations, configuration framework, service registration, capability registry integration, test coverage.
Excluded: Collector, auction scanner, mail collector, loot collector, combat collection, attribution engine, activity detection, any Phase 3 functionality.
Assumptions I made and flag for correction: (1) the authorization is read as accepting D-022, D-024, D-025, D-026 (Phase 2 builds directly on them; conditions X1, X2 were not answered separately); (2) D-027 (legacy adapter removal) and D-028 (interface policy) were not decided, so they stay Proposed and no Phase 2 code depends on them: legacy adapters are untouched and the TOC interface stays 16001; (3) the capability stage model needs registration verification, so exception E1 (a small, scoped change to Platform/Events.lua) is part of this work and is disclosed under D-034.
Also included from the standing TODO for Phase 2 (not new scope): the `/gi` handler moved from Probe to Core (D-022 item 5) and the Future placeholder stubs (D-015).
Phase 3 NOT started. Affected: everything in Phase 2; TODO.md.

## D-034 Capability stage model and minimal Platform support | Approved (user confirmed 2026-10-17) | 2026-10-10
Live validation 2026-10-15: `IsEventRegistered` returned true for all 12 registered events and the stage data was saved at logout; the blocked-event case remains untested live. Awaiting your explicit confirmation.
Why: external finding ER-RELAY-001 and risk R-09. A capability named `event.X` has four proven-independent facts: valid (name accepted), registered (RegisterEvent took effect), delivered (observed arriving), payloadUsable (data readable). API capabilities have one stage (present).
Rules: stages are true/false/nil; `delivered` is only true or nil (never false); Level() reports the highest PROVEN level and delivery overrides a doubted registration; only `payloadUsable` (events) or `present` (APIs) means a design may depend on a capability; unknown stays unknown.
Platform support (scoped, disclosed): `Events.Bind` verifies each registration with `IsEventRegistered` (exception E1); per-event delivery counters; `Events.WatchStage`; `Events.ReportPayload` (called by Money for PLAYER_MONEY and Unit for PLAYER_LEVEL_UP); `Events.Stats`; `Events.BoundEvents`. Fail-safe: `P.TRUSTED_EVENTS` (exactly the 12 events proven live) are never refused because of the check, since the check itself is unverified in the real client (R-26); all other events are verified strictly.
Persistence: a throttled snapshot (`runtime.capabilities`, `runtime.eventStats`) is written into the saved data so every session leaves evidence in the SavedVariables file.
Affected: Platform/Events, Money, Unit, Core/Capabilities, Store (runtime section), /gi caps. Migration: none.

## D-035 Money pipeline vocabulary: four separate stages | Approved (user confirmed 2026-10-17) | 2026-10-10
Why: external finding ER-RELAY-002.
Stages: (1) balance observation (the signed delta computed from the live balance; today Platform `P_MONEY`), (2) transaction detection (a source event or expectation that explains money moving), (3) attribution (which activity/source, with a SEPARATE confidence value), (4) reconciliation (the invariant check that attributed amounts sum to the observed delta).
Phase 2: vocabulary and contracts only. Reserved Bus events `BALANCE_OBSERVED`, `TRANSACTION_DETECTED`, `ATTRIBUTION_ASSIGNED`, `RECONCILIATION_COMPLETE` exist but no Phase 2 code fires them (a test enforces this). Phase 3 designs the payloads. Architecture section 6 is read with this vocabulary.
Affected: Core/Bus, Architecture 6, Contracts F3. Migration: none.

## D-036 Store design: staged migrations, compat guarantee, degraded modes | Approved (user confirmed 2026-10-17) | 2026-10-10
Why: ER-RELAY-003, D-022 item 6, risk R-18. The real Phase 1 database contains only `compat`, so the first Phase 2 open is a migration.
Design: schema version = end of the contiguous migration chain (0->1 built in; schema 0 = a database with no schema field); migrations run on a deep copy and commit only if the whole chain succeeded, validation passed and the copy's `compat` deep-equals the original; the live table keeps its identity and the live `compat` table is never replaced by Store; unknown keys survive; a database NEWER than the addon is opened read-only (private copy, nothing written back); a failing migration or validation leaves saved data untouched and runs in memory (degraded) with a visible message; sections are validated and repaired by type; `meta` (firstSeen, opens, history) is kept; `runtime` holds volatile evidence; `Pruner` only plans (no deletion before the Phase 5 roll-up).
Costs accepted: a migration copies the whole database once at login (small now; step migrations and the size budget keep it bounded; risk R-19).
Affected: Store/*, Contracts F4/F5. Migration: schema 0 -> 1 for existing installs.

## D-037 Platform adapters for SavedVariables and slash commands; boot order | Approved (user confirmed 2026-10-17) | 2026-10-10
Why: no WoW global may be used outside Platform/ (FR-PLT-1), and `GoldIntelDB`, `SlashCmdList` and `SLASH_*` are WoW globals.
Design: `Platform/SavedVars.lua` is the only access to the saved variables; `Platform/Slash.lua` the only slash registration. Boot order: Core/Boot.lua is the last file; it installs `/gi` immediately in minimal mode (works even if the login event is never delivered) and schedules Core.Start for PLAYER_LOGIN (immediately when loaded after login). Core.Start order: Store.Open + Store.Char, Config.Load, Capabilities.Attach, bridges (diagnostics and capability changes onto the Bus), full `/gi`, modules (initialize all, then enable all, dependency order, failure isolated), CORE_READY. If the platform is not operational Core starts nothing except the minimal commands.
Affected: Platform/SavedVars, Platform/Slash, Probe (temporary slash removed), Core/Boot. Migration: none.

## D-038 Configuration framework | Approved (user confirmed 2026-10-17) | 2026-10-10
Typed, validated settings with defaults, ranges and read-only flags, stored as nested tables in `profile`; unknown saved keys preserved; invalid saved values ignored with a warning (default applies); `/gi config` list/get/set/reset; every change fires CONFIG_CHANGED; with a read-only or degraded store a value works for the session and is reported as not saved. Ships the Contracts F6 settings; modules define their own later. Settings for features that do not exist yet say so in their help text.
Affected: Core/Config, Core/Slash. Migration: none.

## D-039 Core and Store have no library dependency | Approved (user confirmed 2026-10-17) | 2026-10-10
Extends D-021 with evidence: libraries in the live client came from other addons; a native C_Map world conversion exists. A static test forbids any mention of LibStub, Ace or HereBeDragons above Platform/ (Probe only detects them), the TOC declares no dependency, and a five-configuration matrix proves identical behavior. Ace3 and HereBeDragons stay optional and are not planned for any current phase.

## D-040 GoldIntel's own chat output is recorded into the saved data | Approved (user confirmed 2026-10-17) | 2026-10-15
Why: the user could not copy text out of the chat window, which made evidence collection slow. Everything GoldIntel prints (`Platform.Print`, including reported errors and every `/gi` command output) is kept in a 200-line ring and the last 100 lines are written to `GoldIntelDB.runtime.output` (with `outputTotal`) by the same throttled snapshot that records capability stages. Every `/gi` command schedules a snapshot (within 5 s), and logout writes a final one, so the saved file contains what the addon said. Not new gold functionality: this is the persistence layer carrying diagnostics.
Affected: Platform.Print/GetOutput/OutputCount/ClearOutput, Capabilities.Persist/Touch, Commands.Run. Contracts 1.4. Migration: none (runtime is replaced each time; bounded to about 10 KB).
Also this session: `/gi caps` now says `yes`, `NO`, `not-seen-yet`, `unknown` instead of `true/false/nil` (a `nil` meant 'not observed yet', which looked like an error); `P.CONTRACT_VERSION` corrected from a stale 1.1 to 1.4.

## D-041 Preserve the previous runtime session record | Approved (user 2026-10-17); IMPLEMENTED (rebuild 4) | 2026-10-17
Why: a `/reload` overwrote the record of the session before it. Rule: at each open the loaded `runtime` becomes `runtime.previous` (compacted, bounded) plus a one-line row in a ten-row `history`; `/gi checkpoint pin` keeps one record until unpinned. User constraint (binding): these records are DIAGNOSTIC EVIDENCE ONLY. Long-term product value comes from aggregated intelligence, not permanent storage of raw events. The feature stays bounded to: current session, previous session, short history, pinned session on request. Design: Runtime_Session_Records_Proposal.md. Implemented: Core/Capabilities.lua, Core/Slash.lua, Contracts 1.5, Tests/test_session_records.lua. Migration: none. A rotation failure costs only the previous record.

## D-042 Phase 3 PLANNING ONLY authorized | Approved (user) | 2026-10-17
User statement: "I approve Phase 3 planning only. I do not approve Phase 3 implementation." Planning and architecture documents only: value attribution, loot valuation, location credit, activity detection, AFK handling, collector signal selection. No collector, Reconciler, Lots, activity/session engine, heat bin, pricing provider or UI may be written. Phase 3 stays NO-GO until OI-8, X-2 and an explicit implementation approval.

## D-043 to D-050 Phase 3 planning decisions | ACCEPTED by the user 2026-10-17 | 2026-10-17
Defined in Phase3_Planning_Package.md. D-043 value is created once at acquisition and is not rebooked. D-044 only looted gold, loot, gathering, fishing and similar acquisition contribute heat; quest turn-ins, vendor sales, repairs, trades, mail, auction settlements and similar transactions never light up the map. D-045 vendor floor and conservative valuation. D-046 late item information stays visible as unknown, never silently guessed. D-047 large single drops are disclosed so they do not distort hotspot interpretation. D-048 activity is evidence-scored and confidence-based. D-049 ACCEPTED WITH CLARIFICATION: idle time is excluded from all GPH calculations and from map heat calculations. D-050 collector signals are selected by verification results, not assumptions. These are planning decisions only: nothing is implemented.

## D-051 Phase 3a authorized (diagnostics, experiments, signal verification) | Approved (user) | 2026-10-17
User: "I approve Phase 3a only. I do NOT approve Phase 3b implementation. Collector implementation remains blocked pending successful verification and review." Scope, safety rules and gate: Phase3a_Verification_Protocol.md. The GoldIntel addon itself is not changed by 3a.

## D-052 Heatmap vision: location-level density, overlay toggle | Approved (user) | 2026-10-17
Not a zone-level heatmap. The system answers "Where exactly am I making money?" with a density map or heat cloud tied to coordinates and activity density; nearby areas cool gradually away from productive locations. 32 x 32 bins, coordinate attribution, value per active hour and minimum sample thresholds are agreed. The overlay must be easy to toggle on and off so Gatherer, Questie or other map overlays remain usable. Requirements amended (AM-1, AM-2). Implementation (Phase 7) and design details (Phase3_Planning_Package.md Addendum A) are not started.

## D-053 Graphical configuration is the primary configuration experience | Approved (user, product direction) | 2026-10-17
Long term, settings are changed in a normal addon options window; slash commands stay for diagnostics and power users. No implementation requested yet (Phase 8). The typed Config framework (D-038) is the intended source of the window's controls.

## D-054 Travel model: Option B, hard travel plus soft travel | Approved (user) | 2026-10-17
Chosen by the user: Option B of Travel_Model_Options.md. Hard travel (taxi, loading screens, teleports and hearths) and soft travel (fast movement, at least the stay-near distance from the last productive spot, no productive event for the dry window) are non-productive. Reasons given: taxi time must not count; long-distance travel must not dilute hotspots or GPH; gathering routes still count as productive; camp-to-camp movement while grinding still counts. Approved values: `travel.countInGph` default false; `TRAVEL` is an activity type (non-credited, non-productive); dry window 60 s; stay-near distance about 150 yards; all tunable later from real data (settings `travel.dryWindowSec`, `travel.stayNearYards` planned). Priority when signals overlap: manual pause > taxi > idle > soft travel > productive. Experiments T1 to T4 (Phase 3a) must verify the signals before any implementation. Nothing is implemented.

## D-055 AFK decisions and manual controls | Approved (user) | 2026-10-17
Waiting for a node respawn counts as idle after the timeout (the user cares about productive activity); fishing is different because casts are activity. `/gi pause`, `/gi resume` and `/gi afk` are required; manual control must always exist.

## D-056 Phase 2 CLOSED WITH EXCEPTIONS | Approved (user) | 2026-10-17
Exceptions PX-1 to PX-8 (Phase2_Closure_Recommendation.md) remain tracked. D-034 to D-040 confirmed. Closure does not authorize Phase 3b.

## D-057 Heat colour scale: relative by default, fixed thresholds as a later option | Approved (user) | 2026-10-17
The default scale is RELATIVE to the best well-sampled locations on the map, so the best spot is red and a spot at half its gph is yellow even if no fixed threshold is reached (example: Lake Nazferiti 20 gph red, Kurzen Compound 10 gph yellow). A fixed gold-per-hour threshold option must be retained in Settings later. Not implemented (Phase 7/8).

## D-058 Ranked hotspot list is in v1 | Approved (user) | 2026-10-17
A ranked list of hotspots. For each: coordinates, place name if available, activity, GPH, active hours, sample count and confidence. Place names depend on experiment H1 (names for coordinates); coordinates and the other fields do not. Requirement FR-HEA-7 added. Not implemented.

## D-059 Overlay commands | Approved (user) | 2026-10-17
`/gi overlay on`, `/gi overlay off`, `/gi overlay toggle`. The future graphical settings window must expose the same functionality. Not implemented (Phase 7/8).

---

## D-060 Instances are evaluated as whole runs, shown at the instance location | Approved (user, including details) | 2026-10-17

User, 2026-10-17: an instance should be treated as a whole. Bosses do not respawn, so waiting inside for respawns is not farming; instance farming is "clear it, leave, reset, go back in". The activity should be heat-mapped and noted at the instance's location on the world map.

Direction (approved): an instance is one location unit placed at its entrance on the world map, not a set of bins inside it; credit and time belong to runs (entry to exit).

APPROVED 2026-10-17 (user, 17:41): instance farms are represented at instance entrances; DEFAULT statistics are per run; full-cycle statistics are an OPTIONAL setting (answers the open question). Remaining details still proposed and subject to Phase 3a evidence: (1) the entrance position is the last open-world position sampled before the loading screen into the instance, or an entrance API if the client has one (P1 lists `C_EncounterJournal`, `C_AreaPoiInfo` names); (2) value per run and active time per run; GPH uses active time inside the run (idle, AFK and pause excluded as everywhere); the run list shows runs, average gold per run, best run; (3) full-cycle statistics (including the out-of-instance reset and re-entry time) are optional, default off; (4) position inside instances is not sampled for heat.

PHASE 3a EVIDENCE for D-060 (E-27): run boundaries are observable (`IsInInstance` and `GetInstanceInfo` instanceID 389, difficulty, group size); position is unavailable inside, so the entrance is the last stable open-world position before entry (exit position matched within about 23 yards); instance identity key proposal: (instanceID, difficultyID). A dungeon entered from inside a city (Ragefire Chasm in Orgrimmar) places its pin on the city map, so the pin/heat map must support city maps, not only zone maps.

## D-061 Heat map scope toggle: account best versus this character | Approved (user, including details) | 2026-10-17

User, 2026-10-17: heat maps should be visible across the characters of the account so a new character does not start from scratch; a low-level character must not weaken the map with its lower GPH. So: a toggle for the TOP OBSERVED GPH across all characters (hovering gives the character and activity responsible), and when off it shows the logged-in character's own GPH heat map.

Direction (approved): two scopes, "account best" and "this character". Account best uses the highest observed value per location across the account's characters, never an average.

APPROVED 2026-10-17 (user, 17:41): the two views are Account Best and Character; the DEFAULT is the character-specific heat map; account-best heat maps are OPTIONAL (a toggle). Remaining details proposed: default scope is this character; command `/gi overlay scope account|character|toggle` and a settings-window control; each scope uses its own relative colour scale (D-057); the same two scopes apply to the ranked hotspot list (D-058) and to instance pins (D-060); the tooltip in account scope shows character name, class, level at the time, activity, GPH, active hours, sample count, date and valuation basis; a location needs the same minimum confidence in both scopes before it can win (so one lucky drop in a barely visited bin cannot become the account best); each bin keeps the level range it was observed at. Realm-specific valuation (auction prices) is labelled by basis in the tooltip.

CONFIRMED 2026-10-17 18:02 (user) for D-060 and D-061: the instance hotspot model is approved; per-run statistics are the default; per-cycle is a SECONDARY metric; Character View is the default; Account Best is an optional view. The details listed under D-060 and D-061 are approved, subject to Phase 3a verification of the signals they depend on (entrance position, run boundaries, `GetInstanceInfo`).

## D-062 Disenchanting and other conversions are valued through lots and a price source | Proposed | 2026-10-17

Trigger: user message 18:31: instance farming will involve disenchanting greens and blues, enchanting materials have no vendor value, so auction data is almost certainly needed.

Proposal (no code, Phase 3b not started):
1. Conversion is not income. Disenchanting destroys an item and creates materials. To avoid double counting (D-043: value booked once at acquisition), the green/blue is booked at acquisition at its floor (vendor price, D-045). If the player later disenchants it, the materials replace the item inside the same lot: the lot's value is revised to (materials value) and the difference versus the floor is credited to the ORIGINAL acquisition place and activity (not to where the disenchant happened, consistent with D-044). This needs the Lot model, so it is Phase 3b.
2. Materials value comes from the pricing provider (AH scan data) as a labelled basis ("auction") stamped with the price date, never vendor 0, and it follows D-063: a historical value is never overwritten by a later price. If no price exists the revision stays "unknown" (D-046) and the session shows the item at floor with a "not yet priced" flag. Account-wide price data is shared by all characters.
3. Optional user setting (proposal): "Value unsold greens/blues at: vendor floor | expected disenchant value". Expected value needs per-level disenchant tables, which are NOT known to the client API; default stays the floor.
4. The same lot mechanism covers other conversions (prospecting, milling, combining). Out of scope until requested.
5. Phase 3a evidence: the disenchant loot window is verified (E-25): source GUID type `Item`, item 10940 Strange Dust, so a disenchant is recognisable; the destroyed item must come from the bag diff. The disenchant cast is also verified (E-26): spell 13262, player unit, readable, no item named. Phase 3a evidence for D-062 is complete; only the cast-to-loot timing in one session is unmeasured.

Status: PROPOSED. User approval required. Interaction: Requirements AM-1 to AM-11 unchanged.

## D-063 Three value views: Verified Value, Current Market Value, Account Best | Approved as a principle (user directive 2026-10-17 18:48); details Proposed

User directive: "Do not replace historical observations with current prices." Future concept so users can distinguish what happened from what would happen now.

1. **Verified Value:** what actually happened, from observations at the time: coin looted, vendor/AH proceeds, and items valued on the basis recorded when they were acquired (D-043, D-045: vendor floor, or a price snapshot with its date). Immutable once recorded. Every number carries its basis and date. Later prices never rewrite it.
2. **Current Market Value:** what the same items or the same run would be worth at today's prices (D-062 pricing provider). Recomputed on demand, always labelled with the price date, shown next to Verified Value, never stored in place of it. Used for "what if I sold it now" and for planning, not for historical gold per hour.
3. **Account Best:** the best VERIFIED result per location across characters (D-061), never an average and never repriced. A view option, not a value basis.
4. Default displays Verified Value. UI wording must make the basis visible (exact labels decided in Phase 8).
5. Data consequence for Phase 3b design: lots keep the acquisition basis plus a separate, replaceable market-valuation field; revaluations (D-062) are appended as dated records, not edits.

Status: principle approved by the user; layout and labels are PROPOSED.

## D-064 Economic Attribution is separate from Location Attribution | Approved (user directive 2026-10-17 19:07) | clarifies D-044

1. **Economic Attribution** answers "where did the value come from" (source: loot, quest, vendor, AH, mail, trade, conversion). Quest rewards REMAIN in the economic records (the ledger, totals, Verified Value).
2. **Location Attribution** answers "where did value-generating activity occur" and feeds heat maps, hotspot lists and instance pins. Quest rewards stay EXCLUDED from it (D-044 unchanged): the reward is earned over a route, not at the NPC.
3. Every ledger entry therefore carries two independent fields: an economic source and a location-eligibility flag. Neither is derived from the other.
4. The same rule applies to other non-farming sources (vendor sales of already-held items, AH, mail, trade).
5. User, 2026-10-17 19:51: quest rewards continue to be recorded as economic data and continue to stay out of location heat calculations. If WoW Forever ever introduces repeatable quests, that data may become economically important (for example as its own source in income reports) while remaining unsuitable for location heat maps. The two-field design keeps this possible without a data change.
6. User, 2026-10-17 20:51: mailbox metadata (sender, subject, money, attachments, auction invoice) is potentially important for auction proceeds, alt transfers, gifts and item deliveries. Mail attribution stays separate from location attribution: mail affects financial reporting and NEVER affects heat maps. Mail sources are classified for the ledger (auction proceeds, alt transfer, gift, item delivery) only if Phase 3a shows the metadata is readable (experiment X2, GoldIntelDiag 1.6).

## D-065 Reconciliation window is 1.0 s | Approved (user directive 2026-10-18 10:14) | amends D-004

1. The money-matching window of D-004 and Architecture section 6 (Money attribution) changes from 0.25 s to **1.0 s**. The window works in both directions: a `PLAYER_MONEY` delta may be explained by an expectation registered up to 1.0 s EARLIER (a context signal such as a window close), and a delta waits up to 1.0 s for an expectation that arrives LATER. It stops waiting as soon as a match is found, so it is a maximum, not a fixed delay.
2. Expectation time-to-live (`Expectations:Register(src, copper, ttl)`) is at least 1.0 s for every source.
3. Why: Phase 3a measured legitimate gaps longer than 0.25 s between the explaining signal and `PLAYER_MONEY`: trade 0.394 s after `TRADE_CLOSED` (E-31), mail 0.365 s after `MAIL_INBOX_UPDATE` (E-28), loot up to 0.509 s after `LOOT_OPENED` (E-24). With 0.25 s these would be mislabelled `OTHER`. The user judged that avoiding false `OTHER` entries matters more than a short window.
4. Matching stays exact (same copper, same sign) and uses the priority order trade, mail, vendor, quest, loot, AH, so a longer window does not loosen what counts as a match. If two expectations of the same copper and sign compete inside the window, the priority order and then the older expectation win.
5. Unmatched remainder after 1.0 s is still `OTHER`, `conf = 'low'`. The invariant (entries sum to the delta) is unchanged. A delta of zero is ignored (E-31: cancelled trades raise `PLAYER_MONEY` with no net change).
6. Consequences to test in Phase 3b: two sources inside one second (loot then vendor sale); repeated identical amounts; a delta that waits the full second and then falls to `OTHER`; ledger entries become final up to 1.0 s after the money event (UI and GPH read the ledger only after entries settle).
7. Not changed: the 0.25 s scheduler queue drain (Architecture sections 5.3 and 13), the 2 s aggregation and the 0.5 s heat tick.

## D-066 Phase 3a CLOSED WITH EXCEPTIONS X-A..X-H | Approved (user) | 2026-10-18

Approved by the user 2026-10-18 10:53: Phase 3a is closed with exceptions X-A to X-H as listed in `Phase3a_Closure_Recommendation.md`.
1. X-A: the XP kill proxy (G2) is DROPPED. GRIND evidence uses the creature loot source (G1, verified) and combat state (G3); no kill count is collected.
2. X-B: boat and zeppelin travel testing (T4) and T1b are NOT a gate; left for normal play.
3. D-065 (1.0 s reconciliation window) remains approved. The E-33 and E-34 findings need no change.
4. This does NOT authorize Phase 3b implementation (D-051, D-042). The user asked for a scope and readiness assessment first: `Phase3b_Scope_and_Readiness.md`.

## D-067 Phase 3b scope and increments | Approved (user) | 2026-10-18

Approved 2026-10-18 10:58 (P3B-1, P3B-2). Phase 3b is limited to: signal adapters, context tracking, Reconciler, cash ledger, item ledger, vendor-floor and manual-price valuation, location and activity STAMPS only.
NOT approved (later phases as planned): activity engine, sessions, GPH calculations, heatmaps, rankings, Current Market Value, Account Best, UI.
Four gated increments 3b-1..3b-4 after a housekeeping increment 3b-0 (Phase3b_Scope_and_Readiness.md 2.3). Each increment needs the user's review before the next begins. Nothing beyond 3b-0 is authorized until the user reviews 3b-0.

## D-068 Verification addendum before 3b-4 (AH, COD, outgoing mail) | Approved (user) | 2026-10-18

Approved 2026-10-18 10:58 (P3B-3, option A). Before increment 3b-4, the lab verifies, with read-only diagnostics and one event per session: AH listing deposits, AH bids and buyouts, auction cancellations, COD (paying and receiving), outgoing mail (postage and money sent). Reason (user): auction profitability is a major long-term use case and the attribution model must rest on evidence. This is Phase 3a-style work under D-051 rules (GoldIntelDiag only, no change to the addon data model).

## D-069 Architecture and Contract package for Phase 3b | Approved (user) | 2026-10-18

Approved 2026-10-18 10:58 (P3B-5). Includes SavedVariables schema 2 (per-character ledger, lots), AC-4 window-mode expectations (exact and window match modes, same 1.0 s rule and priority order as D-065), the Platform event allow-list, new Platform adapters, new directories Collect/ and Ledger/, and the CashEntry, Lot, Expectation and bus additions. Text applied in Architecture.md section 19 and Contracts.md 1.6 (Phase 3b additions). The shapes are approved; the code arrives with 3b-0..3b-3.

## D-070 AH sale split | Approved (user) | 2026-10-18

Approved 2026-10-18 10:58 (P3B-6). A sold-auction mail pays price + deposit refund - cut (E-34: 51 + 100 - 2 = 149). The ledger records three components that sum to the money delta: sale price (income, settlement), auction cut (expense), deposit refund (NOT income; it reverses the deposit expense paid at listing). Deposit refunds never enter income, Wealth or Cash GPH as income.

EXPECTED MECHANICS (user-reported 2026-10-18 11:15, [reported], NOT evidence): a deposit is forfeited when an auction expires or is cancelled; a sale returns the deposit in the sale mail; the house cut is 5% on faction auction houses and 15% on neutral ones (Booty Bay, Gadgetzan, Everlook). RULE: measured Forever behavior always wins; any difference between a Session 19 to 22 measurement and these expectations is documented in Compatibility_Notes, and the ledger rules follow the measurement. One consistency observation only: E-34 (Horde house) shows cut 2 on a price of 51, which fits 5% rounded down; this is a single sale and proves nothing about the rate or the rounding.

## D-071 Disenchanting in Phase 3b is recorded, not revalued | Approved (user) | 2026-10-18

Approved 2026-10-18 10:58 (P3B-7). A disenchant is recorded only as: item consumed, materials created. No revaluation. D-062 stays Proposed and is deferred to Phase 6.

## D-072 Phase 3b validation rules | Approved (user) | 2026-10-18

Approved 2026-10-18 10:58 (P3B-8, P3B-9, P3B-10).
1. Raw ledger retention is determined from the MEASURED entry size at the end of 3b-2, within the storage budget (Architecture 13).
2. GoldIntelDiag is disabled during Phase 3b live validation sessions.
3. Profiling plan approved (C_AddOnProfiler average ms per frame and memory growth per hour with collectors on versus off; fake-clock handler cost test).
4. OTHER target: 2% as a STARTING target, reported as BOTH percentage of entries AND percentage of total value (copper). A few high-value unexplained entries is the more serious signal, so `/gi diag` must show both, PROMINENTLY, and the largest single OTHER entry. The user (2026-10-18 11:10) considers the SHARE BY VALUE the more important figure: it is listed first and is the headline number.

## D-073 Replay corpus is a permanent regression suite | Approved (user) | 2026-10-18

Approved 2026-10-18 11:10. The real-client sequences E-22 (quest), E-28 (mail update), E-31 (trade) and E-34 (AH sale mail) are copied into `GoldIntel/Tests/fixtures/replay/` (never edited, MANIFEST.md) and replayed in every later phase, so a Reconciler or collector change cannot silently break verified timing or data behavior. A missing corpus file FAILS the suite; it never skips. New verified sequences are added with a manifest row and a test.

## D-074 Increment 3b-1 plan (adapters, Context, registration, counters, collect on/off) | Approved 2026-10-18 (all five), built 2026-10-18

Plan in Phase3b_Increment_3b-1_Plan.md. Approved by the user: A-1 AUCTION_HOUSE_AUCTION_CREATED as the 14th collector event (group G6); A-2 additive contract entries (P_BAGS_SETTLED, P_ITEM_INFO, P_LOOT_OPEN, P_LOOT_CLOSE); A-3 collect state not persisted (always OFF after login and /reload); A-4 loot context closes 1.0 s after the last LOOT_SLOT_CLEARED with a 10 s timeout fallback, **with the condition** that the validation report shows slot-clear closes and timeout closes separately and that the assumption is reviewed before 3b-2 if timeouts are frequent; A-5 start of the build.
User also approved the design principle: registration journal plus quarantine (isolate the offending event, never disable the whole collector) and keeping E-22, E-28, E-31, E-34, E-39, E-40 replays as permanent regression tests.
Build note (flagged for acknowledgment, not pre-approved): three further additive normalized events were needed beyond the four named in A-2: P_AH_POSTED, P_MAIL_UPDATE, P_TRADE_CLOSE. They carry no new data source; they are the normalized form of events already on the allow-list.

## D-075 Loot window close signal: LootFrame:IsShown() (supersedes D-074 A-4) | Approved 2026-10-18 | built in 0.3.1-phase3b1

Live validation E-41 falsified the A-4 rule (close 1.0 s after the last slot clear, 10 s timeout): 6 of 6 windows closed by timeout, 2 clears arrived late, and the 11 copper arrived after the context had closed. Probe E-42 (GIProbeLoot, 8 windows) verified `LootFrame:IsShown()` as an exact open/close signal (slow loot, Escape, walk-away, empty corpse, partial loot, close and reopen).
Approved by the user: (1) `LootFrame:IsShown()` is the primary close signal (poll every 0.1 s, only while a window is open); (2) `LOOT_OPENED` stays the open signal; (3) the 1.0 s post-close linger stays (money arrives about 0.05 s after the frame hides); (4) `LOOT_SLOT_CLEARED` is informational only (counted, doubled clears de-duplicated, never closes anything); (5) a 300 s timeout is a recovery backstop only; (6) reporting of closes by frame, by timeout, by replacement, duplicate clears, unreadable cases; (7) contract 1.7.1: `P_LOOT_CLOSE.by` is `frame | timeout | replaced`; (8) if LootFrame cannot be read the old rule applies to that window and is counted separately (`frameUnreadable`, `legacyWindows`; its closes are reported as `timeout`).
3b-2 does not start until the revised 3b-1 validation has been reviewed.

## D-076 Increment 3b-1 closed | Approved (user) | 2026-10-18

Approved 2026-10-18 14:38 after Phase3b_Increment_3b-1_Closure.md. All approved 3b-1 scope was delivered and validated live (E-41..E-45): 14 events registered with no popup, unit filter works, off/on clean, collect off after reload, vendor, mail, quest, trade, auction posting and the revised loot close (D-075). Remaining items are documented risks, not blockers: gathering casts not exercised live, mail field decoding not re-read live, mail CPU on an unrecorded inbox size, poll costs not tracked, context linger is an inference, optional character identity stamp (low risk after E-44). Optional follow-ups (live gathering cast, live invoice/COD read, poll counters, identity stamp) may be done later.
3b-2 remains NOT started, NOT approved. The user asked for a scope and readiness package.

## D-078 Loot share classification (group play) | ACCEPTED, built as the chat-signal rule in 0.3.6 (user approval 2026-10-18; the window-inference rule of the original proposal was NOT built) | 2026-10-18

Package: Phase3b_3b-2_M4_RootCause_and_Proposal.md. E-47 shows solo auto-loot attribution is correct (16/16 exact); E-46 failure is explained by group coin splitting (user confirmed a group of 2). Proposal: attribute a positive delta smaller than the offered coin of an active loot window to `loot` med, comp `split`. Addendum 1 (user scenario: one looter takes all corpses, other members get no window): the window share rule only covers the looter; non-looters need another signal (candidate: CHAT_MSG_MONEY, unverified). Revised plan: diagnostic evidence build 0.3.5 first. Awaiting the user's decision. Nothing built.

**Addendum 2 (E-48 / E-49, grouped evidence, 2026-10-18; still PROPOSED, nothing built):**
- CHAT_MSG_MONEY reaches the addon and is readable. Solo: `You loot N Copper` (10/10). Group of 2: `Your share of the loot is N Copper.` (14/14 coin deltas, including 7 deltas with no loot window at all, i.e. partner-looted corpses). Amount always equals the PLAYER_MONEY delta.
- Chat arrives 0.5-1.0 s AFTER PLAYER_MONEY (max seen 1.000 s). OTHER fallback is written at about 1.0-1.2 s, so chat arrived first in all 14 but with a margin as small as 0.08 s.
- Group API: solo `0/false/false`, grouped `2/true/false`.
- Looter share in 6 splits was ceil(C/2) (11>6, 7>4, 19>10, 4>2, 3>2, 9>5); 1c window matched exactly. Too few samples to rely on; the signal does not need it.
- Proposed rule (for user decision): a chat coin line N becomes an exact late expectation (src loot) against a pending/just-written delta of N; consumes an unmatched window expectation when N <= its coin (comp 'split'); pending hold lengthened to 2.0 s while the Chat adapter is registered; parse failure or no equal delta -> unchanged behavior (OTHER). No heuristics.
- Not yet observed: groups > 2, silver/gold wording, one player looting a pull of several corpses.

**Decision (user, 2026-10-18, after E-48/E-49):** the coin chat line is the primary loot expectation source. `You loot N Copper` and `Your share of the loot is N Copper.` each become an EXACT loot expectation of N; a money change of exactly N is loot, with or without a local loot window. Pending money waits WAIT = 2.0 s (was 1.0 s) because the chat line arrives 0.5-1.0 s after PLAYER_MONEY; the loot window expectation outlives its window by 2.0 s. Safeguards: exact amounts only; unparseable text or no equal delta leaves behavior unchanged (OTHER); no heuristics (no small-gain, combat or grouped guesses); no retroactive edits (a chat line that arrives after the delta became OTHER is only counted, `chatLate`); the sum invariant is unchanged. A split share consumes its loot window expectation only when N = floor or ceil of window coin / k for some k from 2 to the group size (corrected 0.3.8 after the user confirmed that coin is split among the members in range, or everyone in an instance, not by group size). Entries from a share carry comp 'split'. Partner-looted coin has no known corpse or object: src loot (high), activity LOOT (med), the player's stamped location with its normal locConf, not creditable to heat bins (user decision 2026-10-18: OTHER is reserved for income whose source category is genuinely unknown). A share that consumed a creature window keeps GRIND (med).
Also changed (found by the new tests): lastMoney now follows the ledger (previous lastMoney + entry), not the live balance, so money still pending at a crash is recovered as a gap at the next login.

## D-077 Increment 3b-2 scope and readiness | Approved (user) | 2026-10-18

Progress: M1, M2, M3 approved (2026-10-18). Q-6 final interim retention set by the user: CAP 2000 raw entries per character, FOLD 500 unchanged. M4 live validation authorized; 3b-3 NOT authorized until the M4 evidence and the 3b-2 closure recommendation are reviewed.

Package: Phase3b_Increment_3b-2_Scope_and_Readiness.md (architecture amendments AC-9..AC-13, expectation model, Reconciler, cash ledger, schema 2, validation, rollback, exit criteria, decisions Q-1..Q-10). APPROVED 2026-10-18 14:45: Q-1 option A (AH deposit/buy/bid, COD paid, postage stay OTHER until 3b-4), Q-2..Q-10 all approved as proposed, AC-9..AC-13 approved as one package (Sources / Expectations / Reconciler / Cash Ledger separation must stay intact; Reconciler stays source-agnostic). The M1-M3 review package must report OTHER share by value, gap count and unmatched expectation count. Implementation authorized for M1 ONLY; milestone reporting M1..M4; live validation does not begin until the M1-M3 review package is complete.

## D-079 Increment 3b-2 closed; post-closure bug-fix policy | Approved (user) | 2026-10-19

The user approved closing 3b-2 after Phase3b_3b-2_Closure_Recommendation.md (build 0.3.8-phase3b2m8, 1036 tests green). Policy: any discrepancy found later in larger groups, range behavior, silver/gold wording or loot-share edge cases is tracked and resolved as a post-closure bug fix against 3b-2 functionality and does NOT block completion or later increments. The grouped live validation was waived by the user on 2026-10-19. Backlog: TODO.md section "3b-2 post-closure bug-fix backlog".

## D-080 Increment 3b-3 scope and readiness | APPROVED (user, 2026-10-19 13:17) | 2026-10-19

Package: Phase3b_Increment_3b-3_Scope_and_Readiness.md. The user approved Q-1 to Q-14 as recommended, with these emphases: Q-1 scope limited to loot, quest, vendor buy/sell, mail, trade, disenchant (no AH item flows, crafting, bank logic, outgoing mail); Q-2 evidence gate after M2, no lot persistence until the M2 evidence package is reviewed and approved; Q-3 option A (schema 2, additive); Q-5 bag-index behavior still validated in M2; Q-9 probe the repair-cost API, no inference; Q-10 CHAT_MSG_LOOT evidence only, no rule until reviewed; Q-11 caps 1,500 open and 300 closed, revisit only after measurement; Q-12 commands status, check, last, unknown, on, off, reset confirm (current character only); Q-13 Contract 1.9 and AC-14..AC-19 applied; Q-14 disenchant materials vc = false.
Required of M2 evidence before any persistent attribution rule: bag index range, equip/unequip behavior, repair-cost availability, bank movement behavior, roll-awarded item behavior. Crafting stays unexplained. AC-15 (lots never write cash) and the cash-isolation validation (every existing cash replay byte-identical with the item pipeline active) are explicit user requirements.
Addendum (user directive 2026-10-19 13:36): unexpected conditions are never hidden or treated as normal. Anything that contradicts known item data (for example money comes in at a vendor while an item with no sell price leaves the bags, or a sale item's price is unknown) must be counted, recorded, and shown to the user with a "please report this as a bug" message. Built in M1 as the anomaly register in Lots (kinds: sale-price-unknown, sale-no-sell-price, equal-split, shortfall, unallocated-copper, vc-coerced); M3 wires the visible message, `/gi lots status` listing and trace.
Authorization: implementation begins at M1 ONLY (pure modules). M2 is a review gate. M3 and M4 are NOT authorized.

## D-081 Item side is acquisition and conversion accounting, not a mirrored inventory (amends D-080) | Approved (user) | 2026-10-19 19:40

User decision: the item side exists for loot valuation, quest valuation, vendor conversion tracking, AH purchase/sale tracking, profit calculation and prevention of double counting. It is NOT a perfectly mirrored inventory. Equip, unequip, cursor movements, bag rearrangement, consumption, destroying items and similar inventory-only actions must not drive complexity unless required for acquisition and conversion accounting. Inventory value is an approximation: "acquired and not known disposed".
Consequences (applied in this session, documented in Phase3b_Increment_3b-3_Scope_and_Readiness.md, Section 16):
1. Lots are created only from known acquisitions (loot, quest reward, vendor/AH purchase, and the disenchant conversion) and consumed only by known conversions (vendor sale, AH sale later, trade, disenchant). Other removals and additions are ignored (counted at most).
2. WITHDRAWN: item-side Q-4 (opening lots, item gap lots), Q-5 (equipped gear and bag slots in the carried scope), AC-16 and invariant I-3 as a hard rule. `Lots:Check` stays as an optional diagnostic. AC-19 (separate enable switch) stays. Everything else in D-080 stands (Q-1, Q-2 gate, Q-3, Q-6..Q-14 except where this decision narrows them).
3. A conversion of items that no tracked lot covers (acquired before tracking, from the bank, etc.) is NORMAL: counted (`shortfall`, `unallocated`), not an anomaly. Real contradictions stay anomalies (sale at no sell price, price unknown at sale, equal split, coerced vc).
4. M2 evidence list is reduced to what acquisition and conversion accounting needs: bag index range, roll-awarded item arrival, repair-cost API, CHAT_MSG_LOOT shape, loot-item timing, sell price + class of no-vendor items, buyback signal. Equip/unequip, bank, cursor and in-flight probes are DROPPED unless M2 data shows they corrupt acquisitions or conversions.
5. M2 remains a review gate; no lot persistence before the M2 evidence is approved; M3/M4 not authorized.

## D-082 Scope review decisions: activities, value basis, heat basis (user, 2026-10-19 20:08, addendum 20:17) | APPROVED except part 8 (manual price meaning) and the Phase 7 default view

Context: scope review against the product goal (find where and with which repeatable activity a character earns the most gold per hour, account-wide, without weaker characters distorting the picture).
1. **Skinning is GATHER** (FR-SRC-2). A location can have several activities at once; the hover lists them with the combined GPH, for example "Chilly Slaps, 5.6 gph, Activities: grinding, skinning". Time is counted once; value is credited per activity. Consequence for code (M2, item stamping): creature loot following a skin cast within the cast window is GATHER, not GRIND (E-24: the skinning window is a second LOOT_OPENED of the same creature GUID; the `skin` cast kind already exists in `P_CAST` and is missing from the GATHER map). Consequence for Phase 4: a segment must be able to carry more than one activity without being cut at every skin (design item, not decided here).
2. **Not needed:** a "usable by this character" filter (a character may go anyway or change professions) and any power measure beyond level.
3. **Value basis (PENDING, see below):** default item value = the higher of vendor price and AH price net of the AH cut. If vendoring beats auctioning after the cut, the vendor figure is used. With no price addon or when the user opts out of its data, only vendor-based values and Cash GPH exist.
4. **Weaker characters never lower a better result:** Account Best takes the highest observed GPH per location (AM-11: never an average across characters); the hover names the responsible character, level and activities. The personal view stays the default. Normalization by 5-level bracket remains experimental.
5. **3b-4 stays in scope** because AH deposit, cut and failed-auction cost decide whether vendoring beats the AH. COD and postage follow the existing plan.
6. **Money sinks are not an activity cost in the heat map (PENDING in part 7).** Repairs and consumables (potions, water, reagents) depend on class and must not skew a cross-character heat map. The cash ledger still records them (0-copper rule unchanged).
7. **Heat metric basis (PENDING confirmation):** the heat map and Account Best use gross value created per active hour (looted coin plus acquired item value). Repairs, consumables, taxi, training and similar are excluded from heat and Account Best and appear only in the personal session/dashboard Net view. This narrows how FR-MET-2 (Cash GPH visible in every GPH view) is read for location views.
8. **Manual price (PENDING):** Q-6 said a manual price beats the vendor floor. Under part 3 a manual price would be an AH-equivalent price and the rule becomes max(vendor, manual x (1 - AH cut)). Needs the user's confirmation; M1 `Valuation.Value` is unchanged until then.
Addendum 1 (user 2026-10-19 20:17):
9. **Heat metric = value created per active hour (APPROVED).** Items are valued by the known vendor prices and the last synchronized AH data; looted coin is never re-priced. With no AH data the vendor-based value is used.
10. **Heat map is dynamic (APPROVED direction).** It must follow the market: when AH data changes (a scan through a tied-in price addon), the shown values are recomputed from the item counts at the current prices (Current Market Value, D-063/AM-12), dated, next to the Verified Value. Example: a grind profitable at medium leather 2g a stack must show the drop when the market falls to 20s. Which of the two is the default view is settled in the Phase 7 design (proposal: Current when fresh price data exists, Verified otherwise). **Data-model requirement:** aggregates per location/activity must keep compact item counts (itemID to quantity) so values can be recomputed; coin is stored as copper. The size is designed in Phase 4/5.
11. **No repairs or consumables in ANY GPH view, personal included (APPROVED).** Repair and consumable costs are not tracked as an activity cost (a dungeon run with deaths must not reduce a grind's value). Net GPH is removed as a metric. Cash GPH is kept, defined as cash income per hour (inflows only), never reduced by repairs, consumables, taxi, training or similar. AH profit keeps deposit, cut and failed-auction risk as costs of that activity (FR-AH-2). The cash ledger still records every copper change (0-copper rule unchanged).
12. The repair-cost API probe (3b-3 Q-9, M2) and the repair-versus-purchase distinction (3b-2 Q-5) are DROPPED as unnecessary.
Part 7 is resolved by 9 and 11. Part 3: with no AH data the value is vendor-based. Part 8 RESOLVED (user 2026-10-19 20:21): a manual price is an OPTIONAL OVERRIDE set only by slash command (`/gi price set|list|clear`), never used by default. The highest value is used and displayed: max(vendor, manual) now, max(vendor, AH net of cut, manual) once AH data exists (Phase 6). The typed price is taken as typed (no AH cut applied to it); a tie keeps the vendor value. Item data must be ready before a manual price is considered. A manual price set later affects Current value views only, never past Verified values (D-063). This amends 3b-3 Q-6 ("manual beats vendor floor").

## Open decisions and open issues

| ID | Question | Status | Needed by |
|---|---|---|---|
| OI-1 | WoW Forever API discovery (Phase 1 scope) | **CLOSED as scoped (2026-10-10 review)**: build, interface, Lua, 272 namespaces, capability inventory and Phase 1 events measured. Residual unknowns moved to OI-8, OI-9, OI-11 | n/a |
| OI-2 | Metric definitions D-012 | RESOLVED 2026-10-09 | n/a |
| OI-3 | Ace3 / HereBeDragons policy | RESOLVED D-021; evidence suggests neither is needed | n/a |
| OI-4 | Deferrals D-013 | RESOLVED 2026-10-09 | n/a |
| OI-5 | Merge pre-existing project documents from other AI sessions | **OPEN** (not answered) | Before relying on these documents as the only source |
| OI-6 | Original 'Error loading' | RESOLVED: packaging (D-026), confirmed by live compile 8/8 | n/a |
| OI-7 | Which event triggered ADDON_ACTION_FORBIDDEN | **MERGED into OI-8** | n/a |
| OI-8 | Restriction model and Phase 3 signals: which events are restricted; how C_RestrictedActions / C_Secrets / C_CombatLog express restrictions; a combat-log-free grind signal; secret values in combat and instances | **OPEN** (follow-ups F1-F4 and `/gidiag reg` per event) | Before Phase 3 |
| OI-9 | Live validation of P_ZONE, P_TICK, P_LEVEL, P_PROFS, P_COMBAT and of Player()/Where()/professions (exceptions E2, E6) | **OPEN**; Phase 2 runtime validation plan steps V2/V3 produce part of this evidence via capability stages | Before Phase 2 is closed |
| OI-10 | TOC interface policy across patches; does the TOC accept a comma-separated list | **OPEN** (D-028) | Phase 2 |
| OI-11 | Re-probe after each client patch and at launch; beta to launch drift | **OPEN** (protocol in Compatibility_Notes.md) | Launch |
| X-1 | Confirm D-022, D-024, D-025, D-026 | **TREATED AS ACCEPTED by the Phase 2 authorization (D-033, assumption flagged); explicit confirmation still welcome** | n/a |
| X-2 | Decide D-027 (legacy removal), D-028 (interface policy) | **OPEN, not needed for Phase 2**; legacy adapters untouched, TOC interface unchanged | Before Phase 3 |
| OI-12 | Phase 2 live validation (Phase2_Runtime_Validation_Plan.md). **Progress 2026-10-15:** migration of the real database, 12 verified registrations (`IsEventRegistered` true), clean startup, logout persistence CONFIRMED. **Remaining:** delivery of money/zone/combat/level events (V3), config persistence across reload (V5), second session `ok` (V4), libraries-off (V7), sandbox run (V8), blocked-event case | **PARTLY DONE** | Phase 2 closure |
| OI-13 | The ChatGPT and Gemini review DOCUMENTS (only six relayed findings were evaluated) | **OPEN** | Next review |
| OI-12 (2026-10-17) | Phase 2 live validation | **CLOSED with exceptions PX-1..PX-8 (D-056)** | done |
| A-4 | Subzone key (mapID + localized text + locale) | Unconfirmed by you; supported by evidence | Phase 5 |
| OI-14 (2026-11-03) | Item recording default. AC-19 (D-080, kept by D-081) says `/gi lots` is OFF after every login and `/reload`; the code (`Ledger/Ledger.lua`, `lotsSwitch = true`) has it ON by default, and the M2 script expected ON. Precedence cannot settle a decision against the code | **OPEN**, user to decide (recommendation: keep ON and supersede the AC-19 default) | Before analysis of live data |
| OI-15 (2026-11-03) | Beta characters and beta lots in the live account's SavedVariables: keep, wipe, or mark as beta | **OPEN**, user to decide | Before analysis of live data |
| OI-16 (2026-11-03) | Privacy scrub before the repo can go public: a character GUID, six character names (about 480 occurrences in about 20 files, including replay fixtures that D-073 says are never edited), the account folder name in Session_Handoff.md, personal details in HANDOFF_Code_Session_2026-11-02.md | **OPEN**, user to decide scope and whether D-073 fixtures may be anonymized | Before the repo goes public |
| OI-17 (2026-11-03) | D-029, D-030, D-031 are still Proposed although the work follows them (D-031 is cited as a rule) | **OPEN**, user to confirm | Next review |

- D-080 progress: M2 delivered (trace only); evidence gate open.

- D-083 (user 2026-10-19 22:00): cursor pick-up/put-back (item leaves bags as `ignored`, returns as `unexplained`) is handled by RELABEL ONLY: no pairing rule, no timing constant. Display wording for `unexplained` becomes neutral ("other additions: moves, returns, unknown"); counted, nothing hidden, no value created. Evidence: M2 trace 2026-10-19 (item 2318 x3 before the vendor opened).

## D-084 M3 approved; lot book scope (user 2026-10-19 22:09) | APPROVED | 2026-10-19
User approved M2 evidence ("the evidence gate did its job") and authorized M3. Stated principle: GoldIntel is an economic ledger, not a perfect inventory mirror; the item system answers (1) where value came from, (2) where value went, (3) what profit or loss resulted. Equip/unequip, cursor pickup, bag rearrangement, manual reagent-bag moves and destroying low-value items are not tracked unless required for acquisition and disposition accuracy; simplicity is favored whenever inventory-mirroring complexity does not materially improve economic accounting.
M3 design choices (consistent with D-081, D-082, D-083):
1. Lots are CREATED by loot and quest rewards (value created), vendor purchases (cost recorded in `cost`, not value created) and disenchant materials (conversion, not value created). They are CONSUMED by vendor sales (copper allocated exactly), quest turn-ins, disenchant sources and trade-outs (copper 0).
2. Mail and trade arrivals, "other additions" (moves, returns, unknown) and inventory-only removals create nothing and consume nothing; they are counted in `/gi lots status`. Mail/trade lots return with 3b-4 when AH purchases arrive by mail.
3. Storage `GoldIntelDB.lots[charKey]` (schema 2, additive, lazy); manual prices `GoldIntelDB.prices.manual` set only by `/gi price set|list|clear` (price needs units, e.g. 1g20s5c; bare numbers refused).
4. Item-data lifecycle: unknown lots are completed when the data arrives and at the next start; invalid ids stay unknown and are listed by `/gi lots unknown`.
5. Anomalies stay visible: one chat line per kind per session ending "please report it as a bug", trace line every time, `/gi lots status` list.
6. Rollback verified: the 0.3.8 (3b-2 M8) build runs unchanged on a database that contains `lots[charKey]` and `prices.manual`.
Evidence references: M2 report, Compatibility_Notes "M2 live evidence".

## D-085 Money pairing for item decisions (found in the user's M2 trace 2026-10-21 18:26) | build 0.4.7-phase3b3m3
Evidence: five quick vendor sales (5 separate PLAYER_MONEY events 0.03-0.1 s apart, each with its own bag event) all showed "money+156" because every decision summed money in one shared window. Booked as-is, the lot book would have counted 156 copper five times.
Rule (deterministic, no heuristics beyond a distance): every money event belongs to exactly ONE bag settle, the nearest one within 1.0 s (ties: the earlier settle). `IS.PairMoney`. A single settle with several items still splits its own money by price (Q-8). Tests: pure pairing, quest-style late money, and a live five-sale burst (each lot gets exactly its own copper, total 156 once) with a mutation check.

- D-084 progress (2026-10-21): Session V passed: ledger check 0 copper, vendor sales exact against cash entries, persistence confirmed, reagent bag confirmed, skinning fixed (name matching). Awaiting user review of the M3 report; M4 not authorized.

## D-086 M3 approved; passive-play mode for live servers (user 2026-10-31) | APPROVED | 2026-10-31
User approved M3 ("I approve M3") and asked to play normally from the live-server launch on 2026-11-04 without running test scripts, with Claude reading the SavedVariables from the user's computer (folder linked to the session) and alerting the user when a package is ready or a decision is needed. M4 (measurements, closure recommendation) is NOT authorized.
Built (0.5.0-passive):
1. Auto start: the collect interval starts by itself 3 s after login (`collect.auto`, default true; `/gi config set collect.auto false` disables; a hand-made `/gi collect off` is never undone in the same session). One chat line announces it. Cash and item pipelines are unchanged (AC-15 still holds).
2. Every interval starts marked, so `/gi ledger check` works at any time without `/gi ledger mark`.
3. Trace: rolling window of 3000 lines plus a `trace.keep` list (cap 400) of evidence lines that routine lines cannot push out: ANOMALY, UNMATCHED, "-> unexplained", gathering and unrecognized CAST lines, NOTE.
Limits stated to the user: WoW writes SavedVariables only at `/reload` or logout, so Claude sees data per session, not live.
- D-086 addendum (2026-10-31): user approved context event lines and a periodic check (0.5.1). Marks are not placed per event; the interval already starts marked and the check line shows where any drift began.

## D-087 Evidence route for live play: Remote Control link, attach as fallback (user 2026-11-03) | APPROVED | 2026-11-03
Supersedes the evidence-route wording of D-086 ("Claude reading the SavedVariables from the user's computer (folder linked to the session)"), which described the claude.ai chat session. Development moved to a Claude Code cloud session (S-056, S-057); everything else in D-086 stands.
1. **Preferred route:** the user's computer is linked to the Code session through Remote Control, limited to exactly `C:\Program Files (x86)\World of Warcraft\_forever_` (addon files and SavedVariables).
2. **Fallback:** if the link is unavailable, the user attaches `GoldIntel.lua` (character SavedVariables, and the account-wide file when asked) after play.
3. **Trigger:** the user says "logged out, check" (or says `/reload` was typed). No automatic timer or polling (the user declined it).
4. **Each check:** read the GoldIntel SavedVariables read-only; `trace.keep` first; the cash check (difference must be 0 copper); report the ledger difference, `EVT check` lines, anomalies, unexplained adds, new CAST names, roll-won items and anything that needs a user decision.
5. **Guardrails:** never write to WTF or SavedVariables; nothing on the user's computer outside that folder; no code change without the user's approval of a proposal; changes go on a branch with tests and a pull request; files are copied into the AddOns folder only after the user approves that specific build, stating `/reload` or full restart each time.
Status 2026-11-03: the folder is in the user's Remote Control list on the laptop, but that computer does not offer it to cloud sessions (likely cause: the Claude desktop app on Windows needs an update). The fallback (2) is in use until the link works.
Affected: process only. Migration: none.

## Status notes 2026-11-03 (document catch-up, S-057; append-only, nothing above is edited)
- **D-074 A-3** ("collect state not persisted, always OFF after login and /reload") is superseded by D-086 part 1 (auto start 3 s after login, `collect.auto`). A hand-made `/gi collect off` still holds for the rest of that session.
- **Open-issues table, row X-2** is stale: D-027 and D-028 were both approved on 2026-10-18 (P3B-4). Nothing about them is open.
- **OI-8** is formally open only for its closing wording (TODO.md); Phase 3b was built on signals verified in Phase 3a. **OI-9** residue is part of Phase 2 exceptions PX-1..PX-8 (D-056); its "needed by Phase 2 closure" is past. **OI-10** belongs to the D-028 release checklist: due at launch together with **OI-11**.
- **D-084** heading "M3 approved" means M3 was AUTHORIZED to be built (M2 evidence approved). M3 itself was approved by the user in D-086.
- New open items OI-14 to OI-17 added to the open-issues table.

## D-088 Item recording is ON by default (user 2026-11-03; closes OI-14) | APPROVED | 2026-11-03
Supersedes the default in AC-19 (D-080, kept by D-081): `/gi lots` is ON by default whenever a collect interval runs, including the automatic start after login (D-086). It is no longer "OFF after every login and `/reload`". The separate switch itself stays: `/gi lots off` stops item recording for the rest of that load while the cash ledger keeps running. This is what the code has done since 0.4.7 (`Ledger/Ledger.lua`, `lotsSwitch = true`), so no code change follows.
Affected: Architecture AC-19 text only. Migration: none.

## D-089 Beta data stays in the live account's SavedVariables (user 2026-11-03; closes OI-15) | APPROVED | 2026-11-03
Beta characters and beta lots are kept as they are: no wipe, no beta marker. Revisit when Account Best is built (D-061, AM-11, Phase 7), where beta characters could otherwise win a location.
Affected: none now; a design item for Account Best. Migration: none.

- Status note 2026-11-03 (user): OI-16 (privacy scrub) is DEFERRED and stays open; the repository stays private. OI-17 (status of D-029..D-031) stays open.

## D-090 Every stage ends with a ready-to-install package block (user 2026-11-03) | APPROVED | 2026-11-03
Process rule set by the user. When a stage is finished, the message ends with the latest addon version as a ready-to-install package: the version string `/gi version` will show; whether it matches main (commit named); `/reload` or full restart; exact install steps; how to roll back; the zip itself or how to get it. If the addon did not change, the block says "unchanged, <version> is current" and is still given in full. Written into the working rules of HANDOFF_Code_Session_2026-11-02.md section 8.
Affected: process only. Migration: none.

## D-091 Skinning a corpse GoldIntel never looted is GATHER (user 2026-11-05) | APPROVED | 2026-11-05
Evidence (user's live session 2026-11-04): 7 of 7 skinning windows were booked GRIND because the corpse's first loot window was never seen here (corpses left unskinned or unlooted by other players; each window opened 0.25-0.29 s after the skin cast). User: "some people leave unskinned corpses and that is good profit since it's gold without having to spend time killing."
Rule: a creature loot window that opens at most `ItemSources.SKIN_FIRST` = 1.0 s after the player's own skin cast (`UNIT_SPELLCAST_SUCCEEDED`, kind skin by spell name) is skinning (GATHER, high), even when it is the corpse's first window. The existing repeat-window rule (E-24) is unchanged. This restores D-082 part 1 ("creature loot following a skin cast within the cast window is GATHER"), which the M2 implementation had narrowed. New counter `skinFirst`.
Affected: Collect/ItemSources.lua. Migration: none (new lots only). Build 0.5.2-passive.

## D-092 The final check at a real logout uses the last seen balance (user 2026-11-05) | APPROVED | 2026-11-05
Evidence: `EVT check final difference=-17 ... MISMATCH` at a logout on 2026-11-04 although no money moved: GetMoney() reads 0 during a real logout (E-46). Rule: while the logout handler ends the interval, `Ledger.Check()` uses `Money.Last()` (the last balance PLAYER_MONEY reported) and returns `atLogout = true`; the check line ends with ` logout`. `unseen` cannot be measured then; money the client never reported is still caught by the next login's gap check. `/gi ledger check` and the periodic check are unchanged.
Affected: Ledger/Ledger.lua, Ledger/Trace.lua. Migration: none. Build 0.5.2-passive.

## D-093 Trainer fees are a source (user 2026-11-05) | APPROVED | 2026-11-05
Evidence: 5 of 7 OTHER entries on 2026-11-04/05 (410 of 447 copper) were trainer fees (two right after level 4, three followed by a profession change). User: "yes add trainer source". Rule: `TRAINER_SHOW` / `TRAINER_CLOSED` (new collector group G9, Platform/Trainer.lua) open a `trainer` context; money OUT inside it (window mode, 1.0 s linger, like the vendor) is source `trainer`, activity `TRAINER` (not a LocationAct, never creditable), confidence med. Money IN inside the window is not matched.
NOT verified live: the two events were never registered by GoldIntel in the Forever client (Accountant Classic registers TRAINER_SHOW on Forever [reported, Reference_AccountantClassic.md]). They are on the allow-list by this user decision; Events.Bind verifies registration and the Collector journal quarantines a faulting event. The first trainer visit is the live check (`EVIDENCE trainerRegistered=`, `EVT trainer open|close`, probe capability `trainer.events`). A new event means a FULL CLIENT RESTART for this build.
Scope note: this brings one money sink from the 3b-4 candidate list forward as a post-closure fix of the cash ledger (D-079 policy); 3b-4 itself stays NOT authorized. Taxi, respec, barber, guild bank, repairs stay OTHER.
Affected: Platform/Trainer.lua (new, TOC), Platform/Events.lua, Platform/Platform.lua (allow-list), Platform/Probe.lua, Collect/Collector.lua, Collect/Context.lua, Collect/Sources.lua, Collect/Stamps.lua, Ledger/Trace.lua. Contract 1.10.0 (additive). Migration: none.

## D-094 Quest turn-ins leave an evidence line in the trace (user 2026-11-05) | APPROVED | 2026-11-05
Evidence: one quest reward (Rugged Mail Vest, 2026-11-04) arrived without quest context and became "other additions"; the trace had no quest event line to show why. Rule: `EVT quest done id=<questID> copper=<n>` for every P_QUEST_DONE while an interval runs. Evidence only; no decision depends on it.
Affected: Ledger/Trace.lua. Migration: none.

## D-095 Item rolls the player wins are loot (user 2026-11-06) | APPROVED | 2026-11-06
Evidence (user files 2026-11-05): two items won by roll in Ragefire Chasm (Birchwood Maul, vendor 9s 22c; Ancestral Tunic, 2s 3c) became "other additions" (unexplained, no value created). The live line is `|HlootHistory:..|h[Loot]|h: You won: [item]`; the old pattern `^You won:` missed it, so it was classified as another player's roll. The item lands about 1.4 s after the line.
Rule: a CHAT_MSG_LOOT line containing `: You won: ` (or starting `You won:`) emits `P_LOOT_WON { itemID, qty }`. ItemSources turns it into a loot expectation for that item id (closed at once, kept LOOT_KEEP + WAIT seconds, used once): the matching bag add is `loot` (value created), activity LOOT (med), at the stamped location, reason `roll won`. Another player's win, a different item, or an item arriving after the expectation expired stay unexplained.
Supersedes in part D-080 Q-10 ("CHAT_MSG_LOOT evidence only, no rule until reviewed"): this is the one rule; every other CHAT_MSG_LOOT kind stays evidence only. Cash pipeline untouched (AC-15).
Affected: Platform/Chat.lua, Platform/Events.lua, Collect/ItemSources.lua, Ledger/Trace.lua. Migration: none. Build 0.5.3-passive.

## D-096 A group share line claims the money pieces that sum to it (user 2026-11-06) | APPROVED | 2026-11-06
Evidence: five times (2026-11-05, groups of 3 to 5, two of them with normal latency) one "Your share of the loot is N Copper." line followed two separate PLAYER_MONEY changes summing to exactly N (12+5, 13+4, 7+16, 1+4, 3+2); both pieces became OTHER. Explanation (user, 2026-11-06): several corpses looted at the same moment by different players; the game pays each share separately and prints one line with the total. There is no area loot in this version of the game [reported, user 2026-11-06].
Rule: when a share line of N arrives, `Reconciler:ClaimPendingSum(N, spec)` books 2 or 3 PENDING positive deltas whose sum is exactly N as loot entries (conf high, comp split, the share's window source if one was split). It refuses when a single pending delta equals N (the normal exact match applies), when no set sums to N, and when more than one set does (ambiguous). Pieces already written as OTHER are never edited. Solo "You loot N" lines never claim several deltas.
Supersedes in part 3b-2 Q-4 ("no expectation is ever matched across two deltas") for this one case only. The Reconciler stays source-agnostic (the caller passes src, ctx, ref, comp).
Affected: Collect/Reconciler.lua, Collect/Sources.lua. Migration: none. Build 0.5.3-passive.

## D-097 M4 authorized; measurement build 0.5.4 (user 2026-11-07) | APPROVED | 2026-11-07
User: "start M4" (after approving the merge of PR #4). M4 = measurements (lot size, CPU, memory) and the 3b-3 closure recommendation. Built for it: `Platform/Perf.lua` (read-only CPU and memory figures through C_AddOnProfiler and GetAddOnMemoryUsage, whatever the client offers), samples at interval begin, every 10 minutes and at the end in `GoldIntelCharDB.perf.samples` (cap 500), `EVT perf` trace lines, `/gi perf`, probe capability `perf.profiler`. Interim results and retention options R-1..R-4 in Phase3b_3b-3_M4_Report.md (nothing about caps is changed without the user's decision).
User evidence notes of the same day: the three payments of 80 silver in Thunder Bluff (2026-11-07 06:14 UTC) were 10-slot bags bought at the auction house (AH buyouts are OTHER until 3b-4, as planned); a disconnect happened in Blackfathom Deeps (seen in the data: the session ended 21:52 UTC, the next login at 21:57 booked a +44 copper login gap; everything before it was saved).
Affected: Platform/Perf.lua (new, TOC), Ledger/Trace.lua, Core/Slash.lua, Platform/Probe.lua. Contract 1.12.0 (additive). Migration: none (new optional `perf` table in the character data). FULL CLIENT RESTART (new file).

## D-098 Retention stopgap R-1, R-2, R-3 (user 2026-11-07) | APPROVED | 2026-11-07
User: "Approve R-1, R-2 and R-3 as a stopgap" (options in Phase3b_3b-3_M4_Report.md section 3), until Phase 4 aggregates keep where gold was earned.
1. R-1: `Cash.CAP` 6,000 raw entries per character before the oldest 500 fold into totals (was 2,000, 3b-2 Q-6; supersedes that value). About 1.2 MB per active character at the cap.
2. R-2: `Lots.CAP_OPEN` 4,000 (was 1,500, 3b-3 Q-11); at the cap lots merge only when item, value, kind, flags AND zone, subzone and activity are equal, so the place survives at subzone level (exact coordinates of the merged lots are not kept).
3. R-3: `trace.keep` holds at most one "-> unexplained" line per item id per interval; every line stays in the rolling trace.
Affected: Ledger/Cash.lua, Ledger/Lots.lua, Ledger/Trace.lua. Contract 1.13.0. Migration: none (existing data stays; the new caps apply from the next add). Build 0.5.5-passive (contains 0.5.4). `/reload` is enough over 0.5.4; a FULL restart over 0.5.3 (new file from 0.5.4).
The user also asked for a Phase 4 proposal (live aggregation per location and activity, no code): Phase4_Live_Aggregation_Proposal.md. Proposal only; Phase 4 is NOT authorized.

## D-099 Phase 4 design answers; P4-M1 authorized (user 2026-11-07) | APPROVED | 2026-11-07
User answers to Phase4_Live_Aggregation_Proposal.md section 9:
- Q-1 YES: cell key place x activity x 5-level bracket, with item counts per cell.
- Q-2 YES: heat time bins for EVERY visited 32 x 32 cell (not only cells with credit).
- Q-3 Mixed activities: time is SPLIT by the current activity; the place still shows its total once (AM-14).
- Q-4 YES: back-fill the launch-week value and item counts from the raw records, WITHOUT time.
- Q-5 YES: lower the raw caps again, but only after Phase 4 is validated.
- Q-6 YES: a /reload reminder every 60 minutes, ONE chat line, only outside combat.
- Q-7 YES: Phase 4 budget over the 0.5.5 baseline: at most +0.05 ms per frame on average, +0.2 MB per hour.
Authorization: P4-M1 (pure modules and tests, NO change to live behavior) is authorized now. P4-M2 (wired live) waits for the 0.5.5 hour-of-play measurements AND a separate user approval. Phase 4 beyond P4-M1 is NOT authorized.
Built in P4-M1 (session S-061): `GoldIntel/Aggregate/Clock.lua` (time classes with the D-054 priority: manual pause > taxi/loading > idle > soft travel > active, current activity per Q-3) and `GoldIntel/Aggregate/Aggregator.lua` (cells, heat bins, queue, back-fill, live check, segments). They are NOT listed in GoldIntel.toc, so the client never loads them.
Moved to P4-M2 because they touch the live client: the map-size probe needed for soft-travel distance, the /reload reminder (Q-6), wiring and storage. Open for P4-M2 verification: the soft-travel minimum speed (8 yards per second) is an assumption, not part of D-054; back-fill is incomplete by construction where raw records were folded or lots left the closed ring (recorded in `backfilled`, never filled in).
Affected: new files only. Migration: none. Package: unchanged (0.5.5-passive).

## D-100 Automatic perf samples read CPU only; memory only on /gi perf (user 2026-11-08) | APPROVED | 2026-11-08
Evidence (user files 2026-11-08, 0.5.5, 42 samples, sessions up to 111 minutes): every automatic sample added exactly one frame over 100 ms (CountTimeOver100Ms +1 per sample; 100 to 400 ms). The cause is the memory reading: UpdateAddOnMemoryUsage recounts every loaded addon (about 60) and the time is charged to GoldIntel. GoldIntel's own work: 0.04 to 0.06 ms per frame session average. The user did not notice a stutter.
User: "0.5.6 is approved: remove the automatic memory reading, keep the automatic CPU samples, and read memory only on /gi perf."
Rule: `Perf.Sample(opts)` reads memory only with `opts.memory = true`; the begin, periodic and final samples read CPU only (`memSkipped`); `/gi perf` reads memory on request and says a short freeze is possible.
Also recorded the same day: the user will decide the 3b-3 closure after reading Phase3b_3b-3_Closure_Recommendation.md; the P4-M2 plan is delivered as a plan only (Phase4_P4-M2_Plan.md); nothing beyond 0.5.6 is merged or built before the user approves.
Affected: Platform/Perf.lua, Ledger/Trace.lua (comment), Core/Slash.lua. Contract 1.14.0. Migration: none. Build 0.5.6-passive; `/reload` is enough over 0.5.5.

## D-103 Standing orders for every Code session (user 2026-11-08) | APPROVED | 2026-11-08
User: "Standing instruction, effective now." Recorded in full in CODE_STANDING_ORDERS.md (the user's words quoted) and kept current in NEXT_SESSION_PROMPT.md. Key sentences: "Add the rule that anything I decide in chat gets recorded in the docs with my exact words."; "Update Session_Handoff first ... Commit and push it, and say so."; "Tell me when to start a new Code session: if your context has been summarized, or a session has run long, and only at a clean stopping point with nothing half-built and nothing unpushed."; "End with three short parts: 'What you do' (plain language, numbered), 'Reply to send' (ready to paste), and the package block. Keep reports short; long evidence goes in files in the docs folder."; "Do this in your next push, docs only ... Do not change any code or merge anything for it."
Note: D-099 to D-102 are recorded on the open branches (PR #7, #8, #9) and reach main with those merges; this entry is on branch docs/session-state.

## D-104 Chat-only decisions confirmed and recorded with the user's words (user 2026-11-08) | APPROVED | 2026-11-08
User: "Record the chat-only items in Session_Handoff S-064 in Decisions.md with my words: confirmed." The items, with the user's words as S-064 lists them:
1. Lag, no code change. 2026-11-05: "Lag has been very bad on launch, this may explain it". 2026-11-06: "I had very bad lag in RFC up to 3000 ms in some cases. This is not normal and we don't need to adjust code for it". Effect: the late-money fix stays unbuilt (lag case closed without a code change).
2. Merge approvals (dates of the merges from the git history): PR #1, 2026-11-03: "Merge PR #1 after you update it with these". PR #3 (includes #2), merged 2026-11-05: "Approve merging PR #3 (includes #2). I will install 0.5.2 myself tonight." PR #4, merged 2026-11-07: "Approve merging PR #4 and start M4" (the M4 part is D-097). PR #6 (includes #5), merged 2026-11-07: "Merge PR #6".
3. The four answers of 2026-11-05 behind D-091..D-094: "1. yes because some people leave unskinned corpses and that is good profit since it's gold without having to spend time killing" (D-091); "2. agree with recommendation" (D-092); "3. yes add trainer source" (D-093); "4. yes for that option" (D-094).
Not confirmed by this decision: the quotes in Phase4_P4-M2_Plan.md section 0 (D-102). The reply of 2026-11-08 again carried the unfilled placeholder "[correct / corrections]"; that confirmation stays OPEN.

## D-105 Session rules, first-report exception, docs-only merge approval, document fixes (user 2026-11-08) | APPROVED | 2026-11-08
User answers of 2026-11-08 (second message of the day to session S-065), exact words:
1. "Standing order 6.1 applies to every report, with one exception: a new session's first report is read-only. Add that exception to CODE_STANDING_ORDERS.md and NEXT_SESSION_PROMPT.md."
2. "Add to the standing orders: only one Code session works on the repo at a time; the old session stops once the new one has verified the handoff. Evidence files must be re-attached in the session that analyzes them."
3. "Mark CODE_SESSION_OPENING_PROMPT.md as replaced by NEXT_SESSION_PROMPT.md."
4. "Fix the stale documents you listed (items 2, 3, 4, 6, 7): TODO.md (current phase and approvals), Project_Bible.md (version, document list, evidence folder), README, the TOC description note. Docs only, on the docs/session-state branch, no code change."
6. "After that, approve merging PR #10 (docs only). Standing approval: you may merge docs-only pull requests that change only Session_Handoff.md, NEXT_SESSION_PROMPT.md, CODE_STANDING_ORDERS.md or the recording of my decisions; tell me each time. Code, versions and other merges still need my explicit approval."
(Answer 5 is D-104. Answer 7, installed versions and 0.5.6 hours, arrived as an unfilled placeholder: "[version on main character / alt]", "[n]"; still OPEN.)
Done in S-065 on branch docs/session-state: standing orders sections 2, 6 and 8; NEXT_SESSION_PROMPT.md; CODE_SESSION_OPENING_PROMPT.md marked replaced; TODO.md CURRENT PHASE block; Project_Bible.md header, section 9 and inventory (doc version 1.0.2, by this user decision); README status.
Held, not done: the TOC description note (`## Notes:` in GoldIntel/GoldIntel.toc). The TOC is an addon file, not a document: changing it on main makes main's 0.5.5-passive files differ from the 0.5.5 package with no version change, and it sits next to the `## Version:` line that PR #8 and PR #9 change. Proposed instead: change it in the next approved build. Waiting for the user.
Affected: documents only. Migration: none. Package: unchanged (0.5.5-passive on main).

## D-106 Claude merges approved pull requests itself; work-branch pushes need no approval (user 2026-11-08) | APPROVED | 2026-11-08
User: "Standing order, effective now. Record it in CODE_STANDING_ORDERS.md and NEXT_SESSION_PROMPT.md with my words, and as a decision:
"Once I approve a merge in chat, you merge it yourself through its pull request (gh pr merge <n> --merge; no squash, no rebase, no direct push to main), then check main and report the merge commit and the test result. Approval is still required for every merge except the docs-only standing approval. Commits and pushes to work branches need no approval. Never force-push or delete branches.""
Same message: "Also add .claude/settings.json with {"permissions":{"allow":["Bash(gh pr merge *)"]}} on a docs branch and open a PR. I'll merge that one myself. If a merge is still blocked after that, tell me the exact message and don't work around it."
Same message, for the EmpireIntel project (separate repo shawn571/EmpireIntel, not GoldIntel): "For EmpireIntel only, add the same docs-only standing approval GoldIntel has (D-105): 'you may merge docs-only pull requests that change only Session_Handoff.md, NEXT_SESSION_PROMPT.md, CODE_STANDING_ORDERS.md or the recording of my decisions; tell me each time.'" Not acted on in the GoldIntel session (the projects are kept apart, and another session may be working on EmpireIntel); asked the user where to apply it.
Note (S-066): PR #10 was merged earlier the same day through the GitHub REST merge endpoint (a merge commit through the pull request, 10adc91), because `gh pr` commands are refused in this environment ("HTTP 403: GitHub GraphQL is not available from Claude Code sessions"). From D-106 on, merges use `gh pr merge` only; if it is refused, the exact message is reported and nothing is merged.
Affected: documents only (CODE_STANDING_ORDERS.md section 2, NEXT_SESSION_PROMPT.md); .claude/settings.json on its own pull request for the user to merge. Migration: none. Package: unchanged.
Addendum (user, 2026-11-08, after `gh pr merge 12 --merge` was refused with the GraphQL 403): "While gh pr merge is refused: use the REST merge endpoint (gh api -X PUT repos/shawn571/GoldIntel/pulls/<n>/merge -f merge_method=merge), a merge commit through the PR, never a push to main." "Record it with my words in D-106, CODE_STANDING_ORDERS.md and NEXT_SESSION_PROMPT.md. Change #11's rule to Bash(gh api -X PUT repos/shawn571/GoldIntel/pulls/*/merge *); I'll merge #11 myself. Then merge #12 with the REST command and check main." This supersedes the sentence above "From D-106 on, merges use `gh pr merge` only". EmpireIntel: "I'll give it to the EmpireIntel session (already done)." The question is closed; nothing was changed in shawn571/EmpireIntel from the GoldIntel session.

## D-107 P4-M2 section 0 quotes confirmed; 0.5.6 installed everywhere; TOC note in the next build (user 2026-11-08) | APPROVED | 2026-11-08
User: "Merged #11. Section 0 quotes: correct. Installed: 0.5.6-passive on all characters (6620666; your package block says 0.5.5, which is main, not what's installed). 0.5.6 hours so far: [n]. TOC note: next approved build."
1. The quotes in Phase4_P4-M2_Plan.md section 0 are correct. This closes the confirmation left OPEN in D-102 and D-104.
2. Installed: 0.5.6-passive (commit 6620666, PR #8) on all characters. Main is 0.5.5-passive, so the installed build is ahead of main until PR #8 is merged.
3. The TOC `## Notes:` change held in D-105 goes into the next approved build; it is not done on its own.
4. Package block correction (the user's note): the block names the latest delivered build and what is installed, and says separately whether that build matches main; from S-067 it reads 0.5.6-passive, not main's 0.5.5.
Still OPEN: the 0.5.6 hours so far (arrived as the placeholder "[n]"), and whether 0.5.6 works live (D-102: needed before PR #8 and PR #7 are merged).
Affected: documents only. Migration: none. Package: unchanged (0.5.6-passive installed; main 0.5.5-passive).

## D-108 Docs-only standing merge approval extended to TODO.md and Changelog.md (user 2026-11-08) | APPROVED | 2026-11-08
User: "Extend the docs-only standing approval to also cover TODO.md and Changelog.md. Record it with my words, then update TODO.md now and merge it under that approval."
Rule: the D-105 standing approval now covers pull requests that change only Session_Handoff.md, NEXT_SESSION_PROMPT.md, CODE_STANDING_ORDERS.md, the recording of the user's decisions (Decisions.md), TODO.md and Changelog.md; Claude tells the user each time. Code, versions and every other merge still need his explicit approval. Merged with the REST command while `gh pr merge` is refused (D-106 addendum).
Done in S-068: TODO.md CURRENT PHASE block and open tasks brought in line with D-107 (section 0 quotes confirmed, 0.5.6 installed, TOC note in the next approved build).
Affected: documents only (CODE_STANDING_ORDERS.md section 2, TODO.md). Migration: none. Package: unchanged.

## D-109 0.5.6 baseline PASSED; PR #8 and PR #7 merged; PR #9 stays unapproved (user 2026-11-14) | APPROVED | 2026-11-14
User (2026-11-14): "Logged out, check. 0.5.6 hours: about 11.9 h in the last 10 sessions (Nov 11-13; longest 4.4 h, plus 2.5, 2.2, 1.2 and 1.1 h), plus Nov 8-10 play. Files attached (account file and three character files). 0.5.6 works live: yes. Group or dungeon session: yes." And: "If the baseline passes, merge #8 then #7. #9 stays unapproved".
Evidence (S-069, files attached in the session; details in Baseline_0.5.6_Report.md): Paladin (Player-6796-00636CEC) on 0.5.6: 29 loads, 39.9 hours loaded, 13 loads of 60 minutes or more, 224 periodic CPU samples (D-102 needed 3 hours, 3 sessions, one of 60 minutes, 18 samples); Gnomeregan and Scarlet Monastery in groups of up to 5. GoldIntel CPU 0.017 ms per frame (load-weighted session average; NFR-3 limit 0.5). Frames over 100 ms charged to GoldIntel: the load frame of some /reloads (100 to 178 ms; never at a fresh login), and two frames in the 8-hour session of 2026-11-13/14 (312 ms between 00:08 and 00:18 UTC, and one more between 00:58 and 01:08) while the shared Lua heap shrank (garbage collection, inferred). Every ledger check of 0.5.6 is 0 copper; the only two MISMATCH lines in the files (-271 and -6, alt Player-6796-00333B18) are from 2026-11-05 (0.5.1, before D-092) and remain in trace.keep. 0 collector errors, 0 UNEXPECTED lines, no gap recorded on any character.
Done: PR #8 merged with the REST command (2ecc6cc; main = 0.5.6-passive, addon files identical to 6620666, 1,319 tests), then PR #7 (4c78dbe; P4-M1 Clock and Aggregator added but NOT in the TOC, so the client still runs exactly 0.5.6; 1,343 tests). Both branches first took main by a merge commit on the work branch (documents only conflicted). PR #9 (0.6.0) is NOT approved: not merged, not installed.
Q-7 baseline (D-102) for P4-M2: 0.017 ms per frame average; budget +0.05 ms per frame.

## D-110 Other add-ons: copy and credit where allowed, clean room otherwise, cross-checks, optional plugins (user 2026-11-14) | APPROVED | 2026-11-14
User: "New standing order (record with my words in CODE_STANDING_ORDERS.md, NEXT_SESSION_PROMPT.md and Decisions): We can copy and credit where it's allowed. Where copying isn't allowed and it's a core function of what we're trying to build, do the clean room thing. We can use addons to check our work too. Where it makes sense we will have some things be optional plugins and note that some features will be better if these addons are installed but our addon will still work without them."
"In practice: copy only from MIT or CC BY sources, credited in THIRD_PARTY.md. For GPL or All Rights Reserved sources, use only the reviewer's hint notes, never their code or data tables, and record 'approach informed by <add-on>, no code copied'. GoldIntel must work without any other add-on. As a cross-check, compare GoldIntel's session income and spending with Accountant Classic's (installed) for the same sessions, especially the OTHER share; read its file only for comparison. Plan question, no code: for prices, report what GoldIntel does now and whether Auctionator's or TSM's public interface should be an optional source with our own fallback."
Recorded in CODE_STANDING_ORDERS.md section 9 and NEXT_SESSION_PROMPT.md. THIRD_PARTY.md is created with the first copied item (none yet).
Open from this order: the Accountant Classic comparison needs its SavedVariables file attached (not among the four files of 2026-11-14); the price plan answer is in Baseline_0.5.6_Report.md section 6 (plan only, no code). Licences of Auctionator and TSM are NOT verified in this session (GitHub access is limited to this repository).
Affected: documents only. Migration: none. Package: unchanged.

## D-111 Report merged; price plan added to Phase 6 scope as a plan only; Accountant Classic cross-check (user 2026-11-14) | APPROVED | 2026-11-14
User: "Approve merging #16. Accountant Classic file attached. Installed price add-ons: Auctionator and TSM (both). Price plan: add to Phase 6 scope as a plan only; Phase 6 is still not authorized. #9 stays unapproved."
1. PR #16 (Baseline_0.5.6_Report.md) merged with the REST command (b3bf686; tests 1,343 passed, 0 failed).
2. Price add-ons installed on the user's client: Auctionator and TSM (both).
3. Phase 6 scope (plan only; Phase 6 NOT authorized): optional price providers behind the planned PriceProvider interface (TODO 6.1): Auctionator's and TSM's public interfaces, asked in a fixed order, with GoldIntel's own price (vendor floor, manual, later own observations) always available; a market price is a separate figure with source and age and never changes an acquisition value (D-063). Interface calls on Forever and both licences are to be verified before any build (D-110).
4. PR #9 (0.6.0) stays unapproved.
Accountant Classic cross-check (D-110; file attached 2026-11-14, read only for comparison; Accountant's days are local time, matched at UTC-5): Paladin Player-6796-00636CEC, 2026-11-11 to 11-14: GoldIntel's net equals Accountant's own recorded daily balance change to the copper on each day it can be checked (11-12 +31,180; 11-13 +30,547; 11-14 +8,540), and both end at 116,116. Alt Player-6796-00333B18, 11-11: both net +82. Differences are in Accountant's gross figures only: it books in/out pairs that match no money change in GoldIntel's trace (its GUILD category, small MAIL and OTHER pairs), its category sums exceed its own balance change by 74 copper on 11-12, it files a 5,757 vendor sale under REPAIRS, and it books AH sales net of the cut. GoldIntel's OTHER spending on 11-12 and 11-13 (11,787 copper) is mostly what Accountant names TAXI (5,955), MAIL postage (1,401) and AH deposits (1,160): the known 3b-4 sinks.
Affected: documents only. Migration: none. Package: unchanged.

## D-112 PR #18 merged; PR #9 reviewed, not merged; 3b-4 order after 0.6.0 (user 2026-11-14) | APPROVED | 2026-11-14
User: "Approve merging #18. Next: review #9 (0.6.0). Bring it up to date with main (documents only if conflicts), rerun the tests, and give me a plain summary: what 0.6.0 adds in game, what it changes in saved data, its CPU and memory cost against the 0.5.6 baseline (0.017 ms per frame), reload or restart, exact test steps, and the package block. Don't merge #9 and don't build anything new; I'll approve after reading it. 3b-4 (flight fares, postage, AH deposits) comes after 0.6.0."
1. PR #18 (report section 7) merged with the REST command (ce3568c; 1,343 tests).
2. PR #9 brought up to date with main by a merge commit on its branch (1221a7c; documents only conflicted; addon files identical to e6946b0; 1,365 tests). Review added on the branch: GoldIntel_Docs/Phase4_P4-M2_Review.md (reaches main only with #9). PR #9 is NOT merged, NOT approved, and no package was built.
3. 3b-4 order: after 0.6.0; flight fares, postage, AH deposits (the user's list; the Accountant cross-check showed flight fares as the largest OTHER item). 3b-4 is NOT started.
Affected: documents only. Migration: none. Package: unchanged (0.5.6-passive).

## D-113 0.6.0 document gaps, TOC note and trace.keep fix; install approved for the P4-M3 live check (user 2026-11-14) | APPROVED | 2026-11-14
User: "Verified. Fix the document gaps on #9’s branch (D-101/D-102 and S-063 onto main via #9, TODO stale lines, README test command) and add the TOC Notes change to 0.6.0: yes. Project Bible header and inventory update: yes. trace.keep finding: keep only MISMATCH and final lines, with a test. 0.6.0: approve install for the P4-M3 live check once those changes are in; merge #9 only after I report the live check passed. Then give me the 0.6.0 build with the package block and the test steps."
1. Document gaps fixed on PR #9's branch (p4/m2-live): D-101, D-102 and handoff S-063 already sit there and reach main with #9; TODO.md stale lines (Phase 4 line, TOC note task, review finding) corrected; README.md test command is `lua5.4 run.lua`; Project_Bible.md header and inventory updated (on the same branch, so they also reach main with #9).
2. TOC `## Notes:` (held since D-105, D-107): "Gold-making intelligence and analytics for WoW Forever: cash ledger, item lots and live gold per place and activity".
3. trace.keep (review finding 1 of Phase4_P4-M2_Review.md): periodic `EVT agg` and `EVT clock` lines stay in the rolling trace only; `trace.keep` gets the final pair of each interval and any `EVT agg` line marked MISMATCH. `EVT clock` lines now carry the same `periodic|final` word as `EVT agg`. Tests: one scenario test and three mutation checks.
4. 0.6.0-passive is approved to INSTALL for the P4-M3 live check once 1 to 3 are in (they are, S-072). The version stays 0.6.0-passive (never delivered before). PR #9 is merged ONLY after the user reports the live check passed.
Affected: GoldIntel.toc, Aggregate/Live.lua, Ledger/Trace.lua, Tests/test_p4m2.lua; Contracts F23 (1.15.0, not yet in effect on main). Migration: none (trace.keep is a list of strings; old periodic lines already in it age out at the cap). FULL CLIENT RESTART over 0.5.6 (new TOC files).

## D-114 Standing permission for GoldIntel Code sessions (user 2026-11-14) | APPROVED | 2026-11-14
User: "Standing permission (record as a decision with my words, plus CODE_STANDING_ORDERS.md and NEXT_SESSION_PROMPT.md): “GoldIntel Code always has permission to edit code and docs, run tests, build packages, commit and push to work branches. My approval of an increment or fix in chat is the go-ahead to do all of that for it. Merges still follow the merge rules; never push to main or force-push.”"
And: "Make that work technically: on a branch from main, replace .claude/settings.json with {"permissions":{"allow":["Edit","Write","Bash(lua5.4 *)","Bash(lua5.1 *)","Bash(python3 tools/*)","Bash(git add *)","Bash(git commit *)","Bash(git push origin *)","Bash(gh api -X PUT repos/shawn571/GoldIntel/pulls/*/merge *)"],"deny":["Bash(git push origin main*)","Bash(git push --force*)","Bash(git push -f*)","Bash(git push origin +*)"]}} Open a PR and merge it: approved. Then continue with my 0.6.1 approvals from my last message. If anything is still blocked, quote the exact command and message."
Why: in S-072 the session's permission check refused a code edit on p4/m2-live and read access to shawn571/EmpireIntel although the user had asked for the fixes.
Done: recorded in CODE_STANDING_ORDERS.md section 2 and NEXT_SESSION_PROMPT.md. NOT done: the `.claude/settings.json` change. Writing that file was refused by the session's permission check ("Permission for this action was denied by the Claude Code auto mode classifier. Reason: [Unauthorized Access]"): a session may not change its own permission rules. The user makes that change himself (S-073 report gives the file). With the user's approval in chat, the normal edit tools then worked for code and documents in S-073.
Affected: documents (the settings file is the user's). Migration: none. Package: unchanged.

## D-115 P4-M3 live check 1 of 0.6.0: findings; 0.6.1 fixes approved; plans (user 2026-11-14) | APPROVED | 2026-11-14
User (live check, files attached in S-072): "0.6.0 live check (files attached). Passed: version, agg status, agg check 0, probe map.worldsize [ok], afk/resume, activity set/clear, ledger check 0 over 5161 s. Don’t merge #9; fix these first:" followed by six points: the 1771 ms frame ("Find the cause and fix it; spread the back-fill over several frames if that’s it."), time counted twice ("The buckets must not overlap, and their total must equal the session time. Add a test for that."), /gi agg top ("Rank by gold per hour with a minimum time, and list back-filled places separately."), the reminder ("Replace the chat line with a popup: Reload Now / Ignore / Configure. ... Never show the popup in combat or during an encounter. Verify that a button click may call a reload on Forever."), the UI direction (plan only) and file size (plan only).
User (approvals): "Approve the 0.6.1 fixes as proposed: item-info filter and spread back-fill: yes. Non-overlapping time classes with loading screens as hard travel, total= and session= on the final line, and the test: yes. Soft travel across zones: not now, plan it separately. agg top by gold per hour with a 10-minute minimum, back-filled places listed separately: yes. Reminder popup with the bands as proposed, never in combat or an encounter, verify the reload click in game: yes. Configure: A, a small Settings window now that becomes the Settings tab later. EmpireIntel: screenshot attached [attach one]. Retention: 7-day raw window plus daily summaries, a separate rule for open lots, test mode switch, plan only. Update the handoff, then build 0.6.1 with the package block and test steps. Don’t merge #9 until I report the live check passed."
Findings (files of 2026-11-14, read only; details in Phase4_P4-M3_LiveCheck1.md): the 1771 ms frame came from 3,566 item-data replies requested by another add-on (up to 1,999 in one second; 2,526 items, 31 of them in the Paladin's lots), each handled by GoldIntel (desktop 0.060 ms per event); the back-fill took 7.2 ms in all on desktop. travelUnknown overlapped the classes; 26 s of loading screens were never classified. The reminder did fire (15:17:33 UTC, chat only, not traced).
Built (0.6.1-passive, contract 1.16.0, S-073): item replies only for items GoldIntel asked for (desktop: 1,999 foreign replies 3.8 ms instead of about 120); back-fill in steps of 500 records per tick from a snapshot, finished at logout; five non-overlapping classes with loading screens as hard travel and longer freezes as idle, `total=` and `session=` on EVT clock, noDistance (was travelUnknown) shown apart; agg top by gold per hour (10 minutes minimum), back-filled places apart; the popup (Reload Now / Ignore / Configure) with the bands Safe 15..60, Risky 90..180, Not Recommended 240/360, Off, never in combat or an encounter (ENCOUNTER_START/END as collector group G10), the chat line as fallback; a small Settings window (option A) opened by Configure and `/gi settings`.
Unverified on Forever (live check 2): the reload from a button click (C_UI.Reload / ReloadUI), StaticPopup with three buttons, the Settings window's frames and slider, ENCOUNTER_START/END.
NOT now: soft travel across zones (plan separately). Plan only: retention and UI (Phase4_P4-M3_LiveCheck1.md sections 5 and 6). Open: the EmpireIntel screenshot arrived as the placeholder "[attach one]" (no file attached). PR #9 is merged only after the user reports the live check passed.
Affected: Platform/Items.lua, Map.lua, Events.lua, Platform.lua, UI.lua (new), Probe.lua; Core/Reminder.lua (new), Config.lua; Collect/Collector.lua; Aggregate/Clock.lua, Aggregator.lua, Live.lua; Ledger/Trace.lua; TOC; tests. Contract 1.16.0 (F24). Migration: none. FULL CLIENT RESTART (two new TOC files, two new events).
