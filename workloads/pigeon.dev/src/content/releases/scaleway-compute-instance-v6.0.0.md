+++
title = "scaleway/compute-instance v6.0.0"
date = 2026-10-10T12:00:00-07:00
slug = "scaleway-compute-instance-v6.0.0"
description = "Rename compute-instance's enable_heic_transcoding to enable_transcoding"
+++

Renames `instance_config.enable_heic_transcoding` to `instance_config.enable_transcoding`. This is a pure rename — the same `ppa:savoury1/ffmpeg4` repository is added and the same `ffmpeg` package installed, at the same point in cloud-init, producing an identical instance.

The old name described one motivating use rather than the flag's actual effect. What it installs is a general-purpose ffmpeg build; libheif-based HEIC decode is the capability that made that PPA preferable to Ubuntu's own archive build, but it is one codec among everything else the build ships. A job running `transform --input-file-type=png` or `--input-file-type=webp` needs exactly the same flag, and reading `enable_heic_transcoding = true` on such a job would look like a configuration error rather than the correct setting. The `instance_config` description has been rewritten to match: it now leads with the general effect and keeps HEIC as the stated reason for the PPA choice.

**This is a breaking change, and it breaks quietly — please read before upgrading.** Terraform treats an unknown attribute on an object-typed variable as a warning rather than an error, so a caller that upgrades to v6.0.0 while still passing `enable_heic_transcoding` will not fail. `tofu validate` reports only `the object type for input variable "instance_config" does not include an attribute named "enable_heic_transcoding", so this definition is unused`, and plan and apply both succeed. The key is silently dropped, the instance comes up with no ffmpeg installed at all, and the problem surfaces much later as a transform job dying on its first file with ffmpeg's own "decoder not found" error.

So when bumping to v6.0.0, grep your configuration for `enable_heic_transcoding` and rename every occurrence — a clean plan is not evidence that you caught them all.

Recorded in [ADR-0151](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0151-rename-enable-transcoding-and-object-bucket-expiration.md), which also covers the matching `pigeon-cluster` passthrough rename and an unrelated `object-bucket` change landing separately.

[#260](https://github.com/noisypigeon/noisypigeon/pull/260)
