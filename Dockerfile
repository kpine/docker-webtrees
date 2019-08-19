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
# Caddy Builder
#
FROM abiosoft/caddy:builder as builder

ARG version="1.0.3"
ARG plugins=""

# Process Wrapper
RUN go get -v github.com/abiosoft/parent

RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=false /bin/sh /usr/bin/builder.sh

#
# Webtrees Application
#
FROM webtrees-os as webtrees-app

ENV WEBTREES_VERSION 1.7.14

# Caddy Let's Encrypt Agreement
ENV ACME_AGREE="true"

# Caddy Telemetry Stats
ENV ENABLE_TELEMETRY="false"

# Install Caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# Validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

# Install Process Wrapper
COPY --from=builder /go/bin/parent /bin/parent

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
