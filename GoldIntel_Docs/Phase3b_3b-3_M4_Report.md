# Phase 3b-3 M4: measurements and closure inputs (interim)

DATE: 2026-11-07  |  SESSION: S-060  |  AUTHORIZED: user 2026-11-07 ("start M4", D-097)  |  STATUS: sizes measured; retention R-1..R-3 APPROVED as a stopgap (D-098, built in 0.5.5); CPU and memory waiting for live data

M4 scope (Phase3b_Increment_3b-3_Scope_and_Readiness.md): measurements of lot size, CPU and memory, then the 3b-3 closure recommendation. The evidence list for 3b-3 is complete (skinning, roll wins, silver wording, trade, groups of 3 to 5, dungeon, disconnect, client patch).

## 1. Sizes (measured from the user's files of 2026-11-07, build 0.5.3)

| What | Measured |
|---|---|
| Account file (GoldIntel.lua, all characters) | 1,363,925 bytes |
| of which lots | 715,355 bytes (main character 582,340: 1,156 open lots, about 370 bytes each, plus 300 closed and 300 conversions) |
| of which cash ledger | 391,097 bytes (main character 330,273: 1,663 entries, about 195 bytes each) |
| everything else | about 22 KB (runtime records, probe report) |
| Character file (trace) | 369,663 bytes on the main character: 3,000 trace lines (340 KB) and 400 kept lines (44 KB) |

Growth on the main character (2026-11-06 18:32 to 2026-11-07 21:52, 17.2 hours logged in, AFK time included): about 36 cash entries and 24 open lots per hour.

## 2. What happens at the caps (code as built)

| Cap | Today | Reached in about | What happens then |
|---|---|---|---|
| Cash `Cash.CAP` 2,000 raw entries per character (user Q-6, 3b-2) | 1,663 | 10 more hours of play | The oldest 500 entries are folded into totals per source. Copper totals stay exact (0-copper rule unchanged) but those entries lose time, location and activity. |
| Open lots `Lots.CAP_OPEN` 1,500 (3b-3 Q-11) | 1,156 | 14 more hours | Lots of the same item, value and kind are merged, oldest first. The merged lot keeps the FIRST lot's location and activity; the others' locations are lost. 1,156 open lots have only 193 distinct merge keys. |
| Trace window 3,000 lines | full | already | The window covers the last ~3 hours only. |
| Trace keep list 400 lines | full | already | 233 of 400 kept lines are "-> unexplained" lines, mostly gear swaps (old item back in the bags). They pushed out evidence: the three 80-silver payments of 2026-11-07 were gone before the upload. |

Why it matters: the heat map and gold-per-hour views (Phases 4, 5 and 7) do not exist yet, so the raw entries and lots are today the only record of WHERE value was made. Folding and merging at the current caps would discard the launch-week locations before any aggregate keeps them.

## 3. Retention decisions (R-1, R-2, R-3 approved by the user 2026-11-07 as a stopgap, D-098, built in 0.5.5)

- **R-1 Cash cap.** Options: (a) keep 2,000; (b) raise to 6,000 (about 1.2 MB per active character) until Phase 4/5 aggregates exist, then fold as planned. Recommendation: (b).
- **R-2 Lot merge.** Options: (a) as built; (b) merge only lots that also share zone, subzone and activity (keeps the location at subzone level, loses exact coordinates), and raise the open cap to 4,000. Recommendation: (b).
- **R-3 Keep list noise.** Copy at most ONE "-> unexplained" line per item id per interval to `trace.keep` (every line stays in the rolling trace). Recommendation: yes.
- **R-4 File size.** With R-1 and R-2 an active character costs about 2.5 MB at the caps; the client loads it at login and writes it at logout or `/reload`. The 0.5.4 memory samples show the in-game cost; if they show a problem, the caps come back to you.

## 4. CPU and memory (0.5.4 measurement build)

Built: `Platform/Perf.lua` reads every metric that `Enum.AddOnProfilerMetric` offers for GoldIntel through `C_AddOnProfiler.GetAddOnMetric`, plus `GetAddOnMemoryUsage` when present (the function names in Forever were never recorded, so nothing is assumed). A sample is stored at interval begin, every 10 minutes and at interval end in `GoldIntelCharDB.perf.samples` (cap 500, apart from the trace) and printed as `EVT perf` lines; `/gi perf` shows the figures now.

Targets (NFR-3): average CPU under 0.5 ms per frame; memory growth under 2 MB per hour of play.

Needed from the user: play normally on 0.5.4, including at least one session of an hour or more, then upload as usual. No test script. The collectors-off comparison of the D-072 profiling plan is optional: the absolute figures against NFR-3 are enough unless they come close to a target.

## 5. Closure recommendation

Waiting for section 4 data and the R-1..R-3 decisions. Planned content: exit criteria of the 3b-3 scope document, the evidence summary (Compatibility_Notes live evidence 2026-11-04 to 2026-11-07), open bug-fix items under the D-079 policy (lag case, unknown small sinks), and what moves to 3b-4 (auction house, COD, outgoing mail and postage, flight fares if approved).
