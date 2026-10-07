+++
title = "scaleway/block-volume v1.0.0"
date = 2026-10-01T12:00:00-07:00
slug = "scaleway-block-volume-v1.0.0"
description = "Require project_id input on scaleway/block-volume"
+++

Adds a new required input, `project_id`, to `scaleway/block-volume`, wired straight through to `scaleway_block_volume`'s existing `project_id` argument.

This is a breaking change to the module's interface: existing callers must now pass `project_id` explicitly, since the resource no longer falls back to the provider's default project for volumes created through this module.

[#110](https://github.com/noisypigeon/noisypigeon/pull/110)
