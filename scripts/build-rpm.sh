#!/usr/bin/env bash
set -euo pipefail

rpm_version="${VERSION//-/~}"

cargo generate-rpm --target "$TARGET" --payload-compress zstd \
  -s "version=\"$rpm_version\"" \
  --output "dist/$BINARY-$rpm_version-1.$RPM_ARCH.rpm"
