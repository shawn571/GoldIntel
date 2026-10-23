# Phase 3a: Signal verification protocol

DOC VERSION: 1.0.0  |  DATE: 2026-10-17  |  AUTHOR: Claude (S-012)  |  STATUS: PROTOCOL. Phase 3a is APPROVED by the user (D-051); Phase 3b (collectors) is NOT approved. This document defines what is built and run; the diagnostics code itself is built in the next step.

## 1. Authorization and limits

User, 2026-10-17: "I approve Phase 3a only: Diagnostics, Experiments, Signal verification. I do NOT approve Phase 3b implementation. Collector implementation remains blocked pending successful verification and review."

Therefore:
- Allowed: extending the diagnostics addon (`GoldIntelDiag`) with read-only experiments; running them in the real client; recording results in `Compatibility_Notes.md` (E-17 onward); updating the signal matrix.
- NOT allowed: any collector, Reconciler, Lots, activity/session engine, heat bins, pricing provider, UI in the GoldIntel addon itself; any change to what GoldIntel does with game events. The GoldIntel addon is not modified by Phase 3a (except bug fixes the user approves).
- The experiments observe and record. They never write gold data, never alter `GoldIntelDB` (they use `GoldIntelDiagDB`), and each runs only when the user asks.

## 2. Safety rules (lessons from the ADDON_ACTION_FORBIDDEN popup, D-025, D-029)

1. One new event registration per game session. After a registration, `/reload` before the next one.
2. Registration only through the existing opt-in path (`/gidiag reg NAME`) with its ADDON_ACTION_FORBIDDEN watcher; the user reports any popup text verbatim.
3. Record `IsEventRegistered` immediately after registering (this also produces the first observation of the blocked case, PX-3).
4. The lab never registers `COMBAT_LOG_EVENT_UNFILTERED`.
5. Payload capture is defensive: every argument is checked with `issecretvalue` BEFORE being read as a value; secret values are recorded as `secret` and nothing else.
6. Bounded storage: at most 40 payload samples per event, strings cut at 120 characters, `GoldIntelDiagDB.lab` capped at about 100 KB; oldest samples dropped first. This is diagnostic evidence, not retained history.
7. Read-only API probes call only getters, with fixed harmless arguments.

## 3. Output (so the user does not copy and paste)

All results go to `GoldIntelDiagDB.lab` in the SavedVariables file `GoldIntelDiag.lua`, plus a short chat summary line per experiment. Delivery to me is the same as before: log out or `/reload`, send `GoldIntelDiag.lua` (and `GoldIntel.lua` only if asked).

Result record shape (one per experiment run):
```
lab[id] = {
  id, title, ranAt, build, status = 'pass' | 'fail' | 'inconclusive' | 'blocked',
  events = { [name] = { registered, isEventRegisteredAnswer, delivered, popup = '...' } },
  samples = { { t, gt, args = { {type=..., secret=bool, value=...}, ... } }, ... },
  orderings = { 'PLAYER_MONEY +0.03s after LOOT_OPENED', ... },
  notes = { ... },
}
```
Status rules: **pass** = delivered, payload fields usable (not secret), shape documented; **fail** = registration blocked, not delivered when expected, or fields secret/unusable; **inconclusive** = the user did not perform the action; **blocked** = popup or ADDON_ACTION_FORBIDDEN.

## 4. Diagnostics design (to be built next, GoldIntelDiag only)

