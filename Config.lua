-- Crosspaths Config.lua
-- Configuration management and settings

local addonName, Crosspaths = ...

Crosspaths.Config = {}
local Config = Crosspaths.Config

-- Initialize config
function Config:Initialize()
    self.configFrame = nil

    -- Register config slash command
    SLASH_CROSSPATHSCONFIG1 = "/cpconfig"
    SlashCmdList["CROSSPATHSCONFIG"] = function(msg)
        self:Show()
    end

    Crosspaths:DebugLog("Config system initialized", "INFO")
end

-- Show config frame
function Config:Show()
    if not self.configFrame then
        self:CreateConfigFrame()
    end

    self.configFrame:Show()
    self:RefreshSettings()
end

-- Hide config frame
function Config:Hide()
    if self.configFrame then
        self.configFrame:Hide()
    end
end

-- Create config frame
function Config:CreateConfigFrame()
    -- Get UI constants from the UI module for consistency
    local UI = Crosspaths.UI
    local GetResponsiveSize
    
    -- Access GetResponsiveSize function from UI module's local scope
    -- For now, implement a simple responsive config window size
    local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
    local screenHeight = GetScreenHeight() * UIParent:GetEffectiveScale()
    
    -- Calculate responsive size for config window (60% of screen, with limits)
    local width = math.max(400, math.min(800, screenWidth * 0.6))
    local height = math.max(500, math.min(900, screenHeight * 0.75))
    
    local frame = CreateFrame("Frame", "CrosspathsConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(width, height)
    
    -- Set minimum and maximum size constraints
    frame:SetMinResize(400, 500)
    frame:SetMaxResize(800, 900)
    
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Crosspaths Configuration")

    -- Scroll frame for content with responsive sizing
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    -- Make content size responsive to the scroll frame
    content:SetSize(scrollFrame:GetWidth() - 20, 800)
    scrollFrame:SetScrollChild(content)

    frame.content = content
    frame.scrollFrame = scrollFrame

    -- Create config sections
    self:CreateGeneralSettings(content)
    self:CreateTrackingSettings(content)
    self:CreateNotificationSettings(content)
    self:CreateDigestSettings(content)
    self:CreateUISettings(content)
    self:CreateDataManagement(content)

    self.configFrame = frame
end

-- Create general settings
function Config:CreateGeneralSettings(parent)
    local yOffset = -10

    -- Section header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    header:SetText("|cFFFFD700General Settings|r")
    yOffset = yOffset - 30

    -- Enable addon checkbox
    local enabledCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    enabledCheck.Text:SetText("Enable Crosspaths")
    enabledCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.enabled = self:GetChecked()
        Crosspaths:Message("Crosspaths " .. (self:GetChecked() and "enabled" or "disabled"))
    end)
    parent.enabledCheck = enabledCheck
    yOffset = yOffset - 30

    -- Debug mode checkbox
    local debugCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    debugCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    debugCheck.Text:SetText("Debug Mode")
    debugCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.debug = self:GetChecked()
        Crosspaths.debug = self:GetChecked()
        Crosspaths:Message("Debug mode " .. (self:GetChecked() and "enabled" or "disabled"))
    end)
    parent.debugCheck = debugCheck
    yOffset = yOffset - 50

    parent.generalYOffset = yOffset
end

