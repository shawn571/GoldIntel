-- GoldIntel / Aggregate / Live.lua                          (Phase 4 P4-M2, 0.6.0-passive; D-099, D-102)
--
-- PURPOSE
--  Runs the P4-M1 Clock and Aggregator in the live client (Phase4_P4-M2_Plan.md):
--   * every stored cash entry (Bus LEDGER_CASH, also login gaps) and every value-created lot (LotBook) reaches the
--     per-place, per-activity totals; listeners only enqueue, a 2 s task drains (Architecture 13);
--   * every 0.5 s tick (P_TICK) gives the Clock a slice; its ACTIVE slices add time to the cells and heat bins;
--   * the tables live in GoldIntelDB.agg[charKey] and GoldIntelDB.heat[charKey], so WoW saves them with every
--     /reload, logout and disconnect; a crash loses everything since the last save (as for the ledger);
--   * back-fill once per character (value and items of the saved raw records, no time, D-099 Q-4);
--   * the live check: the aggregates' net cash and value created against the ledger and the lot book, 0 copper;
--   * manual controls /gi pause, /gi resume, /gi afk, /gi activity (FR-SES-4, D-055) and /gi agg status|check|top;
--   * the /reload reminder (D-099 Q-6): one chat line, only outside combat, every reminder.reloadMinutes (60) minutes.
-- It decides no source and no value and writes neither cash nor lots (AC-15).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P and GI.Clock and GI.Aggregator, 'Platform, Clock and Aggregator must be loaded before Aggregate/Live.lua')

local Live = {}
GI.AggLive = Live

Live.DRAIN_EVERY = 2.0
Live.REPORT_EVERY = 600          -- EVT agg / EVT clock lines (as EVT check)
Live.REMIND_CHECK = 60
Live.REMINDER_TEXT = 'GoldIntel: %d minutes since your data was last saved; /reload saves it'
Live.ACTIVITIES = { GRIND = true, GATHER = true, FISH = true, LOOT = true, VENDOR = true, QUEST = true, AH = true, TRADE = true,
  MAIL = true, TRAINER = true, OTHER = true, DISENCHANT = true, ARBITRAGE = true, CRAFT = true, DUNGEON = true, RARE = true,
  BOOST = true, SERVICE_MAGE = true, SERVICE_LOCK = true, SERVICE_ENCHANT = true }
local GATHER_CAST = { herb = 'GATHER', mine = 'GATHER', skin = 'GATHER', fish = 'FISH' }

local A, C, state                 -- aggregator, clock (per interval), saved state of this character
local preQueue = {}               -- cash entries that arrived before the aggregator existed (login gap)
local active = false
local manual, override = nil, nil
local inCombat = false
local loadGT, lastRemind = nil, nil
local drainAcc, reportAcc, remindAcc = 0, 0, 0
local c = { cash = 0, lots = 0, lotValues = 0, slices = 0, reminders = 0, errors = 0, preQueued = 0 }

local function nowGT() local _, gt = P.Now(); return gt end
local function nowUnix() local ut = P.Now(); return ut end
local function level() local p = P.Player and P.Player(); return p and p.level end
local function trace(text) if GI.Trace and GI.Trace.IsRunning and GI.Trace.IsRunning() then GI.Trace.Line(text) end end

