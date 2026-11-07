-- GoldIntel / Ledger / Cash.lua                                    (Phase 3b-2 M3, Architecture AC-12)
--
-- PURPOSE
--  The persistent cash ledger: one compact record per finished entry, per character, in
--  GoldIntelDB.ledger[charKey]. The Reconciler (through Ledger/Ledger.lua) is the only producer.
--
--      Cash.Add(entry)            -> id | nil, reason     entry = what the Reconciler emits (Contracts F14.4)
--      Cash.AddGap(copper, ctx)   -> id | nil, reason     an OTHER entry flagged comp = 'gap' (AC-13)
--      Cash.Last(n)               -> array of expanded entry COPIES, newest last
--      Cash.Cumulative()          -> signed copper of every entry ever added (raw + folded)
--      Cash.Stats()               -> persistent indicators (see below)
--      Cash.Writable()            -> true when the Store saves what is added
--
-- STORAGE (Contracts F5b / F15)
--  ledger[charKey] = {
--    nextId = n,
--    cash   = { rec, ... },                 raw records, oldest first
--    totals = { src = { [src] = { n, copper, val } }, gap = { n, copper, val }, folded = n },
--    locs   = { { mapID, zone, sub }, ... } interned places; a record points at one with `l` (long zone names are
--                                           stored once, not on every entry)
--    quality = { intervals, unmatched },    summed over finished intervals (Ledger.lua)
--    largestOther = n,                      largest |OTHER| ever added (survives folding)
--  }
--  rec = { id, t (unix s), c (signed copper), src, conf, act, ac (actConf), lc (locConf), l?, x?, y?, cr? (true),
--          st? (true), ctx?, r? (loot source type), cp? (comp) }
--
-- RETENTION (D-077 Q-6, interim): when more than CAP (2000) raw records exist, the oldest FOLD (500) are folded into
-- `totals` and removed. Folding never changes Cumulative(): sum(raw) + sum(totals) is constant (AC-12). Final values
-- come from the measured entry size.
--
-- IMMUTABILITY: Add stores a fresh record; nothing hands out a stored table (Last/Expand return copies); there is no
-- update or delete function. A fold only removes whole old records after adding them to the totals.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Ledger/Cash.lua')

local Cash = {}
GI.Cash = Cash

Cash.CAP = 6000              -- R-1 (D-098, user 2026-11-07, stopgap until Phase 4 aggregates): was 2000 (3b-2 Q-6)
Cash.FOLD = 500
Cash.stats = { added = 0, rejected = 0, folds = 0, gaps = 0 }

local locIndex = {}          -- [ledger table] -> { [key] = index }, rebuilt lazily after a load

local function bus(name, payload)
  if GI.Bus then GI.Bus.Fire(name, payload) end
end

local function charKey()
  local pl = P.Player and P.Player()
  return pl and pl.key or nil
end

local function ledgerTable(create)
  local key = charKey()
  if not key then return nil, 'no character identity' end
  local store = GI.Store
  if not store then return nil, 'no store' end
  local section = store.Section('ledger')
  if not section then return nil, 'no ledger section' end
  local led = section[key]
  if type(led) ~= 'table' then
    if not create then return nil, 'empty' end
    led = {}
    section[key] = led
  end
  if type(led.nextId) ~= 'number' then led.nextId = 1 end
  if type(led.cash) ~= 'table' then led.cash = {} end
  if type(led.totals) ~= 'table' then led.totals = {} end
  if type(led.totals.src) ~= 'table' then led.totals.src = {} end
  if type(led.totals.gap) ~= 'table' then led.totals.gap = { n = 0, copper = 0, val = 0 } end
  if type(led.totals.folded) ~= 'number' then led.totals.folded = 0 end
  if type(led.locs) ~= 'table' then led.locs = {} end
  if type(led.quality) ~= 'table' then led.quality = { intervals = 0, unmatched = 0 } end
  if type(led.largestOther) ~= 'number' then led.largestOther = 0 end
  return led, key
end

function Cash.Writable() return GI.Store ~= nil and GI.Store.IsWritable() end

