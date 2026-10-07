# locals {
#   job_name_prefix         = "consolidate"
#   job_name_suffix         = "segment-2"
#   job_block_volume_size   = 50

#   job_commands = [
#     "cd pigeon-cli/",
#     "mkdir /mnt/data/segment_a && mise run pigeon-release job run import --source '${local.a_segment_alias}:' --destination 'destination:${local.a_segment_bucket_name}/' --report-bucket reports --yes --local-output /mnt/data/segment_a",
#     "mkdir /mnt/data/segment_b && mise run pigeon-release job run import --source '${local.b_segment_alias}:' --destination 'destination:${local.b_segment_bucket_name}/' --report-bucket reports --yes --local-output /mnt/data/segment_b",
#     "mkdir /mnt/data/segment_c && mise run pigeon-release job run import --source '${local.c_segment_alias}:' --destination 'destination:${local.c_segment_bucket_name}/' --report-bucket reports --yes --local-output /mnt/data/segment_c"
#   ]

#   a_segment_bucket_name = "deduplicate-0msi9l-backblaze-google-consolidation"
#   a_segment_alias = "google"
#   b_segment_bucket_name = "deduplicate-fx7k2k-backblaze-media"
#   b_segment_alias = "media"
#   c_segment_bucket_name = "deduplicate-gzoc4o-backblaze-t7-email-consolidation"
#   c_segment_alias = "t7"

#   # Segments
#   keyring = [
#     {
#       kind          = "bucket"
#       alias         = local.a_segment_alias
#       endpoint      = local.scaleway_s3_endpoint
#       bucket        = local.a_segment_bucket_name
#       access_key_id = module.job.access_key_id
#       secret_key    = module.job.secret_key
#       provider      = local.scaleway_s3_provider_name
#     },
#     {
#       kind          = "bucket"
#       alias         = local.b_segment_alias
#       endpoint      = local.scaleway_s3_endpoint
#       bucket        = local.b_segment_bucket_name
#       access_key_id = module.job.access_key_id
#       secret_key    = module.job.secret_key
#       provider      = local.scaleway_s3_provider_name
#     },
#     {
#       kind          = "bucket"
#       alias         = local.c_segment_alias
#       endpoint      = local.scaleway_s3_endpoint
#       bucket        = local.c_segment_bucket_name
#       access_key_id = module.job.access_key_id
#       secret_key    = module.job.secret_key
#       provider      = local.scaleway_s3_provider_name
#     },
#     {
#       kind          = "bucket"
#       alias         = "destination"
#       endpoint      = local.scaleway_s3_endpoint
#       bucket        = local.destination_bucket_name
#       access_key_id = module.job.access_key_id
#       secret_key    = module.job.secret_key
#       provider      = local.scaleway_s3_provider_name
#     },
#     {
#       kind          = "bucket"
#       alias         = "reports"
#       endpoint      = local.scaleway_s3_endpoint
#       bucket        = "pigeon-cli-vmqjtz-reports"
#       access_key_id = module.job.access_key_id
#       secret_key    = module.job.secret_key
#       provider      = local.scaleway_s3_provider_name
#     }
#   ]


#   destination_bucket_name = "consolidate-o1rzfz-segment-2"
#   # subpath_name            = "2026-03-09-lunakx-protonmail-apple-id-backup"
#   # source_subpath          = "poisoned/${local.subpath_name}"
#   # destination_subpath     = local.subpath_name

#   // Non-configurable
#   instance_type          = "COMPUTE3-X8C-16G"
#   scaleway_s3_endpoint   = "https://s3.fr-par.scw.cloud"
#   job_name               = "${local.job_name_prefix}-${local.job_name_suffix}"

# }
