# 3b-2 Milestone M2 report: Sources, Stamps, LastCast, replay classification, Contract 1.8

Status: M2 BUILT, for the user's review. M3 (Cash store, retention fold, schema 2 migration, `/gi ledger` and `/gi diag` commands, collector wiring, `lastMoney` gap at login) is NOT started. Nothing calls `Sources.Begin()` in the game yet (only tests do), so the addon behaves exactly as 3b-1 in the client. **No `/reload` or restart is needed**, and no install is needed. The rebuilt packages contain the new files (inert) and the unchanged-in-behavior 3b-1 collector; `GoldIntel_3b1_AddOns.zip` is still the rollback.

## 1. What was built
| File | Role |
|---|---|
| `Collect/Sources.lua` | The only module that knows what events mean for money (AC-10). Translates loot coin, quest, mail (inbox diff), vendor and trade windows into expectations; feeds `P_MONEY` to the Reconciler; 0.25 s ticker; `Begin/End/Stats/Entries/SetSink/MailSpec`. Handlers are wrapped in pcall (counted `handlerErrors`). |
| `Collect/Stamps.lua` | Pure. Location stamp (fresh <= 5 s, stale, none), activity stamp, `creditable`. |
| `Platform/Unit.lua` | `Platform.LastCast(kind)` (read-only; secret spell ids never stored). |
| `Collect/Expectations.lua` | One additive change from M1: `hold` (an exact expectation with no expiry until `Close`, used while the loot window is open: money arrives when the player clicks, which can be 25 s after the open, E-42). |
| Docs | Contracts 1.8.0 (new F14, as-built shapes), Architecture AC-9..AC-13 text, Q-4 edge-case change. |

Separation kept as you required: Sources -> Expectations -> Reconciler -> (Cash in M3). Expectations, Reconciler and Stamps contain no WoW knowledge; the static boundary test covers all new files.

## 2. The review question: do replayed E-22..E-45 produce the expected classifications?
Answer: **yes for every case that can be replayed.** `Tests/test_replay_ledger.lua` replays the real event order and lags of the corpus through the real adapters, Context, Sources, Reconciler and Stamps. Each case first PINS the fixture (it fails if the recorded event or money sample is not at that time), so a changed corpus cannot pass silently.

| Case | Evidence | Replayed sequence (real lag) | Result (all asserted) |
|---|---|---|---|
| Quest | E-22 | QUEST_TURNED_IN, money +175 after 0.041 s | 1 entry `quest` +175, high, QUEST, not creditable; OTHER 0% |
| Mail money | E-28 | inbox update, money +44 after 0.365 s | 1 entry `mailMoney` +44, high, settle, MAIL |
| Trade | E-31 | doubled TRADE_CLOSED, money -10 after 0.394 s; cancelled trade (zero move) | 1 entry `trade` -10, med, TRADE; cancelled trade gives no entry |
| Vendor | E-33 | real session: sale +18097, then -10 and -83 inside one window; doubled close 4.668 s later | `vendor` +18097 med; `purchase` -10 med; `purchase` -83 med; no OTHER |
| AH sale | E-34 | +149 | 3 entries: `ahSale` +51 (settle), `ahCut` -2, `ahDepositRefund` +100 (comp deposit), all high, sum 149; money at exactly 1.0 s still matches; at 1.2 s: OTHER 149 + 1 unmatched |
| COD paid + money mail | E-39 | COD mail leaves, -100 after 0.106 s; money mail leaves, +30 after 0.233 s | `other` -100 low (option A); `mailMoney` +30 high settle. Reported: OTHER share by value 76.9%, by entries 50%, largest OTHER 100 |
| COD payment mail | E-40 | "COD Payment" mail, +100 after 0.267 s | 1 entry `codIn` +100, high, settle, MAIL |
| Loot | E-42 | the 8 recorded loot windows, 1 copper per slot, money 0.378 s after each distinct clear | 5 `loot` entries, high, GRIND; expectations for unlooted slots expire as `unmatched` (total slots - 5); OTHER 0% |

Every case also asserts `sumDeltas = sumEntries + pending`, nothing pending, and (where stated) unmatched, gap count and OTHER shares.

