locals {
  enable_bastion      = true
  public_gateway_type = "VPC-GW-M"
  enable_private_network = true
  enable_public_gateway = true
  jobs = [
    {
      job_name              = "transform-mov-to-mp4"
      instance_type         = "COMPUTE3-X8C-16G"
      block_volume_size     = 500
      block_volume_iops     = 15000
      enable_private_network = true
      enable_transcoding = true
      enable_ipv4 = false
      extra_permission_sets = []
      job_commands = [
        "cd pigeon-cli/",
        "mise run pigeon-release job run transform --input-file-type=mov --source-path 'source:mov/' --destination-path 'destination:mp4/' --report-bucket reports --local-output /mnt/data/a --non-interactive --concurrency 14 --transfers 16 --checkers 32",
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
          endpoint      = "https://s3.fr-par.scw.cloud"
          bucket        = "pigeon-spc6f1-transform"
          provider      = "Scaleway"
        }
      }
    }
  ]
}

# "mise run pigeon-release job run rclone copy --source-path 'source:' --destination-path 'destination:' --report-bucket reports --local-output /mnt/data/a --yes --transfers 16 --checkers 32",
