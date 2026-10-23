# GoldIntel - Increment 3b-1 Plan (Platform adapters, Context, event registration, counters, collect on/off)

DOC VERSION: 1.0.0  |  DATE: 2026-10-18  |  AUTHOR: Claude (S-041)  |  STATUS: PROPOSED, FOR USER REVIEW. No code is written. Starting 3b-1 needs the user's approval of this plan (D-067).

Basis: D-067 (scope), D-069 (AC-1..AC-8), D-072 (profiling), D-073 (replay corpus), Contracts 1.6 (F2c, F3b), E-17..E-40.
3b-1 builds NO ledger, NO expectations, NO Reconciler, NO lots, NO schema change (schema stays 1; schema 2 arrives in 3b-2).

## 1. What 3b-1 delivers

1. Seven Platform adapters that turn raw client events into the normalized `P_*` events already in the event table (plus two additive ones, section 3.3).
2. A Context module that knows which windows are open (loot, vendor, mail, trade, auction house) and for how long, and emits `CONTEXT_CHANGED`.
3. Registration of the verified collector events, in groups, behind `/gi collect on|off`.
4. Delivery counters per event, readable with `/gi collect stats`.
5. A registration journal and a quarantine list so a popup can never repeat itself (section 9).

Nothing is stored except a small counter summary and the quarantine list in `GoldIntelCharDB`.

## 2. Exact event allow-list

Already registered since Phase 1 (12, unchanged): PLAYER_LOGIN, PLAYER_ENTERING_WORLD, PLAYER_LEAVING_WORLD, PLAYER_LOGOUT, PLAYER_MONEY, PLAYER_REGEN_DISABLED, PLAYER_REGEN_ENABLED, PLAYER_LEVEL_UP, SKILL_LINES_CHANGED, ZONE_CHANGED, ZONE_CHANGED_INDOORS, ZONE_CHANGED_NEW_AREA.

New in 3b-1 (13, exactly the AC-1 list minus PLAYER_MONEY which is already registered), registered only by `/gi collect on`:

| Group | Event | Evidence |
|---|---|---|
| G1 loot and quest | LOOT_OPENED | E-18..E-20, E-24 |
| G1 | LOOT_SLOT_CLEARED | E-19 |
| G1 | QUEST_TURNED_IN | E-22, E-32 |
| G2 vendor | MERCHANT_SHOW | E-21 |
| G2 | MERCHANT_CLOSED | E-21, E-33 |
| G3 mail and trade | MAIL_INBOX_UPDATE | E-28, E-34, E-39, E-40 |
| G3 | TRADE_SHOW | E-31 |
| G3 | TRADE_CLOSED | E-31 |
| G3 | TRADE_ACCEPT_UPDATE | E-31 |
| G3 | TRADE_MONEY_CHANGED | E-31 |
| G4 items | BAG_UPDATE_DELAYED | E-32 |
| G4 | GET_ITEM_INFO_RECEIVED | E-30 |
| G5 casts (highest suspicion, last) | UNIT_SPELLCAST_SUCCEEDED | E-23 |

After `/gi collect on` the addon has 12 + 13 = 25 raw events registered. Never registered: COMBAT_LOG_EVENT_UNFILTERED, MAIL_CLOSED (never delivered, E-34), MAIL_SHOW (unverified), any event not in this table.

**Decision requested (A-1), optional G6:** add `AUCTION_HOUSE_AUCTION_CREATED` (E-36: fires once per posting, 0.358 s before the deposit leaves) as a 14th event in its own group G6, so the validation also covers posting. It is an AC-1 amendment because AC-1 predates E-36. My recommendation: approve it (it was registered alone in the lab twice with no popup, and the deposit expectation in 3b-2 needs it). If you decline, 3b-1 stays at 13 and every number below drops by that one event.

## 3. Adapters

All in `Platform/`, the only place with WoW globals (invariant 5). Handlers only enqueue and count; the existing 0.25 s drain does the work (Architecture 5.3). Every adapter checks `issecretvalue` before comparing a payload (R-03).

### 3.1 Adapter list

