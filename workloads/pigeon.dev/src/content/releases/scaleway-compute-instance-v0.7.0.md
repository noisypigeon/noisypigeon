+++
title = "scaleway/compute-instance v0.7.0"
date = 2026-10-02T12:00:00-07:00
slug = "scaleway-compute-instance-v0.7.0"
description = "Add cloud-init profiles (rclone/docker) to scaleway/compute-instance"
+++

`scaleway/compute-instance` gains a new `profile` input (`"rclone"` or `"docker"`, defaults to `"rclone"`) that selects between two cloud-init provisioning shapes:

- **`profile = "rclone"`** (default, matches prior behavior): installs `rclone` and `neovim`, and writes `/root/.config/rclone/rclone.conf` from `var.buckets` exactly as before.
- **`profile = "docker"`**: installs Docker CE (official apt repo/key bootstrap) plus `docker-ce-cli`, `containerd.io`, and `docker-compose-plugin`, and enables + starts the `docker` service.

`build-essential`, `pkg-config`, and `libssl-dev` are removed from the cloud-init package list entirely, under both profiles — they were only ever installed to support `mise`'s build-toolchain use case, not rclone, and aren't needed by either new profile. Any existing instance relying on those packages being present will lose them on its next apply.

`buckets` now has a validation guard: it's rejected (non-empty) when `profile != "rclone"`, since bucket config would otherwise silently do nothing.

Full design rationale in [ADR-0087](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0087-add-cloud-init-profiles-to-scaleway-compute-instance.md).

Existing callers are unaffected by the interface change (new input defaults to `"rclone"`), but — as with every prior change to this module's cloud-init content — any existing instance gets replaced on its next apply (ADR-0084's force-replace-on-cloud-init-change lifecycle).

## Test plan
- [x] `terraform fmt -check` clean
- [x] `terraform init -backend=false && terraform validate` clean
- [x] Rendered both profiles via a scratch config and confirmed correct package lists / `write_files` / `runcmd` branching, and that `buckets` + `profile = "docker"` is rejected by the new validation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#114](https://github.com/noisypigeon/noisypigeon/pull/114)
