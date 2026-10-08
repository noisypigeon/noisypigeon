# locals {
#   job_commands = [
#     "cd pigeon-cli",
#     "mkdir /mnt/data/a && mise run pigeon-release job run deduplicate --source-bucket source --remote-output destination --report-bucket reports --local-output /mnt/data/a --concurrency 8 --upload-concurrency 16 --yes"
#   ]

#   keyring = {
#     source = {
#       kind     = "bucket"
#       endpoint = "https://s3.fr-par.scw.cloud"
#       bucket   = "consolidate-n41ilf-segment-1"
#       provider = "Scaleway"
#     }
#     destination = {
#       kind     = "bucket"
#       endpoint = "https://s3.fr-par.scw.cloud"
#       bucket   = "deduplicate-ooov48-segment-1"
#       provider = "Scaleway"
#     }
#   }
# }
