FROM php:8.2-apache-bullseye

RUN apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libpq-dev \
		libzip-dev \
	; \
  docker-php-ext-install -j "$(nproc)" \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
  apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	rm -rf /var/lib/apt/lists/*

  RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

  COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
  RUN chmod +x /usr/bin/composer
  WORKDIR /opt/app
  RUN set -eux; \
	chown -R www-data:www-data /opt/app; \
	rmdir /var/www/html; \
	ln -sf /opt/app/web /var/www/html; 
	# delete composer cache
