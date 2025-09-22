# Unity Runners for Gitea

Gitea [Act Runner]() images with Unity3D installed and additional modules for packaging, building, and testing your Unity3D projects and games.

Built on the work done by [GameCI](https://game.ci/docs/docker/docker-images/), these images are designed to run your build scripts directly in the container.

## Why?
The [`game-ci/unity-builder`](https://game.ci/docs/github/builder) action builds your project inside a Docker container. However with the way Gitea works, this causes issues as you end up with docker-in-docker containers which are not entirely stable, have issues with caching, and annoying to manage with files.

Using this image, you are directly able to launch your runner scripts inside the same container that Unity is in. 

> [!TIP]
> You can use either the `jobs.<name>.container.image` to override the job's current container image, or you can directly add a label to your runner such as:
> ```yaml
>   - unity-6000.0.35f1-android:docker://lachee/unity-runner:6000.0.35f1-android-runner
>   - unity-6000.0.35f1-webgl:docker://lachee/unity-runner:6000.0.35f1-webgl-runner
> ```
> There is a included script that will automate your labels as a cron job.

## Images
A table of available Docker images for Unity CI/CD:

<!-- table -->
|Unity|all|android|ios|linux-il2cpp|mac-mono|webgl|windows-mono|
|-----|---|-------|---|------------|--------|-----|------------|
|6000.0.35f1|[🐳 View](https://docker.lakes.house/repo/unityci/editor/tag/ubuntu-6000.0.35f1-runner)<br>📦 15.66 GB|[🐳 View](https://docker.lakes.house/repo/unityci/editor/tag/ubuntu-6000.0.35f1-android-runner)<br>📦 12.02 GB|[🐳 View](https://docker.lakes.house/repo/unityci/editor/tag/ubuntu-6000.0.35f1-ios-runner)<br>📦 10.47 GB|[🐳 View](https://docker.lakes.house/repo/unityci/editor/tag/ubuntu-6000.0.35f1-linux-il2cpp-runner)<br>📦 10.37 GB|[🐳 View](https://docker.lakes.house/repo/unityci/editor/tag/ubuntu-6000.0.35f1-mac-mono-runner)<br>📦 10.70 GB|[🐳 View](https://docker.lakes.house/repo/unityci/editor/tag/ubuntu-6000.0.35f1-webgl-runner)<br>📦 11.60 GB|[🐳 View](https://docker.lakes.house/repo/unityci/editor/tag/ubuntu-6000.0.35f1-windows-mono-runner)<br>📦 11.07 GB|
<!-- /table -->

## Included Software
### Tools
- Unity3D (as `unity-editor`)
- Blender `3.4`
- CMake
- CURL
- GCC
- Git
- Make
- Zip & Unzip

### Language and Runtime
- Bash `5.1.16(1)-release`
- Node.js `20.19.5`
- Python3 `3.10.12`
- lib-sqlite3
- libssl

### Package Management
- NPM `11.6.0`
- PNPM `10.17.0`
- pip3 `22.0.2`


### SDKs
- AWS CLI
- Azure SDK

## How
...
TODO
...