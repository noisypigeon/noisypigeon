+++
title = "scaleway/compute-instance v5.6.0"
date = 2026-10-08T12:00:00-07:00
slug = "scaleway-compute-instance-v5.6.0"
description = "Fix compute-instance: private NIC count must not depend on private_network_id's nullness"
+++

Attaching an instance to a Private Network that's created in the *same* apply (exactly what \`pigeon-cluster\` does — it provisions one shared Private Network per cluster and attaches every job instance to it) fails to plan at all:

\`\`\`
Error: Invalid count argument
  on instance.tf line 23, in resource "scaleway_instance_private_nic" "private_nic":
  23:   count = var.enabled && var.private_network_id != null ? 1 : 0
The "count" value depends on resource attributes that cannot be determined until apply...
\`\`\`

This is a real-world failure hit on the first live apply of a \`pigeon-cluster\` job. The root cause: \`count\`/\`for_each\` must be fully determinable at plan time, but a newly-created resource's \`.id\` (like the Private Network's) is unknown until apply — and because \`private_network_id\`'s nullable \`string\` type can't be statically proven non-null from an unknown value, gating \`count\` on \`private_network_id != null\` can never resolve for a same-apply Private Network.

This adds a new \`enable_private_network\` boolean (default \`false\`) that decouples "should this instance attach to a Private Network" from "what ID should it use" — the former is always statically known by the caller, the latter is allowed to stay apply-time-unknown since it's now just an ordinary resource argument, not part of a \`count\` expression. A validation block ensures \`private_network_id\` is set whenever \`enable_private_network\` is true.

Any existing caller using \`private_network_id\` must now also set \`enable_private_network = true\` to get the same behavior as before. Verified by reproducing the exact error in a scratch config (a real, not-yet-applied \`scaleway_vpc_private_network\` composed with this module) and confirming the fix produces a clean plan instead.

See \`docs/adr/0145-private-network-access-to-pigeon-cli-job-buckets.md\` (amended in a follow-up PR) for the full incident writeup.

[#246](https://github.com/noisypigeon/noisypigeon/pull/246)
