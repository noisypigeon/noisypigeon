use std::collections::{HashMap, HashSet, VecDeque};
use std::fs;
use std::future::Future;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use futures::{StreamExt, stream};
use indicatif::{MultiProgress, ProgressBar};
use tokio::sync::{OwnedSemaphorePermit, Semaphore};

use crate::commands::keyring::bucket::client;
use crate::commands::keyring::bucket::store::BucketConfig;
use crate::commands::keyring::email::identity;
use crate::commands::keyring::email::imap_client::{self, ImapSession};
use crate::core::crypto::{Aes256GcmSivEncryptor, Encryptor};
use crate::core::data::{ContentIndex, Transform, collect_files};

use super::dedup::{self, EmailDedup};
use super::manifest::{self, Batch, CheckpointEntry};
use super::sink;
use super::transform::{self, EmailTransform};
use super::{IdentityContext, PendingMailbox};

const CONNECT_RETRIES: usize = 3;
const RETRY_BACKOFF: Duration = Duration::from_secs(5);

/// How many extra times a batch that failed to connect/`EXAMINE`/fetch is
/// requeued before its UIDs are counted as failed for this run (ADR-0071) --
/// 2 extra attempts (3 total), matching `CONNECT_RETRIES`'s order of
/// magnitude. Unlike `retry_with_backoff` (which retries one already-chosen
/// operation in place), this retries at the *queue* level, since a batch
/// failure can mean the IMAP session itself died and needs a fresh
/// connection, not just a repeated command.
const BATCH_RETRIES: u8 = 2;
const BATCH_RETRY_BACKOFF: Duration = Duration::from_secs(2);

/// Retries `f` up to `attempts` times, sleeping `backoff * attempt_number`
/// between tries (linear: `backoff`, `2*backoff`, ...) before giving up --
/// absorbs a transient provider-side throttle (e.g. a burst of
/// `concurrency` workers all connecting within the same instant at job
/// start) instead of failing on the first timeout. Generic over `f` so it's
/// testable without any real I/O (see the unit tests below).
pub(crate) async fn retry_with_backoff<T, F, Fut>(
    attempts: usize,
    backoff: Duration,
    mut f: F,
) -> Result<T, String>
where
    F: FnMut() -> Fut,
    Fut: Future<Output = Result<T, String>>,
{
    let mut last_err = None;
    for attempt in 0..attempts.max(1) {
        if attempt > 0 {
            tokio::time::sleep(backoff * attempt as u32).await;
        }
        match f().await {
            Ok(value) => return Ok(value),
            Err(err) => {
                tracing::warn!(
                    attempt = attempt + 1,
                    attempts,
                    error = %err,
                    "retrying after error"
                );
                last_err = Some(err);
            }
        }
    }
    if let Some(err) = &last_err {
        tracing::error!(attempts, error = %err, "retries exhausted");
    }
    Err(last_err.unwrap_or_else(|| "retry_with_backoff called with zero attempts".to_string()))
}

/// Connects and logs in to `ctx`'s identity, retrying on failure per
/// `retry_with_backoff` (ADR-0021 §6 addendum) -- used by `gather_pending`'s
/// one-shot per-identity connection and by each persistent worker's initial
/// connect/reconnect (`run_worker`, below).
#[tracing::instrument(skip(ctx), fields(identity = %ctx.identity.alias))]
pub(crate) async fn connect_with_retry(ctx: &IdentityContext) -> Result<ImapSession, String> {
    retry_with_backoff(CONNECT_RETRIES, RETRY_BACKOFF, || {
        imap_client::connect_and_login(
            &ctx.identity.host,
            ctx.identity.port,
            &ctx.identity.email,
            &ctx.secret,
            ctx.identity.provider.accepts_invalid_certs(),
        )
    })
    .await
}

/// A `failed` count broken down by cause (ADR-0033 #37/#38, extended by
/// ADR-0071): IMAP connect failure, `EXAMINE` failure, any other batch-level
/// hard error, a per-UID `verify_transformed` structural failure, a per-UID
/// lenient `EmailTransform::transform` parse-skip, and a UID whose `.eml`
/// was never written by the fetch phase (`missing_file` -- distinct from
/// `parse_skipped`, which is a genuine unparseable/malformed message).
/// Always sums to the flat `failed` counter it sits alongside -- nothing
/// downstream reading that flat total breaks.
#[derive(Debug, Default)]
pub(crate) struct FailureBreakdown {
    pub connect: usize,
    pub examine: usize,
    pub batch_error: usize,
    pub verification: usize,
    pub parse_skipped: usize,
    pub missing_file: usize,
}

impl FailureBreakdown {
    fn merge(&mut self, other: &FailureBreakdown) {
        self.connect += other.connect;
        self.examine += other.examine;
        self.batch_error += other.batch_error;
        self.verification += other.verification;
        self.parse_skipped += other.parse_skipped;
        self.missing_file += other.missing_file;
    }
}

