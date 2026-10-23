# GoldIntel Phase 3 Planning Package

DOC VERSION: 1.0.0  |  DATE: 2026-10-17  |  AUTHOR: Claude (S-011)  |  STATUS: PLANNING AND ARCHITECTURE ONLY. Phase 3b (collectors) is NOT approved. The user ACCEPTED D-043 to D-050 on 2026-10-17 and approved Phase 3a (D-051); see Addendum A, which supersedes any conflicting text below. Nothing here is built.

Evidence tiers (D-031): [file] saved file, [chat] user's pasted chat, [reported], [inferred], [assumed]. Anything not proven live is marked UNVERIFIED and must not be depended on (D-029, R-23).

## Addendum A (2026-10-17): the user's decisions and the heatmap vision

This addendum SUPERSEDES conflicting text in sections 5, 7.4, 7.5 and 14.

### A.1 Decision status

| Item | Status |
|---|---|
| D-043 value created once at acquisition | ACCEPTED |
| D-044 only acquisition activity contributes heat | ACCEPTED (quest turn-ins, vendor sales, repairs, trades, mail, auction settlements never light the map) |
| D-045 vendor floor and conservative valuation | ACCEPTED |
| D-046 late item info stays visible as unknown | ACCEPTED |
| D-047 disclose large single drops | ACCEPTED |
| D-048 activity evidence-scored with confidence | ACCEPTED |
| D-049 idle handling | ACCEPTED WITH CLARIFICATION: idle time is excluded from ALL GPH calculations and from map heat |
| D-050 select signals by verification | ACCEPTED |
| Q-AFK-1 waiting for a respawn | idle after the timeout (fishing is activity) |
| Q-AFK-2 travel | REJECTED my recommendation; taxi time does not count; model pending: Travel_Model_Options.md (D-054) |
| Q-AFK-3 manual commands | APPROVED: `/gi pause`, `/gi resume`, `/gi afk` (D-055) |
| Phase 3a (diagnostics, experiments, signal verification) | APPROVED (D-051): Phase3a_Verification_Protocol.md |
| Phase 3b (collectors) | NOT approved; blocked pending verification and review |
| Architecture 8 wording ("copper credited" to "value credited") | not yet approved separately; it follows from D-043/D-044 and is applied when the Architecture is revised after Phase 3a |

### A.2 Heatmap design implications of D-052 (planning; nothing built)

1. **Location, not zone.** The overlay never colors a zone as a whole. Value is attached to coordinates in a 32 x 32 grid per map (the user agrees with 32 x 32). A bin is the map's world width divided by 32; the width is readable with `C_Map.GetMapWorldSize` (present).
2. **Density cloud with gradual cooling.** Instead of a fixed 3x3 smoothing, use a distance kernel (radius is a setting, default about 1.5 bins). Compute `F_c` = credit spread by the kernel and `F_s` = active seconds spread by the same kernel. Heat = `F_c / F_s` (value per active hour). Ratio of smoothed fields is honest: it never invents income where no time was spent. Smoothing the ratio itself would not be.
3. **Colour and transparency.** Colour = value per active hour; opacity = confidence, rising with `F_s` up to the minimum-sample threshold. Unvisited or thinly sampled areas fade to transparent, which gives the cloud look; productive spots are opaque and warm.
4. **Colour scale (decision needed):** (a) relative to the best well-sampled spot on that map (for example 95th percentile = red; matches "20 gph RED, 10 gph YELLOW"), or (b) fixed gold-per-hour thresholds in settings. Recommendation: (a) by default with the legend showing the numbers, (b) as an option.
5. **Two views (setting):** value per active hour (default) and activity density (credit only, no time normalization) for answering "where do drops happen".
6. **Hotspot list (proposal, not part of the decision):** local maxima of the smoothed field with a minimum separation, each shown with coordinates, GPH, sample hours and a place name. Names for coordinates: `C_Map.GetMapInfoAtPosition` is present in the client (behaviour unverified, experiment H1).
7. **Large single drops (D-047):** each bin keeps its largest single credit; the tooltip shows its share; an optional cap is a setting.
8. **Overlay toggle (AM-2):** a button on the map and `/gi overlay on|off|toggle` (command name proposed), plus an opacity setting. Frame rules: its own child frame of the map canvas, below pins, mouse-transparent, so Gatherer, Questie and similar addons keep working. Unverified in this client (experiment H2).
9. **Graphical configuration (D-053):** the options window is generated from the typed Config specification (checkbox for booleans, slider for ranges, dropdown for enumerations), so the window and the `/gi config` command share one source of truth. Which UI API the client offers (a Settings category API, or a plain frame) is unverified and becomes an experiment before Phase 8.
10. **Stationary and travel time:** bin seconds follow D-049 (idle excluded) and the travel model once chosen (taxi and soft travel excluded, so flights do not cool the bins they cross).

