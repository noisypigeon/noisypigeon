# Changelog

All notable changes to this module are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-09-27

### feat(adr-0066): guard scaleway/iam-policy against bucket-scope widening

## Context

`terraform/modules/scaleway/iam-policy` has supported bucket-scoped access (`bucket_names`/`bucket_actions`) independently of org/project grants since ADR-0049. But the one real prior attempt to use it for a read-only bucket key — the commented-out `terraform/infrastructure/scaleway/fr-par/pigeon.dev/scratch/iam.tf` (merged in verbatim from `pigeon-do` via ADR-0052) — combined `bucket_names` with a blanket project-level `ObjectStorageObjectsRead`/`ObjectStorageObjectsWrite` grant in the same call. Since Scaleway IAM rules are allow-only with no explicit deny (per ADR-0048's own findings), that blanket grant already covers every bucket in the project, making the bucket restriction decorative — exactly the "composition hazard" ADR-0048 documented but explicitly declined to enforce in code.

## Decision

- Add a cross-variable `validation` block on `bucket_names` rejecting any call that combines it with an `ObjectStorage*`-family `organization_permission_sets`/`project_permission_sets` entry — verified against the exact broken prior-art pattern (now correctly rejected at `plan` time), the one live consumer (`noisypigeon.com/terraform/iam.tf`, unaffected since it never sets `bucket_names`), and the intended bucket-scoped read-only pattern (passes cleanly).
- Document the correct bucket-scoped, read-only usage pattern in the module `README.md`.
- Breaking release → `release:major`, next tag `terraform/modules/scaleway/iam-policy/v1.0.0`.
- Full ADR: [`docs/adr/0066-scaleway-iam-policy-prevent-bucket-scope-widening.md`](../blob/adr-0066/scaleway-iam-policy-bucket-scope-guard/docs/adr/0066-scaleway-iam-policy-prevent-bucket-scope-widening.md)

## Also included

- A pre-existing `terraform fmt` alignment fix in `iam_policy.tf` (`dynamic "rule"` blocks), picked up incidentally while format-checking the module — unrelated to the validation change itself.
- A fix to `.mise.toml`: the ADR-0052 merge left `pigeon-do`'s terraform `fmt`/`fmt-check` tasks under the same names as the pre-existing Rust tasks (duplicate TOML keys), which broke `mise`'s ability to parse its own config at all — blocking `mise run ci` and every other `mise run` command repo-wide. Renamed to `fmt-terraform`/`fmt-check-terraform`, matching what `CLAUDE.md`'s Commands section already documented.

## Test plan

- [x] `terraform validate` passes on the module.
- [x] `terraform plan` with the broken prior-art pattern (`bucket_names` + `ObjectStorageObjectsRead`/`Write`) fails validation with the new error message.
- [x] `terraform plan` with the live `noisypigeon.com/terraform/iam.tf` pattern (org/project grants, no `bucket_names`) still plans cleanly.
- [x] `terraform plan` with the intended read-only bucket-scoped pattern (`bucket_names` + `bucket_actions = ["s3:ListBucket", "s3:GetObject"]`, no org/project grant) plans cleanly.
- [x] `mise run ci` passes.

[#64](https://github.com/noisypigeon/pigeon/pull/64)

## [0.1.0] - 2026-09-26

### Consolidate as terraform/modules/scaleway/iam-policy 0.1.0

A Scaleway `scaleway_iam_application` and `scaleway_iam_policy` wrapper that
produces a permission-scoped `scaleway_iam_api_key`. Access can be granted
independently at three scopes — organization (`organization_id` +
`organization_permission_sets`), project (`project_ids` +
`project_permission_sets`), and specific Object Storage buckets
(`bucket_names`, a map of static logical key → bucket name, +
`bucket_actions`, validated against a known set of S3 actions) — with at
least one scope required but none individually mandatory; the underlying
`scaleway_iam_policy` resource and its `rule` blocks are created only when a
scope is fully populated. An optional `expires_at` input sets an expiration
timestamp on the minted API key. Requires Terraform/OpenTofu `>= 1.9.0` for
its cross-variable `validation` block. See
[ADR-0046](../../../../docs/adr/0046-add-scaleway-iam-policy-module.md)
through
[ADR-0049](../../../../docs/adr/0049-scaleway-iam-policy-optional-scopes.md)
for the full set of decisions behind this module's design.

Consolidates this module's prior `pigeon-tf` version history (`v0.1.0`
through `v3.0.1`) into a single 0.1.0 release as part of merging `pigeon-tf`
into this repo — see
[ADR-0037](../../../../docs/adr/0037-merge-pigeon-tf-terraform-modules.md)
for the merge.
