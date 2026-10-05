module "job" {
  source      = "https://noisypigeon.com/modules/scaleway/compute-instance/v5.3.0"
  enabled     = var.job_enabled
  name_prefix = local.job_name_prefix
  name_suffix = local.job_name_suffix
  user_config = {
    ssh_key = local.ssh_key_public_key
  }

  instance_config = {
    type    = local.instance_type
    cockpit = local.cockpit_config
    block_volume = {
      size       = local.job_block_volume_size
      project_id = local.scaleway_project_id
    }

    post_provision_commands = local.job_commands
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
    },
    {
      kind          = "bucket"
      alias         = "reports"
      endpoint      = local.destination_bucket.bucket_endpoint
      bucket        = "pigeon-cli-vmqjtz-reports"
      access_key_id = local.destination_bucket.access_key_id
      secret_key    = local.destination_bucket.secret_key
      provider      = local.destination_bucket.provider_name
    }
  ]
}

# output "ip_address" {
#   description = "Public IPv4 address"
#   value       = module.job.ipv4_address
# }

# output "access_key_id" {
#   description = "IAM API key access key"
#   value       = module.job.access_key_id
#   sensitive   = true
# }

# output "secret_key" {
#   description = "IAM API key secret key"
#   value       = module.job.secret_key
#   sensitive   = true
# }
