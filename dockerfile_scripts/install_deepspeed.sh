#!/usr/bin/env bash

set -e

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev
#Precompile deepspeed ops except sparse_attn which has dubious support
DS_BUILD_OPS=1 DS_BUILD_SPARSE_ATTN=0
#Remove 5.2 from TORCH_CUDA_ARCH_LIST, it is no longer supported by deepspeed
export TORCH_CUDA_ARCH_LIST=|echo $TORCH_CUDA_ARCH_LIST|sed 's/5.2 //'
TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0 7.5 8.0 8.6 9.0+PTX"
python -m pip install $DEEPSPEED_PIP --no-binary deepspeed
python -m deepspeed.env_report
