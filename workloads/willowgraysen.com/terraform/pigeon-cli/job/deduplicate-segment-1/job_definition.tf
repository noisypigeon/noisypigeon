locals {
  name_prefix = "pigeon-cli"
  name_suffix = "deduplicate-segment-1"

  job_commands = [
    "cd pigeon-cli",
    "mkdir /mnt/data/a && mise run pigeon-release job run deduplicate --source-bucket source --remote-output destination --report-bucket reports --local-output /mnt/data/a --concurrency 8 --upload-concurrency 16 --yes"
  ]

  # keyring_alias = {
  #   source = "source"
  #   destination = "source"
  #   reports = "reports"
  # }

  keyring = {
    source = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "consolidate-n41ilf-segment-1"
      provider = "Scaleway"
    }
    destination = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "deduplicate-ooov48-segment-1"
      provider = "Scaleway"
    }
  }

  shared_keyring = {
    reports = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "pigeon-cli-vmqjtz-reports"
      provider = "Scaleway"
    }
  }




  ##### SECOND JOB
  secondary_keyring = {
    source = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "consolidate-o1rzfz-segment-2"
      provider = "Scaleway"
    }
    destination = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "deduplicate-2q8al4-segment-2"
      provider = "Scaleway"
    }
  }
}
