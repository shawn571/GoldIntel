--[[
Tests / test_bagdiff.lua                (Phase 3b-3 M1: Collect/BagDiff.lua)
Pure module: no Platform, no clock.
]]

local T = require('testlib')
local Loader = require('loader')

local ld = loadstring or load
local SRC = Loader.readFile(Loader.root .. '/Collect/BagDiff.lua')
local function new()
  local ns = {}
  assert(ld(SRC, '=BagDiff'))('GoldIntel', ns)
  return ns.BagDiff
end
local function snap(items, complete) return { items = items, complete = complete ~= false } end

T.describe('BagDiff.Compute', function()
  local B = new()
  T.it('reports additions, removals and new/vanished ids per item id', function()
    local d = B.Compute(snap({ [10] = 5, [11] = 2, [12] = 1 }), snap({ [10] = 7, [11] = 1, [13] = 3 }))
    T.eq(d.added, { [10] = 2, [13] = 3 })
    T.eq(d.removed, { [11] = 1, [12] = 1 })
    T.eq(d.n, 4)
  end)
  T.it('a stack split or merge nets to zero (aggregated per id)', function()
    local d = B.Compute(snap({ [10] = 20 }), snap({ [10] = 20 }))
    T.eq(d.n, 0)
    T.eq(d.added, {}); T.eq(d.removed, {})
  end)
  T.it('refuses an incomplete snapshot on either side', function()
    T.isnil((B.Compute(snap({}, false), snap({}))))
    T.isnil((B.Compute(snap({}), snap({}, false))))
    T.isnil((B.Compute(snap({}), { items = {} })))             -- complete missing is incomplete
    T.isnil((B.Compute(nil, snap({}))))
  end)
  T.it('refuses malformed quantities and ids', function()
    T.isnil((B.Compute(snap({}), snap({ [10] = 0 }))))
    T.isnil((B.Compute(snap({}), snap({ [10] = -1 }))))
    T.isnil((B.Compute(snap({}), snap({ [10] = 1.5 }))))
    T.isnil((B.Compute(snap({}), snap({ ['x'] = 1 }))))
    T.isnil((B.Compute(snap({}), snap({ [0] = 1 }))))
  end)
  T.it('does not modify its inputs', function()
    local a, b = snap({ [1] = 1 }), snap({ [1] = 2, [2] = 1 })
    B.Compute(a, b)
    T.eq(a.items, { [1] = 1 }); T.eq(b.items, { [1] = 2, [2] = 1 })
  end)
end)

T.describe('BagDiff.Fingerprint', function()
  local B = new()
  T.it('is order independent and equal for equal contents', function()
    local a, b = {}, {}
    for i = 1, 50 do a[i] = i end
    for i = 50, 1, -1 do b[i] = i end
    T.eq(B.Fingerprint(a), B.Fingerprint(b))
  end)
  T.it('differs for a changed quantity, a swapped id/quantity and a new id', function()
    local base = B.Fingerprint({ [10] = 2, [11] = 3 })
    T.neq(B.Fingerprint({ [10] = 3, [11] = 3 }), base)
    T.neq(B.Fingerprint({ [10] = 3, [11] = 2 }), base)
    T.neq(B.Fingerprint({ [10] = 2, [11] = 3, [12] = 1 }), base)
  end)
end)

