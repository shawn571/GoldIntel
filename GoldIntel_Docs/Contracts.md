# GoldIntel Contracts

DOC VERSION: 1.15.0  |  CONTRACT VERSION: 1.15.0  |  DATE: 2026-11-08 (code 0.6.0-passive, branch p4/m2-live)

Contracts.md wins over Architecture.md on data shapes. A breaking change to any contract requires a Decisions.md entry (Project_Bible section 4) and a CONTRACT VERSION bump. Additive optional fields are non-breaking.

Notation: Lua tables. `copper` = integer. `t` = Unix seconds (`time()`); `gt` = fractional seconds (`GetTime()`). `?` = optional. Enumerations are listed in F0.

## Change log (contract versions)

- **1.15.0 (2026-11-08, D-102, build 0.6.0-passive, additive):** the F22 modules are now loaded and in effect; new `GI.AggLive` (Aggregate/Live.lua); `GoldIntelDB.agg[charKey]` and `GoldIntelDB.heat[charKey]` written; `Platform.OnTaxi`, `Platform.Distance` / `Map.WorldSize`, probe capability `map.worldsize`; setting `reminder.reloadMinutes`; commands `/gi agg`, `/gi pause`, `/gi resume`, `/gi afk`, `/gi activity`; the Lots emit carries a phase for kind 'lot'; trace lines `EVT agg`, `EVT clock`, `EVIDENCE mapWorldSize`. See F23.

- **1.14.0 (2026-11-08, D-100, build 0.5.6-passive):** `Perf.Sample(opts)`: memory (`memKB`) only with `opts.memory = true`, otherwise `memSkipped = true`; stored automatic samples carry no `memKB`; `/gi perf` reads memory. Text shows `memKB=skipped`.

- **1.13.0 (2026-11-07, D-098, build 0.5.5-passive):** retention values changed: `Cash.CAP` 6000 (was 2000), `Lots.CAP_OPEN` 4000 (was 1500), lot merge key adds the origin place (zone, subzone, activity), `trace.keep` holds one unexplained line per item id per interval. No shape change.

- **1.12.0 (2026-11-07, D-097, build 0.5.4-passive, additive):** `P.PerfModule` (Platform/Perf.lua), `GoldIntelCharDB.perf.samples`, `Trace.PERF_CAP`, trace lines `EVT perf` and `EVIDENCE profilerFunctions|profilerMetrics`, command `/gi perf`, probe capability `perf.profiler`. See F21.

- **1.11.0 (2026-11-06, D-095, D-096, build 0.5.3-passive, additive):** event `P_LOOT_WON { itemID, qty }`, `Chat.ClassifyLoot` recognises the live won line, ItemSources roll expectation (`rollWon` counter, reason `roll won`), `Reconciler:ClaimPendingSum(n, spec)`, Sources counter `chatSum`, trace lines `ITEM_WON` and `CHATSIG sum`. See F20.

- **1.10.0 (2026-11-05, D-091..D-094, build 0.5.2-passive, additive):** source `trainer`, activity `TRAINER`, events `P_TRAINER_OPEN` / `P_TRAINER_CLOSE`, collector group G9, context kind `trainer`, probe capability `trainer.events`, `Ledger.Check().atLogout`, `ItemSources.SKIN_FIRST` and counter `skinFirst`, trace lines `EVT trainer open|close`, `EVT quest done`, `EVIDENCE trainerRegistered=`. See F19.

- **1.9.0 doc 1.9.1 (2026-11-03, S-057, catch-up, no code change):** the header said 1.8.0 while `P.CONTRACT_VERSION` has been 1.9.0 since 0.4.0. Documented the 0.4.7 and 0.5.0/0.5.1 additions that were built without a contract update (D-031 gap): `/gi lots sales`, setting `collect.auto`, `Collector.AutoStart`/`AUTO_DELAY`, `Ledger.Begin` marks, trace caps and `trace.keep`, `EVT` lines, `Trace.GROUP_POLL`, `Trace.CHECK_EVERY`. All additive; contract version unchanged. See section F18.

- **1.9.0 (2026-10-19, D-080 Q-13, increment 3b-3, additive; M1 modules implemented, nothing wired):** Lot gains `src` (`loot|quest|vendor|mail|trade|disenchant|unknown`), `vc` (boolean, counts as value created: only src loot or quest, free lots, none of the flags transfer/conversion/opening/gap/unattributed/unexplained), `vt` (valuation time), `ref`, `out` (copper received through conversions), and flags `transfer`, `unattributed`, `opening`, `gap`, `unexplained`, `invalid`, `merged` (existing: `unknown`, `bound`, `pendingInfo`, `noVendor`, `conversion`). Conversion gains `itemID`, `ref`, `alloc`. See F17.

- **1.8.0 M3 note (2026-10-18, D-077):** F15 documents schema 2 as built (no version change; the contract was already 1.8.0 from M2).

- **1.8.0 (2026-10-18, D-077 Q-8, increment 3b-2 M2, additive, implemented for M2):** the Phase 3b text now matches the system that exists (F2c as built, below F14). New F14: Expectation as built (`hold`, `comps`, `ref`, `settle`), `Expectations`/`Reconciler`/`Sources`/`Stamps` interfaces, entry shape emitted by the Reconciler, `Reconciler:Stats()` as built, `Platform.LastCast`. No persisted shape changed in M2 (schema 2 and `LEDGER_CASH` arrive in M3).
- **1.7.1 (2026-10-18, D-075, E-42):** `P_LOOT_CLOSE.by` is now `frame | timeout | replaced` (was `clear | timeout | replaced`). Only the 1.7 draft shipped for validation used the old values; no persisted data or consumer exists. `frame` = `LootFrame:IsShown()` turned false; `timeout` = 300 s recovery backstop, or the legacy rule for a window whose frame could not be read; `replaced` = a new `LOOT_OPENED` arrived while a window was open. Slot clears no longer produce a close.
- **1.7 (2026-10-18, D-074, increment 3b-1, additive, implemented):** Platform events `P_LOOT_OPEN {sourceType}`, `P_LOOT_CLOSE {by}` (by = 'clear'|'timeout'|'replaced'), `P_BAGS_SETTLED {}`, `P_ITEM_INFO {itemID, ready}` (approved in A-2) and `P_AH_POSTED {}`, `P_MAIL_UPDATE {count}`, `P_TRADE_CLOSE {}` (additive, flagged in D-074); bus event `CONTEXT_CHANGED {kind, open, id?}` is now emitted by `Collect/Context.lua`; `Platform.RegisterCollectAdapter`, `Platform.Call/CallIn/HasIn/IsAddonLoaded` helpers; `GoldIntelCharDB.collect = {pending, quarantine, lastStats}` (extra key, ignored by older versions; schema stays 1; collect state itself is never persisted). No existing shape changed.
- **1.6 (2026-10-18, D-069, Phase 3b additions, shapes approved, code pending):** additive fields on `CashEntry` and `Lot`, new `Expectation` shape, new `SourceKey` values, bus event `CONTEXT_CHANGED`, `Reconciler:Stats()` extended, SavedVariables schema 2 (migration 1 to 2), Platform adapters for Phase 3b. See the end of this file.

- **1.5 (2026-10-17, D-041):** additive, evidence section only. `GoldIntelDB.runtime` keeps the CURRENT session (as before, plus `sessionStart`, `build`, `endedBy`), `runtime.previous` (the record that was current when this session opened: `sessionStart, generatedAt, generatedGT, addonVersion, build, durationSec, eventStats, output (trimmed to 12000 bytes), outputTotal, capDigest ("name=level;..."), endedBy`), `runtime.history` (at most 10 one-line summaries: `sessionStart, durationSec, build, addonVersion, endedBy, lines, delivered`) and `runtime.pinned` (a compacted copy plus `pinnedAt`, kept until unpinned). New: `Capabilities.Persist(reason)` (reason 'logout' sets `endedBy = 'logout-or-reload'`), `Capabilities.Pin()`, `Unpin()`, `Records()`, constants `HISTORY_ROWS = 10`, `RECORD_MAX_BYTES = 12000`; commands `/gi caps previous|pinned|history`, `/gi checkpoint pin|unpin`, a session-records line in `/gi db`. Read-only or degraded databases get no rotation. These records are diagnostic evidence only: no schema change, no gold data.
- **1.4 (2026-10-15, D-040):** additive. `Platform.Print` records its lines; `Platform.GetOutput(n)`, `Platform.OutputCount()`, `Platform.ClearOutput()`; `Capabilities.Touch()`; `GoldIntelDB.runtime.output` (last 100 printed lines, each `'<unix time> <text>'`) and `runtime.outputTotal`. `/gi caps` text uses yes / NO / not-seen-yet / unknown. `Platform.CONTRACT_VERSION` was stale (1.1) and now equals this version.

