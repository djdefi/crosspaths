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

-- Get recent activity statistics
function Engine:GetRecentActivity()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {
            last24h = {players = 0, encounters = 0},
            last7d = {players = 0, encounters = 0},
            last30d = {players = 0, encounters = 0}
        }
    end

    local now = time()
    local day = 24 * 60 * 60
    local week = 7 * day
    local month = 30 * day

    local activity = {
        last24h = {players = 0, encounters = 0},
        last7d = {players = 0, encounters = 0},
        last30d = {players = 0, encounters = 0}
    }

    for name, player in pairs(Crosspaths.db.players) do
        local timeSince = now - (player.lastSeen or 0)

        if timeSince <= day then
            activity.last24h.players = activity.last24h.players + 1
            activity.last24h.encounters = activity.last24h.encounters + player.count
        end

        if timeSince <= week then
            activity.last7d.players = activity.last7d.players + 1
            activity.last7d.encounters = activity.last7d.encounters + player.count
        end

        if timeSince <= month then
            activity.last30d.players = activity.last30d.players + 1
            activity.last30d.encounters = activity.last30d.encounters + player.count
        end
    end

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
    -- Ensure sessionStats is properly initialized
    if not Crosspaths.sessionStats or type(Crosspaths.sessionStats) ~= "table" then
        Crosspaths:DebugLog("SessionStats not initialized, reinitializing", "WARNING")
        if Crosspaths.InitializeSessionStats then
            Crosspaths:InitializeSessionStats()
        else
            Crosspaths.sessionStats = {
                sessionStartTime = time(),
                totalEncounters = 0,
                playersEncountered = 0,
                newPlayers = 0,
                eventsHandled = 0
            }
        end
    end

    -- Ensure all required fields exist
    if not Crosspaths.sessionStats.sessionStartTime then
        Crosspaths.sessionStats.sessionStartTime = time()
    end
    if not Crosspaths.sessionStats.totalEncounters then
        Crosspaths.sessionStats.totalEncounters = 0
    end
    if not Crosspaths.sessionStats.playersEncountered then
        Crosspaths.sessionStats.playersEncountered = 0
    end
    if not Crosspaths.sessionStats.newPlayers then
        Crosspaths.sessionStats.newPlayers = 0
    end

    local sessionTime = time() - (Crosspaths.sessionStats.sessionStartTime or time())
    local totalEncounters = Crosspaths.sessionStats.totalEncounters or 0
    local avgInterval = totalEncounters > 0 and (sessionTime / totalEncounters) or 0

    return {
        playersEncountered = Crosspaths.sessionStats.playersEncountered or 0,
        newPlayers = Crosspaths.sessionStats.newPlayers or 0,
        totalEncounters = totalEncounters,
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
        totalEncounters = 0,
        topZones = {},
        topClasses = {},
        newGuilds = 0,
        averageLevel = 0,
        timestamp = now
    }

    if not Crosspaths.db or not Crosspaths.db.players then
        return dailyStats
    end

    local levelSum = 0
    local playerCount = 0
    local zones = {}
    local classes = {}
    local guilds = {}

    for playerName, player in pairs(Crosspaths.db.players) do
        if player.encounters then
            for _, encounter in ipairs(player.encounters) do
                if encounter.timestamp and encounter.timestamp >= oneDayAgo then
                    dailyStats.totalEncounters = dailyStats.totalEncounters + 1

                    if encounter.zone then
                        zones[encounter.zone] = (zones[encounter.zone] or 0) + 1
                    end
                end
            end
        end

        -- Check if player was first seen today
        if player.firstSeen and player.firstSeen >= oneDayAgo then
            dailyStats.newPlayers = dailyStats.newPlayers + 1
        end

        -- Aggregate level data
        if player.level and player.level > 0 then
            levelSum = levelSum + player.level
            playerCount = playerCount + 1
        end

        -- Aggregate class data
        if player.class then
            classes[player.class] = (classes[player.class] or 0) + 1
        end

        -- Aggregate guild data
        if player.guild and player.firstSeen and player.firstSeen >= oneDayAgo then
            if not guilds[player.guild] then
                guilds[player.guild] = true
                dailyStats.newGuilds = dailyStats.newGuilds + 1
            end
        end
    end

    -- Calculate average level
    if playerCount > 0 then
        dailyStats.averageLevel = math.floor(levelSum / playerCount)
    end

    -- Sort and get top zones
    local sortedZones = {}
    for zone, count in pairs(zones) do
        table.insert(sortedZones, {zone = zone, count = count})
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
        totalEncounters = 0,
        topZones = {},
        topClasses = {},
        topGuilds = {},
        newGuilds = 0,
        averageLevel = 0,
        activeDays = 0,
        timestamp = now
    }

    if not Crosspaths.db or not Crosspaths.db.players then
        return weeklyStats
    end

    local levelSum = 0
    local playerCount = 0
    local zones = {}
    local classes = {}
    local guilds = {}
    local activeDays = {}

    for playerName, player in pairs(Crosspaths.db.players) do
        if player.encounters then
            for _, encounter in ipairs(player.encounters) do
                if encounter.timestamp and encounter.timestamp >= oneWeekAgo then
                    weeklyStats.totalEncounters = weeklyStats.totalEncounters + 1

                    if encounter.zone then
                        zones[encounter.zone] = (zones[encounter.zone] or 0) + 1
                    end

                    -- Track active days
                    local dayKey = os.date("%Y-%m-%d", encounter.timestamp)
                    activeDays[dayKey] = true
                end
            end
        end

        -- Check if player was first seen this week
        if player.firstSeen and player.firstSeen >= oneWeekAgo then
            weeklyStats.newPlayers = weeklyStats.newPlayers + 1
        end

        -- Aggregate level data
        if player.level and player.level > 0 then
            levelSum = levelSum + player.level
            playerCount = playerCount + 1
        end

        -- Aggregate class data
        if player.class then
            classes[player.class] = (classes[player.class] or 0) + 1
        end

        -- Aggregate guild data
        if player.guild then
            guilds[player.guild] = (guilds[player.guild] or 0) + 1
            if player.firstSeen and player.firstSeen >= oneWeekAgo then
                weeklyStats.newGuilds = weeklyStats.newGuilds + 1
            end
        end
    end

    -- Calculate average level
    if playerCount > 0 then
        weeklyStats.averageLevel = math.floor(levelSum / playerCount)
    end

    -- Count active days
    for _ in pairs(activeDays) do
        weeklyStats.activeDays = weeklyStats.activeDays + 1
    end

    -- Sort and get top zones
    local sortedZones = {}
    for zone, count in pairs(zones) do
        table.insert(sortedZones, {zone = zone, count = count})
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
    for guild, count in pairs(guilds) do
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
        totalEncounters = 0,
        topZones = {},
        topClasses = {},
        topGuilds = {},
        topPlayers = {},
        newGuilds = 0,
        averageLevel = 0,
        activeDays = 0,
        peakDayEncounters = 0,
        peakDay = "",
        timestamp = now
    }

    if not Crosspaths.db or not Crosspaths.db.players then
        return monthlyStats
    end

    local levelSum = 0
    local playerCount = 0
    local zones = {}
    local classes = {}
    local guilds = {}
    local players = {}
    local dailyEncounters = {}

    for playerName, player in pairs(Crosspaths.db.players) do
        local playerEncounters = 0

        if player.encounters then
            for _, encounter in ipairs(player.encounters) do
                if encounter.timestamp and encounter.timestamp >= oneMonthAgo then
                    monthlyStats.totalEncounters = monthlyStats.totalEncounters + 1
                    playerEncounters = playerEncounters + 1

                    if encounter.zone then
                        zones[encounter.zone] = (zones[encounter.zone] or 0) + 1
                    end

                    -- Track daily encounters
                    local dayKey = os.date("%Y-%m-%d", encounter.timestamp)
                    dailyEncounters[dayKey] = (dailyEncounters[dayKey] or 0) + 1
                end
            end
        end

        -- Track player encounter counts
        if playerEncounters > 0 then
            table.insert(players, {name = playerName, count = playerEncounters})
        end

        -- Check if player was first seen this month
        if player.firstSeen and player.firstSeen >= oneMonthAgo then
            monthlyStats.newPlayers = monthlyStats.newPlayers + 1
        end

        -- Aggregate level data
        if player.level and player.level > 0 then
            levelSum = levelSum + player.level
            playerCount = playerCount + 1
        end

        -- Aggregate class data
        if player.class then
            classes[player.class] = (classes[player.class] or 0) + 1
        end

        -- Aggregate guild data
        if player.guild then
            guilds[player.guild] = (guilds[player.guild] or 0) + 1
            if player.firstSeen and player.firstSeen >= oneMonthAgo then
                monthlyStats.newGuilds = monthlyStats.newGuilds + 1
            end
        end
    end

    -- Calculate average level
    if playerCount > 0 then
        monthlyStats.averageLevel = math.floor(levelSum / playerCount)
    end

    -- Find peak day
    local peakDay = ""
    local peakCount = 0
    for day, count in pairs(dailyEncounters) do
        if count > peakCount then
            peakCount = count
            peakDay = day
        end
    end
    monthlyStats.peakDay = peakDay
    monthlyStats.peakDayEncounters = peakCount
    monthlyStats.activeDays = 0
    for _ in pairs(dailyEncounters) do
        monthlyStats.activeDays = monthlyStats.activeDays + 1
    end

    -- Sort and get top players
    table.sort(players, function(a, b) return a.count > b.count end)
    monthlyStats.topPlayers = {unpack(players, 1, 10)}

    -- Sort and get top zones
    local sortedZones = {}
    for zone, count in pairs(zones) do
        table.insert(sortedZones, {zone = zone, count = count})
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

