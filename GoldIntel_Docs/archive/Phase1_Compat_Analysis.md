# Phase 1 Compatibility Analysis: "Error loading" of every Platform file

DOC VERSION: 1.0.0  |  DATE: 2026-10-09  |  Session S-003  |  Scope: Phase 1 compatibility fix only. No new functionality. Phase 2 not started.

## ADDENDUM (session S-004): what actually happened, and what I got wrong

**Resolved by the user's in-client result:** the original "Error loading" was caused by **folder structure**. That was cause #1 in section 5, but I framed it as a possible problem on your side. The real error was mine:

- I delivered the addons as **individual file cards**, not as a package, so you had to rebuild the folder tree by hand. Files in subfolders (`Platform/`, `Sub/`) are exactly the ones that go wrong that way.
- The same delivery gap happened again: `GIMin/Sub/Back.lua`, `Fwd.lua`, `Block.lua` and `GoldIntelDiag/SrcV010.lua`, `SrcV011.lua` were **never presented at all**, so the TOC-listed files did not exist on your machine. (The `GIMin` error you saw was therefore correct behavior of a correctly written TOC, not a TOC defect.)
- In S-003 I also presented only the new TOC, not the patched Platform files, so a v0.1.1 TOC may have sat next to v0.1.0 Lua files.

**What was wrong in my S-003 analysis:** it concluded the cause was unproven and shipped a defensive code patch (comment style, TOC cleanup) plus a large diagnostic package. The code patch was unnecessary for the original failure (harmless, now kept as hygiene rules D-024). The right move was to say first, plainly, "my delivery may be the cause: here is a zip", and to check my own delivery against the TOC. My mistake, not yours.

**New failure, and its cause (v0.1.2):** `ADDON_ACTION_FORBIDDEN ... Frame:RegisterEvent()` from `Probe.lua`.
- `Probe.lua` probed event availability by calling `RegisterEvent` on a throwaway frame for 29 event names and relying on `pcall` to catch failures. That design is not legal in a modern client: registering a **restricted** event as an insecure addon is blocked by the client with a popup (`ADDON_ACTION_FORBIDDEN`), and `pcall` cannot suppress it. The report did not name the event. Narrowing (added in S-005): 12 of those 29 are exactly the events v0.1.2 registers without a reported popup, so the culprit is one of the other 17: AUCTION_HOUSE_CLOSED, AUCTION_HOUSE_SHOW, CHAT_MSG_MONEY, COMBAT_LOG_EVENT_UNFILTERED, LOOT_OPENED, LOOT_SLOT_CLEARED, MAIL_CLOSED, MAIL_INBOX_UPDATE, MAIL_SHOW, MERCHANT_CLOSED, MERCHANT_SHOW, QUEST_TURNED_IN, TRADE_ACCEPT_UPDATE, TRADE_CLOSED, TRADE_MONEY_CHANGED, TRADE_SHOW, UNIT_SPELLCAST_SUCCEEDED. The combat-log event is only one candidate among them. The combat-log event (`COMBAT_LOG_EVENT_UNFILTERED`) was in the probe list and is the prime suspect, but that is not proven. I wrote a note in the diagnostics ("may be restricted, verify") and then still shipped a probe, and a diagnostic command, that registered it. That was avoidable.
- **Fix:** nothing probes by registering any more. Event names are checked with `C_EventUtils.IsEventValid` (never registers); restricted events are on a never-register list and `Events.Bind` refuses them; only `Events.lua` may call `RegisterEvent` (test C-6); an exact allowlist of the 12 events Phase 1 registers is asserted by a test. The same fix is applied to GoldIntelDiag and to the copy/paste commands.
- **Honest limit:** the 12 events GoldIntel really registers have never been confirmed non-restricted in the real client. If the popup recurs, `/gi status` now shows `lastRegister=<event>`, which names the culprit, and `/gidiag reg NAME` tests one event at a time.

## 1. Honest summary

- **The root cause is not yet proven.** I could not reproduce the failure: I have no Forever client, and no Lua 5.1 interpreter in my environment (tests ran on Lua 5.3).
- A static audit of everything in the request found **no code-level construct that Lua 5.1 or a 12.0 client should reject**. The evidence points more strongly to a **file-level problem** (path, delivery, integrity, TOC) than to Lua syntax or API differences. That is a judgment, not a measurement.
- I made a **defensive compatibility patch (v0.1.1)** that removes every plausible code-side trigger at zero functional cost, and built tools that will turn the guesswork into facts in about five minutes:
  - **GoldIntelDiag**: lets the client's own compiler compile the old and new sources and print the real error text.
  - **GIMin**: the smallest addon that checks TOC path styles, namespace passing, SavedVariables, slash commands and events.
  - **Phase1_Client_Diagnostics.md**: 45 copy/paste commands by subsystem.