- **1.3 (2026-10-10, Phase 2, Decisions D-033 to D-039):** additive. New Platform pieces (F2a): `Platform.SavedVars`, `Platform.RegisterSlash`, event stage tracking (`Events.WatchStage/ReportPayload/Stats/BoundEvents`), `Platform.TRUSTED_EVENTS`, `Platform.Util.deepCopy/deepEqual`; `Events.Bind` verifies registration. New Core contracts (F10 to F14): Core registry and lifecycle, Bus (with the Phase 2 and reserved events), Capabilities stage model, Config, Store/Migrations/Pruner. `GoldIntelDB` gains the `meta` and `runtime` sections (F5a). Replaces the provisional Store and Config lines of F4. Slash command set expanded (F7a). Nothing a Phase 1 consumer relies on changed.

- **1.2 (2026-10-10, documentation catch-up, Decisions D-025 and D-031):** records what shipped in code 0.1.2 without a contract update (a process violation, corrected). Additive: `Platform.EventNameValid(name) -> true|false|nil`; `Platform.IsSecret(value) -> boolean`; `Platform.RESTRICTED_EVENTS` (table, initially `COMBAT_LOG_EVENT_UNFILTERED`); `Platform.Probe()` is three-state (a capability that cannot be checked safely is ABSENT from the returned table, `Has` is false, and `ProbeModule.last.status[cap]` is `'ok'|'missing'|'unknown'`); `Platform.Events.lastRegisterAttempt`; the shape of `GoldIntelDB.compat` (F5). No consumer breaks.

- **1.1 (2026-10-09, Phase 1, Decisions D-022 item 7):** additive only. `Platform.Off/OnReady/Diag`; `Platform.After` returns a cancel function; `Platform.Player()` gains `key`/`keyKind` and may return `nil, err`; `Loc.mapID` optional plus new optional `Loc.zone`; `P_MONEY.gap`; `P_TICK.loc` optional. No existing consumer breaks.
- 1.0 (2026-10-09): initial.

## F0. Enumerations

```lua
ActivityKey = 'GRIND' | 'GATHER' | 'FISH' | 'LOOT' | 'VENDOR' | 'QUEST' | 'AH' | 'TRADE' | 'MAIL' | 'TRAINER' | 'OTHER'
  -- TRAINER (1.10.0, D-093): class and profession training fees; never a LocationAct.
  -- LOOT (0.3.7, user 2026-10-18): coin known to be loot (coin chat share) whose corpse or object is unknown; actConf med;
  -- not a LocationAct, so never credited to a heat bin; the entry still carries the stamped location and its locConf.
  -- RESERVED (no auto-detection in v1; manual override may set them):
  -- 'DISENCHANT' | 'ARBITRAGE' | 'CRAFT' | 'DUNGEON' | 'RARE' | 'BOOST'
  -- | 'SERVICE_MAGE' | 'SERVICE_LOCK' | 'SERVICE_ENCHANT'
SourceKey   = 'loot' | 'vendor' | 'quest' | 'ahSale' | 'ahDeposit' | 'ahPurchase' | 'trade'
            | 'codIn' | 'codOut' | 'mailMoney' | 'repair' | 'purchase' | 'trainer' | 'unknown'   -- trainer: 1.10.0 (D-093)
Confidence  = 'high' | 'med' | 'low'
LocationActs = { GRIND, GATHER, FISH }   -- the only activities credited to heat bins
```

## F1. Shared records

```lua
Loc = { mapID = number?, zone = string?, sub = string?, locale = string?, x = number?, y = number? }   -- x,y in 0..1
  -- mapID is nil when the client has no C_Map; zone/sub text then identify the place (v1.1).
  -- A Loc always has mapID or zone. x,y are nil when no position is available (e.g. inside instances).

CashEntry = {                 -- schema_rec = 1
  id = number, t = number, copper = number,   -- signed
  act = ActivityKey, src = SourceKey, conf = Confidence,
  loc = Loc, settle = boolean,                -- settle: delayed mail income
}

Lot = {                       -- schema_rec = 1
  id = number, itemID = number, qty = number, qtyLeft = number, t = number,
  valueEach = number, valueSrc = 'market' | 'vendor' | 'manual' | 'unknown',
  how = 'free' | 'purchase',  -- free = loot/quest/gather/fish
  origin = { act = ActivityKey, loc = Loc },
}

Conversion = {                -- asset <-> cash, never value created
  t = number, lotID = number, qty = number, copper = number,
  via = 'vendor' | 'ah' | 'trade' | 'mail' | 'consume' | 'purchase',
}

Segment = {                   -- schema_rec = 1
  id = number, sessionID = number, t0 = number, dur = number,   -- dur = active seconds
  level = number, class = string, profs = { [string] = number },
  loc = Loc, act = ActivityKey,
  cashIn = number, cashOut = number,
  valueCreated = { [SourceKey] = number },   -- sum across keys = value created
  expenses = { [SourceKey] = number },
  conversions = number, settled = number, kills = number,
}

Session = { id = number, charKey = string, t0 = number, t1 = number?, build = string,
            segments = { number }, totals = table }

Price = { value = number, src = string, age = number, conf = Confidence, scope = string }
```

## F2. Platform contract (only layer touching WoW globals)

```lua
Platform.Has(cap) -> boolean
Platform.Probe() -> { [cap] = boolean }               -- also stored in GoldIntelDB.compat; unknown capabilities are ABSENT (v1.2)
Platform.EventNameValid(name) -> true | false | nil    -- C_EventUtils.IsEventValid; nil = cannot tell; never registers (v1.2)
Platform.IsSecret(value) -> boolean                    -- 12.0 secret value check; false if the API is missing (v1.2)
Platform.RESTRICTED_EVENTS -> { [eventName] = true }   -- never registered; Events.Bind refuses them (v1.2)
Platform.On(eventName, handler(payload)) -> handler | nil, err   -- eventName from the table below
Platform.Off(eventName, handler) -> boolean                       -- (v1.1)
Platform.OnReady(fn)                                             -- runs after PLAYER_LOGIN (v1.1)
Platform.Diag(level, module, msg)                                -- level: debug|info|warn|error (v1.1)
Platform.Now() -> t, gt
Platform.Every(seconds, fn) -> cancelFn
Platform.After(seconds, fn) -> cancelFn | nil, err   -- Every also returns cancelFn (v1.1: After returns it too)
Platform.Player() -> { guid, key, keyKind, name, class, level, faction, profs = { [name] = rank } } | nil, err
  -- key = guid when available, else 'name:<Name>:<Faction>'; keyKind = 'guid' | 'name' (v1.1)
  -- class is the non-localized class token, e.g. 'MAGE'
Platform.Where() -> Loc | nil
Platform.Money() -> copper
Platform.Auction.Available() -> 'legacy' | 'modern' | nil
Platform.Auction.Scan(opts, cb)      -- cb(items) or cb(nil, errString)
Platform.Auction.Deposit(itemRef, duration) -> copper | nil
```

Normalized Platform events (payload is always a table):

| Event | Payload |
|---|---|
| `P_MONEY` | `{ copper, gt, gap? }` (signed delta; `gap = true` when money changed without a PLAYER_MONEY event, v1.1) |
| `P_LOOT_MONEY` | `{ copper, source }` |
| `P_LOOT_ITEM` | `{ itemID, qty, source }` |
| `P_VENDOR_OPEN` / `P_VENDOR_CLOSE` | `{}` |
| `P_VENDOR_SOLD` | `{ itemID, qty, copper }` |
| `P_VENDOR_BOUGHT` | `{ itemID, qty, copper }` |
| `P_QUEST_DONE` | `{ questID, copper, items }` |
| `P_MAIL_OPEN` / `P_MAIL_CLOSE` | `{}` |
| `P_MAIL_TAKE` | `{ kind = 'ah'|'cod'|'money'|'other', sender, subject, copper, cod, items }` |
| `P_TRADE_OPEN` | `{ partner }` |
| `P_TRADE_DONE` | `{ gave, got, partner }` (copper) |
| `P_AH_OPEN` / `P_AH_CLOSE` | `{}` |
| `P_AH_LISTED` | `{ itemID, qty, price, deposit, duration }` |
| `P_AH_SOLD` / `P_AH_EXPIRED` | `{ itemID, qty, price? }` |
| `P_CAST` | `{ spellID, kind = 'gather'|'fish'|'other', target }` |
| `P_KILL` | `{ guid, classification }` |
| `P_ZONE` | `{ loc }` |
| `P_LEVEL` | `{ level }` |
| `P_PROFS` | `{ profs }` |
| `P_COMBAT` | `{ inCombat }` |
| `P_TICK` | `{ loc?, dt }` (`loc` is nil when no location data exists; dt = real seconds since the previous tick, clamped to 0..5; v1.1) |
| `P_LOGOUT` | `{}` |

