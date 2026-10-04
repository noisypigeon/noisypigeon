# Changelog

All notable changes to the blog are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
