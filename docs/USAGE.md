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

- [`workloads/`](workloads/) — each workload gets its own
  `workloads/<name>/` (terraform colocated with the resource it's part
  of, not provider-rooted). See [`workloads/README.md`](workloads/README.md).
  - [`workloads/noisypigeon.com/`](workloads/noisypigeon.com/) — the
    Zola site for [noisypigeon.com](https://noisypigeon.com) (`src/`),
    served from a Scaleway Object Storage bucket behind Cloudflare, plus
    its own dedicated Scaleway project, state bucket, deployer IAM, and
    Cloudflare DNS leaves (ADR-0132).
  - [`workloads/pigeon.dev/`](workloads/pigeon.dev/) — the Zola wiki for
    `pigeon.dev`, with the same dedicated self-sufficiency pattern
    (ADR-0130/0131).
  - [`workloads/willowgraysen.com/`](workloads/willowgraysen.com/) — the
    third self-sufficient workload (ADR-0133); infrastructure-only, and
    the home for everything not claimed by a more specific workload: the
    repo's own Terraform state bucket, deployer IAM, and Scaleway project
    (`state/`, `project/`), a Cloudflare redirect from `willowgraysen.com`
    to `noisypigeon.com` (`redirect/`), an `nl-ams` cross-region backup
    bucket (`custodial-storage/duck-jellyfish/`), and the external
    `pigeon` CLI's (`noisypigeon/pigeon-cli`) storage buckets, shared
    Cockpit/IAM-application resources, and compute-instance job leaves
    (`pigeon-cli/{bucket,shared,job}/`).
- [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) — longform current-state design
  rationale: layout, Terragrunt roots/state/providers, secrets, the module
  consumption contract, the Zola/theme pipeline, CI, and `pigeon-cluster`.
  Start here for the *why* behind anything below.

## Getting started

This repo uses [mise](https://mise.jdx.dev/) as the entry point for
Terraform/Terragrunt and the blog:

```sh
mise run fmt-terraform         # terragrunt hcl format + terraform fmt
mise run fmt-check-terraform   # check formatting
mise run plan                  # terragrunt run --all -- plan
mise run apply                 # terragrunt run --all -- apply
mise run blog-build            # zola build (workloads/noisypigeon.com/src)
mise run blog-serve            # zola serve (workloads/noisypigeon.com/src)
mise run pigeon-dev-build      # zola build (workloads/pigeon.dev/src)
mise run pigeon-dev-serve      # zola serve (workloads/pigeon.dev/src)
mise run secrets-edit          # edit the root .env.enc via sops
mise run adr-fetch             # clone/refresh pigeon.dev's ADRs at .adr-src
mise run adr-new -- --title …  # scaffold a new ADR in pigeon.dev
```

Terraform modules and the Zola theme live in their own repo,
[`noisypigeon/pigeon.dev`](https://github.com/noisypigeon/pigeon.dev), since
ADR-0154 — along with their release automation and PR discipline. Changing a
module is a PR there; bumping the version a leaf here pins is a separate PR
here.

## License

Licensed under the GNU General Public License v3.0 or later — see [`LICENSE.md`](LICENSE.md).
