# module "job" {
#   source      = "https://pigeon.dev/modules/scaleway/compute-instance/v5.3.1"
#   enabled     = true
#   name_prefix = local.job_name_prefix
#   name_suffix = local.job_name_suffix
#   user_config = {
#     ssh_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKsmUsSyZRo1u8TLkz+kJVbxuYsrs3M3tBXpI3HVHQa" #gitleaks:allow
#   }

#   instance_config = {
#     type    = local.instance_type
#     cockpit = {
#       metrics_push_url = local.cockpit_metrics_url
#       logs_push_url    = local.cockpit_logs_url
#       token_secret     = local.cockpit_token_secret
#     }

#     block_volume = {
#       size       = local.job_block_volume_size
#       project_id = local.scaleway_project_id
#     }

#     post_provision_commands = local.job_commands
#   }

#   iam_config = {
#     application_id          = local.pigeon_cli_iam_application_id
#     project_ids             = [local.scaleway_project_id]
#     project_permission_sets = ["ObjectStorageFullAccess"]
#     description             = "pigeon-cli API key for ${local.job_name}"
#   }

#   keyring = local.keyring
# }
