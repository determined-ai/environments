# Determined AI Public Environments

This repository contains scripts and configurations used to build Determined environment images and deploy them to AWS. 
To configure a custom image based off an existing Determined image, clone this repository and modify the 
necessary files/scripts.


### Files
- `Dockerfile.cpu` is the main build script for CPU images
- `Dockerfile.gpu` is the main build script for GPU images
- `/scripts` contains scripts for publishing Docker images to repositories
- `/dockerfile_scripts` contains package installation and patch helper scripts for building external packages
- `Makefile` contains Docker build commands and top-level Docker image configurations 
  (e.g. tags, build arguments, registry info)
  

### Run
To build a custom image:
- Modify an existing recipe in `Makefile` or define a new command.
- Add/modify any additional scripts needed for the image build
- run `make {build_name}`

To publish an image:
- Add a `publish` target or modify an existing recipe
- Change registry info (`DOCKERHUB_REGISTRY` and `NGC_REGISTRY`) in `Makefile` or specify make args
- run `make {publish-target} DOCKERHUB_REGISTRY={registry}`

### Multi-platform images
We use [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/) to create multi-platform CPU images. Although `docker buildx` is more powerful than the ordinary
`docker build`, it has a limitation: to build a multi-platform image you have to use
`docker-container` driver that does not allow to export an image so that appears in
`docker images` (see https://docs.docker.com/engine/reference/commandline/buildx_build/#output). You can only push an image directly to a registry (using `--push` option).
As a consequence, if you want to test dockerfile changes locally for one of the
multi-platform images (currently, Base CPU, TF 2.7 CPU, and TF 2.8 CPU), without pushing
to a docker registry, you have to modify `Makefile` or craft your own build command to build a single-platform image.

For example, to build the base image for `linux/arm64` (to use on a Mac with M1 processor):
```
# the default builder uses docker driver
# confirm this with
docker buildx ls

docker buildx build -f Dockerfile-default-cpu \
  --platform linux/arm64 \
 	--build-arg BASE_IMAGE="ubuntu:18.04" \
	--build-arg PYTHON_VERSION="$(PYTHON_VERSION)" \
	-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(SHORT_GIT_HASH) \
	-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(VERSION) \
   -o type=image,push=false \
  .
```
