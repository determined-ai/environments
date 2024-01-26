#!/usr/bin/env bash

set -e

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev

# Install some dependencies for the LLM test
pip install accelerate==0.22.0 arrow==1.2.3 datasets==2.14.5 huggingface-hub==0.17.3 packaging==23.1 safetensors==0.3.3 setuptools==65.7.0 tokenizers==0.14.1 transformers==4.34.1 xxhash==3.3.0 evaluate
#Precompile deepspeed ops except sparse_attn which has dubious support
# Skip precompiling since this fails when using the NGC base image.
# Need to verify that DS can use NCCL correctly for the comms, etc.
#export DS_BUILD_OPS=1
export DS_BUILD_SPARSE_ATTN=0
export DS_BUILD_EVOFORMER_ATTN=0
cuda_ver_str=`echo $CUDA_VERSION | awk -F "." '{print $1"."$2}'`
#export CUDA_DIR="/usr/local/cuda-$cuda_ver_str/targets/sbsa-linux"
#export CUDA_HOME="/usr/local/cuda-$cuda_ver_str/targets/sbsa-linux"
#export CUDA_DIR="/usr/local/cuda-$cuda_ver_str/targets/sbsa-linux"
export CUDA_DIR="/usr/local/cuda-$cuda_ver_str/targets/x86_64-linux"
#export CUDA_HOME="/usr/local/cuda-12.2/compat"
#Remove 5.2 from TORCH_CUDA_ARCH_LIST, it is no longer supported by deepspeed
export TORCH_CUDA_ARCH_LIST=`echo $TORCH_CUDA_ARCH_LIST|sed 's/5.2 //'`
#python -m pip install $DEEPSPEED_PIP --no-binary deepspeed

git clone https://github.com/EleutherAI/gpt-neox.git
pip install -r gpt-neox/requirements/requirements.txt
python -m deepspeed.env_report
pip install -r gpt-neox/requirements/requirements-wandb.txt
pip install -r gpt-neox/requirements/requirements-tensorboard.txt
MAX_JOBS=16 pip install -r gpt-neox/requirements/requirements-flashattention.txt
#pip install -r gpt-neox/requirements/requirements-sparseattention.txt
python gpt-neox/megatron/fused_kernels/setup.py install
