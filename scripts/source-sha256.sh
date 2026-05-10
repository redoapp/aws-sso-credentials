#!/usr/bin/env bash
set -euo pipefail

curl -fsSL -o source.tar.gz \
  "https://github.com/$GITHUB_REPOSITORY/archive/refs/tags/$GITHUB_REF_NAME.tar.gz"
echo "sha256=$(sha256sum source.tar.gz | awk '{print $1}')" >> "$GITHUB_OUTPUT"
