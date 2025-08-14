-- Crosspaths Core.lua
-- Addon initialization, event registration, and saved variables

local addonName, Crosspaths = ...

-- Create the main addon object
Crosspaths = Crosspaths or {}
Crosspaths.version = "0.1.16"
Crosspaths.debug = false

-- Default settings
local defaults = {
    enabled = true,
    debug = false,
    ui = {
        scale = 1.0,
        x = 0,
        y = 0,
        locked = false,
        showNotifications = true,
        notificationDuration = 3,
    },
    tracking = {
        enableGroupTracking = true,
        enableNameplateTracking = true,
        enableCityTracking = true,
        enableMouseoverTracking = true, -- New: mouseover detection
        enableTargetTracking = true, -- New: target change detection
        enableCombatLogTracking = true, -- New: combat log detection
        locationBasedThrottling = true,
        throttleMs = 500, -- Throttle encounter updates
        minimumMoveDistance = 0.01, -- Minimum distance player must move (0-1 map coordinates)
        pruneAfterDays = 180,
        maxPlayers = 10000, -- Maximum players to track
    },
    notifications = {
        enableNotifications = true,
        notifyRepeatEncounters = true,
        notifyFrequentPlayers = true,
        notifyPreviousGroupMembers = true,
        notifyNewEncounters = true,
        notifyGuildMembers = true,
        playSound = true,
        doNotDisturbCombat = true,
        maxNotifications = 3,
        duration = 3,
        frequentPlayerThreshold = 10, -- Encounters needed to be "frequent"
    },
    digests = {
        autoNotify = true,
        enableDaily = true,
        enableWeekly = true,
        enableMonthly = true,
    }
}

-- Initialize saved variables
function Crosspaths:InitializeDB()
    -- Ensure CrosspathsDB exists
    if not CrosspathsDB then
        CrosspathsDB = {}
    end

    -- Validate CrosspathsDB structure
    if type(CrosspathsDB) ~= "table" then
        CrosspathsDB = {}
        self:Message("Crosspaths database was corrupted, resetting to defaults", true)
    end

    -- Check for version upgrade
    if CrosspathsDB.version ~= self.version then
        self:OnVersionUpgrade(CrosspathsDB.version, self.version)
        CrosspathsDB.version = self.version
    end

    -- Initialize main data structures
    if not CrosspathsDB.players then
        CrosspathsDB.players = {}
    end

    if not CrosspathsDB.settings then
        CrosspathsDB.settings = {}
    end

    -- Merge defaults with saved settings
    for key, value in pairs(defaults) do
        if CrosspathsDB.settings[key] == nil then
            if type(value) == "table" then
                CrosspathsDB.settings[key] = {}
                for subkey, subvalue in pairs(value) do
                    CrosspathsDB.settings[key][subkey] = subvalue
                end
            else
                CrosspathsDB.settings[key] = value
            end
        elseif type(value) == "table" and type(CrosspathsDB.settings[key]) == "table" then
            -- Merge nested tables
            for subkey, subvalue in pairs(value) do
                if CrosspathsDB.settings[key][subkey] == nil then
                    CrosspathsDB.settings[key][subkey] = subvalue
                end
            end
        end
    end

    self.db = CrosspathsDB
    self:Print("Database initialized with " .. self:CountPlayers() .. " players tracked")
end

-- Handle version upgrades
function Crosspaths:OnVersionUpgrade(oldVersion, newVersion)
    if oldVersion then
        self:Message("Crosspaths upgraded from v" .. oldVersion .. " to v" .. newVersion)
    else
        self:Message("Crosspaths v" .. newVersion .. " - First time installation")
    end
    
    -- Clean up self-encounters for versions before 0.1.16
    if not oldVersion or self:CompareVersions(oldVersion, "0.1.16") < 0 then
        self:CleanupSelfEncounters()
    end
end

