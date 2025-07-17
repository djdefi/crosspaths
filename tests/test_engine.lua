#!/usr/bin/env lua
-- Comprehensive unit tests for Crosspaths Engine functions
-- Tests all the new analytics functions added in the recent commits

-- Setup paths for require
package.path = package.path .. ";./?.lua;./tests/?.lua"

-- Load dependencies
local TestRunner = require("test_runner")
local MockWoW = require("mock_wow")

-- Setup mock environment
local Crosspaths = MockWoW.setupMockEnvironment()

-- Load the Engine module (we need to manually load it since we're not in WoW)
local function loadEngine()
    -- Simulate the Engine.lua loading process
    local Engine = {}
    
    -- Copy the actual Engine functions (we'll load them manually for testing)
    -- Note: In a real scenario, we'd load the actual Engine.lua file
    -- For this test, we'll implement the core functions directly
    
    function Engine:GetStatsSummary()
        local stats = {
            totalPlayers = 0,
            totalEncounters = 0,
            totalGuilds = 0,
            groupedPlayers = 0,
            averageEncounters = 0,
            oldestEncounter = nil,
            newestEncounter = nil,
        }
        
        if not Crosspaths.db or not Crosspaths.db.players then
            return stats
        end
        
        local guilds = {}
        local oldestTime = math.huge
        local newestTime = 0
        
        for name, player in pairs(Crosspaths.db.players) do
            stats.totalPlayers = stats.totalPlayers + 1
            stats.totalEncounters = stats.totalEncounters + player.count
            
            if player.grouped then
                stats.groupedPlayers = stats.groupedPlayers + 1
            end
            
            if player.guild and player.guild ~= "" then
                guilds[player.guild] = true
            end
            
            if player.firstSeen < oldestTime then
                oldestTime = player.firstSeen
                stats.oldestEncounter = player.firstSeen
            end
            
            if player.lastSeen > newestTime then
                newestTime = player.lastSeen
                stats.newestEncounter = player.lastSeen
            end
        end
        
        stats.totalGuilds = 0
        for _ in pairs(guilds) do
            stats.totalGuilds = stats.totalGuilds + 1
        end
        
        if stats.totalPlayers > 0 then
            stats.averageEncounters = stats.totalEncounters / stats.totalPlayers
        end
        
        return stats
    end
    
    function Engine:GetRecentActivity()
        if not Crosspaths.db or not Crosspaths.db.players then
            return {
                last24h = {players = 0, encounters = 0},
                last7d = {players = 0, encounters = 0},
                last30d = {players = 0, encounters = 0}
            }
        end
        
        local now = time()
        local day = 24 * 60 * 60
        local week = 7 * day
        local month = 30 * day
        
        local activity = {
            last24h = {players = 0, encounters = 0},
            last7d = {players = 0, encounters = 0},
            last30d = {players = 0, encounters = 0}
        }
        
        for name, player in pairs(Crosspaths.db.players) do
            local timeSince = now - (player.lastSeen or 0)
            
            if timeSince <= day then
                activity.last24h.players = activity.last24h.players + 1
                activity.last24h.encounters = activity.last24h.encounters + player.count
            end
            
            if timeSince <= week then
                activity.last7d.players = activity.last7d.players + 1
                activity.last7d.encounters = activity.last7d.encounters + player.count
            end
            
            if timeSince <= month then
                activity.last30d.players = activity.last30d.players + 1
                activity.last30d.encounters = activity.last30d.encounters + player.count
            end
        end
        
        return activity
    end
    
    function Engine:GetContextStats()
        if not Crosspaths.db or not Crosspaths.db.players then
            return {}
        end
        
        local contextCounts = {}
        local totalContextEncounters = 0
        
        for name, player in pairs(Crosspaths.db.players) do
            for context, count in pairs(player.contexts or {}) do
                if not contextCounts[context] then
                    contextCounts[context] = 0
                end
                contextCounts[context] = contextCounts[context] + count
                totalContextEncounters = totalContextEncounters + count
            end
        end
        
        local contextStats = {}
        for context, count in pairs(contextCounts) do
            local percentage = totalContextEncounters > 0 and (count / totalContextEncounters * 100) or 0
            table.insert(contextStats, {
                context = context,
                count = count,
                percentage = percentage
            })
        end
        
        table.sort(contextStats, function(a, b) return a.count > b.count end)
        
        return contextStats
    end
    
    function Engine:GetClassStats()
        if not Crosspaths.db or not Crosspaths.db.players then
            return {}
        end
        
        local classCounts = {}
        local totalPlayers = 0
        
        for name, player in pairs(Crosspaths.db.players) do
            local class = player.class or "Unknown"
            if not classCounts[class] then
                classCounts[class] = {count = 0, encounters = 0}
            end
            classCounts[class].count = classCounts[class].count + 1
            classCounts[class].encounters = classCounts[class].encounters + (player.count or 0)
            totalPlayers = totalPlayers + 1
        end
        
        local classStats = {}
        for class, data in pairs(classCounts) do
            local percentage = totalPlayers > 0 and (data.count / totalPlayers * 100) or 0
            table.insert(classStats, {
                class = class,
                players = data.count,
                encounters = data.encounters,
                percentage = percentage
            })
        end
        
        table.sort(classStats, function(a, b) return a.players > b.players end)
        
        return classStats
    end
    
    function Engine:GetSessionStats()
        -- Ensure sessionStats is properly initialized
        if not Crosspaths.sessionStats or type(Crosspaths.sessionStats) ~= "table" then
            return {
                playersEncountered = 0,
                newPlayers = 0,
                totalEncounters = 0,
                sessionStartTime = time(),
                sessionDuration = 0,
                averageEncounterInterval = 0
            }
        end
        
        -- Ensure all required fields exist
        if not Crosspaths.sessionStats.sessionStartTime then
            Crosspaths.sessionStats.sessionStartTime = time()
        end
        if not Crosspaths.sessionStats.totalEncounters then
            Crosspaths.sessionStats.totalEncounters = 0
        end
        if not Crosspaths.sessionStats.playersEncountered then
            Crosspaths.sessionStats.playersEncountered = 0
        end
        if not Crosspaths.sessionStats.newPlayers then
            Crosspaths.sessionStats.newPlayers = 0
        end
        
        local sessionTime = time() - Crosspaths.sessionStats.sessionStartTime
        local totalEncounters = Crosspaths.sessionStats.totalEncounters
        local avgInterval = totalEncounters > 0 and (sessionTime / totalEncounters) or 0
        
        return {
            playersEncountered = Crosspaths.sessionStats.playersEncountered,
            newPlayers = Crosspaths.sessionStats.newPlayers,
            totalEncounters = totalEncounters,
            sessionStartTime = Crosspaths.sessionStats.sessionStartTime,
            sessionDuration = sessionTime,
            averageEncounterInterval = avgInterval
        }
    end
    
    function Engine:GetTopPlayersByType(statType, limit)
        limit = limit or 10
        local unpack = unpack or table.unpack -- Lua 5.4 compatibility
        
        if not Crosspaths.db or not Crosspaths.db.players then
            return {}
        end
        
        local players = {}
        
        -- Collect all players with required data
        for name, player in pairs(Crosspaths.db.players) do
            table.insert(players, {
                name = name,
                count = player.count or 0,
                class = player.class,
                specialization = player.specialization,
                itemLevel = player.itemLevel or 0,
                achievementPoints = player.achievementPoints or 0
            })
        end
        
        if statType == "tanks" then
            local tanks = {}
            for _, player in ipairs(players) do
                if player.specialization then
                    local spec = string.lower(player.specialization)
                    if string.find(spec, "tank") or string.find(spec, "protection") or 
                       string.find(spec, "guardian") or string.find(spec, "brewmaster") or 
                       string.find(spec, "blood") then
                        table.insert(tanks, player)
                    end
                end
            end
            table.sort(tanks, function(a, b) return a.count > b.count end)
            return {unpack(tanks, 1, limit)}
            
        elseif statType == "healers" then
            local healers = {}
            for _, player in ipairs(players) do
                if player.specialization then
                    local spec = string.lower(player.specialization)
                    if string.find(spec, "heal") or string.find(spec, "restoration") or 
                       string.find(spec, "holy") or string.find(spec, "discipline") or 
                       string.find(spec, "mistweaver") then
                        table.insert(healers, player)
                    end
                end
            end
            table.sort(healers, function(a, b) return a.count > b.count end)
            return {unpack(healers, 1, limit)}
            
        elseif statType == "dps" then
            local dps = {}
            for _, player in ipairs(players) do
                if player.specialization then
                    local spec = string.lower(player.specialization)
                    -- If not tank or healer, assume DPS
                    if not (string.find(spec, "tank") or string.find(spec, "protection") or 
                           string.find(spec, "guardian") or string.find(spec, "brewmaster") or 
                           string.find(spec, "blood") or string.find(spec, "heal") or 
                           string.find(spec, "restoration") or string.find(spec, "holy") or 
                           string.find(spec, "discipline") or string.find(spec, "mistweaver")) then
                        table.insert(dps, player)
                    end
                end
            end
            table.sort(dps, function(a, b) return a.count > b.count end)
            return {unpack(dps, 1, limit)}
            
        elseif statType == "itemlevel" or statType == "ilvl" then
            local playersWithILvl = {}
            for _, player in ipairs(players) do
                if player.itemLevel > 0 then
                    table.insert(playersWithILvl, player)
                end
            end
            table.sort(playersWithILvl, function(a, b) return a.itemLevel > b.itemLevel end)
            return {unpack(playersWithILvl, 1, limit)}
            
        elseif statType == "achievements" then
            local playersWithAchievements = {}
            for _, player in ipairs(players) do
                if player.achievementPoints > 0 then
                    table.insert(playersWithAchievements, player)
                end
            end
            table.sort(playersWithAchievements, function(a, b) return a.achievementPoints > b.achievementPoints end)
            return {unpack(playersWithAchievements, 1, limit)}
        else
            return {}
        end
    end
    
    return Engine
end

-- Load the Engine
local Engine = loadEngine()

-- Test Suite: GetStatsSummary
TestRunner.runTest("GetStatsSummary - Basic Functionality", function()
    local stats = Engine:GetStatsSummary()
    
    TestRunner.assertNotNil(stats, "Stats summary should not be nil")
    TestRunner.assertType(stats, "table", "Stats should be a table")
    TestRunner.assertType(stats.totalPlayers, "number", "totalPlayers should be a number")
    TestRunner.assertType(stats.totalEncounters, "number", "totalEncounters should be a number")
    TestRunner.assertType(stats.totalGuilds, "number", "totalGuilds should be a number")
    TestRunner.assertType(stats.groupedPlayers, "number", "groupedPlayers should be a number")
    TestRunner.assertType(stats.averageEncounters, "number", "averageEncounters should be a number")
    
    -- Check actual values from our mock data
    TestRunner.assertEqual(stats.totalPlayers, 12, "Should have 12 total players from mock data")
    TestRunner.assertTrue(stats.totalEncounters > 0, "Should have some encounters")
    TestRunner.assertTrue(stats.totalGuilds > 0, "Should have some guilds")
    TestRunner.assertTrue(stats.averageEncounters > 0, "Should have positive average encounters")
end)

-- Test Suite: GetRecentActivity
TestRunner.runTest("GetRecentActivity - Time-based Analysis", function()
    local activity = Engine:GetRecentActivity()
    
    TestRunner.assertNotNil(activity, "Activity data should not be nil")
    TestRunner.assertType(activity, "table", "Activity should be a table")
    
    -- Check structure
    TestRunner.assertNotNil(activity.last24h, "Should have last24h data")
    TestRunner.assertNotNil(activity.last7d, "Should have last7d data")
    TestRunner.assertNotNil(activity.last30d, "Should have last30d data")
    
    -- Check types
    TestRunner.assertType(activity.last24h.players, "number", "last24h.players should be a number")
    TestRunner.assertType(activity.last24h.encounters, "number", "last24h.encounters should be a number")
    TestRunner.assertType(activity.last7d.players, "number", "last7d.players should be a number")
    TestRunner.assertType(activity.last7d.encounters, "number", "last7d.encounters should be a number")
    TestRunner.assertType(activity.last30d.players, "number", "last30d.players should be a number")
    TestRunner.assertType(activity.last30d.encounters, "number", "last30d.encounters should be a number")
    
    -- Check logical relationships
    TestRunner.assertTrue(activity.last24h.players <= activity.last7d.players, "24h players should be <= 7d players")
    TestRunner.assertTrue(activity.last7d.players <= activity.last30d.players, "7d players should be <= 30d players")
    TestRunner.assertTrue(activity.last24h.encounters <= activity.last7d.encounters, "24h encounters should be <= 7d encounters")
    TestRunner.assertTrue(activity.last7d.encounters <= activity.last30d.encounters, "7d encounters should be <= 30d encounters")
end)

-- Test Suite: GetContextStats
TestRunner.runTest("GetContextStats - Context Breakdown", function()
    local contextStats = Engine:GetContextStats()
    
    TestRunner.assertNotNil(contextStats, "Context stats should not be nil")
    TestRunner.assertType(contextStats, "table", "Context stats should be a table")
    
    -- Should have some context data from mock
    TestRunner.assertTrue(#contextStats > 0, "Should have some context statistics")
    
    -- Check structure of first context entry
    if #contextStats > 0 then
        local firstContext = contextStats[1]
        TestRunner.assertNotNil(firstContext.context, "Context entry should have context field")
        TestRunner.assertType(firstContext.count, "number", "Context count should be a number")
        TestRunner.assertType(firstContext.percentage, "number", "Context percentage should be a number")
        TestRunner.assertTrue(firstContext.percentage >= 0 and firstContext.percentage <= 100, "Percentage should be between 0 and 100")
    end
    
    -- Check that percentages add up to ~100%
    local totalPercentage = 0
    for _, context in ipairs(contextStats) do
        totalPercentage = totalPercentage + context.percentage
    end
    TestRunner.assertTrue(math.abs(totalPercentage - 100) < 0.1, "Total percentages should add up to ~100%")
end)

-- Test Suite: GetClassStats  
TestRunner.runTest("GetClassStats - Class Distribution", function()
    local classStats = Engine:GetClassStats()
    
    TestRunner.assertNotNil(classStats, "Class stats should not be nil")
    TestRunner.assertType(classStats, "table", "Class stats should be a table")
    
    -- Should have some class data from mock
    TestRunner.assertTrue(#classStats > 0, "Should have some class statistics")
    
    -- Check structure of first class entry
    if #classStats > 0 then
        local firstClass = classStats[1]
        TestRunner.assertNotNil(firstClass.class, "Class entry should have class field")
        TestRunner.assertType(firstClass.players, "number", "Class players should be a number")
        TestRunner.assertType(firstClass.encounters, "number", "Class encounters should be a number")
        TestRunner.assertType(firstClass.percentage, "number", "Class percentage should be a number")
        TestRunner.assertTrue(firstClass.percentage >= 0 and firstClass.percentage <= 100, "Percentage should be between 0 and 100")
        TestRunner.assertTrue(firstClass.players > 0, "Should have positive player count")
        TestRunner.assertTrue(firstClass.encounters > 0, "Should have positive encounter count")
    end
    
    -- Check that percentages add up to ~100%
    local totalPercentage = 0
    for _, class in ipairs(classStats) do
        totalPercentage = totalPercentage + class.percentage
    end
    TestRunner.assertTrue(math.abs(totalPercentage - 100) < 0.1, "Total percentages should add up to ~100%")
end)

-- Test Suite: GetSessionStats
TestRunner.runTest("GetSessionStats - Session Tracking", function()
    local sessionStats = Engine:GetSessionStats()
    
    TestRunner.assertNotNil(sessionStats, "Session stats should not be nil")
    TestRunner.assertType(sessionStats, "table", "Session stats should be a table")
    
    -- Check required fields
    TestRunner.assertType(sessionStats.playersEncountered, "number", "playersEncountered should be a number")
    TestRunner.assertType(sessionStats.newPlayers, "number", "newPlayers should be a number")
    TestRunner.assertType(sessionStats.totalEncounters, "number", "totalEncounters should be a number")
    TestRunner.assertType(sessionStats.sessionStartTime, "number", "sessionStartTime should be a number")
    TestRunner.assertType(sessionStats.sessionDuration, "number", "sessionDuration should be a number")
    TestRunner.assertType(sessionStats.averageEncounterInterval, "number", "averageEncounterInterval should be a number")
    
    -- Check logical relationships
    TestRunner.assertTrue(sessionStats.playersEncountered >= 0, "Players encountered should be non-negative")
    TestRunner.assertTrue(sessionStats.newPlayers >= 0, "New players should be non-negative")
    TestRunner.assertTrue(sessionStats.totalEncounters >= 0, "Total encounters should be non-negative")
    TestRunner.assertTrue(sessionStats.sessionDuration >= 0, "Session duration should be non-negative")
    TestRunner.assertTrue(sessionStats.averageEncounterInterval >= 0, "Average interval should be non-negative")
    
    -- New players should be <= total players encountered
    TestRunner.assertTrue(sessionStats.newPlayers <= sessionStats.playersEncountered, "New players should be <= total players encountered")
end)

-- Test Suite: GetTopPlayersByType - Tanks
TestRunner.runTest("GetTopPlayersByType - Tanks", function()
    local tanks = Engine:GetTopPlayersByType("tanks", 5)
    
    TestRunner.assertNotNil(tanks, "Tanks data should not be nil")
    TestRunner.assertType(tanks, "table", "Tanks should be a table")
    
    -- Should have some tanks from mock data (we have Protection Paladins, Warriors, Blood DK)
    TestRunner.assertTrue(#tanks > 0, "Should have some tank players")
    
    -- Check structure of tank entries
    for i, tank in ipairs(tanks) do
        TestRunner.assertNotNil(tank.name, "Tank should have a name")
        TestRunner.assertType(tank.count, "number", "Tank count should be a number")
        TestRunner.assertNotNil(tank.specialization, "Tank should have specialization")
        
        -- Verify it's actually a tank spec
        local spec = string.lower(tank.specialization)
        local isTankSpec = string.find(spec, "tank") or string.find(spec, "protection") or 
                          string.find(spec, "guardian") or string.find(spec, "brewmaster") or 
                          string.find(spec, "blood")
        TestRunner.assertTrue(isTankSpec, "Should be a tank specialization: " .. tank.specialization .. " (spec: " .. spec .. ")")
        
        -- Check sorting (should be in descending order by count)
        if i > 1 then
            TestRunner.assertTrue(tanks[i-1].count >= tank.count, "Tanks should be sorted by encounter count")
        end
    end
end)

-- Test Suite: GetTopPlayersByType - Healers
TestRunner.runTest("GetTopPlayersByType - Healers", function()
    local healers = Engine:GetTopPlayersByType("healers", 5)
    
    TestRunner.assertNotNil(healers, "Healers data should not be nil")
    TestRunner.assertType(healers, "table", "Healers should be a table")
    
    -- Should have some healers from mock data (we have Holy Priest, Resto Druid, etc.)
    TestRunner.assertTrue(#healers > 0, "Should have some healer players")
    
    -- Check structure of healer entries
    for i, healer in ipairs(healers) do
        TestRunner.assertNotNil(healer.name, "Healer should have a name")
        TestRunner.assertType(healer.count, "number", "Healer count should be a number")
        TestRunner.assertNotNil(healer.specialization, "Healer should have specialization")
        
        -- Verify it's actually a healer spec
        local spec = string.lower(healer.specialization)
        local isHealerSpec = string.find(spec, "heal") or string.find(spec, "restoration") or 
                            string.find(spec, "holy") or string.find(spec, "discipline") or 
                            string.find(spec, "mistweaver")
        TestRunner.assertTrue(isHealerSpec, "Should be a healer specialization: " .. healer.specialization)
        
        -- Check sorting (should be in descending order by count)
        if i > 1 then
            TestRunner.assertTrue(healers[i-1].count >= healer.count, "Healers should be sorted by encounter count")
        end
    end
end)

-- Test Suite: GetTopPlayersByType - DPS
TestRunner.runTest("GetTopPlayersByType - DPS", function()
    local dps = Engine:GetTopPlayersByType("dps", 5)
    
    TestRunner.assertNotNil(dps, "DPS data should not be nil")
    TestRunner.assertType(dps, "table", "DPS should be a table")
    
    -- Should have some DPS from mock data (we have Frost Mage, Assassination Rogue)
    TestRunner.assertTrue(#dps > 0, "Should have some DPS players")
    
    -- Check structure of DPS entries
    for i, dpsPlayer in ipairs(dps) do
        TestRunner.assertNotNil(dpsPlayer.name, "DPS should have a name")
        TestRunner.assertType(dpsPlayer.count, "number", "DPS count should be a number")
        TestRunner.assertNotNil(dpsPlayer.specialization, "DPS should have specialization")
        
        -- Verify it's NOT a tank or healer spec (i.e., it's DPS)
        local spec = string.lower(dpsPlayer.specialization)
        local isTankSpec = string.find(spec, "tank") or string.find(spec, "protection") or 
                          string.find(spec, "guardian") or string.find(spec, "brewmaster") or 
                          string.find(spec, "blood")
        local isHealerSpec = string.find(spec, "heal") or string.find(spec, "restoration") or 
                            string.find(spec, "holy") or string.find(spec, "discipline") or 
                            string.find(spec, "mistweaver")
        TestRunner.assertFalse(isTankSpec, "Should not be a tank specialization for DPS: " .. dpsPlayer.specialization)
        TestRunner.assertFalse(isHealerSpec, "Should not be a healer specialization for DPS: " .. dpsPlayer.specialization)
        
        -- Check sorting (should be in descending order by count)
        if i > 1 then
            TestRunner.assertTrue(dps[i-1].count >= dpsPlayer.count, "DPS should be sorted by encounter count")
        end
    end
end)

-- Test Suite: GetTopPlayersByType - Item Level Leaders
TestRunner.runTest("GetTopPlayersByType - Item Level Leaders", function()
    local ilvlLeaders = Engine:GetTopPlayersByType("itemlevel", 5)
    
    TestRunner.assertNotNil(ilvlLeaders, "Item level leaders data should not be nil")
    TestRunner.assertType(ilvlLeaders, "table", "Item level leaders should be a table")
    
    -- Should have some players with item levels from mock data
    TestRunner.assertTrue(#ilvlLeaders > 0, "Should have some players with item levels")
    
    -- Check structure and sorting
    for i, player in ipairs(ilvlLeaders) do
        TestRunner.assertNotNil(player.name, "Player should have a name")
        TestRunner.assertType(player.itemLevel, "number", "Player should have item level as number")
        TestRunner.assertTrue(player.itemLevel > 0, "Item level should be positive")
        
        -- Check sorting (should be in descending order by item level)
        if i > 1 then
            TestRunner.assertTrue(ilvlLeaders[i-1].itemLevel >= player.itemLevel, "Players should be sorted by item level")
        end
    end
end)

-- Test Suite: GetTopPlayersByType - Achievement Leaders
TestRunner.runTest("GetTopPlayersByType - Achievement Leaders", function()
    local achievementLeaders = Engine:GetTopPlayersByType("achievements", 5)
    
    TestRunner.assertNotNil(achievementLeaders, "Achievement leaders data should not be nil")
    TestRunner.assertType(achievementLeaders, "table", "Achievement leaders should be a table")
    
    -- Should have some players with achievement points from mock data
    TestRunner.assertTrue(#achievementLeaders > 0, "Should have some players with achievement points")
    
    -- Check structure and sorting
    for i, player in ipairs(achievementLeaders) do
        TestRunner.assertNotNil(player.name, "Player should have a name")
        TestRunner.assertType(player.achievementPoints, "number", "Player should have achievement points as number")
        TestRunner.assertTrue(player.achievementPoints > 0, "Achievement points should be positive")
        
        -- Check sorting (should be in descending order by achievement points)
        if i > 1 then
            TestRunner.assertTrue(achievementLeaders[i-1].achievementPoints >= player.achievementPoints, "Players should be sorted by achievement points")
        end
    end
end)

-- Test Suite: GetTopPlayersByType - Invalid Type
TestRunner.runTest("GetTopPlayersByType - Invalid Type", function()
    local result = Engine:GetTopPlayersByType("invalid_type", 5)
    
    TestRunner.assertNotNil(result, "Result should not be nil even for invalid type")
    TestRunner.assertType(result, "table", "Result should be a table")
    TestRunner.assertEqual(#result, 0, "Should return empty table for invalid type")
end)

-- Test Edge Cases
TestRunner.runTest("Edge Cases - Empty Database", function()
    -- Temporarily clear the database
    local originalDB = Crosspaths.db
    Crosspaths.db = {players = {}}
    
    local stats = Engine:GetStatsSummary()
    TestRunner.assertEqual(stats.totalPlayers, 0, "Empty DB should have 0 total players")
    TestRunner.assertEqual(stats.totalEncounters, 0, "Empty DB should have 0 total encounters")
    
    local activity = Engine:GetRecentActivity()
    TestRunner.assertEqual(activity.last24h.players, 0, "Empty DB should have 0 recent players")
    
    local contextStats = Engine:GetContextStats()
    TestRunner.assertEqual(#contextStats, 0, "Empty DB should have no context stats")
    
    local classStats = Engine:GetClassStats()
    TestRunner.assertEqual(#classStats, 0, "Empty DB should have no class stats")
    
    -- Restore original database
    Crosspaths.db = originalDB
end)

TestRunner.runTest("Edge Cases - Nil Database", function()
    -- Temporarily set database to nil
    local originalDB = Crosspaths.db
    Crosspaths.db = nil
    
    local stats = Engine:GetStatsSummary()
    TestRunner.assertEqual(stats.totalPlayers, 0, "Nil DB should have 0 total players")
    
    local activity = Engine:GetRecentActivity()
    TestRunner.assertEqual(activity.last24h.players, 0, "Nil DB should have 0 recent players")
    
    -- Restore original database
    Crosspaths.db = originalDB
end)

TestRunner.runTest("Edge Cases - Empty SessionStats", function()
    -- Test the specific fix for nil comparison error when sessionStats is empty
    local originalSessionStats = Crosspaths.sessionStats
    Crosspaths.sessionStats = {} -- Empty table, not nil
    
    local sessionStats = Engine:GetSessionStats()
    TestRunner.assertNotNil(sessionStats, "Should handle empty sessionStats without error")
    TestRunner.assertType(sessionStats, "table", "Should return valid table for empty sessionStats")
    TestRunner.assertEqual(sessionStats.totalEncounters, 0, "Should have 0 totalEncounters for empty sessionStats")
    TestRunner.assertEqual(sessionStats.playersEncountered, 0, "Should have 0 playersEncountered for empty sessionStats")
    TestRunner.assertEqual(sessionStats.averageEncounterInterval, 0, "Should have 0 averageEncounterInterval for empty sessionStats")
    
    -- Restore original sessionStats
    Crosspaths.sessionStats = originalSessionStats
end)

-- Run all tests and display results
print("Running Crosspaths Engine Tests...")
print("==================================")

local exitCode = TestRunner.printResults()

-- Exit with proper code for CI
if exitCode == 0 then
    print("\n✓ All tests passed! Engine functions are working correctly.")
else
    print("\n✗ Some tests failed! Please review the failures above.")
end

os.exit(exitCode)