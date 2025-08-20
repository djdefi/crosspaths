-- Crosspaths TitanPanel.lua
-- Titan Panel integration plugin

local addonName, Crosspaths = ...

-- Check if Titan Panel is available and provide user feedback
Crosspaths.TitanPanel = {}
local TitanPanel = Crosspaths.TitanPanel

if not TitanPanelUtils then
    -- Delay the check to ensure all addons are loaded
    local checkFrame = CreateFrame("Frame")
    checkFrame:RegisterEvent("ADDON_LOADED")
    checkFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
        if loadedAddonName == "Titan" or loadedAddonName == "TitanClassic" then
            -- TitanPanel was loaded after us, try to initialize
            if TitanPanelUtils and Crosspaths and Crosspaths.TitanPanel then
                Crosspaths.TitanPanel:Initialize()
                Crosspaths:DebugLog("TitanPanel loaded after Crosspaths, initializing integration", "INFO")
            end
        end
    end)
    
    if Crosspaths then
        Crosspaths:DebugLog("TitanPanel not detected during load - will check again when addons load", "INFO")
    end
    -- Don't return - still create the TitanPanel object
end

local TITAN_CROSSPATHS_ID = "Crosspaths"
local TITAN_CROSSPATHS_FREQUENCY = 30 -- Update every 30 seconds

-- Plugin registration data
local titanPluginInfo = {
    id = TITAN_CROSSPATHS_ID,
    category = "Information",
    version = Crosspaths.version or "0.1.17",
    menuText = "Crosspaths",
    buttonTextFunction = "TitanPanelCrosspathsButton_GetButtonText",
    tooltipTitle = "Crosspaths - Social Memory Tracker",
    tooltipTextFunction = "TitanPanelCrosspathsButton_GetTooltipText",
    iconWidth = 16,
    icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
    controlVariables = {
        ShowIcon = true,
        ShowLabelText = true,
        ShowRegularText = false,
        ShowColoredText = false,
        DisplayOnRightSide = false,
    },
    savedVariables = {
        ShowIcon = 1,
        ShowLabelText = 1,
        ShowPlayers = 1,
        ShowEncounters = 1,
        ShowGuilds = 0,
        ShowSession = 0,
    },
    -- Add standard TitanPanel plugin properties
    frequency = TITAN_CROSSPATHS_FREQUENCY,
    clickFunction = "TitanPanelCrosspathsButton_OnClick",
    rightClickFunction = "TitanPanelRightClickMenu_PrepareCrosspathsMenu",
    -- Plugin info for modern versions
    author = "Crosspaths Team",
    email = "support@crosspaths.com",
    website = "https://github.com/djdefi/crosspaths",
}

