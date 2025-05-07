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

# Ensure GAME_CI_VERSION is set, default to 3 if not
if [ -z "${GAMECI_VERSION}" ]; then
    GAMECI_VERSION=3
fi

BASE_IMAGE=unityci/editor:ubuntu-${UNITY_VERSION}-${UNITY_PLATFORM}-${GAMECI_VERSION}
TAG=ubuntu-${UNITY_VERSION}-${UNITY_PLATFORM}-runner

echo "Base Image: ${BASE_IMAGE}"
echo "Tag: ${TAG}"
echo "Image: ${IMAGE_NAME}:${TAG}"

docker build \
    --platform ${PLATFORM} \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    -t ${IMAGE_NAME}:${TAG} \
    ${DOCKER_BUILD_ARGS} \
    Dockerfiles/Runner.Dockerfile

if [ $? -ne 0 ]; then
    echo "Error: Docker build failed."
    exit 1
fi

# Export IMAGE_NAME and TAG for GitHub Actions
if [ -n "$GITHUB_ENV" ]; then
    echo "IMAGE_NAME=${IMAGE_NAME}" >> $GITHUB_ENV
    echo "TAG=${TAG}" >> $GITHUB_ENV
fi
``