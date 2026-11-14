-- GoldIntel / Platform / UI.lua                             (0.6.1-passive; D-115)
--
-- PURPOSE
--  GoldIntel's first frames: the /reload reminder popup and a small Settings window holding the reminder slider (the
--  seed of the main window's Settings tab, user option A, D-115). Only Platform touches WoW API (principle 3); the
--  texts, steps and bands come from Core/Reminder.lua through the spec arguments.
--
--      UI.Blocked() -> true while in combat or during a boss encounter (the popup is never shown then)
--      UI.ShowReloadPrompt{ text, onReload, onCancel(reason), onConfigure, onHide } -> true | false, why   (0.6.2: reasons)
--      UI.PromptVisible() -> true | false | nil;  UI.RefreshSettings(index, real);  UI.SettingsTexts() (tests)
--      UI.HideReloadPrompt()
--      UI.Reload() -> true | false, why          C_UI.Reload, else ReloadUI  [UNVERIFIED on Forever: live check]
--      UI.OpenSettings{ steps, index, label = fn(i), explain = fn(i), band = fn(i), onChange = fn(i) } -> true | false, why
--
-- CLIENT FACTS (unverified on Forever; probe capabilities ui.popup, ui.reload, ui.frames and the live check decide):
--  StaticPopupDialogs / StaticPopup_Show with three buttons (OnAccept, OnCancel, OnAlt); C_UI.Reload or ReloadUI from a
--  button click; CreateFrame 'Frame' and 'Slider' with BackdropTemplate; UIPanelCloseButton; UISpecialFrames (Escape).
--  Every call is protected: a missing piece makes the function return false with the reason, and GoldIntel falls back
--  to a chat line.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/UI.lua')

local UI = {}
P.UI = UI
P.Register('UI', UI)

UI.POPUP = 'GOLDINTEL_RELOAD'
UI.stats = { popups = 0, reloads = 0, reloadFailed = 0, settings = 0, errors = 0 }
UI.lastError = nil

-- Boss encounters (collector events, registered while recording; D-115). NOT yet observed in the Forever client.
local function onEncounter(active)
  return function()
    if P.Events then P.Events.inEncounter = active end
    P.Events.Emit('P_ENCOUNTER', { active = active })
  end
end
P.RegisterCollectAdapter({ name = 'Encounter', handlers = { ENCOUNTER_START = onEncounter(true), ENCOUNTER_END = onEncounter(false) } })

function UI.InEncounter()
  if P.Events and P.Events.inEncounter then return true end
  if P.fn('IsEncounterInProgress') then
    local r = P.Call('IsEncounterInProgress')
    if r and r[1] == true then return true end
  end
  return false
end

function UI.Blocked()
  if P.Events and P.Events.inCombat then return true end
  if P.fn('InCombatLockdown') then
    local r = P.Call('InCombatLockdown')
    if r and r[1] == true then return true end
  end
  return UI.InEncounter()
end

function UI.CanReload() return P.HasIn('C_UI', 'Reload') or P.fn('ReloadUI') ~= nil end
function UI.CanPopup() return type(P.env.StaticPopupDialogs) == 'table' and P.fn('StaticPopup_Show') ~= nil end

function UI.Reload()
  local r, err
  if P.HasIn('C_UI', 'Reload') then r, err = P.CallIn('C_UI', 'Reload')
  elseif P.fn('ReloadUI') then r, err = P.Call('ReloadUI')
  else err = 'no reload function in this client' end
  if r then UI.stats.reloads = UI.stats.reloads + 1; return true end
  UI.stats.reloadFailed = UI.stats.reloadFailed + 1
  UI.lastError = tostring(err)
  return false, tostring(err)
end

