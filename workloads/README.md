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
blog/
  src/  # the Zola site (ADR-0091)
dns/
  terraform/
    noisypigeon.com/
      fastmail/  # Fastmail SPF/DKIM/MX records for noisypigeon.com (ADR-0105)
      bluesky/   # AT Protocol domain-handle verification TXT record (ADR-0105)
      blog/      # the Cloudflare DNS records that point noisypigeon.com at GitHub Pages (ADR-0092, moved here by ADR-0105)
    pigeon.dev/
      fastmail/  # Fastmail SPF/DKIM/MX records for pigeon.dev (ADR-0105)
      redirect/  # redirects pigeon.dev (apex + www) to noisypigeon.com (ADR-0105)
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
    management/              # the deployer IAM application, Terraform state bucket, and Scaleway project/SSH key (ADR-0094, regrouped here by ADR-0106)
    custodian/
      duck-jellyfish/        # nl-ams backup bucket + IAM (ADR-0098, moved here by ADR-0106) -- see workload_definition.hcl below
    pigeon-cli/
      cockpit/               # shared Scaleway Cockpit metrics/logs source + push token for every pigeon-cli compute instance (ADR-0103, moved here by ADR-0115)
```

Not every workload has a `src/` sibling — `scaleway/`, `bucket/`, and `dns/` are all infrastructure-only: `scaleway/` groups every Scaleway-specific leaf — its own bootstrap plumbing (`management/`: the deployer identity and remote-state bucket), a cross-region backup bucket (`custodian/duck-jellyfish/`, formerly the separate `custodian-buckets/` workload until ADR-0106 folded it in), and the shared Cockpit observability leaf for `pigeon-cli` compute instances (`pigeon-cli/cockpit/`, ADR-0115) — `bucket/` groups storage-bucket infrastructure by dataset, independent of which job/CLI consumes it: each dataset under `bucket/terraform/noisypigeon/` collocates its `import/` and/or `deduplication/` leaf (originally grouped by consumer under `pigeon-cli/`, ADR-0097, then by purpose under `workloads/bucket/terraform/pigeon-cli/`, ADR-0116, now by dataset here, ADR-0117) — and `dns/` groups every Cloudflare-managed DNS leaf by domain (ADR-0105) — none is a deployable app in this repo, so all three are `terraform/` alone. Conversely, `blog/` is now `src/`-only (ADR-0105 moved its `terraform/` leaf into `dns/`) — the convention doesn't require either sibling, a workload just has whichever ones it actually needs.

### Per-leaf overrides: `workload_definition.hcl`

Every leaf defaults to Scaleway's `fr-par` region/zone. A leaf needing something different — so far, only `scaleway/terraform/custodian/duck-jellyfish`, which lives in `nl-ams` — drops a `workload_definition.hcl` file directly in its own directory, next to its `terragrunt.hcl`:

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
`dns/terraform/noisypigeon.com/fastmail/`) — widened from "exactly
`<name>/terraform`" by
[ADR-0096](../docs/adr/0096-move-fastmail-leaves-to-workloads-email-terraform.md)
to let a workload split into multiple leaves (one per domain, here)
without colliding on resource addresses.

Secrets come from a single `.env` (git-ignored, never committed) at the
true repo root, read via `find_in_parent_folders(".env", "")` — a real
shell environment variable always overrides the `.env` file value for the
same key. Copy `.env.example` to `.env` and fill in real values to get
started. `workloads/root.hcl` only wires what's actually needed (Cloudflare
for the `dns/` DNS leaves, Scaleway for everything else, added by
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
