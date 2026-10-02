# Changelog

All notable changes to this module are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.8.0] - 2026-10-02

### Add pigeon-cli cloud-init profile and ipv4_address output to scaleway/compute-instance

`scaleway/compute-instance`'s `profile` input gains a third value, `"pigeon-cli"`, alongside the existing `"rclone"`/`"docker"` (ADR-0087). Unlike those two, it installs no packages — it only appends an export line to `~/.bashrc` setting a `BOOTSTRAP` environment variable to:

```
curl -fsSL https://gist.githubusercontent.com/noisypigeon/1e96e8ef94380f913f6ae02782965149/raw/pigeon.sh | bash
```

**Invocation note:** run it as `eval $BOOTSTRAP`, not bare `$BOOTSTRAP`. Unquoted shell variable expansion doesn't get re-parsed for operators like `|`, so typing `$BOOTSTRAP` directly would pass `-fsSL`, the URL, `|`, and `bash` as literal arguments to `curl` rather than piping to it. `eval` re-parses the expanded string and runs the pipeline correctly.

Supporting this profile required making the cloud-init template's `packages:` key itself conditional (previously always emitted; `pigeon-cli` needs zero packages, and an empty `packages:` key is invalid/null in cloud-init YAML). Rendered output for `"rclone"`/`"docker"` is unchanged.

Also adds a new `ipv4_address` output, sourced from the existing routed-IPv4 resource — `null` when `enable_ipv4 = false`. Purely additive; `public_ips`/`private_ips` are unchanged.

Full design rationale in [ADR-0088](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0088-add-pigeon-cli-profile-to-scaleway-compute-instance.md).

Existing callers are unaffected by the interface change (new enum value, new output, both default-preserving), but — as with every prior change to this module's cloud-init content — any existing instance gets replaced on its next apply (ADR-0084's force-replace-on-cloud-init-change lifecycle).

## Test plan
- [x] `terraform fmt -check` clean
- [x] `terraform init -backend=false && terraform validate` clean
- [x] Rendered all three profiles via a scratch config: `rclone`/`docker` output unchanged, `pigeon-cli` correctly omits `packages:` and sets the `BOOTSTRAP` export

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#115](https://github.com/noisypigeon/noisypigeon/pull/115)

## [0.7.0] - 2026-10-02

### Add cloud-init profiles (rclone/docker) to scaleway/compute-instance

`scaleway/compute-instance` gains a new `profile` input (`"rclone"` or `"docker"`, defaults to `"rclone"`) that selects between two cloud-init provisioning shapes:

- **`profile = "rclone"`** (default, matches prior behavior): installs `rclone` and `neovim`, and writes `/root/.config/rclone/rclone.conf` from `var.buckets` exactly as before.
- **`profile = "docker"`**: installs Docker CE (official apt repo/key bootstrap) plus `docker-ce-cli`, `containerd.io`, and `docker-compose-plugin`, and enables + starts the `docker` service.

`build-essential`, `pkg-config`, and `libssl-dev` are removed from the cloud-init package list entirely, under both profiles — they were only ever installed to support `mise`'s build-toolchain use case, not rclone, and aren't needed by either new profile. Any existing instance relying on those packages being present will lose them on its next apply.

`buckets` now has a validation guard: it's rejected (non-empty) when `profile != "rclone"`, since bucket config would otherwise silently do nothing.

Full design rationale in [ADR-0087](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0087-add-cloud-init-profiles-to-scaleway-compute-instance.md).

Existing callers are unaffected by the interface change (new input defaults to `"rclone"`), but — as with every prior change to this module's cloud-init content — any existing instance gets replaced on its next apply (ADR-0084's force-replace-on-cloud-init-change lifecycle).

## Test plan
- [x] `terraform fmt -check` clean
- [x] `terraform init -backend=false && terraform validate` clean
- [x] Rendered both profiles via a scratch config and confirmed correct package lists / `write_files` / `runcmd` branching, and that `buckets` + `profile = "docker"` is rejected by the new validation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

