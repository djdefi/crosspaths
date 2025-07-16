-- Crosspaths Tracker.lua
-- Player encounter tracking and event handling

local addonName, Crosspaths = ...

Crosspaths.Tracker = {}
local Tracker = Crosspaths.Tracker

-- Initialize tracker
function Tracker:Initialize()
    Crosspaths:DebugLog("Initializing Tracker module...", "INFO")

    -- Validate dependencies
    if not Crosspaths.db then
        Crosspaths:DebugLog("Database not ready during Tracker initialization", "WARN")
        return false
    end

    self.eventFrame = CreateFrame("Frame")
    self.lastUpdate = {}
    self.lastNotification = {} -- Track last notification times to prevent spam
    self.lastPosition = {} -- Track last known positions for location-based throttling
    self.updateThrottle = 500 -- 500ms throttle (will be overridden by settings)

    -- Session-based encounter tracking to prevent inflation
    self.currentSession = {
        id = time(), -- Session ID based on start time
        zone = "",
        encounters = {} -- Track players encountered this session in this zone
    }

    -- Initialize session tracking
    self:StartNewSession()
    -- Register events for tracking
    self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT") -- New: proximity detection
    self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- New: target detection
    self.eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED") -- New: focus detection
    self.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- New: combat log detection

    Crosspaths:DebugLog("Registered events: GROUP_ROSTER_UPDATE, NAME_PLATE_UNIT_ADDED, PLAYER_ENTERING_WORLD, ZONE_CHANGED_NEW_AREA, UPDATE_MOUSEOVER_UNIT, PLAYER_TARGET_CHANGED, PLAYER_FOCUS_CHANGED, COMBAT_LOG_EVENT_UNFILTERED", "DEBUG")

    self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        self:OnEvent(event, ...)
    end)

    -- Validate tracking settings
    if Crosspaths.db.settings and Crosspaths.db.settings.tracking then
        local tracking = Crosspaths.db.settings.tracking
        Crosspaths:DebugLog("Tracking settings: groupTracking=" .. tostring(tracking.enableGroupTracking) ..
                           ", nameplateTracking=" .. tostring(tracking.enableNameplateTracking) ..
                           ", cityTracking=" .. tostring(tracking.enableCityTracking) ..
                           ", throttleMs=" .. tostring(tracking.throttleMs), "INFO")
    else
        Crosspaths:DebugLog("Tracking settings not found or incomplete", "WARN")
    end

    Crosspaths:DebugLog("Tracker initialized and events registered successfully", "INFO")
    return true
end

-- Stop tracking
function Tracker:Stop()
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        Crosspaths:DebugLog("Tracker stopped", "INFO")
    end
end

-- Event handler
function Tracker:OnEvent(event, ...)
    Crosspaths:DebugLog("Tracker received event: " .. event, "DEBUG")

    if not Crosspaths.db then
        Crosspaths:DebugLog("Database not ready for event " .. event, "WARN")
        return
    end

    if not Crosspaths.db.settings then
        Crosspaths:DebugLog("Settings not ready for event " .. event, "WARN")
        return
    end

    if not Crosspaths.db.settings.enabled then
        Crosspaths:DebugLog("Addon disabled, ignoring event " .. event, "DEBUG")
        return
    end

    local args = {...}
    Crosspaths:SafeCall(function()
        if event == "GROUP_ROSTER_UPDATE" then
            Crosspaths:DebugLog("Handling GROUP_ROSTER_UPDATE", "DEBUG")
            self:HandleGroupRosterUpdate()
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            local unitToken = args[1]
            Crosspaths:DebugLog("Handling NAME_PLATE_UNIT_ADDED for unit: " .. tostring(unitToken), "DEBUG")
            self:HandleNameplateAdded(unitToken)
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            Crosspaths:DebugLog("Handling UPDATE_MOUSEOVER_UNIT", "DEBUG")
            self:HandleMouseoverUnit()
        elseif event == "PLAYER_TARGET_CHANGED" then
            Crosspaths:DebugLog("Handling PLAYER_TARGET_CHANGED", "DEBUG")
            self:HandleTargetChanged()
        elseif event == "PLAYER_FOCUS_CHANGED" then
            Crosspaths:DebugLog("Handling PLAYER_FOCUS_CHANGED", "DEBUG")
            self:HandleFocusChanged()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            Crosspaths:DebugLog("Handling COMBAT_LOG_EVENT_UNFILTERED", "DEBUG")
            self:HandleCombatLogEvent(CombatLogGetCurrentEventInfo())
        elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            Crosspaths:DebugLog("Handling zone change event: " .. event, "DEBUG")
            self:HandleZoneChange()
        else
            Crosspaths:DebugLog("Unknown event received: " .. event, "WARN")
        end
    end)