/// Outcome of one worker's processing, for the job-level summary.
#[derive(Default)]
struct BatchOutcome {
    synced: usize,
    failed: usize,
    attachments_staged: usize,
    failure_breakdown: FailureBreakdown,
}

/// A worker's currently-open IMAP session, if any -- tracks which identity
/// and mailbox it's scoped to, so `run_worker` can tell whether its next
/// batch needs a full reconnect (different identity -> different
/// credentials) or just a re-`EXAMINE` (same identity, different mailbox --
/// cheap, no new TCP/TLS/LOGIN) before it can be processed. `_permit` holds
/// this identity's connection-count slot (ADR-0071) for as long as this
/// session is open, releasing it automatically (via `Drop`) whenever the
/// connection is replaced or the worker exits -- never read, only held.
struct WorkerConnection {
    identity_index: usize,
    mailbox: String,
    session: ImapSession,
    _permit: OwnedSemaphorePermit,
}

/// After a batch fails (connect, `EXAMINE`, or fetch/transform), either
/// sleeps briefly and returns a requeue-able item with one fewer attempt
/// remaining, or `None` once retries are exhausted (ADR-0071) -- the caller
/// tallies the failure into its `BatchOutcome` only in the `None` case.
/// Batch-level (not in-place) retry: a fetch failure can mean the IMAP
/// session itself died, so simply retrying the last command in place
/// (`retry_with_backoff`'s approach for connect/upload) isn't enough here --
/// the batch needs to flow back through `run_worker`'s normal
/// connect/`EXAMINE`/fetch path, possibly on a different worker.
async fn requeue_or_none(
    identity_index: usize,
    batch: Batch,
    attempts_remaining: u8,
    backoff: Duration,
) -> Option<(usize, Batch, u8)> {
    if attempts_remaining == 0 {
        return None;
    }
    tokio::time::sleep(backoff).await;
    Some((identity_index, batch, attempts_remaining - 1))
}

/// Pulls `(identity_index, Batch, attempts_remaining)` items from `queue`
/// until it's drained, holding one IMAP session per identity for as long as
/// consecutive batches it pulls belong to that identity (ADR-0021 §6
/// addendum) -- the direct fix for the connection-churn bug: a job with
/// `concurrency` workers now opens on the order of `concurrency` connections
/// total over its whole run, not one per batch.
///
/// Before opening a new connection, a worker acquires a permit from
/// `identity_semaphores[identity_index]` (ADR-0071) -- capping how many
/// workers can be connected to any one identity at once, independent of the
/// job's overall `concurrency`, which is what actually prevents a burst of
/// workers from tripping a provider's simultaneous-connection limit. A
/// worker whose target identity is already at its cap simply waits for a
/// permit instead of opening a connection that would likely be rejected.
///
/// A connect/re-`EXAMINE`/fetch failure (even after `connect_with_retry`'s
/// in-place retries) drops the current session and either requeues the
/// batch for another attempt or, once retries are exhausted, counts its
/// UIDs as failed -- then moves on to the next queued batch, which may
/// belong to a different, unaffected identity -- rather than aborting the
/// worker outright.
async fn run_worker(
    queue: Arc<Mutex<VecDeque<(usize, Batch, u8)>>>,
    identities: Arc<Vec<IdentityContext>>,
    identity_semaphores: Arc<Vec<Arc<Semaphore>>>,
    multi_progress: MultiProgress,
) -> BatchOutcome {
    let mut connection: Option<WorkerConnection> = None;
    let mut outcome = BatchOutcome::default();

    loop {
        let next = { queue.lock().unwrap().pop_front() };
        let Some((identity_index, batch, attempts_remaining)) = next else {
            break;
        };
        let ctx = &identities[identity_index];

        if connection
            .as_ref()
            .is_none_or(|conn| conn.identity_index != identity_index)
        {
            if let Some(mut conn) = connection.take() {
                let _ = conn.session.logout().await;
            }
            let permit = identity_semaphores[identity_index]
                .clone()
                .acquire_owned()
                .await
                .expect("identity semaphores are never closed");
            match connect_with_retry(ctx).await {
                Ok(session) => {
                    connection = Some(WorkerConnection {
                        identity_index,
                        mailbox: String::new(),
                        session,
                        _permit: permit,
                    });
                }
                Err(err) => {
                    let _ = multi_progress.println(format!("Error: {err}"));
                    let uid_count = batch.uids.len();
                    let mailbox = batch.mailbox.clone();
                    match requeue_or_none(
                        identity_index,
                        batch,
                        attempts_remaining,
                        BATCH_RETRY_BACKOFF,
                    )
                    .await
                    {
                        Some(item) => {
                            tracing::warn!(
                                identity = %ctx.identity.alias,
                                mailbox,
                                step = "connect",
                                attempts_remaining = item.2,
                                "requeueing batch after connect failure"
                            );
                            queue.lock().unwrap().push_back(item)
                        }
                        None => {
                            tracing::error!(
                                identity = %ctx.identity.alias,
                                mailbox,
                                step = "connect",
                                uid_count,
                                "batch retries exhausted, dropping"
                            );
                            outcome.failed += uid_count;
                            outcome.failure_breakdown.connect += uid_count;
                        }
                    }
                    continue;
                }
            }
        }

        let conn = connection.as_mut().unwrap();
        if conn.mailbox != batch.mailbox {
            match conn.session.examine(&batch.mailbox).await {
                Ok(_) => conn.mailbox = batch.mailbox.clone(),
                Err(err) => {
                    let _ = multi_progress.println(format!(
                        "Error: failed to open '{}' read-only: {err}",
                        batch.mailbox
                    ));
                    connection = None;
                    let uid_count = batch.uids.len();
                    let mailbox = batch.mailbox.clone();
                    match requeue_or_none(
                        identity_index,
                        batch,
                        attempts_remaining,
                        BATCH_RETRY_BACKOFF,
                    )
                    .await
                    {
                        Some(item) => {
                            tracing::warn!(
                                identity = %ctx.identity.alias,
                                mailbox,
                                step = "examine",
                                attempts_remaining = item.2,
                                "requeueing batch after EXAMINE failure"
                            );
                            queue.lock().unwrap().push_back(item)
                        }
                        None => {
                            tracing::error!(
                                identity = %ctx.identity.alias,
                                mailbox,
                                step = "examine",
                                uid_count,
                                "batch retries exhausted, dropping"
                            );
                            outcome.failed += uid_count;
                            outcome.failure_breakdown.examine += uid_count;
                        }
                    }
                    continue;
                }
            }
        }

        let conn = connection.as_mut().unwrap();
        match process_batch_on_session(ctx, &batch, &mut conn.session, &multi_progress).await {
            Ok(batch_outcome) => {
                outcome.synced += batch_outcome.synced;
                outcome.failed += batch_outcome.failed;
                outcome.attachments_staged += batch_outcome.attachments_staged;
                outcome
                    .failure_breakdown
                    .merge(&batch_outcome.failure_breakdown);
            }
            Err(err) => {
                let _ = multi_progress.println(format!("Error: {err}"));
                connection = None;
                let uid_count = batch.uids.len();
                let mailbox = batch.mailbox.clone();
                match requeue_or_none(
                    identity_index,
                    batch,
                    attempts_remaining,
                    BATCH_RETRY_BACKOFF,
                )
                .await
                {
                    Some(item) => {
                        tracing::warn!(
                            identity = %ctx.identity.alias,
                            mailbox,
                            step = "batch",
                            attempts_remaining = item.2,
                            "requeueing batch after processing failure"
                        );
                        queue.lock().unwrap().push_back(item)
                    }
                    None => {
                        tracing::error!(
                            identity = %ctx.identity.alias,
                            mailbox,
                            step = "batch",
                            uid_count,
                            "batch retries exhausted, dropping"
                        );
                        outcome.failed += uid_count;
                        outcome.failure_breakdown.batch_error += uid_count;
                    }
                }
            }
        }
    }

    if let Some(mut conn) = connection {
        let _ = conn.session.logout().await;
    }

    outcome
}

