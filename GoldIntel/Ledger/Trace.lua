-- GoldIntel / Ledger / Trace.lua                          (Phase 3b-2, diagnostic build after E-46)
--
-- PURPOSE
--  Evidence only. While a ledger interval is on, writes one text line per fact needed to explain why money was
--  (not) attributed to a loot window:
--      LOOT_OPEN   slot count, every slot (type, amount, source id tail), coin amounts, item count
--      LOOT_CLEAR  slot cleared
--      LOOT_CLOSE  how the window closed and how long it was open
--      EXP         expectation added / closed / consumed (matched) / expired (UNMATCHED) / cleared
--      MONEY       every money delta with the expectations active at that moment
--      ENTRY       every finished ledger entry, its source, expectation id and how long the delta waited
--  Each line starts with seconds since the interval began and seconds since the previous line.
--  It changes no classification: all hooks are optional taps whose errors are swallowed.
--
-- STORAGE   GoldIntelCharDB.trace = { lines = { "...", ... } }, newest last, at most Trace.CAP (1500) lines.
-- COMMAND   /gi ledger trace [n] | clear | on | off

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Ledger/Trace.lua')

local Trace = {}
GI.Trace = Trace
Trace.CAP = 1500
Trace.stats = { lines = 0, errors = 0 }

local on = true
local t0, prev

local function nowGT() local _, gt = P.Now(); return gt end

local function char()
  local ok, c = pcall(GI.Store.Char)
  if ok and type(c) == 'table' then return c end
end

function Trace.IsOn() return on end
function Trace.IsRunning() return t0 ~= nil end