New commands (all prefixed `/gidiag lab`):
- `lab list` shows the experiment catalog with status of each.
- `lab reg NAME` registers one event (rule 1) and starts capturing.
- `lab api NAME` runs a read-only API probe (section 6) and records the result.
- `lab watch` lists what is currently being captured.
- `lab note TEXT` adds a free-text note to the current experiment (for things only the user sees).
- `lab done ID pass|fail|inconclusive` marks an experiment finished (the lab can suggest a status from the data; the user's word wins).
- `lab clear` empties `lab`.
- `lab report` prints a short summary and writes it to `lab.report` for the saved file.

Testing: the lab is tested on the fake client like the rest (fake events with secret payloads, blocked registration, popup watcher), plus lint rules C-1 to C-6. It follows the delivery policy (zip, TOC verified).

## 5. Event experiments

Each row: the experiment, what the user does, what the lab records, pass criterion, and what failure means. "Order" means the relative time to `PLAYER_MONEY` (proven).

### Stage A: low risk, highest value for Phase 3b

| ID | Event(s) | User action | Record | Pass | If it fails |
|---|---|---|---|---|---|
| L1 | `LOOT_OPENED` | Kill a mob that drops coins, loot it | payload args; delivery; ORDER versus `PLAYER_MONEY` | delivered, args non-secret, order known | collector uses bag diff + money delta |
| L2 | `LOOT_SLOT_CLEARED` | Take items/coins from the window one at a time | slot index payload; per-slot delivery; order | delivered per slot | use window-close + bag diff |
| L3 | (same session as L1/L2) `GetLootSlotInfo` and a source-GUID getter (name to be probed: `GetLootSourceInfo`) | during the open loot window | slot type, icon/name/quantity/quality fields; source GUID type (`Creature` vs `GameObject`), secret flags | fields readable, GUID classified | GRIND rule falls back to XP and combat state |
| M1 | `MERCHANT_SHOW`, `MERCHANT_CLOSED` | Open a vendor, sell one item, buy one, close | delivery; order versus `PLAYER_MONEY` for sale and purchase; buyback | delivered, context window known | context from money sign only (weaker) |
| Q1 | `QUEST_TURNED_IN` | Turn in a quest with a copper reward and an item | args (quest id, xp, money?); order versus `PLAYER_MONEY` | args usable, money arg present | context from quest frame open |

### Stage B: medium

| ID | Event(s) | User action | Pass | If it fails |
|---|---|---|---|---|
| X1 | `MAIL_SHOW`, `MAIL_CLOSED`, `MAIL_INBOX_UPDATE` | Open mailbox, take money, take an item | delivered; money-take order vs `PLAYER_MONEY` | mail context from `TakeInboxMoney` hook or money delta |
| R1 | `TRADE_SHOW`, `TRADE_CLOSED`, `TRADE_MONEY_CHANGED`, `TRADE_ACCEPT_UPDATE` | Trade a small amount of gold with a friend or alt | delivered; gold fields usable | trade context from money delta |

### Stage C: highest suspicion of the old popup

| ID | Event | User action | Pass | If it fails |
|---|---|---|---|---|
| C1 | `UNIT_SPELLCAST_SUCCEEDED` (try unit-filtered registration if the client offers it) | Mine/herb, fish, skin, cast any spell | delivered; unit token and spell id usable | GATHER/FISH from loot source and manual tag |
| C2 | `CHAT_MSG_MONEY` (only if L1 fails) | Loot coins | delivered | not needed if L1 passes |

Never: `COMBAT_LOG_EVENT_UNFILTERED` (D-030).

## 6. API and data experiments (read-only, no registration)

| ID | Probe | Records | Pass | If it fails |
|---|---|---|---|---|
| I1 | Item data: `C_Item.GetItemInfo`, `GetItemInfo`, `C_Item.GetItemInfoInstant` on fixed item ids (a grey item, a common item, a soulbound item, an uncached id) | presence; return field positions; sell price; bind type; async behaviour for an uncached id and the event that completes it | sell price and bind type obtainable; uncached case understood | vendor floor unavailable: valuation tier 1 redesigned |
| I2 | Bags: `C_Container` getters for item count/stack and link per slot | readable fields; speed for a full bag set | bag snapshot cheap and non-secret | no bag-diff fallback |
| A1 | `UnitIsAFK("player")` and a flags-changed event name if any | presence; value after `/afk` on and off | readable and changes | AFK uses movement and signals of life only |
| S1 | `C_Map.GetPlayerMapPosition` and `GetBestMapForUnit` in the open world and inside an instance | availability; secret flags; update cadence | open world usable; instance behaviour documented | heat sampling disabled in instances |
| T1a | `UnitOnTaxi("player")` during a flight path | boolean change at takeoff and landing | accurate | use control-lost/gained events |
| T1b | `PLAYER_CONTROL_LOST` / `PLAYER_CONTROL_GAINED`, `TAXIMAP_OPENED/CLOSED` (stage B registration rule) | delivery and timing around a taxi ride | timing matches the ride | jump rule + dry window only |
| T2 | `GetUnitSpeed("player")` while walking, running, mounted, on a taxi | yards per second per mode | distinguishes modes | derive speed from position deltas and `C_Map.GetMapWorldSize` |
| T3 | `IsMounted`, `IsFlying` | values in each mode | informational | not used |
| T4 | Position jump on hearth, teleport, loading screen, boat/zeppelin | position deltas around `PLAYER_LEAVING_WORLD`/`ENTERING_WORLD`; behaviour on transports | jump detectable | treat any loading screen as a break |
| H1 | Map names for coordinates: `C_Map.GetMapInfoAtPosition(mapID, x, y)` (present), `GetAreaInfo` | name returned for known coordinates such as the lake in Stranglethorn Vale | gives a readable place name | name hotspots by nearest known subzone only |
| H2 | Map overlay host: can an addon frame be parented to `WorldMapFrame`'s canvas, mouse-transparent, below pins; does it coexist with other map addons | frame strata/level, click-through, ordering | works with Gatherer and Questie loaded | standalone window fallback (Architecture 11) |

H2 is a visual check done by the user once the lab can draw a single test square; it keeps the overlay toggle requirement honest long before Phase 7.

## 7. Session plan for the user (one short session each)

Because each event registration needs its own session (safety rule 1), group by what you can do together:

1. **Session 1 (APIs only, no registration):** I1, I2, A1, S1 (open world), T2, T3, H1. Plus idle `lab api` runs while walking, riding, `/afk`.
2. **Session 2:** register `LOOT_OPENED` (L1); play normally, loot a few mobs; run `lab api` for L3 while a loot window is open; `/reload`.
3. **Session 3:** `LOOT_SLOT_CLEARED` (L2).
4. **Session 4:** `MERCHANT_SHOW` (M1), then `MERCHANT_CLOSED` in a later session if needed.
5. **Session 5:** `QUEST_TURNED_IN` (Q1).
6. Then Stage B, then Stage C, each event in its own session.
7. Taxi experiments (T1a, T1b, T4) can ride along in any session that already has a flight path trip.

Time cost for the user is small per session; results arrive in `GoldIntelDiag.lua`.

## 8. Review gate (before Phase 3b can even be proposed)

Phase 3a is complete when:
1. Every row in the Phase3_Planning_Package signal matrix (section 8.2) has a status from this protocol: pass, fail with fallback, or explicitly dropped.
2. Results are recorded in Compatibility_Notes (E-17...) with raw evidence files in `evidence/`.
3. The signal matrix and planning package are updated to reflect results, and any decision D-043 to D-054 that the evidence contradicts is reopened.
4. The user reviews the updated package (the user's wording: "pending successful verification and review") and then decides whether to authorize Phase 3b.

## 9. What Phase 3a does NOT decide

Collector designs, the final activity rules (section 6 of the planning package), the final travel model (`Travel_Model_Options.md`), and the overlay implementation. It only tells us which signals exist and how they behave.

## 10. Proposed decision text

**D-051 Phase 3a authorized (Approved by the user 2026-10-17).** Scope and limits as in section 1. Phase 3b stays blocked until section 8 is satisfied and the user explicitly authorizes it.
