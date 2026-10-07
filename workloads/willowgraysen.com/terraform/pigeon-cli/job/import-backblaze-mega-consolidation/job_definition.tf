locals {
  job_name_prefix         = "import"
  job_name_suffix         = "backblaze-mega-consolidation"
  job_block_volume_size   = 50

  job_commands = [
    "cd pigeon-cli/ && mise run pigeon-release job run import --source 'source:poisoned/mega-s4-consolidation-2025-12-13/' --destination 'destination:mega-s4-consolidation-2025-12-13/' --report-bucket reports --yes --local-output /mnt/data"
  ]

  source_bucket_name      = "import-ikbld8-backblaze"
  destination_bucket_name = "import-4ujtax-backblaze-mega-consolidation"

  // Non-configurable
  instance_type          = "COMPUTE3-X8C-16G"
  scaleway_s3_endpoint   = "https://s3.fr-par.scw.cloud"
  job_name               = "${local.job_name_prefix}-${local.job_name_suffix}"

}
