-- GIProbeLoot: throwaway probe. Question: does LootFrame:IsShown() follow the real loot window?
-- It only READS. It registers only LOOT_OPENED and LOOT_SLOT_CLEARED (both already verified safe).
-- It polls LootFrame every frame and logs every change with GetTime(). No GoldIntel code is involved.

GIProbeLootDB = GIProbeLootDB or {}
local db
local log = {}
local last          -- last polled shown state (nil until the first poll)
local lastVisible
local polls = 0
local lag = 0

local function say(msg)
  local line = string.format('%.3f %s', GetTime(), msg)
  log[#log + 1] = line
  print('|cff66ccffGIProbeLoot|r ' .. line)
end

local function state()
  local f = _G.LootFrame
  if f == nil then return 'no-frame', nil end
  if type(f) ~= 'table' or type(f.IsShown) ~= 'function' then return 'no-IsShown', nil end
  local ok, v = pcall(f.IsShown, f)
  if not ok then return 'error', nil end
  local ok2, vis = pcall(function() return f.IsVisible and f:IsVisible() end)
  if not ok2 then vis = 'error' end
  return v and true or false, vis and true or false
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('PLAYER_LOGIN')
frame:RegisterEvent('LOOT_OPENED')
frame:RegisterEvent('LOOT_SLOT_CLEARED')
frame:SetScript('OnEvent', function(_, event, a1)
  if event == 'PLAYER_LOGIN' then
    db = GIProbeLootDB
    local s, vis = state()
    say('login: LootFrame state=' .. tostring(s) .. ' type=' .. type(_G.LootFrame))
    return
  end
  local s, vis = state()
  local n = (GetNumLootItems and GetNumLootItems()) or -1
  if event == 'LOOT_OPENED' then
    say('EVENT LOOT_OPENED autoLoot=' .. tostring(a1) .. ' slots=' .. n .. ' LootFrame shown=' .. tostring(s) .. ' visible=' .. tostring(vis))
  else
    say('EVENT LOOT_SLOT_CLEARED slot=' .. tostring(a1) .. ' slotsNow=' .. n .. ' LootFrame shown=' .. tostring(s))
  end
end)

frame:SetScript('OnUpdate', function(_, dt)
  polls = polls + 1
  if dt and dt > lag then lag = dt end
  local s, vis = state()
  if s ~= last or vis ~= lastVisible then
    say('POLL LootFrame shown=' .. tostring(s) .. ' visible=' .. tostring(vis) .. ' (was ' .. tostring(last) .. ')')
    last, lastVisible = s, vis
  end
end)

local function save()
  GIProbeLootDB = GIProbeLootDB or {}
  GIProbeLootDB.log = log
  GIProbeLootDB.polls = polls
  GIProbeLootDB.maxFrameSec = lag
  GIProbeLootDB.build = select(2, GetBuildInfo())
end
local saver = CreateFrame('Frame')
saver:RegisterEvent('PLAYER_LOGOUT')
saver:SetScript('OnEvent', save)

SLASH_GIPROBELOOT1 = '/gil'
SlashCmdList['GIPROBELOOT'] = function(msg)
  msg = (msg or ''):lower()
  if msg == 'clear' then log = {}; GIProbeLootDB.log = nil; print('GIProbeLoot: log cleared'); return end
  print(string.format('GIProbeLoot: %d lines, %d polls, longest frame %.3f s, LootFrame now %s', #log, polls, lag, tostring((state()))))
  for i = math.max(1, #log - 25), #log do print(log[i]) end
  save()
end
