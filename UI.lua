-- Crosspaths UI.lua
-- Main user interface, tabs, and notifications

local addonName, Crosspaths = ...

Crosspaths.UI = {}
local UI = Crosspaths.UI

-- Initialize UI
function UI:Initialize()
    self.mainFrame = nil
    self.toastFrames = {}
    self.currentTab = "summary"
    
    -- Create slash commands
    self:RegisterSlashCommands()
    
    -- Initialize tooltip system
    self:InitializeTooltips()
    
    Crosspaths:DebugLog("UI initialized", "INFO")
end

-- Register slash commands
function UI:RegisterSlashCommands()
    SLASH_CROSSPATHS1 = "/crosspaths"
    SLASH_CROSSPATHS2 = "/cp"
    
    SlashCmdList["CROSSPATHS"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    Crosspaths:DebugLog("Slash commands registered: /crosspaths, /cp", "INFO")
end

-- Handle slash commands
function UI:HandleSlashCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    
    local command = args[1] or "show"
    
    if command == "show" then
        self:Show()
    elseif command == "hide" then
        self:Hide()
    elseif command == "toggle" then
        self:Toggle()
    elseif command == "top" then
        self:ShowTopPlayers()
    elseif command == "stats" then
        self:ShowStats()
    elseif command == "search" then
        local query = table.concat(args, " ", 2)
        self:ShowSearchResults(query)
    elseif command == "export" then
        local format = args[2] or "json"
        self:ExportData(format)
    elseif command == "clear" then
        if args[2] == "confirm" then
            self:ClearData()
        else
            Crosspaths:Message("Use '/crosspaths clear confirm' to clear all data")
        end
    elseif command == "help" then
        self:ShowHelp()
    else
        self:ShowHelp()
    end
end

-- Show main UI
function UI:Show()
    if not self.mainFrame then
        self:CreateMainFrame()
    end
    
    self.mainFrame:Show()
    self:RefreshCurrentTab()
end

-- Hide main UI
function UI:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

-- Toggle main UI
function UI:Toggle()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Create main frame
function UI:CreateMainFrame()
    local frame = CreateFrame("Frame", "CrosspathsMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Crosspaths - Social Memory Tracker")
    
    -- Tab buttons
    self:CreateTabButtons(frame)
    
    -- Content area
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -60)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    
    self.mainFrame = frame
    
    -- Create tab content frames
    self:CreateTabContent()
end

-- Create tab buttons
function UI:CreateTabButtons(parent)
    local tabs = {
        {id = "summary", text = "Summary"},
        {id = "players", text = "Players"},
        {id = "guilds", text = "Guilds"},
        {id = "encounters", text = "Encounters"},
    }
    
    parent.tabs = {}
    
    for i, tab in ipairs(tabs) do
        local button = CreateFrame("Button", nil, parent, "CharacterFrameTabButtonTemplate")
        button:SetID(i)
        button:SetText(tab.text)
        button:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", (i-1) * 100 + 10, 30)
        
        button:SetScript("OnClick", function()
            self:SelectTab(tab.id)
        end)
        
        parent.tabs[tab.id] = button
    end
    
    -- Select first tab by default
    self:SelectTab("summary")
end

-- Select tab
function UI:SelectTab(tabId)
    if not self.mainFrame or not self.mainFrame.tabs then
        return
    end
    
    -- Update button states
    for id, button in pairs(self.mainFrame.tabs) do
        if id == tabId then
            button:SetChecked(true)
        else
            button:SetChecked(false)
        end
    end
    
    -- Show/hide content
    for id, content in pairs(self.tabContent or {}) do
        if id == tabId then
            content:Show()
        else
            content:Hide()
        end
    end
    
    self.currentTab = tabId
    self:RefreshCurrentTab()
end

-- Create tab content
function UI:CreateTabContent()
    self.tabContent = {}
    
    -- Summary tab
    self.tabContent.summary = self:CreateSummaryTab()
    
    -- Players tab
    self.tabContent.players = self:CreatePlayersTab()
    
    -- Guilds tab
    self.tabContent.guilds = self:CreateGuildsTab()
    
    -- Encounters tab
    self.tabContent.encounters = self:CreateEncountersTab()