/// Fetches, transforms, and verifies every UID in `batch` on an
/// already-connected, already-`EXAMINE`d `session` (owned by the calling
/// `run_worker`, reused across every batch it processes for the same
/// identity/mailbox), appending a checkpoint entry for each UID that
/// verifies and deleting its `.eml` -- no lock of any kind, since a batch's
/// UIDs are staged under a UID-keyed tree exclusive to this worker
/// (ADR-0021 §7/§10, addendum).
#[tracing::instrument(
    skip(ctx, batch, session, multi_progress),
    fields(identity = %ctx.identity.alias, mailbox = %batch.mailbox, uid_count = batch.uids.len()),
    err
)]
async fn process_batch_on_session(
    ctx: &IdentityContext,
    batch: &Batch,
    session: &mut ImapSession,
    multi_progress: &MultiProgress,
) -> Result<BatchOutcome, String> {
    let mailbox_dir = ctx.staging_dir.join(&batch.mailbox_relpath);
    fs::create_dir_all(&mailbox_dir)
        .map_err(|err| format!("failed to create {}: {err}", mailbox_dir.display()))?;

    sink::fetch_uids(
        session,
        &batch.mailbox,
        &mailbox_dir,
        &batch.uids,
        multi_progress,
    )
    .await?;

    let transformer = EmailTransform {
        identity: ctx.identity.clone(),
        input_root: ctx.staging_dir.clone(),
        staging_root: ctx.staging_dir.clone(),
    };

    let mut outcome = BatchOutcome::default();
    for uid in &batch.uids {
        let eml_path = mailbox_dir.join(format!("{uid}.eml"));
        // A UID whose `.eml` was never written -- the fetch phase above
        // errored partway through, or silently dropped a FETCH response
        // missing a body (`sink::fetch_uids`) -- is tallied and skipped
        // here, before ever calling `transform()`, rather than letting it
        // fail the read and print its own per-UID warning (ADR-0071). A
        // single collapsed warning covers the whole batch below instead of
        // one line per missing file.
        if !eml_path.exists() {
            tracing::warn!(uid, mailbox = %batch.mailbox, step = "fetch", "eml missing before transform, counted as failed");
            outcome.failed += 1;
            outcome.failure_breakdown.missing_file += 1;
            continue;
        }
        let transformed = multi_progress
            .suspend(|| transformer.transform(eml_path.clone()))
            .inspect_err(
                |err| tracing::error!(uid, mailbox = %batch.mailbox, step = "transform", error = %err, "transform failed"),
            )?;
        match transformed {
            Some(transformed) => match transform::verify_transformed(&transformed) {
                Ok(()) => {
                    outcome.attachments_staged += transformed.attachments.len();
                    manifest::append_checkpoint(
                        &ctx.staging_dir,
                        &CheckpointEntry {
                            mailbox: batch.mailbox.clone(),
                            uid: *uid,
                            message_hash: transformed.message_hash,
                            md_staged_relpath: transformed.md_staged_relpath,
                            desired_md_name: transformed.desired_md_name,
                            mailbox_tag: transformed.mailbox_tag,
                            attachments: transformed
                                .attachments
                                .into_iter()
                                .map(|attachment| (attachment.hash, attachment.staged_relpath))
                                .collect(),
                        },
                    )?;
                    let _ = fs::remove_file(&eml_path);
                    outcome.synced += 1;
                }
                Err(reason) => {
                    tracing::warn!(
                        uid,
                        mailbox = %batch.mailbox,
                        step = "verify",
                        file = %eml_path.display(),
                        error = %reason,
                        "verification failed"
                    );
                    let _ = multi_progress.println(format!(
                        "Warning: verification failed for UID {uid} in '{}', keeping {}: {reason}",
                        batch.mailbox,
                        eml_path.display()
                    ));
                    outcome.failed += 1;
                    outcome.failure_breakdown.verification += 1;
                }
            },
            None => {
                tracing::warn!(uid, mailbox = %batch.mailbox, step = "transform", "message parse skipped");
                outcome.failed += 1;
                outcome.failure_breakdown.parse_skipped += 1;
            }
        }
    }

    if outcome.failure_breakdown.missing_file > 0 {
        let _ = multi_progress.println(format!(
            "Warning: {} of {} message(s) in '{}' were missing from staging (fetch likely \
             failed); they'll be retried next run",
            outcome.failure_breakdown.missing_file,
            batch.uids.len(),
            batch.mailbox
        ));
    }

    Ok(outcome)
}

