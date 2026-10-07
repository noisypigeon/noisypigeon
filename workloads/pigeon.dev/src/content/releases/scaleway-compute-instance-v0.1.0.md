+++
title = "scaleway/compute-instance v0.1.0"
date = 2026-09-29T12:00:00-07:00
slug = "scaleway-compute-instance-v0.1.0"
description = "docs(adr-0079): add scaleway/compute-instance module"
+++

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
