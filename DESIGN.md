# Crosspaths: Social Memory Tracker for World of Warcraft

## Overview

**Crosspaths** is a lightweight, extensible World of Warcraft addon that passively tracks and analyzes social encounters with other players. It gives users insights into whom they've seen, grouped with, or interacted with across characters and time. It functions like a personal social graph, enabling emergent storytelling, repeat recognition, and community visibility within the WoW universe.

## Goals

### Primary Goals

* Track and store data about player encounters across time and characters.
* Surface stats about most seen players, most common guilds, zone-based interactions, and time-based activity.
* Enhance social memory with custom notes, encounter history, and contextual notifications.
* Respect Blizzard's social contract by keeping all data local and private to the user.

### Stretch Goals

* Cross-character syncing and import/export of encounter history.
* Alt detection based on behavioral and naming heuristics.
* Social achievements and optional overlays.

## Key Features

### Encounter Tracking

* Stores unique identifiers (name-realm) and associated metadata.
* Tracks:

  * First seen and last seen timestamps
  * Total number of encounters
  * Grouped with (boolean)
  * Guild name (if applicable)
  * Zones of encounter
  * Encounter context (raid, dungeon, world, PvP)

### Statistics & Insights

* Top 10 most seen players
* Top 10 guilds encountered
* Most active realms by player count
* Player encounter heatmap (by time of day/week)
* Zone popularity heatmap (based on seen player volume)
* Dungeon/raid partner pool analytics (repeat teammates vs randoms)

### Social Memory UI

* Main frame with tabbed views:

  * **Summary**: stats dashboard
  * **Players**: sortable list with filters and notes
  * **Guilds**: top guilds and guild member counts
  * **Encounters**: chronological encounter log
  * **Heatmaps**: time and zone activity overlays
* Notifications:

  * Toast on encountering a frequent player
  * Alerts when encountering someone you've grouped with before

### Developer CLI

* Slash commands like:

  * `/crosspaths top`
  * `/crosspaths seen <name>`
  * `/crosspaths purge old`
  * `/crosspaths export`

## Architecture

### Storage Model

* Data stored in `SavedVariables`:

```lua
CrosspathsDB = {
  players = {
    ["Name-Realm"] = {
      count = 12,
      firstSeen = 1693201200,
      lastSeen = 1723201333,
      guild = "Raid Bros",
      grouped = true,
      zones = { Valdrakken = 4, Uldaman = 2 },
      contexts = { raid = 1, dungeon = 2, city = 9 },
      notes = "Great tank!"
    },
    ...
  },
  settings = {
    notifyRepeatEncounters = true,
    pruneAfterDays = 180,
    ...
  }
}
```

### Event Handlers

* `GROUP_ROSTER_UPDATE` for grouped players
* `NAME_PLATE_UNIT_ADDED` for nearby players
* `PLAYER_ENTERING_WORLD` for zone changes
* `CHAT_MSG_ADDON` (optional for future syncing)

### Processing Logic

* When a player is encountered:

  * Create or update entry
  * Record current zone, timestamp
  * If grouped, set `grouped = true`
  * Track context (e.g., dungeon, city, etc.)
  * Prune old entries during zone transitions or login based on `pruneAfterDays`

### Performance Considerations

* Use throttling for encounter events (debounce by name+zone)
* Limit data size with capped entry count or age-based pruning
* Use lazy-loading for UI lists with large player counts

## UI Design

* Built using standard WoW UI toolkit (XML + Lua)
* Tabs or dropdown for switching views
* Sortable columns for player and guild tables
* Tooltip previews on hover for notes, encounter history
* Toast-style notifications using `LibToast` or custom frame

## Future Extensions

* Export/import JSON or paste strings for sharing memory between clients
* In-game heatmap visualizations with custom frames or LibGraph
* WeakAura export integration for nameplate tagging
* Optional LDB launcher via LibDataBroker

## License

MIT or GPL-3.0 depending on intended extensibility and contribution model.

## Summary

Crosspaths aims to fill a meaningful gap in the WoW addon ecosystem by giving players a passive, persistent, and insightful social memory system. By helping players recognize repeat encounters, track patterns in their interactions, and reflect on their journeys, it brings back the human connection in a game that's often anonymized by cross-realm play and rapid content churn.