/// One file queued for upload, carrying everything the concurrent upload
/// phase needs without re-deriving it: which identity's `.uploaded` index
/// to commit into, the absolute path to read, and its already-computed S3
/// key.
struct UploadTask {
    identity: String,
    staging_dir: PathBuf,
    path: PathBuf,
    key: String,
}

const UPLOAD_RETRIES: usize = 3;
const UPLOAD_RETRY_BACKOFF: Duration = Duration::from_secs(2);

const UPLOADED_FILE_NAME: &str = ".uploaded";

/// Tracks which output files (by their S3 key, per `upload_key`) have
/// already been confirmed uploaded, so a resumed/re-run upload phase can
/// skip them without a redundant network round-trip. Purely a
/// resumability-speed optimization, not a correctness requirement --
/// `client::upload_if_changed`'s ETag comparison is already idempotent on
/// its own.
struct UploadedIndex {
    uploaded: HashSet<String>,
}

impl UploadedIndex {
    fn load(staging_dir: &Path) -> Result<UploadedIndex, String> {
        let path = staging_dir.join(UPLOADED_FILE_NAME);
        let contents = match fs::read_to_string(&path) {
            Ok(contents) => contents,
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => String::new(),
            Err(err) => return Err(format!("failed to read {}: {err}", path.display())),
        };
        Ok(UploadedIndex {
            uploaded: contents.lines().map(str::to_string).collect(),
        })
    }

    fn contains(&self, key: &str) -> bool {
        self.uploaded.contains(key)
    }

    fn commit(&mut self, staging_dir: &Path, key: &str) -> Result<(), String> {
        use std::io::Write;
        let path = staging_dir.join(UPLOADED_FILE_NAME);
        let mut file = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&path)
            .map_err(|err| format!("failed to open {}: {err}", path.display()))?;
        writeln!(file, "{key}")
            .map_err(|err| format!("failed to write {}: {err}", path.display()))?;
        self.uploaded.insert(key.to_string());
        Ok(())
    }
}

