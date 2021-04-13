#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y libnccl-dev libnccl2 --no-install-recommends

pip install horovod
ldconfig
