+++
title = "scaleway/iam-api-key v0.2.0"
date = 2026-10-05T12:00:00-07:00
slug = "scaleway-iam-api-key-v0.2.0"
description = "Add default_project_id input to iam-api-key"
+++

## Summary
`scaleway_iam_api_key` has its own `default_project_id` argument — the project Object Storage operations with this key are scoped to, independent of the owning IAM application's policy grants. Without it, a key defaults to the provider's own project regardless of what `project_ids` an attached `iam-policy` covers.

Confirmed live: `workloads/pigeon.dev/terraform/iam`'s key defaulted to the org's default project rather than `pigeon-dev`, so `aws s3 sync` in `pigeon-dev-pages.yml` failed with a deterministic `AccessDenied` on `ListObjectsV2` — the same "Scaleway object storage needs an explicit project_id on nearly everything" lesson as the earlier `object-bucket` ACL/website-config fix (PR #196), just in a different module this time.

Optional, defaults to `null` (today's behavior, unchanged) — no existing consumer needs updating.

## Test plan
- [x] `terraform validate`/`fmt` clean
- [ ] `workloads/pigeon.dev/terraform/iam` bumped to the new version and re-applied (separate follow-up PR, per this repo's module-change-then-consumer-bump sequencing)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#201](https://github.com/noisypigeon/noisypigeon/pull/201)