-- Initialize Titan Panel plugin
function TitanPanel:Initialize()
    -- Check for TitanPanel availability with comprehensive detection methods
    local titanDetected = false
    local detectionMethod = "none"
    
    -- Check for modern TitanPanel
    if TitanPanelUtils then
        titanDetected = true
        detectionMethod = "TitanPanelUtils"
    -- Check for classic TitanPanel
    elseif TitanUtils_RegisterPlugin then
        titanDetected = true
        detectionMethod = "TitanUtils_RegisterPlugin"
    -- Check for legacy TitanPanel
    elseif _G["Titan"] then
        titanDetected = true
        detectionMethod = "Titan global"
    -- Check for other TitanPanel variants
    elseif _G["TitanPanel"] then
        titanDetected = true
        detectionMethod = "TitanPanel global"
    end
    
    if not titanDetected then
        Crosspaths:DebugLog("TitanPanel not detected - no compatible TitanPanel API found", "INFO")
        return false
    end
    
    Crosspaths:DebugLog("TitanPanel detected via: " .. detectionMethod, "DEBUG")

    -- Update plugin info with current version
    titanPluginInfo.version = Crosspaths.version or "0.1.17"

    -- Check for the correct registration function with comprehensive compatibility
    local registerFunc = nil
    local registrationMethod = "unknown"
    
    -- Modern TitanPanel (most common)
    if TitanPanelUtils and TitanPanelUtils.RegisterPlugin then
        registerFunc = function(info) TitanPanelUtils:RegisterPlugin(info) end
        registrationMethod = "TitanPanelUtils:RegisterPlugin"
    -- Alternative modern method
    elseif TitanPanelUtils and TitanPanelUtils.AddButton then
        registerFunc = function(info) TitanPanelUtils:AddButton(info) end
        registrationMethod = "TitanPanelUtils:AddButton"
    -- Classic TitanPanel method
    elseif TitanUtils_RegisterPlugin then
        registerFunc = TitanUtils_RegisterPlugin
        registrationMethod = "TitanUtils_RegisterPlugin"
    -- Legacy TitanPanel method
    elseif _G["Titan"] and _G["Titan"].RegisterPlugin then
        registerFunc = function(info) _G["Titan"]:RegisterPlugin(info) end
        registrationMethod = "Titan:RegisterPlugin"
    end
    
    if not registerFunc then
        Crosspaths:DebugLog("TitanPanel registration function not found", "ERROR")
        if TitanPanelUtils then
            Crosspaths:DebugLog("Available TitanPanelUtils functions:", "DEBUG")
            for key, value in pairs(TitanPanelUtils) do
                if type(value) == "function" and (string.find(key:lower(), "register") or string.find(key:lower(), "add")) then
                    Crosspaths:DebugLog("  - " .. key, "DEBUG")
                end
            end
        end
        return false
    end

    -- Try to register the plugin
    local success, error = pcall(registerFunc, titanPluginInfo)
    if not success then
        Crosspaths:DebugLog("TitanPanel registration failed: " .. tostring(error), "ERROR")
        return false
    end

    Crosspaths:DebugLog("TitanPanel plugin registered successfully using " .. registrationMethod, "INFO")
    
    -- Start the update timer if registration was successful
    self:StartUpdateTimer()
    
    return true
end

-- Get button text for Titan Panel
function TitanPanelCrosspathsButton_GetButtonText(id)
    local text = ""
    
    -- Try to get settings with fallback for API compatibility
    local function getTitanVar(id, setting)
        if TitanGetVar then
            return TitanGetVar(id, setting)
        elseif TitanPanelGetVar then
            return TitanPanelGetVar(id, setting)
        else
            -- Fallback defaults
            if setting == "ShowPlayers" then return 1 end
            if setting == "ShowEncounters" then return 1 end
            return 0
        end
    end
    
    -- Try to get colored text with fallback for API compatibility
    local function getColoredText(textValue, color)
        if TitanUtils_GetColoredText and TITAN_PANEL_TEXT_COLOR then
            return TitanUtils_GetColoredText(textValue, TITAN_PANEL_TEXT_COLOR)
        elseif TitanPanelUtils and TitanPanelUtils.GetColoredText then
            return TitanPanelUtils:GetColoredText(textValue, {r=1, g=1, b=1})
        else
            -- Fallback to simple white text
            return "|cFFFFFFFF" .. textValue .. "|r"
        end
    end
    
    local settings = getTitanVar(TITAN_CROSSPATHS_ID, "ShowPlayers")
    local showEncounters = getTitanVar(TITAN_CROSSPATHS_ID, "ShowEncounters")
    local showGuilds = getTitanVar(TITAN_CROSSPATHS_ID, "ShowGuilds")
    local showSession = getTitanVar(TITAN_CROSSPATHS_ID, "ShowSession")

    local stats = {}

    if settings and settings == 1 then
        local playerCount = Crosspaths:CountPlayers() or 0
        table.insert(stats, getColoredText("Players: " .. playerCount))
    end

    if showEncounters and showEncounters == 1 then
        local encounterCount = Crosspaths:CountEncounters() or 0
        table.insert(stats, getColoredText("Encounters: " .. encounterCount))
    end

    if showGuilds and showGuilds == 1 then
        local guildCount = Crosspaths:CountGuilds() or 0
        table.insert(stats, getColoredText("Guilds: " .. guildCount))
    end

    if showSession and showSession == 1 then
        local sessionStats = Crosspaths.Engine and Crosspaths.Engine:GetSessionStats() or {}
        local sessionEncounters = sessionStats.encountersThisSession or 0
        table.insert(stats, getColoredText("Session: " .. sessionEncounters))
    end

    return table.concat(stats, " | ")
