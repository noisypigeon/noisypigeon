locals {
  enable_bastion = false
  jobs = [
    {
      job_name              = "deduplicate-segment-2"
      instance_type         = "COMPUTE3-X8C-16G"
      block_volume_size     = 3000
      extra_permission_sets = []
      job_commands = [
        "cd pigeon-cli/",
        "mkdir /mnt/data/a",
        "mise run pigeon-release job run deduplicate --source-bucket source --remote-output destination --report-bucket reports --local-output /mnt/data/a --concurrency 8 --upload-concurrency 16 --yes"
      ]
      keyring = {
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
    },
    {
      job_name              = "consolidate-segment-1"
      instance_type         = "COMPUTE3-X8C-16G"
      block_volume_size     = 50
      block_volume_iops     = 5000
      extra_permission_sets = []
      job_commands = [
        "cd pigeon-cli/",
        "mkdir /mnt/data/a",
        "mise run pigeon-release job run import --source 'source:' --destination 'destination:deduplicate-ooov48-segment-1/' --report-bucket reports --yes --local-output /mnt/data/a --transfers 32 --checkers 64"
      ]
      keyring = {
        source = {
          kind     = "bucket"
          endpoint = "https://s3.fr-par.scw.cloud"
          bucket   = "deduplicate-ooov48-segment-1"
          provider = "Scaleway"
        }
        destination = {
          kind     = "bucket"
          endpoint = "https://s3.fr-par.scw.cloud"
          bucket   = "pigeon-oqxg8e-consolidate"
          provider = "Scaleway"
        }
      }
    }
  ]
}