| File | Raw input | Normalized output | Notes |
|---|---|---|---|
| `Platform/Loot.lua` | LOOT_OPENED, LOOT_SLOT_CLEARED | `P_LOOT_MONEY`, `P_LOOT_ITEM` per slot, `P_LOOT_OPEN`/`P_LOOT_CLOSE` context events | Reads slot data once at open (coin slot amount via the loot source info of E-18, item id and quantity, source GUID type only). No bag reads. |
| `Platform/Merchant.lua` | MERCHANT_SHOW, MERCHANT_CLOSED | `P_VENDOR_OPEN`, `P_VENDOR_CLOSE` | Close is idempotent: the client sends two close events on some routes (E-33). |
| `Platform/Quest.lua` | QUEST_TURNED_IN | `P_QUEST_DONE` { questID, copper } | Money argument is a hint only (principle 1). |
| `Platform/Mail.lua` | MAIL_INBOX_UPDATE, polling of `MailFrame:IsShown()` on the 0.5 s tick | `P_MAIL_OPEN`, `P_MAIL_CLOSE`; header snapshot (sender, subject, money, COD amount, item count, invoice) kept for 3b-2 | Open and close come from polling because MAIL_CLOSED is not delivered (E-34). COD amount is read from the header's 6th return (E-39). The snapshot is read BEFORE a take. |
| `Platform/Trade.lua` | TRADE_SHOW, TRADE_CLOSED, TRADE_ACCEPT_UPDATE, TRADE_MONEY_CHANGED | `P_TRADE_OPEN`, `P_TRADE_DONE` (second TRADE_CLOSED swallowed, E-31) | Item side not read (never probed). |
| `Platform/Items.lua` | GET_ITEM_INFO_RECEIVED | `P_ITEM_INFO` (additive, 3.3), wrapper for `GetItemInfo` returning value, `pending`, or `secret` (E-30) | No pricing in 3b-1. |
| `Platform/Bags.lua` | BAG_UPDATE_DELAYED | `P_BAGS_SETTLED` (additive, 3.3), read-only bag snapshot function (item id to quantity, aggregated) | Snapshot function exists and is tested; the diff logic is 3b-3. |

Spellcasts: the `Unit` adapter gains `OnCast`, normalizing UNIT_SPELLCAST_SUCCEEDED to `P_CAST` { spellID, kind }. First line compares the unit token to `player` WITHOUT touching other arguments; every other unit returns at once and is counted as `dropped`. It first tries a unit-filtered registration (`RegisterUnitEvent`) if the function exists (recorded as capability `api.RegisterUnitEvent`); otherwise it registers normally and relies on the early return (F-5). Only the verified spell ids (2366, 2575, 8617, 7731) get a `kind`, as data in a table.

AH: no adapter in 3b-1. Auction House context is polled (`AuctionHouseFrame:IsShown()`, E-35) inside the Context module.

### 3.2 What the adapters never do

No ledger writes, no expectations, no copper arithmetic, no chat parsing, no item valuation, no persistent state, no calls to any API outside the verified lists (Compatibility_Notes).

### 3.3 Additive contract entries (Contracts 1.6 to 1.7)

`P_BAGS_SETTLED {}`, `P_ITEM_INFO { itemID, ready }`, `P_LOOT_OPEN { sourceType }`, `P_LOOT_CLOSE {}`. Additive only, so no existing consumer changes. Needs your approval together with this plan (A-2).

## 4. Context model

`Collect/Context.lua` (new directory `Collect/`, AC-3; TOC order Platform, Core, Store, Collect, Future, Boot).

| Kind | Opens | Closes | Linger |
|---|---|---|---|
| `loot` | LOOT_OPENED | 1.0 s after the last LOOT_SLOT_CLEARED, or 10 s after LOOT_OPENED if nothing was cleared (assumption, see below) | 1.0 s |
| `vendor` | MERCHANT_SHOW | MERCHANT_CLOSED (first one wins, duplicates ignored) | 1.0 s |
| `mail` | `MailFrame:IsShown()` becomes true | `MailFrame:IsShown()` becomes false | 1.0 s |
| `trade` | TRADE_SHOW | first TRADE_CLOSED (second ignored) | 1.0 s (trade money arrives 0.394 s after close, E-31) |
| `ah` | `AuctionHouseFrame:IsShown()` becomes true | becomes false | 1.0 s |
| `quest` | QUEST_TURNED_IN (instant, no window) | the same drain tick | 1.0 s (money lands 0.041 s after, E-22) |

A context record is { kind, id (counter), openedGT, closedGT or nil, lingerUntilGT, closedBy }. `Context.Active()` returns every context that is open or inside its linger. All times are `GetTime` based (Clock). Closes are idempotent. On `/reload` every context is dropped (AC-8); nothing is persisted. Bus event `CONTEXT_CHANGED { kind, open }` fires on every open and close (Contracts F3b).

**Assumption to verify live:** the lab never recorded a loot-window close (no LOOT_CLOSED event is in the allow-list). The 1.0 s after the last slot clear and 10 s fallback are my design choice. Counters record how each loot context closed (`closedBy = clear | timeout`), so the live session shows whether the timeout path is ever hit. A real loot-window poll (`LootFrame:IsShown()`) would be a new unverified API, so I do not use it without a probe.

Context state is exposed only through `Context.Active()`, `Context.Stats()`; nothing consumes it until 3b-2.

## 5. Delivery counters

Per registered raw event, held in memory by `Platform/Events.lua` (extends the existing stage data):

