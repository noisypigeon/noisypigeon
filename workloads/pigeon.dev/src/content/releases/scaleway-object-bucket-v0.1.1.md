+++
title = "scaleway/object-bucket v0.1.1"
date = 2026-09-27T12:00:00-07:00
slug = "scaleway-object-bucket-v0.1.1"
description = "fix(adr-0072): raise GLACIER transition to Scaleway's 90-day minimum"
+++

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
