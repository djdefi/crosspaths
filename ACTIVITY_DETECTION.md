# Enhanced Activity Detection Features

This document describes the enhanced activity detection features added to Crosspaths v0.1.8.

## Encounter Counting System

### Session-Based Encounter Prevention
- **One encounter per player per zone per session** - Prevents encounter inflation
- **Session Definition**: Starts fresh when you enter a new zone or log in
- **Multiple Detection Sources**: Different detection methods don't create duplicate encounters
- **Meaningful Statistics**: Encounter counts represent actual unique meetings, not detection events

### Detection vs. Encounter
- **Detection**: When the addon notices a player (mouseover, nameplate, etc.)
- **Encounter**: Only counted once per session per zone, regardless of detection method
- **Example**: If you mouseover, target, and see a nameplate of the same player in one dungeon, that's still just 1 encounter

## New Detection Methods

### 1. Mouseover/Proximity Detection
- **Event**: `UPDATE_MOUSEOVER_UNIT`
- **Description**: Tracks players when you mouseover them
- **Configuration**: `tracking.enableMouseoverTracking`
- **Throttling**: 2x standard throttle time to prevent spam

### 2. Target/Focus Detection
- **Events**: `PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED`
- **Description**: Tracks players when you target or focus them
- **Configuration**: `tracking.enableTargetTracking`
- **Use Case**: Automatically tracks players you interact with

### 3. Combat Log Detection
- **Event**: `COMBAT_LOG_EVENT_UNFILTERED`
- **Description**: Tracks players you engage in combat with (damage, healing, auras)
- **Configuration**: `tracking.enableCombatLogTracking`
- **Throttling**: 5x standard throttle time (longer due to high event frequency)
- **Relevant Events**: SPELL_DAMAGE, SPELL_HEAL, SPELL_AURA_APPLIED, SWING_DAMAGE, etc.

## Enhanced Tooltip System

### Clear Encounter Status
- **Previously Encountered**: Green text with color-coded encounter counts
  - Gold (10+ encounters)
  - Green (5-9 encounters) 
  - White (1-4 encounters)
- **Never Encountered**: Red text clearly indicating new players
- **Group Status**: Clear indication of previous grouping history

### Improved Information Display
- Enhanced grouped status visibility
- Better color coding throughout
- Clearer feedback for all encounter types

## Selective Removal Feature

### New Command
- `/crosspaths remove <player-name>` 
- Supports both "Name" and "Name-Realm" formats
- Shows confirmation with encounter count
- Auto-refreshes UI if open

## Advanced Statistics

### Role-Based Analytics
- `/crosspaths stats tanks` - Top tank players by encounters
- `/crosspaths stats healers` - Top healer players by encounters  
- `/crosspaths stats dps` - Top DPS players by encounters

### Performance Analytics  
- `/crosspaths stats ilvl` - Highest item level players encountered
- `/crosspaths stats achievements` - Achievement point leaders

### Data Analysis Features
- Class-based top player breakdowns
- Mount rarity analysis (common vs rare mounts)
- Item level rankings
- Achievement point comparisons

## Configuration Options

All new features are configurable via `/cpconfig`:

### Tracking Settings
- ✅ Track Group Members (existing)
- ✅ Track Nearby Players/Nameplates (existing)
- ✅ Track Players in Cities (existing)
- ✅ **Track Mouseover Players** (new)
- ✅ **Track Target/Focus Changes** (new)
- ✅ **Track Combat Interactions** (new)

### Performance Settings
- Location-based throttling with configurable thresholds
- Separate throttle times for different detection methods
- Defensive programming for combat log parsing

## Implementation Details

### Throttling Strategy
- **Nameplate**: Standard throttle (500ms default)
- **Mouseover**: 2x standard throttle (1000ms default)
- **Target/Focus**: No additional throttle (single events)
- **Combat Log**: 5x standard throttle (2500ms default)

### Data Safety
- Extensive validation for combat log data
- Null checks for all unit operations
- Graceful handling of missing player information
- Proper realm name handling across all detection methods

### Backwards Compatibility
- All new features have default enabled state
- Existing settings preserved during upgrades
- No breaking changes to existing functionality

## Usage Examples

```
# View enhanced statistics
/crosspaths stats tanks
/crosspaths stats healers  
/crosspaths stats ilvl
/crosspaths stats achievements

# Remove specific players
/crosspaths remove Playerone
/crosspaths remove Playertwo-Stormrage

# Configure new features
/cpconfig
```

## Benefits

1. **More Complete Detection**: Captures many more player encounters automatically
2. **Better User Feedback**: Clear visual indicators in tooltips
3. **Granular Control**: Users can enable/disable specific detection methods
4. **Advanced Analytics**: Role-based and performance-based player rankings
5. **Data Management**: Easy removal of unwanted entries
6. **Performance Optimized**: Smart throttling prevents game performance impact