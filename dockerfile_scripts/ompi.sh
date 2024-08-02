#!/bin/bash

set -x

# See if we should add CUDA to the OMPI build
OMPI_WITH_CUDA=""
if [ $# -gt 2 ] ; then
    if [ "$3" = "1" ] ; then
	# Tell OMPI to look for cuda in the default location
	OMPI_WITH_CUDA="--with-cuda"
    fi
fi

OS_VER=$1
OFI=$2
# Install OFI
OFI_VER=1.18.1
OFI_CONFIG_OPTIONS="--prefix ${OFI_INSTALL_DIR}"
OFI_SRC_DIR=/tmp/ofi-src
OFI_BASE_URL="https://github.com/ofiwg/libfabric/releases/download"
OFI_URL="${OFI_BASE_URL}/v${OFI_VER}/libfabric-${OFI_VER}.tar.bz2"

mkdir -p ${OFI_SRC_DIR}                              && \
    cd ${OFI_SRC_DIR}                                  && \
    wget ${OFI_URL}                                    && \
    tar -xf libfabric-${OFI_VER}.tar.bz2 --no-same-owner             && \
    cd libfabric-${OFI_VER}                            && \
    ./configure ${OFI_CONFIG_OPTIONS}                  && \
    make install                                       && \
    cd /tmp                                            && \
    rm -rf ${OFI_SRC_DIR}

#OMPI CONFIG ARGS FOR OFI
OMPI_CONFIG_OPTIONS_VAR="--prefix ${OMPI_INSTALL_DIR} --enable-orterun-prefix-by-default --enable-shared --with-cma --with-pic --enable-mpi-cxx --enable-mpi-thread-multiple --with-libfabric=${OFI_INSTALL_DIR} --without-ucx --with-pmi --with-pmix=internal ${OMPI_WITH_CUDA}"

# Install OMPI
OMPI_VER=v4.1
OMPI_VER_NUM=4.1.0
OMPI_CONFIG_OPTIONS=${OMPI_CONFIG_OPTIONS_VAR}
OMPI_SRC_DIR=/tmp/openmpi-src
OMPI_BASE_URL="https://download.open-mpi.org/release/open-mpi"
OMPI_URL="${OMPI_BASE_URL}/${OMPI_VER}/openmpi-${OMPI_VER_NUM}.tar.gz"

mkdir -p ${OMPI_SRC_DIR}                        && \
  cd ${OMPI_SRC_DIR}                            && \
  wget ${OMPI_URL}                              && \
  tar -xzf openmpi-${OMPI_VER_NUM}.tar.gz       && \
  cd openmpi-${OMPI_VER_NUM}                    && \
  ./configure ${OMPI_CONFIG_OPTIONS}            && \
  make                                          && \
  make install                                  && \
  cd /tmp                                       && \
  rm -rf ${OMPI_SRC_DIR}
