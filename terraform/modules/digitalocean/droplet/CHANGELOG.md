# Changelog

All notable changes to this module are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - 2026-09-29

### Drop Cloudflare DNS record integration

This module no longer creates a Cloudflare DNS record for the droplet: `dns_record.tf` (the `cloudflare_dns_record` resource and its `cloudflare_zone` data source), the `cloudflare_zone_id` input variable, and the `hostname` output are all removed. The now-unreferenced `cloudflare` provider requirement in `versions.tf` is removed as well.

This is a breaking change: any caller passing `cloudflare_zone_id` or consuming this module's `hostname` output must be updated. DNS for a droplet provisioned by this module is now entirely the caller's own responsibility.

## Migration

Before:
```hcl
module "droplet" {
  source             = "..."
  cloudflare_zone_id = var.zone_id
  # ...
}

output "hostname" {
  value = module.droplet.hostname
}
```

After: drop `cloudflare_zone_id` from the module call, and create the DNS record (if still needed) alongside the module instead of consuming a `hostname` output from it -- e.g. a `cloudflare_dns_record` resource pointed at `module.droplet.ipv4_address`.

[#91](https://github.com/noisypigeon/noisypigeon/pull/91)

## [1.0.0] - 2026-09-29

### Accept caller-supplied bucket credentials per rclone remote

Each entry in the `buckets` input now carries its own `bucket_provider`, `bucket_endpoint`, `bucket_access_key`, and `bucket_secret_key`, instead of the module implicitly provisioning a single DigitalOcean-Spaces-scoped access key internally (via the now-removed `compute_bucket_access_key` submodule) and hardcoding every rclone remote's `provider`/`endpoint` to DigitalOcean Spaces in the caller's own region. This lets a droplet's rclone config mix buckets from different S3-compatible providers, and hands credential provisioning entirely to the caller rather than this module.

This is a breaking change: every existing caller of this module must update its `buckets` list to supply the four new required fields (previously just `bucket_name` and `bucket_alias`).

## Migration

Before:
```hcl
buckets = [{ bucket_name = "backups", bucket_alias = "backups" }]
```

After:
```hcl
buckets = [{
  bucket_name       = "backups"
  bucket_alias      = "backups"
  bucket_provider   = "DigitalOcean"
  bucket_endpoint   = "nyc3.digitaloceanspaces.com"
  bucket_access_key = module.my_access_key.access_key
  bucket_secret_key = module.my_access_key.secret_key
}]
```

[#90](https://github.com/noisypigeon/noisypigeon/pull/90)

## [0.1.1] - 2026-09-26

### Fix droplet module's access-key dependency source

This module's `compute_bucket_access_key` sub-module dependency was still pointing at the retired `noisypigeon/pigeon-tf` repo's old tag. It now resolves through this repo's own `terraform/modules/digitalocean/access-key` module at the current post-merge tag, so a fresh `terraform init` on this module no longer depends on an external repo that won't receive future updates.

[#63](https://github.com/noisypigeon/pigeon/pull/63)

## [0.1.0] - 2026-09-26

### Consolidate as terraform/modules/digitalocean/droplet 0.1.0

A DigitalOcean droplet (`digitalocean_droplet`) with cloud-init provisioning
(rclone, an LVM auto-combine script for attached volumes, a sudo user) and a
Cloudflare DNS alias (`hostname` output — a bare hostname, not a URL). Ported
from `pigeon-pizza` (per
[ADR-0041](../../../../docs/adr/0041-port-droplet-module.md)), with its
`access-key` dependency pinned to an explicit tagged git ref rather than a
floating relative-path source.

Consolidates this module's prior `pigeon-tf` version history (`v0.1.0`,
`v0.1.1`) into a single 0.1.0 release as part of merging `pigeon-tf` into
this repo — see
[ADR-0037](../../../../docs/adr/0037-merge-pigeon-tf-terraform-modules.md)
for the merge.
