#!/bin/bash

set -e

cd $(dirname $BASH_SOURCE[0])

if [[ -d "../zig-out/ddnuts-linux-amd64-package" ]]; then rm -rf "../zig-out/ddnuts-linux-amd64-package"; fi
if [[ -d "../zig-out/ddnuts-linux-arm64-package" ]]; then rm -rf "../zig-out/ddnuts-linux-arm64-package"; fi

mkdir -p "../zig-out/ddnuts-linux-amd64-package/usr/bin"
mkdir -p "../zig-out/ddnuts-linux-arm64-package/usr/bin"

cp -r "./DEBIAN" "../zig-out/ddnuts-linux-amd64-package"
cp -r "./DEBIAN" "../zig-out/ddnuts-linux-arm64-package"
cp -r "./etc" "../zig-out/ddnuts-linux-amd64-package"
cp -r "./etc" "../zig-out/ddnuts-linux-arm64-package"
cp "../zig-out/ddnuts-linux-amd64" "../zig-out/ddnuts-linux-amd64-package/usr/bin/ddnuts"
cp "../zig-out/ddnuts-linux-arm64" "../zig-out/ddnuts-linux-arm64-package/usr/bin/ddnuts"

VERSION=$(grep -m 1 -oE "\.version[[:space:]]*=[[:space:]]*\"[^,]+" "../build.zig.zon" | grep -m 1 -oE "[0-9]+([0-9]|\.)+")

perl -pi -e "s/<architecture>/amd64/g" "../zig-out/ddnuts-linux-amd64-package/DEBIAN/control"
perl -pi -e "s/<architecture>/arm64/g" "../zig-out/ddnuts-linux-arm64-package/DEBIAN/control"
perl -pi -e "s/<version>/$VERSION/g" "../zig-out/ddnuts-linux-amd64-package/DEBIAN/control"
perl -pi -e "s/<version>/$VERSION/g" "../zig-out/ddnuts-linux-arm64-package/DEBIAN/control"

dpkg-deb --root-owner-group --build ../zig-out/ddnuts-linux-amd64-package ../zig-out/ddnuts-linux-amd64.deb
dpkg-deb --root-owner-group --build ../zig-out/ddnuts-linux-arm64-package ../zig-out/ddnuts-linux-arm64.deb

rm -rf "../zig-out/ddnuts-linux-amd64-package"
rm -rf "../zig-out/ddnuts-linux-arm64-package"
