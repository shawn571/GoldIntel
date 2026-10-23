-- GoldIntel / Store / Pruner.lua                                        (Phase 2: stub)
--
-- PURPOSE
--   Plans data retention. In Phase 2 it only PLANS: it reports what would be pruned and
--   whether the database is over its size budget. It never deletes, because removing raw
--   sessions before they are rolled up into the aggregates (Phase 5) would lose data.
--
--   Pruner.Plan(db, policy, now) -> { cutoff, sessions = {ids}, segments = {ids}, bytes, maxBytes, overBudget }
--   Pruner.Run(policy)           -> { ok, dryRun = true, planned, removed = 0, overBudget, note }
--
--   policy: { days, maxBytes }  (defaults from Config prune.days / prune.maxBytes)
--
-- A session is eligible when its end time (t1, else its start t0) is older than `days`.
-- Segments are eligible when their session is, or when they are orphans older than the cutoff.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Store/Pruner.lua')

local Pruner = {}
GI.Pruner = Pruner

local DAY = 86400

local function sortedKeys(t)
  local out = {}
  for k in pairs(t) do out[#out + 1] = k end
  table.sort(out, function(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    return a < b
  end)
  return out
end

function Pruner.Plan(db, policy, now)
  policy = policy or {}
  local days = policy.days or 90
  local maxBytes = policy.maxBytes or 2000000
  now = now or (P.Now())
  local cutoff = now - days * DAY
  local plan = { cutoff = cutoff, sessions = {}, segments = {}, maxBytes = maxBytes }

  local oldSession = {}
  if type(db.sessions) == 'table' then
    for _, id in ipairs(sortedKeys(db.sessions)) do
      local s = db.sessions[id]
      if type(s) == 'table' then
        local ended = tonumber(s.t1) or tonumber(s.t0)
        if ended and ended < cutoff then
          plan.sessions[#plan.sessions + 1] = id
          oldSession[id] = true
        end
      end
    end
  end
  if type(db.segments) == 'table' then
    for _, id in ipairs(sortedKeys(db.segments)) do
      local seg = db.segments[id]
      if type(seg) == 'table' then
        local started = tonumber(seg.t0)
        local orphan = seg.sessionID == nil or (type(db.sessions) == 'table' and db.sessions[seg.sessionID] == nil)
        if oldSession[seg.sessionID] or (orphan and started and started < cutoff) then
          plan.segments[#plan.segments + 1] = id
        end
      end
    end
  end
  local bytes, truncated = GI.Store.EstimateBytes(db)
  plan.bytes = bytes
  plan.truncated = truncated
  plan.overBudget = bytes > maxBytes
  return plan
end

function Pruner.Run(policy)
  policy = policy or {}
  if policy.days == nil and GI.Config then policy.days = GI.Config.Get('prune.days') end
  if policy.maxBytes == nil and GI.Config then policy.maxBytes = GI.Config.Get('prune.maxBytes') end
  local plan = Pruner.Plan(GI.Store.Get(), policy)
  return {
    ok = true, dryRun = true, removed = 0,
    planned = { sessions = #plan.sessions, segments = #plan.segments },
    bytes = plan.bytes, maxBytes = plan.maxBytes, overBudget = plan.overBudget,
    note = 'Phase 2 plans only; roll-up and deletion arrive with the aggregation tables (Phase 5).',
  }
end

if GI.Core then GI.Core.Service('pruner', Pruner) end
