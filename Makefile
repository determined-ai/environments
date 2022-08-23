SHELL := /bin/bash -o pipefail
VERSION := $(shell cat VERSION)
VERSION_DASHES := $(subst .,-,$(VERSION))
SHORT_GIT_HASH := $(shell git rev-parse --short HEAD)

NGC_REGISTRY := nvcr.io/isv-ngc-partner/determined
NGC_PUBLISH := 1
export DOCKERHUB_REGISTRY := determinedai
export REGISTRY_REPO := environments

CPU_PREFIX := $(REGISTRY_REPO):py-3.8-
CPU_PREFIX_37 := $(REGISTRY_REPO):py-3.7-
CUDA_102_PREFIX := $(REGISTRY_REPO):cuda-10.2-
CUDA_111_PREFIX := $(REGISTRY_REPO):cuda-11.1-
CUDA_112_PREFIX := $(REGISTRY_REPO):cuda-11.2-
CUDA_113_PREFIX := $(REGISTRY_REPO):cuda-11.3-
ROCM_50_PREFIX := $(REGISTRY_REPO):rocm-5.0-

CPU_SUFFIX := -cpu
GPU_SUFFIX := -gpu
ARTIFACTS_DIR := /tmp/artifacts
PYTHON_VERSION := 3.8.11
PYTHON_VERSION_37 := 3.7.11

export CPU_PY_37_BASE_NAME := $(CPU_PREFIX_37)base$(CPU_SUFFIX)
export GPU_CUDA_102_BASE_NAME := $(CUDA_102_PREFIX)base$(GPU_SUFFIX)
export CPU_PY_38_BASE_NAME := $(CPU_PREFIX)base$(CPU_SUFFIX)
export GPU_CUDA_111_BASE_NAME := $(CUDA_111_PREFIX)base$(GPU_SUFFIX)
export GPU_CUDA_112_BASE_NAME := $(CUDA_112_PREFIX)base$(GPU_SUFFIX)
export GPU_CUDA_113_BASE_NAME := $(CUDA_113_PREFIX)base$(GPU_SUFFIX)

export CPU_TF1_ENVIRONMENT_NAME := $(CPU_PREFIX_37)pytorch-1.7-tf-1.15$(CPU_SUFFIX)
export GPU_TF1_ENVIRONMENT_NAME := $(CUDA_102_PREFIX)pytorch-1.7-tf-1.15$(GPU_SUFFIX)
export CPU_TF24_ENVIRONMENT_NAME := $(CPU_PREFIX)pytorch-1.9-lightning-1.5-tf-2.4$(CPU_SUFFIX)
export GPU_TF24_ENVIRONMENT_NAME := $(CUDA_111_PREFIX)pytorch-1.9-lightning-1.5-tf-2.4$(GPU_SUFFIX)
export CPU_TF2_ENVIRONMENT_NAME := $(CPU_PREFIX)pytorch-1.10-lightning-1.5-tf-2.8$(CPU_SUFFIX)
export GPU_TF2_ENVIRONMENT_NAME := $(CUDA_113_PREFIX)pytorch-1.10-lightning-1.5-tf-2.8$(GPU_SUFFIX)
export GPU_DEEPSPEED_ENVIRONMENT_NAME := $(CUDA_113_PREFIX)pytorch-1.10-lightning-1.5-tf-2.8-deepspeed-0.5.10$(GPU_SUFFIX)
export GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME := $(CUDA_113_PREFIX)pytorch-1.10-lightning-1.5-tf-2.8-gpt-neox-deepspeed$(GPU_SUFFIX)
export CPU_TF25_ENVIRONMENT_NAME := $(CPU_PREFIX)tf-2.5$(CPU_SUFFIX)
export GPU_TF25_ENVIRONMENT_NAME := $(CUDA_112_PREFIX)tf-2.5$(GPU_SUFFIX)
export CPU_TF26_ENVIRONMENT_NAME := $(CPU_PREFIX)tf-2.6$(CPU_SUFFIX)
export GPU_TF26_ENVIRONMENT_NAME := $(CUDA_112_PREFIX)tf-2.6$(GPU_SUFFIX)
export CPU_TF27_ENVIRONMENT_NAME := $(CPU_PREFIX)tf-2.7$(CPU_SUFFIX)
export GPU_TF27_ENVIRONMENT_NAME := $(CUDA_112_PREFIX)tf-2.7$(GPU_SUFFIX)

export ROCM50_TORCH_TF_ENVIRONMENT_NAME := $(ROCM_50_PREFIX)pytorch-1.10-tf-2.7-rocm

