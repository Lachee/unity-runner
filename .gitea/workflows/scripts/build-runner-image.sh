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
CHANGELOG_URL="https://public-cdn.cloud.unity3d.com/hub/prod/releases-${UNITY_VERSION}.json"
CHANGESET_ID=$(curl -s "$CHANGELOG_URL" | grep -o '"changeset":[^,]*' | head -n 1 | cut -d':' -f2 | tr -d ' "')

if [ -z "$CHANGESET_ID" ]; then
    echo "Warning: Could not retrieve changeset ID for Unity version ${UNITY_VERSION}."
else
    echo "Unity ${UNITY_VERSION} changeset ID: ${CHANGESET_ID}"
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
echo "- Platfrom: ${PLATFORM}"
echo "- Base: ${BASE_IMAGE}"
echo "- Tag: ${DEST_TAG}"
echo "- Image: ${DEST_IMAGE}"

docker build \
    --platform ${PLATFORM} \
    --build-arg "VERSION=${UNITY_VERSION}" \
    --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
    --build-arg "MODULE=${UNITY_MODULES}" \
    -t ${DEST_IMAGE} \
    ${DOCKER_BUILD_ARGS} \
    .

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
