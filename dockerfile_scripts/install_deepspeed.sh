#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev
if [ "$DEEPSPEED_PIP" ]; then
    python -m  pip install ninja psutil packaging attrdict
    DS_BUILD_OPS=1 python -m  pip install $DEEPSPEED_PIP
fi