## F3. Core bus events (internal)

| Event | Producer | Payload |
|---|---|---|
| `LEDGER_CASH` | Reconciler | `CashEntry` |
| `LEDGER_LOT` | Lots | `Lot` or `Conversion` |
| `ACTIVITY_CHANGED` | ActivityEngine | `{ from, to, reason, manual }` |
| `SEGMENT_OPENED` / `SEGMENT_CLOSED` | SessionEngine | `Segment` |
| `SESSION_STARTED` / `SESSION_STOPPED` | SessionEngine | `Session` |
| `PRICES_UPDATED` | PricingEngine | `{ count, scope, t }` |
| `HEAT_UPDATED` | HeatMapEngine | `{ mapID }` |
| `COMPAT_CHANGED` | Platform | `{ cap, available }` |
| `DIAG` | any | `{ module, level, msg }` |

## F4. Module interfaces

```lua
-- Core
Core.Register(name, module) / Core.Get(name)
Bus:Fire(event, payload) / Bus:On(event, fn) / Bus:Off(event, fn)

-- Collector
Collector:Enable() / Collector:Disable()

-- Expectations
Expectations:Register(src, copper, ttlSeconds) -> id
Expectations:Match(delta) -> { { src = SourceKey, copper = number } , ... }, remainder

-- Reconciler
Reconciler:OnMoney(deltaCopper)               -- emits LEDGER_CASH entries; invariant 1
Reconciler:Stats() -> { total = number, lowConfShare = number }

-- Lots
Lots:Add(itemID, qty, origin, valueEach, how) -> Lot
Lots:Convert(itemID, qty, copper, via) -> { Conversion }   -- FIFO
Lots:InventoryValue() -> copper

-- ActivityEngine
ActivityEngine:Current() -> ActivityKey
ActivityEngine:Set(act, manual)
ActivityEngine:IsIdle() -> boolean

-- SessionEngine
SessionEngine:Start(opts) / :Pause() / :Resume() / :Stop()
SessionEngine:Active() -> Session | nil
SessionEngine:Segment() -> Segment | nil
SessionEngine:Rotate(reason)

-- Metrics (pure)
Metrics.Cash(agg) -> gph            -- (cashIn - cashOut) / h
Metrics.Wealth(agg) -> gph          -- valueCreated / h
Metrics.Net(agg) -> gph             -- (valueCreated - expenses) / h
Metrics.Normalized(netGPH, bracket, baselines) -> ratio | nil
Metrics.Aggregate(segments) -> agg  -- sums of numerators and seconds (never averages rates)
Metrics.Explain(agg) -> { components... }

-- Rankings (pure over aggregates)
Rankings.Zones(filter) / Rankings.Subzones(filter) -> { Row }
Row = { key, name, sec, net, cash, wealth, norm = number?, conf = Confidence }
Filter = { act?, class?, bracket?, dateFrom?, dateTo?, minSec? }

-- PricingEngine
PricingEngine:Price(itemID) -> Price | nil
PricingEngine:Value(itemID, qty) -> copper, Price | nil
PricingEngine:RegisterProvider(name, provider)
PricingEngine:ImportManual(itemID, copper)
-- provider = { Has() -> boolean, Get(itemID) -> { min, med, qty, t } | nil }

-- AHMath (pure)
AHMath.Cut(price, rate) -> copper
AHMath.Expected(price, deposit, rate, p) -> { ifSold, ifFailed, expected }
AHMath.SellThrough(history, defaultP) -> p, conf

-- HeatMapEngine
HeatMapEngine:Add(entry)                      -- ignores non-LocationActs
HeatMapEngine:Tick(loc, dt, act)              -- seconds in bin for all activities
HeatMapEngine:Query(mapID, filter) -> { Cell }   -- Cell = { x, y, value, sec, acts }
HeatMapEngine:At(mapID, nx, ny, filter) -> Cell | nil

-- Store
Store:Get() / Store:Char() / Store:Migrate() / Store:Checkpoint() -> bytes
Pruner:Run(policy)
```

Error convention: functions return `nil, errString` on failure; they never throw across module boundaries. Errors are also reported with `DIAG`.

## F5. SavedVariables schema (first released schema = 1, D-014)

```lua
GoldIntelDB = {
  schema = 1,
  compat = {                         -- written by Platform/Probe.lua at PLAYER_LOGIN (v1.2: full shape)
    build = string, gameVersion = string, interface = number, locale = string, projectID = number,
    addonVersion = string, probedAt = number, operational = boolean,
    caps = { [string] = boolean },   -- only capabilities that were checked; unknown ones are absent
    status = { [string] = 'ok' | 'missing' | 'unknown' },
    report = { string },             -- the pasteable /gi probe lines
  },
  profile = {
    idleSec = 120, minSegSec = 600, heatGrid = 32, minBinSec = 60,
    valuation = 'conservative', defaultSellThrough = 0.6,
    prune = { days = 90, maxBytes = 2000000 },
    normalization = { minHours = 5, bracketSize = 5 },
  },
  chars = { [guid] = { name, class, faction, level, profs, lastSeen, hardcore = boolean? } },
  sessions = { [id] = Session },
  segments = { [id] = Segment },
  lots = { open = { Lot }, closedSummary = { [itemID] = { qty, copperIn } } },
  agg = { zone = {}, sub = {}, act = {}, bracket = {} },   -- Metrics.Aggregate outputs
  heat = { [mapID] = { grid = 32, bins = { [idx] = { c = number, s = number, a = {} } } } },
  prices = { scope = string, snapshots = { [itemID] = { min, med, qty, t } } },
  auctions = { [itemID] = { listed = n, sold = n, expired = n } },
}

GoldIntelCharDB = { activeSessionID = number?, lastMoney = number, pending = {} }
```

All persisted records also carry `build`. Subzone keys are `mapID .. ':' .. locale .. ':' .. subText`.

## F6. Settings keys (profile)

`idleSec`, `minSegSec`, `heatGrid` (fixed 32 in v1), `minBinSec`, `valuation`, `defaultSellThrough`, `prune.*`, `normalization.*`, `ui.*`. Adding a key requires a default in `Core/Config.lua`.

## F7. Slash commands (v1)

`/gi` (toggle dashboard), `/gi start|pause|resume|stop`, `/gi activity <key>`, `/gi probe`, `/gi diag`, `/gi checkpoint`, `/gi price <itemID> <copper>`.

## F8. Placeholder stubs (D-015; NOT implemented)

```lua
-- Future/CommunityDataEngine.lua
CommunityDataEngine:Import(payload)     -> { ok = false, err = 'NOT_IMPLEMENTED' }
CommunityDataEngine:Export(opts)        -> { ok = false, err = 'NOT_IMPLEMENTED' }
CommunityDataEngine:Merge(a, b)         -> { ok = false, err = 'NOT_IMPLEMENTED' }
CommunityDataEngine:GuildSync(opts)     -> { ok = false, err = 'NOT_IMPLEMENTED' }
CommunityDataEngine:ChannelSync(opts)   -> { ok = false, err = 'NOT_IMPLEMENTED' }

-- Future/RouteEngine.lua
RouteEngine:Record(opts)    -> { ok = false, err = 'NOT_IMPLEMENTED' }
RouteEngine:Analyze(route)  -> { ok = false, err = 'NOT_IMPLEMENTED' }
RouteEngine:Discover(opts)  -> { ok = false, err = 'NOT_IMPLEMENTED' }
RouteEngine:Rank(routes)    -> { ok = false, err = 'NOT_IMPLEMENTED' }
```

These stubs register with Core, persist nothing, and have no UI.

## F9. Contract tests (required before any module is marked done)

1. Every function in F4 exists with the documented arity (interface conformance test).
2. Every bus and Platform event payload validates against its shape in debug mode.
3. Persisted records round-trip through Store without loss.
4. Invariants in Architecture section 3 hold on fixtures.

---

# Phase 2 additions (contract 1.3)

Where these differ from F3, F4, F5, F6 or F7 above, these win.

## F2a. New Platform contracts

