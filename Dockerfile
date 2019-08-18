#
# PHP OS Builder
#
FROM php:7.3.7-fpm-alpine3.10 AS webtrees-os

RUN set -e \
    && apk add --no-cache \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install gd pdo mysqli pdo_mysql xml

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"


#
# Webtrees Application
#
FROM webtrees-os as webtrees-app

ENV WEBTREES_VERSION 1.7.14

WORKDIR /srv/webtrees

VOLUME /srv/webtrees/data /srv/webtrees/media

EXPOSE 80

RUN set -e \
    && wget https://github.com/fisharebest/webtrees/archive/$WEBTREES_VERSION.tar.gz \
    && tar -xzf $WEBTREES_VERSION.tar.gz --strip-components=1 \
    && rm $WEBTREES_VERSION.tar.gz
