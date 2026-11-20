# GoldIntel Session Handoff

Append newest section at the TOP. The newest section wins over older ones. Format is mandatory.

---

## S-079 | 2026-11-20 | Claude (Claude Code cloud session "GoldIntel Code", same session) | STATE UPDATE (S-078 holds except as below)
- PR #27 (realm facts, realm-scope and retention plan, R-35/R-38) merged 76712a4; tests on main 1,343.
- D-121 (user's words in Decisions.md): retention B.6 decided (7-day window; stale lots after 7 days, mailbox and AH listings count as present; segments 50, merge under 60 s; test mode ON until Phase 4 closes); realm scope approved to build after #9; order realm scope, then retention.
- Repository public on purpose (found public 2026-11-20). CODE_STANDING_ORDERS section 7: no private check; every push is checked for character names, GUIDs and account names. Already in the files (OI-16, the user's decision): the main characters' names (about 230 occurrences each), the main character's GUID (4 files), the Battle.net account folder number (2 archived files), three test-character names added in D-120 and Compatibility_Notes.
- For the record: Legacy points are account-wide across normal realms; Hardcore will have its own (no GoldIntel change).
PENDING (needs Shawn): rest of live check 3 (next session); OI-16 scope (scrub current files or leave them).
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, 0.6.2-passive). Merged and kept: #1 to #8, #10 to #27 and this docs PR.
INSTALLED: 0.6.2-passive.
NEXT: after live check 3 passes and #9 merges: realm scope, then retention.

## S-078 | 2026-11-20 | Claude (Claude Code cloud session "GoldIntel Code", same session) | STATE UPDATE (S-077 holds except as below)
- PR #25 (documents cleanup) merged 0d3ec9a; main merged into p4/m2-live (3148f0e).
- Live check 3 of 0.6.2, part 1 (files attached in this session): popup at 120 minutes, Reload Now, Ignore without re-show, total = session, no frame over 500 ms. Still to test: 2-minute steps, combat hide, Settings window text, boss fight. PR #9 stays unmerged.
- D-120: build 71037 returns "" for the realm functions; GUID server numbers per realm (6796 PvE, 6800 PvP, 6928 RP, 6935 RP-PvP; 6933 beta). Confirmed from the code: GoldIntel never calls realm functions, keys characters by GUID, does not depend on "!RealmFix".
- Answer: ledger, lots, agg, heat are per character GUID (no mixing); prices.manual is account-wide by item id (empty). Plan (plan only): key realm-dependent data by GUID server number; retention plan with the measured 3.9 MB file. Both in Plan_Retention_and_Realm_Scope.md on the docs PR "realm-retention" (needs approval: it also updates Compatibility_Notes and Risk_Register).
PENDING (needs Shawn): rest of live check 3; approve merging the realm-retention docs PR; decide B.6 of the plan (window length, stale-lot rule, segments, test mode, order).
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, 0.6.2-passive). Docs PR realm-retention open (needs approval). Merged and kept: #1 to #8, #10 to #25 and this docs PR.
INSTALLED: 0.6.2-passive (user); local add-on "!RealmFix" 2.0 (not ours).
SHAWN'S NEXT STEP: finish live check 3; reply on the plan and the docs PR.

## S-077 | 2026-11-16 | Claude (Claude Code cloud session "GoldIntel Code", same session) | STATE UPDATE (S-076 holds except as below)
- D-119 (user's words in Decisions.md): documents cleaned up on branch docs/cleanup-2026-11-16: one AI developer (D-032 superseded), the game is live, finished-phase documents and old TODO/handoff history moved to GoldIntel_Docs/archive/. Living documents rewritten or updated: Project_Bible, README, TODO, Risk_Register, Compatibility_Notes, Architecture, CODE_STANDING_ORDERS, Requirements_v1 (NFR-5 wording only).
- The cleanup PR touches files outside the docs-only standing approval (Bible, README, Architecture, Requirements, Risk_Register, Compatibility_Notes, archive moves): it waits for the user's merge approval.
- After it merges, main is merged into p4/m2-live; expected document conflicts (TODO, handoff, Bible) are resolved in favour of the cleaned versions plus the branch's own entries.
PENDING (needs Shawn): approve merging the cleanup PR; live check 3 of 0.6.2 (unchanged).
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, 0.6.2-passive). Cleanup PR open. Merged and kept: #1 to #8, #10 to #24.
INSTALLED: as the user last said (0.6.1, or 0.6.2 if installed).
SHAWN'S NEXT STEP: approve (or not) the cleanup PR; continue live check 3.