/// The S3 key for `path` (an absolute path rooted at `output_dir`):
/// `output_dir`'s relative tree mirrored directly at the bucket root, per
/// ADR-0011. Joined component-wise rather than via `to_string_lossy()` on
/// the whole relative path so the key always uses `/`, regardless of the
/// host platform's path separator. When `encrypt` is true, appends `.enc`
/// so the final key is what actually gets uploaded (ciphertext) and is what
/// `UploadedIndex`/`client::upload_if_changed` key off of -- computed once,
/// here, rather than branched again at upload time (ADR-0025).
fn upload_key(output_dir: &Path, path: &Path, encrypt: bool) -> Result<String, String> {
    let relative = path
        .strip_prefix(output_dir)
        .map_err(|_| format!("{} is not under {}", path.display(), output_dir.display()))?;
    let key = relative
        .components()
        .map(|component| component.as_os_str().to_string_lossy())
        .collect::<Vec<_>>()
        .join("/");
    Ok(if encrypt { format!("{key}.enc") } else { key })
}

/// Outcome of one identity's upload phase.
#[derive(Debug, Default)]
struct UploadSummary {
    uploaded: usize,
    unchanged: usize,
    upload_failed: usize,
}

/// Builds this identity's not-yet-uploaded file list (per ADR-0019's
/// `.uploaded` tracking) and loads its index, without uploading anything --
/// kept separate from the upload itself (ADR-0024 §1) so it's unit-testable
/// without any network call, and so every identity's tasks can be gathered
/// into one shared queue before the concurrent upload phase runs.
fn pending_upload_tasks(
    ctx: &IdentityContext,
    identity_dir: &Path,
    encrypt: bool,
) -> Result<(Vec<UploadTask>, UploadedIndex), String> {
    let uploaded_index = UploadedIndex::load(&ctx.staging_dir)?;
    let mut tasks = Vec::new();
    for path in collect_files(identity_dir)? {
        let key = upload_key(&ctx.output_dir, &path, encrypt)?;
        if !uploaded_index.contains(&key) {
            tasks.push(UploadTask {
                identity: ctx.identity.alias.clone(),
                staging_dir: ctx.staging_dir.clone(),
                path,
                key,
            });
        }
    }
    Ok((tasks, uploaded_index))
}

/// Commits a successful upload into the uploading identity's index, locked
/// only for the duration of this call -- identities never contend on each
/// other's lock, only concurrent uploads for the *same* identity do
/// (ADR-0024 §3).
fn commit_uploaded(
    uploaded_indexes: &HashMap<PathBuf, Arc<Mutex<UploadedIndex>>>,
    task: &UploadTask,
) -> Result<(), String> {
    let index = uploaded_indexes
        .get(&task.staging_dir)
        .expect("every task's staging_dir has a registered index");
    index.lock().unwrap().commit(&task.staging_dir, &task.key)
}

/// Outcome of one file's upload attempt, for `run_upload_phase`'s summary
/// fold.
enum UploadOutcomeKind {
    Uploaded,
    Unchanged,
    Failed,
}

/// Reads and uploads one file, retrying transient failures with backoff the
/// same way `connect_with_retry` does for IMAP (ADR-0024 §6), then commits
/// success into its identity's index and advances the shared progress bar.
/// A file that still fails after exhausting retries is warned about via
/// `multi_progress.println` (load-bearing now that upload bars are live,
/// ADR-0024 §4/ADR-0015) and counted as failed -- never committed, so it's
/// retried again on the job's next invocation.
#[tracing::instrument(
    skip(task, uploaded_indexes, bucket_config, secret, encryptor, bar, multi_progress),
    fields(identity = %task.identity, file = %task.path.display())
)]
async fn upload_one(
    task: UploadTask,
    uploaded_indexes: &HashMap<PathBuf, Arc<Mutex<UploadedIndex>>>,
    bucket_config: &BucketConfig,
    secret: &str,
    encryptor: Option<&Aes256GcmSivEncryptor>,
    bar: &ProgressBar,
    multi_progress: &MultiProgress,
) -> UploadOutcomeKind {
    let outcome = async {
        let data = fs::read(&task.path)
            .map_err(|err| format!("failed to read {}: {err}", task.path.display()))?;
        // Deterministic encryption (ADR-0025): identical plaintext always
        // yields identical ciphertext under the same key, so
        // `upload_if_changed`'s MD5-vs-ETag dedup below needs no changes.
        let data = match encryptor {
            Some(encryptor) => encryptor.encrypt(&data)?,
            None => data,
        };
        retry_with_backoff(UPLOAD_RETRIES, UPLOAD_RETRY_BACKOFF, || {
            client::upload_if_changed(bucket_config, secret, &task.key, data.clone())
        })
        .await
    }
    .await;

    bar.inc(1);
    match outcome {
        Ok(client::UploadOutcome::Uploaded) => {
            let _ = commit_uploaded(uploaded_indexes, &task);
            UploadOutcomeKind::Uploaded
        }
        Ok(client::UploadOutcome::Unchanged) => {
            let _ = commit_uploaded(uploaded_indexes, &task);
            UploadOutcomeKind::Unchanged
        }
        Err(err) => {
            tracing::warn!(
                identity = %task.identity,
                file = %task.path.display(),
                step = "upload",
                error = %err,
                "upload failed after retries"
            );
            let _ = multi_progress.println(format!(
                "Warning: upload failed for {}: {err}",
                task.path.display()
            ));
            UploadOutcomeKind::Failed
        }
    }
}

