# One shared Cockpit metrics/logs source + push token for every pigeon-cli
# compute instance (docs/adr/0103-shared-cockpit-store.md) -- disambiguated
# at query time by the pigeon_job/instance labels pigeon-cli (ADR-0093) and
# Alloy (compute-instance's cockpit wiring) already attach, rather than by
# giving each instance its own private Cockpit source the way the original
# deduplication/macbook-scratch leaf did.

module "cockpit" {
  source = "https://noisypigeon.com/modules/scaleway/cockpit-observability/v0.1.0"

  name       = "pigeon-cli"
  project_id = local.scaleway_project_id_noisypigeon
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
