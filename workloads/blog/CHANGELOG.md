# Changelog

All notable changes to the blog are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
