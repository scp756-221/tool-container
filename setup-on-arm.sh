#!/usr/bin/env bash
# Set up the ARM EC2 instance
# Prequisite:  All files transferred via ./send-to-arm.sh from host
set -o nounset
set -o errexit
#
REGISTRY=ghcr.io
USERID=$(cat regid.txt)
VER=$(cat version.txt)
#
# Set up AWS credentials
#
cd ~
mkdir -p .aws
mv credentials .aws
#
# Set up packages
#
sudo ./install-docker-on-arm.sh
sudo apt-get install -y make
#
# Sign on to GitHub Container repository (to push and pull)
#
sudo ./docker-ec2-login-ghcr.sh
#
# Get the class code
#
git clone https://github.com/scp756-221/c756-exer.git
#
# Set the template variables
#
mv -f tpl-vars.txt c756-exer/e-k8s/cluster
