# PHP 8.5

Ready to use PHP 8.5 based on alpine and setup for Laravel apps.

## Quick Start

```bash
# Pull the image
docker pull ghcr.io/maxcelos/php:8.5-fpm-alpine
```

## Development

This repository uses automated GitHub Actions to build and publish Docker images when you push git tags.

### Making Changes and Releasing

```bash
# 1. Make your changes
vim Dockerfile

# 2. Commit your changes
git add .
git commit -m "Add Redis extension"

# 3. Bump version (automated - similar to npm version)
./version.sh patch   # or minor, or major

# 4. Push to trigger build
git push --follow-tags
```

The GitHub Actions workflow will automatically build and push the image to `ghcr.io/maxcelos/php:8.5-fpm-alpine`.

### Local Testing

To test your changes locally before releasing:

```bash
# Build the image locally
docker build -t ghcr.io/maxcelos/php:test .

# Test it
docker run --rm ghcr.io/maxcelos/php:test php -v

# When satisfied, release it
./version.sh patch
git push --follow-tags
```

## Documentation

See [WORKFLOW.md](WORKFLOW.md) for detailed documentation on:
- Automated version management
- GitHub Actions workflow
- Tagging strategy
- Troubleshooting