## S-076 | 2026-11-14 | Claude (Claude Code cloud session "GoldIntel Code", same session) | STATE UPDATE (S-075 holds except as below)
- D-118 (user's words in Decisions.md): 0.6.2 fixes approved with (a) full interval after Configure, Ignore, Reload Now; (b) no immediate re-show after Ignore; (c) clicks and the client's own closes logged apart.
- 0.6.2-passive (contract 1.17.0) built on p4/m2-live (ad83a6d): reminder popup state, real value and "Saved" in the Settings window, Close button, single chat prefix. 1,403 tests; Lua 5.1 parse ok. Package GoldIntel_0.6.2_passive_AddOns.zip built from the branch head and sent. /reload is enough over 0.6.1 (D-117).
- NEXT_SESSION_PROMPT.md: REST merge command is the merge method; "gh pr merge" dropped; open PRs listed with gh api (docs-only PR, merged).
PENDING (needs Shawn): live check 3 on 0.6.2 including the boss encounter; then PR #9 is merged when he reports it passed. EmpireIntel screenshot (later).
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, 0.6.2-passive). Merged and kept: #1 to #8, #10 to #23 and this docs PR.
INSTALLED: 0.6.1-passive until the user installs 0.6.2.
SHAWN'S NEXT STEP: install 0.6.2 (/reload), run the live check 3 steps of the S-076 report, then "logged out, check" with files.

## S-075 | 2026-11-14 | Claude (Claude Code cloud session "GoldIntel Code", same session) | STATE UPDATE (S-074 holds except as below)
- Live check 2 of 0.6.1 (files attached in this session, logged out 13:30 local): passed except four bugs (D-117). Reload Now reloads on Forever (verified). Boss encounter NOT tested.
- Bug (1), measured in the trace: every re-show came 60.3 s after the previous "shown", so the timer counts from the show, not the close; the "click=ignore" lines logged in the same instant as a "shown" are most likely the client cancelling the open popup when it is shown again (StaticPopup "override" cancel, inferred from the client's popup code), not clicks.
- Restart rule updated (CODE_STANDING_ORDERS.md section 3, D-117): /reload is enough on Forever for added TOC files and new events.
- 0.6.2 PROPOSED (fixes for bugs 1 to 4, Phase4_P4-M3_LiveCheck2.md on p4/m2-live); NOT built, NOT approved.
PENDING (needs Shawn): approve (or not) the 0.6.2 proposal; boss-encounter test in the next live check; EmpireIntel screenshot (later).
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, 0.6.1-passive), merged only after 0.6.2 passes. Merged and kept: #1 to #8, #10 to #22 and this docs PR.
INSTALLED: 0.6.1-passive.
SHAWN'S NEXT STEP: reply on the 0.6.2 proposal.

## S-074 | 2026-11-14 | Claude (Claude Code cloud session "GoldIntel Code", same session) | STATE UPDATE (S-073 holds except as below)
- D-116 (user's words in Decisions.md): session permissions paragraph now at the top of the NEXT_SESSION_PROMPT.md box and quoted in CODE_STANDING_ORDERS.md section 2; the `.claude/settings.json` change is DROPPED (a session never changes permission settings files).
- PR #21 merged with the REST command (08260ff; main tests 1,343 passed). This docs PR merged under the docs-only standing approval; main merged into p4/m2-live afterwards (documents only).
- INSTALLED: 0.6.1-passive (user, 2026-11-14); live check 2 in progress.
PENDING (needs Shawn): live check 2 report with files ("logged out, check"); EmpireIntel screenshot (later). PR #9 merged only after he reports the live check passed.
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, 0.6.1-passive). Merged and kept: #1 to #8, #10 to #21 and this docs PR.
SHAWN'S NEXT STEP: finish live check 2 on 0.6.1, then "logged out, check" with files attached.

