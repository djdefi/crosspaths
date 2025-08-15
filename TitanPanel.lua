-- Crosspaths TitanPanel.lua
-- Titan Panel integration plugin

local addonName, Crosspaths = ...

-- Check if Titan Panel is available and provide user feedback
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
    return
end

Crosspaths.TitanPanel = {}
local TitanPanel = Crosspaths.TitanPanel

local TITAN_CROSSPATHS_ID = "Crosspaths"
local TITAN_CROSSPATHS_FREQUENCY = 30 -- Update every 30 seconds

-- Plugin registration data
local titanPluginInfo = {
    id = TITAN_CROSSPATHS_ID,
    category = "Information",
    version = Crosspaths.version or "0.1.9",
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
    }
}

-- Initialize Titan Panel plugin
function TitanPanel:Initialize()
    -- Check for TitanPanel availability with multiple detection methods
    if not (TitanPanelUtils or TitanUtils_RegisterPlugin or _G["Titan"]) then
        Crosspaths:DebugLog("TitanPanel not detected - no TitanPanel globals found", "INFO")
        Crosspaths:Message("TitanPanel addon not detected - install TitanPanel for toolbar integration")
        return false
    end

    -- Check for the correct registration function with broader compatibility
    local registerFunc = nil
    if TitanPanelUtils and TitanPanelUtils.RegisterPlugin then
        registerFunc = function(info) TitanPanelUtils:RegisterPlugin(info) end
        Crosspaths:DebugLog("Using TitanPanelUtils:RegisterPlugin method", "INFO")
    elseif TitanUtils_RegisterPlugin then
        registerFunc = TitanUtils_RegisterPlugin
        Crosspaths:DebugLog("Using TitanUtils_RegisterPlugin method", "INFO")
    elseif TitanPanelUtils and TitanPanelUtils.AddButton then
        registerFunc = function(info) TitanPanelUtils:AddButton(info) end
        Crosspaths:DebugLog("Using TitanPanelUtils:AddButton method", "INFO")
    end
    
    if not registerFunc then
        Crosspaths:DebugLog("TitanPanel registration function not found - checking available functions", "ERROR")
        if TitanPanelUtils then
            for key, value in pairs(TitanPanelUtils) do
                if type(value) == "function" and (string.find(key, "Register") or string.find(key, "Add")) then
                    Crosspaths:DebugLog("Available TitanPanelUtils function: " .. key, "DEBUG")
                end
            end
        end
        Crosspaths:Message("TitanPanel integration failed - unsupported TitanPanel version")
        return false
    end

    -- Try to register the plugin
    local success, error = pcall(registerFunc, titanPluginInfo)
    if not success then
        Crosspaths:DebugLog("TitanPanel registration failed: " .. tostring(error), "ERROR")
        Crosspaths:Message("TitanPanel integration failed: " .. tostring(error))
        return false
    end

    Crosspaths:DebugLog("TitanPanel plugin registered successfully", "INFO")
    Crosspaths:Message("TitanPanel integration active - check your TitanPanel bar")
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

    -- Header
    table.insert(tooltip, TitanUtils_GetColoredText("Crosspaths Statistics", TITAN_PANEL_HIGHLIGHT_COLOR))
    table.insert(tooltip, " ")

    -- Basic stats
    local playerCount = Crosspaths:CountPlayers() or 0
    local encounterCount = Crosspaths:CountEncounters() or 0
    local guildCount = Crosspaths:CountGuilds() or 0

    table.insert(tooltip, TitanUtils_GetColoredText("Total Players:", TITAN_PANEL_TEXT_COLOR) ..
                 TitanUtils_GetColoredText(" " .. playerCount, TITAN_PANEL_HIGHLIGHT_COLOR))
    table.insert(tooltip, TitanUtils_GetColoredText("Total Encounters:", TITAN_PANEL_TEXT_COLOR) ..
                 TitanUtils_GetColoredText(" " .. encounterCount, TITAN_PANEL_HIGHLIGHT_COLOR))
    table.insert(tooltip, TitanUtils_GetColoredText("Guilds Tracked:", TITAN_PANEL_TEXT_COLOR) ..
                 TitanUtils_GetColoredText(" " .. guildCount, TITAN_PANEL_HIGHLIGHT_COLOR))

    -- Session stats
    if Crosspaths.Engine then
        local sessionStats = Crosspaths.Engine:GetSessionStats()
        if sessionStats then
            table.insert(tooltip, " ")
            table.insert(tooltip, TitanUtils_GetColoredText("Session Statistics:", TITAN_PANEL_HIGHLIGHT_COLOR))
            table.insert(tooltip, TitanUtils_GetColoredText("New Players:", TITAN_PANEL_TEXT_COLOR) ..
                         TitanUtils_GetColoredText(" " .. (sessionStats.newPlayersThisSession or 0), TITAN_PANEL_HIGHLIGHT_COLOR))
            table.insert(tooltip, TitanUtils_GetColoredText("Encounters:", TITAN_PANEL_TEXT_COLOR) ..
                         TitanUtils_GetColoredText(" " .. (sessionStats.encountersThisSession or 0), TITAN_PANEL_HIGHLIGHT_COLOR))

            if sessionStats.sessionDuration and sessionStats.sessionDuration > 0 then
                local duration = math.floor(sessionStats.sessionDuration / 60)
                table.insert(tooltip, TitanUtils_GetColoredText("Session Time:", TITAN_PANEL_TEXT_COLOR) ..
                             TitanUtils_GetColoredText(" " .. duration .. " minutes", TITAN_PANEL_HIGHLIGHT_COLOR))
            end
        end
    end

    -- Recent activity
    if Crosspaths.Engine then
        local recentActivity = Crosspaths.Engine:GetRecentActivity()
        if recentActivity and recentActivity.last24Hours then
            table.insert(tooltip, " ")
            table.insert(tooltip, TitanUtils_GetColoredText("Recent Activity (24h):", TITAN_PANEL_HIGHLIGHT_COLOR))
            table.insert(tooltip, TitanUtils_GetColoredText("Players:", TITAN_PANEL_TEXT_COLOR) ..
                         TitanUtils_GetColoredText(" " .. recentActivity.last24Hours.players, TITAN_PANEL_HIGHLIGHT_COLOR))
            table.insert(tooltip, TitanUtils_GetColoredText("Encounters:", TITAN_PANEL_TEXT_COLOR) ..
                         TitanUtils_GetColoredText(" " .. recentActivity.last24Hours.encounters, TITAN_PANEL_HIGHLIGHT_COLOR))
        end
    end

    -- Instructions
    table.insert(tooltip, " ")
    table.insert(tooltip, TitanUtils_GetColoredText("Left Click:", TITAN_PANEL_HIGHLIGHT_COLOR) ..
                 TitanUtils_GetColoredText(" Open Crosspaths", TITAN_PANEL_TEXT_COLOR))
    table.insert(tooltip, TitanUtils_GetColoredText("Right Click:", TITAN_PANEL_HIGHLIGHT_COLOR) ..
                 TitanUtils_GetColoredText(" Plugin Options", TITAN_PANEL_TEXT_COLOR))

    return table.concat(tooltip, "\n")
