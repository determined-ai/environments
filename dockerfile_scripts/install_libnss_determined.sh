#!/usr/bin/env bash

set -e

# Add a plugin to the user system that lets us extend the users available in
# the container at runtime. This is critical for supporting non-root shell,
# which in turn is critical for non-root distributed training.
#
# By default, the NSS plugin is placed last, which means it won't override any
# settings present in the container's /etc/passwd.  However, if `--first` is
# passed to the script, the NSS plugin is placed first.  This is necessary when
# another system would conflict with Determined's system requirements.  An
# example is OpenShift 4.+ [1].
#
# [1] https://cloud.redhat.com/blog/a-guide-to-openshift-and-uids "By default,
# OpenShift 4.x appends the effective UID into /etc/passwd of the Container
# during the creation of the Pod."

make -C /tmp/det_dockerfile_scripts/libnss_determined libnss_determined.so.2 install

if [ "$1" = "--first" ]; then
    sed -i -E -e '
        /^(passwd|group|shadow):/{
            s/[ \t]determined//;
            s/:/: determined/;
        }' /etc/nsswitch.conf
else
    sed -E -i -e 's/^((passwd|shadow|group):.*)/\1 determined/' /etc/nsswitch.conf
fi
