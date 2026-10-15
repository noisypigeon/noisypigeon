# Architecture

Longform design rationale for this repo, as it is **today**. `CLAUDE.md` is the
short orientation; this is the detail behind it.

The decision records that produced these designs live in
[`noisypigeon/pigeon.dev`](https://github.com/noisypigeon/pigeon.dev) under
`adr/infrastructure/` (ADR-0157). `ADR-NNNN` citations below are pointers into
that corpus. This document is not a history: when something here changes, the
text is edited in place rather than appended to, the same rule ADR-0156 set for
`CLAUDE.md`.

## 1. Scope and layout

This repo holds its workloads at the top level and nothing else operational.
Each one is its own live Terragrunt/Terraform tree.

Each workload is its own top-level `<name>/` directory, with `src/` for content and `terraform/`
for the infrastructure it is part of. Terraform is colocated with the thing it
serves rather than grouped by provider — the convention ADR-0092 introduced and
ADR-0096 widened to any depth under `<name>/terraform/`. A provider-rooted tree
(`terraform/infrastructure/`) existed until ADR-0098 decommissioned it.

Three workloads exist, one per domain:

| Workload | `src/` | What its `terraform/` owns |
|---|---|---|
| `noisypigeon.com` | — (its site and Terraform moved to `noisypigeon/noisypigeon.com`, ADR-0159/COM-0003) | `state/iam` only |
| `pigeon.dev` | — (its site and Terraform moved to `noisypigeon/pigeon.dev`, DEV-0162/0163) | `state/iam` only |
| `willowgraysen.com` | — (infrastructure only) | `redirect/dns`, `cold/*`, `pigeon-cli/*`, `project`, `state/{bucket,iam}` |

`willowgraysen.com` is the catch-all: it holds what no more specific domain
claims. That includes this repo's original shared bootstrap (ADR-0133 relocated
the `project` resource there unchanged), the `cold/` archival buckets, and all
`pigeon-cli` infrastructure.

### Why per-domain rather than per-provider

Each domain owns its own Scaleway project, state bucket, deployer IAM, and
`root.hcl`. ADR-0130 established this for `pigeon.dev`, ADR-0132 followed for
`noisypigeon.com`, ADR-0133 for `willowgraysen.com`. The point is blast radius:
a credential or state problem in one domain cannot reach another, and each
domain's `terragrunt` invocations authenticate as an identity scoped to it.

One deliberate loose end: the pre-ADR-0133 shared state bucket and deployer IAM
are **still alive on Scaleway and deliberately unmanaged**. `pigeon.dev`'s and
`noisypigeon.com`'s own `state/iam` leaves still depend on them. Do not delete
them on the assumption that ADR-0133 replaced them; it replaced only
`willowgraysen.com`'s use of them.

## 2. Terragrunt roots, state, and provider generation

There are four `root.hcl` files: one shared at the repo root, and one per
domain at `<domain>/root.hcl`. A leaf's `terragrunt.hcl` includes the
nearest one.

### The leaf-validity guard

The shared `root.hcl` enforces the directory convention through Terragrunt's
`exclude` block rather than documentation:

```hcl
path_segments = split("/", path_relative_to_include())
is_valid_leaf = length(local.path_segments) >= 2 && local.path_segments[1] == "terraform"
```

Anything not under `<name>/terraform/` is excluded from `run --all`. The older
top-level `skip` attribute is deprecated in Terragrunt 1.x; `exclude` replaced
it and works from an included `root.hcl` (ADR-0092, ADR-0096).

### State keys

State lives in Scaleway Object Storage over the S3-compatible API, always in
`fr-par` regardless of a leaf's own region (ADR-0062, ADR-0098). The key is
derived purely from path, which is why moving a leaf is a state migration and
never a resource change:

- shared root: `workloads/${path_relative_to_include()}/terraform.tfstate`
- per-domain root: `${path_relative_to_include()}/terraform.tfstate`

Relocating a leaf therefore requires a `state pull`/`state push` against the new
key before the old path is deleted. The runbook established by ADR-0106 and used
through ADR-0133 is: `git worktree add` at the pre-move commit, pull state from
the old key, push to the new, then confirm `terragrunt plan` reports "No
changes" with identical resource IDs on both sides. ADR-0130 records the
matching hazard: moving state to a new key does **not** clear the old key, so an
empty-state push to the old path is required before any PR deletes it.

