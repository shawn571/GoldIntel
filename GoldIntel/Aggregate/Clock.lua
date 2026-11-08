-- GoldIntel / Aggregate / Clock.lua                        (Phase 4 P4-M1, pure, NOT loaded by the TOC; D-099)
--
-- PURPOSE
--  Classifies every tick slice of logged-in time as ACTIVE (with its current activity), IDLE, TRAVEL (hard or soft) or
--  PAUSED, so the aggregates hold honest active time per place and activity (FR-SES-3, AM-3, AM-7, AM-14, Q-3).
--  Pure: no Platform calls; time, positions, distance and flags are arguments.
--
--      local C = GI.Clock.New{ idleSec, drySec, nearYards, minSpeed, actWindow, distance = fn(locA, locB) -> yards | nil }
--      C:Life(gt)                      a signal of life: money, loot, cast, combat change, window open, zone change, level
--      C:Productive(gt, act, loc)      a value event or gathering cast (also a signal of life); sets the current activity
--      C:Manual('pause' | 'afk' | nil) /gi pause, /gi afk; nil = /gi resume (D-055)
--      C:Override(act | nil)           /gi activity <key>: wins over detection until cleared
--      C:Tick(gt, dt, loc, flags)      flags = { taxi, inWorld, level }; returns the slices that became certain ACTIVE now
--      C:Flush(gt)                     interval end: decides every pending slice with what is known; returns ACTIVE slices
--      C:Stats()                       seconds per class and counters
--
-- RULES (D-054 priority: manual pause > taxi > idle > soft travel > productive; a slice has exactly one class)
--  * paused  : a manual pause or afk is on. Decided at once.
--  * travel (hard): on a taxi or not in the world (loading screen, teleport). Decided at once.
--  * idle    : the slice lies in a gap of at least idleSec (120 s) between two signals of life (or between the last
--              signal and now). Movement over a small epsilon is a signal of life. Waiting for a respawn is idle after
--              the timeout; fishing casts are life (D-055). Decided when the next signal arrives or the gap reaches idleSec.
--  * travel (soft): moving at least minSpeed, at least nearYards from the last productive spot, inside a gap of at least
--              drySec (60 s) between productive events (D-054 values; minSpeed is NOT in D-054 and must be verified live).
--              When distance is unknown (no map size), soft travel cannot be decided: the slice is not travel, counted.
--  * active  : everything else; activity = override, else the activity of the last productive event within actWindow
--              (120 s), else OTHER.
--  Slices wait in order until their class is certain (at most idleSec), so the aggregates lag live play by up to 2 min.
--  0.6.0: consecutive slices with no signal between them, on the same place, 32 x 32 cell, activity, level and travel
--  candidacy, are kept as ONE run (dt summed). They share the same signals before and after, so they always get the
--  same class: the result is exact, and the waiting buffer holds a few runs instead of up to 240 slices.
--  At Flush, an undecided slice is ACTIVE unless idle or travel is already proven (logging out right after a kill).

local ADDON, GI = ...
GI = GI or {}

local CK = {}
GI.Clock = CK

CK.IDLE = 120
CK.DRY = 60
CK.NEAR = 150          -- yards (D-054 "about 150 yards")
CK.MIN_SPEED = 8       -- yards per second [assumed]: faster than running (7), slower than any mount; verify live in P4-M2
CK.ACT_WINDOW = 120
CK.MOVE_EPS = 0.0005   -- map-coordinate change that counts as movement when no distance is known
CK.KEEP = 400          -- signal times kept (bounded memory)
-- 0.6.0 (P4-M2): seconds of movement per speed bucket (yards per second), evidence to tune MIN_SPEED from real play
CK.SPEED_BUCKETS = { 4, 7, 9, 12, 16 }   -- upper bounds; the last bucket is '16+'

local Obj = {}
Obj.__index = Obj

function CK.New(opts)
  opts = opts or {}
  return setmetatable({
    idleSec = opts.idleSec or CK.IDLE, drySec = opts.drySec or CK.DRY, nearYards = opts.nearYards or CK.NEAR,
    minSpeed = opts.minSpeed or CK.MIN_SPEED, actWindow = opts.actWindow or CK.ACT_WINDOW, distance = opts.distance,
    lives = {}, prods = {}, lastProd = nil, lastLoc = nil, manual = nil, override = nil, pending = {},
    stats = { active = 0, idle = 0, travelHard = 0, travelSoft = 0, paused = 0, travelUnknown = 0, slices = 0 },
    speed = {},
  }, Obj)
end

