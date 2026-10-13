# module "cluster" {
#   source = "https://pigeon.dev/modules/scaleway/pigeon-cluster/v1.2.0"

#   cluster_config = {
#     name_prefix         = "pigeon-cli"
#     enable_private_network = local.enable_private_network
#     enable_public_gateway = local.enable_public_gateway
#     project_id          = local.scaleway_project_id
#     enable_bastion      = local.enable_bastion
#     public_gateway_type = local.public_gateway_type
#     cockpit = {
#       metrics_push_url = local.cockpit_metrics_url
#       logs_push_url    = local.cockpit_logs_url
#       token_secret     = local.cockpit_token_secret
#     }
#     shared_keyring = {
#       reports = {
#         kind     = "bucket"
#         endpoint = "https://s3.fr-par.scw.cloud"
#         bucket   = "pigeon-cli-vmqjtz-reports"
#         provider = "Scaleway"
#       }
#     }
#     shared_permission_sets = ["ObjectStorageFullAccess"]
#   }

#   jobs = local.jobs
# }

# output "bastion_connect_command" {
#   description = "bastion_connect_command"
#   value       = module.cluster.bastion_connect_command
# }
