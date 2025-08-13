# Crosspaths - World of Warcraft Addon Development Instructions

**ALWAYS follow these instructions first and fallback to additional search and context gathering only if the information here is incomplete or found to be in error.**

Crosspaths is a World of Warcraft addon written in Lua that tracks social encounters with other players. It provides analytics and insights about player interactions in-game.

## Working Effectively

### Essential Setup & Validation (ALL COMMANDS VALIDATED)
- Install Lua 5.3 for testing: `sudo apt-get install -y lua5.3 liblua5.3-dev`
- Install luacheck for linting: `sudo apt-get install -y luarocks && sudo luarocks install luacheck`
- Run comprehensive test suite: `./tests/run_tests.sh` -- takes ~0.02 seconds. NEVER CANCEL.
- Syntax check all files: `luac -p *.lua` -- takes ~0.005 seconds. NEVER CANCEL.
- Run linting: `luacheck *.lua --globals _G --std none --ignore 11 --ignore 21 --ignore 131 --ignore 143 --ignore 213 --ignore 311 --ignore 312 --ignore 631 --ignore 611 --ignore 432 --ignore 212 --ignore 211 --ignore 231 --ignore 111 --ignore 112 --ignore 113` -- takes ~0.25 seconds. NEVER CANCEL.

### CRITICAL: No Build Process Required
- This is a World of Warcraft addon - **NO COMPILATION OR BUILD STEP EXISTS**
- Lua files are executed directly by the WoW client
- Do NOT attempt to run npm, make, maven, gradle, or similar build tools
- Validation consists only of: syntax check + linting + unit tests

### CRITICAL: Timing Expectations (VALIDATED)
- **Test suite: ~0.02 seconds** (196 comprehensive test cases) - NEVER CANCEL
- **Syntax checking: ~0.005 seconds** (instant) - NEVER CANCEL 
- **Linting: ~0.25 seconds** (very fast) - NEVER CANCEL
- **Total validation time: <1 second combined** - NEVER CANCEL
- **Individual test: ~0.004 seconds** (extremely fast) - NEVER CANCEL
- Set timeout to 30+ seconds for all validation commands to be safe, but expect near-instant completion
- **DO NOT STOP** any validation commands - they complete almost instantly

## Validation Scenarios

### ALWAYS Run These Validation Steps
Execute these commands in sequence after making ANY changes:

```bash
# Syntax validation (required)
luac -p *.lua

# Comprehensive test suite (required) 
./tests/run_tests.sh

# Code quality linting (required)
luacheck *.lua --globals _G --std none --ignore 11 --ignore 21 --ignore 131 --ignore 143 --ignore 213 --ignore 311 --ignore 312 --ignore 631 --ignore 611 --ignore 432 --ignore 212 --ignore 211 --ignore 231 --ignore 111 --ignore 112 --ignore 113
```

### Manual Testing Scenarios
Since this is a WoW addon, you cannot run it outside of World of Warcraft. However, validate your changes by:

1. **Code Review**: Check that Lua syntax is valid and follows existing patterns
2. **Test Coverage**: Ensure the 196 unit tests pass and cover your changes
3. **Version Consistency**: Verify version numbers match between `Crosspaths.toc` and `Core.lua`
4. **File Integrity**: Confirm all files listed in `.toc` exist and are accessible

## Repository Structure

### Core Addon Files (DO NOT RENAME OR MOVE)
- **Core.lua** - Addon initialization, event handling, saved variables
- **Tracker.lua** - Player encounter detection and recording (39KB - complex)
- **Engine.lua** - Data processing and analytics calculation (37KB - complex)  
- **UI.lua** - User interface, slash commands, main window (66KB - very complex)
- **Config.lua** - Settings management and configuration UI (33KB - complex)
- **Logging.lua** - Debug and error tracking system
- **TitanPanel.lua** - Integration with TitanPanel addon
- **Crosspaths.toc** - WoW addon metadata file (CRITICAL - defines load order)

### Testing Infrastructure
- **tests/run_tests.sh** - Main test execution script
- **tests/test_engine.lua** - Engine function test suite (196+ test cases)
- **tests/test_runner.lua** - Test framework with assertions
- **tests/mock_wow.lua** - Mock WoW API and comprehensive test data

