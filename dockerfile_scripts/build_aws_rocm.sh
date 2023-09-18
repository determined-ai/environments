#!/bin/bash

set -x

WITH_AWS_TRACE=""
if [ $# -gt 1 ] ; then
    if [ "$2" = "1" ] ; then
	# Tell AWS to build with trace messages enabled
	WITH_AWS_TRACE="--enable-trace"
    fi
    if [ $# -gt 2 ] ; then
        if [ "$3" = "1" ] ; then
	    WITH_MPICH=1;
        fi
    fi
fi

OFI=$1

if [ "$OFI" = "1" ]; then
  apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
                tcsh

  # Install AWS_OFI_NCCL
  AWS_VER=v1.4.0
  AWS_VER_NUM=1.4.0
  AWS_NAME=aws-ofi-rccl-cxi
  AWS_FILE="${AWS_NAME}-${AWS_VER_NUM}"
  # cuda install dir likely dependent on BaseOS (i.e. ubuntu 20.02)
  # in case this changes in the future

  cuda_ver_str=`echo $CUDA_VERSION | awk -F "." '{print $1"."$2}'`
  CUDA_DIR="/usr/local/cuda-$cuda_ver_str/targets/x86_64-linux"
  GDRCOPY_HOME="/usr"
  OFI_INSTALL_DIR=/container/ofi
  ls $OFI_INSTALL_DIR
  [ "$WITH_MPICH" = "1" ]&&MPI_INSTALL_DIR=${MPICH_INSTALL_DIR}||MPI_INSTALL_DIR=${OMPI_INSTALL_DIR}
  AWS_CONFIG_OPTIONS="--prefix ${AWS_PLUGIN_INSTALL_DIR} \
	  --with-libfabric=${OFI_INSTALL_DIR}            \
	  --with-rccl=${HOROVOD_NCCL_HOME}               \
	  --with-mpi=${MPI_INSTALL_DIR}                  \
	  --with-hip=${ROCM_DIR} ${WITH_AWS_TRACE}"

  AWS_SRC_DIR=/tmp/aws-ofi-rccl
  #AWS_BASE_URL="https://github.com/aws/aws-ofi-nccl/archive/refs/tags"
  AWS_BASE_URL="https://github.com/ROCmSoftwarePlatform/aws-ofi-rccl/archive/refs/heads/"
  #AWS_URL="${AWS_BASE_URL}/${AWS_VER}.tar.gz"
  AWS_URL="${AWS_BASE_URL}/cxi.zip"
  # The INTERNAL_AWS_DS variable must exist in the env
  ## INTERNAL_AWS_DS="http://set.to.your.server.name"
  ## INTERNAL_AWS_PATH="/set/to/aws/tarball/path"
  #if [ -z "$INTERNAL_AWS_DS" ]
  #then
  #  echo "Using EXTERNAL AWS $AWS_URL" 
    # aws-ofi-nccl-1.4.0
  #  AWS_NAME="${AWS_NAME}-${AWS_VER_NUM}"
  #else
  #  AWS_BASE_URL="http://${INTERNAL_AWS_DS}${INTERNAL_AWS_PATH}"
  #  AWS_URL="${AWS_BASE_URL}/${AWS_NAME}.tar.gz"
  #  echo "Using INTERNAL AWS $AWS_URL" 
  #fi

  mkdir -p ${AWS_SRC_DIR}                         && \
    cd ${AWS_SRC_DIR}                             && \
    git clone https://github.com/ROCmSoftwarePlatform/aws-ofi-rccl && \
    cd aws-ofi-rccl                               && \
    ./autogen.sh                                  && \
    CC=hipcc ./configure ${AWS_CONFIG_OPTIONS}    && \
    make                                          && \
    make install                                  && \
    cd /tmp                                       && \
    rm -rf ${AWS_SRC_DIR}
fi
