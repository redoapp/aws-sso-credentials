#!/usr/bin/env bash
set -euo pipefail

cd pages
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A
if git diff --cached --quiet; then
  echo "No pages changes to commit."
  exit 0
fi
git commit -m "Publish v$VERSION"
git push origin HEAD:gh-pages