### Documentation & Build
- **.github/workflows/** - CI/CD pipelines (test.yml, release.yml, bump-toc.yml)
- **.pkgmeta** - CurseForge packaging configuration
- **README.md** - User documentation and installation guide
- **CONTRIBUTING.md** - Development guidelines and setup instructions
- **DESIGN.md** - Technical architecture and data model design

## Development Guidelines

### Code Style (Lua)
- Use 4 spaces for indentation (NO TABS)
- Follow existing code patterns in the repository
- Add comments for complex logic only
- Use descriptive variable names
- Follow WoW addon naming conventions for globals

### File Modification Rules
- **NEVER delete or rename core *.lua files** - they are registered in Crosspaths.toc
- **ALWAYS update Crosspaths.toc** if you add new Lua files
- **NEVER modify file load order** in .toc without understanding dependencies
- **ALWAYS maintain version consistency** between .toc and Core.lua

### Testing Requirements
- **ALWAYS run `./tests/run_tests.sh` before committing** - CI will fail otherwise
- Add test cases for new Engine functions in `tests/test_engine.lua`
- Follow existing test patterns and assertion methods
- Use mock data in `tests/mock_wow.lua` for realistic testing

## Common Development Tasks

### Adding New Engine Functions
1. Implement function in `Engine.lua`
2. Add comprehensive test cases in `tests/test_engine.lua`
3. Run test suite: `./tests/run_tests.sh`
4. Update documentation if user-facing

### Modifying UI Components  
1. Edit `UI.lua` (main interface) or `Config.lua` (settings)
2. Test syntax: `luac -p UI.lua Config.lua`
3. Run full test suite: `./tests/run_tests.sh`
4. Check linting: `luacheck UI.lua Config.lua --globals _G --std none --ignore 11 --ignore 21 --ignore 131 --ignore 143 --ignore 213 --ignore 311 --ignore 312 --ignore 631 --ignore 611 --ignore 432 --ignore 212 --ignore 211 --ignore 231 --ignore 111 --ignore 112 --ignore 113`

### Working with Tracking Logic
1. Modify `Tracker.lua` for encounter detection changes
2. Update mock data in `tests/mock_wow.lua` if needed
3. Add corresponding test cases
4. Verify performance impact with large datasets

### Version Updates
1. Update version in `Crosspaths.toc` (## Version: line)
2. Update version in `Core.lua` (Crosspaths.version = line)  
3. Update `CHANGELOG.md` with changes
4. Run validation to ensure consistency

## CI/CD Pipeline

### Automated Checks (GitHub Actions)
- **Syntax validation**: All .lua files checked with luac
- **Linting**: Complete luacheck scan with WoW-specific ignore rules
- **Unit tests**: Full 196+ test case execution  
- **Version consistency**: .toc and Core.lua version matching
- **Documentation validation**: README, CHANGELOG, and file structure checks

### Release Process
- **Automated releases** trigger on pushes to main branch
- **Version extraction** from .toc file drives tagging
- **Package creation** for both GitHub Releases and CurseForge
- **Changelog generation** from CHANGELOG.md

## Troubleshooting

### Common Issues
- **"Interface version errors"** - Update `## Interface:` line in Crosspaths.toc
- **"Missing dependencies"** - Install lua5.3, luarocks, luacheck
- **"Test failures"** - Check syntax first with `luac -p *.lua`
- **"Version mismatch"** - Sync versions between .toc and Core.lua

### Performance Considerations
- Engine.lua contains analytics functions - be mindful of complexity
- Use session-based encounter limiting (1 per player per zone per session)
- Test with large mock datasets when modifying data processing
- Monitor memory usage in data structures

## Key Commands Reference

| Task | Command | Expected Time | Status |
|------|---------|---------------|---------|
| Full test suite | `./tests/run_tests.sh` | ~0.02 seconds | ✅ VALIDATED |
| Syntax check | `luac -p *.lua` | ~0.005 seconds | ✅ VALIDATED |
| Linting | `luacheck *.lua --globals _G --std none --ignore 11 --ignore 21 --ignore 131 --ignore 143 --ignore 213 --ignore 311 --ignore 312 --ignore 631 --ignore 611 --ignore 432 --ignore 212 --ignore 211 --ignore 231 --ignore 111 --ignore 112 --ignore 113` | ~0.25 seconds | ✅ VALIDATED |
| Individual test | `lua tests/test_engine.lua` | ~0.004 seconds | ✅ VALIDATED |
| Check single file | `luac -p filename.lua` | ~0.001 seconds | ✅ VALIDATED |

**REMEMBER**: This is a Lua-based WoW addon with extremely fast validation cycles. There is no build process, compilation, or complex dependency management. Focus on code quality, test coverage, and maintaining the addon's performance characteristics.