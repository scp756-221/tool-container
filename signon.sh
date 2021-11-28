#!/usr/bin/env bash
# Sign on to EC2 instance via ssh
set -o errexit
set -o nounset
default_userid='ubuntu'
if [[ $# -lt 1 || $# -gt 2 ]]
then
  echo "Usage: signon.sh EC2-INSTANCE-NAME [EC2-USERID]"
  echo " This command will save the instance name for later use by transfer.sh."
  echo " EC2-INSTANCE-NAME should not include the userid for signing on."
  echo " The instance userid is optional, with default '${default_userid}'."
  echo " Amazon Linux requires the userid 'ec2-user'."
  exit 1
fi

if [[ $# == 1 ]]
then
  userid=${default_userid}
else
  userid=${2}
fi

echo ${1} > ec2-instance-name.txt
echo ${userid} > ec2-userid.txt
pem=$(cat ec2-pem-path.txt)
set -o xtrace
ssh -i ${pem} ${userid}@${1}
