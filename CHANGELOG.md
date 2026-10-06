# Changelog

One line per PR across this whole repo, sectioned by date, newest first.
Not versioned — for versioned, package-scoped changelogs see
`templates/terraform/*/*/CHANGELOG.md` (each Terraform module),
[`templates/zola-site/CHANGELOG.md`](templates/zola-site/CHANGELOG.md) (the
theme, versioned since ADR-0113), and
[`workloads/noisypigeon.com/CHANGELOG.md`](workloads/noisypigeon.com/CHANGELOG.md) (the blog,
unversioned). The `pigeon-cli` crate's own changelog now lives in its own
repo, `noisypigeon/pigeon-cli`, since ADR-0084's split. Entry format:
`- [<scope>] <summary> ([#N](PR URL))`, where `<scope>` is `pigeon-cli`,
`blog`, `zola-site`, `<provider>/<module>`, or `repo` for cross-cutting/
structural changes. Starts fresh at ADR-0050 — no backfill of prior history, with one
deliberate exception: ADR-0108 backfilled `[blog]` entries for
2026-09-27 through 2026-10-03, the small, concrete window between the
blog's existence in this repo and its changelog automation landing.

## 2026-10-05

- [blog] Make workloads/noisypigeon.com Terraform-self-sufficient ([#208](https://github.com/noisypigeon/noisypigeon/pull/208))

- [scaleway/iam-api-key] Add default_project_id input to iam-api-key ([#201](https://github.com/noisypigeon/noisypigeon/pull/201))

- [scaleway/object-bucket] Add exact_name, website hosting, and public-read ACL to object-bucket ([#194](https://github.com/noisypigeon/noisypigeon/pull/194))

- [zola-site] Fix homepage h1 styling to match plain site-title link ([#191](https://github.com/noisypigeon/noisypigeon/pull/191))

- [zola-site] Strengthen name-entity SEO signals on homepage and posts ([#189](https://github.com/noisypigeon/noisypigeon/pull/189))

- [blog] Strengthen name-entity SEO signals on homepage and posts ([#189](https://github.com/noisypigeon/noisypigeon/pull/189))

## 2026-10-04

- [scaleway/compute-instance] Add enabled kill switch to compute-instance ([#173](https://github.com/noisypigeon/noisypigeon/pull/173))

- [scaleway/compute-instance] Add post_provision_commands to compute-instance ([#172](https://github.com/noisypigeon/noisypigeon/pull/172))

- [scaleway/compute-instance] Compose iam-policy and iam-api-key inside compute-instance ([#167](https://github.com/noisypigeon/noisypigeon/pull/167))

- [scaleway/compute-instance] Pin block-volume source in compute-instance ([#165](https://github.com/noisypigeon/noisypigeon/pull/165))

- [scaleway/compute-instance] Rename block-volume's naming inputs and compose it inside compute-instance ([#163](https://github.com/noisypigeon/noisypigeon/pull/163))

- [scaleway/block-volume] Rename block-volume's naming inputs and compose it inside compute-instance ([#163](https://github.com/noisypigeon/noisypigeon/pull/163))

- [scaleway/iam-policy] Split iam-policy's application/API-key into iam-application and iam-api-key modules ([#162](https://github.com/noisypigeon/noisypigeon/pull/162))

- [scaleway/iam-application] Split iam-policy's application/API-key into iam-application and iam-api-key modules ([#162](https://github.com/noisypigeon/noisypigeon/pull/162))

- [scaleway/iam-api-key] Split iam-policy's application/API-key into iam-application and iam-api-key modules ([#162](https://github.com/noisypigeon/noisypigeon/pull/162))

- [scaleway/object-bucket] Rename object-bucket's namespace/name to name_prefix/name_suffix, default storage_class to glacier ([#161](https://github.com/noisypigeon/noisypigeon/pull/161))

- [scaleway/compute-instance] Simplify scaleway/compute-instance's interface (ADR-0118) ([#157](https://github.com/noisypigeon/noisypigeon/pull/157))

- [scaleway/cockpit-observability] Add scaleway/cockpit-observability module ([#149](https://github.com/noisypigeon/noisypigeon/pull/149))

- [scaleway/object-bucket] Fix object-bucket endpoint output to use the regional host, not the bucket vhost ([#135](https://github.com/noisypigeon/noisypigeon/pull/135))

- [scaleway/iam-policy] Shorten iam-policy generated application name suffix ([#134](https://github.com/noisypigeon/noisypigeon/pull/134))

## 2026-10-03

- [blog] feat: let consumers pin a templates/zola-site version (ADR-0114) ([#147](https://github.com/noisypigeon/noisypigeon/pull/147))

- [zola-site] First versioned release of the templates/zola-site theme ([#146](https://github.com/noisypigeon/noisypigeon/pull/146))

- [blog] feat(blog): extract reusable templates/zola-site theme (ADR-0112) ([#145](https://github.com/noisypigeon/noisypigeon/pull/145))

- [blog] feat(blog): comprehensive SEO pass (ADR-0111) ([#143](https://github.com/noisypigeon/noisypigeon/pull/143))

- [blog] Add short noisypigeon.com module import URLs via blog redirect pages ([#140](https://github.com/noisypigeon/noisypigeon/pull/140))

- [blog] fix(blog): update changelog titles ([#139](https://github.com/noisypigeon/noisypigeon/pull/139))

- [blog] feat(blog): compute digest titles from entries, backfill changelog history ([#138](https://github.com/noisypigeon/noisypigeon/pull/138))

- [blog] feat(blog): wire blog into the changelog workflow, restructure changelog channel ([#136](https://github.com/noisypigeon/noisypigeon/pull/136))

- [blog] fix(blog): changelog css ([8925ece](https://github.com/noisypigeon/noisypigeon/commit/8925ecea7b2965d3b050daa3e33a0ecb070f0594))

- [blog] chore(blog): move more blog posts to changelog channel ([d865f82](https://github.com/noisypigeon/noisypigeon/commit/d865f821f98f145e83f84bc4939657e22a4d72df))

- [blog] chore(blog): organize posts ([3dc9e54](https://github.com/noisypigeon/noisypigeon/commit/3dc9e544d43657b5a8cb5ba9b120959a954de9a8))

- [blog] chore(blog): clean-up about and lineage ([eb25e46](https://github.com/noisypigeon/noisypigeon/commit/eb25e46f619d73de7a6f60a1e94e285b2e089d20))

- [blog] chore(blog); a few more renames ([9f14bcd](https://github.com/noisypigeon/noisypigeon/commit/9f14bcd26f92cdb3a92cff5194954a420ac77a0d))

- [blog] chore: remove duplicate title ([bc99d6b](https://github.com/noisypigeon/noisypigeon/commit/bc99d6bd371d45dcd8b34c7e83bbcd885e427786))

- [blog] chore: clean-up dns terraform; update blog names/lineage page ([4da2430](https://github.com/noisypigeon/noisypigeon/commit/4da24307d524720c8b08e6af148ca0bad63dbaaa))

- [blog] chore(blog): make profile links clickable ([9979a98](https://github.com/noisypigeon/noisypigeon/commit/9979a988555eb6da610f6a4b8a3e606beff3ef95))

- [blog] chore(blog): deploy profiles page ([f256c83](https://github.com/noisypigeon/noisypigeon/commit/f256c83bdfb9c64536ae2b8e22fa0fdf7e05b6ab))

- [scaleway/compute-instance] Fix environment_variables/PIGEON_LOG_DIR not reaching non-login SSH invocations ([#133](https://github.com/noisypigeon/noisypigeon/pull/133))

- [scaleway/compute-instance] Add a shared Cockpit metrics/logs store for pigeon-cli instances ([#132](https://github.com/noisypigeon/noisypigeon/pull/132))

- [scaleway/compute-instance] Fix doubled Cockpit push path and non-resilient log tailing in compute-instance ([#131](https://github.com/noisypigeon/noisypigeon/pull/131))

- [scaleway/compute-instance] Fix alloy install failing on a dpkg conffile prompt in compute-instance ([#130](https://github.com/noisypigeon/noisypigeon/pull/130))

- [scaleway/compute-instance] Add Scaleway Cockpit wiring to compute-instance via Grafana Alloy ([#128](https://github.com/noisypigeon/noisypigeon/pull/128))

## 2026-10-02

- [scaleway/compute-instance] Make keyring bucket encryption key optional; add environment_variables ([#127](https://github.com/noisypigeon/noisypigeon/pull/127))

- [scaleway/compute-instance] Add keyring_entries input for pigeon-cli keyring.toml ([#126](https://github.com/noisypigeon/noisypigeon/pull/126))

- [scaleway/compute-instance] Merge rclone cloud-init profile into pigeon-cli ([#125](https://github.com/noisypigeon/noisypigeon/pull/125))

- [scaleway/project] Move scaleway modules to top-level modules/, major release each ([#120](https://github.com/noisypigeon/noisypigeon/pull/120))

- [scaleway/object-bucket] Move scaleway modules to top-level modules/, major release each ([#120](https://github.com/noisypigeon/noisypigeon/pull/120))

- [scaleway/iam-policy] Move scaleway modules to top-level modules/, major release each ([#120](https://github.com/noisypigeon/noisypigeon/pull/120))

- [scaleway/compute-instance] Move scaleway modules to top-level modules/, major release each ([#120](https://github.com/noisypigeon/noisypigeon/pull/120))

- [scaleway/block-volume] Move scaleway modules to top-level modules/, major release each ([#120](https://github.com/noisypigeon/noisypigeon/pull/120))

- [terraform/scaleway/compute-instance] Fix missing $HOME in scaleway/compute-instance cloud-init runcmd ([#117](https://github.com/noisypigeon/noisypigeon/pull/117))

- [terraform/scaleway/compute-instance] Auto-mount attached volume and inline pigeon-cli bootstrap on scaleway/compute-instance ([#116](https://github.com/noisypigeon/noisypigeon/pull/116))

- [terraform/scaleway/compute-instance] Add pigeon-cli cloud-init profile and ipv4_address output to scaleway/compute-instance ([#115](https://github.com/noisypigeon/noisypigeon/pull/115))

- [terraform/scaleway/compute-instance] Add cloud-init profiles (rclone/docker) to scaleway/compute-instance ([#114](https://github.com/noisypigeon/noisypigeon/pull/114))

## 2026-10-01

- [blog] Rename service/blog to workloads/blog/src ([#118](https://github.com/noisypigeon/noisypigeon/pull/118))

- [terraform/scaleway/compute-instance] Pre-install mise and a build toolchain in compute-instance's cloud-init ([#112](https://github.com/noisypigeon/noisypigeon/pull/112))

- [terraform/scaleway/compute-instance] Attach a routed IPv4 address to compute-instance by default ([#111](https://github.com/noisypigeon/noisypigeon/pull/111))

- [terraform/scaleway/block-volume] Require project_id input on scaleway/block-volume ([#110](https://github.com/noisypigeon/noisypigeon/pull/110))

- [terraform/scaleway/compute-instance] Add scaleway/block-volume module and compute-instance volume attachment ([#109](https://github.com/noisypigeon/noisypigeon/pull/109))

- [terraform/scaleway/block-volume] Add scaleway/block-volume module and compute-instance volume attachment ([#109](https://github.com/noisypigeon/noisypigeon/pull/109))

## 2026-09-30

- [terraform/scaleway/compute-instance] Force instance replacement when compute-instance cloud-init changes ([#108](https://github.com/noisypigeon/noisypigeon/pull/108))

- [terraform/scaleway/project] Fix scaleway/project ssh_key to scope to the created project ([#107](https://github.com/noisypigeon/noisypigeon/pull/107))

- [terraform/scaleway/project] Add optional ssh_key input to scaleway/project ([#106](https://github.com/noisypigeon/noisypigeon/pull/106))

- [terraform/scaleway/compute-instance] Add routed IPv6 and instance-specific SSH keys to scaleway/compute-instance ([#105](https://github.com/noisypigeon/noisypigeon/pull/105))

- [terraform/scaleway/compute-instance] Add rclone/neovim cloud-init and bucket access to scaleway/compute-instance ([#104](https://github.com/noisypigeon/noisypigeon/pull/104))

- [terraform/scaleway/object-bucket] Add force_destroy input to object-bucket ([#101](https://github.com/noisypigeon/noisypigeon/pull/101))

- [repo] docs(adr-0084): prune repo to terraform+blog scope ([#100](https://github.com/noisypigeon/noisypigeon/pull/100))
- [repo] docs(adr-0084): split pigeon-cli into its own repo ([#99](https://github.com/noisypigeon/noisypigeon/pull/99))
- [pigeon-cli] feat(adr-0083): implement sort job ([#98](https://github.com/noisypigeon/noisypigeon/pull/98))
- [pigeon-cli] docs(adr-0083): add sort job ADR ([#96](https://github.com/noisypigeon/noisypigeon-2/pull/96))
- [pigeon-cli] feat(adr-0082): implement dedupe job ([#95](https://github.com/noisypigeon/noisypigeon-2/pull/95))
- [pigeon-cli] docs(adr-0082): add dedupe job ADR ([#94](https://github.com/noisypigeon/noisypigeon/pull/94))
- [pigeon-cli] feat(adr-0081): implement email-pull job ([#93](https://github.com/noisypigeon/noisypigeon/pull/93))
- [pigeon-cli] docs(adr-0081): add email-pull job ADR ([#92](https://github.com/noisypigeon/noisypigeon/pull/92))

## 2026-09-29

- [terraform/digitalocean/droplet] Drop Cloudflare DNS record integration ([#91](https://github.com/noisypigeon/noisypigeon/pull/91))

- [terraform/digitalocean/droplet] Accept caller-supplied bucket credentials per rclone remote ([#90](https://github.com/noisypigeon/noisypigeon/pull/90))

- [terraform/scaleway/compute-instance] docs(adr-0079): add scaleway/compute-instance module ([#86](https://github.com/noisypigeon/noisypigeon/pull/86))

## 2026-09-28

- [pigeon-cli] feat(adr-0080): add a per-identity IMAP connection cap via keyring, and route transform lenient-skip warnings through tracing ([#87](https://github.com/noisypigeon/noisypigeon/pull/87))
- [repo] feat(adr-0078): formalize a job-run log analysis procedure and package it as the `analyze-job-run` Claude Code skill ([#85](https://github.com/noisypigeon/noisypigeon/pull/85))

## 2026-09-27

- [blog] chore(blog): add bix ([#69](https://github.com/noisypigeon/noisypigeon/pull/69))

- [pigeon-cli] feat(adr-0077): add pull-transform file-type selection, adaptable transcoding mapping, and zip pass-through ([#84](https://github.com/noisypigeon/noisypigeon/pull/84))

- [pigeon-cli] fix(adr-0076): stream pull-transform downloads and zip expansion to disk instead of buffering whole objects/zips in memory, fixing a real SIGKILL crash against 50-100GB zip archives ([#83](https://github.com/noisypigeon/noisypigeon/pull/83))

- [pigeon-cli] feat(adr-0075): add progress visibility to pull-transform -- a live bar plus named call-outs for large downloads/recodes, so a long run no longer looks hung ([#82](https://github.com/noisypigeon/noisypigeon/pull/82))

- [pigeon-cli] feat(adr-0074): add pull-transform job -- pulls a bucket, expands zips, recodes media via ffmpeg with verify/fallback, dates and dedups by content, and organizes/uploads the result ([#81](https://github.com/noisypigeon/noisypigeon/pull/81))

- [pigeon-cli] feat(adr-0073): add cross-cutting observability -- structured tracing, a durable JSONL log, and CPU/mem/disk telemetry via one Observable trait reused by every command ([#80](https://github.com/noisypigeon/noisypigeon/pull/80))

- [terraform/scaleway/object-bucket] fix(adr-0072): raise GLACIER transition to Scaleway's 90-day minimum ([#77](https://github.com/noisypigeon/noisypigeon/pull/77))

- [terraform/scaleway/iam-policy] fix(adr-0070): downgrade admin bucket-policy statement to a supported version ([#73](https://github.com/noisypigeon/noisypigeon/pull/73))

- [terraform/scaleway/iam-policy] feat(adr-0069): guard scaleway/iam-policy against bucket-policy self-lockout ([#71](https://github.com/noisypigeon/pigeon/pull/71))

- [blog] ADR-0067: rewrite the noisypigeon.github.io blog from Jekyll to Zola as `service/blog` ([#66](https://github.com/noisypigeon/pigeon/pull/66))
- [pigeon-cli] ADR-0068: treat IMAP `LOGOUT` failures as best-effort, not fatal -- fixes a crash (and silent manifest-data loss) when the connection drops right after a successful `job run email-sync` mailbox scan ([#67](https://github.com/noisypigeon/pigeon/pull/67)).
- [pigeon-cli] ADR-0071: cap simultaneous IMAP connections per identity, retry a transiently-failed batch once, and collapse per-UID fetch-failure warning spam into one line per batch ([#76](https://github.com/noisypigeon/noisypigeon/pull/76))

- [terraform/scaleway/iam-policy] feat(adr-0066): guard scaleway/iam-policy against bucket-scope widening ([#64](https://github.com/noisypigeon/pigeon/pull/64))
- [pigeon-cli] ADR-0065: fix a `job run email-sync` crash caused by a single unparseable `BODYSTRUCTURE` message aborting an entire mailbox's manifest gathering -- `pull_manifest` now bisects the UID batch to isolate just the poisoned message(s) ([#65](https://github.com/noisypigeon/pigeon/pull/65)).

## 2026-09-26

- [terraform/digitalocean/droplet] Fix droplet module's access-key dependency source ([#63](https://github.com/noisypigeon/pigeon/pull/63))

- [repo] ADR-0050: relocate `Cargo.toml`/`Cargo.lock` into `service/pigeon-cli/`, add this repo-wide dated changelog, rename `LICENSE` to `LICENSE.md`, and rewrite both READMEs ([#59](https://github.com/noisypigeon/pigeon/pull/59)).

## 2026-09-25

- [repo] ADR-0051: rename GitHub repo references `pigeon-cli` → `pigeon`, correct `Cargo.toml`'s `repository` field, and bump to `0.2.1` in prep for the next publish ([#60](https://github.com/noisypigeon/pigeon/pull/60)).
- [repo] ADR-0052: decide how to merge the separate `pigeon-do` repo's full history into this repo as `terraform/infrastructure/*`, a new sibling to `terraform/modules/` (documents the decision; the user performs the actual merge manually) ([#62](https://github.com/noisypigeon/pigeon/pull/62)).
