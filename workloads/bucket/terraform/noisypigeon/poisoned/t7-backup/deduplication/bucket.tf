module "bucket" {
  source      = "https://noisypigeon.com/modules/scaleway/object-bucket/v4.0.0"
  force_destroy = true
  name_prefix = local.name_prefix
  name_suffix = local.name_suffix
}
