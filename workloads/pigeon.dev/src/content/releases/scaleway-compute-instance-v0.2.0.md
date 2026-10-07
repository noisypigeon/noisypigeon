+++
title = "scaleway/compute-instance v0.2.0"
date = 2026-09-30T12:00:00-07:00
slug = "scaleway-compute-instance-v0.2.0"
description = "Add rclone/neovim cloud-init and bucket access to scaleway/compute-instance"
+++

`scaleway/compute-instance` now installs `rclone` and `neovim` via cloud-init on every instance, and accepts a new optional `buckets` input (default `[]`) that populates `/root/.config/rclone/rclone.conf` with one `alias` + one `s3` remote per bucket -- the same schema and rendering approach `digitalocean/droplet` already uses for its own rclone config.

Bucket-scoped access-key creation stays outside this module: compose a `scaleway/iam-policy` module call (its `bucket_names`/`bucket_actions`/`admin_project_id` inputs and `access_key`/`secret_key` outputs are unchanged) and pass the resolved credentials into `buckets` yourself.

See ADR-0081 for the full design rationale, including why bucket-credential creation stays external and why `rclone.conf` lands under `/root` rather than a created non-root user.

This PR also fixes stale `docs/archived/adr/` references in `CLAUDE.md`/`docs/USAGE.md` -- that directory no longer exists on `main` (ADRs were flattened back into `docs/adr/` a while back); unrelated to the module change itself but caught while writing ADR-0081.

[#104](https://github.com/noisypigeon/noisypigeon/pull/104)
