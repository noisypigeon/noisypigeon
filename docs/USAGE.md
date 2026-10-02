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

- [`modules/`](modules/) — versioned Scaleway Terraform modules. See
  [`modules/README.md`](modules/README.md) for the module index.
- [`terraform/infrastructure/`](terraform/infrastructure/) — this repo
  owner's live Terragrunt/Terraform configuration for personal
  infrastructure, consuming the modules above. See
  [`terraform/infrastructure/README.md`](terraform/infrastructure/README.md).
- [`workloads/`](workloads/) — each workload gets its own
  `workloads/<name>/` (terraform colocated with the resource it's part
  of, not provider-rooted). See [`workloads/README.md`](workloads/README.md).
  - [`workloads/blog/src/`](workloads/blog/src/) — the Zola site for
    [noisypigeon.com](https://noisypigeon.com).
  - [`workloads/blog/terraform/`](workloads/blog/terraform/) — the
    Cloudflare DNS records pointing `noisypigeon.com` at GitHub Pages.
  - [`workloads/email/terraform/fastmail/`](workloads/email/terraform/fastmail/) —
    Fastmail SPF/DKIM/MX Cloudflare DNS records, one leaf per domain
    (`noisypigeon.com`, `pigeon.dev`).
  - [`workloads/scaleway/terraform/`](workloads/scaleway/terraform/) —
    this repo's own Terraform state bucket and deployer IAM
    application/policy/API key.
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
`release-pr` Claude Code skill and `modules/README.md`.

## License

Licensed under the GNU General Public License v3.0 or later — see [`LICENSE.md`](LICENSE.md).
