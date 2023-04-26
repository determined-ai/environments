#!/usr/bin/env bash

set -e

DEBIAN_FRONTEND=noninteractive apt-get install -y pdsh libaio-dev
# Not building sparse attn operation which depends on a very old version of triton
DS_BUILD_OPS=1 DS_BUILD_SPARSE_ATTN=0 python -m pip install $DEEPSPEED_PIP --no-binary deepspeed
python -m deepspeed.env_report

if [[ "$DEEPSPEED_PIP" == *"determined2"* ]]; then
    # Build gpt-neox and dependencies when we install the gpt-neox version of deepspeed.
    # Triton is needed for flash attn
    python -m pip install triton==2.0.0.dev20221202
    # This is a dependency of gpt-neox
    apt-get install -y mpich
    # Need this to avoid `AttributeError: module 'distutils' has no attribute 'version'` when importing tensorboard. See https://github.com/pytorch/pytorch/issues/69894.
    pip install setuptools==59.5.0
    # Install gpt-neox and dependencies
    git clone -b determined2 https://github.com/determined-ai/gpt-neox.git
    python gpt-neox/megatron/fused_kernels/setup.py install
    
    # Exclude DeeperSpeed reinstall since the version in requirements is not pinned.
    pip install $(grep -ivE "DeeperSpeed" gpt-neox/requirements/requirements.txt)
    pip install -r /gpt-neox/requirements/requirements-flashattention.txt

    # Download sample data
    gsutil cp -r gs://determined-ai-public-datasets/text_data /gpt-neox && mv /gpt-neox/text_data /gpt-neox/data

    # Modify permissions to enable example to run in nonroot mode
    chmod -R 777 /gpt-neox
    chmod -R 777 /tmp
fi
