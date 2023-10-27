#!/bin/bash

# Only scrape host libs if AWS/NCCL/OFI was built for this image
if [ -d /container/aws/lib ]
then
   # See if we mounted in host libs in the expected location
   host_dir="/host"
   if [ -d "$host_dir" ]; then
       libfabric=`find /host -name libfabric.so 2>/dev/null`
       libfabric_dir="$(dirname "$libfabric")"
       if [[ ! -z "$libfabric" ]] ; then
           # Need libfabric to be first in the LD_LIBRARY_PATH to
           # override what is in the container. However, we likely
           # need/want the libs that it is dependent upon to show up
           # after the container ones so we append the rest of the
           # host libs.  tmp_dir="`pwd`/tmp"
           tmp_dir="/var/tmp"
           tmp_lib_dir="$tmp_dir/$(whoami)/detAI/lib"
           mkdir -p $tmp_lib_dir
           for lib in `/bin/ls $libfabric_dir/ | grep libfabric` ; do
               ln -s $libfabric_dir/$lib $tmp_lib_dir 2>/dev/null
           done
           # Prepend the tmp dir for the host libfabric
           export LD_LIBRARY_PATH=$tmp_lib_dir:$LD_LIBRARY_PATH
           # Append the rest of the host lib dirs to try and avoid
           # problems with libs in the container. Note we might want
           # to set these paths based on where we find the libs that
           # libfabric is dependent upon.
           export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$libfabric_dir
           export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/host/usr/lib64
           export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/host/usr/local/lib64
       fi # end if found libfabric.so
   fi # end if /host exists
   export LD_LIBRARY_PATH=/container/aws/lib:$LD_LIBRARY_PATH

   tmp_nvcache_dir=$(mktemp -d -p /var/tmp $(whoami)-nvcache-XXXXXXXX)

   # The following env variables are only set if they are curretly unset,empty or null
   # To override one or more of these variales, simply set them prior to the enrtrypoint
   # of this image
   export CUDA_CACHE_PATH=${CUDA_CACHE_PATH:=${tmp_nvcache_dir}}

   export TF_FORCE_GPU_ALLOW_GROWTH=${TF_FORCE_GPU_ALLOW_GROWTH:=true}

   # NOTE: Disable memory registration to workaround the current issues
   #       between libfabric and cuda.  When those issus are resolved,
   #       simply set the vaiable to 0 before launching the container.
   export FI_CXI_DISABLE_HOST_REGISTER=${FI_CXI_DISABLE_HOST_REGISTER:=1}

   # NOTE: Workaround a potential hang between OMPI and libfabric
   export FI_MR_CACHE_MONITOR=userfaultfd

   if [ -r /usr/lib/x86_64-linux-gnu/libp11-kit.so.0 ]
   then
      export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libp11-kit.so.0:$LD_PRELOAD
   fi
   if [ -r /usr/lib/x86_64-linux-gnu/libffi.so.7 ]
   then
      export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libffi.so.7:$LD_PRELOAD
   fi

fi
# Execute what we were told to execute
exec "${@}"
