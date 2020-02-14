.PHONY: build publish release

VERSION := $(shell cat VERSION)

DOCKER_REGISTRY ?= ""

CPU_IMAGE=determinedai/environments:py-3.6.9-pytorch-1.4-tf-1.14-cpu
GPU_IMAGE=determinedai/environments:cuda-10-py-3.6.9-pytorch-1.4-tf-1.14-gpu
CPU_IMAGE_VERSIONED=$(CPU_IMAGE)-$(VERSION)
GPU_IMAGE_VERSIONED=$(GPU_IMAGE)-$(VERSION)

build:
	docker build -f Dockerfile.cpu \
		-t $(DOCKER_REGISTRY)$(CPU_IMAGE) \
		-t $(DOCKER_REGISTRY)$(CPU_IMAGE_VERSIONED) \
		.
	docker build -f Dockerfile.gpu \
		-t $(DOCKER_REGISTRY)$(GPU_IMAGE) \
		-t $(DOCKER_REGISTRY)$(GPU_IMAGE_VERSIONED) \
		.

publish:
	docker push $(DOCKER_REGISTRY)$(CPU_IMAGE)
	docker push $(DOCKER_REGISTRY)$(CPU_IMAGE_VERSIONED)
	docker push $(DOCKER_REGISTRY)$(GPU_IMAGE)
	docker push $(DOCKER_REGISTRY)$(GPU_IMAGE_VERSIONED)

release: PART?=patch
release:
	bumpversion --current-version $(VERSION) $(PART)
