#!/usr/bin/env bash
# Build on an ARM machine
set -o nounset
set -o errexit
ver=`cat version.txt`
regid=`cat regid.txt`
iname=`cat iname.txt`
set -o xtrace
sudo make TARGET_ARCH=arm VER=${ver} REGID=${regid} INAME=${iname} DOCKERFILE=Dockerfile -f Makefile build
