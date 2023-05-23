#!/usr/bin/env bash

set -e

# Add a plugin to the user system that lets us extend the users available in
# the container at runtime. This is critical for supporting non-root shell,
# which in turn is critical for non-root distributed training.
#
# Also, to work around a behavior in OpenShift 4.+ [1], place `determined`
# NSS plug-in to be searched first instead of last so Determined-defined
# entries are used when there are conflicts with infrastructure-based
# entries in these identity databases: passwd, shadow, group.
#
# [1] https://cloud.redhat.com/blog/a-guide-to-openshift-and-uids "By default,
# OpenShift 4.x appends the effective UID into /etc/passwd of the Container
# during the creation of the Pod."

make -C /tmp/det_dockerfile_scripts/libnss_determined libnss_determined.so.2 install \
    && sed -i -E '
        /^(passwd|group|shadow):/{
            s/[ \t]determined//;
            s/:/: determined/;
        }' /etc/nsswitch.conf
