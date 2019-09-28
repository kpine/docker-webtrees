ARG ALPINE_VERSION=3.10

#
# PHP OS Builder
#
FROM php:7.3.10-fpm-alpine${ALPINE_VERSION} AS webtrees-os

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
# Caddy Builder
#
FROM alpine:${ALPINE_VERSION} AS caddy-builder

ARG TARGETPLATFORM

ARG PLUGINS=http.cache,http.realip
ARG VERSION=v1.0.3

ARG CADDY_URL="https://caddyserver.com/download/$TARGETPLATFORM?version=${VERSION}&plugins=${PLUGINS}&license=personal&telemetry=off"


RUN apk add --no-cache git openssh-client tar curl

RUN curl \
        --silent --show-error --fail --location \
        --header "Accept: application/tar+gzip, application/x-zip, application/octet-stream" -p \
        ${CADDY_URL} \
  | tar --no-same-owner -C /usr/bin -xz caddy \
 && chmod 0755 /usr/bin/caddy

#
# Webtrees Application
#
FROM webtrees-os as webtrees-app

ARG WEBTREES_VERSION=1.7.14

COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy

# Validate install
RUN /usr/bin/caddy --version
RUN /usr/bin/caddy --plugins

WORKDIR /srv/webtrees

RUN set -e \
 && wget https://github.com/fisharebest/webtrees/archive/$WEBTREES_VERSION.tar.gz \
 && tar -xzf $WEBTREES_VERSION.tar.gz --strip-components=1 \
 && rm $WEBTREES_VERSION.tar.gz \
 && cp data/index.php /tmp/

RUN chown -R www-data:www-data data

COPY Caddyfile /etc/Caddyfile
COPY run.sh /usr/local/bin/

VOLUME /srv/webtrees/data
EXPOSE 2015
ENTRYPOINT ["/usr/local/bin/run.sh"]
