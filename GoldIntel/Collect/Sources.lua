-- GoldIntel / Collect / Sources.lua                                (Phase 3b-2 M2, Architecture AC-10)
--
-- PURPOSE
--  The ONLY module that knows what a normalized Platform event means for money. It turns P_* events and
--  context changes into expectations (Expectations.lua) and feeds P_MONEY deltas to the Reconciler.
--  Expectations, Reconciler and Stamps stay source-agnostic.
--
--      Sources.Begin()      starts an interval (collect on): creates the store, Reconciler, Stamps; subscribes
--      Sources.End()        ends it: pending deltas become OTHER, expectations are cleared, ticker stopped
--      Sources.IsActive()   Sources.Stats()   Sources.Entries()   Sources.SetSink(fn)
--
-- Sources in 3b-2 (option A, D-077 Q-1):
--   loot coin   P_LOOT_MONEY      exact, held while the loot context is open, then LOOT_LINGER (2.0 s)   src loot
--   coin chat   P_LOOT_CHAT       (M5, E-48/E-49) the client's own "You loot N" / "Your share of the loot is N" line
--                                 is an EXACT loot expectation of N, whether or not a loot window was opened here.
--                                 It arrives 0.5-1.0 s AFTER the money change, so pending deltas wait WAIT (2.0 s).
--                                 Already explained by an earlier entry -> claimed, nothing added. Already written
--                                 as OTHER -> counted as late, nothing added (no retroactive edits).
--                                 A split share also consumes the loot window expectation it came from, only when
--                                 N is floor or ceil of window coin / k for some k from 2 to the group size
--                                 (the coin is split among the members in range; exact, no guessing).
--   quest       P_QUEST_DONE      exact, ttl 1.0 s                                           src quest
--   mail money  P_MAIL_UPDATE     exact, one per money mail that left the inbox (diff of Mail.Previous/Snapshot)
--                                 COD payment mail -> codIn; seller invoice that adds up -> ahSale/ahCut/
--                                 ahDepositRefund components; any other money mail -> mailMoney
--   vendor      vendor context    window: + -> vendor, - -> purchase
--   trade       trade context     window: + and - -> trade
--  NOT sources yet (stay OTHER until 3b-4): AH deposit, AH buyout and bid, COD paid, postage.
--
-- Mail diff (E-28, E-34, E-39, E-40): the first update after the mailbox opened is only a baseline. After that, a
-- money mail (key sender|subject|money|cod) that is in the previous snapshot but not in the current one means its
-- money was taken (or it was deleted, returned or expired: that expectation simply expires unmatched, R-3b2-5).
-- Taking only the items of a mail that also holds money keeps its key, so it creates nothing. COD mails
-- (cod > 0) create nothing: COD paid is out of scope.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P and GI.Expectations and GI.Reconciler and GI.Stamps, 'Expectations, Reconciler and Stamps must be loaded first')

local Sources = {}
GI.Sources = Sources

Sources.TICK = 0.25
Sources.LINGER = 1.0
Sources.LOOT_LINGER = 2.0    -- a loot window expectation outlives the window by this long (the chat line arrives late)
Sources.WAIT = 2.0           -- pending money waits this long for the chat line before it becomes OTHER
Sources.CHAT_LOOK = 3.0      -- a chat line looks this far back for an entry that already explains it
Sources.ENTRY_CAP = 500
Sources.COD_PREFIX = 'COD Payment:'      -- English client only (R-3b2-4); other locales fall back to mailMoney

local X, R, S                -- the live instances (nil when no interval)
local active = false
local cancelTick
local held = {}              -- loot expectations held open while the loot context is open
local windows = {}           -- context kind -> { ids }
local needBaseline = true    -- the next mail update after the mailbox opened is a baseline only
local entries = {}
local sink
local c

