# Development

## Layout

- `src/` — Rust source for the `aws-sso-credentials` binary.
- `Formula/aws-sso-credentials.rb` — Homebrew formula, single source of truth.
  The release workflow does targeted regex edits on the per-platform
  `url`/`sha256` lines; keep those lines simple enough to match.
- `flake.nix` — Nix package definition.
- `scripts/` — All non-trivial shell the release workflow runs. Workflow `run:`
  blocks are one-liners that invoke a script.
- `.github/workflows/release.yaml` — release pipeline, triggered by `v*` tag
  push. YAML map keys are alphabetized.

## Local commands

```sh
cargo build                              # debug build
cargo test                               # run tests
cargo run -- --profile default           # exercise the binary
pnpm format                              # prettier (YAML, Markdown)
shellcheck scripts/*.sh                  # lint shell
nix build                                # verify the flake
```

## Conventions

- Shell: `set -euo pipefail` and rely on it; no defensive `: "${X:?}"` guards.
- Prettier-formatted YAML and Markdown (`proseWrap: always`).
- Comments only when the _why_ is non-obvious.

## Releasing

1. Bump `version` in `Cargo.toml`, commit, and push to `main`.
2. Tag and push: `git tag v<version> && git push origin v<version>`.

The workflow then builds binaries (Linux x86_64/aarch64, macOS x86_64/aarch64),
publishes a GitHub Release, rewrites the Homebrew formula on `main`, and pushes
the APT/YUM repos to `gh-pages`.
