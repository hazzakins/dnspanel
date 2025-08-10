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

# Configure PHP session cookie domain if APP_DOMAIN is set
if [ -n "${APP_DOMAIN}" ]; then
    for INI in /etc/php/8.3/cli/php.ini /etc/php/8.3/fpm/php.ini; do
        if [ -f "$INI" ]; then
            if grep -q '^\s*;\?\s*session\.cookie_domain' "$INI"; then
                sed -i -E "s/^\s*;?\s*session\.cookie_domain\s*=.*/session.cookie_domain = ${APP_DOMAIN}/" "$INI"
            else
                echo "session.cookie_domain = ${APP_DOMAIN}" >> "$INI"
            fi
        fi
    done
fi

# Start Caddy in the background
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

exec "$@"
