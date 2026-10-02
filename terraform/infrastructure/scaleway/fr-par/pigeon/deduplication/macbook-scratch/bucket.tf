module "bucket" {
  source            = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/object-bucket?ref=terraform/modules/scaleway/object-bucket/v0.2.0"
  namespace         = local.job_name
  name              = local.bucket_alias
}
