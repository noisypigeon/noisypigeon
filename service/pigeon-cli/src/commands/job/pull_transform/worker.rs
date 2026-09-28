//! Concurrent download/expand/classify/recode/verify pipeline (ADR-0074
//! §4), a sequential dedup/placement pass (§5, `dedup.rs`), and an optional
//! concurrent upload phase (§6, reusing `commands::job::upload`).

use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use indicatif::MultiProgress;
use sha2::{Digest, Sha256};

use crate::commands::job::email_sync::sink;
use crate::commands::job::upload;
use crate::commands::keyring::bucket::client;
use crate::commands::keyring::bucket::store::BucketConfig;
use crate::core::crypto::Aes256GcmSivEncryptor;
use crate::core::data::ContentIndex;
use crate::core::retry::retry_with_backoff;

use super::archive;
use super::dedup::{self, ProcessedFile, PullTransformDedup};
use super::documents;
use super::manifest::{self, PullTask, extension_of};
use super::media::{self, MediaKind};

const DOWNLOAD_RETRIES: usize = 3;
const DOWNLOAD_RETRY_BACKOFF: Duration = Duration::from_secs(2);
const RECODE_ATTEMPTS: usize = 2;

/// Below this size, a download is fast enough not to need its own named
/// call-out -- the overall progress bar already shows it completing
/// (ADR-0075). At or above it, a `Downloading <key> (<size>)...` line
/// explains why one item might be visibly slower than the rest.
const ANNOUNCE_DOWNLOAD_THRESHOLD_BYTES: u64 = 50 * 1024 * 1024;

/// A plain `123.4 MB` label for a byte count -- these announcements are
/// only ever for large files, so unlike `wizard.rs`'s `format_bytes` (which
/// scales down to bytes/KB for the pre-run summary table) this always
/// renders in MB.
fn format_mb(bytes: u64) -> String {
    format!("{:.1} MB", bytes as f64 / (1024.0 * 1024.0))
}

/// Whether a download of `size` bytes is worth a named call-out (ADR-0075)
/// -- a pure predicate, kept separate from `download()` itself so the
/// threshold logic is unit-testable without capturing progress-bar output.
fn should_announce_download(size: u64) -> bool {
    size >= ANNOUNCE_DOWNLOAD_THRESHOLD_BYTES
}

/// A `failed` count broken down by which stage the failure happened in
/// (same shape as `email_sync::worker::FailureBreakdown`, ADR-0033).
#[derive(Debug, Default)]
pub(crate) struct FailureBreakdown {
    pub download: usize,
    pub archive: usize,
    pub recode: usize,
    pub classify: usize,
    pub placement: usize,
}

impl FailureBreakdown {
    fn merge(&mut self, other: &FailureBreakdown) {
        self.download += other.download;
        self.archive += other.archive;
        self.recode += other.recode;
        self.classify += other.classify;
        self.placement += other.placement;
    }
}

#[derive(Debug, Default)]
pub(crate) struct PullTransformSummary {
    pub processed: usize,
    pub failed: usize,
    pub failure_breakdown: FailureBreakdown,
    pub duplicates_skipped: usize,
    pub recoded: usize,
    pub recode_fallback_to_original: usize,
    pub uploaded: usize,
    pub unchanged: usize,
    pub upload_failed: usize,
}

/// Broad category driving both processing (does this need `ffmpeg`?) and
/// eventual placement.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum FileKind {
    Zip,
    Image,
    Video,
    Audio,
    Pdf,
    Ooxml,
    Other,
}

fn classify_extension(key: &str) -> (FileKind, String) {
    let extension = extension_of(key);
    let kind = match extension.as_str() {
        "zip" => FileKind::Zip,
        "jpg" | "jpeg" | "png" | "heic" | "heif" | "gif" | "bmp" | "tiff" | "tif" | "webp" => {
            FileKind::Image
        }
        "mov" | "mp4" | "m4v" | "avi" | "mkv" | "webm" | "3gp" | "3g2" => FileKind::Video,
        "m4a" | "mp3" | "wav" | "flac" | "aac" | "ogg" | "wma" | "caf" => FileKind::Audio,
        "pdf" => FileKind::Pdf,
        "docx" | "xlsx" | "pptx" => FileKind::Ooxml,
        _ => FileKind::Other,
    };
    (kind, extension)
}

