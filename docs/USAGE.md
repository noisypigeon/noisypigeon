# noisypigeon

Personal infrastructure: a set of versioned, reusable Terraform modules,
the live Terragrunt/Terraform configuration that consumes them, and the
Zola-based static site for [noisypigeon.com](https://noisypigeon.com).

`service/pigeon-cli` (the `pigeon` Rust CLI) split out of this repo into
its own, `noisypigeon/pigeon-cli`, via ADR-0084 — its pre-split, pigeon-cli-
only ADR and report history was deleted from this repo once no longer
needed here (surviving terraform/blog ADRs live flat in `docs/adr/`; the
full pigeon-cli history survives in `noisypigeon/pigeon-cli`).

## Structure

- [`templates/terraform/`](templates/terraform/) — versioned Scaleway Terraform modules. See
  [`templates/terraform/README.md`](templates/terraform/README.md) for the module index.
- [`workloads/`](workloads/) — each workload gets its own
  `workloads/<name>/` (terraform colocated with the resource it's part
  of, not provider-rooted). See [`workloads/README.md`](workloads/README.md).
  - [`workloads/blog/src/`](workloads/blog/src/) — the Zola site for
    [noisypigeon.com](https://noisypigeon.com).
  - [`workloads/dns/terraform/`](workloads/dns/terraform/) — every
    Cloudflare-managed DNS leaf, grouped by domain: Fastmail SPF/DKIM/MX
    records and a Bluesky domain-handle verification TXT record for
    `noisypigeon.com`, the GitHub Pages CNAME records for
    `noisypigeon.com` (pointing it at the blog), Fastmail records for
    `pigeon.dev`, and a `pigeon.dev` → `noisypigeon.com` redirect.
  - [`workloads/pigeon-cli/terraform/`](workloads/pigeon-cli/terraform/) —
    infrastructure backing the external `pigeon` CLI's jobs
    (`noisypigeon/pigeon-cli`): import buckets plus a deduplication
    compute job.
  - [`workloads/scaleway/terraform/`](workloads/scaleway/terraform/) —
    every Scaleway-specific leaf: `management/` (this repo's own
    Terraform state bucket and deployer IAM application/policy/API key)
    and `custodian/duck-jellyfish/` (an `nl-ams` cross-region backup
    bucket).
- [`docs/adr/`](docs/adr/) — architecture decision records governing
  terraform/blog changes in this repo, including every surviving pre-split
  ADR (renumbered inline, not archived separately).

## Getting started

This repo uses [mise](https://mise.jdx.dev/) as the entry point for
Terraform/Terragrunt and the blog:

```sh
mise run fmt-terraform         # terragrunt hcl format + terraform fmt
mise run fmt-check-terraform   # check formatting
mise run plan                  # terragrunt run --all -- plan
mise run apply                 # terragrunt run --all -- apply
mise run blog-build            # zola build (workloads/blog/src)
mise run blog-serve            # zola serve (workloads/blog/src)
```

Terraform module changes follow their own PR discipline — see the
`release-pr` Claude Code skill and `templates/terraform/README.md`.

## License

Licensed under the GNU General Public License v3.0 or later — see [`LICENSE.md`](LICENSE.md).
