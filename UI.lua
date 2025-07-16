-- Crosspaths UI.lua
-- Main user interface, tabs, and notifications

local addonName, Crosspaths = ...

Crosspaths.UI = {}
local UI = Crosspaths.UI

-- Design tokens for consistent styling
local DesignTokens = {
    colors = {
        primary = {0.2, 0.4, 0.8, 0.95},      -- Blue accent
        secondary = {0.4, 0.4, 0.4, 0.9},    -- Medium gray
        success = {0.2, 0.8, 0.2, 0.9},      -- Green
        warning = {1.0, 0.8, 0.2, 0.9},      -- Yellow
        error = {0.8, 0.2, 0.2, 0.9},        -- Red
        info = {0.4, 0.8, 1.0, 0.9},         -- Light blue
        background = {0.1, 0.1, 0.1, 0.9},   -- Dark background
        surface = {0.2, 0.2, 0.2, 0.9},      -- Surface
        border = {0.6, 0.6, 0.6, 0.8},       -- Border
        text = {1.0, 1.0, 1.0, 1.0},         -- White text
        textSecondary = {0.8, 0.8, 0.8, 1.0}, -- Light gray text
        textMuted = {0.5, 0.5, 0.5, 1.0},    -- Muted text
    },
    fonts = {
        title = "GameFontNormalLarge",
        header = "GameFontHighlight", 
        body = "GameFontNormal",
        small = "GameFontNormalSmall",
        tooltip = "GameTooltipText",
    },
    spacing = {
        xs = 4,
        sm = 8,
        md = 12,
        lg = 16,
        xl = 24,
        xxl = 32,
    },
    sizes = {
        tabHeight = 32,
        buttonHeight = 28,
        inputHeight = 24,
        iconSize = 16,
        notificationWidth = 320,
        notificationHeight = 80,
    }
}

-- Initialize UI
function UI:Initialize()
    self.mainFrame = nil
    self.toastFrames = {}
    self.notificationQueue = {}
    self.currentTab = "summary"
    self.keyboardFocus = nil
    self.searchDebounceTimer = nil
    
    -- Create slash commands
    self:RegisterSlashCommands()
    
    -- Initialize tooltip system
    self:InitializeTooltips()
    
    -- Initialize notification system
    self:InitializeNotificationSystem()
    
    Crosspaths:DebugLog("UI initialized with enhanced design", "INFO")
end

-- Initialize enhanced notification system
function UI:InitializeNotificationSystem()
    self.notificationTypes = {
        success = {color = DesignTokens.colors.success, icon = "✓", sound = SOUNDKIT.ACHIEVEMENT_MENU_OPEN},
        warning = {color = DesignTokens.colors.warning, icon = "⚠", sound = SOUNDKIT.IG_PLAYER_INVITE},
        error = {color = DesignTokens.colors.error, icon = "✗", sound = SOUNDKIT.IG_PLAYER_INVITE_DECLINE},
        info = {color = DesignTokens.colors.info, icon = "ℹ", sound = SOUNDKIT.IG_CHAT_EMOTE_BUTTON},
    }
    
    -- Start notification queue processor
    self:StartNotificationProcessor()
end

-- Start notification queue processor
function UI:StartNotificationProcessor()
    local function processQueue()
        if #self.notificationQueue > 0 then
            local notification = table.remove(self.notificationQueue, 1)
            self:DisplayNotification(notification)
        end
        C_Timer.After(0.5, processQueue) -- Process every 0.5 seconds
    end
    processQueue()
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
    elseif command == "status" then
        self:ShowStatus()
    elseif command == "help" then
        self:ShowHelp()
    else
        self:ShowHelp()
    end
end

-- Show main UI with enhanced design
function UI:Show()
    if not self.mainFrame then
        self:CreateMainFrame()
    end
    
    self.mainFrame:Show()
    self:RefreshCurrentTab()
    
    -- Focus management
    self:SetInitialFocus()
    
    -- Play opening sound
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
end

-- Hide main UI
function UI:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
    
    -- Play closing sound
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
end

-- Toggle main UI
function UI:Toggle()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Set initial keyboard focus
function UI:SetInitialFocus()
    -- Focus on the currently selected tab
    if self.mainFrame and self.mainFrame.tabs and self.mainFrame.tabs[self.currentTab] then
        self:SetKeyboardFocus(self.mainFrame.tabs[self.currentTab])
    end
end

-- Handle global keyboard navigation
function UI:HandleGlobalKeyDown(key)
    if not self.mainFrame or not self.mainFrame:IsShown() then
        return
    end
    
    if key == "TAB" then
        if IsShiftKeyDown() then
            self:NavigateFocusPrevious()
        else
            self:NavigateFocusNext()
        end
    elseif key == "ESCAPE" then
        self:Hide()
    elseif key == "SPACE" or key == "ENTER" then
        if self.keyboardFocus and self.keyboardFocus.OnClick then
            self.keyboardFocus:OnClick()
        end
    elseif tonumber(key) and tonumber(key) >= 1 and tonumber(key) <= 5 then
        -- Number keys 1-5 for quick tab switching
        local tabIds = {"summary", "players", "guilds", "advanced", "encounters"}
        local tabId = tabIds[tonumber(key)]
        if tabId then
            self:SelectTab(tabId)
        end
    end
end