/// One item on the shared work queue -- a top-level bucket object not yet
/// downloaded (`source_key: Some`, `bytes: None`), or a zip member already
/// read into memory during a parent's expansion (`source_key: None`,
/// `bytes: Some`). Only a `depth == 0` item is ever checkpointed --
/// checkpointing tracks "was this top-level object fully handled," not
/// "was every last nested zip member placed" (ADR-0074 §3).
struct QueueItem {
    source_key: Option<String>,
    display_key: String,
    bytes: Option<Vec<u8>>,
    depth: u32,
    /// The object's size in bytes if not yet downloaded (from the bucket
    /// listing), or the already-known size of an in-memory zip member --
    /// used only to decide whether a download is worth announcing
    /// (ADR-0075), never for correctness.
    size: u64,
}

enum FailureCategory {
    Download,
    Archive,
    Classify,
}

enum ItemOutcome {
    /// `display_key`/`depth` identify the zip that was expanded (checkpoint
    /// candidate iff `depth == 0`); `members` are queued for the next pass.
    ZipExpanded {
        display_key: String,
        depth: u32,
        members: Vec<QueueItem>,
    },
    Processed {
        depth: u32,
        file: ProcessedFile,
        recoded: bool,
        fell_back_to_original: bool,
    },
    Failed {
        category: FailureCategory,
    },
}

async fn download(
    bucket_config: &BucketConfig,
    secret: &str,
    key: &str,
    size: u64,
    multi_progress: &MultiProgress,
) -> Result<Vec<u8>, String> {
    if should_announce_download(size) {
        let _ = multi_progress.println(format!("Downloading {key} ({})...", format_mb(size)));
    }
    retry_with_backoff(DOWNLOAD_RETRIES, DOWNLOAD_RETRY_BACKOFF, || {
        client::get_object(bucket_config, secret, key)
    })
    .await
}

fn sha256_hex(bytes: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    hex::encode(hasher.finalize())
}

/// A fresh, not-yet-existing path under `dir` named by `counter`
/// (monotonically increasing, shared across concurrent workers) plus
/// `extension` -- reserved for `ffmpeg` (or some other tool) to write into
/// directly, rather than pre-creating an empty placeholder file.
fn next_scratch_path(dir: &Path, counter: &AtomicU64, extension: &str) -> Result<PathBuf, String> {
    fs::create_dir_all(dir).map_err(|err| format!("failed to create {}: {err}", dir.display()))?;
    let name = counter.fetch_add(1, Ordering::SeqCst);
    Ok(dir.join(format!("{name:012}.{extension}")))
}

/// Writes `bytes` to a fresh path under `dir` (see `next_scratch_path`).
fn write_scratch_file(
    dir: &Path,
    counter: &AtomicU64,
    extension: &str,
    bytes: &[u8],
) -> Result<PathBuf, String> {
    let path = next_scratch_path(dir, counter, extension)?;
    fs::write(&path, bytes).map_err(|err| format!("failed to write {}: {err}", path.display()))?;
    Ok(path)
}

