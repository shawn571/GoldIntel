# GoldIntel Architecture v1

DOC VERSION: 1.0.0  |  DATE: 2026-10-09  |  Must agree with Decisions.md (Decisions wins) and Requirements_v1.md (Requirements wins).

Self-contained consolidation of design spec Part 1 (v0 draft) and Part 2 (review), re-scoped to the charter (D-013). Contains no code beyond illustrative snippets.

## 1. Overview

GoldIntel observes the player's money, loot, vendor, mail, trade, quest, and location signals, turns them into two ledgers (cash and assets), slices play time into sessions and segments, computes Cash / Wealth / Net GPH, aggregates by zone, subzone, and activity, values items through pluggable price providers, and renders rankings, heatmaps, and auction-profit views.

## 2. Layered diagram

```
+------------------------------ Platform (only WoW API users) ------------------------------+
| Events | Clock | Scheduler | Unit | Map | Money | Loot | Merchant | Mail | Trade | Auction |
+-------------------------------------------------------------------------------------------+
           | normalized events (plain tables, contract: Contracts.md F2)
           v
 +-----------+     +--------------+     +-----------+
 | Collector |---->| Reconciler   |---->| Ledgers   |  cash ledger + asset ledger (Lots)
 +-----------+     | Expectations |     +-----------+
                   +--------------+           |
        ActivityEngine <--- Context           v
              |                         SessionEngine ---> Metrics ---> Rankings
              v                               |                |
        (activity tag)                        v                v
                                         HeatMapEngine ------> UI
        PricingEngine (providers) --> valuation for Lots, AHMath for listings
        Store (SavedVariables, migrations, pruning) under everything
        Future/ (CommunityDataEngine, RouteEngine): stubs only
```

## 3. Invariants (each must have an automated test)

1. **Ledger sum:** for any window, sum of tagged cash entries = actual money delta.
2. **No double count:** a lot is created once and consumed once; selling a lot is a conversion, never value created.
3. **Segments partition active time:** no overlap, no gap while active.
4. **Heat bins** contain only location-attributable income (grinding, gathering, fishing).
5. **Platform boundary:** no WoW global is referenced outside `Platform/` (static test).
6. **Settlement exclusion:** settlement entries never enter GPH windows unless explicitly requested.
7. **Aggregation:** rates are always derived from summed numerators and denominators.

## 4. Modules and responsibilities (with requirement trace)

| Module | Responsibility | Requirements |
|---|---|---|
| Platform | WoW API access, normalized events, capability probing | FR-PLT-1..3 |
| Core | Module registry, typed bus, config, slash commands, lifecycle | NFR-5 |
| Store | SavedVariables, schema, migrations, pruning, checkpoint | NFR-4, DR-1..4 |
| Collector | Registers handlers on Platform events, enqueues raw events | FR-SRC-1..8 |
| Context | Tracks merchant / mail / trade / quest / loot open state | FR-LED-1 |
| Expectations | Registry of expected copper amounts with TTL | FR-LED-1, FR-LED-5 |
| Reconciler | Money delta to cash entries; guarantees invariant 1 | FR-LED-1, FR-LED-5 |
| Lots | Asset ledger; FIFO conversions; inventory valuation | FR-LED-2, FR-LED-3 |
| ActivityEngine | Current activity (auto rules + manual override), idle detection | FR-SES-2, FR-SES-3 |
| SessionEngine | Sessions, segments, rotation, active time | FR-SES-1..4 |
| Metrics | Cash / Wealth / Net GPH, normalization, aggregation, explain data | FR-MET-1..5 |
| Rankings | Zone / subzone / activity rankings from aggregates | FR-RNK-1..4 |
| PricingEngine | Provider chain, valuation, staleness | FR-AH-1, FR-AH-3 |
| AHMath | Cut, deposit, failure risk, expected net (pure) | FR-AH-2 |
| HeatMapEngine | Binning, smoothing, queries | FR-HEA-1..4 |
| UI | Dashboard, SessionList, Rankings, MapOverlay, AHProfit, Settings, Minimap | FR-MET-2, FR-MET-5, FR-HEA-1..3 |
| Future/CommunityDataEngine, Future/RouteEngine | Stubs | FR-FUT-1 |

