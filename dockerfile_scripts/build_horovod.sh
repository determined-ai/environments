#!/bin/bash

# Try and build a version of Horovod that works with c++-17, which is
# required by the latest PyTorch
export CUDA_HOME=/usr/local/cuda-12
export HOROVOD_WITHOUT_GLOO=1
export HOROVOD_CUDA_HOME=/usr/local/cuda
export HOROVOD_NCCL_LINK=SHARED
export HOROVOD_GPU_OPERATIONS=NCCL
export HOROVOD_WITH_MPI=1
#export HOROVOD_WITH_PYTORCH=1
#export HOROVOD_WITHOUT_TENSORFLOW=1
export HOROVOD_WITH_PYTORCH=$1
export HOROVOD_WITH_TENSORFLOW=$2
export HOROVOD_WITHOUT_MXNET=1
pip install --no-cache-dir git+https://github.com/thomas-bouvier/horovod.git@compile-cpp17