end

-- Create summary tab
function UI:CreateSummaryTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()
    
    -- Stats display
    frame.statsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.statsText:SetPoint("TOPLEFT", 10, -10)
    frame.statsText:SetJustifyH("LEFT")
    frame.statsText:SetJustifyV("TOP")
    frame.statsText:SetText("Loading statistics...")
    
    return frame
end

-- Create players tab
function UI:CreatePlayersTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()
    
    -- Search box
    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(200, 20)
    searchBox:SetPoint("TOPLEFT", 10, -10)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnEnterPressed", function(self)
        UI:ShowSearchResults(self:GetText())
        self:ClearFocus()
    end)
    
    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
    searchLabel:SetText("Search players...")
    
    -- Results area
    frame.resultsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.resultsText:SetPoint("TOPLEFT", 10, -40)
    frame.resultsText:SetJustifyH("LEFT")
    frame.resultsText:SetJustifyV("TOP")
    frame.resultsText:SetText("Top players will appear here...")
    
    frame.searchBox = searchBox
    
    return frame
end

-- Create guilds tab
function UI:CreateGuildsTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()
    
    frame.guildsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.guildsText:SetPoint("TOPLEFT", 10, -10)
    frame.guildsText:SetJustifyH("LEFT")
    frame.guildsText:SetJustifyV("TOP")
    frame.guildsText:SetText("Guild statistics will appear here...")
    
    return frame
end

-- Create encounters tab
function UI:CreateEncountersTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()
    
    frame.encountersText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.encountersText:SetPoint("TOPLEFT", 10, -10)
    frame.encountersText:SetJustifyH("LEFT")
    frame.encountersText:SetJustifyV("TOP")
    frame.encountersText:SetText("Recent encounters will appear here...")
    
    return frame
end

-- Refresh current tab
function UI:RefreshCurrentTab()
    if not Crosspaths.Engine then
        return
    end
    
    if self.currentTab == "summary" then
        self:RefreshSummaryTab()
    elseif self.currentTab == "players" then
        self:RefreshPlayersTab()
    elseif self.currentTab == "guilds" then
        self:RefreshGuildsTab()
    elseif self.currentTab == "encounters" then
        self:RefreshEncountersTab()
    end
end

-- Refresh summary tab
function UI:RefreshSummaryTab()
    if not self.tabContent.summary then
        return
    end
    
    local stats = Crosspaths.Engine:GetStatsSummary()
    local lines = {}
    
    table.insert(lines, "|cFFFFD700Crosspaths Statistics|r")
    table.insert(lines, "")
    table.insert(lines, string.format("Total Players: |cFF00FF00%d|r", stats.totalPlayers))
    table.insert(lines, string.format("Total Encounters: |cFF00FF00%d|r", stats.totalEncounters))
    table.insert(lines, string.format("Grouped Players: |cFF00FF00%d|r", stats.groupedPlayers))
    table.insert(lines, string.format("Guilds Encountered: |cFF00FF00%d|r", stats.totalGuilds))
    
    if stats.totalPlayers > 0 then
        table.insert(lines, string.format("Average Encounters per Player: |cFF00FF00%.1f|r", stats.averageEncounters))
    end
    
    if stats.oldestEncounter then
        table.insert(lines, "")
        table.insert(lines, string.format("Oldest Encounter: |cFFFFFFFF%s|r", date("%Y-%m-%d %H:%M", stats.oldestEncounter)))
        table.insert(lines, string.format("Newest Encounter: |cFFFFFFFF%s|r", date("%Y-%m-%d %H:%M", stats.newestEncounter)))
    end
    
    -- Top players
    table.insert(lines, "")
    table.insert(lines, "|cFFFFD700Top Players:|r")
    local topPlayers = Crosspaths.Engine:GetTopPlayers(5)
    for i, player in ipairs(topPlayers) do
        table.insert(lines, string.format("%d. %s (%d encounters)", i, player.name, player.count))
    end
    
    self.tabContent.summary.statsText:SetText(table.concat(lines, "\n"))
end

