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
        sed -i -E "s/;opcache\.enable\s*=.*/opcache.enable=1/" "$INI"
        sed -i -E "s/;opcache\.enable_cli\s*=.*/opcache.enable_cli=1/" "$INI"
        sed -i -E "s/;opcache\.jit_buffer_size\s*=.*/opcache.jit_buffer_size=100M/" "$INI"
        sed -i -E "s/;opcache\.jit\s*=.*/opcache.jit=1255/" "$INI"

        sed -i -E "s/;session\.cookie_secure\s*=.*/session.cookie_secure = 1/" "$INI"
        sed -i -E "s/;session\.cookie_httponly\s*=.*/session.cookie_httponly = 1/" "$INI"
        sed -i -E "s/;session\.cookie_samesite\s*=.*/session.cookie_samesite = \"Strict\"/" "$INI"

        if [ -f "$INI" ]; then
            if grep -q '^\s*;\?\s*session\.cookie_domain' "$INI"; then
                sed -i -E "s/^\s*;?\s*session\.cookie_domain\s*=.*/session.cookie_domain = ${APP_DOMAIN}/" "$INI"
            else
                echo "session.cookie_domain = ${APP_DOMAIN}" >> "$INI"
            fi
        fi
    done
    OPCACHE_INI="/etc/php/8.3/mods-available/opcache.ini"
    sed -i -E "s/;opcache\.jit_buffer_size\s*=.*/opcache.jit_buffer_size=100M/" "$OPCACHE_INI"
    sed -i -E "s/;opcache\.jit\s*=.*/opcache.jit=1255/" "$OPCACHE_INI"
fi

# Start Caddy in the background
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

exec "$@"
