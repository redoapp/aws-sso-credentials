#!/usr/bin/env bash
set -euo pipefail

if [ "$USE_CROSS" = "true" ]; then
  cross build --release --locked --target "$TARGET"
else
  cargo build --release --locked --target "$TARGET"
fi
