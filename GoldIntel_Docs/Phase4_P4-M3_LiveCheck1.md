# P4-M3 live check 1: 0.6.0-passive (2026-11-14, session S-072)

STATUS (S-073): the user approved fixes 1 to 4 as proposed (D-115), with option A for Configure; soft travel across
zones NOT now (plan separately); sections 5 and 6 stay PLAN ONLY with the direction: 7-day raw window plus daily
summaries, a separate rule for open lots, a test-mode switch. Built as 0.6.1-passive (D-115). Measured after the fix on
desktop with the same files: 1,999 foreign item replies in one frame 3.8 ms (was about 120 ms); largest 0.5 s step
during the back-fill 3.2 ms including the tick's other work. The EmpireIntel screenshot is still missing.

Files: the account file and the Paladin character file (Player-6796-<main>) attached in this session, plus your notes. Read
only. Times are UTC: your 09:17 is 14:17 UTC. "Measured" means computed from the files or timed on desktop Lua 5.4 with
the real files loaded in the test client. "Inferred" means not proven.

Passed: version, agg status, `agg check` 0 / 0, probe `map.worldsize [ok]`, afk and resume, activity set and clear,
`ledger check` 0 copper over 5,161 s, 0 collector errors, no MISMATCH line.

## 1. The 1,771 ms frame

**Cause (measured):** a flood of item-data replies that GoldIntel did not ask for.
- The collector counted 3,566 `GET_ITEM_INFO_RECEIVED` events this session, up to 1,999 in one second.
- They came in bursts: at least 1,021 lines at +2.9 s after the load (978 earlier lines have rotated out of the trace),
  264 at +9.9 s, then about 91 every 10 s until +2 min.
- They cover 2,526 different items. Only 31 of those are in the Paladin's lots, and none was waiting for a value. So the
  requests came from another add-on. TSM and Auctionator are both installed; which one is not shown in the files.
- GoldIntel handles every such event the same way: one trace line (which shifts the full 3,000-line ring), one item
  lookup, and a scan of the 1,233 open lots.

**Cost on desktop with the real files:**

| Work | Desktop time |
|---|---|
| One item-info event | 0.060 ms (trace line 0.022, open-lot scan 0.036, item lookup 0.004) |
| The 1,999-event second | about 120 ms |
| First-start back-fill (4,708 records, 122 places) | 7.2 ms in total |
| `/gi agg status` | 0.1 ms |

The game's Lua was assumed 5 to 15 times slower than desktop. On that assumption the burst is about 0.6 to 1.8 s,
which is the 1,771 ms frame. The other frame over 100 ms is either the back-fill (about 35 to 110 ms) or the second
burst (about 80 to 240 ms); these files cannot tell them apart. `/gi afk` is negligible. `/gi probe` runs once on
request and was not timed.

**Why 0.5.6 did not show it (inferred):** 0.5.6 has the same item-info handlers. Its 100 to 178 ms /reload frames may be
the same flood with a warm item cache. 0.6.0 needed a full restart, which empties the item cache, so the other add-on
requested many more items.

**Proposed fix:**
1. Pass on item-info events only for items GoldIntel itself asked for. Count the others as "foreign" and do nothing
   else with them.
2. Spread the back-fill over several frames: 500 records per 0.5 s tick, about 10 ticks in all. It works from a snapshot
   taken at the start, so live entries are not counted twice. `/gi agg check` answers "back-fill in progress" until it
   finishes.
3. Optional, small: trim the trace ring in chunks instead of shifting all 3,000 lines for every new line.

Expected result: the flood costs almost nothing. I would measure that on desktop after the change, and in the game in
the next live check.

## 2. Time counted twice

The final line was `active=2438 idle=2103 travelHard=905 travelSoft=64 paused=128 travelUnknown=1203`: 6,841 s over a
5,664 s session.

- `travelUnknown` is not a time class. It counts time spent moving where the distance cannot be measured, and that same
  time is also counted as active, idle or soft travel. Without it the classes add up to 5,638 s.
- The remaining 26 s are loading screens. The 0.5 s tick stops while the player is not in the world, so that time is
  never classified, although the clock's own rule says a loading screen is hard travel.
