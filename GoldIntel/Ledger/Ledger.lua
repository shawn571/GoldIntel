-- GoldIntel / Ledger / Ledger.lua                                  (Phase 3b-2 M3, Architecture AC-9, AC-13)
--
-- PURPOSE
--  Runs the ledger intervals and ties Sources -> Reconciler -> Cash together:
--    * `collect on` (all groups) begins an interval, `collect off` ends it (Collector calls OnCollectOn / OnCollectOff);
--    * every finished entry goes to Cash and `lastMoney` (GoldIntelCharDB) follows the balance;
--    * at login a difference between the saved `lastMoney` and the balance is one OTHER entry flagged gap (AC-13,
--      R-3b2-1: a client crash loses the whole session, the next login still keeps the cumulative sum honest);
--    * at logout / reload the interval is ended first, so pending deltas are written before the client saves.
--    * /gi ledger status | last [n] | mark | check | on | off     and the quality block of /gi diag.
--
-- AC-9: money that moves while collect is OFF is not recorded (only the baseline `lastMoney` is refreshed).
-- Nothing here is persisted except what Cash and CharDB.lastMoney hold; the switch, the mark and the interval are
-- session memory (OFF after every login and reload, D-077 Q-2).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
local Core = GI.Core
assert(P and Core, 'Platform and Core must be loaded before Ledger/Ledger.lua')
assert(GI.Cash and GI.Sources, 'Ledger/Cash.lua and Collect/Sources.lua must be loaded first')

local Ledger = Core.Module('Ledger', { deps = { 'Collector' } })
GI.Ledger = Ledger

local switch = true            -- /gi ledger off switches the Reconciler off while collect stays on
local intervalStart            -- gt
local mark                     -- { balance, cumulative, pending, gt, t }
local last = { reason = 'not started' }

local function nowGT() local _, gt = P.Now(); return gt end

local function char()
  local ok, c = pcall(GI.Store.Char)
  if ok and type(c) == 'table' then return c end
  return nil
end

local function balance()
  local v = P.MoneyModule.Get()
  return v
end

local function setLastMoney(v)
  local c = char()
  if c and type(v) == 'number' then c.lastMoney = v; c.lmv = 2 end
end

local function sink(entry)
  local id, err = GI.Cash.Add(entry)
  if not id then P.Diag('error', 'Ledger', 'entry refused: ' .. tostring(err)) end
  -- lastMoney follows the LEDGER (previous lastMoney + this entry), not the live balance: money still pending
  -- (waiting for its chat line, WAIT 2.0 s) must be recovered as a gap after a crash, never skipped or counted twice
  local c = char()
  if id and c and c.lmv == 2 and type(c.lastMoney) == 'number' then setLastMoney(c.lastMoney + entry.copper)
  elseif id then setLastMoney(P.MoneyModule.Last()) end
end

local lotsSwitch = true          -- /gi lots on|off (AC-19): independent of the ledger switch; nothing runs without an interval
function Ledger.LotsSwitch() return lotsSwitch end

function Ledger.IsOn() return GI.Sources.IsActive() end
function Ledger.Switch() return switch end

--- Begins an interval (AC-9). Returns true, or false plus a reason.
function Ledger.Begin()
  if GI.Sources.IsActive() then return false, 'already on' end
  if not switch then return false, 'switched off (/gi ledger on)' end
  if not P.MoneyModule.Last() then P.MoneyModule.Sync(false) end
  GI.Sources.SetSink(sink)
  GI.Sources.Begin()
  if GI.Trace then GI.Trace.Begin() end
  if lotsSwitch and GI.ItemSources then
    GI.ItemSources.Begin()
    if GI.LotBook then GI.LotBook.Begin() end                               -- 3b-3 M3: stores lots (never cash)
  end
  intervalStart = nowGT()
  setLastMoney(P.MoneyModule.Last())
  last = { reason = 'on' }
  return true
end

