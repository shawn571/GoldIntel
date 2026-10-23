--[[
Tests / test_replay_chat.lua              (Phase 3b-2 M5; permanent regression corpus, D-073)

E-49: the real grouped run (group of 2, 14 coin changes totalling 49 copper, 7 of them looted by the partner), replayed
with the measured timing of every loot window, money change and chat line. Every coin change must be a loot entry.
E-48: the solo run (10 loots, "You loot N Copper").
]]

local T = require('testlib')
local L = require('ledgerworld')

local unpack_ = table.unpack or unpack

-- { gt, kind, arg }  kind: open (amounts) | clear | hide | pay | chat
local E49 = {
  { 697.405, 'open', { 11 } }, { 697.855, 'clear' }, { 697.972, 'pay', 6 }, { 698.005, 'hide' }, { 698.872, 'chat', 'Your share of the loot is 6 Copper.' },
  { 710.224, 'pay', 4 }, { 711.024, 'chat', 'Your share of the loot is 4 Copper.' },
  { 715.128, 'open', { 7 } }, { 715.795, 'pay', 4 }, { 715.945, 'hide' }, { 716.533, 'chat', 'Your share of the loot is 4 Copper.' },
  { 752.965, 'pay', 4 }, { 753.965, 'chat', 'Your share of the loot is 4 Copper.' },
  { 798.652, 'open', { 1 } }, { 799.537, 'pay', 1 }, { 800.037, 'chat', 'Your share of the loot is 1 Copper.' }, { 800.654, 'hide' },
  { 830.058, 'open', { 19 } }, { 830.642, 'pay', 10 }, { 830.658, 'hide' }, { 831.551, 'chat', 'Your share of the loot is 10 Copper.' },
  { 898.499, 'pay', 1 }, { 899.250, 'chat', 'Your share of the loot is 1 Copper.' },
  { 916.066, 'open', { 4 } }, { 916.683, 'pay', 2 }, { 917.466, 'chat', 'Your share of the loot is 2 Copper.' }, { 917.673, 'hide' },
  { 933.249, 'pay', 3 }, { 933.966, 'chat', 'Your share of the loot is 3 Copper.' },
  { 952.778, 'pay', 5 }, { 953.295, 'chat', 'Your share of the loot is 5 Copper.' },
  { 964.710, 'open', { 3 } }, { 965.210, 'hide' }, { 965.244, 'pay', 2 }, { 966.099, 'chat', 'Your share of the loot is 2 Copper.' },
  { 974.240, 'pay', 1 }, { 974.890, 'chat', 'Your share of the loot is 1 Copper.' },
  { 982.238, 'open', { 9 } }, { 982.671, 'pay', 5 }, { 983.338, 'hide' }, { 983.672, 'chat', 'Your share of the loot is 5 Copper.' },
  { 996.071, 'pay', 1 }, { 996.816, 'chat', 'Your share of the loot is 1 Copper.' },
}

local E48 = {
  { 26.0, 'open', { 2 } }, { 26.609, 'pay', 2 }, { 27.130, 'chat', 'You loot 2 Copper' }, { 27.587, 'hide' },
  { 37.749, 'open', { 3 } }, { 38.366, 'pay', 3 }, { 39.116, 'chat', 'You loot 3 Copper' }, { 39.149, 'hide' },
  { 63.354, 'open', { 4 } }, { 63.854, 'hide' }, { 63.937, 'pay', 4 }, { 64.771, 'chat', 'You loot 4 Copper' },
  { 71.699, 'open', { 6 } }, { 72.199, 'pay', 6 }, { 72.199, 'hide' }, { 73.199, 'chat', 'You loot 6 Copper' },
  { 83.834, 'open', { 6 } }, { 84.334, 'hide' }, { 84.384, 'pay', 6 }, { 85.234, 'chat', 'You loot 6 Copper' },
  { 126.601, 'open', { 1 } }, { 127.201, 'hide' }, { 127.251, 'pay', 1 }, { 128.085, 'chat', 'You loot 1 Copper' },
  { 135.961, 'open', { 3 } }, { 136.464, 'hide' }, { 136.548, 'pay', 3 }, { 137.416, 'chat', 'You loot 3 Copper' },
  { 147.851, 'open', { 7 } }, { 148.451, 'pay', 7 }, { 148.451, 'hide' }, { 149.336, 'chat', 'You loot 7 Copper' },
  { 156.932, 'open', { 9 } }, { 157.432, 'hide' }, { 157.549, 'pay', 9 }, { 158.349, 'chat', 'You loot 9 Copper' },
  { 171.990, 'open', { 10 } }, { 172.757, 'pay', 10 }, { 172.793, 'hide' }, { 173.393, 'chat', 'You loot 10 Copper' },
}

local function replay(rows, groupN, tailPay)
  local W, _, ns = L.boot()
  if groupN then W.state.group = { n = groupN } end
  local last = rows[1][1]
  local deltas = 0
  for _, r in ipairs(rows) do
    local gap = r[1] - last
    if gap > 0 then W:advance(gap) end
    last = r[1]
    local kind = r[2]
    if kind == 'open' then
      local slots = {}
      for i, a in ipairs(r[3]) do slots[i] = { type = 2, amount = a } end
      W.state.loot = { guid = 'Creature-0-4621-0-1-95-' .. string.format('%04X', math.floor(r[1] * 10) % 65535), slots = slots }
      W.state.lootShown = true
      W:fire('LOOT_OPENED')
    elseif kind == 'clear' then W:fire('LOOT_SLOT_CLEARED', 1)
    elseif kind == 'hide' then W.state.lootShown = false
    elseif kind == 'pay' then L.pay(W, r[3]); deltas = deltas + r[3]
    elseif kind == 'chat' then W:fire('CHAT_MSG_MONEY', r[3]) end
  end
  W:advance(4.0)
  return W, ns, deltas
end

T.describe('replay E-49: grouped coin, chat-signal rule', function()
  T.it('all 14 coin changes (49 copper, 7 partner-looted) are loot entries; nothing is OTHER or unmatched', function()
    local _, ns, deltas = replay(E49, 2)
    local s, e = ns.Sources.Stats(), ns.Sources.Entries()
    T.eq(deltas, 49)
    T.eq(#e, 14)
    local sum = 0
    for _, x in ipairs(e) do
      T.eq(x.src, 'loot'); T.eq(x.conf, 'high'); sum = sum + x.copper
      T.truthy(x.act == 'GRIND' or x.act == 'LOOT', 'activity ' .. tostring(x.act))   -- never OTHER
      T.eq(x.actConf, 'med')
    end
    T.eq(sum, 49)
    T.eq(s.otherShareValue, 0); T.eq(s.otherShareEntries, 0); T.eq(s.largestOther, 0)
    T.eq(s.unmatched, 0); T.eq(s.gapCount, 0); T.eq(s.pending, 0)
    T.eq(s.sumDeltas, 49); T.eq(s.sumEntries, 49)
  end)
end)

T.describe('replay E-48: solo coin, chat-signal rule', function()
  T.it('10 loots, "You loot N Copper": 10 entries, no doubles, nothing unmatched', function()
    local _, ns, deltas = replay(E48)
    local s, e = ns.Sources.Stats(), ns.Sources.Entries()
    T.eq(deltas, 51)
    T.eq(#e, 10)
    for _, x in ipairs(e) do T.eq(x.src, 'loot') end
    T.eq(s.otherShareValue, 0); T.eq(s.unmatched, 0); T.eq(s.pending, 0)
    T.eq(s.sumDeltas, s.sumEntries)
    T.eq(s.sources.chatClaimed, 10)
  end)
end)
