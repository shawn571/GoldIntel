--[[
Tests / test_libs.lua                                       (Phase 2: optional libraries, D-021)

Core and Store must behave identically with Ace3 and HereBeDragons present, absent, or only
partly present (external review findings 4 and 5).
]]

local T = require('testlib')
local Loader = require('loader')

T.describe('static: no dependency on optional libraries above Platform/', function()
  T.it('Core, Store, Future and Boot never mention LibStub, Ace or HereBeDragons', function()
    for _, path in ipairs(Loader.tocFiles()) do
      if path:sub(1, 9) ~= 'Platform/' then
        local raw = Loader.readFile(Loader.root .. '/' .. path)
        for _, word in ipairs({ 'LibStub', 'Ace', 'HereBeDragons', 'AceDB', 'AceConfig', 'AceGUI' }) do
          T.falsy(raw:find(word, 1, true), path .. ' mentions ' .. word)
        end
      end
    end
  end)

  T.it('the TOC declares no required dependency', function()
    local toc = Loader.readFile(Loader.root .. '/GoldIntel.toc')
    T.falsy(toc:find('## Dependencies', 1, true))
    T.falsy(toc:find('## RequiredDeps', 1, true))
    T.falsy(toc:find('## OptionalDeps', 1, true))
  end)
end)

local ALL_LIBS = { ['HereBeDragons-2.0'] = true, ['AceAddon-3.0'] = true, ['AceDB-3.0'] = true,
                   ['AceConfig-3.0'] = true, ['AceGUI-3.0'] = true }

local MATRIX = {
  { name = 'no LibStub at all', opts = { without = { 'LibStub' } } },
  { name = 'LibStub without any library', opts = {} },
  { name = 'only Ace3 present', opts = { libs = { ['AceAddon-3.0'] = true, ['AceDB-3.0'] = true, ['AceConfig-3.0'] = true, ['AceGUI-3.0'] = true } } },
  { name = 'only HereBeDragons present', opts = { libs = { ['HereBeDragons-2.0'] = true } } },
  { name = 'everything present', opts = { libs = ALL_LIBS } },
}

local results = {}
for _, case in ipairs(MATRIX) do
  T.describe('runtime with ' .. case.name, function()
    local W, P, ns = Loader.boot(case.opts)
    W:login()
    results[case.name] = {
      core = ns.Core.state,
      store = ns.Store.Status().state,
      writable = ns.Store.IsWritable(),
      summary = ns.Capabilities.Summary().event,
      modules = #ns.Core.Modules(),
      diag = P.DiagCount(),
    }

    T.it('Core starts and every module is enabled', function()
      T.eq(ns.Core.state, 'ready')
      T.eq(ns.Core.Describe().enabled, 5)
      T.eq(ns.Core.Describe().failed, 0)
    end)

    T.it('Store opens, is writable, and round-trips data', function()
      T.eq(ns.Store.Status().state, 'migrated')
      T.truthy(ns.Store.IsWritable())
      ns.Config.Set('idleSec', 222)
      T.eq(W.env.GoldIntelDB.profile.idleSec, 222)
    end)

    T.it('every /gi command runs without errors', function()
      for _, cmd in ipairs({ '', 'status', 'version', 'caps', 'caps all', 'config', 'db', 'modules', 'checkpoint', 'diag', 'probe' }) do
        W.printed = {}
        W.env.SlashCmdList.GOLDINTEL(cmd)
        T.falsy(W:printedText():find('command failed', 1, true), cmd)
      end
    end)

    T.it('no diagnostics were recorded', function()
      T.eq(P.DiagCount(), 0)
    end)
  end)
end

T.describe('library presence changes only the lib.* capabilities', function()
  T.it('Core, Store and event-stage results are identical across the whole matrix', function()
    local base = results['no LibStub at all']
    for _, case in ipairs(MATRIX) do
      local r = results[case.name]
      T.eq(r.core, base.core, case.name)
      T.eq(r.store, base.store, case.name)
      T.eq(r.writable, base.writable, case.name)
      T.eq(r.summary, base.summary, case.name)
      T.eq(r.modules, base.modules, case.name)
    end
  end)

  T.it('the probe still reports libraries truthfully', function()
    local _, P = Loader.boot({ libs = ALL_LIBS })
    P.Probe()
    T.truthy(P.Has('lib.hbd')); T.truthy(P.Has('lib.acedb'))
    local _, P2 = Loader.boot({ without = { 'LibStub' } })
    P2.Probe()
    T.falsy(P2.Has('lib.hbd')); T.falsy(P2.Has('lib.acedb'))
  end)
end)
