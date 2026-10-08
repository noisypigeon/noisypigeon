locals {
  name_prefix = "pigeon-cli"
  name_suffix = "consolidate-segment-1"

  job_commands = [
    "cd pigeon-cli",
    "mkdir /mnt/data/a && mise run pigeon-release job run import --source '${local.keyring_alias.fastmail}:' --destination '${local.keyring_alias.destination}:${local.keyring.fastmail.bucket}/' --report-bucket ${local.keyring_alias.reports} --yes --local-output /mnt/data/a",
    "mkdir /mnt/data/b && mise run pigeon-release job run import --source '${local.keyring_alias.mega}:' --destination '${local.keyring_alias.destination}:${local.keyring.mega.bucket}/' --report-bucket ${local.keyring_alias.reports} --yes --local-output /mnt/data/b",
    "mkdir /mnt/data/c && mise run pigeon-release job run import --source '${local.keyring_alias.macbook}:' --destination '${local.keyring_alias.destination}:${local.keyring.macbook.bucket}/' --report-bucket ${local.keyring_alias.reports} --yes --local-output /mnt/data/c",
    "mkdir /mnt/data/d && mise run pigeon-release job run import --source '${local.keyring_alias.snapshots}:' --destination '${local.keyring_alias.destination}:${local.keyring.snapshots.bucket}/' --report-bucket ${local.keyring_alias.reports} --yes --local-output /mnt/data/d"
  ]

  keyring_alias = {
    fastmail = "fastmail"
    mega = "mega"
    macbook = "macbook"
    snapshots = "snapshots"
    destination = "destination"
    reports = "reports"
  }

  fastmail_alias = "fastmail"
  mega_alias = "mega"
  macbook_alias = "macbook"
  snapshots_alias = "snapshots"

  keyring = {
    fastmail = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "deduplicate-uqpdu7-backblaze-fastmail-consolidation"
      provider = "Scaleway"
    }
    mega = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "deduplicate-p7d0kd-backblaze-mega-consolidation"
      provider = "Scaleway"
    }
    macbook = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "deduplicate-qb27gx-macbook"
      provider = "Scaleway"
    }
    snapshots = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "deduplicate-h4w903-backblaze-computer-snapshots"
      provider = "Scaleway"
    }
    destination = {
      kind     = "bucket"
      endpoint = "https://s3.fr-par.scw.cloud"
      bucket   = "consolidate-n41ilf-segment-1"
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
}
