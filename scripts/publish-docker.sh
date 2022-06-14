#!/bin/sh

set -e
set -x

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ] ; then
    echo "usage: $0 LOG_NAME BASE_TAG HASH VERSION ARTIFACTS_DIR" >&2
    exit 1
fi

log_name="$1"
base_tag="$2"
hash="$3"
version="$4"
artifacts="$5"

underscore_name="$(echo -n "$log_name" | tr - _)"

platform="${log_name#*-}"

if [ "$platform" = "arm64" ]; then
    docker push "$base_tag-$hash-arm64v8"
    docker push "$base_tag-$version-arm64v8"
elif [ "$platform" = "amd64" ]; then
    docker push "$base_tag-$hash-amd64"
    docker push "$base_tag-$version-amd64"
elif [ "$platform" = "mp" ]; then
    docker manifest create "$base_tag-$hash" \
    --amend "$base_tag-$hash-arm64v8" \
    --amend "$base_tag-$hash-amd64"
    docker manifest push "$base_tag-$hash"
    docker manifest create "$base_tag-$version" \
    --amend "$base_tag-$version-arm64v8" \
    --amend "$base_tag-$version-amd64"
    docker manifest push "$base_tag-$version"
else
    docker push "$base_tag-$hash"
    docker push "$base_tag-$version"
fi

if [ -n "$artifacts" ]; then
    mkdir -p "$artifacts"

    log_file="$artifacts/publish-$log_name"
    (
        echo "${underscore_name}_hashed: $base_tag-$hash"
        echo "${underscore_name}_versioned: $base_tag-$version"
    ) > "$log_file"
fi
