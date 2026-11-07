# Phase 4 proposal: live aggregation per location and activity

DATE: 2026-11-07  |  SESSION: S-060  |  STATUS: ANSWERED by the user 2026-11-07 (D-099: Q-1..Q-7 yes; Q-2 every visited cell; Q-3 split by current activity; Q-6 60 minutes, one chat line, outside combat). P4-M1 authorized and built (pure, not loaded); P4-M2 waits for the 0.5.5 measurements and the user's approval.
Requested by the user 2026-11-07: live aggregation of gold, time and item counts per location and activity, updated in
memory while playing (the design's 2 s aggregation task and 0.5 s tick), saved with each `/reload` or logout, so that a
retention cap can never erase where gold was earned. This document covers the saved-data change, size and CPU cost, how
the 0.5.4 measurements feed in, how the aggregates later drive the heat map without a reload, and what a crash loses.

Grounding: Requirements FR-SES-1..4, FR-MET-1..5, FR-RNK-1..4, DR-1..DR-5, NFR-3, NFR-4, AM-1, AM-3, AM-7, AM-11,
AM-12, AM-14, AM-15, AM-17; Decisions D-005, D-007, D-008, D-009, D-011, D-044, D-049, D-054, D-055, D-060, D-061,
D-063, D-064, D-082 (part 10: aggregates keep item counts for repricing), D-098 (caps are a stopgap); Architecture
sections 7.4, 7.5, 8, 10, 13; Contracts F5 (the `agg` and `heat` keys are reserved and still empty in every saved file).

## 1. What it fixes

Today the raw cash entries and item lots are the only record of WHERE value was made. Raw records must be capped
(D-098: 6,000 entries, 4,000 open lots per character). Folding and merging at a cap keep copper exact but drop place and
time. Time spent per place is not recorded at all yet, so no gold-per-hour figure exists.

With live aggregates, every copper and every item counted is ALSO added at once to small per-place, per-activity totals
that are never folded. The raw records can then be capped freely (back to a few thousand) because the aggregates already
hold the place, the activity, the time and the item counts. The heat map, rankings and Account Best read the
aggregates, not the raw records.

## 2. Data flow

```
P_TICK (0.5 s, Platform/Map)        -> Clock slice: dt to the CURRENT cell, unless idle or travel (AM-3, AM-7)
Cash entry (Reconciler sink)        -> queue -> 2 s aggregation task -> coin, cash in/out on the entry's cell
Lot created (LotBook, value created)-> queue -> 2 s aggregation task -> value created + item count on the lot's cell
Heat (Phase 7 data, built now)      -> on the same tick: seconds into the 32 x 32 bin of the position; credit from
                                       GRIND / GATHER / FISH entries into the bin of the event position (D-005, D-044)
```

- Handlers only append to a queue (Architecture 13, NFR-3). The 2 s task drains it. The 0.5 s tick already exists;
  it gains one table lookup and a few additions.
- Nothing in the aggregator decides a source or a value. It sums what the ledger and the lot book already decided
  (AC-15 stays: lots never write cash; the aggregator writes neither).
- Exactness: every cash entry is added once, to exactly one cell, so the sum over all cells equals the ledger sum for
  the same period (checked live, section 7).

### 2.1 Keys

| Key | Value | Source |
|---|---|---|
| Place | `mapID:locale:subzone` (D-008); inside an instance, where mapID is nil (live 2026-11-05, Ragefire Chasm), `i:<zone name>` | entry and lot stamps |
| Activity | GRIND, GATHER, FISH, LOOT, QUEST, VENDOR, TRADE, MAIL, TRAINER, AH, OTHER (Contracts F0) | stamps; time by the Activity engine (2.3) |
| Level bracket | `floor((level - 1) / 5)` (D-009, normalization) | the character level at the event |
| Heat bin | `mapID` + `y * 32 + x` (D-011, AM-1) | position at the event or tick |

### 2.2 Cell contents

Per place x activity x bracket: active seconds, looted coin, cash in and out, value created (verified basis at
acquisition, D-063), item counts `{ [itemID] = qty }` of freely acquired items (D-082 part 10, so Current Market Value
can be recomputed later at new prices without the raw lots), event count, first and last time.

### 2.3 Time: what Phase 4 has to build first

Value per place exists today; time does not. Phase 4 needs three small engines before time per place is honest:

1. **Idle** (AM-3, D-049, D-055): no money, loot, cast, combat or movement for `idleSec` (120 s) pauses the clock;
   fishing casts count as activity; `/gi pause`, `/gi resume`, `/gi afk` always work.
2. **Travel** (AM-7, D-054 option B): taxi, loading screens and teleports never count; soft travel (fast movement far
   from the last productive spot with no productive event for 60 s) is excluded by default. Converting map coordinates
   to yards needs a map-size API that is not verified in Forever yet (a probe step in M1).
3. **Current activity**: time goes to the activity of the most recent productive event or gathering cast within the
   last 120 s; a manual `/gi activity` override wins. AM-14: a place shows its total time once and the value per
   activity. How activity-specific rankings split mixed grind-and-skin time is decision Q-3.

Sessions and segments (FR-SES-1, FR-SES-2) come from the same clock: a segment closes on a zone, subzone, activity,
level or profession change. Segments are small and capped; they are a time line, not the store of record.

## 3. Saved-data format

Additive inside schema 2, in the reserved keys, per character (the account file, so Account Best can compare all
characters, D-061). A build that does not know the keys leaves them untouched (rollback stays possible, as with lots).

```lua
GoldIntelDB.agg[charKey] = {
  v = 1, build = string, since = unix,                    -- aggregation start (live play only)
  places = { [placeKey] = { mapID = number?, zone = string, sub = string?, inst = boolean?,
             cells = { [act .. '|' .. bracket] = { s = seconds, coin = copper, cin = copper, cout = copper,
                       vc = copper, q = { [itemID] = qty }, n = count, t0 = unix, t1 = unix } } } },
  totals = { s = seconds, coin, cin, cout, vc },            -- for the live check
  segments = { ... capped ring of recent segments ... },
}
GoldIntelDB.heat[charKey] = { [mapID] = { [binIdx] = { s = seconds, c = credited copper, a = { [act] = copper } } } }
```

- **Back-fill at the first start**: value and item counts from the existing raw entries and lots (they carry place and
  activity) are added once, marked `backfill = true`. Their TIME is unknown (never recorded) and is not guessed, so
  launch-week places get value without gold per hour.
- **Migration**: none required (additive, lazy). A Contracts version and a Decisions entry come with the build.
- **After Phase 4 is validated**: the D-098 stopgap caps can come down again (decision Q-5).

## 4. Size and CPU cost

Measured basis (main character, 2026-11-04 to 2026-11-07, about 3 days, levels 1 to the low 20s): 88 places,
163 place x activity cells, 556 place x activity x item counts over 292 distinct items, 135 credited heat bins.

| Part | Estimate per character | Basis |
|---|---|---|
| Cells (with brackets) | about 15 to 25 KB | 163 cells x about 90 bytes, brackets add up to half again |
| Item counts | about 8 KB | 556 counts x about 14 bytes |
| Heat bins | about 40 to 120 KB | time bins on every visited 32 x 32 cell (credited only 135 so far), about 40 bytes each |
| Segments ring | about 30 KB | capped |
| **Total** | **about 100 to 200 KB** | versus about 1 MB of raw records today; places repeat, so growth slows over time [inferred] |

CPU: the 0.5 s tick adds one lookup and a few additions (about 2 per second); the 2 s task handles about 60 value events
per hour. Estimated well under 0.01 ms per frame [inferred]. The real figure is measured, not assumed (section 5).

## 5. How the 0.5.4 and 0.5.5 measurements feed in

1. **Baseline.** The perf samples now being collected (CPU metrics from C_AddOnProfiler, GoldIntel memory, every 10
   minutes) give the cost of today's addon against NFR-3 (0.5 ms per frame, 2 MB per hour).
2. **Budget.** Phase 4 gets a share of the remaining headroom. Proposal: at most +0.05 ms per frame on average and
   +0.2 MB per hour of memory growth over the baseline.
3. **Same probe.** The Phase 4 build keeps the same sampling, so its live sessions are compared with the baseline in the
   same format. Over budget = the cause is reported and fixed before Phase 4 closes.
4. **Sizes.** The upload sizes measured in M4 give the file-size baseline; Phase 4 must shrink, not grow, the total once
   the caps come down.

## 6. Heat map, rankings and Account Best without a reload

The saved tables ARE the live tables: WoW writes whatever is in memory at logout or `/reload`, so the aggregates need no
separate save step and are always current in memory.

- **Heat map (Phase 7)**: the overlay reads `heat[charKey][mapID]` directly. It rebuilds when the shown map changes,
  when a filter changes, and while the map is open at most every 2 s when bins of that map changed (a changed-flag set
  by the tick), never per frame (Architecture 8). Gold you earn is visible on the open map within about 2 seconds.
- **Account Best (D-061, AM-11)**: other characters' tables are loaded from the account file at login; the current
  character's table is live; the best verified value per location wins, never an average.
- **Rankings (Phase 5)** read the place cells; **Current Market Value (Phase 6)** multiplies the item counts by current
  prices, dated, next to the Verified Value (D-063, AM-12).

## 7. Checks (same discipline as the 0-copper rule)

- `/gi agg check`: the sum of `coin + cin - cout` over all cells since `since` equals the ledger sum over the same
  period (difference must be 0 copper); value created equals the lot book's created value; active seconds plus idle
  plus travel equal logged-in seconds.
- An `EVT agg` line in the periodic check and at interval end, like `EVT check`.
- Tests: invariants on recorded sessions, replay of the live traces, and mutation checks, as for the ledger.

## 8. What a crash loses

WoW writes SavedVariables only at logout, `/reload` and (seen live 2026-11-07) a disconnect. A crash of the client
writes nothing, so EVERYTHING since the last save is lost together: aggregates, cash entries, lots, trace and perf
samples of that stretch of play.

- The money is not lost: the next login sees the balance difference and books it as one login gap (OTHER, no place),
  as today. The place, the time and the items of that stretch are lost.
- Aggregates and ledger can never disagree after a crash, because they are written in the same save or not at all.
- No addon can force a save. Mitigation: an optional reminder to `/reload` after a set time (NFR-4, `/gi checkpoint`),
  for example every 60 minutes outside combat. Decision Q-6.

## 9. Decisions for the user (when reviewing)

- **Q-1** Approve the cell key (place x activity x 5-level bracket) and the item counts per cell.
- **Q-2** Heat time bins for every visited cell (more size, honest gold per hour per bin) versus only bins with credit.
  Recommendation: every visited cell, because time without gold is what makes a spot look poor.
- **Q-3** Mixed activities in one place (grind and skin): show the place total once (AM-14) and, for activity rankings,
  split time by the current activity (recommended) or count the full time for each activity.
- **Q-4** Back-fill launch-week value without time (recommended) or start empty.
- **Q-5** After Phase 4 is validated, lower the raw caps again (for example 2,000 entries and 1,500 lots).
- **Q-6** The optional `/reload` reminder and its interval.
- **Q-7** The CPU and memory budget of section 5.

## 10. Milestones (each needs the user's go-ahead)

1. **P4-M1** pure modules with tests: Aggregator, Idle, Travel, Activity clock; map-size probe for travel distance.
2. **P4-M2** wired live: aggregates stored, `/gi agg status|check|top`, back-fill, perf sampling kept.
3. **P4-M3** live validation in normal play: `/gi agg check` 0 copper, time sums, perf against the budget; then the
   Phase 4 closure recommendation.

Prerequisites: the 3b-3 closure (M4) first. 3b-4 (auction house, COD, outgoing mail) can run before or after Phase 4;
it changes what is booked, not how it is aggregated.
