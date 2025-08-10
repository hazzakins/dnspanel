#!/bin/bash
set -e

APP_DIR="/var/www/dns"

# Generate .env from env-sample using current environment variables
if [ -f "$APP_DIR/env-sample" ]; then
    envsubst < "$APP_DIR/env-sample" > "$APP_DIR/.env"
fi

# Start Caddy in the background
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

exec "$@"
