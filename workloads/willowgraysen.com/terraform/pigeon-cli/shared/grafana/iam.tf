module "iam_application" {
  source = "https://noisypigeon.com/modules/scaleway/iam-application/v0.1.0"
  name   = "pigeon-cli-grafana"
}

module "iam_policy" {
  source = "https://noisypigeon.com/modules/scaleway/iam-policy/v4.0.0"
  name   = "pigeon-cli-grafana-policy"

  application_id          = module.iam_application.id
  project_ids             = [local.scaleway_project_id]
  project_permission_sets = ["ObservabilityGrafanaEditor"]
}

module "iam_api_key" {
  source = "https://noisypigeon.com/modules/scaleway/iam-api-key/v0.2.0"

  application_id     = module.iam_application.id
  default_project_id = local.scaleway_project_id
}
