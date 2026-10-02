# ADR-0094: move the Scaleway bootstrap leaf to `workloads/scaleway/terraform`, pure state surgery

- **Author**: Willow Finch ([@noisypigeon](https://github.com/noisypigeon)).
- **Date**: 2026-10-02.
- **Status**: Accepted.

## Context

`terraform/infrastructure/scaleway/fr-par/noisypigeon/terraform/` is this repo's most sensitive leaf. Its `bucket.tf` provisions the S3 bucket that holds every leaf's own Terraform remote state (`terraform-t0nh1b-state`, via `modules/scaleway/object-bucket`), and its `iam.tf` provisions the deployer IAM application/policy/API key every other `scaleway/*` leaf authenticates as — confirmed directly in ADR-0069's text: *"Every `scaleway/*` leaf... authenticates as one identity: the `noisypigeon/terraform` leaf's self-managed 'deployer' IAM application... Its `access_key`/`secret_key` populate `SCALEWAY_ACCESS_KEY`/`SCALEWAY_SECRET_KEY`"*.

The user wanted it moved into the `workloads/` convention (ADR-0092/0093) at `workloads/scaleway/terraform`, explicitly as a **state surgery** — the underlying cloud resources (bucket, IAM application, policy, API key) must not be destroyed or recreated.

**Research confirmed, verbatim, before planning anything:**

- The leaf has exactly 3 tracked files — `terragrunt.hcl`, `bucket.tf`, `iam.tf` (the latter also holding the two inline `output` blocks, `access_key`/`secret_key`, both `sensitive = true`). Both `.tf` files already referenced the current `modules/scaleway/*` paths at their current major versions (v1.0.0/v2.0.0, ADR-0093) — zero content changes needed, a pure file relocation.
- **No `dependency` block anywhere in the repo reads this leaf's outputs** — confirmed via a repo-wide grep. Every other `iam.tf` under `terraform/infrastructure/scaleway/**` defines its own independent `module "iam"` block. The link from this leaf's `access_key`/`secret_key` to every other leaf's actual credentials is purely manual: hand-copied into the shared root `.env`'s `SCALEWAY_ACCESS_KEY`/`SCALEWAY_SECRET_KEY`, which every `root.hcl` reads via `get_env(...)`. This is exactly why "resources shouldn't change" matters here specifically — if the IAM resources were destroyed and recreated instead of state-migrated, the real credential values would change, and `.env` (along with every other leaf's auth) would silently break, since nothing re-reads them automatically.
- `bucket.tf` already has `enable_versioning = true` on the state bucket — S3 object versioning was already protecting every state object in it, including this leaf's own, before this ADR. A pre-existing safety net, not something added here.
- Current backend (from `scaleway/root.hcl`'s `remote_state`, read verbatim): bucket `terraform-t0nh1b-state`, key `scaleway/${path_relative_to_include()}/terraform.tfstate` → resolved to `scaleway/fr-par/noisypigeon/terraform/terraform.tfstate`.
- `workloads/root.hcl` (ADR-0092) already reuses the **same** S3 bucket for its own `remote_state` block, just under a `workloads/` key prefix. After the move, this leaf's key becomes `workloads/scaleway/terraform/terraform.tfstate` — inside the exact same bucket. The bucket itself never moves or gets renamed; only this leaf's state *key* changes. The leaf's new path also satisfies `workloads/root.hcl`'s existing `exclude` guard (`scaleway/terraform` → 2 segments, second literally `terraform`) with no changes needed to that guard.
- **A real gap found**: `workloads/root.hcl` had no `provider "scaleway"` block at all — only `cloudflare` (ADR-0092 deliberately deferred this: "add a provider when a future workload actually does"). It also lacked the `scaleway_organization_id`/`scaleway_project_id_noisypigeon` locals `iam.tf` references (previously generated only by `scaleway/root.hcl`'s `generate "scaleway_ids"` block). Both needed to be added, or the moved leaf would fail to resolve those locals entirely.
- Neither `bucket.tf` nor `iam.tf` needs `scaleway/root.hcl`'s other machinery (the `ENV_SW_*`-prefixed `bucket_names_generated.tf` mechanism, region/zone-by-path-segment detection) — kept out of `workloads/root.hcl` to stay minimal.

## Decision

### Extended `workloads/root.hcl`: Scaleway provider + ids

Scaleway was combined into the **existing** `generate "provider"` block rather than added as a separate one — mirroring a real precedent in this repo's own history (the pre-provider-split root.hcl era, per ADR-0060's context: "every leaf already receives both providers' `generate "provider"` blocks regardless of whether that leaf actually uses both"), and avoiding any uncertainty about whether two separate `generate` blocks each declaring their own `terraform { required_providers {} }` would merge cleanly. Region/zone hardcoded to `fr-par`/`fr-par-1` (matching this leaf's already-applied provider config exactly) rather than replicating `scaleway/root.hcl`'s path-segment-based region detection — `workloads/<name>/terraform` leaves have no region segment in their path to detect from, and there's only one such leaf today. Add real multi-region support when a second `workloads/*/terraform` leaf actually needs a different region.

A new `generate "scaleway_ids"` block produces the two exact local names `iam.tf` references, unchanged in shape from `scaleway/root.hcl`'s own version. No change was needed to `workloads/root.hcl`'s `remote_state` block or `exclude` guard — both already compatible.

**Verified safe** (without displaying any secret content — checked by redirecting `terragrunt render --json` output to a file and inspecting only the exit code and error count, consistent with this session's established practice after an earlier credential-exposure incident): the moved leaf renders successfully against the extended `workloads/root.hcl` with zero errors.

### Move

`git mv terraform/infrastructure/scaleway/fr-par/noisypigeon/terraform workloads/scaleway/terraform` — all 3 files move unchanged. `terraform/infrastructure/scaleway/fr-par/noisypigeon/` keeps its other leaves (`custodian/dhj/`, `import/*`).

### Documentation

`workloads/README.md` gains the `scaleway/terraform/` example and a note that not every workload needs a `src/` sibling (this one is infrastructure/bootstrap plumbing, not a deployable app). `CLAUDE.md` and `docs/USAGE.md` updated with the new leaf's description/location. `terraform/infrastructure/README.md`'s Structure-section example path swapped from the now-moved leaf to a still-live one (`fr-par/noisypigeon/custodian/dhj`).

### The actual state migration — manual, not performed in this session

This is a live state relocation against this repo's own state-bucket-and-deployer-credential leaf. Consistent with this session's established caution around real credentials, and with every prior leaf-move ADR in this repo (ADR-0092) deferring live `terragrunt init`/state migration to the user, **this ADR does not execute it.** Runbook, to be run by the user once this PR merges:

1. `cd workloads/scaleway/terraform`
2. `terragrunt init` — Terraform detects the backend config changed (new `key`, same bucket/backend type) and prompts to copy existing state to the new backend. Answer **yes**. This copies the state object from the old key to the new one, within the same bucket — it does not touch resource addresses and does not destroy/recreate anything. It does not delete the old state object either (S3 versioning on the bucket is an additional, independent safety net regardless).
3. `terragrunt plan` — **must show zero changes.** This is the verification that the move was purely bookkeeping. If it proposes any change, stop and investigate before applying anything.
4. Optional, low-priority, can be done anytime later or skipped: remove the now-orphaned old state object at `scaleway/fr-par/noisypigeon/terraform/terraform.tfstate` directly (not a Terraform operation).

## Consequences

- Until the user runs the manual migration, `workloads/scaleway/terraform` exists with no state behind it yet at its new key — not runnable as-is immediately after merge. Expected, not a defect.
- Every other `scaleway/*` leaf's `.env`-sourced credentials are unaffected by this move, provided the migration step is a state copy rather than a destroy+apply — verified safe by the lack of any `dependency` block and the existing S3 versioning safety net.
- `terraform/infrastructure/scaleway/fr-par/noisypigeon/` loses one leaf but keeps the others; no other leaf references this one by path or Terragrunt dependency.

## Out of scope

- Running the actual state migration — the user's job, per the runbook above.
- Deleting the orphaned old state object — optional cleanup, left to the user's discretion and timing.
- Multi-region support in `workloads/root.hcl`'s Scaleway provider block — add when a second `workloads/*/terraform` leaf actually needs a region other than `fr-par`.