### A.4 Instances and account-wide heat (D-060, D-061; planning, nothing built)

- **Instance runs.** A run starts at the loading screen into an instance and ends at the loading screen out. Run value is booked at acquisition like any other (D-043). The run is credited to one heat location: the entrance. Boss kills and trash are not separate heat; the run list (per instance: runs, average and best gold per run, active time per run) replaces the bin view for instances. Waiting for respawns inside is simply idle after the timeout (D-055); no special rule. Instance resets are not needed for accounting (a new entry is a new run); whether a reset signal exists is a separate Phase 3a question only if the user wants reset counted.
- **Data needed.** `IsInInstance()` and `GetInstanceInfo()` (lab S1 instance run), the last open-world position before entry (already sampled), and optionally an entrance lookup (P1 lists `C_EncounterJournal` and `C_AreaPoiInfo` names).
- **Account best.** Per bin the view takes the highest GPH among characters whose bin passes the confidence floor; the winner record (character, class, level, activity, GPH, active hours, samples, date, valuation basis) is kept for the tooltip. Computed on demand from each character's bins in the single SavedVariables file and cached; no new collection needed. Each bin should carry `lvlMin` and `lvlMax` so the tooltip can say "level 58 to 60".
- **Risks added to the register as proposed:** a single outlier in a thin bin becoming the account best (mitigation: shared confidence floor, minimum active seconds); stale values after price or patch changes (mitigation: show date, allow a recency window setting); bin size 32 x 32 is per map and shared by all characters so merging is a plain per-bin comparison (no resampling).

### A.3 Answers received (2026-10-17)

1. Colour scale: RELATIVE by default, fixed thresholds retained as a later setting (D-057).
2. Travel model: Option B (D-054).
3. Hotspot list: YES, in v1, with coordinates, place name if available, activity, GPH, active hours, sample count/confidence (D-058).
4. Overlay commands: `/gi overlay on|off|toggle` approved; the settings window exposes the same (D-059).

### A.3 (original questions, now answered)

1. Colour scale default: relative (recommended) or fixed thresholds?
2. Travel model: A, B or C (Travel_Model_Options.md section 9).
3. Is the hotspot list wanted in v1?
4. Name of the overlay command (`/gi overlay` proposed).

## 0. Scope of this package

Covered: (1) value attribution, (2) loot valuation, (3) location credit, (4) activity detection, (5) AFK handling, (6) collector signal selection, plus a verification plan, open questions, a proposed work breakdown and the gate checklist.

Not covered, and not started: any collector, Reconciler, Lots, Activity/Session engine, heat bins, pricing provider, auction scanning, UI. Phases 4 to 9 are only referenced where Phase 3 design depends on them.

## 1. What is known and what is not (the boundary of this plan)

Proven live (Phase 2 evidence):

| Fact | Evidence |
|---|---|
| `PLAYER_MONEY` delivered; payload usable; `GetMoney` works; vendor sale/buyback deltas seen | E-12 [reported], E-15 [chat] |
| `PLAYER_LEVEL_UP`, `ZONE_CHANGED`, `ZONE_CHANGED_NEW_AREA`, `PLAYER_REGEN_DISABLED/ENABLED`, lifecycle events delivered | E-14 [file], E-15 [chat] |
| `C_Map.GetBestMapForUnit` and `GetPlayerMapPosition` work in a city (0.5457, 0.6802 in Orgrimmar) | E-06 [file] |
| 0.5 s ticker via `C_Timer` (scheduler backend `ctimer`) | E-05, E-14 [file] |
| Namespaces present: `C_Item`, `C_Container`, `C_AuctionHouse` (85 functions), `C_Loot`, `C_LootHistory`, `C_LootFrame`, `C_Mail`, `C_MerchantFrame`, `C_TradeInfo`, `C_QuestLog`, `C_CombatLog`, `C_DamageMeter`, `C_Secrets`, `C_RestrictedActions` | E-05 [file]: presence only (R-12) |
| Globals present: `GetLootSlotInfo`, `GetInboxItem`, `GetInboxHeaderInfo`, `TakeInboxMoney`, `GetPlayerTradeMoney`, `GetTargetTradeMoney`, `issecretvalue` | E-04/E-05 [file] (Diag transcript, globals section) |
| Legacy auction / skill-line / trade-skill globals absent | E-02 [file] |

