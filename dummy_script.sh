docker build  -f Dockerfile.gpu \
		--build-arg PYTHON_VERSION="3.7.10" \
		--build-arg BASE_IMAGE="nvidia/cuda:11.1-cudnn8-devel-ubuntu18.04" \
		--build-arg TF_CUDA_SYM="1" \
		--build-arg TENSORFLOW_PIP="tensorflow==2.4.2" \
		--build-arg TORCH_PIP="torch==1.9.0 -f https://download.pytorch.org/whl/cu111/torch_stable.html" \
		--build-arg TORCHVISION_PIP="torchvision==0.10.0 -f https://download.pytorch.org/whl/cu111/torch_stable.html" \
		--build-arg LIGHTNING_PIP="pytorch_lightning==1.3.5" \
		--build-arg TORCH_CUDA_ARCH_LIST="3.7;6.0;6.1;6.2;7.0;7.5;8.0" \
		--build-arg APEX_GIT="https://github.com/NVIDIA/apex.git@b5eb38dbf7accc24bd872b3ab67ffc77ee858e62" \
		--build-arg HOROVOD_PIP="horovod==0.22.1" \
		-t registry/whatever \
		.
