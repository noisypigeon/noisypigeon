module "iam" {
  source = "https://noisypigeon.com/modules/scaleway/iam-policy/v2.0.0"
  name   = "${module.bucket.name}-iam"

  project_ids = [
    local.scaleway_project_id_noisypigeon,
  ]
  project_permission_sets = [
    "InstancesFullAccess",
    "ObjectStorageFullAccess",
    "VPCFullAccess",
    "InstancesFullAccess",
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

  expires_at = "2027-09-25T22:32:12Z"
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
