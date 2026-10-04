locals {
  namespace          = "deduplication"
  name               = "poisoned-mega-consolidation"
  source_bucket_name = "import-yxtsyz-poisoned-mega-storage-consolidation"

  cockpit = {
    metrics_push_url = local.cockpit_metrics_url
    logs_push_url    = local.cockpit_logs_url
    token_secret     = local.cockpit_token_secret
  }
}
