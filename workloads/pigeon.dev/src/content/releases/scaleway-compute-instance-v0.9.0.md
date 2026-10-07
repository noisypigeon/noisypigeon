+++
title = "scaleway/compute-instance v0.9.0"
date = 2026-10-02T12:00:00-07:00
slug = "scaleway-compute-instance-v0.9.0"
description = "Auto-mount attached volume and inline pigeon-cli bootstrap on scaleway/compute-instance"
+++

Two behavior changes, no interface changes:

**Auto-mount the attached volume.** When `additional_volume_ids` is non-empty, cloud-init now formats and mounts the first attached volume automatically on first boot:

```
mkfs.ext4 -L data /dev/sdb
mkdir -p /mnt/data
mount /dev/sdb /mnt/data
UUID=$(blkid -s UUID -o value /dev/sdb)
echo "UUID=$UUID /mnt/data ext4 defaults,nofail 0 2" >> /etc/fstab
mount -a
```

**⚠️ `mkfs.ext4` is unconditional.** This module already force-replaces the instance on any cloud-init content change (ADR-0084), and this PR is itself a cloud-init change — so every existing instance with an attached volume will have that volume **reformatted from scratch** on its next apply after upgrading. This is a deliberate, confirmed tradeoff (no "format only if unformatted" guard), documented in [ADR-0089](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0089-auto-mount-volume-and-inline-pigeon-cli-bootstrap.md). Scope is also limited to exactly one volume at a fixed `/dev/sdb` path and a hardcoded `/mnt/data` mount point / `data` label.

**Fix `pigeon-cli`: inline the bootstrap script.** The `BOOTSTRAP` env var from the previous release (meant to be run via `eval $BOOTSTRAP`) didn't work in practice. `profile = "pigeon-cli"` now runs the bootstrap pipeline directly in `runcmd` on first boot instead:

```
curl -fsSL https://gist.githubusercontent.com/noisypigeon/1e96e8ef94380f913f6ae02782965149/raw/pigeon.sh | bash
```

Full rationale in [ADR-0089](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0089-auto-mount-volume-and-inline-pigeon-cli-bootstrap.md).

## Test plan
- [x] `terraform fmt -check` clean
- [x] `terraform init -backend=false && terraform validate` clean
- [x] Rendered cloud-init for: no volume (no mount commands), with volume (mount sequence appears before mise), and `profile = "pigeon-cli"` with volume (mount sequence + direct bootstrap curl|bash, no stray `BOOTSTRAP` export)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#116](https://github.com/noisypigeon/noisypigeon/pull/116)