T.describe('BagDiff tracker', function()
  T.it('the first complete snapshot is the baseline and produces no diff', function()
    local B = new(); local t = B.New()
    local d, why = t:Settle(snap({ [1] = 1 }))
    T.isnil(d); T.eq(why, 'baseline')
    T.eq(t:Baseline(), { [1] = 1 })
  end)
  T.it('an incomplete snapshot is skipped, the baseline does not move, the next one absorbs the change', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d, why = t:Settle(snap({ [1] = 5 }, false))
    T.isnil(d); T.eq(why, 'incomplete')
    T.eq(t:Baseline(), { [1] = 1 })
    d = t:Settle(snap({ [1] = 5 }))
    T.eq(d.added, { [1] = 4 })
    T.eq(t:Stats().skipped, 1)
  end)
  T.it('an incomplete snapshot before any baseline does not create one', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }, false))
    T.isnil(t:Baseline())
    T.eq(t:Stats().baselines, 0)
  end)
  T.it('an identical snapshot is an empty settle', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d, why = t:Settle(snap({ [1] = 1 }))
    T.isnil(d); T.eq(why, 'empty')
    T.eq(t:Stats().empty, 1)
  end)
  T.it('the baseline advances only on Commit', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d = t:Settle(snap({ [1] = 3 }))
    T.eq(d.seq, 1)
    T.eq(t:Baseline(), { [1] = 1 })
    T.truthy(t:Commit(1))
    T.eq(t:Baseline(), { [1] = 3 })
  end)
  T.it('I-4: a second Commit of the same diff is refused', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d = t:Settle(snap({ [1] = 3 }))
    T.truthy(t:Commit(d.seq))
    local ok = t:Commit(d.seq)
    T.isnil(ok)
    T.eq(t:Stats().committed, 1); T.eq(t:Stats().rejected, 1)
  end)
  T.it('I-4: a repeated settle after Commit produces nothing', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    t:Commit(t:Settle(snap({ [1] = 3 })).seq)
    local d, why = t:Settle(snap({ [1] = 3 }))
    T.isnil(d); T.eq(why, 'empty')
  end)
  T.it('a newer settle supersedes an uncommitted one: only the newest can be committed', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d1 = t:Settle(snap({ [1] = 3 }))
    local d2 = t:Settle(snap({ [1] = 4 }))
    T.eq(d2.added, { [1] = 3 })                              -- relative to the committed baseline
    T.isnil((t:Commit(d1.seq)))
    T.truthy(t:Commit(d2.seq))
    T.eq(t:Baseline(), { [1] = 4 })
  end)
  T.it('a settle that returns to the baseline cancels the pending diff', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d1 = t:Settle(snap({ [1] = 3 }))
    t:Settle(snap({ [1] = 1 }))
    T.isnil((t:Commit(d1.seq)))
  end)
  T.it('sequence numbers increase and carry from/to fingerprints', function()
    local B = new(); local t = B.New()
    t:Settle(snap({ [1] = 1 }))
    local d1 = t:Settle(snap({ [1] = 2 })); t:Commit(d1.seq)
    local d2 = t:Settle(snap({ [1] = 3 })); t:Commit(d2.seq)
    T.eq(d1.seq, 1); T.eq(d2.seq, 2)
    T.eq(d2.from, d1.to)
    T.neq(d2.to, d2.from)
  end)
  T.it('the baseline is a copy (mutating the returned table or the snapshot cannot corrupt it)', function()
    local B = new(); local t = B.New()
    local s = snap({ [1] = 1 })
    t:Settle(s); s.items[1] = 99
    T.eq(t:Baseline(), { [1] = 1 })
    t:Baseline()[1] = 50
    T.eq(t:Baseline(), { [1] = 1 })
  end)
  T.it('property: any random stream of complete snapshots with commits leaves baseline == last snapshot', function()
    local B = new(); local t = B.New()
    math.randomseed(7)
    local last
    for _ = 1, 300 do
      local items = {}
      for id = 1, 8 do if math.random() < 0.6 then items[id] = math.random(1, 20) end end
      last = items
      local d = t:Settle(snap(items))
      if d then T.truthy(t:Commit(d.seq)) end
    end
    local base = t:Baseline()
    T.eq(base, last)
  end)
  T.it('property: applying each committed diff to a shadow inventory reproduces the carried inventory', function()
    local B = new(); local t = B.New()
    math.randomseed(11)
    local shadow, started = {}, false
    for _ = 1, 300 do
      local items = {}
      for id = 1, 8 do if math.random() < 0.6 then items[id] = math.random(1, 20) end end
      local d, why = t:Settle(snap(items, math.random() > 0.15))
      if why == 'baseline' then for id, q in pairs(items) do shadow[id] = q end; started = true end
      if d then
        for id, q in pairs(d.added) do shadow[id] = (shadow[id] or 0) + q end
        for id, q in pairs(d.removed) do shadow[id] = shadow[id] - q; if shadow[id] == 0 then shadow[id] = nil end end
        t:Commit(d.seq)
        T.eq(shadow, items)
      end
    end
    T.truthy(started)
  end)
end)

T.describe('BagDiff isolation (AC-15, I-6)', function()
  T.it('references no cash, reconciler or platform code', function()
    for _, w in ipairs({ 'Cash', 'Reconciler', 'Expectations', 'Platform', 'P%.', 'GetTime' }) do
      T.falsy(SRC:gsub('%-%-[^\n]*', ''):find(w), w)
    end
  end)
end)
