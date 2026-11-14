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
    env.StaticPopupDialogs = {}
    env.StaticPopup_Show = function(which, text) W.ui.shown[#W.ui.shown + 1] = { which = which, text = text }; return {} end
    env.StaticPopup_Hide = function(which) W.ui.hidden[#W.ui.hidden + 1] = which end
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
    popup(W).OnAccept()
    T.eq(W.ui.reloads, 1)
    T.truthy(keep(W):find('EVT reminder click=reload', 1, true))
    local W2 = session({ reloadFails = true })
    W2:advance(61 * 60)
    W2.printed = {}
    popup(W2).OnAccept()
    T.truthy(W2:printedText():find('type /reload to save', 1, true), W2:printedText())
    T.truthy(keep(W2):find('EVT reminder reloadFailed', 1, true))
  end)

  T.it('Ignore waits for the next interval', function()
    local W = session()
    W:advance(61 * 60)
    popup(W).OnCancel()
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
    popup(W).OnAlt()
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