- Why so much `travelUnknown` although `map.worldsize` works: distance is measured only within one map. After a zone or
  map change, movement relative to the last productive spot (on the other map) counts as unknown. Soft travel is
  therefore never detected across zones.

**Proposed fix:**
1. Five classes that never overlap: active, idle, travelHard (taxi and loading screens), travelSoft, paused.
2. Loading-screen time is taken from the time between ticks and booked as hard travel.
3. `EVT clock final` gains `total=` and `session=`. The moving-without-distance counter moves after them as
   `noDistance=` (part of the classes, not one of them).
4. A test: one session with a taxi, a loading screen, a pause, idle time and productive play, where the class total
   equals the session time to 0.01 s. Plus a deliberate-bug check.

Needs your yes separately: treat a last productive spot on another map as far away, so soft travel works across zones.

## 3. /gi agg top

Today it ranks by total gold, so the back-filled cells with 0 minutes win. Only 43 of 302 cells have recorded time.

**Proposed:**
- Rank by gold per hour among cells with at least 10 minutes of recorded time.
- List back-filled places separately, as "Back-filled (no time recorded)", ranked by gold.
- Add one line counting the places with under 10 minutes.

## 4. Reminder popup

**The reminder did fire.** It was printed at 15:17:33 UTC, 60 minutes after the load at 14:17:11. It appears in the
account file's record of printed lines (`runtime.output`). Chat lines are not traced, which is why it was missing from
the trace.

**Proposed popup:**
- The game's standard popup with three buttons:
  - **Reload Now** calls `C_UI.Reload` (or `ReloadUI`).
  - **Ignore** waits for the next interval.
  - **Configure** opens the settings.
- Never shown in combat or during an encounter. Combat is tracked as now; encounters through `ENCOUNTER_START` and
  `ENCOUNTER_END` (new events, so a full restart) and `IsEncounterInProgress` if the client has it. If combat starts
  while the popup is showing, it is hidden.
- New trace lines `EVT reminder shown` and `EVT reminder reload|ignore|configure`, kept in `trace.keep`.
- **Unverified on Forever:** whether a button click may reload. The probe checks that both functions exist, and the test
  steps include clicking Reload Now. If the reload is refused, the popup tells you to type `/reload`.

**Evidence for the bands** (Paladin, 17 sessions of 30 minutes or more, 42.2 h): per hour about 34 cash entries on
average, 68 at the 90th percentile and 81 at most; about 1.1 g gross moved per hour. A crash loses everything since the
last save. The gold itself is still booked, as one login-gap OTHER entry, but its sources, the place time and the heat
of those minutes are lost.

| Band | Interval | At risk on a crash |
|---|---|---|
| Safe | 15, 30, 45, 60 min | at most 1 h: up to about 80 entries in the busiest hour seen |
| Risky | 90, 120, 180 min | up to 3 h: up to about 240 entries |
| Not Recommended | 240, 360 min | 4 h or more (the 8-hour session of 11-13 would have risked about 270 entries) |
| Off | none | the whole session |

The default stays 60 minutes (D-099 Q-6), the top of Safe. The cost side: each /reload is a loading screen plus a
100 to 178 ms GoldIntel frame.

**Conflict:** "Configure opens the /gi window on its settings tab", but the window is plan-only (item 7).
- A (recommended): a small GoldIntel Settings window now, holding only the reminder slider. It becomes the Settings tab
  when the window is built.
- B: until the window exists, Configure prints the slash command for the setting.

**Version:** these fixes make 0.6.1-passive, contract 1.16.0. Full restart required (new files and new events).

## 5. UI plan (plan only)

- `/gi` opens a main window. Tabs: Opportunities, Map, Settings, and later Sessions.
- **Opportunities:** a table of the best places by gold per hour (place, activity, level bracket, minutes, gold per
  hour), using the same minimum time and the separate back-filled list as in item 3.
- **Selecting a row** opens the Map tab:
  - GoldIntel draws the zone's map art itself in its own frame, from the map's art layers and tiles, so other add-ons'
    pins do not appear.
  - The 32 x 32 heat bins are drawn on top, coloured by gold per hour or time.
  - A details panel shows the cell's totals, activity and time.
- **Settings tab:** the reminder slider (item 4), plus a test-mode switch (item 6).
- The slash commands stay as shortcuts.

