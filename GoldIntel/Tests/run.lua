--[[
GoldIntel / Tests / run.lua

Runs the whole suite on plain Lua 5.1+ (also works on LuaJIT and Lua 5.3/5.4).

    cd GoldIntel
    lua Tests/run.lua              -- run everything
    lua Tests/run.lua money        -- run only test files whose name contains "money"

Exit status is 0 when every test passed, 1 otherwise.
]]

local script = arg and arg[0] or 'Tests/run.lua'
local root = script:match('^(.*)[/\\]Tests[/\\]run%.lua$') or '.'
if script == 'run.lua' then root = '..' end

package.path = root .. '/Tests/helpers/?.lua;' .. package.path

local T = require('testlib')
local Loader = require('loader')
Loader.setRoot(root)

-- Every test file returns nothing; it registers tests on the shared T object.
local FILES = {
  'test_platform_boundary',
  'test_platform',
  'test_clock',
  'test_events',
  'test_scheduler',
  'test_unit',
  'test_map',
  'test_money',
  'test_probe',
  'test_integration',
  'test_platform_adapters',
  'test_bus',
  'test_core',
  'test_capabilities',
  'test_config',
  'test_migrations',
  'test_store',
  'test_pruner',
  'test_commands',
  'test_session_records',
  'test_diag_lab',
  'test_libs',
  'test_phase3b_foundation',
  'test_events_collect',
  'test_collect_adapters',
  'test_context',
  'test_collector',
  'test_reconciler',
  'test_stamps',
  'test_sources',
  'test_replay_ledger',
  'test_schema2',
  'test_cash',
  'test_ledger',
  'test_ledger_mutation',
  'test_trace',
  'test_passive052',
  'test_passive053',
  'test_perf054',
  'test_retention055',
  'test_p4m1',
  'test_p4m2',
  'test_ui061',
  'test_chat',
  'test_bagdiff',
  'test_lots',
  'test_item_sources',
  'test_lotbook',
  'test_item_mutation',
  'test_chat_rule',
  'test_replay_chat',
  'test_sources_mutation',
  'test_replay_adapters',
  'test_loot_e42',
  'test_phase2_integration',
}

local filter = arg and arg[1]
for _, name in ipairs(FILES) do
  if not filter or name:find(filter, 1, true) then
    local chunk, err = loadfile(root .. '/Tests/' .. name .. '.lua')
    if not chunk then
      T.failed = T.failed + 1
      T.failures[#T.failures + 1] = { name = name, err = 'cannot load: ' .. tostring(err) }
    else
      local ok, runErr = xpcall(chunk, debug.traceback)
      if not ok then
        T.failed = T.failed + 1
        T.failures[#T.failures + 1] = { name = name .. ' (file body)', err = runErr }
      end
    end
  end
end

local ok = T.summary()
os.exit(ok and 0 or 1)
