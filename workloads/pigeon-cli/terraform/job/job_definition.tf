locals {
  name_prefix        = "import"
  name_suffix        = "some-name"

  source_bucket = {
    bucket_name      = ""
    bucket_endpoint  = ""
    access_key_id    = ""
    secret_key       = ""
    provider_name    = ""
  }

  destination_bucket = {
    bucket_name      = ""
    bucket_endpoint  = ""
    access_key_id    = ""
    secret_key       = ""
    provider_name    = ""
  }

  // Non-configurable
  job_name = "${local.name_prefix}-${local.name_suffix}"
  cockpit_config = {
    metrics_push_url = local.cockpit_metrics_url
    logs_push_url    = local.cockpit_logs_url
    token_secret     = local.cockpit_token_secret
  }
}
