# 0.5.6 baseline report (D-102 Q-7, D-109)

DATE: 2026-11-14  |  SESSION: S-069  |  BUILD: 0.5.6-passive (6620666), client 1.60.1 build 70938  |  STATUS: baseline PASSED

Evidence: the user's files attached on 2026-11-14 (account file `GoldIntel.lua`, three character files). They were read
as data only, in a sandbox with an empty environment. Times are UTC. "0.5.6 period" means from 2026-11-08 14:59, the
first load whose automatic samples carry no memory reading (D-100).

## 1. Characters and files

| File | Character | 0.5.6 loads | Hours loaded | Loads >= 60 min | Periodic samples | CPU ms/frame (load-weighted) |
|---|---|---|---|---|---|---|
| char file 3 (552 KB) | Paladin, Player-6796-00636CEC | 29 | 39.9 | 13 | 224 | 0.017 |
| char file 1 (334 KB) | alt, Player-6796-00333B18 | 7 | 2.6 | 1 | 13 | 0.013 |
| char file 2 (329 KB) | alt, Player-6796-0137B07D | 9 | 4.0 | 2 | 21 | 0.014 |

"Hours loaded" runs from the begin sample to the final sample of each load, so it includes AFK time. The user's
figure of about 11.9 hours of play is lower for that reason. Groups and dungeons: group sizes 2 to 5; Gnomeregan and
Scarlet Monastery appear in the trace.

## 2. D-102 baseline criteria

| Needed | Measured (Paladin) | Result |
|---|---|---|
| at least 3 hours | 39.9 h loaded (user: about 11.9 h played Nov 11-13, plus Nov 8-10) | pass |
| at least 3 sessions, one of 60 minutes or more | 29 loads, 13 of them 60 minutes or more | pass |
| at least 18 periodic CPU samples | 224 (the reviewer's figure, confirmed) | pass |
| a group or dungeon session if possible | yes (user; trace shows groups of 2 to 5) | pass |
| 0.5.6 works live | yes (user); every 0.5.6 ledger check 0 copper; 0 collector errors; 0 UNEXPECTED lines | pass |

Q-7 baseline for P4-M2: GoldIntel's CPU is 0.017 ms per frame on average (mean of the periodic "recent" averages 0.018;
highest 0.354). The Q-7 budget is this plus at most 0.05 ms per frame. NFR-3 allows 0.5 ms.

## 3. Frames over 100 ms (the 312 ms and the 148-178 ms peaks)

The client's add-on profiler counters run per client process: they add up across `/reload` and reset only on a
restart. Each over-100 ms frame was placed between two samples.

| When | Peak | Where | Reading |
|---|---|---|---|
| 2026-11-08 15:17, 20:02, 20:04; 11-09 20:17, 20:40; alts 11-08 22:21-22:25, 11-11 03:50 | 100.6 to 177.6 ms | already in the `begin` sample, 20 to 40 s after the previous final, counters not reset: the load frame of a `/reload`; `LastTime` equals the peak | GoldIntel's own load (code and SavedVariables). The screen is frozen during a reload anyway. It never appears at a fresh login. Cause inside the load is not measured; the 1.9 MB account file is a candidate (unverified). |
| 2026-11-14 00:08 to 00:18 (load +6014 to +6622 s) | 312.2 ms | in the middle of the 8-hour session that began 11-13 22:27 | The shared Lua heap shrank from 1,258 to 1,180 MB in that window. |
| 2026-11-14 00:58 to 01:08 | over 100 ms (peak stayed 312.2) | same session | The heap shrank from 1,419 to 1,363 MB. |

Network lag is not the cause: the profiler counts CPU time spent inside the add-on's own code, and waiting on the
server adds none. The two in-session frames fit a garbage-collection step of the 1.2-1.5 GB heap that all add-ons share,
charged to GoldIntel because its code was running at that moment. That is an inference: the rolling trace had already
rotated past both windows, and nothing of GoldIntel's ran at the time (no retention fold, `folded = 0` everywhere).
For comparison, on 0.5.5 (2026-11-08 01:10 to 06:44) the Paladin had 49 frames over 100 ms in 5.4 hours loaded, about one per automatic sample (D-100); on 0.5.6 there are two in-session frames in 39.9 hours, plus the reload frames.

## 4. "103 unmatched against 95 intervals"

