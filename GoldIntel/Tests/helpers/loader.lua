--[[
GoldIntel / Tests / helpers / loader.lua

Loads addon files exactly like the WoW client does: each chunk is called with the
addon name and a shared private table (`local ADDON, GI = ...`). The file list comes
from GoldIntel.toc so tests and the real load order can never drift apart.
]]

local Loader = {}

Loader.root = '.'

--- Called once by Tests/run.lua.
function Loader.setRoot(root) Loader.root = root end

local function readFile(path)
  local f = assert(io.open(path, 'rb'))
  local s = f:read('*a')
  f:close()
  return s
end
Loader.readFile = readFile

--- Returns the ordered list of files named in GoldIntel.toc (forward slashes).
function Loader.tocFiles()
  local files = {}
  local text = readFile(Loader.root .. '/GoldIntel.toc')
  for line in (text .. '\n'):gmatch('(.-)\r?\n') do
    line = line:match('^%s*(.-)%s*$')
    if line ~= '' and line:sub(1, 1) ~= '#' then
      files[#files + 1] = (line:gsub('\\', '/'))
    end
  end
  return files
end

--- Loads addon files against a fake environment.
-- opts.only  : array of file paths to load instead of the whole TOC
-- opts.upTo  : load the TOC files up to and including this path
-- Returns the Platform table and the shared namespace.
function Loader.load(env, opts)
  opts = opts or {}
  local ns = { Platform = { env = env } }
  local files = opts.only or Loader.tocFiles()
  for _, path in ipairs(files) do
    local chunk, err
    if Loader.override and Loader.override[path] then            -- mutation tests: replacement source text
      chunk, err = (loadstring or load)(Loader.override[path], '=' .. path)
    else
      chunk, err = loadfile(Loader.root .. '/' .. path)
    end
    if not chunk then error('cannot load ' .. path .. ': ' .. tostring(err), 2) end
    chunk('GoldIntel', ns)
    if opts.upTo and path == opts.upTo then break end
  end
  return ns.Platform, ns
end

--- Convenience for tests: builds a fake client and loads the addon into it.
-- fakeOpts goes to Fake.new, loadOpts to Loader.load. Returns W, P, ns.
function Loader.boot(fakeOpts, loadOpts)
  local Fake = require('fake_wow')
  local W = Fake.new(fakeOpts)
  local P, ns = Loader.load(W.env, loadOpts)
  return W, P, ns
end

return Loader
