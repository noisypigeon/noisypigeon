+++
title = "scaleway/compute-instance v2.1.0"
date = 2026-10-02T12:00:00-07:00
slug = "scaleway-compute-instance-v2.1.0"
description = "Add keyring_entries input for pigeon-cli keyring.toml"
+++

Adds a `keyring_entries` input to `scaleway/compute-instance`, used when `profile = "pigeon-cli"`. It renders `/root/.config/pigeon/keyring.toml` on first boot from a list of entries, following the same `write_files` + templating pattern already used for `rclone.conf`/`buckets`.

Each entry has a `kind` (`"email"`, `"bucket"`, or `"encryption-key"`) plus an `alias`, and the fields relevant to that kind:

- `email`: `email`, `provider`, `host`, `port`, optional `max_imap_connections`.
- `bucket`: `endpoint`, `bucket`, `access_key_id`, `encryption_key_alias`.
- `encryption-key`: `created_at`.

As with `buckets`, this module never creates or stores secrets itself — callers resolve any credentials externally (e.g. via `scaleway/iam-policy`) and pass in already-populated values. `keyring_entries` defaults to `[]`, so this is fully backwards compatible.

See ADR-0100 (`docs/adr/0100-add-keyring-toml-templating-to-scaleway-compute-instance.md`) for the full design rationale.

[#126](https://github.com/noisypigeon/noisypigeon/pull/126)
