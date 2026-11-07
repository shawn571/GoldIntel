# GoldIntel

A gold analytics addon for **WoW Forever** (client 1.60.1, Interface 16001). It records where gold comes from, with
which repeatable activity and at which location, so a player can later see where the most gold per hour is earned.

**Status:** under development (Phase 3b-3: item lots; build 0.5.5-passive for passive play). It is not a finished release.

## What it does today
- **Cash ledger:** every copper change is attributed to a source (loot, vendor, quest, mail, trade, auction) with a
  confidence, activity and location stamp. `/gi ledger check` proves the ledger and the real balance agree (0 copper).
- **Item lots:** looted and quest items are valued (vendor price; optional manual override) and followed to the vendor
  sale, so value created and value converted are both known. It is an economic ledger, not an inventory mirror.
- Recording starts by itself about 3 seconds after login (one chat line says so). `/gi collect off` stops it for the
  session; `/gi config set collect.auto false` turns the automatic start off. Every interval starts marked, so
  `/gi ledger check` works at any time.

## Install
Copy the `GoldIntel` folder into the WoW Forever AddOns folder (`World of Warcraft/_forever_/Interface/AddOns/`) and
restart the client. `GIMin`, `GoldIntelDiag` and `GIProbeLoot` are diagnostic tools used during development; leave them out.

## Commands (short list)
`/gi collect on|off`, `/gi ledger status|mark|check|last|trace`, `/gi lots status|last|sales|unknown|check|reset confirm`,
`/gi price set|list|clear`, `/gi config`, `/gi perf`, `/gi version`, `/gi help`.

## Layout
- `GoldIntel/` the addon (`Platform/`, `Collect/`, `Ledger/`, `Core/`, `Store/`) and its tests (`GoldIntel/Tests`, run with `texlua run.lua` from that folder).
- `GoldIntel_Docs/` requirements, decisions, contracts, architecture, changelog, session handoffs.
- `tools/build_package.py` builds and verifies the AddOns zip.

## Reporting a problem
Open an issue with the template. Include `/gi version` and the output of `/gi lots status`.
When GoldIntel prints "UNEXPECTED item condition: ... please report it as a bug", that message is exactly what to paste.

Licensed under the MIT License (see `LICENSE`).
