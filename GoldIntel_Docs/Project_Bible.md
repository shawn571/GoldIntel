# GoldIntel Project Bible

DOC VERSION: 1.0.3  |  DATE: 2026-11-14 (header and inventory only, user decision D-113; governance unchanged)  |  PROJECT VERSION: 0.6.0-passive (PR #9, merged after the P4-M3 live check); 0.5.6-passive on main until then. The newest Session_Handoff section names main, open pull requests and what is installed  |  STATUS: Active

> Read this file first. It is self-contained. If any other project document conflicts with it on governance, this file wins; on product scope, Requirements_v1.md wins.

## 1. What GoldIntel is

A gold-making intelligence and analytics addon for **World of Warcraft: Forever** (Blizzard's "Classic+" game; separate from Classic and retail; launch 2026-11-04, beta 2026-09-17 to 2026-10-21). It tracks every gold-generating activity, attributes income without double-counting, computes Cash / Wealth / Net gold-per-hour (GPH), ranks zones and subzones, models auction-house profit, and shows opportunity on map overlays and heatmaps.

Goal: become the definitive gold analytics platform for WoW Forever.

## 2. Multi-AI collaboration contract

The project is developed across several AI systems (Claude, ChatGPT, Gemini; roles in D-032). Any session can end at any time.

Every AI MUST:

1. Never assume context that is not in the project documents or the user's message.
2. Read documents in the **mandatory order** (section 3) before doing any work.
3. State assumptions explicitly, and record them in Decisions.md (decisions) or Requirements_v1.md section 9 (assumptions).
4. End every session with a `SESSION HANDOFF` block, appended to Session_Handoff.md, and update Changelog.md and TODO.md (and Decisions.md if applicable).
5. Never leave hidden state in the conversation. If it matters, it is in a document.

### 2.1 Roles and review model (Decisions D-032, set by the user 2026-10-10)

| Role | Holder | Responsibilities |
|---|---|---|
| Project sponsor, project manager, client tester, final decision authority | User | Approves phases and decisions; runs the real client; resolves disagreements |
| Lead architect, lead developer; owner of requirements, architecture, contracts, code, changelogs and governance documents | Claude | Source of truth for all project artifacts |
| Independent reviewer: risk assessment, architecture review, runtime evidence review, phase gate review | ChatGPT | Advises; does not implement |
| Platform analyst: WoW Forever compatibility, research review, alternate design review | Gemini | Advises; does not implement |

**External review intake rules** (apply to every finding from ChatGPT, Gemini or any later reviewer):

1. External reviews are independent peer-review inputs. Each finding is recorded and answered with a verdict: **accepted**, **rejected** or **partially accepted**, each with a technical justification (evidence, code, a test, or a documented rule).
2. Architecture is never changed solely because another AI suggested it. A claim that cannot be verified stays tagged [assumed] and becomes a probe, a risk (Risk_Register.md) or a question, not a design change.
3. An accepted finding that changes architecture follows the governance rules in section 4 (why, affected modules, migration, Decisions.md entry) and needs the user's approval where it changes scope, requirements or a phase.
4. Reviewers advise; they cannot approve a phase gate. The user decides. Claude gives a recommendation with the evidence.
5. Findings that expose an error in Claude's own work are acknowledged and corrected in the artifacts.
6. Conflicting reviewer findings are both recorded; Claude states which it follows and why; the user decides if the conflict is material.
7. Review documents are stored unedited in `GoldIntel_Docs/reviews/` with dated names (D-031 evidence discipline). Outcomes go where they belong: Decisions.md (decisions), Risk_Register.md (risks), Compatibility_Notes.md (client facts, only with evidence), TODO.md (work).
8. Finding record: `ID (ER-ChatGPT-001 / ER-Gemini-001) | claim | evidence tier | verdict | technical justification | resulting action`. A log file is created when the first external review arrives.

## 3. Mandatory document review order

1. Project_Bible.md (this file)
2. Requirements_v1.md
3. Decisions.md
4. Changelog.md
5. TODO.md
6. Latest Session_Handoff.md
7. Architecture.md
8. Contracts.md

### Conflict resolution (strict precedence)

| Conflict | Winner |
|---|---|
| Requirements_v1.md vs any implementation decision | Requirements_v1.md |
| Decisions.md vs Architecture.md | Decisions.md |
| Newest Session_Handoff.md section vs older handoffs | Newest |
| Contracts.md vs Architecture.md on a data shape | Contracts.md |
| Anything vs a direct, dated instruction from the user | The user (record it as a decision) |
| An external review finding vs Requirements / Decisions / Contracts | The existing documents, until the finding is accepted through the governance process (section 2.1) |

If you find a conflict you cannot resolve with this table, STOP, list it under OPEN ISSUES in the handoff, and ask the user.

## 4. Governance rules

**Changing architecture requires, in this order:**

1. Explain why the change is needed.
2. List affected modules.
3. List migration requirements (SavedVariables schema, contracts, tests).
4. Record the decision in Decisions.md (ID, status, rationale, affected modules, migration).

**Bookkeeping rules**

- Every approved architectural decision goes in Decisions.md.
- Every implementation change goes in Changelog.md.
- Every completed task updates TODO.md.
- Every session appends a section to Session_Handoff.md.
- Do not expand scope. Work only on the current phase named in TODO.md.
- Planning phase = produce documents and architecture only. Implementation begins only when TODO.md says implementation is approved for a named phase (see Decisions D-019).

## 5. Core design principles (ordered; earlier wins ties)

1. Correctness over convenience
2. Prevent double-counting of gold
3. Platform independence (no WoW API calls outside `Platform/`)
4. Modular design (talk through contracts and the bus only)
5. Testability (pure-Lua engines; unit tests outside the client)
6. Performance (event handlers only enqueue; heavy work is scheduled)
7. Future extensibility (placeholders, versioned schemas)
8. AI-to-AI transferability
9. Explicit assumptions
10. User trust through transparent calculations (every number can be explained)

## 6. Glossary

| Term | Meaning |
|---|---|
| Cash ledger | Record of actual copper changes on the character |
| Asset ledger | Record of item lots (what you hold and what it is worth) |
| Lot | A quantity of one item acquired together, with acquire-time valuation and origin |
| Conversion | Asset becomes cash (sale) or cash becomes asset (purchase); NOT new income |
| Settlement | Delayed income that arrives by mail (AH proceeds, COD, mailed payments) |
| Segment | A slice of a session with a constant zone, subzone, activity, level and profession set |
| Session | One play period made of segments |
| Active time | Session time minus idle and paused time |
| Expectation | A pending, source-declared expected copper amount used to attribute a money change |
| Reconciler | Turns money deltas into tagged cash entries; guarantees entries sum to the delta |
| Provenance | The activity and location that produced an item, carried by its lot |
| Capability | A WoW API feature probed at startup; features degrade if absent |
| GUID | Character identity key (Forever is realmless) |

## 7. Approved metrics (names are fixed; formulas in Requirements_v1.md section 5)

Cash GPH (always visible), Wealth GPH, Net GPH, Zone rankings, Subzone rankings, Heatmap metrics, Activity-specific rankings, Normalization metrics (experimental).

## 8. Known facts about the target game (verified 2026-10-09 from press coverage; not from Blizzard API docs)

- Separate game from Classic and retail; realmless; level cap 60; modernized client; Hardcore announced for a later update.
- **Interface number is 16001 and the client is modern, 12.0-based** (first in-client test, 2026-10-09; Decisions D-023).
- **Addon API surface is NOT confirmed.** No official documentation was found. All API assumptions live in Architecture.md section 11 as capability probes. See OI-1 in the latest handoff.

## 9. How to resume (fresh AI, no memory)

1. Read the documents in section 3 order.
2. Open TODO.md; find `CURRENT PHASE`. For Claude Code sessions, CODE_STANDING_ORDERS.md and the newest Session_Handoff section come first (D-103).
3. Open the newest section of Session_Handoff.md; read `OPEN ISSUES`, `BLOCKERS`, `NEXT RECOMMENDED TASK`.
4. Verify that task is allowed by TODO.md and Requirements_v1.md. If not, ask the user.
5. Do the work. Update the bookkeeping files. Append your handoff.

## 10. Document inventory

| File | Purpose | Owner rule |
|---|---|---|
| Project_Bible.md | Governance and orientation | Change only by user decision |
| Requirements_v1.md | What v1 must do (frozen) | Change only by user decision |
| Decisions.md | Approved architectural decisions | Append-only; supersede, never delete |
| Changelog.md | Implementation changes | Append-only |
| TODO.md | Phases and tasks, current phase | Update every session |
| Session_Handoff.md | Per-session state transfer | Append newest section at top |
| Architecture.md | The v1 design | Must agree with Decisions.md |
| Contracts.md | Interfaces and data shapes | Versioned; breaking changes need a decision; changes in the same change as the code (D-031) |
| Compatibility_Notes.md | Verified facts about the WoW Forever client with an evidence ledger | Wins over Architecture.md on client facts; update after each probe |
| Risk_Register.md | Risks with likelihood, impact, mitigation, owner phase | Review at every phase gate |
| Phase1_PostValidation_Review.md | Phase 1 live-validation review and Phase 2 go/no-go | Historical record |
| Phase1_Compat_Analysis.md, Phase1_Client_Diagnostics.md | Load-failure analysis and in-client diagnostic commands | Historical / reference |
| (no evidence folder) | Runtime evidence (SavedVariables, screenshots) is not stored in the repo: the user attaches it in the session that analyzes it (D-087, D-105); findings go into the session reports and Compatibility_Notes.md | Read-only; never write to the user's WTF or SavedVariables |
| reviews/ | External (ChatGPT, Gemini) review documents and External_Review_Log.md | Documents unedited; log is the verdict record (D-032) |
| Phase2_Runtime_Validation_Plan.md | Step-by-step live validation of Phase 2 | Update after each client run |
| Phase2_Closure_Recommendation.md | Formal Phase 2 closure recommendation (complete with exceptions PX-1..PX-8) | Update when the user decides |
| Runtime_Session_Records_Proposal.md | Design proposal to keep the current and previous runtime records (D-041) | Update when approved/implemented |
| Travel_Model_Options.md | Options for taxi/transit time (D-054), pending the user's choice | Update when decided |
| Phase3a_Verification_Protocol.md | Phase 3a experiments, safety rules, review gate (D-051) | Update with results |
| Phase3_Planning_Package.md | Phase 3 PLANNING ONLY: value attribution, loot valuation, location credit, activity, AFK, signal selection (D-042..D-050) | Update with the user's decisions |
| Phase3a_Closure_Recommendation.md | Phase 3a closure (accepted, D-066) | Closed |
| Phase3b_Scope_and_Readiness.md | Phase 3b scope, readiness, exit criteria (PROPOSED, not authorization) | Update with the user's decisions |
| Phase3b_Increment_*, Phase3b_3b-*_* | Increment plans, milestone reports, validation session scripts for 3b-1..3b-3 | Historical once the increment is closed |
| HANDOFF_Code_Session_2026-11-02.md | Bridge from the claude.ai chat session to the Claude Code session (2026-11-02) | Historical; newer Session_Handoff sections win |
| PreLaunch_Review_2026-11-03.md | Pre-launch review of 0.5.1-passive and the launch-day checklist | Update after the first live session |
| CODE_STANDING_ORDERS.md | How every Claude Code session works: gates, packages, reports, one session at a time (D-103, D-105) | Wins on how to work (D-103); change only by user decision |
| NEXT_SESSION_PROMPT.md | Exact text the user pastes into a new Code session | Keep current; no state in it |
| CODE_SESSION_OPENING_PROMPT.md | Opening prompt of 2026-11-02 | Replaced by NEXT_SESSION_PROMPT.md (D-105); historical |
| Phase4_Live_Aggregation_Proposal.md | Phase 4 proposal (live aggregation per place and activity) and the Q-1..Q-7 answers (D-099) | Historical once Phase 4 closes |
| Phase4_P4-M2_Plan.md | P4-M2 plan; section 0 lists the approvals relied on (D-102, confirmed D-107) | Historical once Phase 4 closes |
| Phase4_P4-M2_Review.md | Review of the 0.6.0-passive build before approval: what it adds, saved data, cost, findings (S-071, D-113) | Historical once P4-M3 closes |
| Baseline_0.5.6_Report.md | 0.5.6 baseline (D-109), price plan (section 6), Accountant Classic cross-check (section 7, D-111) | Historical; Q-7 baseline for Phase 4 |
| Phase3b_3b-3_Closure_Recommendation.md | 3b-3 closure (accepted, D-101) | Closed |
| THIRD_PARTY.md (not yet created) | Credits for anything copied from MIT or CC BY sources (D-110) | Created with the first copied item |
| Reference_AccountantClassic.md, Reference_Auctionator.md | Notes from other addons used as design input (3b-4, Phase 6) | Reference; copying rules in CODE_STANDING_ORDERS.md section 9 (D-110) |
