# 0.3.6 grouped validation (chat-signal rule)

Install: replace the GoldIntel folder in `...\_classic_beta_\Interface\AddOns` with the one from GoldIntel_3b2_M6_AddOns.zip (GoldIntelDiag and GIProbeLoot stay out).
Then type `/reload` (no new files this time; a full client restart also works).

1. `/gi ledger trace clear`
2. `/gi collect on`
3. `/gi ledger mark`
4. `/gi ledger trace note grouped validation start`
5. Group up and play normally for 10 to 15 minutes. Both of you loot whenever you like. If you can, include once: one player looting several corpses, and a group of 3 or more.
6. `/gi ledger check`
7. `/gi ledger status` (shows OTHER share, unmatched, gaps)
8. `/gi ledger trace 400` (copy the chat output)
9. `/gi collect off`
10. `/reload` (saves the character file)

Return: the chat copy from steps 6, 7 and 8, and the character `GoldIntel.lua`.
Optional second part, solo: repeat steps 2 to 9 without a group for about 10 kills (confirms the solo path).
