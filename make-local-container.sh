UNITY_VERSION=6000.0.35f1 \
UNITY_MODULES="$@" \
IMAGE=docker.lakes.house/unityci/editor \
.gitea/workflows/scripts/build-runner-image.sh