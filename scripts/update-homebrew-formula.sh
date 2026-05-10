#!/usr/bin/env bash
set -euo pipefail

exec python3 - <<'PY'
import os
import re
import sys
from pathlib import Path

version = os.environ["VERSION"]
repo = os.environ["GITHUB_REPOSITORY"]
binary = "aws-sso-credentials"
formula = Path("Formula/aws-sso-credentials.rb")
dist = Path("dist")

targets = [
    "aarch64-apple-darwin",
    "x86_64-apple-darwin",
    "aarch64-unknown-linux-gnu",
    "x86_64-unknown-linux-gnu",
]


def sha(target):
    return (dist / f"{binary}-{version}-{target}.tar.gz.sha256").read_text().split()[0]


content = formula.read_text()

content, n = re.subn(
    r'^(\s*)version "[^"]*"',
    rf'\1version "{version}"',
    content, count=1, flags=re.M,
)
if not n:
    sys.exit("could not find a `version` line in the formula")

for target in targets:
    url = (
        f"https://github.com/{repo}/releases/download/v{version}"
        f"/{binary}-{version}-{target}.tar.gz"
    )
    pat = re.compile(
        rf'(\s*)url "[^"]*-{re.escape(target)}\.tar\.gz"\s*\n'
        rf'(\s*)sha256 "[^"]*"',
    )
    content, n = pat.subn(
        lambda m: f'{m.group(1)}url "{url}"\n{m.group(2)}sha256 "{sha(target)}"',
        content, count=1,
    )
    if not n:
        sys.exit(f"could not find url/sha block for {target}")

formula.write_text(content)
print(f"Updated {formula} to v{version}")
PY
