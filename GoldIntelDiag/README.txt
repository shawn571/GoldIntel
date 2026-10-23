GoldIntelDiag - read-only diagnostics for the GoldIntel Phase 1 compatibility investigation

INSTALL
  Extract GoldIntel_Phase1_AddOns.zip into your AddOns folder (contains all three addons complete).
  Do NOT copy single files: GoldIntelDiag needs Diag.lua AND SrcCurrent.lua.
  Manual alternative: copy the whole GoldIntelDiag folder into your WoW Forever AddOns directory
  (the folder that already contains GoldIntel). Do not rename it. Log in.
  Enable "Load out of date AddOns" if the client lists it as incompatible.

RUN (in this order)
  /gidiag compile   The client's own Lua compiler tries every embedded GoldIntel source file
                    (all current files).
                    FAIL lines show the real error text. This answers "why did Platform fail to load".
  /gidiag all       Language, addon/TOC, API namespaces, unit identity, map, event NAMES (nothing registered), timers, slash,
                    saved variables, compile. Read-only.
  /gidiag copy      Opens a window with the whole transcript: Ctrl+A, Ctrl+C, paste it back.
  /gidiag reg NAME  OPT-IN: registers ONE event on a throwaway frame and reports whether the client
                    blocked it (a blocked-action popup naming NAME means NAME is restricted).
  /gidiag run       Runs the whole current GoldIntel (Platform, Core, Store) inside a sandbox with PRIVATE
                    saved variables and slash commands, and prints its probe report, core and store state,
                    capability stages and diagnostics. Your real GoldIntelDB and /gi are not touched.
  Single sections:  /gidiag lua | addon | api | unit | map | events | timer | slash | sv
  /gidiagtest hello works after "/gidiag slash" (proves runtime slash registration).

AFTER /reload the transcript is also saved in
  WTF\Account\<account>\SavedVariables\GoldIntelDiag.lua   (field "transcript")

WHAT IT CHANGES
  Nothing about your character. It registers /gidiag, a throwaway /gidiagtest, a few event
  registrations on throwaway frames, and one saved-variables table (GoldIntelDiagDB).

INTEGRITY CHECK OF YOUR GoldIntel FILES ON DISK
  MANIFEST.txt lists size, adler32 and SHA-256 for every GoldIntel file (old and patched).
  Windows:  certutil -hashfile GoldIntel\Platform\Platform.lua SHA256
  PowerShell: Get-FileHash GoldIntel\Platform\*.lua -Algorithm SHA256
  Compare with MANIFEST.txt. A mismatch means the files on disk are not the files that were delivered.


PHASE 3a LAB (version 1.1)
--------------------------
Read-only signal verification (Decision D-051). Nothing here collects gold data or touches GoldIntel.
Results are saved in GoldIntelDiag.lua under the field "lab" (bounded, about 400 payload samples).

Session 1 (no event registration):
  /gidiag lab api session1      runs P0 I1 I2 A1 S1 T2 H1
  /afk   then  /gidiag lab api A1 afk   then /afk again
  /gidiag lab api T2 mounted    while mounted
  /gidiag lab track 120         walk, run, mount, take a flight path, hearth
  /gidiag lab square on         open the world map and look; then /gidiag lab note H2 <what you saw> ; square off
  /gidiag lab report            then /reload and send GoldIntelDiag.lua

Later sessions: ONE event per session, /reload between:  /gidiag lab reg LOOT_OPENED  (see /gidiag lab list)
Other commands: lab show ID, watch, unreg, note, done ID pass|fail|inconclusive|blocked, clear, help.
If a popup mentions ADDON_ACTION_FORBIDDEN, copy its text exactly and report it.

VERSION 1.2 (after Session 1 results)
  New: /gidiag lab api P1   (names inside the C_Loot, C_Secrets, C_RestrictedActions ... tables; nothing is called)
  New experiment I1b: /gidiag lab reg GET_ITEM_INFO_RECEIVED, then /gidiag lab api I1 (twice, 5 s apart)
SESSION 2 (the first event): 
  /gidiag lab api P1            (once)
  /gidiag lab reg LOOT_OPENED   then kill and loot several mobs that drop coins (and one with an item)
  while a loot window is open: /gidiag lab api L3
  optional at the same time: /gidiag lab track 300 and take a full flight path to capture the landing
  /gidiag lab watch, /gidiag lab report, /reload, send GoldIntelDiag.lua

