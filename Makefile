SHELL := /bin/bash -o pipefail
VERSION := $(shell cat VERSION)
VERSION_DASHES := $(subst .,-,$(VERSION))
SHORT_GIT_HASH := $(shell git rev-parse --short HEAD)

NGC_REGISTRY := nvcr.io/isv-ngc-partner/determined
NGC_PUBLISH := 1
export DOCKERHUB_REGISTRY := determinedai
export REGISTRY_REPO := environments

CPU_PREFIX_38 := $(REGISTRY_REPO):py-3.8-
CPU_PREFIX_39 := $(REGISTRY_REPO):py-3.9-
CPU_PREFIX_310 := $(REGISTRY_REPO):py-3.10-
CUDA_111_PREFIX := $(REGISTRY_REPO):cuda-11.1-
CUDA_112_PREFIX := $(REGISTRY_REPO):cuda-11.2-
CUDA_113_PREFIX := $(REGISTRY_REPO):cuda-11.3-
CUDA_118_PREFIX := $(REGISTRY_REPO):cuda-11.8-
ROCM_56_PREFIX := $(REGISTRY_REPO):rocm-5.6-

CPU_SUFFIX := -cpu
GPU_SUFFIX := -gpu
ARTIFACTS_DIR := /tmp/artifacts
PYTHON_VERSION_38 := 3.8.12
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
	PLATFORMS := $(PLATFORM_LINUX_AMD_64)
	HOROVOD_WITH_MPI := 1
	HOROVOD_WITHOUT_MPI := 0
	HOROVOD_CPU_OPERATIONS := MPI
	GPU_SUFFIX := -gpu-mpi
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
	        GPU_SUFFIX := -gpu-mpi-ofi
		CPU_SUFFIX := -cpu-mpi-ofi
		OFI_BUILD_ARG := WITH_OFI=1
	else
		CPU_SUFFIX := -cpu-mpi
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

export CPU_PY_38_BASE_NAME := $(CPU_PREFIX_38)base$(CPU_SUFFIX)
export CPU_PY_39_BASE_NAME := $(CPU_PREFIX_39)base$(CPU_SUFFIX)
export CPU_PY_310_BASE_NAME := $(CPU_PREFIX_310)base$(CPU_SUFFIX)
export GPU_CUDA_111_BASE_NAME := $(CUDA_111_PREFIX)base$(GPU_SUFFIX)
export GPU_CUDA_112_BASE_NAME := $(CUDA_112_PREFIX)base$(GPU_SUFFIX)
export GPU_CUDA_113_BASE_NAME := $(CUDA_113_PREFIX)base$(GPU_SUFFIX)
export GPU_CUDA_118_BASE_NAME := $(CUDA_118_PREFIX)base$(GPU_SUFFIX)

# Timeout used by packer for AWS operations. Default is 120 (30 minutes) for
# waiting for AMI availablity. Bump to 360 attempts = 90 minutes.
export AWS_MAX_ATTEMPTS=360

# Base images.
.PHONY: build-cpu-py-38-base
build-cpu-py-38-base:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name builder --driver docker-container --use
	docker buildx build -f Dockerfile-base-cpu \
	    --platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(UBUNTU_IMAGE_TAG)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_38)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		--build-arg "$(OFI_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(VERSION) \
		--push \
		.

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
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_39_BASE_NAME)-$(VERSION) \
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
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_310_BASE_NAME)-$(VERSION) \
		--push \
		.

.PHONY: build-gpu-cuda-111-base
build-gpu-cuda-111-base:
	docker build -f Dockerfile-base-gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:11.1.1-cudnn8-devel-$(UBUNTU_VERSION)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_38)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_111_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_111_BASE_NAME)-$(VERSION) \
		.

.PHONY: build-gpu-cuda-112-base
build-gpu-cuda-112-base:
	docker build -f Dockerfile-base-gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:11.2.2-cudnn8-devel-$(UBUNTU_VERSION)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_39)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME)-$(VERSION) \
		.

.PHONY: build-gpu-cuda-113-base
build-gpu-cuda-113-base:
	docker build -f Dockerfile-base-gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:11.3.1-cudnn8-devel-$(UBUNTU_VERSION)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_39)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg WITH_AWS_TRACE="$(WITH_AWS_TRACE)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		--build-arg "$(OFI_BUILD_ARG)" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(VERSION) \
		.

.PHONY: build-gpu-cuda-118-base
build-gpu-cuda-118-base:
	docker build -f Dockerfile-base-gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:11.8.0-cudnn8-devel-$(UBUNTU_VERSION)" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_310)" \
		--build-arg UBUNTU_VERSION="$(UBUNTU_VERSION)" \
		--build-arg WITH_AWS_TRACE="$(WITH_AWS_TRACE)" \
		--build-arg "$(MPI_BUILD_ARG)" \
		--build-arg "$(OFI_BUILD_ARG)" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_118_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_118_BASE_NAME)-$(VERSION) \
		.