-- Navigate focus to next element
function UI:NavigateFocusNext()
    -- Simple implementation - cycle through tabs
    local tabOrder = {"summary", "players", "guilds", "advanced", "encounters"}
    local currentIndex = 1
    
    for i, tabId in ipairs(tabOrder) do
        if tabId == self.currentTab then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = (currentIndex % #tabOrder) + 1
    local nextTab = tabOrder[nextIndex]
    
    if self.mainFrame.tabs[nextTab] then
        self:SetKeyboardFocus(self.mainFrame.tabs[nextTab])
        self:SelectTab(nextTab)
    end
end

-- Navigate focus to previous element
function UI:NavigateFocusPrevious()
    local tabOrder = {"summary", "players", "guilds", "advanced", "encounters"}
    local currentIndex = 1
    
    for i, tabId in ipairs(tabOrder) do
        if tabId == self.currentTab then
            currentIndex = i
            break
        end
    end
    
    local prevIndex = currentIndex - 1
    if prevIndex < 1 then
        prevIndex = #tabOrder
    end
    local prevTab = tabOrder[prevIndex]
    
    if self.mainFrame.tabs[prevTab] then
        self:SetKeyboardFocus(self.mainFrame.tabs[prevTab])
        self:SelectTab(prevTab)
    end
end

-- Set keyboard focus with visual indicator
function UI:SetKeyboardFocus(element)
    -- Remove focus from previous element
    if self.keyboardFocus and self.keyboardFocus.focusIndicator then
        self.keyboardFocus.focusIndicator:Hide()
    end
    
    self.keyboardFocus = element
    
    -- Add focus indicator to new element
    if element then
        if not element.focusIndicator then
            element.focusIndicator = element:CreateTexture(nil, "OVERLAY")
            element.focusIndicator:SetAllPoints()
            element.focusIndicator:SetColorTexture(unpack(DesignTokens.colors.primary))
            element.focusIndicator:SetAlpha(0.3)
        end
        element.focusIndicator:Show()
    end
end

-- Create main frame with enhanced design
function UI:CreateMainFrame()
    local frame = CreateFrame("Frame", "CrosspathsMainFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(650, 450) -- Slightly larger for better content display
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true) -- Prevent dragging off-screen
    
    -- Enhanced styling
    frame:SetBackdropColor(unpack(DesignTokens.colors.background))
    frame:SetBackdropBorderColor(unpack(DesignTokens.colors.border))
    
    -- Accessibility attributes
    frame:SetAttribute("aria-label", "Crosspaths Social Memory Tracker Interface")
    frame:SetAttribute("role", "dialog")
    
    -- Title with improved styling
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject(DesignTokens.fonts.title)
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", DesignTokens.spacing.sm, 0)
    frame.title:SetText("Crosspaths - Social Memory Tracker")
    frame.title:SetTextColor(unpack(DesignTokens.colors.text))
    
    -- Close button accessibility
    if frame.CloseButton then
        frame.CloseButton:SetAttribute("aria-label", "Close Crosspaths interface")
        frame.CloseButton:HookScript("OnClick", function()
            self:Hide()
        end)
    end
    
    -- Tab buttons with enhanced accessibility
    self:CreateTabButtons(frame)
    
    -- Content area with loading state support
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", DesignTokens.spacing.sm, -70)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -DesignTokens.spacing.sm, DesignTokens.spacing.sm)
    frame.content:SetAttribute("aria-live", "polite") -- Announce content changes
    
    -- Loading indicator
    frame.loadingIndicator = self:CreateLoadingIndicator(frame.content)
    
    -- Error display
    frame.errorDisplay = self:CreateErrorDisplay(frame.content)
    
    self.mainFrame = frame
    
    -- Create tab content frames
    self:CreateTabContent()
    
    -- Set up resize functionality
    self:SetupResizing(frame)
end

-- Create loading indicator
function UI:CreateLoadingIndicator(parent)
    local loading = CreateFrame("Frame", nil, parent)
    loading:SetAllPoints()
    loading:Hide()
    
    -- Background
    loading.bg = loading:CreateTexture(nil, "BACKGROUND")
    loading.bg:SetAllPoints()
    loading.bg:SetColorTexture(unpack(DesignTokens.colors.background))
    loading.bg:SetAlpha(0.8)
    
    -- Spinner (using text for simplicity)
    loading.spinner = loading:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.title)
    loading.spinner:SetPoint("CENTER")
    loading.spinner:SetText("Loading...")
    loading.spinner:SetTextColor(unpack(DesignTokens.colors.text))
    
    -- Animate spinner
    local rotation = 0
    loading.animTimer = C_Timer.NewTicker(0.1, function()
        if loading:IsShown() then
            rotation = rotation + 10
            local dots = string.rep(".", (math.floor(rotation / 30) % 3) + 1)
            loading.spinner:SetText("Loading" .. dots)
        end
    end)
    
    return loading
end

-- Create error display
function UI:CreateErrorDisplay(parent)
    local error = CreateFrame("Frame", nil, parent)
    error:SetAllPoints()
    error:Hide()
    
    -- Background
    error.bg = error:CreateTexture(nil, "BACKGROUND")
    error.bg:SetAllPoints()
    error.bg:SetColorTexture(unpack(DesignTokens.colors.error))
    error.bg:SetAlpha(0.2)
    
    -- Error icon and text
    error.icon = error:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.title)
    error.icon:SetPoint("CENTER", 0, DesignTokens.spacing.md)
    error.icon:SetText("⚠")
    error.icon:SetTextColor(unpack(DesignTokens.colors.error))
    
    error.text = error:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
    error.text:SetPoint("TOP", error.icon, "BOTTOM", 0, -DesignTokens.spacing.sm)
    error.text:SetTextColor(unpack(DesignTokens.colors.text))
    error.text:SetJustifyH("CENTER")
    error.text:SetWidth(parent:GetWidth() - DesignTokens.spacing.xl)
    
    -- Retry button
    error.retryBtn = CreateFrame("Button", nil, error, "UIPanelButtonTemplate")
    error.retryBtn:SetSize(100, DesignTokens.sizes.buttonHeight)
    error.retryBtn:SetPoint("TOP", error.text, "BOTTOM", 0, -DesignTokens.spacing.md)
    error.retryBtn:SetText("Retry")
    error.retryBtn:SetScript("OnClick", function()
        error:Hide()
        UI:RefreshCurrentTab()
    end)
    
    return error
end

-- Set up window resizing
function UI:SetupResizing(frame)
    -- Add resize handle
    local resizeBtn = CreateFrame("Button", nil, frame)
    resizeBtn:SetPoint("BOTTOMRIGHT", -DesignTokens.spacing.xs, DesignTokens.spacing.xs)
    resizeBtn:SetSize(DesignTokens.sizes.iconSize, DesignTokens.sizes.iconSize)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    resizeBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    
    resizeBtn:SetScript("OnMouseUp", function(self, button)
        frame:StopMovingOrSizing()
        -- Save size to settings
        if Crosspaths.db and Crosspaths.db.settings.ui then
            Crosspaths.db.settings.ui.width = frame:GetWidth()
            Crosspaths.db.settings.ui.height = frame:GetHeight()
        end
    end)
    
    frame:SetResizable(true)
    frame:SetMinResize(500, 350)
    frame:SetMaxResize(1000, 800)
end

-- Show loading state
function UI:ShowLoading(show, message)
    if not self.mainFrame then return end
    
    local loading = self.mainFrame.loadingIndicator
    if show then
        if message then
            loading.spinner:SetText(message)
        end
        loading:Show()
    else
        loading:Hide()
    end
end

-- Show error state
function UI:ShowError(message, canRetry)
    if not self.mainFrame then return end
    
    local error = self.mainFrame.errorDisplay
    error.text:SetText(message or "An error occurred")
    error.retryBtn:SetShown(canRetry ~= false)
    error:Show()
    
end

-- Hide error state
function UI:HideError()
    if self.mainFrame and self.mainFrame.errorDisplay then
        self.mainFrame.errorDisplay:Hide()
    end
end

