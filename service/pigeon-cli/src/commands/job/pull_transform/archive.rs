//! Recursive, in-memory zip expansion (ADR-0074 §4). Every member is read
//! fully into memory rather than extracted to disk -- this job already
//! holds one object's bytes in memory at a time (the same shape as
//! `bucket::client::get_object`'s whole-object download), and staying
//! in-memory means a zip-in-a-zip is just another call to `expand`, no
//! scratch-directory bookkeeping needed until a member actually needs
//! `ffmpeg` (which does need real files, handled in `media.rs`).

use std::io::{Cursor, Read};

use zip::ZipArchive;

/// How many nested zip levels `worker::run_pull_transform_job` will expand
/// before giving up on that branch -- a zip bomb built from many small
/// nested zips still terminates instead of expanding forever.
pub(crate) const MAX_ZIP_DEPTH: u32 = 10;

/// Total bytes this job will expand from zip members across the whole run,
/// tracked by the caller (a shared counter, since expansion happens
/// concurrently) -- a second, size-based zip-bomb guard independent of
/// nesting depth (a single-level zip that inflates to gigabytes is caught
/// here even though it never hits the depth cap).
pub(crate) const MAX_TOTAL_EXTRACTED_BYTES: u64 = 10 * 1024 * 1024 * 1024;

pub(crate) struct ZipMember {
    /// The member's own path inside the archive, e.g. `"photos/img.jpg"` --
    /// the caller joins this onto the zip's own display key to build a
    /// synthetic, human-readable key for the extracted file.
    pub name: String,
    pub bytes: Vec<u8>,
}

/// Reads every regular-file entry out of a zip archive's bytes, in order.
/// Directory entries are skipped. A password-protected or corrupt archive
/// is a plain `Err` -- treated by the caller as a failed task, not a job
/// abort.
pub(crate) fn expand(bytes: &[u8]) -> Result<Vec<ZipMember>, String> {
    let mut archive =
        ZipArchive::new(Cursor::new(bytes)).map_err(|err| format!("invalid zip archive: {err}"))?;

    let mut members = Vec::with_capacity(archive.len());
    for index in 0..archive.len() {
        let mut entry = archive
            .by_index(index)
            .map_err(|err| format!("failed to read zip entry {index}: {err}"))?;
        if entry.is_dir() {
            continue;
        }
        let name = entry.name().to_string();
        let mut buf = Vec::with_capacity(entry.size() as usize);
        entry
            .read_to_end(&mut buf)
            .map_err(|err| format!("failed to read zip entry '{name}': {err}"))?;
        members.push(ZipMember { name, bytes: buf });
    }
    Ok(members)
}

#[cfg(test)]
mod tests {
    use std::io::Write as _;

    use zip::ZipWriter;
    use zip::write::SimpleFileOptions;

    use super::*;

    fn build_test_zip(entries: &[(&str, &[u8])]) -> Vec<u8> {
        let mut buf = Vec::new();
        {
            let mut writer = ZipWriter::new(Cursor::new(&mut buf));
            let options =
                SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored);
            for (name, contents) in entries {
                writer.start_file(*name, options).unwrap();
                writer.write_all(contents).unwrap();
            }
            writer.finish().unwrap();
        }
        buf
    }

    #[test]
    fn expand_reads_every_member_in_order() {
        let zip_bytes = build_test_zip(&[("a.txt", b"hello"), ("b.txt", b"world")]);

        let members = expand(&zip_bytes).unwrap();

        assert_eq!(members.len(), 2);
        assert_eq!(members[0].name, "a.txt");
        assert_eq!(members[0].bytes, b"hello");
        assert_eq!(members[1].name, "b.txt");
        assert_eq!(members[1].bytes, b"world");
    }

    #[test]
    fn expand_rejects_non_zip_bytes() {
        assert!(expand(b"not a zip file").is_err());
    }

    #[test]
    fn expand_skips_directory_entries() {
        let mut buf = Vec::new();
        {
            let mut writer = ZipWriter::new(Cursor::new(&mut buf));
            writer
                .add_directory("photos/", SimpleFileOptions::default())
                .unwrap();
            writer
                .start_file("photos/img.jpg", SimpleFileOptions::default())
                .unwrap();
            writer.write_all(b"fake-jpeg-bytes").unwrap();
            writer.finish().unwrap();
        }

        let members = expand(&buf).unwrap();

        assert_eq!(members.len(), 1);
        assert_eq!(members[0].name, "photos/img.jpg");
    }
}
