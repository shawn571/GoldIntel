# Phase 2 Runtime Validation Plan (WoW Forever client)

DOC VERSION: 1.1.0  |  DATE: 2026-10-15  |  Covers GoldIntel 0.2.0-phase2 (Core + Store). First live session done 2026-10-15 (see 'Results so far'); the remaining steps are marked TODO.

**Rule: stop at the first Lua error or blocked-action popup, copy the text, and report it. Do not continue past a failure.**

All steps are read-only for the character except the config steps, which change addon settings only. Steps marked OPTIONAL edit a SavedVariables file with the game closed; always keep a backup copy first.

## Results of the third live session (2026-10-17 afternoon, evidence E-15)

V3: PASS except ZONE_CHANGED_INDOORS (money, level-up, zone, new-area, combat delivered with usable payloads where a payload exists). V5: PASS (`idleSec = 240` persisted). V7: PASS in both states (libraries absent in E-14, present in E-15). V8: PASS for `/gidiag run` (0 diagnostics); `/gidiag copy` window still unreported (the user typed `/gi diag copy`, a different command). Lesson: a `/reload` starts a new session and overwrites `runtime`, so only the last session is in the saved file.

## Results of the second live session (2026-10-17, build 70450, evidence E-14)

| Step | Result |
|---|---|
| V1 startup health | PASS again (`diag=0`, operational, 21 installed files identical to the package) |
| V3 delivery stages | PARTIAL, improved: PLAYER_REGEN_DISABLED and PLAYER_REGEN_ENABLED now delivered; SKILL_LINES_CHANGED delivered 3 times. **Still TODO:** PLAYER_MONEY (sell or buy something), ZONE_CHANGED / ZONE_CHANGED_INDOORS / ZONE_CHANGED_NEW_AREA (cross a subzone), PLAYER_LEVEL_UP (if possible) |
| V4 database upgrade | PASS: second and later sessions open with `store=ok schema=1`, `opens=4`, history unchanged, no diagnostics |
| V5 settings persist | STILL TODO: `profile` is empty. Run `/gi config set idleSec 240`, `/reload`, `/gi config` |
| V7 libraries off | PASSED in practice: LibStub was nil, every `lib.*` capability absent, addon operational and store ok (no libraries are used above Platform/) |
| V8 diagnostics sandbox | PARTIAL: `/gidiag compile` 21/21 OK. **TODO:** `/gidiag run` (or `all`) and whether `/gidiag copy` opens |
| Debug echo | `/gi debug ticks` printed "tick echo on" but nothing was echoed because `/gi debug on` was not set; the message now says so (rebuild 3) |

## Results so far (first live session, 2026-10-15, build 70374)

| Step | Result | Evidence |
|---|---|---|
| V1 startup health | PASS (no Lua error; `/gi diag` empty; operational) | E-13 |
| V2 registration verification | PASS for the registered case: `IsEventRegistered` returned true for all 12 events, no warning. The BLOCKED case is untested | E-13 |
| V3 delivery stages | PARTIAL: PLAYER_LOGIN, PLAYER_ENTERING_WORLD, SKILL_LINES_CHANGED (fires at login), PLAYER_LEAVING_WORLD, PLAYER_LOGOUT delivered. **TODO:** money, zone, combat, level-up were not triggered | E-13 |
| V4 database upgrade | PASS: migrated 0 to 1, `schemaHistory` recorded, all sections present, `compat` present. **TODO:** `/gi db` text and the second-session `state=ok` / `opens=2` check | E-13 |
| V5 settings persist | TODO (profile was empty) | |
| V6 evidence without logout | PASS: runtime snapshot and checkpoint were saved at logout. The rebuilt addon also saves command output | E-13 |
| V7 libraries off | see the 2026-10-17 table above | |
| V8 diagnostics sandbox | TODO | |

**What `nil` meant in your first `/gi caps events`:** nothing was wrong. `delivered=nil` meant 'this event has not been seen yet in this session' and `payloadUsable=nil` meant 'not checked yet', because nothing had been sold, no subzone crossed and no combat entered. The rebuilt addon prints words instead: `yes`, `NO` (a real failure), `not-seen-yet`, `unknown`. To fill them in, do the V3 actions.

## Getting output back without copy and paste

