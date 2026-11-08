# Phase 4 P4-M2 plan: live aggregation wired in (PLAN ONLY)

DATE: 2026-11-08  |  SESSION: S-062  |  STATUS: PLAN for the user's approval. No code. P4-M2 is NOT authorized.
Builds on: Phase4_Live_Aggregation_Proposal.md (answered, D-099), the P4-M1 pure modules (PR #7, not merged),
the M4 measurements (Phase3b_3b-3_M4_Report.md section 4) and D-100 (0.5.6).

## 0. What I am treating as approved (please confirm or correct)

Quoted from the user's messages; the Q texts are the questions of the proposal, section 9.

| Item | What it means in this plan | Where you gave it (quote) |
|---|---|---|
| Q-1 | Cell key place x activity x 5-level bracket, with item counts per cell | 2026-11-07: "Q-1 yes" |
| Q-2 | Heat seconds for every visited 32 x 32 cell, not only cells with credit | 2026-11-07: "Q-2 yes (every visited cell)" |
| Q-3 | Mixed activities: time split by the current activity; the place shows its total once | 2026-11-07: "Q-3 split time by current activity" |
| Q-4 | Back-fill launch-week value and item counts from the raw records, without time | 2026-11-07: "Q-4 yes (back-fill value without time)" |
| Q-5 | Lower the raw caps again after Phase 4 is validated. **Only the principle**: the example numbers in the proposal (2,000 entries, 1,500 lots) are NOT treated as approved; they come back to you at validation | 2026-11-07: "Q-5 yes after validation" |
| Q-6 | A /reload reminder every 60 minutes, one chat line, only outside combat. I treat "outside combat" as the only condition (not instances, not groups) | 2026-11-07: "Q-6 yes (60-minute /reload reminder, one chat line, outside combat)" |
| Q-7 | Budget at most +0.05 ms per frame on average and +0.2 MB per hour of lasting memory growth over the baseline. **To confirm:** D-099 says "over the 0.5.5 baseline"; I propose the 0.5.6 CPU samples as the baseline, because the 0.5.5 figures include the measurement freeze removed by D-100 | 2026-11-07: "Q-7 yes" |
| P4-M1 | Pure modules and tests, no live change: built. **Merging PR #7 is NOT approved yet**; P4-M2 builds on it | 2026-11-07: "P4-M1 (pure modules and tests, no change to live behavior) is authorized now." |
| P4-M2 gate | Two conditions: (1) the 0.5.5 hour-of-play measurements, MET by the 2026-11-08 upload (sessions of 111 and 70 minutes); (2) your approval, PENDING | 2026-11-07: "P4-M2 waits for the 0.5.5 hour-of-play measurements and my approval." |
| 0.5.6 | Approved and built (CPU-only automatic samples) | 2026-11-08: "0.5.6 is approved: remove the automatic memory reading, keep the automatic CPU samples, and read memory only on /gi perf." |
| No other build or merge | Nothing beyond 0.5.6 is merged or built before you approve | 2026-11-08: "Do not merge or start any build beyond 0.5.6 until I approve." |
| 3b-3 closure | Not decided; you decide after reading the recommendation | 2026-11-08: "Write the 3b-3 closure recommendation with the M4 results added. I decide after reading it." |
| Earlier, still in force | M4 authorized (D-097: "start M4"); retention stopgap (D-098: "Approve R-1, R-2 and R-3 as a stopgap") | 2026-11-07 |

Not approved and not assumed: Phase 4 beyond P4-M2, 3b-4, Phases 5 to 9, the lower cap numbers, any change to Requirements_v1.

## 1. Goal

Run the P4-M1 Clock and Aggregator in the live client. Every cash entry, every value-created lot and every active slice
of time reaches the per-place, per-activity totals and the heat bins while you play. The totals are saved with every
`/reload`, logout and disconnect, and checked to 0 copper like the ledger.

## 2. What gets wired (files)

| Piece | Where | Notes |
|---|---|---|
| Live wiring | new `Aggregate/Live.lua` (in the TOC, after Ledger) | Owns one Clock and one Aggregator per interval; starts with the ledger interval (auto start), ends with it |
| Clock ticks | P_TICK (0.5 s, already running) | position from the tick; `taxi` from the player-on-taxi read (verified in Phase 3a); `inWorld` from Platform; level from Platform.Player() |
| Signals of life | P_MONEY, P_LOOT_OPEN, P_CAST, P_COMBAT, CONTEXT_CHANGED, P_ZONE, P_LEVEL, P_QUEST_DONE | listeners only enqueue |
| Productive events | cash entries with src loot (activity from the stamp), value-created lots (activity from the origin), gathering casts | |
| Cash into the aggregates | a second consumer on the ledger sink (Ledger.lua already stores every finished entry) | read-only on the entry |
| Lots into the aggregates | a hook after a lot is created in LotBook | only `vc` lots; AC-15 untouched (nothing writes cash) |
| 2 s aggregation task | `P.Every(2, Drain)` | Architecture 13 |
| Map size for soft travel | `Platform/Map.lua`: a yards distance from the client's map world size, plus probe capability `map.worldsize` | read-only; if missing, soft travel stays undecided and is counted (`travelUnknown`), never guessed |
| Manual controls | `/gi pause`, `/gi resume`, `/gi afk`, `/gi activity <key>` and `/gi activity clear` | required by FR-SES-4 and D-055; they only change the time class or the activity of new slices |
| Reminder (Q-6) | `Aggregate/Live.lua` | one chat line when 60 minutes have passed since the last load, only outside combat, at most once per 60 minutes: "GoldIntel: 60 minutes since your data was last saved; /reload saves it". Setting `reminder.reloadMinutes` (default 60; 0 = off) |
| Commands | `/gi agg status`, `/gi agg check`, `/gi agg top [n]` | check prints the difference in copper (must be 0) and the time sum |
| Trace | `EVT agg` (check line, every 10 minutes and at the end); `EVT clock` (seconds per class, soft-travel speed buckets for tuning the 8 yards per second assumption) | kept lines |
| Back-fill | once per character, at the first start on this build | value and item counts without time (Q-4); completeness recorded |

## 3. Saved data

As Contracts F22, inside schema 2 (additive, lazy): `GoldIntelDB.agg[charKey]` and `GoldIntelDB.heat[charKey]` (both keys are
reserved and empty in every file today), plus for the check `since` (unix), `ledgerAtSince` (the ledger cumulative at that
moment) and `createdAtSince` (the lot book's created value). Rollback: 0.5.6 ignores both tables (to be tested). Estimated
size 100 to 200 KB per character (proposal section 4).

## 4. Acceptance (checked in P4-M3, in normal play)

1. `/gi agg check`, periodic and at the end of each interval: cash difference 0 copper; value-created difference 0.
2. Active + idle + travel + paused seconds equal logged-in seconds (within one tick per interval).
3. CPU and memory within the Q-7 budget against the baseline, from the same automatic CPU samples.
4. No Lua error, no popup, no quarantine; the ledger check stays 0.
5. The file size is within the estimate.

## 5. Tests planned (before any live use)

- Wiring tests in the fake client, covering:
  - ticks, taxi, loading screens, combat;
  - the reminder: outside combat only, once per hour, the setting at 0;
  - commands and pause/afk.
- Replays of the recorded live traces through the wiring: the totals must equal the ledger and the lot book exactly.
- Back-fill on a synthetic file with the real shapes. Real character data stays out of the repository, which is private, and the privacy scrub is still open.
- Cash isolation: the ledger entries are identical with the aggregation on and off.
- Mutation checks for the wiring, the check and the reminder.
- Rollback: 0.5.6 runs on a file that holds agg/heat.

## 6. Package and install

Version 0.6.0-passive. **Full client restart** (new files in the TOC). Rollback: install 0.5.6 and restart; the aggregates
stay in the file untouched.

## 7. Risks

- **The 0.5 s tick gains work.** The estimate is under 0.01 ms per frame; it is measured, not assumed.
- **The soft-travel minimum speed (8 yards per second) is an assumption.** It is tuned from the recorded speed buckets before P4-M3 closes.
- **The map world size may be missing in Forever.** Soft travel is then undecided and counted, never guessed.
- **Instances have no map ID.** The time and value inside are kept per instance name, but no heat bins are drawn until Phase 7 (D-060).
- **A crash loses everything since the last save** (proposal section 8). The reminder lowers that risk.
- **The reminder might feel noisy.** It is one line per hour at most, and can be switched off.

## 8. What you do in P4-M3

Play normally and upload as usual. No test script is needed. It helps if the data happens to include a flight, a few
minutes AFK and a dungeon.

## 9. Decisions for the P4-M2 approval

1. Confirm or correct section 0 (in particular the Q-5 reading, the Q-6 reading and the Q-7 baseline).
2. Approve merging PR #7 (P4-M1) as the base of P4-M2.
3. Include the manual controls (`/gi pause`, `/gi resume`, `/gi afk`, `/gi activity`) in P4-M2, as planned here.
4. The reminder text and setting as in section 2.
5. Approve P4-M2 (build 0.6.0-passive on a branch, tests, a pull request; install only after you approve that build).
