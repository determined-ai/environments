#!/bin/bash

set -x

# Install OFI
OFI_VER=1.15.1
OFI_CONFIG_OPTIONS="--prefix ${OFI_INSTALL_DIR}"
OFI_SRC_DIR=/tmp/ofi-src
OFI_BASE_URL="https://github.com/ofiwg/libfabric/releases/download"
OFI_URL="${OFI_BASE_URL}/v${OFI_VER}/libfabric-${OFI_VER}.tar.bz2"

mkdir -p ${OFI_SRC_DIR}                              && \
  cd ${OFI_SRC_DIR}                                  && \
  wget ${OFI_URL}                                    && \
  tar -xf libfabric-${OFI_VER}.tar.bz2               && \
  cd libfabric-${OFI_VER}                            && \
  ./configure ${OFI_CONFIG_OPTIONS}                  && \
  make install                                       && \
  cd /tmp                                            && \
  rm -rf ${OFI_SRC_DIR}
