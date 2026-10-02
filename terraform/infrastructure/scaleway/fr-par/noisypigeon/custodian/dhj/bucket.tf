module "bucket" {
  source        = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/object-bucket?ref=modules/scaleway/object-bucket/v1.0.0"
  storage_class = "glacier"
  namespace     = "custodian"
  name          = "dhj"
}
