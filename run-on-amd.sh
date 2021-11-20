#!/usr/bin/env bash
set -o nounset
set -o errexit
regid=$(cat ${VER_HOME}/regid.txt)
iname=$(cat ${VER_HOME}/iname.txt)
ver=$(cat ${VER_HOME}/version.txt)
set -o xtrace
REGID=${regid} INAME=${iname} tools/shell.sh ${ver}-amd64
