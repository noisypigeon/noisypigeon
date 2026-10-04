module "compute" {
  source                = "https://noisypigeon.com/modules/scaleway/compute-instance/v2.3.2"
  namespace             = "job-${local.job_name}"
  name                  = "${local.bucket_alias}-worker"
  image                 = "ubuntu_jammy"
  type                  = "COMPUTE3-X8C-16G"
  profile               = "pigeon-cli"
  ssh_keys              = [local.ssh_key_public_key]
  additional_volume_ids = [module.volume.id]

  cockpit = {
    metrics_push_url = local.cockpit_metrics_url
    logs_push_url    = local.cockpit_logs_url
    token_secret     = local.cockpit_token_secret
  }

  buckets = [
    {
      bucket_name       = local.import_poisoned_computer_snapshots_bucket_name
      bucket_alias      = "source"
      bucket_endpoint   = module.bucket.endpoint
      bucket_access_key = module.iam.access_key
      bucket_secret_key = module.iam.secret_key
      bucket_provider   = local.scaleway_s3_provider
    },
    {
      bucket_name       = module.bucket.name
      bucket_alias      = "destination"
      bucket_endpoint   = module.bucket.endpoint
      bucket_access_key = module.iam.access_key
      bucket_secret_key = module.iam.secret_key
      bucket_provider   = local.scaleway_s3_provider
    }
  ]

  keyring_entries = [
    {
      kind          = "bucket"
      alias         = "source"
      endpoint      = module.bucket.endpoint
      bucket        = local.import_poisoned_computer_snapshots_bucket_name
      access_key_id = module.iam.access_key
    },
    {
      kind          = "bucket"
      alias         = "destination"
      endpoint      = module.bucket.endpoint
      bucket        = module.bucket.name
      access_key_id = module.iam.access_key
    }
  ]

  environment_variables = {
    "PIGEON_SECRET_SOURCE"      = module.iam.secret_key
    "PIGEON_SECRET_DESTINATION" = module.iam.secret_key
  }
}

output "ip_address" {
  description = "Public IPv4 address"
  value       = module.compute.ipv4_address
}

module "volume" {
  source     = "https://noisypigeon.com/modules/scaleway/block-volume/v2.0.0"
  namespace  = "job-${local.job_name}"
  name       = "${local.bucket_alias}-worker"
  size       = 1000
  project_id = local.scaleway_project_id_noisypigeon
}
