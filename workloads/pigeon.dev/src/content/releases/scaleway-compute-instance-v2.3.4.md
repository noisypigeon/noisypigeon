+++
title = "scaleway/compute-instance v2.3.4"
date = 2026-10-03T12:00:00-07:00
slug = "scaleway-compute-instance-v2.3.4"
description = "Fix environment_variables/PIGEON_LOG_DIR not reaching non-login SSH invocations"
+++

`scaleway/compute-instance` has only ever delivered `environment_variables` (and the cockpit-gated `PIGEON_LOG_DIR`, ADR-0102) via `/etc/profile.d/pigeon-env.sh` (ADR-0101). That file is auto-sourced only by an interactive **login** shell. A one-off `ssh host 'pigeon job run dedupe ...'` — an ordinary way to kick off a job and disconnect — opens a non-login shell and never sources it, so the process falls through to `pigeon-cli`'s own XDG-based default log directory instead of the pinned `/var/log/pigeon` path Alloy's Loki config expects. This was caught live on a real `pigeon-cli` instance: its JSONL log landed under `~/.local/share/pigeon/logs/` instead of `/var/log/pigeon/pigeon.jsonl`, even though a separate, later interactive SSH session correctly showed `PIGEON_LOG_DIR=/var/log/pigeon` — two different shell sessions, two different environments.

This PR also writes the same key/value pairs to `/etc/environment`, alongside (not replacing) the existing `/etc/profile.d` file. `/etc/environment` is read by PAM's `pam_env` module during session setup for *any* SSH-authenticated session — login shell or a direct `ssh host cmd` — because PAM's session phase runs regardless of whether a shell actually starts. This is Ubuntu/Debian's default `sshd` PAM stack, so no new package or config is needed beyond writing the file.

Since `environment_variables` already carries secret material by design (it's `sensitive = true`, e.g. this repo's own `deduplication/media` leaf passes real bucket secret keys through it), the new `/etc/environment` entry is permissioned `0600` rather than the conventional world-readable `0644` — matching the level `pigeon-env.sh` already uses. `sshd`'s own PAM read happens while it's still running as root, before dropping privileges, so the tighter permission doesn't break the mechanism.

No input/output signature change — purely a cloud-init rendering fix. Full writeup: [docs/adr/0104-fix-env-vars-not-reaching-non-login-ssh-invocations.md](docs/adr/0104-fix-env-vars-not-reaching-non-login-ssh-invocations.md).

Note for whoever applies this: like any `local.cloud_init` content change, this force-replaces every existing instance that picks up the new module version on its next `terragrunt apply` (`lifecycle.replace_triggered_by`) — bump a leaf's version pin and apply it deliberately, not as a surprise.

[#133](https://github.com/noisypigeon/noisypigeon/pull/133)
