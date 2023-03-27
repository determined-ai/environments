#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev
# Triton is needed to build deepspeed's sparse_attn operation.
python -m pip install triton==1.0.0
$DEEPSPEED_OPS=1 python -m pip install $DEEPSPEED_PIP --no-binary deepspeed
python -m deepspeed.env_report