### Generated files

Each root generates, with `if_exists = "overwrite"`:

| Generated file | Contents |
|---|---|
| `backend.tf` | the S3 remote-state block |
| `provider_generated.tf` | `required_providers` plus `cloudflare`/`scaleway` providers |
| `scaleway_ids_generated.tf` | `scaleway_organization_id`, `scaleway_project_id`, `scaleway_s3_provider_name` |
| `cloudflare_ids_generated.tf` | `cloudflare_account_id` plus every `ENV_CF_`-prefixed secret |
| `env_scaleway_secrets_generated.tf` | every `ENV_SW_`-prefixed secret as a local |
| `provider_backblaze_generated.tf` | the `b2` provider, or a comment when not enabled |

None of these are committed. Leaves read them as plain locals.

### Per-leaf overrides

Two opt-in mechanisms, both resolved by `read_terragrunt_config` with a default,
so a leaf that omits the file is unaffected and no error is raised:

- **`scaleway_config.hcl`** — declares `scaleway_region`/`scaleway_zone` locals
  for a leaf that is not `fr-par`/`fr-par-1` (ADR-0098). **This mechanism
  currently has zero users.** It was added for an `nl-ams` backup bucket; no
  `nl-ams` leaf exists today. It is live, working code with no consumer.
- **`backblaze_config.hcl`** — sets `enabled = true` to materialize the
  otherwise-latent `b2` provider in `willowgraysen.com/root.hcl` (ADR-0148).
  Three users, all under `willowgraysen.com/terraform/cold/`.

### A wart worth knowing

The shared `root.hcl` computes `is_pigeon_dev_leaf` and branches Cloudflare
credentials on it — but **both branches of the ternary are now identical**, so
the branch is dead code. It dates from when `pigeon.dev`'s zone sat on a
separate Cloudflare account with a separately-scoped token (ADR-0064, ADR-0096).
It reads as load-bearing and is not. The same file also cites
`docs/adr/0006-automatic-bucket-name-locals.md`, which has not existed in this
repo since the `pigeon-cli` split removed ADRs 0001–0030.

## 3. Secrets

Secrets are SOPS/age-encrypted and committed. Nothing is decrypted to disk:
`root.hcl` shells out to `sops` via `run_cmd` on every invocation and parses the
result into a `locals` map (ADR-0123).

- **`.env.enc`** at the repo root — shared values, read by the shared root.
- **`<domain>/secrets.enc`** — per-workload, no leading dot, decrypted
  independently and never merged with the root file (ADR-0131). All three
  domains have one.

`.sops.yaml` covers per-workload files with a generic creation rule
(`^[^/]+/secrets\.enc$`), so a new workload needs no `.sops.yaml`
change. Edit the root file with `mise run secrets-edit`; a workload file with
`sops` directly.

Two prefix conventions turn secrets into Terraform locals automatically: a key
named `ENV_SW_FOO` becomes local `foo` in `env_scaleway_secrets_generated.tf`,
and `ENV_CF_FOO` becomes local `foo` in `cloudflare_ids_generated.tf`. This is
how bucket names reach leaves without being hardcoded. Every lookup is
`get_env(KEY, lookup(secrets, KEY, ""))`, so an environment variable overrides
the encrypted value — which is what makes a one-off `SCALEWAY_PROJECT_ID=… terragrunt plan`
possible during a migration without editing any file.

## 4. Consuming Terraform modules

The modules themselves are **not in this repo** — they live in
`noisypigeon/pigeon.dev` under `templates/terraform/` (ADR-0154). This repo only
pins versions. There are 42 `source =` lines across `**/*.tf`,
resolving to 12 distinct module versions, every one of the form:

```hcl
source = "https://pigeon.dev/modules/<provider>/<module>/vX.Y.Z"
```

The modules actually consumed: `scaleway/`'s `iam-policy`, `iam-application`,
`iam-api-key`, `object-bucket` (three versions pinned concurrently), `project`,
`pigeon-cluster`, `grafana-dashboard`, `cockpit-observability`, and
`backblaze/`'s `bucket` and `api-key`.