-- Create tab buttons with enhanced accessibility and modern design
function UI:CreateTabButtons(parent)
    local tabs = {
        {id = "summary", text = "Summary", tooltip = "View overall statistics and summary", icon = "📊", hotkey = "1"},
        {id = "players", text = "Players", tooltip = "Browse and search tracked players", icon = "👥", hotkey = "2"},
        {id = "guilds", text = "Guilds", tooltip = "View guild statistics and members", icon = "🏛", hotkey = "3"},
        {id = "advanced", text = "Advanced", tooltip = "View advanced role-based and performance statistics", icon = "📈", hotkey = "4"},
        {id = "encounters", text = "Encounters", tooltip = "Browse encounter history by zone", icon = "🌍", hotkey = "5"},
    }
    
    parent.tabs = {}
    parent.tabContainer = CreateFrame("Frame", nil, parent)
    parent.tabContainer:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", DesignTokens.spacing.sm, DesignTokens.sizes.tabHeight + DesignTokens.spacing.xs)
    parent.tabContainer:SetSize(parent:GetWidth() - (DesignTokens.spacing.sm * 2), DesignTokens.sizes.tabHeight)
    
    -- Calculate tab width dynamically
    local availableWidth = parent.tabContainer:GetWidth() - (#tabs - 1) * DesignTokens.spacing.xs
    local tabWidth = availableWidth / #tabs
    
    for i, tab in ipairs(tabs) do
        local button = self:CreateTabButton(parent.tabContainer, i, tab, tabWidth)
        parent.tabs[tab.id] = button
    end
    
    -- Select first tab by default
    self:SelectTab("summary")
end

-- Create individual tab button with modern styling and accessibility
function UI:CreateTabButton(parent, index, tabData, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetID(index)
    button:SetSize(width, DesignTokens.sizes.tabHeight)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", (index-1) * (width + DesignTokens.spacing.xs), 0)
    
    -- Modern tab styling
    self:StyleTabButton(button, tabData)
    
    -- Enhanced tooltip with hotkey information
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tabData.tooltip, 1, 1, 1, 1, true)
        GameTooltip:AddLine("Hotkey: " .. tabData.hotkey, 0.7, 0.7, 0.7, true)
        if index > 1 then
            GameTooltip:AddLine("Use Tab/Shift+Tab to navigate", 0.5, 0.5, 0.5, true)
        end
        GameTooltip:Show()
        
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Tab selection with enhanced feedback
    button:SetScript("OnClick", function()
        UI:SelectTab(tabData.id)
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    end)
    
    -- Keyboard interaction
    button:SetScript("OnKeyDown", function(self, key)
        if key == "SPACE" or key == "ENTER" then
            self:Click()
        end
    end)
    
    -- Store tab data
    button.tabId = tabData.id
    button.tabData = tabData
    button.isChecked = false
    
    return button
end

-- Apply modern styling to tab buttons with enhanced visual design
function UI:StyleTabButton(button, tabData)
    -- Create background textures with smooth gradients
    local normalTexture = button:CreateTexture(nil, "BACKGROUND")
    normalTexture:SetAllPoints()
    normalTexture:SetColorTexture(unpack(DesignTokens.colors.surface))
    button:SetNormalTexture(normalTexture)
    
    local hoverTexture = button:CreateTexture(nil, "HIGHLIGHT")
    hoverTexture:SetAllPoints()
    hoverTexture:SetColorTexture(0.3, 0.3, 0.3, 0.9) -- Lighter on hover
    button:SetHighlightTexture(hoverTexture)
    
    local pushedTexture = button:CreateTexture(nil, "ARTWORK") 
    pushedTexture:SetAllPoints()
    pushedTexture:SetColorTexture(0.15, 0.15, 0.15, 0.9)
    button:SetPushedTexture(pushedTexture)
    
    -- Border with modern styling
    local border = button:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    border:SetColorTexture(unpack(DesignTokens.colors.border))
    
    -- Selected state with accent color
    local checkedTexture = button:CreateTexture(nil, "ARTWORK")
    checkedTexture:SetAllPoints()
    checkedTexture:SetColorTexture(unpack(DesignTokens.colors.primary))
    checkedTexture:Hide()
    
    -- Icon and text layout
    if tabData.icon then
        button.icon = button:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
        button.icon:SetPoint("LEFT", button, "LEFT", DesignTokens.spacing.sm, 0)
        button.icon:SetText(tabData.icon)
        button.icon:SetTextColor(unpack(DesignTokens.colors.text))
        
        button.text = button:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
        button.text:SetPoint("LEFT", button.icon, "RIGHT", DesignTokens.spacing.xs, 0)
        button.text:SetText(tabData.text)
        button.text:SetTextColor(unpack(DesignTokens.colors.text))
    else
        button.text = button:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
        button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.text:SetText(tabData.text)
        button.text:SetTextColor(unpack(DesignTokens.colors.text))
    end
    
    -- Hotkey indicator
    button.hotkey = button:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.small)
    button.hotkey:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -DesignTokens.spacing.xs, DesignTokens.spacing.xs)
    button.hotkey:SetText(tabData.hotkey)
    button.hotkey:SetTextColor(unpack(DesignTokens.colors.textMuted))
    button.hotkey:SetAlpha(0.7)
    
    -- Store textures for state management
    button.normalTexture = normalTexture
    button.checkedTexture = checkedTexture
    button.borderTexture = border
    
    -- Enhanced checked state with animation
    function button:SetChecked(checked)
        self.isChecked = checked
        if checked then
            self.checkedTexture:Show()
            self.borderTexture:SetColorTexture(1.0, 1.0, 1.0, 1.0) -- Bright border
            if self.text then
                self.text:SetTextColor(1, 1, 1, 1) -- Bright text
            end
            if self.icon then
                self.icon:SetTextColor(1, 1, 1, 1)
            end
            -- Subtle glow effect
            UIFrameFadeIn(self.checkedTexture, 0.15, 0.8, 1.0)
        else
            self.checkedTexture:Hide()
            self.borderTexture:SetColorTexture(unpack(DesignTokens.colors.border))
            if self.text then
                self.text:SetTextColor(unpack(DesignTokens.colors.text))
            end
            if self.icon then
                self.icon:SetTextColor(unpack(DesignTokens.colors.text))
            end
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