-- ============================================================================
-- DATA QUALITY AND CLEANUP FUNCTIONS
-- ============================================================================

-- Comprehensive data validation and cleanup
function Engine:ValidateAndCleanData()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {
            duplicatesRemoved = 0,
            invalidEncounters = 0,
            normalizedNames = 0,
            totalCleaned = 0
        }
    end

    local stats = {
        duplicatesRemoved = 0,
        invalidEncounters = 0,
        normalizedNames = 0,
        invalidLevels = 0,
        futureTimestamps = 0,
        totalCleaned = 0
    }

    local now = time()

    Crosspaths:DebugLog("Starting comprehensive data validation and cleanup", "INFO")

    for playerName, player in pairs(Crosspaths.db.players) do
        if player.encounters then
            -- Clean encounters array
            local cleanEncounters = {}
            local encounterMap = {} -- For duplicate detection

            for _, encounter in ipairs(player.encounters) do
                local isValid = true
                local cleanReason = nil

                -- Validate timestamp
                if not encounter.timestamp or encounter.timestamp > now or encounter.timestamp < 1000000000 then
                    isValid = false
                    cleanReason = "invalid timestamp"
                    stats.invalidEncounters = stats.invalidEncounters + 1
                    if encounter.timestamp and encounter.timestamp > now then
                        stats.futureTimestamps = stats.futureTimestamps + 1
                    end
                end

                -- Validate level
                if encounter.level and (encounter.level < 1 or encounter.level > 80) then
                    encounter.level = nil -- Fix rather than remove
                    stats.invalidLevels = stats.invalidLevels + 1
                end

                -- Normalize zone name
                if encounter.zone then
                    encounter.zone = self:NormalizeZoneName(encounter.zone)
                end

                if isValid then
                    -- Check for duplicates (same zone within 30 seconds)
                    local encounterKey = string.format("%s_%s_%d",
                        encounter.zone or "unknown",
                        encounter.instance or "world",
                        math.floor((encounter.timestamp or 0) / 30)) -- 30-second windows

                    if encounterMap[encounterKey] then
                        stats.duplicatesRemoved = stats.duplicatesRemoved + 1
                        Crosspaths:DebugLog(string.format("Removed duplicate encounter for %s in %s",
                            playerName, encounter.zone or "unknown"), "DEBUG")
                    else
                        encounterMap[encounterKey] = true
                        table.insert(cleanEncounters, encounter)
                    end
                else
                    Crosspaths:DebugLog(string.format("Removed invalid encounter for %s: %s",
                        playerName, cleanReason or "unknown"), "DEBUG")
                end
            end

            player.encounters = cleanEncounters
            player.count = #cleanEncounters
        end

        -- Normalize guild name
        if player.guild then
            local normalizedGuild = self:NormalizeGuildName(player.guild)
            if normalizedGuild ~= player.guild then
                player.guild = normalizedGuild
                stats.normalizedNames = stats.normalizedNames + 1
            end
        end

        -- Validate level
        if player.level and (player.level < 1 or player.level > 80) then
            player.level = nil
            stats.invalidLevels = stats.invalidLevels + 1
        end
    end

    stats.totalCleaned = stats.duplicatesRemoved + stats.invalidEncounters + stats.invalidLevels + stats.futureTimestamps

    Crosspaths:DebugLog(string.format("Data cleanup completed: %d duplicates, %d invalid encounters, %d invalid levels, %d future timestamps, %d normalized names",
        stats.duplicatesRemoved, stats.invalidEncounters, stats.invalidLevels, stats.futureTimestamps, stats.normalizedNames), "INFO")

    return stats
