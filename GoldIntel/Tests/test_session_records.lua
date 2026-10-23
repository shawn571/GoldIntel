--[[
Tests / test_session_records.lua                          (D-041: current + previous + history + pin)

Runtime session records are DIAGNOSTIC EVIDENCE ONLY. They must stay bounded and must never
touch the real data (compat, profile, meta). Each test plays whole sessions through the
SavedVariables simulator, exactly like a real logout / reload.
]]

local T = require('testlib')
local Fake = require('fake_wow')
local Loader = require('loader')
local sim = require('svsim')

local function fixture()
  return sim.loadFixture(Loader.root .. '/Tests/fixtures/forever_1.60.1_GoldIntelDB.lua', 'GoldIntelDB')
end

-- One play session. `saved.account` is the text the client wrote at the end of the last one.
-- opts.crash = true: no PLAYER_LOGOUT (the saved text is what a persist already put in memory).
local function session(saved, play, opts)
  opts = opts or {}
  local W = Fake.new()
  if saved.account then W.env.GoldIntelDB = sim.parse(saved.account) end
  if saved.character then W.env.GoldIntelCharDB = sim.parse(saved.character) end
  local P, ns = Loader.load(W.env)
  W:login()
  if play then play(W, ns, P) end
  if not opts.crash then W:fire('PLAYER_LOGOUT') end
  return { account = sim.dump(W.env.GoldIntelDB), character = sim.dump(W.env.GoldIntelCharDB) }, W, ns
end

local function marked(n)
  return function(W, ns, P)
    P.Print('marker of session ' .. n)
    W.state.money = 100 * n; W:fire('PLAYER_MONEY')
    W:advance(10)
  end
end

local function db(saved) return sim.parse(saved.account) end

