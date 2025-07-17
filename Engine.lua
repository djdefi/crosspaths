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

        -- Check for digest schedule
        self:CheckDigestSchedule()

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

-- Get unique player statistics for a specific time period
function Engine:GetUniquePlayerStats(periodDays)
    if not Crosspaths.db or not Crosspaths.db.players then
        return {uniquePlayers = 0, totalEncounters = 0, estimatedPeriodEncounters = 0}
    end

    local now = time()
    local periodSeconds = periodDays * 24 * 60 * 60
    local cutoffTime = now - periodSeconds

    local stats = {
        uniquePlayers = 0,
        totalEncounters = 0,
        estimatedPeriodEncounters = 0
    }

    for name, player in pairs(Crosspaths.db.players) do
        local timeSince = now - (player.lastSeen or 0)
        
        if timeSince <= periodSeconds then
            stats.uniquePlayers = stats.uniquePlayers + 1
            stats.totalEncounters = stats.totalEncounters + (player.count or 0)
            
            -- Estimate encounters that occurred within the period
            local playerActivePeriod = (player.lastSeen or now) - (player.firstSeen or now)
            local playerTotalEncounters = player.count or 0
            
            if playerActivePeriod > 0 and playerTotalEncounters > 0 then
                -- Calculate what portion of the player's activity overlaps with the recent period
                local recentPeriodStart = now - periodSeconds
                local actualPeriodStart = math.max(recentPeriodStart, player.firstSeen or now)
                local periodOverlap = (player.lastSeen or now) - actualPeriodStart
                
                if periodOverlap > 0 then
                    local periodRatio = periodOverlap / playerActivePeriod
                    local estimatedEncounters = math.max(1, math.floor(playerTotalEncounters * periodRatio))
                    stats.estimatedPeriodEncounters = stats.estimatedPeriodEncounters + estimatedEncounters
                else
                    stats.estimatedPeriodEncounters = stats.estimatedPeriodEncounters + 1
                end
            else
                -- If no time data, assume at least 1 encounter
                stats.estimatedPeriodEncounters = stats.estimatedPeriodEncounters + 1
            end
        end
    end

    return stats
end

