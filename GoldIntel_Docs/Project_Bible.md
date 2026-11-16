# GoldIntel Project Bible

DOC VERSION: 2.0.0  |  DATE: 2026-11-16 (rewritten for the current project: one AI developer, the game is live; user decision D-119)  |  STATUS: Active

> Read this file after CODE_STANDING_ORDERS.md and the newest Session_Handoff section. It is self-contained on
> governance. If a project document conflicts with it on governance, this file wins; on how a Claude Code session works,
> CODE_STANDING_ORDERS.md wins; on product scope, Requirements_v1.md wins. The current state (versions, branches,
> pull requests, what is installed, what is pending) is only in the newest Session_Handoff section, never here.

## 1. What GoldIntel is

A gold-making analytics add-on for **World of Warcraft: Forever**, Blizzard's "Classic+" game (separate from Classic Era
and retail; launched 2026-11-04). It records where every copper comes from: the source (loot, vendor, quest, mail,
trade, auction), the activity, the place and the level, so the player can see where and how gold is earned per hour.
It also values the items picked up (item lots) and follows them to the sale, so value created and value converted are
both known and nothing is counted twice.

Goal: the definitive gold analytics add-on for WoW Forever.

## 2. People and roles (D-032 superseded by D-119)

| Role | Holder | Responsibilities |
|---|---|---|
| Sponsor, project manager, tester, final decision authority | Shawn (the user) | Approves phases, increments, builds and merges; plays the real client and supplies the evidence (SavedVariables, screenshots); decides every open question |
| Lead architect and lead developer | Claude (Claude Code sessions) | Owns requirements, architecture, contracts, code, tests, packages and every project document; gives a recommendation with the evidence; Shawn decides |

There are no other AI reviewers. The ChatGPT and Gemini reviews of October 2026 are kept in `archive/reviews/` as a
record; their accepted findings are already in the documents. Other add-ons (Accountant Classic, Auctionator, TSM) are
used only as described in CODE_STANDING_ORDERS.md section 9 (D-110).

Every Claude Code session:
1. Works only from the repository: nothing that matters may live only in a chat.
2. Follows CODE_STANDING_ORDERS.md (gates, packages, test steps, report format, merges).
3. Records each of Shawn's decisions in Decisions.md with his exact words.
4. Ends each report with an updated Session_Handoff section, committed and pushed.

## 3. Reading order and precedence

For a new Claude Code session: CODE_STANDING_ORDERS.md, then the newest Session_Handoff section, then this file, then
as needed: TODO.md (phases and tasks), Decisions.md, Requirements_v1.md, Contracts.md, Architecture.md,
Compatibility_Notes.md.

| Conflict | Winner |
|---|---|
| How a session works | CODE_STANDING_ORDERS.md |
| Requirements_v1.md vs any implementation decision | Requirements_v1.md |
| Decisions.md vs Architecture.md | Decisions.md |
| Contracts.md vs Architecture.md on a data shape | Contracts.md |
| Compatibility_Notes.md vs Architecture.md on a fact about the client | Compatibility_Notes.md |
| Newest Session_Handoff section vs older ones | Newest |
| Anything vs a dated instruction from Shawn | Shawn (recorded as a decision) |
| A current document vs a document in `archive/` | The current one |

A conflict this table cannot settle: stop and ask Shawn.

## 4. Governance rules

**Changing architecture requires, in this order:** why the change is needed; the affected modules; the migration
(SavedVariables schema, contracts, tests); a Decisions.md entry. It needs Shawn's approval where it changes scope,
requirements or a phase.

**Bookkeeping:**
- Every approved decision goes in Decisions.md (append-only; supersede, never delete).
- Every implementation change goes in Changelog.md (append-only).
- TODO.md shows the current phase and tasks; Session_Handoff.md gets a new section at the top with every report.
- A contract change goes into Contracts.md in the same change as the code (D-031).
- Work only on what Shawn has approved (TODO.md `IMPLEMENTATION APPROVED`). Plans and proposals are documents only
  until he approves them.

**Evidence:** measured behaviour beats documents and memory. Facts about the client are recorded in
Compatibility_Notes.md with an evidence tag; an unverified claim is marked [assumed] or [inferred] and becomes a check.
Shawn's SavedVariables are read only, and only from files attached in the session that analyses them.

## 5. Core design principles (ordered; earlier wins ties)

1. Correctness over convenience (the cash ledger must match the real balance to the copper)
2. Prevent double-counting of gold
3. Platform independence (no WoW API calls outside `Platform/`)
4. Modular design (modules talk through contracts and the bus only)
5. Testability (pure-Lua engines; unit tests outside the client)
6. Performance (event handlers only enqueue; heavy work is scheduled or spread over frames)
7. Future extensibility (placeholders, versioned schemas)
8. Session-to-session transferability (any session can end at any time; the repository holds everything)
9. Explicit assumptions
10. User trust through transparent calculations (every number can be explained)

## 6. Glossary