end

-- Get tooltip text for Titan Panel
function TitanPanelCrosspathsButton_GetTooltipText()
    local tooltip = {}
    
    -- Helper function to get colored text with fallback
    local function getColoredText(text, colorType)
        if TitanUtils_GetColoredText then
            local color = nil
            if colorType == "highlight" then
                color = TITAN_PANEL_HIGHLIGHT_COLOR or {r=1, g=1, b=0.2}
            else
                color = TITAN_PANEL_TEXT_COLOR or {r=1, g=1, b=1}
            end
            return TitanUtils_GetColoredText(text, color)
        elseif TitanPanelUtils and TitanPanelUtils.GetColoredText then
            local color = colorType == "highlight" and {r=1, g=1, b=0.2} or {r=1, g=1, b=1}
            return TitanPanelUtils:GetColoredText(text, color)
        else
            -- Fallback to manual color codes
            local colorCode = colorType == "highlight" and "|cFFFFFF33" or "|cFFFFFFFF"
            return colorCode .. text .. "|r"
        end
    end

    -- Header
    table.insert(tooltip, getColoredText("Crosspaths Statistics", "highlight"))
    table.insert(tooltip, " ")

    -- Basic stats
    local playerCount = Crosspaths:CountPlayers() or 0
    local encounterCount = Crosspaths:CountEncounters() or 0
    local guildCount = Crosspaths:CountGuilds() or 0

    table.insert(tooltip, getColoredText("Total Players:", "normal") ..
                 getColoredText(" " .. playerCount, "highlight"))
    table.insert(tooltip, getColoredText("Total Encounters:", "normal") ..
                 getColoredText(" " .. encounterCount, "highlight"))
    table.insert(tooltip, getColoredText("Guilds Tracked:", "normal") ..
                 getColoredText(" " .. guildCount, "highlight"))

    -- Session stats
    if Crosspaths.Engine then
        local sessionStats = Crosspaths.Engine:GetSessionStats()
        if sessionStats then
            table.insert(tooltip, " ")
            table.insert(tooltip, getColoredText("Session Statistics:", "highlight"))
            table.insert(tooltip, getColoredText("New Players:", "normal") ..
                         getColoredText(" " .. (sessionStats.newPlayersThisSession or 0), "highlight"))
            table.insert(tooltip, getColoredText("Encounters:", "normal") ..
                         getColoredText(" " .. (sessionStats.encountersThisSession or 0), "highlight"))

            if sessionStats.sessionDuration and sessionStats.sessionDuration > 0 then
                local duration = math.floor(sessionStats.sessionDuration / 60)
                table.insert(tooltip, getColoredText("Session Time:", "normal") ..
                             getColoredText(" " .. duration .. " minutes", "highlight"))
            end
        end
    end

    -- Recent activity
    if Crosspaths.Engine then
        local recentActivity = Crosspaths.Engine:GetRecentActivity()
        if recentActivity and recentActivity.last24Hours then
            table.insert(tooltip, " ")
            table.insert(tooltip, getColoredText("Recent Activity (24h):", "highlight"))
            table.insert(tooltip, getColoredText("Players:", "normal") ..
                         getColoredText(" " .. recentActivity.last24Hours.players, "highlight"))
            table.insert(tooltip, getColoredText("Encounters:", "normal") ..
                         getColoredText(" " .. recentActivity.last24Hours.encounters, "highlight"))
        end
    end

    -- Instructions
    table.insert(tooltip, " ")
    table.insert(tooltip, getColoredText("Left Click:", "highlight") ..
                 getColoredText(" Open Crosspaths", "normal"))
    table.insert(tooltip, getColoredText("Right Click:", "highlight") ..
                 getColoredText(" Plugin Options", "normal"))

    return table.concat(tooltip, "\n")
end

