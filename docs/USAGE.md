# noisypigeon

Personal infrastructure: a set of versioned, reusable Terraform modules,
the live Terragrunt/Terraform configuration that consumes them, and the
Zola-based static site for [noisypigeon.com](https://noisypigeon.com).

`service/pigeon-cli` (the `pigeon` Rust CLI) split out of this repo into
its own, `noisypigeon/pigeon-cli`, via ADR-0084 — this repo's
`docs/archived/adr/` and `docs/archived/reports/` hold its pre-split ADR
and report history for reference.

## Structure

- [`terraform/modules/`](terraform/modules/) — versioned DigitalOcean and
  Scaleway Terraform modules. See
  [`terraform/modules/README.md`](terraform/modules/README.md) for the
  module index.
- [`terraform/infrastructure/`](terraform/infrastructure/) — this repo
  owner's live Terragrunt/Terraform configuration for personal
  infrastructure, consuming the modules above. See
  [`terraform/infrastructure/README.md`](terraform/infrastructure/README.md).
- [`service/blog/`](service/blog/) — the Zola site for
  [noisypigeon.com](https://noisypigeon.com).
- [`docs/adr/`](docs/adr/) — architecture decision records governing
  terraform/blog changes in this repo going forward.
- [`docs/archived/adr/`](docs/archived/adr/) /
  [`docs/archived/reports/`](docs/archived/reports/) — the full ADR and
  report history from before `service/pigeon-cli` split out (ADR-0084),
  kept for reference.

## Getting started

This repo uses [mise](https://mise.jdx.dev/) as the entry point for
Terraform/Terragrunt and the blog:

```sh
mise run fmt-terraform         # terragrunt hcl format + terraform fmt
mise run fmt-check-terraform   # check formatting
mise run plan                  # terragrunt run --all -- plan
mise run apply                 # terragrunt run --all -- apply
mise run blog-build            # zola build (service/blog)
mise run blog-serve            # zola serve (service/blog)
```

Terraform module changes follow their own PR discipline — see the
`release-pr` Claude Code skill and `terraform/modules/README.md`.

## License

Licensed under the GNU General Public License v3.0 or later — see [`LICENSE.md`](LICENSE.md).