-- Create players tab with enhanced search and filtering
function UI:CreatePlayersTab()
    local frame = CreateFrame("Frame", nil, self.mainFrame.content)
    frame:SetAllPoints()
    
    -- Search and filter container
    local searchContainer = CreateFrame("Frame", nil, frame)
    searchContainer:SetHeight(60)
    searchContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    searchContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    
    -- Enhanced search box with icon
    local searchIcon = searchContainer:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
    searchIcon:SetPoint("TOPLEFT", searchContainer, "TOPLEFT", DesignTokens.spacing.sm, -DesignTokens.spacing.sm)
    searchIcon:SetText("🔍")
    searchIcon:SetTextColor(unpack(DesignTokens.colors.textMuted))
    
    local searchBox = CreateFrame("EditBox", nil, searchContainer, "InputBoxTemplate")
    searchBox:SetSize(200, DesignTokens.sizes.inputHeight)
    searchBox:SetPoint("LEFT", searchIcon, "RIGHT", DesignTokens.spacing.xs, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetAttribute("aria-label", "Search players by name, guild, class, or level")
    
    -- Placeholder text
    searchBox.placeholder = searchBox:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
    searchBox.placeholder:SetPoint("LEFT", searchBox, "LEFT", 5, 0)
    searchBox.placeholder:SetText("Search players...")
    searchBox.placeholder:SetTextColor(unpack(DesignTokens.colors.textMuted))
    searchBox.placeholder:SetAlpha(0.7)
    
    -- Enhanced search with debouncing
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        self.placeholder:SetShown(text == "")
        
        -- Cancel previous search timer
        if UI.searchDebounceTimer then
            UI.searchDebounceTimer:Cancel()
        end
        
        -- Debounced search
        UI.searchDebounceTimer = C_Timer.NewTimer(0.3, function()
            UI:PerformSearch(text, frame)
        end)
    end)
    
    searchBox:SetScript("OnEnterPressed", function(self)
        UI:PerformSearch(self:GetText(), frame)
        self:ClearFocus()
    end)
    
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        UI:PerformSearch("", frame)
    end)
    
    -- Filter dropdown
    local filterLabel = searchContainer:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
    filterLabel:SetPoint("LEFT", searchBox, "RIGHT", DesignTokens.spacing.md, 0)
    filterLabel:SetText("Filter:")
    filterLabel:SetTextColor(unpack(DesignTokens.colors.text))
    
    local filterDropdown = CreateFrame("Frame", nil, searchContainer, "UIDropDownMenuTemplate")
    filterDropdown:SetPoint("LEFT", filterLabel, "RIGHT", DesignTokens.spacing.xs, 0)
    UIDropDownMenu_SetWidth(filterDropdown, 100)
    UIDropDownMenu_SetText(filterDropdown, "All Players")
    
    local function filterDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local filters = {
            {text = "All Players", value = "all"},
            {text = "Grouped Only", value = "grouped"},
            {text = "Guild Members", value = "guild"},
            {text = "High Level (70+)", value = "highlevel"},
            {text = "Recent (7 days)", value = "recent"},
        }
        
        for _, filter in ipairs(filters) do
            info.text = filter.text
            info.value = filter.value
            info.func = function()
                UIDropDownMenu_SetSelectedValue(filterDropdown, filter.value)
                UIDropDownMenu_SetText(filterDropdown, filter.text)
                UI:ApplyPlayerFilter(filter.value, frame)
            end
            info.checked = (UIDropDownMenu_GetSelectedValue(filterDropdown) == filter.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(filterDropdown, filterDropdown_Initialize)
    UIDropDownMenu_SetSelectedValue(filterDropdown, "all")
    
    -- Sort dropdown
    local sortLabel = searchContainer:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
    sortLabel:SetPoint("LEFT", filterDropdown, "RIGHT", DesignTokens.spacing.md, 0)
    sortLabel:SetText("Sort:")
    sortLabel:SetTextColor(unpack(DesignTokens.colors.text))
    
    local sortDropdown = CreateFrame("Frame", nil, searchContainer, "UIDropDownMenuTemplate")
    sortDropdown:SetPoint("LEFT", sortLabel, "RIGHT", DesignTokens.spacing.xs, 0)
    UIDropDownMenu_SetWidth(sortDropdown, 120)
    UIDropDownMenu_SetText(sortDropdown, "Most Encounters")
    
    local function sortDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local sorts = {
            {text = "Most Encounters", value = "encounters"},
            {text = "Alphabetical", value = "name"},
            {text = "Recent First", value = "recent"},
            {text = "Level (High-Low)", value = "level"},
            {text = "Item Level", value = "itemlevel"},
        }
        
        for _, sort in ipairs(sorts) do
            info.text = sort.text
            info.value = sort.value
            info.func = function()
                UIDropDownMenu_SetSelectedValue(sortDropdown, sort.value)
                UIDropDownMenu_SetText(sortDropdown, sort.text)
                UI:ApplyPlayerSort(sort.value, frame)
            end
            info.checked = (UIDropDownMenu_GetSelectedValue(sortDropdown) == sort.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(sortDropdown, sortDropdown_Initialize)
    UIDropDownMenu_SetSelectedValue(sortDropdown, "encounters")
    
    -- Results container with scroll
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchContainer, "BOTTOMLEFT", 0, -DesignTokens.spacing.sm)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 0)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1) -- Will be adjusted dynamically
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Results display
    scrollChild.resultsText = scrollChild:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
    scrollChild.resultsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", DesignTokens.spacing.sm, -DesignTokens.spacing.sm)
    scrollChild.resultsText:SetWidth(scrollChild:GetWidth() - DesignTokens.spacing.md)
    scrollChild.resultsText:SetJustifyH("LEFT")
    scrollChild.resultsText:SetJustifyV("TOP")
    scrollChild.resultsText:SetText("Loading players...")
    scrollChild.resultsText:SetTextColor(unpack(DesignTokens.colors.text))
    
    -- Results summary
    local summaryText = searchContainer:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.small)
    summaryText:SetPoint("TOPLEFT", searchContainer, "BOTTOMLEFT", DesignTokens.spacing.sm, 0)
    summaryText:SetTextColor(unpack(DesignTokens.colors.textMuted))
    
    -- Store references
    frame.searchBox = searchBox
    frame.filterDropdown = filterDropdown
    frame.sortDropdown = sortDropdown
    frame.resultsText = scrollChild.resultsText
    frame.scrollChild = scrollChild
    frame.summaryText = summaryText
    frame.currentFilter = "all"
    frame.currentSort = "encounters"
    frame.currentSearch = ""
    
    return frame
end

-- Perform search with enhanced functionality
function UI:PerformSearch(query, frame)
    if not frame then return end
    
    frame.currentSearch = query or ""
    
    -- Show loading state
    frame.resultsText:SetText("Searching...")
    frame.resultsText:SetTextColor(unpack(DesignTokens.colors.textMuted))
    
    -- Perform search asynchronously to avoid UI freezing
    C_Timer.After(0.1, function()
        local results = self:GetFilteredPlayers(frame.currentSearch, frame.currentFilter, frame.currentSort)
        self:DisplayPlayerResults(results, frame)
    end)
