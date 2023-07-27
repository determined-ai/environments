#!/usr/bin/env bash

set -e

PYTHON_VERSION=${1}
ARCHITECTURE=${2:-linux/amd64}

CONDA_DIR="/opt/conda"

if [[ "$ARCHITECTURE" == "linux/amd64" ]]; then
  CONDA_INSTALLER="Miniconda3-py39_23.5.2-0-Linux-x86_64.sh"
  CONDA_SHA256="9829d95f639bd0053b2ed06d1204e60644617bf37dd5cc57523732e0e8d64516"
  CONDA_URL="https://repo.anaconda.com/miniconda"
elif [[ "$ARCHITECTURE" == "linux/arm64" ]]; then
  CONDA_INSTALLER="Mambaforge-23.1.0-4-Linux-aarch64.sh"
  CONDA_SHA256="95c354268f62e32d57c84f2e1a0caf9b19f77c894ecc83008db0e5e666ce3d43"
  CONDA_URL="https://github.com/conda-forge/miniforge/releases/download/23.1.0-4"
else
  echo "Unsupported architecture $ARCHITECTURE"
fi

mkdir -p /etc/determined/conda.d
mkdir -p "${CONDA_DIR}"

cd /tmp
curl --retry 3 -fsSL -O "${CONDA_URL}/${CONDA_INSTALLER}"
echo "${CONDA_SHA256}  ${CONDA_INSTALLER}" | sha256sum ${CONDA_INSTALLER}
bash "./${CONDA_INSTALLER}" -u -b -p "${CONDA_DIR}"
rm -f "./${CONDA_INSTALLER}"

conda install python=${PYTHON_VERSION}
conda update --prefix ${CONDA_DIR} --all -y
conda clean --all -f -y
