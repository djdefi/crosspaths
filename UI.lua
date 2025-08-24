-- Crosspaths UI.lua
-- Main user interface, tabs, and notifications

local addonName, Crosspaths = ...

Crosspaths.UI = {}
local UI = Crosspaths.UI

-- UI Constants for consistency and responsiveness
local UI_CONSTANTS = {
    -- Window sizes (min, default, max)
    MAIN_WINDOW = {
        MIN_WIDTH = 500,
        MIN_HEIGHT = 350,
        DEFAULT_WIDTH = 650,
        DEFAULT_HEIGHT = 450,
        MAX_WIDTH = 1200,
        MAX_HEIGHT = 800
    },
    CONFIG_WINDOW = {
        MIN_WIDTH = 400,
        MIN_HEIGHT = 500,
        DEFAULT_WIDTH = 520,
        DEFAULT_HEIGHT = 650,
        MAX_WIDTH = 800,
        MAX_HEIGHT = 900
    },
    EXPORT_WINDOW = {
        MIN_WIDTH = 500,
        MIN_HEIGHT = 350,
        DEFAULT_WIDTH = 650,
        DEFAULT_HEIGHT = 450,
        MAX_WIDTH = 1000,
        MAX_HEIGHT = 700
    },
    DIGEST_WINDOW = {
        MIN_WIDTH = 450,
        MIN_HEIGHT = 550,
        DEFAULT_WIDTH = 550,
        DEFAULT_HEIGHT = 650,
        MAX_WIDTH = 800,
        MAX_HEIGHT = 900
    },

    -- Colors for consistent UI theming
    COLORS = {
        -- Tab button colors
        TAB_NORMAL = {0.25, 0.25, 0.25, 0.9},
        TAB_HOVER = {0.4, 0.4, 0.4, 0.9},
        TAB_PRESSED = {0.15, 0.15, 0.15, 0.9},
        TAB_SELECTED = {0.2, 0.4, 0.8, 0.95},
        TAB_BORDER = {0.6, 0.6, 0.6, 0.8},
        TAB_BORDER_SELECTED = {0.8, 0.8, 0.8, 1.0},

        -- Toast notification colors
        TOAST_BG = {0, 0, 0, 0.8},
        TOAST_TITLE = {1, 1, 0, 1},
        TOAST_TEXT = {1, 1, 1, 1}
    },

    -- Spacing and layout
    SPACING = {
        WINDOW_MARGIN = 10,
        TAB_HEIGHT = 28,
        TAB_WIDTH = 95,
        TAB_SPACING = 105,
        BUTTON_HEIGHT = 25,
        SCROLL_BAR_WIDTH = 30,
        SEARCH_BOX_WIDTH = 200,
        SEARCH_BOX_HEIGHT = 24,
        INPUT_BOX_HEIGHT = 20,
        -- Content layout spacing
        CONTENT_MARGIN = 10,
        CONTENT_INDENT = 20,
        SECTION_SPACING = 20,
        LIST_ITEM_SPACING = 15,
        HEADER_SPACING = 25,
        SUBSECTION_SPACING = 10
    }
}

-- Helper function to get responsive window size based on screen dimensions
local function GetResponsiveSize(windowType)
    local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
    local screenHeight = GetScreenHeight() * UIParent:GetEffectiveScale()

    local constants = UI_CONSTANTS[windowType] or UI_CONSTANTS.MAIN_WINDOW

    -- Calculate responsive size (70% of screen, but within min/max bounds)
    local width = math.max(constants.MIN_WIDTH,
                  math.min(constants.MAX_WIDTH, screenWidth * 0.7))
    local height = math.max(constants.MIN_HEIGHT,
                   math.min(constants.MAX_HEIGHT, screenHeight * 0.7))

    return width, height
end

-- Helper function to create a standard resizable frame with common properties
local function CreateStandardFrame(name, parent, windowType, frameStrata)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BasicFrameTemplateWithInset")

    -- Use responsive sizing
    local width, height = GetResponsiveSize(windowType)
    frame:SetSize(width, height)

    -- Set minimum and maximum size constraints (if supported by frame type)
    local constants = UI_CONSTANTS[windowType] or UI_CONSTANTS.MAIN_WINDOW
    if frame.SetMinResize and type(frame.SetMinResize) == "function" then
        pcall(frame.SetMinResize, frame, constants.MIN_WIDTH, constants.MIN_HEIGHT)
    end
    if frame.SetMaxResize and type(frame.SetMaxResize) == "function" then
        pcall(frame.SetMaxResize, frame, constants.MAX_WIDTH, constants.MAX_HEIGHT)
    end

    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    if frameStrata then
        frame:SetFrameStrata(frameStrata)
    end

    -- Store window type for resize handling
    frame.windowType = windowType

    return frame
end

-- Helper function to create a standard close button
local function CreateStandardCloseButton(parent, onClickCallback)
    local closeBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    closeBtn:SetSize(80, UI_CONSTANTS.SPACING.BUTTON_HEIGHT)
    closeBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT",
                     -UI_CONSTANTS.SPACING.WINDOW_MARGIN, UI_CONSTANTS.SPACING.WINDOW_MARGIN)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", onClickCallback or function() parent:Hide() end)
    return closeBtn
end

-- Helper function to update text width dynamically
local function UpdateTextWidth(textElement, parentFrame, margins)
    if textElement and parentFrame then
        margins = margins or 0
        local newWidth = math.max(100, parentFrame:GetWidth() - margins)
        textElement:SetWidth(newWidth)
    end
end

-- Helper function to update content frame and child text widths
local function UpdateContentFrameWidths(contentFrame, scrollFrame, textElements)
    if not contentFrame or not scrollFrame then
        return
    end
    
    local newWidth = math.max(100, scrollFrame:GetWidth() - 20)
    contentFrame:SetWidth(newWidth)
    
    if textElements then
        for _, textElement in ipairs(textElements) do
            if textElement then
                textElement:SetWidth(newWidth)
            end
        end
    end
end

-- Helper function to update tab button spacing when window resizes
local function UpdateTabButtonSpacing(parentFrame, tabButtons)
    if not parentFrame or not tabButtons then
        return
    end
    
    local windowWidth = parentFrame:GetWidth()
    local availableWidth = windowWidth - (2 * UI_CONSTANTS.SPACING.WINDOW_MARGIN)
    local totalTabs = 5 -- Summary, Players, Guilds, Advanced, Encounters
    
    local tabSpacing
    -- Use default spacing if it fits, otherwise calculate needed spacing
    if totalTabs * UI_CONSTANTS.SPACING.TAB_SPACING <= availableWidth then
        tabSpacing = UI_CONSTANTS.SPACING.TAB_SPACING
    else
        -- Calculate spacing to fit all tabs, with minimum spacing being tab width
        tabSpacing = math.max(UI_CONSTANTS.SPACING.TAB_WIDTH * 0.8, availableWidth / totalTabs)
    end
    
    -- Update tab positions
    local index = 1
    for _, button in pairs(tabButtons) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT",
                       (index-1) * tabSpacing + UI_CONSTANTS.SPACING.WINDOW_MARGIN, 32)
        index = index + 1
    end
