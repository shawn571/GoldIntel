-- GoldIntel / Platform / Auction.lua                                    (Phase 3b-1)
--
-- Auction House adapter (context only).
--   * Window state by polling AuctionHouseFrame:IsShown() every 0.5 s while collecting (E-35): P_AH_OPEN
--     and P_AH_CLOSE.
--   * AUCTION_HOUSE_AUCTION_CREATED (approved D-074 A-1) -> P_AH_POSTED. E-36: it fires once per
--     posting, 0.358 s BEFORE the deposit leaves the balance. Its payload is not read.
-- Owned auctions are not readable passively (E-35) and nothing is queried here.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Auction.lua')

local Auction = {}
P.AuctionModule = Auction
P.Register('Auction', Auction)

Auction.POLL = 0.5
local open = false
local cancelPoll = nil
Auction.stats = { opened = 0, closed = 0, posted = 0 }

function Auction.FrameShown()
  local frame = P.env.AuctionHouseFrame
  if type(frame) ~= 'table' or type(frame.IsShown) ~= 'function' then return nil end
  local ok, shown = pcall(frame.IsShown, frame)
  if not ok then return nil end
  return shown and true or false
end

function Auction.IsOpen() return open end

function Auction.Tick()
  local shown = Auction.FrameShown()
  if shown == nil or shown == open then return end
  open = shown
  if shown then
    Auction.stats.opened = Auction.stats.opened + 1
    P.Events.Emit('P_AH_OPEN', {})
  else
    Auction.stats.closed = Auction.stats.closed + 1
    P.Events.Emit('P_AH_CLOSE', {})
  end
end

local function onCreated()
  Auction.stats.posted = Auction.stats.posted + 1
  P.Events.Emit('P_AH_POSTED', {})
end

function Auction.Start()
  if cancelPoll then cancelPoll() end
  cancelPoll = P.Every(Auction.POLL, Auction.Tick)
end

function Auction.Stop()
  if cancelPoll then cancelPoll(); cancelPoll = nil end
  open = false
end

function Auction.Reset()
  Auction.Stop()
  Auction.stats = { opened = 0, closed = 0, posted = 0 }
end

Auction.OnCreated = onCreated

P.RegisterCollectAdapter({
  name = 'Auction',
  handlers = { AUCTION_HOUSE_AUCTION_CREATED = function() return onCreated() end },
  start = Auction.Start, stop = Auction.Stop,
})
