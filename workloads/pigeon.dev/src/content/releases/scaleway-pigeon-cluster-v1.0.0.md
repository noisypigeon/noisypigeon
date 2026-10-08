+++
title = "scaleway/pigeon-cluster v1.0.0"
date = 2026-10-08T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v1.0.0"
description = "Fold debug-SSH bastion into pigeon-cluster, drop per-job enable_ipv4"
+++

`jobs[*].enable_ipv4` (ADR-0145) let you temporarily give one job instance a public IP for debugging, but it never actually worked: the cluster's shared Public Gateway advertises a default route to every instance on the Private Network, which takes priority over an attached instance's own public interface (confirmed via Scaleway's own documented troubleshooting for this exact symptom). The only path that actually works is SSH to the gateway's own public IP, forwarded via a PAT rule to the target's private IP.

This release removes `jobs[*].enable_ipv4` entirely and replaces it with a real, working mechanism: a new `cluster_config.enable_bastion` flag (default `false`). When set to `true`, the module provisions one dedicated bastion instance on the cluster's shared Private Network, with a `scaleway_vpc_public_gateway_pat_rule` forwarding the gateway's public IP (port 2222) to the bastion's private IP:22 — the connection command is available from the new `bastion_connect_command` output. The bastion itself gets no public IP (unlike enable_ipv4's dead-end approach) since the PAT rule is the only path that works.

Also in this release:
- `jobs[*].block_volume_iops` (default `15000`, matching `block-volume`'s and `compute-instance`'s own defaults) is now exposed — previously there was no way to override a job's block volume IOPS at this layer at all.
- Internal `compute-instance` pin bumped from `v5.6.0` to the current latest, `v5.6.1`.

**Breaking:** `jobs[*].enable_ipv4` is gone. No known caller sets it today, but any caller that does will need to remove it.

See ADR-0146 for the full design discussion and rationale.

[#250](https://github.com/noisypigeon/noisypigeon/pull/250)
