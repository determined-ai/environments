#!/usr/bin/env bash

set -x

GDR_VER=2.3
GDR_URL="https://github.com/NVIDIA/gdrcopy/archive/refs/tags"
GDR_TARBALL="v$GDR_VER.tar.gz"
cuda_ver_str=`echo $CUDA_VERSION | awk -F "." '{print $1"."$2}'`
echo "cuda_ver_str: $cuda_ver_str"
# Clone the GDRCopy github and compile it to build the deb packages. Note
# that we only build the libgdrapi* stuff and don't do the kernel mods, etc
# since we're running in a container. This is done just to satisfy linker
# requirements for some libraries (e.g., libfabric) and the AWS plugin
cd /tmp   && \
    wget $GDR_URL/$GDR_TARBALL && \
    tar zxf $GDR_TARBALL && \
    cd gdrcopy-$GDR_VER  && \
    CUDA=/usr/local/cuda-$cuda_ver_str/targets/x86_64-linux \
       ./packages/build-deb-packages.sh -t -k -d && \
    cd / && \
    dpkg -i \
        /tmp/gdrcopy-$GDR_VER/libgdrapi_$GDR_VER-1_amd64.*.deb && \
    rm -rf /tmp/gdrcopy-$GDR_VER /tmp/$GDR_TARBALL

