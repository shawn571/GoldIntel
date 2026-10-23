# GoldIntel Requirements v1

DOC VERSION: 1.1.0  |  DATE: 2026-10-17  |  STATUS: FROZEN (changes only by explicit user decision, recorded in Decisions.md). Amendments in section 10.

> Requirements_v1.md wins over all implementation decisions. Requirements below are derived strictly from the project charter dated 2026-10-09. Anything not in the charter is in section 9 as an ASSUMPTION, not a requirement.

## 1. Scope

### In scope for v1

Session tracking; wealth tracking; cash tracking; grinding; gathering; fishing; vendor sales; auction house sales; direct trades; COD mail; quest rewards; heatmaps; rankings; auction profitability; zone and subzone analytics.

### Deferred (NOT in v1; do not implement)

Community synchronization; cross-player databases; guild sharing; route detection; world-scale route optimization; machine-learning recommendations.

### Architecture placeholders only (stubs, no behavior)

- **CommunityDataEngine**: Import, Export, Database merge, Guild sync, Addon channel sync.
- **RouteEngine**: Route recording, Route analysis, Route discovery, Route ranking.

## 2. Functional requirements

IDs are stable. Tests reference them.

### Sessions

- FR-SES-1: Record sessions made of segments. A new segment starts on zone change, subzone change, activity change, level-up, or profession change.
- FR-SES-2: Each segment stores character level, class, professions, zone, subzone, activity type, cash income, cash expenses, wealth values, and active duration.
- FR-SES-3: Active duration excludes idle time and paused time.
- FR-SES-4: Sessions can be started, paused, resumed, and stopped manually; they also start and stop automatically (configurable).

### Cash and wealth tracking (correctness core)

- FR-LED-1: Maintain a **cash ledger** of every copper change. For any time window, the sum of tagged cash entries equals the actual money delta (no gap, no overlap).
- FR-LED-2: Maintain an **asset ledger** of item lots with acquire-time valuation and origin (provenance).
- FR-LED-3: Never double-count gold. Selling or buying an item is a conversion between ledgers, not new income.
- FR-LED-4: Delayed income received by mail (AH proceeds, COD, mailed payments) is recorded as settlement and kept separate from active-session GPH by default.
- FR-LED-5: Money changes that cannot be attributed are recorded as OTHER with low confidence and are counted in a visible diagnostics statistic.

### Income sources (v1)

- FR-SRC-1 Grinding (mob kills and their loot gold and items)
- FR-SRC-2 Gathering (herbs, ore, skinning and their loot)
- FR-SRC-3 Fishing
- FR-SRC-4 Vendor sales
- FR-SRC-5 Auction House sales (including listing deposits and cut as expenses)
- FR-SRC-6 Direct trades (gold in and out)
- FR-SRC-7 COD mail (both received and paid)
- FR-SRC-8 Quest rewards (gold and items)

### Metrics

- FR-MET-1: Compute Cash GPH, Wealth GPH, Net GPH per segment, session, zone, subzone, activity (definitions in section 5).
- FR-MET-2: **Cash GPH is always visible** in every view that shows any GPH.
- FR-MET-3: Compute experimental normalization metrics, clearly labeled **experimental**.
- FR-MET-4: Aggregate by duration-weighted sums only, never by averaging per-segment rates.
- FR-MET-5: Every displayed metric must be explainable: the UI offers a breakdown of income, expenses, conversions, and the time base used.

### Rankings

- FR-RNK-1: Rank zones.
- FR-RNK-2: Rank subzones.
- FR-RNK-3: Activity-specific rankings (filter by activity).
- FR-RNK-4: Rankings show sample size (active time) and a confidence indicator; places with less than the configured minimum active time are hidden or flagged.

### Heatmaps

- FR-HEA-1: Zone heatmap overlay on the map.
- FR-HEA-2: Hover tooltip with metric value, time spent, and sample size.
- FR-HEA-3: Activity filters.
- FR-HEA-4: Heatmap metrics are selectable among the approved metrics.

### Auction profitability

- FR-AH-1: Value items using a provider chain of price sources; never assume any single source exists.
- FR-AH-2: Model deposit, auction cut, and failed-auction risk to compute expected net per listing.
- FR-AH-3: Show estimate confidence and price staleness.

### Platform

- FR-PLT-1: All WoW API access lives under `Platform/`. No other module calls WoW globals.
- FR-PLT-2: Probe capabilities at startup; disable only the affected feature when a capability is missing and say why in the UI.
- FR-PLT-3: Key characters by GUID (the game is realmless).

### Future placeholders

- FR-FUT-1: `CommunityDataEngine` and `RouteEngine` exist as stub modules that register with Core and return a documented NOT_IMPLEMENTED result. No other behavior.

