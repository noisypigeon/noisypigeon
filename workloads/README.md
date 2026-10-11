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
willowgraysen.com/
  root.hcl                 # per-workload Terragrunt root (ADR-0133)
  secrets.enc              # per-workload sops/age-encrypted secrets (ADR-0131)
  terraform/
    project/               # Scaleway project (relocated from the former shared bootstrap, ADR-0133)
    state/
      bucket/                # dedicated Terraform state bucket (self-governing, ADR-0133)
      iam/                   # dedicated deployer IAM application/policy/API key (resolves to the shared root)
    redirect/
      dns/                   # Cloudflare ruleset redirecting willowgraysen.com (apex + www) to noisypigeon.com
    custodial-storage/
      duck-jellyfish/        # nl-ams backup bucket + IAM -- see scaleway_config.hcl below
    pigeon-cli/
      bucket/                # 11 leaves: per-dataset import/deduplication buckets (ADR-0097/0116/0117)
      shared/
        cockpit/               # shared Cockpit metrics/logs source + push token for every pigeon-cli compute instance (ADR-0103)
        grafana/               # Grafana dashboards-as-code against Cockpit, via a dedicated IAM-proxied credential (ADR-0135)
        iam-application/       # shared IAM application every pigeon-cli job policy attaches to (ADR-0119)
        reports/
          phase-deduplicate/     # shared job-report bucket
      job/
        import-backblaze/     # compute instance + block volume + scoped IAM key (ADR-0097, ADR-0118/0120/0122)
        import-macbook/       # empty placeholder -- its job content was retired before this move
```

Not every workload has a `src/` sibling — `willowgraysen.com/` is infrastructure-only, and not just the former shared bootstrap's own `project`/`state` leaves: it's also where every other Scaleway/Cloudflare leaf that was never claimed by a more specific self-sufficient workload ended up, by ADR-0133 — a cross-region backup bucket (`custodial-storage/duck-jellyfish/`, formerly the separate `custodial-storage/` workload), a Cloudflare redirect leaf, and all of `pigeon-cli/`'s bucket/shared/job leaves (`pigeon-cli/` itself has no `src/` either, the CLI having split out via ADR-0084). `pigeon.dev/` and `noisypigeon.com/` are the other two self-sufficient workloads: each has its own dedicated Terraform state bucket, deployer IAM, Scaleway project, `root.hcl`, and `secrets.enc` — see "Self-sufficient workloads" below — the convention doesn't require any particular sibling, a workload just has whichever ones it actually needs. With all three self-sufficient, the shared `workloads/root.hcl` no longer governs any leaf of its own — it's only still read by each workload's own `state/iam` leaf (and, for `pigeon.dev`'s still-unfixed `state/bucket`, that leaf too), via the explicit shared-root pin described below.

### Self-sufficient workloads: `root.hcl` + `secrets.enc`

`pigeon.dev` (ADR-0130/0131), `noisypigeon.com` (ADR-0132), and `willowgraysen.com` (ADR-0133) each opt out of the shared bootstrap entirely: a `workloads/<name>/root.hcl` (same shape as the shared `workloads/root.hcl`, just scoped to that workload's own `secrets.enc`) and a `workloads/<name>/secrets.enc` (sops/age-encrypted, same age recipient as the shared root `.env.enc`, decrypted independently — never merged with it). Once `root.hcl` exists, every leaf under `terraform/**` resolves to it instead of the shared root via plain `find_in_parent_folders("root.hcl")` — except `terraform/state/iam`, which deliberately keeps an **explicit** `include { path = "${get_repo_root()}/workloads/root.hcl" }` (not `find_in_parent_folders`) so it stays pinned to the shared bootstrap forever: it only ever manages IAM resources, authorized via ordinary org-level policy grants the shared deployer already has, so there's no reason to move it. `terraform/state/bucket` starts on the same explicit pin (needed only to avoid a circular backend dependency *before* its own dedicated bucket exists) but migrates to resolving via `find_in_parent_folders` like every other leaf, with a one-time state migration, once that bucket exists — storing its own state inside the bucket it manages from then on, the same self-referential pattern the shared, repo-wide bootstrap leaf already uses for itself. (`pigeon.dev`'s own `state/bucket` still has the old, unmigrated shared pin — a known, documented gap, ADR-0132.) Any other workload can adopt this same pattern by following either one as a template.

### Per-leaf overrides: `scaleway_config.hcl`

Every leaf defaults to Scaleway's `fr-par` region/zone. A leaf needing something different — so far, only `willowgraysen.com/terraform/custodial-storage/duck-jellyfish`, which lives in `nl-ams` — drops a `scaleway_config.hcl` file directly in its own directory, next to its `terragrunt.hcl`:

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
`workloads/root.hcl` wires Cloudflare and Scaleway (Scaleway added by
[ADR-0094](../docs/adr/0094-move-scaleway-bootstrap-leaf-to-workloads.md))
even though no leaf still resolves to it directly now that every workload
is self-sufficient (ADR-0133) — each workload's own `state/iam` leaf (and,
for `pigeon.dev`, its still-unfixed `state/bucket`) keeps the explicit
shared-root pin described above, so both providers stay live here; add
another provider when a future workload actually needs it, not
preemptively.

## Adding a new workload

1. `workloads/<name>/src/` (or whatever the workload's actual content is).
2. `workloads/<name>/terraform/` for its infrastructure, using the leaf
   shape above — `workloads/root.hcl` will pick it up automatically.
3. If the leaf needs a provider `workloads/root.hcl` doesn't wire yet,
   extend `workloads/root.hcl` at that point — see
   [ADR-0092](../docs/adr/0092-move-github-pages-leaf-to-workloads-blog-terraform.md)
   for the rationale behind keeping it minimal until then.
