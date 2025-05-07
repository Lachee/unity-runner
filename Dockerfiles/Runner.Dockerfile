ARG BASE_IMAGE=unityci/editor

FROM $BASE_IMAGE

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

# Set up the scripts
RUN git clone --depth=1 https://github.com/game-ci/unity-builder.git /gameci && \
        cp -rf /gameci/dist/platforms/ubuntu/steps /steps && \
        cp -rf /gameci/dist/default-build-script /UnityBuilderAction && \
        cp /gameci/dist/platforms/ubuntu/entrypoint.sh /entrypoint.sh

# Set up Node.js environment for github actions
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
        apt-get install -y nodejs && \
        npm install -g npm@latest

# Install Blender
ARG BLENDER_SHORT_VERSION=3.4
ARG BLENDER_FULL_VERSION=3.4.1

RUN echo "BLENDER_SHORT_VERSION: $BLENDER_SHORT_VERSION"
RUN echo "BLENDER_FULL_VERSION: $BLENDER_FULL_VERSION"
RUN apt-get update && \
        apt-get install -y wget && \
        wget https://download.blender.org/release/Blender$BLENDER_SHORT_VERSION/blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz && \
        tar -xf blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz && \
        rm blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz

ENV PATH="$PATH:/blender-$BLENDER_FULL_VERSION-linux-x64"

# Done
ENTRYPOINT [ "/entrypoint.sh" ]