NOT proven (everything Phase 3 needs from the game besides money):
loot, merchant, quest, mail, trade, auction and chat-money events; `UNIT_SPELLCAST_SUCCEEDED`; item-info data (sell price, bind type); loot source GUIDs; whether any of these are restricted or return secret values; `UnitIsAFK`. The earlier ADDON_ACTION_FORBIDDEN popup came from one of 17 never-individually-tested events (D-029, R-01).

Consequence: this package selects signals by hypothesis plus a verification plan (section 8). No signal is "chosen" until its experiment passes.

## 2. Vocabulary (binding for Phase 3, from D-035)

- **Observation**: the balance or an inventory fact the client reports (`GetMoney`, a bag count). Truth.
- **Detection**: noticing that something changed (a `P_MONEY` delta, an item appeared).
- **Attribution**: deciding WHY it changed (loot, vendor, quest...), with its own confidence.
- **Reconciliation**: proving entries add up to the observation.
- **Value created** (Requirements section 5): gold received for free plus the valuation of items acquired without paying. Excludes conversions and purchases.
- **Credit**: assigning a slice of value created to a place (a heat bin). Credit never changes the ledgers; it is a view over them.

## 3. Value attribution

### 3.1 Principles

1. The live balance is the only truth for copper. Chat lines, loot windows and quest messages are classification hints, never amounts (Compatibility_Notes rule: never parse chat or combat events to obtain money).
2. Every copper of delta ends in exactly one cash entry (invariant 1). Unexplained remainder is `OTHER`, confidence low, counted in a visible statistic.
3. Items and copper are two ledgers. A conversion (vendor sale) moves value between them and is not new income (invariant 2, FR-LED-3).
4. Value created is booked ONCE, at the moment the free item or gold arrives, at that moment's valuation. A later sale books cash in and removes the lot; the difference is shown as "realized variance", never added to Wealth.
5. Attribution and credit are separate steps with separate confidence. A low-confidence attribution never produces heat.

### 3.2 Pipeline

```
Platform signals (normalized events)         -- Phase 3 collectors enqueue only (handler rule 5.3)
   -> Context state  (merchant / mail / trade / quest / loot-window open or not)
   -> Expectations   (what each signal says SHOULD change: copper, items)
   -> Reconciler     (matches P_MONEY deltas to expectations; emits CashEntry)
   -> Lots           (items in, FIFO conversions out; valuation attached on arrival)
   -> bus: MoneyObserved / TransactionDetected / TransactionAttributed / Reconciled (reserved in Phase 2)
```

### 3.3 Worked cases (what the design must produce)

| Case | Cash ledger | Asset ledger | Value created | Credited to a place? |
|---|---|---|---|---|
| Kill, loot 35c and a Linen Cloth | +35c, src `loot`, act GRIND | +1 lot (free), valued at acquisition | 35c + item value | Yes, at loot position (3.5) |
| Sell the Linen Cloth to a vendor | +sale price, src `vendor` | lot consumed (FIFO), conversion recorded | 0 | No |
| Repair armor | -cost, src `repair`, expense | none | 0 (expense) | No |
| Buy a potion | -price | +lot (purchase, at cost) | 0 | No |
| Quest turn-in: 1s 20c and an item | +copper, src `quest` | +lot (free) | copper + item value | No by default (reward is earned over a route, not at the NPC) |
| Mail: AH proceeds | +copper, `settle = true` | none | 0 for GPH; reported as Settled | No |
| Trade: receive gold for a service | +copper, src `trade` | none | copper | No |
| Unexplained +5s (no signal) | +5s `OTHER`, conf low | none | 0 until classified | No |

### 3.4 Reconciler timing (unchanged from Architecture 6, restated with the new knowledge)

- `PLAYER_MONEY` is the trigger; the Reconciler waits up to 1.0 s for sibling signals (D-065, was 0.25 s), then matches by exact copper and sign in priority order (trade, mail, vendor, quest, loot, AH).
- Open question A: does the loot-window signal arrive BEFORE `PLAYER_MONEY` for looted gold in this client? Unknown. The design therefore tolerates either order (a delta may wait for a late expectation up to its TTL; an expectation may wait for its delta). Verified by the loot experiment (8.2, L1).
- Secret values: any payload that may be secret (`IsSecret`) is never compared or used in arithmetic; the entry degrades to `OTHER` with a diagnostic (R-03).

### 3.5 Decisions proposed for 3