-- Remove self-encounters from existing data
function Crosspaths:CleanupSelfEncounters()
    if not self.db or not self.db.players then
        return
    end
    
    local currentPlayerName = UnitName("player")
    local currentPlayerRealm = GetRealmName()
    
    if not currentPlayerName or not currentPlayerRealm then
        self:DebugLog("Cannot clean up self-encounters: player info not available", "WARN")
        return
    end
    
    local playerFullName = currentPlayerName .. "-" .. currentPlayerRealm
    local removedCount = 0
    local removedEncounters = 0
    
    -- Check for self-entry using full name format
    if self.db.players[playerFullName] then
        removedEncounters = self.db.players[playerFullName].count or 0
        self.db.players[playerFullName] = nil
        removedCount = removedCount + 1
        self:DebugLog("Removed self-encounter data for: " .. playerFullName .. " (" .. removedEncounters .. " encounters)", "INFO")
    end
    
    -- Check for self-entry using name-only format
    if self.db.players[currentPlayerName] then
        local nameOnlyEncounters = self.db.players[currentPlayerName].count or 0
        removedEncounters = removedEncounters + nameOnlyEncounters
        self.db.players[currentPlayerName] = nil
        removedCount = removedCount + 1
        self:DebugLog("Removed self-encounter data for: " .. currentPlayerName .. " (" .. nameOnlyEncounters .. " encounters)", "INFO")
    end
    
    if removedCount > 0 then
        self:Message("Cleaned up " .. removedCount .. " self-encounter entries (" .. removedEncounters .. " total encounters)")
        self:DebugLog("Self-encounter cleanup completed: removed " .. removedCount .. " entries with " .. removedEncounters .. " total encounters", "INFO")
    else
        self:DebugLog("No self-encounter data found to clean up", "DEBUG")
    end
end

