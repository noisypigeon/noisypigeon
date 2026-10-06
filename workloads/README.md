# workloads

Each workload gets its own directory, `workloads/<name>/`, holding whatever
that workload needs as sibling subdirectories — e.g. `src/` for its
application source, `terraform/` for the infrastructure it's part of.
Terraform here lives *with* the resource it manages, not grouped by cloud
provider. This is this repo's only live Terraform/Terragrunt tree — the
former provider-rooted `terraform/infrastructure/` was fully decommissioned
once its last leaves moved here, see
[ADR-0098](../docs/adr/0098-decommission-terraform-infrastructure.md).

```
noisypigeon.com/
  src/                     # the Zola blog (ADR-0091, moved here from blog/ by ADR-0132)
  root.hcl                 # per-workload Terragrunt root (ADR-0130/0132)
  secrets.enc              # per-workload sops/age-encrypted secrets (ADR-0131)
  terraform/
    project/               # dedicated Scaleway project
    state/
      bucket/                # dedicated Terraform state bucket (resolves to the shared root -- ADR-0130)
      iam/                   # dedicated deployer IAM application/policy/API key (resolves to the shared root)
    blog/
      bucket/                # the noisypigeon.com Scaleway object-bucket (website-hosting, public-read)
      iam/                   # deploy-scoped IAM for the GitHub Actions sync workflow
      dns/                   # Cloudflare apex/www CNAMEs + www redirect ruleset (ADR-0132)
    bluesky/
      dns/                   # AT Protocol domain-handle verification TXT record
    proton/
      dns/                   # Proton Mail SPF/DKIM/MX/DMARC records
    google-search/
      dns/                   # Google site-verification TXT record
pigeon.dev/
  src/                     # the Zola wiki
  root.hcl                 # per-workload Terragrunt root (ADR-0130)
  secrets.enc              # per-workload sops/age-encrypted secrets (ADR-0131)
  terraform/
    project/               # dedicated Scaleway project
    state/
      bucket/                # dedicated Terraform state bucket (resolves to the shared root)
      iam/                   # dedicated deployer IAM application/policy/API key (resolves to the shared root)
    wiki/
      bucket/                # the pigeon.dev Scaleway object-bucket (website-hosting, public-read)
      iam/                   # deploy-scoped IAM for the GitHub Actions sync workflow
      dns/                   # Cloudflare apex/www CNAMEs + www redirect ruleset (ADR-0130)
    fastmail/
      dns/                   # Fastmail SPF/DKIM/MX records
bucket/
  terraform/
    noisypigeon/
      backblaze/
        import/              # Backblaze import bucket (ADR-0097, regrouped here by ADR-0116/0117)
      email/
        import/               # email import bucket (ADR-0097, regrouped here by ADR-0116/0117)
      macbook-scratch/
        deduplication/        # dedup job: compute + volume + bucket (ADR-0097, regrouped here by ADR-0116/0117)
      media/
        deduplication/        # dedup job bucket (ADR-0116, regrouped here by ADR-0117)
      poisoned/
        computer-snapshots/
          import/              # import bucket (ADR-0116, regrouped here by ADR-0117)
          deduplication/       # dedup job bucket (ADR-0116, regrouped here by ADR-0117)
        mega-storage-consolidation/
          import/              # import bucket (ADR-0116, regrouped here by ADR-0117)
          deduplication/       # dedup job: compute + volume + bucket + IAM -- the only leaf in this tree with real compute (ADR-0116, regrouped here by ADR-0117)
        t7-backup/
          import/              # import bucket (ADR-0116, regrouped here by ADR-0117)
          deduplication/       # dedup job bucket (ADR-0116, regrouped here by ADR-0117)
scaleway/
  terraform/
    custodian/
      duck-jellyfish/        # nl-ams backup bucket + IAM (ADR-0098, moved here by ADR-0106) -- see workload_definition.hcl below
management/
  terraform/
    scaleway/                # the deployer IAM application, Terraform state bucket, and Scaleway project/SSH key (ADR-0094, regrouped under scaleway/ by ADR-0106, promoted to its own workload by ADR-0124)
    cloudflare/              # every Cloudflare-managed DNS leaf not owned by a self-sufficient workload, grouped by domain (ADR-0105, moved here by ADR-0127)
      willowgraysen.com/
        redirect/  # redirects willowgraysen.com (apex + www) to noisypigeon.com
pigeon-cli/
  terraform/
    job/                     # the pigeon-cli compute-instance job leaf (ADR-0097, ADR-0118/0120/0122)
    shared/
      cockpit/                # shared Cockpit metrics/logs source + push token for every pigeon-cli compute instance (ADR-0103, regrouped under scaleway/ by ADR-0115, moved here by ADR-0124)
      iam-application/        # shared IAM application every pigeon-cli job policy attaches to (ADR-0119, moved here by ADR-0124)
```