end

-- Handle left click on Titan Panel button
function TitanPanelCrosspathsButton_OnClick(self, button)
    if button == "LeftButton" then
        if Crosspaths.UI then
            Crosspaths.UI:Toggle()
        end
    else
        TitanPanelButton_OnClick(self, button)
    end
end

-- Right-click menu for Titan Panel
function TitanPanelRightClickMenu_PrepareCrosspathsMenu()
    local info = {}

    -- Show players option
    info.text = "Show Player Count"
    info.checked = TitanGetVar(TITAN_CROSSPATHS_ID, "ShowPlayers") == 1
    info.func = function()
        TitanToggleVar(TITAN_CROSSPATHS_ID, "ShowPlayers")
        TitanPanelButton_UpdateButton(TITAN_CROSSPATHS_ID)
    end
    UIDropDownMenu_AddButton(info)

    -- Show encounters option
    info.text = "Show Encounter Count"
    info.checked = TitanGetVar(TITAN_CROSSPATHS_ID, "ShowEncounters") == 1
    info.func = function()
        TitanToggleVar(TITAN_CROSSPATHS_ID, "ShowEncounters")
        TitanPanelButton_UpdateButton(TITAN_CROSSPATHS_ID)
    end
    UIDropDownMenu_AddButton(info)

    -- Show guilds option
    info.text = "Show Guild Count"
    info.checked = TitanGetVar(TITAN_CROSSPATHS_ID, "ShowGuilds") == 1
    info.func = function()
        TitanToggleVar(TITAN_CROSSPATHS_ID, "ShowGuilds")
        TitanPanelButton_UpdateButton(TITAN_CROSSPATHS_ID)
    end
    UIDropDownMenu_AddButton(info)

    -- Show session option
    info.text = "Show Session Stats"
    info.checked = TitanGetVar(TITAN_CROSSPATHS_ID, "ShowSession") == 1
    info.func = function()
        TitanToggleVar(TITAN_CROSSPATHS_ID, "ShowSession")
        TitanPanelButton_UpdateButton(TITAN_CROSSPATHS_ID)
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
    if not TitanPanelUtils then
        return
    end

    if self.updateTimer then
        self.updateTimer:Cancel()
    end

    self.updateTimer = C_Timer.NewTicker(TITAN_CROSSPATHS_FREQUENCY, function()
        TitanPanelButton_UpdateButton(TITAN_CROSSPATHS_ID)
    end)
end

-- Stop update timer
function TitanPanel:StopUpdateTimer()
    if self.updateTimer then
        self.updateTimer:Cancel()
        self.updateTimer = nil
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