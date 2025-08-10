FROM ubuntu:24.04

RUN apt update
RUN apt install -y \
    bzip2 composer git net-tools php8.3 php8.3-bcmath php8.3-bz2 php8.3-cli \
    php8.3-common php8.3-curl php8.3-ds php8.3-fpm php8.3-gd php8.3-gmp php8.3-igbinary \
    php8.3-imap php8.3-intl php8.3-mbstring php8.3-opcache php8.3-readline php8.3-redis \
    php8.3-soap php8.3-swoole php8.3-uuid php8.3-xml php8.3-zip \
    unzip wget whois curl software-properties-common

