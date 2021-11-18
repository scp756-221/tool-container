#!/usr/bin/env bash
set -o nounset
set -o errexit
ver=`cat version.txt`
regid=`cat regid.txt`
iname=`cat iname.txt`
# Note that TARGET_ARCH is ignored for this make target, so we can run this script
# on either architecture
set -o xtrace
make TARGET_ARCH=amd VER=${ver} REGID=${regid} INAME=${iname} -f Makefile manifest