-- Get activity statistics with better separation of unique players vs encounters
function Engine:GetRecentActivity()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {
            last24h = {players = 0, encounters = 0, uniquePlayers = 0},
            last7d = {players = 0, encounters = 0, uniquePlayers = 0},
            last30d = {players = 0, encounters = 0, uniquePlayers = 0}
        }
    end

    local now = time()
    local day = 24 * 60 * 60
    local week = 7 * day
    local month = 30 * day

    local activity = {
        last24h = {players = 0, encounters = 0, uniquePlayers = 0},
        last7d = {players = 0, encounters = 0, uniquePlayers = 0},
        last30d = {players = 0, encounters = 0, uniquePlayers = 0}
    }

    for name, player in pairs(Crosspaths.db.players) do
        local timeSince = now - (player.lastSeen or 0)

        -- Count unique players seen in each period
        if timeSince <= day then
            activity.last24h.uniquePlayers = activity.last24h.uniquePlayers + 1
        end

        if timeSince <= week then
            activity.last7d.uniquePlayers = activity.last7d.uniquePlayers + 1
        end

        if timeSince <= month then
            activity.last30d.uniquePlayers = activity.last30d.uniquePlayers + 1
        end

        -- Count encounters that occurred within each time period
        -- Note: We estimate encounters based on time periods since we don't store individual encounter timestamps
        -- This is an approximation that assumes encounters are evenly distributed over the player's active period
        local playerActivePeriod = (player.lastSeen or now) - (player.firstSeen or now)
        local playerTotalEncounters = player.count or 0

        if playerActivePeriod > 0 and playerTotalEncounters > 0 then
            local encountersPerSecond = playerTotalEncounters / playerActivePeriod

            -- Calculate estimated encounters in each period
            local dayEncounters = 0
            local weekEncounters = 0
            local monthEncounters = 0

            if timeSince <= day then
                -- If player was seen in last day, estimate encounters in that period
                -- Calculate what portion of the total time window overlaps with the recent period
                local recentPeriodStart = now - day
                local actualPeriodStart = math.max(recentPeriodStart, player.firstSeen or now)
                local periodOverlap = (player.lastSeen or now) - actualPeriodStart
                
                if periodOverlap > 0 and playerActivePeriod > 0 then
                    local periodRatio = periodOverlap / playerActivePeriod
                    dayEncounters = math.max(1, math.floor(playerTotalEncounters * periodRatio))
                else
                    dayEncounters = 1
                end
                activity.last24h.encounters = activity.last24h.encounters + dayEncounters
            end

            if timeSince <= week then
                local recentPeriodStart = now - week
                local actualPeriodStart = math.max(recentPeriodStart, player.firstSeen or now)
                local periodOverlap = (player.lastSeen or now) - actualPeriodStart
                
                if periodOverlap > 0 and playerActivePeriod > 0 then
                    local periodRatio = periodOverlap / playerActivePeriod
                    weekEncounters = math.max(1, math.floor(playerTotalEncounters * periodRatio))
                else
                    weekEncounters = 1
                end
                activity.last7d.encounters = activity.last7d.encounters + weekEncounters
            end

            if timeSince <= month then
                local recentPeriodStart = now - month
                local actualPeriodStart = math.max(recentPeriodStart, player.firstSeen or now)
                local periodOverlap = (player.lastSeen or now) - actualPeriodStart
                
                if periodOverlap > 0 and playerActivePeriod > 0 then
                    local periodRatio = periodOverlap / playerActivePeriod
                    monthEncounters = math.max(1, math.floor(playerTotalEncounters * periodRatio))
                else
                    monthEncounters = 1
                end
                activity.last30d.encounters = activity.last30d.encounters + monthEncounters
            end
        else
            if timeSince <= day then
                -- If no time data, assume at least 1 encounter if seen recently
                activity.last24h.encounters = activity.last24h.encounters + 1
            end
            if timeSince <= week then
                activity.last7d.encounters = activity.last7d.encounters + 1
            end
            if timeSince <= month then
                activity.last30d.encounters = activity.last30d.encounters + 1
            end
        end
    end

    -- Set players count to match uniquePlayers for backward compatibility
    activity.last24h.players = activity.last24h.uniquePlayers
    activity.last7d.players = activity.last7d.uniquePlayers  
    activity.last30d.players = activity.last30d.uniquePlayers

    return activity
end

-- Get encounter context statistics
function Engine:GetContextStats()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {}
    end

    local contextCounts = {}
    local totalContextEncounters = 0

    for name, player in pairs(Crosspaths.db.players) do
        for context, count in pairs(player.contexts or {}) do
            if not contextCounts[context] then
                contextCounts[context] = 0
            end
            contextCounts[context] = contextCounts[context] + count
            totalContextEncounters = totalContextEncounters + count
        end
    end

    local contextStats = {}
    for context, count in pairs(contextCounts) do
        local percentage = totalContextEncounters > 0 and (count / totalContextEncounters * 100) or 0
        table.insert(contextStats, {
            context = context,
            count = count,
            percentage = percentage
        })
    end

    table.sort(contextStats, function(a, b) return a.count > b.count end)

    return contextStats
end

-- Get class distribution statistics
function Engine:GetClassStats()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {}
    end

    local classCounts = {}
    local totalPlayers = 0

    for name, player in pairs(Crosspaths.db.players) do
        local class = player.class or "Unknown"
        if not classCounts[class] then
            classCounts[class] = {count = 0, encounters = 0}
        end
        classCounts[class].count = classCounts[class].count + 1
        classCounts[class].encounters = classCounts[class].encounters + (player.count or 0)
        totalPlayers = totalPlayers + 1
    end

    local classStats = {}
    for class, data in pairs(classCounts) do
        local percentage = totalPlayers > 0 and (data.count / totalPlayers * 100) or 0
        table.insert(classStats, {
            class = class,
            players = data.count,
            encounters = data.encounters,
            percentage = percentage
        })
    end

    table.sort(classStats, function(a, b) return a.players > b.players end)

    return classStats
