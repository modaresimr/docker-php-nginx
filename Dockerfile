FROM alpine:3.14
LABEL Maintainer="Ali Modaresi"
LABEL Description="Lightweight container with Nginx 1.20 & PHP 8.0 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk --no-cache add \
  curl \
  nginx \
  php8 \
  php8-ctype \
  php8-curl \
  php8-dom \
  php8-fpm \
  php8-gd \
  php8-intl \
  php8-json \
  php8-mbstring \
  php8-mysqli \
  php8-opcache \
  php8-openssl \
  php8-phar \
  php8-session \
  php8-xml \
  php8-xmlreader \
  php8-zlib \
  php8-zip\
  php8-exif\
#  imagemagick-dev imagemagick\
  php8-pecl-imagick\
  php8-fileinfo\
  supervisor \
  gnu-libiconv \
  php8-iconv

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php8 /usr/bin/php 
	

# Configure nginx
COPY config/nginx.conf /config/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /config/fpm-pool.conf
COPY config/php.ini /config/php.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN rm -f /etc/nginx/nginx.conf && ln -s /config/nginx.conf /etc/nginx/nginx.conf  &&\
    rm -f /etc/php8/php-fpm.d/fpm-pool.conf && ln -s /config/fpm-pool.conf /etc/php8/php-fpm.d/fpm-pool.conf  &&\
    rm -f /etc/php8/conf.d/php.ini && ln -s /config/php.ini /etc/php8/conf.d/php.ini

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

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
