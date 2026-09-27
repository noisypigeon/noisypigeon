//! ffmpeg/ffprobe-backed media handling: probing, recoding, and
//! post-recode verification (ADR-0074 §4), plus EXIF date extraction and
//! the screenshot-vs-photo dimension heuristic. Real audio/video re-encoding
//! has no mature pure-Rust implementation, so this shells out to the
//! `ffmpeg`/`ffprobe` binaries rather than adding a codec crate.

use std::io::{BufReader, Cursor};
use std::path::Path;

use serde::Deserialize;

use super::date::{SimpleDate, parse_exif_datetime, parse_iso_date};

/// What canonical extension/encoding a classified media file recodes to
/// (ADR-0074's canonical-format decision: photo & screenshot -> jpg, video
/// -> mp4, audio -> m4a).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum MediaKind {
    Photo,
    Screenshot,
    Video,
    Audio,
}

impl MediaKind {
    pub(crate) fn canonical_extension(self) -> &'static str {
        match self {
            MediaKind::Photo | MediaKind::Screenshot => "jpg",
            MediaKind::Video => "mp4",
            MediaKind::Audio => "m4a",
        }
    }
}

/// Structural facts about a media file, probed both before a recode (to
/// know what "no loss" means for this specific file) and after (to check
/// against it).
#[derive(Debug, Default, Clone, Copy)]
pub(crate) struct ProbeInfo {
    pub duration_secs: Option<f64>,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub creation_date: Option<SimpleDate>,
}

#[derive(Deserialize)]
struct FfprobeOutput {
    #[serde(default)]
    format: FfprobeFormat,
    #[serde(default)]
    streams: Vec<FfprobeStream>,
}

#[derive(Deserialize, Default)]
struct FfprobeFormat {
    duration: Option<String>,
    #[serde(default)]
    tags: FfprobeTags,
}

#[derive(Deserialize, Default)]
struct FfprobeTags {
    creation_time: Option<String>,
}

#[derive(Deserialize, Default)]
struct FfprobeStream {
    width: Option<u32>,
    height: Option<u32>,
}

/// Confirms `ffmpeg`/`ffprobe` are on `PATH` -- checked once, up front in
/// the wizard, so a missing binary fails the whole job immediately with one
/// clear error instead of failing per-file deep into a long run.
pub(crate) async fn check_ffmpeg_available() -> Result<(), String> {
    for binary in ["ffmpeg", "ffprobe"] {
        tokio::process::Command::new(binary)
            .arg("-version")
            .output()
            .await
            .map_err(|_| {
                format!(
                    "'{binary}' was not found on PATH -- required for \
                     'pigeon job run pull-transform' to recode media"
                )
            })?;
    }
    Ok(())
}

/// Probes `path` (any file `ffprobe` can open) for duration and, if it has a
/// video/image stream, pixel dimensions -- used both to classify
/// screenshots/photos by resolution and to verify a recode didn't
/// truncate/resize the content.
pub(crate) async fn probe(path: &Path) -> Result<ProbeInfo, String> {
    let output = tokio::process::Command::new("ffprobe")
        .args([
            "-v",
            "error",
            "-print_format",
            "json",
            "-show_format",
            "-show_streams",
        ])
        .arg(path)
        .output()
        .await
        .map_err(|err| format!("failed to run ffprobe: {err}"))?;
    if !output.status.success() {
        return Err(format!(
            "ffprobe failed for {}: {}",
            path.display(),
            String::from_utf8_lossy(&output.stderr)
        ));
    }
    let parsed: FfprobeOutput = serde_json::from_slice(&output.stdout).map_err(|err| {
        format!(
            "failed to parse ffprobe output for {}: {err}",
            path.display()
        )
    })?;

    let duration_secs = parsed.format.duration.and_then(|value| value.parse().ok());
    let (width, height) = parsed
        .streams
        .iter()
        .find(|stream| stream.width.is_some() && stream.height.is_some())
        .map(|stream| (stream.width, stream.height))
        .unwrap_or((None, None));
    let creation_date = parsed
        .format
        .tags
        .creation_time
        .as_deref()
        .and_then(parse_iso_date);

    Ok(ProbeInfo {
        duration_secs,
        width,
        height,
        creation_date,
    })
}

/// Re-encodes `input_path` into `output_path` at a fixed, conservative
/// "visually lossless" preset for `kind` (ADR-0074: not a dynamic per-file
/// quality search). Audio already in an AAC/M4A container is a cheap remux
/// (`-c:a copy`), not a re-encode, since there's nothing to gain from
/// touching already-efficient audio.
pub(crate) async fn recode(
    input_path: &Path,
    output_path: &Path,
    kind: MediaKind,
    input_is_already_aac_m4a: bool,
) -> Result<(), String> {
    let mut command = tokio::process::Command::new("ffmpeg");
    command
        .args(["-y", "-loglevel", "error", "-i"])
        .arg(input_path);
    match kind {
        MediaKind::Photo | MediaKind::Screenshot => {
            command.args(["-frames:v", "1", "-q:v", "3"]);
        }
        MediaKind::Video => {
            command.args([
                "-c:v", "libx264", "-preset", "medium", "-crf", "23", "-c:a", "aac", "-b:a", "256k",
            ]);
        }
        MediaKind::Audio if input_is_already_aac_m4a => {
            command.args(["-c:a", "copy"]);
        }
        MediaKind::Audio => {
            command.args(["-c:a", "aac", "-b:a", "256k"]);
        }
    }
    command.arg(output_path);

    let output = command
        .output()
        .await
        .map_err(|err| format!("failed to run ffmpeg: {err}"))?;
    if !output.status.success() {
        return Err(format!(
            "ffmpeg failed to recode {}: {}",
            input_path.display(),
            String::from_utf8_lossy(&output.stderr)
        ));
    }
    Ok(())
}