end

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
        if args[2] then
            self:ShowAdvancedStats(args[2])
        else
            self:ShowStats()
        end
    elseif command == "search" then
        local query = table.concat(args, " ", 2)
        self:ShowSearchResults(query)
    elseif command == "export" then
        local format = args[2] or "json"
        self:ExportData(format)
    elseif command == "remove" then
        local playerName = table.concat(args, " ", 2)
        if playerName and playerName ~= "" then
            self:RemovePlayer(playerName)
        else
            Crosspaths:Message("Usage: /crosspaths remove <player-name>")
        end
    elseif command == "clear" then
        if args[2] == "confirm" then
            self:ClearData()
        else
            Crosspaths:Message("Use '/crosspaths clear confirm' to clear all data")
        end
    elseif command == "cleanup" then
        if args[2] == "confirm" then
            Crosspaths:CleanupSelfEncounters()
        elseif args[2] == "data" and args[3] == "confirm" then
            local stats = Crosspaths.Engine:ValidateAndCleanData()
            Crosspaths:Message(string.format("Data cleanup completed: %d duplicates, %d invalid encounters, %d invalid levels, %d normalized names removed",
                stats.duplicatesRemoved, stats.invalidEncounters, stats.invalidLevels, stats.normalizedNames))
        elseif args[2] == "duplicates" then
            local duplicates = Crosspaths.Engine:DetectDuplicatePlayers()
            if #duplicates > 0 then
                Crosspaths:Message(string.format("Found %d potential duplicate groups:", #duplicates))
                for i, dup in ipairs(duplicates) do
                    if i <= 5 then -- Show top 5
                        Crosspaths:Message(string.format("  %s: %d players (confidence: %d%%)",
                            dup.baseName, #dup.players, math.floor(dup.confidence)))
                    end
                end
                if #duplicates > 5 then
                    Crosspaths:Message(string.format("  ... and %d more", #duplicates - 5))
                end
            else
                Crosspaths:Message("No potential duplicates detected")
            end
        else
            Crosspaths:Message("Usage:")
            Crosspaths:Message("  /crosspaths cleanup confirm - Remove self-encounter data")
            Crosspaths:Message("  /crosspaths cleanup data confirm - Clean invalid data and duplicates")
            Crosspaths:Message("  /crosspaths cleanup duplicates - Detect potential duplicate players")
        end
    elseif command == "debug" then
        if args[2] == "on" then
            Crosspaths.debug = true
            if Crosspaths.db then
                Crosspaths.db.settings.debug = true
            end
            if Crosspaths.Logging then
                Crosspaths.Logging.logLevel = 4 -- DEBUG level
            end
            Crosspaths:Message("Debug mode enabled")
        elseif args[2] == "off" then
            Crosspaths.debug = false
            if Crosspaths.db then
                Crosspaths.db.settings.debug = false
            end
            if Crosspaths.Logging then
                Crosspaths.Logging.logLevel = 3 -- INFO level
            end
            Crosspaths:Message("Debug mode disabled")
        else
            self:ShowDebugStatus()
        end
    elseif command == "analytics" or command == "analysis" then
        local analysisType = args[2] or "activity"
        if analysisType == "activity" then
            local patterns = Crosspaths.Engine:AnalyzeActivityPatterns()
            self:ShowActivityAnalysis(patterns)
        elseif analysisType == "social" then
            local networks = Crosspaths.Engine:AnalyzeSocialNetworks()
            self:ShowSocialAnalysis(networks)
        elseif analysisType == "progression" then
            local progression = Crosspaths.Engine:AnalyzeProgressionTrends()
            self:ShowProgressionAnalysis(progression)
        elseif analysisType == "questlines" or analysisType == "paths" then
            local patterns = Crosspaths.Engine:GetZoneProgressionPatterns()
            self:ShowQuestLineAnalysis(patterns)
        elseif analysisType == "similar" then
            local playerName = args[3]
            if not playerName then
                Crosspaths:Message("Usage: /crosspaths analytics similar <playername>")
                return
            end
            local similar = Crosspaths.Engine:DetectSimilarQuestLines(playerName)
            self:ShowSimilarQuestLines(playerName, similar)
        elseif analysisType == "zone" then
            local zoneName = args[3]
            if not zoneName then
                Crosspaths:Message("Usage: /crosspaths analytics zone <zonename>")
                return
            end
            local insights = Crosspaths.Engine:GetQuestLineInsights(zoneName)
            self:ShowZoneInsights(zoneName, insights)
        else
            Crosspaths:Message("Usage: /crosspaths analytics [activity|social|progression|questlines|similar <player>|zone <zone>]")
        end
    elseif command == "status" then
        self:ShowStatus()
    elseif command == "digest" then
        local digestType = args[2] or "daily"
        if digestType == "daily" then
            local digest = Crosspaths.Engine:GenerateDailyDigest()
            self:ShowDigestReport("Daily Digest", digest)
        elseif digestType == "weekly" then
            local digest = Crosspaths.Engine:GenerateWeeklyDigest()
            self:ShowDigestReport("Weekly Digest", digest)
        elseif digestType == "monthly" then
            local digest = Crosspaths.Engine:GenerateMonthlyDigest()
            self:ShowDigestReport("Monthly Digest", digest)
        else
            Crosspaths:Message("Usage: /crosspaths digest [daily|weekly|monthly]")
        end
    elseif command == "minimap" then
        if Crosspaths.MinimapButton then
            Crosspaths.MinimapButton:Toggle()
        else
            Crosspaths:Message("Minimap button not available")
        end
    elseif command == "titanpanel" or command == "titan" then
        self:ShowTitanPanelStatus()
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
    local frame = CreateStandardFrame("CrosspathsMainFrame", UIParent, "MAIN_WINDOW")

    -- Title with version
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Crosspaths - Social Memory Tracker v" .. (Crosspaths.version or "Unknown"))

    -- Settings button in title bar
    frame.settingsBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    frame.settingsBtn:SetSize(70, 20)
    frame.settingsBtn:SetPoint("RIGHT", frame.TitleBg, "RIGHT", -5, 0)
    frame.settingsBtn:SetText("Settings")
    frame.settingsBtn:SetScript("OnClick", function()
        if Crosspaths.Config then
            Crosspaths.Config:Show()
        else
            Crosspaths:Message("Configuration system not available")
        end
    end)
    frame.settingsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Open Crosspaths configuration panel", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.settingsBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Tab buttons
    self:CreateTabButtons(frame)

    -- Content area with responsive margins
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -60)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI_CONSTANTS.SPACING.WINDOW_MARGIN, UI_CONSTANTS.SPACING.WINDOW_MARGIN)

    -- Add resize event handling to update tab buttons and content
    frame:SetScript("OnSizeChanged", function(self, width, height)
        -- Update tab button spacing
        UpdateTabButtonSpacing(self, self.tabs)
        
        -- Update content in current tab if available
        UI:UpdateCurrentTabContentWidths()
    end)

    self.mainFrame = frame

    -- Create tab content frames
    self:CreateTabContent()
end

-- Create tab buttons
function UI:CreateTabButtons(parent)
    local tabs = {
        {id = "summary", text = "Summary", tooltip = "View overall statistics and summary"},
        {id = "players", text = "Players", tooltip = "Browse and search tracked players"},
        {id = "guilds", text = "Guilds", tooltip = "View guild statistics and members"},
        {id = "advanced", text = "Advanced", tooltip = "View advanced role-based and performance statistics"},
        {id = "encounters", text = "Encounters", tooltip = "Browse encounter history by zone"},
    }

    parent.tabs = {}

    for i, tab in ipairs(tabs) do
        local button = self:CreateTabButton(parent, i, tab)
        parent.tabs[tab.id] = button
    end

    -- Select first tab by default
    self:SelectTab("summary")
end

-- Create individual tab button with modern styling
function UI:CreateTabButton(parent, index, tabData)
    -- Use UIPanelButtonTemplate as a more stable base than manual creation
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetID(index)
    button:SetSize(UI_CONSTANTS.SPACING.TAB_WIDTH, UI_CONSTANTS.SPACING.TAB_HEIGHT)
    button:SetText(tabData.text)

    -- Calculate initial tab spacing - will be updated on resize
    local windowWidth = parent:GetWidth() or UI_CONSTANTS.MAIN_WINDOW.DEFAULT_WIDTH
    local availableWidth = windowWidth - (2 * UI_CONSTANTS.SPACING.WINDOW_MARGIN)
    local totalTabs = 5 -- Summary, Players, Guilds, Advanced, Encounters

    local tabSpacing
    -- Use default spacing if it fits, otherwise calculate needed spacing
    if totalTabs * UI_CONSTANTS.SPACING.TAB_SPACING <= availableWidth then
        tabSpacing = UI_CONSTANTS.SPACING.TAB_SPACING
    else
        -- Calculate spacing to fit all tabs, with minimum spacing being tab width
        tabSpacing = math.max(UI_CONSTANTS.SPACING.TAB_WIDTH * 0.8, availableWidth / totalTabs)
    end

    button:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", (index-1) * tabSpacing + UI_CONSTANTS.SPACING.WINDOW_MARGIN, 32)

    -- Apply modern tab styling
    self:StyleTabButton(button)

    -- Add tooltip for accessibility
    if tabData.tooltip then
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tabData.tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    -- Tab selection behavior
    button:SetScript("OnClick", function()
        UI:SelectTab(tabData.id)
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    end)

    -- Store tab data
    button.tabId = tabData.id
    button.isChecked = false

    return button
end

-- Apply modern styling to tab buttons
function UI:StyleTabButton(button)
    -- Use WoW's standard font objects
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightFontObject("GameFontHighlight")
    button:SetDisabledFontObject("GameFontDisable")

    -- Use consistent color scheme from constants
    local normalColor = UI_CONSTANTS.COLORS.TAB_NORMAL
    local hoverColor = UI_CONSTANTS.COLORS.TAB_HOVER
    local pressedColor = UI_CONSTANTS.COLORS.TAB_PRESSED
    local selectedColor = UI_CONSTANTS.COLORS.TAB_SELECTED

    -- Create background textures with modern styling
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetColorTexture(unpack(normalColor))
    button:SetNormalTexture(normalTexture)

    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints()
    highlightTexture:SetColorTexture(unpack(hoverColor))
    button:SetHighlightTexture(highlightTexture)

    local pushedTexture = button:CreateTexture(nil, "ARTWORK")
    pushedTexture:SetAllPoints()
    pushedTexture:SetColorTexture(unpack(pressedColor))
    button:SetPushedTexture(pushedTexture)

    -- Add border for modern look
    local border = button:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(unpack(UI_CONSTANTS.COLORS.TAB_BORDER))
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)

    -- Selected state texture
    local checkedTexture = button:CreateTexture(nil, "ARTWORK")
    checkedTexture:SetAllPoints()
    checkedTexture:SetColorTexture(unpack(selectedColor))
    checkedTexture:Hide()

    -- Store textures and colors for state management
    button.normalTexture = normalTexture
    button.checkedTexture = checkedTexture
    button.borderTexture = border
    button.selectedColor = selectedColor
    button.normalColor = normalColor

    -- Modern checked state implementation
    function button:SetChecked(checked)
        self.isChecked = checked
        if checked then
            self.checkedTexture:Show()
            -- Brighten border when selected
            self.borderTexture:SetColorTexture(unpack(UI_CONSTANTS.COLORS.TAB_BORDER_SELECTED))
        else
            self.checkedTexture:Hide()
            -- Normal border when not selected
            self.borderTexture:SetColorTexture(unpack(UI_CONSTANTS.COLORS.TAB_BORDER))
        end
    end

    function button:GetChecked()
        return self.isChecked
    end
end

-- Select tab with improved error handling and validation
function UI:SelectTab(tabId)
    if not self.mainFrame or not self.mainFrame.tabs then
        Crosspaths:DebugLog("Cannot select tab: mainFrame or tabs not initialized", "WARNING")
        return
    end

    -- Validate tabId exists
    if not self.mainFrame.tabs[tabId] then
        Crosspaths:DebugLog("Invalid tab ID: " .. tostring(tabId), "WARNING")
        return
    end

    -- Update button states with animation feedback
    for id, button in pairs(self.mainFrame.tabs) do
        if button and button.SetChecked then
            if id == tabId then
                button:SetChecked(true)
            else
                button:SetChecked(false)
            end
        end
    end

    -- Show/hide content with fade effect (if content exists)
    for id, content in pairs(self.tabContent or {}) do
        if content then
            if id == tabId then
                content:Show()
                -- Smooth fade-in effect
                content:SetAlpha(0)
                UIFrameFadeIn(content, 0.15, 0, 1)
            else
                content:Hide()
            end
        end
    end

    local previousTab = self.currentTab
    self.currentTab = tabId

    -- Log tab change for debugging
    if previousTab ~= tabId then
        Crosspaths:DebugLog("Tab changed from " .. tostring(previousTab) .. " to " .. tostring(tabId), "INFO")
    end

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

    -- Advanced stats tab
    self.tabContent.advanced = self:CreateAdvancedTab()

    -- Encounters tab
    self.tabContent.encounters = self:CreateEncountersTab()

    -- Hide all tabs initially except the current one
    for id, content in pairs(self.tabContent) do
        if id ~= self.currentTab then
            content:Hide()
        end
    end
end

-- Update content widths for current tab when window is resized
function UI:UpdateCurrentTabContentWidths()
    if not self.tabContent then
        return
    end
    
    local currentTab = self.tabContent[self.currentTab]
    if not currentTab then
        return
    end
    
    -- Update different tab types based on their structure
    if self.currentTab == "summary" and currentTab.scroll and currentTab.content and currentTab.statsText then
        UpdateContentFrameWidths(currentTab.content, currentTab.scroll, {currentTab.statsText})
    elseif self.currentTab == "players" and currentTab.scroll and currentTab.content and currentTab.resultsText then
        UpdateContentFrameWidths(currentTab.content, currentTab.scroll, {currentTab.resultsText})
    elseif self.currentTab == "guilds" and currentTab.scroll and currentTab.content and currentTab.guildsText then
        UpdateContentFrameWidths(currentTab.content, currentTab.scroll, {currentTab.guildsText})
    elseif self.currentTab == "encounters" and currentTab.scroll and currentTab.content and currentTab.encountersText then
        UpdateContentFrameWidths(currentTab.content, currentTab.scroll, {currentTab.encountersText})
    elseif self.currentTab == "advanced" and currentTab.scroll and currentTab.content and currentTab.advancedText then
        UpdateContentFrameWidths(currentTab.content, currentTab.scroll, {currentTab.advancedText})
    end
end

-- Create summary tab
function UI:CreateSummaryTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()

    -- Create scroll frame for stats to prevent overflow
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -UI_CONSTANTS.SPACING.WINDOW_MARGIN)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI_CONSTANTS.SPACING.SCROLL_BAR_WIDTH, UI_CONSTANTS.SPACING.WINDOW_MARGIN)

    -- Create content frame to hold the text
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth() - 20, 2000) -- Set a large height for scrolling

    -- Stats display with consistent spacing
    frame.statsText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.statsText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    frame.statsText:SetWidth(content:GetWidth())
    frame.statsText:SetJustifyH("LEFT")
    frame.statsText:SetJustifyV("TOP")
    frame.statsText:SetWordWrap(true) -- Enable word wrapping to prevent horizontal overflow
    frame.statsText:SetText("Loading statistics...")

    scroll:SetScrollChild(content)

    -- Store references for resize handling
    frame.scroll = scroll
    frame.content = content

    return frame
