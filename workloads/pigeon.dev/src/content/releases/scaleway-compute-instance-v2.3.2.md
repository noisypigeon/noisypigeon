+++
title = "scaleway/compute-instance v2.3.2"
date = 2026-10-03T12:00:00-07:00
slug = "scaleway-compute-instance-v2.3.2"
description = "Fix doubled Cockpit push path and non-resilient log tailing in compute-instance"
+++

Two confirmed bugs found applying v2.3.1's `cockpit` wiring to a real test-bed instance and inspecting `alloy`'s live logs:

**Doubled push path, every push 404ing.** `scaleway_cockpit_source.push_url` is already the complete ingest endpoint ("Ingest endpoint for transmitting data" per its schema), not a bare host. `instance.tf`'s Alloy config appended `/api/v1/push`/`/loki/api/v1/push` on top of it a second time, producing URLs like `.../metrics.cockpit.fr-par.scw.cloud/api/v1/push/api/v1/push`. Confirmed via `journalctl -u alloy`: `level=error msg="non-recoverable error" ... err="server returned HTTP status 404 Not Found: not found"`, repeating every minute with growing `failedSampleCount`. Fix: use `push_url` directly, no appended path.

**Log file never got picked up.** `loki.source.file "pigeon_logs"` used a static inline `targets = [{"__path__" = "/var/log/pigeon/pigeon.jsonl"}]`. Alloy starts at first boot, before any `pigeon` job has run and created that file — confirmed via `journalctl`: `error="failed to tail file, stat failed: stat /var/log/pigeon/pigeon.jsonl: no such file or directory"`, logged as `"failed to create source, skipping"`, with no further retry visible afterward. Fix: route through `local.file_match`, which periodically re-globs the path and feeds `loki.source.file` updated targets as the file appears — the standard Alloy idiom for exactly this race.

Patch release — no input/output/behavior change beyond fixing both previously-broken cases.

[#131](https://github.com/noisypigeon/noisypigeon/pull/131)
