+++
title = "scaleway/compute-instance v0.3.1"
date = 2026-09-30T12:00:00-07:00
slug = "scaleway-compute-instance-v0.3.1"
description = "Force instance replacement when compute-instance cloud-init changes"
+++

Root-caused (see ADR-0084 for the full investigation and citations): `scaleway_instance_server.user_data` has no `ForceNew` in the Terraform provider schema, so changing its `cloud-init` content on an *existing* instance just PATCHes the metadata in place via Scaleway's API — the instance keeps its instance-id. cloud-init only runs package-install and `write_files` modules once per instance-id, on first boot, so an in-place `user_data` update (or a plain reboot) is silently never applied. This is exactly what DigitalOcean's `digitalocean_droplet.user_data` avoids by being `ForceNew: true`, which ADR-0081 didn't carry over when porting the cloud-init pattern to Scaleway.

Fix: the cloud-config content moves into `local.cloud_init`, a new `terraform_data.cloud_init` resource hashes it, and `scaleway_instance_server.server` gets `lifecycle { replace_triggered_by = [terraform_data.cloud_init.output] }`. Any future change to the rendered cloud-init content (packages, buckets, write_files) now forces a fresh instance, guaranteeing cloud-init gets a genuine first boot on it — matching DigitalOcean's behavior.

No input or output changes. Note this doesn't retroactively fix any instance already running with skipped cloud-init modules — those need a one-time manual rebuild.

[#108](https://github.com/noisypigeon/noisypigeon/pull/108)
