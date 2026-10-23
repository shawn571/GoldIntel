--[[
Tests / test_diag_lab.lua                       (GoldIntelDiag/Lab.lua, Phase 3a)

Loads GoldIntelDiag Diag.lua + Lab.lua into a sandbox on the fake client.
Secret values are simulated with a fake issecretvalue and a table that errors when read.
]]

local T = require('testlib')
local Loader = require('loader')

local function loadLab(path, env, ns)
  local src = Loader.readFile(Loader.root .. '/../GoldIntelDiag/' .. path)
  local chunk, err
  if setfenv then
    chunk, err = loadstring(src, path)
    if chunk then setfenv(chunk, env) end
  else
    chunk, err = load(src, path, 't', env)
  end
  assert(chunk, err)
  chunk('GoldIntelDiag', ns)
end

local function boot(opts)
  local Fake = require('fake_wow')
  local W = Fake.new(opts)
  local env = setmetatable({}, { __index = _G })
  for k, v in pairs(W.env) do env[k] = v end
  env._G = env
  W.sandbox = env
  env.SlashCmdList = env.SlashCmdList or {}
  local secrets = {}
  env.issecretvalue = function(v) return secrets[v] == true end
  W.secrets = secrets
  local ns = {}
  loadLab('Diag.lua', env, ns)
  loadLab('Lab.lua', env, ns)
  W.printed = {}
  local function run(text)
    W.printed = {}
    env.SlashCmdList.GIDIAG('lab ' .. text)
    return W:printedText()
  end
  return W, env, ns, run
end

local function labDB(env) return env.GoldIntelDiagDB and env.GoldIntelDiagDB.lab end

T.describe('gidiag lab: catalog and safety rules', function()
  T.it('lab list shows every protocol experiment', function()
    local _, _, _, run = boot()
    local out = run('list')
    for _, id in ipairs({ 'P0','P1','P2','I1','I1b','I2','A1','S1','T2','T1a','H1','H2','L1','L2','L3','M1','Q1','X1','X2','Q2','AHS','AH1','MS1','CO1','R1','T1b','C1','C2' }) do
      T.truthy(out:find(id, 1, true), id)
    end
  end)

  T.it('COMBAT_LOG_EVENT_UNFILTERED is never registered', function()
    local W, _, _, run = boot()
    local out = run('reg COMBAT_LOG_EVENT_UNFILTERED')
    T.truthy(out:find('refused', 1, true))
    for _, e in ipairs(W.registerCalls) do T.falsy(e == 'COMBAT_LOG_EVENT_UNFILTERED') end
  end)

  T.it('events outside the catalog are refused', function()
    local W, _, _, run = boot()
    T.truthy(run('reg SOME_OTHER_EVENT'):find('not in the Phase 3a catalog', 1, true))
    for _, e in ipairs(W.registerCalls) do T.falsy(e == 'SOME_OTHER_EVENT') end
  end)

  T.it('only one new event per session', function()
    local W, _, _, run = boot()
    run('reg LOOT_OPENED')
    local out = run('reg MERCHANT_SHOW')
    T.truthy(out:find('One NEW event per session', 1, true))
    for _, e in ipairs(W.registerCalls) do T.falsy(e == 'MERCHANT_SHOW') end
  end)

  T.it('registers the event plus PLAYER_MONEY as an ordering reference', function()
    local W, _, _, run = boot()
    run('reg LOOT_OPENED')
    local got = {}
    for _, e in ipairs(W.registerCalls) do got[e] = true end
    T.truthy(got.LOOT_OPENED); T.truthy(got.PLAYER_MONEY)
  end)

  T.it('an invalid event name is recorded as fail and not registered', function()
    local W, env, _, run = boot()
    W.state.invalidEvents.LOOT_OPENED = true
    run('reg LOOT_OPENED')
    for _, e in ipairs(W.registerCalls) do T.falsy(e == 'LOOT_OPENED') end
    T.eq(labDB(env).runs.L1.status, 'fail')
  end)

  T.it('a blocked registration is recorded as blocked', function()
    local W, env, _, run = boot()
    W.state.forbiddenEvents.LOOT_OPENED = true
    local out = run('reg LOOT_OPENED')
    T.truthy(out:find('BLOCKED', 1, true))
    T.eq(labDB(env).runs.L1.status, 'blocked')
  end)

  T.it('the ADDON_ACTION_FORBIDDEN watcher records a popup', function()
    local W, env, _, run = boot()
    run('reg UNIT_SPELLCAST_SUCCEEDED')
    W:fire('ADDON_ACTION_FORBIDDEN', 'GoldIntelDiag', 'RegisterEvent()')
    local ev = labDB(env).runs.C1.events.UNIT_SPELLCAST_SUCCEEDED
    T.truthy(ev.popup:find('RegisterEvent', 1, true))
    T.eq(labDB(env).popups[1], ev.popup)
    T.truthy(run('report'):find('[blocked', 1, true))
  end)
end)

