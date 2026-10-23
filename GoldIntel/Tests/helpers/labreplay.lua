-- GoldIntel / Tests / helpers / labreplay.lua                              (Phase 3b-0, D-069)
--
-- Turns a saved GoldIntelDiag lab file (evidence/*.lua) into a time-ordered stream of normalized
-- records, so Phase 3b tests can replay what the real client actually did instead of inventing
-- timings. Pure Lua, no WoW globals, no GoldIntel code.
--
--   local R = require('labreplay')
--   local lab = R.load(path)                      -- the GoldIntelDiagDB.lab table, or nil, err
--   local tl  = R.timeline(lab)                   -- sorted records
--   record = { gt = number, kind = 'event', name = string, args = number, money = number? }
--          | { gt = number, kind = 'money', balance = number, delta = number? }   -- PLAYER_MONEY reference
--   R.lag(tl, 'TRADE_CLOSED', 1.0)                -- list of signed lags (money.gt - event.gt) of nonzero money moves
--
-- Money deltas come from the difference between consecutive PLAYER_MONEY references; the first
-- reference has no known delta. A zero delta (for example a cancelled trade) is kept but never
-- counts as a money move (D-065).

local R = {}

function R.load(path)
  local f = io.open(path, 'rb')
  if not f then return nil, 'cannot open ' .. tostring(path) end
  local src = f:read('*a')
  f:close()
  local env = {}
  local chunk, err
  if setfenv then
    chunk, err = loadstring(src, path)
    if chunk then setfenv(chunk, env) end
  else
    chunk, err = load(src, path, 't', env)
  end
  if not chunk then return nil, err end
  local ok, runErr = pcall(chunk)
  if not ok then return nil, runErr end
  local db = env.GoldIntelDiagDB
  if type(db) ~= 'table' or type(db.lab) ~= 'table' then return nil, 'no lab table' end
  return db.lab
end

function R.timeline(lab)
  local out = {}
  for _, run in pairs(lab.runs or {}) do
    for name, ev in pairs(run.events or {}) do
      for _, s in ipairs(ev.samples or {}) do
        if type(s.gt) == 'number' then
          out[#out + 1] = { gt = s.gt, kind = 'event', name = name, args = s.n or 0, money = s.money }
        end
      end
    end
  end
  local refs = {}
  for _, r in ipairs(lab.refs or {}) do
    if type(r.gt) == 'number' and type(r.money) == 'number' then refs[#refs + 1] = r end
  end
  table.sort(refs, function(a, b) return a.gt < b.gt end)
  local prev
  for _, r in ipairs(refs) do
    local delta = prev and (r.money - prev) or nil
    out[#out + 1] = { gt = r.gt, kind = 'money', balance = r.money, delta = delta }
    prev = r.money
  end
  table.sort(out, function(a, b)
    if a.gt ~= b.gt then return a.gt < b.gt end
    return a.kind < b.kind
  end)
  return out
end

--- For every event called `name`, the signed lag (money.gt - event.gt) to the nearest nonzero money
-- move, looking forward up to `window` seconds first and then back up to `before` seconds (default 0.5).
-- Events without such a move are skipped.
function R.lag(tl, name, window, before)
  before = before or 0.5
  local lags = {}
  for i, rec in ipairs(tl) do
    if rec.kind == 'event' and rec.name == name then
      local found
      for j = i + 1, #tl do
        if tl[j].gt - rec.gt > window then break end
        local m = tl[j]
        if m.kind == 'money' and m.delta and m.delta ~= 0 then found = m.gt - rec.gt; break end
      end
      if not found then
        for j = i - 1, 1, -1 do
          if rec.gt - tl[j].gt > before then break end
          local m = tl[j]
          if m.kind == 'money' and m.delta and m.delta ~= 0 then found = m.gt - rec.gt; break end
        end
      end
      if found then lags[#lags + 1] = found end
    end
  end
  return lags
end

return R