# Timeout used by packer for AWS operations. Default is 120 (30 minutes) for
# waiting for AMI availablity. Bump to 360 attempts = 90 minutes.
export AWS_MAX_ATTEMPTS=360

# Base images.
.PHONY: build-cpu-py-37-base build-cpu-py-38-base  build-gpu-cuda-111-base build-gpu-cuda-112-base build-gpu-cuda-113-base
build-cpu-py-37-base:
	docker build -f Dockerfile-base-cpu \
		--build-arg BASE_IMAGE="ubuntu:18.04" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_37)" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_37_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_37_BASE_NAME)-$(VERSION) \
		.

.PHONY: build-cpu-py-38-base
build-cpu-py-38-base:
	docker build -f Dockerfile-base-cpu \
		--build-arg BASE_IMAGE="ubuntu:18.04" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(VERSION) \
		.

.PHONY: build-gpu-cuda-102-base
build-gpu-cuda-102-base:
	docker build -f Dockerfile-base-gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION_37)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_102_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_102_BASE_NAME)-$(VERSION) \
		.

.PHONY: build-gpu-cuda-111-base
build-gpu-cuda-111-base:
	docker build -f Dockerfile-base-gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_111_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_111_BASE_NAME)-$(VERSION) \
		.

.PHONY: build-gpu-cuda-112-base
build-gpu-cuda-112-base:
	docker build -f Dockerfile-base-gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:11.2.2-cudnn8-devel-ubuntu18.04" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME)-$(VERSION) \
		.

.PHONY: build-gpu-cuda-113-base
build-gpu-cuda-113-base:
	docker build -f Dockerfile-base-gpu \
		--build-arg BASE_IMAGE="nvidia/cuda:11.3.1-cudnn8-devel-ubuntu18.04" \
		--build-arg PYTHON_VERSION="$(PYTHON_VERSION)" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(VERSION) \
		.

# Full images.
.PHONY: build-tf1-cpu
build-tf1-cpu: build-cpu-py-37-base
	docker build -f Dockerfile-default-cpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_37_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow==1.15.5" \
		--build-arg TORCH_PIP="torch==1.7.1 -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2 -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf1-gpu
build-tf1-gpu: build-gpu-cuda-102-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_102_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="https://github.com/determined-ai/tensorflow-wheels/releases/download/0.1.0/tensorflow_gpu-1.15.5-cp37-cp37m-linux_x86_64.whl" \
		--build-arg TORCH_PIP="torch==1.7.1 -f https://download.pytorch.org/whl/cu102/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.8.2 -f https://download.pytorch.org/whl/cu102/torch_stable.html" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf24-cpu
build-tf24-cpu: build-cpu-py-38-base
	docker build -f Dockerfile-default-cpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow-cpu==2.4.4" \
		--build-arg TORCH_PIP="torch==1.9.1 -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.10.0 -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.5.10 torchmetrics==0.5.1" \
		--build-arg TORCH_PROFILER_GIT="https://github.com/pytorch/kineto.git@7455c31a01dd98bd0a863feacac4d46c7a44ea40" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF24_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF24_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF24_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF24_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf24-gpu
build-tf24-gpu: build-gpu-cuda-111-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_111_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TF_CUDA_SYM="1" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.4.4" \
		--build-arg TORCH_PIP="torch==1.9.1 -f https://download.pytorch.org/whl/cu111/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.10.0 -f https://download.pytorch.org/whl/cu111/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.5.10 torchmetrics==0.5.1" \
		--build-arg TORCH_PROFILER_GIT="https://github.com/pytorch/kineto.git@7455c31a01dd98bd0a863feacac4d46c7a44ea40" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF24_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF24_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF24_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF24_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf2-cpu
build-tf2-cpu: build-cpu-py-38-base
	docker build -f Dockerfile-default-cpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow-cpu==2.8.2" \
		--build-arg TORCH_PIP="torch==1.10.2+cpu torchvision==0.11.3+cpu torchaudio==0.10.2+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.5.10 torchmetrics==0.5.1" \
		--build-arg TORCH_PROFILER_GIT="https://github.com/pytorch/kineto.git@7455c31a01dd98bd0a863feacac4d46c7a44ea40" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf2-gpu
build-tf2-gpu: build-gpu-cuda-113-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.8.2" \
		--build-arg TORCH_PIP="torch==1.10.2+cu113 torchvision==0.11.3+cu113 torchaudio==0.10.2+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.5.10 torchmetrics==0.5.1" \
		--build-arg TORCH_PROFILER_GIT="https://github.com/pytorch/kineto.git@7455c31a01dd98bd0a863feacac4d46c7a44ea40" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg DET_BUILD_NCCL="" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME)-$(VERSION) \
		.