-- Compare version strings (returns -1, 0, or 1)
function Crosspaths:CompareVersions(version1, version2)
    if not version1 then return -1 end
    if not version2 then return 1 end
    
    local function parseVersion(v)
        local parts = {}
        for part in string.gmatch(v, "([^%.]+)") do
            table.insert(parts, tonumber(part) or 0)
        end
        return parts
    end
    
    local v1Parts = parseVersion(version1)
    local v2Parts = parseVersion(version2)
    
    local maxParts = math.max(#v1Parts, #v2Parts)
    
    for i = 1, maxParts do
        local v1Part = v1Parts[i] or 0
        local v2Part = v2Parts[i] or 0
        
        if v1Part < v2Part then
            return -1
        elseif v1Part > v2Part then
            return 1
        end
    end
    
    return 0
end

-- Count players for diagnostics
function Crosspaths:CountPlayers()
    local count = 0
    if self.db and self.db.players then
        for _ in pairs(self.db.players) do
            count = count + 1
        end
    end
    return count
end

-- Initialize session statistics
function Crosspaths:InitializeSessionStats()
    self.sessionStats = {
        sessionStartTime = time(),
        totalEncounters = 0,
        playersEncountered = 0,
        newPlayers = 0,
        eventsHandled = 0,
        -- Keep legacy fields for backward compatibility
        startTime = time(),
        encountersDetected = 0,
        playersAdded = 0,
        playersUpdated = 0,
    }
    self:DebugLog("Session statistics initialized with fields: " ..
                 "sessionStartTime=" .. tostring(self.sessionStats.sessionStartTime) ..
                 ", totalEncounters=" .. tostring(self.sessionStats.totalEncounters), "INFO")
end

-- Debug print function
function Crosspaths:Print(message)
    if self.debug then
        print("|cFF7B68EECrosspaths:|r " .. tostring(message))
    end
end

-- Error handling wrapper
function Crosspaths:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        local errorMsg = tostring(result)
        print("|cFFFF0000Crosspaths Error:|r " .. errorMsg)
        self:LogError("SafeCall Error: " .. errorMsg)

        if self.debug then
            print("|cFFFF0000Stack trace:|r " .. debugstack())
            self:DebugLog("Stack trace: " .. debugstack(), "ERROR")
        end

        return false, result
    end
    return true, result
end

-- User message function
function Crosspaths:Message(message, isError)
    local prefix = isError and "|cFFFF0000Crosspaths Error:|r " or "|cFF7B68EECrosspaths:|r "
    print(prefix .. tostring(message))
end

-- Get current zone name
function Crosspaths:GetCurrentZone()
    local zone = GetZoneText()
    if zone and zone ~= "" then
        return zone
    end
    return GetSubZoneText() or "Unknown"
end

-- Get encounter context
function Crosspaths:GetEncounterContext()
    if IsInGroup() then
        if IsInRaid() then
            return "raid"
        else
            return "party"
        end
    elseif IsInInstance() then
        return "instance"
    else
        return "world"
    end
end

-- Main addon initialization
function Crosspaths:OnInitialize()
    self:SafeCall(function()
        self:InitializeDB()

        -- Apply debug setting from database and update logging level
        if self.db and self.db.settings then
            self.debug = self.db.settings.debug or false

            -- Update logging level based on debug setting
            if self.Logging then
                if self.debug then
                    self.Logging.logLevel = 4 -- DEBUG level
                else
                    self.Logging.logLevel = 3 -- INFO level
                end
            end
        end

        self:Print("Crosspaths " .. self.version .. " loaded")

        -- Initialize session statistics
        self:InitializeSessionStats()

        -- Initialize logging module first for better debugging
        if self.Logging then
            self.Logging:InitializeVariables()
            self:DebugLog("Logging module initialized")
        end

        -- Initialize modules in dependency order
        if self.Tracker then
            local success = self.Tracker:Initialize()
            if success then
                self:DebugLog("Tracker module initialized successfully")
            else
                self:DebugLog("Tracker module initialization failed", "ERROR")
            end
        end

        if self.Engine then
            self.Engine:Initialize()
            self:DebugLog("Engine module initialized")
        end

        if self.UI then
            self.UI:Initialize()
            self:DebugLog("UI module initialized")
        end

        if self.Config then
            self.Config:Initialize()
            self:DebugLog("Config module initialized")
        end

        -- Initialize Titan Panel integration if available
        if self.TitanPanel then
            local success = self.TitanPanel:Initialize()
            if success then
                self.TitanPanel:StartUpdateTimer()
                self:DebugLog("Titan Panel module initialized successfully")
            else
                self:DebugLog("Titan Panel module initialization failed", "WARN")
            end
        end

        -- Initialize Minimap Button
        if self.MinimapButton then
            self.MinimapButton:Initialize()
            self:DebugLog("Minimap button module initialized")
        end

        self:Message("Crosspaths " .. self.version .. " initialized successfully")
        self:DebugLog("Crosspaths initialization completed successfully", "INFO")
    end)
end

-- Event handling
function Crosspaths:OnEvent(event, ...)
    local args = {...}
    self:SafeCall(function()
        if self.sessionStats then
            self.sessionStats.eventsHandled = self.sessionStats.eventsHandled + 1
        end
        self:DebugLog("Event received: " .. event)

        if event == "ADDON_LOADED" then
            local loadedAddon = args[1]
            if loadedAddon == addonName then
                self:OnInitialize()
            end
        elseif event == "PLAYER_LOGIN" then
            self:OnPlayerLogin()
        elseif event == "PLAYER_ENTERING_WORLD" then
            self:OnPlayerEnteringWorld()
        end
    end)
end

function Crosspaths:OnPlayerLogin()
    self:SafeCall(function()
        self:Print("Player logged in")
        self:DebugLog("Player logged in", "INFO")
    end)
end

function Crosspaths:OnPlayerEnteringWorld()
    self:SafeCall(function()
        self:Print("Player entering world")
        self:DebugLog("Player entering world", "INFO")

        if not self.db then
            self:DebugLog("Database not yet initialized during OnPlayerEnteringWorld", "WARN")
            return
        end

        -- Crosspaths works for all classes and specs
        self:Print("Crosspaths enabled for social memory tracking")
        self:DebugLog("Crosspaths enabled for all players", "INFO")
        self.db.settings.enabled = true
        self:Message("Crosspaths active - tracking social encounters")
    end)
end

-- Create event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    Crosspaths:OnEvent(event, ...)
end)

-- Make Crosspaths globally accessible
_G[addonName] = Crosspaths

-- Cleanup function for addon disable/reload
function Crosspaths:Cleanup()
    self:SafeCall(function()
        if self.UI then
            self.UI:Hide()
        end

        if self.Tracker then
            self.Tracker:Stop()
        end

        self:Print("Crosspaths cleanup completed")
    end)
end