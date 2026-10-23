-- GoldIntel / Future / CommunityDataEngine.lua                          (PLACEHOLDER, Decisions D-015)
--
-- Architecture placeholder only. Nothing here is implemented, persisted or shown.
-- Every function returns { ok = false, err = 'NOT_IMPLEMENTED' }. Implementing it needs an
-- explicit user instruction and a new decision. Out of scope until after v1.

local ADDON, GI = ...
GI = GI or {}
local Core = GI.Core
assert(Core, 'Core/Core.lua must be loaded before Future/CommunityDataEngine.lua')

local function notImplemented() return { ok = false, err = 'NOT_IMPLEMENTED' } end

local Engine = Core.Module('CommunityDataEngine', { stub = true })
Engine.Import = notImplemented
Engine.Export = notImplemented
Engine.Merge = notImplemented
Engine.GuildSync = notImplemented
Engine.ChannelSync = notImplemented