end

-- Create players tab
function UI:CreatePlayersTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()

    -- Search box with standardized sizing
    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(UI_CONSTANTS.SPACING.SEARCH_BOX_WIDTH, UI_CONSTANTS.SPACING.SEARCH_BOX_HEIGHT)
    searchBox:SetPoint("TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -UI_CONSTANTS.SPACING.WINDOW_MARGIN)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnEnterPressed", function(self)
        UI:ShowSearchResults(self:GetText())
        self:ClearFocus()
    end)

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("LEFT", searchBox, "RIGHT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, 0)
    searchLabel:SetText("Search players...")

    -- Create scroll frame for results to prevent overflow
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -50)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI_CONSTANTS.SPACING.SCROLL_BAR_WIDTH, UI_CONSTANTS.SPACING.WINDOW_MARGIN)

    -- Create content frame to hold the text
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth() - 20, 2000) -- Set a large height for scrolling

    -- Results area with proper spacing
    frame.resultsText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.resultsText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    frame.resultsText:SetWidth(content:GetWidth())
    frame.resultsText:SetJustifyH("LEFT")
    frame.resultsText:SetJustifyV("TOP")
    frame.resultsText:SetWordWrap(true) -- Enable word wrapping to prevent horizontal overflow
    frame.resultsText:SetText("Top players will appear here...")

    scroll:SetScrollChild(content)

    frame.searchBox = searchBox

    -- Store references for resize handling
    frame.scroll = scroll
    frame.content = content

    return frame
end

-- Create guilds tab
function UI:CreateGuildsTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()

    -- Create scroll frame for guild stats to prevent overflow
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -UI_CONSTANTS.SPACING.WINDOW_MARGIN)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI_CONSTANTS.SPACING.SCROLL_BAR_WIDTH, UI_CONSTANTS.SPACING.WINDOW_MARGIN)

    -- Create content frame to hold the text
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth() - 20, 2000) -- Set a large height for scrolling

    frame.guildsText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.guildsText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    frame.guildsText:SetWidth(content:GetWidth())
    frame.guildsText:SetJustifyH("LEFT")
    frame.guildsText:SetJustifyV("TOP")
    frame.guildsText:SetWordWrap(true) -- Enable word wrapping to prevent horizontal overflow
    frame.guildsText:SetText("Guild statistics will appear here...")

    scroll:SetScrollChild(content)

    -- Store references for resize handling
    frame.scroll = scroll
    frame.content = content

    return frame
end

-- Create encounters tab
function UI:CreateEncountersTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()

    -- Create scroll frame for encounter data to prevent overflow
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -UI_CONSTANTS.SPACING.WINDOW_MARGIN)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI_CONSTANTS.SPACING.SCROLL_BAR_WIDTH, UI_CONSTANTS.SPACING.WINDOW_MARGIN)

    -- Create content frame to hold the text
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth() - 20, 2000) -- Set a large height for scrolling

    frame.encountersText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.encountersText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    frame.encountersText:SetWidth(content:GetWidth())
    frame.encountersText:SetJustifyH("LEFT")
    frame.encountersText:SetJustifyV("TOP")
    frame.encountersText:SetWordWrap(true) -- Enable word wrapping to prevent horizontal overflow
    frame.encountersText:SetText("Recent encounters will appear here...")

    scroll:SetScrollChild(content)

    -- Store references for resize handling
    frame.scroll = scroll
    frame.content = content

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
    elseif self.currentTab == "advanced" then
        self:RefreshAdvancedTab()
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
    local activity = Crosspaths.Engine:GetRecentActivity()
    local lines = {}

    table.insert(lines, "|cFFFFD700Crosspaths Statistics Overview|r")
    table.insert(lines, "")

    -- Overall statistics
    table.insert(lines, "|cFFFF8080Overall Statistics:|r")
    table.insert(lines, string.format("  Total Players: |cFF00FF00%d|r", stats.totalPlayers))
    table.insert(lines, string.format("  Total Encounters: |cFF00FF00%d|r", stats.totalEncounters))
    table.insert(lines, string.format("  Grouped Players: |cFF00FF00%d|r", stats.groupedPlayers))
    table.insert(lines, string.format("  Guilds Encountered: |cFF00FF00%d|r", stats.totalGuilds))

    if stats.totalPlayers > 0 then
        table.insert(lines, string.format("  Average Encounters per Player: |cFF00FF00%.1f|r", stats.averageEncounters))
    end

    -- Recent activity
    table.insert(lines, "")
    table.insert(lines, "|cFF80FF80Recent Activity:|r")
    table.insert(lines, string.format("  Last 24 Hours: |cFFFFFFFF%d players, %d encounters|r", activity.last24h.players, activity.last24h.encounters))
    table.insert(lines, string.format("  Last 7 Days: |cFFFFFFFF%d players, %d encounters|r", activity.last7d.players, activity.last7d.encounters))
    table.insert(lines, string.format("  Last 30 Days: |cFFFFFFFF%d players, %d encounters|r", activity.last30d.players, activity.last30d.encounters))

    -- Time range information
    if stats.oldestEncounter then
        table.insert(lines, "")
        table.insert(lines, "|cFF8080FFTime Range:|r")
        table.insert(lines, string.format("  Oldest Encounter: |cFFFFFFFF%s|r", date("%Y-%m-%d %H:%M", stats.oldestEncounter)))
        table.insert(lines, string.format("  Newest Encounter: |cFFFFFFFF%s|r", date("%Y-%m-%d %H:%M", stats.newestEncounter)))
    end

    -- Top zones
    table.insert(lines, "")
    table.insert(lines, "|cFF80FFFF Top Zones:|r")
    local topZones = Crosspaths.Engine:GetTopZones(5)
    if #topZones > 0 then
        for i, zone in ipairs(topZones) do
            table.insert(lines, string.format("  %d. %s (%d encounters)", i, zone.name, zone.encounterCount))
        end
    else
        table.insert(lines, "  No zone data available")
    end

    -- Top players
    table.insert(lines, "")
    table.insert(lines, "|cFFFFD700Top Players:|r")
    local topPlayers = Crosspaths.Engine:GetTopPlayers(5)
    if #topPlayers > 0 then
        for i, player in ipairs(topPlayers) do
            local guildText = player.guild and player.guild ~= "" and (" <" .. player.guild .. ">") or ""
            table.insert(lines, string.format("  %d. %s%s (%d encounters)", i, player.name, guildText, player.count))
        end
    else
        table.insert(lines, "  No player data available")
    end

    -- Current session statistics
    local sessionStats = Crosspaths.Engine:GetSessionStats()
    table.insert(lines, "")
    table.insert(lines, "|cFFFF80FF Current Session:|r")
    table.insert(lines, string.format("  Players Encountered: |cFFFFFFFF%d|r", sessionStats.playersEncountered))
    table.insert(lines, string.format("  New Players: |cFFFFFFFF%d|r", sessionStats.newPlayers))
    table.insert(lines, string.format("  Total Encounters: |cFFFFFFFF%d|r", sessionStats.totalEncounters))
    if sessionStats.sessionDuration > 60 then
        local minutes = math.floor(sessionStats.sessionDuration / 60)
        local seconds = sessionStats.sessionDuration % 60
        table.insert(lines, string.format("  Session Duration: |cFFFFFFFF%dm %ds|r", minutes, seconds))
    else
        table.insert(lines, string.format("  Session Duration: |cFFFFFFFF%ds|r", sessionStats.sessionDuration))
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

        -- Add class/race information
        local classText = ""
        if player.class and player.class ~= "" then
            classText = " |cFFAAAAAA[" .. player.class
            if player.race and player.race ~= "" then
                classText = classText .. " " .. player.race
            end
            classText = classText .. "]|r"
        end

        -- Add level information
        local levelText = ""
        if player.level and player.level > 0 then
            levelText = " |cFFFFFF00(L" .. player.level .. ")|r"
        end

        -- Add item level if significant
        local iLevelText = ""
        if player.itemLevel and player.itemLevel > 0 then
            iLevelText = " |cFFFF8800(iL" .. player.itemLevel .. ")|r"
        end

        table.insert(lines, string.format("%d. %s%s%s%s%s%s - %d encounters",
            i, player.name, groupedText, guildText, classText, levelText, iLevelText, player.count))
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
    local contextStats = Crosspaths.Engine:GetContextStats()
    local lines = {}

    table.insert(lines, "|cFFFFD700Zone and Context Statistics|r")
    table.insert(lines, "")

    -- Top zones
    table.insert(lines, "|cFF80FFFF Top Zones (by encounters):|r")
    if #zones > 0 then
        for i, zone in ipairs(zones) do
            table.insert(lines, string.format("  %d. %s - %d encounters", i, zone.name, zone.encounterCount))
        end
    else
        table.insert(lines, "  No zone data yet.")
    end

    -- Encounter contexts
    table.insert(lines, "")
    table.insert(lines, "|cFFFF80FF Encounter Contexts:|r")
    if #contextStats > 0 then
        for i, context in ipairs(contextStats) do
            table.insert(lines, string.format("  %d. %s - %d encounters (%.1f%%)", i, context.context, context.count, context.percentage))
        end
    else
        table.insert(lines, "  No context data available")
    end

    self.tabContent.encounters.encountersText:SetText(table.concat(lines, "\n"))
