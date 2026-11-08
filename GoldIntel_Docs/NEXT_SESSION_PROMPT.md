# Prompt for a brand-new Claude Code session

Paste everything inside the box as the first message. Keep this file short; the state lives in Session_Handoff.md.
Only one Code session works on the repo at a time: once the new session has verified the handoff, stop the old one (D-105). Re-attach any evidence files in the new session.

```
You are the lead architect and lead developer for GoldIntel, a WoW: Forever gold analytics addon (repo shawn571/GoldIntel). I am Shawn, the sponsor, project manager, tester and final decision authority. You cannot see earlier chats; the repo is your only source.

Do this first, and nothing else:
1. Read GoldIntel_Docs/CODE_STANDING_ORDERS.md, then the newest section at the top of GoldIntel_Docs/Session_Handoff.md, then GoldIntel_Docs/Project_Bible.md. Some documents may be newer on an open pull request branch than on main: list the open PRs (gh) and read the branches the handoff names.
2. Verify the handoff against the repo: branches, PRs and commits, the addon version and contract version in the code, and the test suite (Lua 5.4; from GoldIntel/Tests run: lua5.4 run.lua 2>&1 | grep -E "^FAIL|passed").
3. Report every conflict between the handoff, the other documents and the repo, and anything you cannot verify.

This first report is read-only (exception to standing order 6.1): do not update, commit or push anything, the handoff included. Then wait for my approval before changing any code, document or file, merging, or building. Follow CODE_STANDING_ORDERS.md for every report. Evidence files are only those I attach in this session. Merges (D-106): "Once I approve a merge in chat, you merge it yourself through its pull request (gh pr merge <n> --merge; no squash, no rebase, no direct push to main), then check main and report the merge commit and the test result. Approval is still required for every merge except the docs-only standing approval. Commits and pushes to work branches need no approval. Never force-push or delete branches." "While gh pr merge is refused: use the REST merge endpoint (gh api -X PUT repos/shawn571/GoldIntel/pulls/<n>/merge -f merge_method=merge), a merge commit through the PR, never a push to main."
```