#[allow(clippy::too_many_arguments)]
#[tracing::instrument(
    skip(bytes, tmp_dir, scratch_dir, counter, multi_progress),
    fields(key = %display_key)
)]
async fn process_media(
    display_key: &str,
    extension: &str,
    kind: FileKind,
    bytes: Vec<u8>,
    tmp_dir: &Path,
    scratch_dir: &Path,
    counter: &AtomicU64,
    multi_progress: &MultiProgress,
) -> Result<(ProcessedFile, bool, bool), String> {
    let input_path = write_scratch_file(tmp_dir, counter, extension, &bytes)?;
    let probe_result = media::probe(&input_path).await;
    let _ = fs::remove_file(&input_path);

    let Ok(before) = probe_result else {
        // Couldn't even probe it -- not confidently this file type despite
        // its extension. No loss of data: place the original bytes as-is.
        let scratch_path = write_scratch_file(scratch_dir, counter, extension, &bytes)?;
        return Ok((
            ProcessedFile {
                original_key: display_key.to_string(),
                scratch_path,
                extension: extension.to_string(),
                date: None,
                content_hash: sha256_hex(&bytes),
                is_media: false,
            },
            false,
            true,
        ));
    };

    let (media_kind, date) = match kind {
        FileKind::Image => {
            let date = media::exif_date(&bytes).or(before.creation_date);
            let is_screenshot = before
                .width
                .zip(before.height)
                .is_some_and(|(w, h)| media::is_screenshot_resolution(w, h));
            let media_kind = if is_screenshot {
                MediaKind::Screenshot
            } else {
                MediaKind::Photo
            };
            (media_kind, date)
        }
        FileKind::Video => (MediaKind::Video, before.creation_date),
        FileKind::Audio => (MediaKind::Audio, before.creation_date),
        FileKind::Zip | FileKind::Pdf | FileKind::Ooxml | FileKind::Other => {
            unreachable!("process_media is only called for Image/Video/Audio")
        }
    };

    let input_path = write_scratch_file(tmp_dir, counter, extension, &bytes)?;
    let canonical_extension = media_kind.canonical_extension();
    let output_path = next_scratch_path(tmp_dir, counter, canonical_extension)?;
    let already_aac_m4a = extension.eq_ignore_ascii_case("m4a");

    // Re-encoding is CPU-bound and slow independent of file size, unlike
    // the cheap mjpeg photo/screenshot path below -- always worth naming
    // (ADR-0075), unlike the size-gated download announcement.
    if matches!(media_kind, MediaKind::Video | MediaKind::Audio) {
        let duration = before
            .duration_secs
            .map(|secs| format!("{secs:.1}s"))
            .unwrap_or_else(|| "unknown duration".to_string());
        let dimensions = before
            .width
            .zip(before.height)
            .map(|(w, h)| format!(", {w}x{h}"))
            .unwrap_or_default();
        let _ = multi_progress.println(format!(
            "Recoding {display_key} ({duration}{dimensions})..."
        ));
    }

    let recode_result = recode_and_verify(
        &input_path,
        &output_path,
        media_kind,
        already_aac_m4a,
        before,
    )
    .await;
    let _ = fs::remove_file(&input_path);

    match recode_result {
        Ok(()) => {
            let recoded_bytes = fs::read(&output_path).map_err(|err| {
                format!("failed to read recoded {}: {err}", output_path.display())
            })?;
            let scratch_path =
                write_scratch_file(scratch_dir, counter, canonical_extension, &recoded_bytes)?;
            let _ = fs::remove_file(&output_path);
            Ok((
                ProcessedFile {
                    original_key: display_key.to_string(),
                    scratch_path,
                    extension: canonical_extension.to_string(),
                    date,
                    content_hash: sha256_hex(&recoded_bytes),
                    is_media: true,
                },
                true,
                false,
            ))
        }
        Err(err) => {
            tracing::warn!(
                key = %display_key,
                step = "recode",
                error = %err,
                "recode did not verify after retries, keeping original file"
            );
            let _ = fs::remove_file(&output_path);
            let scratch_path = write_scratch_file(scratch_dir, counter, extension, &bytes)?;
            Ok((
                ProcessedFile {
                    original_key: display_key.to_string(),
                    scratch_path,
                    extension: extension.to_string(),
                    date,
                    content_hash: sha256_hex(&bytes),
                    is_media: date.is_some(),
                },
                false,
                true,
            ))
        }
    }
}

async fn recode_and_verify(
    input_path: &Path,
    output_path: &Path,
    kind: MediaKind,
    already_aac_m4a: bool,
    before: media::ProbeInfo,
) -> Result<(), String> {
    let mut last_err = None;
    for attempt in 1..=RECODE_ATTEMPTS {
        let outcome = match media::recode(input_path, output_path, kind, already_aac_m4a).await {
            Ok(()) => media::verify(before, output_path).await,
            Err(err) => Err(err),
        };
        match outcome {
            Ok(()) => return Ok(()),
            Err(err) => {
                tracing::warn!(attempt, attempts = RECODE_ATTEMPTS, error = %err, "recode attempt failed");
                last_err = Some(err);
            }
        }
    }
    Err(last_err.unwrap_or_else(|| "recode failed for an unknown reason".to_string()))
}

