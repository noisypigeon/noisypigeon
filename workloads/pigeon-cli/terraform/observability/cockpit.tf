# One shared Cockpit metrics/logs source + push token for every pigeon-cli
# compute instance (docs/adr/0103-shared-cockpit-store.md) -- disambiguated
# at query time by the pigeon_job/instance labels pigeon-cli (ADR-0093) and
# Alloy (compute-instance's cockpit wiring) already attach, rather than by
# giving each instance its own private Cockpit source the way the original
# deduplication/macbook-scratch leaf did.

resource "scaleway_cockpit_source" "pigeon_metrics" {
  project_id     = local.scaleway_project_id_noisypigeon
  name           = "pigeon-cli-metrics"
  type           = "metrics"
  retention_days = 31
}

resource "scaleway_cockpit_source" "pigeon_logs" {
  project_id     = local.scaleway_project_id_noisypigeon
  name           = "pigeon-cli-logs"
  type           = "logs"
  retention_days = 31
}

resource "scaleway_cockpit_token" "pigeon_push" {
  project_id = local.scaleway_project_id_noisypigeon
  name       = "pigeon-cli-push"

  scopes {
    write_metrics = true
    write_logs    = true
  }
}

output "metrics_push_url" {
  description = "Shared Mimir ingest endpoint -- hand-copy into the repo's root .env as PIGEON_COCKPIT_METRICS_PUSH_URL"
  value       = scaleway_cockpit_source.pigeon_metrics.push_url
}

output "logs_push_url" {
  description = "Shared Loki ingest endpoint -- hand-copy into the repo's root .env as PIGEON_COCKPIT_LOGS_PUSH_URL"
  value       = scaleway_cockpit_source.pigeon_logs.push_url
}

output "token_secret" {
  description = "Shared push token -- hand-copy into the repo's root .env as PIGEON_COCKPIT_TOKEN_SECRET"
  value       = scaleway_cockpit_token.pigeon_push.secret_key
  sensitive   = true
}
