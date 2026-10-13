# noisypigeon

Personal infrastructure: a set of versioned, reusable Terraform modules,
the live Terragrunt/Terraform configuration that consumes them, and the
Zola-based static site for [noisypigeon.com](https://noisypigeon.com).

`service/pigeon-cli` (the `pigeon` Rust CLI) split out of this repo into its
own, [`noisypigeon/pigeon-cli`](https://github.com/noisypigeon/pigeon-cli) —
see that repo's ADR-0084 (this corpus's ADR-0084 is an unrelated record; the
number was reused after the split ADR was deleted here). Its pre-split,
pigeon-cli-only ADR and report history went with it. The surviving
infrastructure ADRs now live in
[`noisypigeon/pigeon.dev`](https://github.com/noisypigeon/pigeon.dev/tree/main/adr/infrastructure)
under `adr/infrastructure/` (ADR-0157).

## Structure

Each workload gets its own top-level directory, `<name>/` — terraform
colocated with the resource it's part of, not provider-rooted. This is
this repo's only live Terraform/Terragrunt tree; the former provider-rooted
`terraform/infrastructure/` was fully decommissioned once its last leaves
moved here (ADR-0098).

- [`noisypigeon.com/`](noisypigeon.com/) — the Zola blog (`src/`), served
  via GitHub Pages (ADR-0158), plus its own dedicated Scaleway project,
  state bucket, deployer IAM, and Cloudflare DNS leaves (ADR-0132).
- [`pigeon.dev/`](pigeon.dev/) — infrastructure only; its Zola wiki moved
  into the `noisypigeon/pigeon.dev` repo itself and now serves via GitHub
  Pages from there (ADR-0156). Same dedicated self-sufficiency pattern as
  the other two domains (ADR-0130/0131).
- [`willowgraysen.com/`](willowgraysen.com/) — the third self-sufficient
  workload (ADR-0133); infrastructure-only, and the home for everything
  not claimed by a more specific workload: the repo's own Terraform state
  bucket, deployer IAM, and Scaleway project (`state/`, `project/`), a
  Cloudflare redirect from `willowgraysen.com` to `noisypigeon.com`
  (`redirect/`), three `nl-ams` cold-storage buckets (`cold/*`), and the
  external `pigeon` CLI's (`noisypigeon/pigeon-cli`) storage buckets,
  shared Cockpit/Grafana/IAM-application resources, and job fleet
  (`pigeon-cli/{bucket,shared,cluster}/`).
- [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) — longform current-state design
  rationale: layout, Terragrunt roots/state/providers, secrets, the module
  consumption contract, the Zola/theme pipeline, CI, and `pigeon-cluster`.
  Start here for the *why* behind anything below.

### Workload layout

```
noisypigeon.com/
  src/                     # the Zola blog (ADR-0091, moved here from blog/ by ADR-0132)
  fetch-templates.sh       # fetches the zola-site theme from pigeon.dev into .templates-src (ADR-0156)
  root.hcl                 # per-workload Terragrunt root (ADR-0130/0132)
  secrets.enc              # per-workload sops/age-encrypted secrets (ADR-0131)
  terraform/
    project/               # dedicated Scaleway project
    state/
      bucket/                # dedicated Terraform state bucket (self-governing)
      iam/                   # dedicated deployer IAM application/policy/API key (resolves to the shared root)
    blog/
      dns/                   # GitHub Pages apex/www CNAMEs, DNS-only (ADR-0158)
    bluesky/
      dns/                   # AT Protocol domain-handle verification TXT record
    proton/
      dns/                   # Proton Mail SPF/DKIM/MX/DMARC records
    google-search/
      dns/                   # Google site-verification TXT record
pigeon.dev/
  root.hcl                 # per-workload Terragrunt root (ADR-0130)
  secrets.enc              # per-workload sops/age-encrypted secrets (ADR-0131)
  terraform/
    project/               # dedicated Scaleway project
    state/
      bucket/                # dedicated Terraform state bucket (self-governing)
      iam/                   # dedicated deployer IAM application/policy/API key (resolves to the shared root)
    wiki/
      dns/                   # GitHub Pages apex/www CNAMEs, DNS-only (ADR-0156)
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
    cold/
      custodial-duck-jellyfish/  # nl-ams backup bucket + IAM -- see scaleway_config.hcl below
      deduplicated-misc/         # nl-ams archival bucket
      snapshot-2026-10-09/       # nl-ams archival bucket
    pigeon-cli/
      bucket/
        pigeon/
          deduplicate/           # per-dataset import/deduplication bucket
          transform/             # per-dataset transform bucket
      cluster/                 # the job fleet: one pigeon-cluster module call, configured
                                # by a `jobs` list in cluster_definition.tf -- adding a job is
                                # a list entry, not a new leaf (ADR-0144, ADR-0153)
      shared/
        cockpit/                 # shared Cockpit metrics/logs source + push token (ADR-0103)
        grafana/                 # Grafana dashboards-as-code against Cockpit (ADR-0135)
        iam-application/         # shared IAM application every job policy attaches to (ADR-0119)
        reports/
          phase-deduplicate/       # shared job-report bucket
          phase-transform/         # shared job-report bucket
```

Not every workload has a `src/` sibling — `willowgraysen.com/` is
infrastructure-only, and not just the former shared bootstrap's own
`project`/`state` leaves: it's also where every other Scaleway/Cloudflare
leaf that was never claimed by a more specific self-sufficient workload
ended up, by ADR-0133. `pigeon.dev/` and `noisypigeon.com/` are the other
two self-sufficient workloads: each has its own dedicated Terraform state
bucket, deployer IAM, Scaleway project, `root.hcl`, and `secrets.enc` (see
below) — the convention doesn't require any particular sibling, a workload
just has whichever ones it actually needs. With all three self-sufficient,
the shared `root.hcl` no longer governs any leaf of its own — it's only
still read by each workload's own `state/iam` leaf, via the explicit
shared-root pin described below.

## Workload conventions

### Terraform convention

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

The shared [`root.hcl`](../root.hcl) is what every leaf resolves to by
walking up, and enforces the `<name>/terraform/...` convention itself via
Terragrunt's `exclude` block — see `docs/ARCHITECTURE.md` §2 for the
mechanics.

### Self-sufficient workloads

`pigeon.dev` (ADR-0130/0131), `noisypigeon.com` (ADR-0132), and
`willowgraysen.com` (ADR-0133) each opt out of the shared bootstrap
entirely: their own `<name>/root.hcl` and `<name>/secrets.enc`
(sops/age-encrypted, decrypted independently, never merged with the root
`.env.enc`). Every leaf under `terraform/**` then resolves to its own
domain root via plain `find_in_parent_folders("root.hcl")` — except
`terraform/state/iam`, which deliberately keeps an **explicit**
`include { path = "${get_repo_root()}/root.hcl" }` (not
`find_in_parent_folders`), pinned to the shared bootstrap forever since it
only manages IAM resources authorized via org-level grants the shared
deployer already has. Full rationale and the one-time state-migration
runbook for adopting this pattern: `docs/ARCHITECTURE.md` §1-2.

### Per-leaf overrides

Two opt-in files, both resolved via Terragrunt's `read_terragrunt_config`
with a default, so a leaf that omits either is unaffected:
`scaleway_config.hcl` (region/zone, e.g. `willowgraysen.com/terraform/cold/custodial-duck-jellyfish`'s
`nl-ams` override) and `backblaze_config.hcl` (opts into the `b2`
provider). See `docs/ARCHITECTURE.md` §2 "Per-leaf overrides" for both.

### Adding a new workload

1. `<name>/src/` (or whatever the workload's actual content is).
2. `<name>/terraform/` for its infrastructure, using the leaf shape above
   — the shared `root.hcl` will pick it up automatically.
3. If the leaf needs a provider the shared `root.hcl` doesn't wire yet,
   extend it at that point — see
   [ADR-0092](https://github.com/noisypigeon/pigeon.dev/blob/main/adr/infrastructure/0092-move-github-pages-leaf-to-workloads-blog-terraform.md)
   for the rationale behind keeping it minimal until then.

## Getting started

This repo uses [mise](https://mise.jdx.dev/) as the entry point for
Terraform/Terragrunt and the blog:

```sh
mise run fmt-terraform         # terragrunt hcl format + terraform fmt
mise run fmt-check-terraform   # check formatting
mise run plan                  # terragrunt run --all -- plan
mise run apply                 # terragrunt run --all -- apply
mise run blog-build            # zola build (noisypigeon.com/src)
mise run blog-serve            # zola serve (noisypigeon.com/src)
mise run secrets-edit          # edit the root .env.enc via sops
mise run adr-fetch             # clone/refresh pigeon.dev's ADRs at .adr-src
mise run adr-new -- --title …  # scaffold a new ADR in pigeon.dev
```

Terraform modules and the Zola theme live in their own repo,
[`noisypigeon/pigeon.dev`](https://github.com/noisypigeon/pigeon.dev), since
ADR-0154 — along with their release automation and PR discipline. Changing a
module is a PR there; bumping the version a leaf here pins is a separate PR
here. `pigeon.dev`'s own site is built and served from that same repo now
too (ADR-0156) — there's no local build/serve task for it here any more.

## License

Licensed under the GNU General Public License v3.0 or later — see [`LICENSE.md`](LICENSE.md).
