+++
title = "scaleway/compute-instance v0.8.0"
date = 2026-10-02T12:00:00-07:00
slug = "scaleway-compute-instance-v0.8.0"
description = "Add pigeon-cli cloud-init profile and ipv4_address output to scaleway/compute-instance"
+++

`scaleway/compute-instance`'s `profile` input gains a third value, `"pigeon-cli"`, alongside the existing `"rclone"`/`"docker"` (ADR-0087). Unlike those two, it installs no packages — it only appends an export line to `~/.bashrc` setting a `BOOTSTRAP` environment variable to:

```
curl -fsSL https://gist.githubusercontent.com/noisypigeon/1e96e8ef94380f913f6ae02782965149/raw/pigeon.sh | bash
```

**Invocation note:** run it as `eval $BOOTSTRAP`, not bare `$BOOTSTRAP`. Unquoted shell variable expansion doesn't get re-parsed for operators like `|`, so typing `$BOOTSTRAP` directly would pass `-fsSL`, the URL, `|`, and `bash` as literal arguments to `curl` rather than piping to it. `eval` re-parses the expanded string and runs the pipeline correctly.

Supporting this profile required making the cloud-init template's `packages:` key itself conditional (previously always emitted; `pigeon-cli` needs zero packages, and an empty `packages:` key is invalid/null in cloud-init YAML). Rendered output for `"rclone"`/`"docker"` is unchanged.

Also adds a new `ipv4_address` output, sourced from the existing routed-IPv4 resource — `null` when `enable_ipv4 = false`. Purely additive; `public_ips`/`private_ips` are unchanged.

Full design rationale in [ADR-0088](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0088-add-pigeon-cli-profile-to-scaleway-compute-instance.md).

Existing callers are unaffected by the interface change (new enum value, new output, both default-preserving), but — as with every prior change to this module's cloud-init content — any existing instance gets replaced on its next apply (ADR-0084's force-replace-on-cloud-init-change lifecycle).

## Test plan
- [x] `terraform fmt -check` clean
- [x] `terraform init -backend=false && terraform validate` clean
- [x] Rendered all three profiles via a scratch config: `rclone`/`docker` output unchanged, `pigeon-cli` correctly omits `packages:` and sets the `BOOTSTRAP` export

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#115](https://github.com/noisypigeon/noisypigeon/pull/115)
