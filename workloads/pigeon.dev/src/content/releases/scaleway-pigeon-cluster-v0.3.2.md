+++
title = "scaleway/pigeon-cluster v0.3.2"
date = 2026-10-08T12:00:00-07:00
slug = "scaleway-pigeon-cluster-v0.3.2"
description = "Wire pigeon-cluster to compute-instance's new enable_private_network flag"
+++

\`compute-instance\` v5.6.0 (#246) fixed the \`Invalid count argument\` error that broke \`pigeon-cluster\`'s private-network wiring on every real first apply, by replacing the implicit \`private_network_id != null\` gate with an explicit \`enable_private_network\` boolean.

This updates \`pigeon-cluster\`'s internal \`module "job"\` call to set \`enable_private_network = true\` (unconditionally — every job always attaches to the cluster's one shared Private Network) and bumps its pinned \`compute-instance\` source from \`v5.4.0\`/\`v5.5.0\` to the now-real \`v5.6.0\`. Confirmed via \`tofu validate\` against the real, published \`v5.6.0\` tag.

No public interface change to \`pigeon-cluster\` itself — purely an internal composition fix.

[#247](https://github.com/noisypigeon/noisypigeon/pull/247)
