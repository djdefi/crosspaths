#!/bin/bash

# Generate basic changelog entries from git commits
# Usage: ./generate-changelog.sh [from_tag] [to_version]

set -e

FROM_TAG="${1:-initial}"
TO_VERSION="${2:-$(grep "^## Version:" Crosspaths.toc | cut -d' ' -f3)}"

echo "Generating changelog from $FROM_TAG to $TO_VERSION..."

# Create temporary changelog entries
TEMP_FILE=$(mktemp)

echo "## [$TO_VERSION] - $(date '+%Y-%m-%d')" > "$TEMP_FILE"
echo "" >> "$TEMP_FILE"

# Get commits since last tag
if [ "$FROM_TAG" = "initial" ]; then
    # First release - get all commits
    COMMITS=$(git log --oneline --reverse --pretty=format:"%s")
else
    # Get commits since last tag
    COMMITS=$(git log --oneline --reverse --pretty=format:"%s" "${FROM_TAG}..HEAD")
fi

# Categorize commits
ADDED=()
CHANGED=()
FIXED=()

while IFS= read -r commit; do
    if [[ -z "$commit" ]]; then
        continue
    fi
    
    # Simple categorization based on commit message keywords
    if [[ $commit =~ ^(feat|add|new|implement|create|initial) ]]; then
        ADDED+=("$commit")
    elif [[ $commit =~ ^(fix|bug|patch|correct|resolve) ]]; then
        FIXED+=("$commit")
    elif [[ $commit =~ ^(update|change|modify|refactor|improve) ]]; then
        CHANGED+=("$commit")
    else
        # Default to Added for new functionality
        ADDED+=("$commit")
    fi
done <<< "$COMMITS"

# Write changelog sections
echo "### Added" >> "$TEMP_FILE"
if [ ${#ADDED[@]} -eq 0 ]; then
    echo "- " >> "$TEMP_FILE"
else
    for item in "${ADDED[@]}"; do
        echo "- $item" >> "$TEMP_FILE"
    done
fi

echo "" >> "$TEMP_FILE"
echo "### Changed" >> "$TEMP_FILE"
if [ ${#CHANGED[@]} -eq 0 ]; then
    echo "- " >> "$TEMP_FILE"
else
    for item in "${CHANGED[@]}"; do
        echo "- $item" >> "$TEMP_FILE"
    done
fi

echo "" >> "$TEMP_FILE"
echo "### Fixed" >> "$TEMP_FILE"
if [ ${#FIXED[@]} -eq 0 ]; then
    echo "- " >> "$TEMP_FILE"
else
    for item in "${FIXED[@]}"; do
        echo "- $item" >> "$TEMP_FILE"
    done
fi

echo "" >> "$TEMP_FILE"

# Insert into existing CHANGELOG.md
if [ -f "CHANGELOG.md" ]; then
    # Create backup
    cp CHANGELOG.md CHANGELOG.md.backup
    
    # Find the line with [Unreleased] and insert after it
    if grep -q "## \[Unreleased\]" CHANGELOG.md; then
        # Insert after [Unreleased] section
        sed -i '/## \[Unreleased\]/r '"$TEMP_FILE" CHANGELOG.md
    else
        # Insert at the beginning after the header
        sed -i '1,/^$/r '"$TEMP_FILE" CHANGELOG.md
    fi
else
    # Create new CHANGELOG.md
    echo "# Changelog" > CHANGELOG.md
    echo "" >> CHANGELOG.md
    echo "All notable changes to Crosspaths will be documented in this file." >> CHANGELOG.md
    echo "" >> CHANGELOG.md
    echo "## [Unreleased]" >> CHANGELOG.md
    echo "" >> CHANGELOG.md
    cat "$TEMP_FILE" >> CHANGELOG.md
fi

# Cleanup
rm "$TEMP_FILE"

echo "Changelog updated for version $TO_VERSION"