.PHONY: build publish-dev publish release

VERSION := $(shell cat VERSION)
VERSION_DASHES := $(subst .,-,$(VERSION))
SHORT_GIT_HASH := $(shell git rev-parse --short HEAD)

export CPU_ENVIRONMENT_NAME := determinedai/environments:py-3.6.9-pytorch-1.4-tf-1.14-cpu
export GPU_ENVIRONMENT_NAME := determinedai/environments:cuda-10-py-3.6.9-pytorch-1.4-tf-1.14-gpu

# Timeout used by packer for AWS operations. Default is 120 (30 minutes) for
# waiting for AMI availablity. Bump to 180 attempts = 45 minutes.
export AWS_MAX_ATTEMPTS=180

build:
	docker build -f Dockerfile.cpu \
		--build-arg TENSORFLOW_PIP="tensorflow==1.14.0" \
		--build-arg TORCH_PIP="torch==1.4.0" \
		--build-arg TORCHVISION_PIP="torchvision==0.5.0" \
		--build-arg TENSORPACK_PIP="git+https://github.com/determined-ai/tensorpack.git@0cb4fe8e6e9b7de861c9a1e0d48ffff72b72138a" \
		-t $(CPU_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(CPU_ENVIRONMENT_NAME)-$(VERSION) \
		.
	docker build -f Dockerfile.gpu \
		--build-arg TENSORFLOW_PIP="tensorflow==1.14.0" \
		--build-arg TORCH_PIP="torch==1.4.0+cu100 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.5.0+cu100 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg TENSORPACK_PIP="git+https://github.com/determined-ai/tensorpack.git@0cb4fe8e6e9b7de861c9a1e0d48ffff72b72138a" \
		-t $(GPU_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(GPU_ENVIRONMENT_NAME)-$(VERSION) \
		.

publish-dev:
	docker push $(CPU_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH)
	docker push $(GPU_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH)
	cd cloud && packer build -var "image_suffix=-$(SHORT_GIT_HASH)" environments-packer.json

publish:
	docker push $(CPU_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH)
	docker push $(GPU_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH)
	docker push $(CPU_ENVIRONMENT_NAME)-$(VERSION)
	docker push $(GPU_ENVIRONMENT_NAME)-$(VERSION)
	cd cloud && packer build -var "image_suffix=-$(VERSION_DASHES)" environments-packer.json

release: PART?=patch
release:
	bumpversion --current-version $(VERSION) $(PART)
