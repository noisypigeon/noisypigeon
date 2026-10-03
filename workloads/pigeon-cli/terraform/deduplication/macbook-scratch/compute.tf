module "compute" {
  source                = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/compute-instance?ref=modules/scaleway/compute-instance/v2.3.0"
  namespace             = "job-${local.job_name}"
  name                  = "${local.bucket_alias}-worker"
  image                 = "ubuntu_jammy"
  type                  = "COMPUTE3-X8C-16G"
  profile               = "pigeon-cli"
  ssh_keys              = [local.ssh_key_public_key]
  additional_volume_ids = [module.volume.id]

  cockpit = {
    metrics_push_url = scaleway_cockpit_source.pigeon_metrics.push_url
    logs_push_url    = scaleway_cockpit_source.pigeon_logs.push_url
    token_secret     = scaleway_cockpit_token.pigeon_push.secret_key
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
  size       = 1000
  project_id = local.scaleway_project_id_noisypigeon
}