-- Refresh players tab
function UI:RefreshPlayersTab()
    if not self.tabContent.players then
        return
    end
    
    local topPlayers = Crosspaths.Engine:GetTopPlayers(20)
    local lines = {}
    
    table.insert(lines, "|cFFFFD700Top Players (by encounters):|r")
    table.insert(lines, "")
    
    for i, player in ipairs(topPlayers) do
        local groupedText = player.grouped and " |cFF00FF00(Grouped)|r" or ""
        local guildText = player.guild and player.guild ~= "" and (" |cFFFFFFFF<" .. player.guild .. ">|r") or ""
        table.insert(lines, string.format("%d. %s%s%s - %d encounters", i, player.name, groupedText, guildText, player.count))
    end
    
    if #topPlayers == 0 then
        table.insert(lines, "No players tracked yet. Start exploring to meet some people!")
    end
    
    self.tabContent.players.resultsText:SetText(table.concat(lines, "\n"))
end

-- Refresh guilds tab
function UI:RefreshGuildsTab()
    if not self.tabContent.guilds then
        return
    end
    
    local topGuilds = Crosspaths.Engine:GetTopGuilds(20)
    local lines = {}
    
    table.insert(lines, "|cFFFFD700Top Guilds (by members encountered):|r")
    table.insert(lines, "")
    
    for i, guild in ipairs(topGuilds) do
        table.insert(lines, string.format("%d. %s - %d members", i, guild.name, guild.memberCount))
    end
    
    if #topGuilds == 0 then
        table.insert(lines, "No guilds tracked yet.")
    end
    
    self.tabContent.guilds.guildsText:SetText(table.concat(lines, "\n"))
end

-- Refresh encounters tab
function UI:RefreshEncountersTab()
    if not self.tabContent.encounters then
        return
    end
    
    local zones = Crosspaths.Engine:GetTopZones(10)
    local lines = {}
    
    table.insert(lines, "|cFFFFD700Top Zones (by encounters):|r")
    table.insert(lines, "")
    
    for i, zone in ipairs(zones) do
        table.insert(lines, string.format("%d. %s - %d encounters", i, zone.name, zone.encounterCount))
    end
    
    if #zones == 0 then
        table.insert(lines, "No zone data yet.")
    end
    
    self.tabContent.encounters.encountersText:SetText(table.concat(lines, "\n"))
end

-- Show toast notification
function UI:ShowToast(title, message)
    if not Crosspaths.db or not Crosspaths.db.settings.ui.showNotifications then
        return
    end
    
    -- Simple toast implementation
    local toast = CreateFrame("Frame", nil, UIParent)
    toast:SetSize(300, 60)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -100)
    toast:SetFrameStrata("HIGH")
    
    -- Background
    toast.bg = toast:CreateTexture(nil, "BACKGROUND")
    toast.bg:SetAllPoints()
    toast.bg:SetColorTexture(0, 0, 0, 0.8)
    
    -- Title
    toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toast.title:SetPoint("TOP", toast, "TOP", 0, -5)
    toast.title:SetText(title)
    toast.title:SetTextColor(1, 1, 0)
    
    -- Message
    toast.message = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toast.message:SetPoint("TOP", toast.title, "BOTTOM", 0, -5)
    toast.message:SetText(message)
    toast.message:SetTextColor(1, 1, 1)
    
    -- Auto-hide
    local duration = Crosspaths.db.settings.ui.notificationDuration or 3
    C_Timer.After(duration, function()
        if toast then
            toast:Hide()
        end
    end)
    
    table.insert(self.toastFrames, toast)
end

-- Quick command implementations
function UI:ShowTopPlayers()
    local topPlayers = Crosspaths.Engine:GetTopPlayers(10)
    Crosspaths:Message("Top Players:")
    for i, player in ipairs(topPlayers) do
        Crosspaths:Message(string.format("%d. %s - %d encounters", i, player.name, player.count))
    end
end

