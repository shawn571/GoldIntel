# 3b-2 M3 review package (M1-M3 complete) - APPROVED; retention cap later set to 2000 (0.3.3)

Addon 0.3.2-phase3b2m3, Contract 1.8.0 (F15 added), session S-046, 2026-10-18.
Package: `GoldIntel_3b2_M3_AddOns.zip`. Rollback package: `GoldIntel_3b1_AddOns.zip` (0.3.1).
**Install: a CLIENT RESTART is required (TOC changed: two new files). `/reload` is not enough.** Collect is OFF after login and after every reload; the ledger runs only after `/gi collect on`.
Live validation (M4) has NOT been started and needs your separate go-ahead.

Test status: `texlua run.lua` = **984 passed, 0 failed** (903 before the new M3 test files). New: `test_schema2` (19 tests, real files), `test_cash` (15), `test_ledger` (21), `test_ledger_mutation` (scenario suite + 24 mutants, all caught).

## 1. Schema 2 migration (review focus 1)

- Inputs are the REAL files you produced: E-43 and E-45 `GoldIntelDB`, E-44 and E-45 `GoldIntelCharDB` (stored under `Tests/fixtures/migration/`, a missing fixture fails the suite), plus the Phase 1 database (schema 0 -> 2).
- Result on both account files: state `migrated`, schema 2, `compat` byte-for-byte identical, every other schema 1 key (config, lots, sessions, ...) equal to the input, `ledger = {}` created, `meta.schemaHistory` gains `1 -> 2`. Saved through `svsim.dump/parse`, reopened as `ok`, not migrated twice, backup left untouched.
- `migrationBackup = { from = 1, t, keys, data }` is a deep copy of the schema 1 keys except `compat`, `runtime`, `migrationBackup`. Size on the real files: **708 bytes**. The whole file grows from 23,514 to 24,339 bytes (E-43) and 21,197 to 22,022 (E-45).
- Rollback (tested with the actual 0.3.1 `Store.lua` and `Migrations.lua` loaded through `Loader.override`): 0.3.1 opens the schema 2 file as `readonly` ("newer than this addon"), does not modify it, and a full 0.3.1 session changes nothing except `compat` (which the Probe owns). CharDB schema 2 is treated as newer and handled on a private copy. A manual recovery file rebuilt from `migrationBackup` opens as `ok` in 0.3.1.
- Per-character `lots` (F5b) are left untouched: 3b-3 owns them. This is a deliberate deviation from the F5b text and is flagged here.

## 2. Cash store (focus 2)

- Compact records (`Contracts F15`), places interned once per file (`locs`), coordinates rounded to 4 decimals, game time converted to unix seconds through the clock offset.
- Immutability: no update or delete function exists; `Last()` and the `LEDGER_CASH` event hand out expanded copies (tests mutate the input, the output and confirm the store is unchanged).
- Retention (interim, D-077 Q-6): above 5,000 raw records the oldest 500 fold into `totals` (per source n/copper/value, gap totals, folded count). `Cumulative()` (raw + totals) is unchanged by folding. Evidence: a 400-entry random run with signed amounts, all sources and gap entries at CAP 30 / FOLD 7 checks `Cumulative()` after EVERY add; Stats totals, OTHER shares and gap totals match exactly; `largestOther` survives after its record is folded; the real 5,000/500 limits are tested with 5,001 entries and a save/load.
- **Entry size (for the retention review):** about **212 bytes per entry** serialized (1,000 entries = 211 KB; 4,500 = 956 KB, each with a place, coordinates, creature loot type). A full 5,000-entry ledger is about **1.06 MB per character**, saved and loaded at every login/logout. Please decide whether CAP 5,000 is acceptable or should drop (a CAP of 2,000 would be about 0.4 MB); this is the open Q-6 final review.

## 3. lastMoney (focus 3)

Written at: interval begin, after every entry, interval end (collect off), logout. Tested:
- first run: baseline only, no gap;
- normal logout/login with equal balance: no gap;
- money changed while collect was OFF in a normally saved session: no entry, no gap (the logout writes the true balance);
- client crash (no logout) with a balance change: exactly one gap entry at next login (`src other`, `comp gap`, `ctx login`, signed), cumulative honest again; a second crash right after does not create a second gap;
- read-only store: no gap, nothing written.

