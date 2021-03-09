#!/usr/bin/env bash

set -e

# Add a det-nobody user. Unlike the traditional nobody user, det-nobody will
# have a HOME directory that exists in order to support tools which require a
# home directory, like gsutil. det-nobody is designed to be an out-of-the-box
# solution for running workloads in unprivileged containers.
groupadd --gid 65533 det-nobody
useradd --shell /bin/bash \
    --create-home --home-dir /tmp/det-nobody \
    --uid 65533 --gid 65533 \
    det-nobody
