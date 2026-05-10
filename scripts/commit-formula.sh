#!/usr/bin/env bash
set -euo pipefail

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add Formula/aws-sso-credentials.rb
if git diff --cached --quiet; then
  echo "No formula changes to commit."
  exit 0
fi
git commit -m "Update Homebrew formula to v$VERSION"
git push origin main
