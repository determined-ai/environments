#!/usr/bin/env bash

set -e

PYTHON_VERSION=${1}
ARCHITECTURE=${2:-linux/amd64}

CONDA_DIR="/opt/conda"

if [[ "$ARCHITECTURE" == "linux/amd64" ]]; then
  CONDA_INSTALLER="Miniconda3-py39_4.10.3-Linux-x86_64.sh"
  CONDA_MD5="8c69f65a4ae27fb41df0fe552b4a8a3b"
  CONDA_URL="https://repo.anaconda.com/miniconda"
elif [[ "$ARCHITECTURE" == "linux/arm64" ]]; then
  CONDA_INSTALLER="Miniforge3-4.10.3-10-Linux-aarch64.sh"
  CONDA_MD5="85d7ea630bb91259bf09f6d52a5ec1c4"
  CONDA_URL="https://github.com/conda-forge/miniforge/releases/download/4.10.3-10"
else
  echo "Unsupported architecture $ARCHITECTURE"
fi

mkdir -p /etc/determined/conda.d
mkdir -p "${CONDA_DIR}"

cd /tmp
curl --retry 3 -fsSL -O "${CONDA_URL}/${CONDA_INSTALLER}"
echo "${CONDA_MD5}  ${CONDA_INSTALLER}" | md5sum -c -
bash "./${CONDA_INSTALLER}" -u -b -p "${CONDA_DIR}"
rm -f "./${CONDA_INSTALLER}"

conda install python=${PYTHON_VERSION}
conda update --prefix ${CONDA_DIR} --all -y
conda clean --all -f -y
