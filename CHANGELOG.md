# Changelog

All notable changes to Crosspaths will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [0.1.5] - 2025-07-14

### Added
- Initial plan
- Fix player registration issues with improved nameplate handling and debugging
- Fix trailing whitespace warnings in Tracker.lua
- Merge pull request #16 from djdefi/copilot/fix-15

### Changed
- 

### Fixed
- 

## [0.1.4] - 2025-07-14

### Added
- Initial plan
- Fix CharacterFrameTabButtonTemplate runtime error by replacing with manual button creation
- Modernize tab button implementation with best practices
- Merge pull request #14 from djdefi/copilot/fix-13
- Bump version from 0.1.3 to 0.1.4

### Changed
- 

### Fixed
- 

## [0.1.4] - 2025-07-14

### Added
- Initial plan
- Fix CharacterFrameTabButtonTemplate runtime error by replacing with manual button creation
- Modernize tab button implementation with best practices
- Merge pull request #14 from djdefi/copilot/fix-13

### Changed
- 

### Fixed
- 

## [0.1.3] - 2025-07-14

### Added
- Initial plan
- Fix logging initialization order issue
- Add player tooltip functionality for encounter history
- Fix trailing whitespace in UI.lua comment
- Merge pull request #12 from djdefi/copilot/fix-11
- Bump version from 0.1.2 to 0.1.3

### Changed
- 

### Fixed
- 

## [0.1.3] - 2025-07-14

### Added
- Initial plan
- Fix logging initialization order issue
- Add player tooltip functionality for encounter history
- Fix trailing whitespace in UI.lua comment
- Merge pull request #12 from djdefi/copilot/fix-11

### Changed
- 

### Fixed
- 

## [0.1.2] - 2025-07-14

### Added
- Create DESIGN.md
- Initial plan
- Initial Crosspaths addon implementation with core functionality
- Add final supporting files and scripts - implementation complete
- Update Tracker.lua
- Update Tracker.lua
- Fix code review feedback: debug defaults, JSON escaping, settings reset, and UI method calls
- Merge pull request #2 from djdefi/copilot/fix-1
- Initial plan
- Enhance bump-toc workflow with automatic version increment functionality
- Merge pull request #4 from djdefi/copilot/fix-3
- Initial plan
- Implement healiq-style workflows with semantic versioning and enhanced changelog generation
- Merge pull request #6 from djdefi/copilot/fix-5
- Bump version from 0.1.0 to 0.1.1
- Initial plan
- Fix GitHub Actions workflow syntax error in release.yml
- Merge pull request #8 from djdefi/copilot/fix-7
- Bump version from 0.1.1 to 0.1.2
- Initial plan
- Fix GitHub Actions workflow syntax error in release.yml
- Merge pull request #10 from djdefi/copilot/fix-9

### Changed
- 

### Fixed
- 

## [0.1.2] - 2025-07-14

### Added
- Create DESIGN.md
- Initial plan
- Initial Crosspaths addon implementation with core functionality
- Add final supporting files and scripts - implementation complete
- Update Tracker.lua
- Update Tracker.lua
- Fix code review feedback: debug defaults, JSON escaping, settings reset, and UI method calls
- Merge pull request #2 from djdefi/copilot/fix-1
- Initial plan
- Enhance bump-toc workflow with automatic version increment functionality
- Merge pull request #4 from djdefi/copilot/fix-3
- Initial plan
- Implement healiq-style workflows with semantic versioning and enhanced changelog generation
- Merge pull request #6 from djdefi/copilot/fix-5
- Bump version from 0.1.0 to 0.1.1
- Initial plan
- Fix GitHub Actions workflow syntax error in release.yml
- Merge pull request #8 from djdefi/copilot/fix-7

### Changed
- 

### Fixed
- 

## [0.1.1] - 2025-07-13

### Added
- Create DESIGN.md
- Initial plan
- Initial Crosspaths addon implementation with core functionality
- Add final supporting files and scripts - implementation complete
- Update Tracker.lua
- Update Tracker.lua
- Fix code review feedback: debug defaults, JSON escaping, settings reset, and UI method calls
- Merge pull request #2 from djdefi/copilot/fix-1
- Initial plan
- Enhance bump-toc workflow with automatic version increment functionality
- Merge pull request #4 from djdefi/copilot/fix-3
- Initial plan
- Implement healiq-style workflows with semantic versioning and enhanced changelog generation
- Merge pull request #6 from djdefi/copilot/fix-5

### Changed
- 

### Fixed
- 


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
