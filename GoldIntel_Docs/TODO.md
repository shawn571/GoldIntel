# GoldIntel TODO

DOC VERSION: 2.0.0  |  UPDATED: 2026-11-20 (D-120; rewritten 2026-11-16; the full history up to this date is in archive/TODO_history_2026-11-16.md, D-119)

```
CURRENT PHASE:            Phase 4 (sessions, activity, live aggregates): P4-M1 merged (PR #7); P4-M2 on PR #9 as 0.6.2-passive, in live validation (P4-M3, live check 3); PR #9 merged only after the user reports that 0.6.2 passed. Next: 3b-4 (flight fares, postage, AH deposits; D-112). Phases 0..3b-3 closed. Build on main: 0.5.6-passive.
IMPLEMENTATION APPROVED:  Phase 4 P4-M2 and its live-check fixes (D-102, D-113, D-115, D-118). Standing permissions for work branches (D-114, D-116). Docs-only merges (D-105, D-108); merges with the REST command (D-106, D-118). Everything else is NOT approved: 3b-4 waits for its own approval; soft travel across zones, retention, the main window and the price plan are PLAN ONLY.
OPEN BLOCKERS:            None. Waiting on the user: live check 3 of 0.6.2 (reminder (a)-(c), Settings window, boss encounter); EmpireIntel screenshot (later, D-116).
```

Rules: work only on what is approved above. Do not start the next increment or phase without Shawn's explicit approval.
Mark tasks `[x]` with the date and session when done. The current state (versions, branches, installed builds) is in the
newest Session_Handoff section.

---

## Now: Phase 4 live validation (P4-M3)

- [x] P4-M1 pure modules (Clock, Aggregator), merged with PR #7 (D-099, D-109).
- [x] P4-M2 built as 0.6.0-passive (D-102); live check 1 (D-115) -> 0.6.1; live check 2 (D-117) -> 0.6.2 (D-118).
- [x] Live check 3, part 1 (D-120, 2026-11-20): popup at 120 minutes, Reload Now, Ignore with no re-show for 22 minutes,
  total = session, no frame over 500 ms.
- [ ] User: live check 3, rest: (a) a full interval after Configure, Ignore and Reload Now (2-minute steps); (b) no immediate
  re-show after Ignore; (c) clicks and the client's own closes logged apart; Settings window shows the real value and
  "Saved"; one "GoldIntel:" prefix; a boss encounter (no popup during it; not tested yet).
- [ ] After live check 3 passes: merge PR #9 (with the user's approval in chat), then the Phase 4 closure
  recommendation.
- [ ] Phase 4 requirement items still to map against what 0.6.x does: 4.1 ActivityEngine (v1 activities, manual
  override, idle), 4.2 SessionEngine and segment rotation, 4.3 metrics (Cash, Wealth GPH; explain-breakdown data),
  4.4 tests. Exit test: a 30-minute simulated session matches a hand-computed GPH within 1 percent; Cash GPH is always
  present.
- [ ] Design item: a segment that carries several activities (grind + skin) without rotating at each skin.
- [ ] Note: /reload load frames of 100-178 ms charged to GoldIntel; another add-on's item-data flood was a large part
  (fixed in 0.6.1). Re-measure on 0.6.2; file size is the other candidate.

## Plans only (written on request; nothing is built before Shawn approves)

