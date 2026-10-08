+++
title = "scaleway/pigeon-cluster v0.3.1"
date = 2026-10-08T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v0.3.1"
description = "Fix pigeon-cluster's stale internal compute-instance pin"
+++

`pigeon-cluster` v0.3.0 (#244) added Private Network support by composing \`compute-instance\`'s new \`private_network_id\` input, but its internal \`module "job"\` block was left pinned to \`compute-instance/v5.4.0\` — the version that existed at the time #244 was written, before \`v5.5.0\` (the release that actually adds \`private_network_id\`) had been tagged.

As released, this meant \`pigeon-cluster\` v0.3.0's private-network wiring didn't actually work: it composed a version of \`compute-instance\` that has no \`private_network_id\` input at all, so the argument would be rejected by any real consumer.

This bumps that internal pin to \`compute-instance/v5.5.0\`, the version that was actually released alongside it. No other change — confirmed via \`tofu validate\` against the real, already-published \`v5.5.0\` tag.

[#245](https://github.com/noisypigeon/noisypigeon/pull/245)
