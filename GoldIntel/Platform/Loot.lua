-- GoldIntel / Platform / Loot.lua                                       (Phase 3b-1)
--
-- PURPOSE
--  Loot window adapter. Raw LOOT_OPENED and LOOT_SLOT_CLEARED become:
--      P_LOOT_OPEN  { sourceType }      once per window ('creature' | 'object' | 'item' | 'unknown')
--      P_LOOT_MONEY { copper, source }  one per coin slot offered (a HINT, never the ledger amount)
--      P_LOOT_ITEM  { itemID, qty, source } one per item slot offered
--      P_LOOT_CLOSE { by }              'frame' | 'timeout' | 'replaced'
--
-- EVIDENCE
--  E-18/E-19: coin slot type 2, amount = 2nd return of GetLootSourceInfo; item slot type 1, item id
--  from the link; all readable, also in combat. E-20: LOOT_SLOT_CLEARED can arrive twice for one slot
--  (de-duplicated here). E-24: one GUID can open several windows (never key by GUID alone).
--  E-41: the first rule (close 1.0 s after the last clear, 10 s timeout) was FALSIFIED live: 6 of 6
--  windows closed by timeout, because the player keeps the window open for 20-30 s.
--  E-42 (D-075): LootFrame:IsShown() tracks the window exactly (8 windows, empty corpses, Escape,
--  walk-away, partial loot, close and reopen). So:
--     open  = LOOT_OPENED (LootFrame shown at the same instant)
--     close = LootFrame:IsShown() false, polled every 0.1 s only while a window is open  -> by 'frame'
--     slot clears are INFORMATION ONLY (counted, de-duplicated, never close anything)
--     a 300 s timer is a RECOVERY backstop, not a normal path                            -> by 'timeout'
--     if LootFrame cannot be read the old rule is used for that window (counted as
--     frameUnreadable and legacyWindows; its closes are reported as 'timeout').
--  The 1.0 s linger after a close lives in Collect/Context.lua (money arrives about 0.05 s after the
--  frame hides, E-42).
--
-- This module reads no bags, prices nothing and writes nothing.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Loot.lua')

local Loot = {}
P.LootModule = Loot
P.Register('Loot', Loot)

Loot.POLL = 0.1            -- seconds between LootFrame checks while a window is open (E-42)
Loot.BACKSTOP = 300.0      -- recovery only; the longest observed window was 30.7 s (E-42)
Loot.AFTER_CLEAR = 1.0     -- legacy rule, used only when LootFrame cannot be read
Loot.FALLBACK = 10.0       -- legacy rule, used only when LootFrame cannot be read
Loot.MAX_SLOTS = 40

local SLOT_ITEM, SLOT_MONEY = 1, 2     -- GetLootSlotType (E-18/E-19)

local function tapped(...)           -- diagnostic tap (Ledger/Trace.lua); never changes behaviour
  if Loot.tap then pcall(Loot.tap, ...) end
end

local state = { open = false, id = 0, cleared = {}, legacy = false,
               cancelClose = nil, cancelFallback = nil, cancelPoll = nil }
local function freshStats()
  return { opened = 0, closedFrame = 0, closedTimeout = 0, closedReplaced = 0, clears = 0, lateClears = 0,
           dupClears = 0, unreadable = 0, frameUnreadable = 0, legacyWindows = 0, maxOpenSec = 0 }
end
Loot.stats = freshStats()

local function typeOf(guid)
  if type(guid) ~= 'string' or P.IsSecret(guid) then return 'unknown' end
  local t = guid:match('^(%a+)%-')
  if t == 'Creature' or t == 'Vehicle' then return 'creature' end
  if t == 'GameObject' then return 'object' end
  if t == 'Item' then return 'item' end
  return 'unknown'
end

local function cancelTimers()
  if state.cancelClose then state.cancelClose(); state.cancelClose = nil end
  if state.cancelFallback then state.cancelFallback(); state.cancelFallback = nil end
  if state.cancelPoll then state.cancelPoll(); state.cancelPoll = nil end
end

local function close(by)
  if not state.open then return end
  cancelTimers()
  state.open = false
  if state.openedAt then
    local dur = P.Clock.Since(state.openedAt)
    if dur > Loot.stats.maxOpenSec then Loot.stats.maxOpenSec = dur end
  end
  if by == 'frame' then Loot.stats.closedFrame = Loot.stats.closedFrame + 1
  elseif by == 'timeout' then Loot.stats.closedTimeout = Loot.stats.closedTimeout + 1
  else Loot.stats.closedReplaced = Loot.stats.closedReplaced + 1 end
  tapped('close', by, state.openedAt and P.Clock.Since(state.openedAt) or 0)
  P.Events.Emit('P_LOOT_CLOSE', { by = by })
end

--- True when LootFrame is shown, false when hidden, nil when it cannot be read.
function Loot.FrameShown()
  local frame = P.env.LootFrame
  if type(frame) ~= 'table' or type(frame.IsShown) ~= 'function' then return nil end
  local ok, shown = pcall(frame.IsShown, frame)
  if not ok or P.IsSecret(shown) then return nil end
  return shown and true or false
end

local function num(v)
  if type(v) ~= 'number' or P.IsSecret(v) or v ~= v then return nil end
  return v
end

