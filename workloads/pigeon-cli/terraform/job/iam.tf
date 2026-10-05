module "iam_policy" {
  source = "https://noisypigeon.com/modules/scaleway/iam-policy/v4.0.0"
  name   = "${local.job_name}-iam-policy"

  application_id = local.pigeon_cli_iam_application_id

  project_ids = [
    local.scaleway_project_id,
  ]
  project_permission_sets = [
    "ObjectStorageFullAccess",
  ]
}

module "iam_api_key" {
  source = "https://noisypigeon.com/modules/scaleway/iam-api-key/v0.1.0"

  application_id = local.pigeon_cli_iam_application_id
  description    = "pigeon-cli API key for ${local.job_name}"
}

output "access_key" {
  description = "IAM API key access key"
  value       = module.iam_api_key.access_key
  sensitive   = true
}

output "secret_key" {
  description = "IAM API key secret key"
  value       = module.iam_api_key.secret_key
  sensitive   = true
}
