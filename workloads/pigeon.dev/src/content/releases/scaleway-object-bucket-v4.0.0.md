+++
title = "scaleway/object-bucket v4.0.0"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-object-bucket-v4.0.0"
description = "Rename object-bucket's namespace/name to name_prefix/name_suffix, default storage_class to glacier"
+++

Renames `object-bucket`'s `namespace`/`name` inputs to `name_prefix`/`name_suffix`, matching the convention ADR-0118 already applied to `compute-instance` — same `"${var.name_prefix}-${random_string.suffix.result}-${var.name_suffix}"` naming scheme, just call-site names that read correctly (`name_prefix = "job-${local.namespace}"` instead of pairing a generic `namespace` variable with an already-namespace-shaped value).

Also flips `storage_class`'s default from `"standard"` to `"glacier"`. Nearly every real consumer of this module is cold/archival data (`poisoned/*`, `email`, `media`, `macbook-scratch`, `backblaze`), so the new default matches what most callers actually want instead of requiring each to opt in by hand.

Both changes are breaking: existing callers must rename their `namespace`/`name` arguments, and any caller relying on the implicit `"standard"` default now needs to set `storage_class = "standard"` explicitly to keep that behavior.

See docs/adr/0119-decouple-scaleway-iam-application-api-key-rename-object-bucket.md for the full decision record (this PR covers only the `object-bucket` half of that ADR).

[#161](https://github.com/noisypigeon/noisypigeon/pull/161)
