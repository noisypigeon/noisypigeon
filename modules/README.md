# Terraform modules

Versioned, reusable Terraform modules, consumed by this repo's own
[`terraform/infrastructure/`](../terraform/infrastructure/) and any future
infra repos. Originally the standalone `pigeon-tf` repo, merged into this
repo by [ADR-0037](../docs/adr/0037-merge-pigeon-tf-terraform-modules.md);
see [ADR-0054](../docs/adr/0054-pigeon-tf-scaffold.md) (originally
`pigeon-do` ADR-0002) for the design decisions behind consuming the
original repo. Moved here from `terraform/modules/` by
[ADR-0093](../docs/adr/0093-move-scaleway-modules-to-top-level-modules.md).

This directory holds only module source — it has no root provider/backend configuration and is never `terraform`/`terragrunt` run standalone.

## Modules

| Path | Description |
| --- | --- |
| `scaleway/project` | A thin wrapper around `scaleway_account_project`. |
| `scaleway/object-bucket` | A Scaleway Object Storage bucket (`scaleway_object_bucket`) with a randomized name suffix, versioning, and a standard/glacier storage-class toggle implemented via an immediate lifecycle transition. |
| `scaleway/compute-instance` | A Scaleway compute Instance (`scaleway_instance_server`) with a randomized name suffix; minimal interface — image, type (defaults to `STARDUST1-S`), optional block volume attachment via `additional_volume_ids`. |
| `scaleway/iam-policy` | A Scaleway `scaleway_iam_application` and `scaleway_iam_policy` wrapper to produce a restricted `scaleway_iam_api_key` using permission sets. |
| `scaleway/block-volume` | A Scaleway Block Storage volume (`scaleway_block_volume`) with a randomized name suffix; minimal interface — `size` (renamed from `size_in_gb`), `iops` (defaults to `15000`). |

## Versioning

Releases are tagged on `noisypigeon`'s `main` with per-module, path-scoped semantic versions (`modules/<provider>/<module>/vX.Y.Z`). Consuming repos pin to a tag by checking out that tag in their local clone of this repo. Tags created before [ADR-0093](../docs/adr/0093-move-scaleway-modules-to-top-level-modules.md) keep their original `terraform/modules/<provider>/<module>/vX.Y.Z` form (and tags created before the ADR-0037 merge keep an even older, shorter form still) — old tags are never renamed or deleted, see ADR-0037/ADR-0093 for why.

## Consuming

This repo's own [`terraform/infrastructure/`](../terraform/infrastructure/)
and [`workloads/`](../workloads/) consume these modules directly, in the
same working tree, via a tagged `git::` source pointing back at this same
repo — e.g.:

```hcl
module "state_bucket" {
  source = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/object-bucket?ref=modules/scaleway/object-bucket/v1.0.0"
  ...
}
```

An *external* infra repo (no local checkout of this repo) consumes modules
the same way — a tagged `git::` source works identically for any consumer,
in-repo or not. For local iteration against an unreleased module change
(no network fetch), clone this repo as a sibling directory instead and
reference it by path:

```
git clone git@github.com:noisypigeon/noisypigeon.git ../noisypigeon
```

then reference modules under `modules/`, e.g.
`../noisypigeon/modules/scaleway/object-bucket`.
