#!/usr/bin/env bash
set -euo pipefail

echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"