## S-073 | 2026-11-14 | Claude (Claude Code cloud session "GoldIntel Code", same session as S-072) | STATE UPDATE (S-069..S-072 hold except as below)
- Live check 1 of 0.6.0 (files attached in this session): passed version, agg status, agg check 0, map.worldsize, afk/resume, activity, ledger check 0 over 5,161 s; five problems found (D-115; Phase4_P4-M3_LiveCheck1.md).
- D-114 (standing permission, user's words in Decisions.md, CODE_STANDING_ORDERS.md section 2, NEXT_SESSION_PROMPT.md). The `.claude/settings.json` change was REFUSED by the session's permission check ("Permission for this action was denied by the Claude Code auto mode classifier. Reason: [Unauthorized Access]"): the user applies it himself. With his approval in chat the edit tools worked for code and docs.
- D-115: 0.6.1-passive (contract 1.16.0) built on p4/m2-live: item-info filter, stepped back-fill, non-overlapping time classes (total = session, test), agg top by gold per hour, reload popup with bands, Settings window (option A), encounter events (G10). 1,391 tests pass; Lua 5.1 parse ok. Package GoldIntel_0.6.1_passive_AddOns.zip built from the branch head and sent.
- D-114, D-115, this section, TODO and the standing orders also went to main through a docs-only PR (D-105/D-108).
PHASE: Phase 4 P4-M3 live check 2 (0.6.1). 3b-4 after 0.6.0 (D-112), NOT started. Plan only: soft travel across zones, retention, UI.
PENDING (needs Shawn): install 0.6.1 (FULL restart), play, report live check 2 with files; apply `.claude/settings.json`; EmpireIntel screenshot (arrived as the placeholder "[attach one]").
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, 0.6.1-passive, ahead of main). Merged and kept: #1 to #8, #10 to #20 and this session's docs PR.
INSTALLED: 0.6.0-passive on the Paladin (live check 1); other characters as the user last said (0.5.6).
OPEN QUESTIONS: reload from a button click on Forever; StaticPopup with three buttons; ENCOUNTER_START/END registration; which add-on sends the item flood (TSM or Auctionator, not shown in the files); in-game CPU of 0.6.1.
SHAWN'S NEXT STEP: install 0.6.1 as in the S-073 report, play, then "logged out, check" with files attached.

