module "bucket" {
  source        = "https://noisypigeon.com/modules/scaleway/object-bucket/v1.0.0"
  storage_class = "glacier"
  namespace     = "custodian"
  name          = local.custodian_dj_name
}
