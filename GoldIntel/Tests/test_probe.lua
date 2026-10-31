--[[
Tests / test_probe.lua                                      (task 1.3: Probe.lua)

Capability detection, report format, SavedVariables persistence, the temporary /gi
command, the fatal path, and robustness against failing probes.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local Loader = require('loader')

local function bootAll(fakeOpts)
  local W, P = Loader.boot(fakeOpts or {})
  return W, P
end

local function has(lines, needle)
  for _, line in ipairs(lines) do
    if line:find(needle, 1, true) then return true end
  end
  return false
end

T.describe('Probe.Run', function()
  T.it('detects what the fake client provides and what it lacks', function()
    local _, P = bootAll()
    local caps = P.Probe()
    T.truthy(caps['frame'])
    T.truthy(caps['money.get'])
    T.truthy(caps['money.event'])
    T.truthy(caps['timer.ctimer'])
    T.truthy(caps['identity.guid'])
    T.truthy(caps['map.cmap'])
    T.truthy(caps['zone.text'])
    T.isnil(caps['prof.skilllines'], 'removed under D-027')
    T.truthy(caps['slash'])
    T.falsy(caps['prof.getprofessions'])
    T.isnil(caps['auction.legacy'], 'removed under D-027')
    T.falsy(caps['auction.modern'])
    T.falsy(caps['mail.api'])
    T.isnil(caps['tradeskill.legacy'], 'removed under D-027')
    T.falsy(caps['map.worldframe'])
    T.falsy(caps['lib.hbd'])
  end)

  T.it('returns a copy, and re-running is safe and consistent', function()
    local _, P = bootAll()
    local a = P.Probe()
    a['frame'] = false
    local b = P.Probe()
    T.truthy(b['frame'])
    T.truthy(P.Has('frame'))
  end)

  T.it('invalid event names are reported per family, from names only (nothing is registered)', function()
    local W, P = bootAll()
    local before = #W.registerCalls
    W.state.invalidEvents.MAIL_INBOX_UPDATE = true
    P.Probe()
    T.falsy(P.Has('mail.events'))
    T.truthy(P.CapNote('mail.events'):find('MAIL_INBOX_UPDATE', 1, true))
    T.truthy(P.Has('merchant.events'))
    T.eq(#W.registerCalls, before, 'Probe must not call RegisterEvent at all')
  end)

  T.it('PROBE NEVER REGISTERS EVENTS: a client that forbids restricted/late events sees no violation', function()
    local W, P = bootAll()
    for _, e in ipairs({ 'COMBAT_LOG_EVENT_UNFILTERED', 'LOOT_OPENED', 'MAIL_SHOW', 'AUCTION_HOUSE_SHOW',
                         'TRADE_SHOW', 'MERCHANT_SHOW', 'QUEST_TURNED_IN', 'UNIT_SPELLCAST_SUCCEEDED' }) do
      W.state.forbiddenEvents[e] = true
    end
    local before = #W.registerCalls
    P.Probe()
    T.eq(#W.forbidden, 0)
    T.eq(#W.registerCalls, before)
  end)

  T.it('the combat log family is reported [unknown] (restricted), never missing and never registered', function()
    local _, P = bootAll()
    P.Probe()
    T.falsy(P.Has('combatlog.event'))
    T.eq(P.ProbeModule.last.status['combatlog.event'], 'unknown')
    T.truthy(P.CapNote('combatlog.event') == nil or true)
    T.truthy(P.ProbeModule.last.notes['combatlog.event']:find('restricted', 1, true))
  end)

  T.it('without C_EventUtils every event family is [unknown] and nothing is registered', function()
    local W, P = bootAll({ without = { 'C_EventUtils' } })
    local before = #W.registerCalls
    P.Probe()
    T.eq(P.ProbeModule.last.status['zone.events'], 'unknown')
    T.eq(P.ProbeModule.last.status['mail.events'], 'unknown')
    T.falsy(P.Has('zone.events'))
    T.eq(#W.registerCalls, before)
  end)

  T.it('optional libraries are detected through LibStub', function()
    local _, P = bootAll({ libs = { ['HereBeDragons-2.0'] = true, ['AceDB-3.0'] = true } })
    P.Probe()
    T.truthy(P.Has('lib.libstub'))
    T.truthy(P.Has('lib.hbd'))
    T.truthy(P.Has('lib.acedb'))
    T.falsy(P.Has('lib.acegui'))
  end)

  T.it('absent LibStub means every lib capability is false, with no error', function()
    local _, P = bootAll({ without = { 'LibStub' } })
    P.Probe()
    T.falsy(P.Has('lib.libstub'))
    T.falsy(P.Has('lib.hbd'))
    T.falsy(P.Has('lib.aceaddon'))
  end)

  T.it('a probe that raises is recorded as missing with its error', function()
    local _, P = bootAll()
    local probes = P.ProbeModule.PROBES
    probes[#probes + 1] = { cap = 'test.boom', fn = function() error('probe bug') end }
    P.Probe()
    T.falsy(P.Has('test.boom'))
    T.truthy(P.CapNote('test.boom'):find('probe bug', 1, true))
    probes[#probes] = nil
  end)

  T.it('without CreateFrame the frame capability and money.event are missing, event NAMES still check out', function()
    local _, P = bootAll({ without = { 'CreateFrame' } })
    P.Probe()
    T.falsy(P.Has('frame'))
    T.falsy(P.Has('money.event'))
    T.truthy(P.Has('zone.events'), 'name validity does not need a frame')
  end)

  T.it('identity.guid is false when the GUID is not available yet', function()
    local W, P = bootAll()
    W.state.guid = nil
    P.Probe()
    T.falsy(P.Has('identity.guid'))
  end)
end)

T.describe('Probe.Report', function()
  T.it('contains build info, operational state, capabilities, [unknown] entries and failed registrations', function()
    local W, P = bootAll()
    W.state.invalidEvents.TRADE_SHOW = true
    P.Probe()
    local lines = P.ProbeModule.Report()
    T.truthy(has(lines, 'game version: 1.15.9'))
    T.truthy(has(lines, 'build: 61000'))
    T.truthy(has(lines, 'interface (toc): 11509'))
    T.truthy(has(lines, 'locale: enUS'))
    T.truthy(has(lines, 'WOW_PROJECT_ID: 2'))
    T.truthy(has(lines, 'operational: yes'))
    T.truthy(has(lines, '[ok]      money.get'))
    T.truthy(has(lines, '[MISSING] auction.modern'))
    T.truthy(has(lines, 'invalid event names: TRADE_SHOW'))
    T.truthy(has(lines, '[unknown] combatlog.event'))
    T.truthy(has(lines, '--- events GoldIntel tried to register and could not ---'))
  end)

  T.it('lists capabilities in sorted order and hides per-event entries from the main list', function()
    local _, P = bootAll()
    P.Probe()
    local lines = P.ProbeModule.Report()
    local last
    for _, line in ipairs(lines) do
      local name = line:match('^%[%a+%]%s+([%w%._]+)')
      if name then
        T.falsy(name:sub(1, 6) == 'event.', 'event.* must not appear in the capability list')
        if last then T.truthy(last <= name, last .. ' should sort before ' .. name) end
        last = name
      end
    end
    T.truthy(last)
  end)

  T.it('says NO and why when the platform is not operational', function()
    local _, P = bootAll()
    P.Fatal('money.get', 'test failure reason')
    P.Probe()
    T.truthy(has(P.ProbeModule.Report(), 'operational: NO - test failure reason'))
  end)

  T.it('runs the probe itself when none ran yet', function()
    local _, P = bootAll()
    P.ProbeModule.last = nil
    T.truthy(#P.ProbeModule.Report() > 5)
  end)

  T.it('tolerates missing build APIs', function()
    local _, P = bootAll({ without = { 'GetBuildInfo', 'GetLocale' } })
    P.Probe()
    T.truthy(has(P.ProbeModule.Report(), 'game version: nil'))
  end)
end)

T.describe('Probe.Persist', function()
  T.it('creates GoldIntelDB.compat with caps, build info and report', function()
    local W, P = bootAll()
    P.Probe()
    T.truthy(P.ProbeModule.Persist())
    local compat = W.env.GoldIntelDB.compat
    T.eq(compat.build, '61000')
    T.eq(compat.interface, 11509)
    T.eq(compat.locale, 'enUS')
    T.eq(compat.addonVersion, P.VERSION)
    T.eq(compat.operational, true)
    T.truthy(compat.caps['money.get'])
    T.eq(compat.status['combatlog.event'], 'unknown')
    T.truthy(#compat.report > 5)
    T.eq(compat.probedAt, 1700000000)
  end)

  T.it('keeps unrelated data already in GoldIntelDB', function()
    local W, P = bootAll()
    W.env.GoldIntelDB = { schema = 1, profile = { idleSec = 99 } }
    P.Probe()
    P.ProbeModule.Persist()
    T.eq(W.env.GoldIntelDB.schema, 1)
    T.eq(W.env.GoldIntelDB.profile.idleSec, 99)
    T.truthy(W.env.GoldIntelDB.compat)
  end)

  T.it('replaces a corrupt non-table GoldIntelDB and warns', function()
    local W, P = bootAll()
    W.env.GoldIntelDB = 'corrupt'
    P.Probe()
    T.truthy(P.ProbeModule.Persist())
    T.eq(type(W.env.GoldIntelDB), 'table')
    local warned = false
    for _, d in ipairs(P.GetDiag()) do
      if d.level == 'warn' and d.msg:find('not a table', 1, true) then warned = true end
    end
    T.truthy(warned)
  end)

  T.it('the persisted caps are a copy, not the live table', function()
    local W, P = bootAll()
    P.Probe()
    P.ProbeModule.Persist()
    P.SetCap('money.get', false)
    T.truthy(W.env.GoldIntelDB.compat.caps['money.get'])
  end)

  T.it('refuses to persist before any probe result exists', function()
    local _, P = bootAll()
    P.ProbeModule.last = nil
    local ok, err = P.ProbeModule.Persist()
    T.isnil(ok)
    T.truthy(err)
  end)
end)

T.describe('startup at PLAYER_LOGIN', function()
  T.it('a full login with probe and /gi probe never triggers a forbidden registration', function()
    local W = Fake.new()
    for _, e in ipairs({ 'COMBAT_LOG_EVENT_UNFILTERED', 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'MAIL_SHOW', 'MAIL_CLOSED',
                         'AUCTION_HOUSE_SHOW', 'TRADE_SHOW', 'MERCHANT_SHOW', 'QUEST_TURNED_IN',
                         'UNIT_SPELLCAST_SUCCEEDED', 'CHAT_MSG_MONEY' }) do
      W.state.forbiddenEvents[e] = true
    end
    local P = Loader.load(W.env)
    W:login()
    W.env.SlashCmdList.GOLDINTEL('probe')
    P.Probe()
    T.eq(W.forbidden, {}, 'forbidden registrations attempted: ' .. table.concat(W.forbidden, ','))
    T.truthy(P.IsOperational())
  end)


  T.it('probes, persists, and announces once per client build', function()
    local W, P = bootAll()
    W:login()
    T.truthy(W.env.GoldIntelDB.compat.caps['money.get'])
    T.truthy(W:printedText():find('platform probe saved for client build 61000', 1, true))
    T.truthy(P.IsOperational())
  end)

  T.it('does not repeat the announcement for an unchanged build', function()
    local W = Fake.new()
    W.env.GoldIntelDB = { compat = { build = '61000' } }
    Loader.load(W.env)
    W:login()
    T.falsy(W:printedText():find('platform probe saved', 1, true))
    T.truthy(W.env.GoldIntelDB.compat.caps, 'but the data is refreshed')
  end)

  T.it('announces again when the build changed', function()
    local W = Fake.new()
    W.env.GoldIntelDB = { compat = { build = '55555' } }
    Loader.load(W.env)
    W:login()
    T.truthy(W:printedText():find('platform probe saved', 1, true))
  end)

  T.it('fatal path: a client without frames disables the addon with a clear message', function()
    local W = Fake.new({ without = { 'CreateFrame' } })
    W.state.loggedIn = true                  -- late load, since no frame can deliver PLAYER_LOGIN
    local P = Loader.load(W.env)
    T.falsy(P.IsOperational())
    T.truthy(P.fatalReason:find('frame', 1, true))
    T.truthy(W:printedText():find('GoldIntel is disabled', 1, true))
    T.falsy(W.env.GoldIntelDB.compat.operational)
  end)

  T.it('fatal path: PLAYER_MONEY not registrable disables the addon', function()
    local W = Fake.new()
    W.state.invalidEvents.PLAYER_MONEY = true
    local P = Loader.load(W.env)
    W:login()
    T.falsy(P.IsOperational())
    T.truthy(P.fatalReason:find('money.event', 1, true))
  end)

  T.it('a degraded but sufficient client stays operational', function()
    local W = Fake.new({ without = { 'C_Map', 'C_Timer', 'GetNumSkillLines', 'GetSkillLineInfo', 'LibStub' } })
    local P = Loader.load(W.env)
    W:login()
    T.truthy(P.IsOperational())
    T.falsy(P.Has('map.cmap'))
    T.falsy(P.Has('prof.skilllines'))
    T.eq(P.Scheduler.Backend(), 'onupdate')
  end)
end)

T.describe('/gi command (moved to Core/Slash.lua in Phase 2)', function()
  T.it('registers /gi through SlashCmdList', function()
    local W = bootAll()
    T.eq(W.env.SLASH_GOLDINTEL1, '/gi')
    T.eq(type(W.env.SlashCmdList.GOLDINTEL), 'function')
  end)

  T.it('creates SlashCmdList when the client has none', function()
    local W = Fake.new({ without = { 'SlashCmdList' } })
    Loader.load(W.env)
    T.eq(type(W.env.SlashCmdList.GOLDINTEL), 'function')
  end)

  T.it('/gi probe prints the report and persists it', function()
    local W = bootAll()
    W:login()
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('probe')
    local text = W:printedText()
    T.truthy(text:find('GoldIntel probe report', 1, true))
    T.truthy(text:find('[ok]      money.get', 1, true))
    T.truthy(text:find('/reload or logout', 1, true))
  end)

  T.it('/gi status prints the platform state', function()
    local W = bootAll()
    W:login()
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('status')
    local text = W:printedText()
    T.truthy(text:find('operational=true', 1, true))
    T.truthy(text:find('ready=true', 1, true))
    T.truthy(text:find('inWorld=true', 1, true))
    T.truthy(text:find('scheduler=ctimer', 1, true))
    T.truthy(text:find('lastRegister=PLAYER_MONEY', 1, true), 'last event registered at load is PLAYER_MONEY')
  end)

  T.it('/gi diag prints recent diagnostics or says there are none', function()
    local W, P = bootAll()
    W.printed = {}
    P.ClearDiag()
    W.env.SlashCmdList.GOLDINTEL('diag')
    T.truthy(W:printedText():find('no diagnostics', 1, true))
    P.Diag('warn', 'Test', 'something odd')
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('diag')
    T.truthy(W:printedText():find('warn [Test] something odd', 1, true))
  end)

  T.it('/gi debug toggles event echo; ticks toggles tick echo', function()
    local W, P = bootAll()
    W.env.SlashCmdList.GOLDINTEL('debug on')
    T.truthy(P.debug)
    W.env.SlashCmdList.GOLDINTEL('debug off')
    T.falsy(P.debug)
    W.env.SlashCmdList.GOLDINTEL('debug ticks')
    T.truthy(P.debugTicks)
    W.env.SlashCmdList.GOLDINTEL('debug ticks')
    T.falsy(P.debugTicks)
  end)

  T.it('before login only the minimal set exists; after login empty input prints the summary', function()
    local W = bootAll()
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('')
    T.truthy(W:printedText():find('operational=', 1, true), 'minimal mode prints the status line')
    W:login()
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('')
    T.truthy(W:printedText():find('GoldIntel 0.5.1-passive', 1, true))
    T.truthy(W:printedText():find('store=', 1, true))
  end)

  T.it('unknown commands and nil input are handled', function()
    local W = bootAll()
    W:login()
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('whatever')
    W.env.SlashCmdList.GOLDINTEL(nil)
    T.truthy(W.printed[1]:find('unknown command "whatever"', 1, true))
    T.eq(#W.printed > 1, true)
  end)

  T.it('commands are case-insensitive', function()
    local W = bootAll()
    W:login()
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL('STATUS')
    T.truthy(W:printedText():find('operational=', 1, true))
  end)
end)
