+++
title = "scaleway/compute-instance v5.3.1"
date = 2026-10-06T12:00:00-07:00
slug = "scaleway-compute-instance-v5.3.1"
description = "Move module-redirect short URLs from noisypigeon.com to pigeon.dev"
+++

This moves the ADR-0109/0110/0114 short module-source redirect mechanism
(`noisypigeon.com/modules/<provider>/<module>/vX.Y.Z` and
`noisypigeon.com/templates/zola-site/vX.Y.Z`) off the personal-blog domain
and onto `pigeon.dev`, which already runs the identical Zola/zola-site
hosting pipeline (ADR-0130) with zero new Terraform resources needed.

`generate-module-redirects.sh`, its two templates (`module-redirect.html`,
`theme-redirect.html`), and its two generated-content directories
(`content/modules/`, `content/theme-versions/`) move from
`workloads/noisypigeon.com/src/` to `workloads/pigeon.dev/src/`.
`.mise.toml`'s `pigeon-dev-build`/`pigeon-dev-serve` tasks,
`pigeon-dev-pages.yml`, `noisypigeon-com-deploy.yml`, and
`template-release.yml`'s post-tag deploy dispatch are rewired accordingly.
The public URL path convention (`modules/<provider>/<module>/vX.Y.Z`) stays
exactly as ADR-0110 fixed it — only the hostname changes, and every short
URL still resolves to the identical `git::...?ref=...` target it did before.

This PR also updates `compute-instance`'s own internal composition
(`iam.tf`, `instance.tf`, which source `iam-policy`/`iam-api-key`/
`block-volume` via the short URL) and every `templates/terraform/` module
README's usage example from `noisypigeon.com` to `pigeon.dev`. Because
`compute-instance` already has prior tags, this PR's edit to its tracked
`.tf` content will trigger a real (if purely cosmetic) `v5.3.1` patch
release via the existing changed-module release automation — see
ADR-0136 for why that's accepted rather than avoided.

This is PR A of a two-PR cutover (see ADR-0136's "Decision" section). A
second PR will sweep every `workloads/*/terraform/**` consumer leaf's
`source =` line from `noisypigeon.com` to `pigeon.dev`, opened only once
this PR has merged and `pigeon-dev-pages.yml` has deployed the new
redirect pages live.

New ADR: `docs/adr/0136-move-module-redirect-urls-to-pigeon-dev.md`.

[#223](https://github.com/noisypigeon/noisypigeon/pull/223)
