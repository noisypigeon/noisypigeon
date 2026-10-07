+++
title = "scaleway/compute-instance v0.5.0"
date = 2026-10-01T12:00:00-07:00
slug = "scaleway-compute-instance-v0.5.0"
description = "Attach a routed IPv4 address to compute-instance by default"
+++

Adds a new `enable_ipv4` input to `scaleway/compute-instance` (defaults to `true`), creating and attaching a routed IPv4 address to the instance by default, alongside the existing `enable_ipv6` (defaults to `false`).

`scaleway_instance_server`'s `ip_id` argument only ever holds a single reserved IP, and is mutually exclusive with `ip_ids`, the list-valued equivalent. Since `enable_ipv4` defaults to `true`, an instance can now have both an IPv4 and an IPv6 address enabled at once, which `ip_id` can't express. The server's attachment argument switches from `ip_id` to `ip_ids`, built from whichever of the two IPs are enabled (`compact([...])`, dropping disabled ones) — functionally identical to before when only one or neither is enabled.

Existing callers that already set `enable_ipv6 = true` will pick up a new default IPv4 address on their next apply (and will see `scaleway_instance_server`'s IP attachment move from `ip_id` to `ip_ids`); set `enable_ipv4 = false` to opt out and keep IPv6-only.

[#111](https://github.com/noisypigeon/noisypigeon/pull/111)
