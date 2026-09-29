module "bucket" {
  source            = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/object-bucket?ref=terraform/modules/scaleway/object-bucket/v0.1.1"
  storage_class     = "glacier"
  namespace         = "custodian"
  name              = "dhj"
}