local function safe(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then UI.stats.errors = UI.stats.errors + 1; UI.lastError = tostring(err); P.Diag('error', 'UI', tostring(err)) end
  end
end

function UI.ShowReloadPrompt(spec)
  if not UI.CanPopup() then return false, 'no popup API (StaticPopup) in this client' end
  if UI.Blocked() then return false, 'in combat or an encounter' end
  P.env.StaticPopupDialogs[UI.POPUP] = {
    text = '%s', button1 = 'Reload Now', button2 = 'Ignore', button3 = 'Configure',
    OnAccept = safe(function() if spec.onReload then spec.onReload() end end),
    -- 0.6.2 (D-118): the client also cancels a popup itself (reason 'override' when it is shown again, 'timeout');
    -- only reason 'clicked' is the Ignore button (or Escape, which the client reports as 'clicked' [inferred]).
    OnCancel = safe(function(_, _, reason) if spec.onCancel then spec.onCancel(reason) end end),
    OnAlt = safe(function() if spec.onConfigure then spec.onConfigure() end end),
    OnHide = safe(function() if spec.onHide then spec.onHide() end end),
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  }
  local r, err = P.Call('StaticPopup_Show', UI.POPUP, spec.text or '')
  if not r then UI.stats.errors = UI.stats.errors + 1; UI.lastError = tostring(err); return false, tostring(err) end
  UI.stats.popups = UI.stats.popups + 1
  return true
end

function UI.HideReloadPrompt()
  if P.fn('StaticPopup_Hide') then P.Call('StaticPopup_Hide', UI.POPUP) end
end

--- true / false when the client can tell whether the popup is visible, nil when it cannot (D-118 safety net).
function UI.PromptVisible()
  if not P.fn('StaticPopup_Visible') then return nil end
  local r = P.Call('StaticPopup_Visible', UI.POPUP)
  if not r then return nil end
  return r[1] ~= nil and r[1] ~= false
end

---------------------------------------------------------------------------
-- Settings window
---------------------------------------------------------------------------

local frame, slider, valueText, explainText, statusText
local current                                    -- the spec of the last OpenSettings call
UI.SAVED_COLOR = '33ff33'

local BACKDROP = { bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background', edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
  tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } }
local SLIDER_BACKDROP = { bgFile = 'Interface\\Buttons\\UI-SliderBar-Background', edgeFile = 'Interface\\Buttons\\UI-SliderBar-Border',
  tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 6, bottom = 6 } }
local WIDTH, SLIDER_W = 440, 380

local function create(kind, name, parent, template)
  local cf = P.fn('CreateFrame')
  if not cf then error('CreateFrame missing') end
  if template then
    local ok, f = pcall(cf, kind, name, parent, template)
    if ok and f then return f end
  end
  return cf(kind, name, parent)
end

local function text(parent, font, point, x, y)
  local fs = parent:CreateFontString(nil, 'OVERLAY', font)
  fs:SetPoint(point, x, y)
  return fs
end

-- d = { label, explain, band } (D-118: the window always shows the REAL setting, also off the slider marks)
local function showText(d)
  local color = current and current.color and current.color(d.band) or 'ffffff'
  valueText:SetText('|cff' .. color .. tostring(d.label) .. '|r')
  explainText:SetText(d.explain)
end

local function show(i)
  if not current then return end
  showText({ label = current.label(i), explain = current.explain(i), band = current.band and current.band(i) or '' })
end

local function setStatus(text, color)
  if statusText then statusText:SetText(color and ('|cff' .. color .. text .. '|r') or text) end
end