- **D-043 (Proposed): Value created is booked once, at acquisition, at conservative valuation, and is never rewritten.** Revaluation later only feeds the realized-variance display.
- **D-044 (Proposed): Credit eligibility.** Only loot gold, free items from creature or node loot, gathered items and fished items are credited to places. Quest rewards, trade, mail, AH, vendor, repairs are never credited (confirms Architecture invariant 4).

## 4. Loot valuation

### 4.1 Valuation record

Every lot carries: `valueEach` (copper), `src` (which tier produced it), `conf` ('high' | 'med' | 'low'), `age` (seconds old of the price), `flags` (`unknown`, `bound`, `pendingInfo`). Stored at acquisition and frozen (D-043).

### 4.2 Provider chain (Architecture 9, made concrete)

Order, first provider with an answer wins, but the floor always applies:

1. **Vendor floor.** Sell price from the item data API. Always the lower bound. UNVERIFIED in this client: which function returns it (`C_Item.GetItemInfo`, `GetItemInfo`, `C_Item.GetItemInfoInstant`) and whether sell price is in its results. Experiment I1.
2. **Manual prices.** User-entered per item (a setting-backed table). Works with zero external dependencies.
3. **Own auction observations** (Phase 6). Only when the auction house is open and the modern API behaves. Not available in Phase 3.
4. **Optional third-party adapters** (read-only). Candidates are addons that expose a price through a public function. None is verified to exist in Forever. Each adapter must be probed, never assumed, and may be absent (D-039: no required dependency).

Conservative valuation (default, setting `valuation`): `max(vendorFloor, min(median market, stale-adjusted price))`. Unknown items value 0 and are flagged. "Hot spot" claims later therefore never rest on a guessed price.

### 4.3 Cases the valuation must handle

| Case | Rule |
|---|---|
| Item info not cached yet (async data) | Lot enters as `pendingInfo` with value 0; one revaluation when the data event arrives within a short window (say 5 s); then frozen. If it never arrives: `unknown`, value 0, counted in a visible statistic |
| Soulbound / quest items | `bound` flag; auction tiers do not apply; vendor floor only (may be 0) |
| Grey items | Vendor floor is the whole value |
| Stacks | `valueEach` times quantity; quantity comes from the loot slot or bag diff, whichever is verified |
| Currency-like loot | Out of v1 scope; recorded as `unknown` |
| Price staleness | `age` shown; a very stale price falls back to the next tier |
| Items without sell price (cannot be sold) | Value 0, flagged `noVendor`; not an error |

### 4.4 Your question answered precisely (items, not only coins)

A kill that drops 40 copper and a rare item is credited 40c plus the item's CONSERVATIVE value at the drop location. If only vendor prices are known the heat is a floor, not a promise; if a market price is available the item adds its (staleness-adjusted) market value. Selling the item later changes nothing about the heat (principle 4).

### 4.5 Decisions proposed for 4

- **D-045 (Proposed): Valuation tiers and the vendor floor** as in 4.2; third-party adapters are optional, read-only, probed, and each needs its own approval.
- **D-046 (Proposed): Valuation data may be late.** A bounded `pendingInfo` window and a visible `unknown` count replace silent zeros.

## 5. Location credit

### 5.1 Position source

`Platform.Map` (proven for position and map id). `P_TICK` samples every 0.5 s. No sample when position is unavailable (instances, loading, secret) (Architecture 8). Last good position is held for at most a few seconds (setting, default 5 s) for stamping an event; an older position makes the stamp `locConf = 'stale'` and the event earns no credit.

### 5.2 Where is a drop "located"?

The player's position at the moment the loot arrives (loot window opened or item/gold received), not the corpse. Corpse looting range is a few yards, small against a 32x32 zone grid [inferred]. Gathering and fishing: the player position at the moment of the successful gather/loot.

### 5.3 Grid and bins (restated)

32 x 32 per zone `mapID`, sparse, keyed `y*32 + x`, bin = `{c = value credited, s = active seconds, a = {act = value}}`. Seconds accrue only while ACTIVE (not idle, section 7), for all activities, so value per hour in a bin is honest. Minimum seconds per bin before display (default 60). Smoothing and drawing are Phase 7.

### 5.4 Amendment needed in Architecture section 8 (NOT yet applied)

Architecture 8 says the bin field `c` is "copper credited". It must say **value credited = gold plus valued free items** (Requirements section 5). This was a gap in my wording; it is recorded here as a proposed amendment and will be applied when the user approves it.

### 5.5 Statistical honesty