local function push(list, v)
  list[#list + 1] = v
  if #list > CK.KEEP then table.remove(list, 1) end
end

-- last value <= t and first value > t in an ascending list
local function around(list, t)
  local prev, nextv
  for i = 1, #list do
    local v = list[i]
    if v <= t + 1e-9 then prev = v else nextv = v; break end
  end
  return prev, nextv
end

function Obj:Life(gt) push(self.lives, gt); self.breakRun = true end

function Obj:Productive(gt, act, loc)
  push(self.lives, gt)
  self.breakRun = true
  push(self.prods, gt)
  self.lastProd = { gt = gt, act = act, loc = loc }
end

function Obj:Manual(mode) self.manual = mode end
function Obj:Override(act) self.override = act end

function Obj:Current(gt)
  if self.override then return self.override end
  local p = self.lastProd
  if p and gt - p.gt <= self.actWindow + 1e-9 and p.act then return p.act end
  return 'OTHER'
end

local function dist(self, a, b)
  if not (a and b) then return nil end
  if self.distance then
    local ok, d = pcall(self.distance, a, b)
    if ok and type(d) == 'number' then return d end
  end
  return nil
end

local function moved(self, a, b)
  if not (a and b) then return false end
  if a.mapID ~= b.mapID then return true end
  local d = dist(self, a, b)
  if d then return d > 0.5 end
  if type(a.x) ~= 'number' or type(b.x) ~= 'number' then return false end
  return math.abs(a.x - b.x) > CK.MOVE_EPS or math.abs(a.y - b.y) > CK.MOVE_EPS
end

-- class of the gap around time t in `list`: true (gap >= len), false (gap < len) or nil (not yet known)
local function inGap(list, t, len, now)
  local prev, nextv = around(list, t)
  prev = prev or -math.huge
  if nextv then return nextv - prev >= len - 1e-9 end
  if now - prev >= len - 1e-9 then return true end
  return nil
end

function Obj:_classify(s, now, final)
  local idle = inGap(self.lives, s.gt, self.idleSec, now)
  if idle == nil and final then idle = false end
  if idle == nil then return nil end
  if idle then return 'idle' end
  if s.candidate then
    local tr = inGap(self.prods, s.gt, self.drySec, now)
    if tr == nil and final then tr = false end
    if tr == nil then return nil end
    if tr then return 'travelSoft' end
  end
  return 'active'
end

function Obj:_settle(now, final)
  local out = {}
  while #self.pending > 0 do
    local s = self.pending[1]
    local class = self:_classify(s, now, final)
    if not class then break end
    table.remove(self.pending, 1)
    self.stats[class] = self.stats[class] + s.dt
    if class == 'active' then
      out[#out + 1] = { gt = s.gt, dt = s.dt, loc = s.loc, act = s.act, level = s.level }
    end
  end
  return out
end

function Obj:Tick(gt, dt, loc, flags)
  flags = flags or {}
  if type(dt) ~= 'number' or dt <= 0 then return self:_settle(gt) end
  self.stats.slices = self.stats.slices + 1
  local prevLoc = self.lastLoc
  if loc then
    if moved(self, prevLoc, loc) then self:Life(gt) end
    self.lastLoc = loc
  end
  if self.manual then
    self.stats.paused = self.stats.paused + dt
    return self:_settle(gt)
  end
  if flags.taxi or flags.inWorld == false then
    self.stats.travelHard = self.stats.travelHard + dt
    return self:_settle(gt)
  end
  local candidate = false
  if loc and self.lastProd and self.lastProd.loc then
    local far = dist(self, loc, self.lastProd.loc)
    local step = prevLoc and dist(self, prevLoc, loc)
    if far and step then
      candidate = far >= self.nearYards and (step / dt) >= self.minSpeed
      if step > 0.5 then self:_speed(step / dt, dt) end
    elseif moved(self, prevLoc, loc) then
      self.stats.travelUnknown = self.stats.travelUnknown + dt
    end
  end
  local act = self:Current(gt)
  local cell = loc and (tostring(loc.mapID) .. '|' .. tostring(loc.zone) .. '|' .. tostring(loc.sub) .. '|' ..
    (type(loc.x) == 'number' and math.floor(loc.x * 32) or '-') .. ':' .. (type(loc.y) == 'number' and math.floor(loc.y * 32) or '-')) or '-'
  local last = self.pending[#self.pending]
  if last and not self.breakRun and last.cell == cell and last.act == act and last.level == flags.level and last.candidate == candidate then
    last.dt = last.dt + dt
    last.last = gt
  else
    self.pending[#self.pending + 1] = { gt = gt, last = gt, dt = dt, loc = loc, act = act, level = flags.level, candidate = candidate, cell = cell }
    self.breakRun = false
  end
  return self:_settle(gt)
end

function Obj:_speed(v, dt)
  local label
  for i, top in ipairs(CK.SPEED_BUCKETS) do
    if v < top then label = (i == 1 and '0' or tostring(CK.SPEED_BUCKETS[i - 1])) .. '-' .. top; break end
  end
  label = label or (CK.SPEED_BUCKETS[#CK.SPEED_BUCKETS] .. '+')
  self.speed[label] = (self.speed[label] or 0) + dt
end

--- Seconds of movement per speed bucket (only while moving with a known distance).
function Obj:Speeds() local s = {} for k, v in pairs(self.speed) do s[k] = v end return s end

function Obj:Flush(gt) return self:_settle(gt, true) end

function Obj:Pending() return #self.pending end

function Obj:Stats()
  local s = {}
  for k, v in pairs(self.stats) do s[k] = v end
  s.pending = #self.pending
  return s
end
