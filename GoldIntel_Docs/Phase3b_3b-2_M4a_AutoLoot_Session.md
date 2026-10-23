# 3b-2 focused auto-loot evidence session (addon 0.3.4-phase3b2m4b)

Package: `GoldIntel_3b2_M4b_AddOns.zip`. **Needs a CLIENT RESTART.** It contains the approved `lastMoney` fix and the diagnostic loot trace. Classification is unchanged, so the result will look like the first auto-loot run, now with the facts behind it.

Your correction is built in: corpses are looted one at a time (Classic rules), and with auto-loot the window shows only briefly unless bags are full (then it takes the coin and what fits, and stays open). The old guess that several corpses are looted at once is withdrawn. The trace now also records whether the loot frame is shown at the moment the window opens, because a window that is gone within milliseconds is now a leading suspect.

## Install
1. Close the game. Replace `AddOns/GoldIntel` with the one from the zip (keep `GoldIntelDiag` and `GIProbeLoot` out of AddOns). Start the client.
2. Log in with the auto-loot character (any character works). `/gi version` must show `0.3.4-phase3b2m4b`.
3. Auto Loot ON in the game options. Free bag space.

## Run (about 15-20 minutes, one character, one trace)
Before each part type the note line shown, so I can find the part in the trace.
1. `/gi ledger trace clear`
2. `/gi collect on` (must print `ledger: interval started`), then `/gi ledger mark`
3. `/gi ledger trace note part1 single kills auto-loot`. Kill 6 mobs that drop coin, one at a time, looting each corpse (auto-loot takes it) before attacking the next. Then `/gi ledger check`.
4. `/gi ledger trace note part2 fast kills auto-loot`. Kill and loot 6 more mobs as fast as you can, moving from one corpse to the next with no pauses (this reproduces the quick sequences of the first run). Then `/gi ledger check`.
5. `/gi ledger trace note part3 gathering auto-loot`. Gather 2 herb or ore nodes, and skin 1-2 beasts if you can. Then `/gi ledger check`.
6. Turn Auto Loot OFF in the game options. `/gi ledger trace note part4 manual loot`. Kill 4 mobs that drop coin and loot each one by clicking the corpse and the coin. Then `/gi ledger check`.
7. Optional, only if easy: with Auto Loot ON again and bags nearly full, kill one mob so the window stays open. `/gi ledger trace note part5 full bags`. Then `/gi ledger check`.
8. `/gi ledger status`
9. `/gi ledger trace 200` (the trace keeps the last 400 lines and is saved in the file below, so copying chat is optional).
10. `/gi collect off`, then log out normally to character select (do not close the client).

If the trace would exceed 400 lines (about 45 coin pickups), run `/gi collect off` after part 3, log out, send the files, and repeat parts 4-5 in a second short session.

## Send me
- `GoldIntelCharDB.lua` for that character (the full trace is under `trace`) and `GoldIntelDB.lua`, both after the normal logout.
- The chat text of the `check` and `status` commands, and any error popup.
- How many mobs you killed in each part, and whether any had items only.

Also, if you can, log in once more with any character used in the first run and run `/gi ledger status` to confirm no gap entry appears (gaps must stay 0).

## What I will report
Root cause of the unmatched expectations and the OTHER share, from the trace (window facts, coin amounts, whether the frame was shown, expectation lifetimes, money deltas and the order and timing between them), and a proposed classification change for your review. Nothing is changed before that review.
