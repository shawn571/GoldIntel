--[[
GoldIntel / Tests / helpers / collectworld.lua                          (Phase 3b-1)

A fake client for the collector tests: the normal fake (fake_wow.lua) plus loot window, merchant,
mailbox, auction house, bags, item data and secret values, driven through W.state. Boots the whole
addon from the TOC.

    local W, P, ns = World.boot()        -- addon loaded, logged in, Core started
    W.state.loot = { guid = 'Creature-0-1-0-1-95-X', slots = { { type = 2, amount = 8 }, ... } }
    W.state.mailShown = true
    local seen = World.capture(P, 'P_LOOT_OPEN', 'P_LOOT_CLOSE')    -- list of { name, payload }
]]

local Fake = require('fake_wow')
local Loader = require('loader')

local World = {}

World.SECRET = { __secret = true }      -- sentinel: issecretvalue(World.SECRET) is true

local unpack = table.unpack or unpack

function World.extend(W)
  local s, env = W.state, W.env
  s.loot = { guid = 'Creature-0-4621-0-1-95-AAAA', slots = {} }
  s.mailShown, s.ahShown = false, false
  s.inbox = {}               -- array of { header = {...returns}, invoice = {...returns} }
  s.bags = {}                -- [bag] = array of { itemID, stackCount } (nil = empty slot)
  s.items = {}               -- [itemID] = { name, link, quality, ..., sellPrice(11), ..., bindType(14) }
  s.cached = {}              -- [itemID] = true when GetItemInfo returns data
  s.loadRequests = {}

  env.issecretvalue = function(v) return type(v) == 'table' and v.__secret == true end

  -- Loot ------------------------------------------------------------------
  env.GetNumGroupMembers = function() if s.group == 'absent' then error('nope') end return (s.group and s.group.n) or 0 end
  env.IsInGroup = function() return s.group ~= nil and s.group ~= 'absent' and s.group.n > 1 end
  env.IsInRaid = function() return false end
  env.GetNumLootItems = function() return #s.loot.slots end
  env.GetLootSlotType = function(i) local x = s.loot.slots[i]; return x and x.type end
  env.GetLootSourceInfo = function(i)
    local x = s.loot.slots[i]
    if not x then return nil end
    return x.guid or s.loot.guid, x.amount or x.qty or 1
  end
  env.GetLootSlotLink = function(i) local x = s.loot.slots[i]; return x and x.link end
  env.GetLootSlotInfo = function(i)
    local x = s.loot.slots[i]
    if not x then return nil end
    return 133788, x.name or 'x', x.qty or 0, nil, 1, false, false
  end

  -- Frames polled for visibility --------------------------------------------
  env.MailFrame = { IsShown = function() return s.mailShown end }
  env.AuctionHouseFrame = { IsShown = function() return s.ahShown end }
  -- LootFrame (E-42): shown at the same instant as LOOT_OPENED. W.state.lootShown = false closes it;
  -- W.state.lootFrame = 'missing' | 'error' | 'secret' | 'hidden-at-open' simulate unreadable cases.
  s.lootShown = false
  env.LootFrame = { IsShown = function()
    if s.lootFrame == 'error' then error('boom') end
    if s.lootFrame == 'secret' then return World.SECRET end
    return s.lootShown
  end }
  local rawFire = W.fire
  function W:fire(event, ...)
    if event == 'LOOT_OPENED' then
      if s.lootFrame == 'missing' then env.LootFrame = nil
      elseif s.lootFrame ~= 'hidden-at-open' then s.lootShown = true end
    end
    return rawFire(self, event, ...)
  end

  -- Mailbox ---------------------------------------------------------------
  env.GetInboxNumItems = function() return #s.inbox, #s.inbox end
  env.GetInboxHeaderInfo = function(i)
    local m = s.inbox[i]
    if not m then return nil end
    return unpack(m.header, 1, 15)
  end
  env.GetInboxInvoiceInfo = function(i)
    local m = s.inbox[i]
    if not m or not m.invoice then return nil, nil, nil, 0, 0, 0, 0 end
    return unpack(m.invoice, 1, 12)
  end

  -- Bags and items ----------------------------------------------------------
  env.C_Container = {
    GetContainerNumSlots = function(bag) local b = s.bags[bag]; return b and (b.size or #b) or 0 end,
    GetContainerItemInfo = function(bag, slot)
      local b = s.bags[bag]
      local e = b and b[slot]
      if not e then return nil end
      return { itemID = e[1], stackCount = e[2] }
    end,
  }
  env.C_Item = {
    GetItemInfo = function(id)
      if not s.cached[id] then return nil end
      local it = s.items[id]
      if not it then return nil end
      return unpack(it, 1, 17)
    end,
    RequestLoadItemDataByID = function(id) s.loadRequests[#s.loadRequests + 1] = id end,
  }
  return W
end

--- Builds a mail header tuple in the order of E-29/E-39.
function World.header(t)
  return { t.icon, 134327, t.sender or 'Someone', t.subject or '', t.money or 0, t.cod or 0, t.days or 30.9,
           t.itemCount, false, false, t.textCreated or false, t.canReply ~= false, false, t.firstQty, t.firstLink }
end

--- Boots the whole addon (TOC order) with the extended fake, optionally logs in.
function World.boot(opts)
  opts = opts or {}
  local W = Fake.new(opts.fake)
  World.extend(W)
  local P, ns = Loader.load(W.env)
  if opts.login ~= false then W:login() end
  return W, P, ns
end

--- Records normalized events. Returns a list that fills as events fire.
function World.capture(P, ...)
  local seen = {}
  for _, name in ipairs({ ... }) do
    P.On(name, function(payload) seen[#seen + 1] = { name = name, payload = payload } end)
  end
  return seen
end

--- Number of captured events with this name.
function World.count(seen, name)
  local n = 0
  for _, e in ipairs(seen) do if e.name == name then n = n + 1 end end
  return n
end

return World