Module rule: modules communicate only through contracts (direct calls to published interfaces) and the typed bus. No reaching into another module's tables.

## 5. Event model

### 5.1 WoW events to Platform normalized events (names to be verified in the Forever client via the probe)

| WoW event / hook (Classic-era names; verify) | Normalized event |
|---|---|
| PLAYER_MONEY | `P_MONEY { copper }` (signed delta computed in Platform.Money) |
| CHAT_MSG_MONEY, LOOT_OPENED, LOOT_SLOT_CLEARED | `P_LOOT_MONEY`, `P_LOOT_ITEM` |
| MERCHANT_SHOW / MERCHANT_CLOSED, item-use hooks | `P_VENDOR_OPEN/CLOSE`, `P_VENDOR_SOLD`, `P_VENDOR_BOUGHT` |
| QUEST_TURNED_IN | `P_QUEST_DONE` |
| MAIL_SHOW / MAIL_CLOSED, MAIL_INBOX_UPDATE, TakeInboxMoney hook | `P_MAIL_OPEN/CLOSE`, `P_MAIL_TAKE` |
| TRADE_SHOW, TRADE_MONEY_CHANGED, TRADE_ACCEPT_UPDATE, TRADE_CLOSED | `P_TRADE_OPEN`, `P_TRADE_DONE` |
| AUCTION_HOUSE_SHOW / CLOSED, system messages for sales | `P_AH_OPEN/CLOSE`, `P_AH_LISTED`, `P_AH_SOLD`, `P_AH_EXPIRED` |
| UNIT_SPELLCAST_SUCCEEDED / channel events (gather, fish) | `P_CAST` |
| COMBAT_LOG_EVENT_UNFILTERED (kills) | `P_KILL` |
| ZONE_CHANGED*, PLAYER_ENTERING_WORLD | `P_ZONE` |
| PLAYER_LEVEL_UP, SKILL_LINES_CHANGED | `P_LEVEL`, `P_PROFS` |
| PLAYER_REGEN_DISABLED / ENABLED | `P_COMBAT` |
| PLAYER_LOGOUT | `P_LOGOUT` |
| 0.5 s ticker | `P_TICK { loc, dt }` |

### 5.2 Internal bus events: see Contracts.md F3.

### 5.3 Handler rule

Handlers only validate, stamp time, and enqueue. The scheduler drains the queue every 0.25 s, so heavy work never runs inside a WoW event callback.

## 6. Money attribution (Reconciler)

Goal: every copper change gets exactly one tag; entries sum to the delta (invariant 1).

1. Source events register **expectations**: `Expectations:Register(src, copper, ttl)` (ttl at least 1.0 s, D-065). Examples: vendor sold (sell price), quest done (reward copper), loot money (parsed amount), mail take (money field), trade done (gold diff), AH listing (deposit as negative), COD payment (negative).
2. On `P_MONEY(delta)`, wait up to **1.0 s** for sibling events (D-065; a window in both directions that ends as soon as a match is found), then `Expectations:Match(delta)` consumes matching expectations (exact copper, same sign) in priority order: trade, mail, vendor, quest, loot, AH.
3. Any unmatched remainder becomes an entry tagged `OTHER` with `conf = 'low'`.
4. Mail-sourced income (AH proceeds, COD received, mailed payments) is tagged `settle = true`.
5. Entry also records the location (mapID, subzone, x, y) and current activity at the time.
6. Diagnostics: `Reconciler:Stats()` returns total entries and the low-confidence share; `/gi diag` prints it.

