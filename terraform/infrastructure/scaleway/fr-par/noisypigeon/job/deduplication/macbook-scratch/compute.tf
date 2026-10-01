# module "instance" {
#   source      = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/compute-instance?ref=terraform/modules/scaleway/compute-instance/v0.6.0"
#   namespace   = "job"
#   name        = "${local.import_macbook_scratch_bucket_name}"
#   image       = "ubuntu_jammy"
#   # type        = "STANDARD3-X6C-24G"
#   ssh_keys    = [local.ssh_key_public_key]
#   additional_volume_ids = [module.volume.id]

#   buckets = [
#     {
#       bucket_name       = local.import_macbook_scratch_bucket_name
#       bucket_alias      = "source"
#       bucket_endpoint   = "s3.fr-par.scw.cloud"
#       bucket_access_key = module.iam.access_key
#       bucket_secret_key = module.iam.secret_key
#       bucket_provider   = "Scaleway"
#     },
#     {
#       bucket_name       = module.bucket.name
#       bucket_alias      = "destination"
#       bucket_endpoint   = "s3.fr-par.scw.cloud"
#       bucket_access_key = module.iam.access_key
#       bucket_secret_key = module.iam.secret_key
#       bucket_provider   = "Scaleway"
#     }
#   ]
# }

# module "volume" {
#   source = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/block-volume?ref=terraform/modules/scaleway/block-volume/v1.0.0"
#   namespace = "job"
#   name   = "deduplication-volume"
#   size = 500
#   project_id = local.scaleway_project_id_noisypigeon
# }
