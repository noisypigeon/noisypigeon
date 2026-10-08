# locals {
#   name_prefix = "pigeon-cli"
#   name_suffix = "cluster"

#   shared_keyring = {
#     reports = {
#       kind     = "bucket"
#       endpoint = "https://s3.fr-par.scw.cloud"
#       bucket   = "pigeon-cli-vmqjtz-reports"
#       provider = "Scaleway"
#     }
#   }




#   ##### SECOND JOB
#   secondary_keyring = {
#     source = {
#       kind     = "bucket"
#       endpoint = "https://s3-vpc.fr-par.scw.eu"
#       bucket   = "consolidate-o1rzfz-segment-2"
#       provider = "Scaleway"
#     }
#     destination = {
#       kind     = "bucket"
#       endpoint = "https://s3-vpc.fr-par.scw.eu"
#       bucket   = "deduplicate-2q8al4-segment-2"
#       provider = "Scaleway"
#     }
#   }
# }
