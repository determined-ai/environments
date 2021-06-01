#!/usr/bin/env bash

set -e

if [ "$APEX_GIT" ]; then
  if [ "$APEX_PATCH" == 1 ]; then
    APEX_DIR=/tmp/apex/
    APEX_GIT_URL="${APEX_GIT%@*}"
    APEX_GIT_VER="${APEX_GIT#*@}"
    git clone "$APEX_GIT_URL" "$APEX_DIR"
    pushd "$APEX_DIR"
    git checkout "$APEX_GIT_VER"
    git apply /tmp/det_dockerfile_scripts/apex.patch
    popd
    pip install \
        --global-option="--cpp_ext" \
        --global-option="--cuda_ext" \
        "$APEX_DIR"
  else
    pip install \
        --global-option="--cpp_ext" \
        --global-option="--cuda_ext" \
        git+$APEX_GIT
  fi
fi
