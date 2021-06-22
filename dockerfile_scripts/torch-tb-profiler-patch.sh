#!/usr/bin/env bash

set -e

if [ "$TORCH_PROFILER_GIT" ]; then
  TORCH_PROFILER_DIR=/tmp/kineto
  TORCH_TB_PROFILER_VER="v0.2.0"
  git clone "$TORCH_PROFILER_GIT" "$TORCH_PROFILER_DIR"
  pushd "$TORCH_PROFILER_DIR"/tb_plugin
  git checkout "$TORCH_TB_PROFILER_VER"
  git apply /tmp/det_dockerfile_scripts/torch_tb_profiler_patch.patch
  pip install .
  popd
fi