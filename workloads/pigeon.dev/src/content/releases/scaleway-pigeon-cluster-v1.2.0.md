+++
title = "scaleway/pigeon-cluster v1.2.0"
date = 2026-10-09T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v1.2.0"
description = "Add per-job network opt-out and independent Private Network/Public Gateway toggles to pigeon-cluster"
+++

Every job in a `pigeon-cluster` fleet was forced onto the cluster's shared Private Network with no public IP (ADR-0145/0146), and that shared Private Network/Public Gateway had no lifecycle independent of the cluster as a whole — it was all-or-nothing.

`jobs` gains two new optional fields:

- `enable_private_network` (default `true`, unchanged behavior). `false` makes this job a plain, undecorated `compute-instance` call — no private NIC, no dependency on the cluster's shared Private Network/Gateway at all, with its own public IPv4 as its only network path.
- `enable_ipv4` (default `false`) — reinstates the per-job public-IP override removed in `v1.0.0`. A job that keeps its Private Network attachment can now also request its own public IP; note this still doesn't help with *inbound* SSH reachability while the cluster's gateway is pushing a default route (the ADR-0146 finding), so it's primarily useful once `enable_public_gateway = false` or for outbound-only use. A job with `enable_private_network = false` always gets a public IP regardless of this field, since it would otherwise have no network path at all.

`cluster_config` gains two new optional fields, both defaulting `true`:

- `enable_private_network` — tear down the cluster's shared Private Network (and its Gateway-Network attachment) once no job needs it anymore, independent of the Public Gateway.
- `enable_public_gateway` — tear down the metered Public Gateway independent of the Private Network, e.g. once nothing needs internet/private-Object-Storage egress.

A new `validation` block requires both of the above to be `true` whenever `enable_bastion` is `true`, since the bastion is only reachable through the Gateway's PAT rule onto the shared Private Network.

The four previously-unconditional shared resources (`scaleway_vpc_private_network.jobs`, `scaleway_vpc_public_gateway_ip.jobs`, `scaleway_vpc_public_gateway.jobs`, `scaleway_vpc_gateway_network.jobs`) move to `count`-gated, each protected by a `moved` block (same precedent as `compute-instance`'s own `enabled` kill switch, ADR-0126), so no existing caller's state breaks.

Purely additive — every new field defaults to reproducing today's exact resource graph for any caller that sets nothing new. The one real consumer, `workloads/willowgraysen.com/terraform/pigeon-cli/cluster/`, needs no required change.

See [ADR-0149](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0149-pigeon-cluster-private-network-public-gateway-toggles.md) for the full design discussion and rationale.


[#254](https://github.com/noisypigeon/noisypigeon/pull/254)