end

-- Create advanced stats tab
function UI:CreateAdvancedTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()

    -- Main scroll frame for advanced statistics with consistent spacing
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -UI_CONSTANTS.SPACING.WINDOW_MARGIN)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI_CONSTANTS.SPACING.SCROLL_BAR_WIDTH, UI_CONSTANTS.SPACING.WINDOW_MARGIN)

    -- Create content frame to hold the text
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(scroll:GetWidth() - 20, 2000) -- Set a large height for scrolling

    -- Text display for advanced stats
    frame.advancedText = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.advancedText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    frame.advancedText:SetWidth(content:GetWidth())
    frame.advancedText:SetJustifyH("LEFT")
    frame.advancedText:SetJustifyV("TOP")
    frame.advancedText:SetWordWrap(true) -- Enable word wrapping to prevent horizontal overflow
    frame.advancedText:SetText("Advanced statistics will appear here...")

    scroll:SetScrollChild(content)

    -- Store references for resize handling
    frame.scroll = scroll
    frame.content = content

    return frame
end

-- Refresh advanced stats tab
function UI:RefreshAdvancedTab()
    if not self.tabContent.advanced then
        return
    end

    local stats = Crosspaths.Engine:GetAdvancedStats()
    local lines = {}

    table.insert(lines, "|cFFFFD700Advanced Player Statistics|r")
    table.insert(lines, "")

    -- Role-based statistics
    table.insert(lines, "|cFF8080FFTop Tank Players:|r")
    if #stats.topTanks > 0 then
        for i, player in ipairs(stats.topTanks) do
            if i <= 5 then -- Show top 5
                local spec = player.specialization and (" - " .. player.specialization) or ""
                table.insert(lines, string.format("  %d. %s%s (%d encounters)", i, player.name, spec, player.count))
            end
        end
    else
        table.insert(lines, "  No tank data available")
    end

    table.insert(lines, "")
    table.insert(lines, "|cFF80FF80Top Healer Players:|r")
    if #stats.topHealers > 0 then
        for i, player in ipairs(stats.topHealers) do
            if i <= 5 then
                local spec = player.specialization and (" - " .. player.specialization) or ""
                table.insert(lines, string.format("  %d. %s%s (%d encounters)", i, player.name, spec, player.count))
            end
        end
    else
        table.insert(lines, "  No healer data available")
    end

    table.insert(lines, "")
    table.insert(lines, "|cFFFF8080Top DPS Players:|r")
    if #stats.topDPS > 0 then
        for i, player in ipairs(stats.topDPS) do
            if i <= 5 then
                local spec = player.specialization and (" - " .. player.specialization) or ""
                table.insert(lines, string.format("  %d. %s%s (%d encounters)", i, player.name, spec, player.count))
            end
        end
    else
        table.insert(lines, "  No DPS data available")
    end

    -- Item level statistics
    table.insert(lines, "")
    table.insert(lines, "|cFFFFFF80Highest Item Level Players:|r")
    if #stats.highestItemLevels > 0 then
        for i, player in ipairs(stats.highestItemLevels) do
            if i <= 5 then
                table.insert(lines, string.format("  %d. %s (iLvl: %d, %d encounters)", i, player.name, player.itemLevel, player.count))
            end
        end
    else
        table.insert(lines, "  No item level data available")
    end

    -- Achievement statistics
    table.insert(lines, "")
    table.insert(lines, "|cFFFF80FFAchievement Leaders:|r")
    if #stats.achievementLeaders > 0 then
        for i, player in ipairs(stats.achievementLeaders) do
            if i <= 5 then
                table.insert(lines, string.format("  %d. %s (%d points, %d encounters)", i, player.name, player.achievementPoints, player.count))
            end
        end
    else
        table.insert(lines, "  No achievement data available")
    end

    -- Mount statistics
    table.insert(lines, "")
    table.insert(lines, "|cFF80FFFF Most Common Mounts:|r")
    if #stats.commonMounts > 0 then
        for i, mount in ipairs(stats.commonMounts) do
            if i <= 3 then
                table.insert(lines, string.format("  %d. %s (seen %d times)", i, mount.mount, mount.count))
            end
        end
    else
        table.insert(lines, "  No mount data available")
    end

    -- Class distribution
    local classStats = Crosspaths.Engine:GetClassStats()
    table.insert(lines, "")
    table.insert(lines, "|cFFFFFF80Class Distribution:|r")
    if #classStats > 0 then
        for i, class in ipairs(classStats) do
            if i <= 6 then -- Show top 6 classes
                table.insert(lines, string.format("  %d. %s: %d players (%.1f%%, %d encounters)", i, class.class, class.players, class.percentage, class.encounters))
            end
        end
    else
        table.insert(lines, "  No class data available")
    end

    self.tabContent.advanced.advancedText:SetText(table.concat(lines, "\n"))
end

-- Show toast notification
function UI:ShowToast(title, message, notificationType)
    -- Check master notification settings
    if not Crosspaths.db or not Crosspaths.db.settings.ui.showNotifications then
        return
    end

    local notifications = Crosspaths.db.settings.notifications
    if not notifications.enableNotifications then
        return
    end

    -- Check Do Not Disturb mode
    if notifications.doNotDisturbCombat and InCombatLockdown() then
        return
    end

    -- Check specific notification type
    if notificationType then
        if notificationType == "repeat" and not notifications.notifyRepeatEncounters then
            return
        elseif notificationType == "frequent" and not notifications.notifyFrequentPlayers then
            return
        elseif notificationType == "group" and not notifications.notifyPreviousGroupMembers then
            return
        elseif notificationType == "new" and not notifications.notifyNewEncounters then
            return
        elseif notificationType == "guild" and not notifications.notifyGuildMembers then
            return
        end
    end

    -- Check max notifications limit
    local activeToasts = 0
    for i = #self.toastFrames, 1, -1 do
        local toast = self.toastFrames[i]
        if toast and toast:IsShown() then
            activeToasts = activeToasts + 1
        else
            -- Remove inactive toasts from the list
            table.remove(self.toastFrames, i)
        end
    end

    local maxNotifications = notifications.maxNotifications or 3
    if activeToasts >= maxNotifications then
        return -- Don't show more notifications than the limit
    end

    -- Calculate position based on existing toasts to prevent overlap
    local yOffset = -100
    yOffset = yOffset - (activeToasts * 70) -- 70 pixels per notification (60 height + 10 spacing)

    -- Create toast notification
    local toast = CreateFrame("Frame", nil, UIParent)
    toast:SetSize(320, 70) -- Slightly larger for better text display
    toast:SetPoint("TOP", UIParent, "TOP", 0, yOffset)
    toast:SetFrameStrata("HIGH")

    -- Background with border
    toast.bg = toast:CreateTexture(nil, "BACKGROUND")
    toast.bg:SetAllPoints()
    toast.bg:SetColorTexture(unpack(UI_CONSTANTS.COLORS.TOAST_BG))

    -- Add subtle border for better visibility
    toast.border = toast:CreateTexture(nil, "BORDER")
    toast.border:SetAllPoints()
    toast.border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    toast.border:SetPoint("TOPLEFT", toast, "TOPLEFT", -1, 1)
    toast.border:SetPoint("BOTTOMRIGHT", toast, "BOTTOMRIGHT", 1, -1)

    -- Title with proper width constraints
    toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toast.title:SetPoint("TOP", toast, "TOP", 0, -8)
    toast.title:SetWidth(300) -- Constrain width to prevent overflow
    toast.title:SetJustifyH("CENTER")
    -- Truncate title if too long
    local displayTitle = title
    if string.len(title) > 35 then
        displayTitle = string.sub(title, 1, 32) .. "..."
    end
    toast.title:SetText(displayTitle)
    toast.title:SetTextColor(unpack(UI_CONSTANTS.COLORS.TOAST_TITLE))

    -- Message with proper width constraints and word wrapping
    toast.message = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toast.message:SetPoint("TOP", toast.title, "BOTTOM", 0, -5)
    toast.message:SetWidth(300) -- Constrain width to prevent overflow
    toast.message:SetJustifyH("CENTER")
    toast.message:SetWordWrap(true)
    -- Truncate message if too long
    local displayMessage = message
    if string.len(message) > 60 then
        displayMessage = string.sub(message, 1, 57) .. "..."
    end
    toast.message:SetText(displayMessage)
    toast.message:SetTextColor(unpack(UI_CONSTANTS.COLORS.TOAST_TEXT))

    -- Play sound if enabled
    if notifications.playSound then
        PlaySound(SOUNDKIT.FRIEND_JOIN_GAME or 5633)
    end

    -- Auto-hide
    local duration = notifications.duration or Crosspaths.db.settings.ui.notificationDuration or 3
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

            -- Add class/race information
            local classText = ""
            if player.class and player.class ~= "" then
                classText = " |cFFAAAAAA[" .. player.class
                if player.race and player.race ~= "" then
                    classText = classText .. " " .. player.race
                end
                classText = classText .. "]|r"
            end

            -- Add level information
            local levelText = ""
            if player.level and player.level > 0 then
                levelText = " |cFFFFFF00(L" .. player.level .. ")|r"
            end

            -- Truncate player name if too long to prevent overflow
            local playerName = player.name
            if string.len(playerName) > 20 then
                playerName = string.sub(playerName, 1, 17) .. "..."
            end

            -- Truncate guild name if too long
            if player.guild and string.len(player.guild) > 15 then
                local truncatedGuild = string.sub(player.guild, 1, 12) .. "..."
                guildText = " |cFFFFFFFF<" .. truncatedGuild .. ">|r"
            end

            table.insert(lines, string.format("%d. %s%s%s%s%s - %d encounters",
                i, playerName, groupedText, guildText, classText, levelText, player.count))
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
        "/crosspaths stats [tanks|healers|dps|ilvl|achievements] - Show stats",
        "/crosspaths search <name> - Search for player",
        "/crosspaths export [json|csv] - Export data",
        "/crosspaths remove <player-name> - Remove player from tracking",
        "/crosspaths clear confirm - Clear all data",
        "/crosspaths cleanup confirm - Remove self-encounter data",
        "/crosspaths cleanup data confirm - Clean invalid data and duplicates",
        "/crosspaths cleanup duplicates - Detect potential duplicate players",
        "/crosspaths analytics [activity|social|progression|questlines|similar <player>|zone <zone>] - Advanced analysis",
        "/crosspaths debug [on|off] - Toggle debug mode",
        "/crosspaths status - Show addon status",
        "/crosspaths digest [daily|weekly|monthly] - Generate digest report",
        "/crosspaths minimap - Toggle minimap button",
        "/crosspaths titanpanel - Check TitanPanel integration status",
        "/cpconfig - Open configuration panel",
        "",
        "New Features:",
        "• Enhanced notification options with granular controls",
        "• Daily/Weekly/Monthly digest reports",
        "• Advanced analytics: activity patterns, social networks, progression",
        "• Quest line & path analysis: detect players following similar routes",
        "• Zone progression insights and quest line correlations",
        "• NPC/AI filtering: prevents tracking of follower dungeon companions",
        "• Enhanced deduplication for dungeons, raids, cinematics, and phases",
        "• Comprehensive data cleanup and duplicate detection",
        "• Titan Panel integration (if available)",
        "• Minimap button for easy UI access",
        "• Do Not Disturb mode during combat",
        "• Notification sound options",
    }

    for _, line in ipairs(help) do
        Crosspaths:Message(line)
    end
