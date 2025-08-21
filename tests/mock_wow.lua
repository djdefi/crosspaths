-- Mock WoW API and Data for Testing
-- This file provides mock implementations of WoW API functions and test data

local MockWoW = {}

-- Mock time function
function MockWoW.mockTime(timestamp)
    if timestamp then
        _G.time = function() return timestamp end
    else
        _G.time = function() return 1640995200 end -- Jan 1, 2022 00:00:00 UTC
    end
end

-- Mock WoW API functions
function MockWoW.setupMockAPI()
    -- Mock C_Timer
    _G.C_Timer = {
        NewTicker = function(interval, callback)
            return {
                Cancel = function() end
            }
        end
    }
    
    -- Mock C_Map
    _G.C_Map = {
        GetBestMapForUnit = function(unit)
            return 1519 -- Stormwind City
        end
    }

    -- Mock Unit functions for NPC detection
    _G.UnitGUID = function(unit)
        -- Return mock player GUIDs for test units, NPC GUIDs for test NPCs
        if unit == "target" or unit == "focus" or unit == "mouseover" or string.match(unit or "", "^nameplate") then
            return "Player-1234-56789ABC" -- Mock player GUID
        elseif unit == "testnpc1" then
            return "Creature-0-1234-56789DEF" -- Mock NPC GUID
        elseif unit == "testai1" then  
            return "Vehicle-0-1234-56789GHI" -- Mock AI/Vehicle GUID
        elseif unit == "testfollower1" then
            return "Player-1234-56789XYZ" -- Follower dungeon NPCs may have Player GUIDs!
        else
            return "Player-1234-56789ABC" -- Default to player for existing tests
        end
    end

    _G.UnitIsConnected = function(unit)
        -- NPCs and AI characters are not "connected" 
        if unit == "testnpc1" or unit == "testai1" or unit == "testfollower1" then
            return false -- NPCs are not connected
        end
        return true -- Real players are connected
    end

    _G.UnitCreatureType = function(unit)
        -- Real players should return nil, NPCs return creature type
        if unit == "testnpc1" then
            return "Humanoid" -- NPCs have creature types
        elseif unit == "testai1" then
            return "Mechanical" -- AI might have different types
        elseif unit == "testfollower1" then
            return nil -- Follower dungeon NPCs might not have creature types
        end
        return nil -- Players don't have creature types
    end

    _G.UnitPVPName = function(unit)
        -- Mock function - AI units might have special markers
        if unit == "testai1" then
            return "TestAI (AI)" -- Mock AI marker
        end
        return nil -- Normal for most units
    end

    -- Mock GetGuildInfo for guild-based NPC detection
    _G.GetGuildInfo = function(unit)
        -- Return suspicious guild names for test NPCs/AI
        if unit == "testnpc1" then
            return "NPC Guild", nil, nil, nil -- Suspicious guild name
        elseif unit == "testai1" then
            return "AI Companions", nil, nil, nil -- Suspicious guild name
        elseif unit == "testfollower1" then
            return "Follower Dungeon Bots", nil, nil, nil -- Suspicious guild name
        end
        return nil -- Most real players have no guild or normal guild names
    end

    -- Mock UnitExists for unit validation
    _G.UnitExists = function(unit)
        -- Return false for completely invalid units
        if not unit or unit == "nonexistent" or unit == "" then
            return false
        end
        return true -- Most units exist in our mock environment
    end
end