VERSION 1.3 / SESSION 3 (L2 plus the loot window details)
  /gidiag lab api P2            out of combat, then again in combat (restriction state getters, read-only)
  /gidiag lab reg LOOT_SLOT_CLEARED
  loot a mob that drops an ITEM; with the loot window open run /gidiag lab api L3
  skin a mob; with the skinning loot window open run /gidiag lab api L3 again
  /gidiag lab report, /reload, send GoldIntelDiag.lua
Optional: inside an instance run /gidiag lab api S1 instance

VERSION 1.4 / SESSION 4 (L2)
  /gidiag lab reg LOOT_SLOT_CLEARED
  loot several mobs slot by slot (click each item or coin); a mining or herb node too if you can
  with a loot window open: /gidiag lab api L3
  /gidiag lab report, /reload, send GoldIntelDiag.lua
Optional: after entering any dungeon: /gidiag lab api S1 instance   (and again right after leaving)

VERSION 1.5 / SESSION 5 (M1, merchant)
  /gidiag lab reg MERCHANT_SHOW
  open any vendor, sell ONE item, buy ONE item, (repair if offered), close the window
  /gidiag lab report, /reload, send GoldIntelDiag.lua
Optional extra for the skinning check (needs lab 1.5): later, in a session with LOOT_OPENED registered
  (/gidiag lab reg LOOT_OPENED), loot a skinnable mob, then skin that same mob.


SESSION 8 - LOOT_OPENED (gathering, skinning, disenchanting). Do this on EACH character below.
For every character: log in, do steps 1 to 8, then log out or /reload before switching. Never use "lab clear".
 1. Log in. Wait for the addon message "loaded".
 2. Type: /gidiag lab reg LOOT_OPENED
    Expected: a line saying "LOOT_OPENED: registered (IsEventRegistered true)". If a popup appears, copy its text.
 3. Type ONE note naming the character and its job, for example:
    /gidiag lab note Grizzly Slaps: herb
 4. Do ONLY the action for this character (below), looting everything it gives.
 5. Type: /gidiag lab report
 6. Type: /reload   (this saves the file)
 7. Switch to the next character and repeat from step 1.
 8. After the LAST character, log out. Send me GoldIntelDiag.lua once.
Actions:
 Herbalist: gather one herb.
 Miner: mine one node.
 Skinner: kill one mob, loot the corpse, then skin the same corpse and loot again. (Two loot windows, one corpse. Note: a corpse cannot be skinned twice.)
 Enchanter: disenchant one green or blue item. Accept the loot window.


SESSION 11 - INSTANCE RUN (S1). No event registration. One character, a normal dungeon.
Purpose: what the game reports at the dungeon entrance, inside, and after leaving.
 1. Log in and stand in the open world about 20 yards BEFORE the dungeon entrance portal. Do not enter yet.
 2. Type: /gidiag lab api S1 outside-before
 3. Type: /gidiag lab track 300
    (it samples once per second for 300 seconds; if you need longer, run it again later)
 4. Walk to the entrance and enter the dungeon. Wait for the loading screen to finish.
 5. Immediately type: /gidiag lab api S1 inside-start
 6. Walk about 30 seconds into the dungeon, then type: /gidiag lab api S1 inside-later
 7. Leave the dungeon through the normal exit and wait for the loading screen to finish.
 8. Immediately type: /gidiag lab api S1 outside-after
 9. If the track is still running, let it end or type: /gidiag lab track stop
10. Type one note: /gidiag lab note S1 <Name>: <dungeon name>, entered and left once
11. Type: /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.
Optional (only if easy): zone out and back in without leaving the dungeon, or run a second lap and repeat steps 5 and 8 once.
Do not kill bosses on purpose for this test; clearing normally is fine.


SESSION 12 - MAIL (X1). Registers ONE event: MAIL_INBOX_UPDATE (it fires on every inbox change, so it shows the money and item takes).
PREPARATION (no addon commands needed; do this first, on any characters you like):
 P1. On character A, open a mailbox and send character B a mail with a small amount of money (for example 50 copper) AND one item attached (any cheap item). Use money-attached mail, not cash on delivery.
 P2. Make sure B has the mail waiting (it is usually instant between your own characters).