local function guard(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then c.errors = c.errors + 1; P.Diag('error', 'AggLive', tostring(err)) end
  end
end

local function createdValue(lots) return lots and lots.totals and lots.totals.created and lots.totals.created.value or 0 end

--- Creates the aggregator over the saved tables of the current character (once per load). False when not possible.
function Live.Ensure()
  if A then return true end
  if not (GI.Store and GI.Store.IsWritable and GI.Store.IsWritable()) then return false, 'store not writable' end
  local p = P.Player and P.Player()
  if not p or not p.key then return false, 'no character' end
  local aggSec, heatSec = GI.Store.Section('agg'), GI.Store.Section('heat')
  if not aggSec or not heatSec then return false, 'no section' end
  aggSec[p.key] = aggSec[p.key] or {}
  heatSec[p.key] = heatSec[p.key] or {}
  state = aggSec[p.key]
  local loc = P.Call('GetLocale')
  A = GI.Aggregator.New(state, heatSec[p.key], { locale = loc and loc[1] or nil })
  local ledgerSec, lotsSec = GI.Store.Section('ledger'), GI.Store.Section('lots')
  local ledger, lots = ledgerSec and ledgerSec[p.key], lotsSec and lotsSec[p.key]
  if not state.backfilled then
    -- the saved records already contain any entry that arrived before this moment: the pre-queue is dropped
    A:Backfill(ledger, lots)
    preQueue = {}
    local T = A:Totals()
    local cum = GI.Cash and GI.Cash.Cumulative and GI.Cash.Cumulative() or 0
    state.check = { cash = (T.cin - T.cout) - cum, vc = T.vc - createdValue(lots), since = nowUnix() }
    state.since = state.check.since
    state.build = P.VERSION
  end
  for _, e in ipairs(preQueue) do A:Enqueue('cash', e) end
  preQueue = {}
  return true
end

--- The live check (D-099, plan section 4): both differences must be 0.
function Live.Check()
  local ok, why = Live.Ensure()
  if not ok then return nil, why end
  A:Drain()
  local p = P.Player and P.Player()
  local lotsSec = GI.Store.Section('lots')
  local T = A:Totals()
  local cum = GI.Cash and GI.Cash.Cumulative and GI.Cash.Cumulative() or 0
  local chk = state.check or { cash = 0, vc = 0 }
  return { cash = (T.cin - T.cout) - cum - chk.cash, vc = T.vc - createdValue(lotsSec and p and lotsSec[p.key]) - chk.vc, seconds = T.s }
end

local function clockText()
  if not C then return 'EVT clock none' end
  local s = C:Stats()
  local sp, keys = C:Speeds(), {}
  for k in pairs(sp) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return (tonumber(a:match('^(%d+)')) or 0) < (tonumber(b:match('^(%d+)')) or 0) end)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = k .. ':' .. math.floor(sp[k]) end
  return string.format('EVT clock active=%d idle=%d travelHard=%d travelSoft=%d paused=%d travelUnknown=%d pending=%d speed=%s',
    math.floor(s.active), math.floor(s.idle), math.floor(s.travelHard), math.floor(s.travelSoft), math.floor(s.paused),
    math.floor(s.travelUnknown), s.pending, #parts > 0 and table.concat(parts, ',') or 'none')
end

local function report(why)
  local r = Live.Check()
  if r then
    trace(string.format('EVT agg %s cash=%d vc=%d seconds=%d%s', why, r.cash, r.vc, math.floor(r.seconds),
      (r.cash ~= 0 or r.vc ~= 0) and ' MISMATCH' or ''))
  end
  trace(clockText())
end

local function addSlices(slices)
  local ut = nowUnix()
  for _, s in ipairs(slices or {}) do
    s.t = ut
    A:Enqueue('time', s)
    c.slices = c.slices + 1
  end
end

--- Called by Ledger.Begin (an interval starts).
function Live.Begin()
  if active then return true end
  if not Live.Ensure() then return false end
  C = GI.Clock.New{ distance = P.Distance }
  C:Life(nowGT())
  C:Manual(manual)
  C:Override(override)
  active = true
  drainAcc, reportAcc = 0, 0
  local w = P.MapModule and P.MapModule.WorldSize
  local where = P.Where and P.Where()
  trace('EVIDENCE mapWorldSize=' .. tostring(w and where and where.mapID and (w(where.mapID)) ~= nil))
  return true
end

--- Called by Ledger.End (before the trace ends): flush the clock, drain, final lines.
function Live.End()
  if not active then return false end
  addSlices(C:Flush(nowGT()))
  if A then A:Drain() end
  report('final')
  active = false
  return true
end

---------------------------------------------------------------------------
-- Feeds (listeners only enqueue)
---------------------------------------------------------------------------

local function onCash(e)
  if type(e) ~= 'table' then return end
  local rec = { copper = e.copper, src = e.src, act = e.act, loc = e.loc, creditable = e.creditable and e.locConf == 'fresh',
                level = level(), t = nowUnix() }
  c.cash = c.cash + 1
  if A then A:Enqueue('cash', rec) else preQueue[#preQueue + 1] = rec; c.preQueued = c.preQueued + 1 end
  if C and active and e.src == 'loot' and (e.copper or 0) > 0 then C:Productive(nowGT(), e.act, e.loc) end
end

--- LotBook (via Lots emit): phase 'add' at creation, 'complete' when the value arrives later.
function Live.OnLot(lot, phase)
  if not A or type(lot) ~= 'table' or not lot.vc then return end
  local rec = { itemID = lot.itemID, qty = lot.qty, valueEach = lot.valueEach, vc = true, origin = lot.origin,
                locConf = lot.locConf, level = level(), t = lot.t }
  if phase == 'complete' then
    A:Enqueue('lotValue', rec); c.lotValues = c.lotValues + 1
  else
    A:Enqueue('lot', rec); c.lots = c.lots + 1
    if C and active and lot.origin then C:Productive(nowGT(), lot.origin.act, lot.origin) end
  end
end

local function life() if C and active then C:Life(nowGT()) end end

local function remind(gt)
  local minutes = GI.Config and GI.Config.Get and GI.Config.Get('reminder.reloadMinutes') or 60
  if type(minutes) ~= 'number' or minutes <= 0 or inCombat or not loadGT then return end
  if gt - loadGT < minutes * 60 then return end
  if lastRemind and gt - lastRemind < minutes * 60 then return end
  lastRemind = gt
  c.reminders = c.reminders + 1
  P.Print(string.format(Live.REMINDER_TEXT, minutes))
end

local function onTick(p)
  local gt = nowGT()
  loadGT = loadGT or gt
  local dt = (p and p.dt) or 0
  remindAcc = remindAcc + dt
  if remindAcc >= Live.REMIND_CHECK then remindAcc = 0; remind(gt) end
  if not (active and C and A) then return end
  addSlices(C:Tick(gt, dt, p and p.loc, { taxi = P.OnTaxi and P.OnTaxi() or false, inWorld = P.InWorld and P.InWorld(), level = level() }))
  drainAcc = drainAcc + dt
  if drainAcc >= Live.DRAIN_EVERY then drainAcc = 0; A:Drain() end
  reportAcc = reportAcc + dt
  if reportAcc >= Live.REPORT_EVERY then reportAcc = 0; report('periodic') end
end

local function onCast(p)
  if not (C and active and p) then return end
  local act = GATHER_CAST[p.kind]
  if act then C:Productive(nowGT(), act, P.Where and P.Where() or nil) else C:Life(nowGT()) end
end

local wired = false
local function wire()
  if wired then return end
  wired = true
  if GI.Bus then
    GI.Bus.On('LEDGER_CASH', guard(onCash))
    GI.Bus.On('CONTEXT_CHANGED', guard(life))
  end
  P.On('P_TICK', guard(onTick))
  P.On('P_CAST', guard(onCast))
  P.On('P_COMBAT', guard(function(p) inCombat = p and p.inCombat == true; life() end))
  for _, e in ipairs({ 'P_MONEY', 'P_LOOT_OPEN', 'P_ZONE', 'P_LEVEL', 'P_QUEST_DONE' }) do P.On(e, guard(life)) end
end
wire()

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------

local function say(text) P.Print('GoldIntel: ' .. text) end

function Live.SetManual(mode)
  manual = mode
  if C then C:Manual(mode) end
end
function Live.SetOverride(act)
  override = act
  if C then C:Override(act) end
end

local function placeName(key, place)
  if place.inst then return tostring(place.zone) .. ' (instance)' end
  return tostring(place.zone) .. (place.sub and place.sub ~= '' and (' / ' .. place.sub) or '')
end

function Live.Top(n)
  if not Live.Ensure() then return {} end
  A:Drain()
  local rows = {}
  for key, place in pairs(state.places) do
    for ck, cell in pairs(place.cells) do
      local value = cell.coin + cell.vc
      if value > 0 then rows[#rows + 1] = { name = placeName(key, place), cell = ck, value = value, s = cell.s } end
    end
  end
  table.sort(rows, function(a, b) return a.value > b.value end)
  local out = {}
  for i = 1, math.min(n or 5, #rows) do out[i] = rows[i] end
  return out
end

local function money(c2)
  local g, s, cc = math.floor(c2 / 10000), math.floor((c2 % 10000) / 100), c2 % 100
  return string.format('%dg %ds %dc', g, s, cc)
end

if GI.Commands and GI.Commands.Register then
  GI.Commands.Register('agg', { help = 'live totals per place and activity: status, check, top [n]', usage = 'agg [status|check|top [n]]', fn = function(args)
    local sub = (args[1] or 'status'):lower()
    if sub == 'check' then
      local r, why = Live.Check()
      if not r then say('agg check: ' .. tostring(why)); return end
      say(string.format('agg check: cash difference %d copper, value difference %d copper %s; active time %d s',
        r.cash, r.vc, (r.cash == 0 and r.vc == 0) and '(OK)' or '(MISMATCH)', math.floor(r.seconds)))
    elseif sub == 'top' then
      local rows = Live.Top(tonumber(args[2]) or 5)
      if #rows == 0 then say('agg top: nothing yet') end
      for i, r in ipairs(rows) do
        local rate = r.s >= 60 and (money(math.floor(r.value * 3600 / r.s)) .. ' per hour') or 'time too short (or back-filled)'
        say(string.format('%d. %s [%s] %s in %d min, %s', i, r.name, r.cell, money(r.value), math.floor(r.s / 60), rate))
      end
    else
      if not Live.Ensure() then say('agg: not available (store not writable or no character)'); return end
      A:Drain()
      local T = A:Totals()
      local places, cells = 0, 0
      for _, pl in pairs(state.places) do places = places + 1; for _ in pairs(pl.cells) do cells = cells + 1 end end
      say(string.format('agg: %d places, %d cells; coin %s, value created %s, active %d min; %s', places, cells, money(T.coin), money(T.vc),
        math.floor(T.s / 60), active and 'recording' or 'not recording'))
      if C then say(clockText():gsub('^EVT clock ', 'agg clock: ')) end
      if manual then say('agg: time is ' .. manual .. 'd (/gi resume)') end
      if override then say('agg: activity set to ' .. override .. ' (/gi activity clear)') end
    end
  end })
  GI.Commands.Register('pause', { help = 'stop counting time (gold is still recorded)', fn = function() Live.SetManual('pause'); say('time paused (/gi resume)') end })
  GI.Commands.Register('afk', { help = 'mark yourself away: time is not counted', fn = function() Live.SetManual('afk'); say('away: time is not counted (/gi resume)') end })
  GI.Commands.Register('resume', { help = 'count time again', fn = function() Live.SetManual(nil); say('time counted again') end })
  GI.Commands.Register('activity', { help = 'set the activity by hand, or clear it', usage = 'activity <KEY>|clear', fn = function(args)
    local key = (args[1] or ''):upper()
    if key == '' then say('activity: ' .. tostring(override or 'detected automatically')); return end
    if key == 'CLEAR' then Live.SetOverride(nil); say('activity: detected automatically again'); return end
    if not Live.ACTIVITIES[key] then say('activity: unknown key ' .. key); return end
    Live.SetOverride(key); say('activity set to ' .. key .. ' (/gi activity clear)')
  end })
end

function Live.Stats()
  local s = {}
  for k, v in pairs(c) do s[k] = v end
  s.active = active; s.manual = manual; s.override = override
  if A then for k, v in pairs(A:Stats()) do s['agg_' .. k] = v end end
  return s
end

--- Tests only.
function Live._Reset() A, C, state, preQueue, active, manual, override, inCombat, loadGT, lastRemind = nil, nil, nil, {}, false, nil, nil, false, nil, nil end