-- Create tracking settings
function Config:CreateTrackingSettings(parent)
    local yOffset = parent.generalYOffset or -100

    -- Section header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    header:SetText("|cFFFFD700Tracking Settings|r")
    yOffset = yOffset - 30

    -- Group tracking
    local groupCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    groupCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    groupCheck.Text:SetText("Track Group Members")
    groupCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.tracking.enableGroupTracking = self:GetChecked()
    end)
    parent.groupCheck = groupCheck
    yOffset = yOffset - 25

    -- Nameplate tracking
    local nameplateCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    nameplateCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    nameplateCheck.Text:SetText("Track Nearby Players (Nameplates)")
    nameplateCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.tracking.enableNameplateTracking = self:GetChecked()
    end)
    parent.nameplateCheck = nameplateCheck
    yOffset = yOffset - 25

    -- City tracking
    local cityCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cityCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    cityCheck.Text:SetText("Track Players in Cities")
    cityCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.tracking.enableCityTracking = self:GetChecked()
    end)
    parent.cityCheck = cityCheck
    yOffset = yOffset - 25

    -- Mouseover tracking
    local mouseoverCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    mouseoverCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    mouseoverCheck.Text:SetText("Track Mouseover Players")
    mouseoverCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.tracking.enableMouseoverTracking = self:GetChecked()
    end)
    parent.mouseoverCheck = mouseoverCheck
    yOffset = yOffset - 25

    -- Target tracking
    local targetCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    targetCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    targetCheck.Text:SetText("Track Target/Focus Changes")
    targetCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.tracking.enableTargetTracking = self:GetChecked()
    end)
    parent.targetCheck = targetCheck
    yOffset = yOffset - 25

    -- Combat log tracking
    local combatCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    combatCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    combatCheck.Text:SetText("Track Combat Interactions")
    combatCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.tracking.enableCombatLogTracking = self:GetChecked()
    end)
    parent.combatCheck = combatCheck
    yOffset = yOffset - 25

    -- Location-based throttling
    local locationCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    locationCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    locationCheck.Text:SetText("Enable Location-Based Duplicate Detection")
    locationCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.tracking.locationBasedThrottling = self:GetChecked()
    end)
    parent.locationCheck = locationCheck
    yOffset = yOffset - 25

    -- Minimum move distance
    local distanceLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    distanceLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, yOffset)
    distanceLabel:SetText("Minimum move distance (0.001-0.1):")
    yOffset = yOffset - 20

    local distanceEditBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    distanceEditBox:SetSize(80, 20)
    distanceEditBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, yOffset)
    distanceEditBox:SetAutoFocus(false)
    distanceEditBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 0.01
        if value < 0.001 then value = 0.001 end
        if value > 0.1 then value = 0.1 end
        Crosspaths.db.settings.tracking.minimumMoveDistance = value
        self:SetText(string.format("%.3f", value))
        self:ClearFocus()
    end)
    parent.distanceEditBox = distanceEditBox
    yOffset = yOffset - 35

    -- Pruning settings
    local pruneLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pruneLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    pruneLabel:SetText("Auto-prune data older than (days):")
    yOffset = yOffset - 20

    local pruneEditBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    pruneEditBox:SetSize(60, 20)
    pruneEditBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    pruneEditBox:SetAutoFocus(false)
    pruneEditBox:SetNumeric(true)
    pruneEditBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 180
        if value < 1 then value = 1 end
        if value > 365 then value = 365 end
        Crosspaths.db.settings.tracking.pruneAfterDays = value
        self:SetText(tostring(value))
        self:ClearFocus()
    end)
    parent.pruneEditBox = pruneEditBox
    yOffset = yOffset - 50

    parent.trackingYOffset = yOffset
end

