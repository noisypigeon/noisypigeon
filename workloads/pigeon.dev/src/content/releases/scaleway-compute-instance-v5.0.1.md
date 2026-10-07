+++
title = "scaleway/compute-instance v5.0.1"
date = 2026-10-04T12:00:00-07:00
slug = "scaleway-compute-instance-v5.0.1"
description = "Pin block-volume source in compute-instance"
+++

`compute-instance`'s internal `block_volume` composition (ADR-0120) used a relative source, `source = "../block-volume"`. That only resolves within whatever package `compute-instance` itself was fetched as — a local clone or `git::...` source happens to include the whole repo tree, but go-getter's HTTP installer (what the `noisypigeon.com` short-URL redirects resolve to) fetches only `compute-instance`'s own module directory. The first real consumer to fetch `compute-instance` that way (`workloads/pigeon-cli/terraform/job`, sourcing `compute-instance/v5.0.0`) hit `tofu init` failing outright with "Local module path escapes module package".

This pins the internal `block_volume` module to the released `block-volume` v4.0.0 tag (`https://noisypigeon.com/modules/scaleway/block-volume/v4.0.0`) instead, matching the short-URL pin convention every other cross-module reference in this repo already uses. No input/output change to `compute-instance` itself — any consumer already on `v5.0.0` can bump straight to the patch release this produces with no other changes needed.

See ADR-0121 for the full root cause and decision record; ADR-0120 is amended in place to strike through its now-superseded relative-path description.

[#165](https://github.com/noisypigeon/noisypigeon/pull/165)