THE TEST (on character B, the receiver):
 1. Log in as B. Do not open the mailbox yet.
 2. Type: /gidiag lab reg MAIL_INBOX_UPDATE
    Expected: "MAIL_INBOX_UPDATE: registered (IsEventRegistered true)". If a popup appears, copy its text.
 3. Type: /gidiag lab note <Name>: mail receiver, 1 mail with money and an item
 4. Walk to a mailbox and open it.
 5. Click the money in the mail (take the money). Wait 2 seconds.
 6. Click the item (take the item). Wait 2 seconds.
 7. Close the mailbox.
 8. Type: /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.
Do not delete the mail or send anything during this test.


VERSION 1.6 / SESSION 13 - MAILBOX METADATA (X2). No event registration. Install the new GoldIntelDiag first (version 1.6).
Purpose: can the addon read who sent a mail, its subject, money, attachments and the auction invoice, so that auction
proceeds, alt transfers, gifts and item deliveries can be told apart. It only READS; it does not open or take any mail.
PREPARATION (get mail into one character's inbox; more kinds is better, at least two):
 P1. Alt transfer: from character A send character B a mail with 50 copper and one item (as in Session 12).
 P2. Gift-style mail: send B a second mail with only an item, and a third with only copper, if you can.
 P3. Auction mail (the important one): on any character, list a cheap item on the auction house for the shortest time
     and then cancel it (the Auction House mails the item back), or let it sell to another of your characters
     (the proceeds mail can take a while to arrive). Any mail whose sender is the Auction House helps.
THE TEST (on the character that holds the mail):
 1. Log in. Do not register any event. Go to a mailbox and open it. Leave the mails unopened and unread.
 2. Type: /gidiag lab api X2 mailbox
    (it reads at most 8 mails and prints one block per mail)
 3. Type: /gidiag lab note X2 <Name>: mailbox with <what mails are in it>
 4. Optional: take ONE mail's money, then type /gidiag lab api X2 after-take
 5. Close the mailbox.
 6. Type: /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.
The probe never calls the function that marks a mail as read.


SESSION 14 - ITEM DATA LOADING (I1b). One character. No code change; reload is enough (no new install needed beyond 1.6).
Purpose: does the game tell the addon when item data (sell price, bind type) finishes loading, so unknown prices can be
filled in later instead of being guessed.
 1. Log in fresh (a new login, not /reload, so the item cache is cold). Do not open bags, vendors or the auction house first.
 2. Type: /gidiag lab reg GET_ITEM_INFO_RECEIVED
    Expected: "GET_ITEM_INFO_RECEIVED: registered (IsEventRegistered true)". If a popup appears, copy its text.
 3. Type: /gidiag lab note I1b <Name>: fresh login, item data test
 4. Type: /gidiag lab api I1
 5. Wait 5 seconds, then type: /gidiag lab api I1   again.
 6. Type: /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.

SESSION 15 - TRADE (R1), SECOND VERSION (type the commands EXACTLY as written; nothing in them is a placeholder).
One character (you) plus ONE helper who needs no addon. Four short rounds (about 2 minutes each); each round registers a
different event because the lab allows ONE new event per game session. If the helper can only stay for some rounds, do them in order.

THE TRADE SCRIPT (the same in every round; read this to the helper):
  "I will ask you to trade with me a few times. 1) Open a trade with me. 2) Do nothing for 5 seconds, then cancel it.
   3) Open a trade with me again. 4) Put ONE cheap item (any grey or white item you do not need) on your side; I put 10 copper on mine.
   5) I click Accept first. We both wait 3 seconds. 6) Then you click Accept and the trade completes."
  (Round 3 only: after I click Accept and before you do, add 1 more copper to your side, which resets my Accept; then I click Accept
   again and you accept.)

ROUND 1 - TRADE_CLOSED
  1. Log in (or /reload).
  2. Type exactly:  /gidiag lab reg TRADE_CLOSED
     It must answer "TRADE_CLOSED: registered (IsEventRegistered true)". If it says "not in the catalog", stop and tell me.
  3. Type exactly:  /gidiag lab note R1 round 1 TRADE_CLOSED, helper <the helper's name>
  4. Run the trade script with the helper.
  5. Type exactly:  /gidiag lab report
ROUND 2 - TRADE_SHOW
  1. Type exactly:  /reload
  2. Type exactly:  /gidiag lab reg TRADE_SHOW
  3. Type exactly:  /gidiag lab note R1 round 2 TRADE_SHOW, helper <the helper's name>
  4. Run the trade script.    5. Type exactly:  /gidiag lab report
