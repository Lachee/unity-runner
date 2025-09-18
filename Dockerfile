ARG BASE_IMAGE=unityci/editor
ARG HUB_IMAGE="unityci/hub"

###########################
#         Builder         #
###########################
FROM $HUB_IMAGE AS builder
# Install editor
ARG VERSION
ARG CHANGE_SET
RUN unity-hub install --version "$VERSION" --changeset "$CHANGE_SET" | \
        tee /var/log/install-editor.log && grep 'Failed to install\|Error while installing an editor\|Completed with errors' /var/log/install-editor.log | \
        exit $(wc -l)

# Install modules for that editor
ARG MODULE="non-existent-module"
RUN for mod in $MODULE; do \
      if [ "$mod" = "base" ] ; then \
        echo "running default modules for this baseOs"; \
      else \
        unity-hub install-modules --version "$VERSION" --module "$mod" --childModules | tee /var/log/install-module-${mod}.log && \
        grep 'Missing module\|Completed with errors' /var/log/install-module-${mod}.log | exit $(wc -l); \
      fi \
    done \
	# Set execute permissions for modules
	&& chmod -R 755 /opt/unity/editors/$VERSION/Editor/Data/PlaybackEngines

RUN echo "$VERSION-$MODULE" | grep -q -vP '^(2021.2.(?![0-4](?![0-9]))|2021.[3-9]|202[2-9]|[6-9][0-9]{3}|[1-9][0-9]{4,}).*linux' \
  && exit 0 \
  || unity-hub install-modules --version "$VERSION" --module "linux-server" --childModules | \
  tee /var/log/install-module-linux-server.log && grep 'Missing module' /var/log/install-module-linux-server.log | exit $(wc -l);

RUN echo "$VERSION-$MODULE" | grep -q -vP '^(2021.2.(?![0-4](?![0-9]))|2021.[3-9]|202[2-9]|[6-9][0-9]{3}|[1-9][0-9]{4,}).*windows' \
  && exit 0 \
  || unity-hub install-modules --version "$VERSION" --module "windows-server" --childModules | \
  tee /var/log/install-module-windows-server.log && grep 'Missing module' /var/log/install-module-windows-server.log | exit $(wc -l);



###########################
#          Editor         #
###########################
FROM $BASE_IMAGE
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
RUN echo "BLENDER_FULL_VERSION: $BLENDER_FULL_VERSION" && \
        echo echo "BLENDER_SHORT_VERSION: $BLENDER_SHORT_VERSION" && \
        apt-get install -y wget && \
        wget https://download.blender.org/release/Blender$BLENDER_SHORT_VERSION/blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz && \
        tar -xf blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz && \
        rm blender-$BLENDER_FULL_VERSION-linux-x64.tar.xz
ENV PATH="$PATH:/blender-$BLENDER_FULL_VERSION-linux-x64"

# Add custom scripts
COPY scripts/build.sh /build.sh
RUN chmod +x /build.sh 

# Done
ENTRYPOINT [ "/entrypoint.sh" ]