-- Crosspaths Engine.lua
-- Data processing, statistics, and analytics engine

local addonName, Crosspaths = ...

Crosspaths.Engine = {}
local Engine = Crosspaths.Engine

-- Initialize engine
function Engine:Initialize()
    self.cache = {
        topPlayers = {},
        topGuilds = {},
        topZones = {},
        lastCacheUpdate = 0,
        cacheTimeout = 30, -- 30 seconds
    }
    
    -- Start update loop for cache refresh
    self:StartUpdateLoop()
    
    Crosspaths:DebugLog("Engine initialized", "INFO")
end

-- Start update loop
function Engine:StartUpdateLoop()
    if self.updateTimer then
        self.updateTimer:Cancel()
    end
    
    self.updateTimer = C_Timer.NewTicker(30, function()
        self:RefreshCache()
    end)
end

-- Stop update loop
function Engine:StopUpdateLoop()
    if self.updateTimer then
        self.updateTimer:Cancel()
        self.updateTimer = nil
    end
end

-- Refresh data cache
function Engine:RefreshCache()
    local now = time()
    if now - self.cache.lastCacheUpdate < self.cache.cacheTimeout then
        return
    end
    
    Crosspaths:SafeCall(function()
        self.cache.topPlayers = self:CalculateTopPlayers(10)
        self.cache.topGuilds = self:CalculateTopGuilds(10)
        self.cache.topZones = self:CalculateTopZones(10)
        self.cache.lastCacheUpdate = now
        
        Crosspaths:DebugLog("Engine cache refreshed", "DEBUG")
    end)
end

