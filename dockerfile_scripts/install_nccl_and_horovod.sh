#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y libnccl-dev libnccl2 --no-install-recommends

git clone https://github.com/determined-ai/nccl.git /tmp/det_nccl
(cd /tmp/det_nccl && git checkout -q 8768cb3f881ce198825294b62a435e3f3a804baf)
make -C /tmp/det_nccl -j 4
ldconfig /usr/local/cuda/targets/x86_64-linux/lib/stubs 
pip install git+https://github.com/determined-ai/horovod.git@82b1458d5c6d787180dbca60a5a177b2aabddb59
ldconfig
rm -rf /tmp/det_nccl
