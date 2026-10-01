# Changelog

All notable changes to this module are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-10-01

### Add scaleway/block-volume module and compute-instance volume attachment

Adds a new `scaleway/block-volume` module wrapping `scaleway_block_volume`, and extends `scaleway/compute-instance` so a volume it creates can be attached to an instance.

`block-volume`'s initial interface is required-fields-only, with two deliberate exceptions: the resource's `size_in_gb` is renamed to `size` (required — this module doesn't support creating from a snapshot yet, so omitting a size would be unsafe), and `iops`, though required by the underlying resource, defaults to `15000` (Scaleway's standard tier) rather than being required of every caller. Naming follows the same `{namespace}-{random}-{name}` scheme as every other module in this provider root. Outputs are `id` and `name`.

`compute-instance` gains one new, backwards-compatible input: `additional_volume_ids` (`list(string)`, default `[]`), wired straight through to `scaleway_instance_server`'s existing argument of the same name. Per this repo's established composition rule, `compute-instance` does not call `block-volume` internally — callers create a volume and pass its `id` through themselves, e.g.:

```hcl
module "scratch_volume" {
  source = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/block-volume?ref=terraform/modules/scaleway/block-volume/v0.1.0"
  namespace = "import"
  name      = "scratch"
  size      = 100
}

module "instance" {
  source = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/compute-instance?ref=..."
  ...
  additional_volume_ids = [module.scratch_volume.id]
}
```

Existing `compute-instance` callers are unaffected unless they opt in. Full design rationale in [ADR-0085](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0085-add-scaleway-block-volume-module.md).

[#109](https://github.com/noisypigeon/noisypigeon/pull/109)
