#!/usr/bin/env bash

set -x

PKG_URL="http://archive.ubuntu.com/ubuntu/pool/main/libf/libffi"
FIXED_FFI_PKG="libffi7_3.3-4_amd64.deb"

# Install fixed version of libffi
mkdir -p /tmp/ffi && \
    cd /tmp/ffi && \
    wget "$PKG_URL/$FIXED_FFI_PKG" && \
    cd / && \
    dpkg -i /tmp/ffi/$FIXED_FFI_PKG && \
    rm -rf /tmp/ffi


