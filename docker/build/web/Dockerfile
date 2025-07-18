FROM php:8.4-apache

# Arguments defined in docker-compose.yml
ARG USER_UID
ARG USER_NAME

# Install system dependencies
RUN apt update && \
    apt install -y \
    vim \
    wget \
    curl \
    git \
    ssmtp \
    openssh-server \
    zip \
    unzip

# Clean
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install system dependencies
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions @composer apcu gd intl opcache pdo_pgsql pgsql zip

# Apache config
RUN sed -ri -e 's!/var/www/html!/var/www/html/app/public!g' /etc/apache2/sites-available/000-default.conf

# Sendmail
RUN echo "hostname=localhost.localdomain" > /etc/ssmtp/ssmtp.conf
RUN echo "mailhub=mail:1025" >> /etc/ssmtp/ssmtp.conf

# Custom configuration
RUN echo "sendmail_path=sendmail -i -t" >> ${PHP_INI_DIR}/conf.d/98-sendmail.ini
RUN echo "smtp_port=1025" >> ${PHP_INI_DIR}/conf.d/98-sendmail.ini

# Create system user to run Composer
RUN useradd -G www-data,root -u ${USER_UID} -d /home/${USER_NAME} ${USER_NAME}
RUN mkdir -p /home/${USER_NAME} && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

RUN a2enmod rewrite

# Use local user
USER ${USER_NAME}

# Config git
RUN git config --global --add safe.directory /var/www/html

# Set working directory
WORKDIR /var/www/html

CMD ["apachectl", "-D", "FOREGROUND"]

EXPOSE 80 443