end

-- Handle group roster changes
function Tracker:HandleGroupRosterUpdate()
    if not Crosspaths.db.settings.tracking.enableGroupTracking then
        return
    end

    Crosspaths:DebugLog("Processing group roster update", "DEBUG")

    if IsInGroup() then
        local numMembers = GetNumGroupMembers()
        for i = 1, numMembers - 1 do
            local unit = IsInRaid() and "raid" .. i or "party" .. i

            if UnitExists(unit) then
                local name, realm = UnitNameUnmodified(unit)
                if name and name ~= "" then
                    local fullName = realm and realm ~= "" and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
                    self:RecordEncounter(fullName, "grouped", true)
                end
            end
        end
    end
end

-- Handle nameplate detection
function Tracker:HandleNameplateAdded(unitToken)
    if not Crosspaths.db.settings.tracking.enableNameplateTracking then
        Crosspaths:DebugLog("Nameplate tracking disabled", "DEBUG")
        return
    end

    Crosspaths:DebugLog("Nameplate event received for unit: " .. tostring(unitToken), "DEBUG")

    -- Validate unit token
    if not unitToken or not UnitExists(unitToken) then
        Crosspaths:DebugLog("Invalid or non-existent unit token: " .. tostring(unitToken), "DEBUG")
        return
    end

    -- Check if it's a player and not ourselves
    if not UnitIsPlayer(unitToken) then
        Crosspaths:DebugLog("Unit is not a player: " .. tostring(unitToken), "DEBUG")
        return
    end

    if UnitIsUnit(unitToken, "player") then
        Crosspaths:DebugLog("Unit is the player themselves, ignoring", "DEBUG")
        return
    end

    -- Additional validation: check if unit is actually visible and interactable
    if UnitIsDead(unitToken) and not UnitIsGhost(unitToken) then
        Crosspaths:DebugLog("Unit is dead (not ghost), skipping: " .. tostring(unitToken), "DEBUG")
        return
    end

    -- Get player name with more robust error handling
    local name, realm = UnitNameUnmodified(unitToken)
    Crosspaths:DebugLog("UnitNameUnmodified returned: name=" .. tostring(name) .. ", realm=" .. tostring(realm), "DEBUG")

    -- If UnitNameUnmodified fails, try UnitName as fallback
    if not name or name == "" then
        name, realm = UnitName(unitToken)
        Crosspaths:DebugLog("UnitName fallback returned: name=" .. tostring(name) .. ", realm=" .. tostring(realm), "DEBUG")
    end

    -- Additional validation for the name
    if not name or name == "" then
        Crosspaths:DebugLog("Failed to get valid name from unit token: " .. tostring(unitToken), "WARN")
        return
    end

    -- Validate name format before proceeding
    if string.len(name) < 2 or string.len(name) > 12 then
        Crosspaths:DebugLog("Invalid name length from unit token: " .. tostring(name), "WARN")
        return
    end

    -- Check for invalid characters in name
    if not string.match(name, "^[%a']+$") then -- Allow apostrophes for names like Mal'Ganis
        Crosspaths:DebugLog("Invalid characters in name: " .. tostring(name), "WARN")
        return
    end

    if name and name ~= "" then
        -- Build full name with proper realm handling
        local currentRealm = GetRealmName()
        local fullName

        if realm and realm ~= "" and realm ~= currentRealm then
            fullName = name .. "-" .. realm
        else
            fullName = name .. "-" .. currentRealm
        end

        -- Get current context for better throttling
        local context = Crosspaths:GetEncounterContext()

        -- Enhanced throttling with context awareness and deduplication
        local now = GetTime() * 1000
        local contextKey = fullName .. ":" .. context -- Include context in throttle key
        local lastTime = self.lastUpdate[contextKey] or 0
        local throttleTime = Crosspaths.db.settings.tracking.throttleMs or self.updateThrottle

        -- Apply more aggressive throttling based on context
        if context == "raid" then
            throttleTime = throttleTime * 4 -- 4x throttle time for raids (2000ms default)
        elseif context == "party" then
            throttleTime = throttleTime * 2 -- 2x throttle time for parties (1000ms default)
        elseif context == "instance" then
            throttleTime = throttleTime * 3 -- 3x throttle time for instances (1500ms default)
        end

        -- Additional throttling for same player regardless of context (global deduplication)
        local globalKey = fullName .. ":global"
        local globalLastTime = self.lastUpdate[globalKey] or 0
        local globalThrottleTime = math.min(throttleTime / 2, 1000) -- At least 1 second global throttle

        -- Location-based throttling check
        local locationValid = true
        if Crosspaths.db.settings.tracking.locationBasedThrottling then
            locationValid = self:CheckLocationBasedThrottling(fullName, contextKey)
        end

        if now - lastTime < throttleTime then
            Crosspaths:DebugLog("Throttling nameplate update for " .. fullName .. " in context " .. context .. " (last update " .. (now - lastTime) .. "ms ago)", "DEBUG")
            return
        end

        if now - globalLastTime < globalThrottleTime then
            Crosspaths:DebugLog("Global throttling nameplate update for " .. fullName .. " (last global update " .. (now - globalLastTime) .. "ms ago)", "DEBUG")
            return
        end

        if not locationValid then
            Crosspaths:DebugLog("Location-based throttling nameplate update for " .. fullName .. " (player hasn't moved enough)", "DEBUG")
            return
        end

        -- Update both context-specific and global throttle times
        self.lastUpdate[contextKey] = now
        self.lastUpdate[globalKey] = now

        Crosspaths:DebugLog("Nameplate detected: " .. fullName, "INFO")
        self:RecordEncounter(fullName, "nameplate", false)
    else
        Crosspaths:DebugLog("Could not get valid name from unit token: " .. tostring(unitToken), "WARN")
    end
