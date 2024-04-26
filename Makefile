SHELL := /bin/bash -o pipefail
VERSION := $(shell cat VERSION)
VERSION_DASHES := $(subst .,-,$(VERSION))
SHORT_GIT_HASH := $(shell git rev-parse --short HEAD)

NGC_REGISTRY := nvcr.io/isv-ngc-partner/determined
NGC_PUBLISH := 1
export DOCKERHUB_REGISTRY := determinedai
export REGISTRY_REPO := environments

CPU_PREFIX_39 := $(REGISTRY_REPO):py-3.9-
CPU_PREFIX_310 := $(REGISTRY_REPO):py-3.10-
CUDA_113_PREFIX := $(REGISTRY_REPO):cuda-11.3-
CUDA_118_PREFIX := $(REGISTRY_REPO):cuda-11.8-
ROCM_56_PREFIX := $(REGISTRY_REPO):rocm-5.6-

CPU_SUFFIX := -cpu
CUDA_SUFFIX := -cuda
ARTIFACTS_DIR := /tmp/artifacts
PYTHON_VERSION_39 := 3.9.16
PYTHON_VERSION_310 := 3.10.12
UBUNTU_VERSION := ubuntu20.04
UBUNTU_IMAGE_TAG := ubuntu:20.04
UBUNTU_VERSION_1804 := ubuntu18.04
PLATFORM_LINUX_ARM_64 := linux/arm64
PLATFORM_LINUX_AMD_64 := linux/amd64
HOROVOD_GPU_OPERATIONS := NCCL

ifeq "$(WITH_MPI)" "1"
# 	Don't bother supporting or building arm64+mpi builds.
	HPC_SUFFIX := -hpc
	PLATFORMS := $(PLATFORM_LINUX_AMD_64)
	HOROVOD_WITH_MPI := 1
	HOROVOD_WITHOUT_MPI := 0
	HOROVOD_CPU_OPERATIONS := MPI
	CUDA_SUFFIX := -cuda
	WITH_AWS_TRACE := 0
	NCCL_BUILD_ARG := WITH_NCCL
        ifeq "$(WITH_NCCL)" "1"
		NCCL_BUILD_ARG := WITH_NCCL=1
		ifeq "$(WITH_AWS_TRACE)" "1"
			WITH_AWS_TRACE := 1
		endif
        endif
	MPI_BUILD_ARG := WITH_MPI=1

	ifeq "$(WITH_OFI)" "1"
	        CUDA_SUFFIX := -cuda
		CPU_SUFFIX := -cpu
		OFI_BUILD_ARG := WITH_OFI=1
	else
		CPU_SUFFIX := -cpu
		OFI_BUILD_ARG := WITH_OFI
	endif
else
	PLATFORMS := $(PLATFORM_LINUX_AMD_64),$(PLATFORM_LINUX_ARM_64)
	WITH_MPI := 0
	OFI_BUILD_ARG := WITH_OFI
	NCCL_BUILD_ARG := WITH_NCCL
	HOROVOD_WITH_MPI := 0
	HOROVOD_WITHOUT_MPI := 1
	HOROVOD_CPU_OPERATIONS := GLOO
	MPI_BUILD_ARG := USE_GLOO=1
endif

export CPU_PY_39_BASE_NAME := $(CPU_PREFIX_39)base$(CPU_SUFFIX)
export CPU_PY_310_BASE_NAME := $(CPU_PREFIX_310)base$(CPU_SUFFIX)
export CUDA_113_BASE_NAME := $(CUDA_113_PREFIX)base$(CUDA_SUFFIX)
export CUDA_118_BASE_NAME := $(CUDA_118_PREFIX)base$(CUDA_SUFFIXS)

# Timeout used by packer for AWS operations. Default is 120 (30 minutes) for
# waiting for AMI availablity. Bump to 360 attempts = 90 minutes.
export AWS_MAX_ATTEMPTS=360

# Base images.
.PHONY: build-cpu-py-39-base
build-cpu-py-39-base:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name builder --driver docker-container --use
	docker buildx build -f Dockerfile-base-cpu \
	    --platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(UBUNTU_IMAGE_TAG)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_39)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		--build-arg "$(OFI_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_39_BASE_NAME)-$(SHORT_GIT_HASH) \
		--push \
		.

.PHONY: build-cpu-py-310-base
build-cpu-py-310-base:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name builder --driver docker-container --use
	docker buildx build -f Dockerfile-base-cpu \
	    --platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(UBUNTU_IMAGE_TAG)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_310)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		--build-arg "$(OFI_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_310_BASE_NAME)-$(SHORT_GIT_HASH) \
		--push \
		.

