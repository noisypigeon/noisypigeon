module "droplet" {
  source                   = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/digitalocean/droplet?ref=terraform/modules/digitalocean/droplet/v2.0.0"
  name                     = local.data_custodian_m5q4wp_bucket_name
  namespace                = "droplet"
  image                    = "ubuntu-26-04-x64"
  size                     = "s-4vcpu-8gb-240gb-intel"
  ssh_key_name             = local.ssh_key_name
  region                   = local.tor1_region

  # `rclone` access.
  buckets = [
    {
      bucket_name          = local.data_custodian_m5q4wp_bucket_name
      bucket_alias         = "source"
      bucket_access_key    = module.key.access_key
      bucket_secret_key    = module.key.secret_key
      bucket_provider      = "DigitalOcean"
      bucket_endpoint      = "https://tor1.digitaloceanspaces.com"
    },
    {
      bucket_name          = local.scaleway_dhj_bucket_name
      bucket_alias         = "destination"
      bucket_access_key    = local.scaleway_dhj_access_key
      bucket_secret_key    = local.scaleway_dhj_secret_key
      bucket_provider      = "Scaleway"
      bucket_endpoint      = local.scaleway_endpoint
    }

  ]
}

output "ipv4_address" {
  value = module.droplet.ipv4_address
}
