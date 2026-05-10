#!/usr/bin/env bash
set -euo pipefail

remote="https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git"
if git ls-remote --exit-code --heads "$remote" gh-pages > /dev/null; then
  git clone --depth 1 --branch gh-pages "$remote" pages
else
  mkdir pages
  git -C pages init -b gh-pages
  git -C pages remote add origin "$remote"
fi
