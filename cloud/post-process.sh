#!/bin/bash

set -e

if [[ "$PACKER_BUILDER_TYPE" == 'googlecompute' ]]; then
	gcloud compute images add-iam-policy-binding "$PACKER_BUILD_NAME" \
		--project 'determined-ai' \
		--member='allAuthenticatedUsers' \
		--role='roles/compute.imageUser'
fi
