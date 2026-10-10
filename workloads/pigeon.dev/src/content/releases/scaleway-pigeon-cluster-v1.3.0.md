+++
title = "scaleway/pigeon-cluster v1.3.0"
date = 2026-10-10T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v1.3.0"
description = "Re-pin pigeon-cluster to compute-instance v5.7.0, add per-job HEIC transcoding opt-in"
+++

Re-pins both `compute-instance` calls inside `pigeon-cluster` (`module.job` and `module.bastion`) to `v5.7.0`, which added `instance_config.enable_heic_transcoding` (ADR-0150).

`jobs` gains a new optional `enable_heic_transcoding` field (default `false`, unchanged behavior), passed straight through to that job's own `compute-instance` call's `instance_config`. Set it `true` on any job whose `job_commands` run `pigeon-cli transform --input-file-type=heic`, to get a libheif-enabled ffmpeg build on that job's instance. `module.bastion` doesn't get this field — it never runs transforms.

See ADR-0150 for the full design.

[#258](https://github.com/noisypigeon/noisypigeon/pull/258)
