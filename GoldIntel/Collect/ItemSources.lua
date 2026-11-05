-- GoldIntel / Collect / ItemSources.lua                       (Phase 3b-3 M2, TRACE-ONLY; D-080, D-081, D-082)
--
-- PURPOSE
--  The ONLY module that knows what an item addition or removal in the bags means. M2 runs it in TRACE-ONLY mode:
--  it decides and records what it WOULD do (trace lines, counters, a ring of recent decisions), but it creates no
--  lot, stores nothing and never touches Sources, Reconciler or Cash (AC-15, I-6). M3 will feed the same decisions
--  to Ledger/Lots.lua after the user has reviewed the Session E evidence (D-080 gate).
--
--      ItemSources.Begin()    starts with the ledger interval: baseline bag snapshot, subscriptions live
--      ItemSources.End()      stops; pending decisions are dropped (nothing is stored)
--      ItemSources.IsActive() ItemSources.Stats() ItemSources.Recent(n) ItemSources.Anomalies()
--      ItemSources.Attribute(diff, facts) -> decisions      PURE: the attribution rules (tested without a client)
--
-- Scope (D-081, option B): acquisitions and conversions only. Additions are loot, quest reward, vendor purchase,
-- mail, trade, disenchant materials; removals that matter are vendor sale, quest consumption, disenchant source,
-- trade out. Every other removal is IGNORED (equip, cursor, moves, use, destroy, bank are not our business) and
-- every other addition is UNEXPLAINED (counted, visible, no value created).
--
-- Rules, in this order (no heuristics: each rests on a verified signal; unknowns stay unexplained):
--   add:    loot window slot (id and quantity from the window; disenchant window = materials) -> quest context ->
--           vendor context with money OUT -> mail context -> trade context -> unexplained
--   remove: vendor context with money IN -> quest context -> disenchant (cast 13262 + an item-source window) ->
--           trade context -> ignored
-- Decisions wait WAIT seconds after the bag settle because the money delta can arrive after it (E-32) and the
-- measured lags are what Session E records.
--
-- Skinning (D-082): a loot window of a creature already looted in this interval, after a skin cast made since that
-- first window, is skinning = GATHER (E-24: the skinning window is a second LOOT_OPENED of the same guid).
-- 0.5.2 (D-091): a creature window that opens at most SKIN_FIRST seconds after the player's own skin cast is also
-- skinning, even when it is the corpse's first window here (corpses left unskinned or unlooted by other players;
-- live 2026-11-04: 7 of 7 such windows opened 0.25-0.29 s after the cast and were booked GRIND).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P and GI.BagDiff and GI.Stamps, 'Platform, BagDiff and Stamps must be loaded before Collect/ItemSources.lua')

local IS = {}
GI.ItemSources = IS

IS.WAIT = 2.0                 -- a decision waits this long after the settle (money may land after the bag event, E-32)
IS.LOOT_KEEP = 6.0            -- a loot item expectation outlives its window by this long
IS.MONEY_PAIR = 1.0           -- a money event can belong to a bag settle at most this far away (before or after)
IS.SEEN_KEEP = 600            -- how long a looted creature guid is remembered (for the skinning rule)
IS.SKIN_FIRST = 1.0           -- a first creature window this soon after a skin cast is the skinning window (D-091)
IS.RING = 50
IS.DISENCHANT_SPELL = 13262   -- E-26
IS.CAST_BEFORE = 8.0          -- a disenchant cast this long before the settle explains the removal

---------------------------------------------------------------------------
-- Pure attribution
---------------------------------------------------------------------------

local function sortedIds(map)
  local ids = {}
  for id in pairs(map or {}) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