local function build()
  local parent = P.env.UIParent
  local f = create('Frame', 'GoldIntelSettingsFrame', parent, 'BackdropTemplate')
  f:SetSize(WIDTH, 262)
  f:SetPoint('CENTER')
  if f.SetFrameStrata then f:SetFrameStrata('DIALOG') end
  if f.SetBackdrop then f:SetBackdrop(BACKDROP) end
  f:EnableMouse(true)
  if f.SetMovable then f:SetMovable(true); f:RegisterForDrag('LeftButton') end
  f:SetScript('OnDragStart', function(self) if self.StartMoving then self:StartMoving() end end)
  f:SetScript('OnDragStop', function(self) if self.StopMovingOrSizing then self:StopMovingOrSizing() end end)
  text(f, 'GameFontNormalLarge', 'TOP', 0, -18):SetText('GoldIntel Settings')
  text(f, 'GameFontNormal', 'TOPLEFT', 26, -50):SetText('/reload reminder')

  local s = create('Slider', 'GoldIntelReminderSlider', f, 'BackdropTemplate')
  s:SetOrientation('HORIZONTAL')
  s:SetSize(SLIDER_W, 17)
  s:SetPoint('TOPLEFT', 30, -76)
  if s.SetBackdrop then s:SetBackdrop(SLIDER_BACKDROP) end
  s:SetThumbTexture('Interface\\Buttons\\UI-SliderBar-Button-Horizontal')
  s:SetValueStep(1)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  s:EnableMouse(true)

  -- band captions under the slider at the middle of their steps (positions set by OpenSettings)
  f.captions = {}
  for _, name in ipairs({ 'Safe', 'Risky', 'Not Recommended', 'Off' }) do
    f.captions[name] = s:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    f.captions[name]:SetText(name)
  end

  valueText = text(f, 'GameFontHighlight', 'TOPLEFT', 26, -118)
  explainText = text(f, 'GameFontHighlightSmall', 'TOPLEFT', 26, -142)
  explainText:SetWidth(WIDTH - 52)
  explainText:SetJustifyH('LEFT')

  -- D-118: the save is visible: a hint before any change, "Saved: ..." after each move
  statusText = text(f, 'GameFontHighlightSmall', 'BOTTOMLEFT', 26, 24)
  statusText:SetWidth(WIDTH - 150)
  statusText:SetJustifyH('LEFT')

  s:SetScript('OnValueChanged', function(_, v)
    local i = math.floor((tonumber(v) or 1) + 0.5)
    if current and current.loading then return end   -- opening the window shows the real value and saves nothing
    show(i)
    if current and current.onChange then
      local ok, res = pcall(current.onChange, i)
      if not ok then
        UI.stats.errors = UI.stats.errors + 1; UI.lastError = tostring(res)
        setStatus('Not saved: ' .. tostring(res), 'ff4444')
      else
        setStatus('Saved: ' .. tostring(res or current.label(i)), UI.SAVED_COLOR)
      end
    end
  end)

  local close = create('Button', nil, f, 'UIPanelCloseButton')
  close:SetPoint('TOPRIGHT', -6, -6)
  close:SetScript('OnClick', function() f:Hide() end)
  -- D-118: a plain Close button, so closing does not look like cancelling (every move is already saved)
  local done = create('Button', 'GoldIntelSettingsClose', f, 'UIPanelButtonTemplate')
  done:SetSize(96, 22)
  done:SetPoint('BOTTOMRIGHT', -20, 18)
  if done.SetText then done:SetText('Close') end
  done:SetScript('OnClick', function() f:Hide() end)
  f.closeButton = done

  if type(P.env.UISpecialFrames) == 'table' then table.insert(P.env.UISpecialFrames, 'GoldIntelSettingsFrame') end   -- Escape closes it
  frame, slider = f, s
end

function UI.OpenSettings(spec)
  local ok, err = pcall(function()
    if not frame then build() end
    current = spec
    current.loading = true
    local n = spec.steps
    slider:SetMinMaxValues(1, n)
    for name, fs in pairs(frame.captions) do
      local lo, hi = nil, nil
      for i = 1, n do if spec.band(i) == name then lo = lo or i; hi = i end end
      if lo then
        fs:ClearAllPoints()
        fs:SetPoint('TOP', slider, 'BOTTOMLEFT', ((lo + hi) / 2 - 1) / (n - 1) * SLIDER_W, -2)
        fs:Show()
      else fs:Hide() end
    end
    slider:SetValue(spec.index)
    if spec.real then showText(spec.real) else show(spec.index) end   -- D-118: the real setting, also off the marks
    setStatus(spec.hint or 'Changes are saved as soon as you move the slider.')
    current.loading = false
    frame:Show()
  end)
  if not ok then
    UI.stats.errors = UI.stats.errors + 1
    UI.lastError = tostring(err)
    P.Diag('error', 'UI', 'settings window: ' .. tostring(err))
    return false, tostring(err)
  end
  UI.stats.settings = UI.stats.settings + 1
  return true
end

function UI.SettingsShown() return frame ~= nil and frame.shown ~= false and (not frame.IsShown or frame:IsShown()) end

--- D-118: the setting changed elsewhere (a command) while the window is open: show the new real value, move the thumb
-- without saving anything.
function UI.RefreshSettings(index, real)
  if not (frame and current and UI.SettingsShown()) then return false end
  current.loading = true
  pcall(function() slider:SetValue(index) end)
  current.loading = false
  if real then showText(real) else show(index) end
  return true
end

--- Tests only: the texts the window shows now.
function UI.SettingsTexts()
  return valueText and valueText.text, explainText and explainText.text, statusText and statusText.text
end
function UI.SettingsFrame() return frame, slider end

--- Tests only.
function UI._Reset() frame, slider, valueText, explainText, statusText, current = nil, nil, nil, nil, nil, nil end
