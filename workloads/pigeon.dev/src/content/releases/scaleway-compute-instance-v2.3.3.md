+++
title = "scaleway/compute-instance v2.3.3"
date = 2026-10-03T12:00:00-07:00
slug = "scaleway-compute-instance-v2.3.3"
description = "Add a shared Cockpit metrics/logs store for pigeon-cli instances"
+++

Adds `workloads/pigeon-cli/terraform/observability/` (ADR-0103): one shared `scaleway_cockpit_source` (metrics) + one (logs) + one push token for every pigeon-cli compute instance, replacing ADR-0102's per-leaf private Cockpit sources now that pigeon-cli (`noisypigeon/pigeon-cli` ADR-0093) carries real `pigeon_job`/`instance` identity on every metric and log line — there's no longer a reason for each instance to have its own separate data store.

Fanned out via three new `workloads/root.hcl` generated locals (`PIGEON_COCKPIT_METRICS_PUSH_URL`/`PIGEON_COCKPIT_LOGS_PUSH_URL`/`PIGEON_COCKPIT_TOKEN_SECRET`, hand-copied from this leaf's outputs into the shared root `.env`), following this repo's only established sharing convention — confirmed via research that this repo has never used a Terragrunt `dependency` block anywhere. Deliberately not `ENV_SW_`-prefixed, to avoid colliding with `root.hcl`'s generic per-bucket-name secret-promotion mechanism (the exact collision class ADR-0098 already navigated around once).

Also fixes two `modules/scaleway/compute-instance` Alloy config gaps that only matter once every instance shares one store:
- The default Prometheus `instance` label (the scrape address, identical on every host) is overridden to the real hostname via `discovery.relabel`.
- A new `loki.process` stage extracts pigeon-cli's own JSON `timestamp` field as Loki's real entry time (fixing the redundant double-timestamp display previously reported) and extracts `command`/`instance` into real Loki labels.

Not done here (left to the user, see the ADR's Out of scope): migrating `deduplication/macbook-scratch`'s existing private Cockpit resources over to the shared ones — that leaf has unrelated uncommitted local changes right now.

Full details: [docs/adr/0103-shared-cockpit-store.md](docs/adr/0103-shared-cockpit-store.md)

## Test plan

- [x] `terraform validate`/`fmt -check` clean on the module and new leaf
- [x] Real `terragrunt plan` against this project's Scaleway credentials for the new leaf: 3 to add, 0 to change/destroy
- [x] Confirmed an unrelated leaf (`workloads/blog/terraform`) still plans clean (`No changes`) after the `root.hcl` addition
- [ ] Alloy river syntax (`discovery.relabel`, `stage.json` JMESPath expressions) not independently verified against a real `alloy` binary — flagged explicitly in the ADR, to check at first real apply

[#132](https://github.com/noisypigeon/noisypigeon/pull/132)
