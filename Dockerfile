# syntax=docker/dockerfile:1

ARG FLARUM_VERSION=v1.8.20
ARG ALPINE_VERSION=3.24

FROM docker.io/crazymax/yasu:latest AS yasu
FROM docker.io/crazymax/alpine-s6:${ALPINE_VERSION}-2.2.0.3

COPY --from=yasu / /
RUN apk --update --no-cache add \
    bash \
    curl \
    libgd \
    mysql-client \
    mariadb-connector-c \
    nginx \
    php83 \
    php83-cli \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-fpm \
    php83-gd \
    php83-gmp \
    php83-iconv \
    php83-intl \
    php83-json \
    php83-mbstring \
    php83-opcache \
    php83-openssl \
    php83-pdo \
    php83-pdo_mysql \
    php83-pecl-uuid \
    php83-phar \
    php83-session \
    php83-simplexml \
    php83-sodium \
    php83-tokenizer \
    php83-xml \
    php83-xmlwriter \
    php83-zip \
    php83-zlib \
    shadow \
    tar \
    tzdata \
  && ln -s /usr/bin/php83 /usr/bin/php \
  && rm -rf /tmp/* /var/www/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2"\
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

ARG FLARUM_VERSION
RUN mkdir -p /opt/flarum \
  && curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && COMPOSER_CACHE_DIR="/tmp" composer create-project flarum/flarum /opt/flarum "^1.8" --no-install \
  && composer config --working-dir /opt/flarum policy.advisories.block false \
  && COMPOSER_CACHE_DIR="/tmp" composer require --working-dir /opt/flarum flarum/core:${FLARUM_VERSION} \
  && composer clear-cache \
  && addgroup -g ${PGID} flarum \
  && adduser -D -h /opt/flarum -u ${PUID} -G flarum -s /bin/sh -D flarum \
  && chown -R flarum:flarum /opt/flarum \
  && rm -rf /root/.composer /tmp/*

# Extensions baked into the image. Pass an empty value to build a plain Flarum
# image; `extension require` still works at runtime for anything added later.
ARG FLARUM_EXTENSIONS="\
  askvortsov/flarum-categories \
  clarkwinkelmann/flarum-ext-mass-actions \
  fof/analytics \
  fof/anti-spam \
  fof/cookie-consent \
  fof/filter \
  fof/nightmode \
  fof/oauth \
  fof/pwned-passwords \
  fof/recaptcha \
  fof/spamblock \
  fof/split \
  fof/terms \
  fof/upload \
  hikarilan/flarum-passkey-login \
  ianm/gravatar \
  ianm/twofactor \
  v17development/flarum-seo"

RUN if [ -n "${FLARUM_EXTENSIONS}" ]; then \
    COMPOSER_CACHE_DIR="/tmp" composer require --working-dir /opt/flarum --no-interaction --no-progress ${FLARUM_EXTENSIONS} \
      && chown -R flarum:flarum /opt/flarum; \
  fi \
  && rm -rf /root/.composer /tmp/*

COPY rootfs /

EXPOSE 8000
WORKDIR /opt/flarum
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