end

-- Handle zone changes
function Tracker:HandleZoneChange()
    Crosspaths:DebugLog("Zone change detected", "DEBUG")

    -- Start new session on zone change to prevent encounter inflation
    self:StartNewSession()

    -- Prune old data on zone change
    self:PruneOldData()
end

-- Handle mouseover units for proximity detection
function Tracker:HandleMouseoverUnit()
    if not Crosspaths.db.settings.tracking.enableMouseoverTracking then
        return
    end

    local unit = "mouseover"
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then
        return
    end

    local name, realm = UnitNameUnmodified(unit)
    if not name or name == "" then
        return
    end

    local fullName = realm and realm ~= "" and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())

    -- Use throttling to prevent spam
    local now = GetTime() * 1000
    local lastTime = self.lastUpdate[fullName .. ":mouseover"] or 0
    local throttleTime = (Crosspaths.db.settings.tracking.throttleMs or 500) * 2 -- Longer throttle for mouseover

    if now - lastTime >= throttleTime then
        self.lastUpdate[fullName .. ":mouseover"] = now
        Crosspaths:DebugLog("Mouseover detected: " .. fullName, "INFO")
        self:RecordEncounter(fullName, "mouseover", false)
    end
end

-- Handle target changes
function Tracker:HandleTargetChanged()
    if not Crosspaths.db.settings.tracking.enableTargetTracking then
        return
    end

    local unit = "target"
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then
        return
    end

    local name, realm = UnitNameUnmodified(unit)
    if not name or name == "" then
        return
    end

    local fullName = realm and realm ~= "" and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
    Crosspaths:DebugLog("Target changed to: " .. fullName, "INFO")
    self:RecordEncounter(fullName, "target", false)
end

-- Handle focus changes
function Tracker:HandleFocusChanged()
    if not Crosspaths.db.settings.tracking.enableTargetTracking then -- Share setting with target tracking
        return
    end

    local unit = "focus"
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then
        return
    end

    local name, realm = UnitNameUnmodified(unit)
    if not name or name == "" then
        return
    end

    local fullName = realm and realm ~= "" and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
    Crosspaths:DebugLog("Focus changed to: " .. fullName, "INFO")
    self:RecordEncounter(fullName, "focus", false)
end

