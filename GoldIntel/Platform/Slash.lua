-- GoldIntel / Platform / Slash.lua                                      (Phase 2)
--
-- PURPOSE
--   The only place that registers slash commands with the client (SlashCmdList and the
--   SLASH_<KEY>1 global). Core/Slash.lua builds the /gi command set on top of this.
--
--   Platform.RegisterSlash(key, command, handler) -> true | nil, err
--     key     : uppercase identifier, e.g. 'GOLDINTEL'
--     command : the typed command, e.g. '/gi'
--     handler : function(message)  (errors are caught and reported as diagnostics)
--
-- Re-registering the same key replaces the handler (used by tests and /reload-safe boot).

local ADDON, GI = ...
GI = GI or {}
local P = GI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Slash.lua')

local Slash = {}
P.Slash = Slash
P.Register('Slash', Slash)

function Slash.Register(key, command, handler)
  if type(key) ~= 'string' or not key:match('^[A-Z0-9_]+$') then
    return nil, 'key must be an uppercase identifier'
  end
  if type(command) ~= 'string' or command:sub(1, 1) ~= '/' or #command < 2 then
    return nil, 'command must start with /'
  end
  if type(handler) ~= 'function' then return nil, 'handler must be a function' end
  local list = P.env.SlashCmdList
  if type(list) ~= 'table' then
    list = {}
    P.env.SlashCmdList = list
  end
  P.env['SLASH_' .. key .. '1'] = command
  list[key] = function(message)
    local ok, err = pcall(handler, message)
    if not ok then P.Diag('error', 'Slash', command .. ' handler failed: ' .. tostring(err)) end
  end
  return true
end

P.RegisterSlash = Slash.Register