--- Ends the interval: pending deltas become OTHER at once, quality counters are added to the ledger.
function Ledger.End()
  if not GI.Sources.IsActive() then return false, 'not on' end
  GI.Sources.End()
  if GI.LotBook then GI.LotBook.End() end
  if GI.ItemSources then GI.ItemSources.End() end
  if GI.Trace then GI.Trace.End() end
  GI.Sources.SetSink(nil)
  local s = GI.Sources.Stats()
  local led = GI.Cash.Ledger()
  if led then
    led.quality.intervals = led.quality.intervals + 1
    led.quality.unmatched = led.quality.unmatched + (s and s.unmatched or 0)
  end
  setLastMoney(P.MoneyModule.Last() or balance())
  mark = nil
  intervalStart = nil
  last = { reason = 'ended', stats = s }
  return true
end

---------------------------------------------------------------------------
-- Collector hooks
---------------------------------------------------------------------------

--- Called by Collector.On. `partial` = a single group was requested.
function Ledger.OnCollectOn(partial)
  if partial then last = { reason = 'not started: partial collection (use /gi collect on)' }; return false, last.reason end
  local ok, why = Ledger.Begin()
  if not ok then last = { reason = why }; return false, why end
  return true
end

function Ledger.OnCollectOff()
  if GI.Sources.IsActive() then Ledger.End() end
end

---------------------------------------------------------------------------
-- Login gap check and logout (AC-13, R-3b2-1)
---------------------------------------------------------------------------

function Ledger.CheckLoginGap()
  if not GI.Store.IsWritable() then return nil, 'store not writable' end
  local c = char()
  if not c then return nil, 'no character table' end
  local now = balance()
  if not now then return nil, 'balance unreadable' end
  local saved = c.lastMoney
  if type(saved) ~= 'number' then setLastMoney(now); return 0 end          -- first run: baseline only
  -- E-46: 0.3.3 stored lastMoney = 0 at a real logout (GetMoney reads 0 while the client logs out). A value without the
  -- lmv = 2 marker is not trusted: it becomes the new baseline once, with no gap entry.
  if c.lmv ~= 2 then setLastMoney(now); return 0 end
  if now ~= saved then
    GI.Cash.AddGap(now - saved, 'login')
    setLastMoney(now)
    return now - saved
  end
  return 0
end

function Ledger.OnEnable()
  local ok, res = pcall(Ledger.CheckLoginGap)
  if not ok then P.Diag('error', 'Ledger', 'login check failed: ' .. tostring(res)) end
  last.gap = ok and res or nil
end

function Ledger.OnLogout()
  if GI.Sources.IsActive() then Ledger.End() end
  if GI.Store.IsWritable() then
    -- E-46: GetMoney() returns 0 during a real logout, so the balance this module has accounted for is stored instead
    -- (Money tracks every PLAYER_MONEY, also while collect is off). The live read is only a fallback when it is positive.
    local v = P.MoneyModule.Last()
    if not v then
      local live = balance()
      if live and live > 0 then v = live end
    end
    if v then setLastMoney(v) end
  end
end

---------------------------------------------------------------------------
-- Mark / check (live validation, D-072: the ledger difference must be 0 copper)
---------------------------------------------------------------------------

local function pendingSum()
  local R = GI.Sources.Reconciler()
  return R and R:PendingSum() or 0
end

function Ledger.Mark()
  if not GI.Sources.IsActive() then return nil, 'ledger interval is not on (use /gi collect on)' end
  local bal = balance()
  if not bal then return nil, 'balance unreadable' end
  mark = { balance = bal, cumulative = GI.Cash.Cumulative(), pending = pendingSum(), gt = nowGT() }
  return mark
end

--- Compares the live balance change since the mark with what the ledger holds. difference must be 0.
function Ledger.Check()
  if not mark then return nil, 'no mark (use /gi ledger mark first)' end
  local bal = balance()
  if not bal then return nil, 'balance unreadable' end
  local moved = bal - mark.balance
  local entries = GI.Cash.Cumulative() - mark.cumulative
  local pending = pendingSum() - mark.pending
  local seen = P.MoneyModule.Last()
  return {
    moved = moved, entries = entries, pending = pending,
    unseen = seen and (bal - seen) or 0,                       -- money that moved but PLAYER_MONEY has not been processed yet
    difference = moved - entries - pending,
    seconds = nowGT() - mark.gt,
  }
