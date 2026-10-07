+++
title = "scaleway/compute-instance v5.3.0"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-compute-instance-v5.3.0"
description = "Add enabled kill switch to compute-instance"
+++

`compute-instance` gains an optional top-level `enabled` boolean (default `true`). Setting it to `false` destroys every resource this module instance manages — the server, its IP address(es), its block volume (and the volume's data), and its IAM policy/API key — while the module block itself stays in the caller's configuration; flipping it back to `true` recreates everything from the same config, with the instance's name (random suffix) staying stable across the cycle.

`scaleway_instance_server.server` moves from a singleton resource to `count = var.enabled ? 1 : 0` internally, with a `moved` block protecting any existing state through the addressing change.

Purely additive — defaults to `true`, unchanged behavior for every existing caller. See ADR-0126.

[#173](https://github.com/noisypigeon/noisypigeon/pull/173)