## S-072 | 2026-11-14 | Claude (Claude Code cloud session "GoldIntel Code", new session; the S-071 session makes no further commits, D-105) | STATE UPDATE (S-069..S-071 hold except as below)
- First report (read-only) verified S-071: main e1e6498 = 0.5.6-passive, contract 1.14.0, 1,343 tests; PR #9 head was 971971d (a second docs-only merge of main after #19), 1,365 tests, addon files identical to e6946b0.
- D-113 (user's words in Decisions.md): document gaps fixed on #9's branch; TOC `## Notes:` updated; trace.keep now holds only the final and MISMATCH `EVT agg` / `EVT clock` lines (one test, three mutation checks); Project_Bible header and inventory updated (on #9's branch). 0.6.0-passive APPROVED TO INSTALL for the P4-M3 live check; PR #9 merged ONLY after the user reports the live check passed.
- 0.6.0-passive amended on p4/m2-live (version unchanged: never delivered before): 1,369 tests pass; all addon files parse under Lua 5.1. Package GoldIntel-0.6.0-passive.zip built with tools/build_package.py from a clean checkout of the branch head and sent to the user.
- D-113 and this section are also on main through a docs-only PR (D-105/D-108 standing approval, includes the TODO.md corrections). D-101, D-102 and S-063 reach main with #9.
PHASE: Phase 4 P4-M3 (live validation) starts when the user installs 0.6.0. 3b-4 after 0.6.0 (flight fares, postage, AH deposits; D-112), NOT started.
PENDING (needs Shawn): install 0.6.0 (FULL restart), play normally, then "logged out, check" with the account file and character files attached; say whether the live check passed. Then approve nothing more for #9: the merge follows his report (D-113).
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, ahead of main: 0.6.0-passive, D-101, D-102, S-063, Bible update). The docs PR of this session merged. Merged and kept: #1 to #8, #10 to #19 and that docs PR.
INSTALLED: 0.5.6-passive on all characters until the user installs 0.6.0.
OPEN QUESTIONS: map.worldsize and the 8 yd/s soft-travel speed (settled from EVT clock speed buckets in P4-M3); in-game CPU of 0.6.0 (expected about 0.02 ms per frame, budget 0.017 + 0.05); reload frame times with the larger account file.
SHAWN'S NEXT STEP: install 0.6.0 as in the S-072 report, play, then "logged out, check" with files attached.

## S-071 | 2026-11-14 | Claude (Claude Code cloud session "GoldIntel Code") | STATE UPDATE (S-069, S-070 hold except as below)
- PR #18 merged (ce3568c). D-112 recorded with the user's words.
- PR #9 (0.6.0-passive, contract 1.15.0) brought up to date with main: merge commit 1221a7c on p4/m2-live (documents only), then the review document a377cd4 (GoldIntel_Docs/Phase4_P4-M2_Review.md, on the branch only). 1,365 tests pass. NOT merged, NOT approved, no package built. Mergeable against main; each later docs merge to main may conflict in documents again (resolve on the branch).
- Measured on the user's real Paladin records (desktop Lua): back-fill 4,693 records in 8.7 ms, +80 KB saved; simulated 8 h: 0.0003 ms per frame, +7 KB per hour saved. Expected in game about 0.02 ms per frame against the 0.017 baseline (budget +0.05). Not measured in the game: that is P4-M3.
- 3b-4 after 0.6.0: flight fares, postage, AH deposits (D-112).
PENDING (needs Shawn): approve (or not) installing 0.6.0 (full restart; starts P4-M3), and whether that also covers merging #9 after the live check; decide the minor trace.keep finding.
BRANCHES AND PULL REQUESTS: #9 open (p4/m2-live, head after this session's merges). Merged and kept: #1 to #8, #10 to #18 and this docs PR.
INSTALLED: 0.5.6-passive on all characters.

## S-070 | 2026-11-14 | Claude (Claude Code cloud session "GoldIntel Code") | STATE UPDATE (S-069 holds except as below)
- PR #16 (baseline report) merged with the REST command: main = b3bf686, 0.5.6-passive, 1,343 tests pass.
- D-111: Auctionator and TSM are installed on the user's client; the price plan is in Phase 6 as plan only (TODO 6.1a); Phase 6 NOT authorized; PR #9 stays unapproved.
- Accountant Classic cross-check done (file attached this session): GoldIntel's net equals Accountant's own daily balance change to the copper (Paladin 11-12..11-14, alt 11-11); the differences are Accountant's gross pairs and category names. GoldIntel's OTHER spending is mostly flight fares, postage and AH deposits (3b-4 sinks). The report's section 7 update is on its own PR (outside the docs-only approval).
PENDING (needs Shawn): 1. Review and approve (or not) PR #9 (0.6.0). 2. Approve merging the report update PR. 3. 3b-4 priorities when wanted (the cross-check shows flight fares are the largest OTHER item).
BRANCHES AND PULL REQUESTS: #9 open, unapproved, behind main. This docs PR merged under D-105/D-108. Report update PR open. Merged and kept: #1 to #8, #10 to #16.
INSTALLED: 0.5.6-passive on all characters (behaviour identical to main).

## S-069 | 2026-11-14 | Claude (Claude Code cloud session "GoldIntel Code") | FULL CURRENT STATE (read this first)
Standing orders: CODE_STANDING_ORDERS.md (D-103, D-105, D-106, D-108, D-110). New-session prompt: NEXT_SESSION_PROMPT.md.

THIS SESSION
- Read the user's files of 2026-11-14 (account file, three character files; 0.5.6, client build 70938). Baseline PASSED (D-109): Paladin 39.9 h loaded on 0.5.6, 224 periodic samples, 0.017 ms per frame; every 0.5.6 check 0; 0 collector errors; the two MISMATCH lines are from 2026-11-05 (0.5.1). Details: archive/Baseline_0.5.6_Report.md (separate PR, needs the user's approval: a new report file is outside the docs-only standing approval).
- Merged PR #8 (2ecc6cc) then PR #7 (4c78dbe) with the REST command, each after merging main into its branch (docs conflicts only). Tests on main: 1,343 passed, 0 failed.
- Recorded D-110 (other add-ons: copy and credit where allowed, clean room otherwise, cross-checks, optional plugins) with the user's words.