### How a short URL resolves

These are not registry URLs. They rely on Terraform/go-getter's HTTP
module-source discovery protocol: `terraform init` requests the URL with
`?terraform-get=1` and reads a `<meta name="terraform-get">` tag out of the
response, which names the real `git::…?ref=…` source (ADR-0109). The pages are
static, generated by `generate-module-redirects.sh` — which now lives and runs
in `noisypigeon/pigeon.dev` itself, relocated there by ADR-0156 along with the
site it generates pages for — one per module-version git tag. (It has since
moved again, to `noisypigeon/pigeon-lib` (LIB-0002); this repo's stale copy was
deleted with the hoisted `pigeon.dev` leaves, DEV-0163.)

The part that reliably confuses: **the public URL path is always
`modules/...`, but the git tag behind it may carry either of two prefixes, and
the prefix decides which repo the emitted `git::` source names** (ADR-0110,
ADR-0136, ADR-0154):

- `modules/<provider>/<module>/vX.Y.Z` → `noisypigeon/noisypigeon`, i.e. this
  repo. A **frozen** set of 20 legacy tags whose commits predate
  `templates/` existing, so ADR-0154's `filter-repo` could not carry them. This
  set can never grow. One of them is still live-pinned:
  `scaleway/project/v1.0.0`.
- `templates/terraform/<provider>/<module>/vX.Y.Z` → `noisypigeon/pigeon.dev`,
  where every future tag is cut.

So the redirect layer is permanently two-repo, not transitionally so. Deleting
this repo's 20 `modules/*` tags would break a live `source =` line.

One thing that looks wrong and is not: this repo **also** still carries 53
`templates/*` tags, left behind deliberately — ADR-0154's `filter-repo` copied
them to `pigeon.dev` rather than moving them, and chose not to delete the
originals. They are inert here. The generator resolves a
`templates/terraform/...` version against `pigeon.dev`, so the local tags of
that name are never consulted. Do not "tidy" them on the assumption they are
the live ones, and do not cut new tags here.

### Version-bump discipline

Changing a module is a PR in `pigeon.dev`. Bumping the version a leaf here pins
is a **separate** PR here, and it cannot land until that release's site deploy
has finished — the short URL has to resolve before `terragrunt init` can fetch
it. A module's source path is part of its public interface, so moving a module
is a breaking change regardless of content (ADR-0093, ADR-0110).

## 5. The noisypigeon.com Zola site

One site built from a `src/` here: `noisypigeon.com/src` — the blog, with its
own `CHANGELOG.md` and an on-site `/changelog/` section fed by automation
(ADR-0107, ADR-0108). `pigeon.dev`'s site (the wiki, plus every generated
redirect/release page) moved into the `noisypigeon/pigeon.dev` repo itself
(ADR-0156) — this repo no longer builds, serves, or hosts a `src/` for it.

### Theme resolution

The `zola-site` theme lives in `pigeon.dev`, which `noisypigeon.com` doesn't
vendor locally, so resolution is two scripts and nothing committed:

1. `noisypigeon.com/fetch-templates.sh` maintains a gitignored blobless
   clone at `.templates-src`. Set `TEMPLATES_SRC` to use your own checkout.
2. `resolve-theme.sh` (which ships with the theme) materializes
   `src/themes/<name>` directly from that clone (ADR-0139).

The site picks its version with `[extra].theme_version` in `config.toml`:
`"main"` to track live, or a `vX.Y.Z` tag, materialized via `git archive`
(ADR-0114). It currently tracks `"main"`.

**`.templates-src` is a disposable build input, not a working copy.**
`fetch-templates.sh` runs `git reset --hard origin/HEAD` on every build, so
anything uncommitted there is destroyed by the next `mise run blog-build`. Do
not author changes in it. The ADR clone (`.adr-src`, §8) deliberately does
not share these semantics.

### Both sites now serve via GitHub Pages, DNS-only

