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

Terraform modules and the Zola theme live in their own repo,
[`noisypigeon/pigeon.dev`](https://github.com/noisypigeon/pigeon.dev), since
ADR-0154 — along with their release automation and PR discipline. Changing a
module is a PR there; bumping the version a leaf here pins is a separate PR
here.

## License

Licensed under the GNU General Public License v3.0 or later — see [`LICENSE.md`](LICENSE.md).
