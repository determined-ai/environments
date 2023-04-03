#!/bin/bash

set -x

WITH_AWS_TRACE=""
if [ $# -gt 1 ] ; then
    if [ "$2" = "1" ] ; then
	# Tell AWS to build with trace messages enabled
	WITH_AWS_TRACE="--enable-trace"
    fi
fi
OFI=$1

env|grep -i nccl

if [ "$OFI" = "1" ]; then
  # Install AWS_OFI_NCCL
  AWS_VER=v1.4.0
  AWS_VER_NUM=1.4.0
  AWS_NAME=aws-ofi-nccl
  AWS_FILE="${AWS_NAME}-${AWS_VER_NUM}"
  # cuda install dir likely dependent on BaseOS (i.e. ubuntu 20.02)
  # in case this changes in the future
  cuda_ver_str=`echo $CUDA_VERSION | awk -F "." '{print $1"."$2}'`
  CUDA_DIR="/usr/local/cuda-$cuda_ver_str/targets/x86_64-linux"
  GDRCOPY_HOME="/usr"

  AWS_CONFIG_OPTIONS="--prefix ${AWS_PLUGIN_INSTALL_DIR} \
	  --with-libfabric=${OFI_INSTALL_DIR}            \
	  --with-nccl=${HOROVOD_NCCL_HOME}               \
	  --with-mpi=${OMPI_INSTALL_DIR}                 \
	  --with-gdrcopy=${GDRCOPY_HOME}                 \
	  --with-cuda=${CUDA_DIR} ${WITH_AWS_TRACE}"
  AWS_SRC_DIR=/tmp/aws-ofi-nccl
  AWS_BASE_URL="https://github.com/aws/aws-ofi-nccl/archive/refs/tags"
  AWS_URL="${AWS_BASE_URL}/${AWS_VER}.tar.gz"
  # The INTERNAL_DATASERVER variable must exist in the env
  INTERNAL_DS="http://set.to.your.server.name"
  INTERNAL_DS_NCCL_PATH="/set/to/nccl/tarball/path"
  INTERNAL_DS="cflhal01.us.cray.com"
  INTERNAL_DS_NCCL_PATH="/build_files/nccl"
  AWS_BASE_URL="http://${INTERNAL_DS}${INTERNAL_DS_NCCL_PATH}"
  AWS_URL="${AWS_BASE_URL}/${AWS_NAME}.tar.gz"

  mkdir -p ${AWS_SRC_DIR}                         && \
    cd ${AWS_SRC_DIR}                             && \
    #    wget -O "${AWS_FILE}.tar.gz" ${AWS_URL}       && \
    #    tar -xzf ${AWS_FILE}.tar.gz                   && \
    #    cd ${AWS_FILE}                                && \
    wget -O ${AWS_NAME}.tar.gz ${AWS_URL}         && \
    tar -xzf ${AWS_NAME}.tar.gz                   && \
    cd ${AWS_NAME}                                && \
    ./autogen.sh                                  && \
    ./configure ${AWS_CONFIG_OPTIONS}             && \
    make                                          && \
    make install                                  && \
    cd /tmp                                       && \
    rm -rf ${AWS_SRC_DIR}
fi
