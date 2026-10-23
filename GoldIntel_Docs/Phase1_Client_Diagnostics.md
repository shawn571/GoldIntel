# Phase 1 Client Diagnostics (WoW Forever)

DOC VERSION: 1.1.0  |  DATE: 2026-10-09  |  Scope: Phase 1 compatibility only. No Phase 2 work.

Everything here is read-only for character data. Items that change a client setting (0.1), register a throwaway slash command (H1), or deliberately register one event (I6, opt-in, may show a popup) are flagged where they occur.

## Fastest path (three steps)

1. Extract **GoldIntel_Phase1_AddOns.zip** into your AddOns folder (it contains GoldIntel, GIMin and GoldIntelDiag as complete folders; never copy single files). Log in and run `/gidiag compile`.
2. Run `/gidiag all`, then `/gidiag copy` (Ctrl+A, Ctrl+C) and paste the result back.
3. Install **GIMin** and run `/gimin` (tests TOC path styles, namespace passing, SavedVariables, slash, events).

The copy/paste commands below give the same information without installing anything. Every command is at most 255 characters (the chat box limit); this is verified.

**How to read each entry:** *Supported* is what you see when the feature works; *Unsupported* is what you see when it does not; *Affects* is the GoldIntel module that depends on it.

## 0. Do this first: get the client's real error message

The client log only says 'Error loading'. With Lua errors switched on, a compile or load error shows its real message and line number. This changes a client display setting (a CVar), not character data. Undo with `/console scriptErrors 0`.

**0.1**

```
/console scriptErrors 1
```

- Proves: Turns on the Lua error popup so load errors show their text.
- Supported: No output. After `/reload`, any file that fails shows a popup like `Interface/AddOns/GoldIntel/Platform/Clock.lua:12: <message>`.
- Unsupported: No popup although the log still says 'Error loading': the failure is not a Lua compile error (file missing, unreadable, or path problem).
- GoldIntel module affected: All of Platform/ (file load)

**0.2**

```
/run print(GetCVar("scriptErrors"))
```

- Proves: Confirms the setting took effect.
- Supported: `1`
- Unsupported: `0` or `nil`: the command did not apply; retry `/console scriptErrors 1`.
- GoldIntel module affected: none

## A. Lua language and runtime (what is this Lua?)

Proves which Lua grammar the client compiles. GoldIntel is written for Lua 5.1. Every grammar check prints either a function (compiles) or `nil` plus an error message. In a Lua 5.1 client the first five print `nil` plus a message.

**A1**

```
/run print(_VERSION, jit and "jit" or "nojit", type(loadstring), type(load), type(setfenv))
```

- Proves: Lua version string and which 5.1-era functions exist.
- Supported: `Lua 5.1 nojit function function function`
- Unsupported: `Lua 5.4 nojit nil function nil` means a newer Lua; `loadstring` and `setfenv` are gone (GoldIntel does not use them).
- GoldIntel module affected: all files

**A2**

```
/run print(#"\xff")
```

- Proves: String escape rules: 5.1 treats `\x` as a plain letter, 5.2+ as a hex escape.
- Supported: `3` (5.1)
- Unsupported: `1` (5.2 or newer)
- GoldIntel module affected: all files (grammar level)

**A3**

```
/run print((loadstring or load)("return 7//2"))
```

