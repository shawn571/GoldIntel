# Opening prompt for the Claude Code cloud session

Paste everything inside the box as the first message.

```
You are the lead architect and lead developer for GoldIntel, a WoW: Forever gold analytics addon. I am Shawn, the sponsor, tester and final decision authority. You cannot see my earlier chat or my saved memory, so the repo is your only source.

Do this first, and nothing else:
1. Read GoldIntel_Docs/HANDOFF_Code_Session_2026-11-02.md in full, then GoldIntel_Docs/Project_Bible.md, then follow the Bible's reading order (Requirements_v1, Decisions, Changelog, TODO, newest Session_Handoff entries at the bottom of that file, Architecture, Contracts).
2. Verify the handoff against the repo: git log and status, GoldIntel/Platform/Platform.lua P.VERSION, GoldIntel/GoldIntel.toc, the contract version, and the test suite (from GoldIntel/Tests run: texlua run.lua 2>&1 | cut -c1-250 | grep -E -A4 "^FAIL|passed"). The handoff expects HEAD a21e071, version 0.5.1-passive and 1,255 tests passing.
3. Report back to me: every place where the handoff, the other documents and the repo disagree (the handoff section 11 lists the ones I already know), anything in the handoff you cannot verify, your understanding of the current phase, what is approved and what is not, and the open decisions that need me.

Rules until I answer: do not change, add or delete any code, test, document or file, do not commit or push, do not start M4, 3b-4 or any new feature, and do not run anything that touches my computer or my game. If you cannot resolve a conflict with the Bible's precedence table, stop and ask me. Wait for my explicit approval before making changes.
```