end

-- Apply player filter
function UI:ApplyPlayerFilter(filterType, frame)
    frame.currentFilter = filterType
    self:PerformSearch(frame.currentSearch, frame)
end

-- Apply player sort
function UI:ApplyPlayerSort(sortType, frame)
    frame.currentSort = sortType
    self:PerformSearch(frame.currentSearch, frame)
end

-- Get filtered and sorted players
function UI:GetFilteredPlayers(query, filter, sort)
    if not Crosspaths.Engine then
        return {}
    end
    
    local allPlayers = Crosspaths.Engine:GetTopPlayers(1000) -- Get more for filtering
    local filtered = {}
    
    -- Apply search query
    if query and query ~= "" then
        local lowerQuery = string.lower(query)
        for _, player in ipairs(allPlayers) do
            local playerName = string.lower(player.name or "")
            local playerGuild = string.lower(player.guild or "")
            local playerClass = string.lower(player.class or "")
            local playerLevel = tostring(player.level or 0)
            
            if string.find(playerName, lowerQuery) or 
               string.find(playerGuild, lowerQuery) or
               string.find(playerClass, lowerQuery) or
               string.find(playerLevel, lowerQuery) then
                table.insert(filtered, player)
            end
        end
    else
        filtered = allPlayers
    end
    
    -- Apply filter
    if filter == "grouped" then
        local groupedOnly = {}
        for _, player in ipairs(filtered) do
            if player.grouped then
                table.insert(groupedOnly, player)
            end
        end
        filtered = groupedOnly
    elseif filter == "guild" then
        local guildOnly = {}
        for _, player in ipairs(filtered) do
            if player.guild and player.guild ~= "" then
                table.insert(guildOnly, player)
            end
        end
        filtered = guildOnly
    elseif filter == "highlevel" then
        local highlevelOnly = {}
        for _, player in ipairs(filtered) do
            if player.level and player.level >= 70 then
                table.insert(highlevelOnly, player)
            end
        end
        filtered = highlevelOnly
    elseif filter == "recent" then
        local recentOnly = {}
        local weekAgo = time() - (7 * 24 * 60 * 60)
        for _, player in ipairs(filtered) do
            if player.lastSeen and player.lastSeen >= weekAgo then
                table.insert(recentOnly, player)
            end
        end
        filtered = recentOnly
    end
    
    -- Apply sort
    if sort == "name" then
        table.sort(filtered, function(a, b)
            return (a.name or "") < (b.name or "")
        end)
    elseif sort == "recent" then
        table.sort(filtered, function(a, b)
            return (a.lastSeen or 0) > (b.lastSeen or 0)
        end)
    elseif sort == "level" then
        table.sort(filtered, function(a, b)
            return (a.level or 0) > (b.level or 0)
        end)
    elseif sort == "itemlevel" then
        table.sort(filtered, function(a, b)
            return (a.itemLevel or 0) > (b.itemLevel or 0)
        end)
    else -- encounters (default)
        table.sort(filtered, function(a, b)
            return (a.count or 0) > (b.count or 0)
        end)
    end
    
    return filtered
end