-- Search players and update the players tab
function UI:SearchPlayers(query)
    if not query or query == "" then
        -- If empty query, show top players
        self:RefreshPlayersTab()
        return
    end
    
    if not self.tabContent.players then
        return
    end
    
    local results = Crosspaths.Engine:SearchPlayers(query, 20)
    local lines = {}
    
    table.insert(lines, "|cFFFFD700Search results for '" .. query .. "':|r")
    table.insert(lines, "")
    
    if #results == 0 then
        table.insert(lines, "No players found matching your search.")
    else
        for i, player in ipairs(results) do
            local groupedText = player.grouped and " |cFF00FF00(Grouped)|r" or ""
            local guildText = player.guild and player.guild ~= "" and (" |cFFFFFFFF<" .. player.guild .. ">|r") or ""
            table.insert(lines, string.format("%d. %s%s%s - %d encounters", i, player.name, groupedText, guildText, player.count))
        end
    end
    
    self.tabContent.players.resultsText:SetText(table.concat(lines, "\n"))
end

function UI:ShowStats()
    local stats = Crosspaths.Engine:GetStatsSummary()
    Crosspaths:Message(string.format("Stats: %d players, %d encounters, %d guilds",
        stats.totalPlayers, stats.totalEncounters, stats.totalGuilds))
end

function UI:ShowSearchResults(query)
    if not query or query == "" then
        Crosspaths:Message("Usage: /crosspaths search <name>")
        return
    end
    
    local results = Crosspaths.Engine:SearchPlayers(query, 10)
    if #results == 0 then
        Crosspaths:Message("No players found matching '" .. query .. "'")
    else
        Crosspaths:Message("Search results for '" .. query .. "':")
        for i, player in ipairs(results) do
            Crosspaths:Message(string.format("%d. %s - %d encounters", i, player.name, player.count))
        end
    end
end

function UI:ExportData(format)
    local data = Crosspaths.Engine:ExportData(format)
    Crosspaths:Message("Data exported (" .. format .. ") - " .. string.len(data) .. " characters")
    Crosspaths:Print("Export preview: " .. string.sub(data, 1, 200) .. "...")
end

function UI:ClearData()
    if Crosspaths.db then
        Crosspaths.db.players = {}
        Crosspaths:Message("All player data cleared!")
    end
end

function UI:ShowHelp()
    local help = {
        "Crosspaths Commands:",
        "/crosspaths show - Show main UI",
        "/crosspaths top - Show top players",
        "/crosspaths stats - Show summary stats",
        "/crosspaths search <name> - Search for player",
        "/crosspaths export [json|csv] - Export data",
        "/crosspaths clear confirm - Clear all data",
    }
    
    for _, line in ipairs(help) do
        Crosspaths:Message(line)
    end
end

-- Initialize tooltip functionality
function UI:InitializeTooltips()
    -- Create custom tooltip frame for showing player encounter history
    if not self.tooltip then
        self.tooltip = CreateFrame("GameTooltip", "CrosspathsTooltip", UIParent, "GameTooltipTemplate")
        self.tooltip:SetFrameStrata("TOOLTIP")
    end
    
    -- Hook into the game's tooltip system to show encounter info
    self:HookGameTooltips()
end

-- Hook into game tooltips to show encounter data
function UI:HookGameTooltips()
    -- Hook GameTooltip for unit tooltips (nameplates, target frames, etc.)
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        self:AddEncounterInfoToTooltip(tooltip)
    end)
end

