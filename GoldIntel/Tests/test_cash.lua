--[[
Tests / test_cash.lua                         (Phase 3b-2 M3: Ledger/Cash.lua, AC-12)

Compact records, immutability, retention fold, total preservation, bus event, read-only store.
]]

local T = require('testlib')
local World = require('collectworld')
local sim = require('svsim')

local function boot()
  local W, P, ns = World.boot()
  ns.Ledger.OnCollectOff()          -- no interval: these tests add entries by hand
  return W, P, ns, ns.Cash
end

local function entry(W, copper, extra)
  local e = { t = W.state.gt, copper = copper, src = 'loot', conf = 'high', act = 'GRIND', actConf = 'medium',
    locConf = 'high', creditable = true }
  for k, v in pairs(extra or {}) do e[k] = v end
  return e
end

T.describe('Cash records', function()
  T.it('stores a compact record and expands it into the Contracts shape', function()
    local W, P, ns, Cash = boot()
    local id = Cash.Add(entry(W, 1234, { loc = { mapID = 1411, zone = 'Durotar', sub = 'Razor Hill', x = 0.123456, y = 0.5 },
      ref = { sourceType = 'creature' }, ctx = 'loot' }))
    T.eq(id, 1)
    local rec = ns.Store.Section('ledger')[P.Player().key].cash[1]
    T.eq(rec.c, 1234); T.eq(rec.l, 1); T.eq(rec.x, 0.1235); T.eq(rec.r, 'creature'); T.eq(rec.cr, true)
    T.isnil(rec.copper); T.isnil(rec.loc)
    local e = Cash.Last(1)[1]
    T.eq(e.id, 1); T.eq(e.copper, 1234); T.eq(e.src, 'loot'); T.eq(e.actConf, 'medium'); T.eq(e.locConf, 'high')
    T.eq(e.creditable, true); T.eq(e.settle, false); T.eq(e.ref, 'creature'); T.eq(e.charKey, P.Player().key)
    T.eq(e.loc.zone, 'Durotar'); T.eq(e.loc.sub, 'Razor Hill'); T.eq(e.loc.x, 0.1235)
  end)

  T.it('ids rise by one and continue across a save and load', function()
    local W, P, ns, Cash = boot()
    for i = 1, 3 do T.eq(Cash.Add(entry(W, i)), i) end
    local saved = sim.parse(sim.dump(ns.Store.Section('ledger')))
    local led = saved[P.Player().key]
    T.eq(led.nextId, 4); T.eq(#led.cash, 3)
  end)

  T.it('rejects invalid entries and counts them', function()
    local W, _, _, Cash = boot()
    for _, bad in ipairs({ entry(W, 0), entry(W, 1.5), entry(W, 'x'), { copper = 5 } }) do
      local id, why = Cash.Add(bad)
      T.isnil(id); T.eq(why, 'invalid entry')
    end
    T.isnil((Cash.Add(nil)))
    T.eq(Cash.Stats().total, 0); T.eq(Cash.stats.rejected, 5)
  end)

  T.it('interns places once and rounds coordinates to 4 places', function()
    local W, _, ns, Cash = boot()
    local loc = { mapID = 1, zone = 'A very long zone name', sub = 'sub', x = 0.33333333, y = 0.66666666 }
    for _ = 1, 4 do Cash.Add(entry(W, 10, { loc = loc })) end
    Cash.Add(entry(W, 10, { loc = { mapID = 2, zone = 'B' } }))
    local led = Cash.Ledger()
    T.eq(#led.locs, 2)
    T.eq(led.cash[1].l, 1); T.eq(led.cash[5].l, 2)
    T.eq(led.cash[1].x, 0.3333); T.eq(led.cash[1].y, 0.6667)
    T.isnil(led.cash[5].x)
  end)

  T.it('converts the game time to unix seconds through the clock offset', function()
    local W, P, _, Cash = boot()
    local ut, gt = P.Now()
    Cash.Add(entry(W, 10, { t = gt - 30 }))
    T.eq(Cash.Ledger().cash[1].t, math.floor(ut - 30 + 0.5))
  end)

  T.it('is immutable: callers cannot change what is stored', function()
    local W, _, _, Cash = boot()
    local input = entry(W, 500, { loc = { mapID = 1, zone = 'Z' } })
    Cash.Add(input)
    input.copper = 999; input.loc.zone = 'changed'
    local first = Cash.Last(1)[1]
    first.copper = -1; first.loc.zone = 'hacked'; first.src = 'x'
    local again = Cash.Last(1)[1]
    T.eq(again.copper, 500); T.eq(again.loc.zone, 'Z'); T.eq(again.src, 'loot')
    T.eq(Cash.Cumulative(), 500)
    T.falsy(Cash.Update or Cash.Delete or Cash.Remove or Cash.Set, 'no mutating API')
  end)

  T.it('announces each entry on the bus as an expanded copy', function()
    local W, P, ns, Cash = boot()
    local seen = {}
    ns.Bus.On('LEDGER_CASH', function(e) seen[#seen + 1] = e end)
    Cash.Add(entry(W, 77))
    T.eq(#seen, 1); T.eq(seen[1].copper, 77); T.eq(seen[1].charKey, P.Player().key)
  end)

  T.it('AddGap writes an OTHER low entry flagged as a gap', function()
    local _, _, _, Cash = boot()
    Cash.AddGap(-250, 'login')
    local e = Cash.Last(1)[1]
    T.eq(e.src, 'other'); T.eq(e.comp, 'gap'); T.eq(e.conf, 'low'); T.eq(e.ctx, 'login'); T.eq(e.copper, -250)
    local st = Cash.Stats()
    T.eq(st.gapCount, 1); T.eq(st.gapValue, 250); T.eq(st.largestOther, 250)
  end)
end)

T.describe('Cash retention', function()
  local function fill(W, Cash, n, gen)
    for i = 1, n do Cash.Add(entry(W, gen(i), { src = (i % 3 == 0) and 'other' or 'loot' })) end
  end

  T.it('folds the oldest FOLD records into totals once CAP is passed', function()
    local W, _, _, Cash = boot()
    Cash.CAP, Cash.FOLD = 20, 5
    fill(W, Cash, 21, function(i) return i * 10 end)
    local led = Cash.Ledger()
    T.eq(#led.cash, 16); T.eq(led.totals.folded, 5); T.eq(led.cash[1].id, 6); T.eq(Cash.stats.folds, 1)
    local want = 0
    for i = 1, 21 do want = want + i * 10 end
    T.eq(Cash.Cumulative(), want)
    Cash.CAP, Cash.FOLD = 2000, 500
  end)

  T.it('keeps Cumulative and Stats totals through many folds (random amounts, both signs)', function()
    local W, _, _, Cash = boot()
    Cash.CAP, Cash.FOLD = 30, 7
    math.randomseed(20261018)
    local sum, abssum, n, other, otherVal, gaps = 0, 0, 0, 0, 0, 0
    for _ = 1, 400 do
      local c = math.random(-5000, 5000)
      if c == 0 then c = 1 end
      local src = ({ 'loot', 'other', 'vendor', 'mail' })[math.random(1, 4)]
      local comp = (src == 'other' and math.random() < 0.2) and 'gap' or nil
      Cash.Add(entry(W, c, { src = src, comp = comp }))
      sum = sum + c; abssum = abssum + math.abs(c); n = n + 1
      if src == 'other' then other = other + 1; otherVal = otherVal + math.abs(c) end
      if comp then gaps = gaps + 1 end
      T.eq(Cash.Cumulative(), sum)
    end
    local st = Cash.Stats()
    T.eq(st.total, n); T.eq(st.cumulative, sum); T.eq(st.totalValue, abssum)
    T.eq(st.otherN, other); T.eq(st.otherValue, otherVal); T.eq(st.gapCount, gaps)
    T.near(st.otherShareValue, otherVal / abssum, 1e-12)
    T.near(st.otherShareEntries, other / n, 1e-12)
    T.truthy(st.folded > 0); T.truthy(st.raw <= 30)
    T.eq(st.raw + st.folded, n)
    Cash.CAP, Cash.FOLD = 2000, 500
  end)

  T.it('keeps the largest OTHER after the entry itself is folded away', function()
    local W, _, _, Cash = boot()
    Cash.CAP, Cash.FOLD = 10, 5
    Cash.Add(entry(W, -9000, { src = 'other' }))
    for i = 1, 20 do Cash.Add(entry(W, 1, { src = 'loot' })) end
    T.eq(Cash.Stats().largestOther, 9000)
    T.eq(Cash.Ledger().cash[1].c == -9000, false)
    Cash.CAP, Cash.FOLD = 2000, 500
  end)

  T.it('the real limits (2000 / 500) hold and the file stays loadable', function()
    local W, P, ns, Cash = boot()
    for i = 1, 2001 do Cash.Add(entry(W, (i % 7) + 1)) end
    local led = Cash.Ledger()
    T.eq(#led.cash, 1501); T.eq(led.totals.folded, 500)
    local expect = 0
    for i = 1, 2001 do expect = expect + (i % 7) + 1 end
    T.eq(Cash.Cumulative(), expect)
    local saved = sim.parse(sim.dump(ns.Store.Section('ledger')))
    T.eq(#saved[P.Player().key].cash, 1501)
  end)

  T.it('survives save, load and further adds without losing the running totals', function()
    local W, P, ns, Cash = boot()
    Cash.CAP, Cash.FOLD = 10, 4
    for i = 1, 25 do Cash.Add(entry(W, i)) end
    local before = Cash.Cumulative()
    local reloaded = sim.parse(sim.dump(ns.Store.Section('ledger')))
    ns.Store.Section('ledger')[P.Player().key] = reloaded[P.Player().key]
    Cash.Reset()                                       -- caches forgotten like after a /reload
    T.eq(Cash.Cumulative(), before)
    T.eq(Cash.Add(entry(W, 5, { loc = { mapID = 9, zone = 'New' } })), 26)
    T.eq(Cash.Cumulative(), before + 5)
    Cash.CAP, Cash.FOLD = 2000, 500
  end)

  T.it('rebuilds the place index after a load (no duplicated places)', function()
    local W, P, ns, Cash = boot()
    Cash.Add(entry(W, 1, { loc = { mapID = 1, zone = 'A', sub = 'b' } }))
    local reloaded = sim.parse(sim.dump(ns.Store.Section('ledger')))
    ns.Store.Section('ledger')[P.Player().key] = reloaded[P.Player().key]
    Cash.Reset()
    Cash.Add(entry(W, 1, { loc = { mapID = 1, zone = 'A', sub = 'b' } }))
    T.eq(#Cash.Ledger().locs, 1)
  end)
end)

T.describe('Cash with a read-only store', function()
  T.it('does not write and reports not writable', function()
    local W = require('fake_wow').new()
    World.extend(W)
    W.env.GoldIntelDB = { schema = 99, meta = {}, ledger = {} }          -- newer than this addon: read-only
    local P, ns = require('loader').load(W.env)
    W:login()
    T.falsy(ns.Cash.Writable())
    local before = sim.dump(W.env.GoldIntelDB)
    ns.Cash.Add(entry(W, 100))
    T.eq(sim.dump(W.env.GoldIntelDB), before, 'the saved table was not touched')
    T.eq(ns.Cash.Stats().writable, false)
  end)
end)
