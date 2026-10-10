locals {
  enable_bastion      = false
  public_gateway_type = "VPC-GW-L"
  enable_private_network = false
  enable_public_gateway = false
  jobs = [
    {
      job_name              = "rclone-copy-dj-do-to-b2"
      instance_type         = "COMPUTE3-X8C-16G"
      block_volume_size     = 50
      block_volume_iops     = 5000
      enable_private_network = false
      enable_ipv4 = true
      extra_permission_sets = []
      job_commands = [
        "cd pigeon-cli/",
        "mise run pigeon-release job run rclone copy --source-path 'source:' --destination-path 'destination:' --report-bucket reports --local-output /mnt/data/a --yes --transfers 16 --checkers 32",
      ]
      keyring = {
        source = {
          kind          = "bucket"
          endpoint      = "https://tor1.digitaloceanspaces.com"
          bucket        = local.do_dj_bucket_name
          access_key_id = local.do_dj_access_key_id
          secret_key    = local.do_dj_secret_key
          provider      = "DigitalOcean"
        }
        destination = {
          kind          = "bucket"
          endpoint      = "https://s3.ca-east-006.backblazeb2.com"
          bucket        = local.bb_dj_bucket_name
          access_key_id = local.bb_dj_access_key_id
          secret_key    = local.bb_dj_secret_key
          provider      = "Other"
        }
      }
    },
    {
      job_name              = "rclone-copy-snapshot-b2"
      instance_type         = "COMPUTE3-X8C-16G"
      block_volume_size     = 50
      block_volume_iops     = 5000
      enable_private_network = false
      enable_ipv4 = true
      extra_permission_sets = []
      job_commands = [
        "cd pigeon-cli/",
        "mise run pigeon-release job run rclone copy --source-path 'source:' --destination-path 'destination:' --report-bucket reports --local-output /mnt/data/a --yes --transfers 32 --checkers 64",
      ]
      keyring = {
        source = {
          kind          = "bucket"
          endpoint      = "https://s3.fr-par.scw.cloud"
          bucket        = "pigeon-3gpf9n-deduplicate"
          provider      = "Scaleway"
        }
        destination = {
          kind          = "bucket"
          endpoint      = "https://s3.ca-east-006.backblazeb2.com"
          bucket        = local.bb_snapshot_bucket_name
          access_key_id = local.bb_snapshot_access_key_id
          secret_key    = local.bb_snapshot_secret_key
          provider      = "Other"
        }
      }
    }
  ]
}