local function contextsText(f)
  local t = {}
  for _, k in ipairs({ 'quest', 'merchant', 'mail', 'trade' }) do if f[k] then t[#t + 1] = k end end
  if (f.moneyPos or 0) > 0 then t[#t + 1] = 'money+' end
  if (f.moneyNeg or 0) > 0 then t[#t + 1] = 'money-' end
  return #t > 0 and table.concat(t, ',') or 'none'
end

--- Pure. diff = { added = {[id]=qty}, removed = {[id]=qty} }.
-- facts = { loot = { {itemID,left,sourceType,skinning,act,actConf,windowId}... } (left is CONSUMED),
--           quest, merchant, mail, trade, disenchant = boolean, moneyPos, moneyNeg = number (magnitudes) }.
-- Returns decisions { dir = 'add'|'remove', itemID, qty, how, reason, act?, actConf?, window?, skinning? }.
--- Pure. Each money event belongs to exactly ONE bag settle: the nearest one within `pair` seconds (ties: the earlier
-- settle). A vendor sells one stack per click and money lands with its own bag event (E-21, M2 trace 2026-10-21: five sales
-- within 0.3 s), so a shared window would book the same copper several times.
-- events = { {gt, copper}... }, settles = { gt... } (all known settles), mine = this entry's settle time.
-- Returns moneyPos, moneyNeg (magnitudes) owned by `mine`.
function IS.PairMoney(events, settles, mine, pair)
  local pos, neg = 0, 0
  for _, m in ipairs(events) do
    if math.abs(m.gt - mine) <= pair + 1e-9 then
      local best, bestD = nil, nil
      for _, s in ipairs(settles) do
        local d = math.abs(m.gt - s)
        if d <= pair + 1e-9 and (bestD == nil or d < bestD - 1e-9 or (math.abs(d - bestD) <= 1e-9 and s < best)) then best, bestD = s, d end
      end
      if best == mine then
        if m.copper > 0 then pos = pos + m.copper else neg = neg - m.copper end
      end
    end
  end
  return pos, neg
end

function IS.Attribute(diff, facts)
  facts = facts or {}
  local out = {}
  local hasItemWindow = false
  for _, e in ipairs(facts.loot or {}) do if e.sourceType == 'item' then hasItemWindow = true end end
  for _, id in ipairs(sortedIds(diff.added)) do
    local left = diff.added[id]
    for _, e in ipairs(facts.loot or {}) do
      if left <= 0 then break end
      if e.itemID == id and e.left > 0 then
        local n = math.min(left, e.left)
        e.left = e.left - n
        left = left - n
        out[#out + 1] = { dir = 'add', itemID = id, qty = n, how = e.sourceType == 'item' and 'disenchantMat' or 'loot',
          reason = 'loot window slot', act = e.act, actConf = e.actConf, window = e.windowId, skinning = e.skinning,
          loc = e.loc, locConf = e.locConf }
      end
    end
    if left > 0 then
      local how, reason
      if facts.quest then how, reason = 'quest', 'quest turn-in context'
      elseif facts.merchant and (facts.moneyNeg or 0) > 0 then how, reason = 'vendorBuy', 'vendor open and money out'
      elseif facts.mail then how, reason = 'mail', 'mailbox open'
      elseif facts.trade then how, reason = 'trade', 'trade window'
      else how, reason = 'unexplained', 'no matching signal (' .. contextsText(facts) .. ')' end
      out[#out + 1] = { dir = 'add', itemID = id, qty = left, how = how, reason = reason }
    end
  end
  for _, id in ipairs(sortedIds(diff.removed)) do
    local qty = diff.removed[id]
    local how, reason
    if facts.merchant and (facts.moneyPos or 0) > 0 then how, reason = 'vendorSale', 'vendor open and money in'
    elseif facts.quest then how, reason = 'questConsume', 'quest turn-in context'
    elseif facts.disenchant and hasItemWindow then how, reason = 'disenchantSrc', 'disenchant cast and item-source window'
    elseif facts.trade then how, reason = 'tradeOut', 'trade window'
    else how, reason = 'ignored', 'inventory-only change (D-081)' end
    out[#out + 1] = { dir = 'remove', itemID = id, qty = qty, how = how, reason = reason }
  end
  return out
end

---------------------------------------------------------------------------
-- Live wiring
---------------------------------------------------------------------------

local active = false
local tracker, stamps
local lootExp, win, seen, nextWin
local moneyRing, lastDE, settleLog
local pendingQ
local ring
local seenInfo
local anomalies
local c

local function freshCounters()
  c = { settles = 0, baselines = 0, empty = 0, skipped = 0, snapFail = 0, diffs = 0, decisions = 0, handlerErrors = 0,
        windows = 0, lootSlots = 0, skinWindows = 0, skinFirst = 0, noGuid = 0, how = {}, itemInfoEvents = 0 }
end
freshCounters()

local function nowGT() local _, gt = P.Now(); return gt end

local function tapped(...)
  if IS.tap then pcall(IS.tap, ...) end
end

local function guard(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then
      c.handlerErrors = c.handlerErrors + 1
      P.Diag('error', 'ItemSources', tostring(err))
    end
  end
end

local function reset()
  tracker = GI.BagDiff.New()
  stamps = GI.Stamps.New{ lastCast = P.LastCast }
  lootExp, win, seen, nextWin = {}, nil, {}, 0
  moneyRing, lastDE, settleLog = {}, nil, {}
  pendingQ, ring, seenInfo, anomalies = {}, {}, {}, { counts = {}, recent = {} }
  freshCounters()
end

local function prune(gt)
  local keep = {}
  for _, e in ipairs(lootExp) do
    local expired = e.closeGT and gt - e.closeGT > IS.LOOT_KEEP + IS.WAIT
    if not expired then keep[#keep + 1] = e end
  end
  lootExp = keep
  for guid, t in pairs(seen) do if gt - t > IS.SEEN_KEEP then seen[guid] = nil end end
  local m = {}
  for _, r in ipairs(moneyRing) do if gt - r.gt <= 20 then m[#m + 1] = r end end
  moneyRing = m
  local sl = {}
  for _, g in ipairs(settleLog) do if gt - g <= 20 then sl[#sl + 1] = g end end
  settleLog = sl
end

local function onLootOpen(p)
  local gt = nowGT()
  prune(gt)
  nextWin = nextWin + 1
  local skinning = false
  if p.sourceType == 'creature' then
    if type(p.guid) == 'string' then
      local prev = seen[p.guid]
      local castGT = P.LastCast and P.LastCast('skin')
      if prev then
        if castGT and castGT >= prev and castGT <= gt + 1e-9 then skinning = true end
      elseif castGT and gt - castGT >= -1e-9 and gt - castGT <= IS.SKIN_FIRST then
        skinning = true                                    -- D-091: first window right after the skin cast
        c.skinFirst = c.skinFirst + 1
      end
      seen[p.guid] = gt
    else
      c.noGuid = c.noGuid + 1
    end
  end
  if skinning then c.skinWindows = c.skinWindows + 1 end
  local act, actConf = stamps:ItemActivity{ sourceType = p.sourceType, skinning = skinning, t = gt }
  local loc, locConf = stamps:Loc(gt)
  win = { id = nextWin, sourceType = p.sourceType, skinning = skinning, openGT = gt, act = act, actConf = actConf, loc = loc, locConf = locConf,
          guid = type(p.guid) == 'string' and p.guid:sub(-6) or '?' }
  c.windows = c.windows + 1
  tapped('window', win)
end

local function onLootItem(p)
  local gt = nowGT()
  local w = win
  c.lootSlots = c.lootSlots + 1
  local e = { itemID = p.itemID, left = p.qty, qty = p.qty, sourceType = (w and w.sourceType) or p.source or 'unknown',
              skinning = w and w.skinning or false, act = w and w.act, actConf = w and w.actConf, windowId = w and w.id,
              loc = w and w.loc, locConf = w and w.locConf,
              openGT = gt }
  lootExp[#lootExp + 1] = e
  tapped('slot', e)
end

local function onLootClose(p)
  local gt = nowGT()
  for _, e in ipairs(lootExp) do
    if win and e.windowId == win.id and not e.closeGT then e.closeGT = gt end
  end
  tapped('windowClose', win, p.by)
  win = nil
end

local function onMoney(p)
  moneyRing[#moneyRing + 1] = { gt = nowGT(), copper = p.copper }
end

local function onCast(p)
  if p.spellID == IS.DISENCHANT_SPELL then lastDE = nowGT() end
end

local function note(kind, detail)
  anomalies.counts[kind] = (anomalies.counts[kind] or 0) + 1
  anomalies.recent[#anomalies.recent + 1] = { gt = nowGT(), kind = kind, detail = detail }
  while #anomalies.recent > IS.RING do table.remove(anomalies.recent, 1) end
  tapped('anomaly', kind, detail)
end

local function infoOnce(id)
  if seenInfo[id] then return end
  seenInfo[id] = true
  local info = GI.Platform.ItemsModule and GI.Platform.ItemsModule.Get(id) or nil
  tapped('iteminfo', id, info)
end

local function decide(entry)
  if not active then return end
  local gt = nowGT()
  prune(gt)
  local moneyPos, moneyNeg = IS.PairMoney(moneyRing, settleLog, entry.gt, IS.MONEY_PAIR)
  local f = entry.facts
  f.moneyPos, f.moneyNeg = moneyPos, moneyNeg
  f.disenchant = lastDE ~= nil and lastDE >= entry.gt - IS.CAST_BEFORE and lastDE <= entry.gt + 1.0
  f.loot = lootExp
  local decisions = IS.Attribute(entry.diff, f)
  for _, d in ipairs(decisions) do
    c.decisions = c.decisions + 1
    c.how[d.how] = (c.how[d.how] or 0) + d.qty
    ring[#ring + 1] = { gt = gt, settleGT = entry.gt, d = d }
    while #ring > IS.RING do table.remove(ring, 1) end
    if d.how == 'vendorSale' and not IS.sink then      -- with a sink (M3) the lot book raises these anomalies itself
      local info = P.ItemsModule and P.ItemsModule.Get(d.itemID) or nil
      if info and info.status == 'ready' and info.sellPrice == 0 then
        note('sale-no-sell-price', { itemID = d.itemID, qty = d.qty, moneyIn = moneyPos })
      elseif not info or info.status ~= 'ready' then
        note('sale-price-unknown', { itemID = d.itemID, qty = d.qty, moneyIn = moneyPos })
      end
    end
    tapped('decision', d, entry, f)
  end
  -- M3: the lot book receives the whole entry's decisions at once (a vendor sale of several items shares one money total)
  if IS.sink and #decisions > 0 then
    local ok, err = pcall(IS.sink, decisions, { gt = entry.gt, unix = (P.Now()), moneyPos = moneyPos, moneyNeg = moneyNeg })
    if not ok then c.handlerErrors = c.handlerErrors + 1; P.Diag('error', 'ItemSources', 'sink: ' .. tostring(err)) end
  end
end

local function settle(origin)
  local gt = nowGT()
  c.settles = c.settles + 1
  if not P.BagsModule then c.snapFail = c.snapFail + 1; return end
  local snap, why = P.BagsModule.Snapshot()
  if not snap then
    c.snapFail = c.snapFail + 1
    tapped('snapFail', why)
    return
  end
  local diff, reason = tracker:Settle(snap)
  if not diff then
    if reason == 'baseline' then c.baselines = c.baselines + 1; tapped('baseline', snap, origin)
    elseif reason == 'empty' then c.empty = c.empty + 1; tapped('empty')
    else c.skipped = c.skipped + 1; tapped('skipped', snap) end
    return
  end
  tracker:Commit(diff.seq)
  c.diffs = c.diffs + 1
  settleLog[#settleLog + 1] = gt
  for id in pairs(diff.added) do infoOnce(id) end
  for id in pairs(diff.removed) do infoOnce(id) end
  local Ctx = GI.Context
  local function on(kind) return Ctx and Ctx.IsActive(kind) or false end
  local entry = { gt = gt, diff = diff, snap = snap, facts = { quest = on('quest'), merchant = on('vendor'), mail = on('mail'), trade = on('trade') } }
  tapped('diff', diff, entry)
  pendingQ[#pendingQ + 1] = entry
  P.After(IS.WAIT, function()
    for i, e in ipairs(pendingQ) do if e == entry then table.remove(pendingQ, i); break end end
    guard(decide)(entry)
  end)
end

local wired = false
local function wire()
  if wired then return end
  wired = true
  P.On('P_LOOT_OPEN', guard(function(p) if active then onLootOpen(p) end end))
  P.On('P_LOOT_ITEM', guard(function(p) if active then onLootItem(p) end end))
  P.On('P_LOOT_CLOSE', guard(function(p) if active then onLootClose(p) end end))
  P.On('P_MONEY', guard(function(p) if active then onMoney(p) end end))
  P.On('P_CAST', guard(function(p) if active then onCast(p) end end))
  P.On('P_TICK', guard(function(p) if active and stamps and p.loc then stamps:NoteLoc(p.loc, nowGT()) end end))
  P.On('P_ZONE', guard(function(p) if active and stamps and p.loc then stamps:NoteLoc(p.loc, nowGT()) end end))
  P.On('P_BAGS_SETTLED', guard(function() if active then settle('settle') end end))
  P.On('P_ITEM_INFO', guard(function(p) if active then c.itemInfoEvents = c.itemInfoEvents + 1; tapped('infoEvent', p) end end))
end

function IS.Begin()
  wire()
  if active then return false end
  reset()
  active = true
  if P.BagsModule and P.BagsModule.Ranges then tapped('ranges', P.BagsModule.Ranges()) end
  settle('begin')
  return true
end

function IS.End()
  if not active then return false end
  active = false
  pendingQ = {}
  return true
end

function IS.IsActive() return active end
function IS.Recent(n)
  n = math.max(1, math.min(tonumber(n) or 10, IS.RING))
  local out = {}
  for i = math.max(1, #ring - n + 1), #ring do out[#out + 1] = ring[i] end
  return out
end
function IS.Anomalies() return anomalies end

--- Counters. Nil before the first interval.
function IS.Stats()
  if not c then return nil end
  local s = { active = active, how = {} }
  for k, v in pairs(c) do if k ~= 'how' then s[k] = v end end
  for k, v in pairs(c.how) do s.how[k] = v end
  s.tracker = tracker and tracker:Stats() or nil
  s.anomalies = {}
  if anomalies then for k, v in pairs(anomalies.counts) do s.anomalies[k] = v end end
  return s
end

--- Test helper.
function IS.Reset() active = false; reset() end