## 3. Non-functional requirements

- NFR-1 Correctness over convenience; every ledger invariant has an automated test.
- NFR-2 Testability: Core, Collect (logic), Engines, Store logic run in plain Lua 5.1 outside the client.
- NFR-3 Performance (targets, to be measured): event handlers allocate minimal garbage and only enqueue; average addon CPU under 0.5 ms per frame during play; memory growth under 2 MB per hour of play; heatmap rebuild only on map change or filter change.
- NFR-4 Durability: documented that SavedVariables write only on logout or reload; checkpoint prompt available; storage caps with automatic rollup.
- NFR-5 Maintainability by another AI: comments, contracts, no hidden state.
- NFR-6 Transparency: calculations documented in Architecture.md and visible in-UI.
- NFR-7 Extensibility: versioned schema with migrations; activity keys for deferred activities are reserved in the enum but have no detection logic in v1.

## 4. Data requirements

- DR-1: Persist per session and segment the fields in FR-SES-2.
- DR-2: Persist rolling aggregates for zones and subzones so rankings do not require scanning raw segments.
- DR-3: Persist heat bins sparsely.
- DR-4: Every persisted record type carries a schema version.
- DR-5: Subzone identity stores the localized text together with the client locale (assumption A-4).

## 5. Metric definitions (normative)

Let `h` = active hours in the window. All amounts in copper. Settlement entries are excluded from windows by default and reported separately as "Settled".

- **Cash in / Cash out:** sums of positive / negative cash ledger entries, excluding settlements. Includes conversions (a vendor sale is cash in).
- **Cash GPH** = (Cash in - Cash out) / h.
- **Value created** = new gold received (loot, quests, trade gold received for services) + valuation of items **acquired without paying** (loot, quest, gathered, fished). Excludes conversions and purchased items.
- **Wealth GPH** = Value created / h. (Gross value creation, before expenses.)
- **Expenses** = cash out tagged as an expense (repairs, deposits, material purchases consumed, COD paid, etc.). Purchases that create a held lot are conversions, and become an expense only if the lot is consumed or lost.
- **Net GPH** = (Value created - Expenses) / h.
- **Normalized (experimental)** = Net GPH / median Net GPH for the same 5-level bracket (own history), shown only after the configured minimum hours exist in the bracket. Always labeled experimental.

Open: these formulas refine the charter's metric names, which the charter does not define. See Decisions D-012 and OI-2; confirm with the user.

## 6. Acceptance criteria (v1 release)

1. Ledger invariants (FR-LED-1..5) pass automated tests on recorded event fixtures, including mixed vendor, quest, mail, and trade streams.
2. A 30-minute test session (grind + vendor) yields Cash GPH matching a manual calculation within 1 percent, and no loot item is counted both as value created and as new income when sold.
3. Zone and subzone rankings reproduce hand-computed values on fixtures.
4. Heatmap shows only location-attributable income (see Architecture section 8).
5. With any single capability disabled, the addon loads and every other feature works.
6. No WoW API call exists outside `Platform/` (enforced by a static grep test).
7. All contracts in Contracts.md are implemented or explicitly stubbed.

## 7. Out of scope reminders

No syncing, no guild features, no route logic, no machine-learning recommendations, no networking of any kind.

## 8. Traceability

Every FR maps to at least one module in Architecture.md section 4 and one test in TODO.md. Module-to-FR table is in Architecture.md section 4.

## 9. Assumptions (NOT requirements; status updated 2026-10-09)

Status: A-1, A-2, A-5 CONFIRMED by user (OI-4, "Deferrals approved as written"). A-3 CONFIRMED as part of OI-2 ("Approved as written"; metric definitions and normalization in section 5). A-6 CONFIRMED by user (OI-3; see Decisions D-021). A-4 NOT yet confirmed.

- A-1: Features that were in earlier drafts but not in the charter's v1 list (dungeon farms, rare farms, boosting, disenchanting, vendor arbitrage, crafting profit, mage / warlock / enchanting services, craft profitability ranking, world heatmap) are deferred. Their activity keys are reserved in the enum; manual activity tags may exist but no auto-detection. Confirm.
- A-2: "Heatmaps" in v1 means a zone heatmap (FR-HEA-1). World-level heatmap is deferred. Confirm.
- A-3: Normalization uses percentile and bracket from own history. Confirm.
- A-4: Subzone keys use localized text plus locale because no stable subzone ID is known to exist in Forever.
- A-5: Auction profitability in v1 covers listing and sale economics (deposit, cut, failure risk, expected net) for items the player holds; recipe-based craft ranking is deferred (A-1).
- A-6: Ace3 and HereBeDragons are optional dependencies, pending verification in the Forever client.