end

-- Normalize zone names for consistency
function Engine:NormalizeZoneName(zoneName)
    if not zoneName then return nil end

    -- Remove leading/trailing whitespace and normalize case
    local normalized = strtrim(zoneName)

    -- Common zone name standardizations
    local zoneMap = {
        ["Stormwind"] = "Stormwind City",
        ["Orgrimmar"] = "Orgrimmar",
        ["IF"] = "Ironforge",
        ["Ironforge "] = "Ironforge",
        ["Thunder Bluff"] = "Thunder Bluff",
        ["Undercity"] = "Undercity",
        ["Darnassus"] = "Teldrassil",
        ["SW"] = "Stormwind City",
        ["Org"] = "Orgrimmar",
        ["TB"] = "Thunder Bluff",
        ["UC"] = "Undercity"
    }

    return zoneMap[normalized] or normalized
end

-- Normalize guild names for consistency
function Engine:NormalizeGuildName(guildName)
    if not guildName then return nil end

    -- Remove special characters and extra spaces
    local normalized = string.gsub(guildName, "[%s%p]+", " ")
    normalized = strtrim(normalized)

    return normalized
end

-- Detect and merge potential duplicate players
function Engine:DetectDuplicatePlayers()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {}
    end

    local potentialDuplicates = {}
    local playersByBaseName = {}

    -- Group players by base name (without realm)
    for fullName, player in pairs(Crosspaths.db.players) do
        local baseName = strsplit("-", fullName) or fullName
        if not playersByBaseName[baseName] then
            playersByBaseName[baseName] = {}
        end
        table.insert(playersByBaseName[baseName], {name = fullName, data = player})
    end

    -- Find groups with multiple entries
    for baseName, players in pairs(playersByBaseName) do
        if #players > 1 then
            table.insert(potentialDuplicates, {
                baseName = baseName,
                players = players,
                confidence = self:CalculateDuplicateConfidence(players)
            })
        end
    end

    -- Sort by confidence
    table.sort(potentialDuplicates, function(a, b) return a.confidence > b.confidence end)

    return potentialDuplicates
