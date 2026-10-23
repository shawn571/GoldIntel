# GoldIntel 3b-3 M3 — Session V (live validation of stored lots)

Build 0.4.7-phase3b3m3. New file in the addon: **restart the client** (a `/reload` is not enough). GIProbeLoot and GoldIntelDiag must NOT be in AddOns. One character is enough.

## Run
1. `/gi collect on`, then `/gi ledger mark`.
2. Kill and loot 3 or more mobs (coin and items). Then `/gi lots last 5`: each looted item should appear as a lot with a value and "value-created".
3. Vendor: sell 1 item, then sell a stack of 3, then sell two different items together. Then `/gi lots last 10` and `/gi lots status` (conversions should appear; the open quantity should drop).
4. Vendor: buy 1 item, then buy it back after selling (`/gi lots last 5`: the purchase shows "vendor/purchase").
5. Optional: turn in a quest with a reward item.
6. Optional but valuable: log in on the character, then loot an item you have never seen on this client. Run `/gi lots unknown` right away, again after a few seconds: it should list the item and then say "no unknown values".
7. Manual price (optional): `/gi price set <item id or link> 1g`, loot that item, `/gi lots last 3` (value source "manual"), then `/gi price clear <item>` and `/gi price list`.
8. `/gi lots check` (diagnostic only: differences from the bags are expected), `/gi lots status`.
9. `/gi ledger check` — must show **0 copper difference**.
10. `/gi collect off`, then exit with **/logout** (not /reload), log back in, run `/gi lots status`: the same lots must still be there.

## Report
Paste the output of steps 2, 3, 4, 8, 9 and 10, and any line that says "UNEXPECTED item condition ... please report it as a bug". If the client crashes or shows a Lua error, say at which step.
