#!/usr/bin/env lua
-- Crosspaths real-Engine tests
-- Unlike test_engine.lua (which reimplements functions), this file loads the ACTUAL
-- Engine.lua via MockWoW.loadAddonModule and tests production code, pinning the
-- crash/correctness fixes from the audit so they cannot silently regress.

package.path = package.path .. ";./?.lua;./tests/?.lua"

local TestRunner = require("test_runner")
local MockWoW = require("mock_wow")

-- Fresh mock environment, then load the real Core (utilities) + Engine into it
local Crosspaths = MockWoW.setupMockEnvironment()
MockWoW.loadAddonModule("Core.lua", Crosspaths)
MockWoW.loadAddonModule("Engine.lua", Crosspaths)
local Engine = Crosspaths.Engine
Engine:Initialize()

local mockDB = Crosspaths.db -- the rich 13-player fixture from mock_wow

local function resetDB()
    Crosspaths.db = mockDB
end

-- Sanity: the loader wired real functions (not stubs)
TestRunner.runTest("real Engine loaded", function()
    TestRunner.assertType(Engine.GetStatsSummary, "function", "GetStatsSummary is a real function")
    TestRunner.assertType(Engine.GetZoneProgressionPatterns, "function", "GetZoneProgressionPatterns is real")
end)

-- Real GetStatsSummary over the fixture
TestRunner.runTest("real GetStatsSummary", function()
    resetDB()
    local stats = Engine:GetStatsSummary()
    TestRunner.assertEqual(stats.totalPlayers, 12, "fixture has 12 players")
    TestRunner.assertGreaterThan(stats.totalEncounters, 0, "totalEncounters computed from real data")
    TestRunner.assertNotNil(stats.oldestEncounter, "oldestEncounter set")
end)

-- Bug #10: nil count/firstSeen/lastSeen must not crash GetStatsSummary
TestRunner.runTest("GetStatsSummary survives nil fields (#10)", function()
    Crosspaths.db = {
        players = {
            ["Good-Realm"] = { count = 5, firstSeen = 1000, lastSeen = 2000, guild = "G" },
            ["Corrupt-Realm"] = { guild = "G" }, -- no count/firstSeen/lastSeen
        },
    }
    local ok, stats = pcall(function() return Engine:GetStatsSummary() end)
    TestRunner.assertTrue(ok, "no crash on corrupt saved-data fields")
    if ok then
        TestRunner.assertEqual(stats.totalPlayers, 2, "still counts both players")
        TestRunner.assertEqual(stats.totalEncounters, 5, "nil count treated as 0")
    end
    resetDB()
end)