.PHONY: build-cuda-113-base
build-cuda-113-base:
	docker buildx build -f Dockerfile-base-cuda \
		--build-arg BASE_IMAGE="nvidia/cuda:11.3.1-cudnn8-devel-$(UBUNTU_VERSION)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_39)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg WITH_AWS_TRACE="$(WITH_AWS_TRACE)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		--build-arg "$(OFI_BUILD_ARG)" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH) \
		--load \
		.

.PHONY: build-cuda-118-base
build-cuda-118-base:
	docker buildx build -f Dockerfile-base-cuda \
		--build-arg BASE_IMAGE="nvidia/cuda:11.8.0-cudnn8-devel-$(UBUNTU_VERSION)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_310)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg WITH_AWS_TRACE="$(WITH_AWS_TRACE)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		--build-arg "$(OFI_BUILD_ARG)" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_118_BASE_NAME)-$(SHORT_GIT_HASH) \
		--load \
		.

NGC_PYTORCH_PREFIX := nvcr.io/nvidia/pytorch
NGC_TENSORFLOW_PREFIX := nvcr.io/nvidia/tensorflow
NGC_PYTORCH_VERSION := 24.03-py3
NGC_TENSORFLOW_VERSION := 24.03-tf2-py3
export NGC_PYTORCH_REPO := pytorch-ngc-dev
NGC_PYTORCH_HPC_REPO := pytorch-ngc-hpc-dev
NGC_TF_REPO := tensorflow-ngc-dev
NGC_TF_HPC_REPO := tensorflow-ngc-hpc-dev

# build hpc together since hpc is dependent on the normal build
.PHONY: build-pytorch-ngc
build-pytorch-ngc:
	docker build -f Dockerfile-pytorch-ngc \
		--build-arg BASE_IMAGE="$(NGC_PYTORCH_PREFIX):$(NGC_PYTORCH_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/$(NGC_PYTORCH_REPO):$(SHORT_GIT_HASH) \
		.
	docker build -f Dockerfile-ngc-hpc \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(NGC_PYTORCH_REPO):$(SHORT_GIT_HASH)" \
		-t $(DOCKERHUB_REGISTRY)/$(NGC_PYTORCH_HPC_REPO):$(SHORT_GIT_HASH) \
		.

.PHONY: build-tensorflow-ngc
build-tensorflow-ngc:
	docker build -f Dockerfile-tensorflow-ngc \
		--build-arg BASE_IMAGE="$(NGC_TENSORFLOW_PREFIX):$(NGC_TENSORFLOW_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/$(NGC_TF_REPO):$(SHORT_GIT_HASH) \
		.
	docker build -f Dockerfile-ngc-hpc \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(NGC_TF_REPO):$(SHORT_GIT_HASH)" \
		-t $(DOCKERHUB_REGISTRY)/$(NGC_TF_HPC_REPO):$(SHORT_GIT_HASH) \
		.

ifeq ($(WITH_MPICH),1)
ROCM56_TORCH13_MPI :=pytorch-1.3-tf-2.10-rocm-mpich
else
ROCM56_TORCH13_MPI :=pytorch-1.3-tf-2.10-rocm-ompi
endif
export ROCM56_TORCH13_TF_ENVIRONMENT_NAME := $(ROCM_56_PREFIX)$(ROCM56_TORCH13_MPI)
.PHONY: build-pytorch13-tf210-rocm56
build-pytorch13-tf210-rocm56:
	docker build -f Dockerfile-default-rocm \
		--build-arg BASE_IMAGE="rocm/pytorch:rocm5.6_ubuntu20.04_py3.8_pytorch_1.13.1"\
		--build-arg TENSORFLOW_PIP="tensorflow-rocm==2.10.1.540" \
		--build-arg HOROVOD_PIP="horovod==0.28.1" \
		--build-arg WITH_MPICH=$(WITH_MPICH) \
		-t $(DOCKERHUB_REGISTRY)/$(ROCM56_TORCH13_TF_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(ROCM56_TORCH13_TF_ENVIRONMENT_NAME)-$(VERSION) \
		.

ifeq ($(WITH_MPICH),1)
ROCM56_TORCH_MPI :=pytorch-2.0-tf-2.10-rocm-mpich
else
ROCM56_TORCH_MPI :=pytorch-2.0-tf-2.10-rocm-ompi
endif
export ROCM56_TORCH_TF_ENVIRONMENT_NAME := $(ROCM_56_PREFIX)$(ROCM56_TORCH_MPI)
.PHONY: build-pytorch20-tf210-rocm56
build-pytorch20-tf210-rocm56:
	docker build -f Dockerfile-default-rocm \
		--build-arg BASE_IMAGE="rocm/pytorch:rocm5.6_ubuntu20.04_py3.8_pytorch_2.0.1" \
		--build-arg TENSORFLOW_PIP="tensorflow-rocm==2.10.1.540" \
		--build-arg HOROVOD_PIP="horovod==0.28.1" \
                --build-arg WITH_MPICH=$(WITH_MPICH) \
		-t $(DOCKERHUB_REGISTRY)/$(ROCM56_TORCH_TF_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(ROCM56_TORCH_TF_ENVIRONMENT_NAME)-$(VERSION) \
		.

DEEPSPEED_VERSION := 0.8.3
export GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME := deepspeed-cuda-gpt-neox
export TORCH_PIP_DEEPSPEED_CUDA := torch==1.10.2+cu113 torchvision==0.11.3+cu113 torchaudio==0.10.2+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html

# This builds deepspeed environment off of a patched version of EleutherAI's fork of DeepSpeed
# that we need for gpt-neox support.
.PHONY: build-deepspeed-gpt-neox
build-deepspeed-gpt-neox: build-cuda-113-base
	docker build -f Dockerfile-default-cuda \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_DEEPSPEED_CUDA)" \
		--build-arg TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		--build-arg DEEPSPEED_PIP="git+https://github.com/determined-ai/deepspeed.git@eleuther_dai" \
		-t $(DOCKERHUB_REGISTRY)/$(GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME):$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME):$(SHORT_GIT_HASH) \
		.