- One lucky rare drop can paint a hot spot. Proposed guard (D-047, Proposed): each bin also stores its largest single credit; the tooltip shows "top single drop = x% of bin"; an optional setting caps a single item's credit per bin for ranking (labelled experimental).
- Minimum seconds and sample counts are shown in the tooltip (FR-HEA-2, FR-RNK-4).
- Hearthing or flight paths: position jumps, not travel; time in transit earns seconds but no credit (see 7.4 for whether that time counts at all).
- Two overlapping zone maps (zone vs city, subzone-level maps): credit goes to the `mapID` returned by `GetBestMapForUnit` at that moment; no splitting across maps.

### 5.6 Storage estimate [assumed]

~40 bytes per bin serialized. A very busy zone uses perhaps 300 to 600 bins: 12 to 24 KB. Dozens of zones stay far below the 2 MB budget; roll-up and pruning are Phase 5 (R-19).

## 6. Activity detection

### 6.1 What activities Phase 3/4 must distinguish

GRIND, GATHER, FISH (location-credited); VENDOR, QUEST, AH, TRADE, MAIL (context, never credited); OTHER. Reserved keys exist but have no detection (A-1).

### 6.2 Design: context first, then evidence, then manual

1. **Context activities** come from windows that are open (merchant, mail, trade, quest turn-in, auction house). They need only the open/close events and are independent of the combat log.
2. **Field activities** (GRIND/GATHER/FISH) come from the SOURCE of the last loot or the last gather/fish action.
3. **Manual override** always wins; it is sticky until cleared.

### 6.3 GRIND without the combat log (OI-8, D-030)

Candidate signals, none verified:

| ID | Signal | What it tells us | Strength | Risk |
|---|---|---|---|---|
| G1 | Loot window with a creature source (GUID type `Creature`) | A corpse was looted: kill-and-loot | Strong | Needs `GetLootSourceInfo` or equivalent; source GUID may be secret; unverified |
| G2 | Experience gain event (`PLAYER_XP_UPDATE` or the XP chat event) | A kill that gave XP; works for grey mobs that drop nothing | Medium | At max level or for non-XP kills it is silent; chat form is locale-dependent |
| G3 | `PLAYER_REGEN_DISABLED/ENABLED` (PROVEN) | "In combat" windows; with movement it implies fighting | Weak alone, good as gate | None (proven) |
| G4 | `C_CombatLog` / `C_DamageMeter` outputs | Possibly kill counts or combat sessions | Unknown | Inspect first (F1); may be restricted or secret |
| G5 | Unit death events for the player's target | A kill | Strong | Probably requires the combat log or unit events; unverified |

Proposed rule (if G1 verifies): `GRIND` = combat state seen within the last N seconds (G3) AND a creature loot or XP event (G1/G2) within M seconds; `N` and `M` are settings. If G1 and G2 both fail verification, GRIND falls back to "combat seen (G3) and not any other activity", labelled low confidence, with the manual override prominent.

### 6.4 GATHER and FISH

- GATHER: loot whose source is a `GameObject` (herb, ore node) or a successful gather cast (`UNIT_SPELLCAST_SUCCEEDED`, player only, spell id in a configurable set). Skinning of a corpse is a creature source plus a skinning cast: `GATHER`.
- FISH: a fishing cast or channel followed by a loot from the bobber `GameObject`.
- Spell ids are data, not code (a table in a settings-backed list), because the Forever spell list is UNVERIFIED.

### 6.5 Stability

Activity changes require a minimum dwell (default 10 s) to avoid flapping at a fight edge; the segment merge rule (`minSegSec`, default 600 s) in Architecture 7.5 already smooths the displayed result.

### 6.6 Decision proposed

- **D-048 (Proposed): Activity is evidence-scored, not assumed.** Each segment carries `act`, a confidence, and the signals that justified it. A signal that fails verification is removed from the rule, not patched around.

## 7. AFK handling

### 7.1 What can and cannot be detected

An addon cannot see keystrokes or the mouse [inferred, standard WoW behaviour]. AFK must be inferred from game state or declared by the user. Both are in the requirements (FR-SES-3 idle excluded; FR-SES-4 pause/resume manual).

### 7.2 Signals of life (any one resets the idle timer)

Money change, loot, combat enter/leave, successful cast by the player, position change greater than a small epsilon, window opens (merchant, mail, trade, quest), zone change, level-up. Optional extra if verified: the game's own AFK flag (`UnitIsAFK("player")` and its change event; UNVERIFIED, experiment A1).

### 7.3 Algorithm