1. **Automatic (new in the rebuilt addon):** everything GoldIntel prints in chat, including the output of every `/gi` command, is saved in `GoldIntel.lua` under `runtime.output` (last 100 lines, saved within about 5 seconds after a command and again at logout or `/reload`). Run the commands, `/reload`, and send the file. Nothing needs to be copied.
2. **GoldIntelDiag window:** `/gidiag copy` opens a text box with the diagnostics transcript (click inside, Ctrl+A, Ctrl+C). Please tell me whether it opened; it has not been seen working in the real client.
3. **Screenshots** always work.
4. **Chat log file:** `/chatlog` toggles writing chat to `Logs/WoWChatLog.txt` inside the game folder. I am NOT sure addon `print` lines are included; if you try it, check the file and tell me.
5. Try selecting chat text with the mouse; some current clients allow it. I could not confirm Forever does.

## Before you start

1. Back up `WTF/Account/<ACCOUNT>/SavedVariables/GoldIntel.lua` (it holds the Phase 1 database; this backup is also your rollback). Back up `GoldIntelDiag.lua` if you want to keep that transcript.
2. Delete the old `GoldIntel`, `GIMin` and `GoldIntelDiag` folders. Extract `GoldIntel_Phase2_AddOns.zip` into the AddOns folder.
3. Layout check: `GoldIntel/` contains `GoldIntel.toc` and the folders `Platform`, `Core`, `Store`, `Future`; `GoldIntelDiag/` contains `Diag.lua` and `SrcCurrent.lua`. (Do not copy the `Tests` folder; it is not in this zip.)
4. Enable "Load out of date AddOns" if the client lists any of them as out of date.

## The steps

Each step lists what to do, what you should see, and what a deviation means.

**V1. Startup health.** Log in. Type `/gi`.
Expect, in the chat, lines like:
```
GoldIntel 0.2.0-phase2  -  gold analytics for WoW Forever (client 1.60.1)
operational=true ready=true inWorld=true scheduler=ctimer money=<copper> diag=0 lastRegister=PLAYER_MONEY
core=ready modules=2 enabled=2 failed=0 disabled=0 stubs=2
store=migrated schema=1 writable=true size~<n> KB
events: registered=<n> delivered=<n> payloadUsable=<n> blocked=0   api: present=<n> absent=<n> unknown=<n>
```
No popup, no Lua error. `store=migrated` is right the FIRST time on the Phase 1 database; later sessions show `store=ok`. `diag=0` expected.
Deviation: `operational=false`, `core=platform-failed`, `blocked>0`, `store=degraded` or `store=readonly` (on a normal database) are failures; report them.

**V2. Registration verification (the part never run live before).** Type `/gi caps events`, then `/gi diag`.
Expect for each of the 12 events a line `event.<NAME>  [registered]  valid=yes registered=yes delivered=not-seen-yet payloadUsable=unknown` (`[delivered]` with `delivered=yes` is normal for the login events).
This tests whether `IsEventRegistered` works as modeled (risk R-26).
- `registered=unknown` for an event means the check was unavailable or disagreed. Check `/gi diag` for a warning containing "proven in the live client": that means the real `IsEventRegistered` returned false for a working event. REPORT THIS: it tells us the verification semantics differ.
- `[blocked]` for any of the 12 is a failure: report it.

**V3. Delivery stages.** Do these and then type `/gi caps` after each (use `/gi caps money`, `/gi caps zone`, `/gi caps regen`):
1. Sell or buy something at a vendor. Expect `event.PLAYER_MONEY  [payloadUsable]  valid=yes registered=yes delivered=yes payloadUsable=yes`.
2. Walk across a subzone boundary. Expect `event.ZONE_CHANGED ... delivered=yes`.
3. Enter and leave combat. Expect `event.PLAYER_REGEN_DISABLED` and `..._ENABLED` `delivered=yes`.
4. Level up if one happens; otherwise skip.
An event you did not trigger stays `delivered=not-seen-yet`. That is correct ("not seen yet"), not a failure. Optionally `/gi debug on` to see `[evt]` lines, `/gi debug off` afterwards.