TORCH_VERSION := 1.12
TF_VERSION_SHORT := 2.11
TF_VERSION := 2.11.1
TF_PIP_CPU := tensorflow-cpu==$(TF_VERSION)
TF_PIP_CUDA := tensorflow==$(TF_VERSION)
TORCH_PIP_CPU := torch==1.12.0+cpu torchvision==0.13.0+cpu torchaudio==0.12.0+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html
TORCH_PIP_CUDA := torch==1.12.0+cu113 torchvision==0.13.0+cu113 torchaudio==0.12.0+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html
HOROVOD_PIP_COMMAND := horovod==0.28.1

export CPU_TF_ENVIRONMENT_NAME := pytorch-tensorflow$(CPU_SUFFIX)$(HPC_SUFFIX)-dev
export CUDA_TF_ENVIRONMENT_NAME := pytorch-tensorflow$(CUDA_SUFFIX)$(HPC_SUFFIX)-dev

ifeq ($(NGC_PUBLISH),)
define CPU_TF_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_TF_ENVIRONMENT_NAME):$(SHORT_GIT_HASH)
endef
else
define CPU_TF_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_TF_ENVIRONMENT_NAME):$(SHORT_GIT_HASH) \
-t $(NGC_REGISTRY)/$(CPU_TF_ENVIRONMENT_NAME):$(SHORT_GIT_HASH)
endef
endif

.PHONY: build-tensorflow-cpu
build-tensorflow-cpu: build-cpu-py-39-base
	docker buildx build -f Dockerfile-default-cpu \
	    --platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_39_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="$(TF_PIP_CPU)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_CPU)" \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		$(CPU_TF_TAGS) \
		--push \
		.

.PHONY: build-tensorflow-cuda
build-tensorflow-cuda: build-cuda-113-base
	docker build -f Dockerfile-default-cuda \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="$(TF_PIP_CUDA)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_CUDA)" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg WITH_AWS_TRACE="$(WITH_AWS_TRACE)" \
		--build-arg INTERNAL_AWS_DS="$(INTERNAL_AWS_DS)" \
		--build-arg INTERNAL_AWS_PATH="$(INTERNAL_AWS_PATH)" \
		--build-arg "$(OFI_BUILD_ARG)" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		--build-arg HOROVOD_GPU_OPERATIONS="$(HOROVOD_GPU_OPERATIONS)" \
		--build-arg HOROVOD_GPU_ALLREDUCE="$(HOROVOD_GPU_ALLREDUCE)" \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_TF_ENVIRONMENT_NAME):$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CUDA_TF_ENVIRONMENT_NAME):$(SHORT_GIT_HASH) \
		.

# torch 2.0 recipes
TORCH2_VERSION := 2.0
TORCH2_PIP_CPU := torch==2.0.1+cpu torchvision==0.15.2+cpu torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cpu
TORCH2_PIP_CUDA := torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2+cu118 --index-url https://download.pytorch.org/whl/cu118
TORCH2_APEX_GIT_URL := https://github.com/determined-ai/apex.git@50ac8425403b98147cbb66aea9a2a27dd3fe7673
export CPU_PYTORCH_ENVIRONMENT_NAME := pytorch$(CPU_SUFFIX)$(HPC_SUFFIX)-dev
export CUDA_PYTORCH_ENVIRONMENT_NAME := pytorch$(CUDA_SUFFIX)$(HPC_SUFFIX)-dev

