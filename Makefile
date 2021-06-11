VERSION := $(shell cat VERSION)
VERSION_DASHES := $(subst .,-,$(VERSION))
SHORT_GIT_HASH := $(shell git rev-parse --short HEAD)

NGC_REGISTRY := nvcr.io/isv-ngc-partner/determined
export DOCKERHUB_REGISTRY := determinedai

CPU_PREFIX := environments:py-3.7-
CPU_SUFFIX := -cpu
CUDA_102_PREFIX := environments:cuda-10.2-
CUDA_110_PREFIX := environments:cuda-11.0-
CUDA_112_PREFIX := environments:cuda-11.2-
GPU_SUFFIX := -gpu
ARTIFACTS_DIR := /tmp/artifacts

export CPU_TF1_ENVIRONMENT_NAME := $(CPU_PREFIX)pytorch-1.7-tf-1.15$(CPU_SUFFIX)
export GPU_TF1_ENVIRONMENT_NAME := $(CUDA_102_PREFIX)pytorch-1.7-tf-1.15$(GPU_SUFFIX)
export CPU_TF2_ENVIRONMENT_NAME := $(CPU_PREFIX)pytorch-1.7-lightning-1.2-tf-2.4$(CPU_SUFFIX)
export CUDA_10_ENVIRONMENT_NAME := $(CUDA_102_PREFIX)pytorch-1.8-lightning-1.2-tf-2.4$(GPU_SUFFIX)
export CUDA_11_ENVIRONMENT_NAME := $(CUDA_110_PREFIX)pytorch-1.7-lightning-1.2-tf-2.4$(GPU_SUFFIX)
export GPU_TF25_ENVIRONMENT_NAME := $(CUDA_112_PREFIX)pytorch-1.7-lightning-1.2-tf-2.5$(GPU_SUFFIX)

# Timeout used by packer for AWS operations. Default is 120 (30 minutes) for
# waiting for AMI availablity. Bump to 360 attempts = 90 minutes.
export AWS_MAX_ATTEMPTS=360

.PHONY: build-tf1-cpu
build-tf1-cpu:
	docker build -f Dockerfile.cpu \
		--build-arg PYTHON_VERSION="3.7.10" \
		--build-arg TENSORFLOW_PIP="tensorflow==1.15.5" \
		--build-arg TORCH_PIP="torch==1.7.1 -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2 -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg HOROVOD_PIP="horovod==0.22.0" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf2-cpu
build-tf2-cpu:
	docker build -f Dockerfile.cpu \
		--build-arg PYTHON_VERSION="3.7.10" \
		--build-arg TENSORFLOW_PIP="tensorflow-cpu==2.4.1" \
		--build-arg TORCH_PIP="torch==1.8.1 -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.9.1 -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.2.0" \
		--build-arg HOROVOD_PIP="horovod==0.22.0" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf1-gpu
build-tf1-gpu:
	docker build -f Dockerfile.gpu \
		--build-arg PYTHON_VERSION="3.7.10" \
		--build-arg BASE_IMAGE="nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04" \
		--build-arg TENSORFLOW_PIP="https://github.com/determined-ai/tensorflow-wheels/releases/download/0.1.0/tensorflow_gpu-1.15.5-cp37-cp37m-linux_x86_64.whl" \
		--build-arg TORCH_PIP="torch==1.7.1 -f https://download.pytorch.org/whl/cu102/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2 -f https://download.pytorch.org/whl/cu102/torch_stable.html" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5" \
		--build-arg APEX_GIT="https://github.com/NVIDIA/apex.git@b5eb38dbf7accc24bd872b3ab67ffc77ee858e62" \
		--build-arg HOROVOD_PIP="horovod==0.22.0" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		.


.PHONY: build-cuda-10
build-cuda-10:
	docker build -f Dockerfile.gpu \
		--build-arg PYTHON_VERSION="3.7.10" \
		--build-arg BASE_IMAGE="nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.4.1" \
		--build-arg TORCH_PIP="torch==1.8.1 -f https://download.pytorch.org/whl/cu102/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.9.1 -f https://download.pytorch.org/whl/cu102/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.2.0" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5" \
		--build-arg APEX_GIT="https://github.com/NVIDIA/apex.git@b5eb38dbf7accc24bd872b3ab67ffc77ee858e62" \
		--build-arg HOROVOD_PIP="horovod==0.22.0" \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_10_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_10_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CUDA_10_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CUDA_10_ENVIRONMENT_NAME)-$(VERSION) \
		.


.PHONY: build-cuda-11
build-cuda-11:
	docker build -f Dockerfile.gpu \
		--build-arg PYTHON_VERSION="3.7.10" \
		--build-arg BASE_IMAGE="nvidia/cuda:11.0.3-cudnn8-devel-ubuntu18.04" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.4.1" \
		--build-arg TORCH_PIP="torch==1.7.1 -f https://download.pytorch.org/whl/cu110/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2 -f https://download.pytorch.org/whl/cu110/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.2.0" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/NVIDIA/apex.git@b5eb38dbf7accc24bd872b3ab67ffc77ee858e62" \
		--build-arg HOROVOD_PIP="horovod==0.22.0" \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf25-gpu
build-tf25-gpu:
	docker build -f Dockerfile.gpu \
		--build-arg PYTHON_VERSION="3.7.10" \
		--build-arg BASE_IMAGE="nvidia/cuda:11.2.2-cudnn8-devel-ubuntu18.04" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.5.0" \
		--build-arg TORCH_PIP="torch==1.7.1 -f https://download.pytorch.org/whl/cu110/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2 -f https://download.pytorch.org/whl/cu110/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.2.0" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_PATCH="1" \
		--build-arg APEX_GIT="https://github.com/NVIDIA/apex.git@b5eb38dbf7accc24bd872b3ab67ffc77ee858e62" \
		--build-arg HOROVOD_PIP="horovod==0.22.0" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME)-$(VERSION) \
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

.PHONY: publish-cuda-11
publish-cuda-11:
	scripts/publish-docker.sh cuda-11 $(DOCKERHUB_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh cuda-11 $(NGC_REGISTRY)/$(CUDA_11_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)

.PHONY: publish-tf25-gpu
publish-tf25-gpu:
	scripts/publish-docker.sh tf25-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf25-gpu $(NGC_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)

.PHONY: publish-cloud-images
publish-cloud-images:
	mkdir -p $(ARTIFACTS_DIR)
	cd cloud \
		&& packer build -machine-readable -var "image_suffix=-$(SHORT_GIT_HASH)" environments-packer.json \
		| tee $(ARTIFACTS_DIR)/packer-log
