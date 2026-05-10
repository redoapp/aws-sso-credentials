#!/usr/bin/env bash
set -euo pipefail

cd dist
shasum -a 256 ./*.tar.gz ./*.deb ./*.rpm > SHA256SUMS
