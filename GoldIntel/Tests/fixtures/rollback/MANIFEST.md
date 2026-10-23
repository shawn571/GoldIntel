# Rollback fixtures

`store_0.3.1.lua` and `migrations_0.3.1.lua` are the Store and Migrations sources of the released 3b-1 package (addon 0.3.1-phase3b1, schema 1). Tests load them in place of the current files to prove what a rollback to 0.3.1 does to schema 2 data: it must open it READ-ONLY and leave it untouched (Store rule, D-036). Never edited.
