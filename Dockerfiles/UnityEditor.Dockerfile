ARG GAME_CI_UNITY_EDITOR_IMAGE=unityci/editor

FROM $GAME_CI_UNITY_EDITOR_IMAGE

# Setup Dependants
RUN apt-get update && \
        apt-get install -y \
        git \
        curl \
        gcc \
        make \
        libssl-dev \
        zlib1g-dev \
        libsqlite3-dev

# Set up Node.js environment for github actions
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
        apt-get install -y nodejs && \
        npm install -g npm@latest

# Set up the scripts
RUN git clone --depth=1 https://github.com/game-ci/unity-builder.git /gameci && \
        cp -rf /gameci/dist/platforms/ubuntu/steps /steps && \
        cp -rf /gameci/dist/default-build-script /UnityBuilderAction && \
        cp /gameci/dist/platforms/ubuntu/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]