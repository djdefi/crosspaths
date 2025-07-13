# Crosspaths

**Social Memory Tracker for World of Warcraft**

Crosspaths is a lightweight, extensible World of Warcraft addon that passively tracks and analyzes social encounters with other players. It gives users insights into whom they've seen, grouped with, or interacted with across characters and time.

## Features

### 🎯 Encounter Tracking
- Automatically tracks players you encounter in the world
- Records group members, nearby players, and social interactions
- Stores encounter history with timestamps and context

### 📊 Statistics & Insights  
- View top players by encounter count
- See most encountered guilds and their members
- Analyze zone-based activity patterns
- Track repeat encounters and group partnerships

### 🔔 Smart Notifications
- Get notified when encountering frequent players
- Alerts for previous group members
- Customizable notification thresholds

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
*Coming soon - addon will be available on CurseForge*

## Usage

### Slash Commands
- `/crosspaths` or `/cp` - Open main interface
- `/crosspaths top` - Show top players in chat
- `/crosspaths stats` - Display summary statistics
- `/crosspaths search <name>` - Search for specific players
- `/crosspaths export [json|csv]` - Export your data
- `/cpconfig` - Open configuration panel

### Interface
The main interface features multiple tabs:
- **Summary** - Overview statistics and top players
- **Players** - Detailed player list with search
- **Guilds** - Guild encounter statistics  
- **Encounters** - Zone and context analysis

## Configuration

Access configuration via `/cpconfig` or the main interface. Customize:

- **Tracking Settings** - What types of encounters to track
- **Notifications** - When and how to be notified
- **Data Management** - Pruning and storage options
- **UI Settings** - Interface appearance and behavior

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

### Contributing
Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

### Building
The addon uses GitHub Actions for automated testing and releases:
- Lua syntax checking and linting
- Automated releases to GitHub and CurseForge
- Version management and changelog generation

## Support

- **Issues** - Report bugs or request features on [GitHub Issues](https://github.com/djdefi/crosspaths/issues)
- **Documentation** - See [DESIGN.md](DESIGN.md) for detailed technical design
- **Community** - Join discussions in the Issues section

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by the social aspects of classic MMO communities
- Built using patterns from the WoW addon development community
- Thanks to all beta testers and contributors

---

**Remember**: Crosspaths helps you recognize the people you meet in Azeroth, bringing back the human connection in our digital adventures! 🌟