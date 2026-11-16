# GoldIntel

A gold analytics add-on for **WoW: Forever** (live since 2026-11-04; client 1.60.1, Interface 16001). It records where
every copper comes from, with which activity and at which place, so you can see where you earn the most gold per hour.

**Status:** in development, used in live play. Main holds 0.5.6-passive. Phase 4 (live totals per place and activity,
time classes, the /reload reminder) is in live testing as 0.6.x on an open pull request. Not a finished release.

## What it does
- **Cash ledger:** every copper change is attributed to a source (loot, vendor, quest, mail, trade, auction, trainer)
  with a confidence, an activity and a place. `/gi ledger check` proves that the ledger and the real balance agree to
  the copper.
- **Item lots:** looted and quest items are valued (vendor price, optional manual price) and followed to the vendor
  sale, so value created and value converted are both known. It is an economic ledger, not an inventory mirror.
- **Live totals (0.6.x):** gold and item value per place, activity and level bracket; active, idle, travel and paused
  time; a heat grid per map; `/gi agg top` ranks places by gold per hour.
- **Reload reminder (0.6.x):** a popup every n minutes (never in combat or a boss fight) so a client crash loses little;
  `/gi settings` sets the interval.
- Recording starts by itself a few seconds after login. `/gi collect off` stops it for the session;
  `/gi config set collect.auto false` turns the automatic start off.
- It works on its own; other add-ons are not needed.

## Install
Copy the `GoldIntel` folder from the release zip into `World of Warcraft/_forever_/Interface/AddOns/`. A first install
needs a full client restart (the game lists add-on folders at startup); an update needs only `/reload`. `GIMin`, `GoldIntelDiag` and `GIProbeLoot` are development tools; leave them out.

## Commands (short list)
`/gi collect on|off`, `/gi ledger status|mark|check|last|trace`, `/gi lots status|last|sales|unknown|check|reset confirm`,
`/gi price set|list|clear`, `/gi agg status|check|top`, `/gi pause|resume|afk`, `/gi activity`, `/gi settings`,
`/gi config`, `/gi perf`, `/gi probe`, `/gi version`, `/gi help`. (`/gi agg`, the time commands and `/gi settings`
need 0.6.x.)

## Layout
- `GoldIntel/` the add-on (`Platform/`, `Core/`, `Store/`, `Collect/`, `Ledger/`, `Aggregate/`) and its tests
  (`GoldIntel/Tests`; run `lua5.4 run.lua` from that folder).
- `GoldIntel_Docs/` project documents: start with `Project_Bible.md`; finished-phase records are in `archive/`.
- `tools/build_package.py` builds and verifies the AddOns zip.

## Reporting a problem
Include `/gi version` and the output of `/gi lots status`. When GoldIntel prints "UNEXPECTED item condition: ... please
report it as a bug", paste that line exactly.

Licensed under the MIT License (see `LICENSE`).
