# https://hub.docker.com/_/php
FROM php:8.5-fpm-alpine

LABEL org.opencontainers.image.description="PHP 8.5 image with Composer, NPM and support for MySQL, Postgres, SQLite and Redis. Laravel PHP production ready image to work with Deployer.org"
LABEL org.opencontainers.image.source="https://github.com/maxcelos/docker-php-8.5-fpm-alpine.git"

# Set Current Directory
WORKDIR /var/www/vhost/

# Install essential dependencies
RUN apk add --no-cache \
    libpq \
    libzip \
    libpng \
    libxml2 \
    icu-libs

# Install build dependencies, PHP extensions, then remove build dependencies
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libxml2-dev \
    icu-dev \
    oniguruma-dev \
    postgresql-libs \
    curl git unzip zlib-dev \
    autoconf \
    g++ \
    make \
    gcc \
    libc-dev \
    libtool \
    pkgconf \
    re2c \
    bison \
    linux-headers

# Install necessary build tools and headers for PHP extensions (autoconf, build-base, linux-headers)
# and then clean up the apk cache to keep the image size small.
RUN apk add --no-cache autoconf build-base linux-headers \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf build-base linux-headers


# Install PHP extensions one by one to avoid race conditions
RUN docker-php-ext-install pdo_pgsql
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install exif
RUN docker-php-ext-install zip
RUN docker-php-ext-install pcntl

# Clean up build dependencies
RUN apk del .build-deps


# Install Composer from Official Docker Image
COPY --from=composer:2.2 /usr/bin/composer /usr/bin/composer

# Configure PHP for production
COPY config/php.ini /usr/local/etc/php/conf.d/php.ini
COPY config/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Crie os diretórios, mas NÃO defina chown aqui. Isso será feito no entrypoint.
RUN mkdir -p /composer /var/www/vhost/app /root/.npm

# Install Node.js and npm
RUN apk add --no-cache nodejs npm

# Configure npm to use a directory the user can write to
RUN npm config set cache /.npm --global

# Install the 'shadow' package to provide usermod and groupmod
RUN apk add --no-cache shadow

# Copy an define permissions for entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Defina o entrypoint para o container
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Defina o comando padrão para o container (será executado após o entrypoint)
CMD ["php-fpm"]