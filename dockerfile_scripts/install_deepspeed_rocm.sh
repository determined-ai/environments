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

# clone AMD version of DeepSpeed
git clone https://github.com/ROCmSoftwarePlatform/DeepSpeed.git
cd DeepSpeed
python -m pip install .
python -m deepspeed.env_report