## 4. Collector wiring (focus 4)

`collect on` (all groups) begins the interval and prints `ledger: interval started`; `collect on G1` (a single group) does not start it and prints `ledger: not started: partial collection`; `collect off` ends it and pending money becomes OTHER immediately; `/gi ledger off|on` switches the interval while collect keeps counting events; collect is OFF after a reload. Money outside an interval is not recorded.

## 5. Commands (focus 5)

- `/gi ledger` (status), `last [n]`, `mark`, `check`, `on`, `off`.
- `check` prints `money moved, entries, pending, unseen -> DIFFERENCE n copper (OK|MISMATCH)`. It stays OK with pending money and with window/exact entries in the span; it reports MISMATCH (difference 42, unseen 42) when the balance moves without a PLAYER_MONEY event.
- `/gi diag` now prints the ledger-quality block first (OTHER share by value (headline) and by entries, largest OTHER, gap count and value, unmatched, intervals), then the unchanged diagnostics.

## 6. Runtime accounting invariant with real storage (focus 6)

Six sessions, 360 random money changes of both signs, CAP 25 / FOLD 6 (so folds happen constantly), each session ended through `svsim.dump/parse` (only what the client could save carries over), including a session with collect OFF (+1,000 copper outside the ledger) and a session ending in a crash:
**after every session the saved `Cash.Cumulative()` equals the exact sum of money deltas while the ledger was on (difference 0 copper).** The crash session recovers through the login gap entry.
Also: `ledger mark/check` differences are 0 over mixed exact, window and pending money.

## 7. Mutation checks

24 deliberate bugs in `Cash.lua` and `Ledger.lua` are caught (fold drops copper/value/gap totals, fold keeps records, Cumulative ignores totals, largestOther untracked, id not advanced, zero accepted, time not converted, gap flag lost, places not interned, Last returns stored records, lastMoney not refreshed / not written at logout, logout does not end the interval, gap sign flipped, first run creates a gap, gap leaves lastMoney stale, gap written to a read-only store, check ignores pending (two variants), unmatched/intervals not stored, partial collect starts the ledger, collect off keeps the interval). One survivor was found and fixed by a new scenario (logout `lastMoney` after an OFF period).

## 8. Flags and judgment calls for your review

1. Lots untouched in the migration (above).
2. Compact field names and place interning are new storage conventions (documented in F15).
3. `/gi diag` is extended (ledger block first); old output is unchanged.
4. A single-group `collect on Gn` does not start the ledger.
5. `quality = { intervals, unmatched }` counters are persisted per character; `largestOther` is persisted.
6. A crash loses the pending (unmatched-in-time) part of the session; the next login's gap entry restores the cumulative (R-3b2-1). OTHER share by value is the headline in Stats; gap count/value and unmatched remain visible in `/gi ledger status` and `/gi diag`.
7. Retention CAP value (section 2).
8. Version bumped to 0.3.2-phase3b2m3; fixtures keep their original 0.3.1 values.

## 9. M4 live validation plan (NOT started)

1. Move `GoldIntelDiag` and `GIProbeLoot` out of AddOns; extract `GoldIntel_3b2_M3_AddOns.zip`; restart the client.
2. Session A (normal): `/gi collect on`, `/gi ledger mark`, play normally (loot, vendor, quest, mail, trade), `/gi ledger check` repeatedly (difference must be 0), `/gi ledger status`, `/gi diag`, `/gi collect off`, `/reload`, confirm collect is OFF and the ledger persisted.
3. Session B (AUTO-LOOT): same with auto-loot enabled, to settle R-3b2-2 (coin arrival relative to the loot window).
4. Optional: AH sale mail.
5. Report: OTHER share by value, gap count, unmatched, largest OTHER, difference at every check.

Files changed: new `Ledger/Cash.lua`, `Ledger/Ledger.lua`; `Store/Migrations.lua`, `Store/Store.lua`, `Collect/Collector.lua`, `Core/Slash.lua`, `Platform/Platform.lua`, `GoldIntel.toc`; docs Contracts (F15), Decisions, TODO, Changelog, Session_Handoff (S-046).
