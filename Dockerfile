ARG PHP_VERSION=7.4
ARG ALPINE_VERSION=3.16
ARG CADDY_VERSION=2.5.2

#
# PHP OS Builder
#
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS webtrees-os

COPY --from=docker.io/mlocati/php-extension-installer:1.5.39 /usr/bin/install-php-extensions /usr/local/bin/

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
FROM docker.io/caddy:${CADDY_VERSION}-builder-alpine AS caddy

RUN xcaddy build ${CADDY_VERSION} --with github.com/baldinof/caddy-supervisor@v0.6.0

#
# Webtrees Application
#
FROM webtrees-os AS webtrees-app

WORKDIR /srv/webtrees

ARG WEBTREES_VERSION=2.1.7

# Install webtrees
RUN set -e \
 && wget -q https://github.com/fisharebest/webtrees/releases/download/$WEBTREES_VERSION/webtrees-$WEBTREES_VERSION.zip -O /tmp/webtrees.zip \
 && unzip -d /srv -o /tmp/webtrees.zip \
 && rm /tmp/webtrees.zip \
 && chown -R www-data:www-data data \
 && cp data/index.php /tmp
 
ARG WEBTREES_FANCHART_VERSION=2.4.0

# Install webtrees fanchart module
RUN set -e \
 && wget -q https://github.com/magicsunday/webtrees-fan-chart/releases/download/$WEBTREES_FANCHART_VERSION/webtrees-fan-chart.zip -O /tmp/webtrees-fan-chart.zip \
 && unzip -d /srv/webtrees/modules_v4 -o /tmp/webtrees-fan-chart.zip \
 && rm /tmp/webtrees-fan-chart.zip

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/Caddyfile
COPY entrypoint.sh /usr/local/bin/
COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-docker.conf

RUN caddy validate --config=/etc/Caddyfile

VOLUME /srv/webtrees/data
EXPOSE 2015
ENTRYPOINT ["entrypoint.sh"]
