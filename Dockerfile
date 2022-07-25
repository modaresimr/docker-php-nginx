ARG ALPINE_VERSION=3.16
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Ali Modaresi"
LABEL Description="Lightweight container with Nginx 1.22 & PHP 8.1 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php81 \
  php81-ctype \
  php81-curl \
  php81-dom \
  php81-fpm \
  php81-gd \
  php81-intl \
  php81-mbstring \
  php81-mysqli \
  php81-opcache \
  php81-openssl \
  php81-phar \
  php81-session \
  php81-xml \
  php81-xmlreader \
  php81-zlib \
  php81-zip\
  php81-exif\
#  imagemagick-dev imagemagick\
  php81-pecl-imagick\
  php81-fileinfo\
  supervisor \
  gnu-libiconv \
  php81-iconv

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php81 /usr/bin/php

# Configure nginx
COPY config/nginx.conf /config/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /config/fpm-pool.conf
COPY config/php.ini /config/php.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN rm -f /etc/nginx/nginx.conf && ln -s /config/nginx.conf /etc/nginx/nginx.conf  &&\
    rm -f /etc/php81/php-fpm.d/fpm-pool.conf && ln -s /config/fpm-pool.conf /etc/php81/php-fpm.d/fpm-pool.conf  &&\
    rm -f /etc/php81/conf.d/php.ini && ln -s /config/php.ini /etc/php81/conf.d/php.ini

# Setup document root
RUN mkdir -p /var/www/html
# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping
