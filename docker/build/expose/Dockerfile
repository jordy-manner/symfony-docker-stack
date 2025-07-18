FROM composer:latest

RUN composer global require beyondcode/expose --prefer-dist --no-interaction

ENTRYPOINT ["/tmp/vendor/bin/expose"]