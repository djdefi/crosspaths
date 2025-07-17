# Installation Guide

## System Requirements

- **World of Warcraft** - Retail version (11.0.7 or higher)
- **Operating System** - Windows, macOS, or Linux

## Installation Methods

### Method 1: Manual Installation (Recommended)

1. **Download the addon**
   - Go to [GitHub Releases](https://github.com/djdefi/crosspaths/releases)
   - Download the latest `Crosspaths-x.x.x.zip` file

2. **Extract the files**
   - Extract the zip file to a temporary location
   - You should see a folder named `Crosspaths`

3. **Install to WoW**
   - Navigate to your World of Warcraft installation directory
   - Go to `Interface/AddOns/` folder
   - Copy the `Crosspaths` folder here
   - Final path should be: `World of Warcraft/Interface/AddOns/Crosspaths/`

4. **Enable the addon**
   - Launch World of Warcraft
   - At the character selection screen, click "AddOns"
   - Find "Crosspaths" in the list and check the box to enable it
   - Click "Okay" and enter the game

### Method 2: CurseForge Client

1. **Install CurseForge App**
   - Download from [CurseForge](https://www.curseforge.com/download/app)
   - Install and set up the client

2. **Find the addon**
   - Search for "Crosspaths" in the WoW section
   - Or visit the [project page](https://www.curseforge.com/wow/addons/crosspaths)

3. **Install**
   - Click "Install" in the CurseForge app
   - The addon will be automatically downloaded and installed

## Verification

Once installed, you can verify the addon is working by:

1. **Check addon list**: The addon should appear in your AddOns list
2. **Test commands**: Type `/crosspaths` or `/cp` in chat
3. **Check interface**: You should see the main Crosspaths window

## First Time Setup

1. **Open configuration**: Type `/cpconfig` to access settings
2. **Configure tracking**: Choose what types of encounters to track
3. **Set notifications**: Customize when you want to be notified
4. **Start exploring**: The addon will begin tracking as you play!

## Basic Usage

- `/crosspaths` or `/cp` - Open main interface
- `/crosspaths top` - Show top players in chat
- `/crosspaths stats` - Display summary statistics
- `/cpconfig` - Open configuration panel

## Troubleshooting

### Addon Not Loading
- Ensure the folder is named exactly `Crosspaths` (case-sensitive on some systems)
- Check that `Crosspaths.toc` file is present in the addon folder
- Verify you're running WoW retail (not Classic)

### Interface Version Errors
- The addon requires WoW interface version 110107 or higher
- Update your WoW client to the latest version
- Check [releases](https://github.com/djdefi/crosspaths/releases) for addon updates

### Performance Issues
- Open `/cpconfig` and reduce tracking options if needed
- Check data pruning settings to limit database size
- Monitor memory usage in the addon list

### Data Problems
- Use `/crosspaths export` to backup your data
- Clear corrupted data with `/crosspaths clear confirm`
- Check the debug log for error messages

## Support

If you encounter issues:

1. **Check the logs**: Enable debug mode in `/cpconfig`
2. **Report issues**: Create a bug report on [GitHub Issues](https://github.com/djdefi/crosspaths/issues)
3. **Include details**: WoW version, addon version, error messages, steps to reproduce

## Uninstalling

To remove Crosspaths:

1. Exit World of Warcraft completely
2. Delete the `Crosspaths` folder from `Interface/AddOns/`
3. (Optional) Delete saved data from `WTF/Account/[Account]/SavedVariables/Crosspaths.lua`

Your encounter data will be preserved unless you delete the SavedVariables file.