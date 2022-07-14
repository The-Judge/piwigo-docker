ARG PHP_VARIANT=apache
ARG PHP_VERSION=7.4

FROM php:${PHP_VERSION}-${PHP_VARIANT}

ARG PIWIGO_VERSION=12.3.0
ENV PIWIGO_DEST=/var/www/html
ENV DEBIAN_FRONTEND=noninteractive

ADD entrypoint.sh /usr/local/bin/docker-php-entrypoint
RUN chmod +x /usr/local/bin/docker-php-entrypoint

# Download Piwigo
ADD https://github.com/Piwigo/Piwigo/archive/refs/tags/${PIWIGO_VERSION}.tar.gz /usr/src/piwigo-${PIWIGO_VERSION}.tar.gz
RUN ln /usr/src/piwigo-${PIWIGO_VERSION}.tar.gz /usr/src/piwigo.tar.gz
ADD database.inc.php /usr/src/piwigo_database.inc.php
ADD init_db.gz /usr/src/init_db.gz

# Install mariadb-client
RUN apt update ; \
    apt install -y \
      ffmpeg \
      libgd-dev \
      libimage-exiftool-perl \
      libjpeg-turbo-progs \
      libmagickwand-dev \
      mariadb-client \
      ; \
    apt-get clean

# See https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions mysqli imagick gd exif

# production or development
ARG PHP_INI=production
RUN ln "$PHP_INI_DIR/php.ini-${PHP_INI}" "$PHP_INI_DIR/php.ini"
