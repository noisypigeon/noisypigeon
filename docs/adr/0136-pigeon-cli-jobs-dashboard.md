# ADR-0136: pigeon-cli jobs dashboard (phases, resource usage, logs)

- Status: Accepted
- Date: 2026-10-07
- Author: Willow Graysen

## Context

ADR-0135 shipped Grafana-dashboards-as-code against Scaleway Cockpit and dropped in `dashboards/overview.json` as a minimal placeholder — just enough to prove the pipeline end-to-end (CPU, memory, a logs panel). Now that it's live, the placeholder needs to become a real, useful dashboard for watching `pigeon-cli` job runs: phase-by-phase progress, host resource usage, and logs, all split per instance.

`pigeon_job_phase_total` (defined in `noisypigeon/pigeon-cli`'s `src/observability/metrics.rs`) is a **counter** with labels `pigeon_job`, `phase`, `outcome`, `instance`, `source_bucket`. It resets to 0 on every `pigeon` invocation — `pigeon` is a short-lived CLI, not a daemon, so a raw/cumulative value is meaningless across runs; `increase()`/`rate()` (both reset-aware) are the correct query shape.

`pigeon-cli` also exposes process-scoped resource gauges (`pigeon_resource_cpu_percent`, `pigeon_resource_mem_bytes`, `pigeon_resource_disk_{read,written}_bytes_total`), but since every `pigeon-cli` job runs on its own dedicated compute instance (one job per host, per the `job/<name>/` leaf convention), host-level and process-level numbers are practically identical. `node_exporter` (via Alloy's `prometheus.exporter.unix "node"`, default collector set, 60s scrape) already exposes filesystem (`node_filesystem_*`) and network (`node_network_*`) metrics with no Alloy config changes needed — this is purely a dashboard JSON change.

Both Cockpit metrics and logs sources are capped at 31-day retention (`templates/terraform/scaleway/cockpit-observability`) — a hard ceiling on any default/allowed time range.

## Decision

### Edit `dashboards/overview.json` in place

The file is edited, not replaced/renamed — `grafana.tf`'s `fileset`-driven `for` loop keys the Terraform map (and thus the dashboard's resource address) off the filename stem, so renaming would needlessly recreate the dashboard (new UID) even though this is the same conceptual "pigeon-cli overview" dashboard, now filled in for real instead of being a placeholder.

### Job phases panel: `increase()`, not `rate()`

`sum by (phase, instance) (increase(pigeon_job_phase_total{instance=~"$instance"}[$__rate_interval]))`, one line per phase/instance combination (`legendFormat: "{{phase}} - {{instance}}"`). `increase()` shows "how many phase completions in this window" — intuitive for a sparse, bursty, per-run-resetting counter, where `rate()`'s per-second framing would produce tiny, less legible fractional numbers. `$__rate_interval` (Grafana's built-in, scrape-interval-aware variable) is used instead of a hardcoded window since the `pigeon_cli` scrape interval (15s) differs from `node`'s (60s).

### Resource panels: host-level, not process-level

CPU, memory, and disk panels query `node_exporter` metrics (host-level), not pigeon-cli's own process-scoped gauges, since every job runs on its own dedicated instance and the two are practically equivalent in that setup — and network usage has no process-level equivalent in pigeon-cli at all, so host-level keeps all panels on one consistent data source.

### Disk: both space utilization and I/O throughput

Two separate panels, since "disk usage" is ambiguous between "is it filling up" and "how hard is it working": space utilization (`node_filesystem_avail_bytes` / `node_filesystem_size_bytes`, split by instance *and* mountpoint since a job instance can have an attached block volume (ADR-0120) separate from its root disk — collapsing mountpoints would hide which one is actually filling up) and I/O throughput (`node_disk_read_bytes_total` / `node_disk_written_bytes_total`, rate, split by instance).

### Network usage panel

`node_network_receive_bytes_total` / `node_network_transmit_bytes_total`, rate, split by instance, loopback (`device!="lo"`) excluded.

## Consequences

- The placeholder dashboard becomes a real one: job-phase progress, full host resource usage (CPU/memory/disk space/disk I/O/network), and logs, all per-instance.
- No `templates/terraform/` module is touched and no Terraform interface changes — this is a dashboard-content-only change, so no `release:*` label applies.
- The dashboard's Terraform resource address and UID are unchanged (same map key), so any existing bookmark/link to it keeps working.

## Out of scope

- pigeon-cli's own process-scoped resource metrics as an alternative dashboard — deferred until (if ever) a host stops being single-job-dedicated and host-level numbers stop being representative.
- Cockpit Alertmanager alerting on any of these panels — already tracked by [#218](https://github.com/noisypigeon/noisypigeon/issues/218) per ADR-0135, unaffected by this change.
