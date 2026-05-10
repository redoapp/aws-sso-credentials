#!/usr/bin/env bash
set -euo pipefail

name="$BINARY-$VERSION-$TARGET"
mkdir -p "dist/$name"
cp "target/$TARGET/release/$BINARY" LICENSE.txt README.md "dist/$name/"
tar -C dist -czf "dist/$name.tar.gz" "$name"
rm -rf "dist/$name"
(cd dist && shasum -a 256 "$name.tar.gz" > "$name.tar.gz.sha256")
