module "bucket" {
  source             = "https://pigeon.dev/modules/scaleway/object-bucket/v4.1.1"
  exact_name         = local.exact_name
  project_id         = local.project_id
  enable_website     = true
  enable_public_read = true
}
