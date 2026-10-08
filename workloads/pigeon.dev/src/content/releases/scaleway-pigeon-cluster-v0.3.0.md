+++
title = "scaleway/pigeon-cluster v0.3.0"
date = 2026-10-08T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v0.3.0"
description = "Add Private Network support to compute-instance and pigeon-cluster"
+++

Adds Scaleway Private Network support so `pigeon-cli` job instances can reach Object Storage buckets over Scaleway's internal network instead of the public internet, avoiding egress billing on same-datacenter bucket traffic (ADR-0145, `docs/adr/0145-private-network-access-to-pigeon-cli-job-buckets.md`).

**`compute-instance`** gains an optional `private_network_id` input (default `null`). When set, the instance attaches to that Private Network via a dedicated `scaleway_instance_private_nic`, alongside its normal public IP(s) if any. This is a bring-your-own-ID input, matching the module's existing `additional_volume_ids` pattern — the module does not create the Private Network itself. Purely additive; no change for any existing caller.

**`pigeon-cluster`** now provisions one shared Private Network, Public Gateway, and gateway-network attachment per cluster (not per job), and wires every job's `compute-instance` call to that shared Private Network. Job instances no longer attach a public IP by default — the cluster's Public Gateway NATs outbound internet access for cloud-init's provisioning steps instead — but a new per-job `enable_ipv4` field (default `false`) lets you re-attach a public IP to any individual job, e.g. for debugging a stuck or failed instance.

Also in this change: `jobs` moves from a map keyed by job name to a list of objects, each naming its own `job_name` (e.g. `jobs = [{ job_name = "my-job", ... }]` instead of `jobs = { "my-job" = { ... } }`). `job_name` values must be unique within a cluster; per-job resource addressing is unaffected since the module converts the list to a job-name-keyed map internally. This is a breaking change to an existing input.

See ADR-0145 for the full research and design rationale, including why job buckets still need their `endpoint` manually switched to `https://<bucket>.s3-vpc.<region>.scw.eu` per keyring entry, and the one-time manual Scaleway VPC API step required before that endpoint is actually reachable.

[#244](https://github.com/noisypigeon/noisypigeon/pull/244)
