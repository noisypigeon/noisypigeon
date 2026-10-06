locals {
  # Kill switch
  job_enabled = true

  job_commands = [
    "cd pigeon-cli/ && mise run pigeon-release job run import --source 'source:poisoned/photo-library-stitching/' --destination 'destination:photo-library-stitching/' --report-bucket reports --yes --local-output /mnt/data/pigeon-job-import",
  ]

  # Configuration
  job_name_prefix       = "import"
  job_name_suffix       = "media-photo-library-stitching"
  job_block_volume_size = 50

  source_bucket = {
    bucket_name     = "import-ikbld8-backblaze"
    bucket_endpoint = "https://s3.fr-par.scw.cloud"
    access_key_id   = module.job.access_key_id
    secret_key      = module.job.secret_key
    provider_name   = local.scaleway_s3_provider_name
  }

  destination_bucket = {
    bucket_name     = "import-jfo5la-backblaze-media"
    bucket_endpoint = "https://s3.fr-par.scw.cloud"
    access_key_id   = module.job.access_key_id
    secret_key      = module.job.secret_key
    provider_name   = local.scaleway_s3_provider_name
  }

  // Non-configurable
  job_name           = "${local.job_name_prefix}-${local.job_name_suffix}"
  ssh_key_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKsmUsSyZRo1u8TLkz+kJVbxuYsrs3M3tBXpI3HVHQa" #gitleaks:allow
  instance_type      = "COMPUTE3-X8C-16G"
  cockpit_config = {
    metrics_push_url = local.cockpit_metrics_url
    logs_push_url    = local.cockpit_logs_url
    token_secret     = local.cockpit_token_secret
  }
}
