+++
title = "scaleway/compute-instance v4.0.0"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-compute-instance-v4.0.0"
description = "Simplify scaleway/compute-instance's interface (ADR-0118)"
+++

A census of every `scaleway/compute-instance` consumer (live and historical, via `git log -S`) found exactly one real caller, and it was already working around the module's own redundancy: it hardcoded `profile = "pigeon-cli"` (`profile = "docker"` has never been instantiated anywhere), and re-declared the same bucket secret three separate times across `buckets`, `keyring_entries`, and `environment_variables` just to keep their aliases in sync by hand.

This PR:
- Drops the `docker` profile and the `profile` variable entirely — `pigeon-cli` provisioning (rclone/neovim, the bootstrap script, keyring/rclone config, Cockpit/Alloy) is now the module's only, unconditional behavior.
- Renames `namespace`/`name` to `name_prefix`/`name_suffix`.
- Groups SSH access under a new `user_config` object; `ssh_keys` (a list) becomes `user_config.ssh_key` (a single string) — the only real caller ever passed one key.
- Groups `image` (now optional, defaulting to `"ubuntu_jammy"`), `type`, and `cockpit` under a new `instance_config` object.
- Collapses `buckets` + `keyring_entries` + `environment_variables` into one `keyring` list. A `kind = "bucket"` entry now also renders an rclone.conf remote; any entry's `secret_key` (never written into `keyring.toml` itself) now auto-exports `PIGEON_SECRET_<ALIAS>` on the instance, replacing the free-form `environment_variables` map.

Full rationale and the exact rendering changes: [docs/adr/0118-simplify-scaleway-compute-instance-interface.md](docs/adr/0118-simplify-scaleway-compute-instance-interface.md).

Breaking change — every top-level input except `enable_ipv4`/`enable_ipv6`/`additional_volume_ids` is renamed, regrouped, or removed. A follow-up PR migrates the one real consumer to the new interface and the new tag.

## Test plan

- [x] `mise run fmt-check-terraform` passes.
- [x] `tofu validate` passes against the rewritten module in isolation.
- [ ] After merge: confirm the `v4.0.0` tag/GitHub Release and regenerated README Inputs/Outputs tables.

[#157](https://github.com/noisypigeon/noisypigeon/pull/157)
