+++
title = "scaleway/compute-instance v2.3.0"
date = 2026-10-03T12:00:00-07:00
slug = "scaleway-compute-instance-v2.3.0"
description = "Add Scaleway Cockpit wiring to compute-instance via Grafana Alloy"
+++

Adds a new optional `cockpit` input to `scaleway/compute-instance` (ADR-0102): when set, the module writes `/etc/alloy/config.alloy` and installs Grafana Alloy on first boot, scraping `pigeon-cli`'s local Prometheus metrics endpoint (`noisypigeon/pigeon-cli` ADR-0092) and tailing its JSONL log (pinned to a stable `/var/log/pigeon/pigeon.jsonl` path via a new `PIGEON_LOG_DIR` export), forwarding both to a Scaleway Cockpit project's metrics/logs sources. A whole-instance `node_exporter` scrape is included as a low-cost addition once Alloy is installed anyway.

`cockpit` is `null` by default (fully opt-in) and only used when `profile = "pigeon-cli"`, matching the existing `buckets`/`keyring_entries` gating pattern. Applying this to an existing instance will force-replace it (cloud-init content change, per this module's existing `replace_triggered_by` behavior) — something to call out explicitly in whichever leaf PR actually sets `cockpit`.

The actual `scaleway_cockpit_source`/`scaleway_cockpit_token` resources and wiring `cockpit = {...}` into a real leaf are a deliberate follow-up, not part of this PR — they need this module's new tag to reference.

See [docs/adr/0102-compute-instance-cockpit-alloy.md](docs/adr/0102-compute-instance-cockpit-alloy.md) for full rationale, including one unverified assumption (the Loki-side auth header) flagged explicitly in the ADR's Out of scope section.

[#128](https://github.com/noisypigeon/noisypigeon/pull/128)
