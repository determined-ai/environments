.PHONY: build publish-dev publish release

VERSION := $(shell cat VERSION)
VERSION_DASHES := $(subst .,-,$(VERSION))
SHORT_GIT_HASH := $(shell git rev-parse --short HEAD)

CPU_PREFIX := determinedai/environments:py-3.6.9-
CPU_SUFFIX := -cpu
CUDA_100_PREFIX := determinedai/environments:cuda-10.0-
CUDA_101_PREFIX := determinedai/environments:cuda-10.1-
GPU_SUFFIX := -gpu

export CPU_TF1_ENVIRONMENT_NAME := $(CPU_PREFIX)pytorch-1.4-tf-1.14$(CPU_SUFFIX)
export GPU_TF1_ENVIRONMENT_NAME := $(CUDA_100_PREFIX)pytorch-1.4-tf-1.14$(GPU_SUFFIX)
export CPU_TF2_ENVIRONMENT_NAME := $(CPU_PREFIX)pytorch-1.4-tf-2.1$(CPU_SUFFIX)
export GPU_TF2_ENVIRONMENT_NAME := $(CUDA_101_PREFIX)pytorch-1.4-tf-2.1$(GPU_SUFFIX)

# Timeout used by packer for AWS operations. Default is 120 (30 minutes) for
# waiting for AMI availablity. Bump to 240 attempts = 60 minutes.
export AWS_MAX_ATTEMPTS=240

build:
	docker build -f Dockerfile.cpu \
		--build-arg TENSORFLOW_PIP="tensorflow==1.14.0" \
		--build-arg TORCH_PIP="torch==1.4.0" \
		--build-arg TORCHVISION_PIP="torchvision==0.5.0" \
		--build-arg TENSORPACK_PIP="git+https://github.com/determined-ai/tensorpack.git@0cb4fe8e6e9b7de861c9a1e0d48ffff72b72138a" \
		-t $(CPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(CPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		.
	docker build -f Dockerfile.cpu \
		--build-arg TENSORFLOW_PIP="tensorflow==2.1.0" \
		--build-arg TORCH_PIP="torch==1.4.0" \
		--build-arg TORCHVISION_PIP="torchvision==0.5.0" \
		-t $(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		.
	docker build -f Dockerfile.gpu \
		--build-arg CUDA="10.0" \
		--build-arg TENSORFLOW_PIP="tensorflow-gpu==1.14.0" \
		--build-arg TORCH_PIP="torch==1.4.0+cu100 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.5.0+cu100 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg TENSORPACK_PIP="git+https://github.com/determined-ai/tensorpack.git@0cb4fe8e6e9b7de861c9a1e0d48ffff72b72138a" \
		--build-arg HOROVOD_WITH_TENSORFLOW="1" \
		--build-arg HOROVOD_WITH_PYTORCH="1" \
		-t $(GPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(GPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		.
	docker build -f Dockerfile.gpu \
		--build-arg CUDA="10.1" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.1.0" \
		--build-arg TORCH_PIP="torch==1.4.0" \
		--build-arg TORCHVISION_PIP="torchvision==0.5.0" \
		--build-arg HOROVOD_WITH_TENSORFLOW="1" \
		--build-arg HOROVOD_WITH_PYTORCH="1" \
		-t $(GPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(GPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		.

publish:
	docker push $(CPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH)
	docker push $(GPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH)
	docker push $(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH)
	docker push $(GPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH)
	docker push $(CPU_TF1_ENVIRONMENT_NAME)-$(VERSION)
	docker push $(GPU_TF1_ENVIRONMENT_NAME)-$(VERSION)
	docker push $(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION)
	docker push $(GPU_TF2_ENVIRONMENT_NAME)-$(VERSION)
	cd cloud && packer build -var "image_suffix=-$(SHORT_GIT_HASH)" environments-packer.json

release: PART?=minor
release:
	bumpversion --current-version $(VERSION) $(PART)
