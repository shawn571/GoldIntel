# Phase 4 P4-M3 live check 3 (0.6.2-passive) and the 0.6.3 proposal

DATE: 2026-11-21 | STATUS: proposal only, NOT built, NOT approved (D-123) | Branch p4/m2-live (PR #9 stays unmerged
until 0.6.3 passes)

Files: the account file and one character file, attached in this session (S-081), read only. The character file is a
low-level Shaman's (Orgrimmar and Durotar only). Times are seconds since the start of the Shaman's last recording
interval (2026-11-20 23:46:07 UTC) unless shown as UTC. "Measured" = read from the files; "inferred" = not proven.

## 1. Results reported by the user (reloadMinutes 2)

| Item | User | Evidence in the files |
|---|---|---|
| Settings window: real value, "saved as soon as you move the slider" | pass | not traced (no window lines in 0.6.2) |
| (b) Ignore: no quick re-show | pass | no Ignore click in this interval (an earlier session or character) |
| Combat hide | pass | measured, section 2 |
| Reload Now reloads | pass | no Reload click in this interval |
| (a) Configure: full interval after Configure | FAIL: back after about 4 minutes, not 2; earlier that evening not at all until /gi settings was opened and closed again | measured for the 4 minutes, section 2; "not at all" is not in these files, section 4 |
| Boss fight: no popup during it | FAIL | not in these files, section 3 |

## 2. Measured: the reminder lines of the Shaman's interval (trace.keep and the rolling trace agree)

| s | UTC | Line | Gap |
|---|---|---|---|
| 5451 | 01:16:58 | `/gi config set reminder.reloadMinutes 2` (account file, output) | |
| 5482.5 | 01:17:29 | shown minutes=2 | first check after the setting |
| 5484.9 | | click=configure | 2.3 s open |
| 5662.9 | 01:20:31 | shown | **178.0 s after the click** |
| 5737.5 | | closed reason=combat | 74.6 s open |
| 5843.0 | 01:23:30 | shown | 105.5 s after the combat hide; no new interval (correct) |
| 5852.4 | | click=configure | |
| 6023.9 | 01:26:31 | shown | **171.5 s after the click** |
| 6043.9 | | click=configure | |
| 6166-6227 | | loot from spiders and a scorpid (fighting) | |
| 6264.9 | 01:30:32 | shown | **221.1 s after the click** (the user's "about 4 minutes") |
| 6317.2 | | click=configure | |
| 6357.1 | 01:32:04 | logout; ledger check difference 0 | |

At logout the saved setting is `reloadMinutes = 180` (account file, profile), presumably set at the last Configure.

Cause of the late popups (measured, then confirmed in the code):
1. **60-second polling.** `Live.REMIND_CHECK = 60`: the reminder looks only once a minute. Every show above lies on one
   60 s grid (5482.5 + 180, + 360, + 540, + 780, within 2.4 s). After a click at c the popup comes at the first check at
   or after c + 120 s, so anywhere from 120 to 180 s. Measured: 178.0 and 171.5 s.
2. **A blocked check waits a whole minute more.** At about 6204 (c + 160 s) the Shaman was fighting (loot at 6166,
   6188, 6209, 6227), so `UI.Blocked()` refused that check; the next one, 60 s later, showed it: 221 s.
3. **The count starts at the click, not at Close.** 0.6.2 restarts the interval when Configure is clicked
   (`promptClosed(..., true, 'click=configure')`), while the user expects 2 minutes after closing the Settings window.
   The window's open and close are not traced, so the time from Close to the popup cannot be measured in these files.

Combat hide (measured): the popup closed for combat at 5737.5 and came back at 5843.0 without a new interval. When
combat ended is not traced; the return is at the first 60 s check after it, so "about a minute" is really 0 to 60 s
after combat plus the grid.

## 3. Boss fight: not in these files

- The character file holds only the Shaman's sessions (rolling trace back to 2026-11-10; the last two intervals
  2026-11-20 23:16 and 23:46 UTC, Orgrimmar and Durotar, no instance, no encounter).
- The account file's ledger shows no character with cash entries inside an instance on the evening of 2026-11-20. The
  newest instance entries are the Paladin's Razorfen Downs (2026-11-18 17:23-18:10 UTC). Another zone, "Riverglades"
  (Paladin, 2026-11-20 02:04-04:25 UTC), is unknown to me: I cannot tell whether it is an instance.
