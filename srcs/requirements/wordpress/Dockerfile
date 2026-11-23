FROM alpine:3.23.6

# hadolint ignore=DL3018
RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-json \
    php83-curl \
    php83-dom \
    php83-xml \
    php83-mbstring \
    php83-openssl \
    php83-phar \
    php83-session \
    php83-fileinfo \
    php83-tokenizer \
    php83-zip \
    php83-iconv \
    mariadb-client \
    curl && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php83/php.ini && \
    ln -s /usr/bin/php83 /usr/bin/php && \
    curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp && \
    mkdir -p /var/www/wordpress

WORKDIR /var/www/wordpress

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm83", "-F"]

