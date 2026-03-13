export UNITY_VERSION=6000.0.68f1
export UNITY_PLATFORM="$1"
export GAMECI_OS="ubuntu"
export GAMECI_VERSION=3
export GAMECI_IMAGE="unityci/editor"

docker buildx build \
    --build-arg "UNITY_VERSION=${UNITY_VERSION}" \
    --build-arg "UNITY_PLATFORM=${UNITY_PLATFORM}" \
    --build-arg "GAMECI_OS=${GAMECI_OS}" \
    --build-arg "GAMECI_VERSION=${GAMECI_VERSION}" \
    --build-arg "GAMECI_IMAGE=${GAMECI_IMAGE}" \
    -t lachee/unity-runner:${GAMECI_OS}-${UNITY_VERSION}-${UNITY_PLATFORM}-runner \
    -f dockerfiles/runner.dockerfile .