ARG BASE_IMAGE=unityci/editor
ARG HUB_IMAGE="unityci/hub"

###########################
#         Builder         #
###########################
FROM $BASE_IMAGE AS editor
FROM $HUB_IMAGE AS builder

# Install editor
ARG VERSION
COPY --from=editor "$UNITY_PATH/" /opt/unity/editors/$VERSION/ 

# Install CMake
RUN apt-get update && apt-get install -y cmake
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
FROM $BASE_IMAGE

# Always put "Editor" and "modules.json" directly in $UNITY_PATH
ARG VERSION
ARG MODULE
COPY --from=builder /opt/unity/editors/$VERSION/ "$UNITY_PATH/"
RUN echo $VERSION > "$UNITY_PATH/version"

# Tools
RUN apt-get update && \
  apt-get install -y \
  build-essential \
  cmake \
  curl \
  gcc \
  git \
  libsqlite3-dev \
  libssl-dev \
  make \
  pkg-config \
  zlib1g-dev \
  zip unzip

ARG BLENDER_SHORT_VERSION=3.4
ARG BLENDER_FULL_VERSION=3.4.1
RUN echo "BLENDER_FULL_VERSION: $BLENDER_FULL_VERSION" && \
  echo echo "BLENDER_SHORT_VERSION: $BLENDER_SHORT_VERSION" && \
  apt-get install -y wget && \
  wget https://download.blender.org/release/Blender$BLENDER_SHORT_VERSION/blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz && \
  tar -xf blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz && \
  rm blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz
ENV PATH="$PATH:/blender-$BLENDER_FULL_VERSION-linux-x64"

# Runtimes, Languages, & Package Managers
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
  apt-get install -y nodejs && npm install -g npm@latest
RUN curl -fsSL https://get.pnpm.io/install.sh | bash -
RUN apt-get install -y python3 python3-pip


# SDKs
RUN cd /tmp && curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN cd /tmp && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install


# Scripts
RUN git clone --depth=1 https://github.com/game-ci/unity-builder.git /gameci && \
  cp -rf /gameci/dist/platforms/ubuntu/steps /steps && \
  cp -rf /gameci/dist/default-build-script /UnityBuilderAction && \
  cp /gameci/dist/platforms/ubuntu/entrypoint.sh /entrypoint.sh

COPY scripts/build.sh /build.sh
RUN chmod +x /build.sh 

LABEL com.unity3d.version="$VERSION"
LABEL com.unity3d.modules="$MODULE"
LABEL org.blender.version="$BLENDER_FULL_VERSION"

# Done
# ENTRYPOINT [ "/entrypoint.sh" ]
ENTRYPOINT [ "/bin/bash" ]