Edge cases the tests must cover: zero delta; multiple expectations summing to one delta; one expectation split across two deltas; expectation expiry; loot and vendor within the same 1.0 s window (D-065); a delta that waits the full second and becomes `OTHER`; the signal arriving up to 1.0 s before the money (trade, mail, loot lags measured in E-24, E-28, E-31); rapid repeated sales; money change with no expectation (repair costs); mail opened with several items; COD both directions.

## 7. Ledgers, lots, metrics

### 7.1 Cash ledger entry
`CashEntry { id, t, copper (signed), act, src, conf, loc, settle }`.

### 7.2 Asset ledger (Lots)
- `Lots:Add(itemID, qty, origin, valueEach, how)` where `how` is `'free'` (loot, quest, gather, fish) or `'purchase'`.
- Valuation at acquire time from PricingEngine (conservative; floor at vendor sell price; value 0 if unknown and flagged).
- `Lots:Convert(itemID, qty, copper, via)` consumes lots FIFO, producing `Conversion` records. Conversion proceeds are cash ledger entries (vendor sale = cash in); asset side decreases. Neither is "value created".
- Purchased lots are valued at cost and are not value created (conversion cash to asset).
- Items lost to the ground, consumed, or mailed away: a `Conversion` with `via = 'consume'` or `'mail'`; consumed material cost shows as expense.

### 7.3 Metrics (normative formulas: Requirements section 5)

| Metric | Formula |
|---|---|
| Cash GPH | (cashIn - cashOut) / h, settlements excluded |
| Value created | gold received (loot, quest, service trades) + valuation of freely acquired items |
| Wealth GPH | value created / h |
| Net GPH | (value created - expenses) / h |
| Normalized (exp.) | Net GPH / bracket median Net GPH (own history), hidden below minimum hours |
| Settled | settlement cash received (reported separately) |

Explain data: Metrics returns, with each number, the components (cashIn, cashOut, valueCreated list by source, expenses list by source, conversions, h, idle excluded). UI shows it on request (FR-MET-5).

Realized variance: when a lot sells, the difference between sale cash and its acquire valuation is shown as "realized variance" on the explain view (not added to Wealth).

### 7.4 Activities (v1 detection)
`GRIND` (creature loot source G1 plus combat state G3; the XP kill proxy G2 is dropped, D-066; Phase 4 builds the engine, Phase 3b only STAMPS it from the source), `GATHER` (gather cast in last 30 s), `FISH` (fishing channel), `VENDOR`, `QUEST`, `AH`, `TRADE`, `MAIL` (incl. COD), `OTHER`. Reserved keys with no auto-detection in v1: `DISENCHANT, ARBITRAGE, CRAFT, DUNGEON, RARE, BOOST, SERVICE_MAGE, SERVICE_LOCK, SERVICE_ENCHANT`. A manual override (`/gi activity <key>`) always wins and may use reserved keys.

Idle: no money, loot, movement, or combat for N seconds (default 120) pauses the active clock.

### 7.5 Sessions and segments
Segment fields: id, sessionID, t0, active seconds, level, class, profs, mapID, subzone, activity, cashIn, cashOut, valueCreated (by source), expenses (by source), conversions, kills, settled. New segment on: zone, subzone, activity, level, or profession change. Segments below the configured minimum seconds are merged into the previous segment of the same place and activity.

## 8. HeatMapEngine

- Position sampled from `P_TICK` (every 0.5 s) using Platform.Map. In instances or when position is unavailable, no sample is taken.
- Grid: 32 x 32 per zone map. Bin = `{ c = value credited (gold plus valued free items), s = seconds, a = { [act] = copper } }`, stored sparsely keyed by `y * 32 + x`.
- **Credit rule:** only GRIND, GATHER, FISH entries credit `c` (at the kill or gather location). Seconds `s` accrue for all activities, so GPH per bin is honest.
- Heat value = metric / hours for the bin; Gaussian 3x3 smoothing at render time; minimum seconds per bin (default 60) before display.
- Tooltip: value, time in bin, sample size, top activities.
- Filters: activity, metric (Cash, Wealth, Net), date range, level bracket.
- Rendering: fixed pool of 1024 textures, draw non-empty bins only, rebuild on map change or filter change, never per frame.
- Zone-level only in v1 (A-2). World-level is deferred.

