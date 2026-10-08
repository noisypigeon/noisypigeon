module "pigeon_jobs" {
  source = "https://pigeon.dev/modules/scaleway/pigeon-cluster/v0.2.1"

  cluster_config = {
    name_prefix = local.name_prefix
    project_id  = local.scaleway_project_id
    cockpit = {
      metrics_push_url = local.cockpit_metrics_url
      logs_push_url    = local.cockpit_logs_url
      token_secret     = local.cockpit_token_secret
    }
    shared_keyring = local.shared_keyring
    shared_permission_sets = ["ObjectStorageFullAccess"]
  }


  jobs = {
    consolidate-segment-1 = {
      job_commands = local.job_commands
      instance_type = "COMPUTE3-X8C-16G"
      block_volume_size = 50
      extra_permission_sets = []
      keyring = local.keyring
    }
  }
}
