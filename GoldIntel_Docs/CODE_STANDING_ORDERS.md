# GoldIntel: standing orders for every Claude Code session

Set by Shawn (sponsor, project manager, tester, final decision authority), 2026-11-08, effective at once. Quotes are
Shawn's own words; short notes in brackets say where a rule is recorded. If a project document conflicts with these
orders on how to work, these orders win; on scope, Requirements_v1.md wins; the Project Bible's precedence table
decides the rest. A conflict that cannot be settled: stop and ask Shawn.

## 1. Roles

- Shawn: "I am Shawn, the sponsor, tester and final decision authority" (opening prompt), also project manager. He
  approves phases, increments, builds, merges and decisions, and runs the real client.
- Claude: "You are the lead architect and lead developer for GoldIntel" (opening prompt). Claude owns requirements,
  architecture, contracts, code, changelogs and the governance documents (Project_Bible 2.1, D-032), and gives a
  recommendation with the evidence; Shawn decides.

## 2. Gates and approvals

- "never start the next increment before I approve it." The same holds for milestones, builds and merges: "Do not
  merge or start any build beyond 0.5.6 until I approve" (2026-11-08) is the pattern: nothing is merged, built,
  installed or started without an explicit approval for exactly that step.
- "no code change without my approval of a proposal; changes go on a branch with tests and a pull request" (2026-11-03).
- "copy files into my AddOns folder only after I approve that specific build, and say /reload or restart for each;
  nothing on my computer outside that folder" (2026-11-03). SavedVariables are read-only: "never write to WTF or
  SavedVariables" (2026-11-03).
- Approval is an explicit sentence. Silence, a related approval or a question is not approval. When a reply is
  ambiguous or arrives incomplete (for example an unfilled template), act on what is clear, do not guess the rest, and
  ask in the same report.
- Every decision Shawn makes in chat is recorded in the docs (Decisions.md, with the date) **with his exact words**.
  If something he decided exists only in chat, list it in the report so he can confirm it.
- Standing merge approval (D-105): "you may merge docs-only pull requests that change only Session_Handoff.md,
  NEXT_SESSION_PROMPT.md, CODE_STANDING_ORDERS.md or the recording of my decisions; tell me each time. Code, versions
  and other merges still need my explicit approval."
  Extended (D-108, 2026-11-08): "Extend the docs-only standing approval to also cover TODO.md and Changelog.md. Record it with my words, then update TODO.md now and merge it under that approval."
  Covered files: Session_Handoff.md, NEXT_SESSION_PROMPT.md, CODE_STANDING_ORDERS.md, Decisions.md (recording his
  decisions), TODO.md, Changelog.md. A pull request that touches any other file is not covered.
- Standing permission (D-114, 2026-11-14): "GoldIntel Code always has permission to edit code and docs, run tests, build packages, commit and push to work branches. My approval of an increment or fix in chat is the go-ahead to do all of that for it. Merges still follow the merge rules; never push to main or force-push."
  The `.claude/settings.json` change of D-114 is dropped (D-116). Per session the user pastes the paragraph at the top
  of NEXT_SESSION_PROMPT.md (D-116): "Standing permissions from me, for this whole session: you may edit code and docs, run tests, build packages, commit, and push to work branches without asking (never push to main, never force-push, never change permission settings files). When I approve an increment, fix or merge in this chat, that is my explicit approval to do it, including merging that pull request yourself with the REST merge command. Docs-only pull requests (Session_Handoff, NEXT_SESSION_PROMPT, CODE_STANDING_ORDERS, Decisions, TODO, Changelog) you may merge yourself under my standing approval."
  Never change permission settings files. If a tool is still refused, quote the exact command and message in the report.
- How merges are done (D-106, 2026-11-08): "Once I approve a merge in chat, you merge it yourself through its pull request (gh pr merge <n> --merge; no squash, no rebase, no direct push to main), then check main and report the merge commit and the test result. Approval is still required for every merge except the docs-only standing approval. Commits and pushes to work branches need no approval. Never force-push or delete branches."
  In practice: a merge commit through the pull request only; after it, fetch main, name the merge commit and run the
  test suite on it (`lua5.4 run.lua` from GoldIntel/Tests) in the report.
- The merge command (D-106 addendum, D-118): `gh api -X PUT repos/shawn571/GoldIntel/pulls/<n>/merge -f merge_method=merge`
  is THE merge method: GitHub GraphQL, which every `gh pr` command needs, is refused in this environment ("HTTP 403:
  GitHub GraphQL is not available from Claude Code sessions"). Pull requests are listed and opened with `gh api` too.
  Shawn's addendum words: "While gh pr merge is refused: use the REST merge endpoint (gh api -X PUT repos/shawn571/GoldIntel/pulls/<n>/merge -f merge_method=merge), a merge commit through the PR, never a push to main."
  Any other refusal: report the exact message and do not merge by another route.

## 3. Packages: the reload-or-restart statement

Every package says plainly which is needed (rule updated by D-117, 2026-11-14):
- `/reload` is enough on the WoW Forever client (1.60.1, build 70938) for changed `.lua` files, files added to or
  removed from the TOC, and newly registered events. Evidence: 0.6.1 added two TOC files and two events and was taken
  in with `/reload` alone (user, live check 2, 2026-11-14; EmpireIntel D-034 found the same).
- A full client restart is still required for a NEW add-on folder (the client lists add-ons at startup), a change to
  the TOC's `## SavedVariables` lines or `## Interface`, after a client patch, or when unsure. [These cases are not
  re-tested on Forever; kept as the safe default.]