```lua
-- SavedVariables adapter (the only access to the saved variables globals)
Platform.SavedVars.Account()   -> table, status    -- GoldIntelDB;     status 'existing' | 'created' | 'replaced'
Platform.SavedVars.Character() -> table, status    -- GoldIntelCharDB; same statuses
-- Usable from PLAYER_LOGIN on (the client restores the tables after the files run, before ADDON_LOADED).

-- Slash registration (the only one)
Platform.RegisterSlash(key, command, handler) -> true | nil, err
-- key: uppercase identifier; command: '/gi'; handler(message) runs under pcall; same key replaces the handler.

-- Event stages (raw WoW events; consumed by Core/Capabilities)
Platform.Events.Bind(wowEvent, fn) -> true | false, reason
--   refuses events in Platform.RESTRICTED_EVENTS and names IsEventValid rejects, without calling RegisterEvent;
--   after RegisterEvent verifies with IsEventRegistered: false => returns false ('registration not in effect'),
--   except for Platform.TRUSTED_EVENTS (proven live), where a disagreeing check only logs a warning.
Platform.Events.WatchStage(fn(wowEvent, stage, value, note))   -- stage: 'registered' | 'delivered' | 'payloadUsable'
Platform.Events.ReportPayload(wowEvent, usable, note) -> changed boolean
Platform.Events.Stats(wowEvent) -> { registered = true|false|nil, delivered = count, firstGT, lastGT, payloadUsable = true|false|nil }
Platform.Events.BoundEvents() -> sorted names
Platform.TRUSTED_EVENTS -> { [eventName] = true }   -- exactly the 12 Phase 1 events

Platform.Util.deepCopy(value) / deepEqual(a, b)     -- plain data, cycle-safe
```

## F3a. Bus events declared in Phase 2 (payload shapes enforced when Bus.validate is on)

| Event | Payload | Fired by |
|---|---|---|
| `DIAG` | `{ level, module, msg, t }` | Core bridge of Platform.Diag |
| `COMPAT_CHANGED` | `{ cap, available, previous? }` | Core bridge of Platform.WatchCaps |
| `CAPABILITY_STAGE_CHANGED` | `{ cap, stage, value?, previous?, note?, level }` | Capabilities |
| `CORE_READY` | `{ modules }` | Core.Start |
| `CORE_STOPPING` | `{ reason }` | Core.Stop |
| `MODULE_STATE` | `{ name, state, reason? }` | Core |
| `STORE_OPENED` | `{ state, schema, writable }` | Store.Open |
| `STORE_MIGRATED` | `{ from, to }` | Store.Open |
| `STORE_DEGRADED` | `{ reason }` | Store.Open |
| `CONFIG_CHANGED` | `{ key, value?, previous?, source }` | Config |

**Reserved (declared, provisional shape, NEVER fired in Phase 2):** `BALANCE_OBSERVED`, `TRANSACTION_DETECTED`, `ATTRIBUTION_ASSIGNED`, `RECONCILIATION_COMPLETE` (the four money pipeline stages, D-035), `LEDGER_CASH`, `LEDGER_LOT`, `ACTIVITY_CHANGED`, `SEGMENT_OPENED`, `SEGMENT_CLOSED`, `SESSION_STARTED`, `SESSION_STOPPED`, `PRICES_UPDATED`, `HEAT_UPDATED`. Firing an undeclared event is an error.

```lua
Bus.On(event, fn) -> fn | nil, err      Bus.Off(event, fn) -> boolean       Bus.Fire(event, payload) -> handlersInvoked
Bus.Define(event, spec, opts) -> true | nil, err      -- spec: { field = 'number'|'string'|'boolean'|'table'|'any' [+ '?'] }
Bus.Info(event) -> { reserved, spec } | nil           Bus.Names() -> sorted        Bus.HandlerCount(event)
Bus.validate = false | true (report) | 'strict' (drop invalid)
```

## F10. Core

```lua
Core.Module(name, def) -> def | nil, err
-- def: { deps = {names}, OnInitialize(def), OnEnable(def), OnDisable(def), OnLogout(def), stub = bool }
-- states: registered | initialized | enabled | failed | disabled ; dependency order; failures isolated
Core.Service(name, impl) -> impl | nil, err          Core.GetService(name)     Core.GetModule(name)
Core.ModuleState(name) -> state, reason              Core.Modules() -> { {name, state, reason, stub} }
Core.Start() -> true | false, reason                 Core.Stop(reason) -> true | false, reason   -- 'logout' => OnLogout
Core.Describe() -> { state, total, enabled, failed, disabled, stub }
Core.state: loaded | starting | ready | stopped | platform-failed
-- Registered services: bus, capabilities, config, migrations, store, pruner, commands.
-- Modules must register while the files load; later registration is reported and the module is not started.
```

## F11. Capabilities (stage model, D-034)

```lua
-- event capabilities: name 'event.<WOW_EVENT>', stages valid | registered | delivered | payloadUsable (true/false/nil)
-- api capabilities:   every other name, one stage: present (true/false/nil)
-- 'delivered' is only ever true or nil.
Capabilities.Set(name, stage, value, note) -> changed | nil, err
Capabilities.Stage(name, stage)            Capabilities.Get(name) -> { kind, level, stages, notes } | nil
Capabilities.Level(name) ->
--   events: invalid | blocked | payloadUnusable | payloadUsable | delivered | registered | valid | unknown
--   api:    present | absent | unknown
Capabilities.Usable(name) -> boolean       -- true only for payloadUsable (events) or present (api)
Capabilities.Names(kind?) / Summary() -> { event = {level = n}, api = {level = n} }
Capabilities.Import() / Attach() / Snapshot() / Persist()
-- Persist writes runtime.capabilities, runtime.eventStats, runtime.generatedAt (throttled, PERSIST_DELAY = 5 s)
```

## F12. Config

```lua
Config.Define(key, spec) -> true | nil, err
-- spec: { type = 'number'|'boolean'|'string'|'enum', default, minValue, maxValue, integer, values, maxLength, readonly, help }
-- dotted keys map to nested tables in GoldIntelDB.profile (prune.days -> profile.prune.days); a key may not be the parent or child of another
Config.Get(key) -> value | nil, err         Config.Set(key, value, source) -> true, persisted | nil, err
Config.Reset(key, source) / ResetAll(source) -> count      Config.Parse(key, text) -> typed | nil, err
Config.Load() -> { invalid = { key = reason } }            Config.List() -> sorted descriptions
-- Shipped settings: idleSec 120 [10..3600], minSegSec 600 [30..7200], minBinSec 60 [1..3600], heatGrid 32 (read-only),
--   valuation 'conservative', defaultSellThrough 0.6 [0..1], prune.days 90, prune.maxBytes 2000000,
--   normalization.minHours 5, normalization.bracketSize 5
--   collect.auto true (0.5.0, D-086; see F18)
-- Invalid saved values are ignored (default applies); unknown saved keys are preserved; every change fires CONFIG_CHANGED.
```

## F13. Store, Migrations, Pruner

```lua
Store.Open() -> status          -- idempotent. status = { state, schema, target, writable, repaired, added, migrated, reason, svStatus }
-- state: created | ok | migrated | readonly (saved data NEWER than the addon: private copy, nothing written back)
--        | degraded (migration/validation failed: saved data untouched, runs in memory)
Store.Get() / Store.Section(name) / Store.Char() / Store.Status() / Store.IsOpen() / Store.IsWritable()
Store.Checkpoint() -> { bytes, truncated, writable, note }      Store.EstimateBytes(value, nodeLimit?) -> bytes, truncated
-- THE compat GUARANTEE: Store never creates, replaces or removes GoldIntelDB.compat; migrations run on a copy whose compat must
-- deep-equal the original; the live compat table keeps its identity; unknown keys survive.

Migrations.Register(from, fn, name)     -- fn(db) upgrades schema `from` to from+1; pure; must not touch db.compat
Migrations.Latest() -> schema written by this addon (end of the contiguous chain from 0; currently 1)
Migrations.Plan(from, to) / Run(db, from, to) -> { ok, applied, failedAt?, err? }
Migrations.Sections() / Check(db) / EnsureShape(db) / DefineSection(name, factory, nested)
-- Schema 0 = a database with no schema field (Phase 1: only `compat`).

Pruner.Plan(db, policy, now) -> { cutoff, sessions, segments, bytes, maxBytes, overBudget, truncated }
Pruner.Run(policy) -> { ok, dryRun = true, removed = 0, planned, overBudget, note }   -- Phase 2 NEVER deletes
```

## F5a. SavedVariables additions

