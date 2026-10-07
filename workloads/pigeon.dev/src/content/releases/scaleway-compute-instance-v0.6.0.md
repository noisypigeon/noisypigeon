+++
title = "scaleway/compute-instance v0.6.0"
date = 2026-10-01T12:00:00-07:00
slug = "scaleway-compute-instance-v0.6.0"
description = "Pre-install mise and a build toolchain in compute-instance's cloud-init"
+++

Every instance created by `scaleway/compute-instance` now gets, unconditionally (same posture as the existing `rclone`/`neovim` install), a Rust/C build toolchain (`build-essential`, `pkg-config`, `libssl-dev`) and [mise](https://mise.jdx.dev/) pre-installed via its official quick-install script, with bash activation wired into `~/.bashrc`.

No new module input — this follows the same unconditional-provisioning pattern already used for `rclone`/`neovim`.

Since this edits the instance's cloud-init content, and the module already forces instance replacement whenever that content changes (ADR-0084), any existing instance using this module will be destroyed and recreated on its next `terragrunt apply` after upgrading to this version.

[#112](https://github.com/noisypigeon/noisypigeon/pull/112)
