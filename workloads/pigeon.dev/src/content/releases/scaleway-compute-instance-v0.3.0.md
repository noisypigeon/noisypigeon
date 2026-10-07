+++
title = "scaleway/compute-instance v0.3.0"
date = 2026-09-30T12:00:00-07:00
slug = "scaleway-compute-instance-v0.3.0"
description = "Add routed IPv6 and instance-specific SSH keys to scaleway/compute-instance"
+++

`scaleway/compute-instance` gains two new opt-in inputs:

- **`enable_ipv6`** (bool, default `false`): when true, creates a `scaleway_instance_ip` of type `routed_ipv6` and attaches it to the instance via `ip_id`. The address shows up in the existing `public_ips` output once attached (filter by `family == "inet6"`) -- no new output was added. Note: the originally-proposed `scaleway_flexible_ip` resource does *not* apply here -- it's scoped to Elastic Metal (bare metal) servers only, confirmed directly against the Terraform provider's source. `scaleway_instance_ip` is the correct mechanism for a standard Instance's routed IP.

- **`ssh_keys`** (list of strings, default `[]`): raw SSH public keys that get instance-specific access, in addition to account-wide keys that already apply automatically. The module encodes each into Scaleway's `AUTHORIZED_KEY=<key-with-underscores>` tag convention, so callers don't have to hand-escape spaces themselves.

Both inputs default to their no-op values, so this is fully backwards compatible. See ADR-0082 and ADR-0083 for the full design rationale.

[#105](https://github.com/noisypigeon/noisypigeon/pull/105)
