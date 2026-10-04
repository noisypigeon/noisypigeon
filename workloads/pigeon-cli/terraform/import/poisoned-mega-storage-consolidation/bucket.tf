module "bucket" {
  source    = "https://noisypigeon.com/modules/scaleway/object-bucket/v2.0.0"
  namespace = local.job_name
  name      = local.bucket_alias
}
