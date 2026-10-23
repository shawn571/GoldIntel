--[[
Tests / test_context.lua                            (Phase 3b-1: Collect/Context.lua)
]]

local T = require('testlib')
local World = require('collectworld')

local function boot()
  local W, P, ns = World.boot()
  ns.Context.Reset()
  return W, P, ns
end

T.describe('Context open and close', function()
  T.it('opens and closes each kind through the normalized events', function()
    local _, P, ns = boot()
    local pairs_ = {
      loot = { 'P_LOOT_OPEN', { sourceType = 'creature' }, 'P_LOOT_CLOSE', { by = 'frame' } },
      vendor = { 'P_VENDOR_OPEN', {}, 'P_VENDOR_CLOSE', {} },
      mail = { 'P_MAIL_OPEN', {}, 'P_MAIL_CLOSE', {} },
      trade = { 'P_TRADE_OPEN', {}, 'P_TRADE_CLOSE', {} },
      ah = { 'P_AH_OPEN', {}, 'P_AH_CLOSE', {} },
    }
    for kind, p in pairs(pairs_) do
      P.Emit(p[1], p[2])
      T.truthy(ns.Context.IsActive(kind), kind .. ' open')
      P.Emit(p[3], p[4])
      local s = ns.Context.Stats()[kind]
      T.eq(s.opened, 1, kind); T.eq(s.closed, 1, kind)
    end
  end)

  T.it('a quest turn-in opens and closes in the same instant', function()
    local _, P, ns = boot()
    P.Emit('P_QUEST_DONE', { questID = 1, copper = 5 })
    local s = ns.Context.Stats().quest
    T.eq(s.opened, 1); T.eq(s.closed, 1); T.eq(s.byCounts.instant, 1)
    T.truthy(ns.Context.IsActive('quest'))
  end)

  T.it('closing records how the context closed', function()
    local _, P, ns = boot()
    P.Emit('P_LOOT_OPEN', { sourceType = 'creature' }); P.Emit('P_LOOT_CLOSE', { by = 'timeout' })
    P.Emit('P_LOOT_OPEN', { sourceType = 'creature' }); P.Emit('P_LOOT_CLOSE', { by = 'frame' })
    P.Emit('P_LOOT_OPEN', { sourceType = 'creature' }); P.Emit('P_LOOT_CLOSE', { by = 'frame' })
    local s = ns.Context.Stats().loot
    T.eq(s.byCounts.frame, 2); T.eq(s.byCounts.timeout, 1)
  end)

  T.it('a duplicate open is counted and ignored', function()
    local _, P, ns = boot()
    P.Emit('P_VENDOR_OPEN', {}); P.Emit('P_VENDOR_OPEN', {})
    local s = ns.Context.Stats().vendor
    T.eq(s.opened, 1); T.eq(s.duplicateOpens, 1)
  end)

  T.it('a close without an open is a stray close, counted and ignored', function()
    local _, P, ns = boot()
    P.Emit('P_VENDOR_CLOSE', {})
    local s = ns.Context.Stats().vendor
    T.eq(s.closed, 0); T.eq(s.strayCloses, 1)
    T.falsy(ns.Context.IsActive('vendor'))
  end)

  T.it('closing twice is idempotent', function()
    local _, P, ns = boot()
    P.Emit('P_TRADE_OPEN', {}); P.Emit('P_TRADE_CLOSE', {}); P.Emit('P_TRADE_CLOSE', {})
    local s = ns.Context.Stats().trade
    T.eq(s.closed, 1); T.eq(s.strayCloses, 1)
  end)

  T.it('ids increase with every open', function()
    local _, P, ns = boot()
    P.Emit('P_VENDOR_OPEN', {})
    local a = ns.Context.Active()[1].id
    P.Emit('P_VENDOR_CLOSE', {}); P.Emit('P_VENDOR_OPEN', {})
    local b = ns.Context.Active()[1].id
    T.truthy(b > a)
  end)
end)

