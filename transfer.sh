#!/usr/bin/env bash
# Transfer file to ARM EC2 instance
set -o errexit
set -o nounset
base=$(basename ${1})
pem=$(cat ec2-pem-path.txt)
ec2_instance=$(cat ec2-instance-name.txt)
set -o xtrace
scp -i ${pem} ${1} ubuntu@${ec2_instance}:/home/ubuntu/${base}
