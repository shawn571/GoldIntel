--[[
GoldIntel / Tests / helpers / fake_wow.lua

A deterministic stand-in for the WoW client API, injected as `Platform.env`.
It implements only what Phase 1 touches. Anything not defined here is nil, exactly
like a missing client API, which is how degradation paths are tested.

    local W = Fake.new{ without = { 'C_Map' } }      -- omit APIs
    W.state.money = 500                              -- mutate the "game"
    W:fire('PLAYER_MONEY')                           -- deliver a WoW event
    W:advance(1.0)                                   -- move time, run timers and OnUpdate

TIME MODEL
  advance(dt) moves `time` and `GetTime` together in sub-steps of at most 0.25 s (like
  rendered frames), running due C_Timer tasks and OnUpdate scripts in each sub-step.
  stall(dt) moves time in ONE step (loading screen / lag spike).
]]

local Fake = {}

local SUBSTEP = 0.25

function Fake.new(opts)
  opts = opts or {}
  local W = { env = {}, frames = {}, printed = {}, timers = {}, registerCalls = {}, forbidden = {} }
  local s = {
    time = 1700000000, gt = 1000.0, money = 0,
    guid = 'Player-4372-0A1B2C3D', name = 'Tester', classToken = 'MAGE', classLocal = 'Mage',
    level = 12, faction = 'Alliance',
    mapID = 1411, pos = { 0.5, 0.5 }, zone = 'Durotar', sub = 'Valley of Trials', locale = 'enUS',
    loggedIn = false,
    invalidEvents = {},
    forbiddenEvents = {},     -- events whose insecure registration the client BLOCKS (ADDON_ACTION_FORBIDDEN)
    skills = {
      { name = 'Weapon Skills', header = true, expanded = true },
      { name = 'Staves', rank = 5 },
      { name = 'Professions', header = true, expanded = true },
      { name = 'Mining', rank = 75 },
      { name = 'Herbalism', rank = 40 },
      { name = 'Secondary Skills', header = true, expanded = true },
      { name = 'Fishing', rank = 10 },
    },
  }
  W.state = s
  local env = W.env

  -- Basic ---------------------------------------------------------------
  env.print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    W.printed[#W.printed + 1] = table.concat(parts, ' ')
  end
  env.time = function() return s.time end
  env.GetTime = function() return s.gt end
  env.GetMoney = function() return s.money end
  env.IsLoggedIn = function() return s.loggedIn end
  env.GetLocale = function() return s.locale end
  env.GetBuildInfo = function() return '1.15.9', '61000', 'Oct 01 2026', 11509 end
  env.WOW_PROJECT_ID = 2
  env.SlashCmdList = {}

  -- Frames --------------------------------------------------------------
  env.CreateFrame = function(_kind)
    local f = { events = {}, scripts = {}, shown = true }
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:RegisterEvent(e)
      W.registerCalls[#W.registerCalls + 1] = e
      if s.forbiddenEvents[e] then
        -- The real client blocks the call and shows a popup; pcall cannot hide that, and the
        -- Lua code just continues. Tests assert this list stays empty.
        W.forbidden[#W.forbidden + 1] = e
        return
      end
      if s.invalidEvents[e] then
        error('Frame:RegisterEvent(): Attempt to register unknown event "' .. e .. '"')
      end
      self.events[e] = true
    end
    function f:UnregisterEvent(e) self.events[e] = nil end
    if not opts.noIsEventRegistered then
      function f:IsEventRegistered(e) return self.events[e] == true end
    end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    W.frames[#W.frames + 1] = f
    return f
  end

  -- C_EventUtils (names only; never registers) -----------------------------------
  env.C_EventUtils = {
    IsEventValid = function(e) return not s.invalidEvents[e] end,
  }

  -- C_Timer -------------------------------------------------------------
  local function addTimer(seconds, fn, interval)
    local timer = { due = s.gt + seconds, interval = interval, fn = fn, cancelled = false }
    function timer:Cancel() self.cancelled = true end
    W.timers[#W.timers + 1] = timer
    return timer
  end
  env.C_Timer = {
    NewTicker = function(seconds, fn) return addTimer(seconds, fn, seconds) end,
    NewTimer = function(seconds, fn) return addTimer(seconds, fn, nil) end,
    After = function(seconds, fn) addTimer(seconds, fn, nil) end,
  }

  -- Unit ----------------------------------------------------------------
  env.UnitGUID = function() return s.guid end
  env.UnitName = function() return s.name end
  env.UnitClass = function() return s.classLocal, s.classToken end
  env.UnitLevel = function() return s.level end
  env.UnitFactionGroup = function() return s.faction, s.faction end

  -- Map -----------------------------------------------------------------
  env.C_Map = {
    GetBestMapForUnit = function() return s.mapID end,
    GetPlayerMapPosition = function()
      if not s.pos then return nil end
      local x, y = s.pos[1], s.pos[2]
      return { GetXY = function() return x, y end }
    end,
    GetMapInfo = function(id) return { mapID = id, name = s.zone } end,
  }
  env.GetZoneText = function() return s.zone end
  env.GetSubZoneText = function() return s.sub end

  -- Skill lines (classic-style): collapsed headers hide their children --------
  local function visibleRows()
    local rows, hidden = {}, false
    for i, row in ipairs(s.skills) do
      if row.header then
        hidden = not row.expanded
        rows[#rows + 1] = { row = row, real = i }
      elseif not hidden then
        rows[#rows + 1] = { row = row, real = i }
      end
    end
    return rows
  end
  env.GetNumSkillLines = function() return #visibleRows() end
  env.GetSkillLineInfo = function(i)
    local entry = visibleRows()[i]
    if not entry then return nil end
    local r = entry.row
    return r.name, r.header and 1 or nil, r.expanded and 1 or nil, r.rank or 0, 0, 0, r.max or 0
  end
  env.ExpandSkillHeader = function(i)
    local entry = visibleRows()[i]
    if entry and entry.row.header then entry.row.expanded = true end
  end
  env.CollapseSkillHeader = function(i)
    local entry = visibleRows()[i]
    if entry and entry.row.header then entry.row.expanded = false end
  end

  -- Optional libraries ----------------------------------------------------------
  local libs = opts.libs or {}
  env.LibStub = setmetatable({}, { __call = function(_, name, _silent)
    if libs[name] then return { name = name } end
    return nil
  end })

  -- Retail-style professions (opt-in) -------------------------------------------
  if opts.retailProfessions then
    env.GetProfessions = function()
      local out = {}
      for i = 1, 5 do out[i] = opts.retailProfessions[i] and i or nil end
      return out[1], out[2], out[3], out[4], out[5]
    end
    env.GetProfessionInfo = function(i)
      local p = opts.retailProfessions[i]
      if not p then return nil end
      return p[1], 'icon', p[2], 300
    end
  end

  -- Remove APIs on request (simulates a client that lacks them) -----------------
  for _, name in ipairs(opts.without or {}) do env[name] = nil end

  -- Driving the fake world ------------------------------------------------------

  --- Delivers a WoW event to every frame registered for it.
  function W:fire(event, ...)
    for _, f in ipairs(self.frames) do
      if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
    end
  end

  local function step(dt)
    s.time = s.time + dt
    s.gt = s.gt + dt
    -- C_Timer tasks (snapshot so tasks created during a callback wait for the next step)
    local snapshot = {}
    for i, t in ipairs(W.timers) do snapshot[i] = t end
    for _, t in ipairs(snapshot) do
      if not t.cancelled and t.due <= s.gt then
        if t.interval then t.due = t.due + t.interval else t.cancelled = true end
        t.fn()
      end
    end
    for i = #W.timers, 1, -1 do
      if W.timers[i].cancelled then table.remove(W.timers, i) end
    end
    -- OnUpdate scripts of visible frames
    local frames = {}
    for i, f in ipairs(W.frames) do frames[i] = f end
    for _, f in ipairs(frames) do
      if f.shown and f.scripts.OnUpdate then f.scripts.OnUpdate(f, dt) end
    end
  end

  --- Advances time in frame-sized sub-steps.
  function W:advance(dt)
    local remaining = dt
    while remaining > 1e-9 do
      local d = math.min(SUBSTEP, remaining)
      step(d)
      remaining = remaining - d
    end
  end

  --- Advances time in a single step (loading screen / lag spike).
  function W:stall(dt) step(dt) end

  --- Simulates the login sequence the client performs.
  function W:login()
    s.loggedIn = true
    self:fire('PLAYER_LOGIN')
    self:fire('PLAYER_ENTERING_WORLD')
  end

  function W:printedText() return table.concat(self.printed, '\n') end

  function W:activeTimers()
    local n = 0
    for _, t in ipairs(self.timers) do
      if not t.cancelled then n = n + 1 end
    end
    return n
  end

  return W
end

return Fake