end

-- Get current session statistics
function Engine:GetSessionStats()
    if not Crosspaths.sessionStats then
        return {
            playersEncountered = 0,
            newPlayers = 0,
            totalEncounters = 0,
            sessionStartTime = time(),
            averageEncounterInterval = 0
        }
    end

    local sessionTime = time() - (Crosspaths.sessionStats.sessionStartTime or time())
    local avgInterval = Crosspaths.sessionStats.totalEncounters > 0 and
                       (sessionTime / Crosspaths.sessionStats.totalEncounters) or 0

    return {
        playersEncountered = Crosspaths.sessionStats.playersEncountered or 0,
        newPlayers = Crosspaths.sessionStats.newPlayers or 0,
        totalEncounters = Crosspaths.sessionStats.totalEncounters or 0,
        sessionStartTime = Crosspaths.sessionStats.sessionStartTime or time(),
        sessionDuration = sessionTime,
        averageEncounterInterval = avgInterval
    }
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

-- Get advanced player statistics
function Engine:GetAdvancedStats()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {}
    end

    local stats = {
        topPlayersByClass = {},
        topTanks = {},
        topHealers = {},
        topDPS = {},
        highestItemLevels = {},
        rareMounts = {},
        commonMounts = {},
        levelProgression = {},
        achievementLeaders = {}
    }

    -- Analyze all players
    local allPlayers = {}
    for name, player in pairs(Crosspaths.db.players) do
        table.insert(allPlayers, {
            name = name,
            count = player.count or 0,
            class = player.class,
            specialization = player.specialization,
            itemLevel = player.itemLevel or 0,
            level = player.level or 0,
            achievementPoints = player.achievementPoints or 0,
            mount = player.mount,
            grouped = player.grouped,
            guild = player.guild
        })
    end

    -- Sort by encounters for general rankings
    table.sort(allPlayers, function(a, b) return a.count > b.count end)

    -- Top players by class
    local classCounts = {}
    for _, player in ipairs(allPlayers) do
        if player.class then
            if not classCounts[player.class] then
                classCounts[player.class] = {}
            end
            table.insert(classCounts[player.class], player)
        end
    end

    for class, players in pairs(classCounts) do
        table.sort(players, function(a, b) return a.count > b.count end)
        stats.topPlayersByClass[class] = {players[1], players[2], players[3]} -- Top 3
    end

    -- Role-based analysis (simplified role detection)
    for _, player in ipairs(allPlayers) do
        if player.specialization then
            local spec = string.lower(player.specialization)
            if string.find(spec, "tank") or string.find(spec, "protection") or string.find(spec, "guardian") or string.find(spec, "brewmaster") or string.find(spec, "vengeance") or string.find(spec, "blood") then
                table.insert(stats.topTanks, player)
            elseif string.find(spec, "heal") or string.find(spec, "restoration") or string.find(spec, "holy") or string.find(spec, "discipline") or string.find(spec, "mistweaver") then
                table.insert(stats.topHealers, player)
            else
                table.insert(stats.topDPS, player)
            end
        end
    end

    -- Sort role lists
    table.sort(stats.topTanks, function(a, b) return a.count > b.count end)
    table.sort(stats.topHealers, function(a, b) return a.count > b.count end)
    table.sort(stats.topDPS, function(a, b) return a.count > b.count end)

    -- Limit to top 10 for each role
    stats.topTanks = {unpack(stats.topTanks, 1, 10)}
    stats.topHealers = {unpack(stats.topHealers, 1, 10)}
    stats.topDPS = {unpack(stats.topDPS, 1, 10)}

    -- Item level analysis
    local playersWithILvl = {}
    for _, player in ipairs(allPlayers) do
        if player.itemLevel > 0 then
            table.insert(playersWithILvl, player)
        end
    end
    table.sort(playersWithILvl, function(a, b) return a.itemLevel > b.itemLevel end)
    stats.highestItemLevels = {unpack(playersWithILvl, 1, 10)}

    -- Mount analysis (if mount data is available)
    local mountCounts = {}
    for _, player in ipairs(allPlayers) do
        if player.mount then
            mountCounts[player.mount] = (mountCounts[player.mount] or 0) + 1
        end
    end

    local mountList = {}
    for mount, count in pairs(mountCounts) do
        table.insert(mountList, {mount = mount, count = count})
    end
    table.sort(mountList, function(a, b) return a.count > b.count end)

    stats.commonMounts = {unpack(mountList, 1, 5)} -- Top 5 most common
    stats.rareMounts = {}
    for _, entry in ipairs(mountList) do
        if entry.count == 1 then -- Only seen once = rare
            table.insert(stats.rareMounts, entry)
        end
    end
    stats.rareMounts = {unpack(stats.rareMounts, 1, 10)} -- Top 10 rarest

    -- Achievement leaders
    local playersWithAchievements = {}
    for _, player in ipairs(allPlayers) do
        if player.achievementPoints > 0 then
            table.insert(playersWithAchievements, player)
        end
    end
    table.sort(playersWithAchievements, function(a, b) return a.achievementPoints > b.achievementPoints end)
    stats.achievementLeaders = {unpack(playersWithAchievements, 1, 10)}

    return stats
