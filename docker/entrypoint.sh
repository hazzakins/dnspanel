#!/bin/bash
set -e

APP_DIR="/var/www/dns"

# Generate .env from env-sample using current environment variables
if [ -f "$APP_DIR/env-sample" ]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ -z "$line" || "$line" == \#* ]]; then
            printf '%s\n' "$line"
            continue
        fi

        key=${line%%=*}

        if [ "${!key+x}" ]; then
            printf '%s=%s\n' "$key" "${!key}"
        else
            printf '%s\n' "$line"
        fi
    done < "$APP_DIR/env-sample" > "$APP_DIR/.env"
fi

# Start Caddy in the background
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

exec "$@"
