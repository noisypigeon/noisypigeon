module "iam" {
  source = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/iam-policy?ref=terraform/modules/scaleway/iam-policy/v1.1.1"
  name   = "${module.bucket.name}-iam"

  expires_at = "2027-09-25T22:32:12Z"

  project_ids = [
    local.scaleway_project_id_noisypigeon,
  ]
  project_permission_sets = [
    "ObjectStorageFullAccess",
  ]
}

output "access_key" {
  description = "IAM API key access key"
  value       = module.iam.access_key
  sensitive   = true
}

output "secret_key" {
  description = "IAM API key secret key"
  value       = module.iam.secret_key
  sensitive   = true
}
