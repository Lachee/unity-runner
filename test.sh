UNITY_VERSION=6000.0.35f1 \
UNITY_MODULES="webgl linux-server windows-mono mac-mono linux-il2cpp" \
IMAGE=docker.lakes.house/unityci/editor \
    ./.gitea/workflows/scripts/build-runner-image.sh