fn process_document_or_other(
    display_key: &str,
    extension: &str,
    kind: FileKind,
    bytes: Vec<u8>,
    scratch_dir: &Path,
    counter: &AtomicU64,
) -> Result<(ProcessedFile, bool, bool), String> {
    let date = match kind {
        FileKind::Pdf => documents::pdf_date(&bytes),
        FileKind::Ooxml => documents::ooxml_date(&bytes),
        FileKind::Other => None,
        FileKind::Zip | FileKind::Image | FileKind::Video | FileKind::Audio => {
            unreachable!("process_document_or_other is only called for Pdf/Ooxml/Other")
        }
    };
    let scratch_path = write_scratch_file(scratch_dir, counter, extension, &bytes)?;
    Ok((
        ProcessedFile {
            original_key: display_key.to_string(),
            scratch_path,
            extension: extension.to_string(),
            date,
            content_hash: sha256_hex(&bytes),
            is_media: false,
        },
        false,
        false,
    ))
}

#[allow(clippy::too_many_arguments)]
async fn process_item(
    bucket_config: &BucketConfig,
    secret: &str,
    item: QueueItem,
    tmp_dir: &Path,
    scratch_dir: &Path,
    counter: &AtomicU64,
    extracted_bytes: &AtomicU64,
    multi_progress: &MultiProgress,
) -> ItemOutcome {
    let depth = item.depth;
    let bytes = match item.bytes {
        Some(bytes) => bytes,
        None => {
            let key = item.source_key.as_deref().unwrap_or(&item.display_key);
            match download(bucket_config, secret, key, item.size, multi_progress).await {
                Ok(bytes) => bytes,
                Err(err) => {
                    tracing::warn!(key = %item.display_key, step = "download", error = %err, "download failed");
                    return ItemOutcome::Failed {
                        category: FailureCategory::Download,
                    };
                }
            }
        }
    };

    let (kind, extension) = classify_extension(&item.display_key);

    if kind == FileKind::Zip {
        if depth >= archive::MAX_ZIP_DEPTH {
            tracing::warn!(key = %item.display_key, step = "archive", depth, "zip nesting depth cap reached, not expanding further");
            return ItemOutcome::Failed {
                category: FailureCategory::Archive,
            };
        }
        return match archive::expand(&bytes) {
            Ok(raw_members) => {
                let mut members = Vec::with_capacity(raw_members.len());
                for member in raw_members {
                    let member_size = member.bytes.len() as u64;
                    let total = extracted_bytes.fetch_add(member_size, Ordering::SeqCst);
                    if total > archive::MAX_TOTAL_EXTRACTED_BYTES {
                        tracing::warn!(
                            key = %item.display_key,
                            step = "archive",
                            "total extracted-bytes cap reached, dropping remaining members of this archive"
                        );
                        break;
                    }
                    members.push(QueueItem {
                        source_key: None,
                        display_key: format!("{}!{}", item.display_key, member.name),
                        bytes: Some(member.bytes),
                        depth: depth + 1,
                        size: member_size,
                    });
                }
                ItemOutcome::ZipExpanded {
                    display_key: item.display_key,
                    depth,
                    members,
                }
            }
            Err(err) => {
                tracing::warn!(key = %item.display_key, step = "archive", error = %err, "failed to open zip archive");
                ItemOutcome::Failed {
                    category: FailureCategory::Archive,
                }
            }
        };
    }

    let processed = match kind {
        FileKind::Image | FileKind::Video | FileKind::Audio => {
            process_media(
                &item.display_key,
                &extension,
                kind,
                bytes,
                tmp_dir,
                scratch_dir,
                counter,
                multi_progress,
            )
            .await
        }
        FileKind::Pdf | FileKind::Ooxml | FileKind::Other => process_document_or_other(
            &item.display_key,
            &extension,
            kind,
            bytes,
            scratch_dir,
            counter,
        ),
        FileKind::Zip => unreachable!("handled above"),
    };

    match processed {
        Ok((file, recoded, fell_back)) => ItemOutcome::Processed {
            depth,
            file,
            recoded,
            fell_back_to_original: fell_back,
        },
        Err(err) => {
            tracing::warn!(key = %item.display_key, step = "classify", error = %err, "failed to process file");
            ItemOutcome::Failed {
                category: FailureCategory::Classify,
            }
        }
    }
}

