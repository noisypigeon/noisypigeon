module "bucket" {
  source            = "https://noisypigeon.com/modules/scaleway/object-bucket/v1.0.0"
  enable_versioning = true
  namespace         = "terraform"
  name              = "state"
}
