#!/usr/bin/env lua
-- Unit tests for Crosspaths Tracker functions
-- Tests NPC/AI character detection functionality

-- Setup paths for require
package.path = package.path .. ";./?.lua;./tests/?.lua"

-- Load dependencies
local TestRunner = require("test_runner")
local MockWoW = require("mock_wow")

-- Setup mock environment
local Crosspaths = MockWoW.setupMockEnvironment()

-- Mock the IsNPCorAICharacter function directly for testing
local function IsNPCorAICharacter(unitToken)
    -- Check if NPC filtering is disabled in settings
    if Crosspaths.db and Crosspaths.db.settings and Crosspaths.db.settings.tracking then
        if Crosspaths.db.settings.tracking.filterNPCs == false then
            return false -- Skip filtering if user disabled it
        end
    end
    
    if not unitToken or not UnitExists(unitToken) then
        return true -- Treat invalid units as NPCs for safety
    end

    -- Primary check: Connection status
    -- Real players are connected, NPCs and AI companions typically are not
    if not UnitIsConnected(unitToken) then
        return true
    end

    -- Check creature type - should be nil for real players
    local creatureType = UnitCreatureType(unitToken)
    if creatureType and creatureType ~= "" then
        return true
    end

    -- Guild-based detection (suggested by user feedback)
    -- Follower dungeon NPCs often have suspicious or missing guild info
    local guildName = GetGuildInfo(unitToken)
    if guildName then
        -- Check for typical NPC guild markers or patterns
        local suspiciousGuildNames = {
            "AI", "Bot", "NPC", "Companion", "Follower", "Computer"
        }
        local guildLower = string.lower(guildName)
        for _, suspicious in ipairs(suspiciousGuildNames) do
            if string.find(guildLower, string.lower(suspicious)) then
                return true
            end
        end
    end

    -- Check for AI markers in unit name/flags
    local unitFlags = UnitPVPName(unitToken)
    if unitFlags and string.find(unitFlags, "AI") then
        return true
    end

    -- Secondary check: GUID prefix analysis
    -- Note: Follower dungeon NPCs may have Player- GUIDs, so this is less reliable
    local guid = UnitGUID(unitToken)
    if guid then
        local guidType = string.match(guid, "^([^-]+)-")
        if guidType and guidType ~= "Player" then
            return true
        end
    end

    return false -- Appears to be a real player
end

print("Running Crosspaths Tracker Tests...")
print("==================================")

-- Test NPC/AI Character Detection
print("Running test: NPC Detection - Traditional NPCs by GUID")
local result = IsNPCorAICharacter("testnpc1")
TestRunner.assertEqual(result, true, "testnpc1 should be detected as NPC")

print("Running test: NPC Detection - AI characters by GUID")
local result2 = IsNPCorAICharacter("testai1")
TestRunner.assertEqual(result2, true, "testai1 should be detected as AI")

print("Running test: NPC Detection - Follower dungeon NPCs by connection status")
local result3 = IsNPCorAICharacter("testfollower1")
TestRunner.assertEqual(result3, true, "testfollower1 should be detected as NPC despite Player GUID")

print("Running test: NPC Detection - Real players correctly identified")
local result4 = IsNPCorAICharacter("target")
TestRunner.assertEqual(result4, false, "target should be identified as real player")

print("Running test: NPC Detection - Invalid units handled safely")
local result5 = IsNPCorAICharacter(nil)
TestRunner.assertEqual(result5, true, "nil unit should be treated as NPC for safety")

local result6 = IsNPCorAICharacter("nonexistent")
TestRunner.assertEqual(result6, true, "nonexistent unit should be treated as NPC for safety")

print("Running test: NPC Detection - Settings respect")
-- Save original settings
local originalSettings = nil
if Crosspaths.db and Crosspaths.db.settings and Crosspaths.db.settings.tracking then
    originalSettings = Crosspaths.db.settings.tracking.filterNPCs
end

-- Disable NPC filtering
if not Crosspaths.db then Crosspaths.db = {} end
if not Crosspaths.db.settings then Crosspaths.db.settings = {} end
if not Crosspaths.db.settings.tracking then Crosspaths.db.settings.tracking = {} end
Crosspaths.db.settings.tracking.filterNPCs = false

local result7 = IsNPCorAICharacter("testnpc1")
TestRunner.assertEqual(result7, false, "NPC should not be filtered when setting is disabled")

-- Re-enable NPC filtering
Crosspaths.db.settings.tracking.filterNPCs = true
local result8 = IsNPCorAICharacter("testnpc1")
TestRunner.assertEqual(result8, true, "NPC should be filtered when setting is enabled")

-- Restore original settings
if originalSettings ~= nil then
    Crosspaths.db.settings.tracking.filterNPCs = originalSettings
end

print("Running test: NPC Detection - Guild name patterns")
local result9 = IsNPCorAICharacter("testnpc1")
TestRunner.assertEqual(result9, true, "Unit with suspicious guild name should be detected as NPC")

local result10 = IsNPCorAICharacter("testai1")
TestRunner.assertEqual(result10, true, "Unit with AI guild name should be detected as NPC")

local result11 = IsNPCorAICharacter("testfollower1")
TestRunner.assertEqual(result11, true, "Unit with follower guild name should be detected as NPC")

-- Test name validation with various character combinations
print("Running test: Name Validation - Character patterns")
local testNames = {
    {"John", true},                    -- Simple name
    {"Mal'Ganis", true},              -- Name with apostrophe
    {"Crenna Earth-Daughter", true},   -- Name with space and hyphen
    {"Blood-Elf", true},              -- Name with hyphen
    {"Anna Marie", true},             -- Name with space
    {"L33tH4x0r", false},             -- Name with numbers (should be rejected)
    {"Test@Name", false},             -- Name with special characters
    {"", false},                      -- Empty name
}

for _, test in ipairs(testNames) do
    local name, expected = test[1], test[2]
    -- Use same logic as Tracker.lua for validation
    local maxLength = 12 -- Standard player name limit
    if string.match(name, "[%s%-]") then -- Names with spaces or hyphens (often NPCs)
        maxLength = 25 -- Longer limit for compound names
    end
    local isValid = string.match(name, "^[%a'%s%-]+$") ~= nil and string.len(name) >= 2 and string.len(name) <= maxLength
    
    TestRunner.assertEqual(isValid, expected, "Name validation for: " .. (name ~= "" and name or "[empty]"))
end

-- Display results
print("")
TestRunner.printResults()

-- Exit with appropriate code
if TestRunner.failedTests > 0 then
    os.exit(1)
else
    print("✓ All Tracker tests passed!")
    os.exit(0)
end