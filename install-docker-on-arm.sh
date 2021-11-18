#!/usr/bin/env bash
# Install docker on an EC2 Ubuntu 20.04 instance
# Must run script under sudo
apt update
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
curl  -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update \
&& apt-get install -y docker-ce docker-ce-cli containerd.io
