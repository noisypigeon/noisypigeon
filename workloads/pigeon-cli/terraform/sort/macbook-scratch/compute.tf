module "compute" {
  source                = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/compute-instance?ref=modules/scaleway/compute-instance/v2.2.0"
  namespace             = "job-${local.job_name}"
  name                  = "${local.bucket_alias}-worker"
  image                 = "ubuntu_jammy"
  type                  = "COMPUTE3-X8C-16G"
  profile               = "pigeon-cli"
  ssh_keys              = [local.ssh_key_public_key]
  additional_volume_ids = [module.volume.id]
  buckets = [
    {
      bucket_name       = local.sort_source_bucket_name
      bucket_alias      = "source"
      bucket_endpoint   = local.fr_par_s3_endpoint
      bucket_access_key = local.sort_access_key
      bucket_secret_key = local.sort_secret_key
      bucket_provider   = local.scaleway_s3_provider
    }, {
      bucket_name       = local.sort_destination_bucket_name
      bucket_alias      = "destination"
      bucket_endpoint   = local.fr_par_s3_endpoint
      bucket_access_key = local.sort_access_key
      bucket_secret_key = local.sort_secret_key
      bucket_provider   = local.scaleway_s3_provider
    }
  ]

  keyring_entries = [
    {
      kind          = "bucket"
      alias         = "source"
      endpoint      = local.fr_par_s3_endpoint
      bucket        = local.sort_source_bucket_name
      access_key_id = local.sort_access_key
    },
    {
      kind          = "bucket"
      alias         = "destination"
      endpoint      = local.fr_par_s3_endpoint
      bucket        = local.sort_destination_bucket_name
      access_key_id = local.sort_access_key
    }
  ]

  environment_variables = {
    "PIGEON_SECRET_SOURCE"      = local.sort_secret_key,
    "PIGEON_SECRET_DESTINATION" = local.sort_secret_key,
  }
}

output "ip_address" {
  description = "Public IPv4 address"
  value       = module.compute.ipv4_address
}

module "volume" {
  source     = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/block-volume?ref=modules/scaleway/block-volume/v2.0.0"
  namespace  = "job-${local.job_name}"
  name       = "${local.bucket_alias}-worker"
  size       = 500
  project_id = local.scaleway_project_id_noisypigeon
}