## 2. What the evidence says

| # | Evidence | What it implies |
|---|---|---|
| E1 | All 8 files report `Error loading`, including `Clock.lua` and `Platform.lua`. | A cause common to all files, or a cause independent of file content. |
| E2 | `Platform.lua` and `Clock.lua` run no WoW API at top level (only table and function definitions). | A missing or changed WoW API **cannot** produce "Error loading" for them. API incompatibility is ruled out for this symptom. |
| E3 | A trivial `print("test")` addon loads. | Addon loading, Interface 16001 and flat file loading work. |
| E4 | No stack trace, no line number, no Lua message in the log. | Typical of a file that could not be opened/read, or of a failure the log abbreviates. A compile error normally carries `file:line: message`. (I am not certain how this client words each case; step 0.1 below settles it.) |
| E5 | The log cites TOC lines **18 to 25** for the files. The TOC I delivered has them on lines **20 to 27**. | The TOC on your machine is **not byte-identical** to the one delivered (two fewer lines before the file list). The deployed tree may differ from the delivered package in other ways too. |
| E6 | The delivered files are pure ASCII, LF only, no BOM, and compile under Lua 5.3. | No encoding problem existed in the delivered files. |

## 3. Audit of every item requested

| Area | Result | How verified |
|---|---|---|
| Lua syntax incompatible with the client | None found | Compiled with Lua 5.3; grep for 5.1-only hazards below |
| Lua 5.1 vs newer differences | None found. Checked: nested `[[` in long comments (error in 5.1, legal in 5.3, **the one class my 5.3 tests could not catch**), `break` not last in a block, lines starting with `(` (ambiguous call), stray `;`, `goto`/labels, `//`, bitwise operators, `<const>`, `\x` escapes, `table.unpack`, `unpack`, `...` outside vararg functions | Python lexer emulating 5.1 long-bracket rules; grep; 5.1 limits via bytecode listing (max 10 upvalues per function vs limit 60; max 34 locals vs limit 200) |
| Invalid file encodings | None: ASCII only, LF, no BOM, ends with newline | byte scan, now a permanent test (rule C-2) |
| Unsupported language constructs | None | as above |
| TOC loading issues | **Possible.** Delivered TOC used `\` separators and 9 comment lines; deployed TOC differs (E5). Now: forward slashes, no comments, minimal fields | rule C-4; GIMin tests both separator styles |
| File-level parsing failures | Unknown until step 0.1 | GoldIntelDiag `/gidiag compile` |
| `local ADDON, GI = ...` | Valid: the client passes (addonName, privateTable) to every file's main chunk. Runtime-level, so it could not cause "Error loading" anyway | GIMin prints the types received and shares one table across files |
| Assumptions valid in the test runner but not in WoW | See section 4 | |

## 4. Assumptions that were valid in my test runner but unproven in WoW

1. **Tests ran on Lua 5.3, not 5.1.** 5.3 accepts nested long brackets, `break` mid-block and ambiguous call lines, so passing tests proved nothing about those. (Audited separately; none present.)
2. **The fake client mirrors my beliefs** about the API (Classic-era names). It cannot disprove them.
3. **`P.env = P.env or _G`**: fine in WoW, but the whole design depends on `_G` being the real global table.
4. **`loadfile` with explicit arguments** in tests versus the client's own file loader.
5. **TOC parsed by my loader** (accepts `\`, comments, blank lines) versus the client's parser (stricter or different, unknown).
6. **Saved variables timing**: the client restores them after an addon's files run and before `ADDON_LOADED`. Probe reads `GoldIntelDB` at `PLAYER_LOGIN`, which is safe; GIMin verifies the ordering.

## 5. Probable causes, ranked

Probabilities are my judgment from the evidence above, to be replaced by facts from the diagnostics.

| Rank | Cause | Est. | Why | Decisive test |
|---|---|---|---|---|
| 1 | **Deployment or path problem** (files missing from `Platform/`, extra nesting such as `GoldIntel/GoldIntel/Platform`, wrong case, stale or hand-edited TOC) | 35% | E1, E2, E4, E5 | Folder listing against the tree in section 7; `GetAddOnInfo` reason (B3) |
| 2 | **Files altered or damaged in transit** (text copied from a rendered view, smart punctuation replacing `--`, truncation, encoding conversion, security software) | 25% | E5 shows the deployment was edited; every header started with `--[[` | Hash check against MANIFEST.txt; `/gidiag compile` shows embedded (intact) copies compile |
| 3 | **A construct only the 12.0 client's compiler rejects** that my audit cannot see | 15% | Cannot execute 5.1 or the real compiler here | `/gidiag compile` v0.1.0 FAIL with a message |
| 4 | **TOC parsing quirk** (backslashes, `#` comment lines, unusual fields) | 10% | Delivered TOC was unusual; E5 | GIMin `back` / `fwd` / `block` flags; patched TOC is minimal |
| 5 | **Client security or naming policy** rejecting these paths | 5% | Unknown | `GetAddOnInfo` reason; script errors popup |
| 6 | Unknown / other | 10% | | |

**Ruled out for this symptom:** missing WoW APIs (E2); the `local ADDON, GI = ...` line (runtime-level, and provided by the client); namespace sharing; saved-variable timing.

## 6. Code changes made (v0.1.1, no functional change)

| Change | Files | Rationale | Risk |
|---|---|---|---|
| `## Interface: 16001` | GoldIntel.toc | Your in-client result | none |
| TOC: forward slashes, all `#` comment lines removed, only 6 standard fields, no `OptionalDeps`, no custom `X-` field | GoldIntel.toc | Eliminates TOC parsing quirks (cause 4); the TOC now cannot differ by comment lines | none; libs are not bundled anyway |
| Header `--[[ ... ]]` blocks converted to `--` line comments in all 8 files; no long bracket of any kind remains | Platform/*.lua | Eliminates the 5.1 nested-bracket hazard class and any tooling that mangles block comments (causes 2 and 3) | none (comments only) |
| `P.VERSION` set to `0.1.1-phase1-compat` | Platform.lua | Lets you tell old from new files (`GetAddOnMetadata` version, `/gi probe`) | none |
| New permanent tests C-1..C-5 (ASCII/LF/BOM, no long brackets, TOC minimal/forward slashes/Interface 16001, namespace line first) | Tests/test_platform_boundary.lua | Prevents regressions; 227 tests pass; each rule was proven to fail when violated | none |

**Not changed:** all logic, contracts (still 1.1), event model, module interfaces. No Phase 2 work. No new GoldIntel functionality.

## 7. Expected install layout

```
Interface/AddOns/GoldIntel/
  GoldIntel.toc
  Platform/
    Platform.lua  Clock.lua  Events.lua  Scheduler.lua
    Unit.lua  Map.lua  Money.lua  Probe.lua
```
Copy the **folder**, never paste file contents. The `Tests/` folder is not needed in the game directory. Delete the old GoldIntel folder completely before copying v0.1.1.

## 8. Decision tree (about five minutes)

1. Install **GoldIntelDiag**. Run `/gidiag compile`.
   - v0.1.0 FAIL, v0.1.1 OK: the patch fixes it. Deploy v0.1.1.
   - FAIL on both: the error text names the line and construct. Send it; that is the real cause.
   - OK on both: the sources are fine in this client. Go to 2.
2. Hash your files on disk against `GoldIntelDiag/MANIFEST.txt`.
   - Mismatch: files were altered or damaged. Recopy the delivered folder as a whole.
   - Match: go to 3.
3. Compare your folder listing to section 7, then run B3 (`GetAddOnInfo`) and read `reason`. Then install **GIMin** and run `/gimin`: `back`/`fwd`/`block` isolate TOC path style and block-comment headers.
4. If `/gidiag compile` is OK and the hashes match yet GoldIntel still shows "Error loading", send: the exact TOC text, the folder listing, the B3 output, and the FrameXML.log lines. That combination would point at cause 4 or 5 and I would address it specifically.

## 9. Known unknowns after this patch

- The real cause remains unconfirmed until one of the diagnostic steps runs.
- Runtime behavior of every WoW API Phase 1 touches in the 12.0 client is still unverified (use `/gidiag run` and `/gidiag all`).
- Items worth checking early because they affect later phases: combat-log event availability (I3), unknown-event registration behavior (I5), secret values on money and GUID (A8, G2, G5), auction API shape (E2).