-- Handle left click on Titan Panel button
function TitanPanelCrosspathsButton_OnClick(self, button)
    if not button then
        button = "LeftButton" -- Default for compatibility
    end
    
    if button == "LeftButton" then
        if Crosspaths and Crosspaths.UI then
            local success, error = pcall(function()
                Crosspaths.UI:Toggle()
            end)
            if not success then
                Crosspaths:DebugLog("Failed to toggle Crosspaths UI from TitanPanel: " .. tostring(error), "ERROR")
            end
        else
            Crosspaths:DebugLog("Crosspaths UI not available for TitanPanel click", "WARN")
        end
    else
        -- Handle right-click and other buttons
        if TitanPanelButton_OnClick then
            local success, error = pcall(TitanPanelButton_OnClick, self, button)
            if not success then
                Crosspaths:DebugLog("TitanPanel right-click handler failed: " .. tostring(error), "WARN")
            end
        elseif TitanPanel_OnClick then
            local success, error = pcall(TitanPanel_OnClick, self, button)
            if not success then
                Crosspaths:DebugLog("TitanPanel legacy click handler failed: " .. tostring(error), "WARN")
            end
        end
    end
end

-- Right-click menu for Titan Panel
function TitanPanelRightClickMenu_PrepareCrosspathsMenu()
    local info = {}
    
    -- Helper function to safely get Titan variables with fallback
    local function getTitanVar(id, setting)
        if TitanGetVar then
            return TitanGetVar(id, setting)
        elseif TitanPanelGetVar then
            return TitanPanelGetVar(id, setting)
        else
            -- Fallback to savedVariables defaults
            if setting == "ShowPlayers" then return 1 end
            if setting == "ShowEncounters" then return 1 end
            return 0
        end
    end
    
    -- Helper function to safely toggle Titan variables
    local function toggleTitanVar(id, setting)
        if TitanToggleVar then
            TitanToggleVar(id, setting)
        elseif TitanPanelToggleVar then
            TitanPanelToggleVar(id, setting)
        else
            -- Fallback: manual toggle (this is basic, real implementation would persist to savedvars)
            Crosspaths:DebugLog("TitanPanel toggle function not available, using fallback", "WARN")
        end
    end
    
    -- Helper function to safely update button
    local function updateButton(id)
        if TitanPanelButton_UpdateButton then
            TitanPanelButton_UpdateButton(id)
        elseif TitanPanel_UpdateButton then
            TitanPanel_UpdateButton(id)
        else
            Crosspaths:DebugLog("TitanPanel update function not available", "WARN")
        end
    end

    -- Show players option
    info.text = "Show Player Count"
    info.checked = getTitanVar(TITAN_CROSSPATHS_ID, "ShowPlayers") == 1
    info.func = function()
        toggleTitanVar(TITAN_CROSSPATHS_ID, "ShowPlayers")
        updateButton(TITAN_CROSSPATHS_ID)
    end
    UIDropDownMenu_AddButton(info)

    -- Show encounters option
    info = {} -- Reset info table
    info.text = "Show Encounter Count"
    info.checked = getTitanVar(TITAN_CROSSPATHS_ID, "ShowEncounters") == 1
    info.func = function()
        toggleTitanVar(TITAN_CROSSPATHS_ID, "ShowEncounters")
        updateButton(TITAN_CROSSPATHS_ID)
    end
    UIDropDownMenu_AddButton(info)

    -- Show guilds option
    info = {} -- Reset info table
    info.text = "Show Guild Count"
    info.checked = getTitanVar(TITAN_CROSSPATHS_ID, "ShowGuilds") == 1
    info.func = function()
        toggleTitanVar(TITAN_CROSSPATHS_ID, "ShowGuilds")
        updateButton(TITAN_CROSSPATHS_ID)
    end
    UIDropDownMenu_AddButton(info)

    -- Show session option
    info = {} -- Reset info table
    info.text = "Show Session Stats"
    info.checked = getTitanVar(TITAN_CROSSPATHS_ID, "ShowSession") == 1
    info.func = function()
        toggleTitanVar(TITAN_CROSSPATHS_ID, "ShowSession")
        updateButton(TITAN_CROSSPATHS_ID)
    end
    UIDropDownMenu_AddButton(info)

    -- Separator
    info = {}
    info.text = ""
    info.disabled = true
    UIDropDownMenu_AddButton(info)

    -- Open Crosspaths
    info = {}
    info.text = "Open Crosspaths"
    info.func = function()
        if Crosspaths.UI then
            Crosspaths.UI:Show()
        end
    end
    UIDropDownMenu_AddButton(info)

    -- Configuration
    info.text = "Configuration"
    info.func = function()
        if Crosspaths.Config then
            Crosspaths.Config:Show()
        end
    end
    UIDropDownMenu_AddButton(info)

    -- Generate digest
    info.text = "Generate Digest"
    info.hasArrow = true
    info.func = nil
    UIDropDownMenu_AddButton(info)

    -- Digest submenu
    if UIDROPDOWNMENU_MENU_LEVEL == 2 then
        info = {}
        info.text = "Daily Digest"
        info.func = function()
            if Crosspaths.Engine and Crosspaths.UI then
                local digest = Crosspaths.Engine:GenerateDailyDigest()
                Crosspaths.UI:ShowDigestReport("Daily Digest", digest)
            end
        end
        UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

        info.text = "Weekly Digest"
        info.func = function()
            if Crosspaths.Engine and Crosspaths.UI then
                local digest = Crosspaths.Engine:GenerateWeeklyDigest()
                Crosspaths.UI:ShowDigestReport("Weekly Digest", digest)
            end
        end
        UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

        info.text = "Monthly Digest"
        info.func = function()
            if Crosspaths.Engine and Crosspaths.UI then
                local digest = Crosspaths.Engine:GenerateMonthlyDigest()
                Crosspaths.UI:ShowDigestReport("Monthly Digest", digest)
            end
        end
        UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
    end
