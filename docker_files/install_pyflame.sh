#!/usr/bin/env bash

set -e

# Stock pyflame writes stack traces only at the end of the sampling period.
# Patch pyflame to have a new option that periodically dumps stack traces to
# facilitate profiling long running programs.

mkdir -p /build
cd /build
curl -fsSL https://github.com/uber/pyflame/archive/v1.6.7.tar.gz | tar xzvf -
cd /build/pyflame-1.6.7
patch -p1 < /tmp/det_docker_files/profiler/pyflame-add-output-rate.patch
patch -p1 < /tmp/det_docker_files/profiler/pyflame-fix-for-conda.patch
./autogen.sh

# TODO parameterize Python locations
PY36_CFLAGS="-I${PYTHON_INCLUDE}/python${PYTHON_VERSION}m" \
PY36_LIBS="-L${PYTHON_LIB} -lpython${PYTHON_VERSION}m" \
    ./configure
make install