-- Add encounter information to game tooltips
function UI:AddEncounterInfoToTooltip(tooltip)
    if not Crosspaths.db or not Crosspaths.db.settings.enabled then
        return
    end
    
    local unit = select(2, tooltip:GetUnit())
    if not unit or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then
        return
    end
    
    local name, realm = UnitNameUnmodified(unit)
    if not name or name == "" then
        return
    end
    
    local fullName = realm and realm ~= "" and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
    local playerData = Crosspaths.db.players[fullName]
    
    if playerData and playerData.encounters and #playerData.encounters > 0 then
        local encounterCount = #playerData.encounters
        local lastEncounter = playerData.encounters[encounterCount]
        
        -- Add a separator line
        tooltip:AddLine(" ")
        
        -- Add Crosspaths header
        tooltip:AddLine("|cFF7B68EECrosspaths|r", 0.4, 0.4, 1)
        
        -- Add encounter count
        tooltip:AddDoubleLine("Encounters:", tostring(encounterCount), 0.8, 0.8, 0.8, 1, 1, 1)
        
        -- Add last seen info
        if lastEncounter then
            local timeAgo = self:FormatTimeAgo(lastEncounter.timestamp)
            tooltip:AddDoubleLine("Last seen:", timeAgo, 0.8, 0.8, 0.8, 1, 1, 1)
            
            if lastEncounter.zone then
                tooltip:AddDoubleLine("Zone:", lastEncounter.zone, 0.8, 0.8, 0.8, 0.6, 0.8, 0.6)
            end
            
            if lastEncounter.context and lastEncounter.context ~= "nameplate" then
                local contextText = lastEncounter.context
                if contextText == "party" then
                    contextText = "Group"
                elseif contextText == "raid" then
                    contextText = "Raid"
                elseif contextText == "instance" then
                    contextText = "Instance"
                elseif contextText == "world" then
                    contextText = "World"
                end
                tooltip:AddDoubleLine("Context:", contextText, 0.8, 0.8, 0.8, 0.6, 0.8, 1)
            end
        end
        
        -- Add guild info if available
        if playerData.guild then
            tooltip:AddDoubleLine("Guild:", playerData.guild, 0.8, 0.8, 0.8, 1, 0.8, 0)
        end
        
        -- Add notes if available (truncated for tooltip)
        if playerData.notes and playerData.notes ~= "" then
            local notes = playerData.notes
            if string.len(notes) > 40 then
                notes = string.sub(notes, 1, 37) .. "..."
            end
            tooltip:AddDoubleLine("Notes:", notes, 0.8, 0.8, 0.8, 1, 1, 0.8)
        end
        
        tooltip:Show()
    end
end

-- Show player encounter tooltip
function UI:ShowPlayerTooltip(playerName, anchor)
    if not self.tooltip or not Crosspaths.db then
        return
    end
    
    local playerData = Crosspaths.db.players[playerName]
    if not playerData then
        return
    end
    
    self.tooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    self.tooltip:ClearLines()
    
    -- Player name header
    self.tooltip:AddLine(playerName, 1, 1, 1)
    
    -- Basic encounter info
    local encounterCount = #(playerData.encounters or {})
    if encounterCount > 0 then
        self.tooltip:AddLine("Encounters: " .. encounterCount, 0.7, 0.7, 1)
        
        -- Show last encounter info
        local lastEncounter = playerData.encounters[encounterCount]
        if lastEncounter then
            local timeAgo = self:FormatTimeAgo(lastEncounter.timestamp)
            self.tooltip:AddLine("Last seen: " .. timeAgo, 0.8, 0.8, 0.8)
            
            if lastEncounter.zone then
                self.tooltip:AddLine("Zone: " .. lastEncounter.zone, 0.6, 0.8, 0.6)
            end
            
            if lastEncounter.context then
                self.tooltip:AddLine("Context: " .. lastEncounter.context, 0.6, 0.8, 1)
            end
        end
        
        -- Show guild if available
        if playerData.guild then
            self.tooltip:AddLine("Guild: " .. playerData.guild, 1, 0.8, 0)
        end
        
        -- Show notes if available  
        if playerData.notes and playerData.notes ~= "" then
            self.tooltip:AddLine(" ", 1, 1, 1)  -- Blank line
            self.tooltip:AddLine("Notes:", 0.8, 0.8, 1)
            self.tooltip:AddLine(playerData.notes, 1, 1, 0.8, true)  -- Wrap text
        end
    else
        self.tooltip:AddLine("No encounter data", 0.5, 0.5, 0.5)
    end
    
    self.tooltip:Show()
end

-- Hide player tooltip
function UI:HidePlayerTooltip()
    if self.tooltip then
        self.tooltip:Hide()
    end
end

-- Format time ago helper
function UI:FormatTimeAgo(timestamp)
    if not timestamp then
        return "Unknown"
    end
    
    local now = time()
    local diff = now - timestamp
    
    if diff < 60 then
        return "Just now"
    elseif diff < 3600 then
        local minutes = math.floor(diff / 60)
        return minutes .. " minute" .. (minutes ~= 1 and "s" or "") .. " ago"
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return hours .. " hour" .. (hours ~= 1 and "s" or "") .. " ago"
    else
        local days = math.floor(diff / 86400)
        return days .. " day" .. (days ~= 1 and "s" or "") .. " ago"
    end
end