end

-- Show debug status
function UI:ShowDebugStatus()
    local status = Crosspaths.debug and "enabled" or "disabled"
    local logLevel = "unknown"
    if Crosspaths.Logging and Crosspaths.Logging.logLevel then
        local levels = {[1] = "ERROR", [2] = "WARN", [3] = "INFO", [4] = "DEBUG"}
        logLevel = levels[Crosspaths.Logging.logLevel] or "unknown"
    end

    Crosspaths:Message("Debug mode: " .. status .. " (log level: " .. logLevel .. ")")

    if Crosspaths.debug then
        Crosspaths:Message("Use '/crosspaths debug off' to disable debug mode")
    else
        Crosspaths:Message("Use '/crosspaths debug on' to enable debug mode")
    end
end

-- Show addon status
function UI:ShowStatus()
    local lines = {}

    -- Basic status
    table.insert(lines, "=== Crosspaths Status ===")
    table.insert(lines, "Version: " .. (Crosspaths.version or "unknown"))
    table.insert(lines, "Enabled: " .. tostring(Crosspaths.db and Crosspaths.db.settings.enabled or false))
    table.insert(lines, "Debug: " .. tostring(Crosspaths.debug or false))

    -- Database status
    if Crosspaths.db then
        local playerCount = 0
        if Crosspaths.db.players then
            for _ in pairs(Crosspaths.db.players) do
                playerCount = playerCount + 1
            end
        end
        table.insert(lines, "Tracked players: " .. playerCount)
    else
        table.insert(lines, "Database: NOT INITIALIZED")
    end

    -- Tracking settings
    if Crosspaths.db and Crosspaths.db.settings and Crosspaths.db.settings.tracking then
        local tracking = Crosspaths.db.settings.tracking
        table.insert(lines, "Group tracking: " .. tostring(tracking.enableGroupTracking))
        table.insert(lines, "Nameplate tracking: " .. tostring(tracking.enableNameplateTracking))
        table.insert(lines, "City tracking: " .. tostring(tracking.enableCityTracking))
        table.insert(lines, "Throttle: " .. tostring(tracking.throttleMs) .. "ms")
    else
        table.insert(lines, "Tracking settings: NOT FOUND")
    end

    -- Session stats
    if Crosspaths.sessionStats then
        local stats = Crosspaths.sessionStats
        table.insert(lines, "Session encounters: " .. tostring(stats.totalEncounters or stats.encountersDetected or 0))
        table.insert(lines, "Players encountered: " .. tostring(stats.playersEncountered or stats.playersAdded or 0))
        table.insert(lines, "New players: " .. tostring(stats.newPlayers or stats.playersUpdated or 0))
        table.insert(lines, "Events handled: " .. tostring(stats.eventsHandled))
    else
        table.insert(lines, "Session stats: NOT AVAILABLE")
    end

    -- Current zone
    local zone = Crosspaths:GetCurrentZone()
    local context = Crosspaths:GetEncounterContext()
    table.insert(lines, "Current zone: " .. tostring(zone))
    table.insert(lines, "Current context: " .. tostring(context))

    table.insert(lines, "=== End Status ===")

    for _, line in ipairs(lines) do
        Crosspaths:Message(line)
    end
end

