#!/usr/bin/env bash

set -e

#DEBIAN_FRONTEND=noninteractive apt-get install -y libnccl-dev libnccl2 --no-install-recommends

export NVCC_GENCODE="-gencode=arch=compute_80,code=sm_80"

git clone https://github.com/nvidia/nccl.git /tmp/det_nccl

(cd /tmp/det_nccl && git checkout v2.19.3-1)

make PREFIX=${HOROVOD_NCCL_HOME} -C /tmp/det_nccl -j 4 install

