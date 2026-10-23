-- GoldIntel / Platform / Mail.lua                                       (Phase 3b-1)
--
-- Mailbox adapter.
--   * Window state by polling MailFrame:IsShown() every 0.5 s while collecting (MAIL_CLOSED is NEVER
--     delivered, E-34; MAIL_SHOW is unverified and not used): P_MAIL_OPEN / P_MAIL_CLOSE.
--   * MAIL_INBOX_UPDATE -> a fresh header snapshot (only while the mailbox is shown; headers read with
--     the box closed are a stale cache, E-29) and P_MAIL_UPDATE { count }.
--   * Mail.Snapshot() / Mail.Previous(): the newest snapshot and the one BEFORE it, so 3b-2 can read
--     what a mail carried before it was taken (the mail disappears on take, E-34/E-39).
--
-- HEADER FIELDS (E-29, E-39): GetInboxHeaderInfo(i) = package icon, stationery, sender, subject, money,
-- COD amount, days left, item count (nil when none), was read, was returned, text created, can reply,
-- is GM, first item quantity, first item link. GetInboxInvoiceInfo(i) = type ('seller' | 'buyer' | nil),
-- item name, player, price, ?, deposit, house cut (E-34: 51 | 1 | 100 | 2 for a sale of 51).
-- Index 1 is the newest mail, so the index is not an identity: a fingerprint is stored instead.
--
-- Nothing here takes, deletes or marks mail; it only reads.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Mail.lua')

local Mail = {}
P.MailModule = Mail
P.Register('Mail', Mail)

Mail.POLL = 0.5
Mail.MAX_MAILS = 50

local open = false
local snapshot, previous = nil, nil
local cancelPoll = nil
Mail.stats = { opened = 0, closed = 0, updates = 0, staleUpdates = 0, snapshots = 0, unreadable = 0 }

local function clean(v)
  if P.IsSecret(v) then return nil end
  return v
end

local function str(v)
  v = clean(v)
  if type(v) == 'string' then return v end
  return nil
end

local function num(v)
  v = clean(v)
  if type(v) == 'number' and v == v then return v end
  return nil
end

--- True when MailFrame is shown; nil when the frame does not exist.
function Mail.FrameShown()
  local frame = P.env.MailFrame
  if type(frame) ~= 'table' or type(frame.IsShown) ~= 'function' then return nil end
  local ok, shown = pcall(frame.IsShown, frame)
  if not ok then return nil end
  return shown and true or false
end

local function readOne(i)
  local h = P.Call('GetInboxHeaderInfo', i)
  if not h then return nil end
  local entry = {
    index = i,
    sender = str(h[3]) or '', subject = str(h[4]) or '',
    money = num(h[5]) or 0, cod = num(h[6]) or 0,
    daysLeft = num(h[7]),
    itemCount = num(h[8]) or 0,
    textCreated = clean(h[11]) == true, canReply = clean(h[12]) == true,
    firstQty = num(h[14]), firstLink = str(h[15]),
  }
  entry.firstItemID = entry.firstLink and tonumber(entry.firstLink:match('item:(%d+)')) or nil
  local inv = P.Call('GetInboxInvoiceInfo', i)
  if inv and str(inv[1]) then
    entry.invoice = { kind = str(inv[1]), item = str(inv[2]), player = str(inv[3]),
                      price = num(inv[4]) or 0, deposit = num(inv[6]) or 0, cut = num(inv[7]) or 0 }
  end
  -- Auction House mail: separable from player mail by an invoice or by canReply=false with a text (E-29)
  entry.kind = (entry.invoice or (not entry.canReply and entry.textCreated)) and 'auction' or 'player'
  entry.fingerprint = table.concat({ entry.sender, entry.subject, entry.money, entry.cod, entry.itemCount,
                                     entry.firstItemID or 0, entry.firstQty or 0 }, '|')
  return entry
end

--- Reads every header (up to MAX_MAILS). Returns { count, mails = {...}, gt } or nil plus a reason.
function Mail.Read()
  local n = P.Call('GetInboxNumItems')
  local count = n and num(n[1]) or nil
  if not count then return nil, 'GetInboxNumItems unavailable' end
  local mails = {}
  for i = 1, math.min(count, Mail.MAX_MAILS) do
    local entry = readOne(i)
    if entry then mails[#mails + 1] = entry else Mail.stats.unreadable = Mail.stats.unreadable + 1 end
  end
  local _, gt = P.Now()
  return { count = count, mails = mails, gt = gt }
end

function Mail.Snapshot() return snapshot end
function Mail.Previous() return previous end
function Mail.IsOpen() return open end

local function setOpen(now)
  if now == open then return end
  open = now
  if now then
    Mail.stats.opened = Mail.stats.opened + 1
    P.Events.Emit('P_MAIL_OPEN', {})
  else
    Mail.stats.closed = Mail.stats.closed + 1
    P.Events.Emit('P_MAIL_CLOSE', {})
  end
end

--- One poll step (also called by tests).
function Mail.Tick()
  local shown = Mail.FrameShown()
  if shown == nil then return end
  setOpen(shown)
end

local function onUpdate()
  Mail.stats.updates = Mail.stats.updates + 1
  if Mail.FrameShown() ~= true then
    Mail.stats.staleUpdates = Mail.stats.staleUpdates + 1      -- cached view, not trusted (E-29)
    return 'dropped'
  end
  setOpen(true)
  local snap, err = Mail.Read()
  if not snap then
    P.Diag('warn', 'Mail', 'inbox unreadable: ' .. tostring(err))
    return 'dropped'
  end
  previous = snapshot
  snapshot = snap
  Mail.stats.snapshots = Mail.stats.snapshots + 1
  P.Events.Emit('P_MAIL_UPDATE', { count = snap.count })
end

function Mail.Start()
  if cancelPoll then cancelPoll() end
  cancelPoll = P.Every(Mail.POLL, Mail.Tick)
end

function Mail.Stop()
  if cancelPoll then cancelPoll(); cancelPoll = nil end
  open = false
end

function Mail.Reset()
  Mail.Stop()
  snapshot, previous = nil, nil
  Mail.stats = { opened = 0, closed = 0, updates = 0, staleUpdates = 0, snapshots = 0, unreadable = 0 }
end

Mail.OnUpdate = onUpdate

P.RegisterCollectAdapter({
  name = 'Mail',
  handlers = { MAIL_INBOX_UPDATE = function() return onUpdate() end },
  start = Mail.Start, stop = Mail.Stop,
})
