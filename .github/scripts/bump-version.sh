#!/bin/bash

# Version bumping script for Crosspaths addon
# Usage: ./bump-version.sh [major|minor|patch]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Function to parse version from semantic version string
parse_version() {
    local version="$1"
    if [[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        MAJOR="${BASH_REMATCH[1]}"
        MINOR="${BASH_REMATCH[2]}"
        PATCH="${BASH_REMATCH[3]}"
        return 0
    else
        echo "ERROR: Invalid version format: $version (expected: major.minor.patch)" >&2
        return 1
    fi
}

# Function to increment version based on type
increment_version() {
    local increment_type="$1"
    local current_version="$2"
    
    parse_version "$current_version"
    
    case "$increment_type" in
        "major")
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        "minor")
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        "patch")
            PATCH=$((PATCH + 1))
            ;;
        *)
            echo "ERROR: Invalid increment type: $increment_type (expected: major, minor, or patch)" >&2
            return 1
            ;;
    esac
    
    echo "${MAJOR}.${MINOR}.${PATCH}"
}

# Function to update version in .toc file
update_toc_version() {
    local new_version="$1"
    local toc_file="$PROJECT_ROOT/Crosspaths.toc"
    
    if [ ! -f "$toc_file" ]; then
        echo "ERROR: Crosspaths.toc not found at $toc_file" >&2
        return 1
    fi
    
    # Update version in .toc file
    sed -i "s/^## Version: .*/## Version: $new_version/" "$toc_file"
    
    # Verify the change
    if ! grep -q "^## Version: $new_version" "$toc_file"; then
        echo "ERROR: Failed to update version in Crosspaths.toc" >&2
        return 1
    fi
    
    echo "Updated version in Crosspaths.toc to $new_version"
}

# Function to update version in Core.lua
update_core_version() {
    local new_version="$1"
    local core_file="$PROJECT_ROOT/Core.lua"
    
    if [ ! -f "$core_file" ]; then
        echo "ERROR: Core.lua not found at $core_file" >&2
        return 1
    fi
    
    # Update version in Core.lua
    sed -i "s/Crosspaths.version = \"[^\"]*\"/Crosspaths.version = \"$new_version\"/" "$core_file"
    
    # Verify the change
    if ! grep -q "Crosspaths.version = \"$new_version\"" "$core_file"; then
        echo "ERROR: Failed to update version in Core.lua" >&2
        return 1
    fi
    
    echo "Updated version in Core.lua to $new_version"
}

# Main script logic
main() {
    local increment_type="$1"
    
    if [ -z "$increment_type" ]; then
        echo "Usage: $0 [major|minor|patch]" >&2
        echo "Examples:" >&2
        echo "  $0 patch    # 0.1.0 -> 0.1.1" >&2
        echo "  $0 minor    # 0.1.0 -> 0.2.0" >&2
        echo "  $0 major    # 0.1.0 -> 1.0.0" >&2
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # Get current version from .toc file
    local current_version
    current_version=$(grep "^## Version:" Crosspaths.toc | cut -d' ' -f3)
    
    if [ -z "$current_version" ]; then
        echo "ERROR: Could not extract current version from Crosspaths.toc" >&2
        exit 1
    fi
    
    echo "Current version: $current_version"
    
    # Calculate new version
    local new_version
    new_version=$(increment_version "$increment_type" "$current_version")
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to calculate new version" >&2
        exit 1
    fi
    
    echo "New version: $new_version (increment: $increment_type)"
    
    # Update version in both files
    update_toc_version "$new_version"
    update_core_version "$new_version"
    
    # Verify consistency
    local toc_version
    local core_version
    toc_version=$(grep "^## Version:" Crosspaths.toc | cut -d' ' -f3)
    core_version=$(grep "Crosspaths.version = " Core.lua | cut -d'"' -f2)
    
    if [ "$toc_version" != "$new_version" ] || [ "$core_version" != "$new_version" ]; then
        echo "ERROR: Version inconsistency after update!" >&2
        echo "  Crosspaths.toc: $toc_version" >&2
        echo "  Core.lua: $core_version" >&2
        echo "  Expected: $new_version" >&2
        exit 1
    fi
    
    echo "Version successfully updated from $current_version to $new_version"
    echo "Files modified:"
    echo "  - Crosspaths.toc"
    echo "  - Core.lua"
}

# Run main function with all arguments
main "$@"