end

---------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------

local function money(c)
  local sign = c < 0 and '-' or '+'
  c = c < 0 and -c or c
  local g, s, cc = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = g .. 'g' end
  if s > 0 then parts[#parts + 1] = s .. 's' end
  if cc > 0 or #parts == 0 then parts[#parts + 1] = cc .. 'c' end
  return sign .. table.concat(parts, ' ')
end
Ledger.Money = money

local function pct(x) return string.format('%.1f%%', x * 100) end

--- The review indicators, one block (used by /gi ledger status and /gi diag).
function Ledger.QualityLines()
  local stored = GI.Cash.Stats()
  local lines = {}
  local s = GI.Sources.Stats()
  if s then
    lines[#lines + 1] = string.format('this interval: OTHER %s by value (%s by entries), largest OTHER %s, gaps %d (%s), unmatched %d, pending %d',
      pct(s.otherShareValue), pct(s.otherShareEntries), money(s.largestOther), s.gapCount, money(s.gapValue), s.unmatched, s.pending)
  end
  if stored.total > 0 or stored.gapCount > 0 then
    lines[#lines + 1] = string.format('stored: OTHER %s by value (%s by entries), largest OTHER %s, gaps %d (%s), unmatched %d over %d interval(s)',
      pct(stored.otherShareValue), pct(stored.otherShareEntries), money(stored.largestOther), stored.gapCount, money(stored.gapValue),
      stored.unmatched, stored.intervals)
  end
  return lines
end

function Ledger.StatusLines()
  local lines = {}
  local on = GI.Sources.IsActive()
  local s = GI.Sources.Stats()
  lines[#lines + 1] = string.format('ledger: %s (switch %s)%s', on and 'ON' or 'off', switch and 'on' or 'OFF',
    on and intervalStart and string.format(', interval %.0f s', nowGT() - intervalStart) or '')
  if not on and last.reason and last.reason ~= 'on' then lines[#lines + 1] = '  ' .. tostring(last.reason) end
  if s then
    local ok = GI.Sources.Reconciler():Check()
    lines[#lines + 1] = string.format('interval: %d entries, money deltas %s, entries %s, pending %s -> sum check %s',
      s.total, money(s.sumDeltas), money(s.sumEntries), money(pendingSum()), ok and 'OK' or 'MISMATCH')
  end
  for _, l in ipairs(Ledger.QualityLines()) do lines[#lines + 1] = l end
  local st = GI.Cash.Stats()
  lines[#lines + 1] = string.format('stored: %d raw entries + %d folded, cumulative %s, saving %s, refused %d',
    st.raw, st.folded, money(st.cumulative), st.writable and 'yes' or 'NO (read-only or unavailable store)', GI.Cash.stats.rejected)
  local order = {}
  for src in pairs(st.bySource) do order[#order + 1] = src end
  table.sort(order)
  local parts = {}
  for _, src in ipairs(order) do parts[#parts + 1] = string.format('%s %d (%s)', src, st.bySource[src].n, money(st.bySource[src].copper)) end
  if #parts > 0 then lines[#lines + 1] = 'by source: ' .. table.concat(parts, ', ') end
  return lines
end

function Ledger.DiagLines()
  local lines = Ledger.QualityLines()
  if #lines > 0 then table.insert(lines, 1, 'ledger quality (OTHER share by value is the headline):') end
  return lines
end

local function say(line) P.Print(line) end

if GI.Commands then
  GI.Commands.Register('ledger', {
    help = 'cash ledger: status | last [n] | mark | check | on | off | trace [n|clear|on|off|note text]',
    usage = 'ledger [status|last [n]|mark|check|on|off|trace [n|clear|on|off|note text]]',
    fn = function(args)
      local sub = args[1] or 'status'
      if sub == 'status' then
        for _, l in ipairs(Ledger.StatusLines()) do say(l) end
      elseif sub == 'last' then
        local list = GI.Cash.Last(tonumber(args[2]) or 10)
        if #list == 0 then say('ledger: no entries'); return end
        for _, e in ipairs(list) do
          say(string.format('#%d %s %s %s act=%s/%s loc=%s%s%s%s', e.id, money(e.copper), e.src, e.conf, e.act, e.actConf, e.locConf,
            e.loc and e.loc.zone and (' ' .. e.loc.zone) or '', e.creditable and ' creditable' or '', (e.settle and ' settle' or '') .. (e.comp and (' ' .. e.comp) or '')))
        end
      elseif sub == 'mark' then
        local m, err = Ledger.Mark()
        if not m then say('ledger mark: ' .. tostring(err)); return end
        say(string.format('ledger mark set: balance %s, ledger %s, pending %s', money(m.balance):sub(2), money(m.cumulative), money(m.pending)))
      elseif sub == 'check' then
        local r, err = Ledger.Check()
        if not r then say('ledger check: ' .. tostring(err)); return end
        say(string.format('ledger check over %.0f s: money moved %s, entries %s, pending %s, unseen %s -> DIFFERENCE %d copper %s',
          r.seconds, money(r.moved), money(r.entries), money(r.pending), money(r.unseen), r.difference, r.difference == 0 and '(OK)' or '(MISMATCH)'))
      elseif sub == 'trace' then
        local T = GI.Trace
        local a2 = args[2]
        if a2 == 'clear' then T.Clear(); say('ledger trace: cleared')
        elseif a2 == 'note' then
          local text = table.concat(args, ' ', 3)
          if text == '' then say('usage: /gi ledger trace note <text>')
          elseif T.Note(text) then say('ledger trace: note added')
          else say('ledger trace: no interval is on (use /gi collect on first)') end
        elseif a2 == 'on' then T.Switch(true); say('ledger trace: on (records while a ledger interval is on)')
        elseif a2 == 'off' then T.Switch(false); say('ledger trace: off')
        else
          local list = T.Lines(tonumber(a2) or 40)
          if #list == 0 then say('ledger trace: no lines (trace is ' .. (T.IsOn() and 'on' or 'off') .. ')'); return end
          for _, l in ipairs(list) do say(l) end
        end
      elseif sub == 'on' then
        switch = true
        local c = GI.Collector and GI.Collector.IsEnabled and GI.Collector.IsEnabled()
        if not c then say('ledger: switch on; the interval starts with /gi collect on'); return end
        local ok, why = Ledger.Begin()
        say(ok and 'ledger: on' or ('ledger: ' .. tostring(why)))
      elseif sub == 'off' then
        switch = false
        if GI.Sources.IsActive() then Ledger.End() end
        say('ledger: off (collect keeps counting events)')
      else
        say('usage: /gi ledger [status|last [n]|mark|check|on|off|trace [n|clear|on|off]]')
      end
    end,
  })

  -- 3b-3: item lots (M2 trace of decisions, M3 stored lots). Lots never write cash (AC-15).
  local function lotsStatus()
    local IS, Ch = GI.ItemSources, P.ChatModule
    say(string.format('lots: %s (switch %s)', IS and IS.IsActive() and 'ON' or 'off', lotsSwitch and 'on' or 'OFF'))
    if GI.LotBook then for _, l in ipairs(GI.LotBook.Status()) do say(l) end end
    local s = IS and IS.Stats()
    if s then
      say(string.format('bag settles %d: baselines %d, diffs %d, empty %d, skipped (incomplete) %d, no snapshot %d; decisions %d, errors %d',
        s.settles, s.baselines, s.diffs, s.empty, s.skipped, s.snapFail, s.decisions, s.handlerErrors))
      local order = {}
      for how in pairs(s.how) do order[#order + 1] = how end
      table.sort(order)
      local parts = {}
      for _, how in ipairs(order) do parts[#parts + 1] = how .. ' ' .. s.how[how] end
      say('decided (item quantity): ' .. (#parts > 0 and table.concat(parts, ', ') or 'none yet'))
      say(string.format('loot windows %d (skinning windows %d, without guid %d), loot slots %d, item-info events %d',
        s.windows, s.skinWindows, s.noGuid, s.lootSlots, s.itemInfoEvents))
      local an = {}
      for k, v in pairs(s.anomalies) do an[#an + 1] = k .. ' ' .. v end
      table.sort(an)
      if #an > 0 then say('ANOMALIES (not expected, please report as a bug): ' .. table.concat(an, ', ')) else say('anomalies: none') end
    else
      say('lots: no interval has run (use /gi collect on)')
    end
    if Ch then
      local l = Ch.lootStats
      say(string.format('item chat lines (evidence): seen %d, text %d, secret %d, self %d, other %d', l.seen, l.text, l.secret, l.self, l.other))
    end
  end

  GI.Commands.Register('lots', {
    help = 'item lots: status | last [n] | sales [n] | unknown | check | on | off | reset confirm | decisions [n] | iteminfo <id or link>',
    usage = 'lots [status|last [n]|sales [n]|unknown|check|on|off|reset confirm|decisions [n]|iteminfo <id|link>]',
    fn = function(args)
      local sub = args[1] or 'status'
      if sub == 'status' then lotsStatus()
      elseif sub == 'on' then
        lotsSwitch = true
        if GI.Sources.IsActive() and GI.ItemSources and not GI.ItemSources.IsActive() then
          GI.ItemSources.Begin()
          if GI.LotBook then GI.LotBook.Begin() end
        end
        say('lots: on' .. (GI.Sources.IsActive() and '' or ' (the interval starts with /gi collect on)'))
      elseif sub == 'off' then
        lotsSwitch = false
        if GI.LotBook then GI.LotBook.End() end
        if GI.ItemSources then GI.ItemSources.End() end
        say('lots: off (the cash ledger keeps running)')
      elseif sub == 'decisions' then
        local list = GI.ItemSources and GI.ItemSources.Recent(tonumber(args[2]) or 10) or {}
        if #list == 0 then say('lots: no decisions yet'); return end
        for _, r in ipairs(list) do
          local d = r.d
          say(string.format('%s item %d x%d -> %s%s (%s)', d.dir, d.itemID, d.qty, d.how, d.act and (' ' .. d.act) or '', d.reason))
        end
      elseif sub == 'iteminfo' then
        local arg = args[2]
        local id = arg and (tonumber(arg:match('item:(%d+)')) or tonumber(arg))
        if not id then say('usage: /gi lots iteminfo <itemID or item link>'); return end
        local info = P.ItemsModule.Get(id)
        local text
        if info.status == 'ready' then
          text = string.format('item %d "%s": quality %s, class %s/%s, sell price %s copper, bind type %s', id, tostring(info.name), tostring(info.quality),
            tostring(info.classID), tostring(info.subclassID), tostring(info.sellPrice), tostring(info.bindType))
        else
          text = string.format('item %d: data %s (a load was requested; ask again in a moment)', id, tostring(info.status))
        end
        say(text)
        if GI.Trace and GI.Trace.IsRunning() then GI.Trace.Line('ITEMINFO_CMD ' .. text) end
      elseif sub == 'last' or sub == 'unknown' or sub == 'check' or sub == 'sales' then
        local LB = GI.LotBook
        local lines = sub == 'last' and LB.Last(tonumber(args[2])) or sub == 'sales' and LB.Sales(tonumber(args[2])) or sub == 'unknown' and LB.Unknown() or LB.Check()
        for _, l in ipairs(lines) do say(l) end
      elseif sub == 'reset' then
        if args[2] ~= 'confirm' then
          say('lots reset deletes the stored lots of THIS character only (cash ledger and prices untouched). Type /gi lots reset confirm to do it.')
        else
          local ok, err = GI.LotBook.ResetCurrent()
          say(ok and 'lots reset: this character\'s lots were deleted' or ('lots reset: ' .. tostring(err)))
        end
      else
        say('usage: /gi lots [status|last [n]|sales [n]|unknown|check|on|off|reset confirm|decisions [n]|iteminfo <id|link>]')
      end
    end,
  })
end

--- Test helper.
function Ledger.Reset()
  lotsSwitch = true; switch = true; intervalStart = nil; mark = nil; last = { reason = 'not started' }
end
