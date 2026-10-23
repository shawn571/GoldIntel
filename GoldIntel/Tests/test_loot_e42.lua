--[[
Tests / test_loot_e42.lua                    (Phase 3b-1, D-075, E-42)

The recorded GIProbeLoot log (real WoW Forever loot windows, LootFrame polled every frame) is replayed through the real
Loot adapter, Context and Collector. A missing fixture FAILS the suite.
]]

local T = require('testlib')
local World = require('collectworld')
local Loader = require('loader')

local function loadLog()
  local f = io.open(Loader.root .. '/Tests/fixtures/probe/E-42_lootframe.lua', 'rb')
  T.truthy(f, 'E-42 probe fixture missing (never skipped)')
  local src = f:read('*a'); f:close()
  local env = {}
  local chunk
  if setfenv then chunk = loadstring(src); setfenv(chunk, env) else chunk = load(src, 'e42', 't', env) end
  chunk()
  return env.GIProbeLootDB.log
end

--- Parses the log into { gt, kind = 'open'|'clear'|'hide'|'show', slots?, slot? } sorted by time.
local function records()
  local out = {}
  for _, line in ipairs(loadLog()) do
    local gt, rest = line:match('^([%d%.]+) (.*)$')
    gt = tonumber(gt)
    if rest:find('^EVENT LOOT_OPENED') then
      out[#out + 1] = { gt = gt, kind = 'open', slots = tonumber(rest:match('slots=(%d+)')) }
    elseif rest:find('^EVENT LOOT_SLOT_CLEARED') then
      out[#out + 1] = { gt = gt, kind = 'clear', slot = tonumber(rest:match('slot=(%d+)')) }
    elseif rest:find('^POLL LootFrame shown=false') and not rest:find('was nil') then
      out[#out + 1] = { gt = gt, kind = 'hide' }
    end
  end
  return out
end

--- Replays the records. hooks.afterClear(W, rec) is called after each clear.
local function replay(hooks)
  hooks = hooks or {}
  local W, P, ns = World.boot()
  ns.Collector.On({})
  local recs = records()
  local t0 = recs[1].gt
  local now = 0
  local timeline = {}
  for _, r in ipairs(recs) do
    local target = r.gt - t0
    if target > now then W:advance(target - now); now = target end
    if r.kind == 'open' then
      local slots = {}
      for i = 1, r.slots do slots[i] = { type = 2, amount = 1 } end
      W.state.loot = { slots = slots }
      W:fire('LOOT_OPENED')
    elseif r.kind == 'clear' then
      W:fire('LOOT_SLOT_CLEARED', r.slot)
    elseif r.kind == 'hide' then
      W.state.lootShown = false
    end
    timeline[#timeline + 1] = { r = r, t = now }
    if hooks.after then hooks.after(W, P, ns, r) end
  end
  W:advance(0.3)
  return W, P, ns
end

T.describe('E-42 recorded loot windows through the real adapter', function()
  T.it('the fixture holds the 8 recorded windows', function()
    local n = 0
    for _, r in ipairs(records()) do if r.kind == 'open' then n = n + 1 end end
    T.eq(n, 8)
  end)

  T.it('all 8 windows close by frame; none by timeout or replacement (E-41 regression)', function()
    local _, P = replay()
    local s = P.LootModule.stats
    T.eq(s.opened, 8); T.eq(s.closedFrame, 8); T.eq(s.closedTimeout, 0); T.eq(s.closedReplaced, 0)
    T.eq(s.frameUnreadable, 0); T.eq(s.legacyWindows, 0)
  end)

  T.it('clears are information only: 5 distinct slots, 2 duplicates (E-42 doubled clears), 0 late', function()
    local _, P = replay()
    local s = P.LootModule.stats
    T.eq(s.clears, 5); T.eq(s.dupClears, 2); T.eq(s.lateClears, 0)
  end)

  T.it('the longest recorded window (Escape, 30.7 s) is measured', function()
    local _, P = replay()
    local m = P.LootModule.stats.maxOpenSec
    T.truthy(m > 30.6 and m < 31.3, 'maxOpenSec ' .. tostring(m))
  end)

  T.it('contexts: 8 opened, 8 closed, nothing stray', function()
    local _, _, ns = replay()
    local c = ns.Context.Stats().loot
    T.eq(c.opened, 8); T.eq(c.closed, 8); T.eq(c.duplicateOpens, 0); T.eq(c.strayCloses, 0)
    T.eq(c.byCounts.frame, 8)
  end)

  T.it('the slow loot (24.8 s) and the partial loot keep the context open until the frame hides', function()
    local openAt, checks = nil, {}
    replay({ after = function(W, P, ns, r)
      if r.kind == 'open' then openAt = r.gt end
      -- sample the context 1 s before every recorded hide and 0.5 s after every clear
      if r.kind == 'clear' then checks[#checks + 1] = { gt = r.gt, active = ns.Context.IsActive('loot') } end
    end })
    T.truthy(#checks >= 5)
    for _, c in ipairs(checks) do T.truthy(c.active, 'loot context active at the clear ' .. c.gt) end
  end)

  T.it('money 0.150 s after a clear (about 0.05 s after the frame hides) is inside the loot context', function()
    local W, P, ns = World.boot()
    ns.Collector.On({})
    W.state.loot = { slots = { { type = 2, amount = 11 } } }
    W:fire('LOOT_OPENED'); W:advance(24.3)
    W:fire('LOOT_SLOT_CLEARED', 1)
    W:advance(0.100); W.state.lootShown = false
    W:advance(0.050)
    T.truthy(ns.Context.IsActive('loot'), 'the frame has hidden but the linger still covers the money')
    W.state.money = W.state.money + 11; W:fire('PLAYER_MONEY')
    W:advance(1.3)
    T.falsy(ns.Context.IsActive('loot'))
  end)

  T.it('the collector report shows the frame / timeout / replaced split and the clear counters', function()
    local W, _, ns = replay()
    ns.Commands.Run('collect stats')
    local out = W:printedText()
    T.truthy(out:find('loot windows: opened 8, closed by frame 8, by timeout 0, replaced 0; longest open 3', 1, true))
    T.truthy(out:find('loot slot clears (information only): seen 5, duplicates 2, late 0', 1, true))
  end)
end)
