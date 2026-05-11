mod cache;
mod profile;

use std::env;
use std::fs::{File, OpenOptions};
use std::io::{self, Read, Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};
use std::process::{Stdio, exit};
use std::time::{Duration, SystemTime};

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

const STALE_THRESHOLD: Duration = Duration::from_secs(30);

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

    if try_resolve(&args.profile, &config).await.is_ok() {
        return;
    }

    let lock_path = lock_path(&config);
    let _lock = match acquire_lock(&lock_path) {
        Ok(f) => f,
        Err(e) => {
            eprintln!(
                "aws-sso-credentials: failed to acquire {}: {e}",
                lock_path.display()
            );
            exit(1);
        }
    };

    if try_resolve(&args.profile, &config).await.is_ok() {
        return;
    }

    login(&args.profile, &args.sso_args).await;

    if let Err(e) = try_resolve(&args.profile, &config).await {
        eprintln!("aws-sso-credentials: {e:#}");
        exit(1);
    }
}

async fn try_resolve(profile: &str, config: &SsoConfig) -> anyhow::Result<()> {
    let creds = resolve_sso(config).await?;
    if let Err(e) = cache::write(profile, &creds) {
        eprintln!("aws-sso-credentials: failed to write cache: {e}");
    }
    emit(&creds);
    Ok(())
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
    let key = config.session_name.as_deref().unwrap_or(&config.start_url);
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

fn open_lock_file(path: &Path) -> io::Result<File> {
    let mut opts = OpenOptions::new();
    opts.create(true).read(true).write(true).truncate(false);
    #[cfg(windows)]
    {
        use std::os::windows::fs::OpenOptionsExt;
        // FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE — the last is
        // what lets a later arrival rename this file aside while old waiters
        // still hold handles to it.
        opts.share_mode(0x1 | 0x2 | 0x4);
    }
    opts.open(path)
}

fn acquire_lock(path: &Path) -> io::Result<File> {
    loop {
        let mut file = open_lock_file(path)?;
        if file.try_lock().is_err() {
            if lock_age(&file)? >= STALE_THRESHOLD {
                cleanup_stale(path)?;
                continue;
            }
            notify_waiting(read_holder_pid(&mut file));
            file.lock()?;
        }
        write_pid(&mut file)?;
        return Ok(file);
    }
}

fn lock_age(file: &File) -> io::Result<Duration> {
    let mtime = file.metadata()?.modified()?;
    Ok(SystemTime::now().duration_since(mtime).unwrap_or_default())
}

fn write_pid(file: &mut File) -> io::Result<()> {
    let bytes = format!("{}\n", std::process::id());
    file.seek(SeekFrom::Start(0))?;
    file.write_all(bytes.as_bytes())?;
    file.set_len(bytes.len() as u64)?;
    Ok(())
}

fn read_holder_pid(file: &mut File) -> Option<u32> {
    let mut buf = String::new();
    file.seek(SeekFrom::Start(0)).ok()?;
    file.read_to_string(&mut buf).ok()?;
    buf.trim().parse().ok()
}

fn notify_waiting(pid: Option<u32>) {
    let msg = match pid {
        Some(p) => format!("aws-sso-credentials: waiting on process {p} for AWS SSO login\n"),
        None => String::from("aws-sso-credentials: waiting for AWS SSO login\n"),
    };
    if let Ok(mut tty) = OpenOptions::new().write(true).open(TTY_PATH) {
        let _ = tty.write_all(msg.as_bytes());
    }
}

fn cleanup_stale(path: &Path) -> io::Result<()> {
    match remove_stale(path) {
        Ok(()) => Ok(()),
        Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(()),
        Err(e) => Err(e),
    }
}

#[cfg(unix)]
fn remove_stale(path: &Path) -> io::Result<()> {
    std::fs::remove_file(path)
}

#[cfg(windows)]
fn remove_stale(path: &Path) -> io::Result<()> {
    std::fs::rename(path, stale_path(path))
}

#[cfg(windows)]
fn stale_path(path: &Path) -> PathBuf {
    let nanos = SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    let mut name = path.file_name().unwrap_or_default().to_os_string();
    name.push(format!(".stale-{}-{}", std::process::id(), nanos));
    path.with_file_name(name)
}

async fn login(profile: &str, extra_args: &[String]) {
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

    let _ = child.wait().await;
}
