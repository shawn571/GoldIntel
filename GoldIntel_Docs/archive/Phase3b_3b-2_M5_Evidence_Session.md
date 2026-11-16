# 0.3.5 evidence session: does the coin chat line give an exact signal?

Install: replace the GoldIntel folder in `...\_classic_beta_\Interface\AddOns` with the one from GoldIntel_3b2_M5_AddOns.zip.
Keep GoldIntelDiag and GIProbeLoot out of AddOns. **A full client restart is required** (new file, new event).
Use Chilly Slaps (or any character). Auto-loot on. Type each command exactly as shown.

## Part A: solo (no group)
1. `/gi ledger trace clear`
2. `/gi collect on`
3. `/gi ledger mark`
3b. `/gi ledger trace note A solo start`
4. Kill and loot 5 mobs that drop coin.
5. `/gi ledger check`
6. `/gi ledger trace 200` (copy the chat output)

## Part B: grouped (with a partner, both nearby)
6b. `/gi ledger mark`
7. `/gi ledger trace note B1 I loot 5 corpses`
8. Kill 5 mobs together; YOU loot every corpse. Partner only stands nearby.
9. `/gi ledger trace note B2 partner loots`
10. Kill 5 more; the PARTNER loots every corpse. You do not loot (your addon must still be on).
11. `/gi ledger trace note B3 pull of 3`
12. Kill a pull of 3 mobs; one player loots all three.
13. `/gi ledger check`
14. `/gi ledger trace 400` (copy the chat output)
15. `/gi collect off`
16. `/reload`

## Return
- The chat copy from steps 6 and 14.
- The character file `GoldIntel.lua` from `...\WTF\Account\50437587#1\70\Chilly-Slaps\SavedVariables` (written on /reload or logout).
- Optional: log out and back in once and tell me if the status shows gaps = 0.

## What I will answer from it
1 event reaches addon; 2 exact English text; 3 looter; 4 non-looter share; 5 exact amount; 6 order vs PLAYER_MONEY; 7 group size reliable.