-- Create notification settings
function Config:CreateNotificationSettings(parent)
    local yOffset = parent.trackingYOffset or -300

    -- Section header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    header:SetText("|cFFFFD700Notification Settings|r")
    yOffset = yOffset - 30

    -- Master notification toggle
    local masterCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    masterCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    masterCheck.Text:SetText("Enable All Notifications")
    masterCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.notifications.enableNotifications = self:GetChecked()
        if not self:GetChecked() then
            Crosspaths:Message("All notifications disabled")
        else
            Crosspaths:Message("Notifications enabled")
        end
    end)
    parent.masterCheck = masterCheck
    yOffset = yOffset - 35

    -- Notification types subsection
    local typesLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typesLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    typesLabel:SetText("|cFFADD8E6Notification Types:|r")
    yOffset = yOffset - 20

    -- Repeat encounters
    local repeatCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    repeatCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    repeatCheck.Text:SetText("Repeat Encounters")
    repeatCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.notifications.notifyRepeatEncounters = self:GetChecked()
    end)
    parent.repeatCheck = repeatCheck
    yOffset = yOffset - 25

    -- Frequent players
    local frequentCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    frequentCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    frequentCheck.Text:SetText("Frequent Players")
    frequentCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.notifications.notifyFrequentPlayers = self:GetChecked()
    end)
    parent.frequentCheck = frequentCheck
    yOffset = yOffset - 25

    -- Previous group members
    local groupMemberCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    groupMemberCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    groupMemberCheck.Text:SetText("Previous Group Members")
    groupMemberCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.notifications.notifyPreviousGroupMembers = self:GetChecked()
    end)
    parent.groupMemberCheck = groupMemberCheck
    yOffset = yOffset - 25

    -- New encounters
    local newCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    newCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    newCheck.Text:SetText("New Player Encounters")
    newCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.notifications.notifyNewEncounters = self:GetChecked()
    end)
    parent.newCheck = newCheck
    yOffset = yOffset - 25

    -- Guild members
    local guildCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    guildCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    guildCheck.Text:SetText("Guild Member Encounters")
    guildCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.notifications.notifyGuildMembers = self:GetChecked()
    end)
    parent.guildCheck = guildCheck
    yOffset = yOffset - 35

    -- Notification display options
    local displayLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    displayLabel:SetText("|cFFADD8E6Display Options:|r")
    yOffset = yOffset - 20

    -- Play sounds
    local soundCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    soundCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    soundCheck.Text:SetText("Play notification sounds")
    soundCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.notifications.playSound = self:GetChecked()
    end)
    parent.soundCheck = soundCheck
    yOffset = yOffset - 25

    -- Do not disturb mode
    local dndCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    dndCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    dndCheck.Text:SetText("Do Not Disturb in Combat")
    dndCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.notifications.doNotDisturbCombat = self:GetChecked()
    end)
    parent.dndCheck = dndCheck
    yOffset = yOffset - 25

    -- Max notifications
    local maxLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    maxLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    maxLabel:SetText("Max simultaneous notifications:")
    yOffset = yOffset - 20

    local maxEditBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    maxEditBox:SetSize(40, 20)
    maxEditBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    maxEditBox:SetAutoFocus(false)
    maxEditBox:SetNumeric(true)
    maxEditBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 3
        if value < 1 then value = 1 end
        if value > 10 then value = 10 end
        Crosspaths.db.settings.notifications.maxNotifications = value
        self:SetText(tostring(value))
        self:ClearFocus()
    end)
    parent.maxEditBox = maxEditBox
    yOffset = yOffset - 25

    -- Notification duration
    local durationLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    durationLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    durationLabel:SetText("Notification duration (seconds):")
    yOffset = yOffset - 20

    local durationEditBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    durationEditBox:SetSize(40, 20)
    durationEditBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    durationEditBox:SetAutoFocus(false)
    durationEditBox:SetNumeric(true)
    durationEditBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 3
        if value < 1 then value = 1 end
        if value > 15 then value = 15 end
        Crosspaths.db.settings.notifications.duration = value
        self:SetText(tostring(value))
        self:ClearFocus()
    end)
    parent.notificationDurationEditBox = durationEditBox
    yOffset = yOffset - 35

    -- Thresholds subsection
    local thresholdLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    thresholdLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    thresholdLabel:SetText("|cFFADD8E6Notification Thresholds:|r")
    yOffset = yOffset - 20

    -- Frequent threshold
    local frequentLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frequentLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    frequentLabel:SetText("Frequent player threshold (encounters):")
    yOffset = yOffset - 20

    local thresholdEditBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    thresholdEditBox:SetSize(40, 20)
    thresholdEditBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    thresholdEditBox:SetAutoFocus(false)
    thresholdEditBox:SetNumeric(true)
    thresholdEditBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 10
        if value < 2 then value = 2 end
        if value > 100 then value = 100 end
        Crosspaths.db.settings.notifications.frequentPlayerThreshold = value
        self:SetText(tostring(value))
        self:ClearFocus()
    end)
    parent.thresholdEditBox = thresholdEditBox
    yOffset = yOffset - 50

    parent.notificationsYOffset = yOffset