-- Bug #8: search must rank before truncating, so the top-by-count survive a small limit
TestRunner.runTest("SearchPlayers ranks before truncating (#8)", function()
    Crosspaths.db = {
        players = {
            ["Axe1-Realm"] = { count = 10, lastSeen = 100, guild = "Axe Clan" },
            ["Axe2-Realm"] = { count = 20, lastSeen = 100, guild = "Axe Clan" },
            ["Axe3-Realm"] = { count = 30, lastSeen = 100, guild = "Axe Clan" },
            ["Axe4-Realm"] = { count = 40, lastSeen = 100, guild = "Axe Clan" },
            ["Axe5-Realm"] = { count = 50, lastSeen = 100, guild = "Axe Clan" },
        },
    }
    -- All 5 match "axe" via guild; with limit 2 the two HIGHEST counts must come back.
    local results = Engine:SearchPlayers("axe", 2)
    TestRunner.assertEqual(#results, 2, "respects limit")
    TestRunner.assertEqual(results[1].count, 50, "highest count first (not arbitrary pre-sort pick)")
    TestRunner.assertEqual(results[2].count, 40, "second highest second")
    resetDB()
end)

-- Bug #5: a UI request larger than the fixed cache size must not be capped
TestRunner.runTest("GetTopPlayers not capped by cache size (#5)", function()
    resetDB()
    local top12 = Engine:GetTopPlayers(12)
    TestRunner.assertEqual(#top12, 12, "returns 12 from a 12-player fixture, not a capped 10")
end)

-- Bug #4: encounters stat type must return real top players (not {})
TestRunner.runTest("GetTopPlayersByType('encounters') (#4)", function()
    resetDB()
    local top = Engine:GetTopPlayersByType("encounters", 5)
    TestRunner.assertEqual(#top, 5, "returns 5 top players by encounters")
    TestRunner.assertNotNil(top[1].name, "entries have a name for the copy-stats formatter")
    TestRunner.assertNotNil(top[1].count, "entries have a count")
end)

-- Bug #7: quest-line patterns must use a real player count, not # on a string-keyed
-- table (=> totalPlayers 0 and inf/nan likelihood).
TestRunner.runTest("GetZoneProgressionPatterns real math (#7)", function()
    local now = 1640995200 -- mock time()
    local function enc(zone, ago) return { zone = zone, timestamp = now - ago } end
    Crosspaths.db = {
        players = {
            ["P1-Realm"] = { count = 3, encounters = { enc("Elwynn Forest", 3000), enc("Westfall", 2000), enc("Redridge", 1000) } },
            ["P2-Realm"] = { count = 3, encounters = { enc("Elwynn Forest", 3000), enc("Westfall", 2000), enc("Redridge", 1000) } },
        },
    }
    local patterns = Engine:GetZoneProgressionPatterns()
    TestRunner.assertEqual(patterns.totalPlayers, 2, "totalPlayers reflects real path count (was hardcoded 0)")
    TestRunner.assertGreaterThan(#patterns.commonPaths, 0, "two players sharing a path => a common path")
    local likelihood = patterns.commonPaths[1] and patterns.commonPaths[1].likelihood or -1
    TestRunner.assertTrue(likelihood == likelihood, "likelihood is not NaN") -- NaN ~= NaN
    TestRunner.assertTrue(likelihood ~= math.huge and likelihood <= 100, "likelihood finite and <= 100%")
    resetDB()
end)

-- SortAndSlice powers the top guilds/zones lists
TestRunner.runTest("SortAndSlice: top guilds ordered/limited", function()
    resetDB()
    local guilds = Engine:GetTopGuilds(2)
    TestRunner.assertEqual(#guilds, 2, "limit respected")
    TestRunner.assertTrue(guilds[1].memberCount >= guilds[2].memberCount, "sorted by memberCount desc")
end)

TestRunner.runTest("SortAndSlice: top zones ordered", function()
    resetDB()
    local zones = Engine:GetTopZones(3)
    TestRunner.assertEqual(#zones, 3, "limit respected")
    TestRunner.assertTrue(zones[1].encounterCount >= zones[2].encounterCount, "sorted by encounterCount desc")
end)

-- Bug #9: a guild with several new members counts once, not per member
TestRunner.runTest("weekly newGuilds counts unique guilds (#9)", function()
    local now = 1640995200
    local recent = now - 3600
    Crosspaths.db = {
        players = {
            ["A-R"] = { count = 1, firstSeen = recent, lastSeen = recent, guild = "SameGuild" },
            ["B-R"] = { count = 1, firstSeen = recent, lastSeen = recent, guild = "SameGuild" },
            ["C-R"] = { count = 1, firstSeen = recent, lastSeen = recent, guild = "SameGuild" },
            ["D-R"] = { count = 1, firstSeen = recent, lastSeen = recent, guild = "OtherGuild" },
        },
    }
    local digest = Engine:GenerateWeeklyDigest()
    TestRunner.assertEqual(digest.newGuilds, 2, "3 members of SameGuild + 1 OtherGuild => 2 new guilds, not 4")
    resetDB()
end)

-- Shared Truncate helper (replaces inlined string.sub truncation)
TestRunner.runTest("Crosspaths:Truncate", function()
    TestRunner.assertEqual(Crosspaths:Truncate("short", 20), "short", "short strings unchanged")
    TestRunner.assertEqual(Crosspaths:Truncate("abcdefghij", 8), "abcde...", "long strings truncated with ellipsis")
    TestRunner.assertEqual(#Crosspaths:Truncate("abcdefghij", 8), 8, "result respects max length")
    TestRunner.assertEqual(Crosspaths:Truncate(nil, 8), "", "nil-safe")
end)

-- Design-system colour helper
TestRunner.runTest("Crosspaths:Colorize", function()
    TestRunner.assertEqual(Crosspaths:Colorize("Hi", "GOLD"), "|cFFFFD700Hi|r", "wraps in gold escape code")
    TestRunner.assertEqual(Crosspaths:Colorize("x", "GREEN"), "|cFF00FF00x|r", "green")
    TestRunner.assertEqual(Crosspaths:Colorize("x", "NOPE"), "|cFFFFFFFFx|r", "unknown name falls back to white")
end)

os.exit(TestRunner.printResults())
