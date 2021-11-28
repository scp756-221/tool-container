#!/usr/bin/env bash
# Transfer file to ARM EC2 instance
set -o errexit
set -o nounset
if [[ $# -lt 1 || $# -gt 2 ]]
then
  echo "Usage: transfer.sh PATH [REMOTE-FILE-NAME]"
  echo " This command will send the file at PATH to the home directory of"
  echo " the machine and userid named in the last call to signon.sh."
  echo " If a second argument is provided, the remote file will have that name."
  exit 1
fi

if [[ $# == 1 ]]
then
  base=$(basename ${1})
else
  base=${2}
fi
pem=$(cat ec2-pem-path.txt)
userid=$(cat ec2-userid.txt)
ec2_instance=$(cat ec2-instance-name.txt)
set -o xtrace
scp -i ${pem} ${1} ${userid}@${ec2_instance}:/home/${userid}/${base}
