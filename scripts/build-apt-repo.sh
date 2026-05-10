#!/usr/bin/env bash
set -euo pipefail

apt=pages/apt
mkdir -p "$apt/pool/main" \
  "$apt/dists/stable/main/binary-amd64" \
  "$apt/dists/stable/main/binary-arm64"
cp dist/*.deb "$apt/pool/main/"

cd "$apt"

for arch in amd64 arm64; do
  apt-ftparchive --arch "$arch" packages pool/main \
    > "dists/stable/main/binary-$arch/Packages"
  gzip -kf "dists/stable/main/binary-$arch/Packages"
done

conf=$(mktemp)
cat > "$conf" <<'CONF'
APT::FTPArchive::Release::Origin "Redo";
APT::FTPArchive::Release::Label "Redo";
APT::FTPArchive::Release::Suite "stable";
APT::FTPArchive::Release::Codename "stable";
APT::FTPArchive::Release::Architectures "amd64 arm64";
APT::FTPArchive::Release::Components "main";
APT::FTPArchive::Release::Description "Redo APT repository";
CONF
apt-ftparchive -c "$conf" release dists/stable > dists/stable/Release
rm -f "$conf"