## 9. PricingEngine and AHMath

- Provider chain (ordered): `Native` (own scan if the Auction capability exists; manual prices), optional adapters for third-party price addons. First provider returning a price for an item wins; result carries `src`, `age`, `conf`.
- Valuation default: conservative = min(median market, stale-adjusted price), floored at vendor sell price. Unknown items value 0 and are flagged.
- AHMath (pure functions):
  - `cut = price * rate` (rate from game or profile; faction vs neutral may differ; verify in Forever)
  - `ifSold = price - cut - deposit`; `ifFailed = -deposit`
  - `expected = p * ifSold + (1 - p) * ifFailed`
  - `p` (sell-through) comes from own list/sold/expired history for that item; otherwise a user default; always labeled an estimate with confidence (D-010).
- Deposit: read from the game when the AH is open and the API exists; otherwise an estimate flagged as such.
- Recipe-based craft ranking is deferred (A-1, A-5).

## 10. Store and SavedVariables

- `GoldIntelDB` (account) and `GoldIntelCharDB` (per character). Shapes: Contracts.md F5. First released schema = 1 (D-014).
- Raw segments retained 90 days or 2 MB (configurable) then rolled into aggregates (zone, subzone, activity, bracket).
- Migrations: ordered functions keyed by schema number; each is tested with a fixture of the previous schema.
- Durability: working tables live in memory and are written by the client only at logout or reload. `/gi checkpoint` explains this and suggests `/reload`. Optional timed reminder. A crash loses unsaved data (documented).
- Every price snapshot carries `scope` (Forever is realmless; scope may be global or regional), and every record carries `build` so beta data can be excluded or wiped after launch.

## 11. WoW Forever compatibility

### 11.1 Known facts
**Update 2026-10-10 (live validation):** measured facts about the real client are now in `Compatibility_Notes.md` (evidence ledger) and the analysis is in `Phase1_PostValidation_Review.md`. Where they differ from this section, the Compatibility Notes win. Key corrections: Interface tracks the client version; Lua is 5.1; legacy professions/auction/trade-skill APIs are absent; the beta has a named realm; the combat-log event is never registered (D-025).

**Update 2026-10-09 (D-023):** the first in-client test showed the target client uses Interface **16001** and is a modern, 12.0-based client. Where this section lists Classic-era API names first, treat modern names first (C_AuctionHouse, GetProfessions, C_Map) and keep legacy names as fallbacks.

From press coverage, 2026-10-09:
Separate game from Classic and retail; realmless; level cap 60; modernized client; launch 2026-11-04; beta 2026-09-17 to 2026-10-21; Hardcore planned for a later update. No official addon API documentation was found.

### 11.2 Strategy (D-016)
Probe, do not assume. Adapters per capability family, tried in order. Degrade, never crash. Money API and PLAYER_MONEY are fatal-if-missing.

### 11.3 Capability families to probe

| Family | Checks | If missing |
|---|---|---|
| Money | `GetMoney`, PLAYER_MONEY | Addon disables with a message |
| Loot | LOOT_OPENED, CHAT_MSG_MONEY, loot slot info | Chat parsing only |
| Map | `C_Map.GetBestMapForUnit`, `C_Map.GetPlayerMapPosition`, `C_Map.GetMapInfo` | Heatmap off; zone and subzone rankings still work via zone and subzone text |
| Subzone | `GetSubZoneText`, ZONE_CHANGED events | Region-cell fallback |
| Map overlay host | `WorldMapFrame` and its canvas / data providers | Standalone heatmap window |
| Auction legacy | `QueryAuctionItems`, `GetAuctionItemInfo`, `CalculateAuctionDeposit` | Try modern |
| Auction modern | `C_AuctionHouse` namespace | Native provider uses manual prices only |
| Mail | MAIL_INBOX_UPDATE, `GetInboxItem`, `TakeInboxMoney`, COD fields | Settlement limited to money deltas |
| Trade | TRADE_* events, `GetPlayerTradeMoney`, `GetTargetTradeMoney` | Trades logged as OTHER |
| Instances | `IsInInstance`, `GetInstanceInfo` | No instance awareness (not required in v1) |
| Scheduler | `C_Timer.NewTicker`, `C_Timer.After` | OnUpdate frame fallback |
| Identity | `UnitGUID('player')` at login | Name + faction fallback key |
| SavedVariables | Account and per-character declarations in .toc | Account-wide only |

