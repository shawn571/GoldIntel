--[[
Tests / test_pruner.lua                                       (Phase 2: Store/Pruner.lua, stub)

Phase 2 plans retention but NEVER deletes (roll-up into aggregates arrives in Phase 5).
]]

local T = require('testlib')
local Loader = require('loader')
local sim = require('svsim')

local DAY = 86400
local function boot()
  local W, P, ns = Loader.boot()
  W:login()
  return W, P, ns, ns.Pruner
end

T.describe('Pruner.Plan', function()
  T.it('selects sessions older than the cutoff by end time, else start time', function()
    local _, _, _, Pr = boot()
    local now = 1000 * DAY
    local db = {
      sessions = {
        old = { t0 = now - 200 * DAY, t1 = now - 199 * DAY },
        oldNoEnd = { t0 = now - 100 * DAY },
        recent = { t0 = now - 100 * DAY, t1 = now - 10 * DAY },
        boundary = { t1 = now - 90 * DAY },
        junk = 'not a table',
      },
      segments = {},
    }
    local plan = Pr.Plan(db, { days = 90, maxBytes = 1e9 }, now)
    T.eq(plan.sessions, { 'old', 'oldNoEnd' })
    T.eq(plan.cutoff, now - 90 * DAY)
  end)

  T.it('selects segments of old sessions and old orphans; spares recent ones', function()
    local _, _, _, Pr = boot()
    local now = 1000 * DAY
    local db = {
      sessions = { old = { t1 = now - 200 * DAY }, live = { t1 = now - 1 * DAY } },
      segments = {
        a = { sessionID = 'old', t0 = now - 200 * DAY },
        b = { sessionID = 'live', t0 = now - 1 * DAY },
        c = { sessionID = 'gone', t0 = now - 300 * DAY },
        d = { sessionID = 'gone', t0 = now - 2 * DAY },
        e = { t0 = now - 500 * DAY },
        f = 'junk',
      },
    }
    local plan = Pr.Plan(db, { days = 90 }, now)
    T.eq(plan.segments, { 'a', 'c', 'e' })
  end)

  T.it('flags databases over the size budget', function()
    local _, _, _, Pr = boot()
    local db = { sessions = {}, segments = {}, blob = string.rep('x', 5000) }
    T.truthy(Pr.Plan(db, { days = 90, maxBytes = 1000 }, 1).overBudget)
    T.falsy(Pr.Plan(db, { days = 90, maxBytes = 1000000 }, 1).overBudget)
  end)

  T.it('tolerates missing or malformed sections', function()
    local _, _, _, Pr = boot()
    local plan = Pr.Plan({ sessions = 'x', segments = 5 }, {}, 100)
    T.eq(plan.sessions, {})
    T.eq(plan.segments, {})
  end)
end)

T.describe('Pruner.Run (stub: plans only)', function()
  T.it('reports a dry run, removes nothing, and leaves the database identical', function()
    local W, _, ns, Pr = boot()
    local now = (W.env.time())
    local db = ns.Store.Get()
    db.sessions.s1 = { t0 = now - 500 * DAY, t1 = now - 499 * DAY }
    db.segments.g1 = { sessionID = 's1', t0 = now - 500 * DAY }
    local before = sim.dump(db)
    local r = Pr.Run()
    T.truthy(r.ok); T.truthy(r.dryRun); T.eq(r.removed, 0)
    T.eq(r.planned, { sessions = 1, segments = 1 })
    T.truthy(r.note:find('Phase 5', 1, true))
    T.eq(sim.dump(db), before)
    T.truthy(db.sessions.s1 and db.segments.g1)
  end)

  T.it('takes its defaults from the configuration and honors overrides', function()
    local _, _, ns, Pr = boot()
    ns.Config.Set('prune.maxBytes', 100000)
    T.eq(Pr.Run().maxBytes, 100000)
    T.eq(Pr.Run({ maxBytes = 5 }).maxBytes, 5)
    T.truthy(Pr.Run({ maxBytes = 5 }).overBudget)
  end)
end)