end

-- Calculate confidence that players are duplicates
function Engine:CalculateDuplicateConfidence(players)
    if #players < 2 then return 0 end

    local confidence = 0
    local firstPlayer = players[1].data

    for i = 2, #players do
        local otherPlayer = players[i].data
        local similarity = 0

        -- Same guild increases confidence
        if firstPlayer.guild and otherPlayer.guild and firstPlayer.guild == otherPlayer.guild then
            similarity = similarity + 40
        end

        -- Similar level increases confidence
        if firstPlayer.level and otherPlayer.level then
            local levelDiff = math.abs(firstPlayer.level - otherPlayer.level)
            if levelDiff <= 2 then
                similarity = similarity + 30
            elseif levelDiff <= 5 then
                similarity = similarity + 15
            end
        end

        -- Same class increases confidence
        if firstPlayer.class and otherPlayer.class and firstPlayer.class == otherPlayer.class then
            similarity = similarity + 20
        end

        -- Overlapping zones increases confidence
        local zoneOverlap = self:CalculateZoneOverlap(firstPlayer, otherPlayer)
        similarity = similarity + (zoneOverlap * 10)

        confidence = math.max(confidence, similarity)
    end

    return confidence
end

-- Calculate zone overlap between two players
function Engine:CalculateZoneOverlap(player1, player2)
    if not player1.encounters or not player2.encounters then return 0 end

    local zones1 = {}
    local zones2 = {}

    for _, encounter in ipairs(player1.encounters) do
        if encounter.zone then
            zones1[encounter.zone] = true
        end
    end

    for _, encounter in ipairs(player2.encounters) do
        if encounter.zone then
            zones2[encounter.zone] = true
        end
    end

    local overlap = 0
    local total = 0

    for zone in pairs(zones1) do
        total = total + 1
        if zones2[zone] then
            overlap = overlap + 1
        end
    end

    for zone in pairs(zones2) do
        if not zones1[zone] then
            total = total + 1
        end
    end

    return total > 0 and (overlap / total) or 0
end

-- ============================================================================
-- ENHANCED ANALYTICS AND TRENDS
-- ============================================================================

-- Analyze activity patterns by hour of day
function Engine:AnalyzeActivityPatterns()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {}
    end

    local hourlyActivity = {}
    for i = 0, 23 do
        hourlyActivity[i] = 0
    end

    local dailyActivity = {}
    for i = 1, 7 do -- Sunday = 1, Monday = 2, etc.
        dailyActivity[i] = 0
    end

    for playerName, player in pairs(Crosspaths.db.players) do
        if player.encounters then
            for _, encounter in ipairs(player.encounters) do
                if encounter.timestamp then
                    -- Hour analysis
                    local hour = tonumber(date("%H", encounter.timestamp))
                    if hour then
                        hourlyActivity[hour] = hourlyActivity[hour] + 1
                    end

                    -- Day of week analysis
                    local dayOfWeek = tonumber(date("%w", encounter.timestamp)) + 1 -- Convert 0-6 to 1-7
                    dailyActivity[dayOfWeek] = dailyActivity[dayOfWeek] + 1
                end
            end
        end
    end

    -- Find peak times
    local peakHour = 0
    local peakHourCount = 0
    for hour, count in pairs(hourlyActivity) do
        if count > peakHourCount then
            peakHour = hour
            peakHourCount = count
        end
    end

    local peakDay = 1
    local peakDayCount = 0
    for day, count in pairs(dailyActivity) do
        if count > peakDayCount then
            peakDay = day
            peakDayCount = count
        end
    end

    local dayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

    return {
        hourlyActivity = hourlyActivity,
        dailyActivity = dailyActivity,
        peakHour = peakHour,
        peakHourCount = peakHourCount,
        peakDay = dayNames[peakDay],
        peakDayCount = peakDayCount
    }
end

-- Analyze social network connections
function Engine:AnalyzeSocialNetworks()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {}
    end

    local connections = {}
    local strongConnections = {} -- Players encountered multiple times

    for playerName, player in pairs(Crosspaths.db.players) do
        connections[playerName] = {}

        if player.encounters then
            -- Group encounters by zone to find co-location patterns
            local zoneEncounters = {}
            for _, encounter in ipairs(player.encounters) do
                if encounter.zone then
                    if not zoneEncounters[encounter.zone] then
                        zoneEncounters[encounter.zone] = {}
                    end
                    table.insert(zoneEncounters[encounter.zone], encounter)
                end
            end

            connections[playerName].zones = zoneEncounters
            connections[playerName].totalEncounters = #player.encounters
            connections[playerName].diversity = self:CalculateEncounterDiversity(player)
        end
    end

    -- Find players with strong connections (multiple encounters in same zones)
    for playerName, data in pairs(connections) do
        for zoneName, encounters in pairs(data.zones or {}) do
            if #encounters >= 3 then -- 3+ encounters in same zone indicates strong connection
                if not strongConnections[zoneName] then
                    strongConnections[zoneName] = {}
                end
                table.insert(strongConnections[zoneName], {
                    player = playerName,
                    encounters = #encounters,
                    strength = #encounters / data.totalEncounters
                })
            end
        end
    end

    return {
        totalConnections = self:CountTotalPlayers(),
        strongConnections = strongConnections,
        networkDensity = self:CalculateNetworkDensity(),
        topSocialHubs = self:FindTopSocialHubs()
    }
