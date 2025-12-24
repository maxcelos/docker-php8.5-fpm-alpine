#!/bin/bash

# Semantic version bumping script - similar to npm version
# Usage: ./version.sh [major|minor|patch]

set -e

VERSION_FILE=".version"
BUMP_TYPE="${1:-patch}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
info() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
}

# Check if git working directory is clean
if [[ -n $(git status -s) ]]; then
    error "Working directory is not clean. Please commit or stash your changes first."
fi

# Create version file if it doesn't exist
if [[ ! -f "$VERSION_FILE" ]]; then
    warn "Version file not found. Creating $VERSION_FILE with initial version 1.0.0"
    echo "1.0.0" > "$VERSION_FILE"
    git add "$VERSION_FILE"
    git commit -m "chore: initialize version file"
fi

# Read current version
CURRENT_VERSION=$(cat "$VERSION_FILE")
info "Current version: $CURRENT_VERSION"

# Parse version components
if [[ ! "$CURRENT_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    error "Invalid version format in $VERSION_FILE. Expected: major.minor.patch (e.g., 1.0.0)"
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

# Bump version based on type
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        error "Invalid bump type. Use: major, minor, or patch"
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
TAG_NAME="v$NEW_VERSION"

info "Bumping version: $CURRENT_VERSION → $NEW_VERSION"

# Update version file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Commit the version bump
git add "$VERSION_FILE"
git commit -m "chore: bump version to $NEW_VERSION"
info "Created commit with version bump"

# Create git tag
git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
info "Created tag: $TAG_NAME"

echo ""
echo -e "${GREEN}Version bumped successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git log --oneline -1 && git tag -l $TAG_NAME"
echo "  2. Push to trigger workflow: git push && git push origin $TAG_NAME"
echo "  3. Or push in one command: git push --follow-tags"
echo ""
echo "To undo (if not pushed yet):"
echo "  git tag -d $TAG_NAME && git reset --hard HEAD~1"