-- Show TitanPanel integration status
function UI:ShowTitanPanelStatus()
    local lines = {}

    table.insert(lines, "=== TitanPanel Integration Status ===")

    -- Check if TitanPanel is available
    if TitanPanelUtils then
        table.insert(lines, "TitanPanel: DETECTED")
        table.insert(lines, "TitanPanelUtils: AVAILABLE")

        -- Check if our plugin is registered
        if TitanPanelUtils.IsRegistered and TitanPanelUtils:IsRegistered("Crosspaths") then
            table.insert(lines, "Crosspaths plugin: REGISTERED")
        else
            table.insert(lines, "Crosspaths plugin: NOT REGISTERED")
        end

        -- Check if our module is initialized
        if Crosspaths.TitanPanel then
            table.insert(lines, "TitanPanel module: LOADED")
        else
            table.insert(lines, "TitanPanel module: NOT LOADED")
        end

        table.insert(lines, "")
        table.insert(lines, "To use TitanPanel integration:")
        table.insert(lines, "1. Right-click on your TitanPanel bar")
        table.insert(lines, "2. Select 'Plugins'")
        table.insert(lines, "3. Look for 'Crosspaths' in the Information category")
        table.insert(lines, "4. Enable it to show Crosspaths stats on your bar")

    elseif TitanUtils_RegisterPlugin then
        table.insert(lines, "TitanPanel: LEGACY VERSION DETECTED")
        table.insert(lines, "Crosspaths: Attempting legacy integration")

        if Crosspaths.TitanPanel then
            table.insert(lines, "TitanPanel module: LOADED")
        else
            table.insert(lines, "TitanPanel module: NOT LOADED")
        end

    else
        table.insert(lines, "TitanPanel: NOT INSTALLED")
        table.insert(lines, "")
        table.insert(lines, "To get TitanPanel integration:")
        table.insert(lines, "1. Install the TitanPanel addon from CurseForge or WowInterface")
        table.insert(lines, "2. Restart WoW or reload UI (/reload)")
        table.insert(lines, "3. Crosspaths will automatically integrate with TitanPanel")
    end

    table.insert(lines, "=== End TitanPanel Status ===")

    for _, line in ipairs(lines) do
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
    -- Use documented WoW APIs for tooltip integration
    -- Hook the OnShow script (documented API) and check if displaying unit data
    if GameTooltip:HasScript("OnShow") then
        GameTooltip:HookScript("OnShow", function(tooltip)
            -- Use GetUnit() - documented function to check if tooltip shows a unit
            local unitName, unitID = tooltip:GetUnit()
            if unitName and unitID then
                self:AddEncounterInfoToTooltip(tooltip)
            end
        end)
        Crosspaths:DebugLog("GameTooltip OnShow hook registered successfully using documented WoW API", "DEBUG")
    else
        Crosspaths:DebugLog("GameTooltip does not have OnShow script - tooltip integration disabled", "WARN")
    end
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

    -- Add a separator line
    tooltip:AddLine(" ")

    -- Add Crosspaths header
    tooltip:AddLine("|cFF7B68EECrosspaths|r", 0.4, 0.4, 1)

    if playerData and playerData.count and playerData.count > 0 then
        local encounterCount = playerData.count

        -- Show encounter status with clear feedback
        local statusText = "|cFF00FF00Previously Encountered|r"
        local countColor = encounterCount >= 10 and "|cFFFFD700" or encounterCount >= 5 and "|cFF00FF00" or "|cFFFFFFFF"
        tooltip:AddDoubleLine("Status:", statusText, 0.8, 0.8, 0.8, 0, 1, 0)
        tooltip:AddDoubleLine("Encounters:", countColor .. tostring(encounterCount) .. "|r", 0.8, 0.8, 0.8, 1, 1, 1)

        -- Add class and race info
        if playerData.class and playerData.class ~= "" then
            local classInfo = playerData.class
            if playerData.race and playerData.race ~= "" then
                classInfo = playerData.race .. " " .. playerData.class
            end
            tooltip:AddDoubleLine("Class:", classInfo, 0.8, 0.8, 0.8, 1, 1, 0.8)
        end

        -- Add level info with progression indicator
        if playerData.level and playerData.level > 0 then
            local levelText = tostring(playerData.level)
            -- Show level progression if available
            if playerData.levelHistory and #playerData.levelHistory > 0 then
                local lastProgress = playerData.levelHistory[#playerData.levelHistory]
                if lastProgress and lastProgress.previousLevel then
                    levelText = levelText .. " (was " .. lastProgress.previousLevel .. ")"
                end
            end
            tooltip:AddDoubleLine("Level:", levelText, 0.8, 0.8, 0.8, 0.6, 1, 0.6)
        end

        -- Add specialization if available
        if playerData.specialization and playerData.specialization ~= "" then
            tooltip:AddDoubleLine("Spec:", playerData.specialization, 0.8, 0.8, 0.8, 1, 0.8, 1)
        end

        -- Add item level if available
        if playerData.itemLevel and playerData.itemLevel > 0 then
            tooltip:AddDoubleLine("Item Level:", tostring(playerData.itemLevel), 0.8, 0.8, 0.8, 1, 1, 0.6)
        end

        -- Add achievement points if available
        if playerData.achievementPoints and playerData.achievementPoints > 0 then
            tooltip:AddDoubleLine("Achievements:", tostring(playerData.achievementPoints) .. " points", 0.8, 0.8, 0.8, 1, 0.8, 0.6)
        end

        -- Add last seen info
        if playerData.lastSeen then
            local timeAgo = self:FormatTimeAgo(playerData.lastSeen)
            tooltip:AddDoubleLine("Last seen:", timeAgo, 0.8, 0.8, 0.8, 1, 1, 1)
        end

        -- Add first seen info
        if playerData.firstSeen then
            local timeAgo = self:FormatTimeAgo(playerData.firstSeen)
            tooltip:AddDoubleLine("First seen:", timeAgo, 0.8, 0.8, 0.8, 1, 1, 1)
        end

        -- Add grouped status with enhanced visibility
        if playerData.grouped then
            tooltip:AddDoubleLine("Group Status:", "|cFF00FF00Previously Grouped With You|r", 0.8, 0.8, 0.8, 0, 1, 0)
        else
            tooltip:AddDoubleLine("Group Status:", "|cFF888888Never Grouped|r", 0.8, 0.8, 0.8, 0.5, 0.5, 0.5)
        end

        -- Add guild info if available
        if playerData.guild and playerData.guild ~= "" then
            tooltip:AddDoubleLine("Guild:", playerData.guild, 0.8, 0.8, 0.8, 1, 0.8, 0)
        end

        -- Add location info if available
        if playerData.subzone and playerData.subzone ~= "" then
            tooltip:AddDoubleLine("Last location:", playerData.subzone, 0.8, 0.8, 0.8, 0.8, 0.8, 1)
        end

        -- Add notes if available (truncated for tooltip)
        if playerData.notes and playerData.notes ~= "" then
            local notes = playerData.notes
            if string.len(notes) > 40 then
                notes = string.sub(notes, 1, 37) .. "..."
            end
            tooltip:AddDoubleLine("Notes:", notes, 0.8, 0.8, 0.8, 1, 1, 0.8)
        end

        -- Add encounter context information
        if playerData.contexts and next(playerData.contexts) then
            local contexts = {}
            local totalContexts = 0
            for context, count in pairs(playerData.contexts) do
                totalContexts = totalContexts + count
                table.insert(contexts, context .. " (" .. count .. ")")
            end
            -- Sort by frequency
            table.sort(contexts, function(a, b)
                local countA = tonumber(string.match(a, "%((%d+)%)")) or 0
                local countB = tonumber(string.match(b, "%((%d+)%)")) or 0
                return countA > countB
            end)

            -- Show top 2 contexts
            local contextText = ""
            for i = 1, math.min(2, #contexts) do
                if i > 1 then contextText = contextText .. ", " end
                contextText = contextText .. contexts[i]
            end
            if #contexts > 2 then
                contextText = contextText .. " +more"
            end
            tooltip:AddDoubleLine("Contexts:", contextText, 0.8, 0.8, 0.8, 0.8, 1, 0.8)
        end

        -- Add top zones information
        if playerData.zones and next(playerData.zones) then
            local zones = {}
            for zone, count in pairs(playerData.zones) do
                table.insert(zones, {zone = zone, count = count})
            end
            table.sort(zones, function(a, b) return a.count > b.count end)

            -- Show top zone
            if zones[1] then
                local zoneText = zones[1].zone .. " (" .. zones[1].count .. ")"
                if zones[2] then
                    zoneText = zoneText .. ", " .. zones[2].zone .. " (" .. zones[2].count .. ")"
                end
                tooltip:AddDoubleLine("Top zones:", zoneText, 0.8, 0.8, 0.8, 1, 0.8, 0.6)
            end
        end

        tooltip:Show()
    else
        -- Show clear indication for never encountered players
        tooltip:AddDoubleLine("Status:", "|cFFFF6B6BNever Encountered|r", 0.8, 0.8, 0.8, 1, 0.4, 0.4)
        tooltip:AddDoubleLine("Encounters:", "|cFF888888None|r", 0.8, 0.8, 0.8, 0.5, 0.5, 0.5)
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
    local encounterCount = playerData.count or 0
    if encounterCount > 0 then
        self.tooltip:AddLine("Encounters: " .. encounterCount, 0.7, 0.7, 1)

        -- Show class and race info
        if playerData.class and playerData.class ~= "" then
            local classInfo = playerData.class
            if playerData.race and playerData.race ~= "" then
                classInfo = playerData.race .. " " .. playerData.class
            end
            self.tooltip:AddLine("Class: " .. classInfo, 1, 1, 0.8)
        end

        -- Show level with progression
        if playerData.level and playerData.level > 0 then
            local levelText = "Level: " .. playerData.level
            if playerData.levelHistory and #playerData.levelHistory > 0 then
                local progressCount = #playerData.levelHistory
                levelText = levelText .. " (+" .. progressCount .. " level" .. (progressCount > 1 and "s" or "") .. " tracked)"
            end
            self.tooltip:AddLine(levelText, 0.6, 1, 0.6)
        end

        -- Show specialization if available
        if playerData.specialization and playerData.specialization ~= "" then
            self.tooltip:AddLine("Specialization: " .. playerData.specialization, 1, 0.8, 1)
        end

        -- Show item level if available
        if playerData.itemLevel and playerData.itemLevel > 0 then
            self.tooltip:AddLine("Item Level: " .. playerData.itemLevel, 1, 1, 0.6)
        end

        -- Show achievement points if available
        if playerData.achievementPoints and playerData.achievementPoints > 0 then
            self.tooltip:AddLine("Achievement Points: " .. playerData.achievementPoints, 1, 0.8, 0.6)
        end

        -- Show last seen info
        if playerData.lastSeen then
            local timeAgo = self:FormatTimeAgo(playerData.lastSeen)
            self.tooltip:AddLine("Last seen: " .. timeAgo, 0.8, 0.8, 0.8)
        end

        -- Show first seen info
        if playerData.firstSeen then
            local timeAgo = self:FormatTimeAgo(playerData.firstSeen)
            self.tooltip:AddLine("First seen: " .. timeAgo, 0.8, 0.8, 0.8)
        end

        -- Show grouped status
        if playerData.grouped then
            self.tooltip:AddLine("Status: Previously grouped", 0.6, 1, 0.6)
        end

        -- Show guild if available
        if playerData.guild and playerData.guild ~= "" then
            self.tooltip:AddLine("Guild: " .. playerData.guild, 1, 0.8, 0)
        end

        -- Show location if available
        if playerData.subzone and playerData.subzone ~= "" then
            self.tooltip:AddLine("Last location: " .. playerData.subzone, 0.8, 0.8, 1)
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

-- Remove a specific player from tracking
function UI:RemovePlayer(playerName)
    if not Crosspaths.db or not Crosspaths.db.players then
        Crosspaths:Message("No player database available")
        return
    end

    -- Handle both "Name" and "Name-Realm" formats
    local targetName = playerName
    if not string.find(playerName, "-") then
        targetName = playerName .. "-" .. GetRealmName()
    end

    if Crosspaths.db.players[targetName] then
        local playerData = Crosspaths.db.players[targetName]
        local encounters = playerData.count or 0
        Crosspaths.db.players[targetName] = nil
        Crosspaths:Message("Removed " .. targetName .. " (" .. encounters .. " encounters) from tracking")
        Crosspaths:DebugLog("Player removed: " .. targetName, "INFO")

        -- Refresh UI if it's open
        if self.mainFrame and self.mainFrame:IsShown() then
            self:RefreshCurrentTab()
        end
    else
        Crosspaths:Message("Player '" .. targetName .. "' not found")
    end
end

-- Show digest report in a window
function UI:ShowDigestReport(title, digest)
    -- Create digest report frame using standard helper
    local frame = CreateStandardFrame("CrosspathsDigestFrame", UIParent, "DIGEST_WINDOW", "HIGH")

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText(title)

    -- Scroll frame for content with responsive sizing
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI_CONSTANTS.SPACING.SCROLL_BAR_WIDTH, 40)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth() - 20, 800)
    scrollFrame:SetScrollChild(content)

    -- Generate content
    self:PopulateDigestContent(content, digest)

    -- Close button using standard helper
    local closeBtn = CreateStandardCloseButton(frame)

    -- Export button with standard sizing
    local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    exportBtn:SetSize(80, UI_CONSTANTS.SPACING.BUTTON_HEIGHT)
    exportBtn:SetPoint("RIGHT", closeBtn, "LEFT", -UI_CONSTANTS.SPACING.WINDOW_MARGIN, 0)
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function()
        self:ExportDigest(digest, title)
    end)

    frame:Show()
end

