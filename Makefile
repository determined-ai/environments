.PHONY: build publish

DOCKER_REGISTRY ?= ""

CPU_IMAGE=determinedai/environments:py-3.6.9-pytorch-1.4-tf-1.14-cpu
GPU_IMAGE=determinedai/environments:cuda-10-py-3.6.9-pytorch-1.4-tf-1.14-gpu

build:
	docker build -f Dockerfile.cpu -t $(DOCKER_REGISTRY)$(CPU_IMAGE) .
	docker build -f Dockerfile.gpu -t $(DOCKER_REGISTRY)$(GPU_IMAGE) .

publish:
	docker push $(DOCKER_REGISTRY)$(CPU_IMAGE)
	docker push $(DOCKER_REGISTRY)$(GPU_IMAGE)