end

-- Calculate encounter diversity for a player
function Engine:CalculateEncounterDiversity(player)
    if not player.encounters then return 0 end

    local zones = {}
    for _, encounter in ipairs(player.encounters) do
        if encounter.zone then
            zones[encounter.zone] = true
        end
    end

    local uniqueZones = 0
    for _ in pairs(zones) do
        uniqueZones = uniqueZones + 1
    end

    return #player.encounters > 0 and (uniqueZones / #player.encounters) or 0
end

-- Calculate network density
function Engine:CalculateNetworkDensity()
    local totalPlayers = self:CountTotalPlayers()
    if totalPlayers < 2 then return 0 end

    -- Simplified density calculation based on shared zones
    local sharedZoneConnections = 0
    local zonePlayerCounts = {}

    for playerName, player in pairs(Crosspaths.db.players or {}) do
        if player.encounters then
            local playerZones = {}
            for _, encounter in ipairs(player.encounters) do
                if encounter.zone and not playerZones[encounter.zone] then
                    playerZones[encounter.zone] = true
                    zonePlayerCounts[encounter.zone] = (zonePlayerCounts[encounter.zone] or 0) + 1
                end
            end
        end
    end

    -- Count potential connections (players who shared zones)
    for zone, count in pairs(zonePlayerCounts) do
        if count > 1 then
            sharedZoneConnections = sharedZoneConnections + (count * (count - 1) / 2) -- Combinations
        end
    end

    local maxPossibleConnections = totalPlayers * (totalPlayers - 1) / 2
    return maxPossibleConnections > 0 and (sharedZoneConnections / maxPossibleConnections) or 0
end

-- Find top social hubs (zones with most player interactions)
function Engine:FindTopSocialHubs()
    local zoneStats = {}

    for playerName, player in pairs(Crosspaths.db.players or {}) do
        if player.encounters then
            for _, encounter in ipairs(player.encounters) do
                if encounter.zone then
                    if not zoneStats[encounter.zone] then
                        zoneStats[encounter.zone] = {
                            uniquePlayers = {},
                            totalEncounters = 0
                        }
                    end
                    zoneStats[encounter.zone].uniquePlayers[playerName] = true
                    zoneStats[encounter.zone].totalEncounters = zoneStats[encounter.zone].totalEncounters + 1
                end
            end
        end
    end

    -- Convert to sorted list
    local socialHubs = {}
    for zone, stats in pairs(zoneStats) do
        local uniquePlayerCount = 0
        for _ in pairs(stats.uniquePlayers) do
            uniquePlayerCount = uniquePlayerCount + 1
        end

        table.insert(socialHubs, {
            zone = zone,
            uniquePlayers = uniquePlayerCount,
            totalEncounters = stats.totalEncounters,
            density = stats.totalEncounters / uniquePlayerCount
        })
    end

    table.sort(socialHubs, function(a, b) return a.uniquePlayers > b.uniquePlayers end)

    return {unpack(socialHubs, 1, 10)} -- Top 10
end