-- Populate digest content
function UI:PopulateDigestContent(content, digest)
    local yOffset = -UI_CONSTANTS.SPACING.CONTENT_MARGIN
    local contentWidth = content:GetWidth() - (UI_CONSTANTS.SPACING.CONTENT_MARGIN * 2)

    -- Period header
    local periodLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    periodLabel:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_MARGIN, yOffset)
    periodLabel:SetText("|cFFFFD700" .. digest.period:upper() .. " DIGEST|r")
    periodLabel:SetWidth(contentWidth)
    periodLabel:SetJustifyH("LEFT")
    yOffset = yOffset - UI_CONSTANTS.SPACING.HEADER_SPACING

    local dateRange = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dateRange:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_MARGIN, yOffset)
    dateRange:SetText(string.format("|cFFADD8E6Period:|r %s to %s",
        date("%m/%d/%Y", digest.startTime),
        date("%m/%d/%Y", digest.endTime)))
    dateRange:SetWidth(contentWidth)
    dateRange:SetJustifyH("LEFT")
    yOffset = yOffset - (UI_CONSTANTS.SPACING.HEADER_SPACING + UI_CONSTANTS.SPACING.SUBSECTION_SPACING)

    -- Overview stats
    local overviewLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    overviewLabel:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_MARGIN, yOffset)
    overviewLabel:SetText("|cFF00FF00Overview|r")
    overviewLabel:SetWidth(contentWidth)
    overviewLabel:SetJustifyH("LEFT")
    yOffset = yOffset - UI_CONSTANTS.SPACING.SECTION_SPACING

    local newPlayers = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    newPlayers:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
    newPlayers:SetText(string.format("• New players discovered: |cFFFFFFFF%d|r", digest.newPlayers))
    newPlayers:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
    newPlayers:SetJustifyH("LEFT")
    yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING

    local totalEncounters = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalEncounters:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
    totalEncounters:SetText(string.format("• Total encounters: |cFFFFFFFF%d|r", digest.totalEncounters))
    totalEncounters:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
    totalEncounters:SetJustifyH("LEFT")
    yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING

    if digest.averageLevel and digest.averageLevel > 0 then
        local avgLevel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        avgLevel:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
        avgLevel:SetText(string.format("• Average player level: |cFFFFFFFF%d|r", digest.averageLevel))
        avgLevel:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
        avgLevel:SetJustifyH("LEFT")
        yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING
    end

    if digest.activeDays then
        local activeDays = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        activeDays:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
        activeDays:SetText(string.format("• Active days: |cFFFFFFFF%d|r", digest.activeDays))
        activeDays:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
        activeDays:SetJustifyH("LEFT")
        yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING
    end

    if digest.peakDay and digest.peakDay ~= "" then
        local peakDay = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        peakDay:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
        peakDay:SetText(string.format("• Peak activity: |cFFFFFFFF%s (%d encounters)|r", digest.peakDay, digest.peakDayEncounters))
        peakDay:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
        peakDay:SetJustifyH("LEFT")
        yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING
    end

    yOffset = yOffset - UI_CONSTANTS.SPACING.SUBSECTION_SPACING

    -- Top zones
    if digest.topZones and #digest.topZones > 0 then
        local zonesLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        zonesLabel:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_MARGIN, yOffset)
        zonesLabel:SetText("|cFF00FF00Top Zones|r")
        zonesLabel:SetWidth(contentWidth)
        zonesLabel:SetJustifyH("LEFT")
        yOffset = yOffset - UI_CONSTANTS.SPACING.SECTION_SPACING

        for i, zone in ipairs(digest.topZones) do
            if i <= 5 then
                local zoneText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                zoneText:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
                -- Truncate zone name if too long to prevent overflow
                local zoneName = zone.zone
                if string.len(zoneName) > 30 then
                    zoneName = string.sub(zoneName, 1, 27) .. "..."
                end
                zoneText:SetText(string.format("%d. %s |cFFFFFFFF(%d encounters)|r", i, zoneName, zone.count))
                zoneText:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
                zoneText:SetJustifyH("LEFT")
                yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING
            end
        end
        yOffset = yOffset - UI_CONSTANTS.SPACING.SUBSECTION_SPACING
    end

    -- Top classes
    if digest.topClasses and #digest.topClasses > 0 then
        local classesLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        classesLabel:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_MARGIN, yOffset)
        classesLabel:SetText("|cFF00FF00Popular Classes|r")
        classesLabel:SetWidth(contentWidth)
        classesLabel:SetJustifyH("LEFT")
        yOffset = yOffset - UI_CONSTANTS.SPACING.SECTION_SPACING

        for i, class in ipairs(digest.topClasses) do
            if i <= 5 then
                local classText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                classText:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
                -- Truncate class name if too long to prevent overflow
                local className = class.class
                if string.len(className) > 25 then
                    className = string.sub(className, 1, 22) .. "..."
                end
                classText:SetText(string.format("%d. %s |cFFFFFFFF(%d players)|r", i, className, class.count))
                classText:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
                classText:SetJustifyH("LEFT")
                yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING
            end
        end
        yOffset = yOffset - UI_CONSTANTS.SPACING.SUBSECTION_SPACING
    end

    -- Top guilds (for weekly/monthly)
    if digest.topGuilds and #digest.topGuilds > 0 then
        local guildsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        guildsLabel:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_MARGIN, yOffset)
        guildsLabel:SetText("|cFF00FF00Active Guilds|r")
        guildsLabel:SetWidth(contentWidth)
        guildsLabel:SetJustifyH("LEFT")
        yOffset = yOffset - UI_CONSTANTS.SPACING.SECTION_SPACING

        for i, guild in ipairs(digest.topGuilds) do
            if i <= 5 then
                local guildText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                guildText:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
                -- Truncate guild name if too long to prevent overflow
                local guildName = guild.guild
                if string.len(guildName) > 25 then
                    guildName = string.sub(guildName, 1, 22) .. "..."
                end
                guildText:SetText(string.format("%d. %s |cFFFFFFFF(%d encounters)|r", i, guildName, guild.count))
                guildText:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
                guildText:SetJustifyH("LEFT")
                yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING
            end
        end
        yOffset = yOffset - UI_CONSTANTS.SPACING.SUBSECTION_SPACING
    end

    -- Top players (for monthly)
    if digest.topPlayers and #digest.topPlayers > 0 then
        local playersLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        playersLabel:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_MARGIN, yOffset)
        playersLabel:SetText("|cFF00FF00Most Encountered Players|r")
        playersLabel:SetWidth(contentWidth)
        playersLabel:SetJustifyH("LEFT")
        yOffset = yOffset - UI_CONSTANTS.SPACING.SECTION_SPACING

        for i, player in ipairs(digest.topPlayers) do
            if i <= 10 then
                local playerText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                playerText:SetPoint("TOPLEFT", content, "TOPLEFT", UI_CONSTANTS.SPACING.CONTENT_INDENT, yOffset)
                -- Truncate player name if too long to prevent overflow
                local playerName = player.name
                if string.len(playerName) > 20 then
                    playerName = string.sub(playerName, 1, 17) .. "..."
                end
                playerText:SetText(string.format("%d. %s |cFFFFFFFF(%d encounters)|r", i, playerName, player.count))
                playerText:SetWidth(contentWidth - UI_CONSTANTS.SPACING.CONTENT_INDENT)
                playerText:SetJustifyH("LEFT")
                yOffset = yOffset - UI_CONSTANTS.SPACING.LIST_ITEM_SPACING
            end
        end
    end
end

-- Export digest data
function UI:ExportDigest(digest, title)
    local data = {
        title = title,
        digest = digest,
        exportTime = time()
    }

    local jsonData = self:TableToJSON(data)
    self:ShowExportFrame(jsonData, title .. " - " .. date("%Y-%m-%d"))
end

-- Show export frame with digest data
function UI:ShowExportFrame(data, filename)
    local frame = CreateStandardFrame("CrosspathsExportFrame", UIParent, "EXPORT_WINDOW", "HIGH")

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Export: " .. filename)

    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -30)
    instructions:SetText("Copy the data below and save it to a file:")

    -- Text area with responsive sizing
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", UI_CONSTANTS.SPACING.WINDOW_MARGIN, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -UI_CONSTANTS.SPACING.SCROLL_BAR_WIDTH, 40)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scrollFrame:GetWidth() - 20)
    editBox:SetText(data)
    editBox:SetCursorPosition(0)
    editBox:HighlightText()

    scrollFrame:SetScrollChild(editBox)

    -- Close button using standard helper
    local closeBtn = CreateStandardCloseButton(frame)

    frame:Show()
    editBox:SetFocus()
end

-- Copy comprehensive stats to clipboard-ready format
function UI:CopyStatsToClipboard()
    if not Crosspaths.Engine then
        Crosspaths:Message("Engine not available for stats generation")
        return
    end

    local stats = Crosspaths.Engine:GetStatsSummary()
    if not stats then
        Crosspaths:Message("Unable to generate stats summary")
        return
    end

    local lines = {}
    table.insert(lines, "=== CROSSPATHS STATS SUMMARY ===")
    table.insert(lines, "Generated: " .. date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "Version: " .. (Crosspaths.version or "Unknown"))
    table.insert(lines, "")

    -- Basic stats
    table.insert(lines, "OVERVIEW:")
    table.insert(lines, string.format("  Total Players: %d", stats.totalPlayers or 0))
    table.insert(lines, string.format("  Total Encounters: %d", stats.totalEncounters or 0))
    table.insert(lines, string.format("  Total Guilds: %d", stats.totalGuilds or 0))
    table.insert(lines, string.format("  Grouped Players: %d", stats.groupedPlayers or 0))
    table.insert(lines, string.format("  Average Encounters: %.1f", stats.averageEncounters or 0))
    table.insert(lines, "")

    -- Recent activity
    local activity = Crosspaths.Engine:GetRecentActivity()
    if activity then
        table.insert(lines, "RECENT ACTIVITY:")
        table.insert(lines, string.format("  Last 24h: %d players, %d encounters",
            activity.last24h.players or 0, activity.last24h.encounters or 0))
        table.insert(lines, string.format("  Last 7d: %d players, %d encounters",
            activity.last7d.players or 0, activity.last7d.encounters or 0))
        table.insert(lines, string.format("  Last 30d: %d players, %d encounters",
            activity.last30d.players or 0, activity.last30d.encounters or 0))
        table.insert(lines, "")
    end

    -- Session stats
    local sessionStats = Crosspaths.Engine:GetSessionStats()
    if sessionStats then
        table.insert(lines, "CURRENT SESSION:")
        table.insert(lines, string.format("  Players Encountered: %d", sessionStats.playersEncountered or 0))
        table.insert(lines, string.format("  New Players: %d", sessionStats.newPlayers or 0))
        table.insert(lines, string.format("  Total Encounters: %d", sessionStats.totalEncounters or 0))
        table.insert(lines, string.format("  Session Duration: %.1f minutes",
            (sessionStats.sessionDuration or 0) / 60))
        table.insert(lines, "")
    end

    -- Top players
    local topPlayers = Crosspaths.Engine:GetTopPlayersByType("encounters", 5)
    if topPlayers and #topPlayers > 0 then
        table.insert(lines, "TOP PLAYERS BY ENCOUNTERS:")
        for i, player in ipairs(topPlayers) do
            table.insert(lines, string.format("  %d. %s (%d encounters)",
                i, player.name, player.count))
        end
        table.insert(lines, "")
    end

    local formattedStats = table.concat(lines, "\n")

    -- Show the stats in an export window for easy copying
    self:ShowExportWindow("Crosspaths Stats Summary", formattedStats)
    Crosspaths:Message("Stats summary opened in copyable format")
end

-- Show advanced statistics by type
function UI:ShowAdvancedStats(statType)
    if not Crosspaths.Engine then
        Crosspaths:Message("Engine not available")
        return
    end

    local players = Crosspaths.Engine:GetTopPlayersByType(statType, 10)

    if #players == 0 then
        Crosspaths:Message("No data available for " .. statType)
        return
    end

    local title = "Top " .. string.upper(statType) .. " Players:"
    Crosspaths:Message(title)

    for i, player in ipairs(players) do
        local line = string.format("%d. %s", i, player.name)

        if statType == "ilvl" or statType == "itemlevel" then
            line = line .. string.format(" (iLvl: %d, %d encounters)", player.itemLevel, player.count)
        elseif statType == "achievements" then
            line = line .. string.format(" (%d points, %d encounters)", player.achievementPoints, player.count)
        else
            local spec = player.specialization and (" - " .. player.specialization) or ""
            line = line .. string.format("%s (%d encounters)", spec, player.count)
        end

        Crosspaths:Message(line)
    end
end

-- ============================================================================
-- ENHANCED ANALYTICS DISPLAY FUNCTIONS
-- ============================================================================

