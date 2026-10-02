# Changelog

All notable changes to this module are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.1] - 2026-09-30

### Fix scaleway/project ssh_key to scope to the created project

`scaleway/project`'s `scaleway_iam_ssh_key` resource (added in v0.2.0) was missing `project_id`, so it registered the SSH key against the Scaleway provider's default project rather than the project this module just created. This adds `project_id = scaleway_account_project.project.id` so the key is correctly scoped to the module's own project.

No input or output changes — this only fixes the behavior of the existing `ssh_key` input.

[#107](https://github.com/noisypigeon/noisypigeon/pull/107)

## [0.2.0] - 2026-09-30

### Add optional ssh_key input to scaleway/project

`scaleway/project` now accepts an optional `ssh_key` input (`{ alias, public_key }`) that registers a Scaleway IAM SSH key alongside the project via `scaleway_iam_ssh_key`. It's opt-in — omitting `ssh_key` (the default) skips creating the resource entirely, so existing consumers of this module are unaffected. When provided, the new `ssh_key_id` output exposes the created key's ID so it can be wired into a `scaleway/compute-instance` or similar downstream resource without a separate lookup.

This mirrors the pattern `scaleway/compute-instance` already uses for bucket access: project-adjacent identity/access resources are composed through the project module's own inputs rather than requiring a second module invocation.

[#106](https://github.com/noisypigeon/noisypigeon/pull/106)

## [0.1.0] - 2026-09-26

### Consolidate as terraform/modules/scaleway/project 0.1.0

A thin wrapper around `scaleway_account_project`, mirroring
`terraform/modules/digitalocean/project`'s layout and passthrough style —
this was `pigeon-tf`'s first module under the `scaleway/` provider root
(documented in
[ADR-0043](../../../../docs/adr/0043-add-scaleway-provider.md)), which also
generalized the release automation beyond a single hardcoded provider root.

Consolidates this module's prior `pigeon-tf` version history (`v0.1.0`) into
a single 0.1.0 release as part of merging `pigeon-tf` into this repo — see
[ADR-0037](../../../../docs/adr/0037-merge-pigeon-tf-terraform-modules.md)
for the merge.
