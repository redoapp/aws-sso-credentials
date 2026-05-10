use anyhow::{Result, anyhow};
use aws_config::profile::load;
use aws_runtime::env_config::file::EnvConfigFiles;
use aws_types::os_shim_internal::{Env, Fs};

pub struct SsoConfig {
    pub start_url: String,
    pub region: String,
    pub account_id: String,
    pub role_name: String,
    pub session_name: Option<String>,
    // `aws sso login` reads `sso_registration_scopes` straight from the config
    // file, and the Rust SDK's `SsoCredentialsProvider` has no scopes hook
    // (scopes are baked into the cached SSO token). Stored for awareness only.
    #[allow(dead_code)]
    pub registration_scopes: Option<String>,
}

pub async fn read(profile: &str) -> Result<SsoConfig> {
    let profiles = load(&Fs::real(), &Env::real(), &EnvConfigFiles::default(), None).await?;

    let p = profiles
        .get_profile(profile)
        .ok_or_else(|| anyhow!("profile {profile:?} not found"))?;

    let profile_label = format!("profile {profile:?}");
    let from_profile = |key: &str| -> Result<String> {
        p.get(key)
            .map(str::to_owned)
            .ok_or_else(|| anyhow!("{profile_label} missing {key}"))
    };

    let account_id = from_profile("sso_account_id")?;
    let role_name = from_profile("sso_role_name")?;

    let (start_url, region, session_name, registration_scopes) =
        if let Some(session) = p.get("sso_session") {
            let session_label = format!("sso-session {session:?}");
            let s = profiles
                .sso_session(session)
                .ok_or_else(|| anyhow!("{session_label} not found"))?;
            let from_session = |key: &str| -> Result<String> {
                s.get(key)
                    .map(str::to_owned)
                    .ok_or_else(|| anyhow!("{session_label} missing {key}"))
            };
            (
                from_session("sso_start_url")?,
                from_session("sso_region")?,
                Some(session.to_owned()),
                s.get("sso_registration_scopes").map(str::to_owned),
            )
        } else {
            (
                from_profile("sso_start_url")?,
                from_profile("sso_region")?,
                None,
                p.get("sso_registration_scopes").map(str::to_owned),
            )
        };

    Ok(SsoConfig {
        start_url,
        region,
        account_id,
        role_name,
        session_name,
        registration_scopes,
    })
}
