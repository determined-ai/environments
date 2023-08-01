#!/usr/bin/env bash

set -e

if [ "$APEX_GIT" ]; then
  pip install \
      -v \
      --disable-pip-version-check \
      --no-cache-dir \
      --no-build-isolation \
      --global-option="--cpp_ext" \
      --global-option="--cuda_ext" \
      git+$APEX_GIT
fi
