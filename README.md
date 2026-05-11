# AWS SSO Credentials

A
[`credential_process`](https://docs.aws.amazon.com/sdkref/latest/guide/feature-process-credentials.html)
that automatically invokes `aws sso login` when an SSO session has expired, so
AWS SDKs and tools can authenticate without manual re-login.

## Installation

### Homebrew

```sh
brew tap redoapp/aws-sso-credentials https://github.com/redoapp/aws-sso-credentials
brew install redoapp/aws-sso-credentials/aws-sso-credentials
```

A pre-built binary for your OS/arch is fetched from the GitHub Release; no Rust
toolchain required.

### APT

```sh
echo "deb [trusted=yes] https://redoapp.github.io/aws-sso-credentials/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/aws-sso-credentials.list
sudo apt-get update
sudo apt-get install aws-sso-credentials
```

### YUM

```sh
sudo curl -fsSL -o /etc/yum.repos.d/aws-sso-credentials.repo \
  https://redoapp.github.io/aws-sso-credentials/yum/aws-sso-credentials.repo
sudo dnf install aws-sso-credentials   # or: sudo yum install
```

### Nix

```sh
nix profile install github:redoapp/aws-sso-credentials
# or, ad hoc
nix run github:redoapp/aws-sso-credentials -- --profile default
```

### Pre-built binary

Download a tarball for your platform from the
[releases page](https://github.com/redoapp/aws-sso-credentials/releases) and
place `aws-sso-credentials` on your `PATH`.

## Usage

Add `credential_process` to the profile that already has your SSO config:

```ini
[sso-session sso]
sso_start_url = https://example.awsapps.com/start/
sso_region = us-east-1

[default]
credential_process = aws-sso-credentials
sso_session = sso
sso_account_id = 123456789012
sso_role_name = Developer
```

Then use the profile as normal — `aws s3 ls`, `terraform plan`, anything that
goes through an AWS SDK.

Only one `aws sso login` invocation will be executed concurrently, within the
timeout (15s).

### Command line

```
aws-sso-credentials [--profile <name>] [-- <extra args for aws sso login>...]
```

Anything after `--` is forwarded verbatim to `aws sso login`, e.g.
`aws-sso-credentials --profile dev -- --no-browser`.

`AWS_CONFIG_FILE` and `AWS_SHARED_CREDENTIALS_FILE` are respected.

## Behavior

### Cache

Credentials are cached on disk at `~/.aws/sso-credentials/cache/<profile>.json`
(mode `0600`) until they expire. The AWS CLI's own SSO token cache at
`~/.aws/sso/cache/` is reused for the underlying access token.

### Login coordination

Concurrent invocations for the same SSO session coordinate through a lock file
in the system temp directory keyed by `sso_session` (or `sso_start_url` for
legacy profiles), so two profiles sharing a session do not race on
`aws sso login`. Unrelated sessions do not block each other.

### Configuration keys

The following keys are read from `~/.aws/config`:

- On the `[profile …]` section: `sso_account_id`, `sso_role_name`,
  `sso_session`. For legacy (pre-`sso-session`) profiles, `sso_start_url` and
  `sso_region` may live here instead.
- On the `[sso-session …]` section: `sso_start_url`, `sso_region`,
  `sso_registration_scopes`. Scopes are consumed by `aws sso login` directly
  from the config file.

## Limitations

- Windows is untested.

## License

MIT. Copyright © Redo Tech, Inc.

AWS is a trademark of Amazon.com, Inc. or its affiliates. This project is
independent and is not affiliated with, endorsed, or sponsored by Amazon.