# This builds deepspeed environment off of upstream microsoft/DeepSpeed.
.PHONY: build-deepspeed-gpu
build-deepspeed-gpu: build-gpu-cuda-113-base
	# We should consider building without tensorflow in the future.  Going to keep tensorflow for
	# now since we want to have tensorboard support.  It should be possible to install tensorboard
	# without tensorflow though.
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.8.2" \
		--build-arg TORCH_PIP="torch==1.10.2+cu113 torchvision==0.11.3+cu113 torchaudio==0.10.2+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.5.10 torchmetrics==0.5.1" \
		--build-arg TORCH_PROFILER_GIT="https://github.com/pytorch/kineto.git@7455c31a01dd98bd0a863feacac4d46c7a44ea40" \
		--build-arg TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg DET_BUILD_NCCL="" \
		--build-arg DEEPSPEED_PIP="deepspeed==0.6.0" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME)-$(VERSION) \
		.

# This builds deepspeed environment off of a patched version of EleutherAI's fork of DeepSpeed
# that we need for gpt-neox support.
.PHONY: build-gpt-neox-deepspeed-gpu
build-gpt-neox-deepspeed-gpu: build-gpu-cuda-113-base
	# We should consider building without tensorflow in the future.  Going to keep tensorflow for
	# now since we want to have tensorboard support.  It should be possible to install tensorboard
	# without tensorflow though.
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.8.2" \
		--build-arg TORCH_PIP="torch==1.10.2+cu113 torchvision==0.11.3+cu113 torchaudio==0.10.2+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.5.10 torchmetrics==0.5.1" \
		--build-arg TORCH_PROFILER_GIT="https://github.com/pytorch/kineto.git@7455c31a01dd98bd0a863feacac4d46c7a44ea40" \
		--build-arg TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/determined-ai/apex.git@3caf0f40c92e92b40051d3afff8568a24b8be28d" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg DET_BUILD_NCCL="" \
		--build-arg DEEPSPEED_PIP="git+https://github.com/determined-ai/deepspeed.git@eleuther_dai" \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME)-$(VERSION) \
		.

# TF 2.5 and TF 2.6 images do not have pytorch because their CUDA version doesn't work well with pytorch 1.9.
.PHONY: build-tf25-cpu
build-tf25-cpu: build-cpu-py-38-base
	docker build -f Dockerfile-default-cpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow-cpu==2.5.3" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg HOROVOD_WITH_PYTORCH=0 \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF25_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF25_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF25_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF25_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf25-gpu
build-tf25-gpu: build-gpu-cuda-112-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.5.3" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg HOROVOD_WITH_PYTORCH=0 \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf26-cpu
build-tf26-cpu: build-cpu-py-38-base
	docker build -f Dockerfile-default-cpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow-cpu==2.6.5" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg HOROVOD_WITH_PYTORCH=0 \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF26_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF26_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF26_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF26_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf26-gpu
build-tf26-gpu: build-gpu-cuda-112-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.6.5" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg HOROVOD_WITH_PYTORCH=0 \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF26_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF26_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF26_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF26_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf27-cpu
build-tf27-cpu: build-cpu-py-38-base
	docker build -f Dockerfile-default-cpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow-cpu==2.7.3" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg HOROVOD_WITH_PYTORCH=0 \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF27_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(CPU_TF27_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(CPU_TF27_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(CPU_TF27_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-tf27-gpu
build-tf27-gpu: build-gpu-cuda-112-base
	docker build -f Dockerfile-default-gpu \
		--build-arg BASE_IMAGE="$(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME)-$(SHORT_GIT_HASH)" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.7.3" \
		--build-arg HOROVOD_PIP="horovod==0.24.2" \
		--build-arg HOROVOD_WITH_PYTORCH=0 \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF27_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(GPU_TF27_ENVIRONMENT_NAME)-$(VERSION) \
		-t $(NGC_REGISTRY)/$(GPU_TF27_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(NGC_REGISTRY)/$(GPU_TF27_ENVIRONMENT_NAME)-$(VERSION) \
		.

.PHONY: build-pytorch10-tf27-rocm50
build-pytorch10-tf27-rocm50:
	docker build -f Dockerfile-default-rocm \
		--build-arg BASE_IMAGE="amdih/pytorch:rocm5.0_ubuntu18.04_py3.7_pytorch_1.10.0" \
		--build-arg TENSORFLOW_PIP="tensorflow-rocm==2.7.1" \
		--build-arg HOROVOD_PIP="horovod==0.25.0" \
		-t $(DOCKERHUB_REGISTRY)/$(ROCM50_TORCH_TF_ENVIRONMENT_NAME)-$(SHORT_GIT_HASH) \
		-t $(DOCKERHUB_REGISTRY)/$(ROCM50_TORCH_TF_ENVIRONMENT_NAME)-$(VERSION) \
		.