-- Display player search results with enhanced formatting
function UI:DisplayPlayerResults(results, frame)
    if not frame or not frame.resultsText then return end
    
    local lines = {}
    local maxResults = 50 -- Limit for performance
    local displayCount = math.min(#results, maxResults)
    
    -- Color scheme for different elements
    local colors = {
        rank = DesignTokens.colors.textMuted,
        name = DesignTokens.colors.text,
        guild = {0.7, 0.7, 1.0, 1.0}, -- Light blue
        class = {1.0, 0.8, 0.4, 1.0}, -- Gold
        level = {0.4, 1.0, 0.4, 1.0}, -- Green
        encounters = {1.0, 1.0, 0.6, 1.0}, -- Light yellow
        grouped = DesignTokens.colors.success,
    }
    
    if displayCount == 0 then
        table.insert(lines, "|cFF888888No players found matching your criteria.|r")
    else
        for i = 1, displayCount do
            local player = results[i]
            local line = ""
            
            -- Rank
            line = line .. string.format("|cFF%02X%02X%02X%d.|r ", 
                colors.rank[1]*255, colors.rank[2]*255, colors.rank[3]*255, i)
            
            -- Name with color coding
            line = line .. string.format("|cFF%02X%02X%02X%s|r", 
                colors.name[1]*255, colors.name[2]*255, colors.name[3]*255, player.name)
            
            -- Grouped indicator
            if player.grouped then
                line = line .. string.format(" |cFF%02X%02X%02X★|r", 
                    colors.grouped[1]*255, colors.grouped[2]*255, colors.grouped[3]*255)
            end
            
            -- Guild
            if player.guild and player.guild ~= "" then
                line = line .. string.format(" |cFF%02X%02X%02X<%s>|r", 
                    colors.guild[1]*255, colors.guild[2]*255, colors.guild[3]*255, player.guild)
            end
            
            -- Class and Race
            if player.class and player.class ~= "" then
                local classText = player.class
                if player.race and player.race ~= "" then
                    classText = player.race .. " " .. player.class
                end
                line = line .. string.format(" |cFF%02X%02X%02X[%s]|r", 
                    colors.class[1]*255, colors.class[2]*255, colors.class[3]*255, classText)
            end
            
            -- Level
            if player.level and player.level > 0 then
                line = line .. string.format(" |cFF%02X%02X%02XL%d|r", 
                    colors.level[1]*255, colors.level[2]*255, colors.level[3]*255, player.level)
            end
            
            -- Item Level
            if player.itemLevel and player.itemLevel > 0 then
                line = line .. string.format(" |cFF%02X%02X%02XiL%d|r", 
                    colors.level[1]*255, colors.level[2]*255, colors.level[3]*255, player.itemLevel)
            end
            
            -- Encounters
            line = line .. string.format(" - |cFF%02X%02X%02X%d encounter%s|r", 
                colors.encounters[1]*255, colors.encounters[2]*255, colors.encounters[3]*255, 
                player.count, player.count == 1 and "" or "s")
            
            table.insert(lines, line)
        end
        
        if #results > maxResults then
            table.insert(lines, "")
            table.insert(lines, string.format("|cFF888888... and %d more (refine search to see all)|r", #results - maxResults))
        end
    end
    
    -- Update results
    frame.resultsText:SetText(table.concat(lines, "\n"))
    frame.resultsText:SetTextColor(unpack(DesignTokens.colors.text))
    
    -- Update summary
    if frame.summaryText then
        local summary = string.format("Showing %d of %d players", displayCount, #results)
        if frame.currentSearch ~= "" then
            summary = summary .. string.format(" (search: \"%s\")", frame.currentSearch)
        end
        frame.summaryText:SetText(summary)
    end
    
    -- Adjust scroll child height
    local textHeight = frame.resultsText:GetStringHeight()
    frame.scrollChild:SetHeight(math.max(textHeight + DesignTokens.spacing.md, 1))
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
    
    -- Encounter definition
    table.insert(lines, "|cFF80C0FFWhat are Encounters?|r")
    table.insert(lines, "  An encounter is recorded when you detect another player through:")
    table.insert(lines, "  • |cFFADD8E6Grouping|r (parties, raids)")
    table.insert(lines, "  • |cFFADD8E6Proximity|r (nameplates, mouseover)")
    table.insert(lines, "  • |cFFADD8E6Interaction|r (targeting, combat)")
    table.insert(lines, "  |cFF888888Note: Only 1 encounter per player per zone per session|r")
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
    table.insert(lines, "|cFF80C0FFEncounter Detection:|r")
    table.insert(lines, "  Encounters track when you detect other players in various ways:")
    table.insert(lines, "  • |cFFB0E0E6Party/Raid members|r, |cFFB0E0E6Nearby players|r, |cFFB0E0E6Target/Focus|r")
    table.insert(lines, "  • |cFFB0E0E6Mouseover interactions|r, |cFFB0E0E6Combat participants|r")
    table.insert(lines, "  Limited to 1 encounter per player per zone per session.")
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
    local frame = CreateFrame("Frame", nil, self.mainFrame.Inset)
    frame:SetAllPoints()
    frame:Hide()
    
    -- Main scroll frame for advanced statistics
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
    
    -- Text display for advanced stats
    frame.advancedText = scroll:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.advancedText:SetPoint("TOPLEFT", 0, 0)
    frame.advancedText:SetWidth(scroll:GetWidth() - 20)
    frame.advancedText:SetJustifyH("LEFT")
    frame.advancedText:SetJustifyV("TOP")
    frame.advancedText:SetText("Advanced statistics will appear here...")
    
    scroll:SetScrollChild(frame.advancedText)
    
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

-- Enhanced notification system with queue management and multiple types
function UI:ShowToast(title, message, notificationType, duration, actionButton)
    if not Crosspaths.db or not Crosspaths.db.settings.ui.showNotifications then
        return
    end
    
    notificationType = notificationType or "info"
    duration = duration or (Crosspaths.db.settings.ui.notificationDuration or 3)
    
    -- Add to queue instead of showing immediately
    local notification = {
        title = title,
        message = message,
        type = notificationType,
        duration = duration,
        actionButton = actionButton,
        timestamp = time()
    }
    
    table.insert(self.notificationQueue, notification)
end

-- Display notification from queue
function UI:DisplayNotification(notification)
    -- Limit number of active notifications
    local maxNotifications = 5
    local activeCount = 0
    
    for i = #self.toastFrames, 1, -1 do
        local toast = self.toastFrames[i]
        if toast and toast:IsShown() then
            activeCount = activeCount + 1
        else
            table.remove(self.toastFrames, i)
        end
    end
    
    if activeCount >= maxNotifications then
        -- Remove oldest notification
        if self.toastFrames[1] then
            self.toastFrames[1]:Hide()
            table.remove(self.toastFrames, 1)
        end
    end
    
    -- Calculate position
    local yOffset = -100 - (activeCount * (DesignTokens.sizes.notificationHeight + DesignTokens.spacing.sm))
    
    -- Create enhanced toast
    local toast = self:CreateEnhancedToast(notification, yOffset)
    table.insert(self.toastFrames, toast)
    
    -- Play notification sound
    local notificationInfo = self.notificationTypes[notification.type]
    if notificationInfo and notificationInfo.sound then
        PlaySound(notificationInfo.sound)
    end

-- Create enhanced toast notification
function UI:CreateEnhancedToast(notification, yOffset)
    local toast = CreateFrame("Frame", nil, UIParent)
    toast:SetSize(DesignTokens.sizes.notificationWidth, DesignTokens.sizes.notificationHeight)
    toast:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -DesignTokens.spacing.md, yOffset)
    toast:SetFrameStrata("TOOLTIP")
    
    -- Get notification type info
    local notificationInfo = self.notificationTypes[notification.type] or self.notificationTypes.info
    
    -- Background with type-specific color
    toast.bg = toast:CreateTexture(nil, "BACKGROUND")
    toast.bg:SetAllPoints()
    toast.bg:SetColorTexture(unpack(notificationInfo.color))
    toast.bg:SetAlpha(0.9)
    
    -- Border
    toast.border = toast:CreateTexture(nil, "BORDER")
    toast.border:SetPoint("TOPLEFT", toast, "TOPLEFT", 1, -1)
    toast.border:SetPoint("BOTTOMRIGHT", toast, "BOTTOMRIGHT", -1, 1)
    toast.border:SetColorTexture(1, 1, 1, 0.3)
    
    -- Icon
    toast.icon = toast:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.header)
    toast.icon:SetPoint("TOPLEFT", toast, "TOPLEFT", DesignTokens.spacing.sm, -DesignTokens.spacing.sm)
    toast.icon:SetText(notificationInfo.icon)
    toast.icon:SetTextColor(1, 1, 1, 1)
    
    -- Title
    toast.title = toast:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.body)
    toast.title:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", DesignTokens.spacing.xs, 0)
    toast.title:SetPoint("TOPRIGHT", toast, "TOPRIGHT", -DesignTokens.spacing.sm, -DesignTokens.spacing.sm)
    toast.title:SetText(notification.title or "")
    toast.title:SetTextColor(1, 1, 1, 1)
    toast.title:SetJustifyH("LEFT")
    
    -- Message
    if notification.message and notification.message ~= "" then
        toast.message = toast:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.small)
        toast.message:SetPoint("TOPLEFT", toast.title, "BOTTOMLEFT", 0, -DesignTokens.spacing.xs)
        toast.message:SetPoint("BOTTOMRIGHT", toast, "BOTTOMRIGHT", -DesignTokens.spacing.sm, DesignTokens.spacing.sm)
        toast.message:SetText(notification.message)
        toast.message:SetTextColor(0.9, 0.9, 0.9, 1)
        toast.message:SetJustifyH("LEFT")
        toast.message:SetJustifyV("TOP")
    end
    
    -- Close button
    toast.closeBtn = CreateFrame("Button", nil, toast)
    toast.closeBtn:SetSize(16, 16)
    toast.closeBtn:SetPoint("TOPRIGHT", toast, "TOPRIGHT", -DesignTokens.spacing.xs, -DesignTokens.spacing.xs)
    
    toast.closeBtn.text = toast.closeBtn:CreateFontString(nil, "OVERLAY", DesignTokens.fonts.small)
    toast.closeBtn.text:SetAllPoints()
    toast.closeBtn.text:SetText("✕")
    toast.closeBtn.text:SetTextColor(1, 1, 1, 0.7)
    
    toast.closeBtn:SetScript("OnClick", function()
        toast:Hide()
    end)
    
    toast.closeBtn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    
    toast.closeBtn:SetScript("OnLeave", function(self)
        self.text:SetTextColor(1, 1, 1, 0.7)
    end)
    
    -- Action button if provided
    if notification.actionButton then
        toast.actionBtn = CreateFrame("Button", nil, toast, "UIPanelButtonTemplate")
        toast.actionBtn:SetSize(60, 20)
        toast.actionBtn:SetPoint("BOTTOMRIGHT", toast, "BOTTOMRIGHT", -DesignTokens.spacing.sm, DesignTokens.spacing.sm)
        toast.actionBtn:SetText(notification.actionButton.text or "Action")
        
        if notification.actionButton.onClick then
            toast.actionBtn:SetScript("OnClick", function()
                notification.actionButton.onClick()
                toast:Hide()
            end)
        end
    end
    
    -- Slide in animation
    toast:SetAlpha(0)
    toast:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 50, yOffset) -- Start off-screen
    
    UIFrameFadeIn(toast, 0.3, 0, 1)
    toast:SetScript("OnUpdate", function(self, elapsed)
        local x, y = self:GetCenter()
        if x > UIParent:GetWidth() - DesignTokens.sizes.notificationWidth/2 - DesignTokens.spacing.md then
            self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 
                -DesignTokens.spacing.md - (UIParent:GetWidth() - DesignTokens.sizes.notificationWidth/2 - DesignTokens.spacing.md - x) * 0.1, yOffset)
        else
            self:SetScript("OnUpdate", nil)
        end
    end)
    
    -- Auto-hide with progress bar
    local progressBar = CreateFrame("StatusBar", nil, toast)
    progressBar:SetSize(toast:GetWidth() - DesignTokens.spacing.md, 2)
    progressBar:SetPoint("BOTTOM", toast, "BOTTOM", 0, 0)
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetStatusBarColor(1, 1, 1, 0.5)
    progressBar:SetMinMaxValues(0, notification.duration)
    progressBar:SetValue(notification.duration)
    
    local timeLeft = notification.duration
    local updateTimer = C_Timer.NewTicker(0.1, function()
        timeLeft = timeLeft - 0.1
        progressBar:SetValue(timeLeft)
        if timeLeft <= 0 then
            toast:Hide()
        end
    end)
    
    toast:SetScript("OnHide", function()
        if updateTimer then
            updateTimer:Cancel()
        end
    end)
    
    -- Mouse interaction pauses auto-hide
    toast:SetScript("OnEnter", function()
        if updateTimer then
            updateTimer:Cancel()
            updateTimer = nil
        end
        progressBar:Hide()
    end)
    
    toast:SetScript("OnLeave", function()
        if not updateTimer then
            updateTimer = C_Timer.NewTicker(0.1, function()
                timeLeft = timeLeft - 0.1
                progressBar:SetValue(timeLeft)
                if timeLeft <= 0 then
                    toast:Hide()
                end
            end)
            progressBar:Show()
        end
    end)
    
    return toast
