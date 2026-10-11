+++
title = "scaleway/pigeon-cluster v3.0.0"
date = 2026-10-10T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v3.0.0"
description = "Compose cloud-init, volumes, IPs, NICs and self-delete IAM at the cluster level"
+++

`pigeon-cluster` now composes every concern that used to be nested inside `compute-instance`, and re-pins it from `v6.1.0` to `v7.0.0`. Nothing about `cluster_config` or `jobs` changes — a consuming leaf only needs to bump its pin.

Five things move up into this module. Cloud-init is rendered by `compute-instance-config`, one document per job plus one for the bastion. Block volumes are created directly from `block-volume`, `for_each` over the jobs that ask for one. Per-instance IPv4 addresses are created here and passed in as `ip_ids`, because an IP has to exist before the server that references it — which is precisely why it could not live in the module that creates the server. The private NIC is attached here too, which puts it next to the Private Network it attaches to; it stays a standalone resource rather than an inline block, for ADR-0145's original reason that attach/detach must never replace the server. And the self-delete IAM policy and API key are composed here, with the credential handed to `compute-instance-config`.

The self-delete pair is deliberately kept separate from the job's existing work policy and key rather than merged into them. Merging would have removed a genuine duplicate — each job currently gets two policies and two keys on one application — but it would also hand the job's own keyring credential `InstancesFullAccess`, and ADR-0144 narrowed the self-delete grant to exactly that one permission specifically to keep them apart. What does go away is the `-work-` segment in the first policy's name: that existed only to dodge a 409 duplicate-name collision with a policy generated two layers down and therefore invisible here. Both are now named in the same file, so the collision is avoidable in the obvious way.

Two improvements fall out of the move. The bastion's PAT rule reads `scaleway_instance_private_nic.bastion[0].private_ips` directly, retiring the `private_ips` output that existed only to work around `scaleway_instance_server`'s own attribute not reflecting a separately-attached NIC — with the NIC in this module there is one authoritative source and no `try()` fallback. And `jobs` gains the cross-variable validation ADR-0149 consciously skipped: a job requesting a Private Network on a cluster that has one disabled used to fall through to `compute-instance`'s own validation one level down, which no longer exists, so the check now lives here where it can name both variables and say what is actually wrong.

Every `for_each` added here keys off a `jobs[*]` field and never a resource ID, per ADR-0145 Section 4 — `count`/`for_each` cannot depend on an apply-time-unknown value. Verified with `tofu validate` plus `tofu graph` against a realistic one-job cluster with bastion, private network, gateway, volume and transcoding all enabled: all ten module sources resolve through the pigeon.dev redirect, there is no cycle, and the dependency chain runs self-delete key → config → server → NIC with no back edge. The new validation was confirmed to fire on the misconfiguration and stay quiet on the valid one.


[#270](https://github.com/noisypigeon/noisypigeon/pull/270)
