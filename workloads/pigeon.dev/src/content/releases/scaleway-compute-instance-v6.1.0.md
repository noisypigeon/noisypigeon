+++
title = "scaleway/compute-instance v6.1.0"
date = 2026-10-10T12:00:00-07:00
slug = "scaleway-compute-instance-v6.1.0"
description = "Install a pinned static ffmpeg for tiled HEIF transcoding"
+++

`instance_config.enable_transcoding` previously installed ffmpeg from `ppa:savoury1/ffmpeg4`, which publishes ffmpeg 4.4.8. That is four major versions below what the capability it was added for actually needs: grid-tiled HEIF reconstruction first shipped in the ffmpeg CLI in 8.1 (`- ffmpeg CLI tiled HEIF support`, under `version 8.1:` in FFmpeg's own Changelog). Tiled HEIF is how phone cameras commonly encode large `.heic` photos — as a grid of separate HEVC tile streams — so `pigeon-cli transform --input-file-type=heic` could not convert them. Worse, it did not fail loudly: below 8.1 ffmpeg selects the first tile, writes it, and exits 0, so a job produced silently cropped output instead of an error.

Neither obvious repair works. No Ubuntu archive reaches the 8.1 floor (jammy 4.4, noble 6.1, and resolute 8.0 — `ubuntu_resolute` does exist on Scaleway, but is one minor release short), and every savoury1 ffmpeg PPA above `ffmpeg4` requires a donation-gated private PPA that unattended cloud-init cannot authenticate to. `enable_transcoding = true` therefore now installs a pinned static ffmpeg 9.0.2 build (BtbN, `linux64-gpl`) into `/usr/local/bin`, verified against its published sha256 before extraction, with only `ffmpeg` and `ffprobe` kept. An immutable dated release tag is pinned rather than a rolling `latest` asset, so the rendered cloud-init stays reproducible — the module already treats that script's hash as part of the instance's identity.

Nothing changes for callers: the input keeps its name, type and `false` default, and the default path renders exactly the same cloud-init as before. Two things are worth knowing if you set it. The pinned artifact is an x86_64 binary, so the flag must not be combined with an arm64 `instance_config.type` such as `COPARM1-*`. And an existing instance with the flag already set will be replaced on next apply, since the cloud-init hash changes.

See ADR-0152 for the full investigation, including why ADR-0150's `--enable-libheif` rationale was mistaken (ffmpeg decodes HEIC natively; there is no such configure option, and the capability is version-gated). ADR-0150 is marked superseded.


[#264](https://github.com/noisypigeon/noisypigeon/pull/264)
