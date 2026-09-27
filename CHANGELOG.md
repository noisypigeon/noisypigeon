# Changelog

One line per PR across this whole repo, sectioned by date, newest first.
Not versioned — for versioned, package-scoped changelogs see
[`service/pigeon-cli/CHANGELOG.md`](service/pigeon-cli/CHANGELOG.md) (the
`pigeon-cli` crate) and `terraform/modules/*/*/CHANGELOG.md` (each
Terraform module). Entry format: `- [<scope>] <summary> ([#N](PR URL))`,
where `<scope>` is `pigeon-cli`, `blog`, `terraform/<provider>/<module>`, or
`repo` for cross-cutting/structural changes. Starts fresh at ADR-0050 — no
backfill of prior history.

## 2026-09-27

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