-- Analyze progression trends
function Engine:AnalyzeProgressionTrends()
    if not Crosspaths.db or not Crosspaths.db.players then
        return {}
    end

    local levelTrends = {}
    local guildProgression = {}
    local classDistribution = {}

    for playerName, player in pairs(Crosspaths.db.players) do
        -- Level progression analysis
        if player.encounters and #player.encounters > 1 then
            local firstEncounter = player.encounters[1]
            local lastEncounter = player.encounters[#player.encounters]

            if firstEncounter.level and lastEncounter.level and firstEncounter.timestamp and lastEncounter.timestamp then
                local levelGain = lastEncounter.level - firstEncounter.level
                local timeDiff = lastEncounter.timestamp - firstEncounter.timestamp

                if levelGain > 0 and timeDiff > 0 then
                    table.insert(levelTrends, {
                        player = playerName,
                        levelGain = levelGain,
                        timeSpan = timeDiff,
                        rate = levelGain / (timeDiff / (24 * 60 * 60)) -- levels per day
                    })
                end
            end
        end

        -- Class distribution
        if player.class then
            classDistribution[player.class] = (classDistribution[player.class] or 0) + 1
        end

        -- Guild progression tracking
        if player.guild then
            if not guildProgression[player.guild] then
                guildProgression[player.guild] = {
                    members = {},
                    totalLevels = 0,
                    encounters = 0
                }
            end
            guildProgression[player.guild].members[playerName] = true
            if player.level then
                guildProgression[player.guild].totalLevels = guildProgression[player.guild].totalLevels + player.level
            end
            guildProgression[player.guild].encounters = guildProgression[player.guild].encounters + (player.count or 0)
        end
    end

    -- Calculate guild averages
    for guildName, data in pairs(guildProgression) do
        local memberCount = 0
        for _ in pairs(data.members) do
            memberCount = memberCount + 1
        end
        data.memberCount = memberCount
        data.averageLevel = memberCount > 0 and (data.totalLevels / memberCount) or 0
        data.encountersPerMember = memberCount > 0 and (data.encounters / memberCount) or 0
    end

    -- Sort trends
    table.sort(levelTrends, function(a, b) return a.rate > b.rate end)

    return {
        levelTrends = {unpack(levelTrends, 1, 20)}, -- Top 20 fastest progressors
        classDistribution = classDistribution,
        guildProgression = guildProgression,
        averageLevelGain = self:CalculateAverageLevelGain(levelTrends)
    }
end

-- Calculate average level gain rate
function Engine:CalculateAverageLevelGain(levelTrends)
    if #levelTrends == 0 then return 0 end

    local totalRate = 0
    for _, trend in ipairs(levelTrends) do
        totalRate = totalRate + trend.rate
    end

    return totalRate / #levelTrends
end

-- Count total players
function Engine:CountTotalPlayers()
    if not Crosspaths.db or not Crosspaths.db.players then return 0 end

    local count = 0
    for _ in pairs(Crosspaths.db.players) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- QUEST LINE AND PATH ANALYTICS
-- ============================================================================

-- Get zone progression patterns for path analysis
function Engine:GetZoneProgressionPatterns(timeWindow)
    timeWindow = timeWindow or (7 * 24 * 60 * 60) -- Default 7 days
    local cutoffTime = time() - timeWindow
    
    if not Crosspaths.db or not Crosspaths.db.players then
        return {
            patterns = {},
            totalPlayers = 0,
            commonPaths = {},
            questLineCorrelations = {}
        }
    end
    
    local playerPaths = {}
    local zonePairs = {}
    local zoneSequences = {}
    
    Crosspaths:DebugLog("Analyzing zone progression patterns for quest line detection", "INFO")
    
    -- Extract zone progression for each player
    for playerName, player in pairs(Crosspaths.db.players) do
        if player.encounters then
            local playerZones = {}
            
            -- Get chronologically ordered encounters within time window
            local recentEncounters = {}
            for _, encounter in ipairs(player.encounters) do
                if encounter.timestamp and encounter.timestamp >= cutoffTime and encounter.zone then
                    table.insert(recentEncounters, encounter)
                end
            end
            
            -- Sort by timestamp
            table.sort(recentEncounters, function(a, b) return a.timestamp < b.timestamp end)
            
            -- Extract zone progression path
            local lastZone = nil
            for _, encounter in ipairs(recentEncounters) do
                local zone = self:NormalizeZoneName(encounter.zone)
                if zone ~= lastZone then
                    table.insert(playerZones, {
                        zone = zone,
                        timestamp = encounter.timestamp,
                        level = encounter.level
                    })
                    
                    -- Track zone transitions
                    if lastZone then
                        local pairKey = lastZone .. " -> " .. zone
                        zonePairs[pairKey] = (zonePairs[pairKey] or 0) + 1
                    end
                    
                    lastZone = zone
                end
            end
            
            if #playerZones >= 2 then
                playerPaths[playerName] = playerZones
                
                -- Create sequence key for pattern matching
                local sequenceKey = ""
                for i, zoneData in ipairs(playerZones) do
                    if i <= 5 then -- Limit to first 5 zones for pattern matching
                        sequenceKey = sequenceKey .. (i > 1 and "," or "") .. zoneData.zone
                    end
                end
                
                if sequenceKey ~= "" then
                    zoneSequences[sequenceKey] = (zoneSequences[sequenceKey] or 0) + 1
                end
            end
        end
    end
    
    -- Find common quest line patterns
    local commonPaths = {}
    for sequence, count in pairs(zoneSequences) do
        if count >= 2 then -- At least 2 players followed this path
            table.insert(commonPaths, {
                path = sequence,
                playerCount = count,
                likelihood = count / #playerPaths * 100
            })
        end
    end
    
    -- Sort by player count
    table.sort(commonPaths, function(a, b) return a.playerCount > b.playerCount end)
    
    -- Analyze zone transition correlations
    local questLineCorrelations = {}
    for transition, count in pairs(zonePairs) do
        if count >= 2 then
            local zones = {}
            for zone in string.gmatch(transition, "([^%->]+)") do
                table.insert(zones, zone:match("^%s*(.-)%s*$")) -- Trim whitespace
            end
            
            if #zones == 2 then
                table.insert(questLineCorrelations, {
                    fromZone = zones[1],
                    toZone = zones[2],
                    playerCount = count,
                    strength = count / #playerPaths * 100
                })
            end
        end
    end
    
    -- Sort by strength
    table.sort(questLineCorrelations, function(a, b) return a.strength > b.strength end)
    
    return {
        patterns = playerPaths,
        totalPlayers = 0,
        commonPaths = {unpack(commonPaths, 1, 10)}, -- Top 10
        questLineCorrelations = {unpack(questLineCorrelations, 1, 15)} -- Top 15
    }
end

-- Detect players following similar quest lines
function Engine:DetectSimilarQuestLines(playerName, similarityThreshold)
    similarityThreshold = similarityThreshold or 0.6 -- 60% similarity
    
    if not Crosspaths.db or not Crosspaths.db.players or not playerName then
        return {
            similarPlayers = {},
            targetPlayerPath = {},
            confidence = 0
        }
    end
    
    local targetPlayer = Crosspaths.db.players[playerName]
    if not targetPlayer or not targetPlayer.encounters then
        return {
            similarPlayers = {},
            targetPlayerPath = {},
            confidence = 0
        }
    end
    
    -- Get target player's zone progression
    local targetPath = self:ExtractZoneProgression(targetPlayer)
    if #targetPath < 2 then
        return {
            similarPlayers = {},
            targetPlayerPath = targetPath,
            confidence = 0
        }
    end
    
    Crosspaths:DebugLog("Finding similar quest lines for " .. playerName, "INFO")
    
    local similarPlayers = {}
    
    -- Compare with other players
    for otherPlayerName, otherPlayer in pairs(Crosspaths.db.players) do
        if otherPlayerName ~= playerName and otherPlayer.encounters then
            local otherPath = self:ExtractZoneProgression(otherPlayer)
            
            if #otherPath >= 2 then
                local similarity = self:CalculatePathSimilarity(targetPath, otherPath)
                
                if similarity >= similarityThreshold then
                    table.insert(similarPlayers, {
                        name = otherPlayerName,
                        similarity = similarity,
                        path = otherPath,
                        sharedZones = self:GetSharedZones(targetPath, otherPath),
                        level = otherPlayer.level,
                        class = otherPlayer.class
                    })
                end
            end
        end
    end
    
    -- Sort by similarity
    table.sort(similarPlayers, function(a, b) return a.similarity > b.similarity end)
    
    -- Calculate overall confidence
    local confidence = 0
    if #similarPlayers > 0 then
        local totalSimilarity = 0
        for _, similar in ipairs(similarPlayers) do
            totalSimilarity = totalSimilarity + similar.similarity
        end
        confidence = totalSimilarity / #similarPlayers
    end
    
    return {
        similarPlayers = {unpack(similarPlayers, 1, 10)}, -- Top 10 most similar
        targetPlayerPath = targetPath,
        confidence = confidence
    }
end

-- Extract zone progression from player encounters
function Engine:ExtractZoneProgression(player)
    local progression = {}
    local cutoffTime = time() - (14 * 24 * 60 * 60) -- Last 14 days
    
    if not player.encounters then
        return progression
    end
    
    -- Get recent encounters
    local recentEncounters = {}
    for _, encounter in ipairs(player.encounters) do
        if encounter.timestamp and encounter.timestamp >= cutoffTime and encounter.zone then
            table.insert(recentEncounters, encounter)
        end
    end
    
    -- Sort by timestamp
    table.sort(recentEncounters, function(a, b) return a.timestamp < b.timestamp end)
    
    -- Extract unique zone progression
    local lastZone = nil
    for _, encounter in ipairs(recentEncounters) do
        local zone = self:NormalizeZoneName(encounter.zone)
        if zone ~= lastZone then
            table.insert(progression, {
                zone = zone,
                timestamp = encounter.timestamp,
                level = encounter.level or 0
            })
            lastZone = zone
        end
    end
    
    return progression
end

-- Calculate similarity between two zone progression paths
function Engine:CalculatePathSimilarity(path1, path2)
    if #path1 == 0 or #path2 == 0 then
        return 0
    end
    
    -- Extract zone names
    local zones1 = {}
    local zones2 = {}
    
    for _, step in ipairs(path1) do
        table.insert(zones1, step.zone)
    end
    
    for _, step in ipairs(path2) do
        table.insert(zones2, step.zone)
    end
    
    -- Calculate Jaccard similarity (intersection over union)
    local set1 = {}
    local set2 = {}
    
    for _, zone in ipairs(zones1) do
        set1[zone] = true
    end
    
    for _, zone in ipairs(zones2) do
        set2[zone] = true
    end
    
    -- Count intersection and union
    local intersection = 0
    local union = 0
    
    for zone in pairs(set1) do
        union = union + 1
        if set2[zone] then
            intersection = intersection + 1
        end
    end
    
    for zone in pairs(set2) do
        if not set1[zone] then
            union = union + 1
        end
    end
    
    -- Calculate sequence similarity bonus
    local sequenceBonus = self:CalculateSequenceSimilarity(zones1, zones2)
    
    -- Combine Jaccard similarity with sequence bonus
    local baseSimilarity = union > 0 and intersection / union or 0
    return math.min(1.0, baseSimilarity + (sequenceBonus * 0.3))
end

-- Calculate sequence similarity bonus
function Engine:CalculateSequenceSimilarity(zones1, zones2)
    local maxLength = math.min(#zones1, #zones2, 5) -- Compare up to 5 zones
    if maxLength == 0 then return 0 end
    
    local matches = 0
    for i = 1, maxLength do
        if zones1[i] == zones2[i] then
            matches = matches + 1
        end
    end
    
    return matches / maxLength
end

-- Get shared zones between two paths
function Engine:GetSharedZones(path1, path2)
    local shared = {}
    local zones1 = {}
    
    for _, step in ipairs(path1) do
        zones1[step.zone] = true
    end
    
    for _, step in ipairs(path2) do
        if zones1[step.zone] then
            table.insert(shared, step.zone)
        end
    end
    
    return shared
end

-- Get quest line insights for a specific zone
function Engine:GetQuestLineInsights(zoneName, timeWindow)
    timeWindow = timeWindow or (7 * 24 * 60 * 60) -- Default 7 days
    local cutoffTime = time() - timeWindow
    
    if not Crosspaths.db or not Crosspaths.db.players or not zoneName then
        return {
            totalVisitors = 0,
            averageTimeSpent = 0,
            levelRange = { min = 0, max = 0 },
            progressionFrom = {},
            progressionTo = {},
            peakHours = {}
        }
    end
    
    local normalizedZone = self:NormalizeZoneName(zoneName)
    local visitors = {}
    local timeSpent = {}
    local levels = {}
    local fromZones = {}
    local toZones = {}
    local hourlyActivity = {}
    
    Crosspaths:DebugLog("Analyzing quest line insights for zone: " .. normalizedZone, "INFO")
    
    for playerName, player in pairs(Crosspaths.db.players) do
        if player.encounters then
            local zoneEncounters = {}
            local playerProgression = self:ExtractZoneProgression(player)
            
            -- Find encounters in this zone
            for _, encounter in ipairs(player.encounters) do
                if encounter.timestamp and encounter.timestamp >= cutoffTime and
                   encounter.zone and self:NormalizeZoneName(encounter.zone) == normalizedZone then
                    table.insert(zoneEncounters, encounter)
                    
                    -- Track levels
                    if encounter.level then
                        table.insert(levels, encounter.level)
                    end
                    
                    -- Track hourly activity
                    local hour = tonumber(os.date("%H", encounter.timestamp))
                    hourlyActivity[hour] = (hourlyActivity[hour] or 0) + 1
                end
            end
            
            if #zoneEncounters > 0 then
                visitors[playerName] = zoneEncounters
                
                -- Calculate time spent in zone
                if #zoneEncounters > 1 then
                    table.sort(zoneEncounters, function(a, b) return a.timestamp < b.timestamp end)
                    local duration = zoneEncounters[#zoneEncounters].timestamp - zoneEncounters[1].timestamp
                    table.insert(timeSpent, duration)
                end
                
                -- Analyze progression patterns
                for i, step in ipairs(playerProgression) do
                    if step.zone == normalizedZone then
                        -- Where did they come from?
                        if i > 1 then
                            local fromZone = playerProgression[i-1].zone
                            fromZones[fromZone] = (fromZones[fromZone] or 0) + 1
                        end
                        
                        -- Where did they go?
                        if i < #playerProgression then
                            local toZone = playerProgression[i+1].zone
                            toZones[toZone] = (toZones[toZone] or 0) + 1
                        end
                        break
                    end
                end
            end
        end
    end
    
    -- Calculate averages and insights
    local totalVisitors = 0
    for _ in pairs(visitors) do
        totalVisitors = totalVisitors + 1
    end
    
    local averageTimeSpent = 0
    if #timeSpent > 0 then
        local total = 0
        for _, duration in ipairs(timeSpent) do
            total = total + duration
        end
        averageTimeSpent = total / #timeSpent
    end
    
    local levelRange = { min = 0, max = 0 }
    if #levels > 0 then
        table.sort(levels)
        levelRange.min = levels[1]
        levelRange.max = levels[#levels]
    end
    
    -- Top progression paths
    local progressionFrom = {}
    for zone, count in pairs(fromZones) do
        table.insert(progressionFrom, { zone = zone, count = count })
    end
    table.sort(progressionFrom, function(a, b) return a.count > b.count end)
    
    local progressionTo = {}
    for zone, count in pairs(toZones) do
        table.insert(progressionTo, { zone = zone, count = count })
    end
    table.sort(progressionTo, function(a, b) return a.count > b.count end)
    
    -- Peak hours
    local peakHours = {}
    for hour, count in pairs(hourlyActivity) do
        table.insert(peakHours, { hour = hour, count = count })
    end
    table.sort(peakHours, function(a, b) return a.count > b.count end)
    
    return {
        totalVisitors = totalVisitors,
        averageTimeSpent = averageTimeSpent,
        levelRange = levelRange,
        progressionFrom = {unpack(progressionFrom, 1, 5)}, -- Top 5
        progressionTo = {unpack(progressionTo, 1, 5)}, -- Top 5
        peakHours = {unpack(peakHours, 1, 6)} -- Top 6 hours
    }
end