# tf1 and tf2.4 images are not published to NGC due to vulnerabilities.
.PHONY: publish-tf1-cpu
publish-tf1-cpu:
	scripts/publish-docker.sh tf1-cpu $(DOCKERHUB_REGISTRY)/$(CPU_PY_37_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf1-cpu $(DOCKERHUB_REGISTRY)/$(CPU_TF1_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)

.PHONY: publish-tf1-gpu
publish-tf1-gpu:
	scripts/publish-docker.sh tf1-gpu $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_102_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf1-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF1_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)

.PHONY: publish-tf24-cpu
publish-tf24-cpu:
	scripts/publish-docker.sh tf24-cpu $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf24-cpu $(DOCKERHUB_REGISTRY)/$(CPU_TF24_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)

.PHONY: publish-tf24-gpu
publish-tf24-gpu:
	scripts/publish-docker.sh tf24-gpu $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_111_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf24-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF24_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)

.PHONY: publish-tf2-cpu
publish-tf2-cpu:
	scripts/publish-docker.sh tf2-cpu $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf2-cpu $(DOCKERHUB_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf2-cpu $(NGC_REGISTRY)/$(CPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-tf2-gpu
publish-tf2-gpu:
	scripts/publish-docker.sh tf2-gpu $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_113_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf2-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf2-gpu $(NGC_REGISTRY)/$(GPU_TF2_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-deepspeed-gpu
publish-deepspeed-gpu:
	scripts/publish-docker.sh deepspeed-gpu $(DOCKERHUB_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh deepspeed-gpu $(NGC_REGISTRY)/$(GPU_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-gpt-neox-deepspeed-gpu
publish-gpt-neox-deepspeed-gpu:
	scripts/publish-docker.sh gpt-neox-deepspeed-gpu $(DOCKERHUB_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh gpt-neox-deepspeed-gpu $(NGC_REGISTRY)/$(GPU_GPT_NEOX_DEEPSPEED_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-tf25-cpu
publish-tf25-cpu:
	scripts/publish-docker.sh tf25-cpu $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf25-cpu $(DOCKERHUB_REGISTRY)/$(CPU_TF25_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf25-cpu $(NGC_REGISTRY)/$(CPU_TF25_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-tf25-gpu
publish-tf25-gpu:
	scripts/publish-docker.sh tf25-gpu $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf25-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf25-gpu $(NGC_REGISTRY)/$(GPU_TF25_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-tf26-cpu
publish-tf26-cpu:
	scripts/publish-docker.sh tf26-cpu $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf26-cpu $(DOCKERHUB_REGISTRY)/$(CPU_TF26_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf26-cpu $(NGC_REGISTRY)/$(CPU_TF26_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-tf26-gpu
publish-tf26-gpu:
	scripts/publish-docker.sh tf26-gpu $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf26-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF26_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf26-gpu $(NGC_REGISTRY)/$(GPU_TF26_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-tf27-cpu
publish-tf27-cpu:
	scripts/publish-docker.sh tf27-cpu $(DOCKERHUB_REGISTRY)/$(CPU_PY_38_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf27-cpu $(DOCKERHUB_REGISTRY)/$(CPU_TF27_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf27-cpu $(NGC_REGISTRY)/$(CPU_TF27_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif

.PHONY: publish-tf27-gpu
publish-tf27-gpu:
	scripts/publish-docker.sh tf27-gpu $(DOCKERHUB_REGISTRY)/$(GPU_CUDA_112_BASE_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
	scripts/publish-docker.sh tf27-gpu $(DOCKERHUB_REGISTRY)/$(GPU_TF27_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)
ifneq ($(NGC_PUBLISH),)
	scripts/publish-docker.sh tf27-gpu $(NGC_REGISTRY)/$(GPU_TF27_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION)
endif


.PHONY: publish-pytorch10-tf27-rocm50
publish-pytorch10-tf27-rocm50:
	scripts/publish-docker.sh pytorch10-tf27-rocm50 $(DOCKERHUB_REGISTRY)/$(ROCM50_TORCH_TF_ENVIRONMENT_NAME) $(SHORT_GIT_HASH) $(VERSION) $(ARTIFACTS_DIR)


.PHONY: publish-cloud-images
publish-cloud-images:
	mkdir -p $(ARTIFACTS_DIR)
	cd cloud \
		&& packer build $(PACKER_FLAGS) -machine-readable -var "image_suffix=-$(SHORT_GIT_HASH)" environments-packer.json \
		| tee $(ARTIFACTS_DIR)/packer-log