```lua
GoldIntelDB = {
  schema = 1,
  compat = { ... },                  -- owned by Platform/Probe; Store never touches it (F5)
  meta = { firstSeen, lastOpened, opens, addonVersion, lastBuild, lastCheckpoint,
           schemaHistory = { { from, to, t, addonVersion } } },       -- history capped at 20
  profile = {}, chars = {}, sessions = {}, segments = {},
  lots = { open = {}, closedSummary = {} }, agg = { zone = {}, sub = {}, act = {}, bracket = {} },
  heat = {}, prices = { snapshots = {} }, auctions = {},
  runtime = { capabilities = {...}, eventStats = {...}, generatedAt, generatedGT, addonVersion,
              output = { '<unix time> <line>', ... }, outputTotal,   -- volatile evidence, replaced each time (v1.4: output)
              sessionStart, build, endedBy,                          -- v1.5
              previous = {...}, history = { {...}, ... }, pinned = {...} },   -- v1.5, D-041: bounded diagnostic records
}
GoldIntelCharDB = { schema = 1, pending = {}, activeSessionID?, lastMoney? }
-- Everything must stay plain serializable data (no functions, no cycles); a test round-trips it through a serializer.
```

## F7a. `/gi` commands (Phase 2)

`/gi` (summary), `help`, `status`, `version`, `probe`, `diag`, `debug [on|off|ticks]`, `caps [events|api|all|text]`, `config [list|get K|set K V|reset K|all]`, `db`, `modules`, `checkpoint`. `/gi` is registered in minimal mode as soon as the files load; the full set is installed by Core.Start. When the platform is not operational only `help`, `status`, `version`, `probe`, `diag`, `debug` exist. Modules add commands with `Commands.Register(name, { help, usage, fn(args, rest) })`.


---

# Phase 3b additions (contract 1.6; approved D-069, not yet implemented)

Where these differ from F1, F3, F4, F5 or F5a above, these win.

## F1b. Record additions

```lua
SourceKey adds: 'ahCut' | 'ahDepositRefund' | 'ahSale'(exists) | 'buyback' | 'other'
  -- 'repair' and 'purchase' already exist; 'unknown' is retained for old data and mapped to 'other' by the migration.

CashEntry adds (all optional, non-breaking):
  locConf = 'fresh' | 'stale' | 'none',     -- position stamp quality; stale or none earns no credit
  actConf = Confidence,                      -- confidence of the source-derived activity tag
  ctx = string?,                             -- context key (e.g. 'loot:<GUID>:<gt>', 'merchant:<n>', 'mail:<fingerprint>')
  ref = string?,                             -- evidence or fingerprint reference
  comp = string?,                            -- component name when one delta is split ('price'|'cut'|'depositRefund')
  creditable = boolean,                      -- location-eligible (D-044, D-064); never true for quest, mail, trade, vendor
  charKey = string,                          -- Platform.Player().key

Lot adds: flags = { unknown?, bound?, pendingInfo?, noVendor?, conversion? }, locConf, ctx

Expectation = { id, src = SourceKey, mode = 'exact' | 'window', copper = number?, sign = 1 | -1,
                t0 = gt, ttl = number (>= 1.0), ctx = string? }
  -- exact: copper required. window: copper nil; matches a delta of `sign` inside the context or <= 1.0 s after it closes.
```

## F3b. Bus additions

`CONTEXT_CHANGED { kind = 'loot'|'merchant'|'quest'|'mail'|'trade', open = boolean, ctx = string }` (producer: Context). `LEDGER_CASH` and `LEDGER_LOT` payloads are the extended records above.

## F4b. Interface additions

```lua
Context:Open(kind, ctx) / Context:Close(kind)        -- idempotent; Close within 1.0 s keeps the context claimable
Context:Active(kind) -> ctx | nil
Expectations:Register(src, copper|nil, ttl, opts)   -- opts = { mode, sign, ctx }
Reconciler:Stats() -> { total, lowConfShare, otherShareValue, otherShareEntries, largestOther }   -- D-072; value is the headline figure
Collector:Enable() / Collector:Disable()             -- /gi collect on|off
Lots:Add(itemID, qty, origin, valueEach, how, flags) -> Lot
```

## F2c. Phase 3b Platform adapters (all normalized, payloads plain tables)

`P_LOOT_OPEN { ctx, source = {guid, kind = 'Creature'|'GameObject'|'Item'|'other'}, slots = { {type, itemID?, qty, copper?} } }`, `P_LOOT_SLOT_CLEARED { ctx, slot }` (de-duplicated), `P_VENDOR_OPEN/CLOSE` (close idempotent), `P_QUEST_DONE { questID, xp, copper }`, `P_MAIL_UPDATE { headers }` (headers read only while the mailbox is shown), `P_TRADE_OPEN/CLOSE`, `P_BAG_DIFF { added, removed, changed, moneyDelta? }` (after the last `BAG_UPDATE_DELAYED` of a burst), `P_ITEM_INFO { itemID, success }`, `P_CAST { spellID, kind }` (player only; secret values never read).

## F5b. SavedVariables schema 2

```lua
GoldIntelDB = {
  schema = 2,
  ledger = { [charKey] = { nextId = number, cash = { CashEntry... } } },   -- compact records; retention set from measured size (D-072)
  lots = { [charKey] = { open = { Lot... }, closedSummary = { [itemID] = { qty, copperIn } } } },
  -- all other keys as schema 1
}
GoldIntelCharDB = { schema = 2, lastMoney = number, ... }
```
Migration 1 to 2 runs on a copy (existing Store rules), creates the new tables empty, keeps `compat`, maps `unknown` sources, and is tested on the real Phase 1 fixture.

## F9b. Contract tests added

Allow-list test (registered events equal the list in Architecture 19 AC-1); Expectation shape validation (exact requires copper, window requires sign); `Reconciler:Stats()` returns both OTHER metrics; schema 2 round trip; every Phase 3b Platform event payload validates in debug mode.


## F14. Phase 3b-2 contracts (1.8.0)

### F14.1 Platform events as built in 3b-1 (replaces the F2c draft text for these events)

```lua
P_LOOT_OPEN   { sourceType = 'creature'|'object'|'item'|'unknown' }      -- once per window
P_LOOT_MONEY  { copper, source = sourceType }                              -- one per coin slot, read at open (E-18)
P_LOOT_ITEM   { itemID, qty, source = sourceType }                         -- one per item slot
P_LOOT_CLOSE  { by = 'frame'|'timeout'|'replaced' }                        -- D-075
P_QUEST_DONE  { questID, copper }                                          -- xp is not carried
P_VENDOR_OPEN/CLOSE {}   P_TRADE_OPEN/CLOSE {}   P_MAIL_OPEN/CLOSE {}   P_AH_OPEN/CLOSE {}   P_AH_POSTED {}
P_MAIL_UPDATE { count }   -- the inbox itself is read through Platform.MailModule.Snapshot()/Previous():
                          -- { count, mails = { { index, sender, subject, money, cod, daysLeft, itemCount, textCreated,
                          --   canReply, firstQty, firstItemID?, kind = 'auction'|'player', fingerprint,
                          --   invoice? = { kind, item, player, price, deposit, cut } } }, gt }
P_MONEY       { copper (signed, non-zero), gt, gap? }
```
Not built (3b-3 / 3b-4): `P_BAG_DIFF`, bag logic driven by `P_CAST`. `P_CAST { spellID, kind }` exists (kinds herb|mine|skin|fish|other).

### F14.2 Platform addition

`Platform.LastCast(kind) -> gt, spellID | nil` (kind = 'herb'|'mine'|'skin'|'fish'|'other'): game time and spell id of the player's most recent cast of that kind. Read-only; secret spell ids are never stored.

### F14.3 Expectation (as built)

```lua
Expectations.New() -> store
store:Add{ src, mode = 'exact'|'window', sign = 1|-1, t0 = gt, ttl >= 1.0, ctx?, ref?, settle?,
           copper? = positive integer MAGNITUDE (exact only),
           comps? = { { src, copper = SIGNED nonzero integer, comp?, settle? }, ... },   -- must sum to sign*copper
           hold? = boolean }                                   -- exact only: no expiry until Close(id, gt)
  -> id | nil, reason ('spec'|'mode'|'sign'|'t0'|'ttl'|'src'|'copper'|'comp'|'comps'|'window has no amount')
store:Close(id, gt)   -- window or held exact: context ended; active until max(gt + ttl, t0 + ttl) (inclusive)
store:Extend(id, gt) / Consume(id) (exact only) / Active(gt, sign?, mode?) / Expire(gt) / Clear() / Subscribe(fn) / Stats()
Expectations.PrioOf(src)   -- trade 1; mail kinds 2; vendor/purchase/repair/buyback 3; quest 4; loot 5; ahDeposit/ahPurchase 6; other 9
store:Stats() -> { added, consumed, unmatched, windowsClosed, active }
```
Boundary: an expectation is active while `gt <= expireGT` (inclusive). `unmatched` counts exact expectations that expired or were cleared unused (a diagnostic; no entry, no money moved).

