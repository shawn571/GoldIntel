-- GoldIntel / Collect / Collector.lua                                   (Phase 3b-1, D-074)
--
-- PURPOSE
--  Switches the collector events on and off, in groups, with fault containment, and reports delivery
--  counters. It builds NO ledger and no expectations (3b-2). It registers only events on the allow-list
--  (Platform.COLLECTOR_EVENTS, AC-1) and only through Platform.Events.Bind.
--
--  /gi collect status | on [G1..G8] [plain] | off | stats | reset | allow EVENT
--
-- RULES
--  * Collect is OFF after every login and /reload. The state is never persisted in 3b-1 (A-3).
--  * Fault containment (D-074): before each registration the event name is written to
--    char.collect.pending. If the client ever shows a blocked-action popup, the next load finds `pending`
--    still set, quarantines THAT event (char.collect.quarantine) and skips it from then on; every other
--    event keeps working. `/gi collect allow EVENT` lifts the quarantine.
--  * Groups register in a fixed order, the riskiest event (UNIT_SPELLCAST_SUCCEEDED, G5) last.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
local Core = GI.Core
assert(P and Core, 'Platform and Core must be loaded before Collect/Collector.lua')

local Collector = Core.Module('Collector', { deps = { 'Context' } })
GI.Collector = Collector

Collector.GROUPS = {
  { name = 'G1', label = 'loot and quest', events = { 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'QUEST_TURNED_IN' } },
  { name = 'G2', label = 'vendor', events = { 'MERCHANT_SHOW', 'MERCHANT_CLOSED' } },
  { name = 'G3', label = 'mail and trade', events = { 'MAIL_INBOX_UPDATE', 'TRADE_SHOW', 'TRADE_CLOSED',
                                                     'TRADE_ACCEPT_UPDATE', 'TRADE_MONEY_CHANGED' } },
  { name = 'G4', label = 'items and bags', events = { 'BAG_UPDATE_DELAYED', 'GET_ITEM_INFO_RECEIVED' } },
  { name = 'G5', label = 'casts', events = { 'UNIT_SPELLCAST_SUCCEEDED' } },
  { name = 'G6', label = 'auction posting', events = { 'AUCTION_HOUSE_AUCTION_CREATED' } },
  { name = 'G7', label = 'coin chat (loot signal)', events = { 'CHAT_MSG_MONEY' } },
  { name = 'G8', label = 'item chat (evidence only)', events = { 'CHAT_MSG_LOOT' } },
  { name = 'G9', label = 'trainer (0.5.2, D-093)', events = { 'TRAINER_SHOW', 'TRAINER_CLOSED' } },
  { name = 'G10', label = 'boss encounters: no reload popup (0.6.1, D-115)', events = { 'ENCOUNTER_START', 'ENCOUNTER_END' } },
}

local enabled = false
local autoDone = false          -- passive auto start: tried once per session, never after a hand-made off
local registered = {}          -- event -> handler
local memoryJournal = nil      -- used when the Store is not available
Collector.recovered = nil      -- event quarantined at startup because `pending` was still set
Collector.lastResult = nil

---------------------------------------------------------------------------
-- Journal (char.collect = { pending = EVENT?, quarantine = { EVENT = true }, lastStats = {...} })
---------------------------------------------------------------------------

local function journal()
  local store = GI.Store
  if store and store.Char then
    local ok, char = pcall(store.Char)
    if ok and type(char) == 'table' then
      if type(char.collect) ~= 'table' then char.collect = {} end
      if type(char.collect.quarantine) ~= 'table' then char.collect.quarantine = {} end
      return char.collect
    end
  end
  memoryJournal = memoryJournal or { quarantine = {} }
  return memoryJournal
end

function Collector.Journal() return journal() end

