--[[
Tests / test_platform_boundary.lua                (TODO 1.5, Requirements FR-PLT-1, acceptance criterion 6)

Static checks over every file named in GoldIntel.toc:
  1. All listed files exist.
  2. No WoW global is referenced as a bare identifier anywhere (not even in Platform/):
     WoW APIs may only be reached through P.env / P.fn so tests can inject a fake.
  3. Lua 5.1 compatibility lint (WoW runs Lua 5.1): no goto, table.unpack, or '//'.
  4. Loading every file creates no accidental real globals.
  5. The scanner itself is correct (comments and strings are ignored).
]]

local T = require('testlib')
local Fake = require('fake_wow')
local Loader = require('loader')

local WOW_GLOBALS = {}
for _, name in ipairs({
  'GetMoney', 'GetTime', 'time', 'date', 'CreateFrame', 'UnitGUID', 'UnitName', 'UnitClass',
  'UnitLevel', 'UnitFactionGroup', 'C_Map', 'C_Timer', 'C_AuctionHouse', 'C_TradeSkillUI',
  'WorldMapFrame', 'SlashCmdList', 'LibStub', 'GetLocale', 'GetBuildInfo', 'IsInInstance',
  'GetInstanceInfo', 'GetZoneText', 'GetSubZoneText', 'GetNumSkillLines', 'GetSkillLineInfo',
  'ExpandSkillHeader', 'CollapseSkillHeader', 'GetProfessions', 'GetProfessionInfo', 'IsLoggedIn',
  'print', 'GoldIntelDB', 'GoldIntelCharDB', 'WOW_PROJECT_ID', 'GetLootSlotInfo',
  'QueryAuctionItems', 'GetAuctionItemInfo', 'CalculateAuctionDeposit', 'GetInboxItem',
  'GetInboxHeaderInfo', 'TakeInboxMoney', 'GetPlayerTradeMoney', 'GetTargetTradeMoney',
  'GetTradeSkillInfo', 'GetTradeSkillReagentInfo', 'hooksecurefunc', 'strsplit', 'wipe',
  'tinsert', 'tremove', 'format', 'strtrim', 'floor', 'ceil', 'max', 'min', 'abs',
  'getglobal', 'setglobal', 'UIParent', 'GameTooltip', 'DEFAULT_CHAT_FRAME', 'GetNumLootItems',
  'GetRealmName', 'GetCoinTextureString', 'GetServerTime', 'debugprofilestop',
  'C_EventUtils', 'issecretvalue',
  'C_Container', 'C_Item', 'MailFrame', 'AuctionHouseFrame', 'GetLootSlotType', 'GetLootSourceInfo',
  'GetLootSlotLink', 'GetInboxNumItems', 'GetInboxInvoiceInfo', 'C_AddOns', 'IsAddOnLoaded',
  'GetItemInfo', 'RequestLoadItemDataByID',
}) do WOW_GLOBALS[name] = true end