/// Uploads every task in `tasks` -- spanning every selected identity's
/// not-yet-uploaded files, gathered once every identity's dedup pass has
/// completed (ADR-0024 §1) -- concurrently at `concurrency`, via
/// `stream::buffer_unordered` rather than a manual worker pool: uploads
/// have no per-worker session to reuse (`client::upload_if_changed` already
/// builds a fresh S3 client per call), so there's no connection-affinity
/// reason to prefer the fetch/transform worker-pool shape here. Each task
/// is yielded by `stream::iter` exactly once, so no two concurrently
/// in-flight uploads can ever be for the same file (ADR-0024 §2).
async fn run_upload_phase(
    tasks: Vec<UploadTask>,
    uploaded_indexes: &HashMap<PathBuf, Arc<Mutex<UploadedIndex>>>,
    bucket_config: &BucketConfig,
    secret: &str,
    encryptor: Option<&Aes256GcmSivEncryptor>,
    concurrency: usize,
    multi_progress: &MultiProgress,
) -> UploadSummary {
    if tasks.is_empty() {
        return UploadSummary::default();
    }
    let bar = sink::new_progress_bar("upload".to_string(), tasks.len() as u64, multi_progress);

    let summary = stream::iter(tasks)
        .map(|task| {
            upload_one(
                task,
                uploaded_indexes,
                bucket_config,
                secret,
                encryptor,
                &bar,
                multi_progress,
            )
        })
        .buffer_unordered(concurrency.max(1))
        .fold(
            UploadSummary::default(),
            |mut summary, outcome| async move {
                match outcome {
                    UploadOutcomeKind::Uploaded => summary.uploaded += 1,
                    UploadOutcomeKind::Unchanged => summary.unchanged += 1,
                    UploadOutcomeKind::Failed => summary.upload_failed += 1,
                }
                summary
            },
        )
        .await;

    bar.finish();
    summary
}

/// Outcome of a full `job run email-sync` execution, across every selected
/// identity.
#[derive(Debug, Default)]
pub(crate) struct JobSummary {
    pub synced: usize,
    pub failed: usize,
    pub failure_breakdown: FailureBreakdown,
    pub attachments_staged: usize,
    pub merged_messages: usize,
    pub deduped_attachments: usize,
    pub uploaded: usize,
    pub unchanged: usize,
    pub upload_failed: usize,
}

