#!/usr/bin/env bash

set -e

apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev

#Older versions of deepspeed require pinned pydantic version
python -m pip install pydantic==1.10.11 ninja cmake

#Precompile supported deepspeed ops except sparse_attn
export DS_BUILD_OPS=1
export DS_BUILD_AIO=0
export DS_BUILD_SPARSE_ATTN=0
export DS_BUILD_EVOFORMER_ATTN=0
export DS_BUILD_CUTLASS_OPS=0
export DS_BUILD_CCL_COMM=0

python -m pip install $DEEPSPEED_PIP --no-binary deepspeed
python -m deepspeed.env_report