end

-- Get specific advanced stat by type
function Engine:GetTopPlayersByType(statType, limit)
    limit = limit or 10
    local advancedStats = self:GetAdvancedStats()

    if statType == "tanks" then
        return {unpack(advancedStats.topTanks, 1, limit)}
    elseif statType == "healers" then
        return {unpack(advancedStats.topHealers, 1, limit)}
    elseif statType == "dps" then
        return {unpack(advancedStats.topDPS, 1, limit)}
    elseif statType == "itemlevel" or statType == "ilvl" then
        return {unpack(advancedStats.highestItemLevels, 1, limit)}
    elseif statType == "achievements" then
        return {unpack(advancedStats.achievementLeaders, 1, limit)}
    else
        return {}
    end
end

-- Generate daily digest report
function Engine:GenerateDailyDigest()
    local now = time()
    local oneDayAgo = now - (24 * 60 * 60)

    local dailyStats = {
        period = "24 hours",
        startTime = oneDayAgo,
        endTime = now,
        newPlayers = 0,
        uniquePlayersActive = 0,
        estimatedEncounters = 0,
        topZones = {},
        topClasses = {},
        newGuilds = 0,
        averageLevel = 0,
        activeDays = 1,
        timestamp = now
    }

    if not Crosspaths.db or not Crosspaths.db.players then
        return dailyStats
    end

    -- Use the utility function to get accurate period statistics
    local periodStats = self:GetUniquePlayerStats(1) -- 1 day
    dailyStats.uniquePlayersActive = periodStats.uniquePlayers
    dailyStats.estimatedEncounters = periodStats.estimatedPeriodEncounters

    local levelSum = 0
    local playerCount = 0
    local zones = {}
    local classes = {}
    local guilds = {}

    for playerName, player in pairs(Crosspaths.db.players) do
        local timeSinceLastSeen = now - (player.lastSeen or 0)
        local timeSinceFirstSeen = now - (player.firstSeen or 0)

        -- Check if player was first seen today (new player)
        if player.firstSeen and player.firstSeen >= oneDayAgo then
            dailyStats.newPlayers = dailyStats.newPlayers + 1
        end

        -- Only include data for players active in the last day
        if timeSinceLastSeen <= (24 * 60 * 60) then
            -- Aggregate level data
            if player.level and player.level > 0 then
                levelSum = levelSum + player.level
                playerCount = playerCount + 1
            end

            -- Aggregate class data
            if player.class then
                classes[player.class] = (classes[player.class] or 0) + 1
            end

            -- Count zones where this player was encountered
            -- Since we don't have time-stamped encounters, we count all zones for active players
            if player.zones then
                for zone, count in pairs(player.zones) do
                    zones[zone] = (zones[zone] or 0) + 1 -- Count unique players per zone
                end
            end

            -- Aggregate guild data (new guilds discovered today)
            if player.guild and player.guild ~= "" and player.firstSeen and player.firstSeen >= oneDayAgo then
                if not guilds[player.guild] then
                    guilds[player.guild] = true
                    dailyStats.newGuilds = dailyStats.newGuilds + 1
                end
            end
        end
    end

    -- Calculate average level
    if playerCount > 0 then
        dailyStats.averageLevel = math.floor(levelSum / playerCount)
    end

    -- Sort and get top zones (by unique players, not encounters)
    local sortedZones = {}
    for zone, playerCount in pairs(zones) do
        table.insert(sortedZones, {zone = zone, count = playerCount})
    end
    table.sort(sortedZones, function(a, b) return a.count > b.count end)
    dailyStats.topZones = {unpack(sortedZones, 1, 5)}

    -- Sort and get top classes
    local sortedClasses = {}
    for class, count in pairs(classes) do
        table.insert(sortedClasses, {class = class, count = count})
    end
    table.sort(sortedClasses, function(a, b) return a.count > b.count end)
    dailyStats.topClasses = {unpack(sortedClasses, 1, 5)}

    return dailyStats
