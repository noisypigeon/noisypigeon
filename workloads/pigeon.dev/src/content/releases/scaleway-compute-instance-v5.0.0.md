+++
title = "scaleway/compute-instance v5.0.0"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-compute-instance-v5.0.0"
description = "Rename block-volume's naming inputs and compose it inside compute-instance"
+++

`block-volume` still took `namespace`/`name`, the naming convention every sibling module in this provider root (`compute-instance`, `object-bucket`, `iam-application`) has already moved to `name_prefix`/`name_suffix`. This PR renames them to match.

It also folds volume creation into `compute-instance` itself. A repo-wide census found `block-volume` has had exactly one consumer, ever, and that consumer always paired it 1:1 with the same `compute-instance` call -- composing the two separately bought no real flexibility, just a second module block and manual `additional_volume_ids = [module.volume.id]` plumbing every caller had to repeat. `compute-instance`'s top-level `additional_volume_ids` input is replaced by a new `instance_config.block_volume` object:

- `block_volume` left unset: no managed volume, nothing extra attached.
- `block_volume.size` unset: no managed volume is created, but `block_volume.additional_volume_ids` (pre-created IDs from elsewhere) still attach.
- `block_volume.size` set: `compute-instance` creates the volume itself by composing `scaleway/block-volume` internally, passing through the instance's own `name_prefix`/`name_suffix` so the volume's name matches the instance's -- exactly what the one real past consumer always did by hand. `block_volume.project_id` becomes required in this case, enforced via a `validation` block.

This is a narrow, named exception to ADR-0081/ADR-0085's "no local module composes another internally" principle, which otherwise still holds for every other module pairing in this provider root (`object-bucket`/`iam-policy` keep composing externally -- they're genuinely reused across many leaves, unlike `block-volume`). `block-volume` itself isn't removed; it stays independently callable.

Breaking for both modules:
- `block-volume`: `namespace`/`name` renamed to `name_prefix`/`name_suffix`.
- `compute-instance`: `additional_volume_ids` removed; use `instance_config.block_volume.{size,iops,project_id,additional_volume_ids}` instead.

The one live consumer (`workloads/bucket/terraform/noisypigeon/poisoned/mega-storage-consolidation/deduplication`) stays pinned to its old `compute-instance/v4.0.0`/`block-volume/v2.0.0` tags rather than being migrated here -- its compute/volume/IAM are already being removed entirely on a separate, not-yet-merged branch, so migrating it now would be wasted effort.

See docs/adr/0120-compose-scaleway-block-volume-inside-compute-instance.md for the full decision record, including strikethrough amendments to ADR-0081 and ADR-0085 marking the principle exception.

[#163](https://github.com/noisypigeon/noisypigeon/pull/163)
