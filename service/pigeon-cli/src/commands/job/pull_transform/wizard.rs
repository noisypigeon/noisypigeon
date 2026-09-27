use std::path::PathBuf;

use dialoguer::Input;

use crate::commands::FAILURE_EXIT_CODE;
use crate::commands::job::shared_wizard::{
    ConcurrencyInput, ConfirmInput, EncryptionKeyInput, UploadTargetInput,
};
use crate::commands::keyring::store::Store;
use crate::core::crypto::Aes256GcmSivEncryptor;
use crate::core::job::Job;
use crate::core::keyring::credentials;
use crate::core::wizard::WizardInput;

use super::media::check_ffmpeg_available;
use super::{PullTransformJob, TypeSummary};

/// Resolves which bucket-config to pull from -- mandatory (unlike
/// `UploadTargetInput`'s optional upload target), since there's no sane
/// default source for this job the way `email_sync`'s local-output has one.
struct SourceBucketInput<'a> {
    flag: Option<String>,
    store: &'a Store,
}

impl WizardInput for SourceBucketInput<'_> {
    type Value = String;

    fn flag_value(&self) -> Option<Result<String, String>> {
        self.flag.clone().map(Ok)
    }

    fn prompt(&self) -> Result<String, String> {
        self.store
            .prompt_select_bucket()
            .map(|bucket_config| bucket_config.alias.clone())
    }

    fn non_interactive_fallback(&self) -> Result<String, String> {
        Err("--source-bucket is required when not running interactively".to_string())
    }
}

/// Same shape as `email_sync::wizard`'s `LocalOutputInput` -- `--local-output`
/// if given, an editable prompt on a TTY, that same default silently
/// otherwise.
fn default_local_output() -> PathBuf {
    std::env::temp_dir().join("pigeon-job")
}

struct LocalOutputInput {
    flag: Option<PathBuf>,
}

impl WizardInput for LocalOutputInput {
    type Value = PathBuf;

    fn flag_value(&self) -> Option<Result<PathBuf, String>> {
        self.flag.clone().map(Ok)
    }

    fn prompt(&self) -> Result<PathBuf, String> {
        let default = default_local_output();
        let value = Input::<String>::new()
            .with_prompt("Local directory to stage and store output under")
            .default(default.display().to_string())
            .interact_text()
            .map_err(|err| format!("failed to read local output directory: {err}"))?;
        Ok(PathBuf::from(value))
    }

    fn non_interactive_fallback(&self) -> Result<PathBuf, String> {
        Ok(default_local_output())
    }
}

fn format_bytes(bytes: u64) -> String {
    const UNITS: [&str; 5] = ["B", "KB", "MB", "GB", "TB"];
    let mut value = bytes as f64;
    let mut unit = 0;
    while value >= 1024.0 && unit < UNITS.len() - 1 {
        value /= 1024.0;
        unit += 1;
    }
    if unit == 0 {
        format!("{bytes} B")
    } else {
        format!("{value:.1} {}", UNITS[unit])
    }
}

/// Prints the pre-run per-extension type summary table (ADR-0074 §3) --
/// reflects only pending (not yet checkpointed) objects, and doesn't yet
/// know what's inside any zip (unexpanded, shown as its own `zip` row).
fn print_type_summary(summaries: &[TypeSummary]) {
    let rows: Vec<Vec<String>> = summaries
        .iter()
        .map(|summary| {
            vec![
                summary.extension.clone(),
                summary.count.to_string(),
                format_bytes(summary.total_bytes),
            ]
        })
        .collect();
    crate::commands::print_table(&["EXTENSION", "PENDING", "SIZE"], &rows);
}

fn fail(message: impl std::fmt::Display) -> i32 {
    eprintln!("Error: {message}");
    FAILURE_EXIT_CODE
}

/// Entry point for `pigeon job run pull-transform` (ADR-0074).
pub fn dispatch(
    source_bucket: Option<String>,
    local_output: Option<PathBuf>,
    remote_output: Option<String>,
    encryption_key: Option<String>,
    concurrency: Option<usize>,
    yes: bool,
) -> i32 {
    let runtime = match tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
    {
        Ok(runtime) => runtime,
        Err(err) => return fail(format!("failed to start async runtime: {err}")),
    };
    runtime.block_on(dispatch_async(
        source_bucket,
        local_output,
        remote_output,
        encryption_key,
        concurrency,
        yes,
    ))
}

