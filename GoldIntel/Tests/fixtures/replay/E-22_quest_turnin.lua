
GoldIntelDiagDB = {
["lab"] = {
["report"] = {
"Phase 3a lab report  1.60.1 build 70450  at 1792275764",
"P0 [review, suggested] Presence of every candidate API and event name",
"   api runs: 1",
"I1 [review, suggested] Item data: sell price, bind type, async behaviour",
"   api runs: 1",
"I2 [review, suggested] Bags: readable item fields and scan cost",
"   api runs: 1",
"A1 [review, suggested] AFK flag and related state",
"   api runs: 2",
"S1 [review, suggested] Map position in the open world and in an instance",
"   api runs: 1",
"T2 [review, suggested] Movement speed, mounted, flying, swimming, taxi flags (single snapshot)",
"   api runs: 1",
"T1a [review, suggested] Taxi flag and position jumps over time (also covers T2, T3, T4)",
"   track: 134 samples, maxSpeed 30.342313766479, taxi 81, maxJump 0.03, mapChanges 3",
"P1 [review, suggested] Function names inside the C_* tables found by P0 (names only, nothing is called)",
"   api runs: 1",
"P2 [review, suggested] Restriction and state getters found by P1 (no-argument getters and the restriction enum)",
"   api runs: 2",
"I1b [not run] Item data load completion event (async item info)",
"H1 [review, suggested] Place names for map coordinates",
"   api runs: 1",
"H2 [review, suggested] Map overlay host: a test square on the world map",
"   square: shown",
"   note: part of a red square around Sentinel Hill, not completely filled in. I will upload a screenshot of it.",
"L3 [review, suggested] Loot window slot data and source GUID",
"   api runs: 9",
"L1 [pass, suggested] LOOT_OPENED payload and order versus PLAYER_MONEY",
"   LOOT_OPENED: delivered 5, samples 5, IsEventRegistered true",
"L2 [pass, suggested] LOOT_SLOT_CLEARED per slot",
"   LOOT_SLOT_CLEARED: delivered 9, samples 9, IsEventRegistered true",
"M1 [pass, suggested] Merchant open/close, sale and purchase order versus money",
"   MERCHANT_SHOW: delivered 2, samples 2, IsEventRegistered true",
"Q1 [pass, suggested] Quest turn-in payload",
"   QUEST_TURNED_IN: delivered 1, samples 1, IsEventRegistered true",
"X1 [not run] Mail events",
"R1 [not run] Trade events",
"T1b [not run] Taxi and control events",
"C1 [not run] UNIT_SPELLCAST_SUCCEEDED (highest suspicion of the old popup)",
"C2 [not run] CHAT_MSG_MONEY (only if L1 fails)",
},
["version"] = 1,
["lastRegisterAttempt"] = "QUEST_TURNED_IN",
["runs"] = {
["T2"] = {
["title"] = "Movement speed, mounted, flying, swimming, taxi flags (single snapshot)",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "GetUnitSpeed(player)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 4.722221851348877,
["type"] = "number",
},
},
},
{
["fn"] = "IsMounted()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsFlying()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsSwimming()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsFalling()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitOnTaxi(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "T2",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["Q1"] = {
["events"] = {
["QUEST_TURNED_IN"] = {
["registerCall"] = "returned normally",
["delivered"] = 1,
["samples"] = {
{
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.041,
},
},
["gt"] = 505089.307,
["args"] = {
{
["value"] = 818,
["type"] = "number",
},
{
["value"] = 625,
["type"] = "number",
},
{
["value"] = 175,
["type"] = "number",
},
},
["money"] = 148,
["t"] = 1792275755,
["restr"] = 0,
["n"] = 3,
},
},
["attemptedAt"] = 1792275733,
["isEventRegistered"] = true,
},
},
["notes"] = {
},
["title"] = "Quest turn-in payload",
["api"] = {
},
["id"] = "Q1",
["status"] = "open",
["startedAt"] = 1792275733,
["build"] = "1.60.1 build 70450",
},
["T1a"] = {
["track"] = {
["stoppedBecause"] = "stopped by user",
["seconds"] = 300,
["startedAt"] = 1792270568,
["analysis"] = {
["maxJump"] = 0.03,
["maxSpeed"] = 30.34231376647949,
["mountedSamples"] = 81,
["taxiSamples"] = 81,
["samples"] = 134,
["mapChanges"] = 3,
["maxGap"] = 1.034,
},
["samples"] = {
{
["mounted"] = false,
["gt"] = 499903.216,
["taxi"] = false,
["t"] = 1792270569,
["run"] = 7,
["swimming"] = false,
["y"] = 0.514,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.509,
},
{
["mounted"] = false,
["gt"] = 499904.229,
["taxi"] = false,
["t"] = 1792270570,
["run"] = 7,
["swimming"] = false,
["y"] = 0.513,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.511,
},
{
["mounted"] = false,
["gt"] = 499905.236,
["taxi"] = false,
["t"] = 1792270571,
["run"] = 7,
["swimming"] = false,
["y"] = 0.512,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.512,
},
{
["mounted"] = false,
["gt"] = 499906.238,
["taxi"] = false,
["t"] = 1792270572,
["run"] = 7,
["swimming"] = false,
["y"] = 0.512,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.514,
},
{
["mounted"] = false,
["gt"] = 499907.258,
["taxi"] = false,
["t"] = 1792270573,
["run"] = 7,
["swimming"] = false,
["y"] = 0.512,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.516,
},
{
["mounted"] = false,
["gt"] = 499908.27,
["taxi"] = false,
["t"] = 1792270574,
["run"] = 7,
["swimming"] = false,
["y"] = 0.513,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.518,
},
{
["mounted"] = false,
["gt"] = 499909.283,
["taxi"] = false,
["t"] = 1792270575,
["run"] = 7,
["swimming"] = false,
["y"] = 0.513,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.52,
},
{
["mounted"] = false,
["gt"] = 499910.296,
["taxi"] = false,
["t"] = 1792270576,
["run"] = 7,
["swimming"] = false,
["y"] = 0.514,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.522,
},
{
["mounted"] = false,
["gt"] = 499911.306,
["taxi"] = false,
["t"] = 1792270577,
["run"] = 7,
["swimming"] = false,
["y"] = 0.515,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.524,
},
{
["mounted"] = false,
["gt"] = 499912.317,
["taxi"] = false,
["t"] = 1792270578,
["run"] = 7,
["swimming"] = false,
["y"] = 0.515,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.526,
},
{
["mounted"] = false,
["gt"] = 499913.318,
["taxi"] = false,
["t"] = 1792270579,
["run"] = 7,
["swimming"] = false,
["y"] = 0.515,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.528,
},
{
["mounted"] = false,
["gt"] = 499914.331,
["taxi"] = false,
["t"] = 1792270580,
["run"] = 7,
["swimming"] = false,
["y"] = 0.516,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.53,
},
{
["mounted"] = false,
["gt"] = 499915.349,
["taxi"] = false,
["t"] = 1792270581,
["run"] = 7,
["swimming"] = false,
["y"] = 0.516,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.532,
},
{
["mounted"] = false,
["gt"] = 499916.35,
["taxi"] = false,
["t"] = 1792270582,
["run"] = 7,
["swimming"] = false,
["y"] = 0.517,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.534,
},
{
["mounted"] = false,
["gt"] = 499917.367,
["taxi"] = false,
["t"] = 1792270583,
["run"] = 7,
["swimming"] = false,
["y"] = 0.517,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.536,
},
{
["mounted"] = false,
["gt"] = 499918.378,
["taxi"] = false,
["t"] = 1792270584,
["run"] = 7,
["swimming"] = false,
["y"] = 0.517,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.538,
},
{
["mounted"] = false,
["gt"] = 499919.384,
["taxi"] = false,
["t"] = 1792270585,
["run"] = 7,
["swimming"] = false,
["y"] = 0.518,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.54,
},
{
["mounted"] = false,
["gt"] = 499920.4,
["taxi"] = false,
["t"] = 1792270586,
["run"] = 7,
["swimming"] = false,
["y"] = 0.519,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.542,
},
{
["mounted"] = false,
["gt"] = 499921.401,
["taxi"] = false,
["t"] = 1792270587,
["run"] = 7,
["swimming"] = false,
["y"] = 0.52,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.543,
},
{
["mounted"] = false,
["gt"] = 499922.406,
["taxi"] = false,
["t"] = 1792270588,
["run"] = 7,
["swimming"] = false,
["y"] = 0.521,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.545,
},
{
["mounted"] = false,
["gt"] = 499923.418,
["taxi"] = false,
["t"] = 1792270589,
["run"] = 7,
["swimming"] = false,
["y"] = 0.522,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.547,
},
{
["mounted"] = false,
["gt"] = 499924.421,
["taxi"] = false,
["t"] = 1792270590,
["run"] = 7,
["swimming"] = false,
["y"] = 0.523,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.549,
},
{
["mounted"] = false,
["gt"] = 499925.428,
["taxi"] = false,
["t"] = 1792270591,
["run"] = 7,
["swimming"] = false,
["y"] = 0.523,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.551,
},
{
["mounted"] = false,
["gt"] = 499926.445,
["taxi"] = false,
["t"] = 1792270592,
["run"] = 7,
["swimming"] = false,
["y"] = 0.524,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.553,
},
{
["mounted"] = false,
["gt"] = 499927.454,
["taxi"] = false,
["t"] = 1792270593,
["run"] = 7,
["swimming"] = false,
["y"] = 0.525,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.555,
},
{
["mounted"] = false,
["gt"] = 499928.46,
["taxi"] = false,
["t"] = 1792270594,
["run"] = 7,
["swimming"] = false,
["y"] = 0.526,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.557,
},
{
["mounted"] = false,
["gt"] = 499929.467,
["taxi"] = false,
["t"] = 1792270595,
["run"] = 7,
["swimming"] = false,
["y"] = 0.527,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.559,
},
{
["mounted"] = false,
["gt"] = 499930.476,
["taxi"] = false,
["t"] = 1792270596,
["run"] = 7,
["swimming"] = false,
["y"] = 0.528,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.561,
},
{
["mounted"] = false,
["gt"] = 499931.476,
["taxi"] = false,
["t"] = 1792270597,
["run"] = 7,
["swimming"] = false,
["y"] = 0.528,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.562,
},
{
["mounted"] = false,
["gt"] = 499932.49,
["taxi"] = false,
["t"] = 1792270598,
["run"] = 7,
["swimming"] = false,
["y"] = 0.527,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1436,
["x"] = 0.564,
},
{
["mounted"] = false,
["gt"] = 499933.5,
["taxi"] = false,
["t"] = 1792270599,
["run"] = 7,
["swimming"] = false,
["y"] = 0.526,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1436,
["x"] = 0.565,
},
{
["mounted"] = false,
["gt"] = 499934.507,
["taxi"] = false,
["t"] = 1792270600,
["run"] = 7,
["swimming"] = false,
["y"] = 0.526,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1436,
["x"] = 0.565,
},
{
["mounted"] = false,
["gt"] = 499935.517,
["taxi"] = false,
["t"] = 1792270601,
["run"] = 7,
["swimming"] = false,
["y"] = 0.526,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1436,
["x"] = 0.565,
},
{
["mounted"] = false,
["gt"] = 499936.533,
["taxi"] = false,
["t"] = 1792270602,
["run"] = 7,
["swimming"] = false,
["y"] = 0.526,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1436,
["x"] = 0.565,
},
{
["mounted"] = true,
["gt"] = 499937.55,
["taxi"] = true,
["t"] = 1792270603,
["run"] = 7,
["swimming"] = false,
["y"] = 0.524,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.559,
},
{
["mounted"] = true,
["gt"] = 499938.553,
["taxi"] = true,
["t"] = 1792270604,
["run"] = 7,
["swimming"] = false,
["y"] = 0.523,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.551,
},
{
["mounted"] = true,
["gt"] = 499939.558,
["taxi"] = true,
["t"] = 1792270605,
["run"] = 7,
["swimming"] = false,
["y"] = 0.513,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.546,
},
{
["mounted"] = true,
["gt"] = 499940.569,
["taxi"] = true,
["t"] = 1792270606,
["run"] = 7,
["swimming"] = false,
["y"] = 0.501,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.541,
},
{
["mounted"] = true,
["gt"] = 499941.575,
["taxi"] = true,
["t"] = 1792270607,
["run"] = 7,
["swimming"] = false,
["y"] = 0.488,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.537,
},
{
["mounted"] = true,
["gt"] = 499942.582,
["taxi"] = true,
["t"] = 1792270608,
["run"] = 7,
["swimming"] = false,
["y"] = 0.476,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.535,
},
{
["mounted"] = true,
["gt"] = 499943.599,
["taxi"] = true,
["t"] = 1792270609,
["run"] = 7,
["swimming"] = false,
["y"] = 0.465,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.538,
},
{
["mounted"] = true,
["gt"] = 499944.619,
["taxi"] = true,
["t"] = 1792270610,
["run"] = 7,
["swimming"] = false,
["y"] = 0.456,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.545,
},
{
["mounted"] = true,
["gt"] = 499945.622,
["taxi"] = true,
["t"] = 1792270611,
["run"] = 7,
["swimming"] = false,
["y"] = 0.448,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.552,
},
{
["mounted"] = true,
["gt"] = 499946.627,
["taxi"] = true,
["t"] = 1792270612,
["run"] = 7,
["swimming"] = false,
["y"] = 0.437,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.557,
},
{
["mounted"] = true,
["gt"] = 499947.627,
["taxi"] = true,
["t"] = 1792270613,
["run"] = 7,
["swimming"] = false,
["y"] = 0.425,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.559,
},
{
["mounted"] = true,
["gt"] = 499948.639,
["taxi"] = true,
["t"] = 1792270614,
["run"] = 7,
["swimming"] = false,
["y"] = 0.412,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.559,
},
{
["mounted"] = true,
["gt"] = 499949.654,
["taxi"] = true,
["t"] = 1792270615,
["run"] = 7,
["swimming"] = false,
["y"] = 0.398,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.56,
},
{
["mounted"] = true,
["gt"] = 499950.672,
["taxi"] = true,
["t"] = 1792270616,
["run"] = 7,
["swimming"] = false,
["y"] = 0.387,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.564,
},
{
["mounted"] = true,
["gt"] = 499951.68,
["taxi"] = true,
["t"] = 1792270617,
["run"] = 7,
["swimming"] = false,
["y"] = 0.377,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.569,
},
{
["mounted"] = true,
["gt"] = 499952.69,
["taxi"] = true,
["t"] = 1792270618,
["run"] = 7,
["swimming"] = false,
["y"] = 0.368,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.576,
},
{
["mounted"] = true,
["gt"] = 499953.691,
["taxi"] = true,
["t"] = 1792270619,
["run"] = 7,
["swimming"] = false,
["y"] = 0.359,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.583,
},
{
["mounted"] = true,
["gt"] = 499954.7,
["taxi"] = true,
["t"] = 1792270620,
["run"] = 7,
["swimming"] = false,
["y"] = 0.352,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.591,
},
{
["mounted"] = true,
["gt"] = 499955.702,
["taxi"] = true,
["t"] = 1792270621,
["run"] = 7,
["swimming"] = false,
["y"] = 0.346,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.598,
},
{
["mounted"] = true,
["gt"] = 499956.724,
["taxi"] = true,
["t"] = 1792270622,
["run"] = 7,
["swimming"] = false,
["y"] = 0.341,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.606,
},
{
["mounted"] = true,
["gt"] = 499957.738,
["taxi"] = true,
["t"] = 1792270623,
["run"] = 7,
["swimming"] = false,
["y"] = 0.338,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.614,
},
{
["mounted"] = true,
["gt"] = 499958.742,
["taxi"] = true,
["t"] = 1792270624,
["run"] = 7,
["swimming"] = false,
["y"] = 0.337,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.622,
},
{
["mounted"] = true,
["gt"] = 499959.756,
["taxi"] = true,
["t"] = 1792270625,
["run"] = 7,
["swimming"] = false,
["y"] = 0.336,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.632,
},
{
["mounted"] = true,
["gt"] = 499960.764,
["taxi"] = true,
["t"] = 1792270626,
["run"] = 7,
["swimming"] = false,
["y"] = 0.337,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1436,
["x"] = 0.64,
},
{
["mounted"] = true,
["gt"] = 499961.767,
["taxi"] = true,
["t"] = 1792270627,
["run"] = 7,
["swimming"] = false,
["y"] = 0.262,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1431,
["x"] = 0.033,
},
{
["mounted"] = true,
["gt"] = 499962.79,
["taxi"] = true,
["t"] = 1792270628,
["run"] = 7,
["swimming"] = false,
["y"] = 0.264,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1431,
["x"] = 0.046,
},
{
["mounted"] = true,
["gt"] = 499963.791,
["taxi"] = true,
["t"] = 1792270629,
["run"] = 7,
["swimming"] = false,
["y"] = 0.975,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.247,
},
{
["mounted"] = true,
["gt"] = 499964.791,
["taxi"] = true,
["t"] = 1792270630,
["run"] = 7,
["swimming"] = false,
["y"] = 0.976,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.255,
},
{
["mounted"] = true,
["gt"] = 499965.796,
["taxi"] = true,
["t"] = 1792270631,
["run"] = 7,
["swimming"] = false,
["y"] = 0.975,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.264,
},
{
["mounted"] = true,
["gt"] = 499966.799,
["taxi"] = true,
["t"] = 1792270632,
["run"] = 7,
["swimming"] = false,
["y"] = 0.973,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.273,
},
{
["mounted"] = true,
["gt"] = 499967.812,
["taxi"] = true,
["t"] = 1792270633,
["run"] = 7,
["swimming"] = false,
["y"] = 0.968,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.28,
},
{
["mounted"] = true,
["gt"] = 499968.829,
["taxi"] = true,
["t"] = 1792270634,
["run"] = 7,
["swimming"] = false,
["y"] = 0.961,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.286,
},
{
["mounted"] = true,
["gt"] = 499969.83,
["taxi"] = true,
["t"] = 1792270635,
["run"] = 7,
["swimming"] = false,
["y"] = 0.951,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.291,
},
{
["mounted"] = true,
["gt"] = 499970.845,
["taxi"] = true,
["t"] = 1792270636,
["run"] = 7,
["swimming"] = false,
["y"] = 0.937,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.294,
},
{
["mounted"] = true,
["gt"] = 499971.847,
["taxi"] = true,
["t"] = 1792270637,
["run"] = 7,
["swimming"] = false,
["y"] = 0.925,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.295,
},
{
["mounted"] = true,
["gt"] = 499972.866,
["taxi"] = true,
["t"] = 1792270639,
["run"] = 7,
["swimming"] = false,
["y"] = 0.911,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.296,
},
{
["mounted"] = true,
["gt"] = 499973.882,
["taxi"] = true,
["t"] = 1792270640,
["run"] = 7,
["swimming"] = false,
["y"] = 0.896,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.297,
},
{
["mounted"] = true,
["gt"] = 499974.887,
["taxi"] = true,
["t"] = 1792270641,
["run"] = 7,
["swimming"] = false,
["y"] = 0.882,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.297,
},
{
["mounted"] = true,
["gt"] = 499975.896,
["taxi"] = true,
["t"] = 1792270642,
["run"] = 7,
["swimming"] = false,
["y"] = 0.87,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.296,
},
{
["mounted"] = true,
["gt"] = 499976.902,
["taxi"] = true,
["t"] = 1792270643,
["run"] = 7,
["swimming"] = false,
["y"] = 0.855,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.295,
},
{
["mounted"] = true,
["gt"] = 499977.913,
["taxi"] = true,
["t"] = 1792270644,
["run"] = 7,
["swimming"] = false,
["y"] = 0.844,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.292,
},
{
["mounted"] = true,
["gt"] = 499978.921,
["taxi"] = true,
["t"] = 1792270645,
["run"] = 7,
["swimming"] = false,
["y"] = 0.832,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.291,
},
{
["mounted"] = true,
["gt"] = 499979.93,
["taxi"] = true,
["t"] = 1792270646,
["run"] = 7,
["swimming"] = false,
["y"] = 0.819,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.292,
},
{
["mounted"] = true,
["gt"] = 499980.942,
["taxi"] = true,
["t"] = 1792270647,
["run"] = 7,
["swimming"] = false,
["y"] = 0.806,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.291,
},
{
["mounted"] = true,
["gt"] = 499981.95,
["taxi"] = true,
["t"] = 1792270648,
["run"] = 7,
["swimming"] = false,
["y"] = 0.793,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.287,
},
{
["mounted"] = true,
["gt"] = 499982.961,
["taxi"] = true,
["t"] = 1792270649,
["run"] = 7,
["swimming"] = false,
["y"] = 0.781,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.287,
},
{
["mounted"] = true,
["gt"] = 499983.964,
["taxi"] = true,
["t"] = 1792270650,
["run"] = 7,
["swimming"] = false,
["y"] = 0.769,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.291,
},
{
["mounted"] = true,
["gt"] = 499984.969,
["taxi"] = true,
["t"] = 1792270651,
["run"] = 7,
["swimming"] = false,
["y"] = 0.762,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.297,
},
{
["mounted"] = true,
["gt"] = 499985.974,
["taxi"] = true,
["t"] = 1792270652,
["run"] = 7,
["swimming"] = false,
["y"] = 0.759,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.306,
},
{
["mounted"] = true,
["gt"] = 499986.984,
["taxi"] = true,
["t"] = 1792270653,
["run"] = 7,
["swimming"] = false,
["y"] = 0.75,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.312,
},
{
["mounted"] = true,
["gt"] = 499987.988,
["taxi"] = true,
["t"] = 1792270654,
["run"] = 7,
["swimming"] = false,
["y"] = 0.739,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.317,
},
{
["mounted"] = true,
["gt"] = 499989.004,
["taxi"] = true,
["t"] = 1792270655,
["run"] = 7,
["swimming"] = false,
["y"] = 0.726,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.322,
},
{
["mounted"] = true,
["gt"] = 499990.006,
["taxi"] = true,
["t"] = 1792270656,
["run"] = 7,
["swimming"] = false,
["y"] = 0.715,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.326,
},
{
["mounted"] = true,
["gt"] = 499991.013,
["taxi"] = true,
["t"] = 1792270657,
["run"] = 7,
["swimming"] = false,
["y"] = 0.704,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.332,
},
{
["mounted"] = true,
["gt"] = 499992.016,
["taxi"] = true,
["t"] = 1792270658,
["run"] = 7,
["swimming"] = false,
["y"] = 0.693,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.336,
},
{
["mounted"] = true,
["gt"] = 499993.022,
["taxi"] = true,
["t"] = 1792270659,
["run"] = 7,
["swimming"] = false,
["y"] = 0.682,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.338,
},
{
["mounted"] = true,
["gt"] = 499994.033,
["taxi"] = true,
["t"] = 1792270660,
["run"] = 7,
["swimming"] = false,
["y"] = 0.669,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.337,
},
{
["mounted"] = true,
["gt"] = 499995.041,
["taxi"] = true,
["t"] = 1792270661,
["run"] = 7,
["swimming"] = false,
["y"] = 0.657,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.334,
},
{
["mounted"] = true,
["gt"] = 499996.047,
["taxi"] = true,
["t"] = 1792270662,
["run"] = 7,
["swimming"] = false,
["y"] = 0.647,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.328,
},
{
["mounted"] = true,
["gt"] = 499997.058,
["taxi"] = true,
["t"] = 1792270663,
["run"] = 7,
["swimming"] = false,
["y"] = 0.636,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.322,
},
{
["mounted"] = true,
["gt"] = 499998.062,
["taxi"] = true,
["t"] = 1792270664,
["run"] = 7,
["swimming"] = false,
["y"] = 0.625,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.318,
},
{
["mounted"] = true,
["gt"] = 499999.064,
["taxi"] = true,
["t"] = 1792270665,
["run"] = 7,
["swimming"] = false,
["y"] = 0.613,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.317,
},
{
["mounted"] = true,
["gt"] = 500000.072,
["taxi"] = true,
["t"] = 1792270666,
["run"] = 7,
["swimming"] = false,
["y"] = 0.599,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.317,
},
{
["mounted"] = true,
["gt"] = 500001.073,
["taxi"] = true,
["t"] = 1792270667,
["run"] = 7,
["swimming"] = false,
["y"] = 0.586,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.319,
},
{
["mounted"] = true,
["gt"] = 500002.075,
["taxi"] = true,
["t"] = 1792270668,
["run"] = 7,
["swimming"] = false,
["y"] = 0.574,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.321,
},
{
["mounted"] = true,
["gt"] = 500003.08,
["taxi"] = true,
["t"] = 1792270669,
["run"] = 7,
["swimming"] = false,
["y"] = 0.563,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.326,
},
{
["mounted"] = true,
["gt"] = 500004.081,
["taxi"] = true,
["t"] = 1792270670,
["run"] = 7,
["swimming"] = false,
["y"] = 0.553,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.333,
},
{
["mounted"] = true,
["gt"] = 500005.101,
["taxi"] = true,
["t"] = 1792270671,
["run"] = 7,
["swimming"] = false,
["y"] = 0.542,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.338,
},
{
["mounted"] = true,
["gt"] = 500006.114,
["taxi"] = true,
["t"] = 1792270672,
["run"] = 7,
["swimming"] = false,
["y"] = 0.531,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.339,
},
{
["mounted"] = true,
["gt"] = 500007.13,
["taxi"] = true,
["t"] = 1792270673,
["run"] = 7,
["swimming"] = false,
["y"] = 0.521,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.335,
},
{
["mounted"] = true,
["gt"] = 500008.137,
["taxi"] = true,
["t"] = 1792270674,
["run"] = 7,
["swimming"] = false,
["y"] = 0.51,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.329,
},
{
["mounted"] = true,
["gt"] = 500009.139,
["taxi"] = true,
["t"] = 1792270675,
["run"] = 7,
["swimming"] = false,
["y"] = 0.499,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1429,
["x"] = 0.322,
},
{
["mounted"] = true,
["gt"] = 500010.15,
["taxi"] = true,
["t"] = 1792270676,
["run"] = 7,
["swimming"] = false,
["y"] = 0.927,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.741,
},
{
["mounted"] = true,
["gt"] = 500011.169,
["taxi"] = true,
["t"] = 1792270677,
["run"] = 7,
["swimming"] = false,
["y"] = 0.902,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.737,
},
{
["mounted"] = true,
["gt"] = 500012.176,
["taxi"] = true,
["t"] = 1792270678,
["run"] = 7,
["swimming"] = false,
["y"] = 0.876,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.738,
},
{
["mounted"] = true,
["gt"] = 500013.186,
["taxi"] = true,
["t"] = 1792270679,
["run"] = 7,
["swimming"] = false,
["y"] = 0.849,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.741,
},
{
["mounted"] = true,
["gt"] = 500014.196,
["taxi"] = true,
["t"] = 1792270680,
["run"] = 7,
["swimming"] = false,
["y"] = 0.824,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.742,
},
{
["mounted"] = true,
["gt"] = 500015.201,
["taxi"] = true,
["t"] = 1792270681,
["run"] = 7,
["swimming"] = false,
["y"] = 0.797,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.738,
},
{
["mounted"] = true,
["gt"] = 500016.214,
["taxi"] = true,
["t"] = 1792270682,
["run"] = 7,
["swimming"] = false,
["y"] = 0.768,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.731,
},
{
["mounted"] = true,
["gt"] = 500017.221,
["taxi"] = true,
["t"] = 1792270683,
["run"] = 7,
["swimming"] = false,
["y"] = 0.743,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.723,
},
{
["mounted"] = true,
["gt"] = 500018.255,
["taxi"] = true,
["t"] = 1792270684,
["run"] = 7,
["swimming"] = false,
["y"] = 0.725,
["flying"] = false,
["inst"] = false,
["speed"] = 30.34231376647949,
["map"] = 1453,
["x"] = 0.717,
},
{
["mounted"] = false,
["gt"] = 500019.269,
["taxi"] = false,
["t"] = 1792270685,
["run"] = 7,
["swimming"] = false,
["y"] = 0.723,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.716,
},
{
["mounted"] = false,
["gt"] = 500020.274,
["taxi"] = false,
["t"] = 1792270686,
["run"] = 7,
["swimming"] = false,
["y"] = 0.724,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1453,
["x"] = 0.715,
},
{
["mounted"] = false,
["gt"] = 500021.279,
["taxi"] = false,
["t"] = 1792270687,
["run"] = 7,
["swimming"] = false,
["y"] = 0.729,
["flying"] = false,
["inst"] = false,
["speed"] = 7,
["map"] = 1453,
["x"] = 0.712,
},
{
["mounted"] = false,
["gt"] = 500022.296,
["taxi"] = false,
["t"] = 1792270688,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500023.301,
["taxi"] = false,
["t"] = 1792270689,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500024.314,
["taxi"] = false,
["t"] = 1792270690,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500025.325,
["taxi"] = false,
["t"] = 1792270691,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500026.338,
["taxi"] = false,
["t"] = 1792270692,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500027.346,
["taxi"] = false,
["t"] = 1792270693,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500028.364,
["taxi"] = false,
["t"] = 1792270694,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500029.364,
["taxi"] = false,
["t"] = 1792270695,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500030.365,
["taxi"] = false,
["t"] = 1792270696,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500031.382,
["taxi"] = false,
["t"] = 1792270697,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500032.398,
["taxi"] = false,
["t"] = 1792270698,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500033.412,
["taxi"] = false,
["t"] = 1792270699,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500034.428,
["taxi"] = false,
["t"] = 1792270700,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500035.446,
["taxi"] = false,
["t"] = 1792270701,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500036.463,
["taxi"] = false,
["t"] = 1792270702,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
{
["mounted"] = false,
["gt"] = 500037.479,
["taxi"] = false,
["t"] = 1792270703,
["run"] = 7,
["swimming"] = false,
["y"] = 0.731,
["flying"] = false,
["inst"] = false,
["speed"] = 0,
["map"] = 1453,
["x"] = 0.711,
},
},
},
["notes"] = {
},
["api"] = {
},
["id"] = "T1a",
["startedAt"] = 1792269451,
["status"] = "open",
["events"] = {
},
["title"] = "Taxi flag and position jumps over time (also covers T2, T3, T4)",
["build"] = "1.60.1 build 70450",
},
["P0"] = {
["title"] = "Presence of every candidate API and event name",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["summary"] = {
["count"] = 53,
["list"] = "GetLootSourceInfo=function GetLootSlotInfo=function GetLootSlotType=function GetLootSlotLink=function GetNumLootItems=function LootFrame=table UnitOnTaxi=function GetUnitSpeed=function UnitIsAFK=function UnitIsDND=function IsMounted=function IsFlying=function IsSwimming=function IsFalling=function IsResting=function UnitIsDeadOrGhost=function GetItemInfo=function GetItemInfoInstant=function C_Item.GetItemInfo=function C_Item.GetItemInfoInstant=function C_Item.RequestLoadItemDataByID=function C_Item.GetItemCount=function C_Container.GetContainerNumSlots=function C_Container.GetContainerItemInfo=function C_Container.GetContainerItemLink=function C_Map.GetBestMapForUnit=function C_Map.GetPlayerMapPosition=function C_Map.GetMapInfoAtPosition=function C_Map.GetMapHighlightInfoAtPosition=function C_Map.GetMapWorldSize=function C_Map.GetWorldPosFromMapPos=function C_Map.GetMapRectOnMap=function C_EventUtils.IsEventValid=function issecretvalue=function C_Secrets=table C_RestrictedActions=table C_CombatLog=table C_DamageMeter=table C_LootHistory=table C_Loot=table C_MerchantFrame=table C_Mail=table C_TradeInfo=table C_QuestLog=table C_TaxiMap=table Settings=table C_SettingsUtil=table hooksecurefunc=function WorldMapFrame=table WorldMapFrame.ScrollContainer=table CreateVector2D=function debugprofilestop=function GetTimePreciseSec=function",
},
["fn"] = "present",
},
{
["summary"] = {
["count"] = 2,
["list"] = "GetContainerNumSlots GetContainerItemInfo",
},
["fn"] = "absent",
},
{
["fn"] = "IsEventValid(LOOT_OPENED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(LOOT_SLOT_CLEARED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(LOOT_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(CHAT_MSG_LOOT)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(CHAT_MSG_MONEY)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MERCHANT_SHOW)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MERCHANT_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(QUEST_TURNED_IN)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_SHOW)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(MAIL_INBOX_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TRADE_SHOW)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TRADE_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TRADE_MONEY_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TRADE_ACCEPT_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(UNIT_SPELLCAST_SUCCEEDED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_CONTROL_LOST)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_CONTROL_GAINED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TAXIMAP_OPENED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(TAXIMAP_CLOSED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_FLAGS_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_UPDATE_RESTING)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_XP_UPDATE)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(BAG_UPDATE_DELAYED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(ITEM_DATA_LOAD_RESULT)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(GET_ITEM_INFO_RECEIVED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "P0",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["H2"] = {
["notes"] = {
"part of a red square around Sentinel Hill, not completely filled in. I will upload a screenshot of it.",
},
["api"] = {
},
["id"] = "H2",
["startedAt"] = 1792269616,
["square"] = {
["mouseEnabled"] = false,
["parentLevel"] = 3,
["parentStrata"] = "MEDIUM",
["t"] = 1792270041,
["squareLevel"] = 4,
["parent"] = "canvas (unnamed)",
},
["status"] = "open",
["title"] = "Map overlay host: a test square on the world map",
["events"] = {
},
["build"] = "1.60.1 build 70450",
},
["I2"] = {
["title"] = "Bags: readable item fields and scan cost",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "bag scan",
["present"] = true,
["summary"] = {
["items"] = 26,
["secretResults"] = 0,
["errors"] = 0,
["elapsed"] = "0.74 debugprofilestop ms",
["slots"] = 44,
},
},
{
["fn"] = "GetContainerItemInfo(0,1)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["itemName"] = {
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
["hasLoot"] = {
["value"] = false,
["type"] = "boolean",
},
["hyperlink"] = {
["value"] = "|cnIQ1:|Hitem:6948::::::::14:1482::75:::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 63,
},
["iconFileID"] = {
["value"] = 134414,
["type"] = "number",
},
["hasNoValue"] = {
["value"] = true,
["type"] = "boolean",
},
["isLocked"] = {
["value"] = false,
["type"] = "boolean",
},
["itemID"] = {
["value"] = 6948,
["type"] = "number",
},
["isBound"] = {
["value"] = true,
["type"] = "boolean",
},
["stackCount"] = {
["value"] = 1,
["type"] = "number",
},
["isFiltered"] = {
["value"] = false,
["type"] = "boolean",
},
["isReadable"] = {
["value"] = false,
["type"] = "boolean",
},
["quality"] = {
["value"] = 1,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "GetContainerItemInfo(0,2)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["itemName"] = {
["value"] = "Elixir of Minor Spirit",
["type"] = "string",
["len"] = 22,
},
["hasLoot"] = {
["value"] = false,
["type"] = "boolean",
},
["hyperlink"] = {
["value"] = "|cnIQ1:|Hitem:250344::::::::14:1482:::::::::|h[Elixir of Minor Spirit]|h|r",
["type"] = "string",
["len"] = 74,
},
["iconFileID"] = {
["value"] = 134736,
["type"] = "number",
},
["hasNoValue"] = {
["value"] = false,
["type"] = "boolean",
},
["isLocked"] = {
["value"] = false,
["type"] = "boolean",
},
["itemID"] = {
["value"] = 250344,
["type"] = "number",
},
["isBound"] = {
["value"] = false,
["type"] = "boolean",
},
["stackCount"] = {
["value"] = 5,
["type"] = "number",
},
["isFiltered"] = {
["value"] = false,
["type"] = "boolean",
},
["isReadable"] = {
["value"] = false,
["type"] = "boolean",
},
["quality"] = {
["value"] = 1,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "GetContainerItemInfo(0,3)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["itemName"] = {
["value"] = "Brilliant Smallfish",
["type"] = "string",
["len"] = 19,
},
["hasLoot"] = {
["value"] = false,
["type"] = "boolean",
},
["hyperlink"] = {
["value"] = "|cnIQ1:|Hitem:6290::::::::14:1482:::::::::|h[Brilliant Smallfish]|h|r",
["type"] = "string",
["len"] = 69,
},
["iconFileID"] = {
["value"] = 133893,
["type"] = "number",
},
["hasNoValue"] = {
["value"] = false,
["type"] = "boolean",
},
["isLocked"] = {
["value"] = false,
["type"] = "boolean",
},
["itemID"] = {
["value"] = 6290,
["type"] = "number",
},
["isBound"] = {
["value"] = false,
["type"] = "boolean",
},
["stackCount"] = {
["value"] = 10,
["type"] = "number",
},
["isFiltered"] = {
["value"] = false,
["type"] = "boolean",
},
["isReadable"] = {
["value"] = false,
["type"] = "boolean",
},
["quality"] = {
["value"] = 1,
["type"] = "number",
},
},
},
},
},
},
},
},
["id"] = "I2",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["I1"] = {
["title"] = "Item data: sell price, bind type, async behaviour",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "C_Item.GetItemInfo(6948)",
["present"] = true,
["returns"] = {
{
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:6948::::::::14:1482:::::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 61,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(6948)",
["present"] = true,
["returns"] = {
{
["value"] = "Hearthstone",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:6948::::::::14:1482:::::::::|h[Hearthstone]|h|r",
["type"] = "string",
["len"] = 61,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(6948)",
["present"] = true,
["returns"] = {
{
["value"] = 6948,
["type"] = "number",
},
{
["value"] = "Miscellaneous",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "Junk",
["type"] = "string",
["len"] = 4,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134414,
["type"] = "number",
},
{
["value"] = 15,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(2589)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(2589)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(2589)",
["present"] = true,
["returns"] = {
{
["value"] = 2589,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Cloth",
["type"] = "string",
["len"] = 5,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(2770)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(2770)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(2770)",
["present"] = true,
["returns"] = {
{
["value"] = 2770,
["type"] = "number",
},
{
["value"] = "Trade Goods",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "Metal & Stone",
["type"] = "string",
["len"] = 13,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 134566,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(117)",
["present"] = true,
["returns"] = {
{
["value"] = "Tough Jerky",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:117::::::::14:1482:::::::::|h[Tough Jerky]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetItemInfo(117)",
["present"] = true,
["returns"] = {
{
["value"] = "Tough Jerky",
["type"] = "string",
["len"] = 11,
},
{
["value"] = "|cnIQ1:|Hitem:117::::::::14:1482:::::::::|h[Tough Jerky]|h|r",
["type"] = "string",
["len"] = 60,
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = 20,
["type"] = "number",
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(117)",
["present"] = true,
["returns"] = {
{
["value"] = 117,
["type"] = "number",
},
{
["value"] = "Consumable",
["type"] = "string",
["len"] = 10,
},
{
["value"] = "Food & Drink",
["type"] = "string",
["len"] = 12,
},
{
["value"] = "INVTYPE_NON_EQUIP_IGNORE",
["type"] = "string",
["len"] = 24,
},
{
["value"] = 133972,
["type"] = "number",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = 5,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(19019)",
["present"] = true,
["returns"] = {
{
["value"] = 19019,
["type"] = "number",
},
{
["value"] = "Weapon",
["type"] = "string",
["len"] = 6,
},
{
["value"] = "One-Handed Swords",
["type"] = "string",
["len"] = 17,
},
{
["value"] = "INVTYPE_WEAPON",
["type"] = "string",
["len"] = 14,
},
{
["value"] = 135349,
["type"] = "number",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = 7,
["type"] = "number",
},
},
},
{
["fn"] = "C_Item.GetItemInfo(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "GetItemInfo(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.GetItemInfoInstant(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(19019)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "C_Item.RequestLoadItemDataByID(999999)",
["present"] = true,
["returns"] = {
},
},
{
["fn"] = "IsEventValid(ITEM_DATA_LOAD_RESULT)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(GET_ITEM_INFO_RECEIVED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "I1",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["H1"] = {
["title"] = "Place names for map coordinates",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.528, 0.535)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.578, 0.535)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.478, 0.535)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.528, 0.585)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapInfoAtPosition(1436, 0.528, 0.485)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapHighlightInfoAtPosition(center)",
["present"] = true,
["returns"] = {
},
},
},
},
},
["id"] = "H1",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["L2"] = {
["title"] = "LOOT_SLOT_CLEARED per slot",
["notes"] = {
},
["events"] = {
["LOOT_SLOT_CLEARED"] = {
["registerCall"] = "returned normally",
["delivered"] = 9,
["samples"] = {
{
["gt"] = 502902.209,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273568,
["n"] = 1,
["restr"] = 0,
},
{
["gt"] = 502902.209,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273568,
["n"] = 1,
["restr"] = 0,
},
{
["gt"] = 502902.959,
["args"] = {
{
["value"] = 2,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273569,
["n"] = 1,
["restr"] = 0,
},
{
["n"] = 1,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.417,
},
},
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273641,
["gt"] = 502975.72,
["restr"] = 0,
},
{
["n"] = 1,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.417,
},
},
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 133,
["t"] = 1792273641,
["gt"] = 502975.72,
["restr"] = 0,
},
{
["before"] = {
["event"] = "PLAYER_MONEY",
["dt"] = 0.133,
},
["gt"] = 502976.27,
["args"] = {
{
["value"] = 2,
["type"] = "number",
},
},
["money"] = 142,
["t"] = 1792273642,
["n"] = 1,
["restr"] = 0,
},
{
["gt"] = 502995.133,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 142,
["t"] = 1792273661,
["n"] = 1,
["restr"] = 2,
},
{
["n"] = 1,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0,
},
},
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 142,
["t"] = 1792273690,
["gt"] = 503024.321,
["restr"] = 0,
},
{
["gt"] = 503133.337,
["args"] = {
{
["value"] = 1,
["type"] = "number",
},
},
["money"] = 145,
["t"] = 1792273799,
["n"] = 1,
["restr"] = 0,
},
},
["attemptedAt"] = 1792273515,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "L2",
["startedAt"] = 1792273515,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["L3"] = {
["title"] = "Loot window slot data and source GUID",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "default",
["t"] = 1792270407,
["gt"] = 499741.037,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133788,
["type"] = "number",
},
{
["value"] = "8 Copper",
["type"] = "string",
["len"] = 8,
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-4621-0-1-95-4B8D905020",
["type"] = "string",
["len"] = 33,
},
{
["value"] = 8,
["type"] = "number",
},
},
},
},
},
{
["label"] = "default",
["t"] = 1792271257,
["gt"] = 500591.072,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133722,
["type"] = "number",
},
{
["value"] = "Broken Boar Tusk",
["type"] = "string",
["len"] = 16,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 0,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ0:|Hitem:3171::::::::14:1482:::::::::|h[Broken Boar Tusk]|h|r",
["type"] = "string",
["len"] = 66,
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-6783-0-1-157-38184B766D",
["type"] = "string",
["len"] = 34,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
},
{
["label"] = "default",
["t"] = 1792271315,
["gt"] = 500649.599,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134252,
["type"] = "number",
},
{
["value"] = "Light Leather",
["type"] = "string",
["len"] = 13,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2318::::::::14:1482:::::::::|h[Light Leather]|h|r",
["type"] = "string",
["len"] = 63,
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-6783-0-1-157-22EE329824",
["type"] = "string",
["len"] = 34,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
},
{
["gt"] = 502895.59,
["label"] = "default",
["t"] = 1792273561,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "2",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134187,
["type"] = "number",
},
{
["value"] = "Earthroot",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 2,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2449::::::::7:1484:::::::::|h[Earthroot]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-4615-1-2-1619-C8E1A08EAE",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 133963,
["type"] = "number",
},
{
["value"] = "Frilled Lichen",
["type"] = "string",
["len"] = 14,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 2,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(2)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(2)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ2:|Hitem:249399::::::::7:1484:::::::::|h[Frilled Lichen]|h|r",
["type"] = "string",
["len"] = 65,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-4615-1-2-1619-C8E1A08EAE",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 502973.152,
["label"] = "default",
["t"] = 1792273639,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "2",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133788,
["type"] = "number",
},
{
["value"] = "9 Copper",
["type"] = "string",
["len"] = 8,
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-4615-1-2-2950-696F1CD830",
["type"] = "string",
["len"] = 35,
},
{
["value"] = 9,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = 132889,
["type"] = "number",
},
{
["value"] = "Linen Cloth",
["type"] = "string",
["len"] = 11,
},
{
["value"] = 2,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(2)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(2)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2589::::::::7:1484:::::::::|h[Linen Cloth]|h|r",
["type"] = "string",
["len"] = 60,
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(2)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-4615-1-2-2950-696F1CD830",
["type"] = "string",
["len"] = 35,
},
{
["value"] = 2,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 502992.548,
["label"] = "herb",
["t"] = 1792273658,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134187,
["type"] = "number",
},
{
["value"] = "Earthroot",
["type"] = "string",
["len"] = 9,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2449::::::::7:1484:::::::::|h[Earthroot]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-4615-1-2-1619-155E443212",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
["restr"] = 2,
},
{
["gt"] = 503022.737,
["label"] = "default",
["t"] = 1792273688,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 133788,
["type"] = "number",
},
{
["value"] = "3 Copper",
["type"] = "string",
["len"] = 8,
},
{
["value"] = 0,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["type"] = "nil",
},
},
},
{
["guidType"] = "Creature",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "Creature-0-4615-1-2-2950-E454079710",
["type"] = "string",
["len"] = 35,
},
{
["value"] = 3,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 503131.044,
["label"] = "herb",
["t"] = 1792273797,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134190,
["type"] = "number",
},
{
["value"] = "Silverleaf",
["type"] = "string",
["len"] = 10,
},
{
["value"] = 3,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:765::::::::7:1484:::::::::|h[Silverleaf]|h|r",
["type"] = "string",
["len"] = 58,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-4615-1-2-1617-FCB7D79ACB",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 3,
["type"] = "number",
},
},
},
},
["restr"] = 0,
},
{
["gt"] = 503291.341,
["label"] = "mining",
["t"] = 1792273957,
["restr"] = 0,
["results"] = {
{
["fn"] = "GetNumLootItems()",
["present"] = true,
["summary"] = {
["count"] = "1",
["lootFrameShown"] = "true",
},
},
{
["fn"] = "GetLootSlotInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = 134566,
["type"] = "number",
},
{
["value"] = "Copper Ore",
["type"] = "string",
["len"] = 10,
},
{
["value"] = 1,
["type"] = "number",
},
{
["type"] = "nil",
},
{
["value"] = 1,
["type"] = "number",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
{
["type"] = "nil",
},
{
["type"] = "nil",
},
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetLootSlotType(1)",
["present"] = true,
["returns"] = {
{
["value"] = 1,
["type"] = "number",
},
},
},
{
["fn"] = "GetLootSlotLink(1)",
["present"] = true,
["returns"] = {
{
["value"] = "|cnIQ1:|Hitem:2770::::::::8:1491:::::::::|h[Copper Ore]|h|r",
["type"] = "string",
["len"] = 59,
},
},
},
{
["guidType"] = "GameObject",
["fn"] = "GetLootSourceInfo(1)",
["present"] = true,
["returns"] = {
{
["value"] = "GameObject-0-6782-0-4-1731-048BFFB770",
["type"] = "string",
["len"] = 37,
},
{
["value"] = 1,
["type"] = "number",
},
},
},
},
},
},
["id"] = "L3",
["startedAt"] = 1792270407,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["M1"] = {
["title"] = "Merchant open/close, sale and purchase order versus money",
["notes"] = {
},
["events"] = {
["MERCHANT_SHOW"] = {
["registerCall"] = "returned normally",
["delivered"] = 2,
["samples"] = {
{
["gt"] = 503757.602,
["args"] = {
},
["money"] = 18236,
["t"] = 1792274423,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 503828.546,
["args"] = {
},
["money"] = 18232,
["t"] = 1792274494,
["n"] = 0,
["restr"] = 0,
},
},
["attemptedAt"] = 1792274417,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "M1",
["startedAt"] = 1792274417,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["L1"] = {
["title"] = "LOOT_OPENED payload and order versus PLAYER_MONEY",
["notes"] = {
},
["events"] = {
["LOOT_OPENED"] = {
["registerCall"] = "returned normally",
["delivered"] = 5,
["samples"] = {
{
["gt"] = 499731.509,
["args"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18548,
["t"] = 1792270397,
["n"] = 2,
},
{
["gt"] = 499788.318,
["args"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18556,
["t"] = 1792270454,
["after"] = {
{
["event"] = "PLAYER_MONEY",
["dt"] = 0.509,
},
},
["n"] = 2,
},
{
["gt"] = 499823.517,
["args"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18566,
["t"] = 1792270489,
["n"] = 2,
},
{
["gt"] = 499858.37,
["args"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18566,
["t"] = 1792270524,
["n"] = 2,
},
{
["gt"] = 499882.235,
["args"] = {
{
["value"] = true,
["type"] = "boolean",
},
{
["value"] = false,
["type"] = "boolean",
},
},
["money"] = 18566,
["t"] = 1792270548,
["n"] = 2,
},
},
["attemptedAt"] = 1792270366,
["isEventRegistered"] = true,
},
},
["api"] = {
},
["id"] = "L1",
["startedAt"] = 1792270366,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["P2"] = {
["title"] = "Restriction and state getters found by P1 (no-argument getters and the restriction enum)",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "default",
["t"] = 1792271162,
["gt"] = 500496.699,
["results"] = {
{
["fn"] = "C_Secrets.HasSecretRestrictions()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_CombatLog.IsCombatLogRestricted()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Loot.IsLegacyLootModeEnabled()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney()",
["present"] = true,
["error"] = "bad argument #1 to '?' (Usage: local inboxItemHasMoneyAttached = C_Mail.HasInboxMoney(inboxIndex))",
},
{
["fn"] = "C_MerchantFrame.GetNumJunkItems()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_MerchantFrame.IsSellAllJunkEnabled()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["summary"] = {
["count"] = 6,
["values"] = "Combat=0 Encounter=1 ChallengeMode=2 PvPMatch=3 Map=4 Chat=5",
},
["fn"] = "Enum.AddOnRestrictionType",
},
{
["fn"] = "GetAddOnRestrictionState(Combat)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Combat)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Encounter)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Encounter)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(ChallengeMode)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(ChallengeMode)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(PvPMatch)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(PvPMatch)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Map)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Map)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Chat)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Chat)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
},
},
{
["label"] = "default",
["t"] = 1792271225,
["gt"] = 500559.765,
["results"] = {
{
["fn"] = "C_Secrets.HasSecretRestrictions()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_CombatLog.IsCombatLogRestricted()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Loot.IsLegacyLootModeEnabled()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "C_Mail.HasInboxMoney()",
["present"] = true,
["error"] = "bad argument #1 to '?' (Usage: local inboxItemHasMoneyAttached = C_Mail.HasInboxMoney(inboxIndex))",
},
{
["fn"] = "C_MerchantFrame.GetNumJunkItems()",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "C_MerchantFrame.IsSellAllJunkEnabled()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["summary"] = {
["count"] = 6,
["values"] = "Combat=0 Encounter=1 ChallengeMode=2 PvPMatch=3 Map=4 Chat=5",
},
["fn"] = "Enum.AddOnRestrictionType",
},
{
["fn"] = "GetAddOnRestrictionState(Combat)",
["present"] = true,
["returns"] = {
{
["value"] = 2,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Combat)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Encounter)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Encounter)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(ChallengeMode)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(ChallengeMode)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(PvPMatch)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(PvPMatch)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Map)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Map)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "GetAddOnRestrictionState(Chat)",
["present"] = true,
["returns"] = {
{
["value"] = 0,
["type"] = "number",
},
},
},
{
["fn"] = "IsAddOnRestrictionActive(Chat)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "P2",
["startedAt"] = 1792271162,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["S1"] = {
["title"] = "Map position in the open world and in an instance",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "C_Map.GetBestMapForUnit(player)",
["present"] = true,
["returns"] = {
{
["value"] = 1436,
["type"] = "number",
},
},
},
{
["summary"] = {
["map"] = "1436",
["x"] = "0.52837765216827",
["y"] = "0.53540968894958",
},
["fn"] = "player position",
},
{
["fn"] = "C_Map.GetMapInfo(map)",
["present"] = true,
["returns"] = {
{
["type"] = "table",
["fields"] = {
["mapType"] = {
["value"] = 3,
["type"] = "number",
},
["mapID"] = {
["value"] = 1436,
["type"] = "number",
},
["name"] = {
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
["parentMapID"] = {
["value"] = 1415,
["type"] = "number",
},
["flags"] = {
["value"] = 2,
["type"] = "number",
},
},
},
},
},
{
["fn"] = "C_Map.GetMapWorldSize(map)",
["present"] = true,
["returns"] = {
{
["value"] = 3499.999755859375,
["type"] = "number",
},
{
["value"] = 2333.3330078125,
["type"] = "number",
},
},
},
{
["fn"] = "IsInInstance()",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
{
["value"] = "none",
["type"] = "string",
["len"] = 4,
},
},
},
{
["fn"] = "GetZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Westfall",
["type"] = "string",
["len"] = 8,
},
},
},
{
["fn"] = "GetSubZoneText()",
["present"] = true,
["returns"] = {
{
["value"] = "Sentinel Hill",
["type"] = "string",
["len"] = 13,
},
},
},
},
},
},
["id"] = "S1",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["A1"] = {
["title"] = "AFK flag and related state",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "session1",
["t"] = 1792269244,
["gt"] = 498578.227,
["results"] = {
{
["fn"] = "UnitIsAFK(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitIsDND(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsResting()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitIsDeadOrGhost(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_FLAGS_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_UPDATE_RESTING)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
{
["label"] = "afk",
["t"] = 1792269343,
["gt"] = 498677.407,
["results"] = {
{
["fn"] = "UnitIsAFK(player)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitIsDND(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsResting()",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "UnitIsDeadOrGhost(player)",
["present"] = true,
["returns"] = {
{
["value"] = false,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_FLAGS_CHANGED)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
{
["fn"] = "IsEventValid(PLAYER_UPDATE_RESTING)",
["present"] = true,
["returns"] = {
{
["value"] = true,
["type"] = "boolean",
},
},
},
},
},
},
["id"] = "A1",
["startedAt"] = 1792269244,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
["P1"] = {
["title"] = "Function names inside the C_* tables found by P0 (names only, nothing is called)",
["notes"] = {
},
["events"] = {
},
["api"] = {
{
["label"] = "default",
["t"] = 1792270236,
["gt"] = 499569.901,
["results"] = {
{
["summary"] = {
["count"] = 27,
["names"] = "CanCompareUnitTokens GetPowerTypeSecrecy GetSpellAuraSecrecy GetSpellCastSecrecy GetSpellCooldownSecrecy HasSecretRestrictions ShouldActionCooldownBeSecret ShouldAurasBeSecret ShouldCooldownsBeSecret ShouldSpellAuraBeSecret ShouldSpellBookItemCooldownBeSecret ShouldSpellCooldownBeSecret ShouldTotemSlotBeSecret ShouldTotemSpellBeSecret ShouldUnitAuraIndexBeSecret ShouldUnitAuraInstanceBeSecret ShouldUnitAuraSlotBeSecret ShouldUnitComparisonBeSecret ShouldUnitHealthMaxBeSecret ShouldUnitIdentityBeSecret ShouldUnitPowerBeSecret ShouldUnitPowerMaxBeSecret ShouldUnitSpellCastBeSecret ShouldUnitSpellCastingBeSecret ShouldUnitStatsBeSecret ShouldUnitThreatStateBeSecret ShouldUnitThreatValuesBeSecret",
},
["fn"] = "C_Secrets",
},
{
["summary"] = {
["count"] = 3,
["names"] = "CheckAllowProtectedFunctions GetAddOnRestrictionState IsAddOnRestrictionActive",
},
["fn"] = "C_RestrictedActions",
},
{
["summary"] = {
["count"] = 5,
["names"] = "GetAllEncounterInfos GetInfoForEncounter GetLootHistoryTime GetSortedDropsForEncounter GetSortedInfoForDrop",
},
["fn"] = "C_LootHistory",
},
{
["summary"] = {
["count"] = 2,
["names"] = "GetLootRollDuration IsLegacyLootModeEnabled",
},
["fn"] = "C_Loot",
},
{
["summary"] = {
["count"] = 7,
["names"] = "GetBuybackItemID GetItemInfo GetMerchantCurrencies GetNumJunkItems IsMerchantItemRefundable IsSellAllJunkEnabled SellAllJunkItems",
},
["fn"] = "C_MerchantFrame",
},
{
["summary"] = {
["count"] = 5,
["names"] = "CanCheckInbox GetCraftingOrderMailInfo HasInboxMoney IsCommandPending SetOpeningAll",
},
["fn"] = "C_Mail",
},
{
["summary"] = {
["count"] = 4,
["names"] = "AddTradeMoney PickupTradeMoney SetTradeMoney ShouldShowTradeOfferWarning",
},
["fn"] = "C_TradeInfo",
},
{
["summary"] = {
["count"] = 3,
["names"] = "GetAllTaxiNodes GetTaxiNodesForMap ShouldMapShowTaxiNodes",
},
["fn"] = "C_TaxiMap",
},
{
["summary"] = {
["count"] = 11,
["names"] = "ApplyFilterSettings AreFilteredEventsEnabled ClearEntries DoesObjectMatchFilter GetEntryRetentionTime GetMessageLimit IsCombatLogRestricted RefilterEntries SetEntryRetentionTime SetFilteredEventsEnabled SetMessageLimit",
},
["fn"] = "C_CombatLog",
},
{
["summary"] = {
["count"] = 93,
["names"] = "AbandonQuest AddQuestWatch AddWorldQuestWatch CanAbandonQuest DoesQuestAwardReputationWithFaction GetAbandonQuest GetAbandonQuestItems GetActivePreyQuest GetActiveThreatMaps GetAllCompletedQuestIDs GetBountiesForMapID GetBountySetInfoForMapID GetDistanceSqToQuest GetHeaderIndexForQuest GetInfo GetLogIndexForQuestID GetMapForQuestPOIs GetMaxNumQuests GetMaxNumQuestsCanAccept GetNextWaypoint GetNextWaypointForMap GetNextWaypointText GetNumQuestLogEntries GetNumQuestObjectives GetNumQuestWatches GetNumWorldQuestWatches GetQuestAdditionalHighlights GetQuestDetailsTheme GetQuestDifficultyLevel GetQuestIDForLogIndex GetQuestIDForQuestWatchIndex GetQuestIDForWorldQuestWatchIndex GetQuestLogMajorFactionReputationRewards GetQuestLogPortraitGiver GetQuestObjectives GetQuestRewardCurrencies GetQuestRewardCurrencyInfo GetQuestTagInfo GetQuestTimers GetQuestType GetQuestWatchType GetQuestsOnMap GetRequiredMoney GetSelectedQuest GetSuggestedGroupSize GetTimeAllowed GetTitleForLogIndex GetTitleForQuestID GetTrivialRange GetZoneStoryInfo HasActiveThreats IsAccountQuest IsComplete IsEliteQuest IsFailed IsImportantQuest IsMetaQuest IsOnMap IsOnQuest IsPushableQuest IsQuestBounty IsQuestCalling IsQuestCriteriaForBounty IsQuestDisabledForSession IsQuestFlaggedCompleted IsQuestFlaggedCompletedOnAccount IsQuestFromContentPush IsQuestInvasion IsQuestReplayable IsQuestReplayedRecently IsQuestTask IsQuestTrivial IsRepeatableQuest IsThreatQuest IsUnitOnQuest IsWorldQuest QuestCanHaveWarModeBonus QuestContainsFirstTimeRepBonusForPlayer QuestHasQuestSessionBonus QuestHasWarModeBonus",
},
["fn"] = "C_QuestLog",
},
},
},
},
["id"] = "P1",
["startedAt"] = 1792270236,
["status"] = "open",
["build"] = "1.60.1 build 70450",
},
},
["refs"] = {
{
["gt"] = 499771.668,
["args"] = {
},
["money"] = 18556,
["t"] = 1792270437,
["n"] = 0,
},
{
["before"] = {
["event"] = "LOOT_OPENED",
["dt"] = 0.509,
},
["gt"] = 499788.827,
["args"] = {
},
["money"] = 18566,
["t"] = 1792270454,
["n"] = 0,
},
{
["gt"] = 499936.793,
["args"] = {
},
["money"] = 18456,
["t"] = 1792270602,
["n"] = 0,
},
{
["before"] = {
["event"] = "LOOT_SLOT_CLEARED",
["dt"] = 0.417,
},
["n"] = 0,
["after"] = {
{
["event"] = "LOOT_SLOT_CLEARED",
["dt"] = 0.133,
},
},
["args"] = {
},
["money"] = 142,
["t"] = 1792273642,
["gt"] = 502976.137,
["restr"] = 0,
},
{
["before"] = {
["event"] = "LOOT_SLOT_CLEARED",
["dt"] = 0,
},
["gt"] = 503024.321,
["args"] = {
},
["money"] = 145,
["t"] = 1792273690,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 503769.537,
["args"] = {
},
["money"] = 18242,
["t"] = 1792274435,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 503771.978,
["args"] = {
},
["money"] = 18232,
["t"] = 1792274438,
["n"] = 0,
["restr"] = 0,
},
{
["gt"] = 503832.879,
["args"] = {
},
["money"] = 18149,
["t"] = 1792274498,
["n"] = 0,
["restr"] = 0,
},
{
["before"] = {
["event"] = "QUEST_TURNED_IN",
["dt"] = 0.041,
},
["gt"] = 505089.348,
["args"] = {
},
["money"] = 323,
["t"] = 1792275755,
["restr"] = 0,
["n"] = 0,
},
},
},
["loads"] = 21,
["transcript"] = "loaded. Type /gidiag for commands. (load count 21)\nWARNING: about to register QUEST_TURNED_IN. If an ADDON_ACTION_FORBIDDEN popup appears, that event is RESTRICTED:\nreport the popup text. Nothing changes on your character. Type /reload afterwards before any further registration.\nQUEST_TURNED_IN: registered (IsEventRegistered true). Now do this: /gidiag lab reg QUEST_TURNED_IN ; turn in a quest with a copper reward and an item\nCapturing the first 40 payloads. Then /gidiag lab watch, /gidiag lab report, /reload.\nPhase 3a lab report  1.60.1 build 70450  at 1792275764\nP0 [review, suggested] Presence of every candidate API and event name\n   api runs: 1\nI1 [review, suggested] Item data: sell price, bind type, async behaviour\n   api runs: 1\nI2 [review, suggested] Bags: readable item fields and scan cost\n   api runs: 1\nA1 [review, suggested] AFK flag and related state\n   api runs: 2\nS1 [review, suggested] Map position in the open world and in an instance\n   api runs: 1\nT2 [review, suggested] Movement speed, mounted, flying, swimming, taxi flags (single snapshot)\n   api runs: 1\nT1a [review, suggested] Taxi flag and position jumps over time (also covers T2, T3, T4)\n   track: 134 samples, maxSpeed 30.342313766479, taxi 81, maxJump 0.03, mapChanges 3\nP1 [review, suggested] Function names inside the C_* tables found by P0 (names only, nothing is called)\n   api runs: 1\nP2 [review, suggested] Restriction and state getters found by P1 (no-argument getters and the restriction enum)\n   api runs: 2\nI1b [not run] Item data load completion event (async item info)\nH1 [review, suggested] Place names for map coordinates\n   api runs: 1\nH2 [review, suggested] Map overlay host: a test square on the world map\n   square: shown\n   note: part of a red square around Sentinel Hill, not completely filled in. I will upload a screenshot of it.\nL3 [review, suggested] Loot window slot data and source GUID\n   api runs: 9\nL1 [pass, suggested] LOOT_OPENED payload and order versus PLAYER_MONEY\n   LOOT_OPENED: delivered 5, samples 5, IsEventRegistered true\nL2 [pass, suggested] LOOT_SLOT_CLEARED per slot\n   LOOT_SLOT_CLEARED: delivered 9, samples 9, IsEventRegistered true\nM1 [pass, suggested] Merchant open/close, sale and purchase order versus money\n   MERCHANT_SHOW: delivered 2, samples 2, IsEventRegistered true\nQ1 [pass, suggested] Quest turn-in payload\n   QUEST_TURNED_IN: delivered 1, samples 1, IsEventRegistered true\nX1 [not run] Mail events\nR1 [not run] Trade events\nT1b [not run] Taxi and control events\nC1 [not run] UNIT_SPELLCAST_SUCCEEDED (highest suspicion of the old popup)\nC2 [not run] CHAT_MSG_MONEY (only if L1 fails)",
["lastLoad"] = 1792274898,
}
