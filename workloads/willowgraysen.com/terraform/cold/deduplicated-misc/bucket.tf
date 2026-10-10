module "bucket" {
  source      = "https://pigeon.dev/modules/backblaze/bucket/v0.1.0"
  name_prefix = local.name_prefix
  name_suffix = local.name_suffix
  description = local.description
}
