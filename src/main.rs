mod cache;
mod profile;

use std::env;
use std::fs::{File, OpenOptions};
use std::io::{self, Write};
use std::path::PathBuf;
use std::process::{Stdio, exit};
use std::thread;
use std::time::{Duration, Instant};

use aws_config::Region;
use aws_config::sso::SsoCredentialsProvider;
use aws_credential_types::provider::ProvideCredentials;
use chrono::{DateTime, SecondsFormat, Utc};
use tokio::process::Command;

use profile::SsoConfig;

#[cfg(unix)]
const TTY_PATH: &str = "/dev/tty";
#[cfg(windows)]
const TTY_PATH: &str = "CONOUT$";

const LOCK_TIMEOUT: Duration = Duration::from_secs(15);
const LOGIN_TIMEOUT: Duration = Duration::from_secs(15);
const POLL_INTERVAL: Duration = Duration::from_millis(50);

struct Args {
    profile: String,
    sso_args: Vec<String>,
}

fn parse_args() -> Args {
    let mut profile: Option<String> = None;
    let mut sso_args = Vec::new();
    let mut after_sep = false;
    let mut iter = env::args().skip(1);

    while let Some(arg) = iter.next() {
        if after_sep {
            sso_args.push(arg);
        } else if arg == "--" {
            after_sep = true;
        } else if arg == "--profile" {
            let Some(value) = iter.next() else {
                eprintln!("aws-sso-credentials: --profile requires a value");
                exit(2);
            };
            set_profile(&mut profile, value);
        } else if let Some(value) = arg.strip_prefix("--profile=") {
            set_profile(&mut profile, value.to_owned());
        } else {
            eprintln!(
                "aws-sso-credentials: unexpected argument {arg:?}; \
                 pass extra `aws sso login` args after `--`"
            );
            exit(2);
        }
    }

    let profile = profile
        .or_else(|| env::var("AWS_PROFILE").ok())
        .or_else(|| env::var("AWS_DEFAULT_PROFILE").ok())
        .unwrap_or_else(|| "default".to_owned());

    Args { profile, sso_args }
}

fn set_profile(slot: &mut Option<String>, value: String) {
    if slot.is_some() {
        eprintln!("aws-sso-credentials: profile specified more than once");
        exit(2);
    }
    *slot = Some(value);
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let args = parse_args();

    if let Some(creds) = cache::read(&args.profile) {
        emit(&creds);
        return;
    }

    let config = match profile::read(&args.profile).await {
        Ok(c) => c,
        Err(e) => {
            eprintln!("aws-sso-credentials: {e:#}");
            exit(1);
        }
    };

    if try_resolve(&args.profile, &config).await {
        return;
    }

    let lock_path = lock_path(&config);
    let lock_file = match OpenOptions::new().create(true).write(true).open(&lock_path) {
        Ok(f) => f,
        Err(e) => {
            eprintln!(
                "aws-sso-credentials: failed to open {}: {e}",
                lock_path.display()
            );
            exit(1);
        }
    };

    if acquire_lock(&lock_file, LOCK_TIMEOUT) {
        if try_resolve(&args.profile, &config).await {
            return;
        }
        login(&args.profile, &args.sso_args, LOGIN_TIMEOUT).await;
    }

    if !try_resolve(&args.profile, &config).await {
        exit(1);
    }
}

async fn try_resolve(profile: &str, config: &SsoConfig) -> bool {
    match resolve_sso(config).await {
        Ok(creds) => {
            if let Err(e) = cache::write(profile, &creds) {
                eprintln!("aws-sso-credentials: failed to write cache: {e}");
            }
            emit(&creds);
            true
        }
        Err(e) => {
            eprintln!("aws-sso-credentials: {e:#}");
            false
        }
    }
}

async fn resolve_sso(config: &SsoConfig) -> anyhow::Result<cache::Credentials> {
    let mut builder = SsoCredentialsProvider::builder()
        .start_url(&config.start_url)
        .account_id(&config.account_id)
        .role_name(&config.role_name)
        .region(Region::new(config.region.clone()));
    if let Some(name) = &config.session_name {
        builder = builder.session_name(name);
    }

    let creds = builder.build().provide_credentials().await?;

    let expiration = creds
        .expiry()
        .map(|t| DateTime::<Utc>::from(t).to_rfc3339_opts(SecondsFormat::Secs, true));

    Ok(cache::Credentials {
        version: 1,
        access_key_id: creds.access_key_id().to_owned(),
        secret_access_key: creds.secret_access_key().to_owned(),
        session_token: creds.session_token().map(str::to_owned),
        expiration,
    })
}

fn emit(creds: &cache::Credentials) {
    let mut handle = io::stdout().lock();
    if let Err(e) = serde_json::to_writer(&mut handle, creds) {
        eprintln!("aws-sso-credentials: failed to write stdout: {e}");
    }
    let _ = handle.flush();
}

fn lock_path(config: &SsoConfig) -> PathBuf {
    let key = config
        .session_name
        .as_deref()
        .unwrap_or(&config.start_url);
    let sanitized: String = key
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || matches!(c, '-' | '_' | '.') {
                c
            } else {
                '_'
            }
        })
        .collect();
    env::temp_dir().join(format!("aws-sso-{sanitized}.lock"))
}

fn acquire_lock(file: &File, timeout: Duration) -> bool {
    let deadline = Instant::now() + timeout;
    while file.try_lock().is_err() {
        if Instant::now() >= deadline {
            return false;
        }
        thread::sleep(POLL_INTERVAL);
    }
    true
}

async fn login(profile: &str, extra_args: &[String], duration: Duration) {
    let mut cmd = Command::new("aws");
    cmd.args(["sso", "login", "--profile", profile])
        .args(extra_args);

    // Route output to the console so SSO prompts reach the user even when this
    // binary is invoked as a credentials_process. See
    // https://github.com/aws/aws-cli/issues/7306.
    if let Ok(tty) = OpenOptions::new().read(true).write(true).open(TTY_PATH)
        && let Ok(stderr) = tty.try_clone()
    {
        cmd.stdout(Stdio::from(tty)).stderr(Stdio::from(stderr));
    }

    let mut child = match cmd.spawn() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("aws-sso-credentials: failed to spawn `aws sso login`: {e}");
            return;
        }
    };

    // If the login outlives the timeout, let it keep running in the background:
    // SSO browser auth normally takes longer than this, and the next invocation
    // will pick up the cached token. `kill_on_drop` defaults to false, so
    // dropping `child` leaves the subprocess detached.
    let _ = tokio::time::timeout(duration, child.wait()).await;
}
