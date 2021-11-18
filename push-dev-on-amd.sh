#!/usr/bin/env bash
# Push built AMD64 image to GHCR
set -o nounset
set -o errexit
ver=$(cat version.txt)
regid=$(cat regid.txt)
iname=$(cat iname.txt)
set -o xtrace
make TARGET_ARCH=amd VER=${ver} REGID=${regid} INAME=${iname} -f Makefile dev
