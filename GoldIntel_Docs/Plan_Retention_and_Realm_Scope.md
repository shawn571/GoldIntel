# Plan: retention (7-day raw window plus daily summaries) and realm scope

DATE: 2026-11-20  |  SESSION: S-078  |  STATUS: PLAN ONLY. Nothing is built before Shawn approves (D-115, D-120).

Evidence: the user's account file of 2026-11-20 and four character files (attached in S-078, read only). Sizes are
bytes in the saved file. "Measured" means counted in those files; "estimated" means a projection.

## Part A: realm scope (answer from the code, 2026-11-20)

### A.1 What is keyed how today

| Saved data | Key | Mixes realms? |
|---|---|---|
| `ledger` (cash entries, gaps, folded totals) | character GUID (`Platform.Player().key`) | No |
| `lots` (open, closed, conversions) | character GUID | No |
| `agg` (totals per place x activity x level, segments) | character GUID | No |
| `heat` (32 x 32 bins per map) | character GUID | No |
| Character files (`GoldIntelCharDB`: trace, perf, lastMoney) | WoW keeps one per character | No |
| `prices.manual` (the `/gi price` override) | item id only, account-wide | **Yes**: a manual price set on one realm values new lots on every realm. Today it holds 0 entries |
| `prices.snapshots`, `auctions`, `sessions`, `segments`, `chars` | empty placeholders | Not used yet |

- The GUID contains the server number (`Player-6796-...`), so everything stored per character is per realm too.
- Item values come from the vendor price, which is the same on every realm, or from the manual price above.
- No view adds characters together yet. Account Best (D-089, D-061), the rankings (Phase 5) and the heat map (Phase 7)
  will be the first. Market prices (Phase 6, D-111) will be the first realm-dependent data.
- Fallback: before the GUID is known, `Platform.Player()` uses `name:<Name>:<Faction>`, which has no realm part. Two
  characters with the same name on two realms could then share a key. The ledger starts after login, when the GUID
  is known, so this has not happened: every character key in `ledger`, `lots`, `agg` and `heat` is a GUID.

### A.2 Proposal

1. `Platform.Player()` gains `server`: the number from the GUID (`6796`). It is never derived from a realm name: the
   game returns "" since build 71037, and GoldIntel must not depend on "!RealmFix".
2. Realm-dependent data is keyed by server number:
   - manual prices: `prices.manual[server][itemID]`;
   - later, market-price snapshots and auction history (Phase 6): `prices.snapshots[server]`, `auctions[server]`.
3. Account-wide views (Account Best, rankings, heat across characters) group by server by default, because gold per
   hour on the auction house differs between realms. An "all realms" option is allowed only for vendor-based value,
   which is the same everywhere.
