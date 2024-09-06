# Author: Richard Hopkins-Lutz
# Purpose: Dockerfile for PHP with Apache for use with Symfony
# Date: 2023-09-05
# Image basename: ghcr.io/erroneousbosch/symfony-base
FROM php:8.3-apache


RUN apt-get update; \
 apt-get install -y git zip sqlite3 libmagickwand-dev imagemagick

# Switch to php-extension installer.
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions yaml opcache intl

# Unfortunately, the imagick installer archive on PECL is broken for PHP 8.3.
# https://github.com/Imagick/imagick/issues/640
# Install directly from the git repo
RUN cd /tmp \
&& git clone https://github.com/Imagick/imagick.git \
&& pecl install /tmp/imagick/package.xml \
&& docker-php-ext-enable imagick \
&& apt-get remove -y libmagickwand-dev \
&& rm -rf /tmp/imagick

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
&& php composer-setup.php --install-dir=/usr/local/bin --filename=composer\
&& php -r "unlink('composer-setup.php');"

RUN  apt-get autoremove -y \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share

RUN mkdir /app \
&& rm -r /var/www/html \
&& ln -s /app/public /var/www/html

ENV PATH="/app/bin:/app/vendor/bin:${PATH}"
WORKDIR /app

RUN sed -i 's#DocumentRoot /var/www/html#DocumentRoot /app/public \n <Directory /app/public>\n        AllowOverride None\n        Require all granted\n        FallbackResource /index.php\n   </Directory>#' /etc/apache2/sites-available/000-default.conf

ARG XDEBUG=false

RUN if ( ${XDEBUG} = true ); then  \
  install-php-extensions xdebug; \
  echo "[xdebug]" > /usr/local/etc/php/conf.d/xdebug.ini; \
  echo "zend_extension=xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini; \
  echo "xdebug.log =/var/log/apache2/error.log" > /usr/local/etc/php/conf.d/xdebug.ini; \
  echo "xdebug.mode=debug" > /usr/local/etc/php/conf.d/xdebug.ini; \
  echo "xdebug.client_host=host.docker.internal" > /usr/local/etc/php/conf.d/xdebug.ini; \
  echo "xdebug.max_nesting_level=256" > /usr/local/etc/php/conf.d/xdebug.ini; \
fi

USER www-data
