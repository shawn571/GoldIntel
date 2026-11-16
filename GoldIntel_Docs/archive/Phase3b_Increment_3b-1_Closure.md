# Phase 3b increment 3b-1: closure recommendation

Addon 0.3.1-phase3b1, contract 1.7.1, build 70450. Evidence E-41 .. E-45. 790 automated tests, 0 failed.
Status: CLOSED by the user 2026-10-18 14:38 (D-076). 3b-2 is not started and not approved.

## 1. Validated items (live, real client)

| Item | Evidence | Result |
|---|---|---|
| `/gi collect on` registers all 14 collector events, no popup | E-41, E-43, E-45 (6 times over 3 rounds) | 14 registered, 0 failed, 0 skipped, no popup |
| `RegisterUnitEvent` for casts | E-41, E-43 | works: `via unit-filter`, 15 casts, 15 kept, 0 dropped |
| Collect is OFF after login and `/reload` (A-3) | E-41, E-43, E-45 | confirmed each time |
| Off/on cycle, no duplicate delivery, nothing counted while off | E-41, E-43 | confirmed (vendor +1 open +1 close after re-enable; unchanged while off) |
| Loot window lifetime (revised rule, D-075) | E-42 probe (8 windows), E-43 (7 windows) | 7/7 closed by frame, 0 timeout, 0 replaced, longest open 30.5 s |
| Loot slot clears informational, doubled clears dropped | E-42, E-43 | 10 received = 6 distinct + 4 duplicates, 0 late |
| Vendor open/close, doubled close | E-41, E-43 | 1 duplicate per walk-away close, contexts balanced |
| Mail window context and inbox snapshots | E-45 | 3 opens / 3 closes, 7 updates, 7 snapshots, 0 stale |
| Quest turn-in | E-45 | 1/1, context balanced |
| Trade windows (completed, empty, gift of money) | E-45 | 3 opens / 3 closes, duplicate closes dropped |
| Auction posting event | E-45 | 1/1, context balanced |
| Registration journal, quarantine file structure | E-44, E-45 character files | no pending marker, empty quarantine |
| Per-character file location | E-44 | `...\70\<First-Last>\SavedVariables`, separate per surname |
| Errors | all rounds | 0 |

## 2. Remaining risks

1. **Gathering casts not exercised live.** The four verified spell ids (herb, mine, skin, fish) were never cast under collect; all 15 live casts were 'other'. Low impact now; matters for the activity engine later.
2. **Mail field decoding not re-read live.** Counts and CPU are validated; the decoding of header, COD and invoice fields is validated against recorded real data (E-29, E-34, E-39, E-40) in tests but not printed live. A mail with an invoice or COD was not opened in round 3 (a plain item mail was taken).
3. **Mail snapshot cost depends on inbox size.** Measured 0.16 ms mean per snapshot, 0.3 ms max, with an unrecorded inbox size. The worst case (50 mails) is extrapolated, not measured.
4. **Poll costs are not in the per-event counters.** The mail (0.5 s), loot (0.1 s, only while a window is open) and auction-house polls call `IsShown()` and are expected to be negligible, but they are not measured.
5. **Contexts are an inference tool, not proof.** The 1.0 s linger covers every measured lag (largest: loot 0.509 s, trade 0.394, first loot money 0.378, mail 0.365, auction deposit 0.358, mail take 0.267), but one frame hitch of 0.726 s was seen; a hitch plus a slow signal could exceed it. 3b-2 must treat an unexplained money move as `OTHER` rather than assume coverage.
6. **Character identity stamp (optional hedge, low risk).** Not built; not a blocker (user decision 14:07).

## 3. Open assumptions

- Loot frame poll 0.1 s and 300 s backstop (the longest observed window was 30.7 s); the unreadable-frame fallback has never triggered live (0 of 15 windows).
- `TRADE_CLOSED` arrives once or twice per window (5 for 3 windows in E-45), so the adapter must stay duplicate-tolerant, never duplicate-dependent.
- `TRADE_MONEY_CHANGED` was not delivered when the player gave money (0 of 2 trades); 3b-2 must not rely on it.
- A quest reward choice is not visible in `QUEST_TURNED_IN`; the collector cannot tell which reward was taken.
- `GET_ITEM_INFO_RECEIVED` bursts (up to 13 per second) are cheap (0.1 ms in total) and need no throttle.

## 4. Profiling observations (per-event dispatch CPU)

| Event | Events | Total ms | Max ms | Mean ms |
|---|---|---|---|---|
| MAIL_INBOX_UPDATE | 7 | 1.1 | 0.3 | 0.16 |
| LOOT_OPENED | 7 | 0.6 | 0.1 | 0.09 |
| TRADE_SHOW + TRADE_CLOSED + TRADE_ACCEPT_UPDATE | 10 | 0.2 | 0.0 | 0.02 |
| GET_ITEM_INFO_RECEIVED | 35 | 0.2 | 0.0 | below 0.01 |
| LOOT_SLOT_CLEARED, UNIT_SPELLCAST_SUCCEEDED | 20 | 0.2 | 0.0 | 0.01 |
| all others | | 0.0 | 0.0 | |

A whole validation round of normal play cost about 1 to 1.5 ms in total across all 14 events, against a frame budget of about 16 ms; the heaviest single call was 0.3 ms (a mail snapshot).

## 5. Recommendation

Close 3b-1. All approved scope is delivered and validated live; the one falsified assumption (A-4) was corrected on evidence (D-075, E-41, E-42, E-43) and no popup, registration failure or quarantine occurred in three rounds. Suggested optional follow-ups, none blocking: (a) one gathering cast and one invoice or COD mail checked live, (b) poll counters, (c) the identity stamp. 3b-2 needs your separate approval and should only be discussed after you accept this closure.
