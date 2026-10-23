-- GoldIntel / Platform / Merchant.lua                                   (Phase 3b-1)
--
-- Vendor window adapter: MERCHANT_SHOW -> P_VENDOR_OPEN, MERCHANT_CLOSED -> P_VENDOR_CLOSE.
-- E-33: the close event fires for both close routes and arrives TWICE in the same frame when the
-- window closes by walking away, so the close is idempotent (the duplicate is counted as dropped).
-- No amounts are read here: vendor money is matched by sign inside the window (AC-4 window mode).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Merchant.lua')

local Merchant = {}
P.MerchantModule = Merchant
P.Register('Merchant', Merchant)

local open = false
Merchant.stats = { opened = 0, closed = 0, duplicateCloses = 0, closeWithoutOpen = 0, duplicateOpens = 0 }

local function onShow()
  if open then
    Merchant.stats.duplicateOpens = Merchant.stats.duplicateOpens + 1
    return 'dropped'
  end
  open = true
  Merchant.stats.opened = Merchant.stats.opened + 1
  P.Events.Emit('P_VENDOR_OPEN', {})
end

local function onClosed()
  if not open then
    Merchant.stats.duplicateCloses = Merchant.stats.duplicateCloses + 1
    return 'dropped'
  end
  open = false
  Merchant.stats.closed = Merchant.stats.closed + 1
  P.Events.Emit('P_VENDOR_CLOSE', {})
end

function Merchant.IsOpen() return open end
function Merchant.Stop() open = false end
function Merchant.Reset()
  open = false
  Merchant.stats = { opened = 0, closed = 0, duplicateCloses = 0, closeWithoutOpen = 0, duplicateOpens = 0 }
end

Merchant.OnShow = onShow
Merchant.OnClosed = onClosed

P.RegisterCollectAdapter({
  name = 'Merchant',
  handlers = { MERCHANT_SHOW = function() return onShow() end, MERCHANT_CLOSED = function() return onClosed() end },
  stop = Merchant.Stop,
})
