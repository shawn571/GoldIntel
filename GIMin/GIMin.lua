-- GIMin: the smallest addon that answers the five Phase 1 loading questions.
--   1. does the addon load?                      -> "main" flag below
--   2. is the (name, namespace) pair passed in?  -> ns table + shared with Sub files
--   3. do SavedVariables work, and when?         -> GIMinDB load counter
--   4. do slash commands register?               -> /gimin
--   5. does event registration work?             -> events listed below
local name, ns = ...

local function say(...) print("|cff33ccffGIMin|r", ...) end

local state = {
  nameType = type(name), nsType = type(ns), name = name,
  svAtFileLoad = type(GIMinDB),          -- expected "nil": saved variables are restored AFTER files run
  svAtAddonLoaded = "n/a", loads = "n/a",
  events = {}, fired = {},
}
if type(ns) == "table" then ns.main = true end

local EVENTS = { "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_MONEY",
                 "PLAYER_LOGOUT", "NOT_A_REAL_EVENT_GIMIN" }

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(_, event, arg1)
  state.fired[event] = (state.fired[event] or 0) + 1
  if event == "ADDON_LOADED" and arg1 == name then
    state.svAtAddonLoaded = type(GIMinDB)
    GIMinDB = GIMinDB or { loads = 0 }
    GIMinDB.loads = GIMinDB.loads + 1
    GIMinDB.lastLoad = time()
    state.loads = GIMinDB.loads
  elseif event == "PLAYER_LOGIN" then
    SlashCmdList.GIMIN("login")
  elseif event == "PLAYER_MONEY" then
    say("PLAYER_MONEY fired; GetMoney() =", GetMoney())
  end
end)

for _, event in ipairs(EVENTS) do
  local ok, err = pcall(frame.RegisterEvent, frame, event)
  state.events[event] = ok and "registered" or ("REJECTED: " .. tostring(err))
end

SLASH_GIMIN1 = "/gimin"
SlashCmdList.GIMIN = function(msg)
  say("slash command works. argument:", msg == "" and "(none)" or msg)
  say("1 load      : main file ran, ns passed =", state.nsType, "addon name =", tostring(state.name))
  say("2 namespace : shared with sub files -> back =", tostring(ns and ns.back), " fwd =", tostring(ns and ns.fwd),
      " block =", tostring(ns and ns.block))
  say("3 saved vars: at file load =", state.svAtFileLoad, ", at ADDON_LOADED =", state.svAtAddonLoaded,
      ", total loads (persists across /reload) =", tostring(state.loads))
  for _, event in ipairs(EVENTS) do
    say("5 event     :", event, state.events[event], "fired x" .. (state.fired[event] or 0))
  end
  say("Interface from client:", tostring(select(4, GetBuildInfo())))
end
