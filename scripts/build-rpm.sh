#!/usr/bin/env bash
set -euo pipefail

cargo generate-rpm --target "$TARGET" --payload-compress zstd \
  --output "dist/$BINARY-$VERSION-1.$RPM_ARCH.rpm"
