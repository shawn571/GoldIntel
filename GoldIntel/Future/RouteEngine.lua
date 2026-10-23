-- GoldIntel / Future / RouteEngine.lua                                  (PLACEHOLDER, Decisions D-015)
--
-- Architecture placeholder only. Nothing here is implemented, persisted or shown.
-- Every function returns { ok = false, err = 'NOT_IMPLEMENTED' }. Implementing it needs an
-- explicit user instruction and a new decision. Out of scope until after v1.

local ADDON, GI = ...
GI = GI or {}
local Core = GI.Core
assert(Core, 'Core/Core.lua must be loaded before Future/RouteEngine.lua')

local function notImplemented() return { ok = false, err = 'NOT_IMPLEMENTED' } end

local Engine = Core.Module('RouteEngine', { stub = true })
Engine.Record = notImplemented
Engine.Analyze = notImplemented
Engine.Discover = notImplemented
Engine.Rank = notImplemented