ROUND 3 - TRADE_ACCEPT_UPDATE
  1. Type exactly:  /reload
  2. Type exactly:  /gidiag lab reg TRADE_ACCEPT_UPDATE
  3. Type exactly:  /gidiag lab note R1 round 3 TRADE_ACCEPT_UPDATE, helper <the helper's name>
  4. Run the trade script WITH the round 3 extra step.    5. Type exactly:  /gidiag lab report
ROUND 4 (optional) - TRADE_MONEY_CHANGED
  1. Type exactly:  /reload
  2. Type exactly:  /gidiag lab reg TRADE_MONEY_CHANGED
  3. Type exactly:  /gidiag lab note R1 round 4 TRADE_MONEY_CHANGED, helper <the helper's name>
  4. Run the trade script.    5. Type exactly:  /gidiag lab report
AFTER THE LAST ROUND: type /reload once more and send me GoldIntelDiag.lua (one file holds all rounds).
The lab only records trade events after the matching "registered" line appears, so check it each round.
Do not move items or gold in your bags during a round.


VERSION 1.7 / SESSION 16 - QUEST REWARD ITEM (Q2). Install GoldIntelDiag 1.7 first. A /reload is enough (Lab.lua changed,
no file was added or renamed; the TOC version number is the only TOC change).
Purpose: when a quest gives an item, can the addon see it by comparing the bags before and after, and does the game send
a bag event (BAG_UPDATE_DELAYED) that tells the addon when to compare? It only READS your bags and money; it changes nothing.
YOU NEED: one character with a finished quest whose reward is an ITEM (a fixed item or a choice of items), ideally one that
also pays copper. At least one free bag slot. Do NOT hand the quest in yet.
 1. Log in (or /reload). Stand at the quest giver with the quest ready to hand in. Open the turn-in window but do not click Complete.
 2. Type exactly:  /gidiag lab reg BAG_UPDATE_DELAYED
    It must answer "BAG_UPDATE_DELAYED: registered (IsEventRegistered true)". If a popup appears, copy its text and stop.
 3. Type exactly:  /gidiag lab note Q2 <CharacterName>: quest <quest name>, reward <item name>, <fixed or choice>
 4. Type exactly:  /gidiag lab api Q2 before
    It prints "stored". Do not loot, buy, sell or move anything from now until step 7.
 5. Choose the reward item (if there is a choice) and click Complete Quest. Wait 3 seconds.
 6. Type exactly:  /gidiag lab api Q2 after
    It prints the items that were added, removed or changed, and the copper change.
 7. OPTIONAL second quest (more data, same session): repeat steps 4 to 6 with another quest that has an item reward.
 8. Type exactly:  /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.


SESSION 17 - MERCHANT_CLOSED. One character, any vendor. No install needed (1.7).
Purpose: does the game tell the addon when the vendor window closes, both when you close it and when you walk away?
 1. Log in (or /reload).
 2. Type exactly:  /gidiag lab reg MERCHANT_CLOSED
    It must answer "MERCHANT_CLOSED: registered (IsEventRegistered true)". If a popup appears, copy its text and stop.
 3. Type exactly:  /gidiag lab note M1 <CharacterName>: MERCHANT_CLOSED, vendor <vendor name>
 4. Open a vendor. Sell one cheap item. Wait 2 seconds. Close the window with the X button (or Esc). Wait 3 seconds.
 5. Open the same vendor again. Walk away until the window closes by itself (more than about 10 steps). Wait 3 seconds.
 6. Type exactly:  /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.

SESSION 18 - MAIL_CLOSED plus the sold-auction mail. One character whose mailbox holds the Auction House sale mail. No install needed (1.7).
Purpose: does the game tell the addon when the mailbox closes, and what does a sold-auction mail look like to the addon (invoice fields)?
 1. Type exactly:  /reload     (a new game session is needed for a new event)
 2. Type exactly:  /gidiag lab reg MAIL_CLOSED
    It must answer "MAIL_CLOSED: registered (IsEventRegistered true)". If a popup appears, copy its text and stop.
 3. Type exactly:  /gidiag lab note X1 <CharacterName>: MAIL_CLOSED, mailbox holds an auction sale mail
 4. Open the mailbox. Do NOT click any mail yet.
 5. Type exactly:  /gidiag lab api X2 sale
    (it reads the headers and the invoice of up to 8 mails, including the sale mail)
 6. Take the money from the auction sale mail (click the money). Wait 2 seconds.
 7. Type exactly:  /gidiag lab api X2 after-take
 8. Close the window with the X button (or Esc). Wait 3 seconds.
 9. Open the mailbox again and walk away until the window closes by itself. Wait 3 seconds.
