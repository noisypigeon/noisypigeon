+++
title = "scaleway/project v0.2.0"
date = 2026-09-30T12:00:00-07:00
slug = "scaleway-project-v0.2.0"
description = "Add optional ssh_key input to scaleway/project"
+++

`scaleway/project` now accepts an optional `ssh_key` input (`{ alias, public_key }`) that registers a Scaleway IAM SSH key alongside the project via `scaleway_iam_ssh_key`. It's opt-in — omitting `ssh_key` (the default) skips creating the resource entirely, so existing consumers of this module are unaffected. When provided, the new `ssh_key_id` output exposes the created key's ID so it can be wired into a `scaleway/compute-instance` or similar downstream resource without a separate lookup.

This mirrors the pattern `scaleway/compute-instance` already uses for bucket access: project-adjacent identity/access resources are composed through the project module's own inputs rather than requiring a second module invocation.

[#106](https://github.com/noisypigeon/noisypigeon/pull/106)
