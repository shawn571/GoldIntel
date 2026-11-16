# 3b-2 Milestone M1 report: Expectations and Reconciler (pure modules)

Status: M1 BUILT, for the user's review. M2 (Sources, Stamps, replay corpus) is NOT started. Nothing is wired to the game: both modules are loaded but nothing calls them, so there is no change in-game. No `/reload` or restart is needed.

## What exists
- `Collect/Expectations.lua`: store of exact and window expectations. Validates specs (ttl >= 1.0, integer copper, comps must sum to sign x copper), priority per D-065 (trade, mail, vendor, quest, loot, AH), inclusive expiry at t0 + ttl, windows linger ttl after close, `Extend`, `Consume`, `Expire` (counts `unmatched` for exact only), `Clear`, `Subscribe`.
- `Collect/Reconciler.lua`: `Begin / Money / Tick / End / Stats / Check`. Algorithm exactly as in package section 6.2: gap entry; exact pass (combinations of up to 3 of the 8 highest-priority same-sign exact expectations that sum to the delta exactly; components become separate entries, high); window pass (highest priority same-sign window, med, low if another window of a different source competes); else pending, retried on every add/close and Tick, OTHER (low) at exactly 1.0 s; `End` turns pending into OTHER at once and clears expectations; deltas outside an interval are counted `ignored`.
- Neither module knows about WoW, loot, mail or storage. Time is always an argument. Entry ids, stamps and persistence come in M2/M3 (`decorate` and `sink` hooks).
- `Stats()` already reports what you asked for: `otherShareValue` (headline), `otherShareEntries`, `largestOther`, `gapCount`, `gapValue`, `unmatched`, plus `pending`, `ignored`, `sumDeltas`, `sumEntries`, per-source totals. `Check()` verifies sumDeltas = sumEntries + pending.

## Verification
- Full suite: **818 passed, 0 failed** (790 before, +28 including the boundary check on the new files).
- 26 tests in `test_reconciler.lua`: 5 store tests, 1 scenario suite (16 scenarios: exact, sign, once, AH split 51/-2/+100, bad comps, priority, combos, cross-sign refusal, window med/low, window sign, linger boundary, late exact, wait boundary 0.99/1.00, gap, expiry boundary, no partial matching, End, stats), 2 property tests (200 random streams: entries sum to deltas and nothing pending after End, no zero entries; 100 streams: exact expectations used at most once), 18 mutation checks (each deliberately breaks the source, e.g. sign ignored, expectation not consumed, priority ignored, remainder dropped, wait off by one, gap ignored, expiry exclusive, comps unchecked, window over-claim, no retry on add; all caught). One mutation initially survived (cross-sign combination) and led to a new scenario.
- Design point worth your attention: matching is all-or-nothing per delta (an exact combination equals the delta, or one window takes all of it, or it goes OTHER), so the sum invariant holds by construction and is also checked at runtime by `Check()`.

## Observations for M2 (not changes)
- Vendor windows will be registered as two window expectations (sign +, src `vendor`; sign -, src `purchase`) so a single context never competes with itself.
- An exact expectation that arrives AFTER a window already claimed the same delta stays unused (expires as `unmatched`). The measured signals all precede their money, so this should not occur; the counter will show it.

## Not done / next
M2: Sources.lua, Stamps.lua, `Unit.LastCast`, replay corpus through the Reconciler, Contract 1.8 text, AC-9..AC-13 text in Architecture. Awaiting your M1 approval.
