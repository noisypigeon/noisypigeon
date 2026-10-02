module "compute" {
  source                = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/compute-instance?ref=modules/scaleway/compute-instance/v2.0.0"
  namespace             = "job-${local.job_name}"
  name                  = "${local.bucket_alias}-worker"
  image                 = "ubuntu_jammy"
  type                  = "COMPUTE3-X8C-16G"
  profile               = "pigeon-cli"
  ssh_keys              = [local.ssh_key_public_key]
  additional_volume_ids = [module.volume.id]
  buckets = [
    {
      bucket_name       = local.deduplication_source_bucket_name
      bucket_alias      = "source"
      bucket_endpoint   = "https://s3.fr-par.scw.cloud"
      bucket_access_key = local.deduplication_access_key
      bucket_secret_key = local.deduplication_secret_key
      bucket_provider   = "Scaleway"
    }, {
      bucket_name       = local.deduplication_destination_bucket_name
      bucket_alias      = "destination"
      bucket_endpoint   = "https://s3.fr-par.scw.cloud"
      bucket_access_key = local.deduplication_access_key
      bucket_secret_key = local.deduplication_secret_key
      bucket_provider   = "Scaleway"
    }
  ]
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
