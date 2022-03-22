#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev
# Triton is needed to build deepspeed's sparse_attn operation.
pip install triton==1.0.0
DS_BUILD_OPS=1 pip install $DEEPSPEED_PIP