local function freshCounters()
  c = { chatLines = 0, chatClaimed = 0, chatLate = 0, chatCovered = 0, chatSplit = 0, chatExp = 0, lootExp = 0, questExp = 0, mailExp = 0, mailVanished = 0, mailBaselines = 0, mailSkippedCod = 0,
        windowsOpened = 0, ticks = 0, handlerErrors = 0 }
end
freshCounters()

local function nowGT()
  local _, gt = P.Now()
  return gt
end

--- Diagnostic tap (Ledger/Trace.lua): Sources.tap(kind, ...) with kind 'money' | 'entry' | 'exp'. Never changes behaviour.
local function tapped(...)
  if Sources.tap then pcall(Sources.tap, ...) end
end

local recent = {}        -- recent loot/other entries a chat line may already be explained by: { gt, e, claimed }

local function record(e)                  -- the recent-entries ring (diagnostics, tests); the sink gets every entry too
  tapped('entry', e)
  if e.src == 'loot' or (e.src == 'other' and e.comp ~= 'gap') then
    recent[#recent + 1] = { gt = nowGT(), e = e, claimed = (e.ref and e.ref.chat) == true }
    if #recent > 40 then table.remove(recent, 1) end
  end
  entries[#entries + 1] = e
  if #entries > Sources.ENTRY_CAP then table.remove(entries, 1) end
end

--- Optional second consumer of finished entries (Ledger.lua: the Cash store). nil removes it.
function Sources.SetSink(fn) sink = fn end
function Sources.Entries() return entries end
function Sources.IsActive() return active end
function Sources.Reconciler() return R end
function Sources.Expectations() return X end
function Sources.Stamps() return S end

local function add(spec)
  local id, err = X:Add(spec)
  if not id then P.Diag('warn', 'Sources', 'expectation refused: ' .. tostring(err)) end
  return id
end

---------------------------------------------------------------------------
-- Translators
---------------------------------------------------------------------------

local function onLootMoney(p)
  if not active or type(p.copper) ~= 'number' or p.copper <= 0 then return end
  local id = add({ src = 'loot', mode = 'exact', copper = p.copper, sign = 1, t0 = nowGT(), ttl = Sources.LOOT_LINGER,
    ctx = 'loot', ref = { sourceType = p.source }, hold = true })
  if id then held[#held + 1] = id; c.lootExp = c.lootExp + 1 end
end

--- The coin chat line (P_LOOT_CHAT). See the header. Pure decisions on exact amounts; no guessing.
local function onLootChat(p)
  if not active or type(p.copper) ~= 'number' or p.copper <= 0 then return end
  local n, gt = p.copper, nowGT()
  c.chatLines = c.chatLines + 1
  for i = #recent, 1, -1 do                                  -- 1) an entry already explains this coin
    local r = recent[i]
    if gt - r.gt <= Sources.CHAT_LOOK and not r.claimed and r.e.copper == n then
      if r.e.src == 'loot' then
        r.claimed = true; c.chatClaimed = c.chatClaimed + 1
        tapped('chat', 'claimed', p, r.e)
        return
      end
    end
  end
  for i = #recent, 1, -1 do                                  -- 2) it was already written as OTHER: too late, no edits
    local r = recent[i]
    if gt - r.gt <= Sources.CHAT_LOOK and not r.claimed and r.e.src == 'other' and r.e.copper == n then
      r.claimed = true; c.chatLate = c.chatLate + 1
      tapped('chat', 'late', p, r.e)
      return
    end
  end
  local best, covered                                        -- 3) look at the loot window expectations
  for _, e in ipairs(X:Active(gt, 1, 'exact')) do
    if e.src == 'loot' and not (e.ref and e.ref.chat) then
      if e.copper == n then covered = e end
      if p.kind == 'share' and type(p.group) == 'number' and p.group >= 2 and e.copper > n then
        -- the coin is split among the members who qualify (in range, or everyone in an instance): any count from
        -- 2 up to the group size is possible, so N must be floor or ceil of coin / k for some k in that range
        local fits = false
        for k = 2, p.group do
          if n == math.floor(e.copper / k) or n == math.ceil(e.copper / k) then fits = true; break end
        end
        if fits and (not best or e.copper < best.copper) then best = e end
      end
    end
  end
  if covered then                                            -- the window itself offers exactly N: it will match
    c.chatCovered = c.chatCovered + 1
    tapped('chat', 'covered', p, covered)
    return
  end
  local ref = { chat = true }
  if best then ref.sourceType = best.ref and best.ref.sourceType; X:Consume(best.id); c.chatSplit = c.chatSplit + 1 end
  local id = add({ src = 'loot', mode = 'exact', copper = n, sign = 1, t0 = gt, ttl = Sources.LINGER, ctx = 'loot',
    ref = ref, comp = p.kind == 'share' and 'split' or nil })
  if id then c.chatExp = c.chatExp + 1 end
  tapped('chat', best and 'split' or 'expect', p, best, id)
end

local function releaseHeld(gt)
  for _, id in ipairs(held) do X:Close(id, gt) end
  held = {}
end

local function onQuest(p)
  if not active or type(p.copper) ~= 'number' or p.copper <= 0 then return end
  if add({ src = 'quest', mode = 'exact', copper = p.copper, sign = 1, t0 = nowGT(), ttl = Sources.LINGER, ctx = 'quest' }) then
    c.questExp = c.questExp + 1
  end
end

local WINDOWS = {
  vendor = { { src = 'vendor', sign = 1 }, { src = 'purchase', sign = -1 } },
  trade = { { src = 'trade', sign = 1 }, { src = 'trade', sign = -1 } },
}

local function onContext(p)
  if not active then return end
  local gt = nowGT()
  if p.kind == 'loot' then
    if not p.open then releaseHeld(gt) end
    return
  end
  local w = WINDOWS[p.kind]
  if not w then return end
  if p.open then
    local ids = {}
    for _, def in ipairs(w) do
      ids[#ids + 1] = add({ src = def.src, mode = 'window', sign = def.sign, t0 = gt, ttl = Sources.LINGER, ctx = p.kind })
    end
    windows[p.kind] = ids
    c.windowsOpened = c.windowsOpened + 1
  else
    for _, id in ipairs(windows[p.kind] or {}) do X:Close(id, gt) end
    windows[p.kind] = nil
  end
end

-- mail --------------------------------------------------------------------

local function key(m) return table.concat({ m.sender or '', m.subject or '', m.money or 0, m.cod or 0 }, '|') end

local function count(snap)
  local t, rep = {}, {}
  for _, m in ipairs(snap and snap.mails or {}) do
    local k = key(m)
    t[k] = (t[k] or 0) + 1
    rep[k] = rep[k] or m
  end
  return t, rep
end

--- Builds the expectation spec for one vanished money mail (pure, exposed for tests).
function Sources.MailSpec(m, t0)
  if (m.cod or 0) > 0 or (m.money or 0) <= 0 then return nil end
  local spec = { mode = 'exact', copper = m.money, sign = 1, t0 = t0, ttl = Sources.LINGER, ctx = 'mail' }
  local inv = m.invoice
  if inv and inv.price + inv.deposit - inv.cut == m.money then
    local comps = {}
    if inv.price ~= 0 then comps[#comps + 1] = { src = 'ahSale', copper = inv.price, settle = true } end
    if inv.cut ~= 0 then comps[#comps + 1] = { src = 'ahCut', copper = -inv.cut } end
    if inv.deposit ~= 0 then comps[#comps + 1] = { src = 'ahDepositRefund', copper = inv.deposit, comp = 'deposit' } end
    if #comps > 0 then
      spec.src, spec.comps = 'ahSale', comps
      return spec
    end
  end
  if (m.subject or ''):sub(1, #Sources.COD_PREFIX) == Sources.COD_PREFIX then
    spec.src, spec.settle = 'codIn', true
  else
    spec.src, spec.settle = 'mailMoney', true
  end
  return spec
end

local function onMailOpen() needBaseline = true end

local function onMailUpdate()
  if not active then return end
  local Mail = P.MailModule
  if not Mail then return end
  if needBaseline then
    needBaseline = false
    c.mailBaselines = c.mailBaselines + 1
    return
  end
  local prevN, prevRep = count(Mail.Previous())
  local curN = count(Mail.Snapshot())
  local gt = nowGT()
  for k, n in pairs(prevN) do
    local gone = n - (curN[k] or 0)
    for _ = 1, gone do
      c.mailVanished = c.mailVanished + 1
      local spec = Sources.MailSpec(prevRep[k], gt)
      if spec then
        if add(spec) then c.mailExp = c.mailExp + 1 end
      else
        c.mailSkippedCod = c.mailSkippedCod + 1
      end
    end
  end
end

---------------------------------------------------------------------------
-- Stamps feed, money feed, ticker
---------------------------------------------------------------------------

local function onTick(p)
  if active and S and p.loc then S:NoteLoc(p.loc, nowGT()) end
end

local function onMoney(p)
  if not active then return end
  tapped('money', p)
  R:Money(p.copper, p.gt or nowGT(), p.gap == true)
end

local function tick()
  if not active then return end
  c.ticks = c.ticks + 1
  local gt = nowGT()
  -- safety net: a held loot expectation whose loot context is gone is released now
  if #held > 0 and GI.Context and not GI.Context.IsActive('loot') then releaseHeld(gt) end
  R:Tick(gt)
end

local function guard(fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then
      c.handlerErrors = c.handlerErrors + 1
      P.Diag('error', 'Sources', tostring(err))
    end
  end
end

local wired = false
local function wire()
  if wired then return end
  wired = true
  P.On('P_LOOT_MONEY', guard(onLootMoney))
  P.On('P_LOOT_CHAT', guard(onLootChat))
  P.On('P_QUEST_DONE', guard(onQuest))
  P.On('P_MAIL_OPEN', guard(onMailOpen))
  P.On('P_MAIL_UPDATE', guard(onMailUpdate))
  P.On('P_MONEY', guard(onMoney))
  P.On('P_TICK', guard(onTick))
  P.On('P_ZONE', guard(function(p) if active and S and p.loc then S:NoteLoc(p.loc, nowGT()) end end))
  if GI.Bus then GI.Bus.On('CONTEXT_CHANGED', guard(onContext)) end
end

function Sources.Begin()
  wire()
  if active then return false end
  X = GI.Expectations.New()
  X.tap = function(ev, e, gt) tapped('exp', ev, e, gt) end
  S = GI.Stamps.New{ lastCast = P.LastCast }
  recent = {}
  R = GI.Reconciler.New{ exp = X, wait = Sources.WAIT, sink = function(e) record(e); if sink then sink(e) end end, decorate = function(e) S:Apply(e) end }
  held, windows = {}, {}
  needBaseline = true
  freshCounters()
  entries = {}
  local gt = nowGT()
  active = true
  R:Begin(gt)
  -- contexts that are already open when the interval starts get their windows (collect on inside a window)
  if GI.Context then
    for _, k in ipairs(GI.Context.Active()) do
      if k.open then onContext({ kind = k.kind, open = true }) end
    end
  end
  cancelTick = P.Every(Sources.TICK, tick)
  return true
end

function Sources.End()
  if not active then return false end
  if cancelTick then cancelTick(); cancelTick = nil end
  R:End(nowGT())
  active = false
  held, windows = {}, {}
  return true
end

--- Reconciler statistics plus this module's counters. Nil when no interval has run.
function Sources.Stats()
  if not R then return nil end
  local s = R:Stats()
  s.sources = {}
  for k, v in pairs(c) do s.sources[k] = v end
  s.active = active
  return s
end
