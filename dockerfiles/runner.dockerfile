ARG BASE_OS=ubuntu
ARG VERSION=2023.1.0f1
ARG EDITOR_CACHE_REGISTRY=docker.io

###########################
#         Builder         #
###########################
FROM ${EDITOR_CACHE_REGISTRY}/unityci/editor:${BASE_OS}-${VERSION}-base-3 AS editor
FROM unityci/hub AS builder

# Install editor
ARG VERSION
COPY --from=editor "$UNITY_PATH/" /opt/unity/editors/$VERSION/ 

# Install CMake

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates;
COPY --chmod=770 scripts/install-module.sh /bin/install-module

# Install modules for that editor
ARG MODULE
RUN install-module "$VERSION" "$MODULE" android
RUN install-module "$VERSION" "$MODULE" ios
RUN install-module "$VERSION" "$MODULE" appletv
RUN install-module "$VERSION" "$MODULE" linux-mono
RUN install-module "$VERSION" "$MODULE" linux-il2cpp
RUN install-module "$VERSION" "$MODULE" webgl
RUN install-module "$VERSION" "$MODULE" windows
RUN install-module "$VERSION" "$MODULE" vuforia-ar
RUN install-module "$VERSION" "$MODULE" windows-mono
RUN install-module "$VERSION" "$MODULE" lumin
RUN install-module "$VERSION" "$MODULE" mac-mono
RUN install-module "$VERSION" "$MODULE" mac-il2cpp
RUN install-module "$VERSION" "$MODULE" universal-windows-platform
RUN install-module "$VERSION" "$MODULE" uwp-il2cpp
RUN install-module "$VERSION" "$MODULE" uwp-.net
RUN install-module "$VERSION" "$MODULE" linux-server
RUN install-module "$VERSION" "$MODULE" windows-server

###########################
#          Editor         #
###########################
FROM $BASE_OS:latest

WORKDIR /tmp

ENV UNITY_PATH="/opt/unity"

# Always put "Editor" and "modules.json" directly in $UNITY_PATH
ARG VERSION
ARG MODULE
COPY --from=builder /opt/unity/editors/$VERSION/ "$UNITY_PATH/"
RUN echo $VERSION > "$UNITY_PATH/version"
LABEL com.unity3d.version="$VERSION"
LABEL com.unity3d.modules="$MODULE"

# == System Packages ==
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ca-certificates \
        curl \
        bash \
        git \
        gnupg \
        libsqlite3-dev \
        libssl-dev \
        pkg-config \
        unzip \
        wget \
        zip  \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates;

# == Runtimes, Languages, & Package Managers ==
# - Node
ARG NODE_VERSION=24
LABEL org.nodejs.version="${NODE_VERSION}"
# Node: install globally, not through nvm
ARG NODE_VERSION=24
LABEL org.nodejs.version="${NODE_VERSION}"
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && corepack enable \
 && node -v \
 && npm -v \
 && which node \
 && rm -rf /var/lib/apt/lists/*

# - Python 3
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# == SDKs ==
# - Azure
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
# - AWS
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install

# == Tools ==
# - Blender
ARG BLENDER_SHORT_VERSION=3.4
ARG BLENDER_FULL_VERSION=3.4.1
LABEL org.blender.version="${BLENDER_FULL_VERSION}"
RUN set -eux; \
    mkdir -p /opt/blender; \
    wget -O /tmp/blender.tar.xz "https://download.blender.org/release/Blender${BLENDER_SHORT_VERSION}/blender-${BLENDER_FULL_VERSION}-linux-x64.tar.xz"; \
    tar -xJf /tmp/blender.tar.xz -C /opt/blender; \
    rm /tmp/blender.tar.xz; \
    ln -sf "/opt/blender/blender-${BLENDER_FULL_VERSION}-linux-x64/blender" /usr/local/bin/blender; \
    ls -al /opt/blender
ENV PATH="/opt/blender/blender-${BLENDER_FULL_VERSION}-linux-x64:${PATH}"

# - Butler
RUN curl -L https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default -o butler.zip \
 && unzip butler.zip -d /opt/butler \
 && chmod +x /opt/butler/butler \
 && ln -s /opt/butler/butler /usr/local/bin/butler \
 && rm butler.zip

# == Scripts ==
# - GameCI
RUN git clone --depth=1 https://github.com/game-ci/unity-builder.git /gameci && \
  cp -rf /gameci/dist/platforms/ubuntu/steps /steps && \
  cp -rf /gameci/dist/default-build-script /UnityBuilderAction && \
  cp /gameci/dist/platforms/ubuntu/entrypoint.sh /entrypoint.sh
# - Build Helper
COPY --chmod=774 scripts/build.sh /build.sh

# == Cleanup ==
WORKDIR /workspace
RUN rm -rf /tmp

# Done
ENTRYPOINT []
CMD ["/bin/bash"]