`noisypigeon.com` (ADR-0158) and `pigeon.dev` (ADR-0156, in its own repo) both
moved off Scaleway-bucket-behind-Cloudflare onto GitHub Pages: apex and `www`
are DNS-only (`proxied = false`) CNAMEs to `noisypigeon.github.io`, and GitHub
Pages redirects `www` → apex natively. Neither site's DNS leaf carries a
`cloudflare_ruleset` any more — the Scaleway bucket-website gateway's
Host-header routing quirk that required one no longer applies to either site.
The tradeoff taken knowingly: no Cloudflare CDN/WAF in front of either site,
and TLS comes from GitHub's own certificate instead of Cloudflare's.

## 6. CI, as this repo consumes it

Five workflows, all in `.github/workflows/`, all **thin callers**: each keeps its
own `on:` trigger, `permissions`, `concurrency`, and any event-level `if:` gate,
but delegates its job body to a `workflow_call` reusable workflow in
`noisypigeon/pigeon.dev`, pinned `@main` (ADR-0155).

| Caller here | Delegates to |
|---|---|
| `terragrunt-plan.yml` | `terragrunt-detect.yml` + `terragrunt-run.yml` (`command: plan`) |
| `terragrunt-apply.yml` | `terragrunt-run.yml` (`command: apply`) |
| `blog-changelog.yml` | `blog-changelog.yml` |
| `interaction-limits-renew.yml` | `interaction-limits-renew.yml` |
| `noisypigeon-com-pages.yml` | `zola-site-pages.yml` |

Debugging CI behavior therefore usually means reading the other repo.
`zola-sites-deploy.yml` (the old bucket-sync caller, `detect` job plus a
per-site matrix since `secrets[matrix.key]` is a dynamic lookup and
`workflow_call.secrets` must be statically declared) no longer exists —
both sites it used to deploy now ship via GitHub Pages instead (ADR-0156,
ADR-0158), and `noisypigeon-com-pages.yml` needs neither a `detect` job nor
any secrets at all, since Pages deploys authenticate via OIDC.

One thing deliberately stays here: `terragrunt-apply.yml`'s authorization
gate — the comment body plus an `OWNER`/`MEMBER`/`COLLABORATOR` author-association
check — because it is the boundary for applying real infrastructure and belongs
in the repo whose infrastructure is at stake.

### The merge gate

`terragrunt/apply` is this repo's one required status check (ADR-0129). The
`detect` job runs on every PR with no path filter and sets that status directly:

- no `<name>/terraform/` leaf touched → `success` immediately, and the
  real `plan` job is skipped. Docs-only PRs merge without a Terraform run.
- a leaf touched → `pending`, the `plan` job runs, and the status only flips to
  `success` after a human comments `terragrunt apply` and it succeeds.

On success, `terragrunt-apply.yml` squash-merges and deletes the branch
automatically; stale plan/apply comments are hidden rather than edited
(ADR-0134). The upstream `run --all` invocation — one now, shared by plan and
apply — passes `--filter-allow-destroy`, without which a unit whose directory
was deleted on the branch is silently excluded from the run and so never
destroyed (ADR-0128).

The `main` ruleset carries two `bypass_mode: always` actors. That is the
documented escape hatch for the one failure mode this arrangement has: an
unparseable `terragrunt-detect.yml` upstream means the status is never written
and every PR here blocks on an unresolvable required check, including the fix.

## 7. `pigeon-cli` job infrastructure

