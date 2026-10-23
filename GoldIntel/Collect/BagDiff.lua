-- GoldIntel / Collect / BagDiff.lua                               (Phase 3b-3 M1, Architecture AC-14, AC-16)
--
-- PURPOSE
--  Turns two carried-inventory snapshots into a diff aggregated PER ITEM ID (R-34: a stack split or merge nets
--  to zero). Pure: no Platform calls, no clock, no storage. The caller (M2) supplies snapshots.
--
--  Snapshot = { items = { [itemID] = quantity }, complete = true }
--      Only `complete == true` snapshots are ever compared. A snapshot with any unreadable (secret) slot is
--      incomplete and is REFUSED; the baseline stays where it was and the next complete snapshot absorbs the change.
--
--      BagDiff.Compute(prev, now)  -> { added = {[id]=qty}, removed = {[id]=qty}, n = changed ids } | nil, reason
--      BagDiff.Fingerprint(items)  -> number (order independent checksum)
--      local T = BagDiff.New()
--      T:Settle(snap)  -> diff | nil, reason       reasons: 'incomplete' | 'baseline' | 'empty'
--                         diff = { seq, from, to, added, removed, n }; becomes PENDING (not applied)
--      T:Commit(seq)   -> true | nil, err          the baseline advances ONLY here, after the caller processed the diff
--      T:Baseline()    -> copy of the committed baseline items | nil
--      T:Stats()       -> { settles, skipped, empty, diffs, committed, baselines, rejected }
--
-- Invariant I-4 (applied at most once): a diff can be committed once; a second Commit of the same seq, a Commit
-- of a superseded diff, and a repeated identical settle all change nothing.

local ADDON, GI = ...
GI = GI or {}

local B = {}
GI.BagDiff = B

local MODULUS = 2147483629

local function isCount(n) return type(n) == 'number' and n > 0 and n == math.floor(n) and n < 2 ^ 31 end

--- True when `snap` is a usable snapshot: complete == true and every entry a positive integer id and quantity.
local function usable(snap)
  if type(snap) ~= 'table' or snap.complete ~= true or type(snap.items) ~= 'table' then return false end
  for id, qty in pairs(snap.items) do
    if not isCount(id) or not isCount(qty) then return false end
  end
  return true
end
B.Usable = usable

function B.Fingerprint(items)
  local ids = {}
  for id in pairs(items) do ids[#ids + 1] = id end
  table.sort(ids)
  local h = 7
  for _, id in ipairs(ids) do
    h = (h * 31 + id) % MODULUS
    h = (h * 31 + items[id]) % MODULUS
  end
  return h
end

local function copyItems(items)
  local c = {}
  for id, q in pairs(items) do c[id] = q end
  return c
end

function B.Compute(prev, now)
  if not usable(prev) then return nil, 'previous snapshot unusable' end
  if not usable(now) then return nil, 'snapshot unusable' end
  local added, removed, n = {}, {}, 0
  for id, q in pairs(now.items) do
    local p = prev.items[id] or 0
    if q > p then added[id] = q - p; n = n + 1
    elseif q < p then removed[id] = p - q; n = n + 1 end
  end
  for id, p in pairs(prev.items) do
    if now.items[id] == nil then removed[id] = p; n = n + 1 end
  end
  return { added = added, removed = removed, n = n }
end

local Tracker = {}
Tracker.__index = Tracker

function B.New()
  return setmetatable({ base = nil, fp = nil, seq = 0, pending = nil,
    st = { settles = 0, skipped = 0, empty = 0, diffs = 0, committed = 0, baselines = 0, rejected = 0 } }, Tracker)
end

function Tracker:Settle(snap)
  local st = self.st
  st.settles = st.settles + 1
  if not usable(snap) then
    st.skipped = st.skipped + 1
    return nil, 'incomplete'
  end
  local fp = B.Fingerprint(snap.items)
  if not self.base then
    self.base = copyItems(snap.items)
    self.fp = fp
    self.pending = nil
    st.baselines = st.baselines + 1
    return nil, 'baseline'
  end
  if fp == self.fp then
    self.pending = nil
    st.empty = st.empty + 1
    return nil, 'empty'
  end
  local diff = B.Compute({ items = self.base, complete = true }, snap)
  if not diff or diff.n == 0 then
    self.pending = nil
    st.empty = st.empty + 1
    return nil, 'empty'
  end
  self.seq = self.seq + 1
  diff.seq, diff.from, diff.to = self.seq, self.fp, fp
  self.pending = { seq = self.seq, items = copyItems(snap.items), fp = fp }
  st.diffs = st.diffs + 1
  return diff
end

function Tracker:Commit(seq)
  local p = self.pending
  if not p or p.seq ~= seq then
    self.st.rejected = self.st.rejected + 1
    return nil, 'no such pending diff'
  end
  self.base = p.items
  self.fp = p.fp
  self.pending = nil
  self.st.committed = self.st.committed + 1
  return true
end

function Tracker:Baseline()
  if not self.base then return nil end
  return copyItems(self.base)
end

function Tracker:Stats()
  local s = {}
  for k, v in pairs(self.st) do s[k] = v end
  return s
end
