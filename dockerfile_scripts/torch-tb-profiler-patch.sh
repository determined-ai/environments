#!/usr/bin/env bash

set -e

if [ "$TORCH_PROFILER_GIT" ]; then
  TORCH_PROFILER_DIR=/tmp/kineto
  TORCH_TB_GIT_URL="${TORCH_PROFILER_GIT%@*}"
  TORCH_TB_GIT_VER="${TORCH_PROFILER_GIT#*@}"
  git clone "$TORCH_TB_GIT_URL" "$TORCH_PROFILER_DIR"
  pushd "$TORCH_PROFILER_DIR"/tb_plugin
  git checkout "$TORCH_TB_GIT_VER"
  git apply /tmp/det_dockerfile_scripts/torch_tb_profiler_patch.patch
  pip install .
  popd
fi