end

-- Generate weekly digest report
function Engine:GenerateWeeklyDigest()
    local now = time()
    local oneWeekAgo = now - (7 * 24 * 60 * 60)

    local weeklyStats = {
        period = "7 days",
        startTime = oneWeekAgo,
        endTime = now,
        newPlayers = 0,
        uniquePlayersActive = 0,
        estimatedEncounters = 0,
        topZones = {},
        topClasses = {},
        topGuilds = {},
        newGuilds = 0,
        averageLevel = 0,
        activeDays = 7, -- Approximate
        timestamp = now
    }

    if not Crosspaths.db or not Crosspaths.db.players then
        return weeklyStats
    end

    -- Use the utility function to get accurate period statistics
    local periodStats = self:GetUniquePlayerStats(7) -- 7 days
    weeklyStats.uniquePlayersActive = periodStats.uniquePlayers
    weeklyStats.estimatedEncounters = periodStats.estimatedPeriodEncounters

    local levelSum = 0
    local playerCount = 0
    local zones = {}
    local classes = {}
    local guilds = {}
    local guildCounts = {}

    for playerName, player in pairs(Crosspaths.db.players) do
        local timeSinceLastSeen = now - (player.lastSeen or 0)

        -- Check if player was first seen this week (new player)
        if player.firstSeen and player.firstSeen >= oneWeekAgo then
            weeklyStats.newPlayers = weeklyStats.newPlayers + 1
        end

        -- Only include data for players active in the last week
        if timeSinceLastSeen <= (7 * 24 * 60 * 60) then
            -- Aggregate level data
            if player.level and player.level > 0 then
                levelSum = levelSum + player.level
                playerCount = playerCount + 1
            end

            -- Aggregate class data
            if player.class then
                classes[player.class] = (classes[player.class] or 0) + 1
            end

            -- Count zones where this player was encountered
            if player.zones then
                for zone, count in pairs(player.zones) do
                    zones[zone] = (zones[zone] or 0) + 1 -- Count unique players per zone
                end
            end

            -- Aggregate guild data
            if player.guild and player.guild ~= "" then
                guildCounts[player.guild] = (guildCounts[player.guild] or 0) + 1
                
                -- Count new guilds discovered this week
                if player.firstSeen and player.firstSeen >= oneWeekAgo then
                    if not guilds[player.guild] then
                        guilds[player.guild] = true
                        weeklyStats.newGuilds = weeklyStats.newGuilds + 1
                    end
                end
            end
        end
    end

    -- Calculate average level
    if playerCount > 0 then
        weeklyStats.averageLevel = math.floor(levelSum / playerCount)
    end

    -- Sort and get top zones (by unique players)
    local sortedZones = {}
    for zone, playerCount in pairs(zones) do
        table.insert(sortedZones, {zone = zone, count = playerCount})
    end
    table.sort(sortedZones, function(a, b) return a.count > b.count end)
    weeklyStats.topZones = {unpack(sortedZones, 1, 5)}

    -- Sort and get top classes
    local sortedClasses = {}
    for class, count in pairs(classes) do
        table.insert(sortedClasses, {class = class, count = count})
    end
    table.sort(sortedClasses, function(a, b) return a.count > b.count end)
    weeklyStats.topClasses = {unpack(sortedClasses, 1, 5)}

    -- Sort and get top guilds
    local sortedGuilds = {}
    for guild, count in pairs(guildCounts) do
        table.insert(sortedGuilds, {guild = guild, count = count})
    end
    table.sort(sortedGuilds, function(a, b) return a.count > b.count end)
    weeklyStats.topGuilds = {unpack(sortedGuilds, 1, 5)}

    return weeklyStats