**V4. Database upgrade and compat.** Type `/gi db`.
Expect:
```
state=migrated schema=1 target=1 writable=true        (first session on the Phase 1 database)
  ... sessions: 0 entries ... runtime: <n> entries ...
  compat: present (preserved untouched)
  character data: schema 1, pending none
opens=1 lastBuild=70338 addonVersion=0.2.0-phase2
  migration: schema 0 -> 1 by 0.2.0-phase2
```
Then `/reload` and `/gi db` again: expect `state=ok`, `opens=2`, a single migration line.
Note: `compat` is rewritten at each login by the capability probe (it records the current client); the Store itself never touches it.
OPTIONAL (proves unknown data survives): with the game CLOSED, add a line `["zzMarker"] = "keep",` inside `GoldIntelDB = {` in your backed-up `GoldIntel.lua` copy, put it back in `SavedVariables`, start the game, log in, log out. Open the file: `zzMarker` must still be there.

**V5. Settings persist.**
```
/gi config
/gi config set idleSec 240
/gi config set prune.days 45
/gi config set idleSec 5          (expect: idleSec must be at least 10)
/gi config set heatGrid 32        (expect: heatGrid is read-only)
/reload
/gi config                         (idleSec = 240 and prune.days = 45 are still there, marked with their default)
/gi config reset all               (expect: reset 2 setting(s) to defaults)
```
In the saved file the `profile` section holds `idleSec` and a nested `prune = { days = 45 }` after a logout.

**V6. Evidence is written without a logout.** Type `/gi checkpoint`; expect `database ~<n> KB` and a reminder that the client saves at logout or `/reload`. Then `/reload`. In `GoldIntel.lua`, `runtime` must contain `capabilities`, `eventStats`, `generatedAt` and `output` (the chat lines). This is the file to send back.

**V7. Libraries stay optional.** Disable every addon except GoldIntel (and GoldIntelDiag if you like), restart, log in, and repeat V1. Expect the same lines; only `api: ... present/absent` counts for the `lib.*` entries may differ (`/gi caps api` lists them). Then re-enable your addons.

**V8. Diagnostics addon.** `/gidiag compile` expects `OK` for all 21 files and `RESULT: every embedded source compiles`. `/gidiag run` expects `core: state=ready modules=2 enabled=2`, a `store:` line, `event capability levels:` and `GoldIntel diagnostics: 0`. Afterwards `/gi` must still work and your real data must be unchanged (`/gi db` opens count did not change from the sandbox run). `/gidiag all`, then `/gidiag copy` (Ctrl+A, Ctrl+C) gives the full transcript.

**V9. Restricted-event follow-ups (not Phase 2 work; they feed OI-8).** Run F1, F3 and F4 from `Phase1_PostValidation_Review.md` section 14, F3 also in combat and in an instance.

**V10. OPTIONAL read-only mode.** With the game closed, edit the `schema` value in `GoldIntel.lua` to `99`. Log in. `/gi db` expects `state=readonly` and a note that the saved data is newer than this addon; `/gi config set idleSec 200` says "this session only". Log out: the file must still say `schema = 99` and its `profile` must be unchanged. Restore your backup afterwards.

## What to send back

1. The full `WTF/.../SavedVariables/GoldIntel.lua` and `GoldIntelDiag.lua` after V6/V8.
2. The chat output of V1, V2, V4 (or screenshots/text).
3. Any popup or Lua error, copied exactly.
4. Which steps you skipped.

## Acceptance (Phase 2 closure)

| # | Criterion | Steps |
|---|---|---|
| 1 | No Lua error and no popup in a full session | V1 to V8 |
| 2 | Core ready, 2 placeholder modules enabled, 0 failed | V1, V8 |
| 3 | Store migrates the real Phase 1 database; compat preserved; second session is `ok` | V4 |
| 4 | Registration verification reports `registered=true` for the 12 events, or a clearly explained deviation | V2 |
| 5 | Delivery stages track real events; untouched events stay `not-seen-yet` | V3 |
| 6 | Settings persist across reload and validate input | V5 |
| 7 | Evidence is written into `runtime` | V6 |
| 8 | Behavior identical without other addons | V7 |
| 9 | Sandbox run leaves real data untouched | V8 |

## Known limits of this validation

- Delivery of events you cannot easily trigger stays unknown.
- Degraded mode cannot be induced from the client; it is covered by tests only.
- Performance is not measured here (an hour-long fake-client soak passed; real CPU measurement waits for the profiler functions listed by follow-up F1).