### 11.4 Probe commands to run in the Forever beta client (output needed: OI-1)

```
/dump GetBuildInfo()
/dump select(4, GetBuildInfo())
/dump C_Map ~= nil, C_AuctionHouse ~= nil, QueryAuctionItems ~= nil
/dump C_TradeSkillUI ~= nil, GetTradeSkillInfo ~= nil
/dump UnitGUID('player')
/dump WorldMapFrame ~= nil
/dump C_Timer ~= nil
/dump GetSubZoneText(), GetZoneText()
```

### 11.5 Forever-specific implications
Realmless (no realm in keys; price scope field); new content (nothing hardcoded about zones or items; learn at runtime); Hardcore (GUID is permanent identity; keep data of deleted characters; checkpoint more aggressively if a Hardcore flag is detected); beta data tagged by `build`.

## 12. File tree (as built through Phase 2; Phase 2 additions marked)

```
GoldIntel/
  GoldIntel.toc                       (minimal TOC, forward slashes, Interface 16001, D-024)
  Platform/
    Platform.lua  Clock.lua  Events.lua  Scheduler.lua  Unit.lua  Map.lua  Money.lua
    SavedVars.lua   (Phase 2)  Slash.lua   (Phase 2)  Probe.lua  (last Platform file)
  Core/                               (Phase 2)
    Core.lua  Bus.lua  Capabilities.lua  Config.lua  Slash.lua  Boot.lua   (Boot is the last file)
  Store/                              (Phase 2)
    Migrations.lua  Store.lua  Pruner.lua
  Future/                             (placeholders only, D-015)
    CommunityDataEngine.lua  RouteEngine.lua
  Tests/
    run.lua  helpers/ (testlib, fake_wow, loader, svsim)  fixtures/ (real Phase 1 database)
    test_*.lua (platform, events, scheduler, unit, map, money, probe, integration,
                platform_adapters, bus, core, capabilities, config, migrations, store,
                pruner, commands, libs, phase2_integration)
Not yet built (later phases): Collect/, Ledger/ (Phase 3b, D-069), Engines/, UI/.
```

Load order is the TOC order: Platform first, Probe last among Platform files, then Core, Store, Future, and Boot last (so Core starts only after everything is registered).

## 13. Performance and scheduling

- Handlers enqueue only; no string building or table creation beyond the event record (use a table pool).
- Scheduler tasks: queue drain 0.25 s; aggregation 2 s; checkpoint reminder check 10 s; heat time-in-bin on the 0.5 s tick.
- Budgets (targets to be measured in Phase 9): under 0.5 ms average per frame, under 2 MB memory growth per hour, map overlay rebuild only on change.
- Large loops (rollups, ranking over many segments) run in coroutines sliced per frame.

## 14. Testing strategy

- Pure-Lua 5.1 runner (`Tests/run.lua`); WoW API replaced by recorded **fixtures** of normalized events.
- Per major module: unit tests, edge cases, failure scenarios, performance notes (documented in each test file header).
- Mandatory static test: no WoW globals referenced outside `Platform/`.
- Property-style test: random event streams must keep invariants 1 and 2.
- Migration tests with a fixture per prior schema.
- **Replay corpus (D-073):** real-client lab files in `Tests/fixtures/replay/` are replayed by every phase; a missing file fails the suite.