function Trace.Line(text)
  if not on or not t0 then return end
  local c = char()
  if not c then return end
  local gt = nowGT()
  if type(c.trace) ~= 'table' or type(c.trace.lines) ~= 'table' then c.trace = { lines = {} } end
  local L = c.trace.lines
  L[#L + 1] = string.format('%8.3f +%.3f %s', gt - t0, gt - (prev or gt), text)
  prev = gt
  if #L > Trace.CAP then table.remove(L, 1) end
  Trace.stats.lines = Trace.stats.lines + 1
end

local function safe(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then Trace.stats.errors = Trace.stats.errors + 1 end
  end
end

local function expText(e)
  return string.format('#%d %s %s%dc%s', e.id, e.src, e.sign < 0 and '-' or '', e.copper or 0, e.hold and ' hold' or '')
end

--- Group facts (evidence): which group functions exist and what they report.
local function groupText()
  local n, g, r = P.Call('GetNumGroupMembers'), P.Call('IsInGroup'), P.Call('IsInRaid')
  if not n and not g and not r then return 'grp=unavailable' end
  return string.format('grp=%s/%s/%s', n and tostring(n[1]) or 'nofn', g and tostring(g[1]) or 'nofn', r and tostring(r[1]) or 'nofn')
end

local function clean(text)
  return (tostring(text):gsub('|', '<pipe>'):gsub('[%c]', '?'))
end

local function activeText(gt)
  local X = GI.Sources.Expectations()
  if not X then return '[]', '[]' end
  local ex, wi = {}, {}
  for _, e in ipairs(X:Active(gt, nil, 'exact')) do ex[#ex + 1] = expText(e) end
  for _, e in ipairs(X:Active(gt, nil, 'window')) do wi[#wi + 1] = '#' .. e.id .. ' ' .. e.src end
  return '[' .. table.concat(ex, ', ') .. ']', '[' .. table.concat(wi, ', ') .. ']'
end

local function onSources(kind, a, b, c)
  if kind == 'money' then
    local gt = a.gt or nowGT()
    local ex, wi = activeText(gt)
    Trace.Line(string.format('MONEY %+d%s exact=%s windows=%s %s', a.copper, a.gap and ' GAP' or '', ex, wi, groupText()))
  elseif kind == 'entry' then
    local waited = nowGT() - (a.t or nowGT())
    Trace.Line(string.format('ENTRY %+d %s %s%s%s waited=%.3f', a.copper, a.src, a.conf or '?',
      a.exp and (' exp=#' .. a.exp) or '', a.comp and (' ' .. a.comp) or '', waited))
  elseif kind == 'chat' then
    local how, p, win, id = a, b, c, nil
    Trace.Line(string.format('CHATSIG %s %s %dc group=%s%s', how, tostring(p.kind), p.copper, tostring(p.group),
      win and (' window=#' .. win.id) or ''))
  elseif kind == 'exp' then
    local ev, e = a, b
    if ev == 'add' then Trace.Line('EXP add ' .. expText(e))
    elseif ev == 'close' then Trace.Line('EXP close ' .. expText(e))
    elseif ev == 'consume' then Trace.Line('EXP matched ' .. expText(e))
    elseif ev == 'expire' then Trace.Line('EXP expired UNMATCHED ' .. expText(e))
    elseif ev == 'clear' then Trace.Line('EXP interval end UNMATCHED ' .. expText(e)) end
  end
end

local function onLoot(kind, a, b)
  if kind == 'open' then
    Trace.Line(string.format('LOOT_OPEN src=%s frameShown=%s %s numLootItems=%s read=%d coins=[%s] items=%d slots: %s', a.sourceType,
      tostring(a.frame), groupText(), tostring(a.raw), a.slots or 0, table.concat(a.coins, ','), #a.items, table.concat(a.detail or {}, ' ')))
  elseif kind == 'clear' then Trace.Line('LOOT_CLEAR slot=' .. tostring(a))
  elseif kind == 'close' then Trace.Line(string.format('LOOT_CLOSE by=%s open=%.3fs', tostring(a), b or 0)) end
end

local function onChat(rec)
  if rec.secret then Trace.Line('CHAT_MONEY text=<secret value> ' .. groupText())
  elseif rec.nonString then Trace.Line('CHAT_MONEY text=<' .. rec.nonString .. '> ' .. groupText())
  else
    Trace.Line(string.format('CHAT_MONEY parsed=%s %s text="%s"', tostring(rec.copper), groupText(), clean(rec.text)))
  end
end


local function idList(map)
  local ids = {}
  for id in pairs(map or {}) do ids[#ids + 1] = id end
  table.sort(ids)
  local out = {}
  for _, id in ipairs(ids) do out[#out + 1] = id .. 'x' .. map[id] end
  return table.concat(out, ' ')
end

--- Item pipeline facts (3b-3 M2, trace-only): ItemSources.tap(kind, a, b, c)
local function onItems(kind, a, b, cc)
  if kind == 'window' then
    Trace.Line(string.format('ITEM_WIN #%d src=%s skinning=%s act=%s/%s guid=%s', a.id, tostring(a.sourceType), tostring(a.skinning), tostring(a.act), tostring(a.actConf), tostring(a.guid)))
  elseif kind == 'slot' then
    Trace.Line(string.format('ITEM_SLOT win=#%s item=%d qty=%d', tostring(a.windowId), a.itemID, a.qty))
  elseif kind == 'windowClose' then
    Trace.Line(string.format('ITEM_WIN_CLOSE #%s by=%s', a and tostring(a.id) or '?', tostring(b)))
  elseif kind == 'ranges' then
    local t = {}
    for bag = 0, P.BagsModule and P.BagsModule.RANGE_MAX or 8 do t[#t + 1] = bag .. ':' .. tostring(a.slots[bag]) end
    local k = {}
    for name, v in pairs(a.constants) do k[#k + 1] = name .. '=' .. v end
    table.sort(k)
    Trace.Line('BAGRANGE slots ' .. table.concat(t, ' ') .. ' constants ' .. (#k > 0 and table.concat(k, ' ') or 'none'))
  elseif kind == 'baseline' then
    local n = 0
    for _ in pairs(a.items) do n = n + 1 end
    local t = {}
    for bag = 0, P.BagsModule and P.BagsModule.LAST_BAG or 5 do t[#t + 1] = bag .. ':' .. tostring(a.bags and a.bags[bag]) end
    Trace.Line(string.format('BAGS baseline origin=%s distinctItems=%d slotsRead=%d complete=%s bags %s', tostring(b), n, a.slots or 0, tostring(a.complete), table.concat(t, ' ')))
  elseif kind == 'diff' then
    local f = b.facts
    Trace.Line(string.format('BAGS diff seq=%d +[%s] -[%s] slotsRead=%d ctx quest=%s vendor=%s mail=%s trade=%s', a.seq, idList(a.added), idList(a.removed),
      b.snap.slots or 0, tostring(f.quest), tostring(f.merchant), tostring(f.mail), tostring(f.trade)))
  elseif kind == 'skipped' then
    Trace.Line('BAGS settle skipped: incomplete snapshot (slots read ' .. tostring(a and a.slots) .. ')')
  elseif kind == 'snapFail' then
    Trace.Line('BAGS settle: no snapshot (' .. tostring(a) .. ')')
  elseif kind == 'empty' then
    Trace.Line('BAGS settle: no net change')
  elseif kind == 'decision' then
    local d, e, f = a, b, cc
    Trace.Line(string.format('ITEM %s item=%d qty=%d -> %s%s%s reason="%s" waited=%.3f money+%d money-%d', d.dir, d.itemID, d.qty, d.how,
      d.act and (' act=' .. d.act .. '/' .. tostring(d.actConf)) or '', d.skinning and ' SKINNING' or '', clean(d.reason), nowGT() - e.gt,
      f.moneyPos or 0, f.moneyNeg or 0))
  elseif kind == 'iteminfo' then
    if a and b and b.status == 'ready' then
      Trace.Line(string.format('ITEMINFO id=%d name="%s" quality=%s class=%s/%s sell=%s bind=%s', a, clean(b.name), tostring(b.quality), tostring(b.classID), tostring(b.subclassID), tostring(b.sellPrice), tostring(b.bindType)))
    else
      Trace.Line(string.format('ITEMINFO id=%s status=%s', tostring(a), b and tostring(b.status) or 'noModule'))
    end
  elseif kind == 'infoEvent' then
    Trace.Line(string.format('ITEM_INFO_EVENT id=%s ready=%s', tostring(a.itemID), tostring(a.ready)))
  elseif kind == 'anomaly' then
    local t = {}
    for k, v in pairs(b or {}) do t[#t + 1] = k .. '=' .. tostring(v) end
    table.sort(t)
    Trace.Line('ANOMALY ' .. tostring(a) .. ' ' .. table.concat(t, ' ') .. '  -- NOT EXPECTED: please report this as a bug')
  end
end

local function onChatLoot(rec)
  if rec.secret then Trace.Line('CHAT_LOOT text=<secret value>')
  elseif rec.nonString then Trace.Line('CHAT_LOOT text=<' .. rec.nonString .. '>')
  else
    Trace.Line(string.format('CHAT_LOOT kind=%s item=%s qty=%s text="%s"', tostring(rec.kind), tostring(rec.itemID), tostring(rec.qty), clean(rec.text)))
  end
end

--- Evidence recorder (user-found gap 2026-10-21): the player's own casts, with the spell name, so gathering spell ids of other
--- skill ranks can be added from evidence (E-23 listed only one rank per profession). Nothing else reads this.
local function spellName(id) return P.Unit and P.Unit.SpellName and P.Unit.SpellName(id) or nil end

local castSeen = {}
P.On('P_CAST', function(p)
  if not t0 then return end
  if p.kind == 'other' then                    -- unrecognized casts: once per spell id per interval (combat spells would flood the trace)
    if castSeen[p.spellID] then return end
    castSeen[p.spellID] = true
  end
  local ok, err = pcall(function()
    Trace.Line(string.format('CAST spell=%s kind=%s name=%s', tostring(p.spellID), tostring(p.kind), tostring(spellName(p.spellID))))
  end)
  if not ok then Trace.stats.errors = (Trace.stats.errors or 0) + 1 end
end)

--- Starts a trace for a ledger interval (called by Ledger.Begin after Sources.Begin).
function Trace.Begin()
  t0, prev = nowGT(), nil
  castSeen = {}
  GI.Sources.tap = safe(onSources)
  if P.LootModule then P.LootModule.tap = safe(onLoot) end
  if P.ChatModule then P.ChatModule.tap = safe(onChat); P.ChatModule.lootTap = safe(onChatLoot) end
  if GI.ItemSources then GI.ItemSources.tap = safe(onItems) end
  local ut = P.Now()
  Trace.Line(string.format('INTERVAL begin unix=%d version=%s', ut, tostring(P.VERSION)))
  local okS, st = pcall(function() return P.Events.Stats('CHAT_MSG_MONEY') end)
  Trace.Line(string.format('EVIDENCE chatMoneyRegistered=%s %s', tostring(okS and st and st.registered), groupText()))
  local okL, stl = pcall(function() return P.Events.Stats('CHAT_MSG_LOOT') end)
  Trace.Line(string.format('EVIDENCE chatLootRegistered=%s', tostring(okL and stl and stl.registered)))
end

function Trace.End()
  if not t0 then return end
  Trace.Line('INTERVAL end')
  t0, prev = nil, nil
  GI.Sources.tap = nil
  if P.LootModule then P.LootModule.tap = nil end
  if P.ChatModule then P.ChatModule.tap = nil; P.ChatModule.lootTap = nil end
  if GI.ItemSources then GI.ItemSources.tap = nil end
end

function Trace.Lines(n)
  local c = char()
  local L = c and c.trace and c.trace.lines or {}
  n = math.max(1, math.min(tonumber(n) or 40, Trace.CAP))
  local out = {}
  for i = math.max(1, #L - n + 1), #L do out[#out + 1] = L[i] end
  return out
end

--- A free-text marker from the player (what the next lines are about).
function Trace.Note(text)
  if not t0 then return false end
  Trace.Line('NOTE ' .. tostring(text):sub(1, 120))
  return true
end

function Trace.Clear()
  local c = char()
  if c then c.trace = { lines = {} } end
end

function Trace.Switch(v)
  on = v and true or false
end
