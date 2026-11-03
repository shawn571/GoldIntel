# GoldIntel: Handoff to the Claude Code cloud session

WRITTEN: 2026-11-02 (user's local time, evening) by Claude, lead architect and lead developer, in the claude.ai
conversation where GoldIntel was built. The next session cannot see that conversation or the user's saved memory.
This file is the bridge. It is a handoff, not a decision: where it conflicts with Project_Bible.md (governance) or
Requirements_v1.md (scope), those win. Where it conflicts with the repo, the repo wins and the difference must be reported.

Evidence tags used below:
- **[verified]** I checked it against the repo, the package, or the user's installed folder while writing this file (2026-11-02).
- **[stated]** the user told me, in this chat, in a recorded message. It is not independently checkable from the repo.
- **[recorded]** written in a repo document (named), not re-derived today.
- **[assumed]** my belief, not confirmed. Do not rely on it.

---

## 1. Snapshot (all [verified] unless marked)

| Item | Value |
|---|---|
| Product | GoldIntel, a gold analytics addon for WoW: Forever (client 1.60.1, Interface 16001, Lua 5.1) |
| Repo | github.com/shawn571/GoldIntel, **private**, MIT license (copyright Shawn Robinson) |
| `main` HEAD | The **last code commit is `a21e071`** "0.5.1: context event lines and periodic ledger check in the trace". Commits after it are docs-only (the one adding this handoff and the opening prompt). `git diff a21e071 HEAD --stat` must show only files under GoldIntel_Docs/. Local and remote agreed when written. |
| Commit history | 912a5d6 initial import (0.4.7) > 8de6ce2 MIT > fa78ade copyright holder > eed0156 0.5.0 > a21e071 0.5.1 > (docs-only handoff commit) |
| Addon version | `0.5.1-passive` (`P.VERSION` in GoldIntel/Platform/Platform.lua and `## Version` in GoldIntel.toc) |
| Contract version | 1.9.0 (`P.CONTRACT_VERSION`; Contracts.md header still says 1.8.0, see section 11) |
| Store schema | 2 (additive; the 0.3.8 build still runs on current data, tested at 0.4.7) |
| Other addons in repo | GIMin 1.0, GoldIntelDiag 1.8, GIProbeLoot 0.1.0 (diagnostics only, never in AddOns during live validation) |
| Tests | **1,255 passed, 0 failed** (run 2026-11-02 on main). Run from `GoldIntel/Tests`: `texlua run.lua [substring] 2>&1 \| cut -c1-250 \| grep -E -A4 "^FAIL\|passed"`. The harness runs on Lua 5.4 (texlua); the game runs 5.1. |
| Build tool | `python3 tools/build_package.py` (ROOT = folder containing GoldIntel/, GIMin/, GoldIntelDiag/, tools/). Writes `GoldIntel_Phase2_AddOns.zip` and `GoldIntel_Phase2_Dev.zip` into ROOT; checks every TOC-listed file. The zip names are historical. |

## 2. Current phase and increment

- **Phase 3b** (ledgers only, D-067), increment **3b-3 (item lots)**. 3b-0, 3b-1, 3b-2 are closed (D-076, D-079). [recorded: Decisions.md]
- 3b-3 milestones: M1 pure modules (done), M2 trace-only evidence (done, user approved), **M3 lot book stored (built, validated live, user APPROVED 2026-10-31, D-086)**.
- **M4 (measurements: lot size, CPU, memory; 3b-3 closure recommendation) is NOT authorized.** The user must say so explicitly.
- Between M3 and M4 the user asked for a **passive-play build** for the live launch (0.5.0, 0.5.1). That was built and installed on 2026-10-31 under D-086. It is part of the M3 approval, not a new increment.
- Not started and not authorized: 3b-4 (AH, COD, outgoing mail; needs the D-068 verification addendum first), Phases 4 to 9. [recorded: TODO.md, Decisions.md]

## 3. What is approved and what is not

**Approved by the user** (Decisions.md has the full text; IDs only here):
- Phases 1, 2 (closed with exceptions PX-1..PX-8, D-056), 3a (closed with exceptions X-A..X-H, D-066).
- Phase 3b scope D-067; increments 3b-1 (D-076) and 3b-2 (D-079) closed.
- 3b-3: scope D-080, D-081 (item side = acquisition and conversion accounting, not a mirrored inventory), D-082, D-083 (cursor put-back and `unexplained` are relabel-only: "other additions: moves, returns, unknown"), D-084 (M3 scope), D-085 (money pairing), D-086 (M3 approved, passive-play mode, plus the 0.5.1 addendum).
- Standing product principles: D-063 (three value views), D-061 (heat scope toggle), D-064 (economic vs location attribution), D-065 (reconciliation window 1.0 s).
- License MIT. GitHub as the repo and issue tracker. [stated, this chat]

**NOT approved:**
- M4 and the 3b-3 closure. 3b-4. Phases 4 to 9. Any change to Requirements_v1.md.
- D-062 (disenchanting valued through lots and a price source) is still **Proposed**, not approved. D-071 (disenchanting recorded, not revalued, in Phase 3b) is what is in force.
- Making the repo public. Releasing to other users. Discord announcements. [stated: private while testing]
- Any project-management tool beyond GitHub issues (Linear and YouTrack were offered; the user chose GitHub only).

## 4. Open decisions (need the user)

1. **M3 closure and M4.** The M3 report is delivered (Phase3b_3b-3_M3_Report.md). The user approved M3 but has not asked for M4. Do not start it.
2. **How evidence reaches the Code session.** In the chat session I read GoldIntel SavedVariables straight from the user's linked WoW folder. A cloud Code session probably has no such link [assumed]. The user must choose: attach the file(s) each time, commit them to a gitignored `evidence/` folder, or link the computer if the Code session supports it. See section 7.
3. **Beta data on the live account.** The user's SavedVariables hold beta characters and beta lots. Whether live servers start from a clean database, keep the data, or mark it as beta was never discussed. [open]
4. **Roll-awarded items won by the player.** Only another player's roll was ever observed. User ruled it low risk and non-blocking. If it appears in live play, decide how it is labeled.
5. **Unsourced money sinks for 3b-4** (taxi, trainer, respec, barber, guild bank, repairs). TODO.md 2026-10-18. Each needs a live signal check.
6. **Stale OI items** still open in Decisions.md: OI-5 (merge pre-existing documents), OI-9, OI-10 (TOC interface list policy), OI-11 (re-probe after each client patch and at launch), OI-13 (external review documents), D-027 and D-028 (legacy removal, interface policy).
7. **Discord and tracker content** the user may still want: announcement text, install steps, known issues, bug-report how-to, an issue list of open items, private test group vs public release. Offered, never answered.

## 5. Known bugs, risks and open evidence

Nothing below is a confirmed defect in released behavior except where marked. All [recorded] unless noted.

- **0.5.0 and 0.5.1 have never run in the real client.** [stated: the beta ended 2026-10-21 and the user said he would not play again until the November 4 launch; the builds were made 2026-10-31] They passed 1,255 tests in the harness only. The auto start 3 s after login, the 2-second group poll, the P_TICK listener, the periodic check and the bigger trace are all unproven live. Treat the first live login as a validation event.
- **First `/reload` crash on the M2 build (0.4.1).** The client crashed once when the user typed `/reload`. Not reproduced, cause unknown. The M2 trace may not have saved. [stated + recorded]
- **Item 279912 never becomes ready** in the client's item info (so it stays "unknown"). Cause unknown.
- **Empty loot windows** (src=unknown, 0 items) are unexplained.
- **Gathering spell names at other ranks** are verified only for skinning (8617 / 8613, name "Skinning"). Herbalism 2366, mining 2575, fishing 7731 are known by id only; other ranks arrive through the `CAST` trace line. Name matching is the mechanism (`Unit.SpellName`).
- **Roll-won items** (see 4.4). **Groups of 3 or more**, out-of-range members, one player looting several corpses. **Silver/gold chat wording** of loot shares. **Real logout/login with the final lastMoney logic**, trade, buyer COD payment, AH sale mail, full-bag coin. (TODO.md 3b-2 post-closure backlog; user policy D-079: these are bug fixes, not blockers.)
- **Trace growth.** Trace cap is now 3000 lines plus a 400-line `trace.keep` list per character. I did not measure SavedVariables size growth or whether `prune.maxBytes` covers the trace. [assumed: tens to hundreds of KB per character; unmeasured]
- **Installed TOC label mismatch** [verified 2026-11-02]: on the user's machine `GoldIntel.toc` reads `## Version: 0.5.0-passive` while the six code files I installed match 0.5.1 byte for byte. I wrote the 0.5.1 TOC; the device copy says otherwise and I could not explain it. Effect is cosmetic (the AddOns list label; `/gi version` reads `P.VERSION`). Left unfixed because I was told not to change code. Re-copy `GoldIntel.toc` from main or have the user reinstall.
- **Beta-to-launch drift** (R-08, OI-11): the interface number, build, realm model or APIs may change at launch. Re-probe at launch with `/gi caps`; update `## Interface:` if the client calls the addon out of date.
- **R-21:** the client writes SavedVariables only at logout or `/reload`. A crash loses the session's unsaved data.

## 6. Package and repo state

- `main` is the source of truth from now on (code as of a21e071). [verified]
- **The 0.5.1 package matches main**: `GoldIntel_0.5.1_passive_AddOns.zip` (built 2026-10-31 from the same tree) has GoldIntel/ and GIMin/ byte-identical to main (Tests excluded by design). GoldIntelDiag/ differs only in `MANIFEST.txt` and `SrcCurrent.lua`, which are regenerated on every build (timestamps and embedded source), not source changes. [verified]
- The zips are build output and are **gitignored**; they live only in the chat session's `/mnt/user-data/outputs` and were sent to the user. Rebuild with the build tool. Older packages exist there too (3b0..3b3_M3, 0.5.0, 0.5.1) and are not in the repo.
- **Installed on the user's machine** (`C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\GoldIntel`): I replaced exactly six files on 2026-10-31: GoldIntel.toc, Platform/Platform.lua, Core/Config.lua, Collect/Collector.lua, Ledger/Ledger.lua, Ledger/Trace.lua. Five now match main byte for byte [verified]; the TOC reads 0.5.0 (see section 5). Other files in that folder are the 0.4.7 build. [verified for the six; assumed for the rest, since 0.4.7 files were unchanged between 0.4.7 and 0.5.1 in the repo history]
- GIMin is installed there too. GoldIntelDiag and GIProbeLoot are **not** installed (rule). [verified by the AddOns directory listing on 2026-10-31: GIMin and GoldIntel present, no GoldIntelDiag or GIProbeLoot]
- Repo contents: GoldIntel/ (addon + Tests), GIMin/, GoldIntelDiag/, GIProbeLoot/, tools/, GoldIntel_Docs/, README.md, LICENSE, .gitignore, .github/ISSUE_TEMPLATE/bug_report.yml. `.gitignore` excludes SavedVariables, `*.lua.bak`, WTF/, evidence/, GoldIntel_Docs/evidence/, `*.zip`.
- **Privacy:** the repo is private and must stay private until the docs are scrubbed. One real character GUID (`Player-4618-…`) is in Compatibility_Notes.md and Phase1_PostValidation_Review.md. Not yet scrubbed. [verified by grep]
- Commit style: end commit messages with the attribution lines the Code session is given. Past commits used `git -c user.name="Claude" -c user.email="noreply@anthropic.com"`.

## 7. What is left before the November 4 launch

None of this is approved work beyond what is marked; it is my list for the user to confirm.

1. **Confirm the installed addon.** Re-copy `GoldIntel.toc` so the label reads 0.5.1-passive. Confirm the AddOns folder holds GoldIntel and GIMin only. (Small, user approval first.)
2. **Launch-day client check.** After patching, run `/gi caps` and `/gi version`. Compare the game version, build and Interface number with 1.60.1 / 16001 (Compatibility_Notes.md). If the client reports the addon out of date, the `## Interface:` line needs updating (OI-10, OI-11, R-04, R-08). Confirm the live client folder is still `_forever_`.
3. **First live login is a validation event for 0.5.x.** Expect one chat line "GoldIntel: recording started automatically ..." about 3 s after login. Any "UNEXPECTED item condition" line is a bug report to capture. `/gi ledger check` should read difference 0 copper. `/gi collect off` and `/gi config set collect.auto false` are the escape hatches.
4. **Decide the beta-data question** (4.3) before the user starts real characters, or at least before analysis.
5. **Decide how evidence reaches the Code session** (4.2). I will not have the device link there.
6. **Optional, user decides:** the GUID scrub; the Contracts/README catch-up (section 11); a release plan for Discord users.
7. **Do not start** M4, 3b-4 or any new feature before launch unless the user says so. The user's stated aim is to play normally and have the data analyzed afterwards.

## 8. Working rules (the contract between the user and Claude)

### Roles (Project_Bible 2.1, D-032)
- **User (Shawn Robinson):** project sponsor, project manager, client tester, final decision authority. Approves phases and decisions, runs the real client.
- **Claude:** lead architect and lead developer. Source of truth for requirements, architecture, contracts, code, changelogs and governance documents.
- **ChatGPT:** independent reviewer (risk, architecture, runtime evidence, phase gates). Advises only.
- **Gemini:** platform and WoW Forever compatibility analyst. Advises only.
- External findings are peer-review input: each gets accepted / rejected / partially accepted with a technical justification and is logged in `GoldIntel_Docs/reviews/External_Review_Log.md`. Architecture is never changed solely because another AI suggested it. Reviewers cannot approve a gate. (Project_Bible 2.1.)

### Gates and approvals
- Work only on the phase named in TODO.md. **Never start the next increment or milestone before the user approves it.** The user's approvals are explicit sentences ("I approve M2", "M3 is approved to begin"). Do not infer approval from silence or from a related approval.
- Each approval is recorded as a decision in Decisions.md (append-only; supersede, never delete).
- Precedence: Requirements_v1 > Decisions > Architecture; Contracts wins on data shapes; Compatibility_Notes wins on client facts; newest Session_Handoff wins; a dated user instruction beats everything and is recorded as a decision. A conflict you cannot resolve: stop, list it as an OPEN ISSUE, ask the user.
- Governance changes need: why, affected modules, migration (schema, contracts, tests), a Decisions entry.
- Mandatory reading order (Bible section 3): Project_Bible, Requirements_v1, Decisions, Changelog, TODO, latest Session_Handoff, Architecture, Contracts.
- **Every session ends** with: an appended Session_Handoff section, and updates to Changelog, TODO and (if applicable) Decisions. Contracts change in the same change as the code (D-031).

### Evidence discipline
- Measured behavior is authoritative over documentation or memory. Evidence first; no heuristics and no guessing of ids or client behavior. An unverified claim stays [assumed] and becomes a probe or a question.
- **Hard requirement:** the cash ledger and the real balance differ by **0 copper** (`/gi ledger check` shows "DIFFERENCE 0 copper (OK)"). Cash and item pipelines stay isolated: lots never write cash (AC-15, tested: the lot book source must not reference GI.Cash, Reconciler, Expectations or Sources).
- Any unexpected condition surfaces **visibly** as a bug report (one chat line per kind per session: "UNEXPECTED item condition: ... please report it as a bug", a trace line every time). Never hide it.
- Item side is an **economic ledger, not an inventory mirror** (D-081): where value came from, where it went, profit or loss. Equip, cursor, bag moves, manual reagent moves, destroying low-value items are not tracked unless needed for acquisition and disposition accuracy. Favor simplicity.
- Reporting priorities the user stated: the unexplained-money (OTHER) share **by value** matters more than by entry count; report both prominently.
- Core goal: find gold per hour of repeatable activities so a heat map shows where and with which activity gold is best. Account Best = the highest observed value, never an average; a separate per-character view so weaker characters do not distort it.

### Reload or restart (the user asks for this every time)
Whenever a new addon package or file set is delivered, say plainly which is needed:
- **`/reload`** is enough when only existing `.lua` files change and the TOC file list is unchanged.
- **Full client restart** is required when a file is added to or removed from a TOC, when a new event is registered, or when unsure (restart is the safe choice).
State it in the same message as the package, and say which version the user should see in `/gi version`.

### Step-by-step test instructions
The user plays the real client and wants instructions he can follow exactly:
- Give every step as a numbered list with literal commands in code form (for example `/gi ledger mark`, `/gi lots status`). No "run the usual test".
- Say what the expected result is after each step, and what to copy back (which output, which file).
- Include `/gi ledger mark` where a check needs a baseline (0.5.0 and later start every interval marked automatically, so it is no longer needed after auto start).
- He often plays several characters and cannot repeat a test on all of them; design tests per character role when needed.
- From the live launch he wants **no test scripts**: play normally; data is collected passively; the assistant analyzes after `/reload` or logout and says when a package is ready or a decision is needed.
- GIProbeLoot and GoldIntelDiag stay out of AddOns during live validation.

### Delivery and style
- Deliver packages as zips built by the build tool; send files to the user, do not just describe them. Say what the package contains and whether it matches main.
- **End every stage with a package block (user rule 2026-11-03, D-090).** Whenever a stage is finished, the last part of the message is the latest addon version as a ready-to-install package: (1) the version string `/gi version` will show; (2) whether it matches main, naming the commit; (3) `/reload` or full restart; (4) the exact install steps; (5) how to roll back; (6) the zip itself, or how to get it. If nothing in the addon changed, say "unchanged, 0.5.1-passive is current" (with the then-current version) and still give the whole block. Build with `tools/build_package.py` from a clean checkout of the commit (the tool rewrites `GoldIntelDiag/SrcCurrent.lua` and `MANIFEST.txt`, so do not run it in the working tree).
- Be plain and short with the user. Report outcomes, not effort. Say right away when a limitation changes what he gets.
- Do not narrate tool use or memory use. Do not guess; say what is unverified.
- Every change goes through tests; mutation checks guard Cash, Ledger and LotBook (Loader.override mutants). Boundary test forbids identifiers named like WoW globals. Money formatting must use `string.format('%d')` (Lua 5.4 floats).

## 9. Things that exist only in the chat or in memory

These are not (all) in the repo. The next session should treat the user as the source for any it needs.

- **The live evidence itself**: the user's SavedVariables and pasted traces from the beta (M2 and M3 sessions, 2026-10-19 to 2026-10-21) were not committed (`evidence/` is gitignored). The Docs summarize them (Compatibility_Notes E-numbers, M2/M3 reports). Raw files are in the chat session's `/mnt/user-data/uploads` and `outputs`, not in the repo.
- **The user's character and account layout** (three characters; WTF path `...\_forever_\WTF\Account\<account>\<id>\<char>\SavedVariables\GoldIntel.lua`, plus an account-wide `...\Account\<account>\SavedVariables\GoldIntel.lua`). Only one of the three character folders held a GoldIntel.lua on 2026-10-31 [verified, directory listing that day]. Do not put names in public docs.
- **The WoW install path** `C:\Program Files (x86)\World of Warcraft` with client folders `_forever_`, `_classic_era_`, `_classic_`, `_anniversary_`, `_retail_`, `_classic_beta_`. [verified listing 2026-10-31]
- **Memory facts** (user's saved memory, [stated]): name Shawn Robinson; GitHub account shawn571; ZIP 22192 (irrelevant here); WoW guild is the Countdown To Classic Podcast Discord community; Discord username Malifax; Twitch MalifaxForever; leaning Horde orc Enhancement Shaman main at launch; wants early gold for riding at level 40. GoldIntel facts in memory match this document.
- **EmpireIntel**: the user decided to build a second addon, EmpireIntel (passive alt-tracking, reusing GoldIntel lessons) in its own repo `shawn571/EmpireIntel`. It is a separate project; do not mix it into GoldIntel. The Claude GitHub App has access to all of the user's repositories. [stated, memory]
- **Chat decisions not written as D-numbers**: MIT license choice; copyright holder name (Shawn Robinson, replacing "shawn571"); GitHub chosen over other trackers; private repo until further notice; the 0.5.1 event lines are recorded in the D-086 addendum.
- **Evidence given only in chat** (also summarized in docs): enchanting materials have a nominal 1-copper vendor value in Forever; quest items bind type 4 with sell 0; "sell 0 and bind 0" means tradable but not vendorable (example: Sharpening Wheel 279944); items now go **directly** into the reagent bag (index 5) when looted (this superseded the user's earlier statement that they must be moved by hand); buyback appears as an ordinary vendor purchase at the sale price; apprentice skinning (skill 49) casts spell 8613, named "Skinning".
- **Tool limits met in the chat**: WebFetch could not read Wowhead pages (JavaScript-rendered, came back empty), so the user pasted lists instead. The workspace shell only reaches allowlisted hosts.
- **Scratch work**: `/mnt/user-data/outputs/GoldIntel` and `GoldIntel_Docs` hold the same tree as main (synced 2026-10-31); the repo is now the only authority. No unpushed work exists. [verified: working tree clean at a21e071]

## 10. Confirmed facts versus assumptions

**Confirmed [verified 2026-11-02]:** the last code commit a21e071 is on remote main and the working tree was clean; versions in Platform.lua and the TOC; 1,255 tests pass; the 0.5.1 zip matches main (excluding regenerated Diag files and excluded Tests); five of six installed files match main; the installed TOC reads 0.5.0; the AddOns listing of 2026-10-31 showed GIMin and GoldIntel only; the GUID text exists in two docs; README and Contracts.md header are stale (section 11).

**Confirmed by the user in the chat [stated]:** M2 and M3 approvals; passive-play request; MIT; GitHub; private repo; the item-side principle; the facts listed in section 9.

**Assumptions and unknowns:**
- 0.5.x behaves in the live client as in the harness. **Unproven.**
- The Code session cannot see the user's computer. [assumed; verify at session start]
- The launch client uses the same `_forever_` folder, Interface 16001 and the same APIs. [assumed; beta-to-launch drift is a recorded risk]
- Trace and SavedVariables size stay acceptable. [assumed, unmeasured; M4 would measure]
- Auto start does not slow login or interfere with other addons (the user runs about 60 addons). [assumed]
- The installed files other than the six I replaced equal the repo. [assumed]
- The first-`/reload` crash on the M2 build is not caused by GoldIntel code that still exists. [unknown]
- The doc statements about client facts in Compatibility_Notes.md are correct as of build 70450; later builds were not re-probed. [recorded, one build family only]

## 11. Document conflicts and staleness I know of (verify, then fix with the user's approval)

1. **Contracts.md** header says DOC and CONTRACT VERSION 1.8.0; code and the 1.9.0 section say 1.9.0. Also the 0.5.0/0.5.1 additions are **not in Contracts.md**: config key `collect.auto` (F6 list), `Collector.AutoStart`/`AUTO_DELAY`, trace `keep` list and `Trace.KEEP_CAP`, `EVT group|zone|vendor|mail|trade|ah|level|profs|check` lines, `Trace.GROUP_POLL`, `Trace.CHECK_EVERY`, `Ledger.Begin` now marks. D-031 says contracts change with the code; I did not do this. It is a process gap on my side.
2. **README.md** says "Everything is opt-in per session: nothing is recorded until you type `/gi collect on`" and "Phase 3b-3: item lots". Since 0.5.0 recording starts automatically unless `collect.auto` is false. Its install line also mentions `_classic_era_`.
3. **TODO.md** `IMPLEMENTATION APPROVED:` line says "only 3b-0 is started" and the header DOC VERSION/UPDATED date is old (2026-10-17); many early `[ ]` boxes are open for work that is finished. Its CURRENT PHASE line was updated.
4. **Session_Handoff.md**: the Bible says "append newest section at the top"; the file's top section is S-054 (2026-10-19) and the newest entries (S-054 M3, S-054 close, S-055 and its update) are appended at the **bottom**. Section numbering is S-054 for M3 and S-055 for 0.5.x. Newest by date wins: read the bottom. This file (`HANDOFF_Code_Session_2026-11-02.md`) is newer than all of them.
5. **Project_Bible.md** shows PROJECT VERSION 0.0.1-planning, DATE 2026-10-09, and names ChatGPT and Copilot while D-032 names ChatGPT and Gemini. Governance text is current; the version line is not.
6. **Requirements_v1.md** is frozen at 1.1.0 (2026-10-17). I made no changes in this period. Nothing is known to conflict.
7. **Tests that assume pre-0.5 behavior** were adjusted (config list order, session-records tail, ledger "no mark"). Any test written for "collect is off by default" must now account for the auto start after `AUTO_DELAY` seconds.

## 12. Architecture in one paragraph (so the next session can orient)

Cash pipeline: Platform events > Collect/Sources > Reconciler (turns every money delta into tagged cash entries, entries sum to the delta, 1.0 s reconciliation window) > Ledger/Cash (schema 2, closed). Item pipeline: Platform Bags/Items > Collect/BagDiff > Collect/ItemSources (decides add: loot, disenchantMat, quest, vendorBuy, mail, trade, unexplained; remove: vendorSale, questConsume, disenchantSrc, tradeOut, ignored; pairs each money event to one bag settle within 1.0 s, D-085) > Ledger/LotBook (creates and consumes lots; manual prices) > Ledger/Lots and Valuation (vendor value, no-vendor = 0, manual only if above vendor). Ledger/Trace is an evidence recorder with optional taps; it changes no decision. Collector registers the events (groups G1..G8), keeps a journal and quarantines a faulting event. Passive mode (0.5.x): Collector.AutoStart 3 s after login, every interval marked, trace window 3000 plus keep list. Platform/ is the only place that calls WoW APIs; modules talk through the Bus and Contracts.md. See Architecture.md, Contracts.md and the Phase3b_* documents.

## 13. Suggested first steps for the Code session (for the user to approve)

1. Read this file and Project_Bible.md; verify section 1 and 6 against the repo (`git log`, tests, versions, the TOC) and report any difference, plus anything in section 11 you confirm or dispute.
2. Do not change code or documents until the user approves.
3. If approved, the first candidate work (user's call): fix the TOC label, Contracts/README catch-up (section 11.1, 11.2), then wait for live data.
