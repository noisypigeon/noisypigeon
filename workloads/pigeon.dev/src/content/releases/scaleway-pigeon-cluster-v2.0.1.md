+++
title = "scaleway/pigeon-cluster v2.0.1"
date = 2026-10-10T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v2.0.1"
description = "Re-pin compute-instance to v6.1.0"
+++

Both `compute-instance` calls — `module "job"` and `module "bastion"` — move from `v6.1.0`'s predecessor to `v6.1.0`, which replaces the `ppa:savoury1/ffmpeg4` install behind `enable_transcoding` with a pinned, checksum-verified static ffmpeg 9.0.2 build. The old PPA installed ffmpeg 4.4.8, four major versions below the 8.1 floor where the ffmpeg CLI first reconstructs grid-tiled HEIF images, so `jobs[*].enable_transcoding = true` could not actually convert a tiled `.heic` — it silently wrote a single tile and exited 0.

This is a re-pin only. `jobs[*].enable_transcoding` keeps its name, type and default, its passthrough into `module "job"`'s `instance_config` is unchanged, and `module "bastion"` passes no `instance_config` at all. Callers need no changes.

One thing to know before setting the flag: the pinned ffmpeg artifact is an x86_64 build, so a job using it must not also select an arm64 `instance_type` such as `COPARM1-*`. See ADR-0152.


[#265](https://github.com/noisypigeon/noisypigeon/pull/265)
