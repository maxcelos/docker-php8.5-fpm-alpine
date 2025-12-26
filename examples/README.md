# Configuration Examples

This directory contains example configuration files that you can copy and customize for your project.

## Directory Structure

```
examples/
├── config/              # PHP and PHP-FPM configuration examples
│   ├── php.dev.ini     # Development PHP settings
│   ├── php.prod.ini    # Production PHP settings
│   └── www.conf        # PHP-FPM pool configuration
└── nginx/              # Nginx configuration examples
    └── conf.d/
        └── default.conf # Laravel-optimized Nginx configuration
```

## Usage

### PHP Configuration

Copy the appropriate PHP configuration for your environment:

**For Development:**
```bash
mkdir -p docker/config
cp examples/config/php.dev.ini docker/config/php.ini
```

**For Production:**
```bash
mkdir -p docker/config
cp examples/config/php.prod.ini docker/config/php.ini
```

Then mount it in your `docker-compose.yml`:
```yaml
php:
  volumes:
    - ./docker/config/php.ini:/usr/local/etc/php/conf.d/zz-custom.ini:ro
```

### PHP-FPM Configuration

Copy and customize the PHP-FPM pool configuration:

```bash
mkdir -p docker/config
cp examples/config/www.conf docker/config/www.conf
```

Edit the file to adjust process manager settings based on your server resources, then mount it:

```yaml
php:
  volumes:
    - ./docker/config/www.conf:/usr/local/etc/php-fpm.d/zz-custom.conf:ro
```

### Nginx Configuration

Copy the Nginx configuration:

```bash
mkdir -p docker/nginx/conf.d
cp examples/nginx/conf.d/default.conf docker/nginx/conf.d/default.conf
```

Customize the file for your application (server name, SSL, etc.), then mount it:

```yaml
nginx:
  volumes:
    - ./docker/nginx/conf.d:/etc/nginx/conf.d:ro
```

## Customization Tips

### PHP Configuration

- **Memory Limit**: Adjust `memory_limit` based on your application needs
- **Upload Size**: Increase `upload_max_filesize` and `post_max_size` for file uploads
- **Execution Time**: Modify `max_execution_time` for long-running scripts
- **Error Display**: Keep `display_errors = Off` in production, `On` in development

### PHP-FPM Pool

- **Process Manager**: Use `dynamic` for variable load, `static` for consistent load
- **Max Children**: Calculate based on: (Available RAM) / (Average PHP process size)
- **Max Requests**: Set to recycle processes and prevent memory leaks
- **Timeouts**: Adjust `request_terminate_timeout` for long-running requests

### Nginx

- **Server Name**: Change `server_name` to your domain
- **SSL**: Add SSL configuration for HTTPS
- **Root Directory**: Ensure `root` points to your application's public directory
- **Client Max Body Size**: Match PHP's `upload_max_filesize`

## Environment-Specific Configurations

You can create different configurations for each environment:

```
docker/
├── config/
│   ├── php.local.ini
│   ├── php.staging.ini
│   └── php.production.ini
```

Then use environment variables in docker-compose:

```yaml
php:
  volumes:
    - ./docker/config/php.${APP_ENV}.ini:/usr/local/etc/php/conf.d/zz-custom.ini:ro
```

## Best Practices

1. Always test configuration changes in development first
2. Keep production configs focused on security and performance
3. Version control your docker configurations
4. Document any custom settings specific to your application
5. Use read-only mounts (`:ro`) for security
6. Prefix custom configs with `zz-` to ensure they load last

## Need Help?

- See [USAGE.md](../docs/USAGE.md) for detailed configuration documentation
- Check [docker-compose.sample.yml](docker-compose.sample.yml) for complete setup examples