10. Type exactly:  /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.

==========================================================================================
VERIFICATION ADDENDUM (decision D-068): auction house, outgoing mail, COD. Lab version 1.8.
INSTALL ONCE (before Session 19): replace the GoldIntelDiag folder in Interface\AddOns with the one from the new zip, then log in
or type /reload. A /reload is ENOUGH: no file was added or removed, so no client restart is needed. Check with: /gidiag lab list
(it must show AHS, AH1, MS1 and CO1).
These sessions only READ and record. They change nothing and register NO event except where a step says so.
Use two characters: A (any character that can sell something, with about 2 gold) and B (any other character on your account).
Money matters: the lab records your copper at every "api" command, so the money change of each action is measured.

SESSION 19 - AUCTION HOUSE: listing deposit, cancel, buyout, bid. Character A. No event registered.
YOU NEED: character A next to an Auction House with a few cheap items to sell, and 1 gold or more.
 1. Type exactly:  /reload
 2. Type exactly:  /gidiag lab note AHS <CharacterName>: auction house, listing, cancel, buyout, bid
 3. Open the Auction House window.
 4. Type exactly:  /gidiag lab api AHS names
    (lists which auction and mail event names this client knows; registers nothing)
 5. Type exactly:  /gidiag lab api AHS open
 6. Start listing ONE item for 12 hours but do NOT click Post yet. Read the Deposit shown in the window.
    Type the note with the number you read, in this form (example for 100 copper):  /gidiag lab note AHS deposit shown 100 copper
 7. Click Post. Wait 3 seconds. Type exactly:  /gidiag lab api AHS listed
 8. Cancel that same auction (Auctions tab, select it, Cancel Auction). If the window says anything about losing the deposit or a cost,
    type a note with what it said, for example:  /gidiag lab note AHS cancel window said no cost
    Wait 3 seconds. Type exactly:  /gidiag lab api AHS canceled
 9. Buy something cheap with BUYOUT (a single item or a commodity, under 50 silver). Note the price shown, for example:
    /gidiag lab note AHS buyout price shown 250 copper
    Wait 3 seconds. Type exactly:  /gidiag lab api AHS bought
10. Place a BID (not a buyout) on a cheap non-stackable item, if the House offers bidding. Note the bid, for example:
    /gidiag lab note AHS bid shown 120 copper
    Wait 3 seconds. Type exactly:  /gidiag lab api AHS bid
    If this client has no bidding, type:  /gidiag lab note AHS no bidding available
11. Close the Auction House window. Type exactly:  /gidiag lab api AHS closed
12. Type exactly:  /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.
    The mails created by the cancel, the buyout and the bid arrive later; they are read in Session 22.

SESSION 20 - OUTGOING MAIL: postage, money sent, COD sent. Character A, sending to character B. No event registered.
YOU NEED: character A with 3 cheap tradable items and about 50 silver; character B exists on your account.
 1. Type exactly:  /reload
 2. Type exactly:  /gidiag lab note MS1 <CharacterName>: outgoing mail to my other character, item, money, COD
 3. Open a mailbox and the Send Mail tab.
 4. Type exactly:  /gidiag lab api MS1 names
 5. MAIL 1 (item only): type character B's name, attach ONE cheap item, no money. Do NOT click Send yet.
    Type exactly:  /gidiag lab api MS1 ready-item
    Click Send. Wait 3 seconds. Type exactly:  /gidiag lab api MS1 sent-item
 6. MAIL 2 (money only): attach nothing, put 5 silver in the money field. Do NOT click Send yet.
    Type exactly:  /gidiag lab api MS1 ready-money
    Click Send. Wait 3 seconds. Type exactly:  /gidiag lab api MS1 sent-money
 7. MAIL 3 (COD): attach ONE cheap item, choose Cash on Delivery, set the amount to 20 silver. Do NOT click Send yet.
    Type exactly:  /gidiag lab api MS1 ready-cod
    Click Send. Wait 3 seconds. Type exactly:  /gidiag lab api MS1 sent-cod
 8. If the window showed a postage cost, or said mail to your own characters is free, type a note with what it said, for example:
    /gidiag lab note MS1 postage shown 30 copper      or      /gidiag lab note MS1 no postage shown
 9. Type exactly:  /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.
    Mail to another character can take up to 1 hour to arrive. Wait for it before Session 21.

