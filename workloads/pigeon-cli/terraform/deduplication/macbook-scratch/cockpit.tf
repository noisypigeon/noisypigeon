resource "scaleway_cockpit_source" "pigeon_metrics" {
  project_id     = local.scaleway_project_id_noisypigeon
  name           = "${local.job_name}-${local.bucket_alias}-metrics"
  type           = "metrics"
  retention_days = 31
}

resource "scaleway_cockpit_source" "pigeon_logs" {
  project_id     = local.scaleway_project_id_noisypigeon
  name           = "${local.job_name}-${local.bucket_alias}-logs"
  type           = "logs"
  retention_days = 31
}

resource "scaleway_cockpit_token" "pigeon_push" {
  project_id = local.scaleway_project_id_noisypigeon
  name       = "${local.job_name}-${local.bucket_alias}-push"

  scopes {
    write_metrics = true
    write_logs    = true
  }
}

# No grafana-user resource: the installed scaleway/scaleway provider
# (v2.84.0) has no `scaleway_cockpit_grafana_user` resource type -- Grafana
# dashboard access for this project's Cockpit is via the Scaleway Console
# (Project -> Cockpit -> Open dashboards), authenticated with your own
# Scaleway account/IAM, not a Terraform-managed login.