end

-- Create digest settings
function Config:CreateDigestSettings(parent)
    local yOffset = parent.notificationsYOffset or -450

    -- Section header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    header:SetText("|cFFFFD700Digest Reports|r")
    yOffset = yOffset - 30

    -- Enable auto notifications
    local autoNotifyCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    autoNotifyCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    autoNotifyCheck.Text:SetText("Auto-notify when digests are available")
    autoNotifyCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.digests.autoNotify = self:GetChecked()
    end)
    parent.autoNotifyCheck = autoNotifyCheck
    yOffset = yOffset - 35

    -- Digest types subsection
    local typesLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typesLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    typesLabel:SetText("|cFFADD8E6Digest Types:|r")
    yOffset = yOffset - 20

    -- Daily digest
    local dailyCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    dailyCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    dailyCheck.Text:SetText("Daily Digest (24 hour summary)")
    dailyCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.digests.enableDaily = self:GetChecked()
    end)
    parent.dailyCheck = dailyCheck
    yOffset = yOffset - 25

    -- Weekly digest
    local weeklyCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    weeklyCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    weeklyCheck.Text:SetText("Weekly Digest (7 day summary)")
    weeklyCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.digests.enableWeekly = self:GetChecked()
    end)
    parent.weeklyCheck = weeklyCheck
    yOffset = yOffset - 25

    -- Monthly digest
    local monthlyCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    monthlyCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    monthlyCheck.Text:SetText("Monthly Digest (30 day summary)")
    monthlyCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.digests.enableMonthly = self:GetChecked()
    end)
    parent.monthlyCheck = monthlyCheck
    yOffset = yOffset - 35

    -- Manual digest buttons
    local manualLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    manualLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    manualLabel:SetText("|cFFADD8E6Generate Digest Now:|r")
    yOffset = yOffset - 20

    -- Daily button
    local dailyBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    dailyBtn:SetSize(80, 25)
    dailyBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    dailyBtn:SetText("Daily")
    dailyBtn:SetScript("OnClick", function()
        if Crosspaths.UI and Crosspaths.UI.ShowDigestReport then
            local digest = Crosspaths.Engine:GenerateDailyDigest()
            Crosspaths.UI:ShowDigestReport("Daily Digest", digest)
        end
    end)

    -- Weekly button
    local weeklyBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    weeklyBtn:SetSize(80, 25)
    weeklyBtn:SetPoint("LEFT", dailyBtn, "RIGHT", 10, 0)
    weeklyBtn:SetText("Weekly")
    weeklyBtn:SetScript("OnClick", function()
        if Crosspaths.UI and Crosspaths.UI.ShowDigestReport then
            local digest = Crosspaths.Engine:GenerateWeeklyDigest()
            Crosspaths.UI:ShowDigestReport("Weekly Digest", digest)
        end
    end)

    -- Monthly button
    local monthlyBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    monthlyBtn:SetSize(80, 25)
    monthlyBtn:SetPoint("LEFT", weeklyBtn, "RIGHT", 10, 0)
    monthlyBtn:SetText("Monthly")
    monthlyBtn:SetScript("OnClick", function()
        if Crosspaths.UI and Crosspaths.UI.ShowDigestReport then
            local digest = Crosspaths.Engine:GenerateMonthlyDigest()
            Crosspaths.UI:ShowDigestReport("Monthly Digest", digest)
        end
    end)
    yOffset = yOffset - 50

    parent.digestsYOffset = yOffset
end