## 15. UI wireframes (v1)

```
Dashboard
+------------------------------------------------------+
| GoldIntel   [Session v] [Filters v]    [Explain]      |
| ACTIVE: Grind   Tanaris / Gadgetzan Outskirts         |
| Time 01:12:40                                         |
| CASH GPH 71g  (always visible)                        |
| Wealth GPH 84g   Net GPH 62g   Norm 1.3x (exp.)       |
| Settled (mail): 31g                                   |
| Income by source ####  | Expenses by source ###       |
| [Pause] [Stop] [Activity: Auto v] [Map] [Rank] [AH]   |
+------------------------------------------------------+

Rankings: (o) Zones ( ) Subzones   Activity [All v]  Min time [30m v]
  # Place                    Net GPH  Cash GPH  Norm(exp)  Conf
  1 Un'Goro / ...            78g      70g       1.6x       high

Map overlay: heat on zone map; right panel filters (activity, metric);
hover tooltip: value, time in bin, sample size, top activities.

AH Profit: item list with price, deposit, cut, P(sell) [estimate], expected net, confidence, price age.
```

## 16. Placeholders (D-015)

`Future/CommunityDataEngine.lua` and `Future/RouteEngine.lua` expose the function names listed in Contracts.md F8, each returning `{ ok = false, err = 'NOT_IMPLEMENTED' }`. They persist nothing and add no UI. Implementation requires an explicit user instruction and a new decision.

## 17. Risks (also in the latest handoff)

Unconfirmed Forever API; localized subzone keys; SavedVariables flush timing; price data may not exist at launch; normalization lacks empirical baseline; activity auto-detection is heuristic (manual override always wins).

## 18. Phase 2: Core and Store (built; live validation pending)

Decisions D-033 to D-039; contracts F2a, F3a, F10 to F13. Everything here runs without any library and without any collection of game data.

### 18.1 Startup

```
files load (TOC order) ... Core/Boot.lua:
   Commands.Install(minimal)            -- /gi answers immediately, even if PLAYER_LOGIN never arrives
   Platform.OnReady(Core.Start)         -- immediately if loaded after login
PLAYER_LOGIN -> Platform ready listeners in order:  Probe (run + persist compat)  then  Core.Start
Core.Start:  Store.Open + Store.Char -> Config.Load -> Capabilities.Attach -> bridges (DIAG, COMPAT_CHANGED)
             -> P_LOGOUT hook -> full /gi -> modules (initialize all, then enable all) -> CORE_READY
```
Probe persists `compat` BEFORE Core starts, so on a fresh install Store sees a database holding only `compat` and migrates schema 0 to 1 (state `migrated`), exactly as for the real Phase 1 database.

### 18.2 Capability stages (D-034)

```
event.X   valid -> registered -> delivered -> payloadUsable        (each true / false / nil; delivered never false)
          Level: invalid | blocked | payloadUnusable | payloadUsable | delivered | registered | valid | unknown
api       present            Level: present | absent | unknown
```
Platform.Events.Bind verifies registration; a delivery counter records first observation; modules report payload usability (Money for PLAYER_MONEY, Unit for PLAYER_LEVEL_UP). Core imports and follows all of it and writes a throttled snapshot into `GoldIntelDB.runtime`. Only `payloadUsable` allows a design to depend on an event. The 12 events proven live are trusted by the registration check (R-26 fail-safe); all later events are verified strictly (D-029).

### 18.3 Store (D-036)

Opens GoldIntelDB through `Platform.SavedVars`. Outcomes: `created`, `ok`, `migrated`, `readonly` (newer data, left untouched), `degraded` (migration failed, left untouched, in memory). Migrations run on a copy and commit atomically; `compat` must be unchanged and keeps its identity; unknown keys survive; sections are validated and repaired by type; `meta` records opens and the schema history. The schema number is the end of the contiguous migration chain (currently 1). `Pruner` only plans.

