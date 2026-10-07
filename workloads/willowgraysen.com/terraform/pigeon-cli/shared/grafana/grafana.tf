# grafana's required_providers entry lives in workloads/willowgraysen.com/root.hcl's
# generate "provider" block alongside cloudflare/scaleway -- Terraform allows only one
# required_providers block per module, and that one is already generated into every
# leaf here (ADR-0135).

data "scaleway_cockpit_grafana" "this" {
  project_id = local.scaleway_project_id
}

provider "grafana" {
  url  = data.scaleway_cockpit_grafana.this.grafana_url
  auth = "anonymous"

  http_headers = {
    "X-Auth-Token" = module.iam_api_key.secret_key
  }
}

# Scaleway's Grafana lazily provisions an IAM identity's role on its first
# API access -- there is no Terraform resource for this yet (ADR-0135), so
# this pings the org endpoint once per IAM application (not per key
# rotation) before any dashboard is created against it.
resource "terraform_data" "grafana_first_access" {
  input = module.iam_api_key.secret_key

  triggers_replace = {
    application_id = module.iam_application.id
  }

  provisioner "local-exec" {
    command = "curl -sf -H \"X-Auth-Token: ${self.input}\" \"${data.scaleway_cockpit_grafana.this.grafana_url}/api/org\" >/dev/null"
  }
}

locals {
  dashboard_files = fileset("${path.module}/dashboards", "*.json")
}

module "grafana_dashboard" {
  source     = "https://pigeon.dev/modules/scaleway/grafana-dashboard/v0.1.0"
  depends_on = [terraform_data.grafana_first_access]

  folder_title = "pigeon-cli"
  dashboards = {
    for f in local.dashboard_files :
    trimsuffix(f, ".json") => { config_json = file("${path.module}/dashboards/${f}") }
  }
}
