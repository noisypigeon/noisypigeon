# module "instance" {
#   source      = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/compute-instance?ref=modules/scaleway/compute-instance/v1.0.0"
#   namespace   = "worker"
#   name        = "${module.bucket.name}"
#   image       = "ubuntu_jammy"
#   type        = "COMPUTE3-X8C-16G"
#   enable_ipv6 = true
#   ssh_keys    = [local.ssh_key_public_key]

#   buckets = [
#     {
#       bucket_name       = module.bucket.name
#       bucket_alias      = "source"
#       bucket_endpoint   = "s3.fr-par.scw.cloud"
#       bucket_access_key = module.iam.access_key
#       bucket_secret_key = module.iam.secret_key
#       bucket_provider   = "Scaleway"
#     },
#     {
#       bucket_name       = local.custodian_dj_bucket_name
#       bucket_alias      = "destination"
#       bucket_endpoint   = "s3.nl-ams.scw.cloud"
#       bucket_access_key = module.iam.access_key
#       bucket_secret_key = module.iam.secret_key
#       bucket_provider   = "Scaleway"
#     }
#   ]
# }
