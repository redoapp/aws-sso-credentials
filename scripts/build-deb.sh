#!/usr/bin/env bash
set -euo pipefail

cargo deb --target "$TARGET" --no-build --no-strip \
  --output "dist/${BINARY}_${VERSION}_${DEB_ARCH}.deb"
