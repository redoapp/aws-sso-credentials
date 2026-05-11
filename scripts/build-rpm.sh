#!/usr/bin/env bash
set -euo pipefail

rpm_version=$(printf '%s' "$VERSION" | tr - '~')

sed -i.bak -E "s|^version = \"[^\"]*\"|version = \"$rpm_version\"|" Cargo.toml
trap 'mv Cargo.toml.bak Cargo.toml' EXIT

cargo generate-rpm --target "$TARGET" --payload-compress zstd \
  --output "dist/$BINARY-$rpm_version-1.$RPM_ARCH.rpm"
