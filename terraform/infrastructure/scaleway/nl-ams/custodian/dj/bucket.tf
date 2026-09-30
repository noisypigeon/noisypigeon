module "bucket" {
  source            = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/object-bucket?ref=terraform/modules/scaleway/object-bucket/v0.2.0"
  storage_class     = "glacier"
  namespace         = "custodian"
  name              = local.custodian_dj_name
}
