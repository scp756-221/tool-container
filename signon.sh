#!/usr/bin/env bash
# Sign on to EC2 instance via ssh
set -o errexit
set -o nounset
if [[ $# != 1 ]]
then
  echo "Usage: signon.sh EC2-INSTANCE-NAME"
  echo " This command will save the instance name for later use by transfer.sh."
  echo " EC2-INSTANCE-NAME should not include the userid for signing on."
  echo " The instance userid must be 'ubuntu'."
  exit 1
fi
echo ${1} > ec2-instance-name.txt
pem=$(cat ec2-pem-path.txt)
set -o xtrace
ssh -i ${pem} ubuntu@${1}
