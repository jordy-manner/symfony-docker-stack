# Symfony Docker Stack

This stack allows you to run a Symfony application in a Docker container.

## Features

- Web application container (Apache + PHP).
- Database container (PostgreSQL ready or MariaDB).
- Database manager container (Adminer).
- Reverse proxy container (Traefik).
- Mailcatcher container (Mailpit).
- Publicly exposition of web local (Ngrok).
- A complete [Makefile](/Makefile) for easy setup and run commands.

## Quick start

```shell
make init
```

if you run another instance before a first `init` you should run:

```shell
make reinit
```

> Be careful `reinit` action will delete database and theme files.

## Configuration

### Print configuration variable list

```shell
make config
```

### Print one configuration variable

```shell
make config-get KEY=NAME_OF_VARIABLE
```

### Available configuration variables

#### PROJECT_NAME

Name of the project.

#### PROJECT_DIR

Root directory of the project.

#### APP_DIR

Root directory of the web application.

#### SERVE_BASE_HOST

Local domain used for the reverse proxy.

#### SERVE_WEB_PROXY

Hostname of the application website (Wordpress).

#### SERVE_DBMGR_PROXY

Hostname of the database manager webUI (Adminer).

#### SERVE_MAILCATCH_PROXY

Hostname of the mail server webUI (Mailpit).

#### SERVE_REVERSE_PROXY

Hostname of the reverse proxy webUI (Traefik).

#### LOCAL_UID

User ID of the host user.

#### LOCAL_USERNAME

Username of the host user.

#### LOCAL_GID

Group ID of the host user.

#### LOCAL_HOME

Home directory of the host user.

#### LOCAL_DOCKER_IP

IP address of the Docker host.

#### APP_RELEASE

Release version of application

#### DB_ENGINE

Database engine.

#### DB_HOST

Database host.

#### DB_PORT

Database port.

#### DB_CHARSET

Database charset.

#### DB_SERVER_VERSION

Database server version.

#### DB_ROOT_PASSWORD

Database root password.

#### DB_NAME

Database name.

#### DB_USER

Database user.

#### DB_PASSWORD

Database password.

#### DB_DUMP_DIR

Database dump directory.

#### DB_DUMP_INSTALL_PATH

Path to save secure dump.

#### NPM_DEV_APP_URL

Used `APP_URL` when you run `npm run dev` command

#### NGROK_AUTHTOKEN

Authtoken to publicly expose the web local with [ngrok](https://ngrok.com/).

#### EXPOSE_SHARE_TOKEN

Share token to publicly expose the web local with [expose](https://expose.dev/)

### Customize configuration

#### Easy way

```shell
make config-set KEY=NAME_OF_VARIABLE VAL=VALUE_OF_VARIABLE
```

> This command create the set of variables in a `.config.env.local` file.

Usually `.config.env.local` was not pushed in repository (.gitignore).

You can use `global` scope to push custom configuration in repository.

```shell
make config-set KEY=NAME_OF_VARIABLE VAL=VALUE_OF_VARIABLE SCOPE=global
```

Another way is to scoping to DOCKER_ENV.

```shell
make config-set KEY=NAME_OF_VARIABLE VAL=VALUE_OF_VARIABLE SCOPE=staging
```

> This command create the set of variables in a `.config.env.staging` file.

#### Advanced way

Copy `./docker/conf/.config.sample.env` to `./.config.env` and customize it with your own set of values.