-- Generate comprehensive mock player data
function MockWoW.createMockDatabase()
    local mockDB = {
        players = {}
    }
    
    -- Define test players with various attributes
    local testPlayers = {
        {
            name = "Tankmaster-Stormrage",
            count = 18,
            firstSeen = 1640995200 - (7 * 24 * 60 * 60), -- 7 days ago
            lastSeen = 1640995200 - (1 * 60 * 60), -- 1 hour ago
            guild = "Elite Guardians",
            grouped = true,
            class = "Paladin",
            specialization = "Protection",
            level = 80,
            itemLevel = 450,
            achievementPoints = 15000,
            mount = "Invincible",
            zones = {
                ["Stormwind City"] = 10,
                ["Orgrimmar"] = 5,
                ["Valdrakken"] = 3
            },
            contexts = {
                ["party"] = 8,
                ["raid"] = 6,
                ["world"] = 4
            }
        },
        {
            name = "Shieldwall-Stormrage",
            count = 15,
            firstSeen = 1640995200 - (14 * 24 * 60 * 60), -- 14 days ago
            lastSeen = 1640995200 - (2 * 24 * 60 * 60), -- 2 days ago
            guild = "Elite Guardians",
            grouped = true,
            class = "Warrior",
            specialization = "Protection",
            level = 80,
            itemLevel = 445,
            achievementPoints = 12500,
            mount = "Swift Spectral Tiger",
            zones = {
                ["Stormwind City"] = 8,
                ["Ironforge"] = 4,
                ["The War Within Zone"] = 3
            },
            contexts = {
                ["party"] = 7,
                ["raid"] = 5,
                ["world"] = 3
            }
        },
        {
            name = "Ironwall",
            count = 12,
            firstSeen = 1640995200 - (10 * 24 * 60 * 60), -- 10 days ago
            lastSeen = 1640995200 - (3 * 24 * 60 * 60), -- 3 days ago
            guild = "",
            grouped = false,
            class = "Death Knight",
            specialization = "Blood",
            level = 80,
            itemLevel = 440,
            achievementPoints = 8000,
            mount = "Bone-White Primal Raptor",
            zones = {
                ["Dalaran"] = 6,
                ["Orgrimmar"] = 4,
                ["Dornogal"] = 2
            },
            contexts = {
                ["world"] = 8,
                ["party"] = 3,
                ["pvp"] = 1
            }
        },
        {
            name = "Defender-Tichondrius",
            count = 10,
            firstSeen = 1640995200 - (21 * 24 * 60 * 60), -- 21 days ago
            lastSeen = 1640995200 - (5 * 24 * 60 * 60), -- 5 days ago
            guild = "Stormwind Guard",
            grouped = true,
            class = "Paladin",
            specialization = "Guardian",
            level = 80,
            itemLevel = 435,
            achievementPoints = 11000,
            mount = "Ashes of Al'ar",
            zones = {
                ["Stormwind City"] = 6,
                ["Elwynn Forest"] = 3,
                ["Westfall"] = 1
            },
            contexts = {
                ["party"] = 5,
                ["world"] = 4,
                ["raid"] = 1
            }
        },
        {
            name = "Stormshield",
            count = 8,
            firstSeen = 1640995200 - (5 * 24 * 60 * 60), -- 5 days ago
            lastSeen = 1640995200 - (6 * 60 * 60), -- 6 hours ago
            guild = "Elite Guardians",
            grouped = false,
            class = "Warrior",
            specialization = "Brewmaster",
            level = 80,
            itemLevel = 430,
            achievementPoints = 9500,
            mount = "Common Ground Mount",
            zones = {
                ["Stormwind City"] = 5,
                ["Boralus"] = 2,
                ["Zuldazar"] = 1
            },
            contexts = {
                ["world"] = 5,
                ["party"] = 2,
                ["dungeon"] = 1
            }
        },
        -- Healer examples
        {
            name = "Lightbringer-Kil'jaeden",
            count = 16,
            firstSeen = 1640995200 - (12 * 24 * 60 * 60), -- 12 days ago
            lastSeen = 1640995200 - (4 * 60 * 60), -- 4 hours ago
            guild = "Healing Hands",
            grouped = true,
            class = "Priest",
            specialization = "Holy",
            level = 80,
            itemLevel = 455,
            achievementPoints = 13500,
            mount = "Swift Zulian Tiger",
            zones = {
                ["Stormwind City"] = 8,
                ["Shattrath City"] = 5,
                ["Valdrakken"] = 3
            },
            contexts = {
                ["raid"] = 9,
                ["party"] = 5,
                ["world"] = 2
            }
        },
        {
            name = "Naturekeeper",
            count = 14,
            firstSeen = 1640995200 - (8 * 24 * 60 * 60), -- 8 days ago
            lastSeen = 1640995200 - (2 * 60 * 60), -- 2 hours ago
            guild = "Nature's Embrace",
            grouped = true,
            class = "Druid",
            specialization = "Restoration",
            level = 80,
            itemLevel = 448,
            achievementPoints = 14200,
            mount = "Grove Warden",
            zones = {
                ["Moonglade"] = 7,
                ["Darnassus"] = 4,
                ["Val'sharah"] = 3
            },
            contexts = {
                ["raid"] = 8,
                ["party"] = 4,
                ["world"] = 2
            }
        },
        {
            name = "Wavehealer-Stormrage",
            count = 11,
            firstSeen = 1640995200 - (6 * 24 * 60 * 60), -- 6 days ago
            lastSeen = 1640995200 - (8 * 60 * 60), -- 8 hours ago
            guild = "Tide Turners",
            grouped = false,
            class = "Shaman",
            specialization = "Restoration",
            level = 80,
            itemLevel = 442,
            achievementPoints = 10800,
            mount = "Thundering Cobalt Cloud Serpent",
            zones = {
                ["Thunder Bluff"] = 6,
                ["Orgrimmar"] = 3,
                ["Dazar'alor"] = 2
            },
            contexts = {
                ["party"] = 6,
                ["world"] = 3,
                ["raid"] = 2
            }
        },
        {
            name = "Lifebinder",
            count = 9,
            firstSeen = 1640995200 - (15 * 24 * 60 * 60), -- 15 days ago
            lastSeen = 1640995200 - (12 * 60 * 60), -- 12 hours ago
            guild = "",
            grouped = true,
            class = "Monk",
            specialization = "Mistweaver",
            level = 80,
            itemLevel = 438,
            achievementPoints = 9200,
            mount = "Jade Cloud Serpent",
            zones = {
                ["Pandaria"] = 5,
                ["Stormwind City"] = 3,
                ["Shrine of Seven Stars"] = 1
            },
            contexts = {
                ["party"] = 5,
                ["world"] = 3,
                ["raid"] = 1
            }
        },
        {
            name = "Spiritcaller-Mal'Ganis",
            count = 7,
            firstSeen = 1640995200 - (9 * 24 * 60 * 60), -- 9 days ago
            lastSeen = 1640995200 - (1 * 24 * 60 * 60), -- 1 day ago
            guild = "Spirit Guides",
            grouped = false,
            class = "Priest",
            specialization = "Discipline",
            level = 80,
            itemLevel = 434,
            achievementPoints = 8700,
            mount = "Twilight Drake",
            zones = {
                ["Stormwind City"] = 4,
                ["Northshire Valley"] = 2,
                ["Goldshire"] = 1
            },
            contexts = {
                ["world"] = 4,
                ["party"] = 2,
                ["raid"] = 1
            }
        },
        -- DPS examples
        {
            name = "Frostbolt-Tichondrius",
            count = 13,
            firstSeen = 1640995200 - (11 * 24 * 60 * 60), -- 11 days ago
            lastSeen = 1640995200 - (5 * 60 * 60), -- 5 hours ago
            guild = "Arcane Masters",
            grouped = true,
            class = "Mage",
            specialization = "Frost",
            level = 80,
            itemLevel = 446,
            achievementPoints = 12000,
            mount = "Mimiron's Head",
            zones = {
                ["Stormwind City"] = 7,
                ["Dalaran"] = 4,
                ["Violet Citadel"] = 2
            },
            contexts = {
                ["raid"] = 7,
                ["party"] = 4,
                ["world"] = 2
            }
        },
        {
            name = "Shadowstrike",
            count = 17,
            firstSeen = 1640995200 - (13 * 24 * 60 * 60), -- 13 days ago
            lastSeen = 1640995200 - (3 * 60 * 60), -- 3 hours ago
            guild = "",
            grouped = false,
            class = "Rogue",
            specialization = "Assassination",
            level = 80,
            itemLevel = 452,
            achievementPoints = 16500,
            mount = "Rare Stealth Mount",
            zones = {
                ["Stormwind City"] = 9,
                ["Orgrimmar"] = 5,
                ["Booty Bay"] = 3
            },
            contexts = {
                ["world"] = 10,
                ["party"] = 5,
                ["pvp"] = 2
            }
        }
    }
    
    -- Add all test players to mock database
    for _, player in ipairs(testPlayers) do
        mockDB.players[player.name] = player
    end
    
    return mockDB
end

-- Create mock session stats
function MockWoW.createMockSessionStats()
    return {
        playersEncountered = 5,
        newPlayers = 2,
        totalEncounters = 12,
        sessionStartTime = 1640995200 - (2 * 60 * 60), -- 2 hours ago
    }
end

-- Setup complete mock environment
function MockWoW.setupMockEnvironment()
    -- Setup mock time
    MockWoW.mockTime()
    
    -- Setup mock WoW API
    MockWoW.setupMockAPI()
    
    -- Create mock Crosspaths global
    _G.Crosspaths = {
        version = "0.1.0",
        db = MockWoW.createMockDatabase(),
        sessionStats = MockWoW.createMockSessionStats(),
        
        -- Mock debug logging
        DebugLog = function(message, level)
            -- Silent for tests
        end,
        
        -- Mock safe call
        SafeCall = function(func)
            return func()
        end,
        
        Engine = {}
    }
    
    return _G.Crosspaths
end

return MockWoW