/// Runs the full pull-transform pipeline: lists already come in via `tasks`
/// (from `Job::gather`, already filtered against the `.processed`
/// checkpoint by the wizard); downloads/expands/classifies/recodes/verifies
/// them concurrently at `concurrency`, places the results sequentially
/// (dedup + naming), then uploads (if `remote` is given).
pub(crate) async fn run_pull_transform_job(
    bucket_config: &BucketConfig,
    secret: &str,
    local_output: &Path,
    tasks: Vec<PullTask>,
    concurrency: usize,
    remote: Option<(&BucketConfig, &str)>,
    encryptor: Option<&Aes256GcmSivEncryptor>,
) -> Result<PullTransformSummary, String> {
    let tmp_dir = local_output.join(".staging").join("tmp");
    let scratch_dir = local_output.join(".staging").join("scratch");
    let counter = Arc::new(AtomicU64::new(0));
    let extracted_bytes = Arc::new(AtomicU64::new(0));

    // One `MultiProgress` spans the whole run -- main phase, placement, and
    // (if uploading) upload -- matching `email_sync::worker`'s own shape
    // (ADR-0075).
    let multi_progress = MultiProgress::new();
    let total = tasks.len() as u64;
    let _ = multi_progress.println(format!("Downloading and processing {total} object(s)..."));
    let bar = sink::new_progress_bar("pull-transform".to_string(), total, &multi_progress);

    let queue: Arc<Mutex<std::collections::VecDeque<QueueItem>>> = Arc::new(Mutex::new(
        tasks
            .into_iter()
            .map(|task| QueueItem {
                source_key: Some(task.key.clone()),
                display_key: task.key,
                bytes: None,
                depth: 0,
                size: task.size,
            })
            .collect(),
    ));
    let in_flight = Arc::new(std::sync::atomic::AtomicUsize::new(0));

    let processed_files = Arc::new(Mutex::new(Vec::<ProcessedFile>::new()));
    let finished_root_keys = Arc::new(Mutex::new(Vec::<String>::new()));
    let failure_breakdown = Arc::new(Mutex::new(FailureBreakdown::default()));
    let recoded_count = Arc::new(std::sync::atomic::AtomicUsize::new(0));
    let fallback_count = Arc::new(std::sync::atomic::AtomicUsize::new(0));

    let worker_count = concurrency.max(1);
    let mut handles = Vec::with_capacity(worker_count);
    for _ in 0..worker_count {
        let queue = Arc::clone(&queue);
        let in_flight = Arc::clone(&in_flight);
        let processed_files = Arc::clone(&processed_files);
        let finished_root_keys = Arc::clone(&finished_root_keys);
        let failure_breakdown = Arc::clone(&failure_breakdown);
        let recoded_count = Arc::clone(&recoded_count);
        let fallback_count = Arc::clone(&fallback_count);
        let counter = Arc::clone(&counter);
        let extracted_bytes = Arc::clone(&extracted_bytes);
        let bucket_config = bucket_config.clone();
        let secret = secret.to_string();
        let tmp_dir = tmp_dir.clone();
        let scratch_dir = scratch_dir.clone();
        let multi_progress = multi_progress.clone();
        let bar = bar.clone();

        handles.push(tokio::spawn(async move {
            loop {
                let item = { queue.lock().unwrap().pop_front() };
                let Some(item) = item else {
                    if in_flight.load(Ordering::SeqCst) == 0 {
                        break;
                    }
                    tokio::time::sleep(Duration::from_millis(10)).await;
                    continue;
                };
                in_flight.fetch_add(1, Ordering::SeqCst);

                let outcome = process_item(
                    &bucket_config,
                    &secret,
                    item,
                    &tmp_dir,
                    &scratch_dir,
                    &counter,
                    &extracted_bytes,
                    &multi_progress,
                )
                .await;

                match outcome {
                    ItemOutcome::ZipExpanded {
                        display_key,
                        depth,
                        members,
                    } => {
                        bar.inc_length(members.len() as u64);
                        queue.lock().unwrap().extend(members);
                        if depth == 0 {
                            finished_root_keys.lock().unwrap().push(display_key);
                        }
                    }
                    ItemOutcome::Processed {
                        depth,
                        file,
                        recoded,
                        fell_back_to_original,
                    } => {
                        if depth == 0 {
                            finished_root_keys
                                .lock()
                                .unwrap()
                                .push(file.original_key.clone());
                        }
                        if recoded {
                            recoded_count.fetch_add(1, Ordering::SeqCst);
                        }
                        if fell_back_to_original {
                            fallback_count.fetch_add(1, Ordering::SeqCst);
                        }
                        processed_files.lock().unwrap().push(file);
                    }
                    ItemOutcome::Failed { category, .. } => {
                        let mut breakdown = failure_breakdown.lock().unwrap();
                        match category {
                            FailureCategory::Download => breakdown.download += 1,
                            FailureCategory::Archive => breakdown.archive += 1,
                            FailureCategory::Classify => breakdown.classify += 1,
                        }
                    }
                }

                bar.inc(1);
                in_flight.fetch_sub(1, Ordering::SeqCst);
            }
        }));
    }

    let mut first_panic = None;
    for handle in handles {
        if let Err(err) = handle.await {
            tracing::error!(error = %err, "pull-transform worker task panicked");
            if first_panic.is_none() {
                first_panic = Some(format!("worker task panicked: {err}"));
            }
        }
    }
    if let Some(err) = first_panic {
        return Err(err);
    }
    bar.finish();

    let files = Arc::try_unwrap(processed_files)
        .map_err(|_| "internal error: processed file list still shared".to_string())?
        .into_inner()
        .map_err(|_| "internal error: processed file list lock poisoned".to_string())?;
    let mut finished_root_keys = Arc::try_unwrap(finished_root_keys)
        .map_err(|_| "internal error: finished-key list still shared".to_string())?
        .into_inner()
        .map_err(|_| "internal error: finished-key list lock poisoned".to_string())?;
    let failure_breakdown = Arc::try_unwrap(failure_breakdown)
        .map_err(|_| "internal error: failure breakdown still shared".to_string())?
        .into_inner()
        .map_err(|_| "internal error: failure breakdown lock poisoned".to_string())?;

    let mut dedup = PullTransformDedup(ContentIndex::load(
        local_output,
        dedup::CONTENT_HASHES_FILE,
    )?);
    let (placement_summary, placed_keys) =
        dedup::place_files(local_output, files, &mut dedup, &multi_progress);
    let placed_keys: HashSet<String> = placed_keys.into_iter().collect();

    // A root key is only checkpointed once every file it produced (itself,
    // for a non-zip; every extracted member, for a zip) actually finished
    // placement -- a zip whose expansion succeeded but whose *members*
    // never reached `place_files` (worker task panic notwithstanding, which
    // already aborts the whole run above) still only gets checkpointed via
    // this same mechanism, since `finished_root_keys` already only contains
    // depth-0 keys.
    finished_root_keys.retain(|key| placed_keys.contains(key) || is_zip_key(key));
    let mut summary = PullTransformSummary {
        processed: placement_summary.placed,
        failed: failure_breakdown.download
            + failure_breakdown.archive
            + failure_breakdown.classify
            + placement_summary.failed,
        duplicates_skipped: placement_summary.duplicates_skipped,
        recoded: recoded_count.load(Ordering::SeqCst),
        recode_fallback_to_original: fallback_count.load(Ordering::SeqCst),
        ..Default::default()
    };
    summary.failure_breakdown.merge(&failure_breakdown);
    summary.failure_breakdown.placement = placement_summary.failed;

    for key in &finished_root_keys {
        manifest::append_checkpoint(local_output, key)?;
    }

    if let Some((remote_bucket, remote_secret)) = remote {
        let (tasks, uploaded_index) = upload::pending_upload_tasks(
            &bucket_config.alias,
            local_output,
            local_output,
            local_output,
            encryptor.is_some(),
        )?;
        let mut uploaded_indexes = std::collections::HashMap::new();
        uploaded_indexes.insert(
            local_output.to_path_buf(),
            Arc::new(Mutex::new(uploaded_index)),
        );
        let upload_summary = upload::run_upload_phase(
            tasks,
            &uploaded_indexes,
            remote_bucket,
            remote_secret,
            encryptor,
            concurrency,
            &multi_progress,
        )
        .await;
        summary.uploaded = upload_summary.uploaded;
        summary.unchanged = upload_summary.unchanged;
        summary.upload_failed = upload_summary.upload_failed;
    }

    Ok(summary)
}

