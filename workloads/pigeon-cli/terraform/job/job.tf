module "compute" {
  source                = "https://noisypigeon.com/modules/scaleway/compute-instance/v5.0.1"
  name_prefix           = local.name_prefix
  name_suffix           = local.name_suffix
  user_config = {
    ssh_key = local.ssh_key_public_key
  }

  instance_config = {
    # type    = "COMPUTE3-X8C-16G"
    cockpit = local.cockpit_config
    block_volume = {
      size = 50
      project_id = local.scaleway_project_id
    }
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
