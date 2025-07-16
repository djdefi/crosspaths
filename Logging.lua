-- Crosspaths Logging.lua
-- Debug logging and error tracking system

local addonName, Crosspaths = ...

Crosspaths.Logging = {}
local Logging = Crosspaths.Logging

-- Set default log level to prevent nil comparison errors
Logging.logLevel = 3  -- INFO level by default

-- Log levels
local LOG_LEVELS = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
}

local LOG_LEVEL_NAMES = {
    [1] = "ERROR",
    [2] = "WARN",
    [3] = "INFO",
    [4] = "DEBUG",
}

-- Initialize logging variables
function Logging:InitializeVariables()
    if not CrosspathsDB then
        return
    end

    if not CrosspathsDB.logs then
        CrosspathsDB.logs = {
            session = {},
            errors = {},
            maxSessionLogs = 1000,
            maxErrorLogs = 100,
        }
    end

    -- Clear session logs on each login
    CrosspathsDB.logs.session = {}

    self.logLevel = LOG_LEVELS.INFO
    if Crosspaths.debug then
        self.logLevel = LOG_LEVELS.DEBUG
    end

    self:Log("Logging system initialized with level: " .. LOG_LEVEL_NAMES[self.logLevel], "INFO")
end

-- Main logging function
function Logging:Log(message, level)
    level = level or "INFO"
    local levelNum = LOG_LEVELS[level] or LOG_LEVELS.INFO

    -- Check if we should log this level
    if levelNum > self.logLevel then
        return
    end

    local timestamp = date("%H:%M:%S")
    local logEntry = {
        time = timestamp,
        level = level,
        message = tostring(message),
        timestamp = time(),
    }

    -- Add to session logs
    if CrosspathsDB and CrosspathsDB.logs then
        table.insert(CrosspathsDB.logs.session, logEntry)

        -- Trim session logs if too many
        local maxLogs = CrosspathsDB.logs.maxSessionLogs or 1000
        while #CrosspathsDB.logs.session > maxLogs do
            table.remove(CrosspathsDB.logs.session, 1)
        end

        -- Add errors to error log
        if level == "ERROR" then
            table.insert(CrosspathsDB.logs.errors, logEntry)

            -- Trim error logs if too many
            local maxErrors = CrosspathsDB.logs.maxErrorLogs or 100
            while #CrosspathsDB.logs.errors > maxErrors do
                table.remove(CrosspathsDB.logs.errors, 1)
            end
        end
    end

    -- Print to console for debug level
    if Crosspaths.debug and level == "ERROR" then
        print("|cFFFF0000[Crosspaths " .. level .. "]|r " .. message)
    elseif Crosspaths.debug and levelNum <= LOG_LEVELS.INFO then
        local color = level == "WARN" and "|cFFFFFF00" or "|cFF7B68EE"
        print(color .. "[Crosspaths " .. level .. "]|r " .. message)
    end
end

-- Convenience functions for different log levels
function Logging:Error(message)
    self:Log(message, "ERROR")
end

function Logging:Warn(message)
    self:Log(message, "WARN")
end

function Logging:Info(message)
    self:Log(message, "INFO")
end

function Logging:Debug(message)
    self:Log(message, "DEBUG")
end

-- Get session logs
function Logging:GetSessionLogs()
    if CrosspathsDB and CrosspathsDB.logs then
        return CrosspathsDB.logs.session or {}
    end
    return {}
end

-- Get error logs
function Logging:GetErrorLogs()
    if CrosspathsDB and CrosspathsDB.logs then
        return CrosspathsDB.logs.errors or {}
    end
    return {}
end

-- Clear logs
function Logging:ClearSessionLogs()
    if CrosspathsDB and CrosspathsDB.logs then
        CrosspathsDB.logs.session = {}
        self:Info("Session logs cleared")
    end
end

function Logging:ClearErrorLogs()
    if CrosspathsDB and CrosspathsDB.logs then
        CrosspathsDB.logs.errors = {}
        self:Info("Error logs cleared")
    end
end

-- Export logs as string
function Logging:ExportLogs(includeErrors)
    local logs = self:GetSessionLogs()
    if includeErrors then
        local errorLogs = self:GetErrorLogs()
        for _, errorLog in ipairs(errorLogs) do
            table.insert(logs, errorLog)
        end
    end

    -- Sort by timestamp
    table.sort(logs, function(a, b)
        return a.timestamp < b.timestamp
    end)

    local output = {}
    table.insert(output, "Crosspaths Log Export - " .. date("%Y-%m-%d %H:%M:%S"))
    table.insert(output, "Version: " .. (Crosspaths.version or "unknown"))
    table.insert(output, "Total entries: " .. #logs)
    table.insert(output, "")

    for _, log in ipairs(logs) do
        local line = string.format("[%s] %s: %s", log.time, log.level, log.message)
        table.insert(output, line)
    end

    return table.concat(output, "\n")
end

-- Convenience functions for Crosspaths core
function Crosspaths:DebugLog(message, level)
    if self.Logging then
        self.Logging:Log(message, level or "DEBUG")
    end
end

function Crosspaths:LogError(message)
    if self.Logging then
        self.Logging:Error(message)
    end
end

function Crosspaths:LogInfo(message)
    if self.Logging then
        self.Logging:Info(message)
    end
end

function Crosspaths:LogWarn(message)
    if self.Logging then
        self.Logging:Warn(message)
    end
end