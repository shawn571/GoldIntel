-- GoldIntel / Platform / Chat.lua                       (Phase 3b-2, 0.3.5 evidence, 0.3.6 chat-signal rule)
--
-- PURPOSE
--  The client prints a chat line for money: when you loot coin, and (in Classic) when a group
--  splits coin ("Your share of the loot is ..."). If CHAT_MSG_MONEY reaches the addon with readable text, it may
--  give an exact signal for group shares, also for members who get no loot window. This module records the raw
--  text and when it arrived; it emits nothing and classifies nothing. Ledger/Trace.lua prints the facts.
--
-- QUESTIONS THIS ANSWERS (user list, 2026-10-18): does the event exist and reach the addon; exact English text;
--  does it fire for the looter; for non-looters; does it hold the exact amount; before or after PLAYER_MONEY.
--
-- 3b-2 M5 (user approval 2026-10-18, evidence E-48/E-49): the module now also EMITS P_LOOT_CHAT { copper, kind, group }
-- for the two lines that report coin the local player received from a corpse or object:
--   kind 'self'   YOU_LOOT_MONEY        "You loot 2 Copper"
--   kind 'share'  LOOT_MONEY_SPLIT      "Your share of the loot is 6 Copper."
-- It uses the client's own GlobalStrings when present (English fallback). The amount must be the WHOLE rest of the
-- line (money words only); anything else (guild-bank text, other players' loot, unreadable text) emits nothing.
-- Sources.lua turns the event into an exact expectation. This module classifies nothing.
--
-- Chat.ParseMoney(text) -> copper | nil reads "1 Gold 3 Silver 5 Copper" style amounts (the client's own
-- GOLD_AMOUNT / SILVER_AMOUNT / COPPER_AMOUNT strings when present, English words otherwise). Evidence only.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Chat.lua')

local Chat = {}
P.ChatModule = Chat
P.Register('Chat', Chat)

Chat.stats = { seen = 0, text = 0, secret = 0, nonString = 0, emitted = 0, ignored = 0 }
Chat.RING = 20
local recent = {}

local function formatToPattern(fmt, fallback)
  if type(fmt) ~= 'string' or fmt == '' then return fallback end
  local pat = fmt:gsub('([%^%$%(%)%.%[%]%*%+%-%?])', '%%%1')
  pat = pat:gsub('%%%%d', '(%%d+)'):gsub('%%d', '(%%d+)'):gsub('%%1%$d', '(%%d+)')
  if not pat:find('(%d+)', 1, true) then return fallback end
  return pat
end

--- Copper in a message, or nil. Evidence helper, never used for the ledger.
function Chat.ParseMoney(text)
  if type(text) ~= 'string' then return nil end
  local env = P.env or {}
  local gold = formatToPattern(env.GOLD_AMOUNT, '(%d+) Gold')
  local silver = formatToPattern(env.SILVER_AMOUNT, '(%d+) Silver')
  local copper = formatToPattern(env.COPPER_AMOUNT, '(%d+) Copper')
  local g, s, c = tonumber(text:match(gold)), tonumber(text:match(silver)), tonumber(text:match(copper))
  if not (g or s or c) then return nil end
  return (g or 0) * 10000 + (s or 0) * 100 + (c or 0)
end

local function fmtToAnchored(fmt, fallback)
  if type(fmt) ~= 'string' or not fmt:find('%s', 1, true) then return fallback end
  local a, b = fmt:match('^(.-)%%s(.*)$')
  if not a or b:find('%', 1, true) then return fallback end          -- more than one argument: not the plain shape
  local function esc(x) return (x:gsub('([%^%$%(%)%.%[%]%*%+%-%?%%])', '%%%1')) end
  return '^' .. esc(a) .. '(.-)' .. esc(b) .. '$'
end

--- The copper in a string that holds NOTHING but money words, else nil. (Guild-bank and other text is refused.)
function Chat.ParseExact(rest)
  if type(rest) ~= 'string' then return nil end
  local copper = Chat.ParseMoney(rest)
  if not copper or copper <= 0 then return nil end
  local env = P.env or {}
  local left = rest
  for _, pat in ipairs({ formatToPattern(env.GOLD_AMOUNT, '(%d+) Gold'), formatToPattern(env.SILVER_AMOUNT, '(%d+) Silver'),
                         formatToPattern(env.COPPER_AMOUNT, '(%d+) Copper') }) do
    left = left:gsub(pat, '')
  end
  if left:find('[%w]') then return nil end
  return copper
end

--- 'self' | 'share', copper  for a coin chat line the player received, else nil.
function Chat.Classify(text)
  if type(text) ~= 'string' then return nil end
  local env = P.env or {}
  local selfPat = fmtToAnchored(env.YOU_LOOT_MONEY, '^You loot (.-)$')
  local sharePat = fmtToAnchored(env.LOOT_MONEY_SPLIT, '^Your share of the loot is (.-)%.$')
  local rest = text:match(sharePat)
  if rest then local c = Chat.ParseExact(rest); if c then return 'share', c end return nil end
  rest = text:match(selfPat)
  if rest then local c = Chat.ParseExact(rest); if c then return 'self', c end end
  return nil
end

local function groupSize()
  local ok, r = pcall(P.Call, 'GetNumGroupMembers')
  local n = ok and r and r[1]
  if type(n) == 'number' and not P.IsSecret(n) then return n end
end

local function onMoney(_, text)
  Chat.stats.seen = Chat.stats.seen + 1
  local rec = { gt = select(2, P.Now()) }
  if P.IsSecret(text) then
    Chat.stats.secret = Chat.stats.secret + 1
    rec.secret = true
  elseif type(text) ~= 'string' then
    Chat.stats.nonString = Chat.stats.nonString + 1
    rec.nonString = type(text)
  else
    Chat.stats.text = Chat.stats.text + 1
    rec.text = text
    rec.copper = Chat.ParseMoney(text)
  end
  recent[#recent + 1] = rec
  if #recent > Chat.RING then table.remove(recent, 1) end
  if Chat.tap then pcall(Chat.tap, rec) end          -- diagnostic tap (Ledger/Trace.lua)
  if rec.text then
    local kind, copper = Chat.Classify(rec.text)
    if kind then
      Chat.stats.emitted = (Chat.stats.emitted or 0) + 1
      pcall(P.Events.Emit, 'P_LOOT_CHAT', { copper = copper, kind = kind, group = groupSize() })
    else
      Chat.stats.ignored = (Chat.stats.ignored or 0) + 1
    end
  end
end

function Chat.Recent() return recent end
function Chat.Stop() end
function Chat.Reset()
  Chat.stats = { seen = 0, text = 0, secret = 0, nonString = 0, emitted = 0, ignored = 0 }
  recent = {}
  if Chat.ResetLoot then Chat.ResetLoot() end
end

Chat.OnMoney = onMoney

---------------------------------------------------------------------------
-- CHAT_MSG_LOOT: an EVIDENCE RECORDER (D-080 Q-10, user 2026-10-19), with ONE rule since 0.5.3 (D-095, user 2026-11-06):
-- a 'won' line (an item roll the player won) emits P_LOOT_WON { itemID, qty }. Every other kind emits nothing.
-- It answers: does the event reach the addon with readable text, what do the lines look like for items you loot,
-- items pushed to you (quest rewards, mail), group rolls and items other players receive, and how long after the
-- bag settle they arrive. Ledger/Trace.lua prints the facts (CHAT_LOOT lines). A rule needs a separate approval.
---------------------------------------------------------------------------
Chat.LOOT_RING = 40
Chat.lootStats = { seen = 0, text = 0, secret = 0, nonString = 0, self = 0, other = 0 }
local lootRecent = {}

--- kind, itemID, qty for an item chat line. kind: 'loot' | 'lootMulti' | 'pushed' | 'created' | 'won' | 'otherLoot' |
-- 'roll' | 'unknown'. English patterns (the client's own GlobalStrings are recorded raw by the trace, not trusted).
function Chat.ClassifyLoot(text)
  if type(text) ~= 'string' then return 'unknown' end
  local id = tonumber(text:match('item:(%d+)'))
  local qty = tonumber(text:match('x(%d+)%.?$')) or (id and 1 or nil)
  local kind = 'unknown'
  if text:find('^You receive loot:') then kind = text:find('x%d+%.?$') and 'lootMulti' or 'loot'
  elseif text:find('^You receive item:') then kind = 'pushed'
  elseif text:find('^You create:') then kind = 'created'
  elseif text:find('^You won:') or text:find(': You won: ', 1, true) then kind = 'won'   -- live 2026-11-05: the line starts with a loot-history link, '[Loot]: You won: [item]'
  elseif text:find(' receives loot:') or text:find(' receives item:') then kind = 'otherLoot'
  elseif text:find(' won: ') or text:find('Roll') or text:find(' rolled ') or text:find(' passed') then kind = 'roll' end
  return kind, id, qty
end

local function onLoot(_, text)
  local st = Chat.lootStats
  st.seen = st.seen + 1
  local rec = { gt = select(2, P.Now()) }
  if P.IsSecret(text) then
    st.secret = st.secret + 1
    rec.secret = true
  elseif type(text) ~= 'string' then
    st.nonString = st.nonString + 1
    rec.nonString = type(text)
  else
    st.text = st.text + 1
    rec.text = text
    rec.kind, rec.itemID, rec.qty = Chat.ClassifyLoot(text)
    if rec.kind == 'loot' or rec.kind == 'lootMulti' or rec.kind == 'pushed' or rec.kind == 'created' or rec.kind == 'won' then
      st.self = st.self + 1
    else
      st.other = st.other + 1
    end
  end
  lootRecent[#lootRecent + 1] = rec
  if #lootRecent > Chat.LOOT_RING then table.remove(lootRecent, 1) end
  if Chat.lootTap then pcall(Chat.lootTap, rec) end
  if rec.kind == 'won' and type(rec.itemID) == 'number' then        -- D-095
    pcall(P.Events.Emit, 'P_LOOT_WON', { itemID = rec.itemID, qty = rec.qty or 1 })
  end
end

function Chat.LootRecent() return lootRecent end
function Chat.ResetLoot()
  Chat.lootStats = { seen = 0, text = 0, secret = 0, nonString = 0, self = 0, other = 0 }
  lootRecent = {}
end
Chat.OnLoot = onLoot

P.RegisterCollectAdapter({ name = 'ChatLoot', handlers = { CHAT_MSG_LOOT = onLoot } })

P.RegisterCollectAdapter({
  name = 'Chat',
  handlers = { CHAT_MSG_MONEY = onMoney },
  stop = Chat.Stop,
})
