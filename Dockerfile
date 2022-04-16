ARG PHP_VERSION=7.4
ARG ALPINE_VERSION=3.15

#
# PHP OS Builder
#
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS webtrees-os

COPY --from=docker.io/mlocati/php-extension-installer:1.5.8 /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
      exif \
      gd \
      imagick \
      intl \
      pdo_mysql \
      pdo_pgsql \
      zip

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

#
# Caddy Builder
#
FROM docker.io/caddy:2.4.6-builder-alpine AS caddy

RUN xcaddy build --with github.com/baldinof/caddy-supervisor

#
# Webtrees Application
#
FROM webtrees-os AS webtrees-app

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy

WORKDIR /srv/webtrees

ARG WEBTREES_VERSION=2.0.23

RUN rm -f /usr/local/etc/php-fpm.d/zz-docker.conf

# Install webtrees
RUN set -e \
 && wget -q https://github.com/fisharebest/webtrees/releases/download/$WEBTREES_VERSION/webtrees-$WEBTREES_VERSION.zip -O /tmp/webtrees.zip \
 && unzip -d /srv -o /tmp/webtrees.zip \
 && rm /tmp/webtrees.zip \
 && cp data/index.php /tmp/

ARG WEBTREES_FANCHART_VERSION=2.2.2

# Install webtrees fanchart module
RUN set -e \
 && wget -q https://github.com/magicsunday/webtrees-fan-chart/releases/download/$WEBTREES_FANCHART_VERSION/webtrees-fan-chart.zip -O /tmp/webtrees-fan-chart.zip \
 && unzip -d /srv/webtrees/modules_v4 -o /tmp/webtrees-fan-chart.zip \
 && rm /tmp/webtrees-fan-chart.zip

RUN chown -R www-data:www-data data

COPY Caddyfile /etc/Caddyfile
COPY entrypoint.sh /usr/local/bin/

VOLUME /srv/webtrees/data
EXPOSE 2015
ENTRYPOINT ["entrypoint.sh"]