The `pigeon` CLI itself is a Rust program in a third repo,
[`noisypigeon/pigeon-cli`](https://github.com/noisypigeon/pigeon-cli). This repo
has only the infrastructure its jobs run on, under
`willowgraysen.com/terraform/pigeon-cli/`:

- `cluster/` — the job fleet. One `pigeon-cluster` module call configured by a
  `jobs` list of objects in `cluster_definition.tf`: per job an instance type,
  block volume size/IOPS, network toggles, a `keyring` of bucket and secret
  entries, and `job_commands` to run. Adding a job is a list entry, not a new
  leaf (ADR-0144, ADR-0153).
- `shared/` — resources every job uses: `cockpit` (one shared metrics/logs
  store), `iam-application` (one identity rather than per-job throwaways),
  `grafana` (dashboards as code), and `reports/phase-*` buckets.
- `bucket/pigeon/{deduplicate,transform}` — the datasets jobs read and write.

ADR-0153 decomposed the old monolithic `compute-instance` module, and
`pigeon-cluster` is the composition that replaced it. That composition happens
**inside** the `pigeon-cluster` module, in `pigeon.dev` — so `compute-instance`,
`compute-instance-config` and `block-volume` are not pinned anywhere in this
repo. The `cluster/` leaf pins exactly one module, `scaleway/pigeon-cluster`,
and configures it. Earlier ADRs describing `compute-instance` as composing
`block-volume` and the IAM modules internally (ADR-0120, ADR-0121, ADR-0122) are
superseded.

Provisioning details worth knowing before debugging a job VM: environment
variables reach a non-login `ssh host 'pigeon …'` invocation only because they
are written to `/etc/environment` as well as `/etc/profile.d/` (ADR-0104), and
long-running job commands run as a self-disabling systemd oneshot ordered after
`cloud-final.service`, not as a `runcmd` step, so they do not block cloud-init's
completion status (ADR-0125).

## 8. Authoring an ADR

ADRs live in `noisypigeon/pigeon.dev` under `adr/infrastructure/` (ADR-0157),
numbered continuously from 0031 — ADRs 0001–0030 were `pigeon-cli`-specific and
were removed when that code split out, and survive in that repo.

```sh
mise run adr-fetch                      # clone/refresh pigeon.dev at .adr-src
mise run adr-new -- --title "do a thing"  # next number, skeleton, new branch
```

`adr-new` scaffolds and branches but does not commit; write the ADR, then push
and open a PR against `pigeon.dev`. Numbering is `max + 1` read from
`origin/HEAD`, so two unmerged ADRs can claim the same number — which is how the
existing duplicate `0136` and `0138` numbers arose, and also `0156`: one landed
on an unmerged branch here before ADR-0157's hoist ran, and an unrelated
`0156-simplify-claude-md` claimed the number independently in the meantime. Set
`ADR_SRC` to use your own checkout instead of `.adr-src`.

Unlike `.templates-src`, `.adr-src` is never reset: `fetch-adrs.sh` refuses to
run against a dirty clone rather than discarding an ADR in progress.

Every ADR uses four sections — `## Context`, `## Decision`, `## Consequences`,
`## Out of scope`. When an `Out of scope` bullet is a genuine deferral rather
than a permanent boundary, file it with `mise run adr-issue` while landing the
ADR; it creates or reuses a labeled issue and links it back into the bullet
(ADR-0031). Issues are filed against *this* repo by default, since the work is
here even though the ADR text is not.

Contradicting an existing ADR is fine; doing it silently is not. Write a new ADR,
or update the old one's `Status` to `Superseded by ADR-NNNN` (or `superseded in
part by`, which this corpus uses where only one section is overturned).

## 9. What is gone

Context for references you may hit in old commits, comments, or changelogs:

- **DigitalOcean** — all 6 modules and their leaves deleted once Scaleway reached
  parity (ADR-0086). Scaleway, Cloudflare and Backblaze are the only providers.
- **`terraform/infrastructure/`** — the provider-rooted tree, decommissioned by
  ADR-0098. Also `terraform/modules/` → `modules/` → `templates/terraform/`
  (ADR-0093, ADR-0110), now in `pigeon.dev`.
- **`workloads/blog/`** — became `workloads/noisypigeon.com/` when the site cut
  over from GitHub Pages to a Scaleway bucket (ADR-0132), then just
  `noisypigeon.com/` when `workloads/` itself was flattened away.
- **Intermediate workload groupings** — `workloads/{dns,email,bluesky,scaleway,bucket,management,custodial-storage,pigeon-cli}/`
  all existed and were all consolidated away into the three domain workloads.
  A path in an old commit message probably no longer exists.
- **`workloads/`** — every workload (`noisypigeon.com/`, `pigeon.dev/`,
  `willowgraysen.com/`), `root.hcl`, and `README.md` moved to the repo root;
  `README.md`'s content merged into `docs/USAGE.md`. Nothing nests under a
  `workloads/` directory any more.
- **`service/pigeon-cli`** — split out to `noisypigeon/pigeon-cli`. Note its
  split ADR was **ADR-0084 in that repo**; this repo's `ADR-0084` is an unrelated
  record about `compute-instance` cloud-init replacement, because the number was
  reused after the original was deleted. Citations meaning "the split" must name
  the repo.
