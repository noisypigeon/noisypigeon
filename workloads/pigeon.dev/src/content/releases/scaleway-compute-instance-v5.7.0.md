+++
title = "scaleway/compute-instance v5.7.0"
date = 2026-10-10T12:00:00-07:00
slug = "scaleway-compute-instance-v5.7.0"
description = "Add libheif-enabled ffmpeg support to compute-instance"
+++

`compute-instance` gains a new optional `instance_config.enable_heic_transcoding` field (default `false`, unchanged behavior). When set to `true`, the instance installs an ffmpeg build with libheif-based HEIC decode support via `ppa:savoury1/ffmpeg4`.

This exists for `pigeon-cli transform --input-file-type=heic`: Ubuntu's default apt ffmpeg build (this module's `ubuntu_jammy` default image) typically does not include libheif support, so `transform` would otherwise fail fast on the first `.heic` file with ffmpeg's own "decoder not found" error.

See ADR-0150 for the full design, including why this is net-new provisioning (neither this module's existing `packages:` list nor its `pigeon-cli` bootstrap script touch ffmpeg today) and why a PPA was chosen over a static build (consistency with the module's existing Cockpit/Alloy apt-repo pattern).

[#257](https://github.com/noisypigeon/noisypigeon/pull/257)
