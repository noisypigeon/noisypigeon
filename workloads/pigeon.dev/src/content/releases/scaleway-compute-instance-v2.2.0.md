+++
title = "scaleway/compute-instance v2.2.0"
date = 2026-10-02T12:00:00-07:00
slug = "scaleway-compute-instance-v2.2.0"
description = "Make keyring bucket encryption key optional; add environment_variables"
+++

Two follow-ups to `scaleway/compute-instance`'s `keyring_entries` (ADR-0100):

1. **`encryption_key_alias` is now actually optional for `kind = "bucket"` entries.** The type already declared it `optional(string)`, but the render unconditionally interpolated it, which errors on `null`. A bucket entry with no associated encryption key now renders cleanly without that field.

2. **New `environment_variables` input** — a generic `map(string)` of key/value environment variables, usable with any profile (not just `pigeon-cli`), written to `/etc/profile.d/pigeon-env.sh` and sourced both early in `runcmd` (so it's available at first boot) and automatically by later interactive login shells (so it's available to a manual `pigeon-cli` SSH session too). Marked `sensitive = true`. This lets callers inject secrets such as `pigeon-cli`'s `PIGEON_SECRET_<ALIAS>`-named keyring secrets without this module hardcoding that naming convention.

Both changes are backwards compatible (`environment_variables` defaults to `{}`; the encryption-key fix only makes a previously-erroring case succeed). See ADR-0101 (`docs/adr/0101-add-environment-variables-and-optional-keyring-encryption-key.md`) for full rationale.

[#127](https://github.com/noisypigeon/noisypigeon/pull/127)
