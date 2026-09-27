# Changelog

All notable changes to this module are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.1] - 2026-09-27

### fix(adr-0072): raise GLACIER transition to Scaleway's 90-day minimum

## Context

ADR-0044 designed `storage_class = \"glacier\"` as an immediate (`days = 0`) `lifecycle_rule` transition to `GLACIER`. Applying it against the one live consumer (`noisypigeon/vault/email`) fails outright:

```
Error: error applying lifecycle configuration to bucket vault-5t39z4-email:
... api error InvalidArgument: Transition rule for storage-class "GLACIER" must be at least 90 days
```

Scaleway rejects a `days = 0` GLACIER transition outright — the API enforces a 90-day minimum. `storage_class = "glacier"` never actually worked.

## Decision

- Set `transition.days = 90` in `bucket.tf` — the minimum Scaleway's API accepts.
- No input/output signature change — `release:patch`.

Full ADR: [`docs/adr/0072-fix-scaleway-object-bucket-glacier-transition-minimum-days.md`](../blob/fix-scaleway-object-bucket-glacier-transition-minimum-days/docs/adr/0072-fix-scaleway-object-bucket-glacier-transition-minimum-days.md)

## Test plan

- [x] `terraform validate` passes on the module.
- [x] `terraform fmt -check` passes.
- [x] `mise run ci` (Rust gate) passes — unaffected by this change.
- [ ] `terragrunt apply` for `vault/email` with the new module version (to be run after merge, with live credentials).

[#77](https://github.com/noisypigeon/noisypigeon/pull/77)

## [0.1.0] - 2026-09-26

### Consolidate as terraform/modules/scaleway/object-bucket 0.1.0

A Scaleway Object Storage bucket (`scaleway_object_bucket`) with a
namespaced, randomized name (`{namespace}-{random}-{name}`, matching
`standard-storage-bucket`'s scheme), a versioning toggle
(`enable_versioning`), and a `storage_class` input (`standard`/`glacier`,
implemented via an immediate `lifecycle_rule` transition when set to
`glacier`). See
[ADR-0044](../../../../docs/adr/0044-add-scaleway-object-bucket-module.md)
and
[ADR-0045](../../../../docs/adr/0045-scaleway-object-bucket-namespaced-naming.md)
for the full set of decisions behind this module's design.

Consolidates this module's prior `pigeon-tf` version history (`v0.1.0`,
`v1.0.0`) into a single 0.1.0 release as part of merging `pigeon-tf` into
this repo — see
[ADR-0037](../../../../docs/adr/0037-merge-pigeon-tf-terraform-modules.md)
for the merge.
