# Terraform infrastructure

Live Terragrunt/Terraform configuration for personal infrastructure on
Scaleway. Originally the standalone
`pigeon-do` repo, merged into this repo by
[ADR-0052](../../docs/adr/0052-merge-pigeon-do-terraform-infrastructure.md);
see [`docs/adr/0053`-`0064`](../../docs/adr/) (each carrying an `Origin:
pigeon-do ADR-000N` bullet) for the design decisions behind the original
repo, including how its layout arrived at what's actually on disk today.

This directory consumes [`modules/`](../../modules/) — never a local
path, always a tagged `git::` source, the same way any other consumer
would (see [`modules/README.md`](../../modules/README.md)):

```hcl
module "bucket" {
  source            = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/object-bucket?ref=modules/scaleway/object-bucket/v1.0.0"
  enable_versioning = true
  namespace         = "terraform"
  name              = "state"
}
```

## Structure

Provider-rooted, per [ADR-0061](../../docs/adr/0061-per-provider-root-hcl.md).
Cloudflare-managed DNS used to have its own provider root here too, but
every leaf under it has since moved to (or been deleted in favor of)
`workloads/<name>/terraform/` — see
[ADR-0096](../../docs/adr/0096-move-fastmail-leaves-to-workloads-email-terraform.md)
— leaving this directory Scaleway-only:

```
scaleway/
  root.hcl                              # secrets, provider, remote_state
  <region-or-global>/<domain>/<leaf>/   # e.g. fr-par/noisypigeon/custodian/dhj
```

Every leaf's `terragrunt.hcl` is the same shape:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = get_terragrunt_dir()
}
```

`root.hcl` is found by walking up from the leaf to the nearest match, so
each provider's leaves automatically resolve that provider's own
`root.hcl` — no per-leaf provider selection needed.

A second, parallel Terragrunt tree exists at
[`workloads/`](../../workloads/) — terraform colocated with the resource
it's part of (`workloads/<name>/terraform/`, sitting next to
`workloads/<name>/src/`), rather than provider-rooted. Both trees run
under the same `mise run plan`/`apply` (`terragrunt run --all` from the
repo root discovers both). See `workloads/README.md` and
[ADR-0092](../../docs/adr/0092-move-github-pages-leaf-to-workloads-blog-terraform.md).

## Secrets

A single `.env` (git-ignored, never committed) and `.env.example`
(tracked, blank) at the **true repo root** (moved there from
`terraform/infrastructure/.env` by
[ADR-0092](../../docs/adr/0092-move-github-pages-leaf-to-workloads-blog-terraform.md),
finally realizing what
[ADR-0063](../../docs/adr/0063-shared-root-env-and-cloudflare-migration.md)
originally intended — `workloads/root.hcl` needs to reach the same file
too, and it isn't nested under this directory). Every provider's
`root.hcl` reads it via `find_in_parent_folders(".env", "")`, walking up
from wherever that `root.hcl` lives to the actual repo root. A real shell
environment variable always overrides the `.env` file value for the same
key.

## Getting started

```sh
cp .env.example .env   # at the repo root; then fill in real values — never commit this file
```

`terraform`/`terragrunt` are wired into this repo's root `.mise.toml` —
run from the repo root:

```sh
mise run plan    # terragrunt run --all -- plan, across both terraform/infrastructure/ and workloads/
mise run apply   # terragrunt run --all -- apply
```

or per-leaf / per-provider directly with Terragrunt:

```sh
cd scaleway/fr-par/noisypigeon/custodian/dhj
terragrunt plan
terragrunt apply
```

```sh
cd scaleway
terragrunt run --all -- plan
```
