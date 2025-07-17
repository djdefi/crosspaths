# CurseForge Publishing Setup

This document describes the setup required for automated CurseForge publishing.

## Project Information

- **CurseForge Project ID**: `1308376`
- **Project URL**: https://www.curseforge.com/wow/addons/crosspaths-social-memory-tracker
- **Game**: World of Warcraft
- **Addon Name**: Crosspaths

## Required GitHub Secrets

The following repository secrets must be configured in GitHub for automated publishing:

### CURSEFORGE_TOKEN
- **Purpose**: Authentication token for CurseForge API
- **How to obtain**: 
  1. Log into CurseForge
  2. Go to Account Settings > API Keys
  3. Generate a new API key
  4. Copy the token value

### CURSEFORGE_PROJECT_ID
- **Value**: `1308376`
- **Purpose**: Identifies the CurseForge project for uploads

## Workflow Configuration

The release workflow (`.github/workflows/release.yml`) is already configured to:

1. **Automatic Publishing**: Publishes to CurseForge on every push to main branch
2. **Manual Control**: Can be disabled via workflow dispatch input
3. **Game Version Detection**: Automatically converts WoW interface version to game version
4. **Release Notes**: Includes changelog and installation instructions

## Manual Publishing

To publish manually without triggering the full release workflow:

1. Go to GitHub Actions
2. Select "Release" workflow
3. Click "Run workflow"
4. Set "Publish to CurseForge" to true/false as desired
5. Run the workflow

## File Structure

The addon package includes:
- All `.lua` files
- `Crosspaths.toc` (addon metadata)
- `README.md`, `LICENSE`, `CHANGELOG.md`, `INSTALL.md`

## Troubleshooting

### Common Issues

1. **Invalid Token**: Ensure `CURSEFORGE_TOKEN` is valid and not expired
2. **Project Not Found**: Verify `CURSEFORGE_PROJECT_ID` is set to `1308376`
3. **Game Version**: Check that TOC interface version converts correctly to WoW version
4. **File Size**: Ensure zip file is under CurseForge size limits

### Testing

To test the workflow without publishing:
1. Set up secrets in a fork
2. Run the workflow with publishing disabled
3. Check that the zip file is created correctly

## Reference

This setup follows the same pattern as the HealIQ project: https://github.com/djdefi/healiq