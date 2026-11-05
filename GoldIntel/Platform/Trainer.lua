-- GoldIntel / Platform / Trainer.lua                                    (0.5.2, D-093)
--
-- Trainer window adapter: TRAINER_SHOW -> P_TRAINER_OPEN, TRAINER_CLOSED -> P_TRAINER_CLOSE.
-- Class and profession trainers charge while their window is open; the live data of 2026-11-04 showed every
-- trainer fee as OTHER (5 of 7 OTHER entries, 410 of 447 copper). No amounts are read here: trainer money is
-- matched by sign inside the window (AC-4 window mode), like the vendor.
-- NOT yet verified in the Forever client (user approved building it 2026-11-05): the first trainer visit is the
-- live check. Opens and closes are idempotent and duplicates are counted, as for the vendor (E-33).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Trainer.lua')

local Trainer = {}
P.TrainerModule = Trainer
P.Register('Trainer', Trainer)

local open = false
local function freshStats() return { opened = 0, closed = 0, duplicateCloses = 0, duplicateOpens = 0 } end
Trainer.stats = freshStats()

local function onShow()
  if open then
    Trainer.stats.duplicateOpens = Trainer.stats.duplicateOpens + 1
    return 'dropped'
  end
  open = true
  Trainer.stats.opened = Trainer.stats.opened + 1
  P.Events.Emit('P_TRAINER_OPEN', {})
end

local function onClosed()
  if not open then
    Trainer.stats.duplicateCloses = Trainer.stats.duplicateCloses + 1
    return 'dropped'
  end
  open = false
  Trainer.stats.closed = Trainer.stats.closed + 1
  P.Events.Emit('P_TRAINER_CLOSE', {})
end

function Trainer.IsOpen() return open end
function Trainer.Stop() open = false end
function Trainer.Reset()
  open = false
  Trainer.stats = freshStats()
end

Trainer.OnShow = onShow
Trainer.OnClosed = onClosed

P.RegisterCollectAdapter({
  name = 'Trainer',
  handlers = { TRAINER_SHOW = function() return onShow() end, TRAINER_CLOSED = function() return onClosed() end },
  stop = Trainer.Stop,
})
