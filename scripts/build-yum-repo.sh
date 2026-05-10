#!/usr/bin/env bash
set -euo pipefail

owner="$GITHUB_REPOSITORY_OWNER"
repo_name="${GITHUB_REPOSITORY##*/}"

yum=pages/yum
mkdir -p "$yum"
cp dist/*.rpm "$yum/"
createrepo_c --update "$yum"

cat > "$yum/redo.repo" <<CONF
[redo]
name=Redo
baseurl=https://$owner.github.io/$repo_name/yum
enabled=1
gpgcheck=0
CONF
