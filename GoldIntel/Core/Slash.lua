-- GoldIntel / Core / Slash.lua                                          (Phase 2)
--
-- PURPOSE
--   The /gi command set. The commands moved here from Platform/Probe.lua (Decisions D-022
--   item 5) and grew with Core and Store. Registration with the client goes through
--   Platform.RegisterSlash; this file never touches a WoW API.
--
--   Commands.Register(name, spec)   spec = { help = '...', usage = '...', fn = function(args, rest) }
--   Commands.Run(text, minimal)     parse and dispatch one command line
--   Commands.Install(minimal)       register /gi with the client
--
--   /gi                      summary of the whole addon
--   /gi help                 this list
--   /gi status               platform line (as in Phase 1) plus Core and Store state
--   /gi version              addon, client and interface
--   /gi probe                run the capability probe and print the report
--   /gi diag                 last diagnostics
--   /gi debug [on|off|ticks] echo normalized platform events to chat
--   /gi caps [events|api|all|text]   capability stages (valid/registered/delivered/payloadUsable)
--   /gi config [list|get K|set K V|reset K|all]   settings (persisted)
--   /gi db                   saved database: state, schema, sizes, history
--   /gi modules              module states
--   /gi checkpoint           size estimate and a reminder how saving works
--
--   When the platform is not operational only help, status, version, probe, diag and debug exist.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Core/Slash.lua')

local Commands = {}
GI.Commands = Commands

local registry = {}
local order = {}
local MINIMAL = { help = true, status = true, version = true, probe = true, diag = true, debug = true }

local function say(line) P.Print(line) end

