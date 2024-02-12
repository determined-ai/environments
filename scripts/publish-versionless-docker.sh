#!/bin/sh

set -e
set -x

if [ "$#" -lt 3 ] || [ "$#" -gt 5 ] || [ "$#" -eq 5 ] && [ "$5" != "--no-push" ]; then
    echo "usage: $0 LOG_NAME BASE_TAG HASH ARTIFACTS_DIR [--no-push]" >&2
    exit 1
fi

log_name="$1"
base_tag="$2"
hash="$3"
artifacts="$4"

underscore_name="$(echo -n "$log_name" | tr - _)"

if [ "$#" -lt 5 ] ; then
    docker push "$base_tag:$hash"
fi

if [ -n "$artifacts" ]; then
    mkdir -p "$artifacts"

    log_file="$artifacts/publish-$log_name"
    (
        echo "${underscore_name}_hashed: $base_tag:$hash"
    ) > "$log_file"
fi