**Must be checked in the game first** (a probe build, no other change):
- `C_Map.GetMapArtLayers` and `C_Map.GetMapArtLayerTextures` exist on Forever and return tile textures an add-on can
  load.
- Map IDs and art for dungeons and cities.
- The frame templates exist on this client: a dialog frame, tab buttons, and the scroll list (ScrollBox in 12.0).
- A plain frame opens and closes in combat without errors, and Escape closes it.

**Two open points:**
- EmpireIntel's style: I could not read that repository; attaching it was refused by this session's permission check.
  Please allow it, or attach a screenshot.
- Licences of any map library are to be checked before reuse (D-110). The default is a clean-room implementation.

## 6. File size and retention (plan only)

**(1) Current thresholds, and why folding never ran.**

| Record | Limit |
|---|---|
| Cash ledger | 6,000 raw entries per character; over that, the oldest 500 fold into totals (D-098; was 2,000) |
| Open lots | 4,000; over that, equal-valued lots of one item merge, oldest first |
| Closed lots and conversions | rings of 300 each |
| Trace | 3,000 lines plus 400 kept |
| Perf | 500 samples |
| agg | segments ring of 200 |

`folded=0` because the Paladin has 3,211 entries and 1,233 open lots, both below the caps since D-098 raised them.

**Measured sizes:**
- Account file 2,026 KB. Paladin lots 729 KB (about 400 bytes per record), Paladin ledger 696 KB (about 217 bytes per
  entry), agg 94 KB, heat 34 KB (after 1.6 h live: 137 places, 302 cells, 91 segments).
- Paladin character file 394 KB: trace 221 KB, perf 172 KB.

**(2) Proposal:** keep raw cash entries for a window, then fold them into daily summaries per day x source x activity x
place. On the real data that is 372 summary rows for 3,211 entries: 8.6 times fewer rows, about 30 times fewer bytes
(estimated). agg and heat are kept permanently.
- At the Paladin's rate (292 entries a day), a 30-day window holds about 8,800 raw entries, about 1.9 MB. That is larger
  than today's 6,000 cap (about 1.3 MB).
- So I recommend 7 days (about 2,000 entries, about 440 KB), with the 6,000 cap kept as a ceiling.
- Open lots are current holdings and cannot be folded by age. They need their own rule, for example closing lots for
  items no longer held, checked against a bag and bank scan: a later decision. Closed lots and conversions are already
  capped.

**(3) Test-mode switch:** with test mode off, the trace keeps 300 lines plus 100 kept and perf keeps 50 samples. That is
about 30 KB instead of 394 KB per character file (estimated).

**(4) Projection** (Paladin's share of the account file, at the current play rate):

| | Day 30 | Day 90 |
|---|---|---|
| Current rules | cash 1.25 MB, lots 1.7 MB, agg and heat 0.15 MB: about 3.1 MB | about 3.4 MB (both caps reached) |
| Proposal (7-day raw plus summaries; lots unchanged) | cash 0.49 MB: about 2.3 MB | cash 0.61 MB: about 2.8 MB |
| Plus an open-lot rule | depends on how many lots are stale (unknown) | same |

Character file: about 394 KB now, about 30 KB with test mode off.

The /reload and logout time saved cannot be measured from these files. Inferred: load and save time grow roughly with
file size (today 100 to 178 ms reload frames at 1.9 MB). I would measure it from the `begin` sample after a /reload,
before and after the change.

**(5) What needs raw records kept longer:**
- 3b-4 reclassifying past OTHER entries (flight fares, postage, AH deposits) needs the raw OTHER entries for the period
  to be re-sorted. Otherwise it applies only from then on.
- Cross-checks against Accountant Classic work on daily summaries. `/gi ledger check` uses only the current interval.
  The back-fill is already done.

## 7. Other findings

- CPU: session average 0.054 ms per frame including the spike; 10-minute averages 0.012 to 0.070 ms. The budget is
  0.067 ms (0.017 baseline plus 0.05). To re-measure after fix 1.
- The agg section holds the keys `sub`, `act`, `bracket` and `zone` beside the character keys, probably the empty
  placeholders from 0.5.6. Harmless; to confirm.
