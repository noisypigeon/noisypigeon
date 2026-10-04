module "bucket" {
  source    = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/object-bucket?ref=modules/scaleway/object-bucket/v2.0.0"
  namespace = local.job_name
  name      = local.bucket_alias
}
