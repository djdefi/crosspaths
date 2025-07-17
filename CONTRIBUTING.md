# Contributing to Crosspaths

Thank you for your interest in contributing to Crosspaths! This guide will help you get started.

## Development Setup

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/your-username/crosspaths.git
   cd crosspaths
   ```

3. **Install Lua** (for testing)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install lua5.3
   
   # macOS
   brew install lua
   ```

4. **Run tests**
   ```bash
   ./tests/run_tests.sh
   ```

## Code Guidelines

### Lua Style
- Use 4 spaces for indentation
- Follow existing code patterns in the repository
- Add comments for complex logic
- Use descriptive variable names

### Testing
- All Engine functions have comprehensive tests in `tests/`
- Run tests before submitting changes: `./tests/run_tests.sh`
- Add tests for new functionality

### Documentation
- Update README.md for user-facing changes
- Update CHANGELOG.md following the existing format
- Update TOC version for releases

## Submitting Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the code guidelines above
   - Ensure tests pass
   - Update documentation as needed

3. **Commit your changes**
   ```bash
   git commit -m "Add feature: description of your feature"
   ```

4. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Submit a Pull Request**
   - Describe your changes clearly
   - Reference any related issues
   - Ensure CI tests pass

## Release Process (for maintainers)

### Automated Releases
- The release workflow runs automatically on pushes to main
- Updates version in TOC, creates tags, builds packages
- Publishes to both GitHub Releases and CurseForge

### CurseForge Publishing
- See `.github/CURSEFORGE_SETUP.md` for configuration details
- Project ID: 1308376
- Requires `CURSEFORGE_TOKEN` and `CURSEFORGE_PROJECT_ID` secrets

### Manual Release
1. Update version in `Crosspaths.toc`
2. Update `CHANGELOG.md` with new version section
3. Commit and push to main
4. The workflow will automatically create release and publish

## Architecture

### Core Components
- **Core.lua** - Addon initialization and event handling
- **Tracker.lua** - Player encounter detection and recording
- **Engine.lua** - Data processing and statistics calculation
- **UI.lua** - User interface and slash commands
- **Config.lua** - Settings management
- **Logging.lua** - Debug and error tracking

### File Structure
```
Crosspaths/
├── *.lua                 # Core addon files
├── Crosspaths.toc       # Addon metadata
├── tests/               # Test suite
├── .github/             # GitHub workflows and documentation
├── README.md           # User documentation
├── INSTALL.md          # Installation guide
├── CHANGELOG.md        # Version history
├── DESIGN.md           # Technical design
└── LICENSE             # MIT License
```

## Getting Help

- **Issues**: Report bugs or request features on [GitHub Issues](https://github.com/djdefi/crosspaths/issues)
- **Documentation**: See [DESIGN.md](DESIGN.md) for detailed technical design
- **Community**: Join discussions in the Issues section

## Code of Conduct

Please be respectful and constructive in all interactions. We're all here to make Crosspaths better for the World of Warcraft community.

## License

By contributing to Crosspaths, you agree that your contributions will be licensed under the MIT License.