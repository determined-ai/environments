#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y libnccl-dev libnccl2 --no-install-recommends

git clone https://github.com/nvidia/nccl.git /tmp/det_nccl
(cd /tmp/det_nccl && git checkout v2.9.6-1)
make -C /tmp/det_nccl -j 4