-- Handle combat log events for player interactions
function Tracker:HandleCombatLogEvent(...)
    if not Crosspaths.db.settings.tracking.enableCombatLogTracking then
        return
    end

    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...

    if not subevent or not sourceName or not destName then
        return
    end

    -- Only track certain combat events that indicate meaningful interaction
    local relevantEvents = {
        "SPELL_DAMAGE", "SPELL_HEAL", "SPELL_AURA_APPLIED", "SPELL_AURA_REMOVED",
        "SWING_DAMAGE", "RANGE_DAMAGE", "ENVIRONMENTAL_DAMAGE"
    }

    local isRelevant = false
    for _, event in ipairs(relevantEvents) do
        if subevent == event then
            isRelevant = true
            break
        end
    end

    if not isRelevant then
        return
    end

    local playerName = UnitName("player")
    if not playerName then
        return
    end

    local playerRealm = GetRealmName()
    if not playerRealm then
        return
    end

    local playerFullName = playerName .. "-" .. playerRealm

    -- Check if we're involved in the combat (either as source or destination)
    local targetPlayer = nil

    -- Validate flags before using bit operations
    if sourceFlags and destFlags then
        if sourceName == playerFullName and destGUID and destName then
            -- We are the source, check if destination is a player
            if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and destName ~= playerFullName then
                targetPlayer = destName
            end
        elseif destName == playerFullName and sourceGUID and sourceName then
            -- We are the destination, check if source is a player
            if bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and sourceName ~= playerFullName then
                targetPlayer = sourceName
            end
        end
    end

    if targetPlayer and targetPlayer ~= "" then
        -- Use throttling for combat log events to prevent spam
        local now = GetTime() * 1000
        local lastTime = self.lastUpdate[targetPlayer .. ":combat"] or 0
        local throttleTime = (Crosspaths.db.settings.tracking.throttleMs or 500) * 5 -- Longer throttle for combat

        if now - lastTime >= throttleTime then
            self.lastUpdate[targetPlayer .. ":combat"] = now
            Crosspaths:DebugLog("Combat interaction detected with: " .. targetPlayer .. " (event: " .. subevent .. ")", "INFO")
            self:RecordEncounter(targetPlayer, "combat", false)
        end
    end
end

-- Start a new session (called on zone change or login)
function Tracker:StartNewSession()
    local currentZone = Crosspaths:GetCurrentZone()
    local sessionId = time()

    -- Only start a new session if zone actually changed or this is initial setup
    if not self.currentSession or self.currentSession.zone ~= currentZone then
        self.currentSession = {
            id = sessionId,
            zone = currentZone,
            encounters = {} -- Reset encounters for new zone/session
        }
        Crosspaths:DebugLog("Started new encounter session for zone: " .. currentZone .. " (session ID: " .. sessionId .. ")", "INFO")
    end
end

-- Check if player has been encountered in current session
function Tracker:HasEncounteredInSession(playerName)
    if not self.currentSession or not self.currentSession.encounters then
        return false
    end
    return self.currentSession.encounters[playerName] == true
end

-- Mark player as encountered in current session
function Tracker:MarkEncounteredInSession(playerName)
    if not self.currentSession then
        self:StartNewSession()
    end
    if not self.currentSession.encounters then
        self.currentSession.encounters = {}
    end
    self.currentSession.encounters[playerName] = true
    Crosspaths:DebugLog("Marked " .. playerName .. " as encountered in current session", "DEBUG")
end

