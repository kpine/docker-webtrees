VERSION 0.6

caddy:
  # Custom version of Caddy with Supervisor plugin
  FROM docker.io/caddy:2.5.2-builder-alpine

  RUN xcaddy build --output /caddy \
        --with github.com/baldinof/caddy-supervisor@v0.6.0
  SAVE ARTIFACT /caddy

php-extension-builder:
  FROM docker.io/mlocati/php-extension-installer:1.5.39
  SAVE ARTIFACT /usr/bin/install-php-extensions /install-php-extensions

build-php:
  ARG PHP_VERSION=7.4
  ARG ALPINE_VERSION=3.16
  FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION}

  COPY +php-extension-builder/install-php-extensions /usr/local/bin

  RUN install-php-extensions \
        exif \
        gd \
        imagick \
        intl \
        pdo_mysql \
        pdo_pgsql \
        zip \
   && rm /usr/local/bin/install-php-extensions

  # Use the default production configuration
  RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

webtrees:
  FROM +build-php

  ARG version
  RUN set -e \
   && wget -q https://github.com/fisharebest/webtrees/releases/download/$version/webtrees-$version.zip -O webtrees.zip \
   && unzip -d / -o webtrees.zip

  SAVE ARTIFACT /webtrees

fanchart:
  FROM +build-php

  ARG WEBTREES_FANCHART_VERSION=2.4.0

  RUN set -e \
   && wget -q https://github.com/magicsunday/webtrees-fan-chart/releases/download/$WEBTREES_FANCHART_VERSION/webtrees-fan-chart.zip -O webtrees-fan-chart.zip \
   && unzip -d / -o webtrees-fan-chart.zip

  SAVE ARTIFACT /webtrees-fan-chart

docker:
  FROM +build-php

  COPY +caddy/caddy /usr/bin/caddy
  COPY Caddyfile /etc/Caddyfile
  COPY entrypoint.sh /usr/local/bin/
  COPY php-fpm.conf /usr/local/etc/php-fpm.d/zz-docker.conf
  RUN caddy validate --config=/etc/Caddyfile

  ARG VERSION=2.1.7
  COPY --dir (+webtrees/webtrees --version=$VERSION) /srv
  COPY --dir +fanchart/webtrees-fan-chart /srv/webtrees/modules_v4/

  WORKDIR /srv/webtrees

  RUN chown -R www-data:www-data data \
   && cp data/index.php /tmp

  ARG EARTHLY_GIT_SHORT_HASH
  ARG BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  LABEL org.opencontainers.image.created=$BUILD_DATE
  LABEL org.opencontainers.image.description="Webtrees online genealogy with Caddy Server"
  LABEL org.opencontainers.image.revision=$EARTHLY_GIT_SHORT_HASH
  LABEL org.opencontainers.image.source="https://github.com/kpine/docker-webtrees"
  LABEL org.opencontainers.image.title="Webtrees"
  LABEL org.opencontainers.image.version=$VERSION

  VOLUME /srv/webtrees/data
  EXPOSE 2015
  ENTRYPOINT ["entrypoint.sh"]

  SAVE IMAGE --push kpine/caddy-webtrees:latest kpine/caddy-webtrees:$VERSION
