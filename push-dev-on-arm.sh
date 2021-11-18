#!/usr/bin/env bash
# Push built ARM64 image to development registry
set -o nounset
set -o errexit
ver=$(cat version.txt)
regid=$(cat regid.txt)
iname=$(cat iname.txt)
set -o xtrace
sudo make TARGET_ARCH=arm VER=${ver} REGID=${regid} INAME=${iname} -f Makefile dev