T.describe('Context linger (D-065, 1.0 s)', function()
  T.it('a closed context stays active for 1.0 s and then disappears', function()
    local W, P, ns = boot()
    P.Emit('P_TRADE_OPEN', {}); P.Emit('P_TRADE_CLOSE', {})
    W:advance(0.5); T.truthy(ns.Context.IsActive('trade'))
    W:advance(0.45); T.truthy(ns.Context.IsActive('trade'))
    W:advance(0.2); T.falsy(ns.Context.IsActive('trade'))
    T.eq(#ns.Context.Active(), 0)
  end)

  T.it('an open context is active however long it stays open', function()
    local W, P, ns = boot()
    P.Emit('P_MAIL_OPEN', {})
    W:advance(120)
    T.truthy(ns.Context.IsActive('mail'))
    local a = ns.Context.Active()[1]
    T.truthy(a.open)
  end)

  T.it('the trade money lag of E-31 (0.394 s) falls inside the linger', function()
    local W, P, ns = boot()
    P.Emit('P_TRADE_OPEN', {}); P.Emit('P_TRADE_CLOSE', {})
    W:advance(0.394)
    T.truthy(ns.Context.IsActive('trade'))
  end)

  T.it('the mail lag of E-28 (0.365 s) falls inside the linger even if the box closed at once', function()
    local W, P, ns = boot()
    P.Emit('P_MAIL_OPEN', {}); P.Emit('P_MAIL_CLOSE', {})
    W:advance(0.365)
    T.truthy(ns.Context.IsActive('mail'))
  end)

  T.it('the loot lag of up to 0.509 s after the clear is covered while the context lingers', function()
    local W, P, ns = boot()
    P.Emit('P_LOOT_OPEN', { sourceType = 'creature' }); P.Emit('P_LOOT_CLOSE', { by = 'frame' })
    W:advance(0.509)
    T.truthy(ns.Context.IsActive('loot'))
  end)

  T.it('Active lists several contexts oldest first', function()
    local W, P, ns = boot()
    P.Emit('P_MAIL_OPEN', {}); W:advance(0.3); P.Emit('P_VENDOR_OPEN', {})
    local a = ns.Context.Active()
    T.eq(a[1].kind, 'mail'); T.eq(a[2].kind, 'vendor')
  end)

  T.it('Clear drops everything without firing events', function()
    local _, P, ns = boot()
    local fired = 0
    ns.Bus.On('CONTEXT_CHANGED', function() fired = fired + 1 end)
    P.Emit('P_VENDOR_OPEN', {})
    local before = fired
    ns.Context.Clear()
    T.eq(#ns.Context.Active(), 0)
    T.eq(fired, before)
  end)

  T.it('Reset also zeroes the statistics', function()
    local _, P, ns = boot()
    P.Emit('P_VENDOR_OPEN', {})
    ns.Context.Reset()
    T.eq(ns.Context.Stats().vendor.opened, 0)
  end)
end)

T.describe('CONTEXT_CHANGED on the bus (Contracts F3b)', function()
  T.it('fires on every open and close with kind, open and id', function()
    local _, P, ns = boot()
    local seen = {}
    ns.Bus.On('CONTEXT_CHANGED', function(p) seen[#seen + 1] = p end)
    P.Emit('P_AH_OPEN', {}); P.Emit('P_AH_CLOSE', {})
    T.eq(#seen, 2)
    T.eq(seen[1].kind, 'ah'); T.eq(seen[1].open, true)
    T.eq(seen[2].open, false); T.eq(seen[2].id, seen[1].id)
  end)

  T.it('the event is declared with a shape the bus enforces', function()
    local _, _, ns = boot()
    local info = ns.Bus.Info('CONTEXT_CHANGED')
    T.truthy(info)
    T.falsy(info.reserved)
  end)

  T.it('does not fire for ignored duplicates', function()
    local _, P, ns = boot()
    local n = 0
    ns.Bus.On('CONTEXT_CHANGED', function() n = n + 1 end)
    P.Emit('P_AH_OPEN', {}); P.Emit('P_AH_OPEN', {}); P.Emit('P_AH_CLOSE', {}); P.Emit('P_AH_CLOSE', {})
    T.eq(n, 2)
  end)
end)

T.describe('Context through the whole adapter chain', function()
  T.it('a vendor visit seen from raw events leaves a vendor context', function()
    local W, P, ns = World.boot()
    ns.Context.Reset()
    ns.Collector.On({})
    W:fire('MERCHANT_SHOW')
    T.truthy(ns.Context.IsActive('vendor'))
    W:fire('MERCHANT_CLOSED')
    W:advance(1.5)
    T.falsy(ns.Context.IsActive('vendor'))
    T.eq(ns.Context.Stats().vendor.opened, 1)
  end)

  T.it('nothing opens a context while collect is off', function()
    local W, _, ns = World.boot()
    ns.Context.Reset()
    W:fire('MERCHANT_SHOW'); W.state.mailShown = true; W:advance(2.0)
    for _, kind in ipairs(ns.Context.KINDS) do T.eq(ns.Context.Stats()[kind].opened, 0, kind) end
  end)

  T.it('collect off drops the contexts that were open (AC-8)', function()
    local W, _, ns = World.boot()
    ns.Collector.On({})
    W:fire('MERCHANT_SHOW')
    ns.Collector.Off()
    T.eq(#ns.Context.Active(), 0)
  end)
end)
