# 3b-2 M4 report (live validation, evidence E-46)

Build tested: 0.3.3-phase3b2m4, client 1.60.1 build 70450. Characters (identified by the ledger keys and places): Role 1 = Barrens fighter (`...83E4B2`), Role 2 = Orgrimmar mail partner (`...00B2A2AA`), Role 3 = Elwynn auto-loot character (`...00B2A01C`). Trade could not be done (one account cannot have two characters online).

**Result: NOT ready for a 3b-2 closure recommendation.** The ledger arithmetic is exact everywhere, but (1) AUTO-LOOT classification failed and (2) a bug was found in the saved `lastMoney`. Both are described below with what I propose.

## 1. Ledger check results (difference must be 0 copper)

| Role | Check | Money moved | Entries | Pending | Difference |
|---|---|---|---|---|---|
| 1 | after ~15 mobs (262 s) | +1s 34c | +1s 34c | 0 | **0 (OK)** |
| 1 | after selling 3 items, buying 1 (392 s) | +1s 97c | +1s 97c | 0 | **0 (OK)** |
| 1 | after kill quest and 9s reward (1034 s) | +15s 24c | +15s 24c | 0 | **0 (OK)** |
| 1 | after 2 mails sent incl. COD (1154 s) | +14s 14c | +14s 14c | 0 | **0 (OK)** |
| 2 | after money mail (48 s) | +50c | +50c | 0 | **0 (OK)** |
| 2 | after COD mail (94 s) | +18c | +18c | 0 | **0 (OK)** |
| 3 | not supplied | | | | status line: money deltas +1s 37c = entries +1s 37c, "sum check OK" |

Non-zero differences: **none**. Request: please send the Role 3 `/gi ledger check` lines if you ran them.

## 2. Quality indicators

| Role | Entries | OTHER share by value | by entries | Largest OTHER | Unmatched | Gap count / value |
|---|---|---|---|---|---|---|
| 1 | 28 | **6.5%** (110c of 1680c) | 7.1% | 80c | 0 | 0 / 0 |
| 2 | 2 | 39.0% (32c of 82c) | 50.0% | 32c | 0 | 0 / 0 |
| 3 (auto-loot) | 36 | **75.9%** | 80.6% | 7c | **18** | 0 / 0 |

After `/reload` (Role 1): collect OFF, 0/14 events registered, ledger kept all 28 entries, `intervals` = 1. Reload and a normal collect off/on behaved as designed. No errors, no refused entries, no quarantine.

## 3. Source classification

Role 1 (all as designed): 21 coin loots `loot` high / GRIND / creditable, 3 vendor sales `vendor` med, 1 `purchase` med, 1 quest `quest` high (900c exactly), 2 OTHER. The two OTHER entries are -80c (50c attached to the mail + 30c postage) and -30c (postage of the COD mail). Per D-077 Q-1 (Option A) mail postage and money attached stay OTHER until 3b-4, so these are **expected**, not errors. They are also why OTHER by value is 6.5%: all of it is postage and attached money.

Role 2: the 50c mail is `mailMoney` high / MAIL / settle, correct. The -32c is paying the COD (outbound COD stays OTHER until 3b-4, Q-1), expected. The 39% share is 32c of 82c, a tiny sample driven only by that deferred item.

Role 3 (auto-loot): **unexpected.** 29 of 36 entries are `other` (small +1c..+7c amounts, all while killing mobs at Fargodeep Mine), only 7 are `loot`. 18 loot expectations expired unmatched. The first 5 coin pickups (t+190 s to +281 s, one every 18-28 s) were classified `loot` correctly, then from the 6th on nearly everything became OTHER. Pickups arrive in bursts (two at the same second, then 2-3 s apart), which points to several corpses being looted by one action.

Not seen live yet: trade, `codIn` (the COD payment arriving at Role 1), AH sale mail, quest rewards other than coin, loot windows with items only.

## 4. AUTO-LOOT results (R-3b2-2)

- Money arithmetic: exact (sum check OK). The ledger stayed honest, it just could not explain the money.
- Classification: **failed** (75.9% OTHER by value, 18 unmatched). So the assumption "auto-loot behaves like a corpse window for coin" is false at least for burst looting.
- The saved data cannot tell me why: the ledger stores entries, not the expectations, and I do not know the coin amounts the loot slots reported. Leading hypotheses: (a) auto-loot / area loot takes several corpses at once, so each `LOOT_OPENED` reports different or already-taken coin slots; (b) the coin slots are already empty when `LOOT_OPENED` is handled so no expectation is created; (c) money arrives before the window is read by more than the 1.0 s pending wait. I will not guess a fix.
- The loot-window statistics do not clarify it: the three CharDB files give 39 windows / 37 closed by frame / 0 timeouts for one character, but the file-to-character mapping is ambiguous (one file has zeroed counters), so I do not use them as auto-loot evidence.

## 5. Defect found in the saved data: `lastMoney = 0`

All three `GoldIntelCharDB.lua` files contain `lastMoney = 0`, while the balances were 1g 74s, about 1s and 62s+. The client reports a balance of 0 while logging out, and the 0.3.3 logout code stored that live read. Consequence: the **next login of each character would record a false gap entry equal to its whole balance**, polluting OTHER share, gap count and largest OTHER. (Role 1 showed gaps = 0 after `/reload` because a reload reads the balance correctly; only the final logout reads 0.)

Fix (done in source, unit-tested, not yet packaged): at logout store the balance the money module has accounted for instead of the live read; add a marker `lmv = 2`; a `lastMoney` without the marker (what 0.3.3 wrote) is treated as an untrusted baseline once, with no gap entry. Tests: 988 passed, 0 failed, including two new scenarios and three new mutants. This also means your current saved files are safe to load with the fixed build (the old value is simply re-baselined).

## 6. Proposal and decisions needed

1. Approve the `lastMoney` fix as part of 3b-2 (it is a defect in M3 code).
2. Approve a **diagnostic-only loot trace** to get the missing facts: a bounded ring (about 200 lines) recording per loot window the time, number of slots, each coin amount read and source type; each money delta; each expectation created, matched or expired; printed by `/gi ledger trace [n]` and saved with the character. No change to classification rules. One short auto-loot session (about 10 kills, including group kills) would then show exactly which of the hypotheses holds, and I would propose the rule change (for example allowing a loot window to explain several deltas, or classifying while auto-loot is detected) for approval before building it.
3. Alternative if you prefer not to spend another round: accept auto-loot coin as OTHER (honest but 75% of auto-loot value unexplained) and move on. I do not recommend it, because auto-loot is how most players loot.

Please also tell me which file was which character (or confirm the order account, Role 1, Role 2, Role 3), and whether you traded on any character (one file shows trade events).

Both 3b-3 and any new feature stay untouched.
