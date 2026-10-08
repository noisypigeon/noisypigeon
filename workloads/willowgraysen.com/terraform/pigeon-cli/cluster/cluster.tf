module "cluster" {
  source = "https://pigeon.dev/modules/scaleway/pigeon-cluster/v0.3.2"

  cluster_config = {
    name_prefix = "pigeon-cli"
    project_id  = local.scaleway_project_id
    cockpit = {
      metrics_push_url = local.cockpit_metrics_url
      logs_push_url    = local.cockpit_logs_url
      token_secret     = local.cockpit_token_secret
    }
    shared_keyring = {
      reports = {
        kind = "bucket"
        endpoint = "https://s3.fr-par.scw.cloud"
        bucket   = "pigeon-cli-vmqjtz-reports"
        provider = "Scaleway"
      }
    }
    shared_permission_sets = ["ObjectStorageFullAccess"]
  }

  jobs = local.jobs
}