end

-- Generate monthly digest report
function Engine:GenerateMonthlyDigest()
    local now = time()
    local oneMonthAgo = now - (30 * 24 * 60 * 60)

    local monthlyStats = {
        period = "30 days",
        startTime = oneMonthAgo,
        endTime = now,
        newPlayers = 0,
        uniquePlayersActive = 0,
        estimatedEncounters = 0,
        topZones = {},
        topClasses = {},
        topGuilds = {},
        topPlayers = {},
        newGuilds = 0,
        averageLevel = 0,
        activeDays = 30, -- Approximate
        peakDayEncounters = 0,
        peakDay = "",
        timestamp = now
    }

    if not Crosspaths.db or not Crosspaths.db.players then
        return monthlyStats
    end

    -- Use the utility function to get accurate period statistics
    local periodStats = self:GetUniquePlayerStats(30) -- 30 days
    monthlyStats.uniquePlayersActive = periodStats.uniquePlayers
    monthlyStats.estimatedEncounters = periodStats.estimatedPeriodEncounters

    local levelSum = 0
    local playerCount = 0
    local zones = {}
    local classes = {}
    local guildCounts = {}
    local guilds = {}
    local activePlayers = {}

    for playerName, player in pairs(Crosspaths.db.players) do
        local timeSinceLastSeen = now - (player.lastSeen or 0)

        -- Check if player was first seen this month (new player)
        if player.firstSeen and player.firstSeen >= oneMonthAgo then
            monthlyStats.newPlayers = monthlyStats.newPlayers + 1
        end

        -- Only include data for players active in the last month
        if timeSinceLastSeen <= (30 * 24 * 60 * 60) then
            -- Track active players for top players list
            table.insert(activePlayers, {
                name = playerName, 
                count = player.count or 0,
                lastSeen = player.lastSeen
            })

            -- Aggregate level data
            if player.level and player.level > 0 then
                levelSum = levelSum + player.level
                playerCount = playerCount + 1
            end

            -- Aggregate class data
            if player.class then
                classes[player.class] = (classes[player.class] or 0) + 1
            end

            -- Count zones where this player was encountered
            if player.zones then
                for zone, count in pairs(player.zones) do
                    zones[zone] = (zones[zone] or 0) + 1 -- Count unique players per zone
                end
            end

            -- Aggregate guild data
            if player.guild and player.guild ~= "" then
                guildCounts[player.guild] = (guildCounts[player.guild] or 0) + 1
                
                -- Count new guilds discovered this month
                if player.firstSeen and player.firstSeen >= oneMonthAgo then
                    if not guilds[player.guild] then
                        guilds[player.guild] = true
                        monthlyStats.newGuilds = monthlyStats.newGuilds + 1
                    end
                end
            end
        end
    end

    -- Calculate average level
    if playerCount > 0 then
        monthlyStats.averageLevel = math.floor(levelSum / playerCount)
    end

    -- Sort and get top players (by total encounters)
    table.sort(activePlayers, function(a, b) return a.count > b.count end)
    monthlyStats.topPlayers = {unpack(activePlayers, 1, 10)}

    -- Sort and get top zones (by unique players)
    local sortedZones = {}
    for zone, playerCount in pairs(zones) do
        table.insert(sortedZones, {zone = zone, count = playerCount})
    end
    table.sort(sortedZones, function(a, b) return a.count > b.count end)
    monthlyStats.topZones = {unpack(sortedZones, 1, 10)}

    -- Sort and get top classes
    local sortedClasses = {}
    for class, count in pairs(classes) do
        table.insert(sortedClasses, {class = class, count = count})
    end
    table.sort(sortedClasses, function(a, b) return a.count > b.count end)
    monthlyStats.topClasses = {unpack(sortedClasses, 1, 5)}

    -- Sort and get top guilds
    local sortedGuilds = {}
    for guild, count in pairs(guildCounts) do
        table.insert(sortedGuilds, {guild = guild, count = count})
    end
    table.sort(sortedGuilds, function(a, b) return a.count > b.count end)
    monthlyStats.topGuilds = {unpack(sortedGuilds, 1, 10)}

    -- Estimate peak day (simplified approach)
    if monthlyStats.estimatedEncounters > 0 then
        monthlyStats.peakDayEncounters = math.floor(monthlyStats.estimatedEncounters / 30 * 1.5) -- Assume peak day is 50% above average
        monthlyStats.peakDay = "Estimated peak activity"
    end

    return monthlyStats
