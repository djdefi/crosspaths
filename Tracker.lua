-- Crosspaths Tracker.lua
-- Player encounter tracking and event handling

local addonName, Crosspaths = ...

Crosspaths.Tracker = {}
local Tracker = Crosspaths.Tracker

-- Initialize tracker
function Tracker:Initialize()
    self.eventFrame = CreateFrame("Frame")
    self.lastUpdate = {}
    self.updateThrottle = 500 -- 500ms throttle
    
    -- Register events for tracking
    self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        self:OnEvent(event, ...)
    end)
    
    Crosspaths:DebugLog("Tracker initialized and events registered", "INFO")
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
    if not Crosspaths.db or not Crosspaths.db.settings.enabled then
        return
    end
    
    local args = {...}
    Crosspaths:SafeCall(function()
        if event == "GROUP_ROSTER_UPDATE" then
            self:HandleGroupRosterUpdate()
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            local unitToken = args[1]
            self:HandleNameplateAdded(unitToken)
        elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            self:HandleZoneChange()
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
        return
    end
    
    if not UnitIsPlayer(unitToken) or UnitIsUnit(unitToken, "player") then
        return
    end
    
    local name, realm = UnitNameUnmodified(unitToken)
    if name and name ~= "" then
        local fullName = realm and realm ~= "" and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
        
        -- Throttle nameplate updates
        local now = GetTime() * 1000
        local lastTime = self.lastUpdate[fullName] or 0
        if now - lastTime < self.updateThrottle then
            return
        end
        self.lastUpdate[fullName] = now
        
        Crosspaths:DebugLog("Nameplate detected: " .. fullName, "DEBUG")
        self:RecordEncounter(fullName, "nameplate", false)
    end
end

-- Handle zone changes
function Tracker:HandleZoneChange()
    Crosspaths:DebugLog("Zone change detected", "DEBUG")
    
    -- Prune old data on zone change
    self:PruneOldData()
end

-- Record an encounter
function Tracker:RecordEncounter(playerName, source, isGrouped)
    if not playerName or playerName == "" then
        return
    end
    
    -- Get current context
    local currentZone = Crosspaths:GetCurrentZone()
    local context = Crosspaths:GetEncounterContext()
    local timestamp = time()
    
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
    end
    
    -- Update player data
    player.count = player.count + 1
    player.lastSeen = timestamp
    
    if isGrouped then
        player.grouped = true
    end
    
    -- Update zones
    if not player.zones[currentZone] then
        player.zones[currentZone] = 0
    end
    player.zones[currentZone] = player.zones[currentZone] + 1
    
    -- Update contexts
    if not player.contexts[context] then
        player.contexts[context] = 0
    end
    player.contexts[context] = player.contexts[context] + 1
    
    -- Try to get guild info
    local unitToken = self:FindUnitTokenForPlayer(playerName)
    if unitToken then
        local guildName = GetGuildInfo(unitToken)
        if guildName and guildName ~= "" then
            player.guild = guildName
        end
    end
    
    if Crosspaths.sessionStats then
        Crosspaths.sessionStats.encountersDetected = Crosspaths.sessionStats.encountersDetected + 1
    end
    
    Crosspaths:DebugLog("Encounter recorded: " .. playerName .. " (source: " .. source .. ", grouped: " .. tostring(isGrouped) .. ")", "DEBUG")
    
    -- Check for notifications
    self:CheckNotifications(playerName, player)
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

-- Check for notification triggers
function Tracker:CheckNotifications(playerName, player)
    if not Crosspaths.db.settings.notifications then
        return
    end
    
    local settings = Crosspaths.db.settings.notifications
    
    -- Frequent player notification
    if settings.notifyFrequentPlayers and player.count >= settings.frequentPlayerThreshold then
        if player.count == settings.frequentPlayerThreshold then
            self:ShowNotification("Frequent Player", playerName .. " encountered " .. player.count .. " times")
        end
    end
    
    -- Previous group member notification
    if settings.notifyPreviousGroupMembers and player.grouped and player.count > 1 then
        self:ShowNotification("Previous Group Member", "You've grouped with " .. playerName .. " before!")
    end
    
    -- Repeat encounter notification
    if settings.notifyRepeatEncounters and player.count > 1 and player.count <= 5 then
        self:ShowNotification("Repeat Encounter", playerName .. " (seen " .. player.count .. " times)")
    end
end

-- Show notification
function Tracker:ShowNotification(title, message)
    if Crosspaths.UI and Crosspaths.UI.ShowToast then
        Crosspaths.UI:ShowToast(title, message)
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
    
    if pruned > 0 then
        Crosspaths:DebugLog("Pruned " .. pruned .. " old player records", "INFO")
    end
end