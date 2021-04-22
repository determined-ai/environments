#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y "libnccl-dev=$NCCL_VERSION" "libnccl2=$NCCL_VERSION" --no-install-recommends
ldconfig /usr/local/cuda/targets/x86_64-linux/lib/stubs
pip install "$HOROVOD_PIP"
ldconfig
