# Determined AI Public Environments

This repository contains scripts and configurations used to build Determined environment images and deploy them to AWS. 
To configure a custom image based off an existing Determined image, clone this repository and modify the 
necessary files/scripts.


###Files
- `Dockerfile.cpu` is the main build script for CPU images
- `Dockerfile.gpu` is the main build script for GPU images
- `/scripts` contains scripts for publishing Docker images to repositories
- `/dockerfile_scripts` contains package installation and patch helper scripts for building external packages
- `Makefile` contains Docker build commands and top-level Docker image configurations 
  (e.g. tags, build arguments, registry info)
  

###Run
To build a custom image:
- Modify an existing recipe in `Makefile` or define a new command.
- Add/modify any additional scripts needed for the image build
- run `make {build_name}`

To publish an image:
- Add a `publish` target or modify an existing recipe
- Change registry info (`DOCKERHUB_REGISTRY` and `NGC_REGISTRY`) in `Makefile`
- run `make {publish-target}`
