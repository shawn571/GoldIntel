-- GoldIntel / Platform / Items.lua                                      (Phase 3b-1)
--
-- Item data adapter (E-17, E-30).
--   Items.Get(itemID) -> { status = 'ready' | 'pending' | 'secret' | 'invalid', name?, quality?,
--                          sellPrice?, classID?, subclassID?, bindType? }   (classID/subclassID: M2 evidence, 12th/13th returns)
--   An empty GetItemInfo is NEVER a price of 0 (D-045/D-046): the status says 'pending' and a load is
--   requested. GET_ITEM_INFO_RECEIVED(itemID, success) -> P_ITEM_INFO { itemID, ready }.
--   Items already cached produce no event, so callers check Items.Get first.
-- GetItemInfo order (E-30): name, link, quality, ilvl, minLevel, type, subtype, stack, equipLoc, icon,
-- SELL PRICE (11), classID, subclassID, BIND TYPE (14).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Items.lua')

local Items = {}
P.ItemsModule = Items
P.Register('Items', Items)

Items.stats = { lookups = 0, pending = 0, received = 0, failed = 0, secret = 0 }

function Items.Get(itemID)
  if type(itemID) ~= 'number' or itemID <= 0 or P.IsSecret(itemID) then return { status = 'invalid' } end
  Items.stats.lookups = Items.stats.lookups + 1
  local r
  if P.HasIn('C_Item', 'GetItemInfo') then r = P.CallIn('C_Item', 'GetItemInfo', itemID)
  else r = P.Call('GetItemInfo', itemID) end
  if not r or r[1] == nil then
    Items.stats.pending = Items.stats.pending + 1
    if P.HasIn('C_Item', 'RequestLoadItemDataByID') then P.CallIn('C_Item', 'RequestLoadItemDataByID', itemID) end
    return { status = 'pending' }
  end
  for i = 1, r.n do
    if P.IsSecret(r[i]) then
      Items.stats.secret = Items.stats.secret + 1
      return { status = 'secret' }
    end
  end
  return { status = 'ready', name = r[1], quality = r[3], sellPrice = r[11], classID = r[12], subclassID = r[13], bindType = r[14] }
end

local function onInfo(_, itemID, success)
  if type(itemID) ~= 'number' or P.IsSecret(itemID) or P.IsSecret(success) then return 'dropped' end
  Items.stats.received = Items.stats.received + 1
  if success ~= true then Items.stats.failed = Items.stats.failed + 1 end
  P.Events.Emit('P_ITEM_INFO', { itemID = itemID, ready = success == true })
end

Items.OnInfo = onInfo
function Items.Reset() Items.stats = { lookups = 0, pending = 0, received = 0, failed = 0, secret = 0 } end

P.RegisterCollectAdapter({ name = 'Items', handlers = { GET_ITEM_INFO_RECEIVED = onInfo } })
