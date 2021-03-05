#!/usr/bin/env bash

set -e

rm -rf /var/lib/apt/lists/*
rm /etc/ssh/ssh_host_ecdsa_key
rm /etc/ssh/ssh_host_ed25519_key
rm /etc/ssh/ssh_host_rsa_key
