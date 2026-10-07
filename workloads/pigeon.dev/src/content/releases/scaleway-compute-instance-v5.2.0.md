+++
title = "scaleway/compute-instance v5.2.0"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-compute-instance-v5.2.0"
description = "Add post_provision_commands to compute-instance"
+++

`compute-instance` gains an optional `instance_config.post_provision_commands` list of shell command strings, run in order. When set, they're wired up as a systemd oneshot unit (`pigeon-post-provision.service`, `RemainAfterExit=yes`, self-disabling after a successful run) ordered `After=cloud-final.service`/`Wants=cloud-final.service` and enabled via `runcmd --no-block`, so a long-running command (e.g. a `pigeon-cli` job) doesn't block cloud-init's own completion status and doesn't re-run on later reboots.

The commands are base64-encoded into their own `write_files` entry (`encoding: b64`) rather than embedded in YAML or in the unit's `ExecStart=` line, avoiding quoting/indentation pitfalls for arbitrary shell content. Secrets already written to `/etc/environment` (ADR-0104) reach the unit via `EnvironmentFile=-/etc/environment`. Output is inspected with `journalctl -u pigeon-post-provision.service`.

Purely additive — defaults to `[]`, unchanged behavior for every existing caller. See ADR-0125.

[#172](https://github.com/noisypigeon/noisypigeon/pull/172)