--- Returns the source with comments removed and string/long-string contents blanked.
local function stripLua(src)
  local out, i, n = {}, 1, #src
  while i <= n do
    local c = src:sub(i, i)
    if src:sub(i, i + 1) == '--' then
      local level = src:match('^%-%-%[(=*)%[', i)
      if level then
        local _, e = src:find(']' .. level .. ']', i, true)
        i = (e or n) + 1
      else
        local e = src:find('\n', i, true)
        i = e or (n + 1)
      end
    elseif c == '"' or c == "'" then
      local j = i + 1
      while j <= n do
        local d = src:sub(j, j)
        if d == '\\' then j = j + 2
        elseif d == c then break
        else j = j + 1 end
      end
      out[#out + 1] = '""'
      i = j + 1
    elseif c == '[' and src:match('^%[=*%[', i) then
      local level = src:match('^%[(=*)%[', i)
      local _, e = src:find(']' .. level .. ']', i, true)
      out[#out + 1] = '""'
      i = (e or n) + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

--- Returns a list of "name (line N)" for bare WoW global identifiers.
local function findBareGlobals(code)
  local found = {}
  local lineNo = 1
  for line in (code .. '\n'):gmatch('(.-)\n') do
    for pre, id in line:gmatch('([%.:]?)([%a_][%w_]*)') do
      if pre == '' and WOW_GLOBALS[id] then
        found[#found + 1] = id .. ' (line ' .. lineNo .. ')'
      end
    end
    lineNo = lineNo + 1
  end
  return found
end

T.describe('boundary scanner (self-test)', function()
  T.it('ignores comments, strings, long strings and field accesses', function()
    local src = table.concat({
      '-- GetMoney in a comment',
      '--[[ CreateFrame in a long comment ]]',
      "local a = 'GetMoney'",
      'local b = "CreateFrame"',
      'local c = [[ UnitGUID ]]',
      'local d = P.env.GetMoney',
      'local e = obj:GetTime()',
    }, '\n')
    T.eq(findBareGlobals(stripLua(src)), {})
  end)

  T.it('flags bare identifiers and reports the line', function()
    local found = findBareGlobals(stripLua('local x = 1\nlocal m = GetMoney()\nCreateFrame("Frame")'))
    T.eq(found, { 'GetMoney (line 2)', 'CreateFrame (line 3)' })
  end)

  T.it('handles escaped quotes inside strings', function()
    T.eq(findBareGlobals(stripLua([[local s = "say \"GetMoney\" now"]])), {})
  end)
end)

T.describe('addon source files', function()
  local files = Loader.tocFiles()

  T.it('the TOC lists at least the Phase 1 files', function()
    local want = { 'Platform/Platform.lua', 'Platform/Probe.lua', 'Platform/Events.lua', 'Platform/Clock.lua',
      'Platform/Scheduler.lua', 'Platform/Unit.lua', 'Platform/Map.lua', 'Platform/Money.lua' }
    local have = {}
    for _, f in ipairs(files) do have[f] = true end
    for _, f in ipairs(want) do T.truthy(have[f], 'TOC is missing ' .. f) end
  end)

  T.it('Platform.lua loads first, Probe.lua is the last Platform file, Boot.lua is last overall', function()
    T.eq(files[1], 'Platform/Platform.lua')
    local lastPlatform
    for _, f in ipairs(files) do
      if f:sub(1, 9) == 'Platform/' then lastPlatform = f end
    end
    T.eq(lastPlatform, 'Platform/Probe.lua')
    T.eq(files[#files], 'Core/Boot.lua')
  end)

  for _, path in ipairs(files) do
    T.it(path .. ' exists, uses no bare WoW globals, and is Lua 5.1 safe', function()
      local src = Loader.readFile(Loader.root .. '/' .. path)
      local code = stripLua(src)
      T.eq(findBareGlobals(code), {}, 'bare WoW globals in ' .. path)
      T.falsy(code:find('%f[%w_]goto%f[^%w_]'), path .. ' uses goto (not Lua 5.1)')
      T.falsy(code:find('table.unpack', 1, true), path .. ' uses table.unpack (not Lua 5.1)')
      T.falsy(code:find('//', 1, true), path .. ' uses // (not Lua 5.1)')
    end)
  end

  -- Client-compatibility rules (Decisions D-024). They exist because the first real-client
  -- test rejected every file; see GoldIntel_Docs/archive/Phase1_Compat_Analysis.md.
  T.it('C-1..C-3: files are plain ASCII, LF only, no BOM, end with a newline, no long brackets', function()
    for _, path in ipairs(files) do
      local raw = Loader.readFile(Loader.root .. '/' .. path)
      T.falsy(raw:find('[\128-\255]'), path .. ' contains non-ASCII bytes')
      T.falsy(raw:find('\r', 1, true), path .. ' contains CR characters')
      T.eq(raw:sub(-1), '\n', path .. ' must end with a newline')
      T.falsy(raw:find('%[=*%['), path .. ' contains a long bracket ([[ or [=[); use -- line comments')
    end
  end)

  T.it('C-4: the TOC is minimal, targets interface 16001 and uses forward slashes', function()
    local toc = Loader.readFile(Loader.root .. '/GoldIntel.toc')
    T.truthy(toc:find('## Interface: 16001', 1, true), 'Interface must be 16001 (WoW Forever)')
    T.falsy(toc:find('\\', 1, true), 'TOC must not contain backslashes')
    T.falsy(toc:find('\r', 1, true), 'TOC must be LF only')
    T.falsy(toc:find('[\128-\255]'), 'TOC must be ASCII')
    T.falsy(toc:find('\n#[^#]'), 'TOC comment lines (single #) are not used; keep the TOC minimal')
    T.truthy(toc:find('## SavedVariables: GoldIntelDB', 1, true))
    for _, path in ipairs(files) do
      T.falsy(path:find('\\', 1, true), path)
      T.truthy(path:match('^[%w_/]+%.lua$'), 'unexpected characters in TOC path ' .. path)
    end
  end)

  T.it('C-6: only Platform/Events.lua may call RegisterEvent (restricted events are never probed by registering)', function()
    for _, path in ipairs(files) do
      local code = stripLua(Loader.readFile(Loader.root .. '/' .. path))
      if path ~= 'Platform/Events.lua' then
        T.falsy(code:find('RegisterEvent', 1, true), path .. ' calls RegisterEvent; only Events.lua may (Decisions D-025)')
      end
    end
  end)

  T.it('C-5: every addon file starts with the namespace line before any other statement', function()
    for _, path in ipairs(files) do
      local code = stripLua(Loader.readFile(Loader.root .. '/' .. path))
      local first = code:match('^%s*([^\n]+)')
      T.eq(first, 'local ADDON, GI = ...', path .. ' must begin with: local ADDON, GI = ...')
    end
  end)

  T.it('loading all files creates no real globals', function()
    local before = {}
    for k in pairs(_G) do before[k] = true end
    local W = Fake.new()
    Loader.load(W.env)
    local leaked = {}
    for k in pairs(_G) do
      if not before[k] then leaked[#leaked + 1] = tostring(k) end
    end
    T.eq(leaked, {}, 'globals leaked by addon files')
  end)
end)

T.describe('3b-1 boundary: collector files', function()
  local files = Loader.tocFiles()
  local function strip(f) return stripLua(Loader.readFile(Loader.root .. '/' .. f)) end

  T.it('the new 3b-1 files are in the TOC', function()
    local have = {}
    for _, f in ipairs(files) do have[f] = true end
    for _, f in ipairs({ 'Platform/Loot.lua', 'Platform/Merchant.lua', 'Platform/Quest.lua', 'Platform/Trade.lua',
      'Platform/Mail.lua', 'Platform/Auction.lua', 'Platform/Items.lua', 'Platform/Bags.lua',
      'Collect/Context.lua', 'Collect/Collector.lua' }) do T.truthy(have[f], f) end
  end)

  T.it('RegisterEvent and RegisterUnitEvent are called only from Platform/Events.lua', function()
    for _, f in ipairs(files) do
      if f ~= 'Platform/Events.lua' then
        local code = strip(f)
        T.falsy(code:find('RegisterEvent', 1, true), f .. ' calls RegisterEvent')
        T.falsy(code:find('RegisterUnitEvent', 1, true), f .. ' calls RegisterUnitEvent')
      end
    end
  end)

  T.it('nothing under Collect/ touches a WoW API: no P.env or P.fn access at all', function()
    for _, f in ipairs(files) do
      if f:sub(1, 8) == 'Collect/' then
        local code = strip(f)
        T.falsy(code:find('P.env', 1, true), f)
        T.falsy(code:find('P.fn', 1, true), f)
      end
    end
  end)

  T.it('loading the addon with the collector files creates no accidental globals', function()
    local W = Fake.new()
    local before = {}
    for k in pairs(_G) do before[k] = true end
    Loader.load(W.env)
    for k in pairs(_G) do T.truthy(before[k], 'new real global: ' .. tostring(k)) end
  end)
end)
