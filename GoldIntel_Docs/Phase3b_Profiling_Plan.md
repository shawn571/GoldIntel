# GoldIntel Phase 3b Profiling and Reporting Plan

DOC VERSION: 1.0.0  |  DATE: 2026-10-18  |  AUTHOR: Claude (S-039)  |  STATUS: APPROVED as a plan by D-072 (items 3 and 4). Implemented in increments 3b-1 (counters) and 3b-4 (live measurement). Closes PX-7 when done.

## 1. Purpose

Show that the collectors stay inside the Architecture 13 budgets (average under 0.5 ms per frame, under 2 MB memory growth per hour) and report how much money the ledger could not explain.

## 2. Measurements

| Measure | How | Target | When |
|---|---|---|---|
| Average ms per frame with collectors on versus off | `C_AddOnProfiler` (if present) sampled over 5 minutes of the same scripted play, collectors toggled with `/gi collect on|off` | on minus off under 0.5 ms | 3b-4 live session |
| Memory growth per hour | `GetAddOnMemoryUsage` (or `collectgarbage("count")` delta) at start and end of the free-play hour | under 2 MB per hour | 3b-4 |
| Handler cost | Fake-clock test: each handler's work per event, bounded record count (enqueue only, Architecture 5.3) | no handler allocates beyond its event record | every increment, automated |
| UNIT_SPELLCAST_SUCCEEDED volume | Counter of events received, events dropped by the first-line unit check, events kept | kept events are player casts only | 3b-1 and 3b-4 |
| Ledger size | Bytes per serialized `CashEntry` and `Lot` measured on real entries | sets retention (D-072 item 1) | end of 3b-2 |
| SavedVariables total size | `/gi db` | under the 2 MB prune budget (Architecture 13) with the chosen retention | 3b-2, 3b-4 |

If `C_AddOnProfiler` is absent in this client, the plan falls back to `debugprofilestop` timing inside the handlers and the drain loop (cheap counters, no per-frame cost when off).

## 3. OTHER reporting (D-072 item 4)

`/gi diag` prints, for the session and for the last 24 hours:

1. **OTHER share of value (the headline figure, D-072)**: sum of absolute copper in OTHER divided by sum of absolute copper in all entries.
2. OTHER share of entries: count of OTHER entries divided by all entries.
3. The largest single OTHER entry (copper, time, context that was open, location).
4. The count of OTHER entries above a size threshold (default 1 gold), because a few high-value unexplained entries matter more than many tiny ones.

Both figures appear together on the first lines of the report, value first. Starting target: 2% on each of 1 and 2 for scripted play with verified sources. A miss is reported with the entries that caused it, not hidden. The target is a starting value and can be changed by the user.

## 4. What this plan does not do

It does not add a UI, does not change ledger rules, and does not run unless the collectors are enabled. GoldIntelDiag is disabled during the live validation sessions (D-072 item 2) so its event registrations do not confuse the counts.
