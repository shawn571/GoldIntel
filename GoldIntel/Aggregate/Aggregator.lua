-- GoldIntel / Aggregate / Aggregator.lua                   (Phase 4 P4-M1, pure, NOT loaded by the TOC; D-099)
--
-- PURPOSE
--  Live totals of gold, time and item counts per place x activity x 5-level bracket, plus 32 x 32 heat bins per map,
--  so a retention cap can never erase where value was made (Phase4_Live_Aggregation_Proposal.md, D-099 Q-1..Q-4).
--  It SUMS what the cash ledger and the lot book already decided; it decides no source and no value, and writes neither
--  (AC-15). Pure: no Platform calls, no clock; the tables it fills are the ones that will be saved (P4-M2).
--
--      local A = GI.Aggregator.New(aggState, heatState, { locale = 'enUS' })   -- agg[charKey], heat[charKey]
--      A:AddTime(slice)        slice = { dt, loc, act, level, t? }       (Clock ACTIVE slices; also every visited heat bin, Q-2)
--      A:AddCash(e)            e = { copper, src, act, loc, level?, t?, creditable? }   one finished cash entry
--      A:AddLot(lot)           lot = { itemID, qty, valueEach, vc, origin = { mapID?, zone, sub?, x?, y?, act }, level?, t? }
--      A:Enqueue(kind, rec) / A:Drain()   the handlers' queue and the 2 s aggregation task
--      A:Backfill(ledger, lotState)       once: value and item counts of saved raw records, NO time (Q-4)
--      A:Check(net, created) -> { cash = diff, vc = diff }  both must be 0
--      AG.PlaceKey(loc, locale), AG.Bracket(level), AG.BinIndex(x, y), AG.FromStored(rec, locs)  pure helpers
--
-- Place key: mapID:locale:subzone (D-008); inside an instance (mapID nil, live 2026-11-05) 'i:<zone>'.
-- Cell key: act .. '|' .. bracket ('?' when the level is unknown, as for back-filled records).
-- Heat bin: idx = row * 32 + col of the position (D-011); seconds for every ACTIVE slice with a position (Q-2), credit
-- only for value made by GRIND, GATHER and FISH at a fresh, creditable position (D-005, D-044, D-064).

local ADDON, GI = ...
GI = GI or {}

local AG = {}
GI.Aggregator = AG

AG.GRID = 32
AG.SEG_CAP = 200
AG.CREDIT = { GRIND = true, GATHER = true, FISH = true }

function AG.Bracket(level)
  level = tonumber(level)
  if not level then return '?' end
  if level < 1 then level = 1 end
  return tostring(math.floor((level - 1) / 5))
end

function AG.PlaceKey(loc, locale)
  if type(loc) ~= 'table' then return nil end
  if loc.mapID then
    return tostring(loc.mapID) .. ':' .. tostring(locale or '?') .. ':' .. tostring(loc.sub or ''),
      { mapID = loc.mapID, zone = loc.zone, sub = loc.sub }
  end
  if loc.zone then return 'i:' .. tostring(loc.zone), { zone = loc.zone, inst = true } end
  return nil
end

local function cellIndex(v)
  local i = math.floor(v * AG.GRID)
  if i < 0 then i = 0 elseif i > AG.GRID - 1 then i = AG.GRID - 1 end
  return i
end

function AG.BinIndex(x, y)
  if type(x) ~= 'number' or type(y) ~= 'number' then return nil end
  return cellIndex(y) * AG.GRID + cellIndex(x)
end

--- A stored (compact) cash record of GoldIntelDB.ledger[charKey].cash as an AddCash entry. locs = ledger.locs.
function AG.FromStored(rec, locs)
  local l = locs and rec.l and locs[rec.l] or nil
  local loc = l and { mapID = l.mapID, zone = l.zone, sub = l.sub, x = rec.x, y = rec.y } or nil
  return { copper = rec.c, src = rec.src, act = rec.act, loc = loc, t = rec.t, creditable = rec.cr == true and rec.lc == 'fresh' }
end

local Obj = {}
Obj.__index = Obj

local function zeroTotals() return { s = 0, coin = 0, cin = 0, cout = 0, vc = 0, n = 0 } end

function AG.New(state, heat, opts)
  state = state or {}
  heat = heat or {}
  opts = opts or {}
  state.v = state.v or 1
  state.places = state.places or {}
  state.totals = state.totals or zeroTotals()
  state.segments = state.segments or {}
  return setmetatable({ s = state, h = heat, locale = opts.locale, queue = {}, cur = nil,
    stats = { slices = 0, cash = 0, lots = 0, noPlace = 0, drained = 0 } }, Obj)
end