-- Record an encounter
function Tracker:RecordEncounter(playerName, source, isGrouped)
    if not playerName or playerName == "" then
        Crosspaths:DebugLog("RecordEncounter called with empty player name", "WARN")
        return
    end

    -- Enhanced validation to prevent "unknown player" tracking
    local cleanName = string.gsub(playerName, "%s+", "") -- Remove whitespace
    if cleanName == "" then
        Crosspaths:DebugLog("Rejecting empty player name after cleaning: " .. tostring(playerName), "WARN")
        return
    end

    -- Check for various "unknown" patterns
    local lowerName = string.lower(cleanName)
    local invalidPatterns = {
        "^unknown$",
        "^unknownplayer$",
        "^unknown%-",
        "%-unknown$",
        "^%?%?%?",
        "^nil$",
        "^null$",
        "^%s*$"
    }

    for _, pattern in ipairs(invalidPatterns) do
        if string.match(lowerName, pattern) then
            Crosspaths:DebugLog("Rejecting invalid player name pattern: " .. tostring(playerName), "WARN")
            return
        end
    end

    -- Additional validation for realm format
    local name, realm = string.match(playerName, "^([^%-]+)%-(.+)$")
    if name and realm then
        -- Validate that name part is reasonable
        if string.len(name) < 2 or string.len(name) > 12 then
            Crosspaths:DebugLog("Rejecting player name with invalid length: " .. tostring(playerName), "WARN")
            return
        end

        -- Check for reserved words in name
        local lowerNamePart = string.lower(name)
        local reservedWords = {"nil", "null", "none", "void", "test", "temp"}
        for _, reserved in ipairs(reservedWords) do
            if lowerNamePart == reserved then
                Crosspaths:DebugLog("Rejecting reserved word in name: " .. tostring(playerName), "WARN")
                return
            end
        end

        -- Validate that realm part is reasonable
        if string.len(realm) < 2 or string.len(realm) > 50 then
            Crosspaths:DebugLog("Rejecting player name with invalid realm: " .. tostring(playerName), "WARN")
            return
        end
    else
        Crosspaths:DebugLog("Rejecting player name without proper realm format: " .. tostring(playerName), "WARN")
        return
    end

    -- Session-based encounter tracking to prevent inflation
    -- Check if this player has already been encountered in the current session for this zone
    if self:HasEncounteredInSession(playerName) then
        Crosspaths:DebugLog("Player " .. playerName .. " already encountered in current session, skipping count increment (source: " .. tostring(source) .. ")", "DEBUG")

        -- Still update metadata and other tracking, but don't increment encounter count
        local player = Crosspaths.db.players[playerName]
        if player then
            player.lastSeen = time()
            if isGrouped then
                player.grouped = true
            end

            -- Update zones tracking (but don't increment count)
            local currentZone = Crosspaths:GetCurrentZone()
            if not player.zones[currentZone] then
                player.zones[currentZone] = 0
            end

            -- Try to get guild info and enhanced metadata
            local unitToken = self:FindUnitTokenForPlayer(playerName)
            if unitToken then
                local guildName = GetGuildInfo(unitToken)
                if guildName and guildName ~= "" then
                    player.guild = guildName
                end
                self:UpdatePlayerMetadata(player, unitToken)
            end
        end
        return
    end

    Crosspaths:DebugLog("Recording NEW encounter for: " .. playerName .. " (source: " .. tostring(source) .. ", grouped: " .. tostring(isGrouped) .. ")", "INFO")

    -- Validate database state
    if not Crosspaths.db or not Crosspaths.db.players then
        Crosspaths:DebugLog("Database not initialized when recording encounter for " .. playerName, "ERROR")
        return
    end

    -- Get current context
    local currentZone = Crosspaths:GetCurrentZone()
    local context = Crosspaths:GetEncounterContext()
    local timestamp = time()

    Crosspaths:DebugLog("Context: zone=" .. tostring(currentZone) .. ", context=" .. tostring(context) .. ", timestamp=" .. tostring(timestamp), "DEBUG")

    -- Get or create player entry
    local player = Crosspaths.db.players[playerName]
    if not player then
        player = {
            count = 0,
            firstSeen = timestamp,
            lastSeen = timestamp,
            guild = "",
            grouped = false,
            zones = {},
            contexts = {},
            notes = "",
            -- Enhanced metadata for rich social graph
            class = "",
            race = "",
            level = 0,
            specialization = "",
            itemLevel = 0,
            achievementPoints = 0,
            subzone = "",
            levelHistory = {}, -- Track level progression over time
        }
        Crosspaths.db.players[playerName] = player

        if Crosspaths.sessionStats then
            Crosspaths.sessionStats.playersAdded = Crosspaths.sessionStats.playersAdded + 1
        end

        Crosspaths:DebugLog("New player added: " .. playerName, "INFO")
    else
        if Crosspaths.sessionStats then
            Crosspaths.sessionStats.playersUpdated = Crosspaths.sessionStats.playersUpdated + 1
        end
        Crosspaths:DebugLog("Updating existing player: " .. playerName .. " (previous count: " .. player.count .. ")", "DEBUG")

        -- Ensure backward compatibility by adding missing fields to existing players
        if not player.class then player.class = "" end
        if not player.race then player.race = "" end
        if not player.level then player.level = 0 end
        if not player.specialization then player.specialization = "" end
        if not player.itemLevel then player.itemLevel = 0 end
        if not player.achievementPoints then player.achievementPoints = 0 end
        if not player.subzone then player.subzone = "" end
        if not player.levelHistory then player.levelHistory = {} end
    end

    -- Update player data (only increment count for new session encounters)
    player.count = player.count + 1
    player.lastSeen = timestamp

    if isGrouped then
        player.grouped = true
    end

    -- Update zones and subzones
    if not player.zones[currentZone] then
        player.zones[currentZone] = 0
    end
    player.zones[currentZone] = player.zones[currentZone] + 1

    -- Update subzone if we have one
    local currentSubzone = GetSubZoneText()
    if currentSubzone and currentSubzone ~= "" then
        player.subzone = currentSubzone
    end

    -- Update contexts
    if not player.contexts[context] then
        player.contexts[context] = 0
    end
    player.contexts[context] = player.contexts[context] + 1

    -- Try to get guild info and enhanced metadata
    local unitToken = self:FindUnitTokenForPlayer(playerName)
    if unitToken then
        local guildName = GetGuildInfo(unitToken)
        if guildName and guildName ~= "" then
            player.guild = guildName
            Crosspaths:DebugLog("Guild info updated for " .. playerName .. ": " .. guildName, "DEBUG")
        end

        -- Gather enhanced player metadata
        self:UpdatePlayerMetadata(player, unitToken)
    end

    -- Mark as encountered in current session to prevent duplicate counting
    self:MarkEncounteredInSession(playerName)

    if Crosspaths.sessionStats then
        Crosspaths.sessionStats.encountersDetected = Crosspaths.sessionStats.encountersDetected + 1
    end

    Crosspaths:DebugLog("NEW encounter recorded successfully: " .. playerName .. " (total encounters: " .. player.count .. ", source: " .. source .. ", grouped: " .. tostring(isGrouped) .. ")", "INFO")

    -- Check for notifications
    self:CheckNotifications(playerName, player)
end

-- Update player metadata with enhanced information
function Tracker:UpdatePlayerMetadata(player, unitToken)
    if not unitToken or not UnitExists(unitToken) then
        return
    end

    -- Get class information
    local localizedClass, englishClass = UnitClass(unitToken)
    if englishClass and englishClass ~= "" then
        player.class = englishClass
        Crosspaths:DebugLog("Class info updated: " .. englishClass, "DEBUG")
    end

    -- Get race information
    local localizedRace, englishRace = UnitRace(unitToken)
    if localizedRace and localizedRace ~= "" then
        player.race = localizedRace
        Crosspaths:DebugLog("Race info updated: " .. localizedRace, "DEBUG")
    end

    -- Get level information and track progression
    local level = UnitLevel(unitToken)
    if level and level > 0 then
        local previousLevel = player.level or 0
        player.level = level

        -- Track level progression
        if level > previousLevel and previousLevel > 0 then
            if not player.levelHistory then
                player.levelHistory = {}
            end
            table.insert(player.levelHistory, {
                level = level,
                timestamp = time(),
                previousLevel = previousLevel
            })
            Crosspaths:DebugLog("Level progression tracked: " .. previousLevel .. " -> " .. level, "INFO")
        end
        Crosspaths:DebugLog("Level info updated: " .. level, "DEBUG")
    end

    -- Get specialization (only works for grouped players and requires inspection)
    if IsInGroup() and (UnitInParty(unitToken) or UnitInRaid(unitToken)) then
        -- Note: GetInspectSpecialization requires inspection data to be available
        -- This may not always work, especially for newly encountered players
        local specIndex = GetInspectSpecialization(unitToken)
        if specIndex and specIndex > 0 then
            local _, specName = GetSpecializationInfoByID(specIndex)
            if specName and specName ~= "" then
                player.specialization = specName
                Crosspaths:DebugLog("Specialization info updated: " .. specName, "DEBUG")
            end
        end
    end

    -- Get item level (requires inspection, may not always be available)
    -- This function may not exist in all WoW versions, so wrap in pcall
    local success, avgItemLevel = pcall(GetAverageItemLevel, unitToken)
    if success and avgItemLevel and avgItemLevel > 0 then
        player.itemLevel = math.floor(avgItemLevel)
        Crosspaths:DebugLog("Item level updated: " .. player.itemLevel, "DEBUG")
    end

    -- Get achievement points (limited availability)
    -- These functions have limited scope and may not work for all players
    local achievementPoints = nil
    if IsInGroup() and (UnitInParty(unitToken) or UnitInRaid(unitToken)) then
        -- Try to get achievement points if possible
        local achievementSuccess, points = pcall(GetComparisonAchievementPoints, unitToken)
        if achievementSuccess and points and points > 0 then
            achievementPoints = points
        end
    end
    if achievementPoints and achievementPoints > 0 then
        player.achievementPoints = achievementPoints
        Crosspaths:DebugLog("Achievement points updated: " .. achievementPoints, "DEBUG")
    end

    -- Get more granular location information
    local subzone = GetSubZoneText()
    if subzone and subzone ~= "" then
        player.subzone = subzone
        Crosspaths:DebugLog("Subzone info updated: " .. subzone, "DEBUG")
    end
end

-- Find unit token for a player name
function Tracker:FindUnitTokenForPlayer(playerName)
    -- Check group members first
    if IsInGroup() then
        local numMembers = GetNumGroupMembers()
        for i = 1, numMembers do
            local unit
            if i == 1 and not IsInRaid() then
                unit = "player"
            else
                unit = IsInRaid() and "raid" .. i or "party" .. i
            end

            if UnitExists(unit) then
                local name, realm = UnitNameUnmodified(unit)
                if name then
                    local fullName = realm and realm ~= "" and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
                    if fullName == playerName then
                        return unit
                    end
                end
            end
        end
    end

    -- Check target/focus
    for _, unit in ipairs({"target", "focus", "mouseover"}) do
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm = UnitNameUnmodified(unit)
            if name then
                local fullName = realm and realm ~= "" and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
                if fullName == playerName then
                    return unit
                end
            end
        end
    end

    return nil
end

-- Check location-based throttling to prevent duplicate counts for players who haven't moved
function Tracker:CheckLocationBasedThrottling(playerName, contextKey)
    -- Get current player position
    local currentMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not currentMapID then
        -- If we can't get map info, fall back to time-based throttling only
        Crosspaths:DebugLog("Could not get current map ID for location tracking", "DEBUG")
        return true
    end

    local currentPosition = C_Map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(currentMapID, "player")
    if not currentPosition then
        -- If we can't get position, fall back to time-based throttling only
        Crosspaths:DebugLog("Could not get current position for location tracking", "DEBUG")
        return true
    end

    local currentX, currentY = currentPosition:GetXY()
    if not currentX or not currentY then
        Crosspaths:DebugLog("Could not extract X,Y coordinates from position", "DEBUG")
        return true
    end

    -- Check if we have a previous position for this player
    local lastPos = self.lastPosition[contextKey]
    if not lastPos then
        -- First time seeing this player, store position and allow
        self.lastPosition[contextKey] = {
            mapID = currentMapID,
            x = currentX,
            y = currentY,
            timestamp = GetTime() * 1000
        }
        Crosspaths:DebugLog("First position recorded for " .. playerName .. " at (" .. string.format("%.3f", currentX) .. ", " .. string.format("%.3f", currentY) .. ") on map " .. currentMapID, "DEBUG")
        return true
    end

    -- If map changed, always allow (player changed zones)
    if lastPos.mapID ~= currentMapID then
        self.lastPosition[contextKey] = {
            mapID = currentMapID,
            x = currentX,
            y = currentY,
            timestamp = GetTime() * 1000
        }
        Crosspaths:DebugLog("Map changed for " .. playerName .. " from " .. lastPos.mapID .. " to " .. currentMapID .. ", allowing encounter", "DEBUG")
        return true
    end

    -- Calculate distance moved
    local distance = self:CalculateDistance(lastPos.x, lastPos.y, currentX, currentY)
    local minimumDistance = Crosspaths.db.settings.tracking.minimumMoveDistance or 0.01

    if distance >= minimumDistance then
        -- Player moved enough, update position and allow
        self.lastPosition[contextKey] = {
            mapID = currentMapID,
            x = currentX,
            y = currentY,
            timestamp = GetTime() * 1000
        }
        Crosspaths:DebugLog("Player " .. playerName .. " moved " .. string.format("%.4f", distance) .. " units (minimum: " .. string.format("%.4f", minimumDistance) .. "), allowing encounter", "DEBUG")
        return true
    else
        -- Player hasn't moved enough
        Crosspaths:DebugLog("Player " .. playerName .. " only moved " .. string.format("%.4f", distance) .. " units (minimum: " .. string.format("%.4f", minimumDistance) .. "), blocking encounter", "DEBUG")
        return false
    end
end

-- Calculate distance between two points (simple Euclidean distance)
function Tracker:CalculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Check for notification triggers
function Tracker:CheckNotifications(playerName, player)
    if not Crosspaths.db.settings.notifications then
        return
    end

    local settings = Crosspaths.db.settings.notifications
    local now = GetTime() * 1000 -- Use milliseconds for more precise throttling

    -- Notification throttling to prevent spam (minimum 30 seconds between same notifications)
    local notificationThrottle = 30000 -- 30 seconds

    -- Frequent player notification
    if settings.notifyFrequentPlayers and player.count >= settings.frequentPlayerThreshold then
        if player.count == settings.frequentPlayerThreshold then
            local key = "frequent:" .. playerName
            local lastTime = self.lastNotification[key] or 0
            if now - lastTime >= notificationThrottle then
                self:ShowNotification("Frequent Player", playerName .. " encountered " .. player.count .. " times", "frequent")
                self.lastNotification[key] = now
            end
        end
    end

    -- Previous group member notification (throttled heavily)
    if settings.notifyPreviousGroupMembers and player.grouped and player.count > 1 then
        local key = "grouped:" .. playerName
        local lastTime = self.lastNotification[key] or 0
        -- Use longer throttle for group notifications (5 minutes) to prevent raid spam
        if now - lastTime >= 300000 then -- 5 minutes
            self:ShowNotification("Previous Group Member", "You've grouped with " .. playerName .. " before!", "group")
            self.lastNotification[key] = now
        end
    end

    -- Repeat encounter notification (only for first few encounters)
    if settings.notifyRepeatEncounters and player.count > 1 and player.count <= 3 then
        local key = "repeat:" .. playerName .. ":" .. player.count
        local lastTime = self.lastNotification[key] or 0
        if now - lastTime >= notificationThrottle then
            self:ShowNotification("Repeat Encounter", playerName .. " (seen " .. player.count .. " times)", "repeat")
            self.lastNotification[key] = now
        end
    end
end

-- Show notification
function Tracker:ShowNotification(title, message, notificationType)
    if Crosspaths.UI and Crosspaths.UI.ShowToast then
        Crosspaths.UI:ShowToast(title, message, notificationType)
    else
        -- Fallback to chat message
        Crosspaths:Message("[" .. title .. "] " .. message)
    end
end

-- Prune old data
function Tracker:PruneOldData()
    if not Crosspaths.db.settings.tracking.pruneAfterDays then
        return
    end

    local maxAge = Crosspaths.db.settings.tracking.pruneAfterDays * 24 * 60 * 60 -- Convert to seconds
    local currentTime = time()
    local pruned = 0

    for playerName, player in pairs(Crosspaths.db.players) do
        if player.lastSeen and (currentTime - player.lastSeen) > maxAge then
            Crosspaths.db.players[playerName] = nil
            pruned = pruned + 1
        end
    end

    -- Check max player limit
    local maxPlayers = Crosspaths.db.settings.tracking.maxPlayers or 10000
    local currentCount = 0
    for _ in pairs(Crosspaths.db.players) do
        currentCount = currentCount + 1
    end

    if currentCount > maxPlayers then
        -- Remove oldest players
        local sortedPlayers = {}
        for name, player in pairs(Crosspaths.db.players) do
            table.insert(sortedPlayers, {name = name, lastSeen = player.lastSeen})
        end

        table.sort(sortedPlayers, function(a, b)
            return a.lastSeen < b.lastSeen
        end)

        local toRemove = currentCount - maxPlayers
        for i = 1, toRemove do
            if sortedPlayers[i] then
                Crosspaths.db.players[sortedPlayers[i].name] = nil
                pruned = pruned + 1
            end
        end
    end

    -- Clean up old throttle, notification, and position data (older than 1 hour)
    local oneHourAgo = GetTime() * 1000 - 3600000 -- 1 hour in milliseconds
    local throttlesPruned = 0
    local notificationsPruned = 0
    local positionsPruned = 0

    for key, timestamp in pairs(self.lastUpdate) do
        if timestamp < oneHourAgo then
            self.lastUpdate[key] = nil
            throttlesPruned = throttlesPruned + 1
        end
    end

    for key, timestamp in pairs(self.lastNotification) do
        if timestamp < oneHourAgo then
            self.lastNotification[key] = nil
            notificationsPruned = notificationsPruned + 1
        end
    end

    for key, positionData in pairs(self.lastPosition) do
        if positionData.timestamp < oneHourAgo then
            self.lastPosition[key] = nil
            positionsPruned = positionsPruned + 1
        end
    end

    if pruned > 0 then
        Crosspaths:DebugLog("Pruned " .. pruned .. " old player records", "INFO")
    end
    if throttlesPruned > 0 then
        Crosspaths:DebugLog("Pruned " .. throttlesPruned .. " old throttle entries", "DEBUG")
    end
    if notificationsPruned > 0 then
        Crosspaths:DebugLog("Pruned " .. notificationsPruned .. " old notification entries", "DEBUG")
    end
    if positionsPruned > 0 then
        Crosspaths:DebugLog("Pruned " .. positionsPruned .. " old position entries", "DEBUG")
    end
end