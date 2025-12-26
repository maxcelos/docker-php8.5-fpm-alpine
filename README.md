# PHP 8.5 FPM Alpine

Production-ready PHP 8.5 image based on Alpine Linux, optimized for Laravel applications.

## Features

- PHP 8.5 FPM on Alpine Linux
- Pre-installed extensions: PDO (MySQL, PostgreSQL), Redis, BCMath, MBString, EXIF, ZIP, PCNTL
- Composer 2.2
- Node.js and npm
- Production-optimized PHP and OPcache configurations
- Automatic file permission handling
- Ready for Laravel/Symfony applications

## Quick Start

### Pull the Image

```bash
docker pull ghcr.io/maxcelos/php:8.5-fpm-alpine
```

### Using with Docker Compose

```bash
# Copy the sample configuration
cp docker-compose.sample.yml docker-compose.yml

# Start your services
docker-compose up -d
```

### Simple Docker Run

```bash
docker run -d \
  --name myapp_php \
  -v $(pwd):/var/www/html \
  ghcr.io/maxcelos/php:8.5-fpm-alpine
```

## Documentation

- [USAGE.md](docs/USAGE.md) - Complete usage guide including:
  - Configuration customization (PHP, OPcache, PHP-FPM)
  - Docker Compose examples
  - Environment variables
  - Common use cases
  - Troubleshooting
- [docker-compose.sample.yml](examples/docker-compose.sample.yml) - Full-featured docker-compose example
- [WORKFLOW.md](docs/WORKFLOW.md) - Development and release workflow

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

See [WORKFLOW.md](docs/WORKFLOW.md) for detailed documentation on the automated version management and release process.