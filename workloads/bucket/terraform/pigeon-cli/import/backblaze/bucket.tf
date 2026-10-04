module "bucket" {
  source        = "https://noisypigeon.com/modules/scaleway/object-bucket/v1.0.0"
  storage_class = "glacier"
  namespace     = local.namespace
  name          = local.name
}
