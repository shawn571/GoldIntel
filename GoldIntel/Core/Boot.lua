-- GoldIntel / Core / Boot.lua                                           (Phase 2)
--
-- The LAST file in the TOC. It schedules Core.Start for PLAYER_LOGIN (or runs it at once when
-- the addon was loaded after login), so every module and service is registered before
-- anything starts and Platform/Probe has already persisted its capability data.

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
local Core = GI.Core
assert(P and Core, 'Platform and Core must be loaded before Core/Boot.lua')

-- /gi works from the moment the files load (minimal command set), so it is available even if
-- the login event were never delivered. Core.Start installs the full command set.
if GI.Commands then GI.Commands.Install(true) end

P.OnReady(function()
  Core.Start()
end)
