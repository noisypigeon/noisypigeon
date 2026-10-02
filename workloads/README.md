# workloads

Each workload gets its own directory, `workloads/<name>/`, holding whatever
that workload needs as sibling subdirectories — e.g. `src/` for its
application source, `terraform/` for the infrastructure it's part of.
This is deliberately different from
[`terraform/infrastructure/`](../terraform/infrastructure/)'s
provider-rooted layout: terraform here lives *with* the resource it
manages, not grouped by cloud provider.

```
blog/
  src/        # the Zola site (ADR-0091)
  terraform/  # the Cloudflare DNS records that point noisypigeon.com at it (ADR-0092)
scaleway/
  terraform/  # the deployer IAM application and the Terraform state bucket itself (ADR-0094)
```

Not every workload has a `src/` sibling — `scaleway/` is infrastructure/bootstrap plumbing (the Scaleway deployer identity and this repo's own remote-state bucket), not a deployable app, so it's `terraform/` alone. The convention doesn't require `src/`; it just happens to exist for `blog/`.

## Terraform convention: `workloads/<name>/terraform/`

Every leaf's `terragrunt.hcl` is the same shape as any other leaf in this
repo:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = get_terragrunt_dir()
}
```

[`workloads/root.hcl`](root.hcl) is the shared root every leaf resolves
to by walking up. It enforces the convention itself: any leaf whose path
relative to `root.hcl` isn't exactly `<name>/terraform` gets `exclude`d
from `terragrunt run --all` — so a workload's `src/` (or any other
non-terraform subdirectory) is never accidentally swept into a plan/apply,
even if a `terragrunt.hcl` is mistakenly added there.

Secrets, provider wiring, and the remote-state backend follow the same
pattern as `terraform/infrastructure/`'s provider roots — see
[`terraform/infrastructure/README.md`](../terraform/infrastructure/README.md#secrets).
`workloads/root.hcl` only wires what's actually needed (Cloudflare for the
blog's DNS leaf, Scaleway for the `scaleway/terraform` leaf, added by
[ADR-0094](../docs/adr/0094-move-scaleway-bootstrap-leaf-to-workloads.md));
add a provider when a future workload actually needs it, not preemptively.

## Adding a new workload

1. `workloads/<name>/src/` (or whatever the workload's actual content is).
2. `workloads/<name>/terraform/` for its infrastructure, using the leaf
   shape above — `workloads/root.hcl` will pick it up automatically.
3. If the leaf needs a provider `workloads/root.hcl` doesn't wire yet,
   extend `workloads/root.hcl` at that point — see
   [ADR-0092](../docs/adr/0092-move-github-pages-leaf-to-workloads-blog-terraform.md)
   for the rationale behind keeping it minimal until then.