export TF_PROFILER_PIP := tensorboard-plugin-profile
export TORCH_TB_PROFILER_PIP := torch-tb-profiler==0.4.1

NGC_PYTORCH_PREFIX := nvcr.io/nvidia/pytorch
NGC_TENSORFLOW_PREFIX := nvcr.io/nvidia/tensorflow
NGC_PYTORCH_VERSION := 23.12-py3
NGC_TENSORFLOW_VERSION := 23.12-tf2-py3
NGC_DEEPSPEED_VERSION := 0.13.0

.PHONY: build-pytorch-ngc
build-pytorch-ngc:
	docker build -f Dockerfile-pytorch-ngc \
		--build-arg BASE_IMAGE="$(NGC_PYTORCH_PREFIX):$(NGC_PYTORCH_VERSION)" \
		--build-arg DEEPSPEED_PIP="deepspeed==$(NGC_DEEPSPEED_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/pytorch-ngc:$(SHORT_GIT_HASH) \
		.

.PHONY: build-pytorch-ngc-hpc
build-pytorch-ngc-hpc:
	docker build -f Dockerfile-ngc-hpc \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(NGCPLUS_BASE)-$(NGC_PYTORCH_VERSION)-$(SHORT_GIT_HASH)" \
		-t $(DOCKERHUB_REGISTRY)/pytorch-ngc-hpc:$(SHORT_GIT_HASH) \
		.

.PHONY: build-tensorflow-ngc
build-tensorflow-ngc:
	docker build -f Dockerfile-tensorflow-ngc \
		--build-arg BASE_IMAGE="$(NGC_TENSORFLOW_PREFIX):$(NGC_TENSORFLOW_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/tensorflow-ngc:$(SHORT_GIT_HASH) \
		.

.PHONY: build-tensorflow-ngc-hpc
build-tensorflow-ngc-hpc:
	docker build -f Dockerfile-ngc-hpc \
		--build-arg BASE_IMAGE="$(NGC_TENSORFLOW_PREFIX):$(NGC_TENSORFLOW_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/tensorflow-ngc-hpc:$(SHORT_GIT_HASH) \
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
export GPU_DEEPSPEED_ENVIRONMENT_NAME := $(CUDA_113_PREFIX)pytorch-1.10-deepspeed-$(DEEPSPEED_VERSION)$(GPU_SUFFIX)
export GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME := $(CUDA_113_PREFIX)pytorch-1.10-gpt-neox-deepspeed$(GPU_SUFFIX)
export TORCH_PIP_DEEPSPEED_GPU := torch==1.10.2+cu113 torchvision==0.11.3+cu113 torchaudio==0.10.2+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html

# This builds deepspeed environment off of upstream microsoft/DeepSpeed.
.PHONY: build-deepspeed
build-deepspeed: build-gpu-cuda-113-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_DEEPSPEED_GPU)" \
		--build-arg TORCH_TB_PROFILER_PIP="$(TORCH_TB_PROFILER_PIP)" \
		--build-arg TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		--build-arg DEEPSPEED_PIP="deepspeed==$(DEEPSPEED_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME)-$(VERSION) \
		.

# This builds deepspeed environment off of a patched version of EleutherAI's fork of DeepSpeed
# that we need for gpt-neox support.
.PHONY: build-gpt-neox-deepspeed
build-gpt-neox-deepspeed: build-gpu-cuda-113-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_DEEPSPEED_GPU)" \
		--build-arg TORCH_TB_PROFILER_PIP="$(TORCH_TB_PROFILER_PIP)" \
		--build-arg TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		--build-arg DEEPSPEED_PIP="git+https://github.com/determined-ai/deepspeed.git@eleuther_dai" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME)-$(VERSION) \
		.

TORCH_VERSION := 1.12
TF2_VERSION_SHORT := 2.11
TF2_VERSION := 2.11.1
TF2_PIP_CPU := tensorflow-cpu==$(TF2_VERSION)
TF2_PIP_GPU := tensorflow==$(TF2_VERSION)
TORCH_PIP_CPU := torch==1.12.0+cpu torchvision==0.13.0+cpu torchaudio==0.12.0+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html
TORCH_PIP_GPU := torch==1.12.0+cu113 torchvision==0.13.0+cu113 torchaudio==0.12.0+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html
HOROVOD_PIP_COMMAND := horovod==0.28.1

