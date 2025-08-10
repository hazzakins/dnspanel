FROM ubuntu:24.04

RUN apt update
RUN apt install -y curl software-properties-common
RUN add-apt-repository ppa:ondrej/php
RUN apt update
RUN apt install -y --no-install-recommends \
    bzip2 composer git net-tools php8.3 php8.3-bcmath php8.3-bz2 php8.3-cli \
    php8.3-common php8.3-curl php8.3-ds php8.3-fpm php8.3-gd php8.3-gmp php8.3-igbinary \
    php8.3-imap php8.3-intl php8.3-mbstring php8.3-opcache php8.3-readline php8.3-redis \
    php8.3-soap php8.3-swoole php8.3-uuid php8.3-xml php8.3-zip \
    unzip wget whois 

RUN apt-get update && apt-get install -y --no-install-recommends gettext-base

RUN rm -rf /var/lib/apt/lists/*

RUN curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' -o caddy-stable.gpg.key \
    gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg caddy-stable.gpg.key \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list

RUN apt update 
RUN apt install -y --no-install-recommends caddy

RUN mkdir /usr/share/adminer
RUN wget "http://www.adminer.org/latest.php" -O /usr/share/adminer/latest.php
RUN ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php

COPY . /var/www/dns

RUN mkdir -p /var/log/dns
RUN chown -R www-data:www-data /var/log/dns
RUN chown -R www-data:www-data /var/www/dns/cache/

WORKDIR /var/www/dns
RUN composer install
RUN mv env-sample .env

COPY docker/Caddyfile /etc/caddy/Caddyfile

RUN systemctl enable caddy

ENV PHP_INI_opcache__enable=1 \
    PHP_INI_opcache__enable_cli=1 \
    PHP_INI_opcache__jit=1255 \
    PHP_INI_opcache__jit_buffer_size=100M \
    PHP_INI_session__cookie_secure=1 \
    PHP_INI_session__cookie_httponly=1 \
    PHP_INI_session__cookie_samesite=Strict \
    PHP_INI_session__cookie_domain=example.com

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm8.3", "-F"]   # or your preferred command (apache2-foreground, etc.)
