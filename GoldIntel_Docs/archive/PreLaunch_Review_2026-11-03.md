# GoldIntel pre-launch review (0.5.1-passive)

DATE: 2026-11-03  |  SESSION: S-057 (Claude Code cloud session)  |  BUILD REVIEWED: 0.5.1-passive, code commit a21e071  |  STATUS: review only, no code change

Approved by the user on 2026-11-03 together with the document catch-up. Launch is 2026-11-04.

## 1. What was checked

| Check | Result | Evidence |
|---|---|---|
| Last code commit | a21e071; every later commit is docs only | `git diff a21e071 HEAD --stat` lists only GoldIntel_Docs/ files |
| Versions | `P.VERSION` and TOC `## Version` = 0.5.1-passive; `P.CONTRACT_VERSION` = 1.9.0; character schema 2 | Platform.lua, GoldIntel.toc, Store.lua |
| Test suite | 1,255 passed, 0 failed (Lua 5.4.6, same harness as texlua) | `lua5.4 run.lua` from GoldIntel/Tests |
| Lua 5.1 syntax (the game's Lua) | all 52 addon `.lua` files outside Tests parse with `luac5.1 -p` | new check this session; the harness alone runs on 5.4 |
| Files changed 0.4.7 to 0.5.1 | exactly GoldIntel.toc, Platform.lua, Config.lua, Collector.lua, Ledger.lua, Trace.lua | `git diff fa78ade a21e071`; matches the six files installed on 2026-10-31 |
| Installed copy on the user's laptop | Not checked by Claude (no Remote Control link yet, D-087). The user re-copied `GoldIntel.toc` from main and verified it on 2026-11-03 | user report; before that the installed TOC read 0.5.0-passive |

## 2. Code review of the 0.5.0 and 0.5.1 changes

No finding blocks the launch. Nothing below needs a code change before 2026-11-04.

| # | Severity | Finding |
|---|---|---|
| R-1 | info (user-visible) | Auto start runs once per addon load, 3 s after enable, inside `pcall`, through the normal `Collector.On` path (registration journal and quarantine still apply, so an event that crashed registration last time is skipped). A hand-made `/gi collect off` holds until the next load only: after `/reload` or a new login, recording starts again unless `collect.auto` is false. This matches D-086 ("never undone in the same session"). |
| R-2 | info (user-visible) | `/gi ledger trace clear` empties both `trace.lines` and `trace.keep`. Do not clear the trace before Claude has read the file. |
| R-3 | low | The `EVT check` line formats `seconds` with `%d`. Seconds come from `GetTime()` and can be fractional. Lua 5.1 (the game) truncates, so the line is fine live. Under the Lua 5.4 harness a fractional value would raise inside the protected call and the line would be dropped (counted in `Trace.stats.errors`). Not a live risk; a test with a fractional clock can be added with the next approved code change. |
| R-4 | low, unmeasured | The rolling trace drops its oldest line with `table.remove(L, 1)` on a 3,000-line list, so every new line moves up to 3,000 entries. Cost per line is small but was never measured (NFR-3; M4 measures CPU). |
| R-5 | info, estimate | Size: up to 3,000 trace lines plus 400 kept lines per character, about 60 to 200 bytes each, so roughly 0.2 to 0.7 MB per character file on top of cash entries and lots [inferred, unmeasured]. The Pruner (`prune.maxBytes`) does not count the trace; the line caps are the only bound. A larger file means a slightly longer save at logout or `/reload`. |
| R-6 | info | `EVT group` and the periodic `EVT check` run on `P_TICK` (Platform/Map.lua, every 0.5 s while in the world). The same tick feeds the location stamps of Sources and ItemSources, which worked live in 3b-2 and 3b-3, so the tick is proven indirectly [inferred]. The new lines themselves have never run live. |
| R-7 | info | The group poll calls `GetNumGroupMembers`, `IsInGroup`, `IsInRaid` through `P.Call` every 2 s and writes a line only on change; a missing function gives `grp=unavailable`, not an error. |
| R-8 | doc | The header comment of `Ledger/Trace.lua` still says CAP 1500 (code is 3000). Fix with the next approved code change; Contracts F18 has the correct values. |
| R-9 | decided | Item recording (`/gi lots`) is ON by default; the user confirmed this on 2026-11-03 (D-088, replaces the AC-19 text). With auto start, items are recorded from the first login. |

## 3. Risks that stay open at launch

- 0.5.0 and 0.5.1 have never run in the real client. The first live login is a validation event.
- Beta-to-launch drift (R-08, OI-11): game version, build, Interface number, realm model or APIs may change. Re-probe on launch day.
- R-21: the client writes SavedVariables only at logout or `/reload`; a crash loses the unsaved part of the session.
- The one client crash on `/reload` with the M2 build (0.4.1) was never reproduced; cause unknown.
- Interplay with the user's other addons (about 60) and login time with auto start: unmeasured.
- Open evidence: roll-won items, herbalism/mining/fishing spell names at other ranks, empty loot windows, item 279912 never ready.
- Decided 2026-11-03: item recording ON by default (D-088); beta data kept in the live account, revisit with Account Best (D-089).

## 4. Launch-day checklist (for the user)

The installed `GoldIntel.toc` was re-copied from main and verified by the user on 2026-11-03, so the old step 1 is removed.

Before starting the game:
1. Check that `...\_forever_\Interface\AddOns` contains `GoldIntel` and `GIMin`, and NOT `GoldIntelDiag` or `GIProbeLoot`.

In the game:
2. On the character screen open AddOns. Expected: GoldIntel listed as 0.5.1-passive. If it says "out of date", tell Claude (the `## Interface:` line needs updating, D-028).
3. Log in. Expected, about 3 seconds later: `GoldIntel: recording started automatically (...)`.
4. Type `/gi version`. Expected two lines: `GoldIntel 0.5.1-passive  (contract 1.9.0)` and `client <version> build <build>  interface <number>  locale <locale>`. Copy back the second line (beta was client 1.60.1, interface 16001).
5. Type `/gi caps`. Copy back the output (capability check after the launch patch).
6. Type `/gi ledger check`. Expected: a line ending `-> DIFFERENCE 0 copper (OK)`.
7. Play normally. If a line `GoldIntel: UNEXPECTED item condition: ...` appears, copy it or take a screenshot.
8. Do not type `/gi ledger trace clear` or `/gi lots reset confirm`.
9. After play: log out (or `/reload`), then attach the character file `...\_forever_\WTF\Account\<account>\...\<character>\SavedVariables\GoldIntel.lua` (and the account-wide `...\WTF\Account\<account>\SavedVariables\GoldIntel.lua` if asked) and write "logged out, check".

Escape hatches if anything misbehaves: `/gi collect off` (this session) and `/gi config set collect.auto false` (stops the automatic start).
