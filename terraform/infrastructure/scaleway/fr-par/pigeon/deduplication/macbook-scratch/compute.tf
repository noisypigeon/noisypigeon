module "compute" {
  source      = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/compute-instance?ref=terraform/modules/scaleway/compute-instance/v0.9.1"
  namespace   = "job-${local.job_name}"
  name        = "${local.bucket_alias}-worker"
  image       = "ubuntu_jammy"
  type        = "COMPUTE3-X8C-16G"
  profile     = "pigeon-cli"
  ssh_keys    = [local.ssh_key_public_key]
  additional_volume_ids = [module.volume.id]
}

output "ip_address" {
  description = "Public IPv4 address"
  value       = module.compute.ipv4_address
}

module "volume" {
  source     = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/block-volume?ref=terraform/modules/scaleway/block-volume/v1.0.0"
  namespace  = "job-${local.job_name}"
  name       = "${local.bucket_alias}-worker"
  size       = 500
  project_id = local.scaleway_project_id_noisypigeon
}
