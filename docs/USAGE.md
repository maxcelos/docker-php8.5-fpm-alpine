# Usage Guide

This guide will help you use and customize the PHP 8.5 FPM Alpine Docker image for your projects.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Default Configurations](#default-configurations)
  - [Customizing PHP Configuration](#customizing-php-configuration)
  - [Customizing OPcache Configuration](#customizing-opcache-configuration)
  - [Customizing PHP-FPM Configuration](#customizing-php-fpm-configuration)
- [Docker Compose Setup](#docker-compose-setup)
- [Environment Variables](#environment-variables)
- [Common Use Cases](#common-use-cases)

## Quick Start

### Using with Docker Run

```bash
docker run -d \
  --name myapp_php \
  -v $(pwd):/var/www/html \
  -p 9000:9000 \
  ghcr.io/maxcelos/php:8.5-fpm-alpine
```

### Using with Docker Compose

Copy the sample docker-compose file:

```bash
cp docker-compose.sample.yml docker-compose.yml
```

Edit the `docker-compose.yml` to match your project requirements, then start:

```bash
docker-compose up -d
```

## Configuration

### Default Configurations

This image comes with production-ready configurations located in the `/usr/local/etc/php/conf.d/` directory:

#### PHP Configuration (`php.ini`)

Key settings:
- `memory_limit = 256M`
- `upload_max_filesize = 64M`
- `post_max_size = 64M`
- `max_execution_time = 30`
- `max_input_vars = 3000`
- `display_errors = Off`
- `log_errors = On`
- Session security enabled
- Timezone set to UTC

#### OPcache Configuration (`opcache.ini`)

Key settings:
- `opcache.memory_consumption = 256`
- `opcache.max_accelerated_files = 20000`
- `opcache.revalidate_freq = 0`
- Optimized for production performance

#### Redis Configuration

Redis extension is installed and enabled by default.

### Customizing PHP Configuration

To override PHP settings, create your custom configuration file and mount it as a volume.

#### Option 1: Override Specific Settings

Create a file `docker/config/php.ini` in your project:

```ini
; Custom PHP settings
memory_limit = 512M
upload_max_filesize = 100M
post_max_size = 100M
max_execution_time = 60

; Enable display errors for development
display_errors = On
display_startup_errors = On
error_reporting = E_ALL

; Custom timezone
date.timezone = America/New_York
```

Mount it in your `docker-compose.yml`:

```yaml
php:
  image: ghcr.io/maxcelos/php:8.5-fpm-alpine
  volumes:
    - ./:/var/www/html
    - ./docker/config/php.ini:/usr/local/etc/php/conf.d/zz-custom.ini:ro
```

**Note:** Files are loaded alphabetically. Using `zz-custom.ini` ensures your settings override defaults.

#### Option 2: Environment-Specific Configurations

Create different configurations for different environments:

```yaml
php:
  image: ghcr.io/maxcelos/php:8.5-fpm-alpine
  volumes:
    - ./:/var/www/html
    - ./docker/config/php.${APP_ENV}.ini:/usr/local/etc/php/conf.d/zz-custom.ini:ro
```

Then have files like:
- `php.local.ini` - Development settings
- `php.staging.ini` - Staging settings
- `php.production.ini` - Production settings

### Customizing OPcache Configuration

For development, you may want to disable OPcache or adjust revalidation:

Create `docker/config/opcache.ini`:

```ini
; Development OPcache settings
opcache.enable = 1
opcache.revalidate_freq = 2
opcache.validate_timestamps = 1

; For production, use:
; opcache.validate_timestamps = 0
; opcache.revalidate_freq = 0
```

Mount it in your `docker-compose.yml`:

```yaml
php:
  volumes:
    - ./docker/config/opcache.ini:/usr/local/etc/php/conf.d/zz-opcache.ini:ro
```

### Customizing PHP-FPM Configuration

To customize PHP-FPM pool settings (process manager, max children, etc.):

Create `docker/config/www.conf`:

```ini
[www]
; Process manager settings
pm = dynamic
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

; Logging
catch_workers_output = yes
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /proc/self/fd/2

; Set session path to a directory owned by process user
php_value[session.save_handler] = files
php_value[session.save_path] = /var/lib/php/session

; Ensure worker stdout and stderr are sent to the main error log
decorate_workers_output = no
```

Mount it in your `docker-compose.yml`:

```yaml
php:
  volumes:
    - ./docker/config/www.conf:/usr/local/etc/php-fpm.d/zz-custom.conf:ro
```

## Docker Compose Setup

### Basic Laravel Setup

```yaml
services:
  php:
    image: ghcr.io/maxcelos/php:8.5-fpm-alpine
    volumes:
      - ./:/var/www/html
    environment:
      DB_CONNECTION: mysql
      DB_HOST: mysql
      REDIS_HOST: redis
    depends_on:
      - mysql
      - redis

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./:/var/www/html:ro
      - ./docker/nginx/conf.d:/etc/nginx/conf.d:ro
    depends_on:
      - php

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: myapp
      MYSQL_ROOT_PASSWORD: secret

  redis:
    image: redis:7-alpine
```

### Full Stack with Queue Workers

See `docker-compose.sample.yml` for a complete example including:
- PHP-FPM
- Nginx
- MySQL
- Redis
- Mailpit (email testing)
- Queue workers
- Task scheduler

## Environment Variables

You can pass environment variables to configure your application:

```yaml
php:
  environment:
    # Application
    APP_ENV: production
    APP_DEBUG: false
    APP_KEY: base64:your-app-key

    # Database
    DB_CONNECTION: mysql
    DB_HOST: mysql
    DB_PORT: 3306
    DB_DATABASE: myapp

    # Cache
    CACHE_STORE: redis
    REDIS_HOST: redis
    REDIS_PORT: 6379

    # Session
    SESSION_DRIVER: redis

    # Mail
    MAIL_MAILER: smtp
    MAIL_HOST: smtp.mailtrap.io

    # Custom PHP settings (alternative to ini files)
    PHP_MEMORY_LIMIT: 512M
    PHP_MAX_EXECUTION_TIME: 60
```

## Common Use Cases

### Development Environment

```yaml
php:
  image: ghcr.io/maxcelos/php:8.5-fpm-alpine
  volumes:
    - ./:/var/www/html
    - ./docker/config/php.dev.ini:/usr/local/etc/php/conf.d/zz-custom.ini:ro
  environment:
    APP_ENV: local
    APP_DEBUG: true
```

With `php.dev.ini`:
```ini
display_errors = On
display_startup_errors = On
error_reporting = E_ALL
opcache.validate_timestamps = 1
opcache.revalidate_freq = 2
```

### Production Environment

```yaml
php:
  image: ghcr.io/maxcelos/php:8.5-fpm-alpine
  volumes:
    - ./:/var/www/html:ro  # Read-only for security
  environment:
    APP_ENV: production
    APP_DEBUG: false
```

Use default configurations (already optimized for production).

### Running Artisan Commands

```bash
# One-off commands
docker-compose exec php php artisan migrate

# Interactive shell
docker-compose exec php sh

# Running Composer
docker-compose exec php composer install --no-dev --optimize-autoloader
```

### Running Tests

```bash
# PHPUnit
docker-compose exec php php artisan test

# Pest
docker-compose exec php php artisan test --parallel
```

### Debugging

Mount custom php.ini with Xdebug settings:

```ini
[xdebug]
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.start_with_request=yes
```

Note: You'll need to install Xdebug in a custom image extending this one.

### File Permissions

The image includes an entrypoint script that handles file permissions automatically. It will:
- Match container user UID/GID with host user
- Set proper ownership for application files
- Configure writable directories

To customize, you can set environment variables:

```yaml
php:
  environment:
    PUID: 1000  # Your user ID
    PGID: 1000  # Your group ID
```

## Installed Extensions

This image includes the following PHP extensions:

- PDO (MySQL, PostgreSQL)
- BCMath
- MBString
- EXIF
- ZIP
- PCNTL
- Redis
- OPcache

## Additional Tools

- Composer 2.2
- Node.js and npm
- Git
- Common development utilities

## Troubleshooting

### Permission Issues

If you encounter permission issues:

1. Check your `entrypoint.sh` is executing correctly
2. Verify PUID/PGID environment variables match your host user
3. Ensure volumes are mounted with appropriate permissions

### Performance Issues

1. Check OPcache settings in production
2. Adjust PHP-FPM pool settings based on available resources
3. Monitor memory usage and adjust `memory_limit`
4. Enable Redis for sessions and cache

### Configuration Not Applied

1. Ensure custom ini files are mounted after default ones (use `zz-` prefix)
2. Check file permissions (should be readable)
3. Restart the container after changes
4. Verify mounts with: `docker-compose exec php php --ini`

## Support

For issues and feature requests, please visit:
https://github.com/maxcelos/docker-php-8.5-fpm-alpine/issues