### 18.4 Money pipeline vocabulary (D-035), for Phase 3

Four stages that stay separate in data, events and code: (1) balance observation (`P_MONEY`: the delta of the live balance, never parsed from chat), (2) transaction detection (a source event or expectation that explains movement), (3) attribution (activity and source, with its own confidence), (4) reconciliation (the invariant: attributed parts sum to the observed delta; the remainder is OTHER, low confidence). Architecture section 6 describes the Reconciler as a whole; read it through these stages. Reserved Bus events carry them.

### 18.5 What Phase 2 deliberately does not do

No collector, no ledger, no sessions, no activity detection, no pricing, no UI, no new raw event registration (still exactly the 12 Phase 1 events; tests enforce it), no deletion of saved data, no use of the combat log, no library dependency.


## 19. Phase 3b amendments (approved D-069; text only, code arrives with 3b-0..3b-3)

Scope: D-067 (ledgers only). Everything below is design, not yet built.

- **AC-1 Event allow-list.** Platform registers only an allow-list of VERIFIED events (E-17..E-34): `PLAYER_MONEY`, `LOOT_OPENED`, `LOOT_SLOT_CLEARED`, `MERCHANT_SHOW`, `MERCHANT_CLOSED`, `QUEST_TURNED_IN`, `MAIL_INBOX_UPDATE`, `TRADE_SHOW`, `TRADE_CLOSED`, `TRADE_ACCEPT_UPDATE`, `TRADE_MONEY_CHANGED`, `BAG_UPDATE_DELAYED`, `GET_ITEM_INFO_RECEIVED`, `UNIT_SPELLCAST_SUCCEEDED`, `AUCTION_HOUSE_AUCTION_CREATED` (14th, added in 3b-1 per D-074 A-1, verified E-36), plus the Phase 1 events. In 3b-1 the loot window close is the polled state of `LootFrame:IsShown()` (D-075, E-42), not an event. In 3b-1 the collector registers them only after `/gi collect on`, in six groups with a registration journal and per-event quarantine (D-074). `MAIL_CLOSED` (never delivered, E-34) and `MAIL_SHOW` (unverified) are NOT used; mailbox state is polled with `MailFrame:IsShown()`. The Phase 2 test "exactly the 12 Phase 1 events" becomes "exactly this list".
- **AC-2 Platform adapters:** `Loot`, `Merchant`, `Quest`, `Mail`, `Trade`, `Items`, `Bags`. Only `Platform/` touches WoW globals (invariant 5).
- **AC-3 Directories:** `Collect/` (Context, Collector, Expectations, Reconciler) and `Ledger/` (Lots, Valuation). TOC order: Platform, Core, Store, Collect, Ledger, Future, Boot last.
- **AC-4 Match modes (amends section 6 and D-065):** an expectation is `exact` (copper known: loot coin from the coin slot, quest money argument, mail header money) or `window` (copper unknown: vendor sale, trade). Exact expectations match exact copper and sign. Window expectations claim a delta of the right sign (positive for sale and trade-in, negative for purchase, repair, trade-out) that falls inside the open context, or within 1.0 s after it closes. Same 1.0 s window, same priority order (trade, mail, vendor, quest, loot, AH), same `OTHER` remainder.
- **AC-5 AH sale split (D-070):** one money delta becomes up to three components using the invoice read BEFORE the take (E-34): `ahSale` (price, settlement), `ahCut` (expense), `ahDepositRefund` (not income). Components sum to the delta (invariant 1). Without an invoice the whole delta is one `mailMoney` entry, confidence low.
- **AC-6** Section 8 wording applied above ("value credited").
- **AC-7** Section 7.4 GRIND wording applied above (D-066).
- **AC-8 Pending state is not persisted** across `/reload`: open expectations and the open loot context are lost; anything unmatched becomes `OTHER` with a diagnostic; `GoldIntelCharDB.lastMoney` is the baseline so the ledger sum still holds.
- **Disenchant (D-071):** item consumed (`Conversion via = 'consume'`) and materials created as free lots flagged `conversion`; no revaluation; not location-eligible.
- **OTHER reporting (D-072):** `Reconciler:Stats()` returns share of entries AND share of copper value, and the largest single OTHER entry.

