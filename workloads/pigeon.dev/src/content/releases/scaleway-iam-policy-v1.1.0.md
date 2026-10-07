+++
title = "scaleway/iam-policy v1.1.0"
date = 2026-09-27T12:00:00-07:00
slug = "scaleway-iam-policy-v1.1.0"
description = "feat(adr-0069): guard scaleway/iam-policy against bucket-policy self-lockout"
+++

## Context

Every `scaleway/*` leaf authenticates as one identity: the `noisypigeon/terraform` leaf's self-managed deployer IAM application. `terraform/modules/scaleway/iam-policy/bucket_access.tf` writes each bucket's `scaleway_object_bucket_policy` naming only the module's own freshly-minted, narrow `scaleway_iam_application` as `Principal`. Scaleway bucket policies are allow-only: the moment any bucket policy exists, every other principal — including the deployer running Terraform — loses access to that bucket unless also named, and only the literal Organization Owner is exempt from that. Applying this module's bucket-scoped grant therefore locks the deployer itself out of the bucket it just configured, recoverable only via owner-credentialed `aws s3api delete-bucket-policy` — exactly what happened against `noisypigeon/cli/scratch`.

This is distinct from ADR-0066, which guards the narrow key's own scope, not the applier's continued access.

## Decision

- Add an optional `admin_project_id` variable to `terraform/modules/scaleway/iam-policy`. When set, `bucket_access.tf` appends a second `Allow` statement (`Principal = { SCW = "project_id:<id>" }`, `Action = ["s3:*"]`) to the generated bucket policy, so any principal with IAM permissions in that project — the deployer included — always retains access.
- Wire `admin_project_id = local.scaleway_project_id` at both live bucket-scoped consumers (`noisypigeon/cli/scratch`, `noisypigeon/vault/email`), bumping their module `ref` to `v1.1.0`.
- Update the module README's usage example accordingly.
- Additive/backward-compatible (`release:minor`).

Full ADR: [`docs/adr/0069-guard-scaleway-iam-policy-bucket-policy-self-lockout.md`](../blob/adr-0069-guard-scaleway-iam-policy-bucket-policy-self-lockout/docs/adr/0069-guard-scaleway-iam-policy-bucket-policy-self-lockout.md)

## Out of scope

- Recovering the already-locked-out `noisypigeon/cli/scratch` bucket — a one-time manual step (owner-credentialed `aws s3api delete-bucket-policy`, then a clean `terragrunt apply`), independent of this code fix.
- Enforcing `admin_project_id` via validation whenever `bucket_names` is set — left as a documented convention, not a hard requirement.

## Test plan

- [x] `terraform validate` passes on the module.
- [x] `terraform fmt -check` passes on all changed files.
- [x] `mise run ci` (Rust gate) passes — unaffected by this change.
- [ ] `terragrunt plan` for `cli/scratch` and `vault/email` (requires live Scaleway credentials — to be run before merge).

[#71](https://github.com/noisypigeon/pigeon/pull/71)
