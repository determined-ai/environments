#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev
DS_BUILD_OPS=1 pip install $DEEPSPEED_PIP
