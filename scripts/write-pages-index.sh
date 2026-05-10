#!/usr/bin/env bash
set -euo pipefail

repo_name="${GITHUB_REPOSITORY##*/}"

cat > pages/index.html <<EOF
<!doctype html>
<html><head><meta charset="utf-8"><title>$repo_name</title></head>
<body>
<h1>$repo_name</h1>
<p>See <a href="https://github.com/$GITHUB_REPOSITORY">$GITHUB_REPOSITORY</a> for installation instructions.</p>
<ul>
  <li><a href="apt/">APT repository</a></li>
  <li><a href="yum/">YUM repository</a></li>
</ul>
</body></html>
EOF
touch pages/.nojekyll
