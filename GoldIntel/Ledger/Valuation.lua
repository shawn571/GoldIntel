-- GoldIntel / Ledger / Valuation.lua                              (Phase 3b-3 M1, Architecture AC-17; D-043..D-046, D-063)
--
-- PURPOSE
--  Valuation tiers 1 and 2 for a lot, as pure functions. Tier 1 = vendor floor, tier 2 = manual price.
--  No Platform, no clock, no storage. `info` is an Items.Get result, `manual` is { copper = n } or nil.
--
--      Valuation.Value(info, manual) -> { valueEach, valueSrc, flags }
--          info.status 'ready' + sellPrice >= 0    -> valueSrc 'vendor'; sellPrice 0 is KNOWN: flags.noVendor
--          optional manual price (D-082): the HIGHEST of vendor and manual is used; manual wins only when strictly higher
--          (valueSrc 'manual'); it is an override set by slash command, never a default; item data must be ready first
--          'ready' without a price, 'pending', 'secret' -> valueSrc 'unknown', valueEach 0, flags unknown + pendingInfo
--          'invalid' or anything else              -> valueSrc 'unknown', flags unknown + invalid (final)
--          flags.bound when bindType is 1 (on pickup) or 4 (quest): bound AT ACQUISITION
--      Valuation.Complete(lot, info, manual, now) -> true | false
--          The FIRST valuation of a lot that has none (valueSrc 'unknown', not invalid). Completion, not revaluation:
--          acquisition time, origin, vc and quantity never change. A lot that already has a basis is never touched (D-063).
--      Valuation.Expire(lot, now) -> true | false   ends the pendingInfo window (flag cleared, `unknown` stays, retryable)
--
-- An empty item answer is NEVER a price of 0 (D-045, D-046).

local ADDON, GI = ...
GI = GI or {}

local V = {}
GI.Valuation = V

V.PENDING_WINDOW = 30.0

local function isCopper(n) return type(n) == 'number' and n >= 0 and n == math.floor(n) and n < 2 ^ 40 end

local function boundAtPickup(info)
  return type(info) == 'table' and (info.bindType == 1 or info.bindType == 4)
end

function V.Value(info, manual)
  local flags = {}
  if boundAtPickup(info) then flags.bound = true end
  local mc = type(manual) == 'table' and isCopper(manual.copper) and manual.copper or nil
  local status = type(info) == 'table' and info.status or nil
  if status == 'ready' then
    if isCopper(info.sellPrice) then
      if info.sellPrice == 0 then flags.noVendor = true end
      -- D-082 / user 2026-10-19: the HIGHEST value is used. A manual price is an optional override
      -- (slash command), taken as typed (no AH cut); on a tie the vendor value stands.
      if mc and mc > info.sellPrice then
        return { valueEach = mc, valueSrc = 'manual', flags = flags }
      end
      return { valueEach = info.sellPrice, valueSrc = 'vendor', flags = flags }
    end
    flags.unknown, flags.pendingInfo = true, true
    return { valueEach = 0, valueSrc = 'unknown', flags = flags }
  end
  if status == 'pending' or status == 'secret' then
    flags.unknown, flags.pendingInfo = true, true
    return { valueEach = 0, valueSrc = 'unknown', flags = flags }
  end
  flags.unknown, flags.invalid = true, true
  return { valueEach = 0, valueSrc = 'unknown', flags = flags }
end

function V.Complete(lot, info, manual, now)
  if type(lot) ~= 'table' or lot.valueSrc ~= 'unknown' then return false end
  local f = lot.flags
  if type(f) == 'table' and f.invalid then return false end
  local r = V.Value(info, manual)
  if r.valueSrc == 'unknown' then return false end
  lot.valueEach, lot.valueSrc, lot.vt = r.valueEach, r.valueSrc, now
  lot.flags = lot.flags or {}
  lot.flags.unknown, lot.flags.pendingInfo = nil, nil
  if r.flags.noVendor then lot.flags.noVendor = true end
  if r.flags.bound then lot.flags.bound = true end
  return true
end

function V.Expire(lot, now)
  if type(lot) ~= 'table' or type(lot.flags) ~= 'table' or not lot.flags.pendingInfo then return false end
  if type(now) ~= 'number' or type(lot.t) ~= 'number' or now - lot.t < V.PENDING_WINDOW then return false end
  lot.flags.pendingInfo = nil
  return true
end
