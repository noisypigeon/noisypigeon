# Changelog

All notable changes to the blog are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 2026-10-03 — feat: let consumers pin a templates/zola-site version (ADR-0114)

## Summary
- Adds `[extra].theme_version` to a consuming site's `config.toml` (default `"main"`), resolved by a new `templates/zola-site/resolve-theme.sh` into a gitignored `.theme-resolved/<name>` indirection: a live symlink for `"main"`, or a `git archive`-materialized checkout of a specific tag.
- Retargets `workloads/blog/src/themes/zola-site` through this indirection (`-> ../.theme-resolved/zola-site`, was `-> ../../../../templates/zola-site` directly) so pinning locally never dirties a tracked path. Wires the resolve script into `.mise.toml`'s blog tasks and `blog-pages.yml`'s build job.
- Adds short redirect pages at `noisypigeon.com/templates/zola-site/vX.Y.Z`, mirroring the Terraform module pages — reversing ADR-0113's "none planned" stance at the user's explicit request. `generate-module-redirects.sh` gains a second, parallel loop (the tag shape doesn't fit the existing provider/module one); a new workload-specific `theme-redirect.html` does a real `<meta http-equiv="refresh">` to the tag's GitHub Release page, since unlike the Terraform pages there's no fetch-by-URL protocol for Zola themes to hook into — this is a human/documentation redirect only, not a build input.
- `workloads/blog/src` itself stays on `theme_version = "main"` — the mechanism exists so it (or a future `workloads/<name>/src` consumer) can pin independently when needed, not because anything needs to today.
- See `docs/adr/0114-pin-templates-zola-site-version.md` for the full decision record.

## Test plan
- [x] `mise run blog-build` in default (`"main"`) mode: `resolve-theme.sh` creates an absolute symlink, build succeeds
- [x] Temporarily pinned to `v1.0.0` locally: `resolve-theme.sh` materializes a real directory via `git archive`, build succeeds, output byte-identical to the `"main"` build (expected, since `v1.0.0`'s content currently equals `main`'s) — reverted before committing
- [x] Built `public/templates/zola-site/v1.0.0/index.html` meta-refreshes to and links the correct GitHub release URL
- [x] `git status` clean after builds in both modes (`.theme-resolved/` and generated `content/theme-versions/*.md` properly gitignored)
- [x] This PR's diff doesn't match ADR-0113's content-change glob, so merging won't spuriously fire a new zola-site release (it will however correctly register as a `workloads/blog/src/` change, since several of these files legitimately live there)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#147](https://github.com/noisypigeon/noisypigeon/pull/147)

## 2026-10-03 — feat(blog): extract reusable templates/zola-site theme (ADR-0112)

## Summary
- Extracts a reusable Zola theme, `templates/zola-site/`, from `workloads/blog/src` — a survey found its `templates/` and `static/assets/css/` were already almost entirely generic/config-driven, aside from a hardcoded footer initial and a hardcoded `Person` JSON-LD `sameAs` list (both now generalized).
- `workloads/blog/src` now consumes the theme live via a committed relative symlink (`themes/zola-site` → `../../../../templates/zola-site`) plus `theme = "zola-site"` in `config.toml`, and its own `templates/` holds only `module-redirect.html` (ADR-0109), the one genuinely workload-specific template.
- Widens `blog-pages.yml`'s trigger paths and `module-release.yml`'s blog-change detection to also watch `templates/zola-site/**`.
- See `docs/adr/0112-extract-reusable-zola-site-template.md` for the full decision record.

## Test plan
- [x] `mise run blog-build` succeeds with the symlinked theme
- [x] Generated homepage `Person` JSON-LD `sameAs` array matches the prior hardcoded output (same 3 URLs, same order, no trailing comma)
- [x] Footer renders `Willow Graysen` in place of `WG`
- [x] `git ls-files -s workloads/blog/src/themes/zola-site` reports mode `120000` (tracked as a symlink)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#145](https://github.com/noisypigeon/noisypigeon/pull/145)

## 2026-10-03 — feat(blog): comprehensive SEO pass (ADR-0111)

## Summary
- Canonical URLs, Twitter Cards, and JSON-LD structured data (`WebSite`/`Person` on the homepage, `BlogPosting` on every post)
- `og:type=article` + `article:published_time`, per-post `og:image` wired to the 20 posts that already have their own image directory
- A real favicon/apple-touch-icon/`manifest.json` icon set generated from the existing avatar via `sips`
- A `tags` taxonomy covering all 53 posts (9 tags derived from the site's own bio), browsable at `/tags/`
- Backfilled `description` for the 5 pages/posts that lacked one, and fixed the changelog-digest generator so this can't reopen
- A real, committed `static/robots.txt`, and excluded Terraform module-redirect pages from the sitemap (they have no `date`, so they were the only pages missing `<lastmod>` for a fixable reason)

See `docs/adr/0111-improve-blog-seo.md` for full details.

## Test plan
- [x] `mise run blog-build` completes with zero Tera errors
- [x] Homepage output has `WebSite`/`Person` JSON-LD, canonical link, manifest link, sized favicon links
- [x] A post with its own image (`cmda-zip-scatter`) gets `og:type=article`, `article:published_time`, `BlogPosting` JSON-LD, and `og:image`/`twitter:image` pointing at its own image
- [x] A post without one falls back to the generic social preview
- [x] `/tags/` lists all 9 tags with correct counts; `/tags/personal-essays/` lists its 22 posts grouped by year
- [x] `robots.txt`, `manifest.json`, and all 5 icon files exist in the build output
- [x] `sitemap.xml` has no `modules/...` URLs
- [x] The 5 previously-generic-description pages now render their own description

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#143](https://github.com/noisypigeon/noisypigeon/pull/143)

## 2026-10-03 — Add short noisypigeon.com module import URLs via blog redirect pages

Terraform module \`source\` lines in this repo are long and easy to mistype (the provider/module name repeats):

\`\`\`hcl
source = "git::https://github.com/noisypigeon/noisypigeon.git//modules/scaleway/object-bucket?ref=modules/scaleway/object-bucket/v1.0.0"
\`\`\`

This adds a short equivalent, served from the existing Zola blog at \`noisypigeon.com\`:

\`\`\`hcl
source = "https://noisypigeon.com/modules/scaleway/object-bucket/v1.0.0"
\`\`\`

It works via Terraform/go-getter's standard HTTP module-source discovery protocol: \`terraform init\` requests the URL with \`?terraform-get=1\` and follows a \`<meta name="terraform-get">\` tag in the response to the real \`git::...?ref=...\` source — no backend required, just a static page per module version tag, generated automatically from \`git tag\` on every blog build. A new step in \`module-release.yml\` also redeploys the blog whenever a module is tagged, so a brand-new version's redirect page goes live immediately.

This repo's own 22 existing \`source = "git::..."\` lines are migrated to the short form as part of this same change (non-breaking — the old form keeps working unchanged).

Full design rationale in [ADR-0109](https://github.com/noisypigeon/noisypigeon/blob/add-short-module-import-urls/docs/adr/0109-short-module-source-urls-via-blog-redirect.md).

Verified locally: \`mise run blog-build\` generates the expected pages with the correct \`terraform-get\` meta tag, and a full \`terraform init\` against a locally-served copy of the built site successfully downloaded the real module — confirming the redirect mechanism works end-to-end before deploy.

[#140](https://github.com/noisypigeon/noisypigeon/pull/140)

## 2026-10-03 — fix(blog): update changelog titles



[#139](https://github.com/noisypigeon/noisypigeon/pull/139)

## 2026-10-03 — feat(blog): compute digest titles from entries, backfill changelog history

## Summary
- `module-release.yml`'s daily digest title generation now derives from the day's actual entries (strips a leading conventional-commit prefix off the chronologically-first entry, collapses extra same-day entries into a `(+N more)` suffix) instead of the hardcoded `"Changelog: <date>"`.
- Backfills `workloads/blog/CHANGELOG.md` (12 entries), the root `CHANGELOG.md` (10 entries — PR #66 already had a hand-written entry there, left untouched per this repo's no-rewrite-history precedent), and 3 on-site daily digest posts under `content/changelog/`, covering the 12-commit, 3-day window (2026-09-27, 2026-10-01, 2026-10-03) between the blog's existence in this repo and ADR-0107's automation landing. Two incidentally-blog-touching commits (PR #135, PR #119) excluded as out of the automation's own path-filter scope.

See `docs/adr/0108-backfill-blog-changelog-history.md` for the full decision record.

## Test plan
- [x] `mise run blog-build` succeeds with no Tera errors
- [x] `/changelog/` shows 8 posts total (4 historical + 3 digests), correct year grouping
- [x] `2026-10-03-changelog.md` title recomputed to "deploy profiles page (+9 more)" over its merged 10 entries
- [x] No duplicate entries for PR #136 anywhere
- [x] `.github/workflows/module-release.yml` parses as valid YAML

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#138](https://github.com/noisypigeon/noisypigeon/pull/138)

## 2026-10-03 — feat(blog): wire blog into the changelog workflow, restructure changelog channel

## Summary
- Extends `module-release.yml` with a parallel, unversioned blog path: merged PRs touching `workloads/blog/src/` now get a dated entry in a new `workloads/blog/CHANGELOG.md`, a `[blog]` rollup in the root `CHANGELOG.md`, and an auto-generated daily digest post under `content/changelog/` — no `release:*` label needed, since the blog isn't tagged/released.
- Fixes the workflow's single date computation from UTC to `America/Los_Angeles`, so late-night Pacific merges stop landing under the wrong calendar day.
- Moves the 4 posts previously tagged `post_type = "changelog"` out of `content/posts/` into a real `content/changelog/` section (renumbered `0001`-`0004`, with `aliases` so old `/posts/<slug>/` URLs still resolve), and renumbers the remaining `content/posts/` entries to a contiguous `0001`-`0053`.

See `docs/adr/0107-wire-blog-into-changelog-workflow.md` for the full decision record.

## Test plan
- [x] `mise run blog-build` succeeds with no Tera errors
- [x] `/changelog/` lists exactly the 4 renumbered historical posts, grouped by year
- [x] Old URLs (`/posts/hello-jekyll-re-introduction/` etc.) resolve via `aliases` to the new `/changelog/<slug>/` canonical path
- [x] Home page (`/`) no longer contains any changelog-tagged entries
- [x] No duplicate numeric prefixes in `content/posts/` or `content/changelog/` after renumbering
- [x] `.github/workflows/module-release.yml` parses as valid YAML
- [ ] Live CI path (the new blog changelog/daily-digest steps) — can only be verified on this PR's own merge, since local sessions can't execute GitHub Actions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#136](https://github.com/noisypigeon/noisypigeon/pull/136)

## 2026-10-03 — fix(blog): changelog css

Footer alignment/styling tweaks: drop the duplicate inline padding on the
footer, switch it to a monospace font, and mute the Changelog link until
hover.

[8925ece](https://github.com/noisypigeon/noisypigeon/commit/8925ecea7b2965d3b050daa3e33a0ecb070f0594)

## 2026-10-03 — chore(blog): move more blog posts to changelog channel

Tags 3 more archival posts (`0003-hello-medium-introduction`,
`0025-hiya-svbtle-re-introduction`,
`0049-hihi-pika-lets-consolidate-re-introduction`) with
`post_type = "changelog"`.

[d865f82](https://github.com/noisypigeon/noisypigeon/commit/d865f821f98f145e83f84bc4939657e22a4d72df)

## 2026-10-03 — chore(blog): organize posts

File-level reorganization of `content/posts/`.

[3dc9e54](https://github.com/noisypigeon/noisypigeon/commit/3dc9e544d43657b5a8cb5ba9b120959a954de9a8)

## 2026-10-03 — chore(blog): clean-up about and lineage

Prose cleanup on the About and Lineage pages.

[eb25e46](https://github.com/noisypigeon/noisypigeon/commit/eb25e46f619d73de7a6f60a1e94e285b2e089d20)

## 2026-10-03 — chore(blog); a few more renames

Nav/config and About-page tweaks.

[9f14bcd](https://github.com/noisypigeon/noisypigeon/commit/9f14bcd26f92cdb3a92cff5194954a420ac77a0d)

## 2026-10-03 — chore: remove duplicate title

Drops a duplicate heading from the Lineage page.

[bc99d6b](https://github.com/noisypigeon/noisypigeon/commit/bc99d6bd371d45dcd8b34c7e83bbcd885e427786)

## 2026-10-03 — chore: clean-up dns terraform; update blog names/lineage page

Replaces the Names page with a new Lineage page and updates the home intro.

[4da2430](https://github.com/noisypigeon/noisypigeon/commit/4da24307d524720c8b08e6af148ca0bad63dbaaa)

## 2026-10-03 — chore(blog): make profile links clickable

Fixes the Profiles page's links.

[9979a98](https://github.com/noisypigeon/noisypigeon/commit/9979a988555eb6da610f6a4b8a3e606beff3ef95)

## 2026-10-03 — chore(blog): deploy profiles page

Adds a new Profiles page.

[f256c83](https://github.com/noisypigeon/noisypigeon/commit/f256c83bdfb9c64536ae2b8e22fa0fdf7e05b6ab)

## 2026-10-01 — Rename service/blog to workloads/blog/src

Renames `service/blog/` to `workloads/blog/src/`, establishing a `workloads/<name>/src/` convention for future non-Terraform workloads beyond the blog — `src/` leaves room for future sibling directories per workload (e.g. a hypothetical `workloads/blog/deploy/` later), mirroring how `terraform/` already splits into `modules/`/`infrastructure/`.

`service/` previously held only `blog/` (its other sibling, `pigeon-cli`, split into its own repo via ADR-0084) — it no longer exists as a concept in this repo after this move.

Pure path rename via `git mv` — no content, template, or asset changes (`config.toml` has no internal path self-references, confirmed). Updates every live reference to the old path:
- `.gitignore`'s build-output ignore line
- `.mise.toml`'s `blog-build`/`blog-serve` task `dir`
- **`.github/workflows/blog-pages.yml`** — the live GitHub Pages deploy workflow (trigger path filter, build working-directory, artifact upload path) — all three needed updating together or the next deploy breaks
- `CLAUDE.md` and `docs/USAGE.md` prose/command references

`docs/adr/0067-rewrite-blog-to-zola.md` (the original Zola migration ADR) and `CHANGELOG.md`'s historical `[blog]` entry are left untouched — both accurately describe `service/blog` as it existed when written, consistent with this repo's precedent of not rewriting history.

Full rationale in [ADR-0091](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0091-rename-service-blog-to-workloads-blog-src.md).

[#118](https://github.com/noisypigeon/noisypigeon/pull/118)

## 2026-09-27 — chore(blog): add bix

[#69](https://github.com/noisypigeon/noisypigeon/pull/69)

## 2026-09-27 — docs(adr-0067): rewrite the blog from Jekyll to Zola as service/blog

## Context

`noisypigeon.github.io` is a separate, public repo hosting a hand-rolled
Jekyll blog (custom "gameboy" theme, no theme gem) served via GitHub Pages
at the `noisypigeon.com` custom domain. This PR moves its engine into this
monorepo as `service/blog/`, rewritten from Jekyll/Ruby to Zola/Rust —
continuing the monorepo-consolidation direction of ADR-0037/ADR-0052. The
rendered HTML/CSS is explicitly frozen; this is an engine swap only.

## Decision

- New content at `service/blog/` (Zola project root, not a Cargo crate),
  copied in fresh rather than history-merged — see ADR-0067 for why.
- Full Jekyll → Zola concept mapping (layouts → Tera templates, `_posts` →
  `content/posts`, `_nav` → `config.toml`'s `[[extra.nav]]`, etc.) — see the
  ADR's mapping table.
- Syntax highlighting deliberately left off, matching today's actual
  (unstyled) code block rendering.
- Atom feed lands at `/posts/posts_feed.xml` instead of the original
  `/posts_feed` — two Zola template-loader constraints discovered during
  implementation, documented in the ADR. Feed markup isn't part of the
  frozen UI/CSS.
- **DNS: no changes needed.** GitHub Pages' custom-domain-to-repo mapping is
  account-level, not DNS-based, so the existing CNAME records stay correct
  regardless of which repo backs the Pages site.
- New `.mise.toml` `blog-build`/`blog-serve` tasks and a
  `.github/workflows/blog-pages.yml` workflow mirroring the original's
  configure-pages/upload-pages-artifact/deploy-pages shape.
- The actual GitHub Pages hosting cutover is manual, performed by the user.

Full decision record: `docs/adr/0067-rewrite-blog-to-zola.md`.

[#66](https://github.com/noisypigeon/noisypigeon/pull/66)