function Obj:cell(loc, act, level)
  local key, meta = AG.PlaceKey(loc, self.locale)
  if not key then self.stats.noPlace = self.stats.noPlace + 1; return nil end
  local place = self.s.places[key]
  if not place then
    place = { mapID = meta.mapID, zone = meta.zone, sub = meta.sub, inst = meta.inst, cells = {} }
    self.s.places[key] = place
  end
  local ck = tostring(act or 'OTHER') .. '|' .. AG.Bracket(level)
  local c = place.cells[ck]
  if not c then
    c = { s = 0, coin = 0, cin = 0, cout = 0, vc = 0, q = {}, n = 0 }
    place.cells[ck] = c
  end
  return c, key
end

local function stamp(c, t)
  if type(t) ~= 'number' then return end
  if not c.t0 or t < c.t0 then c.t0 = t end
  if not c.t1 or t > c.t1 then c.t1 = t end
end

function Obj:bin(loc)
  if type(loc) ~= 'table' or not loc.mapID then return nil end
  local idx = AG.BinIndex(loc.x, loc.y)
  if not idx then return nil end
  local m = self.h[loc.mapID]
  if not m then m = {}; self.h[loc.mapID] = m end
  local b = m[idx]
  if not b then b = { s = 0, c = 0, a = {} }; m[idx] = b end
  return b
end

