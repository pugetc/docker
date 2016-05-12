FROM registry.access.redhat.com/rhscl/php-56-rhel7

MAINTAINER Cyrille Puget

ENV PS_VERSION=1.6.1.4 \
PS_DOMAIN=prestashop.local \
PS_LANGUAGE=en  \
PS_COUNTRY=gb \
PS_INSTALL_AUTO=0 \
PS_DEV_MODE=0 \
PS_HOST_MODE=0 \
PS_HANDLE_DYNAMIC_DOMAIN=0 \
PS_FOLDER_ADMIN=admin \
PS_FOLDER_INSTALL=install

RUN apt-get update \
	&& apt-get install -y libmcrypt-dev \
		libjpeg62-turbo-dev \
		libpng12-dev \
		libfreetype6-dev \
		libxml2-dev \
		mysql-client \
		mysql-server \
		wget \
		unzip \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install iconv mcrypt pdo mysql pdo_mysql mbstring soap gd

# Get PrestaShop
ADD https://www.prestashop.com/ajax/controller.php?method=download&type=releases&file=prestashop_1.6.1.4.zip&language=fr /tmp/prestashop.zip
RUN unzip -q /tmp/prestashop.zip -d /tmp/ && mv /tmp/prestashop/* /var/www/html && rm /tmp/prestashop.zip
COPY config_files/docker_updt_ps_domains.php /var/www/html/

# Apache configuration
# Expose 8080 because 80 is allowed only for root and change log files
RUN a2enmod rewrite
RUN chmod -R a+rwx /var/www/html/
RUN sed -e 's/Listen 80/Listen 8080/' -i /etc/apache2/apache2.conf /etc/apache2/ports.conf \
 && sed -i 's/ErrorLog .*/ErrorLog \/var\/log\/apache2\/error.log/' /etc/apache2/apache2.conf \
 && sed -i 's/CustomLog .*/CustomLog \/var\/log\/apache2\/custom.log combined/' /etc/apache2/apache2.conf \
 && sed -i 's/LogLevel .*/LogLevel info/' /etc/apache2/apache2.conf \
 && touch /var\/log\/apache2\/error.log \
 && touch \/var\/log\/apache2\/custom.log \
 && chmod -R a+rwx /var/log/apache2 \
 && chmod -R a+rwx /var/lock/apache2 \
 && chmod -R a+rwx /var/run/apache2

# PHP configuration
COPY config_files/php.ini /usr/local/etc/php/

# Expose 8080 because 80 is allowed only for root
EXPOSE 8080

# Volumes
VOLUME /var/www/html/modules
VOLUME /var/www/html/themes
VOLUME /var/www/html/override

COPY config_files/docker_run.sh /tmp/
RUN chmod +x /tmp/docker_run.sh

#User
USER 1001
ENTRYPOINT ["/tmp/docker_run.sh"]
