module "bucket" {
  source            = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/object-bucket?ref=terraform/modules/scaleway/object-bucket/v0.1.1"
  namespace         = "vault"
  name              = "email"
  storage_class     = "glacier"
  enable_versioning = true
}
