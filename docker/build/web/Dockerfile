FROM dunglas/frankenphp:php8.4

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

# Install PHP extensions (install-php-extensions est déjà inclus dans l'image FrankenPHP)
RUN install-php-extensions @composer apcu gd intl opcache pdo_pgsql pgsql zip

# Sendmail
RUN echo "hostname=localhost.localdomain" > /etc/ssmtp/ssmtp.conf
RUN echo "mailhub=mail:1025" >> /etc/ssmtp/ssmtp.conf

# Custom configuration
RUN echo "sendmail_path=sendmail -i -t" >> ${PHP_INI_DIR}/conf.d/98-sendmail.ini
RUN echo "smtp_port=1025" >> ${PHP_INI_DIR}/conf.d/98-sendmail.ini

# Create system user to run Composer and app
RUN useradd -G www-data,root -u ${USER_UID} -d /home/${USER_NAME} ${USER_NAME}
RUN mkdir -p /home/${USER_NAME} && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# Caddy data dir — doit appartenir à l'user non-root
RUN mkdir -p /data/caddy /config/caddy && \
    chown -R ${USER_UID}:${USER_UID} /data /config

# Use local user
USER ${USER_NAME}

# Config git
RUN git config --global --add safe.directory /app

# Set working directory — FrankenPHP sert depuis /app/public par défaut
WORKDIR /app

# FrankenPHP est derrière Traefik qui gère le TLS → on écoute en HTTP simple
ENV SERVER_NAME=":80"

EXPOSE 80 443 443/udp
