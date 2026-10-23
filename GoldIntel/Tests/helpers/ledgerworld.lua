--[[
GoldIntel / Tests / helpers / ledgerworld.lua                         (Phase 3b-2 M2)

A booted world with collect ON and the Sources interval begun, plus small drivers for the signals the Sources
translate. Entries are read from Sources.Entries(). Nothing here invents timing: callers pass explicit lags.
]]

local World = require('collectworld')

local L = {}

function L.boot(opts)
  opts = opts or {}
  local W, P, ns = World.boot()
  ns.Collector.On({}); ns.Ledger.End()      -- collect on starts the ledger interval; these tests start Sources by hand
  W.state.money = 100000; W:fire('PLAYER_MONEY')     -- a balance that can go down; before Begin so it is not recorded
  W:advance(1.0)                         -- a first tick so the location stamp exists (unless opts.noTick)
  if opts.noTick then ns.Sources.Begin() else ns.Sources.Begin() ; W:advance(0.6) end
  return W, P, ns
end

function L.pay(W, delta)
  W.state.money = W.state.money + delta
  W:fire('PLAYER_MONEY')
end

function L.mailHeader(t) return World.header(t) end

function L.moneyMail(money, subject, sender)
  return { header = World.header({ icon = nil, sender = sender or 'Rehgar Deadeye', subject = subject or 'for you', money = money }) }
end

function L.codMail(cod, subject)
  return { header = World.header({ icon = 1, sender = 'Dottie Slaps', subject = subject or 'Spider Ichor (4)',
                                    money = 0, cod = cod, itemCount = 1, firstQty = 4 }) }
end

function L.saleMail(price, deposit, cut)
  return {
    header = World.header({ icon = 1, sender = 'Horde Auction House', subject = 'Auction successful: Spider Ichor (4)',
                            money = price + deposit - cut, canReply = false, textCreated = true }),
    invoice = { 'seller', 'Spider Ichor', 'Buyer', price, 0, deposit, cut },
  }
end

--- Sets the inbox and delivers MAIL_INBOX_UPDATE with the mailbox shown.
function L.inbox(W, mails)
  W.state.inbox = mails
  W.state.mailShown = true
  W:fire('MAIL_INBOX_UPDATE')
end

function L.bySrc(entries)
  local out = {}
  for _, e in ipairs(entries) do out[e.src] = (out[e.src] or 0) + e.copper end
  return out
end

function L.sum(entries)
  local s = 0
  for _, e in ipairs(entries) do s = s + e.copper end
  return s
end

return L