- ENCOUNTER_START and ENCOUNTER_END: registered, **0 delivered** in both sessions whose counts the account file keeps
  (both the Shaman's, no dungeon). So the files show neither that the events work nor that they do not. They have never
  been observed delivered on Forever (UI.lua says so since 0.6.1).
- Needed: the character file of the character that fought the boss, and which dungeon and boss, roughly when.

How 0.6.2 can show a popup during a boss fight (from the code; which one happened is not known):
- (i) the encounter events do not arrive on Forever and the player is briefly out of combat during the fight (dead,
  released, out of range, a phase or RP pause): the 60 s check that falls into that gap shows the popup;
- (ii) the popup is already due and the check falls between a trash pull and the boss pull; combat hide then closes it
  at the pull, but the boss then starts with a popup that flashed up (would look like "appeared during").
- (iii) the group is fighting while the player is not in combat yet (a ranged or healing character before the first
  heal or hit).

## 4. "Did not come back at all" earlier that evening: not in these files

The Shaman's earlier intervals that evening have no reminder line at all (the setting became 2 only at 01:16:58 UTC),
so this happened on another character. Its character file is needed. Candidates from the code (inferred, unproven): a
popup the client never displayed while GoldIntel thought it open (the "lost" check exists, but runs only at the
60 s checks), or the Settings window opened by Configure being the one the user closed and reopened while the setting
was not yet 2. The 0.6.3 trace lines (F5) make the next case readable.

## 5. Proposed 0.6.3-passive (contract 1.18.0), NOT built

| # | Fix | Behaviour |
|---|---|---|
| F1 | Interval after Configure starts at the window's close | Configure opens the Settings window; while it is open no popup is shown and the timer waits; the full interval starts when it closes by any route (Close, X, Escape). If the window cannot open, the interval starts at the click (as now). |
| F2 | Exact due time instead of 60 s polling | The next popup is due at exactly start + minutes x 60 and is checked on every tick (one number comparison), so it shows within about 1 s of the due time. A change of the setting while waiting moves the due time to start + new minutes. |
| F3 | One-minute cool-down after combat and encounters | A popup that is due (or hidden for combat) is shown only after 60 s with no combat and no encounter. Combat again inside those 60 s restarts the minute. No new interval (as now). This makes "comes back about a minute after combat" exact and closes gap (i). |
| F4 | Group guard inside dungeons and raids | Inside a party or raid instance, the popup is also held while any group member is in combat, so a dead, released or not-yet-engaged player gets no popup during the fight (gaps i and iii). Needs a probe of the unit-combat function on Forever; without it F4 is off and F3 still holds. |
| F5 | Evidence lines | `EVT encounter start id= name=` and `end ... success=`, `EVT reminder held why=combat|encounter|group|cooldown|settings` (once per due time), `EVT reminder settings opened|closed how=`; all in trace.keep. |
| F6 | Lost-popup check every tick | If GoldIntel believes the popup is open and the client says it is not shown, it is closed as `reason=lost` within about 1 s instead of up to 60 s. |

Unchanged: Ignore and Reload Now restart the interval at the click; the client's own closes restart it; combat and
encounter hides do not.

Cost: per tick a few comparisons; the group scan (at most 4 or 39 units) runs only inside an instance, only once a popup
is due, at most once per second.

### Tests (desktop, Lua 5.4; plus Lua 5.1 parse)

1. Configure: click at t, window open 100 s, Close at t+100: no popup before t+220, popup at t+220 (within 1 s). The
   same with X and with Escape. Window fails to open: popup at t+120.
2. While the Settings window is open nothing is shown, even long after the due time.
3. Exact due time: popups at start+120 s, not on a 60 s grid, with ticks of varying length (0.016-5 s).
4. Setting changed from 60 to 2 while waiting: due at start+120; from 2 to 60: due at start+3600.
5. Combat: due during combat, combat ends at e: shown at e+60, not before; combat again at e+30: shown 60 s after that
   second end. Combat hide: closed at the pull, back 60 s after combat, interval start unchanged.
6. Encounter: ENCOUNTER_START with the player out of combat holds the popup; END + 60 s shows it; IsEncounterInProgress
   true also holds it; an encounter that never sends END is released when IsEncounterInProgress turns false.
7. Group: in a party instance a member in combat holds it; outside an instance it does not; without the unit-combat
   function nothing is held for the group and the probe says so.
8. The F5 lines appear in trace.keep, one `held` line per due time, not one per tick.
9. Lost popup: believed open, not shown: closed as lost on the next tick, interval restarted.
10. Deliberate-bug checks: removing the cool-down fails test 5; polling every 60 s again fails test 3; restarting at the
    click fails test 1.

Package: /reload is enough over 0.6.2 (only .lua files change; no new add-on folder, no SavedVariables or Interface
change; D-117). Rollback: the 0.6.2-passive zip plus /reload.

## 6. Live check 4 (after the user approves and installs 0.6.3)

At reloadMinutes 2: Configure, wait 1 minute, Close: popup about 2 minutes after Close; a fight: popup about 1 minute
after it; a dungeon boss fight (the evidence for F3 to F5); then "logged out, check" with the account file and the
file of every character played.