/// Runs the full four-phase pipeline (ADR-0021 §7) for every identity in
/// `identities`. `pending_by_identity` is each identity's already-gathered
/// `gather_pending` result, same order/index as `identities` -- the wizard
/// calls `gather_pending` itself (via `Job::gather`) to build the pre-run
/// summary, so this reuses that result instead of re-connecting to IMAP.
/// Splits every mailbox's pending UIDs into batches at `concurrency`
/// (ADR-0021 §6), then fetches+transforms them all concurrently through one
/// worker pool spanning every identity's every mailbox (this is what fully
/// fixes Context problem 1, the concurrency-capped-by-mailbox-count bug),
/// then runs each identity's dedup pass and (if `remote` is given) upload
/// phase sequentially, one identity after another.
///
/// `max_connections_per_identity` bounds how many workers can be connected
/// to any one identity at once (ADR-0071), independent of `concurrency`
/// itself -- see `run_worker`'s doc comment for why that's needed.
pub(crate) async fn run_email_sync_job(
    identities: Vec<IdentityContext>,
    pending_by_identity: Vec<Vec<PendingMailbox>>,
    concurrency: usize,
    max_connections_per_identity: usize,
    remote: Option<(&BucketConfig, &str)>,
    encryptor: Option<&Aes256GcmSivEncryptor>,
) -> Result<JobSummary, String> {
    let encrypt = encryptor.is_some();

    // Interleaved round-robin across identities (ADR-0071), rather than one
    // identity's batches all pushed contiguously: with the per-identity
    // connection cap below, a queue front-loaded with one identity's batches
    // would otherwise stall every worker on that identity's semaphore while
    // other identities' independent, immediately-runnable work sat idle
    // further back in the same queue.
    let mut per_identity_batches: Vec<VecDeque<Batch>> = pending_by_identity
        .iter()
        .map(|pending| super::batches_from_pending(pending, concurrency).into())
        .collect();
    let mut all_batches: VecDeque<(usize, Batch, u8)> = VecDeque::new();
    loop {
        let mut any_left = false;
        for (index, batches) in per_identity_batches.iter_mut().enumerate() {
            if let Some(batch) = batches.pop_front() {
                all_batches.push_back((index, batch, BATCH_RETRIES));
                any_left = true;
            }
        }
        if !any_left {
            break;
        }
    }

    // A fixed-size pool of `concurrency` persistent workers pulling from one
    // shared queue (ADR-0021 §6), never more than there are batches to hand
    // out.
    let worker_count = concurrency.max(1).min(all_batches.len().max(1));
    let queue = Arc::new(Mutex::new(all_batches));
    let identities = Arc::new(identities);
    let identity_semaphores: Arc<Vec<Arc<Semaphore>>> = Arc::new(
        identities
            .iter()
            .map(|_| {
                Arc::new(Semaphore::new(
                    concurrency.min(max_connections_per_identity).max(1),
                ))
            })
            .collect(),
    );
    let multi_progress = MultiProgress::new();

    let mut handles = Vec::with_capacity(worker_count);
    for _ in 0..worker_count {
        let queue = Arc::clone(&queue);
        let identities = Arc::clone(&identities);
        let identity_semaphores = Arc::clone(&identity_semaphores);
        let multi_progress = multi_progress.clone();
        handles.push(tokio::spawn(run_worker(
            queue,
            identities,
            identity_semaphores,
            multi_progress,
        )));
    }

    let mut summary = JobSummary::default();
    let mut first_error = None;
    for handle in handles {
        match handle.await {
            Ok(outcome) => {
                summary.synced += outcome.synced;
                summary.failed += outcome.failed;
                summary.attachments_staged += outcome.attachments_staged;
                summary.failure_breakdown.merge(&outcome.failure_breakdown);
            }
            Err(err) => {
                let message = format!("worker task panicked: {err}");
                let _ = multi_progress.println(format!("Error: {message}"));
                if first_error.is_none() {
                    first_error = Some(message);
                }
            }
        }
    }
    if let Some(err) = first_error {
        return Err(err);
    }

    let mut all_upload_tasks = Vec::new();
    let mut uploaded_indexes: HashMap<PathBuf, Arc<Mutex<UploadedIndex>>> = HashMap::new();

    for ctx in identities.iter() {
        let identity_dir = ctx
            .output_dir
            .join(identity::sanitize_segment(&ctx.identity.email));
        let mut entries = manifest::load_checkpoint(&ctx.staging_dir)?;
        let mut message_index = EmailDedup(ContentIndex::load(
            &ctx.staging_dir,
            transform::MESSAGE_HASHES_FILE,
        )?);
        let mut attachment_index = EmailDedup(ContentIndex::load(
            &ctx.staging_dir,
            transform::ATTACHMENT_HASHES_FILE,
        )?);
        let dedup_summary = dedup::run_dedup_pass(
            &identity_dir,
            &ctx.staging_dir,
            &mut entries,
            &mut message_index,
            &mut attachment_index,
            &multi_progress,
        )?;
        summary.merged_messages += dedup_summary.merged_messages;
        summary.deduped_attachments += dedup_summary.deduped_attachments;

        if remote.is_some() {
            let (tasks, uploaded_index) = pending_upload_tasks(ctx, &identity_dir, encrypt)?;
            all_upload_tasks.extend(tasks);
            uploaded_indexes.insert(
                ctx.staging_dir.clone(),
                Arc::new(Mutex::new(uploaded_index)),
            );
        }
    }

    if let Some((bucket_config, secret)) = remote {
        let upload_summary = run_upload_phase(
            all_upload_tasks,
            &uploaded_indexes,
            bucket_config,
            secret,
            encryptor,
            concurrency,
            &multi_progress,
        )
        .await;
        summary.uploaded += upload_summary.uploaded;
        summary.unchanged += upload_summary.unchanged;
        summary.upload_failed += upload_summary.upload_failed;
    }

    Ok(summary)
}

#[cfg(test)]
mod tests {
    use std::sync::atomic::{AtomicUsize, Ordering};

    use super::*;

    #[tokio::test]
    async fn retry_with_backoff_succeeds_after_transient_failures() {
        let attempts = AtomicUsize::new(0);
        let result: Result<&str, String> =
            retry_with_backoff(CONNECT_RETRIES, Duration::from_millis(1), || {
                let count = attempts.fetch_add(1, Ordering::SeqCst) + 1;
                async move {
                    if count < 3 {
                        Err(format!("attempt {count} failed"))
                    } else {
                        Ok("connected")
                    }
                }
            })
            .await;

        assert_eq!(result, Ok("connected"));
        assert_eq!(attempts.load(Ordering::SeqCst), 3);
    }

    #[tokio::test]
    async fn retry_with_backoff_returns_the_last_error_after_exhausting_attempts() {
        let attempts = AtomicUsize::new(0);
        let result: Result<(), String> =
            retry_with_backoff(CONNECT_RETRIES, Duration::from_millis(1), || {
                let count = attempts.fetch_add(1, Ordering::SeqCst) + 1;
                async move { Err(format!("attempt {count} failed")) }
            })
            .await;

        assert_eq!(result, Err("attempt 3 failed".to_string()));
        assert_eq!(attempts.load(Ordering::SeqCst), CONNECT_RETRIES);
    }

