module "bucket" {
  source        = "https://pigeon.dev/modules/scaleway/object-bucket/v4.0.0"
  storage_class = "glacier"
  name_prefix   = local.name_prefix
  name_suffix   = local.name_suffix
}
