#!/usr/bin/env bash

set -e

if [ "$APEX_GIT" ]; then
    pip install \
        --global-option="--cpp_ext" \
        --global-option="--cuda_ext" \
        git+$APEX_GIT
fi