-- segments: one open segment per place x activity x level; a change closes it into a capped ring (FR-SES-1)
function Obj:segment(key, act, level, t, dt, coin, vc)
  local cur = self.cur
  if not cur or cur.place ~= key or cur.act ~= act or cur.level ~= level then
    if cur then
      local S = self.s.segments
      S[#S + 1] = cur
      while #S > AG.SEG_CAP do table.remove(S, 1) end
    end
    cur = { place = key, act = act, level = level, t0 = t, t1 = t, s = 0, coin = 0, vc = 0 }
    self.cur = cur
  end
  cur.s = cur.s + (dt or 0); cur.coin = cur.coin + (coin or 0); cur.vc = cur.vc + (vc or 0)
  if type(t) == 'number' then cur.t1 = t end
end

function Obj:AddTime(sl)
  if type(sl) ~= 'table' or type(sl.dt) ~= 'number' or sl.dt <= 0 then return false end
  local c, key = self:cell(sl.loc, sl.act, sl.level)
  if not c then return false end
  c.s = c.s + sl.dt
  stamp(c, sl.t)
  self.s.totals.s = self.s.totals.s + sl.dt
  local b = self:bin(sl.loc)
  if b then b.s = b.s + sl.dt end
  self:segment(key, sl.act, sl.level, sl.t, sl.dt, 0, 0)
  self.stats.slices = self.stats.slices + 1
  return true
end

function Obj:AddCash(e)
  if type(e) ~= 'table' or type(e.copper) ~= 'number' or e.copper == 0 then return false end
  local T = self.s.totals
  local c, key = self:cell(e.loc, e.act, e.level)
  -- the totals always take the entry, so the live check stays exact even for an entry without a place
  if e.copper > 0 then T.cin = T.cin + e.copper else T.cout = T.cout - e.copper end
  local coin = (e.src == 'loot' and e.copper > 0) and e.copper or 0
  T.coin = T.coin + coin
  T.n = T.n + 1
  self.stats.cash = self.stats.cash + 1
  if not c then return false end
  if e.copper > 0 then c.cin = c.cin + e.copper else c.cout = c.cout - e.copper end
  c.coin = c.coin + coin
  c.n = c.n + 1
  if e.backfill then c.bf = true end
  stamp(c, e.t)
  if coin > 0 and e.creditable and AG.CREDIT[e.act] then
    local b = self:bin(e.loc)
    if b then b.c = b.c + coin; b.a[e.act] = (b.a[e.act] or 0) + coin end
  end
  if not e.backfill then self:segment(key, e.act, e.level, e.t, 0, coin, 0) end
  return true
end

function Obj:AddLot(lot)
  if type(lot) ~= 'table' or not lot.vc then return false end
  local qty, each = tonumber(lot.qty) or 0, tonumber(lot.valueEach) or 0
  if qty <= 0 then return false end
  local o = lot.origin or {}
  local value = qty * each
  local T = self.s.totals
  T.vc = T.vc + value
  self.stats.lots = self.stats.lots + 1
  local c, key = self:cell(o, o.act, lot.level)
  if not c then return false end
  c.vc = c.vc + value
  c.q[lot.itemID] = (c.q[lot.itemID] or 0) + qty
  c.n = c.n + 1
  if lot.backfill then c.bf = true end
  stamp(c, lot.t)
  if value > 0 and AG.CREDIT[o.act] and lot.locConf ~= 'stale' and lot.locConf ~= 'none' then
    local b = self:bin(o)
    if b then b.c = b.c + value; b.a[o.act] = (b.a[o.act] or 0) + value end
  end
  if not lot.backfill then self:segment(key, o.act, lot.level, lot.t, 0, 0, value) end
  return true
end

-- queue (handlers only enqueue, Architecture 13) and the 2 s aggregation task
function Obj:Enqueue(kind, rec) self.queue[#self.queue + 1] = { kind, rec } end

function Obj:Drain()
  local q = self.queue
  self.queue = {}
  for _, item in ipairs(q) do
    local kind, rec = item[1], item[2]
    if kind == 'cash' then self:AddCash(rec)
    elseif kind == 'lot' then self:AddLot(rec)
    elseif kind == 'lotValue' then self:AddLotValue(rec)
    elseif kind == 'time' then self:AddTime(rec) end
  end
  self.stats.drained = self.stats.drained + #q
  return #q
end

--- Once per character: value and item counts of the saved raw records, NO time (Q-4). Records keep `bf = true`.
-- ledger = GoldIntelDB.ledger[charKey] (cash, locs); lotState = GoldIntelDB.lots[charKey] (open, closed).
function Obj:Backfill(ledger, lotState)
  local ok, why = self:BackfillStart(ledger, lotState)
  if not ok then return false, why end
  self:BackfillStep(math.huge)
  return true, self.s.backfilled.n
end

--- 0.6.1 (D-115): the back-fill in steps. Start takes a snapshot (cash records by reference: they never change once
-- stored; lots by value: a lot may get its value later, which then arrives live), so records stored while the steps
-- run are not counted twice. Step(n) adds at most n records and returns true when the back-fill is complete.
function Obj:BackfillStart(ledger, lotState)
  if self.s.backfilled then return false, 'already' end
  if self.bf then return false, 'running' end
  local cash, lotsSnap = {}, {}
  if ledger and ledger.cash then
    for i, rec in ipairs(ledger.cash) do cash[i] = rec end
  end
  local function snap(list)
    for _, lot in ipairs(list or {}) do
      if lot.vc then
        lotsSnap[#lotsSnap + 1] = { itemID = lot.itemID, qty = lot.qty, valueEach = lot.valueEach, vc = true, origin = lot.origin,
          locConf = lot.locConf, t = lot.t, backfill = true }
      end
    end
  end
  if lotState then snap(lotState.open); snap(lotState.closed) end
  -- completeness is recorded, never assumed: folded cash and lots that left the closed ring are not in the raw records
  self.bf = { cash = cash, locs = ledger and ledger.locs, lots = lotsSnap, ci = 0, li = 0,
    folded = ledger and ledger.totals and ledger.totals.folded or 0,
    created = lotState and lotState.totals and lotState.totals.created and lotState.totals.created.n or nil }
  return true, #cash + #lotsSnap
end

function Obj:BackfillStep(n)
  local b = self.bf
  if not b then return self.s.backfilled ~= nil end
  local budget = n or 500
  while budget > 0 and b.ci < #b.cash do
    b.ci = b.ci + 1
    local e = AG.FromStored(b.cash[b.ci], b.locs)
    e.backfill = true
    self:AddCash(e)
    budget = budget - 1
  end
  while budget > 0 and b.li < #b.lots do
    b.li = b.li + 1
    self:AddLot(b.lots[b.li])
    budget = budget - 1
  end
  if b.ci >= #b.cash and b.li >= #b.lots then
    self.s.backfilled = { n = b.ci + b.li, foldedCash = b.folded, lotsCreated = b.created }
    self.bf = nil
    return true
  end
  return false
end

--- Progress of a running back-fill: done, total (nil when none is running).
function Obj:BackfillProgress()
  local b = self.bf
  if not b then return nil end
  return b.ci + b.li, #b.cash + #b.lots
end

--- Live check (D-099): net cash of the aggregates minus the ledger's net over the same period, and value created minus
-- the lot book's created value. Both must be 0.
function Obj:Check(ledgerNet, createdValue)
  local T = self.s.totals
  return { cash = (T.cin - T.cout) - (ledgerNet or 0), vc = T.vc - (createdValue or 0), seconds = T.s }
end

--- 0.6.0: the value of a lot whose item data arrived later (Lots:Complete). Value only: the item count was added at creation.
function Obj:AddLotValue(lot)
  if type(lot) ~= 'table' or not lot.vc then return false end
  local value = (tonumber(lot.qty) or 0) * (tonumber(lot.valueEach) or 0)
  if value <= 0 then return false end
  local o = lot.origin or {}
  self.s.totals.vc = self.s.totals.vc + value
  local c = self:cell(o, o.act, lot.level)
  if not c then return false end
  c.vc = c.vc + value
  if AG.CREDIT[o.act] and lot.locConf ~= 'stale' and lot.locConf ~= 'none' then
    local b = self:bin(o)
    if b then b.c = b.c + value; b.a[o.act] = (b.a[o.act] or 0) + value end
  end
  return true
end

function Obj:Totals() return self.s.totals end
function Obj:Stats() local s = {} for k, v in pairs(self.stats) do s[k] = v end s.queued = #self.queue return s end