| Term | Meaning |
|---|---|
| Cash ledger | Record of actual copper changes on the character |
| Lot (asset ledger) | A quantity of one item acquired together, with its valuation at acquisition and its origin |
| Conversion | Asset becomes cash (sale) or cash becomes asset (purchase); NOT new income |
| Settlement | Delayed income that arrives by mail (AH proceeds, COD, mailed payments) |
| Interval | One recording period, from the automatic start after login to the logout or /reload |
| Segment | A slice of play with a constant place, activity and level |
| Active time | Session time minus idle, travel and paused time (Phase 4 time classes) |
| Expectation | A pending, source-declared copper amount used to attribute a money change |
| Reconciler | Turns money changes into tagged cash entries; guarantees the entries sum to the change |
| Provenance | The activity and place that produced an item, carried by its lot |
| Aggregates | Phase 4 totals per place x activity x level bracket, and heat bins per map (`agg`, `heat`) |
| Capability | A WoW API feature probed at startup (`/gi probe`); features degrade if absent |
| GUID | Character identity key |

## 7. Approved metrics (names are fixed; formulas in Requirements_v1.md section 5)

Cash GPH (always visible), Wealth GPH, Net GPH, Zone rankings, Subzone rankings, Heatmap metrics, Activity-specific
rankings, Normalization metrics (experimental).

## 8. Facts about the game (details and evidence in Compatibility_Notes.md)

- WoW: Forever launched on 2026-11-04 (beta 2026-09-17 to 2026-10-21). Level cap 60, Classic Era content, modern client.
- Client 1.60.1, Interface 16001, WOW_PROJECT_ID 18; builds seen live: 70790 (launch), 70862, 70938.
- Add-ons run on Lua 5.1 with the modern (12.0-era) API: `C_` namespaces, `C_Map` with world sizes, `C_Item`,
  `C_AuctionHouse`, StaticPopup; reloading the UI from a popup button works (verified 2026-11-14).
- There is no official add-on API documentation for Forever. Every API GoldIntel relies on is a capability probe; the
  live results are in Compatibility_Notes.md.
- `/reload` takes in changed and added add-on files and new events (verified 2026-11-14, D-117).
- Other add-ons in the same client can be heavy: TSM or Auctionator request thousands of items after a login, which
  GoldIntel now ignores (D-115).

## 9. Phases (the authoritative status is TODO.md `CURRENT PHASE`)

| Phase | Content | Status |
|---|---|---|
| 0 | Documentation baseline | Closed |
| 1, 2 | Platform layer, probes, core, store | Closed |
| 3a | Signal verification lab | Closed (D-066) |
| 3b | Cash ledger (3b-1, 3b-2) and item lots (3b-3); 3b-4 more spending sources (flight fares, postage, AH deposits) | 3b-0..3b-3 closed; 3b-4 next after Phase 4 |
| 4 | Sessions, activity, time classes, live aggregates per place and activity, reload reminder | In live validation (P4-M3) |
| 5 | Rankings and aggregates | Planned |
| 6 | Pricing and auction profitability (optional Auctionator / TSM prices, D-111) | Planned; plan only |
| 7 | Heatmap | Planned |
| 8 | UI (main window with tabs; the Settings window of 0.6.1 is its seed, D-115) | Planned; plan only |
| 9 | Hardening and release | Planned |

## 10. Document inventory

| File | Purpose | Rule |
|---|---|---|
| CODE_STANDING_ORDERS.md | How every Claude Code session works | Shawn's decision only; wins on how to work |
| NEXT_SESSION_PROMPT.md | The text Shawn pastes into a new session | Kept current; no state in it |
| Session_Handoff.md | Current state, newest section at the top | A new section with every report |
| Project_Bible.md | Governance and orientation (this file) | Shawn's decision only |
| Requirements_v1.md | What v1 must do (frozen) | Shawn's decision only |
| Decisions.md | Every decision, with Shawn's words | Append-only |
| Changelog.md | Every implementation change, per version | Append-only |
| TODO.md | Current phase, approvals, tasks | Updated with every change |
| Architecture.md | The v1 design | Must agree with Decisions.md |
| Contracts.md | Interfaces and data shapes, versioned | Changed with the code (D-031) |
| Compatibility_Notes.md | Facts about the Forever client with evidence | Updated after each live check |
| Risk_Register.md | Open and closed risks | Reviewed at each phase gate |
| Phase4_Live_Aggregation_Proposal.md, Phase4_P4-M2_Plan.md | Phase 4 design answers (D-099) and the P4-M2 plan (D-102) | Moved to archive when Phase 4 closes |
| Phase4_P4-M2_Review.md, Phase4_P4-M3_LiveCheck*.md | 0.6.x review and live checks (on PR #9 until it merges) | Same |
| Reference_AccountantClassic.md, Reference_Auctionator.md | Notes from other add-ons (design input only, D-110) | Reference |
| archive/ | Finished-phase plans, reports, the pre-launch review, the October reviews | Records only; see archive/README.md |

Runtime evidence (SavedVariables, screenshots) is never stored in the repository: Shawn attaches it in the session
that analyses it (D-087, D-105).