/// Duration tolerance for verification: the larger of 2% or half a second,
/// so a recode's container-level rounding never registers as a mismatch on
/// short clips while still catching a truncated/corrupted re-encode of a
/// long one.
fn duration_tolerance(seconds: f64) -> f64 {
    (seconds * 0.02).max(0.5)
}

/// Compares `before` (probed pre-recode) against `after_path` (probed
/// post-recode): duration within tolerance, dimensions exact when both are
/// known. Anything outside that is treated as data loss, not just "a
/// different encode" -- the caller retries, then falls back to the
/// original file (ADR-0074 §4).
pub(crate) async fn verify(before: ProbeInfo, after_path: &Path) -> Result<(), String> {
    let after = probe(after_path).await?;
    if let (Some(b), Some(a)) = (before.duration_secs, after.duration_secs) {
        let tolerance = duration_tolerance(b);
        if (b - a).abs() > tolerance {
            return Err(format!(
                "duration mismatch after recode: {b:.2}s before, {a:.2}s after (tolerance {tolerance:.2}s)"
            ));
        }
    }
    if let (Some(bw), Some(bh), Some(aw), Some(ah)) =
        (before.width, before.height, after.width, after.height)
        && (bw, bh) != (aw, ah)
    {
        return Err(format!(
            "dimension mismatch after recode: {bw}x{bh} before, {aw}x{ah} after"
        ));
    }
    Ok(())
}

/// Reads EXIF `DateTimeOriginal` from an image's bytes (JPEG/TIFF/HEIF/PNG/
/// WebP -- `kamadak-exif` auto-detects the container). Absent for most
/// screenshots (no camera wrote EXIF into them) and for images with no EXIF
/// segment at all -- `None` either way, letting the caller fall through to
/// its next date source.
pub(crate) fn exif_date(bytes: &[u8]) -> Option<SimpleDate> {
    let mut reader = BufReader::new(Cursor::new(bytes));
    let exif = exif::Reader::new().read_from_container(&mut reader).ok()?;
    let field = exif.get_field(exif::Tag::DateTimeOriginal, exif::In::PRIMARY)?;
    parse_exif_datetime(&field.display_value().to_string())
}

/// Common device/monitor screen resolutions (width, height as captured,
/// either orientation) -- an image whose dimensions match one of these is
/// classified a screenshot rather than a photo (ADR-0074's chosen
/// heuristic). Not exhaustive by design: a miss just means "treated as a
/// photo," never a lost or corrupted file.
const COMMON_SCREEN_RESOLUTIONS: &[(u32, u32)] = &[
    (750, 1334),  // iPhone SE/8
    (828, 1792),  // iPhone 11/XR
    (1080, 1920), // common Android/1080p portrait
    (1125, 2436), // iPhone X/XS/11 Pro
    (1170, 2532), // iPhone 12/13
    (1179, 2556), // iPhone 15/16
    (1206, 2622), // iPhone 15/16 Pro Max
    (1284, 2778), // iPhone 12/13 Pro Max
    (1290, 2796), // iPhone 15/16 Pro Max variant
    (1440, 2960), // Galaxy S-series
    (1440, 3200), // Galaxy S20+/Note
    (2048, 1536), // iPad (4:3)
    (2224, 1668), // iPad Pro 10.5"
    (2360, 1640), // iPad Air
    (2732, 2048), // iPad Pro 12.9"
    (1920, 1080), // 1080p monitor
    (2560, 1440), // 1440p monitor
    (3840, 2160), // 4K monitor
    (1366, 768),  // common laptop
    (2560, 1600), // MacBook-class
    (2880, 1800), // MacBook Pro Retina
    (3024, 1964), // MacBook Pro 14"
    (3456, 2234), // MacBook Pro 16"
];

pub(crate) fn is_screenshot_resolution(width: u32, height: u32) -> bool {
    COMMON_SCREEN_RESOLUTIONS
        .iter()
        .any(|&(w, h)| (w, h) == (width, height) || (w, h) == (height, width))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn canonical_extension_maps_each_category() {
        assert_eq!(MediaKind::Photo.canonical_extension(), "jpg");
        assert_eq!(MediaKind::Screenshot.canonical_extension(), "jpg");
        assert_eq!(MediaKind::Video.canonical_extension(), "mp4");
        assert_eq!(MediaKind::Audio.canonical_extension(), "m4a");
    }

    #[test]
    fn is_screenshot_resolution_matches_known_phone_size() {
        assert!(is_screenshot_resolution(1170, 2532));
        assert!(is_screenshot_resolution(2532, 1170));
    }

    #[test]
    fn is_screenshot_resolution_false_for_typical_camera_photo() {
        // A common DSLR/phone-camera photo resolution, not a screen size.
        assert!(!is_screenshot_resolution(4032, 3024));
    }

    #[test]
    fn duration_tolerance_has_a_floor_for_short_clips() {
        assert_eq!(duration_tolerance(1.0), 0.5);
    }

    #[test]
    fn duration_tolerance_scales_for_long_clips() {
        assert!((duration_tolerance(100.0) - 2.0).abs() < f64::EPSILON);
    }

    #[test]
    fn exif_date_returns_none_for_non_image_bytes() {
        assert_eq!(exif_date(b"not an image"), None);
    }
}