async fn dispatch_async(
    source_bucket: Option<String>,
    local_output: Option<PathBuf>,
    remote_output: Option<String>,
    encryption_key: Option<String>,
    concurrency: Option<usize>,
    yes: bool,
) -> i32 {
    // Held for this whole async fn's lifetime -- every early `return
    // fail(...)` below drops it, aborting the sampling task automatically
    // (ADR-0073).
    let _sampler =
        crate::observability::resources::ResourceSampler::spawn(std::time::Duration::from_secs(5));

    // Checked once, up front: a missing ffmpeg/ffprobe fails the whole job
    // immediately with one clear error, instead of failing per-file deep
    // into a long run (ADR-0074 §4).
    if let Err(err) = check_ffmpeg_available().await {
        return fail(err);
    }

    let keyring_store_path = match Store::default_path() {
        Ok(path) => path,
        Err(err) => return fail(err),
    };
    let keyring_store = match Store::load(&keyring_store_path) {
        Ok(store) => store,
        Err(err) => return fail(err),
    };

    let source_alias = match (SourceBucketInput {
        flag: source_bucket,
        store: &keyring_store,
    })
    .resolve()
    {
        Ok(alias) => alias,
        Err(err) => return fail(err),
    };
    let source_bucket_config = match keyring_store
        .bucket_configs()
        .find(|bucket_config| bucket_config.alias == source_alias)
    {
        Some(bucket_config) => bucket_config.clone(),
        None => return fail(format!("no bucket-config named '{source_alias}'")),
    };
    let source_secret = match credentials::get_secret(&source_bucket_config.alias) {
        Ok(secret) => secret,
        Err(err) => return fail(err),
    };

    let local_output = match (LocalOutputInput { flag: local_output }).resolve() {
        Ok(path) => path,
        Err(err) => return fail(err),
    };

    let mut job = PullTransformJob {
        source_bucket: source_bucket_config,
        source_secret,
        local_output,
        remote: None,
        encryptor: None,
    };
    let plan = match job.gather().await {
        Ok(plan) => plan,
        Err(err) => return fail(err),
    };

    print_type_summary(&plan.type_summary);
    if plan.tasks.is_empty() {
        println!("Everything is already up to date.");
        return 0;
    }
    println!("{} pending object(s) found.", plan.tasks.len());

    let resolved_remote_alias = match (UploadTargetInput {
        flag: remote_output,
        store: &keyring_store,
    })
    .resolve()
    {
        Ok(alias) => alias,
        Err(err) => return fail(err),
    };
    job.remote = match resolved_remote_alias {
        Some(alias) => {
            let bucket_config = match keyring_store.bucket_configs().find(|b| b.alias == alias) {
                Some(bucket_config) => bucket_config.clone(),
                None => return fail(format!("no bucket-config named '{alias}'")),
            };
            let secret = match credentials::get_secret(&bucket_config.alias) {
                Ok(secret) => secret,
                Err(err) => return fail(err),
            };
            Some((bucket_config, secret))
        }
        None => None,
    };

    let resolved_encryption_key_alias = match (EncryptionKeyInput {
        flag: encryption_key,
        store: &keyring_store,
        uploading: job.remote.is_some(),
        bucket_default: job
            .remote
            .as_ref()
            .and_then(|(bc, _)| bc.encryption_key_alias.clone()),
    })
    .resolve()
    {
        Ok(alias) => alias,
        Err(err) => return fail(err),
    };
    job.encryptor = match resolved_encryption_key_alias {
        Some(alias) => {
            let key_hex = match credentials::get_secret(&alias) {
                Ok(secret) => secret,
                Err(err) => return fail(err),
            };
            match Aes256GcmSivEncryptor::from_hex_key(&key_hex) {
                Ok(encryptor) => Some(encryptor),
                Err(err) => return fail(err),
            }
        }
        None => None,
    };

    let concurrency = match (ConcurrencyInput { flag: concurrency }).resolve() {
        Ok(value) => value,
        Err(err) => return fail(err),
    };

    match (ConfirmInput { yes }).resolve() {
        Ok(true) => {}
        Ok(false) => {
            println!("Cancelled.");
            return 0;
        }
        Err(err) => return fail(err),
    }

    match job.run(plan, concurrency).await {
        Ok(summary) => {
            println!(
                "Processed {} file(s), {} failed ({} download, {} archive, {} classify, {} placement), {} duplicate(s) skipped, {} recoded, {} kept as original (recode did not verify), {} uploaded, {} unchanged, {} upload failed.",
                summary.processed,
                summary.failed,
                summary.failure_breakdown.download,
                summary.failure_breakdown.archive,
                summary.failure_breakdown.classify,
                summary.failure_breakdown.placement,
                summary.duplicates_skipped,
                summary.recoded,
                summary.recode_fallback_to_original,
                summary.uploaded,
                summary.unchanged,
                summary.upload_failed
            );
            if summary.failed > 0 || summary.upload_failed > 0 {
                FAILURE_EXIT_CODE
            } else {
                0
            }
        }
        Err(err) => fail(err),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_local_output_is_under_the_os_temp_dir() {
        let path = default_local_output();
        assert!(path.starts_with(std::env::temp_dir()));
        assert_eq!(path.file_name().unwrap(), "pigeon-job");
    }

    #[test]
    fn format_bytes_stays_in_bytes_under_a_kib() {
        assert_eq!(format_bytes(512), "512 B");
    }

    #[test]
    fn format_bytes_uses_larger_units_for_larger_sizes() {
        assert_eq!(format_bytes(1024), "1.0 KB");
    }
}