export CPU_TF2_ENVIRONMENT_NAME := $(CPU_PREFIX_39)pytorch-$(TORCH_VERSION)-tf-$(TF2_VERSION_SHORT)$(CPU_SUFFIX)
export GPU_TF2_ENVIRONMENT_NAME := $(CUDA_113_PREFIX)pytorch-$(TORCH_VERSION)-tf-$(TF2_VERSION_SHORT)$(GPU_SUFFIX)
export CPU_PT_ENVIRONMENT_NAME := $(CPU_PREFIX_39)pytorch-$(TORCH_VERSION)$(CPU_SUFFIX)
export GPU_PT_ENVIRONMENT_NAME := $(CUDA_113_PREFIX)pytorch-$(TORCH_VERSION)$(GPU_SUFFIX)

ifeq ($(NGC_PUBLISH),)
define CPU_TF2_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION)
endef
define CPU_PT_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_PT_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(DOCKERHUB_REGISTRY)/$(CPU_PT_ENVIRONMENT_NAME)-$(VERSION)
endef
else
define CPU_TF2_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
-t $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION)
endef
define CPU_PT_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_PT_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(DOCKERHUB_REGISTRY)/$(CPU_PT_ENVIRONMENT_NAME)-$(VERSION) \
-t $(NGC_REGISTRY)/$(CPU_PT_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(NGC_REGISTRY)/$(CPU_PT_ENVIRONMENT_NAME)-$(VERSION)
endef
endif

.PHONY: build-tf2-cpu
build-tf2-cpu: build-cpu-py-39-base
	docker buildx build -f Dockerfile-default-cpu \
	    --platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_39_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="$(TF2_PIP_CPU)" \
		--build-arg TF_PROFILER_PIP="$(TF_PROFILER_PIP)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_CPU)" \
		--build-arg TORCH_TB_PROFILER_PIP="$(TORCH_TB_PROFILER_PIP)" \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		$(CPU_TF2_TAGS) \
		--push \
		.

.PHONY: build-pt-cpu
build-pt-cpu: build-cpu-py-39-base
	docker buildx build -f Dockerfile-default-cpu \
	    --platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_39_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_CPU)" \
		--build-arg TORCH_TB_PROFILER_PIP="$(TORCH_TB_PROFILER_PIP)" \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		$(CPU_PT_TAGS) \
		--push \
		.

.PHONY: build-tf2-gpu
build-tf2-gpu: build-gpu-cuda-113-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="$(TF2_PIP_GPU)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_GPU)" \
		--build-arg TF_PROFILER_PIP="$(TF_PROFILER_PIP)" \
		--build-arg TORCH_TB_PROFILER_PIP="$(TORCH_TB_PROFILER_PIP)" \
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
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-pt-gpu
build-pt-gpu: build-gpu-cuda-113-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH_PIP_GPU)" \
		--build-arg TORCH_TB_PROFILER_PIP="$(TORCH_TB_PROFILER_PIP)" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_PT_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_PT_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_PT_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_PT_ENVIRONMENT_NAME)-$(VERSION) \
		.

# torch 2.0 recipes
TORCH2_VERSION := 2.0
TORCH2_PIP_CPU := torch==2.0.1+cpu torchvision==0.15.2+cpu torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cpu
TORCH2_PIP_GPU := torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2+cu118 --index-url https://download.pytorch.org/whl/cu118
TORCH2_APEX_GIT_URL := https://github.com/determined-ai/apex.git@50ac8425403b98147cbb66aea9a2a27dd3fe7673
export CPU_PT2_ENVIRONMENT_NAME := $(CPU_PREFIX_310)pytorch-$(TORCH2_VERSION)$(CPU_SUFFIX)
export GPU_PT2_ENVIRONMENT_NAME := $(CUDA_118_PREFIX)pytorch-$(TORCH2_VERSION)$(GPU_SUFFIX)

