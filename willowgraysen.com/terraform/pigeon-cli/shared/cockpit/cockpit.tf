module "cockpit" {
  source = "https://pigeon.dev/modules/scaleway/cockpit-observability/v0.1.0"

  name       = local.name
  project_id = local.scaleway_project_id
}

output "metrics_push_url" {
  description = "Shared Mimir ingest endpoint -- hand-copy into the repo's root .env as PIGEON_COCKPIT_METRICS_PUSH_URL"
  value       = module.cockpit.metrics_push_url
}

output "logs_push_url" {
  description = "Shared Loki ingest endpoint -- hand-copy into the repo's root .env as PIGEON_COCKPIT_LOGS_PUSH_URL"
  value       = module.cockpit.logs_push_url
}

output "token_secret" {
  description = "Shared push token -- hand-copy into the repo's root .env as PIGEON_COCKPIT_TOKEN_SECRET"
  value       = module.cockpit.token_secret
  sensitive   = true
}
