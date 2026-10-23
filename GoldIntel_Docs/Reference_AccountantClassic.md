# Reference review: Accountant Classic (Forever-compatible build)

Source: Core.lua, Constants.lua, MoneyFrame.lua, Tabs.lua, Templates.lua, UI.lua, Config.lua supplied by the user 2026-10-18. Behavior read only; no code copied. Ace libraries (AceAddon, AceDB, AceLocale, AceConfig, AceEvent) supply storage, options, translations and event registration only. The money logic is plain Lua in Core.lua, so no Ace file is needed for this review.

## How it classifies money
- A sticky "mode" variable. Opening events set it (LOOT_OPENED -> LOOT, MERCHANT_SHOW -> MERCH, TRADE_SHOW -> TRADE, QUEST_* -> QUEST, TAXIMAP_OPENED -> TAXI, TRAINER_SHOW -> TRAIN, AUCTION_HOUSE_SHOW -> AH, MAIL_INBOX_UPDATE -> AH if a seller invoice exists else MAIL, MERCHANT_UPDATE in repair mode -> REPAIRS). Most closing events set it to "" and "" means OTHER.
- On PLAYER_MONEY the whole difference since the last balance is booked under the current mode. No amounts are matched, nothing is held back, nothing is reconciled. This is the "recent context" heuristic we rejected; our expectations design is stricter.
- OTHER also comes from a login/logout difference ("un-recorded money").
- Categories: TRANSMO, GARRISON, LFG, BARBER, GUILD, TRAIN, TAXI, TRADE, AH, MERCH, REPAIRS, MAIL, QUEST, LOOT, OTHER ("Unknown").

## Coin chat line
- It registers CHAT_MSG_MONEY and its comment says the event "is supposed to be fired before PLAYER_MONEY". On Forever we measured the opposite (E-48/E-49: chat 0.5-1.0 s after). Its handler books the parsed amount as LOOT and then shifts its stored balance to suppress the next PLAYER_MONEY. If the order is reversed, my reading is that this can book the amount twice or leave a phantom difference. Not tested in the client.
- It ignores the chat line when the mode is already LOOT (a loot window was opened), so a group share is booked by the money change, not the chat line.
- It parses with translated patterns ("(%d+) Gold" etc.), takes any text, and does not check what the line says. We anchor to the two received-coin lines and require money words only.

## Client facts it implies for Forever (third-party code, not verified by us)
- Forever has its own project id constant, `WOW_PROJECT_CAMELOT` (we log `WOW_PROJECT_ID` in the probe and can compare).
- `UnitName("player")` returns a second value that is the secondary ("last") name, not a realm; the addon builds "First-Last" (matches our Chilly-Slaps file names).
- It uses the retail-style API paths on Forever (currency info as a table, retail tab textures) and registers the retail event list, including GARRISON, BARBER_SHOP, TRANSMOGRIFY, GUILDBANK, LFG_COMPLETION_REWARD, TAXIMAP_OPENED, TRAINER_SHOW, CONFIRM_TALENT_WIPE. Whether each actually fires on Forever is unknown.

## What it suggests for our open work (proposals only; nothing approved)
- Money sinks we do not yet source: taxi fares, trainer costs, talent respec, barber, guild bank, repairs (repairs may already fall under vendor purchase at the merchant). Candidates for the 3b-4 scope list, each needs a live check of its opening event first.
- First-session baseline priming matches our first-run baseline and lastMoney fix.
- Per-zone income tracking exists; ours is richer (stamped location per entry).
