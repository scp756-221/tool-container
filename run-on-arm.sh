#!/usr/bin/env bash
set -o nounset
set -o errexit
regid=$(cat ~/regid.txt)
iname=$(cat ~/iname.txt)
ver=$(cat ~/version.txt)
sudo HOME=/home/ubuntu REGID=${regid} INAME=${iname} tools/shell.sh ${ver}-arm64