function Commands.Register(name, spec)
  if type(name) ~= 'string' or not name:match('^[a-z][a-z0-9]*$') then return nil, 'command names are lowercase words' end
  if registry[name] then return nil, 'command already registered: ' .. name end
  if type(spec) ~= 'table' or type(spec.fn) ~= 'function' then return nil, 'spec needs a function' end
  registry[name] = spec
  order[#order + 1] = name
  return true
end

function Commands.Names()
  local out = {}
  for i = 1, #order do out[i] = order[i] end
  table.sort(out)
  return out
end

local function parse(text)
  text = tostring(text or '')
  local cmd, rest = text:match('^%s*(%S*)%s*(.-)%s*$')
  local args = {}
  for word in (rest or ''):gmatch('%S+') do args[#args + 1] = word end
  return (cmd or ''):lower(), args, rest or ''
end

local function kb(bytes)
  return string.format('%.1f KB', bytes / 1024)
end

---------------------------------------------------------------------------
-- Built-in commands
---------------------------------------------------------------------------

local function statusLine()
  local lastRegister = P.Events and P.Events.lastRegisterAttempt
  return 'operational=' .. tostring(P.operational) .. ' ready=' .. tostring(P.IsReady())
    .. ' inWorld=' .. tostring(P.InWorld()) .. ' scheduler=' .. tostring(P.Scheduler.Backend())
    .. ' money=' .. tostring(P.MoneyModule.Last()) .. ' diag=' .. P.DiagCount()
    .. ' lastRegister=' .. tostring(lastRegister)
end

local function coreLines()
  local lines = {}
  if GI.Core then
    local d = GI.Core.Describe()
    lines[#lines + 1] = 'core=' .. d.state .. ' modules=' .. d.total .. ' enabled=' .. d.enabled
      .. ' failed=' .. d.failed .. ' disabled=' .. d.disabled .. ' stubs=' .. d.stub
  end
  if GI.Store and GI.Store.IsOpen() then
    local s = GI.Store.Status()
    local bytes = GI.Store.EstimateBytes(GI.Store.Get())
    lines[#lines + 1] = 'store=' .. s.state .. ' schema=' .. tostring(s.schema) .. ' writable=' .. tostring(s.writable)
      .. ' size~' .. kb(bytes)
    if s.reason then lines[#lines + 1] = 'store note: ' .. s.reason end
  end
  return lines
end

Commands.Register('status', { help = 'platform, core and store state', fn = function()
  say(statusLine())
  for _, line in ipairs(coreLines()) do say(line) end
end })

Commands.Register('help', { help = 'list commands', fn = function()
  say('GoldIntel ' .. P.VERSION .. ' commands (/gi <command>):')
  for _, name in ipairs(Commands.Names()) do
    if not Commands.minimal or MINIMAL[name] then
      local spec = registry[name]
      say('  ' .. (spec.usage or name) .. '  -  ' .. (spec.help or ''))
    end
  end
end })

Commands.Register('version', { help = 'addon, client and interface versions', fn = function()
  local info = P.ProbeModule and P.ProbeModule.last and P.ProbeModule.last.info or {}
  say('GoldIntel ' .. P.VERSION .. '  (contract ' .. P.CONTRACT_VERSION .. ')')
  say('client ' .. tostring(info.gameVersion) .. ' build ' .. tostring(info.build) .. '  interface ' .. tostring(info.interface)
    .. '  locale ' .. tostring(info.locale))
end })

Commands.Register('perf', { help = 'CPU and memory of GoldIntel (M4 measurement, read-only)', fn = function()
  local Perf = P.PerfModule
  if not Perf then say('perf: not available'); return end
  local fns, mets = Perf.Functions(), Perf.Metrics()
  say('perf: profiler functions ' .. (fns and table.concat(fns, ', ') or 'none'))
  say('perf: metrics ' .. (mets and table.concat(mets, ', ') or 'none'))
  say('perf: now ' .. Perf.Text(Perf.Sample({ memory = true })) .. '  (memory read on request only: a short freeze is possible)')
  local ok, c = pcall(GI.Store.Char)
  local n = ok and type(c) == 'table' and type(c.perf) == 'table' and type(c.perf.samples) == 'table' and #c.perf.samples or 0
  say('perf: ' .. n .. ' samples stored (CPU every 10 minutes while recording; read after logout)')
end })

Commands.Register('probe', { help = 'run the capability probe and print the report', fn = function()
  P.ProbeModule.Run()
  P.CheckFatal()
  P.ProbeModule.Persist()
  if GI.Capabilities then GI.Capabilities.Import() end
  for _, line in ipairs(P.ProbeModule.Report()) do say(line) end
  say('Report saved to SavedVariables after /reload or logout (GoldIntelDB.compat.report).')
end })

Commands.Register('diag', { help = 'last diagnostics', fn = function()
  local list = P.GetDiag()
  if GI.Ledger then for _, l in ipairs(GI.Ledger.DiagLines()) do say(l) end end
  if #list == 0 then say('no diagnostics') end
  for i = math.max(1, #list - 9), #list do
    say(list[i].level .. ' [' .. list[i].module .. '] ' .. list[i].msg)
  end
end })

Commands.Register('debug', { help = 'echo platform events: on | off | ticks', usage = 'debug [on|off|ticks]', fn = function(args)
  local arg = (args[1] or ''):lower()
  if arg == 'ticks' then
    P.debugTicks = not P.debugTicks
    local note = ''
    if P.debugTicks and not P.debug then
      note = ' (nothing is echoed until you also type /gi debug on)'
    end
    say('tick echo ' .. (P.debugTicks and 'on' or 'off') .. note)
  else
    P.SetDebug(arg ~= 'off')
    say('debug ' .. (P.debug and 'on' or 'off') .. ' (normalized events are echoed to chat)')
  end
end })

-- yes = proven, NO = failed, anything else = not observed yet (NOT a failure)
local function stageWord(stage, value)
  if value == true then return 'yes' end
  if value == false then return 'NO' end
  if stage == 'delivered' then return 'not-seen-yet' end
  return 'unknown'
end

local function stageText(rec)
  local parts = {}
  for _, stage in ipairs(GI.Capabilities.STAGES[rec.kind]) do
    parts[#parts + 1] = stage .. '=' .. stageWord(stage, rec.stages[stage])
  end
  return table.concat(parts, ' ')
end

-- Read-only view of a kept session record (D-041): previous or pinned.
local function showRecord(which, rec)
  if type(rec) ~= 'table' then say('no ' .. which .. ' session record'); return end
  local now = P.Now()
  local age = (type(rec.generatedAt) == 'number') and math.floor((now - rec.generatedAt) / 60) or nil
  say(which .. ' session: ' .. (rec.durationSec and (math.floor(rec.durationSec / 60) .. ' min') or 'length unknown')
    .. ', addon ' .. tostring(rec.addonVersion) .. ', build ' .. tostring(rec.build)
    .. ', ended by ' .. tostring(rec.endedBy) .. (age and (', saved ' .. age .. ' min ago') or ''))
  local names = {}
  for event in pairs(rec.eventStats or {}) do names[#names + 1] = event end
  table.sort(names)
  for _, event in ipairs(names) do
    local d = rec.eventStats[event].delivered or 0
    say('  ' .. event .. ': delivered ' .. d .. (d == 0 and '  (not seen)' or ''))
  end
  say('  ' .. #(rec.output or {}) .. ' output lines are kept in the saved file (GoldIntel.lua, runtime.' .. which .. '.output)')
end

Commands.Register('caps', { help = 'capability stages', usage = 'caps [events|api|all|text|history|events previous|events pinned]', fn = function(args)
  local C = GI.Capabilities
  if not C then say('capabilities are not available'); return end
  local filter = (args[1] or ''):lower()
  local second = (args[2] or ''):lower()
  if filter == 'history' then
    local rows = C.Records().history
    if #rows == 0 then say('no earlier sessions are recorded') end
    for i = #rows, 1, -1 do
      local r = rows[i]
      say('session at ' .. tostring(r.sessionStart) .. ': ' .. (r.durationSec and (math.floor(r.durationSec / 60) .. ' min') or '? min')
        .. ', build ' .. tostring(r.build) .. ', ended by ' .. tostring(r.endedBy))
    end
    return
  end
  if filter == 'previous' or filter == 'pinned' or (filter == 'events' and (second == 'previous' or second == 'pinned')) then
    local which = (filter == 'events') and second or filter
    showRecord(which, C.Records()[which])
    return
  end
  local summary = C.Summary()
  local function line(kind)
    local parts = {}
    local levels = {}
    for level in pairs(summary[kind]) do levels[#levels + 1] = level end
    table.sort(levels)
    for _, level in ipairs(levels) do parts[#parts + 1] = level .. '=' .. summary[kind][level] end
    return table.concat(parts, ' ')
  end
  say('events: ' .. (line('event') ~= '' and line('event') or 'none'))
  say('api:    ' .. (line('api') ~= '' and line('api') or 'none'))
  local kind = nil
  if filter == 'events' then kind = 'event' elseif filter == 'api' then kind = 'api' end
  local showAll = filter == 'all'
  for _, name in ipairs(C.Names(kind)) do
    local rec = C.Get(name)
    local match = (filter == '' and rec.kind == 'event') or showAll or kind ~= nil
    if not match and filter ~= '' and name:lower():find(filter, 1, true) then match = true end
    if match then
      if rec.kind == 'event' then
        say(name .. '  [' .. rec.level .. ']  ' .. stageText(rec))
      else
        say(name .. '  [' .. rec.level .. ']' .. ((rec.notes.present and rec.level ~= 'present') and ('  ' .. rec.notes.present) or ''))
      end
    end
  end
  say('yes = proven, NO = failed, not-seen-yet / unknown = not observed yet (not a failure). Only payloadUsable (events) or present (api) means a design may depend on a capability.')
end })

Commands.Register('config', { help = 'settings', usage = 'config [list|get K|set K V|reset K|all]', fn = function(args)
  local Config = GI.Config
  if not Config then say('config is not available'); return end
  local sub = (args[1] or 'list'):lower()
  if sub == 'list' then
    for _, e in ipairs(Config.List()) do
      say(e.key .. ' = ' .. tostring(e.value) .. (e.isDefault and '' or ('   (default ' .. tostring(e.default) .. ')'))
        .. (e.readonly and '  [read-only]' or ''))
    end
  elseif sub == 'get' then
    if not args[2] then say('usage: /gi config get <key>'); return end
    local value, err = Config.Get(args[2])
    if value == nil then say(tostring(err)) else say(args[2] .. ' = ' .. tostring(value)) end
  elseif sub == 'set' then
    if not args[2] or args[3] == nil then say('usage: /gi config set <key> <value>'); return end
    local value, perr = Config.Parse(args[2], args[3])
    if value == nil then say(tostring(perr)); return end
    local ok, result = Config.Set(args[2], value, 'command')
    if not ok then say(tostring(result)); return end
    say(args[2] .. ' = ' .. tostring(value) .. (result and '' or '   (this session only: the saved database is not writable)'))
  elseif sub == 'reset' then
    if not args[2] then say('usage: /gi config reset <key|all>'); return end
    if args[2]:lower() == 'all' then
      say('reset ' .. Config.ResetAll('command') .. ' setting(s) to defaults')
    else
      local ok, err = Config.Reset(args[2], 'command')
      if not ok then say(tostring(err)) else say(args[2] .. ' reset to ' .. tostring(Config.Get(args[2]))) end
    end
  else
    say('usage: /gi config [list|get <key>|set <key> <value>|reset <key|all>]')
  end
end })

Commands.Register('db', { help = 'saved database state, schema, sizes, history', fn = function()
  local Store = GI.Store
  if not Store or not Store.IsOpen() then say('store is not open'); return end
  local s = Store.Status()
  say('state=' .. s.state .. ' schema=' .. tostring(s.schema) .. ' target=' .. tostring(s.target) .. ' writable=' .. tostring(s.writable))
  if s.reason then say('note: ' .. s.reason) end
  if #s.added > 0 then say('added sections: ' .. table.concat(s.added, ', ')) end
  if #s.repaired > 0 then say('repaired sections: ' .. table.concat(s.repaired, ', ')) end
  local db = Store.Get()
  for _, name in ipairs(GI.Migrations.SECTION_NAMES) do
    local section = db[name]
    if type(section) == 'table' then
      local n = 0
      for _ in pairs(section) do n = n + 1 end
      local bytes = Store.EstimateBytes(section)
      say('  ' .. name .. ': ' .. n .. ' entries, ~' .. kb(bytes))
    end
  end
  say('  compat: ' .. (type(db.compat) == 'table' and 'present (preserved untouched)' or 'absent'))
  local c = Store.Char()
  say('  character data: schema ' .. tostring(c.schema) .. ', pending ' .. (next(c.pending) == nil and 'none' or 'yes') .. (c.activeSessionID and (', activeSessionID ' .. tostring(c.activeSessionID)) or ''))
  if GI.Capabilities and GI.Capabilities.Records then
    local r = GI.Capabilities.Records()
    say('  session records: current + previous ' .. (r.previous and 'kept' or 'none yet') .. ', history ' .. #r.history .. ' row(s), pinned ' .. (r.pinned and 'yes' or 'no'))
  end
  local meta = db.meta
  if type(meta) == 'table' then
    say('opens=' .. tostring(meta.opens) .. ' lastBuild=' .. tostring(meta.lastBuild) .. ' addonVersion=' .. tostring(meta.addonVersion))
    local history = meta.schemaHistory
    if type(history) == 'table' then
      for i = math.max(1, #history - 4), #history do
        say('  migration: schema ' .. tostring(history[i].from) .. ' -> ' .. tostring(history[i].to) .. ' by ' .. tostring(history[i].addonVersion))
      end
    end
  end
end })

Commands.Register('modules', { help = 'module states', fn = function()
  if not GI.Core then say('core is not available'); return end
  local list = GI.Core.Modules()
  if #list == 0 then say('no modules registered') end
  for _, m in ipairs(list) do
    say(m.name .. ': ' .. m.state .. (m.reason and (' (' .. m.reason .. ')') or '') .. (m.stub and '  [placeholder]' or ''))
  end
end })

Commands.Register('checkpoint', { help = 'size estimate; how saving works; pin | unpin keeps this session record', usage = 'checkpoint [pin|unpin]', fn = function(args)
  local Store = GI.Store
  if not Store or not Store.IsOpen() then say('store is not open'); return end
  local sub = ((args and args[1]) or ''):lower()
  if sub == 'pin' or sub == 'unpin' then
    local C = GI.Capabilities
    if not C then say('capabilities are not available'); return end
    if sub == 'pin' then
      local ok, why = C.Pin()
      say(ok and 'pinned: this session record is kept until you unpin or pin another (/reload to save it now)' or ('not pinned: ' .. tostring(why)))
    else
      local had, why = C.Unpin()
      if had == nil then say('not changed: ' .. tostring(why)) else say(had and 'unpinned' or 'nothing was pinned') end
    end
    return
  end
  if GI.Capabilities then GI.Capabilities.Persist() end
  local r = Store.Checkpoint()
  say('database ~' .. kb(r.bytes) .. (r.truncated and ' (estimate truncated)' or '') .. '  writable=' .. tostring(r.writable))
  say(r.note .. ' Use /reload to save now.')
end })

---------------------------------------------------------------------------
-- Dispatch and installation
---------------------------------------------------------------------------

local function summary()
  local info = P.ProbeModule and P.ProbeModule.last and P.ProbeModule.last.info or {}
  say('GoldIntel ' .. P.VERSION .. '  -  gold analytics for WoW Forever (client ' .. tostring(info.gameVersion) .. ')')
  say(statusLine())
  for _, line in ipairs(coreLines()) do say(line) end
  if GI.Capabilities then
    local s = GI.Capabilities.Summary()
    local function n(kind, level) return s[kind][level] or 0 end
    say('events: registered=' .. n('event', 'registered') .. ' delivered=' .. n('event', 'delivered')
      .. ' payloadUsable=' .. n('event', 'payloadUsable') .. ' blocked=' .. n('event', 'blocked')
      .. '   api: present=' .. n('api', 'present') .. ' absent=' .. n('api', 'absent') .. ' unknown=' .. n('api', 'unknown'))
  end
  say('Type /gi help for commands. Collection of gold data starts in a later version.')
end

--- Dispatches one command line.
function Commands.Run(text, minimal)
  local cmd, args, rest = parse(text)
  if minimal == nil then minimal = Commands.minimal end
  if cmd == '' then
    if minimal then registry.status.fn({}, '') else summary() end
    return
  end
  local spec = registry[cmd]
  if not spec or (minimal and not MINIMAL[cmd]) then
    say('unknown command "' .. cmd .. '". Type /gi help.')
    return
  end
  local ok, err = pcall(spec.fn, args, rest)
  if not ok then P.Diag('error', 'Slash', 'command ' .. cmd .. ' failed: ' .. tostring(err)) ; say('command failed: ' .. tostring(err)) end
  if GI.Capabilities then GI.Capabilities.Touch() end      -- save this command's output with the data soon
end

--- Registers /gi with the client. minimal = only the platform commands.
function Commands.Install(minimal)
  Commands.minimal = minimal and true or false
  return P.RegisterSlash('GOLDINTEL', '/gi', function(text) Commands.Run(text) end)
end

if GI.Core then GI.Core.Service('commands', Commands) end
