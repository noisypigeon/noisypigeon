module "bucket" {
  source            = "https://noisypigeon.com/modules/scaleway/object-bucket/v4.1.1"
  name_prefix       = local.name_prefix
  name_suffix       = local.name_suffix
  project_id        = local.scaleway_project_id
  enable_versioning = true
  storage_class     = "standard"
}
