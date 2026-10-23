GIMin - smallest WoW Forever load test (GoldIntel Phase 1 compatibility)

INSTALL   Extract GoldIntel_Phase1_AddOns.zip into your AddOns folder (it contains GIMin, GoldIntel and GoldIntelDiag
          as complete folders). Do NOT copy single files: GIMin needs its Sub folder (Back.lua, Fwd.lua, Block.lua).
          Manual alternative: copy the whole GIMin folder to  <WoW Forever>\_retail_\Interface\AddOns\   (or the
          AddOns folder your client uses). Folder name and GIMin.toc must match: GIMin.
RUN       Log in, then type  /gimin
EXPECT (everything working):
  1 load       main file ran, ns passed = table
  2 namespace  back = true  fwd = true  block = true
  3 saved vars at file load = nil, at ADDON_LOADED = nil (first run) or table, loads = 1, 2, 3 ... after each /reload
  4 slash      you are reading its output
  5 events     ADDON_LOADED/PLAYER_LOGIN/PLAYER_ENTERING_WORLD/PLAYER_MONEY/PLAYER_LOGOUT registered,
               NOT_A_REAL_EVENT_GIMIN REJECTED (or registered, which is also important to report)
HOW TO READ FAILURES
  back = nil               the BACKSLASH path in the TOC failed -> GoldIntel TOC must use forward slashes
  fwd = nil                forward-slash paths failed (unlikely)
  block = nil              a file starting with a --[[ block comment failed to load
  ns passed = nil          the (name, namespace) vararg is not delivered -> report immediately
  main file did not run    nothing prints at all: check Logs\FrameXML.log and /console scriptErrors 1
Money test: gain or spend a little gold; "PLAYER_MONEY fired" should print (read-only, nothing changes).
