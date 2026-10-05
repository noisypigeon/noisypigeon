module "iam_application" {
  source      = "https://noisypigeon.com/modules/scaleway/iam-application/v0.1.0"
  name        = module.bucket.name
  description = "Deployer identity for every Scaleway leaf in this repo"
}

module "iam_policy" {
  source = "https://noisypigeon.com/modules/scaleway/iam-policy/v4.0.0"
  name   = "${module.bucket.name}-policy"

  application_id = module.iam_application.id

  project_ids = [
    local.scaleway_project_id,
  ]
  project_permission_sets = [
    "InstancesFullAccess",
    "ObjectStorageFullAccess",
    "VPCFullAccess",
    "BlockStorageFullAccess",
    "SSHKeysReadOnly",
    "SSHKeysFullAccess",
    "ObservabilityFullAccess"
  ]

  organization_id = local.scaleway_organization_id
  organization_permission_sets = [
    "ProjectManager",
    "IAMManager",
    "IAMApplicationManager"
  ]
}

module "iam_api_key" {
  source = "https://noisypigeon.com/modules/scaleway/iam-api-key/v0.1.0"

  application_id = module.iam_application.id
  expires_at     = "2027-09-25T22:32:12Z"
}

# output "access_key" {
#   description = "IAM API key access key"
#   value       = module.iam_api_key.access_key
#   sensitive   = true
# }

# output "secret_key" {
#   description = "IAM API key secret key"
#   value       = module.iam_api_key.secret_key
#   sensitive   = true
# }