ifeq ($(NGC_PUBLISH),)
define CPU_PYTORCH_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_PYTORCH_ENVIRONMENT_NAME):$(SHORT_GIT_HASH)
endef
else
define CPU_PYTORCH_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_PYTORCH_ENVIRONMENT_NAME):$(SHORT_GIT_HASH) \
-t $(NGC_REGISTRY)/$(CPU_PYTORCH_ENVIRONMENT_NAME):$(SHORT_GIT_HASH)
endef
endif

.PHONY: build-pytorch-cpu
build-pytorch-cpu: build-cpu-py-310-base
	docker buildx build -f Dockerfile-default-cpu \
	    --platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_310_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH2_PIP_CPU)" \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		$(CPU_PYTORCH_TAGS) \
		--push \
		.

.PHONY: build-pytorch-cuda
build-pytorch-cuda: build-cuda-118-base
	docker build -f Dockerfile-default-cuda \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CUDA_118_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH2_PIP_CUDA)" \
		--build-arg TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT=$(TORCH2_APEX_GIT_URL) \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		-t $(DOCKERHUB_REGISTRY)/$(CUDA_PYTORCH_ENVIRONMENT_NAME):$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CUDA_PYTORCH_ENVIRONMENT_NAME):$(SHORT_GIT_HASH) \
		.

.PHONY: publish-tensorflow-cpu
publish-tensorflow-cpu:
	scripts/publish-versionless-docker.sh tensorflow-cpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CPU_TF_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR) --no-push

.PHONY: publish-tensorflow-cuda
publish-tensorflow-cuda:
	scripts/publish-versionless-docker.sh tensorflow-cuda-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CUDA_TF_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-versionless-docker.sh tensorflow-cuda-$(WITH_MPI) $(NGC_REGISTRY)/$(CUDA_TF_ENVIRONMENT_NAME) $(SHORT_GIT_HASH)
endif

.PHONY: publish-pytorch-cpu
publish-pytorch-cpu:
	scripts/publish-versionless-docker.sh pytorch-cpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CPU_PYTORCH_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR) --no-push

.PHONY: publish-pytorch-cuda
publish-pytorch-cuda:
	scripts/publish-versionless-docker.sh pytorch-cuda-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CUDA_PYTORCH_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-versionless-docker.sh pytorch-cuda-$(WITH_MPI) $(NGC_REGISTRY)/$(CUDA_PYTORCH_ENVIRONMENT_NAME) $(SHORT_GIT_HASH)
endif

.PHONY: publish-deepspeed-gpt-neox
publish-deepspeed-gpt-neox:
	scripts/publish-versionless-docker.sh deepspeed-gpt-neox-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-versionless-docker.sh deepspeed-gpt-neox-$(WITH_MPI) $(NGC_REGISTRY)/$(GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH)
endif

.PHONY: publish-pytorch-ngc
publish-pytorch-ngc:
	scripts/publish-versionless-docker.sh pytorch-ngc $(DOCKERHUB_REGISTRY)/$(NGC_PYTORCH_REPO) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)
	scripts/publish-versionless-docker.sh pytorch-ngc-hpc $(DOCKERHUB_REGISTRY)/$(NGC_PYTORCH_HPC_REPO) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)

.PHONY: publish-pytorch13-tf210-rocm56
publish-pytorch13-tf210-rocm56:
	scripts/publish-docker.sh pytorch13-tf210-rocm56-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(ROCM56_TORCH13_TF_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)

.PHONY: publish-pytorch20-tf210-rocm56
publish-pytorch20-tf210-rocm56:
	scripts/publish-docker.sh pytorch20-tf210-rocm56-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(ROCM56_TORCH_TF_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)

.PHONY: publish-tensorflow-ngc
publish-tensorflow-ngc:
	scripts/publish-versionless-docker.sh tensorflow-ngc $(DOCKERHUB_REGISTRY)/$(NGC_TF_REPO) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)
	scripts/publish-versionless-docker.sh tensorflow-ngc-hpc $(DOCKERHUB_REGISTRY)/$(NGC_TF_HPC_REPO) $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)

.PHONY: publish-cloud-images
publish-cloud-images:
	mkdir -p $(ARTIFACTS_DIR)
	cd cloud \
		&& packer build $(PACKER_FLAGS) -machine-readable -var "image_suffix=$(SHORT_GIT_HASH)" environments-packer.json \
		| tee $(ARTIFACTS_DIR)/packer-log