Not every workload has a `src/` sibling — `scaleway/`, `management/`, and `bucket/` are all infrastructure-only: `scaleway/` groups every Scaleway-specific leaf not already owned by a more specific workload — today just a cross-region backup bucket (`custodian/duck-jellyfish/`, formerly the separate `custodian-buckets/` workload until ADR-0106 folded it in); `management/` is this repo's own bootstrap plumbing, promoted out of `scaleway/` to its own top-level workload by ADR-0124 — the `terraform/scaleway/` segment deliberately left room for a future non-Scaleway management leaf without a second move, exercised by ADR-0127's `terraform/cloudflare/` sibling (every Cloudflare-managed DNS leaf, grouped by domain — formerly the separate `dns/` workload, ADR-0105, until ADR-0127 folded it in here and decommissioned `dns/` entirely); `bucket/` groups storage-bucket infrastructure by dataset, independent of which job/CLI consumes it: each dataset under `bucket/terraform/noisypigeon/` collocates its `import/` and/or `deduplication/` leaf (originally grouped by consumer under `pigeon-cli/`, ADR-0097, then by purpose under `workloads/bucket/terraform/pigeon-cli/`, ADR-0116, now by dataset here, ADR-0117) — none is a deployable app in this repo, so all three are `terraform/` alone. `pigeon-cli/` has no `src/` either (the CLI itself split out via ADR-0084) but isn't infrastructure-only in the same provider-rooted sense: its `job/` leaf and `shared/` leaves (the Cockpit source and IAM application every job policy attaches to) are colocated by owning workload rather than grouped under `scaleway/`, following ADR-0124. `pigeon.dev/` and `noisypigeon.com/` are the two exceptions to the shared `management/`/`scaleway/` bootstrap: each has its own dedicated Terraform state bucket, deployer IAM, Scaleway project, `root.hcl`, and `secrets.enc` — see "Self-sufficient workloads" below — the convention doesn't require any particular sibling, a workload just has whichever ones it actually needs.

### Self-sufficient workloads: `root.hcl` + `secrets.enc`

`pigeon.dev` (ADR-0130/0131) and `noisypigeon.com` (ADR-0132) each opt out of the shared bootstrap entirely: a `workloads/<name>/root.hcl` (same shape as the shared `workloads/root.hcl`, just scoped to that workload's own `secrets.enc`) and a `workloads/<name>/secrets.enc` (sops/age-encrypted, same age recipient as the shared root `.env.enc`, decrypted independently — never merged with it). Once `root.hcl` exists, every leaf under `terraform/**` resolves to it instead of the shared root — except the workload's own `terraform/state/{bucket,iam}` leaves, which deliberately keep an **explicit** `include { path = "${get_repo_root()}/workloads/root.hcl" }` (not `find_in_parent_folders`) so they stay pinned to the shared bootstrap forever, avoiding the circular dependency of a backend that would otherwise point at the bucket it's responsible for creating. Any other workload can adopt this same pattern by following either one as a template.

### Per-leaf overrides: `scaleway_config.hcl`

Every leaf defaults to Scaleway's `fr-par` region/zone. A leaf needing something different — so far, only `scaleway/terraform/custodian/duck-jellyfish`, which lives in `nl-ams` — drops a `scaleway_config.hcl` file directly in its own directory, next to its `terragrunt.hcl`:

```hcl
locals {
  scaleway_region = "nl-ams"
  scaleway_zone   = "nl-ams-1"
}
```

`workloads/root.hcl` reads this file (if present) via Terragrunt's `read_terragrunt_config`, which returns a given default untouched when the file doesn't exist — every other leaf is entirely unaffected. See [ADR-0098](../docs/adr/0098-decommission-terraform-infrastructure.md) for the full mechanism and why it's built on `find_in_parent_folders`/`path_relative_to_include` rather than `get_terragrunt_dir()`. The pattern isn't specific to region/zone — a future leaf needing some other per-leaf override can extend the same file and have `workloads/root.hcl` read additional keys from it the same way.

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
relative to `root.hcl` doesn't start with `<name>/terraform` gets
`exclude`d from `terragrunt run --all` — so a workload's `src/` (or any
other non-terraform subdirectory) is never accidentally swept into a
plan/apply, even if a `terragrunt.hcl` is mistakenly added there. A leaf
can nest arbitrarily deep under `<name>/terraform/` (e.g.
`noisypigeon.com/terraform/proton/dns/`) — widened from "exactly
`<name>/terraform`" by
[ADR-0096](../docs/adr/0096-move-fastmail-leaves-to-workloads-email-terraform.md)
to let a workload split into multiple leaves (one per domain or
sub-service) without colliding on resource addresses.

Secrets come from a sops/age-encrypted `.env.enc` (committed, never
plaintext) at the true repo root, decrypted in-memory via
`find_in_parent_folders(".env.enc", "")` — a real shell environment
variable always overrides the decrypted file's value for the same key.
Run `mise run secrets-edit` to edit it. See
[ADR-0123](../docs/adr/0123-sops-encrypted-root-env.md). A self-sufficient
workload (see above) instead reads its own `secrets.enc`, same mechanism,
never falling back to the shared file
([ADR-0131](../docs/adr/0131-workload-specific-secrets.md)).
`workloads/root.hcl` only wires what's actually needed (Cloudflare for
the `management/terraform/cloudflare/` DNS leaves, Scaleway for
everything else, added by
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