    #[tokio::test]
    async fn retry_with_backoff_does_not_retry_a_first_success() {
        let attempts = AtomicUsize::new(0);
        let result: Result<&str, String> =
            retry_with_backoff(CONNECT_RETRIES, Duration::from_millis(1), || {
                attempts.fetch_add(1, Ordering::SeqCst);
                async move { Ok("connected") }
            })
            .await;

        assert_eq!(result, Ok("connected"));
        assert_eq!(attempts.load(Ordering::SeqCst), 1);
    }

    fn test_batch() -> Batch {
        Batch {
            mailbox: "INBOX".to_string(),
            mailbox_relpath: PathBuf::from("inbox"),
            uids: vec![1, 2, 3],
        }
    }

    #[tokio::test]
    async fn requeue_or_none_returns_none_once_attempts_are_exhausted() {
        let result = requeue_or_none(0, test_batch(), 0, Duration::from_millis(1)).await;

        assert!(result.is_none());
    }

    #[tokio::test]
    async fn requeue_or_none_requeues_with_one_fewer_attempt_remaining() {
        let (identity_index, batch, attempts_remaining) =
            requeue_or_none(2, test_batch(), BATCH_RETRIES, Duration::from_millis(1))
                .await
                .unwrap();

        assert_eq!(identity_index, 2);
        assert_eq!(batch.uids, vec![1, 2, 3]);
        assert_eq!(attempts_remaining, BATCH_RETRIES - 1);
    }

    fn test_ctx(staging_dir: &Path, output_dir: &Path) -> IdentityContext {
        IdentityContext {
            identity: crate::commands::keyring::email::identity::Identity {
                alias: "alias".to_string(),
                email: "person@example.com".to_string(),
                provider: crate::commands::keyring::email::provider::Provider::Gmail,
                host: "imap.gmail.com".to_string(),
                port: 993,
            },
            secret: "secret".to_string(),
            staging_dir: staging_dir.to_path_buf(),
            output_dir: output_dir.to_path_buf(),
        }
    }

    #[test]
    fn pending_upload_tasks_includes_every_file_when_index_is_empty() {
        let staging = tempfile::tempdir().unwrap();
        let output = tempfile::tempdir().unwrap();
        let identity_dir = output.path().join("alias-out");
        fs::create_dir_all(&identity_dir).unwrap();
        fs::write(identity_dir.join("a.md"), b"a").unwrap();
        fs::write(identity_dir.join("b.md"), b"b").unwrap();

        let ctx = test_ctx(staging.path(), output.path());
        let (tasks, index) = pending_upload_tasks(&ctx, &identity_dir, false).unwrap();

        let mut keys: Vec<String> = tasks.iter().map(|task| task.key.clone()).collect();
        keys.sort();
        assert_eq!(
            keys,
            vec!["alias-out/a.md".to_string(), "alias-out/b.md".to_string()]
        );
        assert!(!index.contains("alias-out/a.md"));
    }

    #[test]
    fn pending_upload_tasks_skips_files_already_in_uploaded_index() {
        let staging = tempfile::tempdir().unwrap();
        let output = tempfile::tempdir().unwrap();
        let identity_dir = output.path().join("alias-out");
        fs::create_dir_all(&identity_dir).unwrap();
        fs::write(identity_dir.join("a.md"), b"a").unwrap();
        fs::write(identity_dir.join("b.md"), b"b").unwrap();

        let ctx = test_ctx(staging.path(), output.path());
        let key_a = upload_key(&ctx.output_dir, &identity_dir.join("a.md"), false).unwrap();
        fs::write(
            staging.path().join(UPLOADED_FILE_NAME),
            format!("{key_a}\n"),
        )
        .unwrap();

        let (tasks, index) = pending_upload_tasks(&ctx, &identity_dir, false).unwrap();

        assert_eq!(tasks.len(), 1);
        assert_eq!(
            tasks[0].key,
            upload_key(&ctx.output_dir, &identity_dir.join("b.md"), false).unwrap()
        );
        assert!(index.contains(&key_a));
    }

    #[test]
    fn upload_key_appends_enc_suffix_when_encryption_enabled() {
        let output = tempfile::tempdir().unwrap();
        let path = output.path().join("alias-out").join("a.md");

        assert_eq!(
            upload_key(output.path(), &path, false).unwrap(),
            "alias-out/a.md"
        );
        assert_eq!(
            upload_key(output.path(), &path, true).unwrap(),
            "alias-out/a.md.enc"
        );
    }

    #[test]
    fn pending_upload_tasks_uses_enc_suffixed_keys_when_encryption_enabled() {
        let staging = tempfile::tempdir().unwrap();
        let output = tempfile::tempdir().unwrap();
        let identity_dir = output.path().join("alias-out");
        fs::create_dir_all(&identity_dir).unwrap();
        fs::write(identity_dir.join("a.md"), b"a").unwrap();

        let ctx = test_ctx(staging.path(), output.path());
        let (tasks, _index) = pending_upload_tasks(&ctx, &identity_dir, true).unwrap();

        assert_eq!(tasks.len(), 1);
        assert_eq!(tasks[0].key, "alias-out/a.md.enc");
    }
}
