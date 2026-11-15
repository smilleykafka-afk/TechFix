#!/bin/sh
set -eu

mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs
# Persist the local encryption key without copying the host's .env or secrets.
if [ ! -s storage/docker-app-key ]; then
    php -r 'echo "base64:".base64_encode(random_bytes(32));' > storage/docker-app-key
fi
export APP_KEY="${APP_KEY:-$(cat storage/docker-app-key)}"
# docker compose exec starts a new process without this shell's exports.
# This file is container-local; the host .env is excluded from the image.
printf 'APP_KEY=%s\n' "$APP_KEY" > /app/.env
# docker compose exec starts a new process without this shell's exports.
# This file is container-local; the host .env is excluded from the image.
printf 'APP_KEY=%s\n' "$APP_KEY" > /app/.env

if [ "${1:-}" = php ] && [ "${2:-}" = artisan ] && [ "${3:-}" = serve ]; then
    php artisan migrate --force --no-interaction
fi
exec "$@"
