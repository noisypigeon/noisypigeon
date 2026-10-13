# CLAUDE.md

## Project layout

Each workload gets its own top-level directory, `<name>/`: `src/` for its content, `terraform/` for the infrastructure it's part of, colocated rather than provider-rooted. The shared `root.hcl` enforces that convention and resolves each leaf's Scaleway region/zone (default `fr-par`/`fr-par-1`; a leaf overrides it by dropping a `scaleway_config.hcl` beside its `terragrunt.hcl` — a mechanism that currently has no users).

Three domains are fully Terraform-self-sufficient (own Scaleway project, state bucket, deployer IAM, `root.hcl`/`secrets.enc`): `pigeon.dev`, `noisypigeon.com`, and `willowgraysen.com`. `willowgraysen.com` additionally hosts this repo's original shared bootstrap (`project` resource) and every `pigeon-cli` job/bucket/shared leaf, under `willowgraysen.com/terraform/pigeon-cli/{bucket,shared,job}/`. The pre-ADR-0133 shared state bucket and deployer IAM stay alive, deliberately unmanaged — `pigeon.dev`'s and `noisypigeon.com`'s own `state/iam` leaves still depend on it.

Versioned, reusable Terraform modules and the Zola `zola-site` theme no longer live in this repo — they moved to `noisypigeon/pigeon.dev` (ADR-0154). This repo only pins versions in `**/*.tf` `source =` lines; the modules/theme themselves, their release tooling, and the `release-pr` skill live and get edited in that repo. Import URLs are unaffected by the move and still resolve from `pigeon.dev`: `pigeon.dev/modules/<provider>/<module>/vX.Y.Z` and `pigeon.dev/templates/zola-site/vX.Y.Z`.

Both Zola sites — `noisypigeon.com` and `pigeon.dev` — have moved to their own repos: `noisypigeon/noisypigeon.com` (ADR-0159) and `noisypigeon/pigeon.dev` respectively. This repo no longer builds or serves them. Their content tracks the theme on live `"main"` by default, pinnable via `[extra].theme_version`; `resolve-theme.sh` materializes `themes/<name>` directly from the remote clone (nothing committed locally).

`.github/workflows/` here are thin callers: each keeps its trigger (`on:`), permissions, and any authorization gate (e.g. `terragrunt-apply`'s comment-author check), but the job body is a `workflow_call` into a reusable workflow hosted in `noisypigeon/pigeon.dev`, pinned `@main`.

## Gotchas

- **Legacy `modules/*` tags still live here, not in `pigeon.dev`.** 20 tags predate `templates/` existing in this repo and couldn't be carried over when `templates/` was hoisted out; the redirect generator maps `modules` → this repo and `templates/terraform`/`templates/zola-site` → `pigeon.dev` (frozen, won't grow). (ADR-0154)
- **Terraform module/theme development happens in `noisypigeon/pigeon.dev`, not here.** A module or theme change is a PR there; bumping the version a leaf here pins is a separate PR here, landable only once that release's deploy has finished. (ADR-0154)
- **`pigeon-cli` (the Rust CLI) lives in `noisypigeon/pigeon-cli`.** This repo only has its job/bucket/shared Terraform leaves, not its source. (`pigeon-cli`'s own ADR-0084 — *not* this corpus's ADR-0084, which is an unrelated record about `compute-instance` cloud-init; the number was reused after the split ADR was deleted here.)
- **CI job bodies live in `noisypigeon/pigeon.dev`, not here.** `terragrunt-plan`/`apply` and `interaction-limits-renew` are thin wrappers calling reusable workflows there; their content-publishing counterparts (`blog-changelog`, `zola-site-deploy`) live with the content in their own repos — debugging CI behavior usually means reading the relevant repo. (ADR-0155, ADR-0159)
- **This repo is the only live Terragrunt tree.** Each workload is its own top-level directory (`noisypigeon.com/`, `pigeon.dev/`, `willowgraysen.com/`) rather than nested under a `workloads/` wrapper; there is no `terraform/infrastructure/` or separate top-level `modules/`/`templates/` anymore.
- ADRs are numbered continuously and never renumbered or archived across repo splits — only the pigeon-cli-specific ADRs (0001-0030) were ever removed, because that code moved out entirely. Numbers are not globally unique: 0084 was reused after a deletion, and 0136/0138 are each used twice from parallel branches.

## Design docs

**`docs/ARCHITECTURE.md`** is the longform companion to this file: current-state
design rationale for the layout, state/secrets model, module-consumption
contract, Zola/theme pipeline, CI gates, and `pigeon-cluster`. Read it when you
need the *why* behind something summarized here, or before changing any of it.
Like this file, it documents the present and is edited in place when the tree
changes — it is not a history.

The ADRs themselves are **not in this repo** — they live in
[`noisypigeon/pigeon.dev`](https://github.com/noisypigeon/pigeon.dev/tree/main/adr/infrastructure)
under `adr/infrastructure/`, numbered chronologically from 0031, one file per
decision (ADR-0157). Before making architectural or interface changes, read
them; `mise run adr-fetch` puts a clone at `.adr-src` so you can grep them
locally. If a change would contradict an existing ADR, flag it rather than
silently diverging: write a new one with `mise run adr-new`, or update the old
one's `Status` to `Superseded by ADR-NNNN` — or `superseded in part by`, where
only one section is overturned.

## Dev cycle

Terraform modules and the `zola-site` theme live in `noisypigeon/pigeon.dev` (ADR-0154), with their own PR discipline, `release:*` label vocabulary, release automation, and the `release-pr` skill. Changing a module is a PR there; bumping the version a `**/*.tf` leaf here pins is a separate PR here, landable only once that release's deploy has finished (the short URL has to resolve before `terragrunt init` can fetch it). There is no crate-style `mise run ci` gate in this repo — that was `service/pigeon-cli`-specific and now lives with it in `noisypigeon/pigeon-cli`.

When an ADR's `## Out of scope` section has a genuinely-deferred item (not a permanent design boundary), file it via `mise run adr-issue` while landing that ADR — reuse an existing `out-of-scope`-labeled issue with `--issue N` if the same gap was already raised elsewhere. Issues are filed against this repo even though the ADR text is not here. See `adr/infrastructure/0031-out-of-scope-issue-tracking.md` in `pigeon.dev`.

## Commands

- `mise run fmt-terraform` / `mise run fmt-check-terraform` — format / check formatting for Terraform and Terragrunt files.
- `mise run plan` / `mise run apply` — `terragrunt run --all -- plan`/`apply` across the whole repo.
- `mise run secrets-edit` — edit the root `.env.enc` via `sops`.
- `mise run adr-issue -- <args>` — file (or reuse) a GitHub issue for an ADR's Out of scope bullet and link it back into the ADR.