- Proves: Integer division operator (5.3+ only).
- Supported: `nil  [string "return 7//2"]:1: unexpected symbol near '/'` (5.1)
- Unsupported: `function: 0x...` (5.3 or newer)
- GoldIntel module affected: all files (none use //)

**A4**

```
/run print((loadstring or load)("goto a ::a::"))
```

- Proves: goto and labels (5.2+).
- Supported: `nil` plus an error (5.1)
- Unsupported: `function: 0x...`
- GoldIntel module affected: all files (none use goto)

**A5**

```
/run print((loadstring or load)("for i=1,2 do break print(i) end"))
```

- Proves: 5.1 requires `break` to be the last statement of a block.
- Supported: `nil` plus an error (5.1)
- Unsupported: `function: 0x...` (5.2+)
- GoldIntel module affected: all files (verified by grep)

**A6**

```
/run print((loadstring or load)("x=[[a[[b]]c]]"))
```

- Proves: Nested long brackets: a hard error in 5.1, legal in 5.2+. This is the hazard behind the old `--[[ ... ]]` headers (now removed).
- Supported: `nil  ... nesting of [[...]] is deprecated near '['` (5.1)
- Unsupported: `function: 0x...`
- GoldIntel module affected: all files (headers converted to -- comments)

**A7**

```
/run print(type(table.unpack), type(unpack), type(bit and bit.band), type(math.pow), type(string.pack))
```

- Proves: Library differences between 5.1 and newer versions.
- Supported: `nil function function function nil` (5.1 with WoW's bit library)
- Unsupported: Anything else: record it; GoldIntel uses none of these.
- GoldIntel module affected: none (informational)

**A8**

```
/run print(type(issecretvalue), type(C_Secrets), type(canaccessvalue))
```

- Proves: Whether this client has the 12.0 'secret values' system that restricts addon access to some data.
- Supported: `function table function` (12.0-style; exact names may vary)
- Unsupported: `nil nil nil`: pre-12.0 behavior.
- GoldIntel module affected: Money, Unit, Map (values that might become secret)

## B. Addon loading and TOC

Proves how the client sees the GoldIntel folder. `reason` is the key field: `nil` means loadable.

**B1**

```
/dump GetBuildInfo()
```

- Proves: Game version, build, date and interface number of the running client.
- Supported: e.g. `1: "12.0.x" 2: "<build>" 3: "<date>" 4: <number>`
- Unsupported: n/a
- GoldIntel module affected: Probe, GoldIntel.toc

**B2**

```
/run print(select(4, GetBuildInfo()))
```

- Proves: The interface number the client itself reports (compare with TOC 16001).
- Supported: A number (your evidence says addons use 16001)
- Unsupported: A different number: record it; the TOC may still load with out-of-date addons enabled.
- GoldIntel module affected: GoldIntel.toc

**B3**

```
/dump C_AddOns.GetAddOnInfo("GoldIntel")
```

- Proves: How the client classifies the addon (name, title, notes, loadable, reason, security).
- Supported: `loadable: true`, `reason: nil`
- Unsupported: `reason: "INTERFACE_VERSION"` incompatible number; `"CORRUPT"` or `"MISSING"` the TOC or folder is the problem; `"DISABLED"`.
- GoldIntel module affected: GoldIntel.toc

**B4**

```
/run print(C_AddOns.IsAddOnLoaded("GoldIntel"))
```

- Proves: Whether the addon finished loading.
- Supported: `true true`
- Unsupported: `false`/`nil`: it did not load (see B3 reason).
- GoldIntel module affected: all

**B5**

```
/run print(C_AddOns.GetAddOnMetadata("GoldIntel","Interface"), C_AddOns.GetAddOnMetadata("GoldIntel","Version"))
```

- Proves: That the client reads the TOC fields you deployed.
- Supported: `16001  0.1.1-phase1-compat`
- Unsupported: `nil nil` TOC not read; a different version means an OLD copy is installed.
- GoldIntel module affected: GoldIntel.toc

**B6**

```
/run print(C_AddOns.GetNumAddOns(), (C_AddOns.GetAddOnInfo(1)))
```

- Proves: The addon API namespace exists and counts addons.
- Supported: `<count> <name of first addon>`
- Unsupported: Error `attempt to index global 'C_AddOns'`: older API; use `GetNumAddOns()`.
- GoldIntel module affected: Probe (informational)

## C. API namespaces

Proves which modern or Classic-era API families exist. GoldIntel adapters try modern and legacy names and degrade, so this only decides adapter ORDER.

**C1**

```
/run for _,n in ipairs({"C_Map","C_AuctionHouse","C_Timer","C_TradeSkillUI","C_AddOns","C_Container","C_Secrets"}) do print(n,type(_G[n])) end
```

- Proves: Which namespaces are tables.
- Supported: Seven lines, each `table` in a modern client
- Unsupported: `nil` for a missing namespace
- GoldIntel module affected: Map, Scheduler, (later) Auction and TradeSkill adapters

**C2**

```
/run local t={} for k,v in pairs(_G) do if type(k)=="string" and k:find("^C_") and type(v)=="table" then t[#t+1]=k end end table.sort(t) print(#t,table.concat(t," "))
```

- Proves: Complete list of C_ namespaces in this client.
- Supported: A count (dozens in a modern client) and the names
- Unsupported: A small count suggests a Classic-style client
- GoldIntel module affected: adapter ordering (all)

**C3**

```
/run for _,n in ipairs({"GetNumSkillLines","GetSkillLineInfo","GetProfessions","GetProfessionInfo","QueryAuctionItems","GetTradeSkillInfo","TakeInboxMoney","GetInboxItem"}) do print(n,type(_G[n])) end
```

- Proves: Which Classic-era global functions still exist (Unit.lua and Probe.lua look for these).
- Supported: Modern client: `GetProfessions function`, most Classic-only names `nil`
- Unsupported: `function` for the Classic names means a Classic-style API surface
- GoldIntel module affected: Unit (professions), Probe, later Auction/TradeSkill/Mail adapters

**C4**

```
/dump type(IsLoggedIn), type(SlashCmdList), type(CreateFrame), type(LibStub)
```

- Proves: Core globals GoldIntel uses on every load.
- Supported: `"function" "table" "function"` and `"table"` or `"function"` or `"nil"` for LibStub (nil is fine)
- Unsupported: `nil` for any of the first three: the addon cannot run.
- GoldIntel module affected: Events, Probe (fatal if CreateFrame is missing)

## D. C_Map (location)

Proves what Map.lua can read. All are read-only.

**D1**

```
/dump C_Map.GetBestMapForUnit("player")
```

- Proves: Current map ID.
- Supported: A number (e.g. `85`)
- Unsupported: Error `attempt to index ... 'C_Map' (a nil value)`: GoldIntel falls back to zone text, heatmap disabled.
- GoldIntel module affected: Map

**D2**

```
/run local m=C_Map.GetBestMapForUnit("player") local p=C_Map.GetPlayerMapPosition(m,"player") print(m, p and p:GetXY())
```

- Proves: Normalized x, y position (0 to 1).
- Supported: `85 0.52 0.31` style numbers
- Unsupported: `85` only (no position object) inside instances, or an error if the API changed
- GoldIntel module affected: Map, HeatMapEngine (future)

**D3**

```
/dump C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player"))
```

- Proves: Map metadata table (name, parent, type).
- Supported: `{ mapID=..., name="...", mapType=... }`
- Unsupported: `nil` or error
- GoldIntel module affected: Map (zone naming)

**D4**

```
/run print(GetZoneText(), GetSubZoneText(), GetLocale())
```

- Proves: Zone and subzone text plus locale: the fallback identity if C_Map is missing (Decisions D-008).
- Supported: `Zone  Subzone  enUS` (subzone may be empty outdoors)
- Unsupported: Error: text functions missing (then no location identity at all)
- GoldIntel module affected: Map, Rankings (future)

**D5**

```
/run print(type(WorldMapFrame), type(WorldMapFrame and WorldMapFrame.ScrollContainer))
```

- Proves: Whether the world map frame exists to host a heatmap overlay.
- Supported: `table table`
- Unsupported: `nil nil`: the map UI is load-on-demand or different; overlay must attach later.
- GoldIntel module affected: MapOverlay (future)

## E. C_AuctionHouse

Proves which auction API family exists. Do not call these functions while away from an auction house; only presence is tested.

**E1**

```
/dump type(C_AuctionHouse), type(QueryAuctionItems)
```

- Proves: Modern versus legacy auction API.
- Supported: `"table" "nil"` (modern)
- Unsupported: `"nil" "function"` (Classic-style) or both nil (no scanning API)
- GoldIntel module affected: PricingEngine, Native price provider (Phase 6)

**E2**

```
/run local t={} for k in pairs(C_AuctionHouse) do t[#t+1]=k end table.sort(t) print(#t,table.concat(t," "))
```

- Proves: Every function in the namespace (names to design the scanner against).
- Supported: A count and a sorted list
- Unsupported: Error if the namespace is missing
- GoldIntel module affected: PricingEngine

**E3**

```
/dump type(C_AuctionHouse.ReplicateItems), type(C_AuctionHouse.GetNumReplicateItems), type(C_AuctionHouse.GetReplicateItemInfo), type(C_AuctionHouse.CalculateCommodityDeposit)
```

- Proves: Presence of the bulk-scan and deposit functions (retail names; `nil` for a name only means that name does not exist, trust E2).
- Supported: `"function"` x4 in a retail-style client
- Unsupported: `nil` entries: scan or deposit design must use what E2 lists
- GoldIntel module affected: PricingEngine, AHMath

**E4**

```
/dump type(AuctionHouseFrame)
```

- Proves: Whether the auction UI is already loaded (it is load-on-demand).
- Supported: `"nil"` until you open an auction house, then `"table"`
- Unsupported: n/a
- GoldIntel module affected: AH events (Platform/Auction, Phase 6)

## F. C_Timer

Proves the scheduler backend GoldIntel will choose. Output arrives over time.

**F1**

```
/dump type(C_Timer), type(C_Timer and C_Timer.NewTicker), type(C_Timer and C_Timer.NewTimer), type(C_Timer and C_Timer.After)
```

- Proves: Which timer functions exist.
- Supported: `"table" "function" "function" "function"`
- Unsupported: `"nil"`: GoldIntel uses its OnUpdate backend
- GoldIntel module affected: Scheduler

**F2**

```
/run local t=GetTime() C_Timer.After(1,function() print("After fired",GetTime()-t) end) print("scheduled")
```

- Proves: One-shot timer accuracy.
- Supported: `scheduled`, then about one second later `After fired 1.0x`
- Unsupported: Never fires: timers are broken or restricted
- GoldIntel module affected: Scheduler

**F3**

```
/run local n,tk=0 tk=C_Timer.NewTicker(0.5,function() n=n+1 print("tick",n) if n==3 then tk:Cancel() end end)
```

- Proves: Ticker cadence and cancellation.
- Supported: `tick 1`, `tick 2`, `tick 3` about 0.5 s apart, then nothing
- Unsupported: More than three ticks: Cancel does not work (report!)
- GoldIntel module affected: Scheduler, Map (0.5 s tick)

## G. Unit identity, money, time (read-only)

Proves what Unit.lua, Money.lua and Clock.lua will read.

**G1**

```
/dump UnitGUID("player")
```

- Proves: GUID format and availability (character key, Decisions D-006).
- Supported: `"Player-<number>-<hex>"`
- Unsupported: `nil` (too early) or a different format: report it
- GoldIntel module affected: Unit

**G2**

```
/run local g=UnitGUID("player") print(type(g), g, issecretvalue and issecretvalue(g))
```

- Proves: Whether the GUID is a normal string or a restricted 'secret' value.
- Supported: `string  Player-...  false`
- Unsupported: `true` or an error when used as a table key: Unit must avoid storing it
- GoldIntel module affected: Unit, Store (future)

**G3**

```
/run print(UnitName("player"), UnitClass("player"), UnitLevel("player"), UnitFactionGroup("player"))
```

- Proves: Name, class (localized + token), level, faction.
- Supported: `Name  Mage  MAGE  60 ...` style values
- Unsupported: `nil` fields: Unit returns nils (handled)
- GoldIntel module affected: Unit

**G4**

```
/run print(GetRealmName(), GetNormalizedRealmName())
```

- Proves: Realm behavior (WoW Forever is described as realmless).
- Supported: A fixed or empty realm string
- Unsupported: A normal realm name: key choice still GUID
- GoldIntel module affected: Unit, price scope (future)

**G5**

```
/run print(GetMoney(), issecretvalue and issecretvalue(GetMoney()))
```

- Proves: Money read (copper) and whether it is a secret value.
- Supported: `<copper>  false`
- Unsupported: `true`: Money.lua arithmetic would break; report immediately
- GoldIntel module affected: Money

**G6**

```
/run print(time(), GetTime())
```

- Proves: Wall clock and monotonic clock.
- Supported: Unix seconds and a fractional uptime
- Unsupported: nil: Clock degrades
- GoldIntel module affected: Clock

## H. Slash command registration

Proves runtime slash registration works. Registers a throwaway command for this session only.

**H1**

```
/run SLASH_GITEST1="/gitest" SlashCmdList.GITEST=function(m) print("gitest ok",m) end print("registered")
```

- Proves: That slash commands can be registered from Lua.
- Supported: `registered`
- Unsupported: Error: SlashCmdList is missing or protected
- GoldIntel module affected: Probe (/gi), Core/Slash (Phase 2)

**H2**

```
/gitest hello
```

- Proves: That the registered command runs (run after H1).
- Supported: `gitest ok hello`
- Unsupported: `Unknown command` or nothing: registration is not honored
- GoldIntel module affected: Probe, Core/Slash

**H3**

```
/dump SlashCmdList.GOLDINTEL ~= nil
```

- Proves: Whether GoldIntel's own `/gi` handler registered (only if GoldIntel loaded).
- Supported: `true`
- Unsupported: `false`: GoldIntel's files did not run
- GoldIntel module affected: Probe

## I. Event names and registration

**IMPORTANT (changed in v0.1.2, Decisions D-025):** the earlier commands in this section REGISTERED events, including `COMBAT_LOG_EVENT_UNFILTERED`. Registering a restricted event as an insecure addon is blocked by the client with an `ADDON_ACTION_FORBIDDEN` popup, and `pcall` cannot hide that. That is the failure class Probe.lua hit (the report did not name the event; the combat-log event is the prime suspect but is not proven). The commands below only CHECK NAMES with `C_EventUtils.IsEventValid`, which never registers anything. A valid name does not prove registration is allowed; I6 tests one event at a time, opt-in.

**I1**

```
/run for _,e in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEAVING_WORLD","PLAYER_LOGOUT","PLAYER_MONEY","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}) do print(e,C_EventUtils.IsEventValid(e)) end
```

- Proves: Lifecycle, money and combat-state event names exist (money is fatal if missing).
- Supported: Seven lines ending `true`
- Unsupported: `false` for a name: that event does not exist in this client. `nil`/error `C_EventUtils` is missing: use I6.
- GoldIntel module affected: Events, Money (FATAL)

**I2**

```
/run for _,e in ipairs({"PLAYER_LEVEL_UP","SKILL_LINES_CHANGED","ZONE_CHANGED","ZONE_CHANGED_INDOORS","ZONE_CHANGED_NEW_AREA"}) do print(e,C_EventUtils.IsEventValid(e)) end
```

- Proves: Level, skill and zone event names. SKILL_LINES_CHANGED is Classic-era and may legitimately be `false` in a modern client (GoldIntel then skips it).
- Supported: `true` for the level and zone events; skills may be `false`
- Unsupported: `false` for zone events would disable P_ZONE
- GoldIntel module affected: Events, Unit, Map

**I3**

```
/run for _,e in ipairs({"COMBAT_LOG_EVENT_UNFILTERED","UNIT_SPELLCAST_SUCCEEDED","LOOT_OPENED","LOOT_SLOT_CLEARED","CHAT_MSG_MONEY","QUEST_TURNED_IN"}) do print(e,C_EventUtils.IsEventValid(e)) end
```

- Proves: Combat-log, spell, loot and quest event NAMES (no registration). `true` for COMBAT_LOG_EVENT_UNFILTERED only means the name exists, not that addons may register it.
- Supported: Six lines `true`
- Unsupported: `false`: that name is not valid in this client
- GoldIntel module affected: Collector (Phase 3), Probe (combat log is never registered by GoldIntel)

**I4**

```
/run for _,e in ipairs({"MERCHANT_SHOW","MERCHANT_CLOSED","MAIL_SHOW","MAIL_CLOSED","MAIL_INBOX_UPDATE","TRADE_SHOW","TRADE_CLOSED","TRADE_MONEY_CHANGED"}) do print(e,C_EventUtils.IsEventValid(e)) end
```

- Proves: Vendor, mail and trade event names.
- Supported: Eight lines `true`
- Unsupported: `false` lines: that source cannot be tracked by that event
- GoldIntel module affected: Collector (Phase 3)

**I5**

```
/run for _,e in ipairs({"AUCTION_HOUSE_SHOW","AUCTION_HOUSE_CLOSED","TRADE_ACCEPT_UPDATE","GIDIAG_NOT_A_REAL_EVENT"}) do print(e,C_EventUtils.IsEventValid(e)) end
```

- Proves: Auction event names, plus a deliberately fake name as a sanity check (must be `false`).
- Supported: First three `true`, last `false`
- Unsupported: Last line `true`: the validity API is unreliable here; use I6
- GoldIntel module affected: Collector (Phase 6), Events

**I6 (OPT-IN)**

```
/run local w=CreateFrame("Frame") w:RegisterEvent("ADDON_ACTION_FORBIDDEN") w:SetScript("OnEvent",function(_,_,a,f) print("FORBIDDEN",a,f) end) local f=CreateFrame("Frame") f:RegisterEvent("PLAYER_MONEY") print(f:IsEventRegistered("PLAYER_MONEY"))
```

- Proves: Registers ONE event (replace PLAYER_MONEY in the command, or use `/gidiag reg NAME` in GoldIntelDiag). WARNING: for a restricted event this shows a blocked-action popup, which is the point: the popup and the printed `FORBIDDEN <addon> <function>` identify it. Nothing on the character changes.
- Supported: `true` and no `FORBIDDEN` line: registration is allowed
- Unsupported: `false` plus a `FORBIDDEN ... Frame:RegisterEvent` line (or a popup): the event is RESTRICTED. Report its name; GoldIntel will add it to the never-register list.
- GoldIntel module affected: Events (Bind), Platform.RESTRICTED_EVENTS

**I7**

```
/etrace
```

- Proves: Opens Blizzard's event trace window to watch real events live (close it with its X).
- Supported: A window listing events as they fire
- Unsupported: Command unknown: use I1-I5 only
- GoldIntel module affected: observation aid

## J. SavedVariables

Needs the GIMin addon (below). SavedVariables are restored AFTER an addon's files run and BEFORE `ADDON_LOADED`, so initialization must happen in the `ADDON_LOADED` handler.

**J1**

```
/gimin
```

- Proves: GIMin prints saved-variable state, namespace sharing, slash and event results in one go.
- Supported: `saved vars: at file load = nil, at ADDON_LOADED = nil (first run), total loads = 1`
- Unsupported: `total loads` stays 1 after `/reload`: SavedVariables are not persisting
- GoldIntel module affected: Store (Phase 2), Probe.Persist

**J2**

```
/reload  then  /gimin
```

- Proves: Persistence across a reload.
- Supported: `total loads = 2`, `at ADDON_LOADED = table`
- Unsupported: `total loads = 1` again
- GoldIntel module affected: Store, Probe.Persist

**J3**

```
/dump GoldIntelDB and GoldIntelDB.compat and GoldIntelDB.compat.build
```

- Proves: Whether GoldIntel's Probe persisted its results (only if GoldIntel loaded; needs a logout or reload to appear in the file on disk).
- Supported: The client build string
- Unsupported: `nil`: Probe did not run
- GoldIntel module affected: Probe.Persist

## K. Differences from the Classic-era assumptions GoldIntel Phase 1 was written with

| Topic | Classic-era assumption in v0.1.0 | Likely 12.0-based reality (to verify with the commands above) | Status in code |
|---|---|---|---|
| Interface number | 11508 | 16001 (confirmed by your in-client test) | TOC updated |
| Professions | skill-lines API with localized headers | `GetProfessions()` style API | Unit.lua already tries GetProfessions first |
| Auction scanning | `QueryAuctionItems` | `C_AuctionHouse` (replicate/commodity calls) | Probe detects both; adapters are Phase 6 |
| Combat log | `COMBAT_LOG_EVENT_UNFILTERED` available | restricted for addons (consistent with the observed popup; the event name was not shown, so not proven) | Never registered; Phase 3 kill detection needs a different signal |
| Restricted ('secret') values | do not exist | exist in 12.0 (verify A8, G2, G5) | Money/Unit/Map read values defensively but do not test `issecretvalue` yet |
| Addon metadata API | `GetAddOnMetadata` | `C_AddOns.GetAddOnMetadata` | Not used in Phase 1 |
| Restricted event registration | not restricted | `COMBAT_LOG_EVENT_UNFILTERED` and possibly others are blocked for addons with ADDON_ACTION_FORBIDDEN (observed: Probe.lua tripped it) | GoldIntel never registers it; names are checked with C_EventUtils.IsEventValid (D-025) |
| Load error text | file and line | log shows only 'Error loading' (observed) | Use step 0.1 to get the real message |

Total commands in this document: 51.
