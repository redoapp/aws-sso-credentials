# Agent notes

See [DEVELOPMENT.md](./DEVELOPMENT.md) for project layout, conventions, and the
release process — read it before making changes.

A few things that are easy to get wrong:

- `Formula/aws-sso-credentials.rb` is the single source of truth for the
  Homebrew formula. Don't generate it from a template — the release script does
  targeted regex edits on the existing `url`/`sha256` lines.
- Shell scripts rely on `set -euo pipefail`; don't add defensive `: "${X:?}"`
  guards or `[ -n "$x" ] || exit` checks.
- Workflow `run:` blocks should invoke a `scripts/*.sh`, not contain multi-line
  shell.
