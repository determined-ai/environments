#!/usr/bin/env bash

set -e

PYTHON_VERSION=${1}

CONDA_DIR="/opt/conda"
CONDA_INSTALLER="Miniconda3-4.7.10-Linux-x86_64.sh"
CONDA_MD5="1c945f2b3335c7b2b15130b1b2dc5cf4"
CONDA_URL="https://repo.continuum.io/miniconda"

mkdir -p /etc/determined/conda.d
mkdir -p "${CONDA_DIR}"

cd /tmp
curl --retry 3 -fsSL -O "${CONDA_URL}/${CONDA_INSTALLER}"
echo "${CONDA_MD5}  ${CONDA_INSTALLER}" | md5sum -c -
bash "./${CONDA_INSTALLER}" -u -b -p "${CONDA_DIR}"
rm -f "./${CONDA_INSTALLER}"

conda install python=${PYTHON_VERSION}