/// A zip whose expansion succeeded is checkpoint-eligible even though its
/// own key never appears in `place_files`'s "placed" list (a zip is never
/// itself placed -- only its extracted members are, each under their own
/// synthetic `"<zip-key>!<member>"` key).
fn is_zip_key(key: &str) -> bool {
    classify_extension(key).0 == FileKind::Zip
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn should_announce_download_is_false_below_the_threshold() {
        assert!(!should_announce_download(
            ANNOUNCE_DOWNLOAD_THRESHOLD_BYTES - 1
        ));
        assert!(!should_announce_download(1024));
    }

    #[test]
    fn should_announce_download_is_true_at_and_above_the_threshold() {
        assert!(should_announce_download(ANNOUNCE_DOWNLOAD_THRESHOLD_BYTES));
        assert!(should_announce_download(
            ANNOUNCE_DOWNLOAD_THRESHOLD_BYTES + 1
        ));
    }

    #[test]
    fn format_mb_renders_one_decimal_place() {
        assert_eq!(format_mb(50 * 1024 * 1024), "50.0 MB");
        assert_eq!(format_mb(1024 * 1024 + 512 * 1024), "1.5 MB");
    }

    #[test]
    fn classify_extension_recognizes_common_media_and_document_types() {
        assert_eq!(classify_extension("a.jpg").0, FileKind::Image);
        assert_eq!(classify_extension("a.JPEG").0, FileKind::Image);
        assert_eq!(classify_extension("a.mov").0, FileKind::Video);
        assert_eq!(classify_extension("a.m4a").0, FileKind::Audio);
        assert_eq!(classify_extension("a.zip").0, FileKind::Zip);
        assert_eq!(classify_extension("a.pdf").0, FileKind::Pdf);
        assert_eq!(classify_extension("a.docx").0, FileKind::Ooxml);
        assert_eq!(classify_extension("a.txt").0, FileKind::Other);
    }

    #[test]
    fn write_scratch_file_produces_unique_paths() {
        let dir = tempfile::tempdir().unwrap();
        let counter = AtomicU64::new(0);
        let a = write_scratch_file(dir.path(), &counter, "jpg", b"a").unwrap();
        let b = write_scratch_file(dir.path(), &counter, "jpg", b"b").unwrap();
        assert_ne!(a, b);
        assert_eq!(fs::read(a).unwrap(), b"a");
        assert_eq!(fs::read(b).unwrap(), b"b");
    }

    /// End-to-end regression coverage for `process_media` against a real
    /// `ffmpeg`-generated clip -- classify -> probe -> recode -> verify,
    /// exactly as `process_item` drives it. Skipped (not failed) if
    /// `ffmpeg` isn't on `PATH`, same reasoning as `media`'s own tests.
    #[tokio::test]
    async fn process_media_recodes_a_real_video_to_mp4() {
        if media::check_ffmpeg_available().await.is_err() {
            eprintln!("skipping: ffmpeg/ffprobe not found on PATH");
            return;
        }
        let dir = tempfile::tempdir().unwrap();
        let source = dir.path().join("clip.mov");
        let output = tokio::process::Command::new("ffmpeg")
            .args([
                "-y",
                "-loglevel",
                "error",
                "-f",
                "lavfi",
                "-i",
                "testsrc=size=320x240:duration=1:rate=10",
                "-pix_fmt",
                "yuv420p",
            ])
            .arg(&source)
            .output()
            .await
            .unwrap();
        assert!(output.status.success());
        let bytes = fs::read(&source).unwrap();

        let tmp_dir = dir.path().join("tmp");
        let scratch_dir = dir.path().join("scratch");
        let counter = AtomicU64::new(0);

        let (file, recoded, fell_back) = process_media(
            "clips/clip.mov",
            "mov",
            FileKind::Video,
            bytes,
            &tmp_dir,
            &scratch_dir,
            &counter,
            &MultiProgress::new(),
        )
        .await
        .unwrap();

        assert!(recoded);
        assert!(!fell_back);
        assert_eq!(file.extension, "mp4");
        assert!(file.is_media);
        assert!(file.scratch_path.exists());
        assert!(!file.content_hash.is_empty());
    }
}
