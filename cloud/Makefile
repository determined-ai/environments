.PHONY: publish

export VERSION := $(shell cat ../VERSION)
export VERSION_DASHES := $(subst .,-,$(VERSION))

# Timeout used by packer for AWS operations. Default is 120 (30 minutes) for
# waiting for AMI availablity. Bump to 180 attempts = 45 minutes.
export AWS_MAX_ATTEMPTS=180

publish:
	packer build environments-packer.json
