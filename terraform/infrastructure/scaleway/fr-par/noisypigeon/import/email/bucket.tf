module "bucket" {
  source            = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/object-bucket?ref=modules/scaleway/object-bucket/v1.0.0"
  enable_versioning = true
  namespace         = "import"
  name              = "email"
}
