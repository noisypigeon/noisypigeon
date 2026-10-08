+++
title = "scaleway/compute-instance v5.6.1"
date = 2026-10-08T12:00:00-07:00
slug = "scaleway-compute-instance-v5.6.1"
description = "Fix compute-instance's private_ips output to read from the private NIC"
+++

Confirmed by a real apply failure (wiring a bastion's private IP into a \`scaleway_vpc_public_gateway_pat_rule\`): \`compute-instance\`'s \`private_ips\` output returns an empty list even after \`scaleway_instance_private_nic\` successfully attaches a Private Network.

ADR-0145's original text assumed \`scaleway_instance_server\`'s own \`private_ips\` attribute would reflect a NIC attached via the separate \`scaleway_instance_private_nic\` resource, based on reading the provider's schema rather than a live test. It doesn't — that attribute only ever reflected the deprecated inline \`private_network\` block, which this module has never used. The private NIC resource has its own, separate \`private_ips\` computed block that was never read.

This fixes the output to read from \`scaleway_instance_private_nic.private_nic[0].private_ips\` first, falling back to the server's own attribute and then \`null\` — same \`try()\`-chain convention already used by every other conditional-resource output in this module. No shape/interface change, bug fix only.

[#249](https://github.com/noisypigeon/noisypigeon/pull/249)
