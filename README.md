# Crosspaths

**Social Memory Tracker for World of Warcraft**

Crosspaths is a lightweight, extensible World of Warcraft addon that passively tracks and analyzes social encounters with other players. It gives users insights into whom they've seen, grouped with, or interacted with across characters and time.

## Features

### 🎯 Encounter Tracking
- Automatically tracks players you encounter in the world
- **What is an Encounter?** - Detection of another player through:
  - Grouping (parties, raids, battlegrounds)
  - Proximity (nameplates, mouseover interactions)
  - Direct interaction (targeting, focusing)
  - Combat participation (damage, healing, buffs)
- **Enhanced Detection Methods** (configurable):
  - Mouseover/proximity tracking with smart throttling
  - Target and focus change tracking
  - Combat log analysis for meaningful interactions
- **Session-based counting** - Only 1 encounter per player per zone per session
- Records encounter history with timestamps and context

### 📊 Statistics & Insights  
- View top players by encounter count
- See most encountered guilds and their members
- Analyze zone-based activity patterns
- Track repeat encounters and group partnerships

### 🔔 Smart Notifications
- Get notified when encountering frequent players
- Alerts for previous group members
- Customizable notification thresholds
- **Do Not Disturb mode** - Disable notifications during combat
- **Granular controls** - Enable/disable specific notification types
- **Sound options** - Customizable notification sounds

### 📈 Advanced Analytics
- **Role-based statistics** - View top tanks, healers, and DPS players
- **Performance metrics** - Track item level and achievement data
- **Digest reports** - Generate daily, weekly, or monthly summaries
- **Historical analysis** - Review encounter patterns over time

### 🔧 System Integration
- **Titan Panel support** - Display encounter stats in Titan Panel
- **Debug mode** - Advanced troubleshooting and logging options
- **Data management** - Remove specific players or clear all data

### 💾 Data Management
- Local data storage (respects Blizzard's social contract)
- Export capabilities (JSON/CSV)
- Automatic data pruning options
- Cross-character compatibility

## Installation

### Manual Installation
1. Download the latest release from [GitHub Releases](https://github.com/djdefi/crosspaths/releases)
2. Extract the `Crosspaths` folder to your `World of Warcraft/Interface/AddOns/` directory
3. Restart World of Warcraft or reload your UI (`/reload`)
4. Enable the addon in your AddOns list

### CurseForge
*Addon is configured for CurseForge publishing - releases are automated through GitHub workflows*

## Usage

### Slash Commands
- `/crosspaths` or `/cp` - Open main interface
- `/crosspaths top` - Show top players in chat
- `/crosspaths stats [tanks|healers|dps|ilvl|achievements]` - Display summary or advanced statistics
- `/crosspaths search <name>` - Search for specific players
- `/crosspaths export [json|csv]` - Export your data
- `/crosspaths remove <player-name>` - Remove player from tracking
- `/crosspaths clear confirm` - Clear all data (requires confirmation)
- `/crosspaths debug [on|off]` - Toggle debug mode
- `/crosspaths status` - Show addon status and diagnostics
- `/crosspaths digest [daily|weekly|monthly]` - Generate digest reports
- `/cpconfig` - Open configuration panel

### Interface
The main interface features multiple tabs:
- **Summary** - Overview statistics and top players
- **Players** - Detailed player list with search
- **Guilds** - Guild encounter statistics  
- **Advanced** - Role-based statistics (tanks, healers, DPS, item level, achievements)
- **Encounters** - Zone and context analysis

## Configuration

Access configuration via `/cpconfig` or the main interface. Customize:

- **Tracking Settings** - What types of encounters to track (groups, nameplates, mouseover, targeting, combat)
- **Notifications** - When and how to be notified, including Do Not Disturb mode
- **Data Management** - Pruning and storage options, player removal tools
- **UI Settings** - Interface appearance and behavior
- **Advanced Features** - Digest report settings, debug mode, Titan Panel integration

## Privacy & Data

Crosspaths respects your privacy and Blizzard's social contract:
- All data is stored locally on your computer
- No data is transmitted to external servers
- You control what data is tracked and for how long
- Export/import features allow you to manage your own data

## System Requirements

- **World of Warcraft** - Retail version (11.0.7+)
- **Interface Version** - 110107 or higher
- **Memory** - Minimal impact on game performance
- **Disk Space** - Very small footprint

## Development

### Architecture
- **Core.lua** - Addon initialization and event handling
- **Tracker.lua** - Player encounter detection and recording
- **Engine.lua** - Data processing and statistics calculation
- **UI.lua** - User interface and slash commands
- **Config.lua** - Settings management
- **Logging.lua** - Debug and error tracking
- **TitanPanel.lua** - Titan Panel integration plugin

### Contributing
Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

### Building
The addon uses GitHub Actions for automated testing and releases:
- Lua syntax checking and linting with luacheck
- Comprehensive unit testing (181+ test cases)
- Automated releases to GitHub and CurseForge
- Version management and changelog generation

## Support

- **Issues** - Report bugs or request features on [GitHub Issues](https://github.com/djdefi/crosspaths/issues)
- **Documentation** - See [DESIGN.md](DESIGN.md) for detailed technical design
- **Community** - Join discussions in the Issues section

## Frequently Asked Questions

### What exactly is an "encounter"?
An encounter is recorded when Crosspaths detects another player through various means:
- **Grouping** with them (parties, raids, battlegrounds)
- **Proximity** detection (nameplates, mouseover)
- **Direct interaction** (targeting, focusing them)
- **Combat** participation (damage, healing, buffs between you)

To prevent spam, only **1 encounter per player per zone per session** is counted. A new session starts when you change zones or log in.

### Why don't I see high encounter counts?
The session-based system prevents encounter inflation. If you see the same player multiple times in the same zone during the same session, it only counts as 1 encounter. This gives more meaningful statistics about actual unique meetings rather than detection events.

### How accurate is the tracking?
Crosspaths only tracks what it can detect through the WoW API. Some limitations:
- Players must be within detection range (nameplates, interaction range)
- Some player information (class, level) may only be available when grouped
- Cross-realm players are tracked with their full "Name-Realm" identifier

### What are digest reports?
Digest reports are periodic summaries of your encounter activity:
- **Daily** - Shows encounters from the past 24 hours
- **Weekly** - Shows encounters from the past 7 days  
- **Monthly** - Shows encounters from the past 30 days

Access them via `/crosspaths digest [daily|weekly|monthly]` or the main interface.

### How do I manage my data?
Crosspaths provides several data management tools:
- **Remove specific players**: `/crosspaths remove <player-name>`
- **Clear all data**: `/crosspaths clear confirm` (requires confirmation)
- **Export data**: `/crosspaths export [json|csv]` for backup or analysis
- **Automatic pruning**: Configure in settings to automatically clean old data

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by the social aspects of classic MMO communities
- Built using patterns from the WoW addon development community
- Thanks to all beta testers and contributors

---

**Remember**: Crosspaths helps you recognize the people you meet in Azeroth, bringing back the human connection in our digital adventures! 🌟