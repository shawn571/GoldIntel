-- GoldIntel / Collect / Stamps.lua                                 (Phase 3b-2 M2, Architecture AC-10)
--
-- PURPOSE
--  Adds the location stamp (loc, locConf), the activity stamp (act, actConf) and `creditable` to a finished
--  ledger entry. No engine (Phase 4): activity is a pure function of the source, plus the last gathering cast
--  for game-object loot. Pure: no Platform calls; times and the cast lookup are injected.
--
--      local S = GI.Stamps.New{ lastCast = function(kind) -> gt, spellID | nil end }
--      S:NoteLoc(loc, gt)         the last good Where() (from P_TICK / P_ZONE)
--      S:Apply(entry)             fills entry.act, actConf, loc, locConf, creditable (entry.t is the delta time)
--
-- Location: fresh when the last good Where() is at most 5 s old, stale when older, none when never seen.
-- Creditable (D-044, D-064): only creature or game-object loot coin AND a fresh location. Never quest, mail,
-- trade, vendor, other.
--
-- Activity (judgment calls made in M2, listed in the M2 report): creature loot GRIND (med); game-object loot
-- GATHER (herb or mine cast within 30 s) or FISH (fish cast within 30 s) with high confidence, otherwise OTHER
-- (low); coin from a chat share with no known corpse or object LOOT (med, never credited to a place);
-- vendor and purchase VENDOR; quest QUEST; trade TRADE; trainer TRAINER (0.5.2); every mail-paid source MAIL; unknown OTHER.

local ADDON, GI = ...
GI = GI or {}

local S = {}
GI.Stamps = S

S.FRESH = 5.0
S.CAST_WINDOW = 30.0

S.BY_SOURCE = {
  vendor = 'VENDOR', purchase = 'VENDOR', repair = 'VENDOR', buyback = 'VENDOR',
  quest = 'QUEST', trade = 'TRADE', trainer = 'TRAINER',     -- TRAINER: 0.5.2 (D-093), never a LocationAct
  mailMoney = 'MAIL', codIn = 'MAIL', codOut = 'MAIL', ahSale = 'MAIL', ahCut = 'MAIL', ahDepositRefund = 'MAIL',
}

local Obj = {}
Obj.__index = Obj

function S.New(opts)
  opts = opts or {}
  return setmetatable({ lastCast = opts.lastCast, loc = nil, locGT = nil }, Obj)
end

function Obj:NoteLoc(loc, gt)
  if type(loc) ~= 'table' or type(gt) ~= 'number' then return end
  self.loc = { mapID = loc.mapID, zone = loc.zone, sub = loc.sub, x = loc.x, y = loc.y }
  self.locGT = gt
end

function Obj:Clear() self.loc, self.locGT = nil, nil end

--- Returns loc (a copy) or nil, plus 'fresh' | 'stale' | 'none'.
function Obj:Loc(t)
  if not self.loc then return nil, 'none' end
  local age = t - self.locGT
  local copy = { mapID = self.loc.mapID, zone = self.loc.zone, sub = self.loc.sub, x = self.loc.x, y = self.loc.y }
  if age <= S.FRESH then return copy, 'fresh' end
  return copy, 'stale'
end

local GATHER = { herb = 'GATHER', mine = 'GATHER', fish = 'FISH' }

function Obj:Activity(e)
  local fixed = S.BY_SOURCE[e.src]
  if fixed then return fixed, e.conf or 'high' end
  if e.src == 'loot' then
    local st = e.ref and e.ref.sourceType
    if st == 'creature' then return 'GRIND', 'med' end
    if not st and e.ref and e.ref.chat then return 'LOOT', 'med' end      -- coin chat share, source unknown (D-078, user 2026-10-18)
    if st == 'object' then
      local act = self:ObjectActivity(e.t)
      if act then return act, 'high' end
    end
  end
  return 'OTHER', 'low'
end

--- GATHER or FISH when a herb, mine or fish cast happened within CAST_WINDOW before `t`, else nil.
function Obj:ObjectActivity(t)
  if not self.lastCast then return nil end
  local bestAct, bestGT
  for kind, act in pairs(GATHER) do
    local gt = self.lastCast(kind)
    if gt and t - gt >= 0 - 1e-9 and t - gt <= S.CAST_WINDOW and (not bestGT or gt > bestGT) then
      bestAct, bestGT = act, gt
    end
  end
  return bestAct
end

--- Activity of an ITEM loot window (3b-3 M2; D-082: skinning is GATHER, user 2026-10-19).
--   w = { sourceType = 'creature'|'object'|'item'|..., skinning = boolean, t = gt }
-- 'skinning' is decided by ItemSources (a repeat window of the same corpse after a skin cast, E-24), never here.
-- Creature window: GATHER (high) when skinning, otherwise GRIND (med). Object window: as for coin. Item window
-- (disenchant) and anything else: OTHER (low).
function Obj:ItemActivity(w)
  if w.sourceType == 'creature' then
    if w.skinning then return 'GATHER', 'high' end
    return 'GRIND', 'med'
  end
  if w.sourceType == 'object' then
    local act = self:ObjectActivity(w.t)
    if act then return act, 'high' end
  end
  return 'OTHER', 'low'
end

function Obj:Apply(e)
  e.act, e.actConf = self:Activity(e)
  e.loc, e.locConf = self:Loc(e.t)
  local st = e.ref and e.ref.sourceType
  e.creditable = (e.src == 'loot' and (st == 'creature' or st == 'object') and e.locConf == 'fresh') or false
  return e
end
