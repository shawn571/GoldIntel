-- GoldIntel / Core / Reminder.lua                           (0.6.1-passive; D-099 Q-6, D-115)
--
-- PURPOSE
--  The /reload reminder's interval steps and bands, and the text that explains them. Pure: no WoW API; the popup and
--  the settings window live in Platform/UI.lua, the timing in Aggregate/Live.lua.
--
-- WHY THE BANDS (evidence, Paladin Player-6796-<main>, 17 recorded sessions of 30 minutes or more, 42.2 hours,
-- 2026-11-08..14): per hour of play about 34 cash entries on average, 68 at the 90th percentile, 81 at most; about
-- 1.1 g moved. WoW writes saved data only at /reload, logout or disconnect; a client crash loses everything since the
-- last save: the gold is still booked at the next login (one OTHER entry, a login gap), but its sources, the time per
-- place and the heat map of those minutes are lost.
--   Safe             15..60 min   at most one hour at risk (up to about 80 entries in the busiest hour recorded)
--   Risky            90..180 min  up to three hours (up to about 240 entries)
--   Not Recommended  240, 360     four hours or more (an 8-hour session risks about 270 entries at the average rate)
--   Off              0            the whole session
-- Each /reload costs a loading screen and one GoldIntel frame of 100..180 ms (0.5.6 baseline).

local ADDON, GI = ...
GI = GI or {}

local R = {}
GI.Reminder = R

R.STEPS = { 15, 30, 45, 60, 90, 120, 180, 240, 360, 0 }      -- 0 = Off (the slider's last position)
R.ENTRIES_PER_HOUR = 34                                       -- average (evidence above)
R.ENTRIES_PER_HOUR_MAX = 81                                   -- busiest recorded hour
R.COLORS = { Safe = '33ff33', Risky = 'ffcc00', ['Not Recommended'] = 'ff4444', Off = 'aaaaaa' }

function R.Band(minutes)
  if type(minutes) ~= 'number' or minutes <= 0 then return 'Off' end
  if minutes <= 60 then return 'Safe' end
  if minutes <= 180 then return 'Risky' end
  return 'Not Recommended'
end

--- Index of the slider step closest to `minutes` (0 = Off is the last step).
function R.StepIndex(minutes)
  if type(minutes) ~= 'number' or minutes <= 0 then return #R.STEPS end
  local best, bestD = 1, math.huge
  for i, m in ipairs(R.STEPS) do
    if m > 0 and math.abs(m - minutes) < bestD then best, bestD = i, math.abs(m - minutes) end
  end
  return best
end

function R.Label(minutes)
  local band = R.Band(minutes)
  if band == 'Off' then return 'Off: no reminder' end
  return string.format('%d minute%s: %s', minutes, minutes == 1 and '' or 's', band)
end

function R.OnMark(minutes)
  for _, m in ipairs(R.STEPS) do if m == minutes then return true end end
  return false
end

--- D-118: what the window shows for the REAL setting (also a value set by command that is not a slider mark).
function R.Describe(minutes)
  local label = R.Label(minutes)
  if not R.OnMark(minutes) and R.Band(minutes) ~= 'Off' then label = label .. ' (set by command; not a slider mark)' end
  return { label = label, explain = R.Explain(minutes), band = R.Band(minutes) }
end

--- One or two sentences on what is at risk at this interval.
function R.Explain(minutes)
  local band = R.Band(minutes)
  if band == 'Off' then
    return 'No reminder. A client crash loses everything since your last /reload or logout: sources, time per place and the heat map.'
  end
  local h = minutes / 60
  return string.format('A crash loses at most %d minutes: about %d cash entries (up to %d in a busy session), their sources and the time per place. The gold itself is still booked at the next login.',
    minutes, math.floor(R.ENTRIES_PER_HOUR * h + 0.5), math.floor(R.ENTRIES_PER_HOUR_MAX * h + 0.5))
end

local function cfgMinutes()
  local v = GI.Config and GI.Config.Get and GI.Config.Get('reminder.reloadMinutes')
  if type(v) ~= 'number' then return 60 end
  return v
end

--- Opens the Settings window (Platform/UI) on the reminder slider. Each move is saved at once in the profile.
function R.OpenSettings()
  local P = GI.Platform
  if not (P and P.UI and P.UI.OpenSettings) then return false, 'no UI module' end
  local real = cfgMinutes()
  local ok, why = P.UI.OpenSettings{
    steps = #R.STEPS,
    index = R.StepIndex(real),
    real = R.Describe(real),                       -- D-118: the window opens on the real value
    hint = 'Changes are saved as soon as you move the slider.',
    label = function(i) return R.Label(R.STEPS[i]) end,
    explain = function(i) return R.Explain(R.STEPS[i]) end,
    band = function(i) return R.Band(R.STEPS[i]) end,
    color = function(band) return R.COLORS[band] end,
    onChange = function(i)
      local m = R.STEPS[i]
      if not (GI.Config and GI.Config.Set) then error('no settings store') end
      local okSet, err = GI.Config.Set('reminder.reloadMinutes', m)
      if not okSet then error(tostring(err)) end
      return m == 0 and 'reminder off' or string.format('%d minute%s', m, m == 1 and '' or 's')
    end,
  }
  if not ok and P.Print then
    P.Print('GoldIntel: the settings window could not open (' .. tostring(why) .. '); use /gi config set reminder.reloadMinutes <minutes>')
  end
  return ok, why
end

-- D-118: a change by command while the window is open shows at once (no save from the window itself)
if GI.Bus and GI.Bus.On then
  GI.Bus.On('CONFIG_CHANGED', function(p)
    local P = GI.Platform
    if p and p.key == 'reminder.reloadMinutes' and P and P.UI and P.UI.RefreshSettings then
      local m = cfgMinutes()
      pcall(P.UI.RefreshSettings, R.StepIndex(m), R.Describe(m))
    end
  end)
end

if GI.Commands and GI.Commands.Register then
  GI.Commands.Register('settings', { help = 'open the GoldIntel settings window (reload reminder)', fn = function() R.OpenSettings() end })
end

--- Text of the popup.
function R.PopupText(minutes)
  return string.format('GoldIntel: %d minutes since your data was last saved.\nA crash now would lose about %d cash entries and the time per place of that period.\n\nReload now to save?',
    minutes, math.floor(R.ENTRIES_PER_HOUR * minutes / 60 + 0.5))
end
