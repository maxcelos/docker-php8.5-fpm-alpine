# GitHub Actions Workflow Guide

## Overview

This repository uses GitHub Actions to automatically build and push Docker images to GitHub Container Registry (ghcr.io) when you push git tags.

## How It Works

### Trigger
The workflow triggers automatically when you push a git tag that starts with `v` (e.g., `v8.5.1`, `v1.0.0`).

### Tagging Strategy

This workflow separates **repository versioning** from **Docker image tags**:

#### Repository Versions (Git Tags)
- Track YOUR changes and customizations to this image
- Examples: `v1.0.0`, `v1.0.1`, `v2.0.0`
- Follow semantic versioning for your modifications

#### Docker Image Tags
When you push a tag like `v1.0.0`, the workflow creates these Docker tags:

- `v1.0.0-8.5-fpm-alpine` - Immutable snapshot of your v1.0.0 changes
- `8.5-fpm-alpine` - Moving pointer, always updates to latest build

**Note:** We intentionally don't use a `latest` tag to avoid conflicts when you create repositories for other PHP versions (8.4, 9.0, etc.). The variant tag (`8.5-fpm-alpine`) serves as the "latest" for this specific PHP version.

### Example: Releasing a New Version

**Option 1: Automated (Recommended)**

Use the `version.sh` script for automated version bumping:

```bash
# Make sure your changes are committed
git add .
git commit -m "Add custom PHP extensions and configuration"

# Bump version automatically (similar to npm version)
./version.sh patch   # 1.0.0 → 1.0.1 (bug fixes)
./version.sh minor   # 1.0.0 → 1.1.0 (new features)
./version.sh major   # 1.0.0 → 2.0.0 (breaking changes)

# Push everything (commit + tag)
git push --follow-tags
```

**Option 2: Manual**

```bash
# Make sure your changes are committed
git add .
git commit -m "Add custom PHP extensions and configuration"

# Create and push a version tag manually
git tag v1.0.0
git push origin v1.0.0
```

This will automatically:
1. Trigger the GitHub Actions workflow
2. Build the Docker image for both AMD64 and ARM64
3. Push to `ghcr.io/maxcelos/php` with these tags:
   - `v1.0.0-8.5-fpm-alpine` (immutable snapshot)
   - `8.5-fpm-alpine` (moving pointer, always latest)

### Viewing Build Status

- Go to your repository on GitHub
- Click the "Actions" tab
- You'll see the workflow run for your tag
- Click on it to view detailed logs

### Pulling the Image

After the workflow completes, you can pull your image:

```bash
# RECOMMENDED: Use the PHP variant tag (always gets latest build)
docker pull ghcr.io/maxcelos/php:8.5-fpm-alpine

# Or pull a specific snapshot for reproducible deployments
docker pull ghcr.io/maxcelos/php:v1.0.0-8.5-fpm-alpine
```

**For docker-compose.yml:**
```yaml
services:
  app:
    image: ghcr.io/maxcelos/php:8.5-fpm-alpine  # Auto-updates on deployment
```

## Automated Version Management

The included `version.sh` script automates version bumping similar to `npm version`:

### Quick Reference

```bash
./version.sh patch   # Bug fixes:        1.0.0 → 1.0.1
./version.sh minor   # New features:     1.0.0 → 1.1.0
./version.sh major   # Breaking changes: 1.0.0 → 2.0.0
```

### What the Script Does

1. Checks that your git working directory is clean
2. Reads the current version from `.version` file
3. Bumps the version according to semantic versioning
4. Creates a git commit with the version change
5. Creates a git tag (e.g., `v1.0.1`)
6. Provides instructions for pushing

### Full Workflow Example

