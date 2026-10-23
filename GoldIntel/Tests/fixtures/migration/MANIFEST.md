# Migration fixtures (schema 1 files written by the real addon 0.3.1 in the WoW Forever client)

Real SavedVariables files from the user's live validation, copies of `GoldIntel_Docs/evidence/` (never edited). They are the schema 1 inputs of the 1 -> 2 migration tests (D-077 Q-7: "the E-43 file remains part of the migration validation set").

| File | Evidence | What it is |
|---|---|---|
| E-43_GoldIntelDB_round2_schema1.lua | E-43 (2026-10-18o) | GoldIntelDB after 3b-1 round 2 (loot revalidation), schema 1 |
| E-45_GoldIntelDB_round3_schema1.lua | E-45 (2026-10-18q) | GoldIntelDB after 3b-1 round 3 (mail, quest, trade, auction), schema 1 |
| E-44_GoldIntelCharDB_schema1.lua | E-44 (2026-10-18p) | GoldIntelCharDB of Rehgar-Deadeye, schema 1 |
| E-45_GoldIntelCharDB_round3_schema1.lua | E-45 (2026-10-18r) | GoldIntelCharDB of Rehgar-Deadeye after round 3 (collect journal and lastStats), schema 1 |

The Phase 1 file `../forever_1.60.1_GoldIntelDB.lua` (schema 0) stays the 0 -> 2 fixture. A missing file FAILS the suite.
