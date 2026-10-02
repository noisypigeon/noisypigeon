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

- [`terraform/modules/`](terraform/modules/) — versioned Scaleway
  Terraform modules. See
  [`terraform/modules/README.md`](terraform/modules/README.md) for the
  module index.
- [`terraform/infrastructure/`](terraform/infrastructure/) — this repo
  owner's live Terragrunt/Terraform configuration for personal
  infrastructure, consuming the modules above. See
  [`terraform/infrastructure/README.md`](terraform/infrastructure/README.md).
- [`workloads/blog/src/`](workloads/blog/src/) — the Zola site for
  [noisypigeon.com](https://noisypigeon.com).
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
`release-pr` Claude Code skill and `terraform/modules/README.md`.

## License

Licensed under the GNU General Public License v3.0 or later — see [`LICENSE.md`](LICENSE.md).
