#!/usr/bin/env bash

set -e

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev
# Triton==1.0.0 is needed to build deepspeed's sparse_attn operation.
# It also version pins deepspeed
python -m pip install $DEEPSPEED_PIP --no-binary deepspeed
python -m deepspeed.env_report
