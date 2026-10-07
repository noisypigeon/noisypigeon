
# module "iam_policy" {
#   source = "https://pigeon.dev/modules/scaleway/iam-policy/v4.0.0"
#   name   = "${local.name_prefix}-${local.name_suffix}-iam-policy"

#   application_id = local.pigeon_cli_iam_application_id
#   project_ids    = [local.scaleway_project_id]
#   project_permission_sets = ["ObjectStorageFullAccess"]
# }

# module "iam_api_key" {
#   source = "https://pigeon.dev/modules/scaleway/iam-api-key/v0.2.0"

#   application_id = local.pigeon_cli_iam_application_id
#   description    = "${local.name_prefix}-${local.name_suffix} API key"
#   # expires_at     = var.iam_config.api_key_expires_at
# }

# output "access_key_id" {
#   value = module.iam_api_key.access_key
#   description = "access_key_id"
#   sensitive = true
# }

# output "secret_key" {
#   value = module.iam_api_key.secret_key
#   description = "secret_key"
#   sensitive = true
# }
