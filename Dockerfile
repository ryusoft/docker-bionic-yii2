FROM ubuntu:bionic
LABEL maintainer="RYU Chua <me@ryu.my>"

ENV DEBIAN_FRONTEND=noninteractive \
    OS_LOCALE="en_US.UTF-8" \
    TZ="Asia/Kuala_Lumpur" \
    LANG=${OS_LOCALE} \
    LANGUAGE=${OS_LOCALE} \
    LC_ALL=${OS_LOCALE} \
    APACHE_CONF_DIR=/etc/apache2 \
    PHP_CONF_DIR=/etc/php/7.2 \
    PHP_DATA_DIR=/var/lib/php \
    BUILD_DEPS='software-properties-common'

COPY entrypoint.sh /sbin/entrypoint.sh

RUN apt-get update \
	&& apt-get install -y locales tzdata wget gnupg2 \
    && unlink /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime \
	&& locale-gen ${OS_LOCALE} \
    && dpkg-reconfigure locales tzdata \
    && apt-get update \
    # Install common libraries
    && apt-get install --no-install-recommends -y $BUILD_DEPS \
    # Install PHP libraries
    && apt-get install -y apache2 php php-cli php-mbstring php-curl \
    	php-xml php-bcmath php-intl php-zip php-mysql php-pgsql php-json php-imagick php-gd php-memcached php-memcache \
    	libapache2-mod-php php7.2-dev php-pear phpunit libz-dev composer \
    	libfontenc1 x11-common xfonts-75dpi xfonts-base xfonts-encodings xfonts-utils fontconfig libxrender1 composer \
	# wkhtmltopdf
	&& wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb -P /tmp \
	&& dpkg -i /tmp/wkhtmltox_0.12.6-1.bionic_amd64.deb \
    # Apache settings
    && cp /dev/null ${APACHE_CONF_DIR}/conf-available/other-vhosts-access-log.conf \
    && a2enmod rewrite \
    # gRPC & Protobuf
    && pecl install grpc \
    && pecl install protobuf \
    # adding to config
    && echo "extension=grpc.so" > /etc/php/7.2/mods-available/grpc.ini \
    && echo "extension=protobuf.so" > /etc/php/7.2/mods-available/protobuf.ini \
    && ln -s /etc/php/7.2/mods-available/grpc.ini /etc/php/7.2/cli/conf.d/20-grpc.ini \
    && ln -s /etc/php/7.2/mods-available/grpc.ini /etc/php/7.2/apache2/conf.d/20-grpc.ini \
    && ln -s /etc/php/7.2/mods-available/protobuf.ini /etc/php/7.2/cli/conf.d/20-protobuf.ini \
    && ln -s /etc/php/7.2/mods-available/protobuf.ini /etc/php/7.2/apache2/conf.d/20-protobuf.ini \
    # cleaning
    && apt-get purge -y --auto-remove wget gnupg2 php-pear phpunit libz-dev \
    && apt-get purge -y --auto-remove $BUILD_DEPS \
    && apt-get autoremove -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/pear \
    && rm -rf /tmp/wkhtmltox_0.12.6-1.bionic_amd64.deb \
    # Forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log \
    && chmod 755 /sbin/entrypoint.sh \
    && chown www-data:www-data ${PHP_DATA_DIR} -Rf

EXPOSE 80 443

# By default, simply start apache.
CMD ["/sbin/entrypoint.sh"]