--- Names of quarantined events (sorted).
function Collector.Quarantined()
  local out = {}
  for name, v in pairs(journal().quarantine) do
    if v then out[#out + 1] = name end
  end
  table.sort(out)
  return out
end

--- Startup check: an unfinished registration means the previous session ended inside RegisterEvent.
function Collector.Recover()
  local j = journal()
  if type(j.pending) == 'string' and j.pending ~= '' then
    local event = j.pending
    j.quarantine[event] = true
    Collector.recovered = event
    P.Diag('warn', 'Collector', event .. ' was being registered when the last session ended: quarantined')
    j.pending = nil
    return event
  end
  return nil
end

function Collector.Allow(event)
  local j = journal()
  if not j.quarantine[event] then return false end
  j.quarantine[event] = nil
  if Collector.recovered == event then Collector.recovered = nil end
  return true
end

---------------------------------------------------------------------------
-- Adapter lookup
---------------------------------------------------------------------------

local function adapterFor(event)
  for _, a in ipairs(P.CollectAdapters) do
    if a.handlers and a.handlers[event] then return a, a.handlers[event] end
  end
  return nil
end

function Collector.IsEnabled() return enabled end

--- Sorted list of the raw events currently registered by the collector.
function Collector.Registered()
  local out = {}
  for name in pairs(registered) do out[#out + 1] = name end
  table.sort(out)
  return out
end

---------------------------------------------------------------------------
-- On / Off
---------------------------------------------------------------------------

local function groupByName(name)
  for _, g in ipairs(Collector.GROUPS) do
    if g.name == name then return g end
  end
  return nil
end

--- Registers one or all groups. opts.group = 'G3' (nil = all), opts.plain = true skips unit filtering.
-- Returns { registered = n, failed = {...}, skipped = {...} } or nil plus a reason.
function Collector.On(opts)
  opts = opts or {}
  local groups = Collector.GROUPS
  if opts.group then
    local g = groupByName(opts.group)
    if not g then return nil, 'unknown group ' .. tostring(opts.group) end
    groups = { g }
  end
  local j = journal()
  local result = { registered = 0, failed = {}, skipped = {}, already = 0 }
  for _, g in ipairs(groups) do
    for _, event in ipairs(g.events) do
      if registered[event] then
        result.already = result.already + 1
      elseif j.quarantine[event] then
        result.skipped[#result.skipped + 1] = event
      else
        local adapter, handler = adapterFor(event)
        if not adapter then
          result.failed[#result.failed + 1] = event .. ' (no adapter)'
        else
          j.pending = event                                   -- written BEFORE the call (fault containment)
          local bindOpts = nil
          if not opts.plain and adapter.unitFilter and adapter.unitFilter[event] then
            bindOpts = { unit = adapter.unitFilter[event] }
          end
          local ok, err = P.Events.Bind(event, handler, bindOpts)
          local stat = P.Events.Stats(event)
          if ok and stat.registered ~= false then
            registered[event] = handler
            result.registered = result.registered + 1
          else
            result.failed[#result.failed + 1] = event .. ' (' .. tostring(err or 'not in effect') .. ')'
          end
          j.pending = nil                                     -- cleared only after the call returned
        end
      end
    end
  end
  for _, a in ipairs(P.CollectAdapters) do
    if a.start then
      local ok, err = pcall(a.start)
      if not ok then P.Diag('error', 'Collector', 'adapter ' .. tostring(a.name) .. ' failed to start: ' .. tostring(err)) end
    end
  end
  enabled = next(registered) ~= nil
  Collector.lastResult = result
  if enabled and GI.Ledger then
    local ok, why = GI.Ledger.OnCollectOn(opts.group ~= nil)
    result.ledger = ok and 'interval started' or ('not started: ' .. tostring(why))
  end
  return result
end

--- Unregisters every collector event, stops the adapters and drops all contexts.
function Collector.Off()
  autoDone = true                                     -- a hand-made off must not be undone by a pending auto start
  local n = 0
  if GI.Ledger then GI.Ledger.OnCollectOff() end      -- ends the ledger interval while contexts still exist (AC-9)
  for event, handler in pairs(registered) do
    P.Events.Unbind(event, handler)
    registered[event] = nil
    n = n + 1
  end
  for _, a in ipairs(P.CollectAdapters) do
    if a.stop then pcall(a.stop) end
  end
  if GI.Context then GI.Context.Clear() end
  enabled = false
  return n
end

---------------------------------------------------------------------------
-- Statistics
---------------------------------------------------------------------------

--- Rows for every collector event (registered or not), in group order, plus totals.
function Collector.Stats()
  local rows = {}
  local total = { received = 0, kept = 0, dropped = 0, errors = 0 }
  for _, g in ipairs(Collector.GROUPS) do
    for _, event in ipairs(g.events) do
      local c = P.Events.Counters(event) or { received = 0, kept = 0, dropped = 0, errors = 0, maxPerSec = 0,
                                              cpuTotalMs = 0, cpuMaxMs = 0 }
      rows[#rows + 1] = { group = g.name, event = event, registered = registered[event] ~= nil,
                          via = P.Events.RegisteredVia(event), received = c.received, kept = c.kept,
                          dropped = c.dropped, errors = c.errors, maxPerSec = c.maxPerSec,
                          cpuTotalMs = c.cpuTotalMs, cpuMaxMs = c.cpuMaxMs }
      total.received = total.received + c.received
      total.kept = total.kept + c.kept
      total.dropped = total.dropped + c.dropped
      total.errors = total.errors + c.errors
    end
  end
  return { rows = rows, total = total }
end

--- Adapter and context statistics the validation report needs (loot closes by clear or timeout, ...).
function Collector.Details()
  local d = {}
  if P.LootModule then d.loot = P.LootModule.stats end
  if P.MerchantModule then d.vendor = P.MerchantModule.stats end
  if P.TradeModule then d.trade = P.TradeModule.stats end
  if P.MailModule then d.mail = P.MailModule.stats end
  if P.AuctionModule then d.ah = P.AuctionModule.stats end
  if P.QuestModule then d.quest = P.QuestModule.stats end
  if P.ItemsModule then d.items = P.ItemsModule.stats end
  if P.BagsModule then d.bags = P.BagsModule.stats end
  if P.Unit then d.cast = P.Unit.castStats end
  d.context = GI.Context and GI.Context.Stats() or {}
  return d
end

function Collector.Reset()
  P.Events.ResetCounters()
  for _, mod in ipairs({ P.LootModule, P.MerchantModule, P.TradeModule, P.MailModule, P.AuctionModule,
                         P.QuestModule, P.ItemsModule, P.BagsModule }) do
    if mod and mod.stats then
      for k in pairs(mod.stats) do mod.stats[k] = 0 end
    end
  end
  if P.Unit then P.Unit.castStats = { player = 0, secret = 0 } end
  if GI.Context then GI.Context.Reset() end
end

--- Compact counts-only summary kept in the character data (about 1.5 KB).
local function summaryForSave()
  local s = Collector.Stats()
  local out = { events = {}, total = s.total }
  for _, r in ipairs(s.rows) do
    if r.received > 0 then
      out.events[r.event] = { r.received, r.kept, r.dropped, r.errors, r.maxPerSec }
    end
  end
  local d = Collector.Details()
  if d.loot then
    out.loot = { opened = d.loot.opened, frame = d.loot.closedFrame, timeout = d.loot.closedTimeout,
                 replaced = d.loot.closedReplaced, clears = d.loot.clears, late = d.loot.lateClears,
                 dup = d.loot.dupClears, slotUnreadable = d.loot.unreadable, frameUnreadable = d.loot.frameUnreadable,
                 legacy = d.loot.legacyWindows, maxOpenSec = d.loot.maxOpenSec }
  end
  return out
end

Collector.SummaryForSave = summaryForSave

function Collector.OnInitialize()
  Collector.Recover()
end

-- Passive mode (0.5.0): the interval starts by itself after login so normal play is recorded without test scripts.
-- `collect.auto false` turns it off; a collect that is already on (or was switched off by hand this session) is left alone.
Collector.AUTO_DELAY = 3
function Collector.AutoStart()
  if autoDone or enabled then return false, 'already on' end
  autoDone = true
  local cfg = GI.Config and GI.Config.Get and GI.Config.Get('collect.auto')
  if cfg == false then return false, 'collect.auto is off' end
  local res, why = Collector.On({})
  if not res then return false, why end
  if enabled then P.Print('GoldIntel: recording started automatically (/gi collect off stops it; /gi config set collect.auto false disables auto-start)') end
  return enabled, res
end

function Collector.OnEnable()
  if P.After then P.After(Collector.AUTO_DELAY, function()
    local ok, err = pcall(Collector.AutoStart)
    if not ok then P.Diag('error', 'Collector', 'auto start failed: ' .. tostring(err)) end
  end) end
end

function Collector.OnLogout()
  local ok, err = pcall(function() journal().lastStats = summaryForSave() end)
  if not ok then P.Diag('warn', 'Collector', 'could not save the counter summary: ' .. tostring(err)) end
end

---------------------------------------------------------------------------
-- /gi collect
---------------------------------------------------------------------------

local function say(line) P.Print(line) end

local function statusLines()
  local lines = {}
  lines[#lines + 1] = 'collect: ' .. (enabled and 'ON' or 'off') .. ', ' .. #Collector.Registered() .. ' events registered'
  for _, g in ipairs(Collector.GROUPS) do
    local n = 0
    for _, e in ipairs(g.events) do if registered[e] then n = n + 1 end end
    lines[#lines + 1] = '  ' .. g.name .. ' (' .. g.label .. '): ' .. n .. '/' .. #g.events
  end
  local q = Collector.Quarantined()
  lines[#lines + 1] = 'quarantined: ' .. (#q > 0 and table.concat(q, ', ') or 'none')
  if Collector.recovered then
    lines[#lines + 1] = 'NOTE: ' .. Collector.recovered .. ' was quarantined at startup (an earlier registration did not finish)'
  end
  if P.IsAddonLoaded('GoldIntelDiag') then
    lines[#lines + 1] = 'WARNING: GoldIntelDiag is loaded; disable it for validation sessions (D-072)'
  end
  return lines
end

Collector.StatusLines = statusLines

local function fmt(n) return string.format('%.1f', n or 0) end

local function statsLines()
  local lines = {}
  local s = Collector.Stats()
  lines[#lines + 1] = 'event                            recv  kept  drop  err  max/s  cpu ms (total/max)  via'
  for _, r in ipairs(s.rows) do
    lines[#lines + 1] = string.format('%-32s %5d %5d %5d %4d %6d  %s/%s  %s%s', r.event, r.received, r.kept, r.dropped,
      r.errors, r.maxPerSec, fmt(r.cpuTotalMs), fmt(r.cpuMaxMs), r.via or '-', r.registered and '' or '  (not registered)')
  end
  lines[#lines + 1] = string.format('total: received %d, kept %d, dropped %d, errors %d', s.total.received, s.total.kept,
    s.total.dropped, s.total.errors)
  local d = Collector.Details()
  local l = d.loot or {}
  lines[#lines + 1] = string.format('loot windows: opened %d, closed by frame %d, by timeout %d, replaced %d; longest open %.1f s',
    l.opened or 0, l.closedFrame or 0, l.closedTimeout or 0, l.closedReplaced or 0, l.maxOpenSec or 0)
  lines[#lines + 1] = string.format('loot slot clears (information only): seen %d, duplicates %d, late %d; unreadable: frame %d (legacy rule windows %d), slots %d',
    l.clears or 0, l.dupClears or 0, l.lateClears or 0, l.frameUnreadable or 0, l.legacyWindows or 0, l.unreadable or 0)
  for _, kind in ipairs(GI.Context and GI.Context.KINDS or {}) do
    local c = d.context[kind]
    if c and (c.opened > 0 or c.strayCloses > 0) then
      lines[#lines + 1] = string.format('context %-6s opened %d, closed %d, duplicate opens %d, stray closes %d',
        kind, c.opened, c.closed, c.duplicateOpens, c.strayCloses)
    end
  end
  local m = d.mail or {}
  lines[#lines + 1] = string.format('mail: updates %d, stale (box closed) %d, snapshots %d; vendor duplicate closes %d; trade duplicate closes %d; casts kept %d, secret %d',
    m.updates or 0, m.staleUpdates or 0, m.snapshots or 0, (d.vendor or {}).duplicateCloses or 0,
    (d.trade or {}).duplicateCloses or 0, (d.cast or {}).player or 0, (d.cast or {}).secret or 0)
  return lines
end

Collector.StatsLines = statsLines

if GI.Commands then
  GI.Commands.Register('collect', {
    help = 'collector events: status | on [G1..G8] [plain] | off | stats | reset | allow EVENT',
    usage = 'collect [status|on [G1-G8] [plain]|off|stats|reset|allow EVENT]',
    fn = function(args)
      local sub = args[1] or 'status'
      if sub == 'status' then
        for _, line in ipairs(statusLines()) do say(line) end
      elseif sub == 'on' then
        local opts = {}
        for i = 2, #args do
          local a = args[i]
          if a == 'plain' then opts.plain = true
          elseif a:match('^[Gg]%d$') then opts.group = a:upper()
          else say('collect on: unknown option ' .. a); return end
        end
        local r, err = Collector.On(opts)
        if not r then say('collect on failed: ' .. tostring(err)); return end
        say(string.format('collect: %s, %d registered now, %d already, %d failed, %d skipped by quarantine',
          enabled and 'on' or 'off', r.registered, r.already, #r.failed, #r.skipped))
        for _, f in ipairs(r.failed) do say('  failed: ' .. f) end
        for _, f in ipairs(r.skipped) do say('  skipped: ' .. f) end
        if r.ledger then say('  ledger: ' .. r.ledger) end
      elseif sub == 'off' then
        say('collect: off, ' .. Collector.Off() .. ' events unregistered')
      elseif sub == 'stats' then
        for _, line in ipairs(statsLines()) do say(line) end
      elseif sub == 'reset' then
        Collector.Reset()
        say('collect: counters reset')
      elseif sub == 'allow' then
        local event = args[2] and args[2]:upper() or nil
        if not event then say('usage: /gi collect allow EVENT'); return end
        say(Collector.Allow(event) and ('collect: ' .. event .. ' released from quarantine') or ('collect: ' .. event .. ' was not quarantined'))
      else
        say('usage: /gi collect [status|on [G1-G8] [plain]|off|stats|reset|allow EVENT]')
      end
    end,
  })
end
