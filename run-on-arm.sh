#!/usr/bin/env bash
set -o nounset
set -o errexit
ver=$(cat ~/version.txt)
sudo HOME=/home/ubuntu tools/shell.sh ${ver}-arm64
