use std::env;
use std::fs::{self, OpenOptions};
use std::io::{self, Write};
#[cfg(unix)]
use std::os::unix::fs::OpenOptionsExt;
use std::path::PathBuf;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

const SKEW: chrono::TimeDelta = chrono::TimeDelta::seconds(60);

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub struct Credentials {
    pub version: u32,
    pub access_key_id: String,
    pub secret_access_key: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub expiration: Option<String>,
}

pub fn read(profile: &str) -> Option<Credentials> {
    let bytes = fs::read(path(profile)?).ok()?;
    let creds: Credentials = serde_json::from_slice(&bytes).ok()?;
    let expires_at = DateTime::parse_from_rfc3339(creds.expiration.as_deref()?)
        .ok()?
        .with_timezone(&Utc);
    (Utc::now() + SKEW < expires_at).then_some(creds)
}

pub fn write(profile: &str, creds: &Credentials) -> io::Result<()> {
    let path = path(profile).ok_or_else(|| io::Error::other("$HOME not set"))?;
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }

    let mut tmp = path.clone();
    tmp.set_extension("json.tmp");

    let mut opts = OpenOptions::new();
    opts.write(true).create(true).truncate(true);
    #[cfg(unix)]
    opts.mode(0o600);
    let mut file = opts.open(&tmp)?;
    let json = serde_json::to_vec(creds).map_err(io::Error::other)?;
    file.write_all(&json)?;
    drop(file);

    fs::rename(&tmp, &path)
}

fn path(profile: &str) -> Option<PathBuf> {
    env::home_dir().map(|home| {
        home.join(".aws/sso-credentials/cache")
            .join(format!("{profile}.json"))
    })
}
