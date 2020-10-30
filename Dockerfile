ARG PHP_VERSION=7.4
ARG ALPINE_VERSION=3.12

#
# PHP OS Builder
#
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS webtrees-os

RUN set -e \
 && apk add --no-cache --virtual .phpize-deps \
      $PHPIZE_DEPS \
      freetype-dev \
      icu-dev \
      imagemagick-dev \
      libjpeg-turbo-dev \
      libpng-dev \
      libtool \
      libxml2-dev \
      libzip-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install exif gd intl pdo mysqli pdo_mysql xml zip \
 && export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
 && pecl install imagick-3.4.4 \
 && docker-php-ext-enable imagick \
 && apk add --no-cache --virtual .php-runtime-deps \
      icu-libs \
      libzip \
      libxml2 \
      imagemagick \
 && apk del .phpize-deps

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

#
# Caddy Builder
#
FROM caddy:2.1.1-alpine AS caddy

#
# Webtrees Application
#
FROM webtrees-os AS webtrees-app

RUN set -e \
 && apk add --no-cache supervisor

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

WORKDIR /srv/webtrees

ARG WEBTREES_VERSION=2.0.10

# Install webtrees
RUN set -e \
 && wget -q https://github.com/fisharebest/webtrees/releases/download/$WEBTREES_VERSION/webtrees-$WEBTREES_VERSION.zip -O /tmp/webtrees.zip \
 && unzip -d /srv -o /tmp/webtrees.zip \
 && rm /tmp/webtrees.zip \
 && cp data/index.php /tmp/

ARG WEBTREES_FANCHART_VERSION=v2.0.3

# Install webtrees fanchart module
RUN set -e \
 && wget -q https://github.com/magicsunday/webtrees-fan-chart/releases/download/$WEBTREES_FANCHART_VERSION/webtrees-fan-chart.zip -O /tmp/webtrees-fan-chart.zip \
 && unzip -d /srv/webtrees/modules_v4 -o /tmp/webtrees-fan-chart.zip \
 && rm /tmp/webtrees-fan-chart.zip

RUN chown -R www-data:www-data data

COPY supervisord.conf /etc/supervisord.conf
COPY Caddyfile /etc/Caddyfile
COPY entrypoint.sh /usr/local/bin/

VOLUME /srv/webtrees/data
EXPOSE 2015
ENTRYPOINT ["entrypoint.sh"]
