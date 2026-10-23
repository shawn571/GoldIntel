# Travel model: options (PLANNING ONLY, nothing implemented)

DOC VERSION: 1.0.0  |  DATE: 2026-10-17  |  AUTHOR: Claude (S-012)  |  STATUS: DECIDED 2026-10-17: the user chose OPTION B with `travel.countInGph` = false, a `TRAVEL` activity type, dry window 60 s and stay-near about 150 yards (D-054). Remaining text is the analysis behind the choice; implementation needs the Phase 3a experiments T1 to T4 first. Original status: OPTIONS for the user's decision. Replaces the recommendation "count travel as active time" (Phase3_Planning_Package.md 7.4, Q-AFK-2), which the user rejected.

## 1. The user's requirement (2026-10-17)

- Productive farming time counts. AFK time does not count. **Taxi time does not count.**
- Long-distance travel should not dilute hotspot accuracy.
- Example: 20 gph at Lake Nazferiti, then ten minutes flying across Stranglethorn Vale. The flight must not make the zone look productive, and must not make the lake look less productive.
- Travel must be treated differently from productive activity. Propose options first.

## 2. What "dilute" means here (three separate effects)

1. **GPH denominator.** Time with no income lowers GPH. 20 gold in 60 min is 20 gph; add 10 min of flight and it reads 17.1 gph.
2. **Bin seconds.** The map divides value credited by seconds spent in each bin. Flying over bins adds seconds but no credit, so flight paths would look like cold stripes.
3. **Wrong credit.** Value must never be credited to a bin the player only flew over (for example loot received just after landing).

The model has to handle all three, and handle them separately.

## 3. What can be known (all UNVERIFIED in this client)

| Signal | What it would tell us | Candidate API / event | Status |
|---|---|---|---|
| On a flight path | Certain taxi time | `UnitOnTaxi("player")`; `PLAYER_CONTROL_LOST` / `PLAYER_CONTROL_GAINED`; `TAXIMAP_OPENED` / `TAXIMAP_CLOSED` | not probed |
| Movement speed | Fast travel vs working movement | `GetUnitSpeed("player")` (yards per second); or position change per tick scaled with `C_Map.GetMapWorldSize` (present) | not probed |
| Mounted / flying | Travel hint only (gatherers mount up to work) | `IsMounted()`, `IsFlying()` | not probed |
| Teleport / hearth | Position jump with no travel | position delta between ticks above a limit; loading screen events (`PLAYER_LEAVING_WORLD` / `PLAYER_ENTERING_WORLD` are PROVEN) | jump logic is ours |
| Distance from last productive spot | Are we still working this area | position vs last credited bin | ours |

Only the loading-screen events and position sampling are proven today. Experiments T1 to T4 in `Phase3a_Verification_Protocol.md` test the rest.

## 4. Options

### Option A: hard travel only (taxi and teleports)

Time on a flight path, in a loading screen, or immediately after a hearth/teleport is TRAVEL. TRAVEL is excluded from GPH denominators, from bin seconds, and from active time. Everything else (walking, running, mounted travel) is unchanged.

- Pros: precise, almost no false positives, tiny rules, matches your example exactly.
- Cons: a ten-minute ride on your own mount from the farm to the next farm still counts and dilutes.
- Needs: `UnitOnTaxi` or the control events (T1), jump rule (T4).

### Option B: hard travel plus "dry transit" (soft travel) (RECOMMENDED)

Option A, plus time is also TRAVEL when ALL of these hold:
- moving faster than a threshold (for example above normal run speed) or moving continuously in one direction;
- at least a minimum distance from the last credited spot (for example more than ~150 yards);
- no productive event (loot, gather, fish, kill signal) for a dry window `W` (default 60 s).

Soft travel is excluded from bin seconds always (so it cannot cool a bin it only crossed). Whether it is excluded from GPH is a setting.

- Gatherers: a herbalist riding a route gets a loot every 20 to 40 s, so the window keeps resetting and the route counts as productive (and credit lands where the herb was picked, which is correct).
- Grinders: running to the next pack for 30 s stays productive (inside the window and close to the last spot); running 5 minutes to another zone becomes travel after the window.
- Cons: more rules; thresholds need tuning; a cautious farmer who stops productive work for a while is classified as travel while moving and idle while still. Both are excluded, so the effect is conservative.
- Needs: speed signal (T2), activity signals from section 8 of the planning package.

