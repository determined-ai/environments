#!/bin/bash

export UCX_INSTALL_DIR=/container/ucx
export OMPI_INSTALL_DIR=/container/ompi
export MPICH_INSTALL_DIR=/container/mpich
export OFI_INSTALL_DIR=/container/ofi
export ROCM_DIR=/opt/rocm

# Make sure OMPI/UCX show up in the right paths
VERBS_LIB_DIR=/usr/lib/libibverbs
export UCX_LIB_DIR=${UCX_INSTALL_DIR}/lib:${UCX_INSTALL_DIR}/lib64
export UCX_PATH_DIR=${UCX_INSTALL_DIR}/bin
export OFI_LIB_DIR=${OFI_INSTALL_DIR}/lib:${OFI_INSTALL_DIR}/lib64
export OFI_PATH_DIR=${OFI_INSTALL_DIR}/bin
export OMPI_LIB_DIR=${OMPI_INSTALL_DIR}/lib
export OMPI_PATH_DIR=${OMPI_INSTALL_DIR}/bin
export MPICH_LIB_DIR=${MPICH_INSTALL_DIR}/lib
export MPICH_PATH_DIR=${MPICH_INSTALL_DIR}/bin

# Set up UCX_LIBS and OFI_LIBS
UCX_LIBS="${VERBS_LIB_DIR}:${UCX_LIB_DIR}:${OMPI_LIB_DIR}:"
OFI_LIBS="${VERBS_LIB_DIR}:${OFI_LIB_DIR}:${MPICH_LIB_DIR}:"

# If WITH_OFI is true, then set EXTRA_LIBS to OFI libs, else set to empty string
EXTRA_LIBS="${WITH_OFI:+${OFI_LIBS}}"

# If EXTRA_LIBS is empty, set to UCX libs, else leave as OFI libs
export EXTRA_LIBS="${EXTRA_LIBS:-${UCX_LIBS}}"

# But, only add them if WITH_MPI
LD_LIBRARY_PATH=${WITH_MPI:+$EXTRA_LIBS}$LD_LIBRARY_PATH

#USING OFI
PATH=${WITH_OFI:+$PATH:${WITH_MPI:+$OFI_PATH_DIR:$MPICH_PATH_DIR}}

#USING UCX
PATH=${PATH:-$CONDA:${WITH_MPI:+$UCX_PATH_DIR:$OMPI_PATH_DIR}}

export PATH=$OMPI_PATH_DIR:$OFI_INSTALL_DIR:$PATH

# Enable running OMPI as root
OMPI_ALLOW_RUN_AS_ROOT ${WITH_MPI:+1}
OMPI_ALLOW_RUN_AS_ROOT_CONFIRM ${WITH_MPI:+1}

export AWS_PLUGIN_INSTALL_DIR=/container/aws

export LD_LIBRARY_PATH=${WITH_OFI:+$AWS_PLUGIN_INSTALL_DIR:}$LD_LIBRARY_PATH
