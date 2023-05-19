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

To publish an image manually:
- Add a `publish` target or modify an existing recipe
- Change registry info (`DOCKERHUB_REGISTRY` and `NGC_REGISTRY`) in `Makefile` or specify make args
- run `make {publish-target} DOCKERHUB_REGISTRY={registry}`

### Complete development workflow for updates to environment images
This repository is tightly coupled with [the determined repository](https://github.com/determined-ai/determined). Changes to environment images may (and should be assumed to) affect the behavior of the MLDE. When making significant changes to the images, such as updating a deep learning framework library to a more recent version, make sure Determined can still run experiments using the new image.

#### Steps to introduce an updated environment image
1. Create a PR against this repo.
2. Open CI workflow and approve `request-publish-dev-docker`. Make sure all the downstream jobs succeed. Approve `request-publish-dev-cloud`. Wait for it to succeed as well. The images are now published to [the development dockerhub](https://hub.docker.com/r/determinedai/environments-dev).
3. Review the REAMDE.md in https://github.com/determined-ai/determined/tree/main/tools/scripts . It describes the bumpenvs procedure. You are going to run a test "drill" of this procedure with the development images just created.
4. Create a branch in your local clone of determined github repo. From `tools/scripts` directory run 
```bash
./update-bumpenvs-yaml.py --dev bumpenvs.yaml THECOMMIT
```
where THECOMMIT is _the full commit hash of the commit to your branch in environments repo_. (This corresponds to steps 3 and 4 from the `tools/scripts` README.)
5. Run `./bumpenvs.py bumpenvs.yaml`. (This corresponds to step 6 in the `tools/scripts` README.)
6. Push your branch _to the main determined-ai remote_. This is an important detail! Image updates, in particular ones containing version changes to DL frameworks may break functionality in Determined. In order to run the extended
test suite, including long-running tests, you need to push to the upstream repo and not to your fork!
7. Approve the `request-` jobs in `test-e2e-longrunning` CI workflow. Monitor the workflow to confirm nothing is broken. If some of the end-to-end tests (or unit or integration tests), investigate!
8. Note: not all images are currently tested with end-to-end tests in the determined repo. This is a flaw in the current system. It is prudent to run a workload with the new version of every image specified in a startup hook to confirm that the image works. We are planning to address this.
9. After you confirmed that Determined works nicely with the new images, you can merge your PR to environments and follow the steps from [toos/scripts/README.md](https://github.com/determined-ai/determined/tree/main/tools/scripts/README.md) with the images published to the official dockerhub.
10. Again, it is recommended to push your bumpenvs branch to the main determined-ai remote (and not to your fork). Open your PR from there to confirm again that all the long-running tests pass.

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