-- Create UI settings
function Config:CreateUISettings(parent)
    local yOffset = parent.digestsYOffset or -700

    -- Section header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    header:SetText("|cFFFFD700UI Settings|r")
    yOffset = yOffset - 30

    -- Show notifications
    local notifCheck = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    notifCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    notifCheck.Text:SetText("Show Toast Notifications")
    notifCheck:SetScript("OnClick", function(self)
        Crosspaths.db.settings.ui.showNotifications = self:GetChecked()
    end)
    parent.notifCheck = notifCheck
    yOffset = yOffset - 25

    -- Notification duration
    local durationLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    durationLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    durationLabel:SetText("Notification duration (seconds):")
    yOffset = yOffset - 20

    local durationEditBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    durationEditBox:SetSize(60, 20)
    durationEditBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    durationEditBox:SetAutoFocus(false)
    durationEditBox:SetNumeric(true)
    durationEditBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 3
        if value < 1 then value = 1 end
        if value > 10 then value = 10 end
        Crosspaths.db.settings.ui.notificationDuration = value
        self:SetText(tostring(value))
        self:ClearFocus()
    end)
    parent.durationEditBox = durationEditBox
    yOffset = yOffset - 50

    parent.uiYOffset = yOffset
end

-- Create data management
function Config:CreateDataManagement(parent)
    local yOffset = parent.uiYOffset or -650

    -- Section header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    header:SetText("|cFFFFD700Data Management|r")
    yOffset = yOffset - 30

    -- Export button
    local exportBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    exportBtn:SetSize(120, 25)
    exportBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    exportBtn:SetText("Export Data")
    exportBtn:SetScript("OnClick", function()
        Crosspaths.UI:ExportData("json")
    end)
    yOffset = yOffset - 35

    -- Clear data button
    local clearBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    clearBtn:SetSize(120, 25)
    clearBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    clearBtn:SetText("Clear All Data")
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("CROSSPATHS_CLEAR_DATA")
    end)
    yOffset = yOffset - 35

    -- Reset settings button
    local resetBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    resetBtn:SetSize(120, 25)
    resetBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    resetBtn:SetText("Reset Settings")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("CROSSPATHS_RESET_SETTINGS")
    end)
end

