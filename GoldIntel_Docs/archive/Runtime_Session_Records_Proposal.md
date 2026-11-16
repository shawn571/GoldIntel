# Proposal: preserving current and previous runtime session records

DOC VERSION: 1.0.0  |  DATE: 2026-10-17  |  AUTHOR: Claude (S-011)  |  STATUS: APPROVED by the user on 2026-10-17 (sections 3.1 to 3.4 and the pin) and IMPLEMENTED in rebuild 4. User constraint: diagnostic evidence only, bounded (current, previous, short history, pinned on request), never permanent retention of raw events. Implementation note: a rotation failure loses only the previous record (section 6 originally said the old record is kept; that was inaccurate because the current fields are rewritten right after); `Records()` also rotates so `/gi caps previous` works right after login; the field `endedBy` uses 'logout-or-reload' because the two cannot be told apart.

## 1. Problem

`GoldIntelDB.runtime` holds the evidence of the current session: capability stages, event counters, the last 100 lines GoldIntel printed (D-040). It is replaced at every open. On 2026-10-17 the user ran a long test session, typed `/reload` for the settings test, and the saved file then described only the 2-minute session after the reload. The long session survived only because the user pasted chat text [file: evidence/2026-10-17b_*; chat].

Cause: `Capabilities.Persist()` writes into the same `runtime` table that the client loaded from disk at login, so the first persist of the new session overwrites the previous session's record.

## 2. Requirements (from the user's decision)

- R1 Keep the current session's record. (exists)
- R2 Keep the previous session's record.
- R3 Stay small and bounded; never threaten the gold data or `compat`.
- R4 No change to what Core/Store do with real data; evidence tooling only.

## 3. Proposed design

### 3.1 Shape

```
GoldIntelDB.runtime = {
  -- CURRENT session (exactly as today, plus two fields)
  addonVersion, generatedAt, generatedGT,
  sessionStart,            -- NEW: time() at this open
  capabilities, eventStats, output, outputTotal,

  previous = {             -- NEW: the record that was "current" when this session opened
    sessionStart, generatedAt, generatedGT, addonVersion, build,
    durationSec,           -- generatedAt - sessionStart (0 if unknown)
    eventStats, output, outputTotal,
    capDigest,             -- compact: one string "name=level;..." instead of the full tables
    endedBy,               -- 'logout' | 'reload' | 'unknown' (see 3.4)
  },

  history = {              -- NEW: ring of the last 10 one-line summaries (oldest first)
    { sessionStart, durationSec, build, addonVersion, store, diag, delivered = {name=count,...} },
  },
}
```

"Current" keeps its present field names, so Contracts F-runtime readers and the existing tests stay valid.

### 3.2 Rotation rule (the whole change)

At the first persist of a session (or at `Capabilities.Attach` after Store open, before any persist):

1. Read the loaded `runtime`. If it has `generatedAt` (a real record), then:
   - build `previous` from it (capabilities compacted to `capDigest`);
   - push one summary into `history`, drop entries beyond 10.
2. Clear the current fields, set `sessionStart = time()`, and continue as today.

Rotation happens exactly once per open, before the first overwrite. If the loaded record is empty or has no `generatedAt` (fresh install, first Phase 2 open), nothing rotates.

### 3.3 Size budget

Measured today [file]: `runtime` is about 4.2 KB (with 11 output lines) and grows to roughly 8 to 10 KB with 100 output lines [estimated]. Adding `previous` (output kept, capabilities compacted to a digest of about 1 KB) and ten history rows (about 0.3 KB each) gives roughly 15 KB total [estimated]. Hard cap: if serialized size of `previous` exceeds 12 KB, trim its `output` from the oldest end. The prune budget (2 MB) and `Pruner` never touch `runtime`.

### 3.4 `endedBy`

`PLAYER_LOGOUT` fires on both logout and `/reload`, so `endedBy` cannot be told apart from inside the saved record at the time (and a crash writes nothing). Proposal: do not guess. Store `'logout'` only when the last persist was triggered by the logout handler (`generatedGT` equals the logout event time), else `'unknown'`. A crashed session simply never rotates in: the next open sees the last good record, which is the correct behaviour.

### 3.5 Optional extension (decision for the user): pin

`/gi checkpoint pin` copies the current record to `runtime.pinned` once. A pinned record survives any number of reloads until replaced or cleared (`/gi checkpoint unpin`). It solves "my long test session is then pushed out by two quick reloads" without enlarging the ring. Cost: about 5 more KB and one command. Recommended: yes, but only if you want it; the base design works without it.

### 3.6 What the user will see

- `/gi db` gains one line: `runtime: current <n> lines, previous <n> lines (ended <time>), history <n>`.
- `/gi caps events previous` prints the stage table from `previous` (read-only). Nothing else changes.

## 4. Affected modules and files

- `Core/Capabilities.lua`: rotation inside `Attach`/first `Persist`, compaction helper.
- `Core/Slash.lua`: `db` line, `caps events previous`, optional `checkpoint pin|unpin`.
- `Contracts.md` 1.4 to 1.5: `runtime` shape (current, previous, history, optional pinned).
- Store/Migrations: NONE. `runtime` is an evidence section that is replaced on open (D-036); the `compat` guarantee and schema version 1 are untouched. If the user prefers strictness, a schema bump is possible but not recommended.
- Docs: Decisions D-041, Changelog, TODO, Handoff, Risk_Register (R-21 note).

## 5. Test plan (to write with the code)

1. First open with no record: no `previous`, no `history`.
2. Second open: `previous` equals the first session's `eventStats` and `output`; `history` has 1 row.
3. Third open: `previous` is the second session; the first is only a history row.
4. Ring bound: after 15 opens `history` has exactly 10 rows, oldest dropped.
5. Size bound: a 100-line output keeps `previous` under the cap; trimming drops oldest lines first.
6. Serializability: whole `runtime` passes the existing saved-variable serializability test.
7. `compat` is deep-equal before and after rotation (existing guarantee test, extended).
8. Read-only and degraded Store: no rotation, no writes, no error.
9. `/reload` round trip in `svsim`: the long session is `previous` after one reload, and a `pin` survives two reloads.
10. Mutation check: removing the rotation (writing straight over `runtime`) makes tests 2 and 3 fail.

## 6. Risks

- Reload spam still pushes a useful session out of `previous` after two quick reloads. Mitigation: history rows keep the numbers; pin (3.5) keeps the full record.
- A bug here could corrupt `runtime`. Mitigation: rotation works on a deep copy and is wrapped so that failure leaves the old record untouched and reports a diagnostic; `runtime` holds nothing the addon depends on.
- File growth. Mitigation: hard caps in 3.3.

## 7. Decision text

**D-041 Preserve the previous runtime session record | Principle: APPROVED by the user 2026-10-17; design: PROPOSED.**
Why: `/reload` overwrote the record of the session before it (R-21 evidence loss). Rule: at each open, the loaded `runtime` becomes `runtime.previous` (compacted, bounded) and a one-line summary is appended to a ten-row `history`. Pin is optional. Affected: Capabilities, Slash, Contracts F-runtime. Migration: none.

## 8. Approval requested

- Approve the design in sections 3.1 to 3.4 (yes / change).
- Pin (3.5): yes / no.
- Then I implement it as a Phase 2 maintenance change (0.2.0-phase2 rebuild 4), with tests, rebuilt packages and updated documents. Nothing is implemented before you answer.
