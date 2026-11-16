# GoldIntel Phase 2 Closure Recommendation

DOC VERSION: 1.0.0  |  DATE: 2026-10-17  |  AUTHOR: Claude (S-011)  |  STATUS: ACCEPTED by the user on 2026-10-17 (D-056): Phase 2 CLOSED WITH EXCEPTIONS PX-1..PX-8; D-034 to D-040 confirmed. Closing Phase 2 does NOT authorize Phase 3b. PX-4 is now fixed (D-041, rebuild 4).

Evidence tiers follow D-031: [file] = in a saved file, [chat] = user's pasted chat text, [reported] = user's statement, [inferred], [assumed].

## 1. Recommendation

**Phase 2 (Core + Store) COMPLETE WITH EXCEPTIONS.**

The user's own words (2026-10-17): "Phase 2 substantially validated." The evidence supports that: every Phase 2 exit-test item that can be observed in the live client has been observed and passed. The exceptions below are small, none blocks closure, and each has an owner and a gate.

## 2. Exit test versus evidence

Exit test text (TODO Phase 2): automated part DONE; live part PENDING until 2.8.

| Item | Live result | Evidence |
|---|---|---|
| Addon loads, 21 files, no Lua error, `diag=0` | PASS in every live session (builds 70374 and 70450) | E-13, E-14 [file] |
| Installed files identical to the package (21/21 adler32 and size) | PASS | E-14 [file] |
| Files compile in the live client | PASS 21/21 | E-14 [file] |
| Store migrates the real Phase 1 database 0 to 1, `compat` preserved | PASS | E-13 [file] |
| Second and later sessions open `state=ok`, history unchanged | PASS through `opens=7` | E-14, E-15 [file] |
| Registration verification (`IsEventRegistered`), registered case | PASS for all 12 events | E-13 [file] |
| Delivery stages: PLAYER_MONEY | delivered, payload usable (`copper=1`, `-1`) | E-15 [chat] |
| Delivery stages: PLAYER_LEVEL_UP | delivered, payload usable (`level=7`) | E-15 [chat] |
| Delivery stages: ZONE_CHANGED, ZONE_CHANGED_NEW_AREA | delivered (three `P_ZONE`) | E-15 [chat] |
| Delivery stages: PLAYER_REGEN_DISABLED / ENABLED | delivered, repeatedly | E-14 [file], E-15 [chat] |
| Settings persist across `/reload` and logout | PASS (`profile.idleSec = 240` in the saved file) | E-15 [file] |
| Libraries absent | PASS (all `lib.*` absent, operational, store ok) | E-14 [file] |
| Libraries present | PASS (all present, operational, store ok) | E-15 [file] |
| Diagnostics sandbox `/gidiag run` | PASS (21 files, 0 diagnostics, user data untouched) | E-15 [file] |
| Output recorded without copy and paste | PASS, with one weakness (section 4) | E-14, E-15 [file] |

## 3. Exceptions carried out of Phase 2

| ID | Exception | Why it does not block closure | Gate |
|---|---|---|---|
| PX-1 | ZONE_CHANGED_INDOORS never delivered (no building was entered) | "Not seen" is not a failure; the other two zone events are proven; indoors changes only the sub-label | Observe once, any time; before Phase 3 uses subzone text |
| PX-2 | `/gidiag copy` window never reported (user typed `/gi diag copy`, a different command) | Evidence now travels through the saved file; the window was a convenience | Optional; one line from the user |
| PX-3 | `IsEventRegistered` for a BLOCKED event still unobserved (R-26) | The 12 live events are on the trusted list, so a wrong "blocked" answer cannot disable them; strict mode only matters for unproven events | Phase 3 signal verification (D-029) is exactly this test |
| PX-4 | The runtime record of the previous session is overwritten at every open | Evidence tooling only; no gold data involved | Fixed by the proposal in `Runtime_Session_Records_Proposal.md` (user approved the principle) |
| PX-5 | D-027 (legacy adapter removal) and D-028 (interface policy) still Proposed (X-2) | Legacy code is inert; Interface 16001 works | Before Phase 3 |
| PX-6 | D-034 to D-040 are "approved-pending-confirm" | Built and live-validated; the user's closure statement can serve as confirmation if the user says so | Your explicit confirmation requested (section 5) |
| PX-7 | CPU and memory soak with `C_AddOnProfiler` (E7, R-15) not measured | Phase 2 does almost nothing per frame (a 0.5 s ticker, no collectors) | Before the first collector ships (Phase 3 exit) |
| PX-8 | OI-13: the ChatGPT and Gemini review documents were never provided | Six relayed findings were evaluated (all accepted) | Next review round |

## 4. One weakness found by the validation itself

`runtime` (capability stages, event counters, last 100 output lines) is replaced on every open. A `/reload` therefore destroys the record of the session before it. On 2026-10-17 the long test session was visible only because the user pasted chat text. Proposal and decision text: `Runtime_Session_Records_Proposal.md` (D-041).

## 5. What the user is asked to do

1. State whether Phase 2 is closed (recommended: yes, with exceptions PX-1 to PX-8).
2. State whether D-034 to D-040 are now confirmed (recommended: yes; they are built, tested and live-validated).
3. Review the session-record proposal and either approve its design or request changes. Code is NOT written until you approve the design.
4. Review the Phase 3 planning package. Phase 3 implementation stays unapproved (D-042).

## 6. What closing Phase 2 changes

- TODO: Phase 2 marked complete with exceptions; task 2.8 closed; OI-9 and the live part of OI-12 closed; PX-1 to PX-8 tracked.
- Nothing else. No Phase 3 file, test or setting is created by closing Phase 2.

## 7. Confidence

- Platform + Core + Store: high. Three live sessions, three states of the optional libraries, one real database migration, 483 automated tests, 7 mutation checks.
- Everything Phase 3 needs from the client (loot, vendor, quest, mail, trade, casting, item data): unproven. Only money, zone, level, combat, lifecycle and skill events are proven. This is the real boundary of what is known (R-01, R-02, R-07).
