module "bucket" {
  source             = "https://noisypigeon.com/modules/scaleway/object-bucket/v4.1.0"
  exact_name         = local.exact_name
  project_id         = local.project_id
  enable_website     = true
  enable_public_read = true
}
