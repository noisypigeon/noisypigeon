+++
title = "scaleway/compute-instance v0.9.1"
date = 2026-10-02T12:00:00-07:00
slug = "scaleway-compute-instance-v0.9.1"
description = "Fix missing $HOME in scaleway/compute-instance cloud-init runcmd"
+++

`cloud-init status --long` was reporting `status: error` on every instance using this module. `cloud-init-output.log` pinpoints the root cause (confirmed from the actual log, not guessed — an initial hypothesis about an interactive `mkfs.ext4` prompt was ruled out; the volume mount block completes cleanly):

```
mise: selected 2026.9.18 (minimum release age: 24h)
sh: 325: HOME: parameter not set
/var/lib/cloud/instance/scripts/runcmd: 9: cannot create ~/.bashrc: Directory nonexistent
bash: line 6: HOME: unbound variable
```

cloud-init's `runcmd` module bundles every list item into one shell script and runs it once, in an environment with **no `$HOME` set**. That broke three independent things in the same script: the `mise.run` installer (references `$HOME` internally), this module's own `echo '...' >> ~/.bashrc` line (tilde expansion needs `$HOME`), and the `pigeon-cli` profile's bootstrap script (also references `$HOME`, under `bash`'s strict mode).

Fix: `export HOME=/root` as the first `runcmd` line (inherited by every later line in the same script), plus switching this module's own `~/.bashrc` reference to the absolute `/root/.bashrc`.

Full root-cause writeup in [ADR-0090](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0090-fix-missing-home-in-compute-instance-cloud-init-runcmd.md).

No input/output changes — pure bugfix to existing, previously-broken behavior.

## Test plan
- [x] `terraform fmt -check` clean
- [x] `terraform init -backend=false && terraform validate` clean
- [x] Rendered cloud-init and confirmed `export HOME=/root` is the first `runcmd` line and the mise line now targets `/root/.bashrc`
- [ ] User to re-apply and confirm `cloud-init status --long` reports `status: done` on a fresh instance

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#117](https://github.com/noisypigeon/noisypigeon/pull/117)
