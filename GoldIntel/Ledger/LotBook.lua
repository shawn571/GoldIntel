-- GoldIntel / Ledger / LotBook.lua                                  (Phase 3b-3 M3, D-080, D-081, D-082, D-083)
--
-- PURPOSE
--  Turns the item decisions of Collect/ItemSources.lua into stored lots (Ledger/Lots.lua) for the current character.
--  The item side is an ECONOMIC ledger, not an inventory mirror (D-081): lots are created only by known acquisitions
--  and consumed only by known conversions; everything else is counted and nothing more.
--
--    CREATED   loot (value created), quest reward (value created), vendor purchase (cost recorded, not created),
--              disenchant materials (conversion, not created)
--    CONSUMED  vendor sale (copper allocated exactly), quest turn-in, disenchant source, trade out (copper 0)
--    COUNTED   mail and trade arrivals, "other additions" (moves, returns, unknown: D-083), inventory-only removals
--
--  AC-15: this module never touches Cash, Reconciler, Expectations or Sources. It reads item decisions only.
--  Storage: GoldIntelDB.lots[charKey] (additive inside schema 2, lazily created; the legacy empty keys stay untouched)
--           GoldIntelDB.prices.manual[itemID] = { copper, t }   (optional override, only by /gi price, D-082)
--  Nothing is written when the store is read-only.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P and GI.Lots and GI.Valuation, 'Platform, Lots and Valuation must be loaded before Ledger/LotBook.lua')

local LB = {}
GI.LotBook = LB

local active, readonly = false, false
local L, state, charKeyNow
local told = {}                              -- anomaly kinds already announced this session
local c

local function fresh()
  c = { batches = 0, lotsCreated = 0, conversions = 0, purchases = 0, ignoredRemovals = 0, ignoredAdds = 0,
        arrivals = 0, otherAdds = 0, errors = 0 }
end
fresh()

local function charKey()
  local pl = P.Player and P.Player()
  return pl and pl.key or nil
end

local function section(name)
  local st = GI.Store
  if not st then return nil end
  local ok, s = pcall(st.Section, name)
  if ok and type(s) == 'table' then return s end
  return nil
end

local function unixNow() return (P.Now()) end

---------------------------------------------------------------------------
-- Manual prices (optional override, D-082): account-wide, only by /gi price
---------------------------------------------------------------------------

local function manualTable(create)
  local s = section('prices')
  if not s then return nil end
  if type(s.manual) ~= 'table' then
    if not create then return nil end
    s.manual = {}
  end
  return s.manual
end

function LB.ManualFor(itemID)
  local m = manualTable(false)
  return m and m[itemID] or nil
end

--- "1g20s5c", "20s", "500c" (units required; a bare number is refused because it is ambiguous). -> copper | nil, err
function LB.ParseMoney(text)
  if type(text) ~= 'string' then return nil, 'a price like 1g20s5c is required' end
  local t = text:lower():gsub('%s+', '')
  if t == '' then return nil, 'a price like 1g20s5c is required' end
  local total
  local rest = t
  local gg, r1 = rest:match('^(%d+)g(.*)$')
  if gg then total = (total or 0) + tonumber(gg) * 10000; rest = r1 end
  local ss, r2 = rest:match('^(%d+)s(.*)$')
  if ss then if tonumber(ss) > 99 and gg then return nil, 'silver must be 0 to 99 when gold is given' end total = (total or 0) + tonumber(ss) * 100; rest = r2 end
  local c1, r3 = rest:match('^(%d+)c(.*)$')
  if c1 then if tonumber(c1) > 99 and (gg or ss) then return nil, 'copper must be 0 to 99 when gold or silver is given' end total = (total or 0) + tonumber(c1); rest = r3 end
  if rest ~= '' or total == nil then return nil, 'could not read "' .. text .. '"; use units, for example 1g20s5c' end
  if total > 2 ^ 40 then return nil, 'price too large' end
  return total
end

function LB.PriceSet(itemID, copper)
  if not GI.Store or not GI.Store.IsWritable() then return false, 'the store is read-only' end
  if type(itemID) ~= 'number' or itemID <= 0 or itemID ~= math.floor(itemID) then return false, 'bad item id' end
  if type(copper) ~= 'number' or copper < 0 then return false, 'bad price' end
  local m = manualTable(true)
  if not m then return false, 'no prices section' end
  m[itemID] = { copper = copper, t = unixNow() }
  return true
end

function LB.PriceClear(itemID)
  local m = manualTable(false)
  if not m or not m[itemID] then return false end
  m[itemID] = nil
  return true