- `lastLife` = latest signal time. If `now - lastLife > idleSec` the state becomes IDLE.
- **Retroactive subtraction:** when idle is declared, the seconds already counted since `lastLife` are removed from active time (they belong to the idle gap). On the next signal the clock resumes. A short gap shorter than `idleSec` is never removed.
- Idle seconds never accrue to heat bins (section 5.3) and never enter the GPH denominator (Requirements section 5).
- `idleSec`: default 120 s; the user already set 240 s and it persists [file].
- `PLAYER_LEAVING_WORLD` / loading screens pause the clock (no ticker progress counts).
- Dead or ghost: pause (proposed); resting in an inn or city is NOT idle by itself.

### 7.4 Questions that need a user decision

- **Q-AFK-1 Stationary legitimate activity.** Fishing and waiting for a node respawn can exceed `idleSec` with no signals. Option A: casts and loot count as life, so fishing is safe; waiting for a respawn is idle after `idleSec`. Option B: a per-activity exemption list. Recommendation: A first, B only if testing shows a real problem (scope control).
- **Q-AFK-2 Travel.** Flight paths and long runs have low income. Option A: count them as active time (honest GPH, dilutes it). Option B: a `TRAVEL` pause when on a taxi (requires verifying a taxi signal). Recommendation: A for v1, record as a limitation.
- **Q-AFK-3 Manual controls.** `/gi pause`, `/gi resume`, `/gi afk` toggle (already required by FR-SES-4). Recommendation: yes, and the UI shows the clock state.

### 7.5 Decision proposed

- **D-049 (Proposed): Idle is evidence-based with retroactive subtraction; manual pause always available; heat seconds accrue only while ACTIVE.**

## 8. Collector signal selection and verification plan

### 8.1 Selection criteria

A signal is selected only if all hold: (1) delivered AND payload usable in the live client (stage `payloadUsable`, D-034); (2) not restricted, no popup; (3) no secret-value dependence for the needed fields, or a safe degradation exists; (4) not locale-dependent text parsing for amounts; (5) a fallback or a stated loss if it fails; (6) bounded CPU (handlers only enqueue).

### 8.2 Signal matrix

