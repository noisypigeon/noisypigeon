# module "pigeon_jobs" {
#   source = "https://pigeon.dev/modules/scaleway/pigeon-cluster/v0.1.0"

#   cluster_config = {
#     name_prefix = "pigeon-cli"
#     project_id  = local.scaleway_project_id
#     cockpit = {
#       metrics_push_url = local.cockpit_metrics_url
#       logs_push_url    = local.cockpit_logs_url
#       token_secret     = local.cockpit_token_secret
#     }
#   }


#   jobs = {
#     consolidate-segment-1 = {
#       job_commands = [
#         "cd pigeon-cli",
#         "mkdir /mnt/data/a && mise run pigeon-release job run import --source 'fastmail:' --destination 'destination:deduplicate-uqpdu7-backblaze-fastmail-consolidation/' --report-bucket reports --yes --local-output /mnt/data/a",
#         "mkdir /mnt/data/b && mise run pigeon-release job run import --source 'mega:' --destination 'destination:deduplicate-p7d0kd-backblaze-mega-consolidation/' --report-bucket reports --yes --local-output /mnt/data/b",
#         "mkdir /mnt/data/c && mise run pigeon-release job run import --source 'macbook:' --destination 'destination:deduplicate-qb27gx-macbook/' --report-bucket reports --yes --local-output /mnt/data/c",
#         "mkdir /mnt/data/d && mise run pigeon-release job run import --source 'snapshots:' --destination 'destination:deduplicate-h4w903-backblaze-computer-snapshots/' --report-bucket reports --yes --local-output /mnt/data/d"
#       ]
#       extra_permission_sets = ["ObjectStorageFullAccess"]
#       keyring = [
#         {
#           kind          = "bucket"
#           alias         = "fastmail"
#           endpoint      = "https://s3.fr-par.scw.cloud"
#           bucket        = "deduplicate-uqpdu7-backblaze-fastmail-consolidation"
#           access_key_id = module.iam_api_key.access_key
#           secret_key    = module.iam_api_key.secret_key
#           provider      = local.scaleway_s3_provider_name
#         },
#         {
#           kind          = "bucket"
#           alias         = "mega"
#           endpoint      = "https://s3.fr-par.scw.cloud"
#           bucket        = "deduplicate-p7d0kd-backblaze-mega-consolidation"
#           access_key_id = module.iam_api_key.access_key
#           secret_key    = module.iam_api_key.secret_key
#           provider      = local.scaleway_s3_provider_name
#         },
#         {
#           kind          = "bucket"
#           alias         = "macbook"
#           endpoint      = "https://s3.fr-par.scw.cloud"
#           bucket        = "deduplicate-qb27gx-macbook"
#           access_key_id = module.iam_api_key.access_key
#           secret_key    = module.iam_api_key.secret_key
#           provider      = local.scaleway_s3_provider_name
#         },
#         {
#           kind          = "bucket"
#           alias         = "snapshots"
#           endpoint      = "https://s3.fr-par.scw.cloud"
#           bucket        = "deduplicate-h4w903-backblaze-computer-snapshots"
#           access_key_id = module.iam_api_key.access_key
#           secret_key    = module.iam_api_key.secret_key
#           provider      = local.scaleway_s3_provider_name
#         },
#         {
#           kind          = "bucket"
#           alias         = "destination"
#           endpoint      = "https://s3.fr-par.scw.cloud"
#           bucket        = "consolidate-n41ilf-segment-1"
#           access_key_id = module.iam_api_key.access_key
#           secret_key    = module.iam_api_key.secret_key
#           provider      = local.scaleway_s3_provider_name
#         },
#         {
#           kind          = "bucket"
#           alias         = "reports"
#           endpoint      = "https://s3.fr-par.scw.cloud"
#           bucket        = "pigeon-cli-vmqjtz-reports"
#           access_key_id = module.iam_api_key.access_key
#           secret_key    = module.iam_api_key.secret_key
#           provider      = local.scaleway_s3_provider_name
#         }
#       ]
#     }
#   }
# }