-- Get top players by encounter count
function Engine:CalculateTopPlayers(limit)
    limit = limit or 10
    local players = {}
    
    if not Crosspaths.db or not Crosspaths.db.players then
        return players
    end
    
    for name, player in pairs(Crosspaths.db.players) do
        table.insert(players, {
            name = name,
            count = player.count,
            lastSeen = player.lastSeen,
            guild = player.guild,
            grouped = player.grouped,
        })
    end
    
    -- Sort by encounter count
    table.sort(players, function(a, b)
        if a.count == b.count then
            return a.lastSeen > b.lastSeen -- More recent if same count
        end
        return a.count > b.count
    end)
    
    -- Limit results
    local result = {}
    for i = 1, math.min(limit, #players) do
        table.insert(result, players[i])
    end
    
    return result
end

-- Get top guilds by member count
function Engine:CalculateTopGuilds(limit)
    limit = limit or 10
    local guilds = {}
    
    if not Crosspaths.db or not Crosspaths.db.players then
        return guilds
    end
    
    local guildCounts = {}
    local guildMembers = {}
    
    for name, player in pairs(Crosspaths.db.players) do
        if player.guild and player.guild ~= "" then
            if not guildCounts[player.guild] then
                guildCounts[player.guild] = 0
                guildMembers[player.guild] = {}
            end
            guildCounts[player.guild] = guildCounts[player.guild] + 1
            table.insert(guildMembers[player.guild], name)
        end
    end
    
    -- Convert to sortable array
    for guildName, count in pairs(guildCounts) do
        table.insert(guilds, {
            name = guildName,
            memberCount = count,
            members = guildMembers[guildName],
        })
    end
    
    -- Sort by member count
    table.sort(guilds, function(a, b)
        return a.memberCount > b.memberCount
    end)
    
    -- Limit results
    local result = {}
    for i = 1, math.min(limit, #guilds) do
        table.insert(result, guilds[i])
    end
    
    return result
end

-- Get top zones by encounter count
function Engine:CalculateTopZones(limit)
    limit = limit or 10
    local zones = {}
    
    if not Crosspaths.db or not Crosspaths.db.players then
        return zones
    end
    
    local zoneCounts = {}
    
    for name, player in pairs(Crosspaths.db.players) do
        for zone, count in pairs(player.zones or {}) do
            if not zoneCounts[zone] then
                zoneCounts[zone] = 0
            end
            zoneCounts[zone] = zoneCounts[zone] + count
        end
    end
    
    -- Convert to sortable array
    for zone, count in pairs(zoneCounts) do
        table.insert(zones, {
            name = zone,
            encounterCount = count,
        })
    end
    
    -- Sort by encounter count
    table.sort(zones, function(a, b)
        return a.encounterCount > b.encounterCount
    end)
    
    -- Limit results
    local result = {}
    for i = 1, math.min(limit, #zones) do
        table.insert(result, zones[i])
    end
    
    return result
end

-- Get cached or calculate top players
function Engine:GetTopPlayers(limit)
    if #self.cache.topPlayers == 0 then
        return self:CalculateTopPlayers(limit)
    end
    
    limit = limit or #self.cache.topPlayers
    local result = {}
    for i = 1, math.min(limit, #self.cache.topPlayers) do
        table.insert(result, self.cache.topPlayers[i])
    end
    
    return result
end

-- Get cached or calculate top guilds
function Engine:GetTopGuilds(limit)
    if #self.cache.topGuilds == 0 then
        return self:CalculateTopGuilds(limit)
    end
    
    limit = limit or #self.cache.topGuilds
    local result = {}
    for i = 1, math.min(limit, #self.cache.topGuilds) do
        table.insert(result, self.cache.topGuilds[i])
    end
    
    return result
end

-- Get cached or calculate top zones
function Engine:GetTopZones(limit)
    if #self.cache.topZones == 0 then
        return self:CalculateTopZones(limit)
    end
    
    limit = limit or #self.cache.topZones
    local result = {}
    for i = 1, math.min(limit, #self.cache.topZones) do
        table.insert(result, self.cache.topZones[i])
    end
    
    return result
end

-- Get statistics summary
function Engine:GetStatsSummary()
    local stats = {
        totalPlayers = 0,
        totalEncounters = 0,
        totalGuilds = 0,
        groupedPlayers = 0,
        averageEncounters = 0,
        oldestEncounter = nil,
        newestEncounter = nil,
    }
    
    if not Crosspaths.db or not Crosspaths.db.players then
        return stats
    end
    
    local guilds = {}
    local oldestTime = math.huge
    local newestTime = 0
    
    for name, player in pairs(Crosspaths.db.players) do
        stats.totalPlayers = stats.totalPlayers + 1
        stats.totalEncounters = stats.totalEncounters + player.count
        
        if player.grouped then
            stats.groupedPlayers = stats.groupedPlayers + 1
        end
        
        if player.guild and player.guild ~= "" then
            guilds[player.guild] = true
        end
        
        if player.firstSeen < oldestTime then
            oldestTime = player.firstSeen
            stats.oldestEncounter = player.firstSeen
        end
        
        if player.lastSeen > newestTime then
            newestTime = player.lastSeen
            stats.newestEncounter = player.lastSeen
        end
    end
    
    stats.totalGuilds = 0
    for _ in pairs(guilds) do
        stats.totalGuilds = stats.totalGuilds + 1
    end
    
    if stats.totalPlayers > 0 then
        stats.averageEncounters = stats.totalEncounters / stats.totalPlayers
    end
    
    return stats
end

-- Search players
function Engine:SearchPlayers(query, limit)
    limit = limit or 50
    local results = {}
    
    if not query or query == "" then
        return results
    end
    
    if not Crosspaths.db or not Crosspaths.db.players then
        return results
    end
    
    query = string.lower(query)
    
    for name, player in pairs(Crosspaths.db.players) do
        local nameMatch = string.find(string.lower(name), query, 1, true)
        local guildMatch = player.guild and string.find(string.lower(player.guild), query, 1, true)
        local noteMatch = player.notes and string.find(string.lower(player.notes), query, 1, true)
        
        if nameMatch or guildMatch or noteMatch then
            table.insert(results, {
                name = name,
                count = player.count,
                lastSeen = player.lastSeen,
                guild = player.guild,
                grouped = player.grouped,
                notes = player.notes,
            })
        end
        
        if #results >= limit then
            break
        end
    end
    
    -- Sort by relevance (name matches first, then by encounter count)
    table.sort(results, function(a, b)
        local aNameMatch = string.find(string.lower(a.name), query, 1, true) == 1
        local bNameMatch = string.find(string.lower(b.name), query, 1, true) == 1
        
        if aNameMatch and not bNameMatch then
            return true
        elseif bNameMatch and not aNameMatch then
            return false
        else
            return a.count > b.count
        end
    end)
    
    return results
end

-- Get player details
function Engine:GetPlayerDetails(playerName)
    if not Crosspaths.db or not Crosspaths.db.players then
        return nil
    end
    
    local player = Crosspaths.db.players[playerName]
    if not player then
        return nil
    end
    
    -- Calculate additional details
    local details = {
        name = playerName,
        count = player.count,
        firstSeen = player.firstSeen,
        lastSeen = player.lastSeen,
        guild = player.guild,
        grouped = player.grouped,
        notes = player.notes,
        zones = player.zones or {},
        contexts = player.contexts or {},
        daysSinceFirstSeen = 0,
        daysSinceLastSeen = 0,
        topZone = "",
        topContext = "",
    }
    
    -- Calculate days
    local now = time()
    if player.firstSeen then
        details.daysSinceFirstSeen = math.floor((now - player.firstSeen) / (24 * 60 * 60))
    end
    if player.lastSeen then
        details.daysSinceLastSeen = math.floor((now - player.lastSeen) / (24 * 60 * 60))
    end
    
    -- Find top zone
    local maxZoneCount = 0
    for zone, count in pairs(player.zones or {}) do
        if count > maxZoneCount then
            maxZoneCount = count
            details.topZone = zone
        end
    end
    
    -- Find top context
    local maxContextCount = 0
    for context, count in pairs(player.contexts or {}) do
        if count > maxContextCount then
            maxContextCount = count
            details.topContext = context
        end
    end
    
    return details
end

-- Export data
function Engine:ExportData(format)
    format = format or "json"
    
    if format == "json" then
        return self:ExportJSON()
    elseif format == "csv" then
        return self:ExportCSV()
    else
        return "Unsupported format: " .. format
    end
end

-- Export as JSON
function Engine:ExportJSON()
    if not Crosspaths.db then
        return "{}"
    end
    
    -- Helper function to escape JSON strings
    local function escapeJsonString(str)
        if not str then return '""' end
        str = tostring(str)
        -- Escape special JSON characters
        str = string.gsub(str, '\\', '\\\\')  -- Escape backslashes first
        str = string.gsub(str, '"', '\\"')    -- Escape quotes
        str = string.gsub(str, '\n', '\\n')   -- Escape newlines
        str = string.gsub(str, '\r', '\\r')   -- Escape carriage returns
        str = string.gsub(str, '\t', '\\t')   -- Escape tabs
        return '"' .. str .. '"'
    end
    
    -- Simple JSON export with proper escaping
    local lines = {}
    table.insert(lines, "{")
    table.insert(lines, '  "version": ' .. escapeJsonString(Crosspaths.version or "unknown") .. ',')
    table.insert(lines, '  "exportTime": ' .. time() .. ',')
    table.insert(lines, '  "totalPlayers": ' .. self:GetStatsSummary().totalPlayers .. ',')
    table.insert(lines, '  "players": {')
    
    local playerLines = {}
    for name, player in pairs(Crosspaths.db.players or {}) do
        local playerJson = '    ' .. escapeJsonString(name) .. ': {'
        playerJson = playerJson .. '"count": ' .. player.count .. ','
        playerJson = playerJson .. '"firstSeen": ' .. (player.firstSeen or 0) .. ','
        playerJson = playerJson .. '"lastSeen": ' .. (player.lastSeen or 0) .. ','
        playerJson = playerJson .. '"guild": ' .. escapeJsonString(player.guild or "") .. ','
        playerJson = playerJson .. '"grouped": ' .. tostring(player.grouped or false)
        playerJson = playerJson .. '}'
        table.insert(playerLines, playerJson)
    end
    
    table.insert(lines, table.concat(playerLines, ",\n"))
    table.insert(lines, "  }")
    table.insert(lines, "}")
    
    return table.concat(lines, "\n")
end

-- Export as CSV
function Engine:ExportCSV()
    -- Helper function to escape CSV fields
    local function escapeCsvField(str)
        if not str then return '""' end
        str = tostring(str)
        -- If field contains quotes, commas, or newlines, wrap in quotes and escape internal quotes
        if string.find(str, '[",\n\r]') then
            str = string.gsub(str, '"', '""')  -- Escape quotes by doubling them
            str = '"' .. str .. '"'
        end
        return str
    end
    
    local lines = {}
    table.insert(lines, "Name,Count,FirstSeen,LastSeen,Guild,Grouped")
    
    if Crosspaths.db and Crosspaths.db.players then
        for name, player in pairs(Crosspaths.db.players) do
            local line = string.format('%s,%d,%d,%d,%s,%s',
                escapeCsvField(name),
                player.count,
                player.firstSeen or 0,
                player.lastSeen or 0,
                escapeCsvField(player.guild or ""),
                tostring(player.grouped or false)
            )
            table.insert(lines, line)
        end
    end
    
    return table.concat(lines, "\n")
end