-- Show activity pattern analysis
function UI:ShowActivityAnalysis(patterns)
    if not patterns then
        Crosspaths:Message("Unable to generate activity analysis")
        return
    end

    Crosspaths:Message("=== Activity Pattern Analysis ===")

    -- Peak times
    Crosspaths:Message(string.format("Peak Hour: %02d:00 (%d encounters)",
        patterns.peakHour or 0, patterns.peakHourCount or 0))
    Crosspaths:Message(string.format("Peak Day: %s (%d encounters)",
        patterns.peakDay or "Unknown", patterns.peakDayCount or 0))

    -- Hourly breakdown
    if patterns.hourlyActivity then
        Crosspaths:Message("Hourly Activity Distribution:")
        local sortedHours = {}
        for hour, count in pairs(patterns.hourlyActivity) do
            table.insert(sortedHours, {hour = hour, count = count})
        end
        table.sort(sortedHours, function(a, b) return a.count > b.count end)

        for i = 1, math.min(5, #sortedHours) do
            local hourData = sortedHours[i]
            if hourData.count > 0 then
                Crosspaths:Message(string.format("  %02d:00 - %d encounters", hourData.hour, hourData.count))
            end
        end
    end

    -- Daily breakdown
    if patterns.dailyActivity then
        Crosspaths:Message("Daily Activity Distribution:")
        local dayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
        local sortedDays = {}
        for day, count in pairs(patterns.dailyActivity) do
            table.insert(sortedDays, {day = day, name = dayNames[day], count = count})
        end
        table.sort(sortedDays, function(a, b) return a.count > b.count end)

        for i = 1, math.min(7, #sortedDays) do
            local dayData = sortedDays[i]
            if dayData.count > 0 then
                Crosspaths:Message(string.format("  %s - %d encounters", dayData.name, dayData.count))
            end
        end
    end
end

-- Show social network analysis
function UI:ShowSocialAnalysis(networks)
    if not networks then
        Crosspaths:Message("Unable to generate social network analysis")
        return
    end

    Crosspaths:Message("=== Social Network Analysis ===")

    Crosspaths:Message(string.format("Total Players: %d", networks.totalConnections or 0))
    Crosspaths:Message(string.format("Network Density: %.1f%%", (networks.networkDensity or 0) * 100))

    -- Top social hubs
    if networks.topSocialHubs and #networks.topSocialHubs > 0 then
        Crosspaths:Message("Top Social Hubs:")
        for i, hub in ipairs(networks.topSocialHubs) do
            if i <= 5 then
                Crosspaths:Message(string.format("  %d. %s - %d players, %d encounters (%.1f density)",
                    i, hub.zone, hub.uniquePlayers, hub.totalEncounters, hub.density))
            end
        end
    end

    -- Strong connections
    if networks.strongConnections then
        local strongZones = 0
        for _ in pairs(networks.strongConnections) do
            strongZones = strongZones + 1
        end
        if strongZones > 0 then
            Crosspaths:Message(string.format("Strong Connection Zones: %d", strongZones))
            local zoneCount = 0
            for zoneName, players in pairs(networks.strongConnections) do
                if zoneCount < 3 then
                    Crosspaths:Message(string.format("  %s: %d dedicated players", zoneName, #players))
                    zoneCount = zoneCount + 1
                end
            end
        end
    end
end

-- Show progression analysis
function UI:ShowProgressionAnalysis(progression)
    if not progression then
        Crosspaths:Message("Unable to generate progression analysis")
        return
    end

    Crosspaths:Message("=== Progression Analysis ===")

    -- Level trends
    if progression.levelTrends and #progression.levelTrends > 0 then
        Crosspaths:Message(string.format("Fastest Progressors (Average: %.2f levels/day):",
            progression.averageLevelGain or 0))
        for i, trend in ipairs(progression.levelTrends) do
            if i <= 5 then
                Crosspaths:Message(string.format("  %d. %s - %.2f levels/day (%d levels gained)",
                    i, trend.player, trend.rate, trend.levelGain))
            end
        end
    end

    -- Class distribution
    if progression.classDistribution then
        Crosspaths:Message("Class Distribution:")
        local sortedClasses = {}
        for class, count in pairs(progression.classDistribution) do
            table.insert(sortedClasses, {class = class, count = count})
        end
        table.sort(sortedClasses, function(a, b) return a.count > b.count end)

        for i, classData in ipairs(sortedClasses) do
            if i <= 5 then
                Crosspaths:Message(string.format("  %d. %s - %d players", i, classData.class, classData.count))
            end
        end
    end

    -- Top guilds by progression
    if progression.guildProgression then
        local sortedGuilds = {}
        for guildName, data in pairs(progression.guildProgression) do
            table.insert(sortedGuilds, {
                name = guildName,
                members = data.memberCount,
                avgLevel = data.averageLevel,
                activity = data.encountersPerMember
            })
        end
        table.sort(sortedGuilds, function(a, b) return a.avgLevel > b.avgLevel end)

        if #sortedGuilds > 0 then
            Crosspaths:Message("Top Guilds by Average Level:")
            for i, guild in ipairs(sortedGuilds) do
                if i <= 5 then
                    Crosspaths:Message(string.format("  %d. %s - %.1f avg level (%d members)",
                        i, guild.name, guild.avgLevel, guild.members))
                end
            end
        end
    end
end

-- Show quest line and path analysis
function UI:ShowQuestLineAnalysis(patterns)
    if not patterns then
        Crosspaths:Message("No quest line patterns found.")
        return
    end

    Crosspaths:Message("Quest Line & Path Analysis")
    Crosspaths:Message("==========================")

    -- Show common quest paths
    if patterns.commonPaths and #patterns.commonPaths > 0 then
        Crosspaths:Message("Most Common Quest Paths:")
        for i, path in ipairs(patterns.commonPaths) do
            if i <= 5 then
                Crosspaths:Message(string.format("  %d. %s (%d players, %.1f%% likelihood)",
                    i, path.path, path.playerCount, path.likelihood))
            end
        end
        Crosspaths:Message("")
    end

    -- Show zone correlations
    if patterns.questLineCorrelations and #patterns.questLineCorrelations > 0 then
        Crosspaths:Message("Strong Zone Progression Correlations:")
        for i, correlation in ipairs(patterns.questLineCorrelations) do
            if i <= 8 then
                Crosspaths:Message(string.format("  %s → %s (%d players, %.1f%% strength)",
                    correlation.fromZone, correlation.toZone, correlation.playerCount, correlation.strength))
            end
        end
    end

    if (#patterns.commonPaths == 0) and (#patterns.questLineCorrelations == 0) then
        Crosspaths:Message("No significant quest line patterns detected. Need more data or longer observation period.")
    end
end

-- Show similar quest lines for a player
function UI:ShowSimilarQuestLines(playerName, similar)
    if not similar then
        Crosspaths:Message("Unable to analyze quest lines for " .. playerName)
        return
    end

    Crosspaths:Message("Similar Quest Lines for " .. playerName)
    Crosspaths:Message("=====================================")

    -- Show player's path
    if similar.targetPlayerPath and #similar.targetPlayerPath > 0 then
        local pathStr = ""
        for i, step in ipairs(similar.targetPlayerPath) do
            if i <= 6 then -- Show first 6 zones
                pathStr = pathStr .. (i > 1 and " → " or "") .. step.zone
            end
        end
        Crosspaths:Message("Player's Path: " .. pathStr)
        Crosspaths:Message("")
    end

    -- Show similar players
    if similar.similarPlayers and #similar.similarPlayers > 0 then
        Crosspaths:Message(string.format("Found %d players with similar quest paths (%.1f%% confidence):",
            #similar.similarPlayers, similar.confidence * 100))

        for i, player in ipairs(similar.similarPlayers) do
            if i <= 8 then
                local sharedZonesStr = ""
                if player.sharedZones and #player.sharedZones > 0 then
                    sharedZonesStr = " (shared: " .. table.concat(player.sharedZones, ", ", 1, 3)
                    if #player.sharedZones > 3 then
                        sharedZonesStr = sharedZonesStr .. "..."
                    end
                    sharedZonesStr = sharedZonesStr .. ")"
                end

                local levelStr = player.level and ("L" .. player.level) or "L?"
                local classStr = player.class or "Unknown"

                Crosspaths:Message(string.format("  %d. %s (%s %s) - %.1f%% similar%s",
                    i, player.name, levelStr, classStr, player.similarity * 100, sharedZonesStr))
            end
        end
    else
        Crosspaths:Message("No players found with similar quest line patterns.")
        Crosspaths:Message("This could indicate a unique leveling path or insufficient data.")
    end
end

-- Show zone insights
function UI:ShowZoneInsights(zoneName, insights)
    if not insights then
        Crosspaths:Message("No insights available for " .. zoneName)
        return
    end

    Crosspaths:Message("Quest Line Insights: " .. zoneName)
    Crosspaths:Message("====================================")

    -- Basic stats
    Crosspaths:Message(string.format("Total Visitors: %d", insights.totalVisitors))

    if insights.averageTimeSpent > 0 then
        local timeStr = ""
        if insights.averageTimeSpent >= 3600 then
            timeStr = string.format("%.1f hours", insights.averageTimeSpent / 3600)
        elseif insights.averageTimeSpent >= 60 then
            timeStr = string.format("%.1f minutes", insights.averageTimeSpent / 60)
        else
            timeStr = string.format("%.0f seconds", insights.averageTimeSpent)
        end
        Crosspaths:Message("Average Time Spent: " .. timeStr)
    end

    if insights.levelRange.min > 0 and insights.levelRange.max > 0 then
        Crosspaths:Message(string.format("Level Range: %d - %d", insights.levelRange.min, insights.levelRange.max))
    end

    Crosspaths:Message("")

    -- Progression patterns
    if insights.progressionFrom and #insights.progressionFrom > 0 then
        Crosspaths:Message("Players typically come from:")
        for i, from in ipairs(insights.progressionFrom) do
            if i <= 3 then
                Crosspaths:Message(string.format("  %d. %s (%d players)", i, from.zone, from.count))
            end
        end
        Crosspaths:Message("")
    end

    if insights.progressionTo and #insights.progressionTo > 0 then
        Crosspaths:Message("Players typically go to:")
        for i, to in ipairs(insights.progressionTo) do
            if i <= 3 then
                Crosspaths:Message(string.format("  %d. %s (%d players)", i, to.zone, to.count))
            end
        end
        Crosspaths:Message("")
    end

    -- Peak activity hours
    if insights.peakHours and #insights.peakHours > 0 then
        Crosspaths:Message("Peak Activity Hours:")
        for i, hour in ipairs(insights.peakHours) do
            if i <= 3 then
                local timeStr = string.format("%02d:00-%02d:59", hour.hour, hour.hour)
                Crosspaths:Message(string.format("  %s (%d encounters)", timeStr, hour.count))
            end
        end
    end

    if insights.totalVisitors == 0 then
        Crosspaths:Message("No recent activity in this zone. Try a different zone name or check spelling.")
    end
end