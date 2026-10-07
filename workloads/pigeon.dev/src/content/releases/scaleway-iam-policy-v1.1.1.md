+++
title = "scaleway/iam-policy v1.1.1"
date = 2026-09-27T12:00:00-07:00
slug = "scaleway-iam-policy-v1.1.1"
description = "fix(adr-0070): downgrade admin bucket-policy statement to a supported version"
+++

## Context

`v1.1.0`'s `admin_project_id` statement (ADR-0069) used `Version = "2023-04-17"`, which rejects `project_id:` principals. The first live field-test (`tofu apply` against `noisypigeon/cli/scratch`) failed:

```
Error: error putting SCW bucket policy: ... MalformedPolicy: project_id Principal is deprecated
and only supported in the bucket-policy version 2012-10-17
```

Confirmed against Scaleway's own `terraform-provider-scaleway` docs: `2012-10-17` accepts the exact same Statement shape (Sid/Effect/Principal/Action/Resource) with a `project_id:` principal; `2023-04-17` only accepts `application_id:`/`user_id:`/wildcard principals. So `admin_project_id`'s mechanism was broken from the start for any bucket-scoped caller that set it.

## Decision

- Downgrade the whole generated policy document to `Version = "2012-10-17"`. No input/output signature change — `admin_project_id`'s name/type/default are untouched.
- `README.md` gets a note explaining the version downgrade and its trade-off (Scaleway documents `2012-10-17` as deprecated; the non-deprecated alternative — naming the deployer's `application_id` instead of its project — is deferred, since it needs new cross-leaf plumbing).
- `cli/scratch/iam.tf` and `vault/email/iam.tf` bump their module `ref` from `v1.1.0` to `v1.1.1`.
- `release:patch` — pure bugfix, no interface change.

Full ADR: [`docs/adr/0070-fix-scaleway-iam-policy-admin-statement-deprecated-version.md`](../blob/adr-0070-fix-scaleway-iam-policy-admin-statement-deprecated-version/docs/adr/0070-fix-scaleway-iam-policy-admin-statement-deprecated-version.md)

## Out of scope

- Switching to an `application_id:`-based admin principal — the non-deprecated alternative, deferred pending new plumbing for the deployer's application id.
- Recovering the already-locked-out `noisypigeon/cli/scratch` bucket — still a separate, pending manual step (owner-credentialed `aws s3api delete-bucket-policy`).

## Test plan

- [x] `terraform validate` passes on the module.
- [x] `terraform fmt -check` passes on all changed files.
- [x] `mise run ci` (Rust gate) passes — unaffected by this change.
- [ ] `terragrunt apply` for `cli/scratch` and `vault/email` with the new ref (requires live Scaleway credentials, and the pending owner-side recovery for `cli/scratch` — to be run after merge).

[#73](https://github.com/noisypigeon/noisypigeon/pull/73)