SESSION 21 - COD, PAYING. Character B (the receiver). Registers ONE event: MAIL_INBOX_UPDATE.
 1. Type exactly:  /reload
 2. Type exactly:  /gidiag lab reg MAIL_INBOX_UPDATE
    It must answer "MAIL_INBOX_UPDATE: registered (IsEventRegistered true)". If a popup appears, copy its text and stop.
 3. Type exactly:  /gidiag lab note CO1 <CharacterName>: paying a COD of 20 silver
 4. Open the mailbox. Do NOT click any mail yet. Type exactly:  /gidiag lab api X2 cod
 5. Take the COD item (this pays the 20 silver). Wait 3 seconds. Type exactly:  /gidiag lab api X2 cod-paid
 6. Also take the other two mails (the item mail and the 5 silver mail), one at a time, waiting 3 seconds between them.
    After each, type exactly:  /gidiag lab api X2 taken
 7. Type exactly:  /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.

SESSION 22 - COD PAYMENT AND AUCTION MAILS. Character A. Registers ONE event: MAIL_INBOX_UPDATE.
Do this once the COD payment mail and the auction mails (cancel, buyout win, bid) have arrived. Waiting an hour after Sessions 19 to 21 is fine.
 1. Type exactly:  /reload
 2. Type exactly:  /gidiag lab reg MAIL_INBOX_UPDATE
    It must answer "MAIL_INBOX_UPDATE: registered (IsEventRegistered true)". If a popup appears, copy its text and stop.
 3. Type exactly:  /gidiag lab note CO1 <CharacterName>: COD payment mail and auction mails
 4. Open the mailbox. Do NOT click any mail yet. Type exactly:  /gidiag lab api X2 all-mail
 5. Take the money from the COD payment mail. Wait 3 seconds. Type exactly:  /gidiag lab api X2 cod-money
 6. Take what is in each auction mail (won item, returned item, returned bid), ONE mail at a time, waiting 3 seconds between them.
    After each, type exactly:  /gidiag lab api X2 auction-taken
 7. Type exactly:  /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.

AFTER SESSION 19 I will tell you whether one more session is worth it to register an auction event (for example the one that fires when an
auction is created). Event registration is limited to one new event per game session, so I will only ask if the data shows it is needed.

SESSION 23 - AUCTION HOUSE WITH ONE EVENT (repeat of the buyout and bid). Character A (the one from Session 19). Registers ONE event: AUCTION_HOUSE_AUCTION_CREATED.
Purpose: does the game announce a new auction, and how long before or after the deposit money? The registration also makes the lab record each money change on its own, which splits the buyout from the bid (Session 19 showed -113 for both, 1 copper short of 114).
YOU NEED: character A next to the Auction House, a few cheap items to sell, about 500 copper, and something cheap to buy by buyout and something cheap to bid on.
 1. Type exactly:  /reload
 2. Type exactly:  /gidiag lab reg AUCTION_HOUSE_AUCTION_CREATED
    It must answer "AUCTION_HOUSE_AUCTION_CREATED: registered (IsEventRegistered true)". If a popup appears, copy its text and stop.
 3. Type exactly:  /gidiag lab note AH1 <CharacterName>: session 23, post, cancel, buyout, bid, one snapshot after each
 4. Open the Auction House. Type exactly:  /gidiag lab api AHS s23-open
 5. List ONE item for 12 hours. Note the deposit shown, for example:  /gidiag lab note AH1 deposit shown 100 copper
    Click Post. Wait 3 seconds. Type exactly:  /gidiag lab api AHS s23-listed
 6. Cancel that auction. Wait 3 seconds. Type exactly:  /gidiag lab api AHS s23-cancelled
 7. Buy something cheap by BUYOUT only. Note the price, for example:  /gidiag lab note AH1 buyout price shown 13 copper
    Wait 3 seconds. Type exactly:  /gidiag lab api AHS s23-bought
 8. Place a BID on something cheap. Note the bid, for example:  /gidiag lab note AH1 bid shown 101 copper
    Wait 3 seconds. Type exactly:  /gidiag lab api AHS s23-bid
 9. Close the Auction House. Type exactly:  /gidiag lab api AHS s23-closed
10. Type exactly:  /gidiag lab report   then   /reload   and send me GoldIntelDiag.lua.
Do not do anything else that costs or earns money between steps 4 and 9 (no vendor, no mail, no quests); every snapshot must show only its own action.