end

-- Update button periodically
function TitanPanel:StartUpdateTimer()
    -- Only start timer if TitanPanel is available and we have an update function
    local updateFunc = TitanPanelButton_UpdateButton or TitanPanel_UpdateButton
    if not updateFunc then
        Crosspaths:DebugLog("No TitanPanel update function available, skipping timer", "DEBUG")
        return
    end

    if self.updateTimer then
        self.updateTimer:Cancel()
    end

    -- Use C_Timer if available (modern WoW), otherwise fallback to manual scheduling
    if C_Timer and C_Timer.NewTicker then
        self.updateTimer = C_Timer.NewTicker(TITAN_CROSSPATHS_FREQUENCY, function()
            local success, error = pcall(updateFunc, TITAN_CROSSPATHS_ID)
            if not success then
                Crosspaths:DebugLog("TitanPanel update failed: " .. tostring(error), "WARN")
            end
        end)
        Crosspaths:DebugLog("TitanPanel update timer started with C_Timer", "DEBUG")
    else
        -- Legacy timer fallback for older WoW versions
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame.frequency = TITAN_CROSSPATHS_FREQUENCY
        frame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= self.frequency then
                self.elapsed = 0
                local success, error = pcall(updateFunc, TITAN_CROSSPATHS_ID)
                if not success then
                    Crosspaths:DebugLog("TitanPanel update failed: " .. tostring(error), "WARN")
                end
            end
        end)
        self.updateTimer = frame
        Crosspaths:DebugLog("TitanPanel update timer started with legacy method", "DEBUG")
    end
end

-- Stop update timer
function TitanPanel:StopUpdateTimer()
    if self.updateTimer then
        if type(self.updateTimer.Cancel) == "function" then
            -- Modern C_Timer
            self.updateTimer:Cancel()
        elseif type(self.updateTimer.SetScript) == "function" then
            -- Legacy frame-based timer
            self.updateTimer:SetScript("OnUpdate", nil)
        end
        self.updateTimer = nil
        Crosspaths:DebugLog("TitanPanel update timer stopped", "DEBUG")
    end
end

-- Helper function to get encounter count
if not Crosspaths.CountEncounters then
    function Crosspaths:CountEncounters()
        if not self.db or not self.db.players then
            return 0
        end

        local count = 0
        for _, player in pairs(self.db.players) do
            count = count + (player.count or 0)
        end
        return count
    end
end

-- Helper function to get guild count
if not Crosspaths.CountGuilds then
    function Crosspaths:CountGuilds()
        if not self.db or not self.db.players then
            return 0
        end

        local guilds = {}
        for _, player in pairs(self.db.players) do
            if player.guild and player.guild ~= "" then
                guilds[player.guild] = true
            end
        end

        local count = 0
        for _ in pairs(guilds) do
            count = count + 1
        end
        return count
    end
end