function Cash.Ledger() return (ledgerTable(true)) end          -- the live table (for Ledger.lua's counters; not for callers)

local function mag(n) return n < 0 and -n or n end
local function round4(v) return math.floor(v * 10000 + 0.5) / 10000 end

local function internLoc(led, loc)
  local idx = locIndex[led]
  if not idx then
    idx = {}
    for i, l in ipairs(led.locs) do idx[tostring(l.mapID) .. '|' .. tostring(l.zone) .. '|' .. tostring(l.sub)] = i end
    locIndex[led] = idx
  end
  local k = tostring(loc.mapID) .. '|' .. tostring(loc.zone) .. '|' .. tostring(loc.sub)
  local i = idx[k]
  if not i then
    i = #led.locs + 1
    led.locs[i] = { mapID = loc.mapID, zone = loc.zone, sub = loc.sub }
    idx[k] = i
  end
  return i
end

local function fold(led)
  local cash, totals = led.cash, led.totals
  local n = math.min(Cash.FOLD, #cash)
  for i = 1, n do
    local r = cash[i]
    local s = totals.src[r.src]
    if not s then s = { n = 0, copper = 0, val = 0 }; totals.src[r.src] = s end
    s.n = s.n + 1; s.copper = s.copper + r.c; s.val = s.val + mag(r.c)
    if r.cp == 'gap' then
      totals.gap.n = totals.gap.n + 1; totals.gap.copper = totals.gap.copper + r.c; totals.gap.val = totals.gap.val + mag(r.c)
    end
  end
  local kept = {}
  for i = n + 1, #cash do kept[#kept + 1] = cash[i] end
  led.cash = kept
  totals.folded = totals.folded + n
  Cash.stats.folds = Cash.stats.folds + 1
end

--- Expands a stored record into the Contracts entry shape (a new table every call).
function Cash.Expand(rec, led, key)
  local e = { id = rec.id, t = rec.t, copper = rec.c, src = rec.src, conf = rec.conf, act = rec.act, actConf = rec.ac,
    locConf = rec.lc, creditable = rec.cr == true, settle = rec.st == true, ctx = rec.ctx, comp = rec.cp, charKey = key }
  if rec.r then e.ref = rec.r end
  if rec.l and led and led.locs[rec.l] then
    local l = led.locs[rec.l]
    e.loc = { mapID = l.mapID, zone = l.zone, sub = l.sub, x = rec.x, y = rec.y }
  end
  return e
end

local function build(e, led)
  local ut, gt = P.Now()
  local rec = {
    id = led.nextId, t = math.floor(ut - (gt - (e.t or gt)) + 0.5), c = e.copper, src = e.src, conf = e.conf or 'low',
    act = e.act or 'OTHER', ac = e.actConf or 'low', lc = e.locConf or 'none',
  }
  if e.loc then
    rec.l = internLoc(led, e.loc)
    if type(e.loc.x) == 'number' then rec.x = round4(e.loc.x) end
    if type(e.loc.y) == 'number' then rec.y = round4(e.loc.y) end
  end
  if e.creditable then rec.cr = true end
  if e.settle then rec.st = true end
  if e.ctx then rec.ctx = e.ctx end
  if e.comp then rec.cp = e.comp end
  local st = e.ref and (type(e.ref) == 'table' and e.ref.sourceType or (type(e.ref) == 'string' and e.ref))
  if st then rec.r = st end
  return rec
end

function Cash.Add(e)
  if type(e) ~= 'table' or type(e.copper) ~= 'number' or e.copper == 0 or e.copper ~= math.floor(e.copper) or type(e.src) ~= 'string' then
    Cash.stats.rejected = Cash.stats.rejected + 1
    return nil, 'invalid entry'
  end
  local led, key = ledgerTable(true)
  if not led then
    Cash.stats.rejected = Cash.stats.rejected + 1
    return nil, key
  end
  local rec = build(e, led)
  led.nextId = led.nextId + 1
  led.cash[#led.cash + 1] = rec
  if rec.src == 'other' and mag(rec.c) > led.largestOther then led.largestOther = mag(rec.c) end
  Cash.stats.added = Cash.stats.added + 1
  if rec.cp == 'gap' then Cash.stats.gaps = Cash.stats.gaps + 1 end
  if #led.cash > Cash.CAP then fold(led) end
  bus('LEDGER_CASH', Cash.Expand(rec, led, key))
  return rec.id
end

function Cash.AddGap(copper, ctx)
  local _, gt = P.Now()
  return Cash.Add({ t = gt, copper = copper, src = 'other', conf = 'low', comp = 'gap', ctx = ctx or 'login',
    act = 'OTHER', actConf = 'low', locConf = 'none', creditable = false })
end

function Cash.Count()
  local led = ledgerTable(false)
  return led and #led.cash or 0
end

function Cash.Last(n)
  local led, key = ledgerTable(false)
  local out = {}
  if not led then return out end
  n = math.max(1, math.min(tonumber(n) or 10, 200))
  for i = math.max(1, #led.cash - n + 1), #led.cash do out[#out + 1] = Cash.Expand(led.cash[i], led, key) end
  return out
end

function Cash.Cumulative()
  local led = ledgerTable(false)
  if not led then return 0 end
  local sum = 0
  for _, r in ipairs(led.cash) do sum = sum + r.c end
  for _, s in pairs(led.totals.src) do sum = sum + s.copper end
  return sum
end

--- Persistent indicators over raw records and folded totals. Shares use absolute copper; value is the headline (D-072).
function Cash.Stats()
  local led = ledgerTable(false)
  local out = { raw = 0, folded = 0, total = 0, cumulative = 0, totalValue = 0, otherN = 0, otherValue = 0,
    otherShareValue = 0, otherShareEntries = 0, largestOther = 0, gapCount = 0, gapValue = 0, unmatched = 0, intervals = 0,
    bySource = {}, writable = Cash.Writable() }
  if not led then return out end
  local by = out.bySource
  local function acc(src, n, copper, av)
    local s = by[src]
    if not s then s = { n = 0, copper = 0, val = 0 }; by[src] = s end
    s.n = s.n + n; s.copper = s.copper + copper; s.val = s.val + av
  end
  for _, r in ipairs(led.cash) do
    acc(r.src, 1, r.c, mag(r.c))
    if r.cp == 'gap' then out.gapCount = out.gapCount + 1; out.gapValue = out.gapValue + mag(r.c) end
  end
  for src, s in pairs(led.totals.src) do acc(src, s.n, s.copper, s.val) end
  out.gapCount = out.gapCount + led.totals.gap.n
  out.gapValue = out.gapValue + led.totals.gap.val
  out.raw, out.folded = #led.cash, led.totals.folded
  for _, s in pairs(by) do
    out.total = out.total + s.n; out.cumulative = out.cumulative + s.copper; out.totalValue = out.totalValue + s.val
  end
  if by.other then out.otherN, out.otherValue = by.other.n, by.other.val end
  if out.total > 0 then out.otherShareEntries = out.otherN / out.total end
  if out.totalValue > 0 then out.otherShareValue = out.otherValue / out.totalValue end
  out.largestOther = led.largestOther
  out.unmatched = led.quality.unmatched
  out.intervals = led.quality.intervals
  return out
end

--- Test helper: forget cached lookups (the saved tables stay).
function Cash.Reset()
  locIndex = {}
  Cash.stats = { added = 0, rejected = 0, folds = 0, gaps = 0 }
end