end

-- Convenience methods for different notification types
function UI:ShowSuccessToast(title, message, duration)
    self:ShowToast(title, message, "success", duration)
end

function UI:ShowWarningToast(title, message, duration)
    self:ShowToast(title, message, "warning", duration)
end

function UI:ShowErrorToast(title, message, duration)
    self:ShowToast(title, message, "error", duration)
end

function UI:ShowInfoToast(title, message, duration)
    self:ShowToast(title, message, "info", duration)
end

-- Refresh players tab with enhanced functionality
function UI:RefreshPlayersTab()
    if not self.tabContent.players then
        return
    end
    
    local frame = self.tabContent.players
    
    -- If no search is active, show top players by default
    if not frame.currentSearch or frame.currentSearch == "" then
        local results = self:GetFilteredPlayers("", frame.currentFilter or "all", frame.currentSort or "encounters")
        self:DisplayPlayerResults(results, frame)
    else
        -- Refresh current search
        self:PerformSearch(frame.currentSearch, frame)
    end
end

-- Apply player filter
function UI:ApplyPlayerFilter(filterType, frame)
    frame.currentFilter = filterType
    self:PerformSearch(frame.currentSearch, frame)
end

-- Apply player sort
function UI:ApplyPlayerSort(sortType, frame)
    frame.currentSort = sortType
    self:PerformSearch(frame.currentSearch, frame)
end

-- Get filtered and sorted players
function UI:GetFilteredPlayers(query, filter, sort)
    if not Crosspaths.Engine then
        return {}
    end
    
    local allPlayers = Crosspaths.Engine:GetTopPlayers(1000) -- Get more for filtering
    local filtered = {}
    
    -- Apply search query
    if query and query ~= "" then
        local lowerQuery = string.lower(query)
        for _, player in ipairs(allPlayers) do
            local playerName = string.lower(player.name or "")
            local playerGuild = string.lower(player.guild or "")
            local playerClass = string.lower(player.class or "")
            local playerLevel = tostring(player.level or 0)
            
            if string.find(playerName, lowerQuery) or 
               string.find(playerGuild, lowerQuery) or
               string.find(playerClass, lowerQuery) or
               string.find(playerLevel, lowerQuery) then
                table.insert(filtered, player)
            end
        end
    else
        filtered = allPlayers
    end
    
    -- Apply filter
    if filter == "grouped" then
        local groupedOnly = {}
        for _, player in ipairs(filtered) do
            if player.grouped then
                table.insert(groupedOnly, player)
            end
        end
        filtered = groupedOnly
    elseif filter == "guild" then
        local guildOnly = {}
        for _, player in ipairs(filtered) do
            if player.guild and player.guild ~= "" then
                table.insert(guildOnly, player)
            end
        end
        filtered = guildOnly
    elseif filter == "highlevel" then
        local highlevelOnly = {}
        for _, player in ipairs(filtered) do
            if player.level and player.level >= 70 then
                table.insert(highlevelOnly, player)
            end
        end
        filtered = highlevelOnly
    elseif filter == "recent" then
        local recentOnly = {}
        local weekAgo = time() - (7 * 24 * 60 * 60)
        for _, player in ipairs(filtered) do
            if player.lastSeen and player.lastSeen >= weekAgo then
                table.insert(recentOnly, player)
            end
        end
        filtered = recentOnly
    end
    
    -- Apply sort
    if sort == "name" then
        table.sort(filtered, function(a, b)
            return (a.name or "") < (b.name or "")
        end)
    elseif sort == "recent" then
        table.sort(filtered, function(a, b)
            return (a.lastSeen or 0) > (b.lastSeen or 0)
        end)
    elseif sort == "level" then
        table.sort(filtered, function(a, b)
            return (a.level or 0) > (b.level or 0)
        end)
    elseif sort == "itemlevel" then
        table.sort(filtered, function(a, b)
            return (a.itemLevel or 0) > (b.itemLevel or 0)
        end)
    else -- encounters (default)
        table.sort(filtered, function(a, b)
            return (a.count or 0) > (b.count or 0)
        end)
    end
    
    return filtered