```bash
# Make your changes
vim Dockerfile

# Commit your changes
git add .
git commit -m "Add Redis extension"

# Bump version (creates commit + tag automatically)
./version.sh minor

# Output:
# ✓ Current version: 1.0.0
# ✓ Bumping version: 1.0.0 → 1.1.0
# ✓ Created commit with version bump
# ✓ Created tag: v1.1.0

# Push everything at once
git push --follow-tags

# GitHub Actions will now build and push:
# - ghcr.io/maxcelos/php:v1.1.0-8.5-fpm-alpine (snapshot)
# - ghcr.io/maxcelos/php:8.5-fpm-alpine (updated)
```

### Undo a Version Bump (Before Pushing)

If you made a mistake before pushing:

```bash
# Delete the tag and reset the commit
git tag -d v1.1.0 && git reset --hard HEAD~1
```

## Versioning Best Practices

### Semantic Versioning for Repository Changes
Follow [semantic versioning](https://semver.org/) for tracking YOUR modifications:

- `v1.0.0` - Initial stable release
- `v1.0.1` - Patch release (bug fixes, config tweaks)
- `v1.1.0` - Minor release (add new extensions, features)
- `v2.0.0` - Major release (breaking changes, major restructuring)

**Note:** These versions track your customizations, NOT the PHP version. The PHP version is always `8.5-fpm-alpine` in the image tag.

### Creating Releases

For a more professional workflow, create GitHub releases:

```bash
# Tag the version
git tag -a v1.0.0 -m "Release v1.0.0 - Initial custom PHP 8.5 image with Laravel optimizations"
git push origin v1.0.0

# Then go to GitHub > Releases > Draft a new release
# Select your tag and add release notes
```

## Workflow Features

### Performance Optimizations
- **Build caching**: Uses GitHub Actions cache to speed up builds
- **Multi-architecture support**: Builds for both AMD64 and ARM64 (Apple Silicon)
- **Parallel builds**: Builds happen in GitHub's infrastructure

### Security
- Uses `GITHUB_TOKEN` (no manual secrets needed for ghcr.io)
- Minimal permissions (read contents, write packages)
- Credentials never exposed in logs

## Troubleshooting

### Workflow not triggering?
- Ensure your tag starts with `v` (e.g., `v1.0.0`)
- Check that you pushed the tag: `git push origin v1.0.0`
- Verify the workflow file is in the `main` branch

### Build failing?
- Check the Actions tab for detailed error logs
- Verify your Dockerfile is valid
- Ensure all required files are committed

### Can't pull the image?
- Make sure the package is public (Settings > Packages)
- Or authenticate: `echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin`

## Multi-Version Strategy

This repository is specifically for **PHP 8.5**. If you want to support other PHP versions:

### Recommended Approach: Separate Repositories

Create a separate repository for each PHP major version:

```
docker-php-8.4-fpm-alpine  → ghcr.io/maxcelos/php:8.4-fpm-alpine
docker-php-8.5-fpm-alpine  → ghcr.io/maxcelos/php:8.5-fpm-alpine
docker-php-9.0-fpm-alpine  → ghcr.io/maxcelos/php:9.0-fpm-alpine
```

**Benefits:**
- Clean separation of concerns
- Independent version tracking (each repo has its own v1.0.0, v1.0.1, etc.)
- No tag conflicts
- Easy to deprecate old versions
- Clear ownership and maintenance

**In docker-compose.yml:**
```yaml
services:
  app:
    image: ghcr.io/maxcelos/php:8.5-fpm-alpine  # Explicit PHP version
```

This avoids the ambiguity of a single `latest` tag and makes it clear which PHP version your application uses.

## Advanced Configuration

### Custom Tag Patterns

To change the tag pattern that triggers the workflow, edit `.github/workflows/build-and-push.yml`:

```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # Only trigger on v1.2.3 format
      # or
      - 'release-*'  # Trigger on release-1.0.0
```

### Local Testing Before Release

Test your changes locally before creating a release:

```bash
# Build and test locally
docker build -t ghcr.io/maxcelos/php:test .
docker run --rm ghcr.io/maxcelos/php:test php -v

# Run your test suite
docker run --rm ghcr.io/maxcelos/php:test php artisan test

# When satisfied, create a release
./version.sh patch
git push --follow-tags
```