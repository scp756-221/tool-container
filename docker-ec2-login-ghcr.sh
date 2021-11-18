#!/usr/bin/env bash
set -o nounset
set -o errexit
regid=$(cat regid.txt)
set -o xtrace
cat ec2-ghcr-token.txt | docker login ghcr.io -u ${regid} --password-stdin
