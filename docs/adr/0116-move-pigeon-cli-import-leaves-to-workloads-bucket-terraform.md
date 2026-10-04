# ADR-0116: move `workloads/pigeon-cli/terraform/import/*` to `workloads/bucket/terraform/pigeon-cli/import/*`

- **Author**: Willow Graysen
- **Date**: 2026-10-04.
- **Status**: Accepted.

## Context

`workloads/pigeon-cli/terraform/import/` held exactly 5 leaves — `backblaze`, `email`, `poisoned-computer-snapshots`, `poisoned-mega-storage-consolidation`, `poisoned-t7-backup-2026-05-25` — all of them. All 5 move to a brand-new top-level workload, `workloads/bucket/terraform/pigeon-cli/import/`, establishing `workloads/bucket/` as the home for storage-bucket infrastructure generally, decoupled from which job/CLI happens to consume it, rather than nested under the consuming workload's own directory. `workloads/pigeon-cli/terraform/` now holds only `deduplication/*`, the compute-side dedup leaves — `import/` no longer exists. (A `workloads/bucket/terraform/pigeon-cli/deduplication/` placeholder already sits pre-scaffolded too, hinting those leaves are a planned future follow-up — out of scope here, not touched.)

Three of the five leaves are renamed along the way: `poisoned-computer-snapshots` → `poisoned/computer-snapshots`, `poisoned-mega-storage-consolidation` → `poisoned/mega-storage-consolidation`, and `poisoned-t7-backup-2026-05-25` → `poisoned/t7-backup` (also dropping the date suffix) — grouping the three `poisoned-*` leaves under a shared `poisoned/` directory instead of a flat, repeated prefix.

## Decision

### 1. Directory-only move, no content changes

All 5 destinations existed beforehand as empty, pre-scaffolded placeholders — the same pattern ADR-0105/0106/0115 established. Moved via `rmdir <empty destination>` + `git mv <source> <destination>`, same as those precedents; `.terraform.lock.hcl`/`.terragrunt-cache/` are gitignored, not moved. All 16 moved files (`terragrunt.hcl`, `bucket.tf`, `workload_definition.tf`, plus `email/iam.tf`) show as pure renames with zero content diff — confirmed via `git diff --cached --stat` reporting `0 insertions(+), 0 deletions(-)` across the board.

**Deliberately not touched**: each leaf's `workload_definition.tf` `name` local, which feeds directly into its real Scaleway bucket's actual name (e.g. `poisoned-computer-snapshots/workload_definition.tf` keeps `name = "poisoned-computer-snapshots"` verbatim even though the directory is now `poisoned/computer-snapshots/`). This is a pure repo-organization and Terraform-state-location change — changing that value would rename/recreate the real cloud bucket, which isn't the goal. Confirmed post-migration: every bucket's actual Scaleway name (`import-<suffix>-<name>`) is byte-identical before and after.

No `workloads/root.hcl` changes needed: its leaf-validity (`path_segments[1] == "terraform"`), remote-state-key (`workloads/${path_relative_to_include()}/terraform.tfstate`), and region/zone resolution are purely structural/path-derived, confirmed workload-name-agnostic (the only name-keyed branch in `root.hcl` is Cloudflare's `pigeon.dev`-domain check, irrelevant here) — a brand-new top-level workload name needs zero wiring, same conclusion ADR-0097/0106/0115 each reached for their own moves.

No `dependency` blocks exist anywhere in `workloads/` referencing these leaves. One real cross-reference exists — `poisoned-mega-storage-consolidation/workload_definition.tf`'s `source_bucket_name = local.import_backblaze_bucket_name` — but that local is synthesized by `root.hcl` from an `.env` key (`ENV_SW_IMPORT_BACKBLAZE_BUCKET_NAME`), entirely independent of any leaf's directory path, so it resolved correctly and unchanged through the move (confirmed: the destination leaf's `terragrunt plan` showed the same bucket name for this reference as the baseline).

### 2. State migration

Same `git worktree add ... HEAD` + `terragrunt state pull`/`push` runbook as ADR-0106/0115, run for all 5 leaves against one shared worktree. Unlike ADR-0115, the repo was at a fully clean, consistent baseline throughout (the `scaleway_project_id` rename that complicated the prior move had since landed and merged) — no env-var workaround needed this time. Every leaf's baseline plan (old location, pristine `HEAD`) and post-push plan (new location, real working tree) showed "No changes," with identical resource IDs in both:

| Leaf | Resource ID (unchanged by the move) |
|---|---|
| `backblaze` | `fr-par/import-h7hkdr-backblaze` |
| `email` | `fr-par/import-bfurb3-email` |
| `poisoned/computer-snapshots` | `fr-par/import-5vk8yg-poisoned-computer-snapshots` |
| `poisoned/mega-storage-consolidation` | `fr-par/import-yxtsyz-poisoned-mega-storage-consolidation` |
| `poisoned/t7-backup` | `fr-par/import-a10yv2-poisoned-t7-backup-2026-05-25` |

Old-location state objects left as low-priority cleanup, per established precedent.

## Consequences

- `workloads/pigeon-cli/terraform/` now holds only `deduplication/*` — `import/` is gone entirely (not git-tracked either way, since git doesn't track empty directories).
- `workloads/bucket/` is now a live workload, its first occupant being these 5 `pigeon-cli`-owned import buckets.
- `CLAUDE.md`'s `workloads/pigeon-cli/terraform/` description is corrected to reflect this (it had already drifted stale before this move — it listed `macbook-scratch` under `import/`, which actually lives under `deduplication/`, and didn't mention the `poisoned-*` leaves at all).

## Out of scope

- `workloads/bucket/terraform/pigeon-cli/deduplication/`'s pre-scaffolded placeholder — not populated by this ADR.
- The stray, unrelated empty directory `workloads/pigeon-cli/terraform/bucket/` (old workload, confusingly similar name to the new one) — left as-is, not this ADR's concern.
