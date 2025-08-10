#!/bin/bash
set -e

APP_DIR="/var/www/dns"
if [ -z "${APP_DOMAIN}" ]; then
    APP_DOMAIN="example.com"
fi

if [ -n "${APP_URL}" ]; then
    CADDY_URL="${APP_URL#http://}"
    CADDY_URL="${CADDY_URL#https://}"
else
    APP_URL="https://dns.example.com"

    CADDY_URL="${APP_URL#http://}"
    CADDY_URL="${CADDY_URL#https://}"
fi
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

for INI in /etc/php/8.3/cli/conf.d/99-dnspanel /etc/php/8.3/fpm/conf.d/99-dnspanel; do
cat << 'EOF' > $INI
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=100M
opcache.jit=1255

[Session]
session.cookie_secure = 1
session.cookie_httponly = 1
session.cookie_samesite = "Strict"
session.cookie_domain = ${APP_DOMAIN}
EOF
done

OPCACHE_INI="/etc/php/8.3/mods-available/opcache.ini"
cat << 'EOF' > $OPCACHE_INI
[opcache]
opcache.jit_buffer_size=100M
opcache.jit=1255
EOF

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

service php8.3-fpm restart


if [ -n "${ADMIN_USER}" ]; then
    sed -i "s/admin/${ADMIN_USER}/" /var/www/dns/bin/create_admin_user.php
fi

if [ -n "${ADMIN_EMAIL}" ]; then
    sed -i "s/admin@example.com/${ADMIN_EMAIL}/" /var/www/dns/bin/create_admin_user.php
fi

if [ -n "${ADMIN_PASSWORD}" ]; then
    sed -i "s/TestPassword/${ADMIN_PASSWORD}/" /var/www/dns/bin/create_admin_user.php
else
    ADMIN_PASSWORD=$(tr -cd '[:graph:]' < /dev/urandom | head -c 12)
    sed -i "s/TestPassword/${ADMIN_PASSWORD}/" /var/www/dns/bin/create_admin_user.php
fi


sed -i "s/your-email@example.com/${ADMIN_EMAIL}/" /etc/caddy/Caddyfile
sed -i "s/dns.example.com/${CADDY_URL}/" /etc/caddy/Caddyfile

if [ "${TEST}" ]; then
    sed -i "s/tls/# tls/" /etc/caddy/Caddyfile
fi
. .env

until mysql -u ${DB_USERNAME} -h ${DB_HOST} -p${DB_PASSWORD} -P ${DB_PORT}  -e ";" ; do
       echo "Waiting for MySQL to be ready..."
       sleep 10
done
echo "MySQL is ready, running migrations..."

mysql -u ${DB_USERNAME} -h ${DB_HOST} -p${DB_PASSWORD} -P ${DB_PORT} < /var/www/dns/db.sql

composer install

echo "############################################"
cd /var/www/dns/bin
php create_admin_user.php
cd ..

echo "Admin user: ${ADMIN_USER}"
echo "Admin email: ${ADMIN_EMAIL}"
echo "Admin password: ${ADMIN_PASSWORD}"
echo "############################################"

exec "$@"