-- Refresh settings display
function Config:RefreshSettings()
    if not self.configFrame or not Crosspaths.db then
        return
    end

    local content = self.configFrame.content

    -- General settings
    if content.enabledCheck then
        content.enabledCheck:SetChecked(Crosspaths.db.settings.enabled)
    end
    if content.debugCheck then
        content.debugCheck:SetChecked(Crosspaths.db.settings.debug)
    end

    -- Tracking settings
    if content.groupCheck then
        content.groupCheck:SetChecked(Crosspaths.db.settings.tracking.enableGroupTracking)
    end
    if content.nameplateCheck then
        content.nameplateCheck:SetChecked(Crosspaths.db.settings.tracking.enableNameplateTracking)
    end
    if content.cityCheck then
        content.cityCheck:SetChecked(Crosspaths.db.settings.tracking.enableCityTracking)
    end
    if content.mouseoverCheck then
        content.mouseoverCheck:SetChecked(Crosspaths.db.settings.tracking.enableMouseoverTracking)
    end
    if content.targetCheck then
        content.targetCheck:SetChecked(Crosspaths.db.settings.tracking.enableTargetTracking)
    end
    if content.combatCheck then
        content.combatCheck:SetChecked(Crosspaths.db.settings.tracking.enableCombatLogTracking)
    end
    if content.locationCheck then
        content.locationCheck:SetChecked(Crosspaths.db.settings.tracking.locationBasedThrottling)
    end
    if content.distanceEditBox then
        content.distanceEditBox:SetText(string.format("%.3f", Crosspaths.db.settings.tracking.minimumMoveDistance or 0.01))
    end
    if content.pruneEditBox then
        content.pruneEditBox:SetText(tostring(Crosspaths.db.settings.tracking.pruneAfterDays or 180))
    end

    -- Notification settings
    if content.masterCheck then
        content.masterCheck:SetChecked(Crosspaths.db.settings.notifications.enableNotifications ~= false)
    end
    if content.repeatCheck then
        content.repeatCheck:SetChecked(Crosspaths.db.settings.notifications.notifyRepeatEncounters)
    end
    if content.frequentCheck then
        content.frequentCheck:SetChecked(Crosspaths.db.settings.notifications.notifyFrequentPlayers)
    end
    if content.groupMemberCheck then
        content.groupMemberCheck:SetChecked(Crosspaths.db.settings.notifications.notifyPreviousGroupMembers)
    end
    if content.newCheck then
        content.newCheck:SetChecked(Crosspaths.db.settings.notifications.notifyNewEncounters ~= false)
    end
    if content.guildCheck then
        content.guildCheck:SetChecked(Crosspaths.db.settings.notifications.notifyGuildMembers ~= false)
    end
    if content.soundCheck then
        content.soundCheck:SetChecked(Crosspaths.db.settings.notifications.playSound ~= false)
    end
    if content.dndCheck then
        content.dndCheck:SetChecked(Crosspaths.db.settings.notifications.doNotDisturbCombat ~= false)
    end
    if content.maxEditBox then
        content.maxEditBox:SetText(tostring(Crosspaths.db.settings.notifications.maxNotifications or 3))
    end
    if content.notificationDurationEditBox then
        content.notificationDurationEditBox:SetText(tostring(Crosspaths.db.settings.notifications.duration or 3))
    end
    if content.thresholdEditBox then
        content.thresholdEditBox:SetText(tostring(Crosspaths.db.settings.notifications.frequentPlayerThreshold or 10))
    end

    -- Digest settings
    if content.autoNotifyCheck then
        content.autoNotifyCheck:SetChecked(Crosspaths.db.settings.digests.autoNotify ~= false)
    end
    if content.dailyCheck then
        content.dailyCheck:SetChecked(Crosspaths.db.settings.digests.enableDaily ~= false)
    end
    if content.weeklyCheck then
        content.weeklyCheck:SetChecked(Crosspaths.db.settings.digests.enableWeekly ~= false)
    end
    if content.monthlyCheck then
        content.monthlyCheck:SetChecked(Crosspaths.db.settings.digests.enableMonthly ~= false)
    end

    -- UI settings
    if content.notifCheck then
        content.notifCheck:SetChecked(Crosspaths.db.settings.ui.showNotifications)
    end
    if content.durationEditBox then
        content.durationEditBox:SetText(tostring(Crosspaths.db.settings.ui.notificationDuration or 3))
    end
end

-- Create popup dialogs
StaticPopupDialogs["CROSSPATHS_CLEAR_DATA"] = {
    text = "Are you sure you want to clear all Crosspaths data? This cannot be undone.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        if Crosspaths.db then
            Crosspaths.db.players = {}
            Crosspaths:Message("All player data cleared!")
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["CROSSPATHS_RESET_SETTINGS"] = {
    text = "Are you sure you want to reset all settings to defaults?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        if Crosspaths.db then
            -- Safe reset: replace settings with defaults instead of setting to nil
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
                    enableMouseoverTracking = true,
                    enableTargetTracking = true,
                    enableCombatLogTracking = true,
                    locationBasedThrottling = true,
                    throttleMs = 500,
                    minimumMoveDistance = 0.01,
                    pruneAfterDays = 180,
                    maxPlayers = 10000,
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
                    frequentPlayerThreshold = 10,
                },
                digests = {
                    autoNotify = true,
                    enableDaily = true,
                    enableWeekly = true,
                    enableMonthly = true,
                }
            }

            -- Replace settings with fresh defaults
            for key, value in pairs(defaults) do
                if type(value) == "table" then
                    Crosspaths.db.settings[key] = {}
                    for subkey, subvalue in pairs(value) do
                        Crosspaths.db.settings[key][subkey] = subvalue
                    end
                else
                    Crosspaths.db.settings[key] = value
                end
            end

            -- Update debug flag
            Crosspaths.debug = Crosspaths.db.settings.debug

            Crosspaths:Message("Settings reset to defaults!")
            if Crosspaths.Config and Crosspaths.Config.configFrame then
                Crosspaths.Config:RefreshSettings()
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}