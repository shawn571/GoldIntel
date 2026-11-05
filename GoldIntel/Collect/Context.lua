-- GoldIntel / Collect / Context.lua                                     (Phase 3b-1, Architecture AC-3)
--
-- PURPOSE
--  Knows which game windows are open (loot, vendor, mail, trade, auction house, trainer) and for how long, from the
--  normalized events the Platform adapters emit. Nothing here touches the client.
--      Context.Active()   -> array of { kind, id, open, openedGT, closedGT, by }   open or inside the linger
--      Context.Stats()    -> per kind { opened, closed, byCounts, duplicateOpens, strayCloses }
--      Context.Clear()    -> drops every context (collect off, reload; AC-8)
--  A context that closed stays "active" for LINGER seconds (1.0, D-065) so money that lands after the
--  window closed can still be matched (trade money 0.394 s, E-31). Closing is idempotent (E-31, E-33).
--  The quest turn-in has no window: it opens and closes in the same instant and lingers like the others.
--  CONTEXT_CHANGED { kind, open, id } is fired on the Bus on every open and close (Contracts F3b).
--
-- Nothing is stored. After /reload every context is gone and unmatched money becomes OTHER (AC-8).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
local Core = GI.Core
assert(P and Core, 'Platform and Core must be loaded before Collect/Context.lua')

local Context = Core.Module('Context', {})
GI.Context = Context

Context.LINGER = 1.0
Context.KINDS = { 'loot', 'vendor', 'mail', 'trade', 'ah', 'quest', 'trainer' }

local records = {}      -- kind -> { id, open, openedGT, closedGT, by }
local stats = {}
local nextId = 0

local function freshStats()
  stats = {}
  for _, kind in ipairs(Context.KINDS) do
    stats[kind] = { opened = 0, closed = 0, byCounts = {}, duplicateOpens = 0, strayCloses = 0 }
  end
end
freshStats()

local function nowGT()
  local _, gt = P.Now()
  return gt
end

local function fire(kind, open, id)
  if GI.Bus then GI.Bus.Fire('CONTEXT_CHANGED', { kind = kind, open = open, id = id }) end
end

local function openKind(kind)
  local r = records[kind]
  local s = stats[kind]
  if r and r.open then
    s.duplicateOpens = s.duplicateOpens + 1
    return false
  end
  nextId = nextId + 1
  records[kind] = { id = nextId, open = true, openedGT = nowGT() }
  s.opened = s.opened + 1
  fire(kind, true, nextId)
  return true
end

local function closeKind(kind, by)
  local r = records[kind]
  local s = stats[kind]
  if not r or not r.open then
    s.strayCloses = s.strayCloses + 1
    return false
  end
  r.open = false
  r.closedGT = nowGT()
  r.by = by or 'close'
  s.closed = s.closed + 1
  s.byCounts[r.by] = (s.byCounts[r.by] or 0) + 1
  fire(kind, false, r.id)
  return true
end

Context.Open, Context.Close = openKind, closeKind

--- Contexts that are open or closed less than LINGER seconds ago, oldest first.
function Context.Active()
  local gt = nowGT()
  local out = {}
  for _, kind in ipairs(Context.KINDS) do
    local r = records[kind]
    if r and (r.open or (r.closedGT and gt - r.closedGT <= Context.LINGER)) then
      out[#out + 1] = { kind = kind, id = r.id, open = r.open, openedGT = r.openedGT, closedGT = r.closedGT, by = r.by }
    end
  end
  table.sort(out, function(a, b) return a.openedGT < b.openedGT end)
  return out
end

--- True when `kind` is open or inside its linger.
function Context.IsActive(kind)
  local r = records[kind]
  if not r then return false end
  if r.open then return true end
  return r.closedGT ~= nil and nowGT() - r.closedGT <= Context.LINGER
end

function Context.Stats()
  local out = {}
  for kind, s in pairs(stats) do
    local copy = { opened = s.opened, closed = s.closed, duplicateOpens = s.duplicateOpens,
                   strayCloses = s.strayCloses, byCounts = {} }
    for k, v in pairs(s.byCounts) do copy.byCounts[k] = v end
    out[kind] = copy
  end
  return out
end

--- Drops every context without firing events (collect off, reload).
function Context.Clear()
  records = {}
end

function Context.Reset()
  records = {}
  nextId = 0
  freshStats()
end

---------------------------------------------------------------------------
-- Wiring: the Platform adapters emit these; they emit nothing while collect is off.
---------------------------------------------------------------------------

P.On('P_LOOT_OPEN', function() openKind('loot') end)
P.On('P_LOOT_CLOSE', function(p) closeKind('loot', p.by) end)
P.On('P_VENDOR_OPEN', function() openKind('vendor') end)
P.On('P_VENDOR_CLOSE', function() closeKind('vendor', 'close') end)
P.On('P_MAIL_OPEN', function() openKind('mail') end)
P.On('P_MAIL_CLOSE', function() closeKind('mail', 'close') end)
P.On('P_TRADE_OPEN', function() openKind('trade') end)
P.On('P_TRADE_CLOSE', function() closeKind('trade', 'close') end)
P.On('P_AH_OPEN', function() openKind('ah') end)
P.On('P_AH_CLOSE', function() closeKind('ah', 'close') end)
P.On('P_TRAINER_OPEN', function() openKind('trainer') end)          -- 0.5.2 (D-093)
P.On('P_TRAINER_CLOSE', function() closeKind('trainer', 'close') end)
P.On('P_QUEST_DONE', function()
  if openKind('quest') then closeKind('quest', 'instant') end
end)