## 10. Amendments (explicit user decisions of 2026-10-17; they refine, they do not remove)

- **AM-1 Heatmap is location-level (D-052).** FR-HEA-1 means an overlay drawn ON the map that shows density by coordinates. It never colors a whole zone because money was made somewhere inside it. Assumption A-2 is amended accordingly: v1 heatmaps are location-level density maps drawn on a zone's map; a world-level map stays deferred. Nearby areas cool gradually away from a productive location. The user generally agrees with 32 x 32 bins, coordinate-based attribution, value per active hour and minimum sample thresholds. Example target: "Lake Nazferiti, about 38.0, 3.3, 20 gph, red; Kurzen Compound, 10 gph, yellow."
- **AM-2 Overlay toggle (D-052).** FR-HEA-6: the overlay can be switched on and off easily (so the user can use Gatherer, Questie or other map addons without GoldIntel hiding information).
- **AM-3 Idle exclusion (D-049 clarified).** FR-SES-3 applies everywhere: idle time is excluded from all GPH calculations (Cash, Wealth, Net; segment, session, zone, subzone, activity) and from map heat. Waiting for a node respawn counts as idle after the timeout; fishing does not, because casts are activity.
- **AM-4 Travel (D-054, direction only).** Taxi travel time is not productive time. Long-distance travel must not dilute hotspot accuracy. The model is NOT decided: see Travel_Model_Options.md.
- **AM-7 Travel (D-054, model chosen).** Option B: taxi, loading-screen and teleport time are non-productive; soft travel (fast, far from the last productive spot, no productive event for the dry window) is excluded from bin seconds and, by default, from GPH (`travel.countInGph` = false). Gathering routes and camp-to-camp movement while grinding remain productive. `TRAVEL` is an activity type. Starting values: dry window 60 s, stay-near about 150 yards (tunable).
- **AM-8 Colour scale and hotspots (D-057, D-058).** FR-HEA-8: the default colour scale is relative to the best well-sampled locations on the map; a fixed-threshold option follows in Settings. FR-HEA-7: a ranked hotspot list shows coordinates, place name if available, activity, GPH, active hours and sample count/confidence.
- **AM-9 Overlay commands (D-059).** `/gi overlay on|off|toggle`; the settings window exposes the same.
- **AM-10 Instances as runs (D-060).** An instance is one location unit at its world-map entrance; value and time are accounted per run. Default statistics are per run; full-cycle statistics (including reset and re-entry time) are an optional setting. Remaining details follow Phase 3a evidence.
- **AM-11 Heat scope (D-061).** FR-HEA-9: a toggle between account best (highest observed GPH per location across all characters, with the responsible character and activity shown on hover) and this character. Never an average across characters. Default view is the character's own heat map; Account Best is optional (toggle).
- **AM-12 Value views (D-063).** Historical observations are never replaced by current prices. Verified Value (what happened), Current Market Value (what it would be worth now, dated) and Account Best (best verified result across characters) are separate views. Default is Verified Value. Direction only; no implementation before Phase 3b approval.
- **AM-13 Attribution (D-064).** Economic Attribution (source of value) and Location Attribution (where value-generating activity occurred) are separate. Quest rewards stay in the economic records and stay out of location heat maps.
- **AM-5 Manual control (D-055).** FR-SES-4 is realized at least as `/gi pause`, `/gi resume` and `/gi afk`. Manual control must always exist.
- **AM-6 Graphical configuration (D-053).** FR-UI-1: the primary configuration experience is a normal addon options window. Slash commands remain for diagnostics and power users. Product direction for Phase 8; nothing is implemented yet.
- **AM-14 Multi-activity locations (D-082, user 2026-10-19).** Skinning is GATHER. A location may show several activities at once; the hover lists them with the combined GPH. Time counts once.
- **AM-15 Account Best and weaker characters (D-082).** Account Best is the highest observed GPH per location, never an average; the hover names character, level and activities. No usable-by-character filter and no power measure beyond level are required.
- **AM-17 Metrics revised (D-082 addendum, user 2026-10-19 20:17).** Net GPH is removed; repairs and consumables are not tracked in any GPH view. Cash GPH = cash income per hour (inflows only). The headline metric is value created per active hour. The heat map recomputes item values from the current price data (dated) and shows Verified next to Current. Section 5 definitions of Net GPH and Expenses are superseded by this amendment (kept above for history). AH profit keeps deposit, cut and failed-auction risk as costs.
- **AM-16 Value basis and heat basis (D-082; superseded in part by AM-17; manual price meaning pending).** Default item value is the higher of vendor price and AH price net of the AH cut. Heat and Account Best use gross value created per active hour; repairs, consumables, taxi, training and similar are excluded there and appear only in the personal Net view.