[#114](https://github.com/noisypigeon/noisypigeon/pull/114)

## [0.6.0] - 2026-10-01

### Pre-install mise and a build toolchain in compute-instance's cloud-init

Every instance created by `scaleway/compute-instance` now gets, unconditionally (same posture as the existing `rclone`/`neovim` install), a Rust/C build toolchain (`build-essential`, `pkg-config`, `libssl-dev`) and [mise](https://mise.jdx.dev/) pre-installed via its official quick-install script, with bash activation wired into `~/.bashrc`.

No new module input — this follows the same unconditional-provisioning pattern already used for `rclone`/`neovim`.

Since this edits the instance's cloud-init content, and the module already forces instance replacement whenever that content changes (ADR-0084), any existing instance using this module will be destroyed and recreated on its next `terragrunt apply` after upgrading to this version.

[#112](https://github.com/noisypigeon/noisypigeon/pull/112)

## [0.5.0] - 2026-10-01

### Attach a routed IPv4 address to compute-instance by default

Adds a new `enable_ipv4` input to `scaleway/compute-instance` (defaults to `true`), creating and attaching a routed IPv4 address to the instance by default, alongside the existing `enable_ipv6` (defaults to `false`).

`scaleway_instance_server`'s `ip_id` argument only ever holds a single reserved IP, and is mutually exclusive with `ip_ids`, the list-valued equivalent. Since `enable_ipv4` defaults to `true`, an instance can now have both an IPv4 and an IPv6 address enabled at once, which `ip_id` can't express. The server's attachment argument switches from `ip_id` to `ip_ids`, built from whichever of the two IPs are enabled (`compact([...])`, dropping disabled ones) — functionally identical to before when only one or neither is enabled.

Existing callers that already set `enable_ipv6 = true` will pick up a new default IPv4 address on their next apply (and will see `scaleway_instance_server`'s IP attachment move from `ip_id` to `ip_ids`); set `enable_ipv4 = false` to opt out and keep IPv6-only.

[#111](https://github.com/noisypigeon/noisypigeon/pull/111)

## [0.4.0] - 2026-10-01

### Add scaleway/block-volume module and compute-instance volume attachment

Adds a new `scaleway/block-volume` module wrapping `scaleway_block_volume`, and extends `scaleway/compute-instance` so a volume it creates can be attached to an instance.

`block-volume`'s initial interface is required-fields-only, with two deliberate exceptions: the resource's `size_in_gb` is renamed to `size` (required — this module doesn't support creating from a snapshot yet, so omitting a size would be unsafe), and `iops`, though required by the underlying resource, defaults to `15000` (Scaleway's standard tier) rather than being required of every caller. Naming follows the same `{namespace}-{random}-{name}` scheme as every other module in this provider root. Outputs are `id` and `name`.

`compute-instance` gains one new, backwards-compatible input: `additional_volume_ids` (`list(string)`, default `[]`), wired straight through to `scaleway_instance_server`'s existing argument of the same name. Per this repo's established composition rule, `compute-instance` does not call `block-volume` internally — callers create a volume and pass its `id` through themselves, e.g.:

```hcl
module "scratch_volume" {
  source = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/block-volume?ref=terraform/modules/scaleway/block-volume/v0.1.0"
  namespace = "import"
  name      = "scratch"
  size      = 100
}

module "instance" {
  source = "git::https://github.com/noisypigeon/pigeon.git//terraform/modules/scaleway/compute-instance?ref=..."
  ...
  additional_volume_ids = [module.scratch_volume.id]
}
```

Existing `compute-instance` callers are unaffected unless they opt in. Full design rationale in [ADR-0085](https://github.com/noisypigeon/noisypigeon/blob/main/docs/adr/0085-add-scaleway-block-volume-module.md).

[#109](https://github.com/noisypigeon/noisypigeon/pull/109)

## [0.3.1] - 2026-09-30

### Force instance replacement when compute-instance cloud-init changes

Root-caused (see ADR-0084 for the full investigation and citations): `scaleway_instance_server.user_data` has no `ForceNew` in the Terraform provider schema, so changing its `cloud-init` content on an *existing* instance just PATCHes the metadata in place via Scaleway's API — the instance keeps its instance-id. cloud-init only runs package-install and `write_files` modules once per instance-id, on first boot, so an in-place `user_data` update (or a plain reboot) is silently never applied. This is exactly what DigitalOcean's `digitalocean_droplet.user_data` avoids by being `ForceNew: true`, which ADR-0081 didn't carry over when porting the cloud-init pattern to Scaleway.

Fix: the cloud-config content moves into `local.cloud_init`, a new `terraform_data.cloud_init` resource hashes it, and `scaleway_instance_server.server` gets `lifecycle { replace_triggered_by = [terraform_data.cloud_init.output] }`. Any future change to the rendered cloud-init content (packages, buckets, write_files) now forces a fresh instance, guaranteeing cloud-init gets a genuine first boot on it — matching DigitalOcean's behavior.

No input or output changes. Note this doesn't retroactively fix any instance already running with skipped cloud-init modules — those need a one-time manual rebuild.

[#108](https://github.com/noisypigeon/noisypigeon/pull/108)

## [0.3.0] - 2026-09-30

### Add routed IPv6 and instance-specific SSH keys to scaleway/compute-instance

`scaleway/compute-instance` gains two new opt-in inputs:

- **`enable_ipv6`** (bool, default `false`): when true, creates a `scaleway_instance_ip` of type `routed_ipv6` and attaches it to the instance via `ip_id`. The address shows up in the existing `public_ips` output once attached (filter by `family == "inet6"`) -- no new output was added. Note: the originally-proposed `scaleway_flexible_ip` resource does *not* apply here -- it's scoped to Elastic Metal (bare metal) servers only, confirmed directly against the Terraform provider's source. `scaleway_instance_ip` is the correct mechanism for a standard Instance's routed IP.

- **`ssh_keys`** (list of strings, default `[]`): raw SSH public keys that get instance-specific access, in addition to account-wide keys that already apply automatically. The module encodes each into Scaleway's `AUTHORIZED_KEY=<key-with-underscores>` tag convention, so callers don't have to hand-escape spaces themselves.

Both inputs default to their no-op values, so this is fully backwards compatible. See ADR-0082 and ADR-0083 for the full design rationale.

[#105](https://github.com/noisypigeon/noisypigeon/pull/105)

## [0.2.0] - 2026-09-30

### Add rclone/neovim cloud-init and bucket access to scaleway/compute-instance

`scaleway/compute-instance` now installs `rclone` and `neovim` via cloud-init on every instance, and accepts a new optional `buckets` input (default `[]`) that populates `/root/.config/rclone/rclone.conf` with one `alias` + one `s3` remote per bucket -- the same schema and rendering approach `digitalocean/droplet` already uses for its own rclone config.

Bucket-scoped access-key creation stays outside this module: compose a `scaleway/iam-policy` module call (its `bucket_names`/`bucket_actions`/`admin_project_id` inputs and `access_key`/`secret_key` outputs are unchanged) and pass the resolved credentials into `buckets` yourself.

See ADR-0081 for the full design rationale, including why bucket-credential creation stays external and why `rclone.conf` lands under `/root` rather than a created non-root user.

This PR also fixes stale `docs/archived/adr/` references in `CLAUDE.md`/`docs/USAGE.md` -- that directory no longer exists on `main` (ADRs were flattened back into `docs/adr/` a while back); unrelated to the module change itself but caught while writing ADR-0081.

[#104](https://github.com/noisypigeon/noisypigeon/pull/104)

## [0.1.0] - 2026-09-29

### docs(adr-0079): add scaleway/compute-instance module

## Context

`terraform/modules/scaleway/` has `project`, `object-bucket`, and `iam-policy`, but no compute module. `digitalocean/droplet` is the DigitalOcean analog, but it bundles DigitalOcean-specific machinery (cloud-init, an access-key sub-module, SSH-key data source, Cloudflare DNS alias) not wanted yet. This adds a deliberately minimal wrapper around `scaleway_instance_server`, using `droplet` only for structural/naming inspiration.

## Decision

- New module `terraform/modules/scaleway/compute-instance`: `namespace`/`name`/`image` required, `type` defaults to `STARDUST1-S` (overridable) — the one deliberate exception to "required fields only," per the user's request.
- `image` is a required *module* input even though it's an optional *resource* argument on `scaleway_instance_server` — the resource only allows skipping it when attaching an existing root volume, a path this module doesn't support yet (same kind of call ADR-0044 made for `object-bucket`'s `storage_class`).
- Outputs are pass-through only (`id`, `name`, `public_ips`, `private_ips`) — no invented indexing, since no IP is attached by default.
- `terraform/modules/README.md` gains a row; `module-docs.yml`'s hand-maintained `working-dir:` list gains an entry. `module-release.yml` needs no change — its module discovery and changelog/tagging automation already generalize to any provider root with a `versions.tf`.
- No hand-written `CHANGELOG.md` — `module-release.yml` creates one on first merge.

Full ADR: [`docs/adr/0079-add-scaleway-compute-instance-module.md`](../blob/adr-0079-add-scaleway-compute-instance-module/docs/adr/0079-add-scaleway-compute-instance-module.md)

## Test plan

- [x] `terraform fmt -check` clean.
- [x] `terraform init -backend=false && terraform validate` clean.
- [x] `mise run ci` clean.

[#86](https://github.com/noisypigeon/noisypigeon/pull/86)
