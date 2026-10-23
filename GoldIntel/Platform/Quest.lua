-- GoldIntel / Platform / Quest.lua                                      (Phase 3b-1)
--
-- Quest turn-in adapter: QUEST_TURNED_IN(questID, xp, money) -> P_QUEST_DONE { questID, copper }.
-- E-22: all three arguments are non-secret numbers; the money argument equals the following
-- PLAYER_MONEY delta exactly (0.041 s later). The argument is an EXPECTATION for the ledger, never
-- a ledger amount (principle 1). Secret or non-numeric arguments are dropped and counted.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Quest.lua')

local Quest = {}
P.QuestModule = Quest
P.Register('Quest', Quest)

Quest.stats = { turnedIn = 0, unreadable = 0 }

local function onTurnedIn(_, questID, _xp, money)
  local function ok(v) return type(v) == 'number' and not P.IsSecret(v) and v == v end
  if not ok(questID) or not ok(money) or money < 0 then
    Quest.stats.unreadable = Quest.stats.unreadable + 1
    return 'dropped'
  end
  Quest.stats.turnedIn = Quest.stats.turnedIn + 1
  P.Events.Emit('P_QUEST_DONE', { questID = math.floor(questID), copper = math.floor(money) })
end

Quest.OnTurnedIn = onTurnedIn
function Quest.Reset() Quest.stats = { turnedIn = 0, unreadable = 0 } end

P.RegisterCollectAdapter({ name = 'Quest', handlers = { QUEST_TURNED_IN = onTurnedIn } })