### F14.4 Reconciler (as built)

```lua
Reconciler.New{ exp = store, sink = function(entry), decorate = function(entry)? } -> R
R:Begin(gt) / R:Money(copper, gt, gap?) / R:Tick(gt) / R:End(gt) / R:Check() -> ok, sumDeltas, sumEntries, pendingSum
R:Stats() -> { total, totalValue, lowConfShare, otherShareValue, otherShareEntries, largestOther, gapCount, gapValue,
               unmatched, pending, ignored, sumDeltas, sumEntries, bySource = { [src] = { n, copper } } }
Reconciler.WAIT = 1.0   Reconciler.MAX_CANDIDATES = 8   Reconciler.MAX_COMBO = 3
```
Entry emitted to `sink` (before the Cash store adds `id` and `charKey`, M3):
`{ t = gt of the money delta, copper (signed, non-zero), src, conf, comp?, ctx?, ref?, settle?, exp = expectation id?, act, actConf, loc?, locConf, creditable }`.
Rules: exact pass (same-sign combination of up to 3 of the 8 highest-priority exact expectations summing to the delta, conf `high`) before window pass (highest-priority same-sign window takes the whole delta, `med`, `low` when a window of a different source was also active); otherwise pending; after 1.0 s `src = 'other'`, conf `low`. A gap delta is `src = 'other'`, `comp = 'gap'`. All-or-nothing per delta (no partial matching, Q-4). Invariant: `sumDeltas = sumEntries + pending`. `otherShareValue` and `largestOther` use absolute copper.

### F14.5 Sources and Stamps

`Sources.Begin() / End() / IsActive() / Stats() / Entries() / SetSink(fn) / MailSpec(mail, t0)`. `Sources.Stats()` = Reconciler stats plus `sources = { lootExp, questExp, mailExp, mailVanished, mailBaselines, mailSkippedCod, windowsOpened, ticks, handlerErrors }`.
Mapping (option A, Q-1): loot coin -> `loot` (exact, held while the loot context is open); quest -> `quest` (exact); a money mail that left the inbox -> `mailMoney` / `codIn` (subject starts "COD Payment:", English only) / `ahSale` + `ahCut` + `ahDepositRefund` (seller invoice that adds up; `ahSale`, `mailMoney` and `codIn` carry `settle = true`; `ahCut` and `ahDepositRefund` do not); vendor window -> `vendor` (+) / `purchase` (-); trade window -> `trade` (+ and -). Everything else (AH deposit, AH buy/bid, COD paid, postage) is `other` until 3b-4.
`Stamps.New{ lastCast }`: `NoteLoc(loc, gt)`, `Loc(t)`, `Apply(entry)`. Fresh location <= 5 s; creditable only for creature or game-object loot with a fresh location. Activity: creature loot GRIND (med); coin chat share with no known source LOOT (med); object loot GATHER (herb or mine cast <= 30 s) or FISH (fish cast <= 30 s), high, else OTHER (low); vendor and purchase VENDOR; quest QUEST; trade TRADE; mail kinds MAIL; other OTHER (low).

### F14.6 Contract tests added in M2

Expectation spec validation; boundary tests (ttl 1.0, expiry inclusive, wait exactly 1.0); sum invariant property tests; every replay case in `test_replay_ledger.lua`; mutation sets for Expectations, Reconciler, Stamps and Sources.

## F15. Schema 2, cash ledger and ledger commands (3b-2 M3, as built; Contract 1.8.0)

**GoldIntelDB (schema 2)**: `ledger = { [charKey] = L }` and `migrationBackup`. Migration step 1 -> 2 (`Store/Migrations.lua`) creates `ledger = {}` and `migrationBackup = { from = 1, t, keys, data }` (a deep copy of every schema 1 key except `compat`, `runtime`, `migrationBackup`; 708 bytes on the real E-43/E-45 files). Other keys, `lots` included, are untouched (per-character lots belong to 3b-3; F5b is still to be applied there). A schema 2 file opened by addon 0.3.1 is read-only (Store rule `schema > target`), nothing is written back (tested with the real 0.3.1 Store sources).

**GoldIntelCharDB (schema 2)**: `Store.CHAR_SCHEMA = 2`; `lastMoney` (copper, written by the Ledger). 0.3.1 treats schema 2 as newer and works on a private copy.

**L (per character)**:
```lua
L = { nextId, cash = { rec... }, totals = { src = { [src] = { n, copper, val } }, gap = { n, copper, val }, folded },
      locs = { { mapID, zone, sub }... }, quality = { intervals, unmatched }, largestOther }
rec = { id, t (unix s), c (signed copper), src, conf, act, ac (actConf), lc (locConf), l? (index into locs), x?, y? (4 dp),
        cr? (creditable), st? (settle), ctx?, r? (loot source type), cp? ('gap') }
```
`val` is the sum of absolute copper (the "abs" name is avoided on purpose: bare WoW global names are forbidden in addon files).

**Cash API** (`GI.Cash`): `Add(entry) -> id | nil, reason`, `AddGap(copper, ctx)`, `Last(n)` (expanded copies), `Expand(rec, led, key)`, `Count()`, `Cumulative()` (raw + folded, signed), `Stats()` (raw, folded, total, cumulative, totalValue, otherN, otherValue, otherShareValue, otherShareEntries, largestOther, gapCount, gapValue, unmatched, intervals, bySource, writable), `Writable()`, `Ledger()` (live table, for Ledger.lua only), `Reset()` (test). `Cash.CAP = 2000` (changed from 5000 by the user, M3 approval), `Cash.FOLD = 500`. Expanded entry = Contracts shape: `{ id, t, copper, src, conf, act, actConf, locConf, creditable, settle, ref, comp, ctx, charKey, loc? }`. Bus event `LEDGER_CASH` carries the expanded entry. Entries are immutable: no update or delete exists; Last/Expand return copies.

**Ledger API** (`GI.Ledger`, module 'Ledger', deps Collector): `Begin() / End() / IsOn() / Switch() / OnCollectOn(partial) / OnCollectOff() / CheckLoginGap() / OnLogout() / Mark() / Check() / StatusLines() / QualityLines() / DiagLines()`. `Check()` -> `{ moved, entries, pending, unseen, difference, seconds }`; difference = moved - entries - pending and must be 0.

**Rules**: a single-group `collect on Gn` does not start the ledger. Collect on starts the interval; collect off ends it (pending -> OTHER at once). Login: first run stores a baseline; saved `lastMoney` != balance gives one gap entry (`comp = 'gap'`, `ctx = 'login'`) only when the store is writable. `lastMoney` is written at begin, after each entry, at End and at logout.

**Trace (diagnostic, after E-46)**: `GI.Trace` (Ledger/Trace.lua) writes `GoldIntelCharDB.trace = { lines }` (max 400 when written; 1500 from 0.4.1, 3000 plus a `keep` list from 0.5.0, see F18; newest last) while an interval is on; optional taps `Expectations.tap(event, e, gt)`, `Sources.tap(kind, ...)`, `Loot.tap(kind, ...)`; `Loot.ReadWindow()` additionally returns `raw`, `slots`, `detail`. CharDB `lmv = 2` marks a trusted `lastMoney`. No classification behaviour depends on any of it.

**Commands**: `/gi ledger [status|last [n]|mark|check|on|off|trace [n|clear|on|off]]`; `/gi collect on` prints a `ledger:` line; `/gi diag` prints the ledger quality block first (OTHER share by value and entries, largest OTHER, gap count/value, unmatched, intervals).

## F16 Coin chat signal (3b-2 M5, 0.3.6)
- Event `P_LOOT_CHAT { copper:number>0, kind:'self'|'share', group:number? }`, emitted by Platform/Chat.lua from CHAT_MSG_MONEY (collect group G7). Only the two received-coin lines emit; everything else, secret or non-string text is recorded for the trace and ignored.
- Sources: exact loot expectation, ttl 1.0, comp 'split' for kind 'share'. Entry comps in the ledger: 'gap', 'deposit', 'split'.
- Reconciler option `wait` (>= 1.0); Sources passes 2.0. `Sources.Stats().sources` adds chatLines, chatClaimed, chatLate, chatCovered, chatSplit, chatExp.