| Counter | Meaning |
|---|---|
| `received` | times the frame delivered the event |
| `kept` | passed the first-line filter and were enqueued |
| `dropped` | filtered at once (UNIT_SPELLCAST_SUCCEEDED for other units; duplicate closes) |
| `errors` | handler raised an error (pcall caught) |
| `firstGT`, `lastGT` | first and last delivery game time |
| `maxPerSec` | highest count inside any one second |
| `cpuTotalMs`, `cpuMaxMs` | handler time, only if `debugprofilestop` exists (profiling plan, PX-7) |

Plus per context kind: opened, closed, closedBy counts. `/gi collect stats` prints one line per event and a total line. A summary (counts only, no payloads) is written to `GoldIntelCharDB.collect.lastStats` at logout, about 1.5 KB. Reset with `/gi collect reset`.

## 6. Collect on/off behavior

Commands (Core/Slash.lua, new `collect` command):

| Command | Behavior |
|---|---|
| `/gi collect status` | collect on or off, per group registered or not, quarantined events, whether GoldIntelDiag is loaded |
| `/gi collect on` | registers G1..G5 (and G6 if approved) in that order, writing the journal before each event (section 9); prints `collect: on, N registered, M failed` |
| `/gi collect on G3` | registers one group only (staged mode, used if the combined test fails) |
| `/gi collect off` | unregisters every collector event (`UnregisterEvent`), stops the adapters, closes all contexts, keeps counters |
| `/gi collect stats` | counters (section 5) |
| `/gi collect reset` | zeroes counters |
| `/gi collect allow EVENT` | removes one event from quarantine |

Rules: the state is NOT persisted in 3b-1. After every login or `/reload` collect is off. Persisting it, and starting automatically, is a 3b-2 decision. `collect on` while GoldIntelDiag is loaded prints a warning and still works, because D-072 only requires the lab to be off during validation sessions. `collect on` twice is a no-op; `off` then `on` re-registers cleanly with no duplicate deliveries (tested).

## 7. Live validation procedure (about 15 minutes)

Restart needed: YES. 3b-1 adds files to the TOC (Collect/, seven adapters), so a client restart is required, not just `/reload`.

Preparation (game closed):
1. Replace the folder `GoldIntel` in Interface\AddOns with the one from the new package.
2. Move the folder `GoldIntelDiag` out of Interface\AddOns (for example to the Desktop). D-072 requires the lab off during validation.
3. Start the game and log in with a character that has a few items to sell and a mailbox nearby.

In game, write a tally on paper as you go:
4. Type: `/gi collect status` (expect: collect off, 0 registered, no quarantine).
5. Type: `/gi collect on` (expect: no popup, `collect: on, 13 registered, 0 failed`, or 14 if G6 is approved). If a popup appears, go to section 9 now.
6. Kill and loot 3 mobs, one of them with coin. Tally: 3 loots.
7. Open a vendor, sell 2 items, close the window by walking away once and by pressing Escape once. Tally: 2 opens, 2 closes, 2 sales.
8. Open the mailbox, take one mail with money or an item, close it. Tally: 1 open, 1 take.
9. If a quest is ready, turn it in. If a helper is available, do one trade and one cancelled trade.
10. Cast any gathering or fishing spell once (or mine/herb a node). Tally the casts.
11. If G6 approved: post one item at the auction house, then close the window.
12. Type: `/gi collect stats` and copy the lines (or take a screenshot).
13. Type: `/gi collect off`, then `/gi collect status` (expect: 0 registered), then do one more vendor open (nothing should count), then `/gi collect on` again and open one vendor window (counts go up by exactly one open and one close).
14. Type: `/reload`, then send me `GoldIntel.lua` from SavedVariables (account file and the character file).

Pass criteria: no popup; every registered count matches the tally (received equals your actions, with the known doubles: two MERCHANT_CLOSED per Escape/walk-away route, two TRADE_CLOSED per trade); `dropped` for casts is large and `kept` equals your own casts; context opens equal closes; no `errors`; off/on cycle clean.

## 8. Tests

New files and approximate counts (my estimates; the real number is reported at hand-off):

