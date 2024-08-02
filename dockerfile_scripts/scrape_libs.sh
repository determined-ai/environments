#!/bin/bash

WHOAMI=$(whoami)
# Only scrape host libs if AWS/NCCL/OFI was built for this image
if [ -d /container/aws/lib ]
#if [ -d /container/lib ]
then
   host_dir="/det_libfabric"
   if [ ! -d "$host_dir" ]; then
     host_dir="/det_host"
     if [ ! -d "$host_dir" ]; then
       host_dir="/host"
     fi
   fi
   if [ -d "$host_dir" ]; then
       libfabric=`find $host_dir -name libfabric.so 2>/dev/null`
       libfabric_dir="$(dirname "$libfabric")"
       if [[ ! -z "$libfabric" ]] ; then
           # Need libfabric to be first in the LD_LIBRARY_PATH to
           # override what is in the container. However, we likely
           # need/want the libs that it is dependent upon to show up
           # after the container ones so we append the rest of the
           # host libs.  tmp_dir="`pwd`/tmp"
           tmp_dir="/var/tmp"
           tmp_lib_dir="$tmp_dir/${WHOAMI}/detAI/lib"
           mkdir -p $tmp_lib_dir
           for lib in `/bin/ls $libfabric_dir/ | grep -elibfabric -ecxi` ; do
               ln -s $libfabric_dir/$lib $tmp_lib_dir 2>/dev/null
           done
           # Prepend the tmp dir for the host libfabric
           export LD_LIBRARY_PATH=$tmp_lib_dir:$LD_LIBRARY_PATH
           # Append the rest of the host lib dirs to try and avoid
           # problems with libs in the container. Note we might want
           # to set these paths based on where we find the libs that
           # libfabric is dependent upon.
           export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$libfabric_dir
       else 
	       echo "libfabric not found within $host_dir." >&2
       fi # end if found libfabric.so
   else echo "no suitable mounts available." >&2
   fi # end if /det_libfabric exists
   # See if we mounted in host libs in the expected location

   host_dir="/det_host"
   if [ ! -d "$host_dir" ]; then
   	host_dir="/host"
   fi
   if [ -d "$host_dir" ]; then
       # to set these paths based on where we find the libs that
       # libfabric is dependent upon.
       export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$host_dir/usr/lib64
       export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$host_dir/usr/local/lib64
   fi # end if /det_host exists
   export LD_LIBRARY_PATH=/container/aws/lib:$LD_LIBRARY_PATH
#   export LD_LIBRARY_PATH=/container/lib:$LD_LIBRARY_PATH

   tmp_nvcache_dir=$(mktemp -d -p /var/tmp ${WHOAMI}-nvcache-XXXXXXXX)

   # The following env variables are only set if they are curretly unset,empty or null
   # To override one or more of these variales, simply set them prior to the enrtrypoint
   # of this image
   export CUDA_CACHE_PATH=${CUDA_CACHE_PATH:=${tmp_nvcache_dir}}

   export TF_FORCE_GPU_ALLOW_GROWTH=${TF_FORCE_GPU_ALLOW_GROWTH:=true}

   # NOTE: Disable memory registration to workaround the current issues
   #       between libfabric and cuda.  When those issus are resolved,
   #       simply set the vaiable to 0 before launching the container.
   export FI_CXI_DISABLE_HOST_REGISTER=${FI_CXI_DISABLE_HOST_REGISTER:=1}

   if [ -r /usr/lib/x86_64-linux-gnu/libp11-kit.so.0 ]
   then
      export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libp11-kit.so.0:$LD_PRELOAD
   fi
   if [ -r /usr/lib/x86_64-linux-gnu/libffi.so.7 ]
   then
      export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libffi.so.7:$LD_PRELOAD
   fi
# Execute what we were told to execute

   if [ "$WITH_RCCL" = "1" ]; then
      #export LD_LIBRARY_PATH=/scratch2/${WHOAMI}/lib/libfabric-1.21.1:/scratch2/${WHOAMI}/lib:/container/aws/lib:$LD_LIBRARY_PATH
      #export LD_LIBRARY_PATH=/scratch2/${WHOAMI}/lib/libfabric-1.21.1:/scratch2/${WHOAMI}/lib:$LD_LIBRARY_PATH

      export TF_FORCE_GPU_ALLOW_GROWTH=true
      export CUDA_CACHE_PATH=/tmp/${WHOAMI}.nvcache
      export FI_CXI_COMPAT=0
      export NCCL_SOCKET_IFNAME="hsn0"
      #export FI_CXI_DISABLE_HOST_REGISTER=1
      export CUDA_VISIBLE_DEVICES="0,1,2,3"

      export FI_CXI_DEFAULT_TX_SIZE=1024
      export FI_CXI_DISABLE_CQ_HUGETLB=1
      export FI_CXI_DEFAULT_CQ_SIZE=131072
      export FI_CXI_DISABLE_HOST_REGISTER=1
      export FI_CXI_RX_MATCH_MODE=software
      export FI_CXI_RDZV_PROTO=alt_read
      export FI_PROVIDER=^ofi_rxm,efa,ofi_rxd
      export FI_HMEM_CUDA_USE_GDRCOPY=1
      export FI_CXI_REQ_BUF_SIZE=8338608
      export FI_LOG_PROV=cxi
      export FI_LOG_LEVEL=info
      export FI_LOG_SUBSYS=domain
      export FI_CXI_TELEMENTRY=pct_no_mst_nacks,pct_mst_hit_on_som,pct_sct_timeouts,pct_spt_timeouts,pct_tct_timeouts

      export CXI_FORK_SAFE=1
      export FI_EFA_FORK_SAFE=${CXI_FORK_SAFE}
      # Avoid hang with NCCL/RCCL and libfabric
      export FI_MR_CACHE_MONITOR=userfaultfd

      export NCCL_DEBUG=TRACE
      export RCCL_DEBUG=${NCCL_DEBUG}

      if [ "$WITH_NFS_WORKAROUND" = "1" ]; then
         export MIOPEN_USER_DB_PATH="/tmp/${WHOAMI}_${SLURM_LOCALID}"
         export MIOPEN_USER_CACHE_PATH="$MIOPEN_USER_DB_PATH/.cache"
         export MIOPEN_CACHE_DIR=${MIOPEN_USER_CACHE_PATH}
         echo "MIOPEN_USER_DB_PATH: $MIOPEN_USER_DB_PATH, cache dir: $MIOPEN_USER_CACHE_PATH"
         mkdir -p $MIOPEN_USER_DB_PATH
         mkdir -p $MIOPEN_USER_CACHE_PATH/miopen
         export HOME=${MIOPEN_USER_DB_PATH}

      fi
   fi
fi
exec "${@}"
