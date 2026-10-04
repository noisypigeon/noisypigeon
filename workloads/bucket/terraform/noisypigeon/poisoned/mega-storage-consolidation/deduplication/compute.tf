module "compute" {
  source                = "https://noisypigeon.com/modules/scaleway/compute-instance/v4.0.0"
  name_prefix           = "job-${local.namespace}"
  name_suffix           = "${local.name}-worker"
  additional_volume_ids = [module.volume.id]

  user_config = {
    ssh_key = local.ssh_key_public_key
  }

  instance_config = {
    type    = "COMPUTE3-X8C-16G"
    cockpit = local.cockpit
    # image omitted -- defaults to "ubuntu_jammy", same value this leaf passed explicitly before
  }

  keyring = [
    {
      kind          = "bucket"
      alias         = "source"
      endpoint      = module.bucket.endpoint
      bucket        = local.source_bucket_name
      access_key_id = module.iam.access_key
      secret_key    = module.iam.secret_key
      provider      = local.scaleway_s3_provider_name
    },
    {
      kind          = "bucket"
      alias         = "destination"
      endpoint      = module.bucket.endpoint
      bucket        = module.bucket.name
      access_key_id = module.iam.access_key
      secret_key    = module.iam.secret_key
      provider      = local.scaleway_s3_provider_name
    }
  ]
}

output "ip_address" {
  description = "Public IPv4 address"
  value       = module.compute.ipv4_address
}

module "volume" {
  source     = "https://noisypigeon.com/modules/scaleway/block-volume/v2.0.0"
  namespace  = "job-${local.namespace}"
  name       = "${local.name}-worker"
  size       = 1000
  project_id = local.scaleway_project_id
}
