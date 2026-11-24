
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
    libpq-dev \
    unzip \
    libstdc++6 \
    && docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        intl \
        zip \
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


ARG APP_VERSION=dev
ARG GIT_SHA=unknown
ENV APP_VERSION=$APP_VERSION \
    GIT_SHA=$GIT_SHA



USER www-data

EXPOSE 9000

CMD ["php-fpm"]


# Stage 5: Serve public files through Nginx
FROM nginx:1.28-alpine AS web

COPY --from=app /var/www/html/public /var/www/html/public
COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template

# Stage 6: Single container for Render (nginx + PHP-FPM under supervisord)
       FROM app AS render

       USER root
       RUN apt-get update && apt-get install -y --no-install-recommends \
               nginx supervisor gettext-base \
           && apt-get clean \
           && rm -rf /var/lib/apt/lists/*

       COPY docker/render/nginx.conf.template /etc/nginx/nginx.conf.template
       COPY docker/render/php-fpm.conf /usr/local/etc/php-fpm.d/zz-render.conf
       COPY docker/render/supervisord.conf /etc/supervisor/render.conf
       COPY docker/render/entrypoint.sh /usr/local/bin/render-entrypoint
       RUN chmod 755 /usr/local/bin/render-entrypoint

       ENV PORT=10000
       EXPOSE 10000
       USER www-data
       ENTRYPOINT ["/usr/local/bin/render-entrypoint"]
       CMD []