# =============================================================================
# Ticket Center — API  (PHP 8.4 · Laravel 12 · Nginx · Supervisord)
# =============================================================================
FROM php:8.4-fpm-alpine

# ── System packages ───────────────────────────────────────────────────────────
RUN apk add --no-cache \
        bash curl nginx supervisor \
        libpng-dev libjpeg-turbo-dev libwebp-dev freetype-dev \
        libxml2-dev libzip-dev \
        icu-dev oniguruma-dev \
        linux-headers \
        zip unzip mysql-client

# ── PHP extensions ────────────────────────────────────────────────────────────
RUN docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype \
 && docker-php-ext-install \
        pdo_mysql mbstring exif pcntl bcmath gd zip sockets intl opcache

# ── Opcache ───────────────────────────────────────────────────────────────────
RUN { echo "opcache.enable=1"; \
      echo "opcache.memory_consumption=128"; \
      echo "opcache.max_accelerated_files=10000"; \
      echo "opcache.validate_timestamps=0"; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# ── Composer ──────────────────────────────────────────────────────────────────
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# ── PHP dependencies ──────────────────────────────────────────────────────────
COPY composer.json composer.lock ./
RUN composer install \
        --no-dev \
        --no-scripts \
        --no-autoloader \
        --no-interaction \
        --prefer-dist

COPY . .

# ── Autoloader ────────────────────────────────────────────────────────────────
# --no-scripts: package:discover needs a real env, so it runs in the entrypoint.
RUN composer dump-autoload --optimize --no-dev --no-scripts

# ── Permissions ───────────────────────────────────────────────────────────────
RUN mkdir -p storage/logs \
             storage/framework/cache \
             storage/framework/sessions \
             storage/framework/views \
 && chown -R www-data:www-data /var/www \
 && chmod -R 775 storage bootstrap/cache

# ── Nginx config ──────────────────────────────────────────────────────────────
# CORS is handled by Laravel (config/cors.php) — not here, to avoid duplicate headers.
RUN printf '%s\n' \
    'user nginx;' \
    'worker_processes auto;' \
    'error_log /dev/stderr warn;' \
    'pid /var/run/nginx.pid;' \
    'events { worker_connections 1024; }' \
    'http {' \
    '    include /etc/nginx/mime.types;' \
    '    default_type application/octet-stream;' \
    '    sendfile on;' \
    '    keepalive_timeout 65;' \
    '    server {' \
    '        listen 8000;' \
    '        server_name _;' \
    '        root /var/www/public;' \
    '        index index.php;' \
    '        location = /favicon.ico { log_not_found off; access_log off; }' \
    '        location / { try_files $uri $uri/ /index.php?$query_string; }' \
    '        location ~ \.php$ {' \
    '            fastcgi_pass 127.0.0.1:9000;' \
    '            fastcgi_index index.php;' \
    '            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;' \
    '            include fastcgi_params;' \
    '            fastcgi_read_timeout 300;' \
    '        }' \
    '        location ~ /\.ht { deny all; }' \
    '    }' \
    '}' > /etc/nginx/nginx.conf

# ── Supervisord config ────────────────────────────────────────────────────────
# Only php-fpm + nginx. reverb and queue run as separate containers.
RUN mkdir -p /etc/supervisor/conf.d && printf '%s\n' \
    '[supervisord]' \
    'nodaemon=true' \
    'logfile=/dev/null' \
    'logfile_maxbytes=0' \
    'pidfile=/var/run/supervisord.pid' \
    '' \
    '[program:php-fpm]' \
    'command=php-fpm -F' \
    'autostart=true' \
    'autorestart=true' \
    'stdout_logfile=/dev/stdout' \
    'stdout_logfile_maxbytes=0' \
    'stderr_logfile=/dev/stderr' \
    'stderr_logfile_maxbytes=0' \
    '' \
    '[program:nginx]' \
    'command=nginx -g "daemon off;"' \
    'autostart=true' \
    'autorestart=true' \
    'stdout_logfile=/dev/stdout' \
    'stdout_logfile_maxbytes=0' \
    'stderr_logfile=/dev/stderr' \
    'stderr_logfile_maxbytes=0' \
    > /etc/supervisor/conf.d/supervisord.conf

# ── Entrypoint script ─────────────────────────────────────────────────────────
# RUN_MIGRATIONS=true on exactly ONE container (avoids migration races).
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    'cd /var/www' \
    '' \
    'if [ -z "$APP_KEY" ]; then' \
    '  echo "ERROR: APP_KEY is required (php artisan key:generate --show)" >&2' \
    '  exit 1' \
    'fi' \
    '' \
    'if [ -n "$DB_HOST" ] && [ "${DB_CONNECTION:-mysql}" = "mysql" ]; then' \
    '  echo "Waiting for MySQL at $DB_HOST:${DB_PORT:-3306}..."' \
    '  until (echo > /dev/tcp/"$DB_HOST"/"${DB_PORT:-3306}") 2>/dev/null; do' \
    '    sleep 2' \
    '  done' \
    '  echo "MySQL is ready."' \
    'fi' \
    '' \
    'php artisan package:discover --ansi || true' \
    '' \
    'if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then' \
    '  php artisan migrate --force' \
    'fi' \
    '' \
    'php artisan config:cache' \
    'php artisan route:cache' \
    'php artisan view:cache' \
    '' \
    '# artisan ran as root — hand writable dirs back to php-fpm user' \
    'chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache' \
    '' \
    'exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' \
    > /usr/local/bin/docker-entrypoint.sh \
 && chmod +x /usr/local/bin/docker-entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -fs http://127.0.0.1:8000/up || exit 1

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]