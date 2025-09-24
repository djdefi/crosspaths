-- Crosspaths MinimapButton.lua
-- Minimap button integration for easy UI access

local addonName, Crosspaths = ...

Crosspaths.MinimapButton = {}
local MinimapButton = Crosspaths.MinimapButton

-- Minimap button configuration
local MINIMAP_BUTTON_CONFIG = {
    -- Position settings (saved per character)
    position = 220, -- degrees around the minimap (0-360)
    radius = 78,    -- distance from minimap center
    
    -- Button appearance
    size = 32,
    icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
    
    -- Behavior
    showInCompartment = true, -- Show in addon compartment if available
    allowDragging = true,
}

-- Initialize minimap button
function MinimapButton:Initialize()
    -- Don't initialize if disabled in settings
    if Crosspaths.db and Crosspaths.db.settings and Crosspaths.db.settings.ui and
       Crosspaths.db.settings.ui.hideMinimapButton then
        return
    end
    
    self:CreateButton()
    self:LoadPosition()
    self:SetupSearchDialog()
    
    Crosspaths:DebugLog("Minimap button initialized", "INFO")
end

-- Setup player search dialog
function MinimapButton:SetupSearchDialog()
    StaticPopupDialogs["CROSSPATHS_SEARCH_PLAYER"] = {
        text = "Search for player:",
        button1 = "Search",
        button2 = "Cancel",
        hasEditBox = true,
        maxLetters = 50,
        OnAccept = function(self)
            local input = self.editBox:GetText()
            if input and input ~= "" then
                if Crosspaths.UI then
                    Crosspaths.UI:SearchPlayers(input)
                    Crosspaths.UI:Show()
                end
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local input = self:GetText()
            if input and input ~= "" then
                if Crosspaths.UI then
                    Crosspaths.UI:SearchPlayers(input)
                    Crosspaths.UI:Show()
                end
            end
            self:GetParent():Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- Create the minimap button
function MinimapButton:CreateButton()
    -- Create main button frame
    local button = CreateFrame("Button", "CrosspathsMinimapButton", Minimap)
    button:SetSize(MINIMAP_BUTTON_CONFIG.size, MINIMAP_BUTTON_CONFIG.size)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    
    -- Icon
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture(MINIMAP_BUTTON_CONFIG.icon)
    button.icon = icon
    
    -- Border
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    -- Background
    local background = button:CreateTexture(nil, "BORDER")
    background:SetSize(20, 20)
    background:SetPoint("CENTER", 0, 0)
    background:SetColorTexture(0, 0, 0, 0.3)
    
    -- Click handlers
    button:SetScript("OnClick", function(self, mouseButton)
        MinimapButton:OnClick(mouseButton)
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        MinimapButton:ShowTooltip(self)
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Dragging for repositioning
    if MINIMAP_BUTTON_CONFIG.allowDragging then
        button:SetMovable(true)
        button:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        
        button:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            MinimapButton:SavePosition()
        end)
        
        button:RegisterForDrag("LeftButton")
    end
    
    -- Register for clicks
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    self.button = button
end

-- Handle button clicks
function MinimapButton:OnClick(mouseButton)
    if mouseButton == "LeftButton" then
        -- Left click: Toggle main UI
        if Crosspaths.UI then
            Crosspaths.UI:Toggle()
        end
    elseif mouseButton == "RightButton" then
        -- Right click: Show context menu
        self:ShowContextMenu()
    end
end

-- Show tooltip on hover
function MinimapButton:ShowTooltip(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    GameTooltip:SetText("Crosspaths", 1, 1, 1)
    GameTooltip:AddLine("Social Memory Tracker", 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")
    
    -- Basic stats
    if Crosspaths.db and Crosspaths.db.players then
        local playerCount = Crosspaths:CountPlayers() or 0
        local encounterCount = Crosspaths:CountEncounters() or 0
        GameTooltip:AddLine("Players Tracked: " .. playerCount, 0.7, 0.9, 1)
        GameTooltip:AddLine("Total Encounters: " .. encounterCount, 0.7, 0.9, 1)
    end
    
    -- Session stats if available
    if Crosspaths.Engine then
        local sessionStats = Crosspaths.Engine:GetSessionStats()
        if sessionStats then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Session Stats:", 1, 1, 0.5)
            GameTooltip:AddLine("New Players: " .. (sessionStats.newPlayersThisSession or 0), 0.7, 0.9, 1)
            GameTooltip:AddLine("Encounters: " .. (sessionStats.encountersThisSession or 0), 0.7, 0.9, 1)
        end
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left Click: Open Crosspaths", 0.5, 1, 0.5)
    GameTooltip:AddLine("Right Click: Options", 0.5, 1, 0.5)
    if MINIMAP_BUTTON_CONFIG.allowDragging then
        GameTooltip:AddLine("Drag: Reposition", 0.5, 1, 0.5)
    end
    
    GameTooltip:Show()
end

-- Show context menu with improved organization
function MinimapButton:ShowContextMenu()
    local menu = CreateFrame("Frame", "CrosspathsMinimapMenu", UIParent, "UIDropDownMenuTemplate")
    
    local function AddMenuItem(text, func, hasArrow, disabled, tooltipText)
        local info = UIDropDownMenu_CreateInfo()
        info.text = text
        info.func = func
        info.hasArrow = hasArrow
        info.disabled = disabled
        info.tooltipTitle = tooltipText
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(menu, function(self, level)
        if level == 1 then
            -- Main interface access
            AddMenuItem("|cFF00FF00Open Crosspaths|r", function()
                if Crosspaths.UI then
                    Crosspaths.UI:Show()
                end
                CloseDropDownMenus()
            end, false, false, "Open main interface with all features")
            
            UIDropDownMenu_AddSeparator()
            
            -- Quick access features
            AddMenuItem("Quick Stats", function()
                if Crosspaths.UI then
                    Crosspaths.UI:ShowStatus()
                end
                CloseDropDownMenus()
            end, false, false, "Show basic statistics summary")
            
            AddMenuItem("Reports", nil, true, false, "Generate digest reports")
            
            UIDropDownMenu_AddSeparator()
            
            -- Direct access to tools that are commonly used
            AddMenuItem("Search Player", function()
                -- Create a simple search dialog
                StaticPopup_Show("CROSSPATHS_SEARCH_PLAYER")
                CloseDropDownMenus()
            end, false, false, "Search for a specific player")
            
            AddMenuItem("Analytics", nil, true, false, "Advanced analytics and insights")
            
            UIDropDownMenu_AddSeparator()
            
            -- Settings moved to main UI indication
            AddMenuItem("|cFFAAAAFFSettings (Use Main UI)|r", function()
                if Crosspaths.UI then
                    Crosspaths.UI:Show()
                    -- Focus on the main UI for settings access
                end
                CloseDropDownMenus()
            end, false, false, "All settings are now in the main interface")
            
        elseif level == 2 then
            -- Get the parent button text to determine submenu
            local parentText = UIDROPDOWNMENU_MENU_VALUE or ""
            
            if parentText == "Reports" then
                AddMenuItem("Daily Digest", function()
                    if Crosspaths.Engine and Crosspaths.UI then
                        local digest = Crosspaths.Engine:GenerateDailyDigest()
                        Crosspaths.UI:ShowDigestReport("Daily Digest", digest)
                    end
                    CloseDropDownMenus()
                end)
                
                AddMenuItem("Weekly Digest", function()
                    if Crosspaths.Engine and Crosspaths.UI then
                        local digest = Crosspaths.Engine:GenerateWeeklyDigest()
                        Crosspaths.UI:ShowDigestReport("Weekly Digest", digest)
                    end
                    CloseDropDownMenus()
                end)
                
                AddMenuItem("Monthly Digest", function()
                    if Crosspaths.Engine and Crosspaths.UI then
                        local digest = Crosspaths.Engine:GenerateMonthlyDigest()
                        Crosspaths.UI:ShowDigestReport("Monthly Digest", digest)
                    end
                    CloseDropDownMenus()
                end)
                
            elseif parentText == "Analytics" then
                AddMenuItem("Zone Analytics", function()
                    if Crosspaths.UI then
                        Crosspaths.UI:Show()
                        -- Could add logic to focus on analytics tab when implemented
                    end
                    CloseDropDownMenus()
                end)
                
                AddMenuItem("Class Distribution", function()
                    if Crosspaths.UI then
                        Crosspaths.UI:ShowClassStats()
                    end
                    CloseDropDownMenus()
                end)
                
                AddMenuItem("Activity Patterns", function()
                    if Crosspaths.UI then
                        Crosspaths.UI:ShowActivityStats()
                    end
                    CloseDropDownMenus()
                end)
            end
        end
    end)
    
    ToggleDropDownMenu(1, nil, menu, "cursor", 3, -3)
end

-- Update button position around minimap
function MinimapButton:UpdatePosition()
    if not self.button then
        return
    end
    
    local position = self:GetPosition()
    local radius = MINIMAP_BUTTON_CONFIG.radius
    
    local x = radius * math.cos(math.rad(position))
    local y = radius * math.sin(math.rad(position))
    
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Get saved position
function MinimapButton:GetPosition()
    if Crosspaths.db and Crosspaths.db.settings and Crosspaths.db.settings.ui then
        return Crosspaths.db.settings.ui.minimapButtonPosition or MINIMAP_BUTTON_CONFIG.position
    end
    return MINIMAP_BUTTON_CONFIG.position
end

-- Save current position
function MinimapButton:SavePosition()
    if not self.button then
        return
    end
    
    -- Calculate angle from center of minimap
    local centerX, centerY = Minimap:GetCenter()
    local buttonX, buttonY = self.button:GetCenter()
    
    if centerX and centerY and buttonX and buttonY then
        local deltaX = buttonX - centerX
        local deltaY = buttonY - centerY
        local angle = math.deg(math.atan2(deltaY, deltaX))
        
        -- Normalize angle to 0-360
        if angle < 0 then
            angle = angle + 360
        end
        
        -- Ensure settings structure exists
        if not Crosspaths.db.settings.ui then
            Crosspaths.db.settings.ui = {}
        end
        
        Crosspaths.db.settings.ui.minimapButtonPosition = angle
        self:UpdatePosition()
        
        Crosspaths:DebugLog("Minimap button position saved: " .. angle, "INFO")
    end
end

-- Load saved position
function MinimapButton:LoadPosition()
    local position = self:GetPosition()
    
    -- Update button position
    self:UpdatePosition()
    
    Crosspaths:DebugLog("Minimap button position loaded: " .. position, "INFO")
end

-- Show/hide the minimap button
function MinimapButton:SetVisible(visible)
    if self.button then
        if visible then
            self.button:Show()
        else
            self.button:Hide()
        end
    end
end

-- Check if minimap button is enabled
function MinimapButton:IsEnabled()
    if not Crosspaths.db or not Crosspaths.db.settings or not Crosspaths.db.settings.ui then
        return true -- Default to enabled
    end
    return not Crosspaths.db.settings.ui.hideMinimapButton
end

-- Toggle minimap button visibility
function MinimapButton:Toggle()
    local isEnabled = self:IsEnabled()
    
    -- Ensure settings structure exists
    if not Crosspaths.db.settings.ui then
        Crosspaths.db.settings.ui = {}
    end
    
    Crosspaths.db.settings.ui.hideMinimapButton = isEnabled
    
    if isEnabled then
        self:SetVisible(false)
        Crosspaths:Message("Minimap button hidden")
    else
        if not self.button then
            self:CreateButton()
            self:LoadPosition()
        end
        self:SetVisible(true)
        Crosspaths:Message("Minimap button shown")
    end
end