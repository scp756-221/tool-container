#!/usr/bin/env bash
# Send files to ARM EC2 instance
set -o errexit
set -o nounset
tokens=$(cat token-path.txt)
code=$(cat code-path.txt)
set -o xtrace
./transfer.sh Dockerfile
./transfer.sh Makefile
./transfer.sh install-docker-on-arm.sh
./transfer.sh build-on-arm.sh
./transfer.sh run-on-arm.sh
./transfer.sh push-dev-on-arm.sh
./transfer.sh setup-on-arm.sh
./transfer.sh version.txt
./transfer.sh regid.txt
./transfer.sh iname.txt
./transfer.sh ~/.aws/credentials
./transfer.sh docker-ec2-login-ghcr.sh
./transfer.sh ${tokens}/ec2-ghcr-token.txt 
./transfer.sh ${code}/e-k8s/cluster/tpl-vars.txt