end

function LB.PriceList()
  local m = manualTable(false)
  local out = {}
  if m then for id, v in pairs(m) do out[#out + 1] = { itemID = id, copper = v.copper, t = v.t } end end
  table.sort(out, function(a, b) return a.itemID < b.itemID end)
  return out
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local function lotsState(create)
  local key = charKey()
  if not key then return nil, 'no character identity' end
  local sec = section('lots')
  if not sec then return nil, 'no lots section' end
  local s = sec[key]
  if type(s) ~= 'table' then
    if not create then return nil, 'empty' end
    s = {}
    sec[key] = s
  end
  return s, key
end

local function alert(kind, rec)
  if GI.Trace and GI.Trace.IsRunning and GI.Trace.IsRunning() then
    GI.Trace.Line('ANOMALY ' .. kind .. ' -- NOT EXPECTED: please report this as a bug')
  end
  if not told[kind] then
    told[kind] = true
    P.Print('GoldIntel: UNEXPECTED item condition: ' .. GI.Lots.Describe(kind))
  end
end

local function emit(kind, rec, phase)
  if kind == 'lot' and GI.AggLive and GI.AggLive.OnLot then pcall(GI.AggLive.OnLot, rec, phase) end   -- 0.6.0 (P4-M2)
  if GI.Trace and GI.Trace.IsRunning and GI.Trace.IsRunning() and kind == 'conversion' then
    GI.Trace.Line(string.format('LOT conversion lot=%s item=%s qty=%s copper=%s via=%s', tostring(rec.lotID), tostring(rec.itemID), tostring(rec.qty), tostring(rec.copper), tostring(rec.via)))
  elseif GI.Trace and GI.Trace.IsRunning and GI.Trace.IsRunning() and kind == 'lot' then
    GI.Trace.Line(string.format('LOT lot=%s item=%s qty=%s each=%s src=%s how=%s valueSrc=%s vc=%s', tostring(rec.id), tostring(rec.itemID), tostring(rec.qty), tostring(rec.valueEach), tostring(rec.src), tostring(rec.how), tostring(rec.valueSrc), tostring(rec.vc)))
  end
end

---------------------------------------------------------------------------
-- Decisions -> lots
---------------------------------------------------------------------------

local function priceOf(id)
  local info = P.ItemsModule and P.ItemsModule.Get(id)
  if info and info.status == 'ready' and type(info.sellPrice) == 'number' then return info.sellPrice end
  return nil
end

local function origin(d)
  local o = { act = d.act, actConf = d.actConf }
  if d.loc then o.mapID, o.zone, o.sub, o.x, o.y = d.loc.mapID, d.loc.zone, d.loc.sub, d.loc.x, d.loc.y end
  if d.skinning then o.skinning = true end
  return o
end

local function addLot(d, now, src, how, vc, extraFlags, cost)
  local info = P.ItemsModule and P.ItemsModule.Get(d.itemID) or { status = 'invalid' }
  local r = GI.Valuation.Value(info, LB.ManualFor(d.itemID))
  local flags = {}
  for k in pairs(r.flags) do flags[k] = true end
  for k in pairs(extraFlags or {}) do flags[k] = true end
  local lot, err = L:Add{ itemID = d.itemID, qty = d.qty, t = now, src = src, how = how, valueEach = r.valueEach,
    valueSrc = r.valueSrc, vc = vc, flags = flags, origin = origin(d), locConf = d.locConf, cost = cost }
  if not lot then c.errors = c.errors + 1; P.Diag('error', 'LotBook', 'Add refused: ' .. tostring(err)); return end
  c.lotsCreated = c.lotsCreated + 1
end

--- decisions from ItemSources, info = { gt, unix, moneyPos, moneyNeg }
function LB.OnDecisions(decisions, info)
  if not active or not L then return end
  local now = info.unix or unixNow()
  c.batches = c.batches + 1
  local sales, consume, trade = {}, {}, {}
  local anySales, anyConsume, anyTrade = false, false, false
  for _, d in ipairs(decisions) do
    if d.dir == 'remove' then
      if d.how == 'vendorSale' then sales[d.itemID] = (sales[d.itemID] or 0) + d.qty; anySales = true
      elseif d.how == 'questConsume' or d.how == 'disenchantSrc' then consume[d.itemID] = (consume[d.itemID] or 0) + d.qty; anyConsume = true
      elseif d.how == 'tradeOut' then trade[d.itemID] = (trade[d.itemID] or 0) + d.qty; anyTrade = true
      else c.ignoredRemovals = c.ignoredRemovals + 1 end
    end
  end
  if anySales then
    local convs = L:Convert(sales, info.moneyPos or 0, { t = now, via = 'vendor', priceOf = priceOf })
    c.conversions = c.conversions + #convs
  end
  if anyConsume then c.conversions = c.conversions + #L:Convert(consume, 0, { t = now, via = 'consume' }) end
  if anyTrade then c.conversions = c.conversions + #L:Convert(trade, 0, { t = now, via = 'trade' }) end
  -- purchases share the money that left the character in this entry, per unit
  local buys, weights = {}, {}
  for _, d in ipairs(decisions) do
    if d.dir == 'add' and d.how == 'vendorBuy' then buys[#buys + 1] = d; weights[#weights + 1] = d.qty end
  end
  local costs = (#buys > 0) and GI.Lots.AllocateCopper(info.moneyNeg or 0, weights) or {}
  local bi = 0
  for _, d in ipairs(decisions) do
    if d.dir == 'add' then
      if d.how == 'loot' then addLot(d, now, 'loot', 'free', true)
      elseif d.how == 'quest' then addLot(d, now, 'quest', 'free', true)
      elseif d.how == 'disenchantMat' then addLot(d, now, 'disenchant', 'free', false, { conversion = true })
      elseif d.how == 'vendorBuy' then
        bi = bi + 1
        c.purchases = c.purchases + 1
        addLot(d, now, 'vendor', 'purchase', false, nil, costs[bi] or 0)
      elseif d.how == 'mail' or d.how == 'trade' then c.arrivals = c.arrivals + 1
      else c.otherAdds = c.otherAdds + 1 end
    end
  end
  L:ExpirePending(now)
  L:Compact()
end

local function onItemInfo(p)
  if not active or not L or not p.ready then return end
  local info = P.ItemsModule.Get(p.itemID)
  if info.status == 'ready' then L:Complete(p.itemID, info, LB.ManualFor(p.itemID), unixNow()) end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------

local wired = false

--- Called by Ledger.Begin after ItemSources.Begin. Returns true when lots are being stored.
function LB.Begin()
  if active then return true end
  fresh()
  told = {}
  readonly = false
  if not (GI.Store and GI.Store.IsWritable()) then readonly = true; return false end
  local s, key = lotsState(true)
  if not s then readonly = true; return false end
  state, charKeyNow = s, key
  L = GI.Lots.New(s, { alert = alert, emit = emit })
  active = true
  if not wired then
    wired = true
    P.On('P_ITEM_INFO', function(p) local ok, err = pcall(onItemInfo, p); if not ok then c.errors = c.errors + 1; P.Diag('error', 'LotBook', tostring(err)) end end)
  end
  if GI.ItemSources then GI.ItemSources.sink = LB.OnDecisions end
  -- lots still waiting for item data (a previous session, a cold cache): ask again and complete what is ready now
  local seen, now = {}, unixNow()
  for _, lot in ipairs(s.open) do
    if lot.valueSrc == 'unknown' and not (lot.flags and lot.flags.invalid) and not seen[lot.itemID] then
      seen[lot.itemID] = true
      local info = P.ItemsModule.Get(lot.itemID)
      if info.status == 'ready' then L:Complete(lot.itemID, info, LB.ManualFor(lot.itemID), now) end
    end
  end
  return true
end

function LB.End()
  if GI.ItemSources and GI.ItemSources.sink == LB.OnDecisions then GI.ItemSources.sink = nil end
  active = false
end

function LB.IsActive() return active end
function LB.ReadOnly() return readonly end
function LB.Instance() return L end

--- Test helper.
function LB.Reset() active, readonly, L, state = false, false, nil, nil; told = {}; fresh() end

---------------------------------------------------------------------------
-- Reports (lines of text; the commands print them)
---------------------------------------------------------------------------

local function fmt(cop)
  cop = cop or 0
  local g, s, cc = math.floor(cop / 10000), math.floor(cop / 100) % 100, math.floor(cop % 100)
  local parts = {}
  if g > 0 then parts[#parts + 1] = string.format('%dg', g) end
  if s > 0 then parts[#parts + 1] = string.format('%ds', s) end
  if cc > 0 or #parts == 0 then parts[#parts + 1] = string.format('%dc', cc) end
  return table.concat(parts, ' ')
end
LB.Format = fmt

local function nameOf(id)
  local info = P.ItemsModule and P.ItemsModule.Get(id)
  if info and info.status == 'ready' and info.name then return info.name end
  return 'item ' .. tostring(id)
end

--- The stored state even when the interval is off.
local function view()
  if L then return L end
  local s = lotsState(false)
  if not s then return nil end
  return GI.Lots.New(s, {}), s
end

function LB.Status()
  local lines = {}
  local v = view()
  if not v then
    lines[1] = 'lots stored: none yet for this character'
    return lines
  end
  local st = v:Stats()
  lines[#lines + 1] = string.format('lots stored: %d open (%d units), %d recent closed; inventory value (acquired, not known disposed) %s',
    st.openLots, st.openQty, st.closedRing, fmt(st.inventoryValue))
  lines[#lines + 1] = string.format('value created by loot and quests: %s in %d lots; unknown value: %d lots / %d items',
    fmt(st.created.value), st.created.n, st.unknown.lots, st.unknown.items)
  lines[#lines + 1] = string.format('conversions not covered by a lot (normal, D-081): %d units, %s unallocated; merged lots %d',
    st.shortfall, fmt(st.unallocated), st.merged)
  lines[#lines + 1] = string.format('this interval: batches %d, lots created %d (purchases %d), conversions %d, ignored removals %d, mail/trade arrivals %d, other additions (moves, returns, unknown) %d, errors %d',
    c.batches, c.lotsCreated, c.purchases, c.conversions, c.ignoredRemovals, c.arrivals, c.otherAdds, c.errors)
  local bv = (view() and select(2, view())) or state
  local via = bv and bv.totals and bv.totals.byVia
  if via then
    local order = {}
    for k in pairs(via) do order[#order + 1] = k end
    table.sort(order)
    local parts = {}
    for _, k in ipairs(order) do parts[#parts + 1] = string.format('%s %d units for %s', k, via[k].qty, fmt(via[k].copper)) end
    if #parts > 0 then lines[#lines + 1] = 'conversions so far: ' .. table.concat(parts, '; ') end
  end
  local an = {}
  for k, n in pairs(st.anomalies) do an[#an + 1] = k .. ' ' .. n end
  table.sort(an)
  if #an > 0 then lines[#lines + 1] = 'ANOMALIES (not expected, please report as a bug): ' .. table.concat(an, ', ') end
  if readonly then lines[#lines + 1] = 'the store is read-only: nothing is being saved' end
  return lines
end

function LB.Last(n)
  n = math.max(1, math.min(tonumber(n) or 10, 30))
  local v, s = view()
  local lines = {}
  if not v then return { 'lots: none yet for this character' } end
  s = s or state
  local all = {}
  for _, lot in ipairs(s.closed) do all[#all + 1] = lot end
  for _, lot in ipairs(s.open) do all[#all + 1] = lot end
  table.sort(all, function(a, b) return a.id < b.id end)
  for i = math.max(1, #all - n + 1), #all do
    local lot = all[i]
    local worth = (lot.flags and lot.flags.noVendor and lot.valueSrc == 'vendor') and 'no vendor value'
      or (fmt(lot.valueEach) .. ' each [' .. lot.valueSrc .. ']')
    local act = lot.origin and lot.origin.act
    lines[#lines + 1] = string.format('#%d %s x%d (%d left) %s %s/%s%s%s%s', lot.id, nameOf(lot.itemID), lot.qty, lot.qtyLeft,
      worth, lot.src, lot.how, act and (' ' .. act .. (lot.origin.skinning and ' (skinning)' or '')) or '', lot.vc and ' value-created' or '',
      (lot.flags and lot.flags.unknown) and (lot.flags.invalid and ' UNKNOWN(invalid item)' or ' UNKNOWN(waiting for item data)') or '')
  end
  if #lines == 0 then lines[1] = 'lots: none yet for this character' end
  return lines
end

--- The most recent conversions (what each lot received when it left), newest last.
function LB.Sales(n)
  n = math.max(1, math.min(tonumber(n) or 15, 40))
  local _, s = view()
  s = s or state
  if not s or #s.conv == 0 then return { 'lots: no conversions yet' } end
  local lines = {}
  for i = math.max(1, #s.conv - n + 1), #s.conv do
    local cv = s.conv[i]
    lines[#lines + 1] = string.format('lot #%d %s x%d -> %s via %s%s', cv.lotID, nameOf(cv.itemID), cv.qty, fmt(cv.copper), cv.via, cv.alloc and ' (split)' or '')
  end
  return lines
end

function LB.Unknown()
  local _, s = view()
  s = s or state
  local lines, byItem, order = {}, {}, {}
  if s then
    for _, lot in ipairs(s.open) do
      if lot.valueSrc == 'unknown' then
        local e = byItem[lot.itemID]
        if not e then e = { qty = 0, invalid = false }; byItem[lot.itemID] = e; order[#order + 1] = lot.itemID end
        e.qty = e.qty + lot.qtyLeft
        if lot.flags and lot.flags.invalid then e.invalid = true end
      end
    end
  end
  table.sort(order)
  for _, id in ipairs(order) do
    local e = byItem[id]
    lines[#lines + 1] = string.format('item %d %s x%d: %s', id, nameOf(id), e.qty, e.invalid and 'invalid item id (stays unknown)' or 'waiting for item data (retried at login and when the data arrives)')
  end
  if #lines == 0 then lines[1] = 'lots: no unknown values' end
  return lines
end

--- Optional diagnostic (D-081): stored open quantities against what is in the bags now. Differences are expected
--- (items used, destroyed, moved to the bank or acquired before tracking); this is not an invariant.
function LB.Check()
  local v = view()
  if not v then return { 'lots check: no lots stored for this character' } end
  local snap = P.BagsModule and P.BagsModule.Snapshot()
  if not snap then return { 'lots check: the bags could not be read now' } end
  local ok, diffs = v:Check(snap.items)
  local ids = {}
  for id in pairs(diffs) do ids[#ids + 1] = id end
  table.sort(ids)
  local lines = { string.format('lots check (diagnostic only): %d item ids differ from the bags%s', #ids, snap.complete and '' or ' (bag read incomplete)') }
  for i = 1, math.min(#ids, 10) do
    local id, d = ids[i], diffs[ids[i]]
    lines[#lines + 1] = string.format('  %s: %s%d (%s)', nameOf(id), d > 0 and '+' or '', d, d > 0 and 'lots hold more than the bags' or 'bags hold more than the lots')
  end
  if #ids > 10 then lines[#lines + 1] = string.format('  ... and %d more', #ids - 10) end
  return lines
end

--- Deletes the current character's lots only. The caller has already checked for the word "confirm".
function LB.ResetCurrent()
  if not (GI.Store and GI.Store.IsWritable()) then return false, 'the store is read-only' end
  local key = charKey()
  local sec = section('lots')
  if not key or not sec then return false, 'no character identity' end
  sec[key] = nil
  if active then
    local s = lotsState(true)
    state = s
    L = GI.Lots.New(s, { alert = alert, emit = emit })
  else
    L = nil
  end
  told = {}
  return true
end

---------------------------------------------------------------------------
-- /gi price  (optional manual override, never used unless set; D-082)
---------------------------------------------------------------------------

if GI.Commands then
  local function say(line) P.Print(line) end
  GI.Commands.Register('price', {
    help = 'optional manual item price (override): set <item id or link> <1g20s5c> | list | clear <item id or link>',
    usage = 'price set <item> <price> | list | clear <item>',
    fn = function(args)
      local sub = args[1]
      local function itemId()
        local rest = table.concat(args, ' ', 2)
        return tonumber(rest:match('item:(%d+)')) or tonumber(args[2])
      end
      if sub == 'list' or sub == nil then
        local list = LB.PriceList()
        if #list == 0 then say('prices: no manual prices set (the vendor value is used)'); return end
        for _, e in ipairs(list) do say(string.format('manual price: %s (item %d) = %s', nameOf(e.itemID), e.itemID, fmt(e.copper))) end
      elseif sub == 'set' then
        local id = itemId()
        if not id then say('usage: /gi price set <item id or link> <price such as 1g20s5c>'); return end
        local copper, err = LB.ParseMoney(args[#args])
        if #args < 3 or not copper then say('prices: ' .. tostring(err or 'a price like 1g20s5c is required')); return end
        local ok, why = LB.PriceSet(id, copper)
        if ok then
          say(string.format('prices: item %d (%s) manual price %s. It is used only when higher than the vendor value, for new lots and current views; past values are not changed.', id, nameOf(id), fmt(copper)))
        else
          say('prices: ' .. tostring(why))
        end
      elseif sub == 'clear' then
        local id = itemId()
        if not id then say('usage: /gi price clear <item id or link>'); return end
        say(LB.PriceClear(id) and ('prices: manual price for item ' .. id .. ' removed') or ('prices: no manual price for item ' .. id))
      else
        say('usage: /gi price set <item> <price> | list | clear <item>')
      end
    end,
  })
end
