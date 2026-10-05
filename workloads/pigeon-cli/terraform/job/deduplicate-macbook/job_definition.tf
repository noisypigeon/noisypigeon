# locals {
#   # Kill switch
#   job_enabled       = true

#   job_commands = [
#     "cd pigeon-cli/ && mise run pigeon-release job run deduplicate --source-bucket source --concurrency 8 --report-bucket reports --yes --local-output /mnt/data --remote-output destination --upload-concurrency 16",
#   ]

#   # Configuration
#   job_name_prefix   = "deduplicate"
#   job_name_suffix   = "macbook"
#   job_block_volume_size = 750

#   source_bucket = {
#     bucket_name     = local.import_macbook_bucket_name
#     bucket_endpoint = "https://s3.fr-par.scw.cloud"
#     access_key_id   = module.job.access_key_id
#     secret_key      = module.job.secret_key
#     provider_name   = local.scaleway_s3_provider_name
#   }

#   destination_bucket = {
#     bucket_name     = local.deduplicate_macbook_bucket_name
#     bucket_endpoint = "https://s3.fr-par.scw.cloud"
#     access_key_id   = module.job.access_key_id
#     secret_key      = module.job.secret_key
#     provider_name   = local.scaleway_s3_provider_name
#   }

#   // Non-configurable
#   job_name      = "${local.job_name_prefix}-${local.job_name_suffix}"
#   ssh_key_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKsmUsSyZRo1u8TLkz+kJVbxuYsrs3M3tBXpI3HVHQa" #gitleaks:allow
#   instance_type = "COMPUTE3-X8C-16G"
#   cockpit_config = {
#     metrics_push_url = local.cockpit_metrics_url
#     logs_push_url    = local.cockpit_logs_url
#     token_secret     = local.cockpit_token_secret
#   }
# }
