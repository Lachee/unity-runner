#!/bin/sh
# Ensure UNITY_VERSION is set, pull from arguments if not
if [ -z "${UNITY_VERSION}" ]; then
    if [ -n "$1" ]; then
        UNITY_VERSION=$1
    else
        echo "Error: UNITY_VERSION is not set."
        exit 1
    fi
fi

# Fetch the changelog and extract the changeset ID for the specified Unity version
# This is because hub doesnt remember every version of unity and uses the changset for the exact id lookup.
if [ -z "${UNITY_CHANGESET}" ]; then
    echo "Warning: No changeset provided. Scraping one from the change logs."
    echo "This might take a while. Use the UNITY_CHANGESET to avoid this lookup."
    CHANGELOG_URL="https://unity.com/releases/editor/whats-new/${UNITY_VERSION}"
    UNITY_CHANGESET=$(curl -s -r 0-500 "$CHANGELOG_URL" | grep -oP 'unityhub://(?:[0-9a-z.])+/\K([a-z0-9]+)' | head -n 1)
    if [ -z "$UNITY_CHANGESET" ]; then
        echo "Error: Could not extract changeset for Unity version ${UNITY_VERSION}."
        exit 1
    fi
fi

# Ensure we have some modules
if [ -z "${UNITY_MODULES}" ]; then
    if [ -n "$3" ]; then
        UNITY_MODULES=$3
    else
        echo "Error: UNITY_MODULES is not set."
        exit 1
    fi
fi

# Ensure IMAGE is set, pull from arguments if not
if [ -z "${IMAGE}" ]; then
    if [ -n "$3" ]; then
        IMAGE=$3
    else
        echo "Error: IMAGE is not set."
        exit 1
    fi
fi

# Ensure GAME_CI_VERSION is set, default to 3 if not
if [ -z "${GAMECI_VERSION}" ]; then
    GAMECI_VERSION=3
fi

# Ensure IMAGE_OS is set, default to ubuntu if not
if [ -z "${GAMECI_OS}" ]; then

    # windows-il2cpp requires windows OS
    if [ "${UNITY_PLATFORM}" = "windows-il2cpp" ]; then
        GAMECI_OS="windows"
    else
        GAMECI_OS="ubuntu"
    fi

    # TODO: MacOS probably requires a mac image. 
    # Might be worth just putting this in the strategy at this point
fi

# Ensure PLATFORM is set, default to the current system if not
if [ -z "${PLATFORM}" ]; then
    PLATFORM=$(uname -m)
    case "${PLATFORM}" in
        x86_64) PLATFORM="linux/amd64" ;;
        arm64) PLATFORM="linux/arm64" ;;
        *) 
            echo "Error: Unsupported platform ${PLATFORM}."
            exit 1
            ;;
    esac
fi

# Ensure some additional build settings are set
if [ -z "${DOCKER_BUILD_ARGS}" ]; then
    DOCKER_BUILD_ARGS=""
fi

BASE_TAG=${GAMECI_OS}-${UNITY_VERSION}-base-${GAMECI_VERSION}
BASE_IMAGE=unityci/editor:${BASE_TAG}
DEST_TAG=${GAMECI_OS}-${UNITY_VERSION}-runner
DEST_IMAGE=${IMAGE}:${DEST_TAG}

echo "Building Docker image ${DEST_IMAGE}"
echo "- Version: ${UNITY_VERSION}"
echo "- Changeset: ${UNITY_CHANGESET}"
echo "- Platfrom: ${PLATFORM}"
echo "- Base: ${BASE_IMAGE}"
echo "- Tag: ${DEST_TAG}"
echo "- Image: ${DEST_IMAGE}"

docker build \
    --platform ${PLATFORM} \
    --build-arg "VERSION=${UNITY_VERSION}" \
    --build-arg "CHANGESET=${UNITY_CHANGESET}" \
    --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
    --build-arg "MODULE=${UNITY_MODULES}" \
    -t ${DEST_IMAGE} ${DOCKER_BUILD_ARGS} dockerfiles/runner.dockerfile

if [ $? -ne 0 ]; then
    echo "Error: Docker build failed."
    exit 1
fi

# Export IMAGE and TAG for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "IMAGE=${IMAGE}" >> $GITHUB_OUTPUT
    echo "TAG=$DEST_TAG" >> $GITHUB_OUTPUT
    echo "FULL_IMAGE=${DEST_IMAGE}" >> $GITHUB_OUTPUT
fi