| Test file | Content | Tests |
|---|---|---|
| `test_events_collect.lua` | allow-list is exactly the 25 (or 26) names; unknown and restricted names refused; Bind/Unbind; counters; no duplicate delivery after off/on | 30 |
| `test_platform_loot.lua` | slot parsing, secret values, coin vs item, source type | 16 |
| `test_platform_merchant.lua` | open/close, duplicate close | 10 |
| `test_platform_quest.lua` | payload, secret money | 8 |
| `test_platform_mail.lua` | polling open/close, header snapshot incl. COD amount, invoice, missing mail | 24 |
| `test_platform_trade.lua` | open, close x2, cancelled trade | 14 |
| `test_platform_items_bags.lua` | pending/secret item info, bag snapshot aggregation | 18 |
| `test_unit_cast.lua` | unit filter first line, RegisterUnitEvent present/absent, verified spell ids | 14 |
| `test_context.lua` | open/close/linger for each kind, idempotent closes, loot timeout path, reload drops state | 30 |
| `test_collect_command.lua` | status/on/off/stats/reset/allow, group staging, not persisted | 20 |
| `test_collect_journal.lua` | journal before each event, quarantine after interrupted registration, allow | 16 |
| `test_replay_adapters.lua` | E-22, E-28, E-31, E-33, E-34, E-39, E-40 replayed through the adapters and Context: normalized events and context windows match the recorded timing (D-073) | 24 |
| existing files | `test_platform_boundary` (RegisterEvent only in Events.lua, no WoW globals in Collect/), `test_commands`, version strings | 6 |
| **Total new** | | **about 230** |

Expected count: 567 now, about 790 after 3b-1 (range 770 to 810). Every existing test must still pass unchanged except the allow-list assertions, which move from 12 to the exact list.

## 9. Rollback plan: all collector events registered together trigger a popup

Why this is a real risk (R-31): the lab verified each event alone, with one new registration per game session. Registering 13 together has never been done, and a blocked registration shows an ADDON_ACTION_FORBIDDEN popup that no code can suppress.

Built-in protections (in 3b-1 itself):
1. **Off by default, never persisted.** A popup can therefore never repeat at login.
2. **Journal before registering.** Before each `RegisterEvent` the code writes `GoldIntelCharDB.collect.pending = EVENT`, and clears it after `IsEventRegistered` confirms. The journal reaches disk at `/reload` or logout.
3. **Quarantine.** At the next load, if `pending` is still set, that event goes on the quarantine list and is skipped by every later `collect on`, so the culprit never fires again. `/gi collect allow EVENT` lifts it.
4. **Order by suspicion.** The riskiest event (UNIT_SPELLCAST_SUCCEEDED, G5) is registered last, so a popup there still leaves G1..G4 working. Groups can be enabled alone (`/gi collect on G3`).
5. **Failure is reported, not hidden.** `collect on` prints the failed count; `/gi collect status` lists quarantined events.

If a popup appears (steps for you):
1. Do not click Disable. Copy the popup text exactly (or screenshot it), then dismiss it with the Ignore/Close button.
2. Type `/reload`. Collect is off again and the journal has flagged the event.
3. Type `/gi collect status` and send me the text and the popup text.
4. Optional: type `/gi collect on G1`, then `/gi collect on G2`, and so on, one at a time, until the popup repeats. That tells us which group.
5. Send me `GoldIntel.lua` after a `/reload`.

My response to a popup: remove that event from the allow-list, replace it with a verified non-event alternative (for example polling), amend AC-1 and add a Compatibility_Notes entry, then rebuild. The ledger design is unaffected because every context has a polling fallback except loot and trade, where we would use the money event window alone and mark those entries lower confidence.

Hard rollback (any problem): close the game, delete the `GoldIntel` folder, copy back the 3b-0 package folder (`GoldIntel_Phase2_AddOns.zip` as delivered with 3b-0; I keep a copy as `GoldIntel_3b0_AddOns.zip`), start the game. Because 3b-1 adds no schema change, the old version reads the saved variables unchanged (the extra `collect` keys are ignored).

## 10. Exit criteria for 3b-1

1. All tests pass (about 790).
2. Live validation passes (section 7) with GoldIntelDiag off.
3. Counters equal the tally; no popup; off/on clean; zero handler errors.
4. Loot context close path (clear vs timeout) reported.
5. CPU profile line for UNIT_SPELLCAST_SUCCEEDED and BAG_UPDATE_DELAYED reported (starts PX-7).
6. Docs updated: Contracts 1.7 additions, Architecture section 19 note, Compatibility_Notes live results (E-41), Changelog, TODO, Session_Handoff.
7. You review 3b-1 before 3b-2 starts.

## 11. Decisions requested

| ID | Question | My recommendation |
|---|---|---|
| A-1 | Add `AUCTION_HOUSE_AUCTION_CREATED` as a 14th event in group G6 | Approve |
| A-2 | Additive contract entries P_BAGS_SETTLED, P_ITEM_INFO, P_LOOT_OPEN, P_LOOT_CLOSE (Contracts 1.7) | Approve |
| A-3 | Collect state is not persisted in 3b-1 (always off at login) | Approve |
| A-4 | Loot context close rule (1.0 s after last clear, 10 s fallback) as a design assumption verified live | Approve |
| A-5 | Approve starting 3b-1 | After your review |

## 12. Not in 3b-1

Expectations, Reconciler, cash ledger, lots, bag diff, valuation, location/activity stamps (3b-2 and 3b-3), schema 2, auction expiry and outbid mail, any UI, any GPH value.
