# Changelog

All notable changes to Crosspaths will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-13

### Added
- Initial addon implementation with core functionality
- Player encounter tracking system
  - Group member detection via GROUP_ROSTER_UPDATE
  - Nearby player detection via NAME_PLATE_UNIT_ADDED
  - Zone change tracking with PLAYER_ENTERING_WORLD
- Statistics and analytics engine
  - Top players by encounter count
  - Guild encounter statistics
  - Zone activity analysis
  - Data export capabilities (JSON/CSV)
- User interface with tabbed design
  - Summary tab with overview statistics
  - Players tab with search functionality
  - Guilds tab for guild-based insights
  - Encounters tab for zone/context analysis
- Comprehensive slash command system
  - `/crosspaths` and `/cp` for main interface
  - Quick commands for stats, search, and data management
- Notification system
  - Toast notifications for repeat encounters
  - Configurable thresholds and notification types
  - Smart filtering to avoid spam
- Configuration management
  - Full settings panel accessible via `/cpconfig`
  - Tracking, notification, and UI customization options
  - Data management tools with safety confirmations
- Robust error handling and logging system
  - Debug logging with configurable levels
  - Session and error log tracking
  - Safe function wrappers with error recovery
- Data persistence and management
  - SavedVariables integration for data storage
  - Automatic data pruning by age and size limits
  - Version upgrade handling
- Performance optimizations
  - Event throttling to prevent spam
  - Cached statistics calculations
  - Efficient data structures for large player databases

### Technical Features
- Modular architecture with clean separation of concerns
- WoW 11.0.7 (interface 110107) compatibility
- Comprehensive Lua syntax validation
- Memory-efficient data storage
- Cross-character data compatibility

### Documentation
- Complete README with installation and usage instructions
- Detailed design documentation (DESIGN.md)
- MIT license for open source development
- Inline code documentation and comments

[Unreleased]: https://github.com/djdefi/crosspaths/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/djdefi/crosspaths/releases/tag/v0.1.0