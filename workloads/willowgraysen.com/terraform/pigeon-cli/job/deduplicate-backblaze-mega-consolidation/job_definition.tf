locals {
  job_name_prefix         = "deduplicate"
  job_name_suffix         = "backblaze-mega-consolidation"
  job_block_volume_size   = 800

  job_commands = [
    "cd pigeon-cli/ && mise run pigeon-release job run deduplicate --source-bucket source --remote-output destination --report-bucket reports --local-output /mnt/data --concurrency 8 --upload-concurrency 16 --yes"
  ]

  # job_commands = [
  #   "cd pigeon-cli/ && mise run pigeon-release job run import --source 'source:${local.source_subpath}/' --destination 'destination:${local.destination_subpath}/' --report-bucket reports --yes --local-output /mnt/data"
  # ]

  source_bucket_name      = "import-4ujtax-backblaze-mega-consolidation"
  destination_bucket_name = "deduplicate-p7d0kd-backblaze-mega-consolidation"
  # subpath_name            = "google-drive-computers-consolidation-2025-12-17"
  # source_subpath          = "poisoned/${local.subpath_name}"
  # destination_subpath     = local.subpath_name

  // Non-configurable
  instance_type          = "COMPUTE3-X8C-16G"
  scaleway_s3_endpoint   = "https://s3.fr-par.scw.cloud"
  job_name               = "${local.job_name_prefix}-${local.job_name_suffix}"

}