4. Data is never written under the fallback `name:` key: the stores wait until the GUID is known.
5. Migration: today's `prices.manual` is empty, so the new shape costs nothing. Should an entry exist when this is
   built, it goes to server 6796 (the user's main realm) and the report says so.
6. Tests:
   - two characters on different servers with different manual prices for the same item;
   - an account-wide view that never mixes servers;
   - an empty realm name changes nothing;
   - a deliberate-bug check: dropping the server level lets prices mix.

Size: small. Best done before Phase 6, while no price data exists.

## Part B: retention

### B.1 Measured, 2026-11-20 (account file 3.9 MB; it was 2.0 MB on 2026-11-14)

| Section | Size | What drives it |
|---|---|---|
| `ledger` | 1,782 KB | Raw cash entries, about 216 bytes each. Paladin: 4,762 entries over 15 play days, 317 per active day, 1,027 KB. Nothing folded yet: below the 6,000 cap |
| `lots` | 1,170 KB | Paladin 746 KB: 1,276 open lots for only 263 distinct items, plus the closed and conversion rings (300 each) |
| `agg` | 718 KB | 21 characters. Segment rings about 330 KB: 200 segments per character, and on the Paladin 169 of 200 are under 60 s, so 200 cover only 10.5 hours. Places and cells about 240 KB (Paladin 256 places, 664 cells) |
| `heat` | 228 KB | Bins per map per character (Paladin 82 KB) |
| Character file (Paladin) | 578 KB | Trace 330 KB (3,000 lines + 400 kept), perf 247 KB (500 samples) |

Growth from 14 to 20 November, about 1.9 MB in six days:

| Section | Change |
|---|---|
| `ledger` | +866 KB (the Paladin +331 KB; the rest other characters, 22 now) |
| `agg` | +624 KB |
| `lots` | +218 KB |
| `heat` | +194 KB |

The aggregates of 0.6.x are a larger share than expected: the 0.6.0 review estimated +7 KB per hour, but 21 characters
with segment rings of 200 cost more.

### B.2 Current thresholds, and why nothing is folded

- **Cash:** 6,000 raw entries per character, then the oldest 500 fold into totals (D-098 stopgap). The Paladin has
  4,762, so folding will start in about four play days.
- **Lots:** 4,000 open lots, then equal-valued lots of one item merge; closed and conversion rings of 300.
- **Aggregates:** segments ring of 200 per character; places, cells and heat have no cap.
- **Character files:** trace 3,000 + 400; perf 500 samples.

### B.3 Proposal

1. **Cash: 7-day raw window plus daily summaries.**
   - Entries older than 7 days (setting 3..30) fold into one row per day x source x activity x place x level bracket:
     `{ n, cin, cout }`.
   - Measured on the Paladin: 8.8 entries per row, and a row is about 70 bytes instead of 8.8 x 216, so about 30
     times smaller.
   - The 6,000 cap stays as a ceiling.
   - `Cash.Cumulative()` counts the summaries exactly as it counts the folded totals today, so `/gi ledger check` and
     `/gi agg check` stay at 0. Tests prove both, plus a deliberate-bug check for a double-counted day.
2. **Lots: a rule for stale open lots** (separate from the window, as the user asked).
   - Open lots are holdings and cannot be folded by age.
   - The bag check (`/gi lots check` logic) already compares lots with the items in the bags. A lot whose item has
     been missing from the bags (and the bank, when it was last seen) for 7 days is closed as "left without a signal".
     It is counted and shown, and value converted stays 0.
   - The closed and conversion rings fold into the same daily summaries.
   - Expected on the Paladin: most of the 1,276 open lots for 263 items should close. To be measured with a read-only
     count first.
3. **Aggregates.**
   - Places, cells and heat are the product and are kept permanently.
   - Segments: nothing reads them yet. Keep at most 50 per character, merge a segment shorter than 60 s into its
     neighbour, and drop segments of characters not played for 30 days. This saves most of the 330 KB. The empty schema placeholder keys in `agg` (`sub`, `bracket`, `act`, `zone`) and `lots` (`open`, `closedSummary`) are removed in the same migration.
4. **Test-mode switch** (`debug.testMode`, ON until Phase 4 closes, then OFF).
   - OFF: trace 300 lines + 100 kept, perf 50 samples, so a character file is about 40 KB instead of 578 KB.
   - ON: today's limits, for live checks.

### B.4 Projection (estimated, at the current play rate)

| | Day 30 | Day 90 |
|---|---|---|
| Account file, current rules | 5 to 6 MB (cash cap reached; lots near the 4,000 cap) | 7 to 9 MB (more characters, uncapped aggregates) |
| Account file, proposal | 1.5 to 2 MB (Paladin cash about 0.45 MB raw + 0.1 MB summaries; lots depend on the stale rule) | 2 to 2.5 MB |
| Paladin character file | 578 KB, test mode ON | about 40 KB, test mode OFF |

/reload and logout time: not measurable from these files. Today a /reload costs a GoldIntel frame of 100 to 178 ms at
1.9 to 3.9 MB. Load and save time grow roughly with file size [inferred]. The reload frame would be measured before and
after the change.

### B.5 What needs raw records for longer

- **3b-4** (flight fares, postage, AH deposits): re-sorting past OTHER entries works only inside the raw window, so
  3b-4 applies from its release onward plus the last 7 days. If older history should be re-sorted, 3b-4 must ship
  before the window is introduced, or the window starts at 30 days until then.
- **Cross-checks** with Accountant Classic: daily summaries are enough.
- **Back-fill** of aggregates: already done for every existing character. A new character back-fills from what is
  there.
- **The live checks:** `/gi ledger check` uses the current interval only.

### B.6 Decisions for Shawn

1. Raw window length: 7 days (recommended), or 30 days until 3b-4 ships.
2. Stale-lot rule: 7 days missing from the bags and bank.
3. Segments: 50 per character, merge under 60 s, drop after 30 idle days.
4. Test mode: ON until Phase 4 closes.
5. Order: realm scope (small) first, then retention, both after PR #9 merges.