PHASE AND INCREMENT
- Phase 3b: 3b-0..3b-3 CLOSED; 3b-4 NOT started. Phase 4: P4-M1 merged (not loaded); P4-M2 = 0.6.0-passive on PR #9, NOT approved; P4-M3 not started.

APPROVED: D-087..D-110 (user's words in Decisions.md). PR #9 NOT approved.

PENDING (needs Shawn)
1. Review and approve (or not) the 0.6.0 build, PR #9. It is behind main now; main must be merged into it first (documents conflict).
2. Attach Accountant Classic's SavedVariables file for the cross-check (D-110).
3. Decide the price plan (report section 6). Plan only.
4. Approve merging the report PR (archive/Baseline_0.5.6_Report.md).

BRANCHES AND PULL REQUESTS (main = 0.5.6-passive, contract 1.14.0; P4-M1 files present, not loaded)
| PR | Branch | Content | Matches main |
|---|---|---|---|
| #9 | p4/m2-live (e6946b0) | 0.6.0-passive (P4-M2), D-101, D-102 | no: ahead, and behind main since #7/#8 merged |
| this | docs/baseline-2026-11-14 | D-109, D-110, standing orders 9, prompt, TODO, this section | merged under D-105/D-108 |
| report | docs/baseline-report-2026-11-14 | archive/Baseline_0.5.6_Report.md | open, needs approval |
Merged and kept: #1 to #8, #10 to #14 and this one.

INSTALLED: 0.5.6-passive (6620666) on all characters (user, D-107). Behaviour identical to main (main adds only the unloaded P4-M1 files). Client 1.60.1, build 70938 (new since 70862), Interface 16001.

OPEN QUESTIONS
- 312 ms frame (2026-11-14 00:08-00:18 UTC) and the second >100 ms frame: garbage collection of the 1.2-1.5 GB shared Lua heap charged to GoldIntel (inferred: heap shrank in both windows; the rolling trace had rotated out). Not network lag: the profiler counts CPU time inside the add-on.
- /reload load frames 100-178 ms (cause not measured).
- GoldIntel's own memory is not in the 0.5.6 automatic samples (D-100); last measured 6.6-14.3 MB (0.5.5, 2026-11-08) of a 0.53-1.4 GB heap. `/gi perf` reads it on request.
- C_Map.GetMapWorldSize in Forever unverified; soft-travel speed 8 yd/s an assumption. OI-16 deferred; OI-17 open.
BLOCKERS: none.
SHAWN'S NEXT STEP: reply on the four pending items; keep playing on 0.5.6 (no install needed).

---

Older sections (S-001 to S-068, 2026-10-09 to 2026-11-08): archive/Session_Handoff_history_to_S-068.md.