## F17 Item pipeline, M1 modules (3b-3, contract 1.9, 0.4.0)
- `GI.BagDiff`: `Compute(prev, now) -> {added, removed, n} | nil, reason`; `Fingerprint(items)`; `New() -> tracker` with `Settle(snap) -> diff | nil, 'incomplete'|'baseline'|'empty'`, `Commit(seq)`, `Baseline()`, `Stats()`. Snapshot = `{ items = {[itemID]=qty}, complete = true }`; only `complete == true` snapshots are compared. Diff = `{ seq, from, to, added, removed, n }`. The baseline advances only on `Commit` (I-4: applied at most once).
- `GI.Valuation`: `Value(info, manual) -> {valueEach, valueSrc, flags}`, `Complete(lot, info, manual, now)` (first valuation only, never a revaluation, D-063), `Expire(lot, now)`, `PENDING_WINDOW = 30.0`. `info` is an `Items.Get` result; `manual` is `{copper}`. The HIGHEST of vendor and manual price is used (manual only when strictly higher; optional override, D-082); item data must be `ready` first; sell price 0 is `noVendor` and known; pending/secret are `unknown` + `pendingInfo`; invalid is `unknown` + `invalid`. `bound` = bindType 1 or 4.
- `GI.Lots`: `New(state, {capOpen=4000 (1.13.0; was 1500), capClosed=300, emit}) -> L`; `L:Add(spec) -> lot | nil, err`; `L:Convert(removed, copper, {t, via, ref?, priceOf?}) -> conversions, short, unallocated`; `L:Complete(itemID, info, manual, now)`; `L:ExpirePending(now)`; `L:Compact()`; `L:Check(carried) -> ok, diffs` (I-3); `L:OpenQty()`; `L:InventoryValue()`; `L:Stats()`; `Lots.AllocateCopper(total, weights)` (exact sum, remainder to the largest weight). `via` in `vendor|consume|trade|ah|mail|purchase`. State shape (persisted from M3 as `lots[charKey]`): `{ nextId, open, closed (ring), closedSummary, conv (ring), totals = {created, transfer, unattributed, byVia}, quality = {shortfall, merged, unallocated, vcCoerced} }`.
- Sale allocation (Q-8): copper is divided across item ids by `sellPrice x qty` when every price is known, otherwise equal per unit; within an item across lot pieces by quantity; the sum equals the cash entry exactly; remainder to the largest share. Copper for an item no lot covers is returned as `unallocated` and counted.
- Anomalies (user directive 2026-10-19): `Lots.New(state, {alert})` calls `alert(kind, record)` for EVERY anomaly; `state.anomalies = { counts = {[kind]=n}, recent = ring of 50 {t, kind, detail} }`; `Stats().anomalies` = counts; `Lots.Describe(kind)` returns the user text ending "please report it as a bug". Kinds: `sale-price-unknown`, `sale-no-sell-price`, `equal-split`, `shortfall`, `unallocated-copper`, `vc-coerced`. A vendor sale with copper > 0 and a `priceOf` hook checks every removed item: unknown price or price 0 is flagged.
- Modules reference no Cash, Reconciler, Expectations or Platform code (AC-15, I-6; static test).

## Contract 1.9.0 - M3 additions (additive, 2026-10-19)
- Lot: new optional `cost` (copper paid, purchase lots only; informational). `origin` = { act, actConf, mapID, zone, sub, x, y, skinning? }, `locConf` from the loot window stamp.
- `GI.LotBook`: Begin/End (called by Ledger), OnDecisions(decisions, { unix, moneyPos, moneyNeg }), Instance, Status/Last/Unknown/Check lines, ResetCurrent, ParseMoney, PriceSet/PriceClear/PriceList/ManualFor. Never references Cash, Reconciler, Expectations or Sources (AC-15).
- `GI.ItemSources.sink(decisions, info)`: optional consumer of one entry's decisions; decisions gain `loc`, `locConf` (loot adds).
- Storage: `lots[charKey]` = Lots state (nextId, open, closed, closedSummary, conv, totals, quality, anomalies); `prices.manual[itemID] = { copper, t }`.
- Commands: `/gi lots status|last [n]|unknown|check|on|off|reset confirm|decisions [n]|iteminfo`, `/gi price set|list|clear`.
- 0.4.7 addition: `/gi lots sales [n]` lists what each lot received when it left; `/gi lots status` adds conversion totals (units and copper per via).

## F18 Passive-play additions (0.5.0 and 0.5.1, D-086; contract 1.9.0, additive; documented 2026-11-03)
- **Setting** `collect.auto` (boolean, default `true`, F6/F12): start collecting a few seconds after login. `/gi config set collect.auto false` disables it.
- **`GI.Collector.AutoStart() -> enabled, result | false, reason`**, scheduled once by `Collector.OnEnable` after `Collector.AUTO_DELAY = 3` seconds. Runs at most once per load (`autoDone`); does nothing if collect is already on, if `collect.auto` is false, or after a hand-made `/gi collect off` in the same session. On success prints one chat line: `GoldIntel: recording started automatically (...)`. Supersedes the "collect always OFF after login" rule of D-074 A-3.
- **`GI.Ledger.Begin()`** now calls `Ledger.Mark()` (protected), so every interval starts marked and `/gi ledger check` works without `/gi ledger mark`.
- **`GI.Ledger.Check() -> { moved, entries, pending, unseen, difference, seconds } | nil, reason`**; `difference = moved - entries - pending` must be 0.
- **Trace storage:** `GoldIntelCharDB.trace = { lines = {...}, keep = {...} }`, newest last. `Trace.CAP = 3000` (rolling window of all lines). `Trace.KEEP_CAP = 400`: lines that are evidence for open questions are also copied to `keep`, which routine lines cannot push out. Kept: lines starting `ANOMALY`, `NOTE`, `EVT group`, `EVT check`, `BAGS settle skipped`, `BAGS settle: no snapshot`, `CAST spell=<id> kind=h|m|s|f...` (gathering) or `kind=other`; lines containing `UNMATCHED` or `-> unexplained`. Both lists survive across sessions until their cap; `/gi ledger trace clear` empties both.
- **Context event lines (0.5.1, evidence only; no decision depends on them):** `EVT group <old> -> <new>` (group state `grp=members/inGroup/inRaid`, polled every `Trace.GROUP_POLL = 2.0` s on `P_TICK`, logged only on change), `EVT zone map=<id> zone=<text> sub=<text>`, `EVT vendor|mail|trade|ah open|close`, `EVT level <n>`, `EVT profs changed`.
- **Check line (0.5.1):** `EVT check <periodic|final> difference=<c> moved=<c> entries=<c> pending=<c> unseen=<c> seconds=<s>[ MISMATCH]`, every `Trace.CHECK_EVERY = 600` s of ticks while an interval runs and once at interval end; `MISMATCH` is appended when difference is not 0. Written only while an interval is on.

## F19 0.5.2 additions (contract 1.10.0, additive, D-091..D-094)
- **Trainer source (D-093):** Platform/Trainer.lua maps `TRAINER_SHOW` -> `P_TRAINER_OPEN {}` and `TRAINER_CLOSED` -> `P_TRAINER_CLOSE {}` (idempotent; `P.TrainerModule.stats = { opened, closed, duplicateOpens, duplicateCloses }`). Collector group `G9` = { TRAINER_SHOW, TRAINER_CLOSED } (registered last; allow-list entries by user decision, not yet observed live). `Context.KINDS` gains `trainer`. Sources window `trainer = { { src = 'trainer', sign = -1 } }` (window mode, ttl 1.0 s): money out while the window is open or inside the linger becomes `src = 'trainer'`, `act = 'TRAINER'`, `conf = 'med'`, not creditable. Probe capability `trainer.events` checks the two names with `IsEventValid` (never registers).
- **Skinning, first window (D-091):** `ItemSources.SKIN_FIRST = 1.0`. A creature `P_LOOT_OPEN` whose guid was not seen in this interval is skinning when `LastCast('skin')` is at most SKIN_FIRST seconds earlier. `ItemSources.Stats().skinFirst` counts these windows (also included in `skinWindows`).
- **Logout check (D-092):** `Ledger.Check()` may return `atLogout = true`; then `moved` uses `Money.Last()` instead of GetMoney() (which reads 0 during a real logout, E-46) and `unseen` is 0. The trace line is `EVT check final ... seconds=<s> logout` (seconds are floored). Outside the logout handler nothing changes.
- **Trace (D-093, D-094):** `EVT trainer open`, `EVT trainer close` (also copied to `trace.keep`), `EVT quest done id=<questID> copper=<n>`, and at interval begin `EVIDENCE trainerRegistered=<true|false|nil>`.

