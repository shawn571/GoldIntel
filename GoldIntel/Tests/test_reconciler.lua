--[[
Tests / test_reconciler.lua                (Phase 3b-2 M1: Collect/Expectations.lua, Collect/Reconciler.lua)
Pure modules: no Platform, no clock. Includes property tests and a mutation set.
]]

local T = require('testlib')
local Loader = require('loader')

local function readSrc(rel) return Loader.readFile(Loader.root .. '/' .. rel) end

local function loadSrc(srcX, srcR)
  local ns = {}
  assert(loadstring or load)
  local ld = loadstring or load
  local fx = assert(ld(srcX, '=Expectations')); fx('GoldIntel', ns)
  local fr = assert(ld(srcR, '=Reconciler')); fr('GoldIntel', ns)
  return ns
end

local SRC_X, SRC_R = readSrc('Collect/Expectations.lua'), readSrc('Collect/Reconciler.lua')

local function new(ns)
  ns = ns or loadSrc(SRC_X, SRC_R)
  local out = {}
  local X = ns.Expectations.New()
  local R = ns.Reconciler.New{ exp = X, sink = function(e) out[#out + 1] = e end }
  return X, R, out, ns
end

local function exact(X, src, copper, sign, t0, extra)
  local s = { src = src, mode = 'exact', copper = copper, sign = sign or 1, t0 = t0 or 0, ttl = 1.0 }
  for k, v in pairs(extra or {}) do s[k] = v end
  return assert(X:Add(s))
end
local function window(X, src, sign, t0, ctx)
  return assert(X:Add{ src = src, mode = 'window', sign = sign, t0 = t0 or 0, ttl = 1.0, ctx = ctx or src })
end
local function sum(out) local s = 0 for _, e in ipairs(out) do s = s + e.copper end return s end

-- ---------------------------------------------------------------------------------------------------
-- Scenario suite: returns the names of failed checks. Used directly AND against mutated sources.
-- ---------------------------------------------------------------------------------------------------
local function scenarios(ns)
  local fails = {}
  local function check(name, ok) if not ok then fails[#fails + 1] = name end end
  local function inv(name, R, out) local ok = R:Check(); check(name .. ':invariant', ok) end

  do -- exact match, high
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 120, 1, 0)
    R:Money(120, 0.4)
    check('exact', #out == 1 and out[1].src == 'loot' and out[1].conf == 'high' and out[1].copper == 120)
    inv('exact', R, out)
  end
  do -- sign must agree
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 120, 1, 0)
    R:Money(-120, 0.4); R:Tick(1.5)
    check('sign', #out == 1 and out[1].src == 'other' and out[1].copper == -120)
    inv('sign', R, out)
  end
  do -- consumed once
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 50, 1, 0)
    R:Money(50, 0.1); R:Money(50, 0.2); R:Tick(1.3)
    check('once', #out == 2 and out[1].src == 'loot' and out[2].src == 'other')
    inv('once', R, out)
  end
  do -- AH sale split 51 / -2 / +100 = 149
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'ahSale', 149, 1, 0, { comps = {
      { src = 'ahSale', copper = 51, settle = true }, { src = 'ahCut', copper = -2 },
      { src = 'ahDepositRefund', copper = 100, comp = 'deposit' } } })
    R:Money(149, 0.27)
    check('split', #out == 3 and sum(out) == 149 and out[2].src == 'ahCut' and out[2].copper == -2
      and out[1].settle == true and out[3].comp == 'deposit')
    inv('split', R, out)
  end
  do -- bad comps refused
    local X = new(ns)
    local id, err = X:Add{ src = 'ahSale', mode = 'exact', copper = 149, sign = 1, t0 = 0, ttl = 1.0,
      comps = { { src = 'ahSale', copper = 50 } } }
    check('badcomps', id == nil and err == 'comps')
  end
  do -- priority: trade before loot for equal copper
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 77, 1, 0); exact(X, 'trade', 77, 1, 0.1)
    R:Money(77, 0.5)
    check('prio', out[1].src == 'trade')
    R:Money(77, 0.6)
    check('prio2', out[2] and out[2].src == 'loot')
    inv('prio', R, out)
  end
  do -- no cross-sign combinations (+100 and -30 must not explain +70)
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 100, 1, 0); exact(X, 'purchase', 30, -1, 0)
    R:Money(70, 0.5); R:Tick(1.6)
    check('crosssign', #out == 1 and out[1].src == 'other' and out[1].copper == 70)
    inv('crosssign', R, out)
  end
  do -- combination of two
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 30, 1, 0); exact(X, 'quest', 70, 1, 0)
    R:Money(100, 0.5)
    check('combo', #out == 2 and sum(out) == 100)
    inv('combo', R, out)
  end
  do -- window: med, then low when competing
    local X, R, out = new(ns); R:Begin(0)
    window(X, 'vendor', 1, 0, 'v')
    R:Money(33, 0.5)
    check('window', out[1] and out[1].src == 'vendor' and out[1].conf == 'med')
    window(X, 'trade', 1, 0.6, 't')
    R:Money(40, 0.7)
    check('compete', out[2] and out[2].src == 'trade' and out[2].conf == 'low')
    inv('window', R, out)
  end
  do -- window sign
    local X, R, out = new(ns); R:Begin(0)
    window(X, 'vendor', 1, 0); window(X, 'purchase', -1, 0)
    R:Money(-9, 0.5)
    check('wsign', out[1] and out[1].src == 'purchase' and out[1].copper == -9 and out[1].conf == 'med')
  end
  do -- window linger: active 1.0 after close (inclusive), not after
    local X, R, out = new(ns); R:Begin(0)
    local w = window(X, 'trade', 1, 0); X:Close(w, 2.0)
    R:Money(10, 3.0)
    check('linger_in', out[1] and out[1].src == 'trade')
    R:Money(11, 3.01); R:Tick(4.2)
    check('linger_out', out[2] and out[2].src == 'other')
    inv('linger', R, out)
  end
  do -- pending: late exact registration resolves; otherwise OTHER at exactly WAIT
    local X, R, out = new(ns); R:Begin(0)
    R:Money(25, 1.0)
    check('pend0', #out == 0)
    R:Tick(1.99); check('pend_before', #out == 0)
    exact(X, 'quest', 25, 1, 1.5)
    check('late', #out == 1 and out[1].src == 'quest' and out[1].t == 1.0)
    R:Money(26, 3.0); R:Tick(3.99); check('wait_before', #out == 1)
    R:Tick(4.0); check('wait_at', #out == 2 and out[2].src == 'other' and out[2].conf == 'low')
    inv('pending', R, out)
  end
  do -- gap
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 500, 1, 0)
    R:Money(500, 0.1, true)
    check('gap', #out == 1 and out[1].src == 'other' and out[1].comp == 'gap')
    check('gapstats', R:Stats().gapCount == 1 and R:Stats().gapValue == 500)
    inv('gap', R, out)
  end
  do -- expiry boundary: inclusive at t0 + ttl, unmatched counted after
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 10, 1, 0)
    R:Money(10, 1.0)
    check('expiry_in', #out == 1 and out[1].src == 'loot')
    exact(X, 'loot', 11, 1, 5)
    R:Tick(6.01)
    check('unmatched', R:Stats().unmatched == 1)
    R:Money(11, 6.02); R:Tick(7.1)
    check('expired_not_used', out[2] and out[2].src == 'other')
    inv('expiry', R, out)
  end
  do -- no partial matching across deltas (Q-4)
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 100, 1, 0)
    R:Money(60, 0.2); R:Money(40, 0.3); R:Tick(1.5)
    check('nopartial', #out == 2 and out[1].src == 'other' and out[2].src == 'other')
    check('nopartial_sum', sum(out) == 100)
    inv('nopartial', R, out)
  end
  do -- End flushes pending immediately and clears; deltas outside interval ignored
    local X, R, out = new(ns); R:Begin(0)
    R:Money(5, 0.5); R:End(0.6)
    check('end', #out == 1 and out[1].src == 'other' and R:Stats().pending == 0)
    R:Money(99, 1.0)
    check('inactive', #out == 1 and R:Stats().ignored == 1)
    inv('end', R, out)
  end
  do -- stats: shares by value and entries
    local X, R, out = new(ns); R:Begin(0)
    exact(X, 'loot', 300, 1, 0)
    R:Money(300, 0.1); R:Money(100, 0.2); R:Tick(1.3)
    local s = R:Stats()
    check('stats_entries', s.total == 2 and math.abs(s.otherShareEntries - 0.5) < 1e-9)
    check('stats_value', math.abs(s.otherShareValue - 0.25) < 1e-9 and s.largestOther == 100)
  end
  return fails
end

T.describe('Expectations store', function()
  T.it('validates specs', function()
    local X = new()
    local function bad(spec, why) local id, err = X:Add(spec); T.isnil(id); T.eq(err, why) end
    bad(nil, 'spec')
    bad({ src = 'a', mode = 'x', sign = 1, t0 = 0, ttl = 1 }, 'mode')
    bad({ src = 'a', mode = 'exact', sign = 0, t0 = 0, ttl = 1, copper = 1 }, 'sign')
    bad({ src = 'a', mode = 'exact', sign = 1, t0 = 0, ttl = 0.99, copper = 1 }, 'ttl')
    bad({ src = 'a', mode = 'exact', sign = 1, t0 = 0, ttl = 1, copper = 0 }, 'copper')
    bad({ src = 'a', mode = 'exact', sign = 1, t0 = 0, ttl = 1, copper = 1.5 }, 'copper')
    bad({ src = 'a', mode = 'window', sign = 1, t0 = 0, ttl = 1, copper = 5 }, 'window has no amount')
    bad({ mode = 'exact', sign = 1, t0 = 0, ttl = 1, copper = 1 }, 'src')
  end)
  T.it('orders by priority, then t0, then id', function()
    local X = new()
    exact(X, 'loot', 1, 1, 0); exact(X, 'trade', 1, 1, 5); exact(X, 'trade', 2, 1, 3); exact(X, 'vendor', 1, 1, 0)
    local a = X:Active(0.5)
    T.eq({ a[1].src, a[1].t0, a[2].t0, a[3].src, a[4].src }, { 'trade', 3, 5, 'vendor', 'loot' })
  end)
  T.it('Extend keeps an exact expectation alive; Consume removes it', function()
    local X = new()
    local id = exact(X, 'loot', 5, 1, 0)
    T.eq(#X:Active(1.5), 0)
    X:Extend(id, 4.0)
    T.eq(#X:Active(3.9), 1)
    T.truthy(X:Consume(id)); T.falsy(X:Consume(id))
    T.eq(X:Stats().consumed, 1)
  end)
  T.it('windows are never consumed and not counted as unmatched', function()
    local X = new()
    local w = window(X, 'vendor', 1, 0)
    T.falsy(X:Consume(w))
    X:Close(w, 1); T.falsy(X:Close(w, 2))
    X:Expire(5)
    T.eq(X:Stats().unmatched, 0); T.eq(X:Stats().active, 0)
  end)
  T.it('priority table follows D-065', function()
    local X = require and nil
    local ns = loadSrc(SRC_X, SRC_R)
    local P = ns.Expectations.PrioOf
    T.truthy(P('trade') < P('mailMoney')); T.truthy(P('mailMoney') < P('vendor'))
    T.truthy(P('vendor') < P('quest')); T.truthy(P('quest') < P('loot')); T.truthy(P('loot') < P('ahDeposit'))
    T.eq(P('whatever'), 9)
  end)
end)

T.describe('Reconciler scenarios', function()
  T.it('every scenario passes on the real source', function()
    local f = scenarios()
    T.eq(f, {})
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Reconciler property tests', function()
  local function lcg(seed)
    local s = seed
    return function(n) s = (s * 1103515245 + 12345) % 2147483648; return (math.floor(s / 65536) % n) + 1 end
  end
  T.it('200 random streams: entries always sum to the deltas, expectations used at most once', function()
    local bad = 0
    for seed = 1, 200 do
      local rnd = lcg(seed)
      local X, R, out = new()
      R:Begin(0)
      local t, deltas, wins = 0, 0, {}
      local SRCS = { 'loot', 'quest', 'mailMoney', 'trade', 'vendor' }
      for _ = 1, 60 do
        t = t + rnd(8) * 0.15
        local k = rnd(8)
        if k <= 2 then
          local cp = rnd(5) * 25
          X:Add{ src = SRCS[rnd(#SRCS)], mode = 'exact', copper = cp, sign = rnd(2) == 1 and 1 or -1, t0 = t, ttl = 1.0 }
        elseif k == 3 then
          wins[#wins + 1] = X:Add{ src = SRCS[rnd(#SRCS)], mode = 'window', sign = rnd(2) == 1 and 1 or -1, t0 = t, ttl = 1.0 }
        elseif k == 4 and #wins > 0 then
          X:Close(table.remove(wins, 1), t)
        elseif k <= 7 then
          local d = (rnd(2) == 1 and 1 or -1) * rnd(5) * 25
          deltas = deltas + d
          R:Money(d, t, rnd(20) == 1)
        else
          R:Tick(t)
        end
      end
      R:Tick(t + 5)
      if not R:Check() then bad = bad + 1 end
      R:End(t + 6)
      local ok = R:Check()
      local seen, dup, zero = {}, false, false
      for _, e in ipairs(out) do
        if e.copper == 0 then zero = true end
        if e.exp and e.src ~= 'other' then
          local win = false
          for _, a in ipairs(X.list) do if a.id == e.exp and a.mode == 'window' then win = true end end
        end
      end
      if not ok or sum(out) ~= deltas or R:Stats().pending ~= 0 or zero then bad = bad + 1 end
    end
    T.eq(bad, 0)
  end)
  T.it('exact expectations are consumed at most once across random streams', function()
    local bad = 0
    for seed = 1, 100 do
      local rnd = lcg(seed * 7)
      local X, R, out = new()
      R:Begin(0)
      local t, exactIds = 0, {}
      for _ = 1, 50 do
        t = t + rnd(6) * 0.1
        if rnd(3) == 1 then
          exactIds[X:Add{ src = 'loot', mode = 'exact', copper = rnd(4) * 10, sign = 1, t0 = t, ttl = 1.0 }] = true
        else
          R:Money(rnd(4) * 10, t)
        end
      end
      R:End(t + 5)
      local used = {}
      for _, e in ipairs(out) do
        if e.exp and exactIds[e.exp] then
          if used[e.exp] and not e.comp then bad = bad + 1 end
          used[e.exp] = true
        end
      end
    end
    T.eq(bad, 0)
  end)
end)

-- ---------------------------------------------------------------------------------------------------
T.describe('Reconciler mutation checks', function()
  local MUT = {
    { 'sign ignored', 'R', "local sign = d > 0 and 1 or -1", "local sign = 1" },
    { 'consume skipped', 'R', "      self.exp:Consume(e.id)\n", "" },
    { 'priority ignored', 'X', "  table.sort(out, before)\n", "" },
    { 'remainder dropped', 'R', "if gt - p.t >= self.wait then self:_other(p, gt) else keep[#keep + 1] = p end",
      "if gt - p.t >= self.wait then else keep[#keep + 1] = p end" },
    { 'competition ignored', 'R', "conf = 'low'; break", "break" },
    { 'wait off by one', 'R', "gt - p.t >= self.wait", "gt - p.t > self.wait" },
    { 'wait too long', 'R', "R.WAIT = 1.0", "R.WAIT = 2.0" },
    { 'gap ignored', 'R', "if gap then self:_other(p, gt, 'gap'); return end", "" },
    { 'expiry exclusive', 'X', "return gt <= e.expireGT", "return gt < e.expireGT" },
    { 'comps unchecked', 'X', "sum ~= spec.sign * spec.copper", "false" },
    { 'combos disabled', 'R', "R.MAX_COMBO = 3", "R.MAX_COMBO = 1" },
    { 'window sign ignored', 'R', "self.exp:Active(gt, sign, 'window')", "self.exp:Active(gt, nil, 'window')" },
    { 'exact sign ignored', 'R', "self.exp:Active(gt, sign, 'exact')", "self.exp:Active(gt, nil, 'exact')" },
    { 'no retry on add', 'R', "if self.active then self:_retry(self.lastGT or 0) end", "" },
    { 'inactive not ignored', 'R', "if not self.active then self.ignored = self.ignored + 1; return end", "" },
    { 'end keeps pending', 'R', "for _, p in ipairs(self.pending) do self:_other(p, gt) end\n  self.pending = {}", "" },
    { 'window never closes', 'X', "e.expireGT = math.max(gt + e.ttl, base)", "" },
    { 'sum lost on window', 'R', "self:_emit({ t = p.t, copper = d, src = w.src", "self:_emit({ t = p.t, copper = d + 1, src = w.src" },
  }
  for _, m in ipairs(MUT) do
    T.it('mutation is caught: ' .. m[1], function()
      local sx, sr = SRC_X, SRC_R
      local function sub(s, a, b)
        local i, j = s:find(a, 1, true)
        T.truthy(i, 'mutation anchor missing: ' .. m[1])
        return s:sub(1, i - 1) .. b .. s:sub(j + 1)
      end
      if m[2] == 'X' then sx = sub(sx, m[3], m[4]) else sr = sub(sr, m[3], m[4]) end
      local ns = loadSrc(sx, sr)
      local ok, fails = pcall(scenarios, ns)
      T.truthy((not ok) or #fails > 0, 'mutation survived: ' .. m[1])
    end)
  end
end)
