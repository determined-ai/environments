#!/usr/bin/env bash

set -e

apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev

#Older versions of deepspeed require pinned pydantic version
python -m pip install pydantic==1.10.11

#Precompile supported deepspeed ops except sparse_attn
export DS_BUILD_OPS=1
export DS_BUILD_SPARSE_ATTN=0
export DS_BUILD_EVOFORMER_ATTN=0
export DS_BUILD_CUTLASS_OPS=0
export DS_BUILD_RAGGED_DEVICE_OPS=0

#Remove 5.2 from TORCH_CUDA_ARCH_LIST, it is no longer supported by deepspeed
export TORCH_CUDA_ARCH_LIST=`echo $TORCH_CUDA_ARCH_LIST|sed 's/5.2 //'`
python -m pip install $DEEPSPEED_PIP --no-binary deepspeed
python -m deepspeed.env_report
