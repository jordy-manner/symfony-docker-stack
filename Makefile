#!make

SHELL := /bin/bash

ifndef DOCKER_ENV
export DOCKER_ENV=dev
endif

ifndef DOCKER_DIR
export DOCKER_DIR=$(PWD)/docker
endif

# Import .env file
include $(DOCKER_DIR)/conf/.env

# set binary
composer = @$(php) -d memory_limit=-1 /usr/local/bin/composer --working-dir=app/
console = @$(php) php -d memory_limit=-1 app/bin/console
docker-compose = docker compose -f $(DOCKER_DIR)/compose.yml -f $(DOCKER_DIR)/compose.override.yml -p $(PROJECT_NAME)
node = @$(docker-compose) exec node
php = @$(docker-compose) run --rm web php

# output colors
C_BLACK=\033[0;30m
C_RED=\033[0;31m
C_GREEN=\033[0;32m
C_YELLOW=\033[0;33m
C_BLUE=\033[0;34m
C_PURPLE=\033[0;35m
C_CYAN=\033[0;36m
C_WHITE=\033[0;37m
C_GRAY=\033[0;90m
C_NONE=\033[0m

# set vars
date = $(shell date +'%y%m%d%H%M%S')
config_vars=\
	PROJECT_NAME\
	PROJECT_DIR\
	APP_DIR\
	SERVE_BASE_HOST\
	SERVE_WEB_PROXY\
	SERVE_DBMGR_PROXY\
	SERVE_MAILCATCH_PROXY\
	SERVE_REVERSE_PROXY\
	LOCAL_UID\
	LOCAL_USERNAME\
	LOCAL_GID\
	LOCAL_HOME\
	LOCAL_DOCKER_IP\
	APP_RELEASE\
	DB_ENGINE\
	DB_HOST\
	DB_PORT\
	DB_CHARSET\
	DB_SERVER_VERSION\
	DB_ROOT_PASSWORD\
	DB_NAME\
	DB_USER\
	DB_PASSWORD\
	DB_DUMP_INSTALL_PATH\
	CERT_DIR\
	CERT_CA_DIR\
	CERT_CA_COUNTR\
	CERT_CA_STATE\
	CERT_CA_LOCALITY\
	CERT_CA_ORG\
	CERT_CA_ORG_UNIT\
	CERT_CA_COMMON_NAME\
	CERT_CA_SUBJ\
	CERT_CA_CRT\
	CERT_CA_KEY\
	CERT_CA_SERIAL_FILE\
	CERT_DOMAIN\
	CERT_KEY\
	CERT_CSR\
	CERT_CRT\
	CERT_EXT\
	NGROK_AUTHTOKEN\
	EXPOSE_SHARE_TOKEN

# default target
.DEFAULT_GOAL := help

##@ Initialization (should be deleted on your own project)
.PHONY: init ## Initialize application.
init: up init-cert init-create init-dependencies info

.PHONY: init ## Clean, flush and  renew initialization.
reinit: init-reset init-clean down init


init-reset:
	@echo "⚠️  WARNING: This will delete the application folder and all related data!" && \
	read -p "Are you sure you want to continue? [y/N] " answer; \
	if [ "$$answer" != "y" ]; then \
		echo "Aborted."; \
		exit 1; \
	fi; \
	echo "Proceeding with reset..."; \

.PHONY: init-cert
init-cert: install-cert

.PHONY: init-create
init-create: ## Download and install Roots/Sage.
	$(docker-compose) exec -ti web bash -c '/usr/local/bin/composer create-project symfony/skeleton:"${or ${version}, 6.4.x}" app/'
##? [version="{{ version }}"]	Symfony version, 6.4.x by default.

.PHONY: init-dependencies
init-dependencies: ## Install application dependencies.
	$(composer) remove symfony/ux-turbo symfony/asset-mapper symfony/stimulus-bundle
	$(composer) require webapp symfony/webpack-encore-bundle
	@make npm CMD="install"
	@make npm CMD="run build"

init-clean: ## Clean initialization to allow renewing.
	@rm -rf ${APP_DIR}/* ${APP_DIR}/.[!.]* ${APP_DIR}/..?*

##@ General
.PHONY: help
help: ## ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\n${PROJECT_NAME} ${C_GREEN}${APP_RELEASE}${C_NONE}\n\nUsage:\n  make ${C_BLUE}<target>${C_NONE}\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  ${C_GREEN}%-25s${C_NONE} %s\n", $$1, $$2 } /^##@/ { printf "\n${C_YELLOW}%s${C_NONE}\n", substr($$0, 5) } /^##\?/ { printf "  ${C_GRAY}%s${C_NONE}\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: info
info: ## Show services info.
	@printf "\n${PROJECT_NAME} ${C_GREEN}${APP_RELEASE}${C_NONE}\n"
	@printf "\n${C_CYAN}WEB FRONT APPLICATION${C_NONE}\n"
	@printf "   http://${SERVE_WEB_PROXY} ${C_GRAY}[$$(curl -k -s -o /dev/null -w "%{http_code}" http://${SERVE_WEB_PROXY})]${C_NONE}\n"
	@printf "   https://${SERVE_WEB_PROXY} ${C_GRAY}[$$(curl -k -s -o /dev/null -w "%{http_code}" https://${SERVE_WEB_PROXY})]${C_NONE}\n"
	@printf "   http://$$(make ip container=web -s) ${C_GRAY}[$$(curl -s -o /dev/null -w "%{http_code}" http://$$(make ip container=web -s))]${C_NONE}\n"
	@printf "\n${C_CYAN}DB MANAGER${C_NONE}\n"
	@printf "   https://${SERVE_DBMGR_PROXY} ${C_GRAY}[$$(curl -k -s -o /dev/null -w "%{http_code}" https://${SERVE_DBMGR_PROXY})]${C_NONE}\n"
	@printf "   http://$$(make ip container=adminer -s):8080 ${C_GRAY}[$$(curl -s -o /dev/null -w "%{http_code}" http://$$(make ip container=adminer -s):8080)]${C_NONE}\n"
	@printf "\n${C_CYAN}MAIL CATCHER${C_NONE}\n"
	@printf "   https://${SERVE_MAILCATCH_PROXY} ${C_GRAY}[$$(curl -k -s -o /dev/null -w "%{http_code}" https://${SERVE_MAILCATCH_PROXY})]${C_NONE}\n"
	@printf "   http://$$(make ip container=mail -s):8025 ${C_GRAY}[$$(curl -s -o /dev/null -w "%{http_code}" http://$$(make ip container=mail -s):8025)]${C_NONE}\n"
	@printf "\n${C_CYAN}TRAEFIK${C_NONE}\n"
	@printf "   https://${SERVE_REVERSE_PROXY} ${C_GRAY}[$$(curl -k -s -o /dev/null -w "%{http_code}" https://${SERVE_REVERSE_PROXY})]${C_NONE}\n"
	@printf "   http://$$(make ip container=traefik -s):8080 ${C_GRAY}[$$(curl -k -s -o /dev/null -w "%{http_code}" http://$$(make ip container=traefik -s):8080)]${C_NONE}\n"
	@printf "\n${C_CYAN}DATABASE${C_NONE}\n"
	@printf "   ${C_GREEN}Engine:${C_NONE}		${DB_ENGINE}\n"
	@printf "   ${C_GREEN}Host:${C_NONE}		`make ip container=db -s`\n"
	@printf "   ${C_GREEN}Port:${C_NONE}		${DB_PORT}\n"
	@printf "   ${C_GREEN}Name:${C_NONE}		${DB_NAME}\n"
	@printf "   ${C_GREEN}User:${C_NONE}		${DB_USER}\n"
	@printf "   ${C_GREEN}Password:${C_NONE}		${DB_PASSWORD}\n"
	@printf "   ${C_GREEN}DSN:${C_NONE}			${DB_ENGINE}://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?serverVersion=${DB_SERVER_VERSION}&charset=${DB_CHARSET}\n"

.PHONY: ip
ip: ## Show container IP.
	@docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $$($(docker-compose) ps -aq ${or ${container}, web})
##? [container="{{ name }}"]	Service name, web by default.

.PHONY: ips
ips: ## Show container IPs.
	@for CONTAINER in $$(docker container ls --filter name=$(PROJECT_NAME) | awk '{print $$NF}' | awk 'NR > 1'); do echo -e "\033[32m$$CONTAINER\033[0m" $$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $$CONTAINER); done | column -t

.PHONY: open
open: ## Open browser
	@nohup xdg-open https://${SERVE_WEB_PROXY} > /dev/null 2>&1

##@ Install
.PHONY: install
install: build up install-dependencies install-database install-fixtures post-install info ## ## Installing project

.PHONY: install-cert
install-cert: cert-init-ca cert-sign cert-generate-traefik-config cert-import-ca
	@echo "✅ All certificates have been successfully generated!"

.PHONY: install-dependencies
install-dependencies: ## Install application dependencies.
	@$(composer) install --no-interaction --no-progress --optimize-autoloader --prefer-dist
	@make yarn CMD="install"
	@make yarn CMD="build"

.PHONY: install-database
install-database: ## Install application database.
	@if [ -f "$(DB_DUMP_INSTALL_PATH)" ]; then \
		make up container=db; \
		make db-import FILE=$(DB_DUMP_INSTALL_PATH); \
		$(console) doctrine:migrations:migrate --allow-no-migration --no-interaction --quiet
	else \
		echo "No database dump file found at $(DB_DUMP_INSTALL_PATH). Please create it before installing the database."; \
	fi

install-fixtures: ## Install application fixtures.
	@$(console) doctrine:fixtures:load --no-interaction

.PHONY: post-install
post-install: ## Execute post-install scripts.
	@$(docker-compose) exec -u ${LOCAL_USERNAME} web /bin/bash scripts/post-install.sh

.PHONY: uninstall
uninstall: clean ## Uninstall application.
	@$(docker-compose) down --remove-orphans ${or ${container}, -v}
##? [container="{{ name }}"]	For only one container by it service name.

.PHONY: reinstall
reinstall: uninstall install ## Reinstall application.

.PHONY: clean
clean: ## Remove application dependencies.
	@rm -rf $(APP_ROOT_DIR)/var/cache $(APP_ROOT_DIR)/var/log $(APP_ROOT_DIR)/vendor/ $(APP_ROOT_DIR)/node_modules $(APP_ROOT_DIR)/public/build $(APP_ROOT_DIR)/public/bundles

.PHONY: start
start: up install-dependencies post-install info ## Start application.

.PHONY: restart
restart: stop start ## Restart application.

##@ Docker
.PHONY: build
build: ## Build docker images.
	@$(docker-compose) build $(container)
##? [container="{{ name }}"]	For only one container by it service name.

.PHONY: rebuild
rebuild: ## Rebuild docker images.
	@$(docker-compose) build --no-cache $(container)
##? [container="{{ name }}"]	For only one container by it service name.

.PHONY: up
up: ## (Re-)Create and start containers.
	@$(docker-compose) up -d --remove-orphans $(container)
##? [container="{{ name }}"]	For only one container by it service name.

.PHONY: down
down: ## (Re-)Create and start containers.
	@$(docker-compose) down $(container) ${or ${CMD}, --volumes}

.PHONY: stop
stop: ## Stop containers.
	@$(docker-compose) stop $(container)
##? [container="{{ name }}"]	For only one container by it service name.

.PHONY: respawn
respawn: stop up ## Stop and up containers.
##? [container="{{ name }}"]	For only one container by it service name.

.PHONY: ps
ps: ## List containers status.
	@$(docker-compose) ps $(container)
##? [container="{{ name }}"]	For only one container by it service name.

.PHONY: logs
logs: ## Show containers logs.
	@$(docker-compose) logs -f $(container)
##? [container="{{ name }}"]	For only one container by it service name.

##@ Configuration
.PHONY: config
config: ## Print list of configuration variables.
	@for var in $(config_vars); do \
		echo "$$var=$${!var}"; \
	done

.PHONY: config-get
config-get: guard-KEY ## Print one configuration variable.
	@echo ${if ${KEY}, "$$KEY=$${!KEY}", '"var" arg is required'}
##? [KEY="{{ name }}"]		Required environment variable name.

.PHONY: config-set
config-set: guard-KEY guard-VAL ## Set a customized configuration variable.
	@SCOPE=$(SCOPE); \
	if [ -z "$$SCOPE" ]; then \
		SCOPE=local; \
	fi; \
	if [ "$$SCOPE" = "global" ]; then \
		FILE=.config.env; \
	else \
		FILE=.config.env.$$SCOPE; \
	fi; \
	KEY=$(KEY); \
	VAL=$(VAL); \
	if [ ! -f $$FILE ]; then \
		touch $$FILE; \
	fi; \
	if grep -q "^$$KEY=" $$FILE; then \
		if sed --version >/dev/null 2>&1; then \
			sed -i "s|^$$KEY=.*|$$KEY=$$VAL|" $$FILE; \
		else \
			sed -i '' "s|^$$KEY=.*|$$KEY=$$VAL|" $$FILE; \
		fi; \
	else \
		echo "$$KEY=$$VAL" >> $$FILE; \
	fi; \
	echo "✅ $$KEY set to '$$VAL' in $$FILE (scope: $$SCOPE)"
##? [KEY="{{ name of variable }}"]		Variable name.
##? [VAL="{{ value of variable }}"]		Variable value.
##? [SCOPE="{{ local|global|${DOCKER_ENV} }}"]	Scope of variable.

##@ Utils
.PHONY: bash
bash: ## Open a container bash.cd
	@$(docker-compose) exec -u ${or ${user}, root} ${or ${container}, web} /bin/bash
##? [container="{{ name }}"]	Service name, [web] by default.
##? [user="{{ name }}"]		User name, [root] by default.

.PHONY: sh
sh: ## Open a container shell.
	@$(docker-compose) exec -u ${or ${user}, root} ${or ${container}, web} /bin/sh
##? [container="{{ name }}"]	Service name, [web] by default.
##? [user="{{ name }}"]		User name, [root] by default.

.PHONY: php
php: ## Launch a PHP command.
	@$(php) php ${or ${CMD}, -v}
##? [CMD="{{ command }}"]		[-v] by default.

.PHONY: composer
composer: ## Launch composer command.
	@$(composer) ${or ${CMD}, list}
##? [CMD="{{ command }}"]		[list] by default.

.PHONY: console
console: ## Launch Symfony console command.
	@$(console) ${or ${CMD}, list}
##? [CMD="{{ command }}"]		[list] by default.

.PHONY: mailer
mailer: ## @todo Open a terminal to test mail send.
	@curl -X POST "http://`make ip container=mail -s`:8025/api/v1/send" \
     -H 'accept: application/json'\
     -H 'content-type: application/json' \
     -d '{"Attachments":[{"Content":"iVBORw0KGgoAAAANSUhEUgAAAEEAAAA8CAMAAAAOlSdoAAAACXBIWXMAAAHrAAAB6wGM2bZBAAAAS1BMVEVHcEwRfnUkZ2gAt4UsSF8At4UtSV4At4YsSV4At4YsSV8At4YsSV4At4YsSV4sSV4At4YsSV4At4YtSV4At4YsSV4At4YtSV8At4YsUWYNAAAAGHRSTlMAAwoXGiktRE5dbnd7kpOlr7zJ0d3h8PD8PCSRAAACWUlEQVR42pXT4ZaqIBSG4W9rhqQYocG+/ys9Y0Z0Br+x3j8zaxUPewFh65K+7yrIMeIY4MT3wPfEJCidKXEMnLaVkxDiELiMz4WEOAZSFghxBIypCOlKiAMgXfIqTnBgSm8CIQ6BImxEUxEckClVQiHGj4Ba4AQHikAIClwTE9KtIghAhUJwoLkmLnCiAHJLRKgIMsEtVUKbBUIwoAg2C4QgQBE6l4VCnApBgSKYLLApCnCa0+96AEMW2BQcmC+Pr3nfp7o5Exy49gIADcIqUELGfeA+bp93LmAJp8QJoEcN3C7NY3sbVANixMyI0nku20/n5/ZRf3KI2k6JEDWQtxcbdGuAqu3TAXG+/799Oyyas1B1MnMiA+XyxHp9q0PUKGPiRAau1fZbLRZV09wZcT8/gHk8QQAxXn8VgaDqcUmU6O/r28nbVwXAqca2mRNtPAF5+zoP2MeN9Fy4NgC6RfcbgE7XITBRYTtOE3U3C2DVff7pk+PkUxgAbvtnPXJaD6DxulMLwOhPS/M3MQkgg1ZFrIXnmfaZoOfpKiFgzeZD/WuKqQEGrfJYkyWf6vlG3xUgTuscnkNkQsb599q124kdpMUjCa/XARHs1gZymVtGt3wLkiFv8rUgTxitYCex5EVGec0Y9VmoDTFBSQte2TfXGXlf7hbdaUM9Sk7fisEN9qfBBTK+FZcvM9fQSdkl2vj4W2oX/bRogO3XasiNH7R0eW7fgRM834ImTg+Lg6BEnx4vz81rhr+MYPBBQg1v8GndEOrthxaCTxNAOut8WKLGZQl+MPz88Q9tAO/hVuSeqQAAAABJRU5ErkJggg==","ContentID":"mailpit-logo","ContentType":"image/png","Filename":"mailpit.png"}],"Bcc":["jack@example.com"],"Cc":[{"Email":"manager@example.com","Name":"Manager"}],"From":{"Email":"john@example.com","Name":"John Doe"},"HTML":"<div style=\"text-align:center\"><p style=\"font-family: arial; font-size: 24px;\">Mailpit is <b>awesome</b>!</p><p><img src=\"cid:mailpit-logo\" /></p></div>","Headers":{"X-IP":"1.2.3.4"},"ReplyTo":[{"Email":"secretary@example.com","Name":"Secretary"}],"Subject":"Mailpit message via the HTTP API","Tags":["Tag 1","Tag 2"],"Text":"Mailpit is awesome!","To":[{"Email":"jane@example.com","Name":"Jane Doe"}]}'

.PHONY: share
share: guard-NGROK_AUTHTOKEN ## Publicly expose app on the web with nGrok (NGROK_AUTHTOKEN required).
	@$(docker-compose) run --rm -p 4040:4040 -e NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN} ngrok http ${or ${server}, http://`make ip container=web -s`}
##? [server="{{ server }}"]	expose web service by default.

.PHONY: expose
expose: guard-EXPOSE_SHARE_TOKEN ## Publicly expose app on the web with expose.dev (EXPOSE_SHARE_TOKEN required).
	@$(docker-compose) run --rm -p 4040:4040 expose share --auth=${EXPOSE_SHARE_TOKEN} -- ${or ${server}, "http://`make ip container=web -s`"}
##? [server="{{ server }}"]	expose web service by default.

##@ NodeJS
.PHONY: node
node:  ## Launch a NodeJS command.
	@$(node) ${or ${CMD}, -h}
##? [CMD="{{ command }}"]		[-h] by default.

.PHONY: npm
npm: $(APP_DIR)/package.json $(wildcard $(APP_DIR)/package-lock.json) ## Launch a NPM command.
	@$(node) npm ${or ${CMD}, help}
##? [CMD="{{ command }}"]		[help] by default.

.PHONY: npx
npx: ## Launch a NPX command.
	@$(node) npx ${or ${CMD}, -h}
##? [CMD="{{ command }}"]		[-h] by default.

.PHONY: yarn
yarn: $(APP_DIR)/package.json $(wildcard $(APP_DIR)/package-lock.json) ## Launch a YARN command.
	@$(node) yarn ${or ${CMD}, -h}
##? [CMD="{{ command }}"]		[-h] by default.

.PHONY: pnpm
pnpm: $(APP_DIR)/package.json $(wildcard $(APP_DIR)/package-lock.json) ## Launch a PNPM command.
	@$(node) pnpm ${or ${CMD}, -h}
##? [CMD="{{ command }}"]		[-h] by default.

##@ Database
.PHONY: db-import
db-import: guard-FILE ## Import a database.
	@$(console) doctrine:database:drop --force --if-exists -q
	@$(console) doctrine:database:create --if-not-exists -q
	@echo Importing ${FILE} in database ; \
	case "${FILE}" in \
		*.sql) $(docker-compose) cp "${FILE}" db:/tmp/import.sql && $(docker-compose) exec -ti db bash -c 'pv /tmp/import.sql | psql -q -o /tmp/import-result -U "$$POSTGRES_USER" -w -d "$$POSTGRES_DB"' ;; \
		*.sql.gz) $(docker-compose) cp "${FILE}" db:/tmp/import.sql.gz && $(docker-compose) exec -ti db bash -c 'gunzip -f /tmp/import.sql.gz && pv /tmp/import.sql | psql -q -o /tmp/import-result -U "$$POSTGRES_USER" -w -d "$$POSTGRES_DB"' ;; \
	esac \
##? [FILE="{{ file_path }}"]		*required.

.PHONY: db-dump
db-dump: ## Dump the database.
	@make up container=db
	@mkdir -p $(DB_DUMP_DIR)
	@if [ "$(GZIP)" != "1" ]; then \
		$(docker-compose) exec -ti db bash -c 'pg_dump -U "$$POSTGRES_USER" -w "$$POSTGRES_DB" | pv > /tmp/dump.sql'; \
		$(docker-compose) cp db:/tmp/dump.sql${or ${FILE}, $(DB_DUMP_DIR)/dump-$(date).sql}; \
	else \
		$(docker-compose) exec -ti db bash -c 'pg_dump -U "$$POSTGRES_USER" -w "$$POSTGRES_DB" | pv | gzip > /tmp/dump.sql.gz'; \
		$(docker-compose) cp db:/tmp/dump.sql.gz ${or ${FILE}, $(DB_DUMP_DIR)/dump-$(date).sql.gz}; \
	fi
##? [GZIP=1]			Force overwriting file if it exists.
##? [FILE="{{ file_path }}"]		Destination file

.PHONY: db-dump-installer
db-dump-installer: guard-DB_DUMP_INSTALL_PATH ## Generate a secure dump database to install.
	@if [ -f "$(DB_DUMP_INSTALL_PATH)" ] && [ "$(FORCE)" != "1" ]; then \
		echo "⚠️  File $(DB_DUMP_INSTALL_PATH) already exists."; \
		read -p "Do you want to overwrite this file ? [y/N] " confirm; \
		if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
			echo "Operation canceled."; \
			exit 1; \
		fi \
	fi
	@if echo "$(DB_DUMP_INSTALL_PATH)" | grep -q '\.sql\.gz$$'; then \
		make db-dump FILE=$(DB_DUMP_INSTALL_PATH) GZIP=1; \
	else \
		make db-dump FILE=$(DB_DUMP_INSTALL_PATH); \
	fi
##? [FORCE=1]			Force overwriting file if it exists.

##@ Certificates
.PHONY: cert-init-ca
cert-init-ca: ## Initialize a self-signed CA certificate.
	@mkdir -p $(CERT_CA_DIR)
	@echo "🔐 Generating CA private key..."
	openssl genrsa -out $(CERT_CA_DIR)/$(CERT_CA_KEY) 4096

	@echo "📜 Generating self-signed root certificate..."
	openssl req -x509 -new -nodes -key $(CERT_CA_DIR)/$(CERT_CA_KEY) -sha256 -days 3650 -out $(CERT_CA_DIR)/$(CERT_CA_CRT) \
	-subj "$(CERT_CA_SUBJ)"

.PHONY: cert-sign
cert-sign: ## Create a certificate signing request (CSR) and sign it with the local CA.
	@mkdir -p $(CERT_DIR)

	@echo "🔑 Generating wildcard private key..."
	openssl genrsa -out $(CERT_DIR)/$(CERT_KEY) 2048

	@echo "📝 Creating extensions file..."
	@echo "authorityKeyIdentifier=keyid,issuer" > $(CERT_DIR)/$(CERT_EXT)
	@echo "basicConstraints=CA:FALSE" >> $(CERT_DIR)/$(CERT_EXT)
	@echo "keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment" >> $(CERT_DIR)/$(CERT_EXT)
	@echo "subjectAltName = @alt_names" >> $(CERT_DIR)/$(CERT_EXT)
	@echo "" >> $(CERT_DIR)/$(CERT_EXT)
	@echo "[alt_names]" >> $(CERT_DIR)/$(CERT_EXT)
	@echo "DNS.1 = *.$(CERT_DOMAIN)" >> $(CERT_DIR)/$(CERT_EXT)
	@echo "DNS.2 = $(CERT_DOMAIN)" >> $(CERT_DIR)/$(CERT_EXT)

	@echo "📥 Generating CSR..."
	openssl req -new -key $(CERT_DIR)/$(CERT_KEY) -out $(CERT_DIR)/$(CERT_CSR) \
	-subj "/CN=*.$(CERT_DOMAIN)"

	@echo "✅ Signing certificate with local CA..."
	openssl x509 -req -in $(CERT_DIR)/$(CERT_CSR) -CA $(CERT_CA_DIR)/$(CERT_CA_CRT) -CAkey $(CERT_CA_DIR)/$(CERT_CA_KEY) \
	-CAserial $(CERT_CA_DIR)/$(CERT_CA_SERIAL_FILE) -CAcreateserial -out $(CERT_DIR)/$(CERT_CRT) \
	-days 3650 -sha256 -extfile $(CERT_DIR)/$(CERT_EXT)

.PHONY: cert-generate-traefik-config
cert-generate-traefik-config: ## Generate a Traefik configuration file with dynamic TLS certificates.
	@echo "⚙️ Generating dynamic_conf.yml from template..."
	envsubst < $(DOCKER_DIR)/conf/traefik/dynamic_conf.yml.tmpl > $(DOCKER_DIR)/conf/traefik/dynamic_conf.yml
	@echo "✅ Traefik config generated at $(DOCKER_DIR)/conf/traefik/dynamic_conf.yml"

.PHONY: cert-import-ca
cert-import-ca: ## Import the local CA certificate into the trusted store of the operating system.
	@if [ "$$(uname)" = "Linux" ] && command -v update-ca-certificates >/dev/null; then \
		echo "📥 Importing CA certificate into Linux trusted store..."; \
		sudo cp $(CERT_CA_DIR)/$(CERT_CA_CRT) /usr/local/share/ca-certificates/${PROJECT_NAME}-ca.crt; \
		sudo update-ca-certificates; \
	elif [ "$$(uname)" = "Darwin" ] && command -v security >/dev/null; then \
		echo "📥 Importing CA certificate into MacOS System Keychain..."; \
		sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $(CERT_CA_DIR)/$(CERT_CA_CRT); \
	else \
		echo "⚠️  Skipping CA import: unsupported OS or missing required commands."; \
	fi

.PHONY: cert-clean
cert-clean: ## Clean up all certificates.
	@echo "🧹 Cleaning up all certificates..."
	rm -rf $(CERT_DIR)

.PHONY: cert-status
cert-status: ## Check certificates status.
	@echo "🔍 Checking certificates status..."
	@openssl x509 -in $(CERT_DIR)/$(CERT_CRT) -noout -dates || echo "Certificate not found."
	@openssl x509 -in $(CERT_CA_DIR)/$(CERT_CA_CRT) -noout -dates || echo "CA certificate not found."

#### Utils
guard-%:
	@#$(or ${$*}, $(error $* is not set))
