+++
title = "scaleway/compute-instance v2.0.0"
date = 2026-10-02T12:00:00-07:00
slug = "scaleway-compute-instance-v2.0.0"
description = "Merge rclone cloud-init profile into pigeon-cli"
+++

## Summary

`scaleway/compute-instance`'s `profile` input drops `"rclone"` as a distinct value. `"pigeon-cli"` now absorbs everything `"rclone"` used to do:

- Installs `rclone` and `neovim` via cloud-init `packages:` (previously only under `profile = "rclone"`).
- Writes `/root/.config/rclone/rclone.conf` from `var.buckets` (previously only under `profile = "rclone"`).
- Still runs the `pigeon-cli` bootstrap script in `runcmd` on first boot, unchanged.

`"docker"` is untouched. `buckets`' validation gate moves from `profile == "rclone"` to `profile == "pigeon-cli"`. The `profile` default changes from `"rclone"` to `"pigeon-cli"` — the closest equivalent to preserving "omit `profile`, get rclone+neovim+bucket config," since `"pigeon-cli"` is now a strict superset of the old default's behavior.

**Why:** no live caller used `profile = "rclone"` or relied on the old default (confirmed via a repo-wide grep before making this change), but a real in-progress leaf (`workloads/pigeon-cli/terraform/sort/macbook-scratch`) already needs `profile = "pigeon-cli"` **and** a non-empty `buckets` list at the same time — a combination the prior version rejected outright. This unblocks it.

Full rationale in [ADR-0099](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0099-merge-rclone-profile-into-pigeon-cli.md).

**Breaking change:** `profile = "rclone"` is no longer a valid value (rejected by the input's own validation block). Existing callers using `"docker"` or `"pigeon-cli"` are unaffected except that `"pigeon-cli"` now also installs `rclone`/`neovim` and accepts `buckets`. As with every prior cloud-init content change to this module (ADR-0084's force-replace lifecycle), any existing instance is replaced on its next apply.

## Test plan
- [x] `terraform fmt -check` clean
- [x] `terraform init -backend=false && terraform validate` clean
- [x] Rendered the cloud-init `locals` block standalone (no provider needed) for both remaining profiles: `docker` output is byte-identical to before; `pigeon-cli` with a sample `buckets` entry now renders the `rclone`/`neovim` packages, the populated `write_files` block, and the unchanged bootstrap `runcmd` line
- [x] Exercised the real module's own validation via `terraform plan`: `profile = "rclone"` rejected (invalid enum value), `profile = "docker"` + non-empty `buckets` rejected (updated error message), `profile = "pigeon-cli"` + non-empty `buckets` plans cleanly

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#125](https://github.com/noisypigeon/noisypigeon/pull/125)