What could NOT be replayed from a file, and how it is covered instead:
- **E-35..E-38 (AH deposit, bid, postage) and E-45:** the corpus holds no timelines for them (E-45 and the 3b-1 round files are collector statistics, not event streams). They are covered by `test_sources.lua` with the measured lags from the notes (deposit 0.358 s after the event, bid inside the AH window) and are asserted to be `other`, as option A requires.
- **Amounts:** the lab files are cumulative and splice several lab sessions, so a delta between two samples of different sessions is meaningless (for example the E-22 file shows -17826 around the quest). Each case uses only deltas from consecutive samples of the same session (E-33, E-31) or the amount written in the evidence note (E-22 175, E-34 149 with invoice 51/100/2, E-39 -100 and +30, E-40 +100, E-28 44). The E-33 sale amount (+18097) is a real consecutive-sample delta.
- **E-34 mail-to-money lag** is not in the recording; the case uses 0.3 s (inside the measured 0.233..0.367 band) and tests the 1.0 s and 1.2 s boundaries.
- **Mailbox contents** are rebuilt from the evidence notes (the files hold no header values).

## 3. Verification
- Suite: **901 passed, 0 failed** (818 at M1; +83). New: Stamps and LastCast and held expectations 17, Sources 36, replay ledger 11, Sources mutation 20 (including a scenario suite), plus 2 changed existing assertions (contract version).
- Mutation checks: 9 on Stamps, 16 on Sources, all caught. Three Sources mutants survived at first (baseline ignored, gap flag dropped, vanished mail counted once only); each produced a new scenario instead of being accepted.
- Unchanged: allow-list, boundary and 3b-1 tests.

## 4. Judgment calls to confirm (all small and reversible; nothing is persisted yet)
1. `ahCut` and `ahDepositRefund` carry `settle = false`; only `ahSale`, `mailMoney` and `codIn` are settlement (the deposit refund "is not income", D-070).
2. Activity for mail-paid sources is `MAIL`, including AH sale proceeds.
3. Skinning loot (creature GUID) is GRIND; only game-object loot after a herb/mine/fish cast within 30 s is GATHER/FISH (high, because the four spell ids are the verified ones, E-23).
4. The first inbox update after the mailbox opened is a baseline only; money mails are diffed by `sender|subject|money|cod`, not by the full fingerprint, so taking only the items of a mail that also holds money creates nothing.
5. COD detection uses the English subject prefix "COD Payment:" (R-3b2-4); other locales fall back to `mailMoney` (still settlement).
6. Ticker 0.25 s while an interval is active (the 1.0 s wait therefore resolves within 0.25 s).
7. The loot coin expectation is held while the loot context is open (a safety net releases it if the context is gone), then lives 1.0 s.

## 5. Known limits (unchanged risks, now visible in code)
- More than three money mails taken inside one money event, or a combination outside the 8 highest-priority candidates, falls to OTHER. The sum invariant still holds.
- A money mail that was deleted, returned or expired creates an expectation that expires `unmatched` (R-3b2-5); the counter shows it.
- Auto-loot is still not validated live (R-3b2-2). The legacy close rule is exercised only by unit tests. Live session 2 covers it, after M3.
- Location stamp uses the last good position at the time the entry is finalized, up to 1.0 s after the money moved; a zone change inside that second could mis-stamp (negligible).

## 6. Diagnostics (as you asked, kept visible)
`Sources.Stats()` returns: `otherShareValue` (headline), `otherShareEntries`, `largestOther`, `gapCount`, `gapValue`, `unmatched`, `pending`, `ignored`, `sumDeltas`, `sumEntries`, `bySource`, `lowConfShare`, plus the source counters. The commands that print them (`/gi ledger status`, `/gi diag`) are part of M3.

## 7. Next
M3 (needs your approval of M2): Cash store (`GoldIntelDB.ledger`), 5,000/500 retention fold, schema 2 migration with `migrationBackup` and the E-43 real-file fixture, `lastMoney` and the login gap entry, `LEDGER_CASH`, collector wiring (`collect on` begins an interval, `off` ends it), `/gi ledger status|last|mark|check|off|on`, `/gi diag`. Live validation does not start until the M1-M3 review package is complete.
