--[[
Tests / test_ui061.lua                   (0.6.1-passive: the /reload popup, the Settings window, the bands; D-115)

The reminder becomes a popup (Reload Now / Ignore / Configure) that is never shown in combat or during a boss
encounter; Reload Now asks the client to reload (refusal falls back to a chat line); Configure opens the Settings window
whose slider sets reminder.reloadMinutes in the Safe / Risky / Not Recommended / Off bands; without a popup API the chat
line stays. The fake client gets a StaticPopup, C_UI.Reload and frames that accept any widget call.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local World = require('collectworld')
local Loader = require('loader')

-- frames that accept any method (the fake client only knows events and scripts); calls are recorded per frame
local function uiWorld(W, opts)
  opts = opts or {}
  local env = W.env
  local base = env.CreateFrame
  W.ui = { shown = {}, hidden = {}, reloads = 0, named = {} }
  local function widget(t)
    t.calls = t.calls or {}
    return setmetatable(t, { __index = function(_, k)
      return function(self, ...) self.calls[#self.calls + 1] = { k, ... }; if k == 'GetName' then return self.name end end
    end })
  end
  env.CreateFrame = function(kind, name, parent, template)
    local f = base(kind)
    f.kind, f.name, f.template = kind, name, template
    function f:CreateFontString() local fs = widget({ text = nil }); function fs:SetText(v) self.text = v end; return fs end
    function f:SetMinMaxValues(a, b) self.min, self.max = a, b end
    function f:SetValue(v) self.value = v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end end
    function f:IsShown() return self.shown end
    if name then W.ui.named[name] = f; env[name] = f end
    return widget(f)
  end
  env.UIParent = widget({})
  env.UISpecialFrames = {}
  if not opts.noPopup then
    -- like the client's popup code: showing an open popup again cancels it first with reason 'override'; every
    -- close runs OnHide; a button runs its handler, then the popup hides
    env.StaticPopupDialogs = {}
    W.ui.open = {}
    local function hide(which)
      if not W.ui.open[which] then return end
      W.ui.open[which] = nil
      local d = env.StaticPopupDialogs[which]
      if d and d.OnHide then d.OnHide({}) end
    end
    env.StaticPopup_Show = function(which, text)
      local d = env.StaticPopupDialogs[which]
      if W.ui.open[which] then
        if d and d.OnCancel then d.OnCancel({}, nil, 'override') end
        hide(which)
      end
      W.ui.shown[#W.ui.shown + 1] = { which = which, text = text }
      W.ui.open[which] = true
      return {}
    end
    env.StaticPopup_Hide = function(which) W.ui.hidden[#W.ui.hidden + 1] = which; hide(which) end
    env.StaticPopup_Visible = function(which) return W.ui.open[which] and {} or nil end
    -- a click on a button (or Escape, which the client reports as an Ignore click)
    W.click = function(button, which)
      which = which or 'GOLDINTEL_RELOAD'
      local d = env.StaticPopupDialogs[which]
      assert(W.ui.open[which], 'no open popup to click')
      if button == 'reload' then d.OnAccept({})
      elseif button == 'ignore' or button == 'escape' then d.OnCancel({}, nil, 'clicked')
      elseif button == 'configure' then d.OnAlt({}) end
      hide(which)
    end
  end
  env.C_UI = { Reload = function() if opts.reloadFails then error('blocked') end W.ui.reloads = W.ui.reloads + 1 end }
end

local function session(opts)
  opts = opts or {}
  local W = Fake.new()
  World.extend(W)
  W.state.money = 5000
  uiWorld(W, opts)
  Loader.override = opts.override
  local P, ns = Loader.load(W.env)
  Loader.override = nil
  W:login()
  local function run(text) W.printed = {}; W.env.SlashCmdList.GOLDINTEL(text); return W:printedText() end
  run('collect on'); W:advance(1)
  return W, P, ns, run
end
local function keep(W) return table.concat(W.env.GoldIntelCharDB.trace.keep or {}, '\n') end
local function popup(W) return W.env.StaticPopupDialogs and W.env.StaticPopupDialogs.GOLDINTEL_RELOAD end

T.describe('0.6.1 reminder bands (Core/Reminder, D-115)', function()
  T.it('bands, steps and texts follow the evidence', function()
    local W, _, ns = session()
    local R = ns.Reminder
    T.eq(R.Band(15), 'Safe'); T.eq(R.Band(60), 'Safe'); T.eq(R.Band(90), 'Risky'); T.eq(R.Band(180), 'Risky')
    T.eq(R.Band(240), 'Not Recommended'); T.eq(R.Band(360), 'Not Recommended'); T.eq(R.Band(0), 'Off')
    T.eq(R.STEPS[R.StepIndex(60)], 60); T.eq(R.StepIndex(0), #R.STEPS); T.eq(R.STEPS[R.StepIndex(100)], 90)
    T.truthy(R.Explain(60):find('about 34 cash entries (up to 81', 1, true), R.Explain(60))
    T.truthy(R.Label(120):find('Risky', 1, true))
    T.truthy(R.PopupText(60):find('60 minutes since your data was last saved', 1, true))
  end)
end)

T.describe('0.6.1 reload popup (D-115)', function()
  T.it('after 60 minutes a popup (not a chat line) with three buttons; the trace keeps the line', function()
    local W = session()
    W.printed = {}
    W:advance(59 * 60); T.eq(#W.ui.shown, 0)
    W:advance(2 * 60)
    T.eq(#W.ui.shown, 1)
    T.eq(W.ui.shown[1].which, 'GOLDINTEL_RELOAD')
    T.truthy(W.ui.shown[1].text:find('60 minutes', 1, true))
    local d = popup(W)
    T.eq(d.button1, 'Reload Now'); T.eq(d.button2, 'Ignore'); T.eq(d.button3, 'Configure')
    T.falsy(W:printedText():find('/reload saves it', 1, true))
    T.truthy(keep(W):find('EVT reminder shown minutes=60 band=Safe', 1, true))
  end)

  T.it('Reload Now asks the client to reload; a refusal says to type /reload', function()
    local W = session()
    W:advance(61 * 60)
    W.click('reload')
    T.eq(W.ui.reloads, 1)
    T.truthy(keep(W):find('EVT reminder click=reload', 1, true))
    local W2 = session({ reloadFails = true })
    W2:advance(61 * 60)
    W2.printed = {}
    W2.click('reload')
    T.truthy(W2:printedText():find('type /reload to save', 1, true), W2:printedText())
    T.truthy(keep(W2):find('EVT reminder reloadFailed', 1, true))
  end)

  T.it('Ignore waits for the next interval', function()
    local W = session()
    W:advance(61 * 60)
    W.click('ignore')
    T.truthy(keep(W):find('EVT reminder click=ignore', 1, true))
    W:advance(50 * 60); T.eq(#W.ui.shown, 1)
    W:advance(11 * 60); T.eq(#W.ui.shown, 2)
  end)

  T.it('never in combat: it waits, and a popup that is up hides when combat starts', function()
    local W = session()
    W:advance(58 * 60)
    W:fire('PLAYER_REGEN_DISABLED')
    W:advance(5 * 60); T.eq(#W.ui.shown, 0)
    W:fire('PLAYER_REGEN_ENABLED')
    W:advance(61); T.eq(#W.ui.shown, 1)
    W:fire('PLAYER_REGEN_DISABLED')
    T.eq(W.ui.hidden[#W.ui.hidden], 'GOLDINTEL_RELOAD')
  end)

  T.it('never during a boss encounter (ENCOUNTER_START / ENCOUNTER_END, registered while recording)', function()
    local W = session()
    local reg = table.concat(W.registerCalls, ' ')
    T.truthy(reg:find('ENCOUNTER_START', 1, true) and reg:find('ENCOUNTER_END', 1, true), reg)
    W:advance(58 * 60)
    W:fire('ENCOUNTER_START', 1, 'Boss', 1, 5)
    W:advance(5 * 60); T.eq(#W.ui.shown, 0)
    W:fire('ENCOUNTER_END', 1, 'Boss', 1, 5, 1)
    W:advance(61); T.eq(#W.ui.shown, 1)
    W:fire('ENCOUNTER_START', 2, 'Boss2', 1, 5)
    T.eq(W.ui.hidden[#W.ui.hidden], 'GOLDINTEL_RELOAD')
  end)

  T.it('without a popup API the chat line stays (fallback)', function()
    local W = session({ noPopup = true })
    W.printed = {}
    W:advance(61 * 60)
    T.truthy(W:printedText():find('60 minutes since your data was last saved; /reload saves it', 1, true))
    T.truthy(keep(W):find('EVT reminder chat minutes=60', 1, true))
  end)
end)

T.describe('0.6.1 Settings window (option A, D-115)', function()
  T.it('Configure opens the Settings window on the reminder slider; moving it saves the minutes', function()
    local W, _, ns = session()
    W:advance(61 * 60)
    W.click('configure')
    T.truthy(keep(W):find('EVT reminder click=configure', 1, true))
    local f = W.ui.named.GoldIntelSettingsFrame
    local s = W.ui.named.GoldIntelReminderSlider
    T.truthy(f and f.shown, 'window shown')
    T.eq(s.min, 1); T.eq(s.max, #ns.Reminder.STEPS)
    T.eq(ns.Reminder.STEPS[s.value], 60)
    T.eq(ns.Config.Get('reminder.reloadMinutes'), 60, 'opening the window changes nothing')
    s:SetValue(6)
    T.eq(ns.Config.Get('reminder.reloadMinutes'), ns.Reminder.STEPS[6])
    T.eq(ns.Reminder.Band(ns.Reminder.STEPS[6]), 'Risky')
    s:SetValue(#ns.Reminder.STEPS)
    T.eq(ns.Config.Get('reminder.reloadMinutes'), 0, 'Off')
    T.eq(W.env.UISpecialFrames[1], 'GoldIntelSettingsFrame', 'Escape closes it')
  end)

  T.it('/gi settings opens it too; without CreateFrame a chat line names the command instead', function()
    local W, _, _, run = session()
    run('settings')
    T.truthy(W.ui.named.GoldIntelSettingsFrame.shown)
    local W2, _, _, run2 = session()
    W2.env.CreateFrame = nil
    W2.env.GoldIntelSettingsFrame = nil
    local out = run2('settings')
    T.truthy(out:find('use /gi config set reminder.reloadMinutes', 1, true), out)
  end)
end)

---------------------------------------------------------------------------
-- 0.6.2 (D-118)
---------------------------------------------------------------------------
-- (a) after Configure, Ignore or Reload Now the next popup waits one full interval from the click
local function fullIntervalScenario(override)
  for _, button in ipairs({ 'configure', 'ignore', 'reload' }) do
    local W = session({ override = override })
    W:advance(61 * 60)
    assert(#W.ui.shown == 1, button .. ': first popup')
    W:advance(26)                                                  -- as in the trace: 696 s -> click -> 722 s
    W.click(button)
    W:advance(59 * 60)
    assert(#W.ui.shown == 1, button .. ': popup again before a full interval: ' .. #W.ui.shown)
    W:advance(2 * 60)
    assert(#W.ui.shown == 2, button .. ': popup after a full interval: ' .. #W.ui.shown)
  end
end

-- (b) never a second show while the popup is open; a real Ignore click never re-shows it immediately
local function noReshowScenario(override)
  local W = session({ override = override })
  W:advance(61 * 60)
  W:advance(50 * 60)                                               -- open for 50 minutes, no click
  assert(#W.ui.shown == 1, 'shown again while open: ' .. #W.ui.shown)
  W.click('ignore')
  W:advance(61)
  assert(#W.ui.shown == 1, 'Ignore re-showed it')
  assert(not keep(W):find('closed reason=override', 1, true), 'the client never had to cancel an open popup')
end

-- (c) the log separates the user's clicks from closes the client (or GoldIntel) makes
local function logScenario(override)
  local W = session({ override = override })
  W:advance(61 * 60)
  W.env.StaticPopup_Show('GOLDINTEL_RELOAD', 'another show')      -- the client cancels the open one ('override')
  local k = keep(W)
  assert(k:find('EVT reminder closed reason=override', 1, true), 'override logged as a close')
  assert(not k:find('click=ignore', 1, true), 'override logged as a click')
  return W
end

T.describe('0.6.2 reminder (D-118)', function()
  T.it('(a) after Configure, Ignore or Reload Now the next popup waits one full interval', function() fullIntervalScenario() end)
  T.it('(b) no second show while open; Ignore never re-shows it at once', function() noReshowScenario() end)
  T.it('(c) clicks and the client\'s own closes are logged apart; Escape counts as Ignore', function()
    logScenario()
    local W = session()
    W:advance(61 * 60)
    W.click('escape')
    T.truthy(keep(W):find('EVT reminder click=ignore', 1, true))
  end)
  T.it('hidden for combat: logged as closed reason=combat, back after combat without a new interval', function()
    local W = session()
    W:advance(61 * 60)
    W:fire('PLAYER_REGEN_DISABLED')
    T.truthy(keep(W):find('EVT reminder closed reason=combat', 1, true))
    T.falsy(keep(W):find('click=ignore', 1, true))
    W:fire('PLAYER_REGEN_ENABLED')
    W:advance(61)
    T.eq(#W.ui.shown, 2)
  end)
  T.it('safety net: a popup that vanished without a close is noted and the interval restarts', function()
    local W = session()
    W:advance(61 * 60)
    W.ui.open.GOLDINTEL_RELOAD = nil                               -- gone, no handler ran
    W:advance(61)
    T.truthy(keep(W):find('EVT reminder closed reason=lost', 1, true))
    T.eq(#W.ui.shown, 1)
  end)
end)

T.describe('0.6.2 Settings window (D-118)', function()
  T.it('shows the real setting, also one set by command that is not a slider mark; opening saves nothing', function()
    local W, P, ns, run = session()
    run('config set reminder.reloadMinutes 1')
    run('settings')
    local label, _, status = P.UI.SettingsTexts()
    T.truthy(label:find('1 minute: Safe (set by command; not a slider mark)', 1, true), label)
    T.truthy(status:find('saved as soon as you move the slider', 1, true), status)
    T.eq(ns.Config.Get('reminder.reloadMinutes'), 1)
    run('config set reminder.reloadMinutes 75')                    -- changed while the window is open
    label = P.UI.SettingsTexts()
    T.truthy(label:find('75 minutes: Risky', 1, true), label)
    T.eq(ns.Config.Get('reminder.reloadMinutes'), 75)
  end)
  T.it('a move shows "Saved: <value>"; Close hides the window and keeps the setting', function()
    local W, P, ns, run = session()
    run('settings')
    W.ui.named.GoldIntelReminderSlider:SetValue(6)
    local label, _, status = P.UI.SettingsTexts()
    T.truthy(status:find('Saved: 120 minutes', 1, true), status)
    T.truthy(label:find('120 minutes: Risky', 1, true), label)
    W.ui.named.GoldIntelSettingsClose.scripts.OnClick()
    T.falsy(W.ui.named.GoldIntelSettingsFrame.shown)
    T.eq(ns.Config.Get('reminder.reloadMinutes'), 120)
  end)
end)

T.describe('0.6.2 chat prefix (D-118)', function()
  T.it('chat lines carry "GoldIntel:" once', function()
    local W, _, _, run = session()
    local lines = {}
    W.env.print = function(s) lines[#lines + 1] = s end
    run('agg check'); run('version'); run('collect status')
    local all = table.concat(lines, '\n')
    T.falsy(all:find('GoldIntel: GoldIntel:', 1, true), all)
    T.truthy(all:find('GoldIntel: agg check', 1, true), all)
    for _, l in ipairs(lines) do T.truthy(l:find('^GoldIntel'), l) end
  end)
end)

T.describe('0.6.2 reminder mutation checks', function()
  local LIVE = Loader.readFile(Loader.root .. '/Aggregate/Live.lua')
  local function mutant(a, b)
    local i, j = LIVE:find(a, 1, true); assert(i, 'anchor missing: ' .. a)
    return { ['Aggregate/Live.lua'] = LIVE:sub(1, i - 1) .. b .. LIVE:sub(j + 1) }
  end
  T.it('the real source passes', function() fullIntervalScenario(); noReshowScenario(); logScenario() end)
  T.it('mutation is caught: the interval does not restart at the close', function()
    T.falsy((pcall(fullIntervalScenario, mutant('  if restart then lastRemind = gt end', ''))), 'the mutant passed')
  end)
  T.it('mutation is caught: shown again while open', function()
    T.falsy((pcall(noReshowScenario, mutant('  if promptOpen then\n', '  if false then\n'))), 'the mutant passed')
  end)
  T.it('mutation is caught: a client close logged as Ignore', function()
    T.falsy((pcall(logScenario, mutant("        if reason == 'clicked' then", '        if true then'))), 'the mutant passed')
  end)
end)

T.describe('0.6.1 popup mutation checks', function()
  local UIF = Loader.readFile(Loader.root .. '/Platform/UI.lua')
  local function mutant(a, b)
    local i, j = UIF:find(a, 1, true); assert(i, 'anchor missing: ' .. a)
    return { ['Platform/UI.lua'] = UIF:sub(1, i - 1) .. b .. UIF:sub(j + 1) }
  end
  local function encounterScenario(override)
    local W = session({ override = override })
    W:advance(58 * 60)
    W:fire('ENCOUNTER_START', 1, 'Boss', 1, 5)
    W:advance(5 * 60)
    assert(#W.ui.shown == 0, 'popup during an encounter')
  end
  T.it('the real source passes', function() encounterScenario() end)
  T.it('mutation is caught: encounters not checked', function()
    T.falsy((pcall(encounterScenario, mutant('  return UI.InEncounter()', '  return false'))), 'the mutant passed')
  end)
end)
