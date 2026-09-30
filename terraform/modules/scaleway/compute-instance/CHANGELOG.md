# Changelog

All notable changes to this module are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-09-30

### Add rclone/neovim cloud-init and bucket access to scaleway/compute-instance

`scaleway/compute-instance` now installs `rclone` and `neovim` via cloud-init on every instance, and accepts a new optional `buckets` input (default `[]`) that populates `/root/.config/rclone/rclone.conf` with one `alias` + one `s3` remote per bucket -- the same schema and rendering approach `digitalocean/droplet` already uses for its own rclone config.

Bucket-scoped access-key creation stays outside this module: compose a `scaleway/iam-policy` module call (its `bucket_names`/`bucket_actions`/`admin_project_id` inputs and `access_key`/`secret_key` outputs are unchanged) and pass the resolved credentials into `buckets` yourself.

See ADR-0081 for the full design rationale, including why bucket-credential creation stays external and why `rclone.conf` lands under `/root` rather than a created non-root user.

This PR also fixes stale `docs/archived/adr/` references in `CLAUDE.md`/`docs/USAGE.md` -- that directory no longer exists on `main` (ADRs were flattened back into `docs/adr/` a while back); unrelated to the module change itself but caught while writing ADR-0081.

[#104](https://github.com/noisypigeon/noisypigeon/pull/104)

## [0.1.0] - 2026-09-29

### docs(adr-0079): add scaleway/compute-instance module

## Context

`terraform/modules/scaleway/` has `project`, `object-bucket`, and `iam-policy`, but no compute module. `digitalocean/droplet` is the DigitalOcean analog, but it bundles DigitalOcean-specific machinery (cloud-init, an access-key sub-module, SSH-key data source, Cloudflare DNS alias) not wanted yet. This adds a deliberately minimal wrapper around `scaleway_instance_server`, using `droplet` only for structural/naming inspiration.

## Decision

- New module `terraform/modules/scaleway/compute-instance`: `namespace`/`name`/`image` required, `type` defaults to `STARDUST1-S` (overridable) — the one deliberate exception to "required fields only," per the user's request.
- `image` is a required *module* input even though it's an optional *resource* argument on `scaleway_instance_server` — the resource only allows skipping it when attaching an existing root volume, a path this module doesn't support yet (same kind of call ADR-0044 made for `object-bucket`'s `storage_class`).
- Outputs are pass-through only (`id`, `name`, `public_ips`, `private_ips`) — no invented indexing, since no IP is attached by default.
- `terraform/modules/README.md` gains a row; `module-docs.yml`'s hand-maintained `working-dir:` list gains an entry. `module-release.yml` needs no change — its module discovery and changelog/tagging automation already generalize to any provider root with a `versions.tf`.
- No hand-written `CHANGELOG.md` — `module-release.yml` creates one on first merge.

Full ADR: [`docs/adr/0079-add-scaleway-compute-instance-module.md`](../blob/adr-0079-add-scaleway-compute-instance-module/docs/adr/0079-add-scaleway-compute-instance-module.md)

## Test plan

- [x] `terraform fmt -check` clean.
- [x] `terraform init -backend=false && terraform validate` clean.
- [x] `mise run ci` clean.

[#86](https://github.com/noisypigeon/noisypigeon/pull/86)
