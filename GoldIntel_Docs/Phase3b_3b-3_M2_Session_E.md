# GoldIntel 3b-3 M2 — Session E (live evidence, trace only)

Build: 0.4.1-phase3b3m2, Contract 1.9.0. **Nothing is stored for items** in this build; it only writes trace lines.
Install: replace the GoldIntel folder, **restart the client** (new files, new event). GIProbeLoot and GoldIntelDiag must NOT be in AddOns.

## Setup
1. `/gi collect on`   (starts groups G1-G8 and the trace; G8 = item chat, evidence only)
2. `/gi lots status`  (expect: lots ON, trace only)

## Steps (do each, wait ~3 s after each)
1. Loot a creature that drops coin + an item (normal loot window).
2. Loot an item only (no coin). Then with auto-loot, once.
3. Leave one item behind in a loot window, close it.
4. Fill your bags, loot one more item (full bag).
5. Turn in a quest that gives a reward item.
6. Vendor: sell 1 item, then sell 3 items of one stack, then buy 1 item, then buy back 1 item.
7. Skin a creature you killed (skinning), mine a node, pick a herb.
8. If you have an enchanter: disenchant one item.
9. If grouped: win a roll on an item (optional).
10. Item facts — run each once: `/gi lots iteminfo <id or shift-click link>` for (a) an enchanting material, (b) a quest item, (c) a normal grey/white item.
11. Fight and loot during combat once.
12. `/gi lots status`, `/gi lots decisions 30`, `/gi ledger check` (must show 0 copper difference).
13. `/gi collect off`, then send the trace/SavedVariables as in earlier sessions (`/reload` once to flush).

## What the trace must answer
- BAGRANGE line: which bag indexes exist (0..5? reagent bag?).
- CHAT_LOOT lines: exact shapes for self loot, multi, pushed, created, won/roll.
- Timing of loot item vs money vs bag settle (ITEM_SLOT, BAGS settle, ITEM decision).
- Sell price / class / subclass of a no-vendor item (ITEMINFO lines).
- Vendor buyback signal (the sale/buyback decision lines).
- Any `ANOMALY ... please report this as a bug` line: report it.
