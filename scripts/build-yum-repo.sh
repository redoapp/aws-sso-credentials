#!/usr/bin/env bash
set -euo pipefail

owner="$GITHUB_REPOSITORY_OWNER"
repo_name="${GITHUB_REPOSITORY##*/}"

yum=pages/yum
mkdir -p "$yum"
cp dist/*.rpm "$yum/"
createrepo_c --update "$yum"

cat > "$yum/aws-sso-credentials.repo" <<CONF
[aws-sso-credentials]
name=AWS SSO Credentials
baseurl=https://$owner.github.io/$repo_name/yum
enabled=1
gpgcheck=0
CONF