`quality.unmatched` (Paladin: 103 over 95 intervals since 2026-11-04, all builds) counts *exact expectations* that
expired or were cleared without a matching money change (Expectations.lua). It is not missing money: an expectation
is announced when a signal promises an amount (a loot coin line, a money mail being taken), and it stays unmatched
when that amount never arrives as its own money change, for example a mail deleted or returned instead of taken
(R-3b2-5), or coin that arrived in a different split. The money itself is always booked: every ledger check is 0 and no
gap was recorded. Of the 27 unmatched lines still in the Paladin's trace, 21 are loot and 6 are mailMoney. About one per
interval is the normal rate; all nine characters together have 120 over 164 intervals.

## 5. Ledger, OTHER share, memory

- Ledger checks: Paladin 105 periodic and 6 final checks in the file, all 0. The only MISMATCH lines in any file
  (-271 and -6, alt Player-6796-00333B18) are from 2026-11-05: the entries reach +271 at 03:08 and fall back to +6 at
  05:37 that day. That was 0.5.1, before the D-092 logout fix (S-059 already reported "MISMATCH only on old 0.5.1
  lines"). The lines remain in `trace.keep`.
- Paladin, 0.5.6 period: income 23.85 g (vendor 44.5 %, loot 26.6 %, quest 24.6 %, AH sale 2.8 %, OTHER 1.2 %);
  spending 14.88 g (trainer 71.2 %, OTHER 18.3 %, purchase 10.2 %). Spending OTHER is mostly auction house deposits
  and buyouts, flight fares and postage (largest: -5,030 twice on 11-10 23:39, -3,000 on 11-14 01:02), which stay OTHER
  by design until 3b-4.
- Memory: the 1.2 to 1.6 GB the user saw is `uiLuaKB`, the whole UI Lua heap of every add-on. GoldIntel's own share
  is read only by `/gi perf` since 0.5.6 (D-100). It was last measured on 2026-11-08 on 0.5.5: 6.6 to 14.3 MB, against
  a 0.53 to 1.4 GB heap, so about 0.5 to 1 %. Run `/gi perf` once for a current figure (it can freeze for a moment).

## 6. Prices: what GoldIntel does now, and optional Auctionator / TSM sources (plan question, no code)

**Now (Valuation.lua, D-043..D-046, D-063, D-082):** an item lot is valued once, when it is acquired. Tier 1 is the
vendor sell price from item info. Tier 2 is a manual price (`/gi price`); the higher of the two is used. An item with no
answer yet is "unknown" and is never valued at 0. An existing value is never revised (D-063). There is no market price:
`GoldIntelDB.prices.snapshots` is empty in your file, and auction house prices are Phase 6, not authorized.

**Recommendation: yes, as an optional source, with GoldIntel's own price always available.**

1. One adapter in `Platform/` (no add-on API calls elsewhere, Bible principle 3) asks the installed price add-ons in a
   fixed order and records which one answered. With none installed, GoldIntel uses tier 1 and tier 2 as today, and
   later its own auction house observations (Phase 6).
2. Candidates, all **unverified on Forever**:
   - Auctionator's public interface (`Auctionator.API.v1`, for example a price by item id with a caller id). The Forever
     build exists (Reference_Auctionator.md: `Auctionator.Constants.IsForever`).
   - TSM's `TSM_API.GetCustomPriceValue` with a price source such as DBMarket. TSM's Forever support is not known.
3. Rules: a market price is stored with its source and age, as a separate figure (value at market) beside the
   acquisition value, which never changes (D-063, D-082 dynamic heat map). Cash GPH never uses it. An answer that is
   missing, nil or "secret" counts as no price, never 0 (D-045).
4. D-110: calling a public interface at runtime is not copying code. Before building, verify each add-on's licence and
   its interface in the installed copy. GoldIntel copies nothing from TSM (All Rights Reserved, to be confirmed) or from
   any GPL source.
5. Live checks first: is Auctionator or TSM installed on your client? Do the interface calls answer on Forever? Do they
   answer for commodities and for single items?

Decision for the user: whether this becomes part of the Phase 6 scope. Nothing is built before that.

## 7. Accountant Classic cross-check (D-110): not done yet

The four files of 2026-11-14 are all GoldIntel files. Accountant Classic's SavedVariables file sits in the same
SavedVariables folder (the exact file name needs checking on your disk). When it is attached, the comparison per
session will be: income and spending totals, OTHER against Accountant's categories, the same time windows, and any
copper difference explained. It will be read only for comparison.
