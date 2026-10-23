# 3b-2 auto-loot: root-cause analysis and proposed classification change (D-078, PROPOSED)

Evidence: E-46 (Role 3, build 0.3.3, no trace) and E-47 (Chilly Slaps, build 0.3.4-phase3b2m4b, full trace, 999 s). Nothing in this document is built. 3b-3 is not started and 3b-2 closure is not requested.

## 1. What the evidence says

**E-47 (solo, with trace):** 16 of 16 coin loots matched their expectation exactly with 0.000 s wait (auto-loot parts 1 and 2: 12; manual part 4: 4). 23 loot windows, all closed by frame, 0 timeouts, frame shown at open every time, windows open 0.5-1.0 s for auto-loot. Vendor sales (5) classified `vendor`. Nothing unexplained. So **the auto-loot window handling is correct**: the old suspicion (brief window, coin already taken, wrong order of events) is not supported. In E-47 the coin arrives about 0.1 s after the first slot clear and 0.5 s after the window opened, exactly as for manual looting.

**E-46 Role 3 (grouped):** the user confirms part of the run was done in a group of 2. In Classic the coin of a kill is split equally between the group, automatically. Consequences:
1. Looting a corpse yourself: the window offers the FULL coin C, you receive a SHARE d < C. The expectation C never equals the delta d, so the exact pass fails: the expectation expires unmatched and the delta becomes OTHER. 
2. Your partner loots a corpse: you receive a share although none of your windows opened, so there is no expectation at all: OTHER.
3. Coin of 1c cannot be split and goes entirely to the looter, which is why the two `+1c loot` entries (#18, #36) matched exactly.
4. The first five pickups (solo, before the group formed) matched exactly.

**Arithmetic check on the E-46 file:** 36 entries = 7 `loot` + 29 `other`; unmatched expectations 18. The 29 OTHER decompose into 18 own-loot shares (the 18 unmatched expectations) and 11 partner-loot shares (no window): 18 + 11 = 29. This is consistent with the group explanation; it is not proof because E-46 had no trace.

**Root cause:** attribution failure, not an arithmetic failure. The Reconciler only knows "exact amount" for loot, and a group share is a different amount. The ledger stayed exact (sum check OK) throughout.

## 2. Proposed classification change (D-078)

**Rule: loot share.** In the Reconciler, after the exact pass and after the source windows (trade, mail, vendor, ...) and before a delta waits for OTHER: a positive delta d that arrives while a held loot expectation of amount C is active (same lifetime as today: window open plus the 1.0 s linger) with 0 < d < C is attributed to that loot window.
- Entry: `src = 'loot'`, `conf = 'med'` (not high: the amount did not match exactly), `comp = 'split'`, copper = d (the real delta, so the invariant sumDeltas = sumEntries + pending is untouched), `ref` and `ctx` as today, `creditable` as today.
- If several loot expectations are active the oldest is used (existing order: priority, then t0, then id). The expectation is consumed (it explains one delta).
- Unchanged: exact matches stay `high`; a delta with no window stays OTHER; d >= C that does not match exactly stays OTHER; vendor/mail/trade windows keep priority over the share rule.
- Visible indicators: Stats gain `splitCount` and `splitValue`; `/gi ledger status` and `/gi diag` show "loot shares (group): n (value)" next to OTHER, unmatched and gaps. `unmatched` then counts only expectations that really did not receive money.

**What stays OTHER (honest):** shares from the partner's kills (case 2 above) have no signal on our side. Expected effect on the E-46 data: OTHER by value falls from 75.9% to roughly the partner-loot share (about 11 of 36 entries, around 30% by value), unmatched from 18 to about 0.

**Not part of this proposal (needs its own evidence first):** tagging OTHER deltas as "while grouped". It needs a group API (IsInGroup / GetNumGroupMembers) that has not been probed on WoW Forever. Until it is, grouped play will show some OTHER; that is a known, documented limit.

## 3. Options for your decision

| Option | Effect | Risk |
|---|---|---|
| A (recommended) | Build the loot share rule; keep partner loot as OTHER; add the split indicators. | A stray small positive delta inside a loot window is called a share (med confidence, flagged `split`, visible in counts). Windows are 0.5-1.0 s long, so rare. |
| B | Do nothing; document that grouped play is OTHER. | Group play (common) stays 30-75% OTHER. |
| C | A plus a group probe and "grouped" tag now. | Needs new API evidence; larger scope. |

## 4. Proposed plan (each step reviewed)

1. **Confirmation run (10 minutes, current build 0.3.4b, no code change):** the same two players in a group; use the same trace script, parts 1 only, one character looting, then the partner looting; `/gi ledger trace note` before each. The trace will show the offered coin C and received share d for each window, the remainder rule for odd coin, and the unattributed partner shares. This proves or disproves section 1 before any code is written.
2. If confirmed and you approve option A: I build the rule with tests (replay of this pattern, exact still wins over share, vendor window precedence, stray delta, d >= C, invariant property tests, mutants), Contract 1.9, and a new package; I state whether a restart is needed (it will be).
3. Validation run on the new build in a group of 2, then the 3b-2 closure recommendation.

Not started and not requested: 3b-3.

## Addendum 1 (user scenario): one looter takes all corpses

User input: in a group, one person can loot all corpses (10 mobs, one at a time); the coin is divided evenly among the group and **the other members get no loot window**. Loot rules (free for all, group loot, need/greed rolls, master loot) concern items only: they do not change how coin is split, and they belong to 3b-3 (lots), not to the cash ledger.

Effect on the proposal:
1. **Looter:** has a window per corpse offering the full coin C and receives a share d. The loot share rule (section 2) covers this case.
2. **Every other member:** receives only a delta, with no window, no slot clear, no expectation. The section 2 rule cannot see it, so all of their group coin stays OTHER. In a group where one player loots, that is most of the members' kill income. So the "partner share" case is not a small remainder; it is the main case for non-looters, and option A alone is not enough for grouped play.
3. A heuristic such as "small positive delta with no window right after combat" is too weak to classify safely (it would also swallow other unexplained income), so I do not propose it.

**A possible exact signal (unverified on WoW Forever):** in Classic the client prints a chat line for a coin split ("Your share of the loot is ...", event CHAT_MSG_MONEY), and a different line when you loot coin yourself. If that event is delivered and readable here, it would give every group member the exact amount of each share, including non-looters, so the share could be an exact `high`-confidence expectation instead of a guess, with or without a window. Unknowns to settle by evidence, not assumption: whether the event is delivered and not restricted or secret in this client, its exact text in the English client, whether it arrives before or after PLAYER_MONEY, and whether a group-size API exists. A built-in locale-safe parse would use the client's own global strings.

**Revised plan (replaces step 1 of section 4):**
1. Evidence build 0.3.5 (diagnostic only, no classification change): the trace additionally records `CHAT_MSG_MONEY` raw text and its time, and the group size and whether the player is in a group at each loot window and money delta. The event is registered through the existing collector (journal and quarantine protect against a popup) and only while the ledger interval is on.
2. Grouped evidence session with two players: (a) you loot 5 corpses; (b) the partner loots 5 corpses while you only stand next to them; (c) one player loots a pull of 3 mobs one after another. `/gi ledger trace note` before each part.
3. From that evidence I propose the final rule (exact from the chat line if it works; otherwise the narrower window share rule plus documented OTHER for non-looters) for your decision before anything is built.
