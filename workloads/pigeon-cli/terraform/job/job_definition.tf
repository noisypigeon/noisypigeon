# locals {
#   name_prefix       = "import"
#   name_suffix       = "some-name"
#   block_volume_size = 50

#   # Not a secret; this is my pub key. Matches
#   # workloads/management/terraform/scaleway/project.tf's own key.
#   ssh_key_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKsmUsSyZRo1u8TLkz+kJVbxuYsrs3M3tBXpI3HVHQa" #gitleaks:allow

#   # source_bucket = {
#   #   bucket_name     = ""
#   #   bucket_endpoint = "https://s3.fr-par.scw.cloud"
#   #   access_key_id   = module.job.access_key_id
#   #   secret_key      = module.job.secret_key
#   #   provider_name   = local.scaleway_s3_provider_name
#   # }

#   # destination_bucket = {
#   #   bucket_name     = ""
#   #   bucket_endpoint = "https://s3.fr-par.scw.cloud"
#   #   access_key_id   = module.job.access_key_id
#   #   secret_key      = module.job.secret_key
#   #   provider_name   = local.scaleway_s3_provider_name
#   # }

#   // Non-configurable
#   job_name      = "${local.name_prefix}-${local.name_suffix}"
#   instance_type = "COMPUTE3-X8C-16G"
#   cockpit_config = {
#     metrics_push_url = local.cockpit_metrics_url
#     logs_push_url    = local.cockpit_logs_url
#     token_secret     = local.cockpit_token_secret
#   }
# }
