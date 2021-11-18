#!/usr/bin/env bash
set -o nounset
set -o errexit
ver=$(cat ${VER_HOME}/version.txt)
set -o xtrace
tools/shell.sh ${ver}-amd64