end

-- Display player search results with enhanced formatting
function UI:DisplayPlayerResults(results, frame)
    if not frame or not frame.resultsText then return end
    
    local lines = {}
    local maxResults = 50 -- Limit for performance
    local displayCount = math.min(#results, maxResults)
    
    -- Color scheme for different elements
    local colors = {
        rank = DesignTokens.colors.textMuted,
        name = DesignTokens.colors.text,
        guild = {0.7, 0.7, 1.0, 1.0}, -- Light blue
        class = {1.0, 0.8, 0.4, 1.0}, -- Gold
        level = {0.4, 1.0, 0.4, 1.0}, -- Green
        encounters = {1.0, 1.0, 0.6, 1.0}, -- Light yellow
        grouped = DesignTokens.colors.success,
    }
    
    if displayCount == 0 then
        table.insert(lines, "|cFF888888No players found matching your criteria.|r")
    else
        for i = 1, displayCount do
            local player = results[i]
            local line = ""
            
            -- Rank
            line = line .. string.format("|cFF%02X%02X%02X%d.|r ", 
                colors.rank[1]*255, colors.rank[2]*255, colors.rank[3]*255, i)
            
            -- Name with color coding
            line = line .. string.format("|cFF%02X%02X%02X%s|r", 
                colors.name[1]*255, colors.name[2]*255, colors.name[3]*255, player.name)
            
            -- Grouped indicator
            if player.grouped then
                line = line .. string.format(" |cFF%02X%02X%02X★|r", 
                    colors.grouped[1]*255, colors.grouped[2]*255, colors.grouped[3]*255)
            end
            
            -- Guild
            if player.guild and player.guild ~= "" then
                line = line .. string.format(" |cFF%02X%02X%02X<%s>|r", 
                    colors.guild[1]*255, colors.guild[2]*255, colors.guild[3]*255, player.guild)
            end
            
            -- Class and Race
            if player.class and player.class ~= "" then
                local classText = player.class
                if player.race and player.race ~= "" then
                    classText = player.race .. " " .. player.class
                end
                line = line .. string.format(" |cFF%02X%02X%02X[%s]|r", 
                    colors.class[1]*255, colors.class[2]*255, colors.class[3]*255, classText)
            end
            
            -- Level
            if player.level and player.level > 0 then
                line = line .. string.format(" |cFF%02X%02X%02XL%d|r", 
                    colors.level[1]*255, colors.level[2]*255, colors.level[3]*255, player.level)
            end
            
            -- Item Level
            if player.itemLevel and player.itemLevel > 0 then
                line = line .. string.format(" |cFF%02X%02X%02XiL%d|r", 
                    colors.level[1]*255, colors.level[2]*255, colors.level[3]*255, player.itemLevel)
            end
            
            -- Encounters
            line = line .. string.format(" - |cFF%02X%02X%02X%d encounter%s|r", 
                colors.encounters[1]*255, colors.encounters[2]*255, colors.encounters[3]*255, 
                player.count, player.count == 1 and "" or "s")
            
            table.insert(lines, line)
        end
        
        if #results > maxResults then
            table.insert(lines, "")
            table.insert(lines, string.format("|cFF888888... and %d more (refine search to see all)|r", #results - maxResults))
        end
    end
    
    -- Update results
    frame.resultsText:SetText(table.concat(lines, "\n"))
    frame.resultsText:SetTextColor(unpack(DesignTokens.colors.text))
    
    -- Update summary
    if frame.summaryText then
        local summary = string.format("Showing %d of %d players", displayCount, #results)
        if frame.currentSearch ~= "" then
            summary = summary .. string.format(" (search: \"%s\")", frame.currentSearch)
        end
        frame.summaryText:SetText(summary)
    end
    
    -- Adjust scroll child height
    local textHeight = frame.resultsText:GetStringHeight()
    frame.scrollChild:SetHeight(math.max(textHeight + DesignTokens.spacing.md, 1))
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
    if not self.tabContent.players then
        return
    end
    
    local frame = self.tabContent.players
    if frame.searchBox then
        frame.searchBox:SetText(query or "")
    end
    
    self:PerformSearch(query, frame)
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
        "|cFFFFD700Crosspaths - Social Memory Tracker|r",
        "",
        "|cFF80C0FFWhat are Encounters?|r",
        "• Encounters track when you detect other players through:",
        "  - Grouping (parties, raids, battlegrounds)",
        "  - Proximity (nameplates, mouseover interactions)", 
        "  - Direct interaction (targeting, focusing)",
        "  - Combat participation (damage, healing, buffs)",
        "• Limited to 1 encounter per player per zone per session",
        "• A new session starts when you change zones or log in",
        "",
        "|cFFFFD700Commands:|r",
        "/crosspaths show - Show main UI",
        "/crosspaths top - Show top players",
        "/crosspaths stats [tanks|healers|dps|ilvl|achievements] - Show stats",
        "/crosspaths search <name> - Search for player",
        "/crosspaths export [json|csv] - Export data",
        "/crosspaths remove <player-name> - Remove player from tracking",
        "/crosspaths clear confirm - Clear all data",
        "/crosspaths debug [on|off] - Toggle debug mode",
        "/crosspaths status - Show addon status",
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
        table.insert(lines, "Session encounters: " .. tostring(stats.encountersDetected))
        table.insert(lines, "Players added: " .. tostring(stats.playersAdded))
        table.insert(lines, "Players updated: " .. tostring(stats.playersUpdated))
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
        
        -- Add helpful explanation for encounters
        if encounterCount == 1 then
            tooltip:AddLine("|cFF888888(Detected through proximity, grouping, or interaction)|r", 0.5, 0.5, 0.5, true)
        end
        
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
                local countA = tonumber(string.match(a, "%((%d+)%)"))
                local countB = tonumber(string.match(b, "%((%d+)%)"))
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
        tooltip:AddLine("|cFF888888(Will be tracked once detected)|r", 0.5, 0.5, 0.5, true)
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
        Crosspaths:Message("Player not found in database: " .. targetName)
    end
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