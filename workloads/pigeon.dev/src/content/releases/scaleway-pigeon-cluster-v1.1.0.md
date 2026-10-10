+++
title = "scaleway/pigeon-cluster v1.1.0"
date = 2026-10-08T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v1.1.0"
description = "Expose pigeon-cluster's Public Gateway offer type as a variable"
+++

The cluster's shared Public Gateway (ADR-0145) has been hardcoded to Scaleway's smallest offer type, `VPC-GW-S` (up to 100 Mbps), shared by every concurrently-running job instance in the cluster. `cluster_config` gains a new optional `public_gateway_type` field, defaulting to `"VPC-GW-S"` so existing callers see no behavior change, letting a caller size the gateway up (`VPC-GW-M`/`VPC-GW-L`/`VPC-GW-XL`) if that shared bandwidth cap turns out to be a bottleneck for a given cluster's job traffic.

Confirmed against the Scaleway Terraform provider's own source (`internal/services/vpcgw/public_gateway.go`) that `scaleway_vpc_public_gateway`'s `type` argument has no `ForceNew` -- changing it goes through a dedicated `UpgradeGateway` API call, upgrading the existing gateway in place (same gateway ID/IP) rather than recreating it. No job or bastion instance needs to restart or reconnect to pick up the new bandwidth. Upgrades are one-directional -- Scaleway doesn't support downgrading a gateway back to a smaller tier afterward.

A `validation` block restricts the value to Scaleway's four known offer types (`VPC-GW-S`/`M`/`L`/`XL`), so a typo fails at `plan` time rather than as an opaque API error at `apply`.

Purely additive -- no interface or behavior change for any existing caller.

[#251](https://github.com/noisypigeon/noisypigeon/pull/251)
