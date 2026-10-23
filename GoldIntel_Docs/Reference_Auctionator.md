# Reference review: Auctionator (Forever-compatible build)

Source: Constants (Forever durations), the TOC, Source\Manifest.xml, AH\Events.lua, AH Mixins manifest, and from Source_ModernAH: Constants\Main.lua, AH\Initialize.lua, AH\Wrappers.lua, Tabs\Selling\Mixins\SaleItem.lua, Tabs\Buying\Item\Mixins\Main.lua, Tabs\Buying\Commodity\Mixins\Main.lua, Tabs\Cancelling\Mixins\Main.lua (supplied by the user 2026-10-18). Behavior read only; nothing copied. For 3b-4 (AH deposit, buyout, bid, cancel) and Phase 6. Nothing here is verified by us in the live client.

## What this says about Forever (third-party code)
- Forever runs the modern auction API (`C_AuctionHouse`) and the modern `AuctionHouseFrame` (it uses `ItemSellFrame` and `CommoditiesSellFrame`). Matches our E-36 event AUCTION_HOUSE_AUCTION_CREATED. `Auctionator.Constants.IsForever` exists.
- Prices on Forever can be to the copper. Retail rounds posting prices and commodity unit prices up to whole silver; the Forever branch skips that rounding. Deposits therefore can be exact copper amounts.
- Forever durations are 2, 8 and 24 hours (Constants file). The SaleItem file maps 12/24/48 hours to codes 1/2/3, which is the retail table, so either Forever posts through a different path or that mapping does not apply. UNRESOLVED. Our P_AH_LISTED should store the code and derive hours from the Forever table, then be checked live.

## Posting
- Deposit is read BEFORE posting: `CalculateItemDeposit(location, durationCode, qty)` for items, `CalculateCommodityDeposit(itemID, durationCode, qty)` for stackable goods; item vs commodity via `GetItemCommodityStatus`. A readable exact signal.
- Post: `PostItem(location, duration, qty, bid, buyout)` or `PostCommodity(location, duration, qty, buyout)`; both return a truthy value when accepted. Auctionator treats the click as success and does not wait for a server event. It also guards "not throttled (to avoid silent post failure)" and "enough money for the deposit": a post can fail silently, so an expectation made at click time could be a phantom. Our own signal (AUCTION_HOUSE_AUCTION_CREATED about 0.36 s before the deposit, E-36) is the server's word and is the better trigger.

## Buying
- Stackable goods: `StartCommoditiesPurchase(itemID, qty)` then event COMMODITY_PRICE_UPDATED (unit price, TOTAL price) before the player confirms, then COMMODITY_PURCHASE_SUCCEEDED or COMMODITY_PURCHASE_FAILED. The total is known before the money moves: exact outgoing expectation of that total on SUCCEEDED, nothing on FAILED.
- Non-stackable items: one call, `PlaceBid(auctionID, price)`; the dialog shows "Paying X" first. Bid and buyout are the same call (the price passed decides which). Auctionator registers no success event for it, so the money change itself is the only confirmation there; our E-37 measured a 300 copper bid charged exactly and immediately.
- Stackable goods, full sequence (Dialogs.lua): `StartCommoditiesPurchase(itemID, qty)` -> COMMODITY_PRICE_UPDATED (unit, total) -> player confirms -> `ConfirmCommoditiesPurchase(itemID, qty)` -> COMMODITY_PURCHASE_SUCCEEDED or FAILED. Money moves only after the confirm. If the player closes the dialog it calls `CancelCommoditiesPurchase()` and nothing is charged. So the expectation is made on the confirm path and only counts after SUCCEEDED.

## Cancelling
- `C_AuctionHouse.GetCancelCost(auctionID)` is readable before `CancelAuction(auctionID)`. Auctionator warns when it is above 0 ("bid existing on owned auction"). Our E-36 measured a cancel with no bid: cost 0. A cancel on an auction that has a bid can cost money; untestable with one account. Candidate: exact expectation of -cancelCost, otherwise stays OTHER (documented limitation).

## Data it keeps (saved variables)
AUCTIONATOR_POSTING_HISTORY, AUCTIONATOR_PRICE_DATABASE, AUCTIONATOR_VENDOR_PRICE_CACHE: reference shapes for Phase 6 pricing and item valuation.

## Not needed
AH\Events.lua is only Auctionator's own internal message names; AH\Mixins is a request queue/throttle; the rest is UI.

## Posting history (PostingHistory\Mixin.lua)
- Per item key a list of { price (buyout), quantity, bidPrice, time }. Written when Auctionator's own AuctionCreated message fires, which happens at click time (not on a server event), so a silently failed post is still recorded.
- Merges entries of the same price on the same day (quantities added) and keeps only the newest N (a setting). Records no deposit, no outcome (sold, expired, cancelled) and no income.
- Takeaway: it is a pricing aid, not an accounting record. Ours should be written on the server event, keep the deposit, and be linked later to the outcome (sale mail, expiry return, cancel).

## 3b-4 design inputs (proposals only; nothing approved, nothing built)
1. Post: expectation of -deposit made on AUCTION_HOUSE_AUCTION_CREATED (E-36: money follows 0.358 s later); deposit amount from the pre-post calculation if we can capture it, otherwise matched by the money change alone.
2. Item buyout or bid: exact -price from the dialog's call to PlaceBid; confirmed by the money change only.
3. Stackable purchase: exact -total from COMMODITY_PRICE_UPDATED, counted only after COMMODITY_PURCHASE_SUCCEEDED, discarded on FAILED or CancelCommoditiesPurchase.
4. Cancel: -GetCancelCost when above 0, else nothing; the bid case cannot be tested with one account (stays OTHER, documented).
5. Duration: store the code and derive hours from the Forever table (2, 8, 24); verify live.
6. Prices and deposits are exact copper on Forever; no whole-silver rounding.
7. Each of these needs a live check on Forever before it is built (what Auctionator does is not proof of what the client sends).