- **AC-9 Ledger intervals (D-077).** The Reconciler runs only while collect is ON. The invariant (entries sum to the money deltas) holds per ON interval. `collect on` begins an interval; `collect off` ends it, turning pending deltas into `OTHER` at once and clearing expectations. Money changes while collect is OFF are not recorded.
- **AC-10 Source translators (D-077).** `Collect/Sources.lua` is the only module that maps normalized events to expectations. Expectations, Reconciler and Stamps know nothing about WoW, mail, loot or trade. Adding AH deposit/buy, COD paid and postage later (3b-4) means adding rules to `Sources.lua` only.
- **AC-11 Expectation lifetime follows contexts (D-077).** An exact expectation tied to a context (loot coin) is held until that context closes and then lives its `ttl` (1.0 s); a window expectation is the context itself plus its linger. Other exact expectations live `ttl` (at least 1.0 s). An expired exact expectation is counted `unmatched`, never an entry.
- **AC-12 Entries are immutable and sum-preserving (D-077).** Pruning folds raw entries into per-source totals so cumulative sums stay exact (implemented in M3).
- **AC-13 Gap entries (D-077).** A `P_MONEY` with `gap = true`, and the difference between `lastMoney` and the balance at login (M3), become `OTHER` entries flagged `comp = 'gap'`, counted separately and never attributed.
- **Edge case change (Q-4):** a delta is explained by whole expectations or not at all. One exact expectation is never split across two deltas; both deltas become `OTHER` and the expectation expires `unmatched`.

## Phase 3b-3 amendments (D-080, Q-13)
- **AC-14 Item pipeline mirrors the money pipeline.** Platform events -> ItemSources -> item expectations -> BagDiff confirmation -> Lots. The bag diff is the only thing that creates or consumes a lot; an expectation without a confirming diff creates nothing (R-34).
- **AC-15 Lots never write cash.** Lots has no dependency on Cash/Reconciler/Expectations except reading a finalized cash entry for a conversion's copper (`ref`). The 3b-2 accounting invariant is independent of every 3b-3 failure. Item handlers run under the same guard as Sources.
- **AC-16 Carried inventory** (bags plus equipped gear, Q-5) is the unit the asset ledger accounts for. After every processed settle, open lots per item id equal the carried quantity (I-3, `Lots:Check`). Anything outside (bank etc.) is outside the ledger.
- **AC-17 One valuation per lot.** Valuation happens at acquisition (D-043). A pendingInfo lot receives its FIRST valuation when item data arrives (completion, not revaluation, stored with its own time). Nothing overwrites a valuation (D-063).
- **AC-18 Lot retention** is capped per character (open 1,500, closed ring 300, interim); closed lots fold into closedSummary; equal-valued open lots of one item may merge. Final values from measurement (D-072).
- **AC-19 Separate enable switch** `/gi lots on|off`, independent of `/gi ledger`, OFF after login and `/reload`; while OFF the diff is not computed and the next ON reconciles through the gap rule.
  - Note 2026-11-03 (S-057): the code (0.4.7 to 0.5.1) has `/gi lots` ON by default whenever an interval runs, and from 0.5.0 the interval starts automatically (D-086). The "OFF after login" default above is not what is built; the user decides under OI-14 (Decisions.md).
  - Decided 2026-11-03 (D-088): item recording is ON by default; the "OFF after login" default is superseded. The switch itself stays.
- **Item invariants:** I-2 created once, consumed once; I-3 open quantity equals carried; I-4 a diff is applied at most once; I-5 value created only for loot and quest free lots; I-6 lots never touch the cash ledger.
