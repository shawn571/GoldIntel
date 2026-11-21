# P4-M2 review: 0.6.0-passive before approval (S-071)

DATE: 2026-11-14  |  BRANCH: p4/m2-live (PR #9)  |  STATUS: for the user's approval; NOT merged, NOT installed

PR #9 was brought up to date with main (merge commit 1221a7c, documents only conflicted; addon files identical to the
built e6946b0). Tests: 1,365 passed, 0 failed (main: 1,343).

## 1. What 0.6.0 adds in the game

- Live totals per place x activity x 5-level bracket (gold in and out, loot coin, value of items created, item counts,
  active time) and 32 x 32 heat bins per map (time in every visited bin; credit for GRIND, GATHER and FISH value).
  Fed by the cash ledger and the lot book; it decides no source and no value (AC-15).
- A time clock every 0.5 s: active, idle, flight path, soft travel, paused (D-054 priority). Aggregates lag play by up
  to 2 minutes (the clock waits until a slice's class is certain).
- Commands: `/gi agg status`, `/gi agg check`, `/gi agg top [n]`, `/gi pause`, `/gi afk`, `/gi resume`,
  `/gi activity <KEY>` and `/gi activity clear`.
- One chat line every 60 minutes after a load, never in combat: "GoldIntel: 60 minutes since your data was last
  saved; /reload saves it" (setting `reminder.reloadMinutes`, 0 = off; D-099 Q-6).
- Probe capability `map.worldsize` (C_Map.GetMapWorldSize, unverified in Forever). Without it, soft travel stays
  undecided and that time counts as active.
- Nothing changes in the cash ledger, the lot book or `/gi ledger check`.

## 2. What it changes in saved data

- Account file `GoldIntelDB`: new `agg[<character GUID>]` (places -> cells with cin, cout, coin, vc, item counts q,
  seconds s, first and last time; totals; a ring of at most 200 segments; `backfilled`; `check` offsets) and
  `heat[<character GUID>]` (map -> bin index -> seconds, credit, credit per activity). The empty placeholder sections
  already exist in 0.5.6 files. No migration; schema stays 2. Existing sections are not changed.
- First start per character: a one-time back-fill of value and item counts from the saved records, without time
  (D-099 Q-4); back-filled cells have level bracket "?" and 0 seconds.
- Character files: new trace line kinds `EVT agg`, `EVT clock` (every 10 minutes and at the end of an interval) and
  `EVIDENCE mapWorldSize`. They are kept in `trace.keep`.
- New setting `reminder.reloadMinutes` in the profile.
- Rollback to 0.5.6 is safe: the 0.5.6 store never touches keys it does not know (Migrations.EnsureShape), and a test
  covers a file holding agg and heat under a build without Live.

## 3. CPU and memory against the 0.5.6 baseline (0.017 ms per frame)

Not measured in the game yet; that is P4-M3. Measured here on the user's real Paladin records (desktop Lua 5.4; the
game's Lua is slower, so treat these as lower bounds and allow a factor of up to 10):

| Item | Measured | Q-7 budget |
|---|---|---|
| Back-fill (once per character, at first start) | 4,693 records in 8.7 ms; 121 places, 257 cells, 12 maps, 244 heat bins | (one-off, at login) |
| Clock and aggregation, simulated 8-hour session | 0.0099 ms per 0.5 s tick incl. drains = 0.0003 ms per frame at 60 fps; largest single call 0.44 ms | +0.05 ms per frame |
| Saved data | +80 KB at back-fill (agg 63 KB, heat 17 KB); +7 KB per hour of play | +0.2 MB per hour |
| Memory in the game | +0.27 MB at back-fill; +20 KB per hour (simulation) | +0.2 MB per hour |

Not in the simulation: Live.lua's own client calls on each tick (player, position, flight-path state), the trace lines
and real variety of places. Expected total: 0.017 ms per frame rising to about 0.02, well inside the +0.05 budget. The
account file (1.9 MB) grows by about 4 %; reload frames (100 to 178 ms on 0.5.6) may grow slightly with it.

## 4. Review findings (not fixed; no code change without approval)

1. `EVT agg` and `EVT clock` go to `trace.keep` every 10 minutes (12 lines per hour). The keep list is capped at 400
   and is already full on the Paladin, so older evidence (UNMATCHED, unexplained, checks) rotates out sooner.
   Option: keep only MISMATCH and final lines. Minor. DECIDED and FIXED (D-113, S-072): only final and MISMATCH
   lines are kept; `EVT clock` lines carry `periodic|final`; tests added (1,369 pass).
2. The reminder counts from the load, not from the last save; a disconnect or logout also saves. Matches the approved
   text ("since your data was last saved" is true from the load). No change proposed.
3. `map.worldsize` and the 8 yards per second soft-travel speed are unverified; the `EVT clock` speed buckets are the
   evidence to settle them in P4-M3.

## 5. Approving the install starts P4-M3 (live validation)

Installing 0.6.0 is the live validation of Phase 4. The approval should say whether it covers installing only, or also
merging #9 after the live check (as D-102 did for #8 and #7).
