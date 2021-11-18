#!/usr/bin/env bash
# Build on an Mac/amd64
set -o nounset
set -o errexit
ver=`cat version.txt`
regid=`cat regid.txt`
iname=`cat iname.txt`
set -o xtrace
make TARGET_ARCH=amd VER=${ver} REGID=${regid} INAME=${iname} DOCKERFILE=Dockerfile -f Makefile build
