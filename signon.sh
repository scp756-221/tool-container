#!/usr/bin/env bash
# Sign on to EC2 instance via ssh
set -o errexit
set -o nounset
default_userid='ubuntu'
if [[ $# -gt 3 ]]
then
  echo "Usage: signon.sh [EC2-INSTANCE-NAME] [EC2-USERID]"
  echo " This command signs onto your EC2 instance; all data is also saved for subsequent use by transfer.sh."
  echo " You can either save the destination instance in advance (into ec2-instance-name.txt) or specify it here."
  echo " If you specify the instance, you must also supply the userid. The default userid is '${default_userid}'."
  echo " Amazon Linux requires the userid 'ec2-user'."
  exit 1
fi

if [[ $# == 0 ]]
then
  userid=${default_userid}
fi

if [[ $# == 1 ]]
then
  userid=${1}
fi

if [[ $# == 2 ]]
then
  echo ${1} > ec2-instance-name.txt
  userid=${2}
fi

echo ${userid} > ec2-userid.txt
pem=$(cat ec2-pem-path.txt)
set -o xtrace
ssh -i ${pem} ${userid}@`cat ec2-instance-name.txt`
