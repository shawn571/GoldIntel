# 3b-2 M4 live validation plan (addon 0.3.3-phase3b2m4)

Package: `GoldIntel_3b2_M4_AddOns.zip`. **Needs a CLIENT RESTART** (not just /reload). Retention cap is 2000 raw entries per character (fold 500).

## Preparation
1. Close the game. In the AddOns folder, remove `GoldIntelDiag` and `GIProbeLoot` (and any older GoldIntel folder), then extract the zip so `AddOns/GoldIntel` is the new one (keep `GIMin` if present).
2. Start the client and log in. Type `/gi version` -> must show `0.3.3-phase3b2m4`, contract 1.8. Type `/gi status`: store must say `schema=2 writable=true`.

## Session A - normal play (about 20-30 minutes)
Do a mix: kill and loot mobs (corpse looting by clicking, not auto-loot), vendor some items (sell AND buy something), turn in at least one quest, take money from a mail, one trade if possible.
1. `/gi collect on` -> the output must contain `ledger: interval started`.
2. `/gi ledger mark`
3. Play. At least every 5 minutes, and after each different activity, type `/gi ledger check`. Each line must end with `DIFFERENCE 0 copper (OK)`. Copy any line that does not.
4. After the activities: `/gi ledger last 30`, `/gi ledger status`, `/gi diag`
5. `/gi collect off`, then `/reload`. After the reload type `/gi collect status` (collect must be OFF) and `/gi ledger status` (entries must still be there).
6. Log out normally (character select or `/logout`), not by closing the client.

## Session B - AUTO-LOOT (about 15-20 minutes)
1. Turn auto-loot ON in the game options (Interface > Controls > Auto Loot). Log in again.
2. `/gi collect on`, `/gi ledger mark`.
3. Kill and loot at least 15-20 mobs that drop coin, plus one or two skinning loots if available. `/gi ledger check` every 5 mins and at the end.
4. `/gi ledger last 30`, `/gi ledger status`, `/gi diag`, `/gi collect off`.
5. Log out normally.
Optional: sell an item on the auction house, collect the sale mail (note which mail), `/gi ledger check`.

## What to send me
Both SavedVariables files from `WTF/Account/<account>/SavedVariables/`: `GoldIntelDB.lua` and the character's `GoldIntelCharDB.lua`, taken after step "log out normally" of each session (copy after Session A and again after Session B), plus the chat text of every `/gi ledger check`, `/gi ledger status` and `/gi diag`, and any error popup.

## What I will report
Ledger check results, OTHER share by value (and entries), largest OTHER entry, unmatched count, gap count and value, AUTO-LOOT results, any non-zero difference, any unexpected source classification; then a 3b-2 closure recommendation if the difference is 0 copper and there are no major classification errors.