### Option C: productive window only (no travel concept)

Time counts only when a productive event happened within the last `W` seconds, regardless of movement.

- Pros: one rule, handles flight, idle and long runs together.
- Cons: wrongly removes honest search time (looking for the next mob or node) and so inflates GPH; makes grinders with long pulls look faster than they are. Not recommended because it rewards ignoring dead time that really belongs to farming.

### Option D: manual only

Nothing is automatic; the user pauses with `/gi pause` before travel and resumes after. Always available as an override under every option (Q-AFK-3 approved).

- Pros: zero false positives.
- Cons: relies on memory; defeats the point of an automatic tool.

### Option E (extension, not for v1): record travel as routes

Flight and transit paths could be kept as route data for the deferred RouteEngine. Out of scope (deferred in Requirements); mentioned only so the TRAVEL label stays compatible.

## 5. Interaction with idle (AFK)

Idle and travel are both "non-productive time" and are handled by the same retroactive-subtraction machinery (planning package 7.3): a stretch is relabelled once its class is certain. Taxi time is certain at once (no retroactivity). Soft travel is classified when the dry window ends; the stretch since the last productive event is relabelled.

Priority when signals overlap: manual pause > taxi > idle > soft travel > productive. A stretch has exactly one class, so time is never subtracted twice.

## 6. Effect on each output (recommended Option B)

| Output | Taxi | Soft travel | Idle |
|---|---|---|---|
| Cash / Wealth / Net GPH denominator | excluded | excluded by default (setting `travel.countInGph`, default false) | excluded |
| Bin seconds (map) | excluded | excluded | excluded |
| Bin credit | none | normal if a productive event happens (credit goes where it happened) | none |
| Zone / subzone rankings (active hours) | excluded | excluded by default | excluded |
| Session "wall clock" display | shown separately as Travel time | shown separately | shown separately |

The explain view (FR-MET-5) lists Active, Travel and Idle minutes so the user can see why a number is what it is. Nothing is hidden.

## 7. Worked example (Lake Nazferiti)

60 min farming (20 gold) at the lake, 10 min taxi, 5 min of walking and running between camps with a kill every 30 s.

| Model | Time base | GPH shown |
|---|---|---|
| Count everything | 75 min | 16.0 |
| Option A | 65 min (taxi out) | 18.5 |
| Option B | 65 min (taxi out; the camp-to-camp run stays productive) | 18.5 |
| Option C | 60 min | 20.0, but only because the dead time inside farming is dropped too |

(Example values are arithmetic on the numbers above, not measurements.)

## 8. Edge cases to decide or test

- Flight-master mounts that are not taxis (for example a Wyvern/Gryphon ride is a taxi; a mount you fly yourself is not).
- Boat, zeppelin, elevator rides: position changes without player movement. Treated as hard travel if the position jumps or speed signal says so; otherwise caught by the dry window. Needs a test in a harbour.
- Dungeons or instances: no position samples at all (Architecture 8); time there is its own question (not covered).
- Dead / ghost run: counts as travel (new class) or as idle; proposal: travel (no productive events, moving).
- Resting in a city after selling: idle after the timeout; vendor, mail and AH windows are context activities and are not credited.
- Speed buffs (Pathfinding, speed potions) change thresholds: thresholds should compare to the player's own base speed or be settings.

## 9. Decisions requested

1. Choose A, B, or C (recommended B), and say whether D is only the always-available override (recommended yes).
2. `travel.countInGph` default: false (recommended, matches your wish), or true.
3. Dry window default `W` = 60 s, and a "stay-near" distance of about 150 yards: acceptable starting values (they are settings and will be tuned from your own data).
4. Whether a new activity key `TRAVEL` may be added to the reserved enum (Requirements NFR-7 reserves keys; adding one needs your decision). Recommended: yes, as a non-credited, non-productive class.

## 10. Proposed decision text (not recorded as approved)

**D-054 Travel is a separate non-productive class (Proposed).** Taxi, loading-screen and teleport time are always excluded; soft travel (fast, far from the last productive spot, no productive event for `W`) is excluded from bin seconds and by default from GPH; `TRAVEL` is a reserved activity key; manual pause always wins. Pending: choice among options A to D, thresholds, and experiments T1 to T4.
