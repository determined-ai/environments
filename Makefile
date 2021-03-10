VERSION := $(shell cat VERSION)
VERSION_DASHES := $(subst .,-,$(VERSION))
SHORT_GIT_HASH := $(shell git rev-parse --short HEAD)

NGC_REGISTRY := nvcr.io/isv-ngc-partner/determined
export DOCKERHUB_REGISTRY := determinedai

CPU_PREFIX := environments:py-3.6.9-
CPU_SUFFIX := -cpu
CUDA_101_PREFIX := environments:cuda-10.1-
CUDA_110_PREFIX := environments:cuda-11.0-
GPU_SUFFIX := -gpu
ARTIFACTS_DIR := /tmp/artifacts

export CPU_TF1_ENVIRONMENT_NAME := $(CPU_PREFIX)pytorch-1.7-tf-1.15$(CPU_SUFFIX)
export GPU_TF1_ENVIRONMENT_NAME := $(CUDA_101_PREFIX)pytorch-1.7-tf-1.15$(GPU_SUFFIX)
export CPU_TF2_ENVIRONMENT_NAME := $(CPU_PREFIX)pytorch-1.7-lightning-1.2-tf-2.4$(CPU_SUFFIX)
export GPU_TF2_ENVIRONMENT_NAME := $(CUDA_101_PREFIX)pytorch-1.7-lightning-1.2-tf-2.4$(GPU_SUFFIX)

export CUDA_11_NVIDIA_TF_ENVIRONMENT_NAME := $(CUDA_110_PREFIX)pytorch-1.7-tf-1.15$(GPU_SUFFIX)
export CUDA_11_ENVIRONMENT_NAME := $(CUDA_110_PREFIX)pytorch-1.7-lightning-1.2-tf-2.4$(GPU_SUFFIX)

# Timeout used by packer for AWS operations. Default is 120 (30 minutes) for
# waiting for AMI availablity. Bump to 360 attempts = 90 minutes.
export AWS_MAX_ATTEMPTS=360

.PHONY: build-tf1-cpu
build-tf1-cpu:
	docker build -f Dockerfile.cpu \
		--build-arg TENSORFLOW_PIP="tensorflow==1.15.5" \
		--build-arg TORCH_PIP="torch==1.7.1" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf2-cpu
build-tf2-cpu:
	docker build -f Dockerfile.cpu \
		--build-arg TENSORFLOW_PIP="tensorflow==2.4.1" \
		--build-arg TORCH_PIP="torch==1.7.1" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.2.0" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf1-gpu
build-tf1-gpu:
	docker build -f Dockerfile.gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04" \
		--build-arg TENSORFLOW_PIP="tensorflow-gpu==1.15.5" \
		--build-arg TORCH_PIP="torch==1.7.1+cu101 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2+cu101 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@37cdaf4ad57ab4e7dd9ef13dbed7b29aa939d061" \
		--build-arg HOROVOD_WITH_TENSORFLOW="1" \
		--build-arg HOROVOD_WITH_PYTORCH="1" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf2-gpu
build-tf2-gpu:
	docker build -f Dockerfile.gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.4.1" \
		--build-arg TORCH_PIP="torch==1.7.1+cu101 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.2.0" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2+cu101 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@37cdaf4ad57ab4e7dd9ef13dbed7b29aa939d061" \
		--build-arg HOROVOD_WITH_TENSORFLOW="1" \
		--build-arg HOROVOD_WITH_PYTORCH="1" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-cuda-11
build-cuda-11:
	docker build -f Dockerfile.gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:11.0-cudnn8-devel-ubuntu18.04" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.4.1" \
		--build-arg TORCH_PIP="torch==1.7.1+cu110 -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.2.0" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2+cu110  -f https://download.pytorch.org/whl/torch_stable.html" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/NVIDIA/apex.git@154c6336aa7aedd40d3b3583fb5e1328f9cdf387" \
		--build-arg HOROVOD_WITH_TENSORFLOW="1" \
		--build-arg HOROVOD_WITH_PYTORCH="1" \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: publish-tf1-cpu
publish-tf1-cpu:
	scripts/publish-docker.sh tf1-cpu $(DOCKERHUB_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf1-cpu $(NGC_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)

.PHONY: publish-tf2-cpu
publish-tf2-cpu:
	scripts/publish-docker.sh tf2-cpu $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf2-cpu $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)

.PHONY: publish-tf1-gpu
publish-tf1-gpu:
	scripts/publish-docker.sh tf1-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf1-gpu $(NGC_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)

.PHONY: publish-tf2-gpu
publish-tf2-gpu:
	scripts/publish-docker.sh tf2-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf2-gpu $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)

.PHONY: publish-cuda-11
publish-cuda-11:
	scripts/publish-docker.sh cuda-11 $(DOCKERHUB_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh cuda-11 $(NGC_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)

.PHONY: publish-cloud-images
publish-cloud-images:
	mkdir -p $(ARTIFACTS_DIR)
	cd cloud \
		&& packer build -machine-readable -var "image_suffix=-$(SHORT_GIT_HASH)" environments-packer.json \
		| tee $(ARTIFACTS_DIR)/packer-log
