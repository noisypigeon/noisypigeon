locals {
  job_name_prefix         = "consolidate"
  job_name_suffix         = "segment-1"
  job_block_volume_size   = 50

  job_commands = [
    "mkdir /mnt/data/segment_b && cd pigeon-cli/ && mise run pigeon-release job run import --source '${local.b_segment_alias}:' --destination 'destination:${local.b_segment_bucket_name}/' --report-bucket reports --yes --local-output /mnt/data/segment_b",
    "mkdir /mnt/data/segment_c && mise run pigeon-release job run import --source '${local.c_segment_alias}:' --destination 'destination:${local.c_segment_bucket_name}/' --report-bucket reports --yes --local-output /mnt/data/segment_c",
    "mkdir /mnt/data/segment_d && mise run pigeon-release job run import --source '${local.d_segment_alias}:' --destination 'destination:${local.d_segment_bucket_name}/' --report-bucket reports --yes --local-output /mnt/data/segment_d"
  ]

  # a_segment_bucket_name = "deduplicate-uqpdu7-backblaze-fastmail-consolidation"
  # a_segment_alias = "fastmail"
  b_segment_bucket_name = "deduplicate-p7d0kd-backblaze-mega-consolidation"
  b_segment_alias = "mega"
  c_segment_bucket_name = "deduplicate-qb27gx-macbook"
  c_segment_alias = "macbook"
  d_segment_bucket_name = "deduplicate-h4w903-backblaze-computer-snapshots"
  d_segment_alias = "snapshots"

  # Segments
  keyring = [
    # {
    #   kind          = "bucket"
    #   alias         = local.a_segment_alias
    #   endpoint      = local.scaleway_s3_endpoint
    #   bucket        = local.a_segment_bucket_name
    #   access_key_id = module.job.access_key_id
    #   secret_key    = module.job.secret_key
    #   provider      = local.scaleway_s3_provider_name
    # },
    {
      kind          = "bucket"
      alias         = local.b_segment_alias
      endpoint      = local.scaleway_s3_endpoint
      bucket        = local.b_segment_bucket_name
      access_key_id = module.job.access_key_id
      secret_key    = module.job.secret_key
      provider      = local.scaleway_s3_provider_name
    },
    {
      kind          = "bucket"
      alias         = local.c_segment_alias
      endpoint      = local.scaleway_s3_endpoint
      bucket        = local.c_segment_bucket_name
      access_key_id = module.job.access_key_id
      secret_key    = module.job.secret_key
      provider      = local.scaleway_s3_provider_name
    },
    {
      kind          = "bucket"
      alias         = local.d_segment_alias
      endpoint      = local.scaleway_s3_endpoint
      bucket        = local.d_segment_bucket_name
      access_key_id = module.job.access_key_id
      secret_key    = module.job.secret_key
      provider      = local.scaleway_s3_provider_name
    },
    {
      kind          = "bucket"
      alias         = "destination"
      endpoint      = local.scaleway_s3_endpoint
      bucket        = local.destination_bucket_name
      access_key_id = module.job.access_key_id
      secret_key    = module.job.secret_key
      provider      = local.scaleway_s3_provider_name
    },
    {
      kind          = "bucket"
      alias         = "reports"
      endpoint      = local.scaleway_s3_endpoint
      bucket        = "pigeon-cli-vmqjtz-reports"
      access_key_id = module.job.access_key_id
      secret_key    = module.job.secret_key
      provider      = local.scaleway_s3_provider_name
    }
  ]


  destination_bucket_name = "consolidate-n41ilf-segment-1"
  # subpath_name            = "2026-03-09-lunakx-protonmail-apple-id-backup"
  # source_subpath          = "poisoned/${local.subpath_name}"
  # destination_subpath     = local.subpath_name

  // Non-configurable
  instance_type          = "COMPUTE3-X8C-16G"
  scaleway_s3_endpoint   = "https://s3.fr-par.scw.cloud"
  job_name               = "${local.job_name_prefix}-${local.job_name_suffix}"

}
