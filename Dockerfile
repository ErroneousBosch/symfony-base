# Author: Richard Hopkins-Lutz
# Purpose: Dockerfile for PHP with Apache for use with Symfony
# Date: 2023-09-05
# Image basename: ghcr.io/erroneousbosch/symfony-base
FROM php:8.3-apache


RUN apt-get update; \
 apt-get install -y libyaml-dev git zip sqlite3 libicu-dev libmagickwand-dev imagemagick 

RUN cd /tmp \
&& git clone https://github.com/Imagick/imagick.git \
&& pecl install /tmp/imagick/package.xml 

RUN pecl install yaml \
&& docker-php-ext-enable yaml opcache imagick\
&& docker-php-ext-configure intl \
&& docker-php-ext-install intl 


RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
&& php composer-setup.php --install-dir=/usr/local/bin --filename=composer\
&& php -r "unlink('composer-setup.php');"

RUN  apt-get clean; \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share

RUN mkdir /app \
&& rm -r /var/www/html \
&& ln -s /app/public /var/www/html

ENV PATH="/app/bin:/app/vendor/bin:${PATH}"
WORKDIR /app

RUN sed -i 's#DocumentRoot /var/www/html#DocumentRoot /app/public \n <Directory /app/public>\n        AllowOverride None\n        Require all granted\n        FallbackResource /index.php\n   </Directory>#' /etc/apache2/sites-available/000-default.conf
USER www-data