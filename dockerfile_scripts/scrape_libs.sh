#!/bin/bash

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
        tmp_dir="/tmp"
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
else
    echo "INFO: $host_dir not present, check srun for --bind /usr:$host_dir/usr"
fi # end if /host exists

if [ -d /container/aws/lib ]
then
    export LD_LIBRARY_PATH=/container/aws/lib:$LD_LIBRARY_PATH
fi
# Execute what we were told to execute
exec "${@}"
