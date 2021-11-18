#/usr/bin/env bash
# Sign on to an EC2 instance a second time
set -o errexit
set -o nounset
if [[ $# != 0 ]]
then
  echo "Usage: second-signon.sh"
  echo " This command does not allow any parameters."
  echo " A previous signon.sh must have been run."
  exit 1
fi
pem=$(cat ec2-pem-path.txt)
ec2_instance=$(cat ec2-instance-name.txt)
set -o xtrace
ssh -i  ${pem} ubuntu@${ec2_instance}
