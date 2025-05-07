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

# Ensure UNITY_PLATFORM is set, pull from arguments if not
if [ -z "${UNITY_PLATFORM}" ]; then
    if [ -n "$2" ]; then
        UNITY_PLATFORM=$2
    else
        echo "Error: UNITY_PLATFORM is not set."
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
    if [ "${GAMECI_OS}" = "windows-il2cpp" ]; then
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


BASE_IMAGE=unityci/editor:${GAMECI_OS}-${UNITY_VERSION}-${UNITY_PLATFORM}-${GAMECI_VERSION}
TAG=${GAMECI_OS}-${UNITY_VERSION}-${UNITY_PLATFORM}-runner
FULL_IMAGE=${IMAGE}:${TAG}

echo "Building Docker image ${FULL_IMAGE}"
echo "- Platfrom: ${PLATFORM}"
echo "- Base: ${BASE_IMAGE}"
echo "- Tag: ${TAG}"
echo "- Image: ${IMAGE}:${TAG}"

docker build \
    --platform ${PLATFORM} \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    -t ${FULL_IMAGE} \
    ${DOCKER_BUILD_ARGS} \
    .

if [ $? -ne 0 ]; then
    echo "Error: Docker build failed."
    exit 1
fi

# Export IMAGE and TAG for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "IMAGE=${IMAGE}" >> $GITHUB_OUTPUT
    echo "TAG=${TAG}" >> $GITHUB_OUTPUT
    echo "FULL_IMAGE=${FULL_IMAGE}" >> $GITHUB_OUTPUT
fi