end

    -- Sort and get top guilds
    local sortedGuilds = {}
    for guild, count in pairs(guilds) do
        table.insert(sortedGuilds, {guild = guild, count = count})
    end
    table.sort(sortedGuilds, function(a, b) return a.count > b.count end)
    monthlyStats.topGuilds = {unpack(sortedGuilds, 1, 10)}

    return monthlyStats
end

-- Schedule digest notifications
function Engine:CheckDigestSchedule()
    if not Crosspaths.db or not Crosspaths.db.settings.digests then
        return
    end

    local settings = Crosspaths.db.settings.digests
    local now = time()

    -- Check daily digest
    if settings.enableDaily then
        local lastDaily = Crosspaths.db.lastDigests and Crosspaths.db.lastDigests.daily or 0
        local daysSinceLastDaily = math.floor((now - lastDaily) / (24 * 60 * 60))

        if daysSinceLastDaily >= 1 then
            if settings.autoNotify then
                local digest = self:GenerateDailyDigest()
                self:ShowDigestNotification("Daily Summary", digest)
            end

            if not Crosspaths.db.lastDigests then
                Crosspaths.db.lastDigests = {}
            end
            Crosspaths.db.lastDigests.daily = now
        end
    end

    -- Check weekly digest
    if settings.enableWeekly then
        local lastWeekly = Crosspaths.db.lastDigests and Crosspaths.db.lastDigests.weekly or 0
        local daysSinceLastWeekly = math.floor((now - lastWeekly) / (24 * 60 * 60))

        if daysSinceLastWeekly >= 7 then
            if settings.autoNotify then
                local digest = self:GenerateWeeklyDigest()
                self:ShowDigestNotification("Weekly Summary", digest)
            end

            if not Crosspaths.db.lastDigests then
                Crosspaths.db.lastDigests = {}
            end
            Crosspaths.db.lastDigests.weekly = now
        end
    end

    -- Check monthly digest
    if settings.enableMonthly then
        local lastMonthly = Crosspaths.db.lastDigests and Crosspaths.db.lastDigests.monthly or 0
        local daysSinceLastMonthly = math.floor((now - lastMonthly) / (24 * 60 * 60))

        if daysSinceLastMonthly >= 30 then
            if settings.autoNotify then
                local digest = self:GenerateMonthlyDigest()
                self:ShowDigestNotification("Monthly Summary", digest)
            end

            if not Crosspaths.db.lastDigests then
                Crosspaths.db.lastDigests = {}
            end
            Crosspaths.db.lastDigests.monthly = now
        end
    end
end

-- Show digest notification
function Engine:ShowDigestNotification(title, digest)
    local message = string.format("%d new players, %d encounters", digest.newPlayers, digest.totalEncounters)
    if Crosspaths.UI and Crosspaths.UI.ShowToast then
        Crosspaths.UI:ShowToast(title, message, "digest")
    end
end