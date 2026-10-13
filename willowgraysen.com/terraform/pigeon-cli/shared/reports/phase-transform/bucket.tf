module "bucket" {
  source      = "https://pigeon.dev/modules/scaleway/object-bucket/v4.2.0"
  name_prefix = local.name_prefix
  name_suffix = local.name_suffix
  storage_class   = "standard"
  expiration_days = 3
}
