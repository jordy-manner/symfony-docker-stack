FROM node:lts

# Arguments defined in compose.yml
ARG USER_UID
ARG USER_NAME

## Create system user to run PHP
RUN useradd ${USER_NAME} --uid ${USER_UID} -m || useradd ${USER_NAME} -m

# System dependencies
RUN touch /.yarnrc && chmod 777 /.yarnrc
RUN mkdir /.npm && chown ${USER_NAME} /.npm

# Use local user
USER ${USER_UID}

# Set working directory
WORKDIR /usr/src/app