--- Reads the slots of the open loot window. Returns { sourceType, coins = {...}, items = {...} }.
function Loot.ReadWindow()
  local out = { sourceType = 'unknown', coins = {}, items = {}, detail = {} }
  local n = P.Call('GetNumLootItems')
  local count = n and num(n[1]) or 0
  out.raw = count
  if count > Loot.MAX_SLOTS then count = Loot.MAX_SLOTS end
  local first = true
  for i = 1, count do
    local kind = P.Call('GetLootSlotType', i)
    local slotType = kind and num(kind[1]) or nil
    local src = P.Call('GetLootSourceInfo', i)
    do
      local g = src and src[1]
      local tail = (type(g) == 'string' and not P.IsSecret(g)) and g:sub(-6) or '?'
      out.detail[#out.detail + 1] = string.format('s%d:t%s:a%s:g%s', i, tostring(slotType), tostring(src and num(src[2]) or '?'), tail)
    end
    if first and src then
      out.sourceType = typeOf(src[1]); first = false
      if type(src[1]) == 'string' and not P.IsSecret(src[1]) then out.guid = src[1] end      -- the corpse/object identity (skinning = a repeat window of the same guid, E-24)
    end
    if slotType == SLOT_MONEY then
      local amount = src and num(src[2]) or nil
      if amount and amount > 0 then out.coins[#out.coins + 1] = math.floor(amount) end
    elseif slotType == SLOT_ITEM then
      local link = P.Call('GetLootSlotLink', i)
      local text = link and link[1]
      local id = (type(text) == 'string' and not P.IsSecret(text)) and tonumber(text:match('item:(%d+)')) or nil
      local info = P.Call('GetLootSlotInfo', i)
      local qty = info and num(info[3]) or nil
      if id then out.items[#out.items + 1] = { itemID = id, qty = qty and math.max(1, math.floor(qty)) or 1 } end
    else
      Loot.stats.unreadable = Loot.stats.unreadable + 1
    end
  end
  out.slots = count
  return out
end

--- The old rule, kept only for a window whose frame cannot be read (counted separately).
local function enterLegacy(id)
  if state.cancelPoll then state.cancelPoll(); state.cancelPoll = nil end
  if state.cancelFallback then state.cancelFallback(); state.cancelFallback = nil end
  if state.cancelClose then state.cancelClose(); state.cancelClose = nil end
  state.legacy = true
  Loot.stats.frameUnreadable = Loot.stats.frameUnreadable + 1
  Loot.stats.legacyWindows = Loot.stats.legacyWindows + 1
  if next(state.cleared) ~= nil then
    state.cancelClose = P.After(Loot.AFTER_CLEAR, function()
      state.cancelClose = nil
      if state.open and state.id == id then close('timeout') end
    end)
  else
    state.cancelFallback = P.After(Loot.FALLBACK, function()
      state.cancelFallback = nil
      if state.open and state.id == id and next(state.cleared) == nil then close('timeout') end
    end)
  end
end

--- One check of the loot frame (called every Loot.POLL seconds while a window is open).
function Loot.Tick(id)
  if not state.open or state.legacy or (id and id ~= state.id) then return end
  local shown = Loot.FrameShown()
  if shown == false then
    close('frame')
  elseif shown == nil then
    enterLegacy(state.id)       -- the frame became unreadable mid-window
  end
end

local function onOpened()
  if state.open then close('replaced') end
  state.id = state.id + 1
  state.open = true
  state.cleared = {}
  Loot.stats.opened = Loot.stats.opened + 1
  local id = state.id
  local w = Loot.ReadWindow()
  w.frame = Loot.FrameShown()
  tapped('open', w)
  P.Events.Emit('P_LOOT_OPEN', { sourceType = w.sourceType, guid = w.guid })
  for _, copper in ipairs(w.coins) do P.Events.Emit('P_LOOT_MONEY', { copper = copper, source = w.sourceType }) end
  for _, it in ipairs(w.items) do
    P.Events.Emit('P_LOOT_ITEM', { itemID = it.itemID, qty = it.qty, source = w.sourceType })
  end
  local _, gt = P.Now()
  state.openedAt = gt
  state.legacy = false
  if Loot.FrameShown() == true then
    state.cancelPoll = P.Every(Loot.POLL, function() Loot.Tick(id) end)
    state.cancelFallback = P.After(Loot.BACKSTOP, function()
      state.cancelFallback = nil
      if state.open and state.id == id then close('timeout') end
    end)
  else
    enterLegacy(id)           -- LootFrame missing, unreadable, or not shown when the event arrived
  end
end

local function onCleared(_, slot)
  slot = num(slot)
  if not slot then return 'dropped' end
  if not state.open then
    Loot.stats.lateClears = Loot.stats.lateClears + 1
    return 'dropped'
  end
  if state.cleared[slot] then
    Loot.stats.dupClears = Loot.stats.dupClears + 1       -- E-20: the client sends a slot twice
    return 'dropped'
  end
  state.cleared[slot] = true
  tapped('clear', slot)
  Loot.stats.clears = Loot.stats.clears + 1          -- information only (D-075)
  if state.legacy then
    if state.cancelFallback then state.cancelFallback(); state.cancelFallback = nil end
    if state.cancelClose then state.cancelClose() end
    local id = state.id
    state.cancelClose = P.After(Loot.AFTER_CLEAR, function()
      state.cancelClose = nil
      if state.open and state.id == id then close('timeout') end
    end)
  end
end

--- True while a loot window is considered open.
function Loot.IsOpen() return state.open end

function Loot.Stop()
  cancelTimers()
  state.open = false
  state.cleared = {}
end

function Loot.Reset()
  Loot.Stop()
  state.id = 0
  Loot.stats = freshStats()
end

Loot.OnOpened = function() onOpened() end
Loot.OnCleared = onCleared

P.RegisterCollectAdapter({
  name = 'Loot',
  handlers = { LOOT_OPENED = function(_, ...) return Loot.OnOpened(...) end, LOOT_SLOT_CLEARED = onCleared },
  stop = Loot.Stop,
})