T.describe('session records: rotation', function()
  T.it('the first open has no previous record and no history', function()
    local s1 = session({}, marked(1))
    local d = db(s1)
    T.isnil(d.runtime.previous)
    T.eq(#(d.runtime.history or {}), 0)
    T.truthy(d.runtime.sessionStart)
    T.eq(d.runtime.endedBy, 'logout-or-reload')
  end)

  T.it('the second open keeps session 1 as previous, with its counters and output', function()
    local s1 = session({}, marked(1))
    local s2 = session(s1, marked(2))
    local d = db(s2)
    local prev = d.runtime.previous
    T.truthy(prev)
    T.eq(prev.eventStats.PLAYER_MONEY.delivered, 1)
    local found = false
    for _, line in ipairs(prev.output) do if line:find('marker of session 1', 1, true) then found = true end end
    T.truthy(found, 'session 1 output is in previous')
    local currentHasOld = false
    for _, line in ipairs(d.runtime.output) do if line:find('marker of session 1', 1, true) then currentHasOld = true end end
    T.falsy(currentHasOld, 'current holds only session 2')
    T.eq(#d.runtime.history, 1)
    T.eq(prev.endedBy, 'logout-or-reload')
    T.truthy(prev.capDigest:find('event.PLAYER_MONEY=', 1, true))
    T.isnil(prev.capabilities, 'full capability tables are not kept for old sessions')
  end)

  T.it('the third open: previous is session 2, session 1 survives only as a history row', function()
    local s1 = session({}, marked(1))
    local s2 = session(s1, marked(2))
    local s3 = session(s2, marked(3))
    local d = db(s3)
    local text = table.concat(d.runtime.previous.output, '\n')
    T.truthy(text:find('marker of session 2', 1, true))
    T.falsy(text:find('marker of session 1', 1, true))
    T.eq(#d.runtime.history, 2)
  end)

  T.it('history is a ring of ten rows, oldest dropped', function()
    local saved = {}
    for i = 1, 15 do saved = session(saved, marked(i)) end
    local d = db(saved)
    T.eq(#d.runtime.history, 10)
    T.eq(d.runtime.history[1].delivered.PLAYER_MONEY, 1)
  end)

  T.it('rotation happens once per open, not at every persist', function()
    local s1 = session({}, marked(1))
    local s2 = session(s1, function(W, ns, P)
      for i = 1, 5 do ns.Capabilities.Persist() end
      W:advance(20)
    end)
    T.eq(#db(s2).runtime.history, 1)
  end)

  T.it('a session that never reached logout is recorded as endedBy unknown', function()
    local s1 = session({}, marked(1), { crash = true })
    local s2 = session(s1, marked(2))
    T.eq(db(s2).runtime.previous.endedBy, 'unknown')
  end)

  T.it('a record with no timestamp is not rotated', function()
    local d = fixture()
    d.runtime = { capabilities = {} }
    local s = session({ account = sim.dump(d) }, marked(1))
    T.isnil(db(s).runtime.previous)
  end)
end)

T.describe('session records: bounds', function()
  T.it('previous trims its oldest output lines to stay under the cap', function()
    local s1 = session({}, function(W, ns, P)
      P.ClearOutput()
      for i = 1, 100 do P.Print(string.rep('x', 400) .. ' line ' .. i) end
      W:advance(10)
    end)
    local s2 = session(s1, marked(2))
    local prev = db(s2).runtime.previous
    local bytes = 0
    for _, line in ipairs(prev.output) do bytes = bytes + #line + 4 end
    T.truthy(bytes <= 12000, 'previous output is ' .. bytes .. ' bytes')
    T.truthy(#prev.output > 0 and #prev.output < 100)
    T.truthy(prev.output[#prev.output]:find('line 100', 1, true), 'newest lines are kept')
  end)

  T.it('the whole runtime section stays small after many sessions', function()
    local saved = {}
    for i = 1, 12 do saved = session(saved, marked(i)) end
    local d = db(saved)
    local text = sim.dump(d.runtime)
    T.truthy(#text < 60000, 'runtime is ' .. #text .. ' bytes')
  end)
end)

T.describe('session records: real data is never touched', function()
  T.it('compat, profile and meta are identical before and after the rotation machinery', function()
    local before = fixture()
    local s1 = session({ account = sim.dump(before) }, marked(1))
    local s2 = session(s1, marked(2))
    local a, b = db(s1), db(s2)
    T.eq(sim.dump(a.compat), sim.dump(b.compat))
    T.eq(a.profile, b.profile)
    T.eq(a.schema, b.schema)
  end)

  T.it('a read-only database (written by a newer addon) gets no rotation and no error', function()
    local d = fixture()
    d.schema = 99
    d.runtime = { generatedAt = 111, eventStats = {}, output = { 'old line' } }
    local s = session({ account = sim.dump(d) }, marked(1))
    local out = db(s)
    T.eq(out.schema, 99)
    T.eq(out.runtime.generatedAt, 111, 'runtime of a read-only database is left alone')
    T.isnil(out.runtime.previous)
  end)

  T.it('a failure inside rotation is reported and never raises', function()
    local s1 = session({}, marked(1))
    local s2, _, ns = session(s1, function(W, ns, P)
      local original = P.Util.deepCopy
      P.Util.deepCopy = function() error('boom') end
      local ok = ns.Capabilities.Persist()
      P.Util.deepCopy = original
      T.truthy(ok, 'Persist still succeeds')
    end)
    local d = db(s2)
    T.truthy(d.runtime.generatedAt)
    T.isnil(d.runtime.previous)
  end)
end)

T.describe('session records: pin', function()
  T.it('a pinned record survives any number of later sessions until unpinned', function()
    local s1 = session({}, function(W, ns, P)
      marked(1)(W, ns, P)
      T.truthy(ns.Capabilities.Pin())
    end)
    local saved = s1
    for i = 2, 5 do saved = session(saved, marked(i)) end
    local pinned = db(saved).runtime.pinned
    T.truthy(pinned)
    local text = table.concat(pinned.output, '\n')
    T.truthy(text:find('marker of session 1', 1, true))
    T.truthy(pinned.pinnedAt)
    local s6 = session(saved, function(W, ns) T.truthy(ns.Capabilities.Unpin()) end)
    T.isnil(db(s6).runtime.pinned)
  end)

  T.it('pin is refused when the database is not writable', function()
    local d = fixture(); d.schema = 99
    session({ account = sim.dump(d) }, function(W, ns)
      local ok, why = ns.Capabilities.Pin()
      T.isnil(ok)
      T.truthy(why:find('not writable', 1, true))
    end)
  end)

  T.it('unpin reports when nothing was pinned', function()
    session({}, function(W, ns) T.eq(ns.Capabilities.Unpin(), false) end)
  end)
end)

T.describe('session records: commands', function()
  local function run(W, line)
    W.printed = {}
    W.env.SlashCmdList.GOLDINTEL(line)
    return W:printedText()
  end

  T.it('/gi caps previous, caps history, checkpoint pin|unpin and the /gi db line', function()
    local s1 = session({}, marked(1))
    session(s1, function(W, ns)
      local none = run(W, 'caps pinned')
      T.truthy(none:find('no pinned session record', 1, true))
      local prev = run(W, 'caps events previous')
      T.truthy(prev:find('previous session:', 1, true))
      T.truthy(prev:find('PLAYER_MONEY: delivered 1', 1, true))
      T.truthy(run(W, 'caps history'):find('session at', 1, true))
      T.truthy(run(W, 'checkpoint pin'):find('pinned:', 1, true))
      T.truthy(run(W, 'db'):find('pinned yes', 1, true))
      T.truthy(run(W, 'checkpoint unpin'):find('unpinned', 1, true))
      T.truthy(run(W, 'checkpoint unpin'):find('nothing was pinned', 1, true))
      T.truthy(run(W, 'db'):find('history 1 row', 1, true))
    end)
  end)
end)
