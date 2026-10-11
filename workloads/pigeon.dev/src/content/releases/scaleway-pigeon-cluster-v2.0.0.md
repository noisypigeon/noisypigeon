+++
title = "scaleway/pigeon-cluster v2.0.0"
date = 2026-10-10T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v2.0.0"
description = "Rename pigeon-cluster's jobs[*].enable_heic_transcoding to enable_transcoding, re-pin compute-instance v6.0.0"
+++

Follows `compute-instance` v6.0.0, which renamed `instance_config.enable_heic_transcoding` to `instance_config.enable_transcoding`. This renames the matching per-job passthrough and re-pins the module.

- `jobs[*].enable_heic_transcoding` is renamed to `jobs[*].enable_transcoding`. Its meaning is unchanged: `false` (the default) installs no ffmpeg, `true` installs a general-purpose ffmpeg build on that job's instance. The old name described only the HEIC case, but the flag is exactly what any `pigeon-cli transform` job needs regardless of input file type.
- Both `compute-instance` source pins — `module "job"` and `module "bastion"` — move from v5.7.0 to v6.0.0. `module "bastion"` passes no `instance_config`, so it takes the re-pin without a field change.

**This is a breaking change that fails silently if you miss it.** Terraform treats an unknown attribute on an object-typed variable as a warning, not an error, so a `jobs` entry still setting `enable_heic_transcoding` after upgrading to v2.0.0 will plan and apply cleanly — the key is simply dropped. The job's instance then comes up with no ffmpeg installed, and the failure appears later as the transform dying on its first file with ffmpeg's own "decoder not found" error.

When bumping to v2.0.0, grep your `jobs` list for `enable_heic_transcoding` and rename every occurrence. A clean plan does not mean you caught them all.

Recorded in [ADR-0151](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0151-rename-enable-transcoding-and-object-bucket-expiration.md).

[#261](https://github.com/noisypigeon/noisypigeon/pull/261)