| Need | Primary candidate | Status | Fallback if it fails | Verification |
|---|---|---|---|---|
| Copper balance and delta | `PLAYER_MONEY` + `GetMoney` | PROVEN | none needed | done |
| Item arrival (loot) | Loot window events + `GetLootSlotInfo` / `GetLootSlotLink` | VERIFIED (E-18..E-20): `LOOT_OPENED` and `LOOT_SLOT_CLEARED` non-secret, before `PLAYER_MONEY`; slots readable for creature and node loot, also while the Combat restriction was active; `LOOT_SLOT_CLEARED` can arrive twice for one slot (de-duplicate) | none needed | L1, L2, L3 done | Inventory (bag) diff at defined boundaries via `C_Container` | L1, L2, I2 |
| Loot source (creature/node) | `GetLootSourceInfo(slot)` GUID | VERIFIED (E-18..E-20): `Creature-...` for mobs, `GameObject-...` for herb and mining nodes (object id in field 6), quantity as second return; skinning reports the corpse GUID, PROVEN in E-24: same GUID twice (corpse, then skin) and the same node GUID once per harvest, so GUID alone is never a once-only key (repeat-GUID rule still to prove, lab 1.5 records it) | GRIND rule falls back to XP and combat state | L3 done | Activity from combat state + XP; GATHER from cast | L3 |
| Free vs purchased item | Context (merchant open) + money sign | VERIFIED as derivable (E-21): purchases and repairs are negative, sales positive, all inside the open window | bag diff + merchant context | M1 |
| Vendor open/close, sold/bought | `MERCHANT_SHOW/CLOSED` + bag diff | PARTIAL (E-21): `MERCHANT_SHOW` delivered, no args, money changes follow by seconds (sale +, purchase -, repair -); `MERCHANT_CLOSED` VERIFIED (E-33): fires on button/Esc close and on walk-away close, no args, duplicates possible (idempotent handler) | money delta with merchant context only; poll the merchant frame for close | M1 done |
| Quest turn-in reward | `QUEST_TURNED_IN` (quest id, xp, money args) | VERIFIED (E-22): 3 non-secret args (818, 625, 175); money arg equals the PLAYER_MONEY delta exactly, event arrives 0.041 s before it; item rewards not in payload; bag diff VERIFIED (E-32): reward added, quest item removed, `BAG_UPDATE_DELAYED` (no args) fires before and after the money, so diff after the last event of a burst | money delta while quest frame was open | Q1 done |
| Mail money / items | `MAIL_INBOX_UPDATE` (payloadless, E-28); headers readable while the mailbox is open (E-29); `MAIL_SHOW/CLOSED`, `TakeInboxMoney` hook | VERIFIED except MAIL_CLOSED: update event and header fields proven (E-28, E-29); sold-auction invoice readable before the take (E-34: price, deposit, cut; deposit is a refund, not income; mail and invoice vanish after the take); `MAIL_CLOSED` NOT delivered in two closes (E-34), use `MailFrame:IsShown()` polling | money delta with mail context; ledger classification by sender/subject/invoice | X1, X2 done |
| Trade gold | `TRADE_SHOW`, `TRADE_CLOSED` (fires twice per close), `TRADE_ACCEPT_UPDATE(player,target)`, `TRADE_MONEY_CHANGED` | VERIFIED (E-31): window open/close and accept flags readable; PLAYER_MONEY follows TRADE_CLOSED by about 0.4 s; helper's accept not seen; `GetPlayerTradeMoney/GetTargetTradeMoney` and the item side not probed | money delta with trade context (context must outlive the close by at least 1 s) | R1 |
| Gather / fish action | `UNIT_SPELLCAST_SUCCEEDED` (player) | VERIFIED (E-23): no popup; player casts readable even in combat; other units' casts secret in combat; spell ids 2366 herb, 2575 mining, 8617 skinning, 7731 fishing seen | loot source GameObject; manual activity | C1 done |
| Kill proxy | XP event, creature loot source | DROPPED (D-066, X-A): XP kill proxy not used; creature loot source is verified (E-18..E-20) | combat state only (low confidence) | G1, G2 |
| Combat state | `PLAYER_REGEN_*` | PROVEN | none needed | done |
| Position | `C_Map` | PROVEN (city, open world E-17); instance: map and position are NIL inside by design, entry and exit verified (E-27); `IsInInstance`/`GetInstanceInfo` verified | none | S1 done |
| Item sell price / bind type | `GetItemInfo` (full tuple) | VERIFIED for cached items only (E-17): uncached items return nothing; `GetItemInfoInstant` always works but has no price or bind type; async completion VERIFIED (E-30): `C_Item.RequestLoadItemDataByID` then `GET_ITEM_INFO_RECEIVED(itemID, success)`; no event for already-cached items; success false = invalid id | value 0 + flagged "unknown" (D-046); request load and retry later | I1, I1b done |
| AFK flag | `UnitIsAFK("player")` polled | VERIFIED (E-17): true after `/afk`; flags event name valid, delivery not needed if polling | movement + signal-of-life only | A1 done |
| Taxi flag | `UnitOnTaxi("player")` polled | VERIFIED (E-17, E-18): true for the whole ride, false on the first sample after landing; speed 30.3 vs 7; no loading gap on a ride; `IsMounted` also true | speed + position | T1a done; T1b optional |
| Hearth / teleport jump | map id change plus sample gap | VERIFIED (E-17): nil map, one bogus continent-level sample, 2.4 s gap, then new map | treat any loading screen as a break | T4 done for hearth; boat/zeppelin pending |
| Place names for hotspots | `C_Map.GetMapInfoAtPosition` | FAILED for subzones (zone only, E-17); `GetSubZoneText()` works at the player's position | record the subzone text seen when a bin is credited | H1 done |
| Bag snapshot | `C_Container.GetContainerItemInfo` | VERIFIED (E-17): non-secret, 0.74 ms for 44 slots; `hasNoValue` flag available | none needed | I2 done |
| Combat log | `COMBAT_LOG_EVENT_UNFILTERED` | NEVER REGISTERED | not used (D-030) | none |

### 8.3 Verification order (each step is one event, one session, fully reported)

Registering an event is the dangerous act (the earlier popup). Rules: one event per session; use the existing `/gidiag reg NAME` with its ADDON_ACTION_FORBIDDEN watcher; record the popup text and the `IsEventRegistered` answer; add the result to Compatibility_Notes.

- **Stage A, low risk, high value:** `LOOT_OPENED`, `LOOT_SLOT_CLEARED`, `MERCHANT_SHOW`, `MERCHANT_CLOSED`, `QUEST_TURNED_IN`.
- **Stage B:** `MAIL_SHOW`, `MAIL_CLOSED`, `MAIL_INBOX_UPDATE`, `TRADE_SHOW`, `TRADE_CLOSED`, `TRADE_MONEY_CHANGED`, `TRADE_ACCEPT_UPDATE`.
- **Stage C, highest suspicion:** `UNIT_SPELLCAST_SUCCEEDED` (tried as a unit-filtered registration if the client offers one), `CHAT_MSG_MONEY` only if the loot window route fails (it is not required by this plan).
- **Never:** `COMBAT_LOG_EVENT_UNFILTERED`.
- After each registration, a behaviour test (what does the payload contain, is anything secret): L1 (loot gold ordering vs `PLAYER_MONEY`), L2 (items in the window), L3 (source GUID), M1, Q1, X1, R1, C1, G1, G2, I1, I2 (stack quantity), A1, S1 (position in the open world and in an instance).
- Nothing in this list is code for the collectors: they extend the diagnostics addon only and would be a separate small approval ("Phase 3a", section 10).