T.describe('gidiag lab: payload capture', function()
  T.it('captures non-secret args and money, and orders versus PLAYER_MONEY', function()
    local W, env, _, run = boot()
    run('reg LOOT_OPENED')
    W:fire('LOOT_OPENED', false, true)
    W.state.money = 55
    W:advance(0.03)
    W:fire('PLAYER_MONEY')
    local ev = labDB(env).runs.L1.events.LOOT_OPENED
    T.eq(ev.delivered, 1)
    T.eq(ev.samples[1].args[1].type, 'boolean')
    T.eq(ev.samples[1].after[1].event, 'PLAYER_MONEY')
    T.truthy(ev.samples[1].after[1].dt >= 0.02)
  end)

  T.it('secret values are recorded as secret and never read', function()
    local W, env, _, run = boot()
    run('reg LOOT_OPENED')
    local secret = setmetatable({}, { __tostring = function() error('read a secret') end,
                                      __index = function() error('read a secret') end,
                                      __len = function() error('read a secret') end })
    W.secrets[secret] = true
    W:fire('LOOT_OPENED', secret, 'ok')
    local s = labDB(env).runs.L1.events.LOOT_OPENED.samples[1]
    T.eq(s.args[1].secret, true)
    T.isnil(s.args[1].value)
    T.eq(s.args[2].value, 'ok')
    T.eq(labDB(env).runs.L1.status, 'open')
    local out = run('report')
    T.truthy(out:find('L1 [fail', 1, true), 'secret payload suggests fail')
  end)

  T.it('long strings are clipped and samples are capped', function()
    local W, env, ns, run = boot()
    run('reg LOOT_OPENED')
    for i = 1, 60 do W:fire('LOOT_OPENED', string.rep('x', 500)) end
    local ev = labDB(env).runs.L1.events.LOOT_OPENED
    T.eq(ev.delivered, 60)
    T.eq(#ev.samples, ns.Lab.MAX_SAMPLES_PER_EVENT)
    T.truthy(ev.capped)
    T.truthy(#ev.samples[1].args[1].value <= ns.Lab.MAX_STRING + 3)
  end)

  T.it('a throwing handler never escapes', function()
    local W, env, _, run = boot()
    run('reg LOOT_OPENED')
    env.GetMoney = function() error('boom') end
    W:fire('LOOT_OPENED', 1)
    T.eq(labDB(env).runs.L1.events.LOOT_OPENED.delivered, 1)
  end)

  T.it('reference PLAYER_MONEY samples are bounded', function()
    local W, env, ns, run = boot()
    run('reg LOOT_OPENED')
    for i = 1, 150 do W:fire('PLAYER_MONEY') end
    T.truthy(#labDB(env).refs <= ns.Lab.MAX_REFS)
  end)
end)

T.describe('gidiag lab: API probes', function()
  T.it('session1 runs the API probes without registering any event', function()
    local W, env, _, run = boot()
    local before = #W.registerCalls
    local out = run('api session1')
    T.eq(#W.registerCalls, before)
    for _, id in ipairs({ 'P0', 'P1', 'P2', 'I1', 'I2', 'A1', 'S1', 'T2', 'H1' }) do
      T.truthy(labDB(env).runs[id], id)
      T.eq(#labDB(env).runs[id].api, 1)
    end
    T.truthy(out:find('Session 1 follow-ups', 1, true))
  end)

  T.it('missing APIs are reported as absent, not as errors', function()
    local _, env, _, run = boot()
    local out = run('api i1')
    T.truthy(out:find('ABSENT', 1, true))
    T.eq(labDB(env).runs.I1.api[1].results[1].present, false)
  end)

  T.it('item data probe describes returns of a present API', function()
    local W, env, _, run = boot()
    W.sandbox.GetItemInfo = function(id) return 'Item' .. id, 'link', 1, 5, 1, 'Misc', 'Junk', 20, '', 1, 7 end
    local out = run('api i1')
    T.truthy(out:find('GetItemInfo(6948) -> Item6948', 1, true))
  end)

  T.it('a crashing getter is caught and recorded', function()
    local W, _, _, run = boot()
    W.sandbox.UnitIsAFK = function() error('nope') end
    local out = run('api a1')
    T.truthy(out:find('ERROR', 1, true))
  end)

  T.it('secret returns from an API are marked secret', function()
    local W, _, _, run = boot()
    local s = setmetatable({}, { __tostring = function() error('read') end })
    W.secrets[s] = true
    W.sandbox.UnitIsAFK = function() return s end
    T.truthy(run('api a1'):find('<secret>', 1, true))
  end)

  T.it('position and place-name probes use the fake map', function()
    local W, _, _, run = boot()
    W.sandbox.C_Map.GetMapInfoAtPosition = function(m, x, y) return { name = 'Lake', mapID = m } end
    local pos = run('api s1 openworld')
    T.truthy(pos:find('map=1411', 1, true))
    local names = run('api h1')
    T.truthy(names:find('name=Lake', 1, true))
  end)

  T.it('H1 accepts explicit map coordinates in percent', function()
    local W, _, _, run = boot()
    local seen
    W.sandbox.C_Map.GetMapInfoAtPosition = function(m, x, y) seen = { m, x, y }; return nil end
    run('api h1 1434 40 50')
    T.eq(seen[1], 1434); T.eq(math.floor(seen[2] * 100 + 0.5), 40)
  end)

  T.it('the bag probe is safe without container APIs', function()
    local _, _, _, run = boot()
    T.truthy(run('api i2'):find('ABSENT', 1, true))
  end)

  T.it('the loot probe says what to do without an open window', function()
    local W, _, _, run = boot()
    W.sandbox.GetNumLootItems = function() return 0 end
    T.truthy(run('api l3'):find('no loot window open', 1, true))
  end)

  T.it('the loot probe classifies the source GUID', function()
    local W, env, _, run = boot()
    W.sandbox.GetNumLootItems = function() return 1 end
    W.sandbox.GetLootSlotInfo = function() return 'icon', 'Copper', 3, nil, 1, false end
    W.sandbox.GetLootSourceInfo = function() return 'Creature-0-1-2-3-4567-000', 1 end
    run('api l3')
    local res = labDB(env).runs.L3.api[1].results
    local found
    for _, r in ipairs(res) do if r.guidType then found = r.guidType end end
    T.eq(found, 'Creature')
  end)

  T.it('the mail probe is safe without mail APIs and never calls GetInboxText', function()
    local W, env, _, run = boot()
    W.sandbox.GetInboxText = function() error('GetInboxText must not be called') end
    run('api x2 closed')
    local res = labDB(env).runs.X2.api[1].results
    T.truthy(#res >= 3)
    T.eq(labDB(env).runs.X2.api[1].label, 'closed')
  end)

  T.it('the mail probe records headers, invoice and attachment of an open mailbox', function()
    local W, env, _, run = boot()
    W.sandbox.MailFrame = { IsShown = function() return true end }
    W.sandbox.GetInboxNumItems = function() return 2, 2 end
    W.sandbox.GetInboxHeaderInfo = function(i)
      if i == 1 then return 'icon', 'st', 'Auction House', 'Auction successful: Copper Ore', 120, 0, 29, 0, false, false, false, false, false end
      return 'icon', 'st', 'Friend', 'Gift', 50, 0, 30, 1, true, false, false, true, false
    end
    W.sandbox.GetInboxInvoiceInfo = function(i)
      if i == 1 then return 'seller', 'Copper Ore', 'Buyer', 100, 0, 5, 10, 0, 0, 0, 1, false end
      return nil
    end
    W.sandbox.GetInboxItem = function() return 'Copper Ore', 2770, 'tex', 1, 1, true end
    W.sandbox.GetInboxItemLink = function() return '|cffffffff|Hitem:2770|h[Copper Ore]|h|r' end
    W.sandbox.C_Mail = { CanCheckInbox = function() return true end, HasInboxMoney = function() return true end }
    run('api x2 open')
    local res = labDB(env).runs.X2.api[1].results
    local sender, invoice
    for _, r in ipairs(res) do
      if r.fn == 'GetInboxHeaderInfo(1)' and r.returns then sender = r.returns[3].value end
      if r.fn == 'GetInboxInvoiceInfo(1)' and r.returns then invoice = r.returns[1].value end
    end
    T.eq(sender, 'Auction House')
    T.eq(invoice, 'seller')
  end)

  T.it('the mail probe caps how many mails it reads and survives secret values', function()
    local W, env, _, run = boot()
    W.sandbox.GetInboxNumItems = function() return 50, 50 end
    local sec = {}
    W.secrets[sec] = true
    W.sandbox.GetInboxHeaderInfo = function() return sec, sec, sec, sec, sec end
    run('api x2 many')
    local res = labDB(env).runs.X2.api[1].results
    local calls = 0
    for _, r in ipairs(res) do if r.fn:find('GetInboxHeaderInfo', 1, true) then calls = calls + 1 end end
    T.eq(calls, 8)
  end)

  T.it('unknown probes are reported', function()
    local _, _, _, run = boot()
    T.truthy(run('api nothing'):find('unknown API probe', 1, true))
  end)
end)

T.describe('gidiag lab: Session 1 follow-ups', function()
  T.it('the tables probe lists names and never calls them', function()
    local W, env, _, run = boot()
    local called = false
    W.sandbox.C_Loot = { GetThing = function() called = true end, Another = function() called = true end }
    local out = run('api p1')
    T.truthy(out:find('Another GetThing', 1, true))
    T.falsy(called)
  end)

  T.it('GET_ITEM_INFO_RECEIVED is a registrable catalog event for I1b', function()
    local W, env, _, run = boot()
    run('reg GET_ITEM_INFO_RECEIVED')
    W:fire('GET_ITEM_INFO_RECEIVED', 2589, true)
    T.eq(labDB(env).runs.I1b.events.GET_ITEM_INFO_RECEIVED.delivered, 1)
  end)
end)

T.describe('gidiag lab: restriction probe', function()
  T.it('P2 reads getters and the restriction enum with fixed arguments only', function()
    local W, env, _, run = boot()
    local seen = {}
    W.sandbox.Enum = { AddOnRestrictionType = { Combat = 0, Encounter = 1 } }
    W.sandbox.C_RestrictedActions = {
      GetAddOnRestrictionState = function(v) seen[#seen + 1] = v; return 0 end,
      IsAddOnRestrictionActive = function(v) return false end }
    W.sandbox.C_Secrets = { HasSecretRestrictions = function() return false end }
    local out = run('api p2')
    T.truthy(out:find('Combat=0 Encounter=1', 1, true))
    T.eq(seen, { 0, 1, 0 })   -- 0 again is the restriction snapshot stored with the run
    T.truthy(out:find('HasSecretRestrictions() -> false', 1, true))
  end)
end)

T.describe('gidiag lab: restriction state in samples', function()
  T.it('event samples and api entries carry the combat restriction state', function()
    local W, env, _, run = boot()
    local state = 0
    W.sandbox.Enum = { AddOnRestrictionType = { Combat = 0 } }
    W.sandbox.C_RestrictedActions = { GetAddOnRestrictionState = function() return state end }
    run('reg LOOT_OPENED')
    W:fire('LOOT_OPENED', false, false)
    state = 2
    W:fire('LOOT_OPENED', true, false)
    run('api a1')
    local ev = labDB(env).runs.L1.events.LOOT_OPENED
    T.eq(ev.samples[1].restr, 0)
    T.eq(ev.samples[2].restr, 2)
    T.eq(labDB(env).runs.A1.api[1].restr, 2)
  end)
  T.it('samples simply omit it when the API is missing', function()
    local W, env, _, run = boot()
    run('reg LOOT_OPENED')
    W:fire('LOOT_OPENED', false, false)
    T.isnil(labDB(env).runs.L1.events.LOOT_OPENED.samples[1].restr)
  end)
end)

T.describe('gidiag lab: loot window snapshot on LOOT_OPENED', function()
  T.it('records slot type, item id, quantity and source GUID parts', function()
    local W, env, _, run = boot()
    W.sandbox.GetNumLootItems = function() return 2 end
    W.sandbox.GetLootSlotType = function(i) return i == 1 and 2 or 1 end
    W.sandbox.GetLootSlotLink = function(i) if i == 2 then return '|cnIQ1:|Hitem:2318::::|h[Light Leather]|h|r' end end
    W.sandbox.GetLootSourceInfo = function(i) return 'Creature-0-6783-0-1-157-22EE329824', i == 1 and 8 or 1 end
    run('reg LOOT_OPENED')
    W:fire('LOOT_OPENED', true, false)
    local snap = labDB(env).runs.L1.events.LOOT_OPENED.samples[1].loot
    T.eq(snap.slots, 2)
    T.eq(snap.list[1].type, 2); T.eq(snap.list[1].qty, 8)
    T.eq(snap.list[2].itemId, 2318)
    T.eq(snap.list[2].guidType, 'Creature'); T.eq(snap.list[2].sourceId, 157)
  end)
  T.it('secret values in the loot window are recorded as S and nothing is read', function()
    local W, env, _, run = boot()
    local secret = setmetatable({}, { __tostring = function() error('read') end })
    W.secrets[secret] = true
    W.sandbox.GetNumLootItems = function() return 1 end
    W.sandbox.GetLootSlotType = function() return secret end
    W.sandbox.GetLootSlotLink = function() return secret end
    W.sandbox.GetLootSourceInfo = function() return secret, secret end
    run('reg LOOT_OPENED')
    W:fire('LOOT_OPENED', true, false)
    local row = labDB(env).runs.L1.events.LOOT_OPENED.samples[1].loot.list[1]
    T.eq(row.type, 'S'); T.eq(row.itemId, 'S'); T.eq(row.guid, 'S')
  end)
  T.it('a missing loot API leaves the sample intact', function()
    local W, env, _, run = boot()
    run('reg LOOT_OPENED')
    W:fire('LOOT_OPENED', true, false)
    T.eq(labDB(env).runs.L1.events.LOOT_OPENED.delivered, 1)
    T.isnil(labDB(env).runs.L1.events.LOOT_OPENED.samples[1].loot)
  end)
end)

T.describe('gidiag lab: tracking, notes, status, report, clear', function()
  T.it('track samples once per second, analyses and stops', function()
    local W, env, _, run = boot()
    W.sandbox.UnitOnTaxi = function() return W.state.taxi == true end
    W.sandbox.GetUnitSpeed = function() return 7, 7 end
    run('track 10')
    for i = 1, 4 do W:advance(1) end
    W.state.taxi = true
    for i = 1, 3 do W:advance(1) end
    W.state.pos = { 0.9, 0.9 }
    W:advance(1)
    W:advance(5)
    local tr = labDB(env).runs.T1a.track
    T.eq(#tr.samples, 10)
    T.eq(tr.analysis.taxiSamples >= 3, true)
    T.truthy(tr.analysis.maxJump > 0.3)
    T.eq(tr.analysis.maxSpeed, 7)
  end)

  T.it('track stop ends early; double start is refused', function()
    local W, env, _, run = boot()
    run('track 60')
    T.truthy(run('track'):find('already running', 1, true))
    W:advance(3)
    run('track stop')
    T.truthy(labDB(env).runs.T1a.track.analysis)
  end)

  T.it('notes and done are stored; the user status wins in the report', function()
    local _, env, _, run = boot()
    run('note H2 square visible, below pins')
    run('done H2 pass')
    T.eq(labDB(env).runs.H2.notes[1], 'square visible, below pins')
    T.truthy(run('report'):find('H2 [pass, set by you]', 1, true))
    T.truthy(run('done H2 maybe'):find('usage', 1, true))
  end)

  T.it('report writes lab.report; clear empties the lab', function()
    local _, env, _, run = boot()
    run('api p0')
    run('report')
    T.truthy(#labDB(env).report > 5)
    run('clear')
    T.isnil(labDB(env))
  end)

  T.it('the square test degrades cleanly without a world map', function()
    local _, env, _, run = boot()
    T.truthy(run('square on'):find('absent', 1, true))
  end)

  T.it('the square test parents to the canvas when present', function()
    local W, env, _, run = boot()
    local canvas = { GetFrameLevel = function() return 3 end, GetFrameStrata = function() return 'MEDIUM' end, GetName = function() return 'Canvas' end }
    W.sandbox.WorldMapFrame = { GetCanvas = function() return canvas end }
    W.sandbox.CreateFrame = function()
      local tex = { SetAllPoints = function() end, SetColorTexture = function() end }
      local f = { SetSize = function() end, SetPoint = function() end, EnableMouse = function() end,
        SetFrameLevel = function(s, l) s.level = l end, GetFrameLevel = function(s) return s.level end,
        CreateTexture = function() return tex end, Show = function() end, Hide = function() end,
        IsMouseEnabled = function() return false end }
      return f
    end
    run('square on')
    local sq = labDB(env).runs.H2.square
    T.eq(sq.parent, 'Canvas'); T.eq(sq.mouseEnabled, false); T.eq(sq.squareLevel, 4)
  end)

  T.it('an unknown lab command prints help', function()
    local _, _, _, run = boot()
    T.truthy(run('wat'):find('unknown lab command', 1, true))
  end)

  T.it('the lab never touches GoldIntelDB', function()
    local W, env, _, run = boot()
    run('api session1'); run('reg LOOT_OPENED'); run('report')
    T.isnil(env.GoldIntelDB)
  end)
end)

T.describe('gidiag lab: quest reward bag diff (Q2)', function()
  local function bags(W, contents)
    W.sandbox.C_Container = {
      GetContainerNumSlots = function(bag) if bag == 0 then return 4 end return 0 end,
      GetContainerItemInfo = function(bag, slot)
        local c = contents[slot]
        if bag ~= 0 or not c then return nil end
        return { itemID = c[1], stackCount = c[2], hyperlink = '|Hitem:' .. c[1] .. '|h[x]|h' }
      end,
    }
  end

  T.it('the bag diff probe is safe without container APIs', function()
    local _, env, _, run = boot()
    run('api q2 before')
    T.eq(labDB(env).runs.Q2.api[1].results[1].present, false)
  end)

  T.it('an after run without a before snapshot says what to do', function()
    local W, _, _, run = boot()
    bags(W, { { 2589, 5 } })
    T.truthy(run('api q2 after'):find("no 'before' snapshot", 1, true))
  end)

  T.it('the diff reports an added item, a changed stack and the money change', function()
    local W, env, _, run = boot()
    local contents = { { 2589, 5 }, { 117, 2 } }
    bags(W, contents)
    local money = 1000
    W.sandbox.GetMoney = function() return money end
    run('api q2 before')
    contents[3] = { 6948, 1 }
    contents[1] = { 2589, 7 }
    money = 1175
    run('api q2 after')
    local res = labDB(env).runs.Q2.api[2].results
    local added, changed, total
    for _, r in ipairs(res) do
      if r.fn == 'added item 6948' then added = r.summary end
      if r.fn == 'changed item 2589' then changed = r.summary end
      if r.fn == 'diff total' then total = r.summary end
    end
    T.eq(added.delta, 1)
    T.eq(changed.delta, 2)
    T.eq(total.changedItems, 2)
    T.eq(total.moneyDelta, '175')
  end)

  T.it('a removed item is reported and secret stacks do not crash the probe', function()
    local W, env, _, run = boot()
    local contents = { { 2589, 5 }, { 117, 2 } }
    bags(W, contents)
    run('api q2 before')
    contents[2] = nil
    local secret = { }
    W.secrets[secret] = true
    contents[4] = { 999, secret }
    W.sandbox.issecretvalue = function(v) return W.secrets[v] == true end
    run('api q2 after')
    local res = labDB(env).runs.Q2.api[2].results
    local removed
    for _, r in ipairs(res) do if r.fn == 'removed item 117' then removed = r.summary end end
    T.eq(removed.delta, -2)
  end)

  T.it('BAG_UPDATE_DELAYED is a registrable catalog event for Q2', function()
    local W, _, _, run = boot()
    local out = run('reg BAG_UPDATE_DELAYED')
    T.truthy(out:find('registered', 1, true))
    T.falsy(out:find('not in the Phase 3a catalog', 1, true))
  end)
end)

T.describe('gidiag lab: addendum probes for AH, outgoing mail, COD (D-068)', function()
  T.it('AHS and MS1 are safe when no AH or mail APIs exist', function()
    local _, env, _, run = boot()
    run('api ahs open')
    run('api ms1 before')
    T.eq(labDB(env).runs.AHS.api[1].results[1].summary.label, 'open')
    T.eq(labDB(env).runs.MS1.api[1].results[1].summary.label, 'before')
  end)

  T.it('AHS records money, window state and owned auctions; secret fields show as S', function()
    local W, env, _, run = boot()
    W.sandbox.GetMoney = function() return 5000 end
    W.sandbox.AuctionHouseFrame = { IsShown = function() return true end }
    local secret = {}
    W.secrets[secret] = true
    W.sandbox.issecretvalue = function(v) return W.secrets[v] == true end
    W.sandbox.C_AuctionHouse = {
      GetNumOwnedAuctions = function() return 2 end,
      GetOwnedAuctions = function()
        return { { auctionID = 11, quantity = 3, buyoutAmount = 900, itemKey = { itemID = 2589 }, bidder = secret },
                 { auctionID = 12, quantity = 1, buyoutAmount = 50, itemKey = { itemID = 117 } } }
      end,
    }
    run('api ahs listed')
    local res = labDB(env).runs.AHS.api[1].results
    T.eq(res[1].summary.money, '5000')
    T.eq(res[1].summary.ahShown, 'true')
    local first, count
    for _, r in ipairs(res) do
      if r.fn == 'owned auction 1' then first = r.summary.fields end
      if r.fn == 'GetOwnedAuctions()' then count = r.summary.count end
    end
    T.eq(count, 2)
    T.truthy(first:find('auctionID=11', 1, true))
    T.truthy(first:find('itemID=2589', 1, true))
    T.truthy(first:find('bidder=S', 1, true))
  end)

  T.it('AHS names lists event name validity and does not register anything', function()
    local W, env, _, run = boot()
    run('api ahs names')
    local n = 0
    for _, r in ipairs(labDB(env).runs.AHS.api[1].results) do
      if r.fn:find('IsEventValid(AUCTION_HOUSE_AUCTION_CREATED)', 1, true) then n = n + 1 end
    end
    T.eq(n, 1)
    T.eq(W.registered and #W.registered or 0, 0)
  end)

  T.it('MS1 reads postage and attached money through the old or the C_Mail name', function()
    local W, env, _, run = boot()
    W.sandbox.C_Mail = { GetSendMailPrice = function() return 30 end, GetSendMailMoney = function() return 120 end }
    W.sandbox.SendMailFrame = { IsShown = function() return true end }
    run('api ms1 after')
    local seen = {}
    for _, r in ipairs(labDB(env).runs.MS1.api[1].results) do seen[r.fn] = r end
    T.eq(seen['C_Mail.GetSendMailPrice()'].returns[1].value, 30)
    T.eq(seen['C_Mail.GetSendMailMoney()'].returns[1].value, 120)
    T.eq(seen['GetSendMailPrice()'].present, false)
  end)

  T.it('X2 now records the money alongside the headers', function()
    local W, env, _, run = boot()
    W.sandbox.GetMoney = function() return 777 end
    run('api x2 money')
    local found
    for _, r in ipairs(labDB(env).runs.X2.api[1].results) do
      if r.fn == 'money' then found = r.summary.copper end
    end
    T.eq(found, '777')
  end)

  T.it('AH and send-mail events are registrable catalog events', function()
    local _, _, _, run = boot()
    for _, e in ipairs({ 'AUCTION_HOUSE_SHOW', 'MAIL_SEND_SUCCESS' }) do
      local out = run('reg ' .. e)
      T.falsy(out:find('not in the Phase 3a catalog', 1, true), e)
    end
  end)
end)

T.describe('gidiag lab: static checks', function()
  local function src(path)
    return Loader.readFile(Loader.root .. '/../GoldIntelDiag/' .. path)
  end
  T.it('Lab.lua is ASCII, LF only and has no block comments', function()
    local s = src('Lab.lua')
    T.falsy(s:find('[\128-\255]'))
    T.falsy(s:find('\r', 1, true))
    T.falsy(s:find('--[[', 1, true))
  end)
  T.it('Lab.lua never names COMBAT_LOG_EVENT_UNFILTERED outside the refusal list', function()
    local s = src('Lab.lua')
    local n = 0
    for line in s:gmatch('[^\n]+') do
      if line:find('COMBAT_LOG_EVENT_UNFILTERED', 1, true) and not line:match('^%s*%-%-') then n = n + 1 end
    end
    T.eq(n, 1)
  end)
  T.it('Lab.lua has no GoldIntelDB reference other than comments', function()
    for line in src('Lab.lua'):gmatch('[^\n]+') do
      if line:find('GoldIntelDB', 1, true) and not line:match('^%s*%-%-') and not line:find('GoldIntelDiagDB', 1, true) then
        error('GoldIntelDB used: ' .. line)
      end
    end
  end)
  T.it('the TOC lists Lab.lua between Diag.lua and SrcCurrent.lua', function()
    local toc = src('GoldIntelDiag.toc')
    local a, b, c = toc:find('Diag.lua', 1, true), toc:find('Lab.lua', 1, true), toc:find('SrcCurrent.lua', 1, true)
    T.truthy(a and b and c and a < b and b < c)
  end)
end)
