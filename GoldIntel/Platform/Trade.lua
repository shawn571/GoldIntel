-- GoldIntel / Platform / Trade.lua                                      (Phase 3b-1)
--
-- Trade window adapter. TRADE_SHOW -> P_TRADE_OPEN, the FIRST TRADE_CLOSED of a window ->
-- P_TRADE_CLOSE. E-31: TRADE_CLOSED arrives twice per close (the second is dropped); the trade money
-- lands 0.394 s after the close; a cancelled trade changes no money. TRADE_ACCEPT_UPDATE and
-- TRADE_MONEY_CHANGED are counted and remembered (flags readable through Trade.State()) but emit
-- nothing; the item side of a trade is not read (never probed).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Trade.lua')

local Trade = {}
P.TradeModule = Trade
P.Register('Trade', Trade)

local open = false
local flags = { moneyChanged = false, acceptUpdates = 0 }
Trade.stats = { opened = 0, closed = 0, duplicateCloses = 0, duplicateOpens = 0 }

local function onShow()
  if open then
    Trade.stats.duplicateOpens = Trade.stats.duplicateOpens + 1
    return 'dropped'
  end
  open = true
  flags = { moneyChanged = false, acceptUpdates = 0 }
  Trade.stats.opened = Trade.stats.opened + 1
  P.Events.Emit('P_TRADE_OPEN', {})
end

local function onClosed()
  if not open then
    Trade.stats.duplicateCloses = Trade.stats.duplicateCloses + 1
    return 'dropped'
  end
  open = false
  Trade.stats.closed = Trade.stats.closed + 1
  P.Events.Emit('P_TRADE_CLOSE', {})
end

local function onAccept()
  if not open then return 'dropped' end
  flags.acceptUpdates = flags.acceptUpdates + 1
end

local function onMoney()
  if not open then return 'dropped' end
  flags.moneyChanged = true
end

function Trade.IsOpen() return open end
--- { moneyChanged, acceptUpdates } of the current or last window.
function Trade.State() return { moneyChanged = flags.moneyChanged, acceptUpdates = flags.acceptUpdates } end
function Trade.Stop() open = false end
function Trade.Reset()
  open = false
  flags = { moneyChanged = false, acceptUpdates = 0 }
  Trade.stats = { opened = 0, closed = 0, duplicateCloses = 0, duplicateOpens = 0 }
end

Trade.OnShow, Trade.OnClosed, Trade.OnAccept, Trade.OnMoney = onShow, onClosed, onAccept, onMoney

P.RegisterCollectAdapter({
  name = 'Trade',
  handlers = {
    TRADE_SHOW = function() return onShow() end, TRADE_CLOSED = function() return onClosed() end,
    TRADE_ACCEPT_UPDATE = function() return onAccept() end, TRADE_MONEY_CHANGED = function() return onMoney() end,
  },
  stop = Trade.Stop,
})