## F20 0.5.3 additions (contract 1.11.0, additive, D-095, D-096)
- **`P_LOOT_WON { itemID:number, qty:number }`** (Platform/Chat.lua): emitted for a CHAT_MSG_LOOT line of kind `won`. `Chat.ClassifyLoot` returns `won` for text containing `: You won: ` (live shape `|HlootHistory:..|h[Loot]|h: You won: |c..|Hitem:<id>..`) or starting `You won:`; `X won: ` (another player) stays `roll`.
- **ItemSources roll expectation:** on P_LOOT_WON a loot expectation `{ itemID, left = qty, sourceType = 'roll', act = 'LOOT', actConf = 'med', loc, locConf, closeGT = now }` joins the loot-window expectations; it is pruned after LOOT_KEEP + WAIT seconds and consumed once. A matching add is decision `how = 'loot'`, `reason = 'roll won'`. Counter `Stats().rollWon`. Trace `ITEM_WON item=<id> qty=<n>` (kept).
- **`Reconciler:ClaimPendingSum(n, spec) -> true, setSize | false, 'inactive'|'single'|'nosum'|'ambiguous'`**: among pending deltas with n's sign, finds every set of 2 or 3 whose sum is exactly n; books the set when it is the only one and no single pending delta equals n; each delta becomes `{ t, copper, src = spec.src, conf = 'high', ctx = spec.ctx, ref = spec.ref, comp = spec.comp }`. Sources calls it for share lines only (`kind == 'share'`), with `{ src = 'loot', ctx = 'loot', ref = { chat = true, sourceType? }, comp = 'split' }`; counter `Stats().sources.chatSum`; trace `CHATSIG sum share <n>c`.

## F21 0.5.4 additions (contract 1.12.0, additive, D-097; 3b-3 M4 measurement)
- **`P.PerfModule`** (Platform/Perf.lua, read-only): `Functions() -> sorted names | nil` (functions of C_AddOnProfiler), `Metrics() -> sorted names | nil` (keys of Enum.AddOnProfilerMetric), `Sample() -> { t, metrics = { [name] = number }, memKB?, luaKB?, profilerEnabled?, why? }` (every enum metric read with `GetAddOnMetric('GoldIntel', value)`, each call protected; `memKB` from `UpdateAddOnMemoryUsage` + `GetAddOnMemoryUsage('GoldIntel')` when both exist; `luaKB` = collectgarbage('count'), the whole UI heap, context only; `why` names what is missing), `Text(sample) -> string`.
- **Storage:** `GoldIntelCharDB.perf = { samples = { { t (unix), why = 'begin'|'periodic'|'final', m = metrics, memKB?, luaKB?, en?, why2?, collect? } } }`, newest last, at most `Trace.PERF_CAP` = 500. Written at interval begin, every `Trace.CHECK_EVERY` seconds and at interval end.
- **Trace:** `EVT perf <why> <metric=value ...> memKB=<n|n/a> uiLuaKB=<n>[ profiler=<bool>][ (<why>)]`; at interval begin `EVIDENCE profilerFunctions=<list|none>` and `EVIDENCE profilerMetrics=<list|none>` (both kept).
- **Command:** `/gi perf` prints the functions, the metrics, a sample now and the number of stored samples. **Probe:** `perf.profiler` = C_AddOnProfiler.GetAddOnMetric exists.

## F22 Phase 4 P4-M1 pure modules (D-099; loaded and in effect from 1.15.0 / 0.6.0, see F23)
- **`GI.Clock`** (Aggregate/Clock.lua): `New{ idleSec=120, drySec=60, nearYards=150, minSpeed=8, actWindow=120, distance=fn(a,b)->yards|nil }`; `:Life(gt)`, `:Productive(gt, act, loc)`, `:Manual('pause'|'afk'|nil)`, `:Override(act|nil)`, `:Tick(gt, dt, loc, { taxi, inWorld, level }) -> { ACTIVE slice }`, `:Flush(gt) -> { ACTIVE slice }`, `:Current(gt)`, `:Pending()`, `:Stats() -> { active, idle, travelHard, travelSoft, paused, travelUnknown, slices, pending }`. Slice = `{ gt, dt, loc, act, level }`. Classes follow D-054 priority; a slice takes the state at its end; slices wait until certain (at most idleSec).
- **`GI.Aggregator`** (Aggregate/Aggregator.lua): `New(aggState, heatState, { locale })`; `:AddTime(slice)`, `:AddCash(e)`, `:AddLot(lot)`, `:Enqueue(kind, rec)` with kind `cash|lot|time`, `:Drain() -> n`, `:Backfill(ledger, lotState) -> true, n | false, 'already'`, `:Check(ledgerNet, createdValue) -> { cash, vc, seconds }`, `:Totals()`, `:Stats()`; helpers `PlaceKey(loc, locale)`, `Bracket(level)`, `BinIndex(x, y)`, `FromStored(rec, locs)`. Shapes as Phase4_Live_Aggregation_Proposal.md section 3: `agg[charKey] = { v = 1, places = { [placeKey] = { mapID?, zone, sub?, inst?, cells = { [act|bracket] = { s, coin, cin, cout, vc, q = { [itemID] = qty }, n, t0?, t1?, bf? } } } }, totals = { s, coin, cin, cout, vc, n }, segments = { ... }, backfilled? }`, `heat[charKey] = { [mapID] = { [idx] = { s, c, a = { [act] = copper } } } }`.

## F23 0.6.0 live aggregation (contract 1.15.0, additive, D-102)
- **`GI.AggLive`** (Aggregate/Live.lua): `Ensure() -> true | false, reason` (creates the aggregator over `agg[charKey]`, `heat[charKey]`; once per character: `Backfill`, then `state.check = { cash, vc, since }` offsets), `Begin()` / `End()` (called by Ledger.Begin after LotBook.Begin, Ledger.End before Trace.End), `Check() -> { cash, vc, seconds } | nil, reason` (cash = (cin - cout) - Cash.Cumulative() - check.cash; vc = totals.vc - lots created value - check.vc; both must be 0), `OnLot(lot, 'add'|'complete')`, `Top(n)`, `SetManual('pause'|'afk'|nil)`, `SetOverride(act|nil)`, `Stats()`. Feeds: Bus `LEDGER_CASH` (every stored entry, also login gaps; queued before the aggregator exists), Lots emit, P_TICK (Clock slices; drain every 2 s; report every 600 s), signals of life P_MONEY, P_LOOT_OPEN, P_ZONE, P_LEVEL, P_QUEST_DONE, P_COMBAT, CONTEXT_CHANGED, P_CAST (gathering casts are productive).
- **Clock (amended):** pending slices are runs `{ gt, last, dt, loc, act, level, candidate, cell }`; a signal of life or a productive event starts a new run; `:Speeds() -> { [bucket] = seconds }` with buckets 0-4, 4-7, 7-9, 9-12, 12-16, 16+ yards per second. **Aggregator:** `:AddLotValue(lot)`, queue kind `lotValue`.
- **Platform:** `Platform.OnTaxi() -> boolean | nil` (UnitOnTaxi), `Map.WorldSize(mapID) -> w, h | nil` (C_Map.GetMapWorldSize, cached), `Platform.Distance(a, b) -> yards | nil` (same map only). Probe `map.worldsize`.
- **Lots emit:** `emit(kind, rec, phase)`; for kind 'lot' the phase is 'add' (Lots:Add) or 'complete' (Lots:Complete).
- **Setting** `reminder.reloadMinutes` (number, default 60, 0..600; 0 = off). Reminder line: `GoldIntel: <n> minutes since your data was last saved; /reload saves it`, once per n minutes after the load, never in combat (checked every 60 s).
- **Commands:** `/gi agg [status|check|top [n]]`, `/gi pause`, `/gi afk`, `/gi resume`, `/gi activity <KEY>|clear` (keys: Contracts F0 ActivityKey, reserved keys included).
- **Trace (kept):** `EVT agg <periodic|final> cash=<c> vc=<c> seconds=<s>[ MISMATCH]`, `EVT clock active=.. idle=.. travelHard=.. travelSoft=.. paused=.. travelUnknown=.. pending=.. speed=<bucket:seconds,...>`, at interval begin `EVIDENCE mapWorldSize=<true|false>`.

