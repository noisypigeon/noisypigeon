module "compute" {
  source      = "https://noisypigeon.com/modules/scaleway/compute-instance/v5.1.0"
  name_prefix = local.name_prefix
  name_suffix = local.name_suffix
  user_config = {
    ssh_key = local.ssh_key_public_key
  }

  instance_config = {
    # type    = "COMPUTE3-X8C-16G"
    cockpit = local.cockpit_config
    block_volume = {
      size       = 50
      project_id = local.scaleway_project_id
    }
  }

  iam_config = {
    application_id          = local.pigeon_cli_iam_application_id
    project_ids             = [local.scaleway_project_id]
    project_permission_sets = ["ObjectStorageFullAccess"]
    description             = "pigeon-cli API key for ${local.job_name}"
  }

  keyring = [
    {
      kind          = "bucket"
      alias         = "source"
      endpoint      = local.source_bucket.bucket_endpoint
      bucket        = local.source_bucket.bucket_name
      access_key_id = local.source_bucket.access_key_id
      secret_key    = local.source_bucket.secret_key
      provider      = local.source_bucket.provider_name
    },
    {
      kind          = "bucket"
      alias         = "destination"
      endpoint      = local.destination_bucket.bucket_endpoint
      bucket        = local.destination_bucket.bucket_name
      access_key_id = local.destination_bucket.access_key_id
      secret_key    = local.destination_bucket.secret_key
      provider      = local.destination_bucket.provider_name
    }
  ]
}

output "ip_address" {
  description = "Public IPv4 address"
  value       = module.compute.ipv4_address
}

output "access_key_id" {
  description = "IAM API key access key"
  value       = module.compute.access_key_id
  sensitive   = true
}

output "secret_key" {
  description = "IAM API key secret key"
  value       = module.compute.secret_key
  sensitive   = true
}

moved {
  from = module.iam_policy.scaleway_iam_policy.policy[0]
  to   = module.compute.module.iam_policy[0].scaleway_iam_policy.policy
}

moved {
  from = module.iam_api_key.scaleway_iam_api_key.api_key
  to   = module.compute.module.iam_api_key[0].scaleway_iam_api_key.api_key
}

moved {
  from = module.iam_api_key.time_static.created
  to   = module.compute.module.iam_api_key[0].time_static.created
}