### 8.4 Decision proposed

- **D-050 (Proposed): Signal selection by verification, not by name.** A collector is written only for a signal whose experiment passed; each experiment's result is a ledger entry (E-17...).

## 9. Risks specific to Phase 3

| ID | Risk | Mitigation in this plan |
|---|---|---|
| R-01 | Needed events restricted | verification before code (8.3); fallbacks in 8.2 |
| R-02 | No combat log | GRIND redesign (6.3), manual override |
| R-03 | Secret values in combat/loot payloads | IsSecret guards; degrade to OTHER with a diagnostic |
| R-23 | Stage mistaken for dependable | selection criterion (1) in 8.1 |
| R-27 (new, proposed) | Item data arrives late or never, valuations silently zero | `pendingInfo` window and visible `unknown` count (4.3) |
| R-28 (new, proposed) | One lucky drop paints a false hot spot | top-single-drop disclosure and optional cap (5.5) |
| R-29 (new, proposed) | Idle heuristics mislabel legitimate waiting | per-activity exemption option (Q-AFK-1), manual pause |
| R-30 (new, proposed) | Inventory diff misattributes items (loot vs purchase vs mail) | context stamping and the bag diff used only at defined boundaries |

## 10. Proposed work breakdown (NOT approved)

- **Phase 3a: Signal verification (diagnostics only).** Extend GoldIntelDiag with the experiments in 8.3, run them in the real client, record E-17 onward. No change to the addon's data model. Output: a filled signal matrix.
- **Phase 3b: Collect (the current TODO Phase 3).** Context state, Expectations/Reconciler, Lots with valuation tiers 1 and 2, collectors only for verified signals. Exit test: invariants 1 and 2 on fixtures; low-confidence share in `/gi diag`.
- Dependent work already planned later: Phase 4 (activity, sessions, idle), Phase 6 (auction observations), Phase 7 (heat bins and overlay).
- Dependency note: heat credit needs a position stamp in every Phase 3b entry, and activity needs the loot source. Phase 3b entry format therefore reserves `loc`, `locConf`, `act`, `actConf` from the start (Contracts already has `loc`).

## 11. Traceability

| Topic | Requirements | Architecture |
|---|---|---|
| Value attribution | FR-LED-1..5, FR-MET-1..5, section 5 | 6, 7 |
| Loot valuation | FR-AH-1, FR-AH-3, FR-LED-2 | 7.2, 9 |
| Location credit | FR-HEA-1..4, DR-3 | 8 |
| Activity detection | FR-SES-1, FR-SRC-1..8 | 7.4 |
| AFK | FR-SES-3, FR-SES-4 | 7.4 (idle), 7.5 |
| Collector signals | FR-PLT-2, NFR-3 | 5, 11 |

## 12. Documents to amend if the user approves (proposed, none applied)

Architecture 5.1 (event table: mark proven and unverified signals), 7.4 (GRIND redesign, AFK rules), 8 (value credited, top-drop disclosure), 9 (tiers and flags); Contracts (entry fields `locConf`, `actConf`, lot `flags`, `pendingInfo`); Requirements unchanged (no requirement changes proposed).

## 13. Gate checklist before ANY Phase 3 implementation

1. User approves Phase 3a and/or Phase 3b explicitly (new decision).
2. OI-8: restriction model understood; the matrix in 8.2 has no UNVERIFIED row that a collector depends on.
3. X-2: decide D-027 (legacy adapter removal) and D-028 (interface policy).
4. PX-1 to PX-8 triaged (Phase2_Closure_Recommendation.md).
5. Decisions D-043 to D-050 accepted, rejected or amended by the user.
6. CPU/memory measurement plan (E7) agreed, since collectors add per-event work.

## 14. Decisions the user is asked to make about this package

1. D-043 to D-050 (sections 3.5, 4.5, 5.5, 6.6, 7.5, 8.4): accept / amend / reject each.
2. Q-AFK-1, Q-AFK-2, Q-AFK-3 (7.4).
3. Whether a Phase 3a (verification only) is the right first step, and if so authorize it separately.
4. Approve the Architecture 8 wording amendment (5.4).
