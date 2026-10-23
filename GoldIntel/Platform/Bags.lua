-- GoldIntel / Platform / Bags.lua                                       (Phase 3b-1)
--
-- Bag adapter: BAG_UPDATE_DELAYED -> P_BAGS_SETTLED (E-32: it fires once after a change settles, 0.15 s
-- before and 0.289 s after the money event). Bags.Snapshot() is a read-only aggregate item id -> quantity
-- (C_Container.GetContainerItemInfo, E-17: the legacy globals do not exist). The diff logic that turns
-- two snapshots into lots belongs to 3b-3 (Collect/BagDiff.lua, Collect/ItemSources.lua); nothing here is stored.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Bags.lua')

local Bags = {}
P.BagsModule = Bags
P.Register('Bags', Bags)

Bags.FIRST_BAG, Bags.LAST_BAG = 0, 5     -- E-32 read bags 0 to 5 (52 slots); a bag index that does not exist reports 0 slots
Bags.RANGE_MAX = 8                       -- evidence only: Bags.Ranges() asks bag indexes 0..8 what they hold
Bags.stats = { settled = 0, snapshots = 0, unreadable = 0, incomplete = 0 }

--- Returns { items = { [itemID] = quantity }, slots = number read, complete = boolean, bags = { [bag] = slotCount } }
-- or nil plus a reason. complete == false when ANY slot or count could not be read (secret value): a quantity that is
-- not exactly known never counts as complete (BagDiff refuses incomplete snapshots, D-080 AC-14).
function Bags.Snapshot()
  if not P.HasIn('C_Container', 'GetContainerNumSlots') or not P.HasIn('C_Container', 'GetContainerItemInfo') then
    return nil, 'C_Container unavailable'
  end
  local items, read, bad, bags = {}, 0, 0, {}
  for bag = Bags.FIRST_BAG, Bags.LAST_BAG do
    local n = P.CallIn('C_Container', 'GetContainerNumSlots', bag)
    local slots = 0
    if n and type(n[1]) == 'number' and not P.IsSecret(n[1]) then slots = n[1]
    elseif n and n[1] ~= nil then bad = bad + 1 end
    bags[bag] = slots
    for slot = 1, slots do
      local r = P.CallIn('C_Container', 'GetContainerItemInfo', bag, slot)
      local info = r and r[1]
      if type(info) == 'table' then
        local id, count = info.itemID, info.stackCount
        if type(id) == 'number' and not P.IsSecret(id) then
          if type(count) ~= 'number' or P.IsSecret(count) then count = 1; bad = bad + 1 end
          items[id] = (items[id] or 0) + count
          read = read + 1
        else
          bad = bad + 1
        end
      end
    end
  end
  Bags.stats.snapshots = Bags.stats.snapshots + 1
  Bags.stats.unreadable = Bags.stats.unreadable + bad
  if bad > 0 then Bags.stats.incomplete = Bags.stats.incomplete + 1 end
  return { items = items, slots = read, complete = bad == 0, bags = bags }
end

--- Evidence (D-080 M2): the slot count of bag indexes 0..RANGE_MAX, plus the client constants that describe them.
function Bags.Ranges()
  local out = { slots = {}, constants = {} }
  for bag = 0, Bags.RANGE_MAX do
    local r = P.HasIn('C_Container', 'GetContainerNumSlots') and P.CallIn('C_Container', 'GetContainerNumSlots', bag) or nil
    local n = r and r[1]
    out.slots[bag] = (type(n) == 'number' and not P.IsSecret(n)) and n or nil
  end
  local env = P.env or {}
  for _, k in ipairs({ 'NUM_BAG_SLOTS', 'NUM_TOTAL_EQUIPPED_BAG_SLOTS', 'NUM_REAGENTBAG_SLOTS' }) do
    local v = env[k]
    if type(v) == 'number' then out.constants[k] = v end
  end
  return out
end

local function onSettled()
  Bags.stats.settled = Bags.stats.settled + 1
  P.Events.Emit('P_BAGS_SETTLED', {})
end

Bags.OnSettled = onSettled
function Bags.Reset() Bags.stats = { settled = 0, snapshots = 0, unreadable = 0, incomplete = 0 } end

P.RegisterCollectAdapter({ name = 'Bags', handlers = { BAG_UPDATE_DELAYED = function() return onSettled() end } })