- If a /reload is not enough after all, the package block says so in the next report and the rule is corrected.
It also says which version `/gi version` will show. Packages are zips built by `tools/build_package.py` from a clean
checkout of the commit, and the files are sent to Shawn, not only described.

## 4. Test steps and evidence

- When Shawn has to do something in the game: a numbered list with literal commands in code form (for example
  `/gi ledger check`), the expected result after each step, and exactly what to copy back. No "run the usual test".
- Since the live launch Shawn plays normally: no test scripts unless he asks; data is collected passively and read
  after he logs out or types `/reload` and says "logged out, check" (D-087). Read his GoldIntel SavedVariables
  read-only, `trace.keep` first, and the cash check (difference must be 0 copper).
- Evidence first: measured behavior beats documents and memory. No guessing of ids or client behavior; an unverified
  claim is marked as such and becomes a check or a question. The cash ledger must match the real balance to 0 copper.
  Unexpected conditions are shown, never hidden.

## 5. The package block (end of every report, D-090)

"whenever you finish a stage, end with the latest addon version as a ready-to-install package: the version string /gi
version will show, whether it matches main (name the commit), /reload or full restart, the exact install steps, how to
roll back, and the file itself or how to get it. If nothing in the addon changed, say 'unchanged, 0.5.1-passive is
current' and still give that block." (2026-11-03; the version named is the then-current one.)

Format:
- **Version:** ... (`/gi version` will show ...)
- **Matches main:** yes/no, commit ...
- **Reload or restart:** ...
- **Install steps:** numbered
- **Roll back:** ...
- **File:** attached, or how to rebuild it

## 6. Every report (2026-11-08)

1. "Update Session_Handoff first: current phase and increment, what I have approved and what is pending, the state of
   every branch and PR and whether each matches main, installed versions as far as I have told you, open questions, and
   my next step. Commit and push it, and say so."
   Exception (D-105): "a new session's first report is read-only." The first report verifies and reports; it changes,
   commits and pushes nothing, the handoff included. 6.1 applies from the second report on.
2. "Tell me when to start a new Code session: if your context has been summarized, or a session has run long, and only
   at a clean stopping point with nothing half-built and nothing unpushed. Then say 'start a new session now', confirm
   the handoff and NEXT_SESSION_PROMPT.md are pushed, and print the exact prompt for me to copy."
3. "End with three short parts: 'What you do' (plain language, numbered), 'Reply to send' (ready to paste), and the
   package block. Keep reports short; long evidence goes in files in the docs folder."

## 7. Keeping this permanent

- This file and `NEXT_SESSION_PROMPT.md` live in `GoldIntel_Docs/`. "Keep NEXT_SESSION_PROMPT.md in the docs folder,
  always current. It holds the exact text I paste into a brand-new Code session." The current state lives in
  Session_Handoff.md, never in the prompt.
- The documents a new session needs may be ahead of `main` on an open pull request branch until Shawn approves a
  merge; Session_Handoff.md names the branches.
- `CODE_SESSION_OPENING_PROMPT.md` is replaced by `NEXT_SESSION_PROMPT.md` (D-105) and kept only as a record in `archive/`.

## 8. One session at a time; evidence per session (D-105)

- "only one Code session works on the repo at a time; the old session stops once the new one has verified the
  handoff." The old session makes no commit or push after the new session's first report.
- "Evidence files must be re-attached in the session that analyzes them." A session never relies on files attached
  to an earlier session; if they are needed and not attached, it asks for them.

## 9. Other add-ons: copying, clean room, cross-checks, optional plugins (D-110, 2026-11-14)

- "We can copy and credit where it's allowed. Where copying isn't allowed and it's a core function of what we're trying to build, do the clean room thing. We can use addons to check our work too. Where it makes sense we will have some things be optional plugins and note that some features will be better if these addons are installed but our addon will still work without them."
- "In practice: copy only from MIT or CC BY sources, credited in THIRD_PARTY.md. For GPL or All Rights Reserved sources, use only the reviewer's hint notes, never their code or data tables, and record 'approach informed by <add-on>, no code copied'. GoldIntel must work without any other add-on. As a cross-check, compare GoldIntel's session income and spending with Accountant Classic's (installed) for the same sessions, especially the OTHER share; read its file only for comparison. Plan question, no code: for prices, report what GoldIntel does now and whether Auctionator's or TSM's public interface should be an optional source with our own fallback."
- So: code or data is copied only from an MIT or CC BY source and credited in `THIRD_PARTY.md` (created with the first
  copy). A GPL or All Rights Reserved source is never copied, code or data tables: only the reviewer's hint notes are
  used, and the record says "approach informed by <add-on>, no code copied". Calling another add-on's public interface
  at runtime is not copying; it is allowed only as an optional source with GoldIntel's own fallback. GoldIntel must
  work with no other add-on installed. Another add-on's SavedVariables are read only for comparison, read-only, and
  only from files attached in the session (section 8).
