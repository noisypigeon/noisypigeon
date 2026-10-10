+++
title = "backblaze/api-key v0.1.1"
date = 2026-10-09T12:00:00-07:00
slug = "backblaze-api-key-v0.1.1"
description = "Qualify backblaze/b2 provider source with an explicit registry host"
+++

Both \`templates/terraform/backblaze/bucket\` and \`templates/terraform/backblaze/api-key\` declared their \`b2\` provider requirement as a bare \`source = "Backblaze/b2"\`, leaving the registry host to whatever the running Terraform-compatible binary defaults an unqualified source to.

PR #252's CI run — the first time any leaf actually exercising this provider ran through \`terragrunt plan\` — failed trying to install the provider from \`registry.opentofu.org\`, hitting an "authentication signature from unknown issuer" error there. The provider itself is fine: reproducing the exact generated configuration with this repo's own pinned Terraform binary (\`1.16.3\`, real HashiCorp, not OpenTofu) installs \`backblaze/b2 v0.14.0\` cleanly from \`registry.terraform.io\`, "signed by a HashiCorp partner."

This makes the source fully host-qualified (\`registry.terraform.io/Backblaze/b2\`) in both modules, removing the ambiguity regardless of which binary ends up resolving it. A matching change already landed in \`workloads/willowgraysen.com/root.hcl\`'s own generated \`required_providers\` entry for the same provider.

[#255](https://github.com/noisypigeon/noisypigeon/pull/255)
