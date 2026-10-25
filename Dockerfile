
# Stage 1: Install production PHP dependencies
FROM composer:2 AS composer-deps

WORKDIR /app

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --no-scripts \
    --optimize-autoloader


# Stage 2: Obtain Node.js
FROM node:22-bookworm-slim AS node-runtime


# Stage 3: Build frontend assets and generate Wayfinder routes
FROM php:8.4-cli-bookworm AS frontend

RUN apt-get update && apt-get install -y --no-install-recommends \
    libicu-dev \
    libzip-dev \
    unzip \
    libstdc++6 \
    && docker-php-ext-install pdo_mysql intl zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=node-runtime /usr/local/bin/node /usr/local/bin/node
COPY --from=node-runtime /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm

RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

WORKDIR /app

COPY composer.json composer.lock package.json package-lock.json ./
COPY --from=composer-deps /app/vendor ./vendor
COPY . .

RUN npm ci

RUN php artisan package:discover --ansi \
    && npm run build


# Stage 4: Run Laravel with PHP-FPM
FROM php:8.4-fpm-bookworm AS app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libicu-dev \
    libzip-dev \
    unzip \
    && docker-php-ext-install pdo_mysql intl zip opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY --from=composer-deps /app/vendor ./vendor
COPY . .
COPY --from=frontend /app/public/build ./public/build

RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && php artisan package:discover --ansi \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache

USER www-data

EXPOSE 9000

CMD ["php-fpm"]


# Stage 5: Serve public files through Nginx
FROM nginx:1.28-alpine AS web

COPY --from=app /var/www/html/public /var/www/html/public
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