- [ ] Soft travel across zones: a last productive spot on another map counts as far (D-115: "not now, plan it
  separately").
- [ ] Retention: 7-day raw cash window plus daily summaries, a separate rule for open lots, a test-mode switch for trace
  and perf (Phase4_P4-M3_LiveCheck1.md section 6, on PR #9 until it merges; direction D-115).
- [ ] Main window with tabs (Opportunities, Map, Settings), GoldIntel's own map drawing with a heat overlay; in-game
  checks first (Phase4_P4-M3_LiveCheck1.md section 5, on PR #9). Needs the EmpireIntel screenshot.
- [ ] Realm scope: key realm-dependent data (manual prices, later market prices, auctions, account-wide views) by the
  GUID server number, never the realm name (Plan_Retention_and_Realm_Scope.md part A, D-120).
- [ ] Retention, measured 2026-11-20 (account file 3.9 MB): Plan_Retention_and_Realm_Scope.md part B, decisions in B.6.
- [ ] Prices: Auctionator and TSM public interfaces as optional sources with GoldIntel's own fallback (D-111, Phase 6).

## Next: 3b-4 more spending sources (after Phase 4; D-112; NOT started, needs approval)

- [ ] Flight fares (largest OTHER item in the Accountant cross-check), then postage, then AH deposits.
- [ ] Still OTHER by design until then: respec, barber, guild bank (repairs at a vendor are already vendor purchases).
- [ ] Design inputs: Reference_Auctionator.md (7 points); Auctionator's duration-code mapping is unresolved.
- [ ] Each new source needs a live signal check before it is built.

## Open evidence (collected passively during normal play)

- [ ] Coin share wording with gold (`Your share of the loot is 4 Gold, ...`); silver is verified.
- [ ] Herbalism and fishing cast names at every rank (skinning and mining verified).
- [ ] Quest rewards without a quest context (watch `EVT quest done` timing); the lag case where the coin chat line
  comes before late money.
- [ ] Money taken from mail, money in a trade, an AH sale mail, in live play.

## Later phases (planned; each needs its own approval)

### Phase 5: Rankings and aggregates (REQ: FR-RNK-1..4)
- [ ] 5.1 Aggregation tables and rollup in Pruner (retention plan above)
- [ ] 5.2 Zone, subzone and activity rankings with confidence and minimum time (`/gi agg top` is the first step)
- [ ] 5.3 Tests on fixtures including locale-tagged subzone keys
- Exit test: rankings reproduce hand-computed values.

### Phase 6: Pricing and auction profitability (REQ: FR-AH-1..3)
- [ ] 6.1 PriceProvider interface and native provider (manual prices; scan if the capability exists)
- [ ] 6.1a Optional Auctionator / TSM providers (plan above; licences and interfaces on Forever verified first, D-110)
- [ ] 6.2 PricingEngine valuation (conservative, staleness); the bound state of an item is read live, not from the lot
- [ ] 6.3 AHMath: cut, deposit, failure risk, expected net; tests
- [ ] 6.4 Own list/sold/expired history for sell-through estimates
- [ ] Disenchant-value estimates need a drop-chance source (ask for a reference add-on then)
- Exit test: AHMath matches hand calculations; the add-on works with no price source.

### Phase 7: Heatmap (REQ: FR-HEA-1..4)
- [ ] 7.1 HeatMapEngine queries and smoothing over the 0.6.x heat bins (32 x 32, time and credit already recorded)
- [ ] 7.2 Map overlay (see the main-window plan): texture pool, tooltip, activity filter, metric selector
- [ ] Inside an instance the map id is nil and only the zone name is known (D-060 places instance runs at the entrance)
- [ ] Beta characters and Account Best (D-089)
- Exit test: acceptance criterion 4; opening the map does not drop the frame rate noticeably (measured).

### Phase 8: UI (REQ: FR-MET-2, FR-MET-5, FR-PLT-2)
- [ ] 8.1 Main window: dashboard (Cash GPH always visible), sessions, rankings, AH profit, settings (the 0.6.1 Settings
  window is its seed), minimap button
- [ ] 8.2 Explain-breakdown view for every metric
- [ ] 8.3 Capability-degradation messages
- Exit test: manual walkthrough checklist recorded in the handoff.

### Phase 9: Hardening and release
- [ ] 9.1 Performance against NFR-3 (baseline 0.017 ms per frame on 0.5.6)
- [ ] 9.2 Acceptance criteria 1-7 checklist
- [ ] 9.3 Release notes; version 1.0.0

## Deferred (do NOT start; Requirements section 1)

CommunityDataEngine behaviour; RouteEngine behaviour; community sync; guild sharing; route detection and optimization;
ML recommendations; world heatmap; craft profitability ranking; auto-detection of dungeon / rare / boost activities.

## Open questions and housekeeping

- [ ] Before using any other add-on as a source or reference: verify its licence (D-110); THIRD_PARTY.md with the first
  copied item.
- [ ] OI-16 privacy scrub (deferred while the repository is private); OI-17 status of D-029..D-031; OI-5, OI-13 and the
  OI-8 closing wording unchanged (Decisions.md).
- [ ] Optional: a folder link from Shawn's computer to cloud sessions (D-087); today evidence files are attached by
  hand.
