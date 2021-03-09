#!/usr/bin/env bash

set -e

# Add a plugin to the user system that lets us extend the users available in
# the container at runtime. This is critical for supporting non-root shell,
# which in turn is critical for non-root distributed training.
make -C /tmp/det_dockerfile_scripts/libnss_determined libnss_determined.so.2 install \
    && sed -E -i -e 's/^((passwd|shadow|group):.*)/\1 determined/' /etc/nsswitch.conf