ifeq ($(NGC_PUBLISH),)
define CPU_PT2_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_PT2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(DOCKERHUB_REGISTRY)/$(CPU_PT2_ENVIRONMENT_NAME)-$(VERSION)
endef
else
define CPU_PT2_TAGS
-t $(DOCKERHUB_REGISTRY)/$(CPU_PT2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(DOCKERHUB_REGISTRY)/$(CPU_PT2_ENVIRONMENT_NAME)-$(VERSION) \
-t $(NGC_REGISTRY)/$(CPU_PT2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
-t $(NGC_REGISTRY)/$(CPU_PT2_ENVIRONMENT_NAME)-$(VERSION)
endef
endif

.PHONY: build-pt2-cpu
build-pt2-cpu: build-cpu-py-310-base
	docker buildx build -f Dockerfile-default-cpu \
	    --platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_310_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH2_PIP_CPU)" \
		--build-arg TORCH_TB_PROFILER_PIP="$(TORCH_TB_PROFILER_PIP)" \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		$(CPU_PT2_TAGS) \
		--push \
		.

.PHONY: build-pt2-gpu
build-pt2-gpu: build-gpu-cuda-118-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_118_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TORCH_PIP="$(TORCH2_PIP_GPU)" \
		--build-arg TORCH_TB_PROFILER_PIP="$(TORCH_TB_PROFILER_PIP)" \
		--build-arg TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT=$(TORCH2_APEX_GIT_URL) \
		--build-arg HOROVOD_PIP="$(HOROVOD_PIP_COMMAND)" \
		--build-arg "$(NCCL_BUILD_ARG)" \
		--build-arg HOROVOD_WITH_MPI="$(HOROVOD_WITH_MPI)" \
		--build-arg HOROVOD_WITHOUT_MPI="$(HOROVOD_WITHOUT_MPI)" \
		--build-arg HOROVOD_CPU_OPERATIONS="$(HOROVOD_CPU_OPERATIONS)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_PT2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_PT2_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_PT2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_PT2_ENVIRONMENT_NAME)-$(VERSION) \
		.

# tf1 and tf2.4 images are not published to NGC due to vulnerabilities.
.PHONY: publish-tf2-cpu
publish-tf2-cpu:
	scripts/publish-docker.sh tf2-cpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR) --no-push
	scripts/publish-docker.sh tf2-cpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR) --no-push

.PHONY: publish-tf2-gpu
publish-tf2-gpu:
	scripts/publish-docker.sh tf2-gpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf2-gpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf2-gpu-$(WITH_MPI) $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-pt-cpu
publish-pt-cpu:
	scripts/publish-docker.sh pt-cpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR) --no-push
	scripts/publish-docker.sh pt-cpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CPU_PT_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR) --no-push

.PHONY: publish-pt-gpu
publish-pt-gpu:
	scripts/publish-docker.sh pt-gpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh pt-gpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPU_PT_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh pt-gpu-$(WITH_MPI) $(NGC_REGISTRY)/$(GPU_PT_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-pt2-cpu
publish-pt2-cpu:
	scripts/publish-docker.sh pt2-cpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CPU_PY_310_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR) --no-push
	scripts/publish-docker.sh pt2-cpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(CPU_PT2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR) --no-push

.PHONY: publish-pt2-gpu
publish-pt2-gpu:
	scripts/publish-docker.sh pt2-gpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_118_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh pt2-gpu-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPU_PT2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh pt2-gpu-$(WITH_MPI) $(NGC_REGISTRY)/$(GPU_PT2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-deepspeed
publish-deepspeed:
	scripts/publish-docker.sh deepspeed-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh deepspeed-$(WITH_MPI) $(NGC_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-gpt-neox-deepspeed
publish-gpt-neox-deepspeed:
	scripts/publish-docker.sh gpt-neox-deepspeed-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh gpt-neox-deepspeed-$(WITH_MPI) $(NGC_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-pytorch13-tf210-rocm56
publish-pytorch13-tf210-rocm56:
	scripts/publish-docker.sh pytorch13-tf210-rocm56-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(ROCM56_TORCH13_TF_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)

.PHONY: publish-pytorch20-tf210-rocm56
publish-pytorch20-tf210-rocm56:
	scripts/publish-docker.sh pytorch20-tf210-rocm56-$(WITH_MPI) $(DOCKERHUB_REGISTRY)/$(ROCM56_TORCH_TF_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)

.PHONY: publish-pytorch-ngc
publish-pytorch-ngc:
	scripts/publish-versionless-docker.sh pytorch-ngc $(DOCKERHUB_REGISTRY)/pytorch-ngc $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)

.PHONY: publish-pytorch-ngc-hpc
publish-pytorch-ngc-hpc:
	scripts/publish-versionless-docker.sh pytorch-ngc-hpc $(DOCKERHUB_REGISTRY)/pytorch-ngc-hpc $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)

.PHONY: publish-tensorflow-ngc
publish-tensorflow-ngc:
	scripts/publish-versionless-docker.sh tensorflow-ngc $(DOCKERHUB_REGISTRY)/tensorflow-ngc $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)

.PHONY: publish-tensorflow-ngc-hpc
publish-tensorflow-ngc-hpc:
	scripts/publish-versionless-docker.sh tensorflow-ngc-hpc $(DOCKERHUB_REGISTRY)/tensorflow-ngc-hpc $(SHORT_GIT_HASH) $(ARTIFACTS_DIR)

.PHONY: publish-cloud-images
publish-cloud-images:
	mkdir -p $(ARTIFACTS_DIR)
	cd cloud \
		&& packer build $(PACKER_FLAGS) -machine-readable -var "image_suffix=-$(SHORT_GIT_HASH)" environments-packer.json \
		| tee $(ARTIFACTS_DIR)/packer-log

