# locals {
#   name_prefix = "pigeon-cli"
#   name_suffix = "consolidate-segment-2"

#   job_commands = [
#     "cd pigeon-cli",
#     "mkdir /mnt/data/a && mise run pigeon-release job run import --source '${local.keyring_alias.media}:' --destination '${local.keyring_alias.destination}:${local.keyring.media.bucket}/' --report-bucket ${local.keyring_alias.reports} --yes --local-output /mnt/data/a --transfers 8 --checkers 16",
#     "mkdir /mnt/data/b && mise run pigeon-release job run import --source '${local.keyring_alias.google}:' --destination '${local.keyring_alias.destination}:${local.keyring.google.bucket}/' --report-bucket ${local.keyring_alias.reports} --yes --local-output /mnt/data/b --transfers 8 --checkers 16",
#     "mkdir /mnt/data/c && mise run pigeon-release job run import --source '${local.keyring_alias.t7}:' --destination '${local.keyring_alias.destination}:${local.keyring.t7.bucket}/' --report-bucket ${local.keyring_alias.reports} --yes --local-output /mnt/data/c --transfers 8 --checkers 16",
#   ]

#   keyring_alias = {
#     media = "media"
#     google = "google"
#     t7 = "t7"
#     destination = "destination"
#     reports = "reports"
#   }

#   keyring = {
#     media = {
#       kind     = "bucket"
#       endpoint = "https://s3.fr-par.scw.cloud"
#       bucket   = "deduplicate-fx7k2k-backblaze-media"
#       provider = "Scaleway"
#     }
#     google = {
#       kind     = "bucket"
#       endpoint = "https://s3.fr-par.scw.cloud"
#       bucket   = "deduplicate-0msi9l-backblaze-google-consolidation"
#       provider = "Scaleway"
#     }
#     t7 = {
#       kind     = "bucket"
#       endpoint = "https://s3.fr-par.scw.cloud"
#       bucket   = "deduplicate-gzoc4o-backblaze-t7-email-consolidation"
#       provider = "Scaleway"
#     }
#     destination = {
#       kind     = "bucket"
#       endpoint = "https://s3.fr-par.scw.cloud"
#       bucket   = "consolidate-o1rzfz-segment-2"
#       provider = "Scaleway"
#     }
#   }

#   shared_keyring = {
#     reports = {
#       kind     = "bucket"
#       endpoint = "https://s3.fr-par.scw.cloud"
#       bucket   = "pigeon-cli-vmqjtz-reports"
#       provider = "Scaleway"
#     }
#   }
# }
